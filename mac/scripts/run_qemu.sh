#!/bin/bash

# OpenHarmony arm64_virt boot for macOS (adapted from vendor/edu/arm64_virt/qemu_run.sh)
# Changes vs upstream: no sudo, no virbr0 bridge (user networking), no SDL display (VNC only)

OHOS_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OHOS_IMG="$OHOS_ROOT/out/arm64_virt/packages/phone/images"

exec qemu-system-aarch64 \
-M virt \
-cpu cortex-a57 \
-smp 4 \
-m 4096 \
-kernel ${OHOS_IMG}/Image \
-initrd ${OHOS_IMG}/ramdisk.img \
-nographic \
-vga none \
-device virtio-gpu-pci,xres=800,yres=500 \
-vnc :21,password=on \
-monitor unix:/tmp/qemu_mon.sock,server,nowait \
-device virtio-mouse-pci \
-device virtio-keyboard-pci \
-k en-us \
-rtc base=localtime,clock=host \
-device es1370 \
-netdev user,id=net0 -device virtio-net-device,netdev=net0,mac=12:22:33:44:55:66 \
-drive if=none,file=${OHOS_IMG}/userdata.img,format=raw,id=userdata,index=5 -device virtio-blk-device,drive=userdata \
-drive if=none,file=${OHOS_IMG}/chip_prod.img,format=raw,id=chip_prod,index=4 -device virtio-blk-device,drive=chip_prod \
-drive if=none,file=${OHOS_IMG}/sys_prod.img,format=raw,id=sys_prod,index=3 -device virtio-blk-device,drive=sys_prod \
-drive if=none,file=${OHOS_IMG}/vendor.img,format=raw,id=vendor,index=2 -device virtio-blk-device,drive=vendor \
-drive if=none,file=${OHOS_IMG}/system.img,format=raw,id=system,index=1 -device virtio-blk-device,drive=system \
-drive if=none,file=${OHOS_IMG}/updater.img,format=raw,id=updater,index=0 -device virtio-blk-device,drive=updater \
-append " \
ip=dhcp \
loglevel=7 \
console=tty0,115200 console=ttyAMA0,115200 \
init=/bin/init ohos.boot.hardware=virt \
root=/dev/ram0 rw \
ohos.required_mount.system=/dev/block/vdb@/usr@ext4@ro,barrier=1@wait,required \
ohos.required_mount.vendor=/dev/block/vdc@/vendor@ext4@ro,barrier=1@wait,required \
ohos.required_mount.sys_prod=/dev/block/vdd@/sys_prod@ext4@rw,barrier=1@wait,required \
ohos.required_mount.chip_prod=/dev/block/vde@/chip_prod@ext4@rw,barrier=1@wait,required \
ohos.required_mount.data=/dev/block/vdf@/data@ext4@nosuid,nodev,noatime,barrier=1,data=ordered,noauto_da_alloc@wait,reservedsize=104857600"
