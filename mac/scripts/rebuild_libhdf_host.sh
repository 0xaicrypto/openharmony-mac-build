#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
DEFINES="$(cat /tmp/lh_defines.txt)"
INCLUDE_DIRS="$(cat /tmp/lh_include_dirs.txt)"
CFLAGS="$(cat /tmp/lh_cflags.txt)"
CFLAGS_C="$(cat /tmp/lh_cflags_c.txt)"
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
/opt/homebrew/bin/ccache $CLANG -MMD -MF obj/drivers/hdf_core/adapter/uhdf2/host/src/libhdf_host/devhost_service_full.o.d $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c ../../drivers/hdf_core/adapter/uhdf2/host/src/devhost_service_full.c -o obj/drivers/hdf_core/adapter/uhdf2/host/src/libhdf_host/devhost_service_full.o
echo "devhost_service_full.o compiled"
LDFLAGS="$(cat /tmp/lh_ldflags.txt)"
LIBS="$(cat /tmp/lh_libs.txt)"
SOLIBS="$(cat /tmp/lh_solibs.txt | tr '\n' ' ')"
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/hdf/hdf_core/libhdf_host.z.so" \
  --output="hdf/hdf_core/libhdf_host.z.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/hdf/hdf_core/libhdf_host.z.so" \
  $(cat /tmp/lh_objs.txt | tr '\n' ' ') $SOLIBS $LIBS
echo "=== LINKED ==="
ls -la hdf/hdf_core/libhdf_host.z.so
