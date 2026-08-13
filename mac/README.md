# OpenHarmony 原生 macOS (Apple Silicon) 构建 + 启动

在 macOS (Apple Silicon) 上**原生**编译并启动 OpenHarmony `arm64_virt` 产品，
不使用 Linux 虚拟机 / Docker。直接使用 Darwin host 工具链 + OHOS 自带 darwin prebuilts，
产物为 QEMU 可启动的完整镜像（system/vendor/userdata 等）。

- 基线版本: **OpenHarmony 5.0.3.137** (API 15, `arm64_virt`)
- 主机要求: macOS 13+ / Apple Silicon (arm64)，建议 ≥ 32GB 内存、≥ 200GB 磁盘
- 远程仓库: https://github.com/0xaicrypto/openharmony-mac-build

---

## 当前状态 (2026-08-13)

| 项 | 状态 |
| --- | --- |
| 全量构建 → 镜像产出 | ✅ 完成 (attempt 463) |
| 系统启动 (QEMU) | ✅ foundation/render_service/wms/appfwk/bms 全部就绪 |
| 应用框架 (appspawn) | ✅ 模块加载、launcher/lockscreen `bootevent` ready、应用正常 spawn |
| EGL 图形栈 | ✅ Mesa 22.2.4 软件渲染 (swrast) 初始化成功 (EGL 1.4) |
| 屏幕输出 | ⚠️ **部分**：`-vga std` 下内核文本/帧缓冲可见；但 HDI 合成器 `composer_host` 崩溃导致桌面 UI 未上屏（virtio-gpu 下 QEMU 侧帧传输亦不正常） |

> 即：**系统完整运行、应用可启动，最后差"合成器把桌面画到屏幕上"这一步**。

---

## 原理

OpenHarmony 官方只支持 Linux 构建。本方案的核心思路：

1. **darwin prebuilts 优先**：OHOS 5.0.3 自带 `prebuilts/clang/ohos/darwin-arm64` 等
   Darwin 主机工具链，交叉编译 `aarch64-linux-ohos` 目标（clang 指定
   `--target=aarch64-linux-ohos`）。
2. **宿主头 shim**：Darwin 宿主编译 (configure/feature 检测) 需要 Linux 头，仓库提供
   `override/third_party` + `compat/` 两套 shim，按 `__has_include_next` 区分宿主/目标。
3. **本仓库 = 补丁集**：以"OHOS 源码相对路径"镜像所有被修改的文件，
   `scripts/apply_patches.sh` 一键回放，回放后可独立构建。

---

## 在自己的机器上构建（完整步骤）

### 0. 前置准备

```bash
# 安装 Homebrew 依赖（含 python3、ninja、ccache 等构建工具）
brew install python3 ninja ccache bison make gnu-sed openjdk@17 libelf pkg-config
export PATH=/opt/homebrew/bin:/opt/homebrew/opt/bison/bin:$PATH
```

### 1. 拉取 OpenHarmony 源码（官方 5.0.3 分支）

```bash
mkdir -p ~/ohos && cd ~/ohos
# 使用官方 repo 工具（repo 从 gitee 拉取全量 manifest）
repo init -u https://gitee.com/openharmony/manifest.git \
  -b OpenHarmony-5.0.3-Release --no-repo-verify
repo sync -c -j8
```

> 源码约 80GB+（含 git 历史）。若只需构建，也可用 `--depth 1` 浅克隆加速。

### 2. 回放本仓库补丁

```bash
# 将本仓库克隆到源码树内
cd ~/ohos
git clone https://github.com/0xaicrypto/openharmony-mac-build.git .opencode/mac

# 执行一次环境初始化（prebuilts symlink、rust std、brew 依赖说明等）
bash .opencode/mac/scripts/setup.sh

# 回放全部源码修改（原文件自动备份到 .opencode/mac-backup/）
bash .opencode/mac/scripts/apply_patches.sh ~/ohos
```

### 3. 全量构建

```bash
cd ~/ohos
./build.sh --product-name arm64_virt --no-prebuilt-sdk
```

- 构建约 2–6 小时（取决于机器），产物在 `out/arm64_virt/packages/phone/images/`。
- 构建失败点、以及各轮修复内容见 `docs/PROGRESS.md`。
- 需要 **prebuilt SDK**（`arm64_virt` 通常需要）时去掉 `--no-prebuilt-sdk` 参数。

### 4. 启动（QEMU）

```bash
bash .opencode/mac/scripts/run_qemu.sh
```

- 串口日志输出到终端；VNC 桌面: `vnc://localhost:5921`，密码 `123456`
  （启动后通过 monitor socket 设置：`echo 'change vnc password 123456' |
  socat - UNIX-CONNECT:/tmp/qemu_mon.sock`）。
- 显示器建议用 `-vga std`（QEMU 9/11 下 virtio-gpu 的帧传输有兼容问题，
  见 `docs/HANDOVER.md` §7 显示输出排查）。

---

## 完整修复历程（五轮）

> 详细清单见 `docs/PROGRESS.md`。以下是"为什么会失败、修了什么"的摘要，
> 新机器构建遇到同样错误时直接对照。

