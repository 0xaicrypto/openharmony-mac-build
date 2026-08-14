#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
export DEFINES="$(cat /tmp/dh_defines.txt)"
export INCLUDE_DIRS="$(cat /tmp/dh_include_dirs.txt)"
export CFLAGS="$(cat /tmp/dh_cflags.txt)"
export CFLAGS_C="$(cat /tmp/dh_cflags_c.txt)"
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
/opt/homebrew/bin/ccache $CLANG -MMD -MF obj/drivers/hdf_core/adapter/uhdf2/host/hdf_devhost/devhost.o.d $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c ../../drivers/hdf_core/adapter/uhdf2/host/devhost.c -o obj/drivers/hdf_core/adapter/uhdf2/host/hdf_devhost/devhost.o
echo "devhost.o compiled"
LDFLAGS="$(cat /tmp/dh_ldflags.txt)"
LIBS="$(cat /tmp/dh_libs.txt)"
/usr/bin/env "../../build/toolchain/gcc_link_wrapper.py" \
  --output="hdf/hdf_core/hdf_devhost" \
  --strip="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip" \
  --unstripped-file="exe.unstripped/hdf/hdf_core/hdf_devhost" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ $LDFLAGS \
  -o "exe.unstripped/hdf/hdf_core/hdf_devhost" \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/Scrt1.o obj/third_party/musl/usr/lib/aarch64-linux-ohos/crti.o \
  obj/drivers/hdf_core/adapter/uhdf2/host/hdf_devhost/devhost.o \
  -Lhdf/hdf_core -l:libhdf_host.z.so -l:libhdf_ipc_adapter.z.so -l:libhdf_utils.z.so \
  commonlibrary/c_utils/libutils.z.so hiviewdfx/hilog/libhilog.so startup/init/libbegetutil.z.so \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so obj/third_party/musl/usr/lib/aarch64-linux-ohos/libcrypt.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libdl.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libm.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libpthread.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libresolv.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/librt.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libutil.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libxnet.a thirdparty/bounds_checking_function/libsec_shared.z.so \
  $LIBS obj/third_party/musl/usr/lib/aarch64-linux-ohos/crtn.o
echo "=== LINKED ==="
ls -la hdf/hdf_core/hdf_devhost
