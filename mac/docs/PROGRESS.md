# 修复日志 (按轮次)

> 时间线: 2026-08-07 ~ 2026-08-12。构建 attempt 计数从 0 到 463。
> 每个文件的**最终内容**都镜像在本仓库源码路径下，.applied 表示已回放。

## 第一轮 (2026-08-07): 构建基础设施打通

### override/third_party/sys/ (darwin 交叉编译 shim, 21 个)
`__has_include_next` 模式: host 编译落到 mac SDK 真头; 交叉编译(aarch64-linux-ohos)落到最小 fallback。
解决 configure 宿主机检测(HAVE_SYS_*)与交叉目标的头不一致问题(如 e2fsprogs `sys/disk.h`)。
`build/config/compiler/BUILD.gn` 的 default_include_dirs 增加 `//override/third_party`。

### build/ 基础设施
| 文件 | 修改 |
| --- | --- |
| `build/templates/bpf/gen_bpf_uapi.py` | darwin 分支: 跳过 `make -C tools/lib/bpf`，用 `scripts/bpf_helpers_doc.py --header` 直接生成 `bpf_helper_defs.h` |
| `build/templates/bpf/ohos_bpf.gni` | `host_os == "mac"` 时追加 `-I//device/board/edu/virt/bpf_compat` |
| `build/misc/mac/find_sdk.py` 等 | 早前一次性修正 (见 .applied 标记) |

### 产品板级 (device/board/edu/virt)
| 文件 | 修改 |
| --- | --- |
| `device/board/edu/virt/bpf_compat/` | BPF 宿主编译用 stub: `sys/socket.h`(AF_INET/INET6 等)、`string.h` |
| `device/board/edu/virt/kernel/build_kernel.sh` | MAKE_OPTIONS: `HOSTCFLAGS=-I${KERNEL_BUILD_ROOT}/hostelf` + `HOSTLDFLAGS=-L/opt/homebrew/opt/openssl@3/lib` |

### 图形编译链 (graphic_3d)
| 文件 | 修改 |
| --- | --- |
| `LumeShaderCompiler/build.sh`、`lumeassetcompiler/build.sh` | 路径改为 darwin prebuilts (`darwin-universal`, `darwin-arm64`, `darwin-x86`) |
| `shader.compile.toolchain.darwin.cmake` | `/usr/bin/clang` + `-include stdint.h`；不能加 `-isystem c++/v1` |
| `LumeShaderCompiler/CMakeLists.txt` | `KHRONOS_KHR` → `third_party/openGLES/api` |
| `lumeassetcompiler/src/main.cpp` | `std::set<dirent*>` → `{name, isDir}` 副本 (macOS readdir 缓冲区复用导致文件名损坏) |
| `third_party/openGLES/api/KHR/khrplatform.h` | 补齐缺失头 |

### 三方库
| 文件 | 修改 |
| --- | --- |
| `third_party/{libinput,libevdev,mtdev}/patch/apply_patch.sh` | `cp -fra` → `cp -fR` (BSD cp 不接受 -r + -R) |
| `kernel/linux/linux-6.6/hostelf/` | 宿主编译用 `elf.h`、`endian.h`、openssl 软链 |
| `tools/build/feature/test-bpf.c` (linux-5.10) | darwin 特征检测时 `syscall()` 恒失败 → 改为 `return 0` |
| darwin 构建 bpftool | macOS `ld -r` 会把 `-fvisibility=hidden` 符号降级为局部 → libbpf Makefile darwin 分支去掉该 flag |

### Prebuilts 修补 (不修改源码，需 setup.sh 执行)
| 位置 | 操作 |
| --- | --- |
| `prebuilts/ark_tools/ark_js_prebuilts/llvm_prebuilts_aarch64` | symlink → `llvm_prebuilts_darwin_arm64` |
| `.../llvm_prebuilts_darwin_arm64/llvm/include/llvm/IR/BuiltinGCs.h` | 转发头 → `../CodeGen/BuiltinGCs.h` (LLVM12 无 IR 版本) |
| `prebuilts/rustc/darwin-arm64` | symlink → `darwin-aarch64` |
| `prebuilts/rustc/darwin-aarch64/current/lib/rustlib/aarch64-unknown-linux-ohos/lib/` | 完整 std rlibs (与 rustc commit 匹配) |
| `prebuilts/develop_tools/bpftool/bin/bpftool` | darwin 构建产物 (build_bpftool.sh 生成) |

