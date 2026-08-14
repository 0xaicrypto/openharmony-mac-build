#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
DEFINES="$(cat /tmp/dm_defines.txt)"
INCLUDE_DIRS="$(cat /tmp/dm_include_dirs.txt)"
CFLAGS="$(cat /tmp/dm_cflags.txt)"
CFLAGS_C="$(cat /tmp/dm_cflags_c.txt)"
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
/opt/homebrew/bin/ccache $CLANG -MMD -MF obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/devmgr_service.o.d $DEFINES $INCLUDE_DIRS $CFLAGS $CFLAGS_C -c ../../drivers/hdf_core/framework/core/manager/src/devmgr_service.c -o obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/devmgr_service.o
echo "devmgr_service.o compiled"
LDFLAGS="$(cat /tmp/dm_ldflags.txt)"
LIBS="$(cat /tmp/dm_libs.txt)"
/usr/bin/env "../../build/toolchain/gcc_link_wrapper.py" \
  --output="hdf/hdf_core/hdf_devmgr" \
  --strip="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip" \
  --unstripped-file="exe.unstripped/hdf/hdf_core/hdf_devmgr" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ $LDFLAGS \
  -o "exe.unstripped/hdf/hdf_core/hdf_devmgr" \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/Scrt1.o obj/third_party/musl/usr/lib/aarch64-linux-ohos/crti.o \
  obj/drivers/hdf_core/framework/core/common/src/hdf_devmgr/hdf_attribute.o \
  obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/devhost_service_clnt.o \
  obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/device_token_clnt.o \
  obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/devmgr_service.o \
  obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/devsvc_manager.o \
  obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/hdf_driver_installer.o \
  obj/drivers/hdf_core/framework/core/manager/src/hdf_devmgr/hdf_host_info.o \
  obj/drivers/hdf_core/framework/core/shared/src/hdf_devmgr/hdf_device_info.o \
  obj/drivers/hdf_core/framework/core/shared/src/hdf_devmgr/hdf_object_manager.o \
  obj/drivers/hdf_core/framework/core/shared/src/hdf_devmgr/hdf_service_record.o \
  obj/drivers/hdf_core/adapter/uhdf2/shared/src/hdf_devmgr/dev_attribute_serialize.o \
  obj/drivers/hdf_core/adapter/uhdf2/shared/src/hdf_devmgr/hcb_config_entry.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/hdf_devmgr/device_manager.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devhost_service_proxy.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/device_token_proxy.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devmgr_dump.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devmgr_object_config.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devmgr_query_device.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devmgr_service_full.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devmgr_service_stub.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devmgr_uevent.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/devsvc_manager_stub.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/driver_installer_full.o \
  obj/drivers/hdf_core/adapter/uhdf2/manager/src/hdf_devmgr/servstat_listener_holder.o \
  -Lhdf/hdf_core -l:libhdf_ipc_adapter.z.so -l:libhdf_utils.z.so \
  commonlibrary/c_utils/libutils.z.so hiviewdfx/hilog/libhilog.so startup/init/libbegetutil.z.so \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so obj/third_party/musl/usr/lib/aarch64-linux-ohos/libcrypt.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libdl.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libm.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libpthread.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libresolv.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/librt.a obj/third_party/musl/usr/lib/aarch64-linux-ohos/libutil.a \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/libxnet.a thirdparty/bounds_checking_function/libsec_shared.z.so \
  $LIBS obj/third_party/musl/usr/lib/aarch64-linux-ohos/crtn.o
echo "=== LINKED ==="
ls -la hdf/hdf_core/hdf_devmgr
