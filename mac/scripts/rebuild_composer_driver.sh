#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
DEFINES="$(cat /tmp/cd_defines.txt)"
INCLUDE_DIRS="$(cat /tmp/cd_include_dirs.txt)"
CFLAGS="$(cat /tmp/cd_cflags.txt)"
CFLAGS_CC="$(cat /tmp/cd_cflags_cc.txt)"
CLANGPP=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++
/opt/homebrew/bin/ccache $CLANGPP -MMD -MF obj/drivers/peripheral/display/composer/hdi_service/src/libdisplay_composer_driver_1.0/display_composer_driver.o.d $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_CC -c ../../drivers/peripheral/display/composer/hdi_service/src/display_composer_driver.cpp -o obj/drivers/peripheral/display/composer/hdi_service/src/libdisplay_composer_driver_1.0/display_composer_driver.o
echo "display_composer_driver.o compiled"
LDFLAGS="$(cat /tmp/cd_ldflags.txt)"
LIBS="$(cat /tmp/cd_libs.txt)"
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/hdf/drivers_peripheral_display/libdisplay_composer_driver_1.0.z.so" \
  --output="hdf/drivers_peripheral_display/libdisplay_composer_driver_1.0.z.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/hdf/drivers_peripheral_display/libdisplay_composer_driver_1.0.z.so" \
  obj/drivers/peripheral/display/composer/hdi_service/src/libdisplay_composer_driver_1.0/display_composer_driver.o \
  commonlibrary/c_utils/libutils.z.so hdf/drivers_interface_display/libdisplay_buffer_stub_1.0.z.so \
  hdf/drivers_interface_display/libdisplay_composer_stub_1.0.z.so hdf/drivers_interface_display/libdisplay_composer_stub_1.1.z.so \
  hdf/drivers_interface_display/libdisplay_composer_stub_1.2.z.so hdf/hdf_core/libhdf_host.z.so hdf/hdf_core/libhdf_ipc_adapter.z.so \
  hdf/hdf_core/libhdf_utils.z.so hdf/hdf_core/libhdi.z.so hiviewdfx/hilog/libhilog.so hiviewdfx/hitrace/libhitrace_meter.so \
  startup/init/libbegetutil.z.so communication/ipc/libipc_single.z.so hiviewdfx/hicollie/libhicollie.z.so \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so obj/third_party/musl/usr/lib/aarch64-linux-ohos/libcrypt.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libdl.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libm.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libpthread.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libresolv.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/librt.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libutil.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libxnet.a thirdparty/bounds_checking_function/libsec_shared.z.so \
  hdf/drivers_interface_display/libhdifd_parcelable.z.so $LIBS \
  -Wl,--version-script=../../build/templates/cxx/hdi.versionscript
echo "=== LINKED ==="
ls -la hdf/drivers_peripheral_display/libdisplay_composer_driver_1.0.z.so
