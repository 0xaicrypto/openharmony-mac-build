#!/bin/bash
# Rebuild init_early + libueventd_ramdisk_static with fixed sysmacros.h
set -e
cd /Users/hui/ohos-src/out/arm64_virt
CLANG=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang
CCACHE=/opt/homebrew/bin/ccache

# --- extract common vars ---
getvar() { # $1=file $2=var
  sed -n "s/^[ ]*$2 = //p" "$1" | head -1
}

INIT_N=obj/base/startup/init/services/init/standard/init_early.ninja
UVD_N=obj/base/startup/init/ueventd/libueventd_ramdisk_static.ninja

DEFS_I="$(getvar $INIT_N defines)"
INC_I="$(getvar $INIT_N include_dirs)"
CFL_I="$(getvar $INIT_N cflags)"
CFLC_I="$(getvar $INIT_N cflags_c)"

DEFS_U="$(getvar $UVD_N defines)"
INC_U="$(getvar $UVD_N include_dirs)"
CFL_U="$(getvar $UVD_N cflags)"
CFLC_U="$(getvar $UVD_N cflags_c)"

cc_one() { # $1=in $2=out $3=defs $4=inc
  $CCACHE $CLANG -MMD -MF "$2.d" $3 $4 $CFL_I $CFLC_I -c "$1" -o "$2"
}

echo "== ueventd objects =="
for f in ueventd ueventd_device_handler ueventd_firmware_handler ueventd_read_cfg ueventd_socket; do
  cc_one "../../base/startup/init/ueventd/$f.c" "obj/base/startup/init/ueventd/libueventd_ramdisk_static/$f.o" "$DEFS_U" "$INC_U"
  echo "  $f.o done"
done

echo "== repack .a =="
A=obj/base/startup/init/ueventd/libueventd_ramdisk_static.a
rm -f $A
"../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-ar" -r -c -s -D $A \
  obj/base/startup/init/ueventd/libueventd_ramdisk_static/ueventd.o \
  obj/base/startup/init/ueventd/libueventd_ramdisk_static/ueventd_device_handler.o \
  obj/base/startup/init/ueventd/libueventd_ramdisk_static/ueventd_firmware_handler.o \
  obj/base/startup/init/ueventd/libueventd_ramdisk_static/ueventd_read_cfg.o \
  obj/base/startup/init/ueventd/libueventd_ramdisk_static/ueventd_socket.o
echo "  .a done"

echo "== init_early objects =="
cc_one ../../base/startup/init/interfaces/innerkits/hookmgr/hookmgr.c obj/base/startup/init/interfaces/innerkits/hookmgr/init_early/hookmgr.o "$DEFS_I" "$INC_I"
cc_one ../../base/startup/init/services/log/init_commlog.c obj/base/startup/init/services/log/init_early/init_commlog.o "$DEFS_I" "$INC_I"
for f in bootstagehooker device init_firststage init_mount main_early; do
  cc_one "../../base/startup/init/services/init/standard/$f.c" "obj/base/startup/init/services/init/standard/init_early/$f.o" "$DEFS_I" "$INC_I"
done
echo "  done"

echo "== link =="
LDFLAGS="$(getvar $INIT_N ldflags)"
LIBS="$(getvar $INIT_N libs)"
# rsp file: objects + static libs (order from ninja)
RSP=startup/init/init_early.rsp
: > $RSP
cat >> $RSP <<'EOF'
obj/base/startup/init/interfaces/innerkits/hookmgr/init_early/hookmgr.o
obj/base/startup/init/services/log/init_early/init_commlog.o
obj/base/startup/init/services/init/standard/init_early/bootstagehooker.o
obj/base/startup/init/services/init/standard/init_early/device.o
obj/base/startup/init/services/init/standard/init_early/init_firststage.o
obj/base/startup/init/services/init/standard/init_early/init_mount.o
obj/base/startup/init/services/init/standard/init_early/main_early.o
obj/base/startup/init/interfaces/innerkits/fs_manager/libfsmanager_static.a
obj/base/startup/init/services/log/libinit_log.a
obj/base/startup/init/ueventd/libueventd_ramdisk_static.a
thirdparty/bounds_checking_function/libsec_shared.z.so
obj/third_party/cJSON/libcjson_static.a
obj/base/startup/init/services/utils/libinit_utils.a
obj/third_party/bounds_checking_function/libsec_static.a
obj/base/startup/init/interfaces/innerkits/socket/libsocket.a
thirdparty/selinux/libselinux.z.so
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libcrypt.a
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libdl.a
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libm.a
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libpthread.a
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libresolv.a
obj/third_party/musl/usr/lib/aarch64-linux-ohos/librt.a
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libutil.a
obj/third_party/musl/usr/lib/aarch64-linux-ohos/libxnet.a
EOF
/usr/bin/env "../../build/toolchain/gcc_link_wrapper.py" \
  --output="startup/init/init_early" \
  --strip="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip" \
  --unstripped-file="exe.unstripped/startup/init/init_early" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" \
  -- ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ $LDFLAGS \
  -o "exe.unstripped/startup/init/init_early" \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/Scrt1.o obj/third_party/musl/usr/lib/aarch64-linux-ohos/crti.o \
  -Wl,--start-group @"$RSP" $LIBS -Wl,--end-group \
  obj/third_party/musl/usr/lib/aarch64-linux-ohos/crtn.o
echo "== done =="
ls -la exe.unstripped/startup/init/init_early startup/init/init_early
