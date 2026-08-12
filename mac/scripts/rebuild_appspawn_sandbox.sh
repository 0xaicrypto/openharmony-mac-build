#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
export DEFINES="$(cat /tmp/asb_defines.txt)"
export INCLUDE_DIRS="$(cat /tmp/asb_include_dirs.txt)"
export CFLAGS="$(cat /tmp/asb_cflags.txt)"
export CFLAGS_CC="$(cat /tmp/asb_cflags_cc.txt)"
CLANGPP=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++

while IFS='|' read -r o k s; do
  [ -z "$o" ] && continue
  if [ "$k" = "cxx" ]; then
    /opt/homebrew/bin/ccache $CLANGPP -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_CC -c "$s" -o "$o"
  else
    CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
    CFLC=$(cat /tmp/asb_cflags_c.txt 2>/dev/null || echo "--sysroot=obj/third_party/musl")
    /opt/homebrew/bin/ccache $CLANG -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLC -c "$s" -o "$o"
  fi
  echo "  $o"
done < /tmp/asb_objs.txt

LDFLAGS="$(cat /tmp/asb_ldflags.txt)"
LIBS="$(cat /tmp/asb_libs.txt)"
IN="$(cat /tmp/asb_link_inputs.txt)"
python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split()
objs = [x for x in inp if x.endswith('.o')]
solibs = [x for x in inp if x.endswith('.so')]
libs = [x for x in inp if x.endswith('.a')]
rsp = ['-Wl,--whole-archive'] + objs + ['-Wl,--no-whole-archive'] + libs + solibs
open('/tmp/asb.rsp','w').write('\n'.join(rsp))
print('rsp:', len(objs), 'objs,', len(libs), 'a,', len(solibs), 'so')
PYEOF
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/appspawn/common/libappspawn_sandbox.z.so" \
  --output="appspawn/common/libappspawn_sandbox.z.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/appspawn/common/libappspawn_sandbox.z.so" \
  @/tmp/asb.rsp $LIBS -Wl,-soname="libappspawn_sandbox.z.so"
echo "=== LINKED ==="
ls -la appspawn/common/libappspawn_sandbox.z.so 2>/dev/null || ls -la lib.unstripped/appspawn/common/libappspawn_sandbox.z.so
