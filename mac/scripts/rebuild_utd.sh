#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
export DEFINES="$(cat /tmp/utd_defines.txt)"
export INCLUDE_DIRS="$(cat /tmp/utd_include_dirs.txt)"
export CFLAGS="$(cat /tmp/utd_cflags.txt)"
export CFLAGS_CC="$(cat /tmp/utd_cflags_cc.txt)"
CLANGPP=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++

while IFS='|' read -r o k s; do
  [ -z "$o" ] && continue
  /opt/homebrew/bin/ccache $CLANGPP -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_CC -c "$s" -o "$o"
  echo "  $o"
done < /tmp/utd_objs.txt

# link
LDFLAGS="$(cat /tmp/utd_ldflags.txt)"
LIBS="$(cat /tmp/utd_libs.txt)"
IN=$(cat /tmp/utd_link_inputs.txt)
python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split()
objs = [x for x in inp if x.endswith('.o')]
solibs = [x for x in inp if x.endswith('.so')]
libs = [x for x in inp if x.endswith('.a')]
rsp = ['-Wl,--whole-archive'] + objs + ['-Wl,--no-whole-archive'] + libs + solibs
open('/tmp/utd.rsp','w').write('\n'.join(rsp))
print('rsp:', len(objs), 'objs,', len(libs), 'a,', len(solibs), 'so')
PYEOF
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/distributeddatamgr/udmf/libutd_client.z.so" \
  --output="distributeddatamgr/udmf/libutd_client.z.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/distributeddatamgr/udmf/libutd_client.z.so" \
  @/tmp/utd.rsp $LIBS -Wl,-soname="libutd_client.z.so"
echo "=== LINKED ==="
ls -la lib.unstripped/distributeddatamgr/udmf/libutd_client.z.so distributeddatamgr/udmf/libutd_client.z.so
