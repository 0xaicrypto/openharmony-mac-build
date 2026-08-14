#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
DEFINES="$(cat /tmp/ldso_defines.txt)"
INCLUDE_DIRS="$(cat /tmp/ldso_include_dirs.txt)"
CFLAGS="$(cat /tmp/ldso_cflags.txt)"
CFLAGS_C="$(cat /tmp/ldso_cflags_c.txt)"
OUT=obj/out/arm64_virt/obj/third_party/musl/intermidiates/linux/musl_src_ported/src/env/soft_musl_src_nossp/__libc_start_main.o
SRC=obj/third_party/musl/intermidiates/linux/musl_src_ported/src/env/__libc_start_main.c
/opt/homebrew/bin/ccache $CLANG -MMD -MF "$OUT.d" $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c "$SRC" -o "$OUT"
echo "__libc_start_main.o compiled"
