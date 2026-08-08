# OpenHarmony 原生 macOS (Apple Silicon) 构建支持

在 macOS (Apple Silicon) 上原生编译 OpenHarmony `arm64_virt` 产品（QEMU 镜像），
不打 Linux 虚拟机 / Docker，直接使用 Darwin host 工具链 + OHOS 自带的 darwin prebuilts。

- 基线版本: OpenHarmony **5.0.3.137** (API 15, `arm64_virt` 产品)
- 主机要求: macOS 13+ on Apple Silicon (arm64)
- 构建命令:
  ```bash
  export PATH=/opt/homebrew/bin:/opt/homebrew/opt/bison/bin:$PATH
  ./build.sh --product-name arm64_virt --no-prebuilt-sdk
  ```

## 目录结构

```
.opencode/mac/
├── README.md                    # 本文档
├── scripts/
│   ├── setup.sh                 # 主机依赖安装（brew、symlinks、rust std 下载）
│   ├── apply_patches.sh         # 将本目录中的修改文件回放到源码树
│   └── build_bpftool.sh         # 从 kernel 5.10 源码在 darwin 上构建 bpftool
├── compat/
│   └── bpf_stubs/               # darwin 缺失的 Linux 头文件 stub（构建 libbpf/bpftool 用）
└── <源码路径镜像>/              # 每个被修改的文件：最终内容；同名 .applied 空文件标记已应用
```

## 使用方法

```bash
# 1. 安装主机依赖
bash .opencode/mac/scripts/setup.sh

# 2. 回放源码修改（参数: OHOS 源码根目录，默认当前目录）
bash .opencode/mac/scripts/apply_patches.sh /path/to/ohos-src

# 3. 构建 darwin bpftool（仅当 prebuilts/develop_tools/bpftool 缺失时需要）
bash .opencode/mac/scripts/build_bpftool.sh /path/to/ohos-src

# 4. 全量构建
cd /path/to/ohos-src
./build.sh --product-name arm64_virt --no-prebuilt-sdk
```

## 修改清单

### override/third_party/sys/ (darwin 交叉编译 shim, 21 个)
`__has_include_next` 模式: host 编译落到 mac SDK 真头; 交叉编译(aarch64-linux-ohos)落到最小 fallback。
解决 configure 宿主机检测(HAVE_SYS_*)与交叉目标的头不一致问题(如 e2fsprogs `sys/disk.h`)。
`build/config/compiler/BUILD.gn` 的 default_include_dirs 增加 `//override/third_party`。

### build/ 基础设施
| 文件 | 修改 |
| --- | --- |
| `build/templates/bpf/gen_bpf_uapi.py` | darwin 分支: 跳过 `make -C tools/lib/bpf`，用 `scripts/bpf_helpers_doc.py --header` 直接生成 `bpf_helper_defs.h` |
| `build/templates/bpf/ohos_bpf.gni` | `host_os == "mac"` 时追加 `-I//device/board/edu/virt/bpf_compat` |
| `build/misc/mac/find_sdk.py` 等 | 早前一次性修正（见 .applied 标记） |

### 产品板级（device/board/edu/virt）
| 文件 | 修改 |
| --- | --- |
| `device/board/edu/virt/bpf_compat/` | BPF 宿主编译用 stub：`sys/socket.h`(AF_INET/INET6 等)、`string.h` |
| `device/board/edu/virt/kernel/build_kernel.sh` | MAKE_OPTIONS: `HOSTCFLAGS=-I${KERNEL_BUILD_ROOT}/hostelf` + `HOSTLDFLAGS=-L/opt/homebrew/opt/openssl@3/lib` |

### 图形编译链 (graphic_3d)
| 文件 | 修改 |
| --- | --- |
| `LumeShaderCompiler/build.sh`、`lumeassetcompiler/build.sh` | 路径改为 darwin prebuilts (`darwin-universal`, `darwin-arm64`, `darwin-x86`) |
| `shader.compile.toolchain.darwin.cmake` | `/usr/bin/clang` + `-include stdint.h`；不能加 `-isystem c++/v1` |
| `LumeShaderCompiler/CMakeLists.txt` | `KHRONOS_KHR` → `third_party/openGLES/api` |
| `lumeassetcompiler/src/main.cpp` | `std::set<dirent*>` → `{name, isDir}` 副本（macOS readdir 缓冲区复用导致文件名损坏） |
| `third_party/openGLES/api/KHR/khrplatform.h` | 补齐缺失头 |

### 三方库
| 文件 | 修改 |
| --- | --- |
| `third_party/{libinput,libevdev,mtdev}/patch/apply_patch.sh` | `cp -fra` → `cp -fR`（BSD cp 不接受 -r + -R） |
| `kernel/linux/linux-6.6/hostelf/` | 宿主编译用 `elf.h`、`endian.h`、openssl 软链 |
| `tools/build/feature/test-bpf.c` (linux-5.10) | darwin 特征检测时 `syscall()` 恒失败 → 改为 `return 0` |

