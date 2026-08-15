# OpenHarmony macOS 构建与系统镜像 (macOS-on-OHOS)

在 macOS (Apple Silicon) 上原生构建 OpenHarmony `arm64_virt` 产品并启动到系统。
本仓库收录全部 macOS 适配补丁与构建文档，任何人的 Mac 都可以按 README 复现。

## 当前状态 (2026-08-14)

- 全量构建 ✅ 系统启动 ✅ 应用框架 ✅ **应用完整运行** ✅
  (launcher 启动并渲染桌面布局, systemui/settingsdata 正常运行, uid 体系修复)
- EGL 软件渲染 ✅ (Mesa swrast)
- 显示输出 ⚠️ 进行中: HDI 显示服务 display_composer_service 未注册(composer_host
  host attach 成功但服务未发布, 疑驱动 LoadVdiSo/构造失败), 屏幕黑;
  virtio-gpu 帧传输不上屏

## 仓库结构

```
├── README.md                    # 仓库入口 (总览 + 状态)
├── mac/                         # ★ 主要工作目录
│   ├── README.md                # 完整 build 流程 (从零开始)
│   ├── docs/
│   │   ├── PROGRESS.md          # 七轮修复日志
│   │   └── HANDOVER.md          # 交接指南: 当前卡点/调试方法
│   ├── scripts/                 # 安装/回放/重建/启动脚本
│   └── <源码路径镜像>/          # 被修改源码文件的最终内容
└── interface/innersdk/native/   # OHOS SDK 头文件
```

## 快速开始

```bash
# 1. 回放补丁到 OHOS 5.0.3 源码树 (完整步骤见 mac/README.md)
bash mac/scripts/apply_patches.sh /path/to/ohos-src

# 2. 全量构建
cd /path/to/ohos-src && ./build.sh --product-name arm64_virt --no-prebuilt-sdk

# 3. QEMU 启动 (VNC: vnc://localhost:5921, 密码 123456)
bash mac/scripts/run_qemu.sh
```
