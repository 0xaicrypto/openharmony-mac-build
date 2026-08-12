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
