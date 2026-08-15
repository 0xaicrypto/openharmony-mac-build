# 交接指南 (HANDOVER)

> 给接手者的第一份文档。读完本文件 + PROGRESS.md + scripts/README.md 即可接手。

## 1. 现状一句话

构建 ✅、系统启动 ✅、**应用完整运行** ✅ (launcher 启动并渲染桌面布局、
systemui/settingsdata 正常运行、bms/appmgr 数据链路完整)。
EGL 软件渲染 ✅ (Mesa swrast, EGL 1.4)。
**当前唯一卡点: 桌面 UI 未上屏 —— HDI 显示服务 `display_composer_service` 未注册
(composer_host 的 host attach 成功、主线程在 HDF 消息循环正常等待, 但服务未发布,
疑 DisplayComposerService 构造失败走 ExitService), RS 合成无法输出, 屏幕全黑;
virtio-gpu 下 QEMU 侧帧传输也不上屏 (QEMU 9/11 均复现)**

## 2. 为什么会有这个仓库

OHOS 官方构建只支持 Linux。本仓库以"源码相对路径镜像"的方式记录全部 macOS 适配补丁,
`scripts/apply_patches.sh` 可回放到任意干净源码树后直接构建。构建产物在
`out/arm64_virt/` (被 .gitignore 排除, 不入库)。

## 3. 环境与约定 (务必先读)

| 项 | 值 |
| --- | --- |
| 源码根 | `/Users/hui/ohos-src` (本机); 远端构建需先 apply_patches |
| 构建产物 | `/Users/hui/ohos-src/out/arm64_virt/` |
| 镜像目录 | `out/arm64_virt/packages/phone/images/*.img` (system/vendor/userdata...) |
| 系统文件根 | `out/arm64_virt/packages/phone/` (system=system/lib 等) |
| QEMU 启动 | `.opencode/mac/scripts/run_qemu.sh` (VNC :21, 密码 123456, monitor socket `/tmp/qemu_mon.sock`) |
| 启动日志 | `/tmp/ohos_bootNN.log` (最新一轮编号最大) |
| 设备内日志 | `/dev/kmsg` (musl/调试插桩都打这里) |
| musl 源码 | `third_party/musl/ldso/linux/dynlink.c`; 构建副本 `out/.../obj/third_party/musl/intermidiates/linux/musl_src_ported/ldso/dynlink.c` (**改完要双向同步**) |
| 每次启动前 | 改 musl 后重跑 `scripts/rebuild_ldso.sh` + `scripts/rebuild_libc.sh` 再部署 libc.so (见 §6) |

## 4. 崩溃调查历史 (避免重复劳动)

调查链条 (每步都验证过, 别走回头路):

1. **符号缺失/平台差异** → 已全部解决 (mesa KHR 导出、platformsdk 459 个 symlink、sysmacros 双平台)。
2. **CFI abort** → libmmi-client 补 `-fsanitize=cfi -fsanitize-cfi-cross-dso` 重编 → 解决。
3. **utd_client 栈溢出 (148KB > 128KB 线程栈)** → InitDescriptors 470 元素拆分 → 解决。
4. **ANDROID_RELA (packed reloc) 缺失** → musl `do_android_relocs()` 调用 tag 从
   `DT_ANDROID_REL` 改为 `DT_ANDROID_RELA` → 重定位现在正确解码 (日志已验证与 llvm-readelf 一致)。
5. **旧卡点 (libimage_native 崩溃) 已全部解开**: 真实链条是 dlopen 卸载/析构竞争
   (TESTDL/PREDLOPEN 调试循环引发) + 模块符号缺失。解法见 PROGRESS.md 第五轮。
6. **uid 体系(第六轮)**: round4 的两个临时绕过(setresuid/setresgid bypass +
   init SetPerms 整体跳过)导致服务进程全是 root → binder caller uid=0 →
   installd/bms 权限全挂、应用 GetBundleInfoForSelf 失败(launcher 反复 spawn)。
   恢复两者后 launcher 完整启动。**别再把 setresuid/setgid/SetPerms 当"绕过"手段。**
7. **当前卡点**: display_composer_service 未注册 (见 §7)。
   已确认: composer_host 未卡死(主线程在 HDF 消息循环 OsalSemWait 等消息, ptrace
   帧回溯证实); probe 无 = /data 0771 权限; 日志静默(fd1/2=/dev/null + kmsg open 失败)。

## 6. 修改 → 验证 循环 (核心工作流)