### 主机依赖 (Homebrew)
bison, make (gnu), gnu-sed, openjdk@17, libelf, pkg-config, ccache, nproc/python shims

## 第二轮 (2026-08-08, attempt 87-169): 编译中段
- updater lexer: `LexerInput` 签名 int→size_t (flex 2.6)
- iptables: xt_dscp/xt_mark/xt_tcpmss/ipt_TTL 头补全 + `-Wno-error=nonportable-include-path`
- e2fsprogs: 批量 `__has_include` 门 (script/patch_e2fsprogs_has_include.py), sysmacros/linux 头, e2fsdroid _GNU_SOURCE/vfs_cap_data, getsectsize 块条件修正
- SDK innerkits: check.txt 从输出目录生成 (script/gen_sdk_checkfiles.py), gen_sdk_build_file.py 跳过接口校验
- rust: c_utils cxx 桥接 mac 启用 (BUILD.gn), llvm-strip host 路径, tests 跳过, proc_macro 残留清理
- compile_standard_whitelist.json: 补充跨 part 依赖白名单 (deps/external_deps 校验保留)

## 第三轮 (2026-08-08 晚, attempt 197-222): 宿主工具链收尾
- jsvm (node/v8): 宿主构建完整打通 - gyp make.py (start-group/ElfW/-all_load/普通归档), gyp_node.py (-Dhost_os=mac),
  v8.gyp (platform 源选择/trap-handler arm64), build_jsvm_inter.sh (cpuinfo/HOST_OS/cflags_host/dylib 拷贝),
  platform-posix.cc (__APPLE__ 特例), platform-linux.cc (RemapShared), libjsvm.108.dylib→libjsvm.so
- ohpm/hvigor: 下载 oh-command-line-tools 5.0.2 (repo.huaweicloud.com), node-v16.20.2-darwin-x64 真实二进制
- hap: dlp_manager/permission_manager 改 ohos_prebuilt_etc 占位 (避免 SDK 依赖)
- kernel ko: make_ko.sh 路径 arm64_virt + 签名跳过
- 宿主头 shim (override/third_party): elf.h(hostelf), link.h(ElfW), endian.h, linux/magic.h, sys/statfs.h,
  sys/statfs 双平台, securec.h/securectype.h, hitrace_meter.h, windows.h
- FreeBSD fts.c: sys/statfs.h + linux/magic.h shim
- unwinder 宿主工具: ElfW 大小写修正 (Elf64_Addr)

## 第四轮 (2026-08-12, attempt 463): 构建成功 + 系统启动

### 构建期修复
- **sysmacros.h darwin shim 污染交叉编译** (`override/third_party/sys/sysmacros.h`):
  Darwin 格式 makedev 被 aarch64-linux-ohos 目标编译误用，设备节点 dev 号错乱 (major/minor 编码不同)
  → 按 `__linux__` 区分 Linux/darwin 编码。**这是 switch_root 后设备节点全错的根因。**
- **mesa 22.2.4 在 darwin 上完整重建** (meson cross 配置适配, `scripts/rebuild_mesa.sh`):
  - `src/egl/main/eglapi.c`: 导出 KHR 符号 (eglCreateImageKHR 等, mesa 22.2 默认 static 不导出)
  - 补 glEGLImageTargetTexture2DOES stub
  - `src/panfrost/lib/pan_props.c` 重复定义、`bin/git_sha1_gen.py` git 挂起、expat/zstd 依赖处理
- **mesa3d symlink 缺失**: libEGL.so.1/libGLESv2.so.2/libgbm 等 12 个链接未生成 → 手动补齐

### 运行期修复 (QEMU 启动)
- **/data/storage 目录树缺失** (foundation 建目录失败) → 首次启动前手动初始化 userdata.img
- **CFI 类型表不匹配** (foundation abort): libmmi-client 编译时缺
  `-fsanitize=cfi -fsanitize-cfi-cross-dso` 标志 → 手动重编 (`scripts/rebuild_utd.sh` 同法)
- **UDMF utd_client 线程栈溢出**: InitDescriptors() 470 元素大初始化列表单帧栈 148KB >
  musl 默认线程栈 128KB → 拆分列表 (`foundation/distributeddatamgr/.../preset_type_descriptors.cpp`)
