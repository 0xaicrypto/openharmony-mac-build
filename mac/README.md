# OpenHarmony 原生 macOS (Apple Silicon) 构建 + 启动

在 macOS (Apple Silicon) 上**原生**编译 OpenHarmony `arm64_virt` 产品 (QEMU 镜像)，
不使用 Linux 虚拟机 / Docker，直接走 Darwin host 工具链 + OHOS 自带 darwin prebuilts。

- 基线版本: OpenHarmony **5.0.3.137** (API 15, `arm64_virt` 产品)
- 主机要求: macOS 13+ on Apple Silicon (arm64)
- 远程仓库: https://github.com/0xaicrypto/openharmony-mac-build

## 当前状态 (2026-08-12)

| 项 | 状态 |
| --- | --- |
| 全量构建 → 镜像产出 | ✅ 成功 (attempt 463) |
| QEMU 启动 → 系统就绪 | ✅ foundation / render_service / wms / appfwk / bms 全部就绪，开机动画完整播放 (VNC) |
| 桌面 (launcher) | ❌ appspawn 加载 ace 模块链时崩溃 (libimage_native dlopen 后跳转 .dynstr)，**当前唯一卡点** |

## 快速开始

```bash
# 1. 安装主机依赖 (brew 包、prebuilts symlink、rust std 下载)
bash .opencode/mac/scripts/setup.sh

# 2. 回放源码修改 (参数: OHOS 源码根目录，默认当前目录)
bash .opencode/mac/scripts/apply_patches.sh /path/to/ohos-src

# 3. 构建 darwin bpftool (仅当 prebuilts/develop_tools/bpftool 缺失时需要)
bash .opencode/mac/scripts/build_bpftool.sh /path/to/ohos-src

# 4. 全量构建
cd /path/to/ohos-src
export PATH=/opt/homebrew/bin:/opt/homebrew/opt/bison/bin:$PATH
./build.sh --product-name arm64_virt --no-prebuilt-sdk
```

## 仓库结构

```
├── README.md                 # 本文档 (总览)
├── docs/
│   ├── PROGRESS.md           # 四轮修复日志 (详细清单)
│   └── HANDOVER.md           # ★ 交接指南: 当前卡点/调试方法/下一步 (新人从这开始)
├── scripts/                  # 构建/重建/启动脚本 (见 scripts/README.md)
├── compat/bpf_stubs/         # darwin 缺失的 Linux 头 stub (libbpf/bpftool 构建用)
├── override/third_party/     # 宿主头 shim (host 编译落 mac SDK 头, 交叉编译落 fallback)
├── prebuilts/                # prebuilts 修补说明 (ark_js, rustc, bpftool)
└── <源码路径镜像>/           # 每个被修改的源码文件: 最终内容
                              #   同名 .applied 空文件 = 标记已回放 (见 apply_patches.sh)
```

**文件回放机制**: 仓库以"OHOS 源码相对路径"镜像被修改的文件，
`scripts/apply_patches.sh` 将其覆盖回源码树 (原版自动备份到 `.opencode/mac-backup/`)。
`.applied` 是空标记文件，仅表示该补丁已被应用，不参与回放。

## 文档导航

- 想知道改了哪些文件、为什么 → `docs/PROGRESS.md`
- 想接手继续开发 (launcher 崩溃) → `docs/HANDOVER.md`
- 想复现构建/重跑脚本 → `scripts/README.md`
