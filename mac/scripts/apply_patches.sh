#!/bin/bash
# apply_patches.sh - 将 .opencode/mac 镜像中的修改文件回放到 OHOS 源码树
# 用法: bash .opencode/mac/scripts/apply_patches.sh [OHOS_ROOT]
#
# 规则:
#   - .opencode/mac/<relpath>  -> <OHOS_ROOT>/<relpath>   (直接复制覆盖)
#   - 跳过: *.applied (标记文件), README.md, scripts/, compat/
#   - 每次覆盖前把原文件备份到 <OHOS_ROOT>/.opencode/mac-backup/<relpath>

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_DIR="$(cd "${SELF_DIR}/.." && pwd)"
OHOS_ROOT="${1:-$(cd "${MAC_DIR}/.." && pwd)}"
BACKUP_DIR="${OHOS_ROOT}/.opencode/mac-backup"

if [ ! -d "${OHOS_ROOT}/build" ]; then
  echo "错误: ${OHOS_ROOT} 不是有效的 OHOS 源码根目录 (缺少 build/)"
  exit 1
fi

echo "==> MAC_DIR   = ${MAC_DIR}"
echo "==> OHOS_ROOT = ${OHOS_ROOT}"
echo "==> 备份目录  = ${BACKUP_DIR}"

SKIP_SUBDIRS="^(${MAC_DIR}/scripts|${MAC_DIR}/compat)$"
count=0
while IFS= read -r -d '' src; do
  rel="${src#"${MAC_DIR}/"}"
  case "${rel}" in
    *.applied|README.md) continue ;;
  esac
  dst="${OHOS_ROOT}/${rel}"
  mkdir -p "$(dirname "${dst}")"
  if [ -f "${dst}" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "${rel}")"
    cp -f "${dst}" "${BACKUP_DIR}/${rel}"
  fi
  cp -f "${src}" "${dst}"
  echo "  + ${rel}"
  count=$((count+1))
done < <(find "${MAC_DIR}" -type f -not -path "${MAC_DIR}/scripts/*" -not -path "${MAC_DIR}/compat/*" -print0)

echo "==> 已应用 ${count} 个文件 (原版备份于 ${BACKUP_DIR})"
