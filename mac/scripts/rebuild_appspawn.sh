#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
export DEFINES="$(cat /tmp/as_defines.txt)"
export INCLUDE_DIRS="$(cat /tmp/as_include_dirs.txt)"
export CFLAGS="$(cat /tmp/as_cflags.txt)"
export CFLAGS_C="$(cat /tmp/as_cflags_c.txt)"
export CFLAGS_CC="$(cat /tmp/as_cflags_cc.txt)"
CLANGPP=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang

while IFS='|' read -r o k s; do
  [ -z "$o" ] && continue
  if [ "$k" = "cxx" ]; then
    /opt/homebrew/bin/ccache $CLANGPP -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_CC -c "$s" -o "$o"
  else
    /opt/homebrew/bin/ccache $CLANG -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c "$s" -o "$o"
  fi
  echo "  $o"
done < /tmp/as_objs.txt

LDFLAGS="$(cat /tmp/as_ldflags.txt)"
LIBS="$(cat /tmp/as_libs.txt)"
IN="$(cat /tmp/as_link_inputs.txt)"
python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split()
objs = [x for x in inp if x.endswith('.o')]
solibs = [x for x in inp if x.endswith('.so')]
libs = [x for x in inp if x.endswith('.a')]
rsp = ['-Wl,--start-group'] + objs + libs + ['-Wl,--end-group'] + solibs
open('/tmp/as.rsp','w').write('\n'.join(rsp))
print('rsp:', len(objs), 'objs,', len(libs), 'a,', len(solibs), 'so')
PYEOF
/usr/bin/env "../../build/toolchain/gcc_link_wrapper.py" \
  --output="startup/appspawn/appspawn" \
  --strip="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip" \
  --unstripped-file="exe.unstripped/startup/appspawn/appspawn" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ $LDFLAGS \
  -o "exe.unstripped/startup/appspawn/appspawn" \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/Scrt1.o obj/third_party/musl/usr/lib/aarch64-linux-ohos/crti.o \
  @/tmp/as.rsp $LIBS \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/crtn.o
echo "=== LINKED ==="
ls -la startup/appspawn/appspawn exe.unstripped/startup/appspawn/appspawn
