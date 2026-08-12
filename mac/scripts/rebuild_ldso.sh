#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
export DEFINES="$(cat /tmp/ldso_defines.txt) " INCLUDE_DIRS="$(cat /tmp/ldso_include_dirs.txt)"
export CFLAGS="$(cat /tmp/ldso_cflags.txt)" CFLAGS_C="$(cat /tmp/ldso_cflags_c.txt)"
while IFS='|' read -r o s; do
  [ -z "$o" ] && continue
  /opt/homebrew/bin/ccache $CLANG -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c "$s" -o "$o"
  echo "  $o"
done < /tmp/ldso_objs.txt
echo "ldso objects done"
