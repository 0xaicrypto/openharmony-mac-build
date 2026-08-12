#!/bin/bash
# Rebuild libappspawn_common.z.so + libappspawn_helper.z.so + appspawn
set -e
cd /Users/hui/ohos-src/out/arm64_virt
CLANGPP=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang

rebuild_so() { # $1=ninja  $2=output_dir  $3=output_name
  local N=$1 OUT=$2 NAME=$3
  python3 - "$N" "$OUT" "$NAME" <<'PYEOF'
import re, sys
N, OUT, NAME = sys.argv[1:4]
txt = open(N).read()
def getvar(name):
    m = re.search(r'^%s = (.*?)$' % name, txt, re.M)
    return m.group(1).replace('$$','$') if m else ''
for k in ['defines','include_dirs','cflags','cflags_c','cflags_cc']:
    open('/tmp/so_%s.txt'%k,'w').write(getvar(k))
objs = re.findall(r'^build (obj/base/startup/appspawn[^ |]*\.o): (cxx|cc) (\.\./\.\./[^ |]+) \|', txt, re.M)
open('/tmp/so_objs.txt','w').write('\n'.join('%s|%s|%s'%o for o in objs))
for l in txt.split('\n'):
    if 'solink' in l and NAME in l:
        inp = l.split(': solink ',1)[1].split('||')[0].split('|')[0].strip()
        open('/tmp/so_link.txt','w').write(inp)
        break
ld = re.search(r'\n  ldflags = (.*?)\n', txt)
lib = re.search(r'\n  libs = (.*?)\n', txt)
if ld: open('/tmp/so_ldflags.txt','w').write(ld.group(1).replace('$$','$'))
if lib: open('/tmp/so_libs.txt','w').write(lib.group(1).replace('$$','$'))
print('prepared', len(objs))
PYEOF
  export DEFINES="$(cat /tmp/so_defines.txt)" INCLUDE_DIRS="$(cat /tmp/so_include_dirs.txt)"
  export CFLAGS="$(cat /tmp/so_cflags.txt)" CFLAGS_C="$(cat /tmp/so_cflags_c.txt)" CFLAGS_CC="$(cat /tmp/so_cflags_cc.txt)"
  while IFS='|' read -r o k s; do
    [ -z "$o" ] && continue
    if [ "$k" = "cxx" ]; then
      /opt/homebrew/bin/ccache $CLANGPP -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_CC -c "$s" -o "$o"
    else
      /opt/homebrew/bin/ccache $CLANG -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c "$s" -o "$o"
    fi
  done < /tmp/so_objs.txt
  LDFLAGS="$(cat /tmp/so_ldflags.txt)" LIBS="$(cat /tmp/so_libs.txt)" IN="$(cat /tmp/so_link.txt)"
  python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split()
objs = [x for x in inp if x.endswith('.o')]
solibs = [x for x in inp if x.endswith('.so')]
libs = [x for x in inp if x.endswith('.a')]
open('/tmp/so.rsp','w').write('\n'.join(['-Wl,--whole-archive'] + objs + ['-Wl,--no-whole-archive'] + libs + solibs))
print('rsp ok')
PYEOF
  /usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
    --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
    --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
    --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
    --sofile="lib.unstripped/$OUT/$NAME.z.so" \
    --output="$OUT/$NAME.z.so" \
    --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
    ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
    -o "lib.unstripped/$OUT/$NAME.z.so" @/tmp/so.rsp $LIBS -Wl,-soname="$NAME.z.so"
  echo "LINKED $OUT/$NAME.z.so"
}

echo "=== common ==="
rebuild_so obj/base/startup/appspawn/modules/common/appspawn_common.ninja appspawn/common libappspawn_common
echo "=== helper ==="
rebuild_so obj/base/startup/appspawn/standard/appspawn_helper.ninja startup/appspawn libappspawn_helper