- **appspawn dlopen ace 模块崩溃链** (持续排查中, 见 docs/HANDOVER.md):
  - /system/lib64 缺 platformsdk 库的顶层链接 → 批量创建 459 个 symlink
  - **musl 缺 ANDROID_RELA (packed reloc) 支持**: OHOS 链接用 `--pack-dyn-relocs=android+relr`,
    musl 原本忽略 DT_ANDROID_RELA (0x60000011) → ABS64/GLOB_DAT 重定位全部丢失 → GOT 跳转垃圾。
    新版 musl (`third_party/musl/ldso/linux/dynlink.c`) 已内置解码器但调用 tag 错误 (DT_ANDROID_REL)
    → 改为 DT_ANDROID_RELA 并重建 ldso+libc (`scripts/rebuild_ldso.sh`, `scripts/rebuild_libc.sh`)
  - 剩余: libimage_native 加载时跳转 .dynstr (内存损坏), 待继续排查
- **QEMU 启动**: `scripts/run_qemu.sh` (VNC :21 + 密码 123456, monitor socket /tmp/qemu_mon.sock)

## 第五轮 (2026-08-13, attempt 464+): 应用框架 + 图形栈打通

### appspawn 模块链（从"静默失败"到"全部加载成功"）
- **症状**: 所有 appspawn 模块 dlopen 返回 NULL，dlerror 为空，errno=22 (EINVAL)
- **根因**: 重编 appspawn 时链接命令丢了 `-Wl,--export-dynamic`。OHOS 的模块机制
  要求主程序把 `AddServerStageHook`/`GetAppSpawnMsgInfo`/`AddAppSpawnHook` 等符号
  导出到 .dynsym，模块 dlopen 重定位才能解析；musl 对解析失败**静默 longjmp**（dlerror 为空）
- **修复**: `rebuild_appspawn.sh` 链接参数加 `-Wl,--export-dynamic`
  （也可用官方 version-script: `libappspawn_stub_versionscript.map.txt`）
- **调试方法**: `error_impl()` 直接写 /dev/kmsg（musl 的 `Error relocating ...: symbol not found`
  会打出来，这是最终定位手段）

### Mesa libEGL 补 OHOS wrapper 符号
- **症状**: `Error relocating libappkit_native.z.so: EglSetCacheDir: symbol not found`
- **背景**: 我们早前用 mesa 构建直接顶替了 OHOS 的 libEGL wrapper，wrapper 特有的
  `OHOS::EglSetCacheDir` 符号缺失
- **修复**: `src/egl/main/eglapi.c` 加 stub 并 `__attribute__((visibility("default")))`
  导出（`-fvisibility=hidden` 默认隐藏）
- **注意**: mesa 代码里混用 `%{public}` 格式符（OHOS 风格），标准 vsnprintf 会失败，
  `egllog.c` 加了 sanitize（`%{public}` → `%`）

### Rust std 版本不匹配
- **症状**: `_ZN5alloc7raw_vec17capacity_overflow17h78fe...: symbol not found`
  （libmmi_rust_key_config / libylong_cloud_extension 等）
- **根因**: 镜像 `libstd.dylib.so` 来自 `prebuilts/rustc/linux-x86_64`（官方 Linux 构建），
  但本机构建的 rust 库用的 darwin rustc → 符号 hash 不同
- **修复**: 部署 `prebuilts/rustc/darwin-aarch64/current/lib/rustlib/
  aarch64-unknown-linux-ohos/lib/libstd.dylib.so`

### EGL 初始化失败 (EGL_NOT_INITIALIZED) 排查链
1. **libdrm dev_t 编码**: 旧 libdrm（sysmacros 修复前构建）`major()/minor()` 解析错 →
   `drmGetDevices2` 返回 0 → 用修复后版本重编 `thirdparty/libdrm/libdrm.so` 替换
2. **libdrm.so 搜索路径**: 库在 `system/lib64/chipset-sdk/`，musl 默认搜不到 →
   `system/lib64` 根加软链