```bash
# 1. 改 musl/ldso/init/appspawn 源码 (改 /Users/hui/ohos-src 下的源码)
#    musl 特例: 改 third_party/musl/ldso/linux/dynlink.c 后要 cp 到
#    out/arm64_virt/obj/third_party/musl/intermidiates/linux/musl_src_ported/ldso/dynlink.c

# 2. 重建 (脚本在本仓库 scripts/, 变量提取自对应 .ninja, 只编目标不跑全量)
bash scripts/rebuild_ldso.sh     # musl ldso 8 个 .o (改 dynlink.c 后必跑)
bash scripts/rebuild_libc.sh     # 链 libc.so
bash scripts/rebuild_appspawn.sh # appspawn (含 --export-dynamic)
bash scripts/rebuild_begetutil.sh # libbegetutil (modulemgr.c 所在)
bash scripts/rebuild_mesa.sh     # mesa (swrast 软件渲染)

# 3. 部署产物到镜像树
cp out/arm64_virt/obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so \
   out/arm64_virt/packages/phone/system/lib/ld-musl-aarch64.so.1

# 4. 重建 system.img
cd out/arm64_virt
export PATH=/opt/homebrew/bin:$PATH
/usr/bin/env python3 ../../build/ohos/images/build_image.py \
  --depfile gen/build/ohos/images/phone_system_image.d --image-name system \
  --input-path packages/phone/system --image-config-file ../../build/ohos/images/mkimage/system_image_conf.txt \
  --device-image-config-file packages/imagesconf/system_image_conf.txt \
  --output-image packages/phone/images/system.img --target-cpu arm64 --build-variant root \
  --build-image-tools-path clang_arm64/thirdparty/e2fsprogs clang_arm64/thirdparty/f2fs-tools \
  ../../third_party/e2fsprogs/prebuilt/host/bin ../../build/ohos/images/mkimage

# 5. 重启 QEMU 验证
pkill -9 -f qemu-system; rm -f /tmp/ohos_boot41.log
nohup .opencode/mac/scripts/run_qemu.sh > /tmp/ohos_boot41.log 2>&1 &
sleep 100; grep -n "musl: image_native reloc\|SIGSEGV\|launcher\|lockscreen" /tmp/ohos_boot41.log
```

## 7. 下一步行动清单 (按优先级)

1. [ ] **显示输出 (当前主卡点)**:
      - 方案 A: 修 `-vga std` 下 `composer_host` (hdf_devhost) 的 SIGSEGV。
        给 hdf_devhost 加 SIGSEGV handler 打印 PC (参照 modulemgr.c 的 asdbg_segv_handler)，
        定位崩溃函数；重点怀疑 HDI display 在 bochs/DRM 下的合成初始化路径。
      - 方案 B: 解决 virtio-gpu 的 QEMU 帧传输问题 (换 QEMU 版本 / 查 QEMU display 配置)。
2. [ ] 显示恢复后: 清理全部调试插桩 (asdbg/TESTDL/SIG 日志/kmsg 日志/error_impl 直写 kmsg、
      egllog.c sanitize 之外的调试分支), 恢复 appspawn.cfg sandbox-switch on,
      全量 rebuild + 完整重启验证桌面。
3. [ ] 把最终修复同步回本仓库源码镜像 + PROGRESS.md 追加记录。

## 8. 已建立的自测工具 (test_*)

为分层验证图形链路写的临时工具 (通过 init cfg 启动, 输出到 /dev/kmsg, 见 PROGRESS.md 第五轮):

| 工具 | 验证内容 | 当前结果 |
| --- | --- | --- |
| test_egl | dlopen libEGL + eglInitialize | ✅ EGL 1.4 Mesa |
| test_drm | DRM resources/SetCrtc/dumb buffer | ✅ ioctl 全成功 (virtio 下内容不上屏) |
| test_fb | fbdev mmap/write + 读回 | ✅ 写入读回正确 (QEMU 侧显示依赖设备) |

编译模板: clang --target=aarch64-linux-ohos --sysroot=obj/third_party/musl 链接对应 .so。

## 8. 常用调试命令

```bash
# VNC 密码 (monitor socket)
echo 'change vnc password 123456' | socat - UNIX-CONNECT:/tmp/qemu_mon.sock

# 看当前轮启动日志关键行
grep -nE "musl: android|SIGSEGV|appspawn|launcher|render_service|wms" /tmp/ohos_boot40.log

# 库的重定位信息 (宿主机, clang_arm64 的 llvm-readelf)
out/arm64_virt/clang_arm64/llvm/bin/llvm-readelf -r -d <lib>.so | head -40

# 已部署镜像树里的库
readelf -d packages/phone/system/lib/ld-musl-aarch64.so.1 | grep -i android
```

## 9. 应用进程卡死调试速记 (2026-08-13)

- 现象: launcher(uid 10007)exec appspawn 冷启动后, ldso ctor 阶段静默,
  4 vCPU 全空闲, 系统其他服务正常
- 已排除: ANDROID_RELA 解码 / FillpSo gnu hash 死循环 / fcodec ctor /
  musl futex __wait(200万次自旋检测无 stuck)
- 当前工具: tools/dump_wchan.c(遍历 /proc 打印 wchan)、QEMU -s gdb
- 下一步: 抓应用进程 syscall 断点(QEMU gdb 或 strace 等价), 或确认 PID
  namespace 影响
