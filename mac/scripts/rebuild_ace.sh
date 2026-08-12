#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
CLANGPP=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
export DEFINES="$(cat /tmp/ace_defines.txt)" INCLUDE_DIRS="$(cat /tmp/ace_include_dirs.txt)"
export CFLAGS="$(cat /tmp/ace_cflags.txt)" CFLAGS_C="$(cat /tmp/ace_cflags_c.txt)" CFLAGS_CC="$(cat /tmp/ace_cflags_cc.txt)"
while IFS='|' read -r o k s; do
  [ -z "$o" ] && continue
  if [ "$k" = "cxx" ]; then
    /opt/homebrew/bin/ccache $CLANGPP -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_CC -c "$s" -o "$o"
  else
    /opt/homebrew/bin/ccache $CLANG -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c "$s" -o "$o"
  fi
done < /tmp/ace_objs.txt
echo "objects done"

LDFLAGS="$(cat /tmp/ace_ldflags.txt)" LIBS="$(cat /tmp/ace_libs.txt)" IN="$(cat /tmp/ace_link.txt)"
python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split()
open('/tmp/ace.rsp','w').write('\n'.join(['-Wl,--whole-archive'] + inp + ['-Wl,--no-whole-archive']))
print('rsp:', len(inp))
PYEOF
mkdir -p startup/appspawn lib.unstripped/startup/appspawn
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/startup/appspawn/libappspawn_ace.z.so" \
  --output="startup/appspawn/libappspawn_ace.z.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/startup/appspawn/libappspawn_ace.z.so" @/tmp/ace.rsp $LIBS -Wl,-soname="libappspawn_ace.z.so"
echo "=== LINKED ==="
ls -la startup/appspawn/libappspawn_ace.z.so