3. **CFI 类型表冲突**: OHOS 构建的 `kms_swrast_dri.so`（14MB）带 CFI 检查，
   与无 CFI 的 libEGL 间接调用 → `__cfi_fail_report` → abort (SIGABRT)
   → **rebuild_mesa.sh 改为 `-Dgallium-drivers=swrast -Dllvm=disabled`**
   用自家无 CFI 的 `kms_swrast_dri.so`/`swrast_dri.so` 替换
4. 最终验证: 自写 `test_egl` 工具（`eglInitialize = 1 (1.4)`，Mesa Project）

### 显示输出（进行中）
- **virtio-gpu**: guest 写 /dev/graphics/fb0 读回正确，但 QEMU 侧 VNC/screendump 全黑
  （QEMU 9.2 自编译 与 11.0.3 均复现 → 帧传输/QEMU 显示子系统兼容问题）
- **-vga std**: 帧缓冲显示正常（内核启动文本可见），但 HDI 合成器 `composer_host`
  (hdf_devhost 12) 在 15s 与 render_service 交互时 SIGSEGV → RS 合成无法上屏
- 自写工具: test_egl / test_drm / test_fb（验证 EGL/DRM/fbdev 各层，输出到 /dev/kmsg）

## 第五轮补充 (2026-08-13 晚): 显示输出深挖

### 修复的隐藏问题
- **libFillpSo.open.z.so GNU hash 表损坏**（链接产物 92/109 桶非法）
  → find_sym 的 gnu_lookup 死循环 → 应用进程卡死。修复: 重新链接该库
  （`--hash-style=sysv`，relink_fillp.sh）
- **libfcodec 构造函数在应用进程卡死**（最后一个 ctor 指向 .got 数据区）
  → musl do_init_fini 跳过 fcodec 的 init_array（编解码注册，launcher 不依赖）
- **musl `__tl_lock` fork 继承锁死锁**（构建副本基于 clang_x64 原版恢复后加
  tgkill ESRCH 抢占）

### 定位链（应用进程卡住 → 内核等待）
- 应用 exec /system/bin/appspawn 冷启动 → ldso 加载 400+ 库
- ld-musl ctor(4 个)→ libutils ctor(_GLOBAL__sub_I_mapped_file.cpp)后静默
- 4 个 vCPU 全 wfi(空闲)= 应用进程阻塞在内核(futex_wait)
- dump_wchan 工具（tools/dump_wchan.c）: 应用进程不在主 /proc(疑 PID namespace
  或已退出)，appspawn 未收到 SIGCHLD
- 待续: 需抓应用进程的内核等待点(单个 syscall 断点 / PID ns 内观察)

## 第六轮 (2026-08-14): uid 体系修复 → 应用(launcher)完整启动

### 定位过程(应用"反复 spawn 失败"的真相)
- 应用进程(exec appspawn)一直卡在 `MainThread::Start` 前: 加 pid 级日志(asdbg 带 pid、
  dls2b/dls3/ctor-array 带 pid)后确认应用进程在 `runChildProcessor → RunChildThread` 处
  静默、线程创建(EventRunner)成功但 `GetBundleInfoForSelf` 失败 → exit(0) → ams 每 10 秒重启。
- 两个隐藏的 uid 问题(都是 round4 临时绕过遗留):
  1. **init SetPerms 被整体跳过**(round4 为绕 composer/allocator 挂起) → 服务进程从未
     setuid(全是 root) → binder `sender_euid=0` → installd(`VerifyCallingPermission`
     要求 uid==5523)、bms 权限验证全部失败, `GetCallingUid=0`
  2. **musl setresuid/setresgid 被 bypass**(round4 疑 seccomp 挂起) → 应用进程
     (launcher uid 10007)实际仍 root → `GetBundleInfoForSelf` 用 uid 查 bundle 失败
- 期间还发现: bms 数据库(bmsdb.db)从未写入(稀疏空文件)→ 扫描走"首次启动"路径但
  用户 0 未创建(/data 无 accounts 目录)→ 反复清空 userdata 无效 → 最终由 SetPerms
  恢复(uid 正确)后 bms 入库 + 用户激活(52s)+ 一切打通

### 修复
- **init SetPerms 完整恢复**(setgid/seccomp/setuid/capset/ambient 全部恢复,
  不再 SKIP)。注意: 之前 capset 跳过测试引发 sysrq crash(服务能力缺失), 必须完整恢复。
