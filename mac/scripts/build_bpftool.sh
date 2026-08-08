#!/bin/bash
# build_bpftool.sh - 在 macOS 上从 kernel 5.10 源码构建 bpftool
#
# 背景: OHOS 的 prebuilts/develop_tools/bpftool 只提供 Linux 二进制，
# 构建 hiebpf 骨架 (gen_skeleton.sh) 需要在宿主机跑 `bpftool gen skeleton`。
# 这里复刻 Linux 工具链的 feature 检测与编译，用 compat/bpf_stubs 补齐
# macOS 缺失的 Linux 头文件。
#
# 用法: bash .opencode/mac/scripts/build_bpftool.sh [OHOS_ROOT] [OUT_BPFTOOL]

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_DIR="$(cd "${SELF_DIR}/.." && pwd)"
STUBS="${MAC_DIR}/compat/bpf_stubs"
OHOS_ROOT="${1:-$(cd "${MAC_DIR}/.." && pwd)}"
OUT_BPFTOL="${2:-${OHOS_ROOT}/prebuilts/develop_tools/bpftool/bin/bpftool}"

K510="${OHOS_ROOT}/kernel/linux/linux-5.10"
HOSTELF="${OHOS_ROOT}/kernel/linux/linux-6.6/hostelf"
UAPI="${OHOS_ROOT}/out/arm64_virt/obj/build/templates/bpf/aarch64-linux-ohos/usr/include"
if [ ! -d "${UAPI}" ]; then
  echo "错误: UAPI 头目录不存在，请先构建过 bpf 目标: ${UAPI}"
  exit 1
fi
LIBELF_INC="/opt/homebrew/opt/libelf/include"
LIBELF_LIB="/opt/homebrew/opt/libelf/lib"

if [ ! -d "${K510}/tools/lib/bpf" ]; then
  echo "错误: ${K510}/tools/lib/bpf 不存在"
  exit 1
fi

COMMON_FLAGS="-I${STUBS} -I${K510}/tools/include -I${K510}/tools/include/uapi -I${UAPI} -I${HOSTELF} -I${LIBELF_INC} -I${LIBELF_INC}/libelf \
 -include ${STUBS}/extras.h -DEUCLEAN=117 \
 -Wno-deprecated-declarations -Wno-unused-parameter -Wno-macro-redefined \
 -Wno-implicit-function-declaration -Wno-nullability-completeness -Wno-visibility \
 -D__LIBELF_INTERNAL__=0 -D__LIBELF_NEED_LINK_H=0 -D__LIBELF_NEED_SYS_LINK_H=0"
COMMON_LDFLAGS="-L${LIBELF_LIB} -lelf"

# ---------- 1. feature test: darwin 上 syscall() 恒失败，改为返回 0 ----------
FEATURE_T="${K510}/tools/build/feature/test-bpf.c"
if ! grep -q "return 0;" "${FEATURE_T}"; then
  echo "==> patch ${FEATURE_T}: syscall() 结果不再作为 feature 判定"
  python3 - "${FEATURE_T}" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace(
    "return syscall(__NR_bpf, BPF_PROG_LOAD, &attr, sizeof(attr));",
    "syscall(__NR_bpf, BPF_PROG_LOAD, &attr, sizeof(attr));\n\treturn 0;")
open(p, "w").write(s)
EOF
fi

# ---------- 2. 构建 libbpf.a ----------
echo "==> 构建 libbpf.a"
make -C "${K510}/tools/lib/bpf" clean >/dev/null 2>&1 || true
make -C "${K510}/tools/lib/bpf" \
  EXTRA_CFLAGS="${COMMON_FLAGS}" \
  LDFLAGS="${COMMON_LDFLAGS}" 2>&1 | tee /tmp/libbpf-build.log
if [ ! -f "${K510}/tools/lib/bpf/libbpf.a" ]; then
  echo "错误: libbpf.a 构建失败，见 /tmp/libbpf-build.log"
  exit 1
fi

# ---------- 3. 构建 bpftool ----------
echo "==> 构建 bpftool"
make -C "${K510}/tools/bpf/bpftool" clean >/dev/null 2>&1 || true
make -C "${K510}/tools/bpf/bpftool" \
  EXTRA_CFLAGS="${COMMON_FLAGS}" \
  LDFLAGS="${COMMON_LDFLAGS}" 2>&1 | tee /tmp/bpftool-build.log

BPFTOOL_BIN=$(find "${K510}/tools/bpf/bpftool" -maxdepth 2 -name "bpftool" -type f | head -1)
if [ -z "${BPFTOOL_BIN}" ]; then
  echo "错误: 未找到 bpftool 产物，见 /tmp/bpftool-build.log"
  exit 1
fi

# ---------- 4. 安装到 prebuilts ----------
echo "==> 安装到 ${OUT_BPFTOL}"
mkdir -p "$(dirname "${OUT_BPFTOL}")"
cp -f "${BPFTOOL_BIN}" "${OUT_BPFTOL}"

echo "==> 验证"
"${OUT_BPFTOL}" gen skeleton --help >/dev/null 2>&1 || "${OUT_BPFTOL}" gen skeleton 2>&1 | head -2 || true
echo "==> build_bpftool.sh 完成: ${OUT_BPFTOL}"
