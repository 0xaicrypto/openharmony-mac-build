# 交接指南 (HANDOVER)

> 给接手者的第一份文档。读完本文件 + PROGRESS.md + scripts/README.md 即可接手。

## 1. 现状一句话

构建 ✅、系统启动 ✅ (核心服务全就绪、开机动画完整)、**唯一卡点: launcher 无法孵化 ——
appspawn dlopen ace 模块依赖链时崩溃, PC 稳定跳转到 libimage_native 的 .dynstr (符号名数据区)**。

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
| 每次启动前 | 必须重跑 `/tmp/rebuild_ldso.sh` + `/tmp/rebuild_libc.sh` 再部署 libc.so (见 §6) —— 只重编译不全量构建 |

## 4. 崩溃调查历史 (避免重复劳动)

调查链条 (每步都验证过, 别走回头路):

1. **符号缺失/平台差异** → 已全部解决 (mesa KHR 导出、platformsdk 459 个 symlink、sysmacros 双平台)。
2. **CFI abort** → libmmi-client 补 `-fsanitize=cfi -fsanitize-cfi-cross-dso` 重编 → 解决。
3. **utd_client 栈溢出 (148KB > 128KB 线程栈)** → InitDescriptors 470 元素拆分 → 解决。
4. **ANDROID_RELA (packed reloc) 缺失** → musl `do_android_relocs()` 调用 tag 从
   `DT_ANDROID_REL` 改为 `DT_ANDROID_RELA` → 重定位现在正确解码 (日志已验证与 llvm-readelf 一致)。
5. **当前问题**: 重定位正确后崩溃**依旧**, 跳转目标是 libimage_native `.dynstr` 偏移 0x17730
   (地址 0xffff10476730, 每次加载偏移相同) → 这是**内存损坏**特征, 不是重定位缺失。
   怀疑方向: 某个库的重定位/初始化**越界写**破坏了 libimage_native 的 GOT; 或 dlopen 的
   符号解析路径写入了错误地址。未定位。

调试插桩现状 (临时, 成功后清理):
- `base/startup/appspawn/standard/appspawn_main.c`: ASDBG 日志 (打 /dev/kmsg)、跳过 execv (LD_PRELOAD 注入)。
- `base/startup/appspawn/modules/modulemgr/appspawn_modulemgr.c`: TESTDL/PREDLOPEN 强制加载测试。
- `base/startup/init/interfaces/innerkits/modulemgr/modulemgr.c`: dlopen 日志 + SIGSEGV handler
  (打印崩溃 PC 和 /proc/self/maps)。
- 镜像 `appspawn.cfg` 已临时改 `--sandbox-switch off` + `"critical": [5,1,60]`
  (源码树 cfg 仍是 on, 别把临时改法提交进源码镜像)。

## 5. 崩溃现象速查

```
[   18.839360] appspawn-dbg: SIGSEGV pc=0xffff10476730 addr=0xffff17bb69f0 sig=11   ← 每轮必现
[   18.933662] Child process appspawn(pid 91) exit with code : 1
```
PC 偏移 = 0x17730 = libimage_native `.dynstr` 区 (符号名数据), 执行数据区 = 跳转表被写坏。

## 6. 修改 → 验证 循环 (核心工作流)

```bash
# 1. 改 musl/ldso/init/appspawn 源码 (改 /Users/hui/ohos-src 下的源码)
#    musl 特例: 改 third_party/musl/ldso/linux/dynlink.c 后要 cp 到
#    out/arm64_virt/obj/third_party/musl/intermidiates/linux/musl_src_ported/ldso/dynlink.c

# 2. 重建 (脚本在 /tmp, 变量提取自对应 .ninja, 只编目标不跑全量)
bash /tmp/rebuild_ldso.sh        # musl ldso 8 个 .o
bash /tmp/rebuild_libc.sh        # 链 libc.so
bash /tmp/rebuild_appspawn.sh    # appspawn (含调试插桩)
bash /tmp/rebuild_init.sh        # init
bash /tmp/rebuild_utd.sh         # libutd_client (栈拆分后无需再动, 保险起见可跑)

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

1. [ ] 定位 libimage_native 内存损坏源: 在 SIGSEGV handler 里打印调用栈 (libunwind/backtrace 不可用,
      可用 musl 的 __unmapself 前的自实现 fp 链) 或逐库二进制搜索 (对每个 dlopen 的库做
      `lldb`/qemu user 模拟单步)。
2. [ ] 若损坏源是其他库 (非 libimage_native), 检查该库的重定位信息 (llvm-readelf -r) 与 musl
      do_android_relocs 解码是否一一对应。
3. [ ] 崩溃解决后: 清理所有调试插桩 (asdbg/TESTDL/PREDLOPEN/SIGSEGV handler/kmsg 日志),
      恢复 appspawn.cfg sandbox-switch on, 全量 rebuild + 完整重启验证桌面。
4. [ ] 把最终修复同步回本仓库源码镜像 + PROGRESS.md 追加第五轮记录。

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