- **musl setresuid/setresgid 恢复真实 syscall**(移除 bypass)。恢复后不再挂起
  (round4 的挂起根源其实是 uid 体系混乱本身)。
- **appmgr(SA:114)profile 缺失**: 源码 `foundation/ability/ability_runtime/services/sa_profile/`
  只有 180/182/183/184/501.json, 无 114.json → foundation.json 无 appmgr →
  应用连不上 appmgr。修复: 手动向 `packages/phone/system/profile/foundation.json`
  添加 SA 114(libappms.z.so, run-on-create)。
- **usb_host(hdf_devhost) SIGSEGV 空指针崩溃**(无 USB 硬件时) → init 卡 632 秒
  (bootevent 未全触发)。修复: QEMU 加 `-device qemu-xhci`; 并临时在
  hdf_devhost.cfg 禁用 usb_host。
- **bmsdb.db 空文件** → SetPerms 恢复后扫描正常入库(installed_bundle 含
  com.ohos.launcher 完整 JSON)。

### 结果
- launcher 首次完整启动: `LayoutViewModel calculateFolder/calculateForm`(桌面布局渲染)
- systemui / settingsdata 正常运行(binder 活跃)
- launcher 不再反复 spawn; spawn 的进程名确认(AppSpawnProcessMsg 加 proc/pname 日志)

### 本轮新增/更新的工具与脚本
- `tools/dump_wchan.c`: 循环模式(每 60s dump)+ 覆盖 pid 1-1500
- `scripts/cc_dynlink.sh`: 单文件重编 dynlink.o(musl ldso)
- `scripts/rebuild_init2.sh`、`scripts/rebuild_composer_driver.sh`: 已入库
- musl 日志梳理: 去掉 fillp-*/futex-wait 高频日志(拖慢系统), 保留 fwait(pid>=600)
  /dls2b/dls3/ctor-array(带 pid)/dlopen_impl(带 pid)

## 第七轮 (2026-08-14 晚): 显示链路(composer_host)诊断(进行中)

### 状态
- 系统+应用全部正常(launcher/systemui/settingsdata 运行), 但屏幕全黑:
  `display_composer_service not found`(HDI 显示服务未注册, 所有 boot)
- composer_host(hdf_devhost hostId=12)进程存在(主线程 futex_wait + 2 binder 线程),
  但 comm 未变(未 exec 完成?)、无 dls3/无 devhost-dbg ENTRY、无任何 hilog 输出;
  wifi_host/power_host 等其它 host 全部正常(devhost-dbg ENTRY/main/AttachClnt 都有)
- vsync 链路: composer 的 vdi_impl(DRM vsync worker)从未被 dlopen
  (`drmWaitVBlank` 在 virtio-gpu 无 vblank 时永久阻塞)→ RS 合成/显示无 vsync
- RS(render_service)合成日志 `PreProcessLayersComp: layer map is empty, drop this frame`
  (有合成尝试但无图层/无输出)

### 已尝试(无效或回退)
- chipsetsdk 芯片 GPU 库(libGLES_mali/libEGL_impl/libhvgr_v200)缺失 →
  用 mesa(libGLESv2/libEGL)复制替代 → mali dlopen 成功, 但服务仍不注册
- init seccomp 跳过(SetSystemSeccompPolicy)→ 无效
- init capset 跳过 → sysrq crash(panic) → 已回退
- 新库部署(vdi_impl_default/service_1.2/driver_1.0 手动链接):
  - vsync 软件模拟补丁已写入 `drm_vsync_worker.cpp`(drmWaitVBlank 失败时
    usleep(16ms) 模拟 60Hz; 未实际生效因为 vdi_impl 未被加载)
  - 手动链接方法: 从 obj/ 的 .ninja 提取变量编译 + 链接
    (需要补 prebuilts libc++.a/libunwind.a, --start-group 不解决 _Unwind,
     libc++abi.a 的 _Unwind 是 U, 需 libunwind.a)

### 下一步
1. composer_host 的 exec 异常(comm 未变 + 无 ldso 日志)需内核侧确认
   (QEMU gdb / sysrq 阻塞栈), 或对比 SetPerms 跳过(round4)时 composer_host 是否正常
2. 确认 hdf 驱动(libdisplay_composer_driver_1.0)加载机制(preload=0x0 按需加载,
   RS 请求时 devmgr 加载, 但 composer_host 未注册服务)
