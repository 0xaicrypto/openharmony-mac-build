#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
CLANGPP=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang

N=obj/base/startup/init/interfaces/innerkits/libbegetutil.ninja
python3 - "$N" <<'PYEOF'
import re, sys
N = sys.argv[1]
txt = open(N).read()
def getvar(name):
    m = re.search(r'^%s = (.*?)$' % name, txt, re.M)
    return m.group(1).replace('$$','$') if m else ''
for k in ['defines','include_dirs','cflags','cflags_c','cflags_cc']:
    open('/tmp/bg_%s.txt'%k,'w').write(getvar(k))
objs = re.findall(r'^build (obj/base/startup/init/interfaces/innerkits[^ |]*\.o): (cxx|cc) (\.\./\.\./[^ |]+) \|', txt, re.M)
open('/tmp/bg_objs.txt','w').write('\n'.join('%s|%s|%s'%o for o in objs) + '\n')
print('objs:', len(objs))
for l in txt.split('\n'):
    if l.startswith('build startup/init/libbegetutil.z.so') and 'solink' in l:
        inp = l.split(': solink ',1)[1].split('||')[0].split('|')[0].strip()
        open('/tmp/bg_link.txt','w').write(inp)
        # count
        print('inputs:', len(inp.split()))
        break
ld = re.search(r'\n  ldflags = (.*?)\n', txt)
lib = re.search(r'\n  libs = (.*?)\n', txt)
if ld: open('/tmp/bg_ldflags.txt','w').write(ld.group(1).replace('$$','$'))
if lib: open('/tmp/bg_libs.txt','w').write(lib.group(1).replace('$$','$'))
print('done')
PYEOF

export DEFINES="$(cat /tmp/bg_defines.txt)" INCLUDE_DIRS="$(cat /tmp/bg_include_dirs.txt)"
export CFLAGS="$(cat /tmp/bg_cflags.txt)" CFLAGS_C="$(cat /tmp/bg_cflags_c.txt)" CFLAGS_CC="$(cat /tmp/bg_cflags_cc.txt)"
while IFS='|' read -r o k s; do
  [ -z "$o" ] && continue
  if [ "$k" = "cxx" ]; then
    /opt/homebrew/bin/ccache $CLANGPP -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_CC -c "$s" -o "$o"
  else
    /opt/homebrew/bin/ccache $CLANG -MMD -MF "$o.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c "$s" -o "$o"
  fi
done < /tmp/bg_objs.txt
echo "objects done"

LDFLAGS="$(cat /tmp/bg_ldflags.txt)" LIBS="$(cat /tmp/bg_libs.txt)" IN="$(cat /tmp/bg_link.txt)"
python3 - "$IN" <<'PYEOF'
import sys
inp = sys.argv[1].split()
# preserve order: all inputs (objs, .a, .so)
rsp = ['-Wl,--whole-archive'] + inp + ['-Wl,--no-whole-archive']
open('/tmp/bg.rsp','w').write('\n'.join(rsp))
print('rsp:', len(inp))
PYEOF
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/startup/init/libbegetutil.z.so" \
  --output="startup/init/libbegetutil.z.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/startup/init/libbegetutil.z.so" @/tmp/bg.rsp $LIBS -Wl,-soname="libbegetutil.z.so"
echo "=== LINKED ==="
LL=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin
$LL/llvm-nm -D startup/init/libbegetutil.z.so | grep -c " T "
ls -la startup/init/libbegetutil.z.so