### 第一轮 — 构建基础设施 (2026-08-07)
- **宿主头 shim 体系**：`override/third_party`（sys/statfs、endian 等 21 个）
- **bpftool darwin 构建**：`ld -r` 的 visibility 问题、bpf uapi 生成跳过 `make`
- 图形编译链 (LumeShaderCompiler)、三方库 patch 脚本的 BSD `cp` 兼容

### 第二轮 — 编译中段 (2026-08-08)
- e2fsprogs/iptables/updater 等 `__has_include` 与头文件修补
- rust cxx 桥接、SDK check 文件生成、白名单补充

### 第三轮 — 宿主工具链收尾 (2026-08-08)
- jsvm (node/v8) Darwin 宿主构建全打通
- ohpm/hvigor 真实二进制、hap 占位、内核 ko 构建

### 第四轮 — 构建成功 + 系统启动 (2026-08-12)
- **sysmacros 双平台修复**（dev_t 编码，修复前设备节点全错）
- mesa 22.2.4 darwin 重建（KHR 符号导出）
- CFI 类型表不匹配（libmmi-client 补 `-fsanitize=cfi -fsanitize-cfi-cross-dso`）
- UDMF 线程栈溢出（InitDescriptors 列表拆分）
- **musl 动态链接器 ANDROID_RELA 支持**（OHOS 用 `--pack-dyn-relocs=android+relr`，
  老 musl 忽略 `DT_ANDROID_RELA` → 全部 ABS64/GLOB_DAT 重定位丢失；改为
  `do_android_relocs(p, DT_ANDROID_RELA, DT_ANDROID_RELASZ)`）

### 第五轮 — 应用框架与图形栈 (2026-08-13)
- **appspawn 模块 dlopen 静默失败**（EINVAL）→ 根因：重编 appspawn 时丢了
  `--export-dynamic`，主程序不导出 `AddServerStageHook` 等符号 → 链接补回
- **`EglSetCacheDir` 符号缺失** → mesa `eglapi.c` 补 OHOS wrapper 符号 stub
  （`visibility("default")` 导出，同时进 `src/egl` 导出表）
- **Rust std 符号不匹配**（`capacity_overflow` hash 不同）→ 镜像里
  `libstd.dylib.so` 换成 `prebuilts/rustc/darwin-aarch64/.../libstd.dylib.so`
  （构建时用的是 darwin rustc，符号 hash 必须匹配 darwin 版 std）
- **EGL 初始化失败**（EGL_NOT_INITIALIZED）三连：
  1. `libdrm` 用了旧 sysmacros（dev_t 编码错 → `drmGetDevices2` 返回 0）
     → 用修复后版本重编替换
  2. `libdrm.so` 在 `chipset-sdk` 子目录，musl 搜索不到 → `system/lib64` 根加软链
  3. OHOS 构建的 `kms_swrast_dri.so` 带 CFI → 与无 CFI 的 libEGL 间接调用
     触发 `__cfi_fail_report` abort → **用自家构建的无 CFI swrast 驱动替换**
     （`rebuild_mesa.sh` 改为 `-Dgallium-drivers=swrast`）
- **显示输出**（未完成）：virtio-gpu 下 QEMU 侧帧传输不上屏（QEMU 9/11 均复现）；
  `-vga std` 下帧缓冲正常但 HDI 合成器 `composer_host` SIGSEGV。

---

## 调试工作流（改一处 → 验证）

```bash
# 重建单个目标（变量提取自对应 .ninja，不跑全量构建）
bash scripts/rebuild_ldso.sh          # musl ldso .o
bash scripts/rebuild_libc.sh          # 重链 libc.so（含 ldso）
bash scripts/rebuild_appspawn.sh      # appspawn（含 --export-dynamic）
bash scripts/rebuild_mesa.sh          # mesa（swrast 软件渲染）

# 部署到镜像树 + 重建 system.img（命令模板见 docs/HANDOVER.md §6）
cp out/arm64_virt/obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so \
   out/arm64_virt/packages/phone/system/lib/ld-musl-aarch64.so.1

# 重启 QEMU 验证（日志 /tmp/ohos_bootNN.log）
pkill -9 -f qemu-system; sleep 1
python3 .opencode/mac/scripts/start_qemu_bg.py /tmp/ohos_bootN.log   # 或直接 run_qemu.sh
grep -E "bootevent.launcher.ready|SIGSEGV" /tmp/ohos_bootN.log
```

---

## 仓库结构

```
├── README.md                 # 本文件（总览 + 完整流程）
├── docs/
│   ├── PROGRESS.md           # 五轮修复详细日志
│   └── HANDOVER.md           # ★ 交接指南：当前卡点/调试方法/下一步
├── scripts/                  # 安装/回放/重建/启动脚本（见 scripts/README.md）
├── compat/bpf_stubs/         # darwin 缺失的 Linux 头 stub
├── override/third_party/     # 宿主头 shim
└── <源码路径镜像>/            # 每个被修改源码文件的最终内容
                                # 同名 .applied 空文件 = 已回放标记
```

## 文档导航

- 想知道每轮改了哪些文件、为什么 → `docs/PROGRESS.md`
- 想接手继续开发（合成器/显示输出）→ `docs/HANDOVER.md`
- 想复现构建/重跑脚本 → `scripts/README.md`
