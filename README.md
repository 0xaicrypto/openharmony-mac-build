# OpenHarmony macOS 构建与系统镜像 (macOS-on-OHOS)

在 macOS (Apple Silicon) 上原生构建 OpenHarmony `arm64_virt` 产品并启动到系统。
本仓库同时收录构建所需的 SDK 头文件与全部 macOS 适配补丁。

## 仓库结构

```
├── README.md                    # 本文件 (仓库总入口)
├── mac/                         # ★ 主要工作目录: 构建适配补丁集
│   ├── README.md                # 项目总览: 状态/快速开始/结构图
│   ├── docs/
│   │   ├── PROGRESS.md          # 四轮修复日志
│   │   └── HANDOVER.md          # 交接指南: 当前卡点/调试方法/下一步
│   ├── scripts/                 # 安装/回放/重建/启动脚本
│   └── <源码路径镜像>/          # 每个被修改源码文件的最终内容
└── interface/innersdk/native/   # OHOS SDK 头文件 (arm64_virt 构建所需)
```

## 当前状态 (2026-08-12)

- 全量构建 ✅ 镜像产出 ✅ 系统启动 ✅ (核心服务就绪, 开机动画播放, VNC 查看)
- 唯一卡点: 桌面 launcher 未孵化 (appspawn dlopen ace 模块崩溃), 排查中
- 详见 `mac/docs/HANDOVER.md`

## 上手

```bash
# 回放补丁到 OHOS 源码树后全量构建 (详见 mac/README.md)
bash mac/scripts/apply_patches.sh /path/to/ohos-src
cd /path/to/ohos-src && ./build.sh --product-name arm64_virt --no-prebuilt-sdk
```
