#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
LDFLAGS="$(cat /tmp/fp_ldflags.txt)"
LIBS="$(cat /tmp/fp_libs.txt)"
IN="$(cat /tmp/fp_link.txt)"
python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split(': solink ', 1)[1]
inp = inp.split(' || ')[0]
parts = inp.split()
objs = [x for x in parts if x.endswith('.o')]
solibs = [x for x in parts if x.endswith('.so')]
libs = [x for x in parts if x.endswith('.a')]
rsp = ['-Wl,--start-group'] + objs + libs + ['-Wl,--end-group'] + solibs
open('/tmp/fp.rsp','w').write('\n'.join(rsp))
print('objs:', len(objs), 'libs:', len(libs), 'so:', len(solibs))
PYEOF
# replace hash-style=gnu with sysv in ldflags
LDFLAGS="${LDFLAGS//--hash-style=gnu/--hash-style=sysv}"
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/communication/dsoftbus/libFillpSo.open.z.so" \
  --output="communication/dsoftbus/libFillpSo.open.z.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/communication/dsoftbus/libFillpSo.open.z.so" \
  @/tmp/fp.rsp $LIBS
echo "=== LINKED ==="
ls -la communication/dsoftbus/libFillpSo.open.z.so
