#!/bin/bash
set -e
cd /Users/hui/ohos-src/out/arm64_virt
LDFLAGS="$(cat /tmp/libc_ldflags.txt)"
LIBS="$(cat /tmp/libc_libs.txt)"
/usr/bin/env "../../build/toolchain/gcc_solink_wrapper.py" \
  --readelf="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-readobj" \
  --nm="../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-nm" \
  --strip=../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/llvm-strip \
  --sofile="lib.unstripped/obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so" \
  --output="obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so" \
  --clang-base-dir="/Users/hui/ohos-src/prebuilts/clang/ohos" -- \
  ../../prebuilts/clang/ohos/darwin-arm64/llvm/bin/clang++ -shared $LDFLAGS \
  -o "lib.unstripped/obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so" \
  @/tmp/libc.rsp $LIBS -Wl,-soname="libc.so"
echo "=== LINKED ==="
ls -la obj/third_party/musl/usr/lib/aarch64-linux-ohos/libc.so