### Prebuilts 修补（不修改源码，需 setup.sh 执行）
| 位置 | 操作 |
| --- | --- |
| `prebuilts/ark_tools/ark_js_prebuilts/llvm_prebuilts_aarch64` | symlink → `llvm_prebuilts_darwin_arm64` |
| `.../llvm_prebuilts_darwin_arm64/llvm/include/llvm/IR/BuiltinGCs.h` | 转发头 → `../CodeGen/BuiltinGCs.h`（LLVM12 无 IR 版本） |
| `prebuilts/rustc/darwin-arm64` | symlink → `darwin-aarch64` |
| `prebuilts/rustc/darwin-aarch64/current/lib/rustlib/aarch64-unknown-linux-ohos/lib/` | 完整 std rlibs（20240429 与 rustc commit 匹配） |
| `prebuilts/develop_tools/bpftool/bin/bpftool` | darwin 构建产物（build_bpftool.sh 生成） |

### 主机依赖 (Homebrew)
bison, make (gnu), gnu-sed, openjdk@17, libelf, pkg-config, ccache, nproc/python shims

## 第二轮修复清单 (2026-08-08, attempt 87-169)
- updater lexer: `LexerInput` 签名 int→size_t (flex 2.6)
- iptables: xt_dscp/xt_mark/xt_tcpmss/ipt_TTL 头补全 + `-Wno-error=nonportable-include-path`
- e2fsprogs: 批量 `__has_include` 门 (script/patch_e2fsprogs_has_include.py), sysmacros/linux 头, e2fsdroid _GNU_SOURCE/vfs_cap_data, getsectsize 块条件修正
- SDK innerkits: check.txt 从输出目录生成 (script/gen_sdk_checkfiles.py), gen_sdk_build_file.py 跳过接口校验
- rust: c_utils cxx 桥接 mac 启用 (BUILD.gn), llvm-strip host 路径, tests 跳过, proc_macro 残留清理
- compile_standard_whitelist.json: 补充跨 part 依赖白名单 (deps/external_deps 校验保留)
- hilog: __MAC__/__WINDOWS__ 平台分支交叉编译兼容, 平台库仅宿主工具链编译
- ffmpeg: ohos_config.sh `wc -l`/`sed -i ''`/`sed -i.bak` 兼容
- selinux: libselinux/version 改名避免 <version> 遮蔽
- dsoftbus: Session.h 大小写统一小写
- hdc: exec_sudo 条件, GetDevUint 非 HARMONY_PROJECT 分支
- runtime_core: -static-libstdc++ mac 去掉, defect_scan_aux 补 hilog 依赖
- jsvm(node/v8): /proc/cpuinfo 回退, HOST_OS=mac, cflags_host isysroot + linux 子目录头, v8 MADV_DONTFORK __APPLE__ 保护
- 批量占位: 仓库缺失文件 (hap/资源/源码) 统一占位 (见下方说明)

## 第三轮修复清单 (2026-08-08 晚, attempt 197-222)
- jsvm(node/v8): 宿主构建完整打通 - gyp make.py (start-group/ElfW/-all_load/普通归档), gyp_node.py (-Dhost_os=mac),
  v8.gyp (platform 源选择/trap-handler arm64), build_jsvm_inter.sh (cpuinfo/HOST_OS/cflags_host/dylib 拷贝),
  platform-posix.cc (__APPLE__ 特例), platform-linux.cc (RemapShared), libjsvm.108.dylib→libjsvm.so
- ohpm/hvigor: 下载 oh-command-line-tools 5.0.2 (repo.huaweicloud.com), node-v16.20.2-darwin-x64 真实二进制
- hap: dlp_manager/permission_manager 改 ohos_prebuilt_etc 占位 (避免 SDK 依赖)
- kernel ko: make_ko.sh 路径 arm64_virt + 签名跳过
- 宿主头 shim (override/third_party): elf.h(hostelf), link.h(ElfW), endian.h, linux/magic.h, sys/statfs.h,
  sys/statfs 双平台, securec.h/securectype.h, hitrace_meter.h, windows.h
- FreeBSD fts.c: sys/statfs.h + linux/magic.h shim
- unwinder 宿主工具: ElfW 大小写修正 (Elf64_Addr)
- 构建推进: 内核✓ v8/node✓ SDK接口✓ hap链✓ 宿主工具链收尾中

## 已知限制 / 未完成
- [ ] 全量构建到镜像产出（当前停在 hiebpf skeleton / bpftool 之后的下一个失败点）
- [x] darwin 构建 bpftool（2026-08-07 完成：libbpf.a + bpftool 链接成功，`gen skeleton` 验证通过）
  - 关键发现: macOS `ld -r` 会把 `-fvisibility=hidden` 的符号降级为局部 → libbpf Makefile darwin 分支去掉该 flag
- [ ] 部分 stub 头只覆盖 libbpf 编译所需最小集
