#!/bin/bash
# setup.sh - 安装 macOS 构建 OpenHarmony 所需的主机依赖
# 用法: bash .opencode/mac/scripts/setup.sh [OHOS_ROOT]
# OHOS_ROOT 默认 = 脚本所在仓库的上级上级 (即 .opencode 的父目录)

set -euo pipefail

OHOS_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
echo "==> OHOS_ROOT = ${OHOS_ROOT}"

# ---------- 1. Homebrew 依赖 ----------
PACKAGES="bison make gnu-sed openjdk@17 libelf pkg-config ccache"
echo "==> 安装 Homebrew 包: ${PACKAGES}"
brew install ${PACKAGES} 2>/dev/null || {
  echo "brew install 失败，请手动安装: ${PACKAGES}"
  exit 1
}

# python3 shim (ohos 构建脚本需要 python 别名)
if ! command -v python >/dev/null 2>&1; then
  echo "==> 创建 python -> python3 软链"
  sudo ln -sf "$(command -v python3)" /usr/local/bin/python || true
fi

# ---------- 2. Prebuilts symlinks ----------
ARK_DIR="${OHOS_ROOT}/prebuilts/ark_tools/ark_js_prebuilts"
RUST_DIR="${OHOS_ROOT}/prebuilts/rustc"

echo "==> LLVM prebuilts symlink (arm64 目标编译用 darwin 工具链头)"
if [ ! -e "${ARK_DIR}/llvm_prebuilts_aarch64" ]; then
  ln -sf llvm_prebuilts_darwin_arm64 "${ARK_DIR}/llvm_prebuilts_aarch64"
fi

echo "==> LLVM12 BuiltinGCs.h 转发头"
LLVM_INC="${ARK_DIR}/llvm_prebuilts_darwin_arm64/llvm/include/llvm/IR"
if [ ! -e "${LLVM_INC}/BuiltinGCs.h" ]; then
  printf '#include "../CodeGen/BuiltinGCs.h"\n' > "${LLVM_INC}/BuiltinGCs.h"
fi

echo "==> rustc darwin-arm64 symlink"
if [ ! -e "${RUST_DIR}/darwin-arm64" ]; then
  ln -sf darwin-aarch64 "${RUST_DIR}/darwin-arm64"
fi

# ---------- 3. rust std rlibs 下载 (需与 rustc commit 匹配) ----------
RUSTLIB="${RUST_DIR}/darwin-aarch64/current/lib/rustlib/aarch64-unknown-linux-ohos/lib"
RUSTC_VER="$("${RUST_DIR}/darwin-aarch64/current/bin/rustc" --version 2>/dev/null || echo unknown)"
echo "==> rustc 版本: ${RUSTC_VER}"
if [ "$(ls "${RUSTLIB}" 2>/dev/null | wc -l | tr -d ' ')" -lt 10 ]; then
  echo "==> 下载 OHOS aarch64 std rlibs (20240429)"
  TMP=$(mktemp -d)
  curl -fL -o "${TMP}/std.tgz" \
    "https://repo.huaweicloud.com/harmonyos/compiler/rust/20240429/rust-std-nightly-aarch64-unknown-linux-ohos_20240429.tar.gz"
  tar -xzf "${TMP}/std.tgz" -C "${TMP}"
  STDDIR=$(find "${TMP}" -type d -name 'aarch64-unknown-linux-ohos' | head -1)
  if [ -n "${STDDIR}" ]; then
    mkdir -p "${RUSTLIB}"
    cp "${STDDIR}"/lib/*.rlib "${RUSTLIB}"/
  fi
  rm -rf "${TMP}"
fi

echo "==> 验证: rustc --target aarch64-unknown-linux-ohos --emit=metadata"
printf 'fn main(){}\n' > /tmp/_rust_check.rs
"${RUST_DIR}/darwin-aarch64/current/bin/rustc" --crate-type staticlib \
  --target aarch64-unknown-linux-ohos --emit=metadata -o /tmp/_rust_check.rmeta /tmp/_rust_check.rs
rm -f /tmp/_rust_check.rs /tmp/_rust_check.rmeta

echo "==> setup.sh 完成"
