# scripts/ 说明

所有脚本在 macOS (Apple Silicon) 上运行。`/tmp/rebuild_*.sh` 是**本机调试工作流**的临时副本，
与仓库脚本内容一致（`cp /tmp/rebuild_*.sh scripts/` 同步）。

## 构建/环境

| 脚本 | 用途 |
| --- | --- |
| `setup.sh` | 主机依赖安装：brew 包 (bison/make/gnu-sed/openjdk@17/libelf/pkg-config/ccache)、prebuilts symlink (ark_js/rustc)、rust std rlibs 下载 |
| `apply_patches.sh` | 将本仓库镜像的源码修改回放到 OHOS 源码树（原版备份到 `.opencode/mac-backup/`） |
| `build_bpftool.sh` | 从 kernel 5.10 源码在 darwin 构建 bpftool（libbpf.a + bpftool + gen skeleton 验证） |
| `patch_e2fsprogs_has_include.py` | 批量给 e2fsprogs 加 `__has_include` 门（darwin 缺失的 Linux 头） |
| `gen_sdk_checkfiles.py` | 从输出目录生成 SDK innerkits check.txt（替代缺失的官方检查文件） |

## 重建（调试循环，见 docs/HANDOVER.md §6）

> 变量提取自 `out/arm64_virt/obj/<part>/<target>.ninja`，只编译目标本身，不跑全量构建。
> 产物部署 + 镜像重建命令见 HANDOVER.md。

| 脚本 | 重建目标 | 备注 |
| --- | --- | --- |
| `rebuild_ldso.sh` | musl 动态链接器 8 个 .o | **必须**在 rebuild_libc.sh 之前跑 |
| `rebuild_libc.sh` | libc.so (含 ldso) | 产物 → `system/lib/ld-musl-aarch64.so.1` |
| `rebuild_appspawn.sh` | appspawn | 含 ASDBG/TESTDL/PREDLOPEN 调试插桩（成功后清理） |
| `rebuild_appspawn_common.sh` | appspawn common 库 | |
| `rebuild_appspawn_sandbox.sh` | appspawn sandbox 库 | |
| `rebuild_begetutil.sh` | libbegetutil.z.so | 完整 358 导出（含 libsocket.a 等 23 个静态库） |
| `rebuild_init.sh` | init | |
| `rebuild_mesa.sh` | mesa 22.2.4 (darwin 交叉) | KHR 符号导出 + symlink 补齐 |
| `rebuild_utd.sh` | libutd_client | CFI 标志 + 栈拆分后一般无需再动 |
| `rebuild_ace.sh` | ace 引擎库 | |

## 运行

| 脚本 | 用途 |
| --- | --- |
| `run_qemu.sh` | 启动 QEMU (arm64_virt 镜像)：VNC :21 (密码 123456)、monitor socket `/tmp/qemu_mon.sock`、`/tmp/ohos_boot*.log` |
