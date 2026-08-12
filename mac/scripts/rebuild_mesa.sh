#!/bin/bash
# Rebuild mesa3d (aarch64-linux-ohos) on darwin host with KHR symbol export fix
set -e
SRC=/Users/hui/ohos-src
MESA=$SRC/third_party/mesa3d
OUT=$SRC/out/arm64_virt
LL=$SRC/prebuilts/clang/ohos/darwin-arm64/llvm/bin
SYSROOT=$OUT/obj/third_party/musl

cd $MESA

# generate cross_file for aarch64 + darwin host
cat > cross_file <<EOF
[properties]
needs_exe_wrapper = true

c_args = [
    '-march=armv8-a',
    '--target=aarch64-linux-ohos',
    '--sysroot=$SYSROOT',
    '-fPIC']

cpp_args = [
    '-march=armv8-a',
    '--target=aarch64-linux-ohos',
    '--sysroot=$SYSROOT',
    '-fPIC']

c_link_args = [
    '--target=aarch64-linux-ohos',
    '-fuse-ld=lld',
    '--sysroot=$SYSROOT',
    '-L$SYSROOT/usr/lib/aarch64-linux-ohos',
    '--rtlib=compiler-rt',
    ]

cpp_link_args = [
    '--target=aarch64-linux-ohos',
    '-fuse-ld=lld',
    '--sysroot=$SYSROOT',
    '-L$SYSROOT/usr/lib/aarch64-linux-ohos',
    '-fPIC',
    '--rtlib=compiler-rt',
    ]

[binaries]
ar = '$LL/llvm-ar'
c = ['ccache', '$LL/clang']
cpp = ['ccache', '$LL/clang++']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '$LL/llvm-strip'
pkgconfig = '/opt/homebrew/bin/pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
EOF
echo "cross_file generated"

# generate pkgconfig files pointing at real out dirs
mkdir -p pkgconfig
gen_pc() { # $1=template $2=libdir
  name=$(basename $1)
  sed -e "s|ohos_project_directory_stub|$SRC|g" \
      -e "s|ohos-arm-release|arm64_virt|g" \
      -e "s|out/arm64_virt/thirdparty/libdrm|out/arm64_virt/thirdparty/libdrm|g" \
      "$1" > pkgconfig/$name
  echo "  $name"
}
for t in ohos/pkgconfig_template/*.pc; do gen_pc $t; done

# fix libdir paths that don't exist (point to real locations)
sed -i '' "s|out/arm64_virt/thirdparty/libdrm|out/arm64_virt/lib.unstripped/thirdparty/libdrm|" pkgconfig/libdrm.pc
sed -i '' "s|out/arm64_virt/hiviewdfx/hilog_native|out/arm64_virt/hiviewdfx/hilog|" pkgconfig/libhilog.pc

# zlib: find where libz.a/libz.so is
ZDIR=$(dirname $(find $OUT -name "libz.so*" -o -name "libz.a" 2>/dev/null | head -1))
echo "zlib at: $ZDIR"
sed -i '' "s|out/arm64_virt/obj/third_party/zlib|${ZDIR#$SRC/}|" pkgconfig/zlib.pc

rm -rf build-ohos
export PKG_CONFIG_PATH=$MESA/pkgconfig
export PATH=$SRC/prebuilts/python/darwin-arm64/current/bin:$PATH

/Users/hui/Library/Python/3.9/bin/meson setup build-ohos \
  -Dplatforms=ohos \
  -Degl-native-platform=ohos \
  -Ddri-drivers= \
  -Dgallium-drivers=panfrost \
  -Dvulkan-drivers= \
  -Dgbm=enabled \
  -Degl=enabled \
  -Dcpp_rtti=false \
  -Dglx=disabled \
  -Dtools=panfrost \
  -Ddri-search-path=/system/lib \
  -Dzstd=disabled \
  --cross-file=cross_file \
  --prefix=$MESA/build-ohos/install
ninja -C build-ohos -j10
ninja -C build-ohos install
echo "=== BUILD DONE ==="
ls -la build-ohos/install/lib/
