#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
DEFINES="$(cat /tmp/in_defines.txt)"
INCLUDE_DIRS="$(cat /tmp/in_include_dirs.txt)"
CFLAGS="$(cat /tmp/in_cflags.txt)"
CFLAGS_C="$(cat /tmp/in_cflags_c.txt)"
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
/opt/homebrew/bin/ccache $CLANG -MMD -MF obj/base/startup/init/services/init/init/init_common_service.o.d $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c ../../base/startup/init/services/init/init_common_service.c -o obj/base/startup/init/services/init/init/init_common_service.o
echo "init_common_service.o compiled"
LDFLAGS="$(cat /tmp/in_ldflags.txt)"
LIBS="$(cat /tmp/in_libs.txt)"
IN="$(cat /tmp/in_link.txt)"
# extract .o and .so inputs
python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split(': link ', 1)[1]
inp = inp.split(' || ')[0]
parts = inp.split()
objs = [x for x in parts if x.endswith('.o')]
solibs = [x for x in parts if x.endswith('.so')]
libs = [x for x in parts if x.endswith('.a')]
rsp = ['-Wl,--start-group'] + objs + libs + ['-Wl,--end-group'] + solibs
open('/tmp/init.rsp','w').write('\n'.join(rsp))
print('objs:', len(objs), 'libs:', len(libs), 'so:', len(solibs))
PYEOF
/usr/bin/env "../../build/toolchain/gcc_link_wrapper.py" \
  --output="startup/init/init" \
  --strip="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip" \
  --unstripped-file="exe.unstripped/startup/init/init" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ $LDFLAGS \
  -o "exe.unstripped/startup/init/init" \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/Scrt1.o obj/third_party/musl/usr/lib/aarch64-linux-ohos/crti.o \
  @/tmp/init.rsp $LIBS obj/third_party/musl/usr/lib/aarch64-linux-ohos/crtn.o
echo "=== LINKED ==="
ls -la startup/init/init
