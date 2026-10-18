#!/bin/sh
set -eu
mkdir -p /mnt
mountpoint -q /mnt || mount /dev/vda2 /mnt

echo "=== KERNELS ==="
ls -1 /mnt/boot/vmlinuz-* 2>/dev/null || true

echo "=== GRAPHICS / SYSTEM PACKAGES ==="
chroot /mnt xbps-query -p pkgver mesa mesa-dri mesa-vulkan-radeon linux-firmware-amd \
    linux6.12 linux-lts elogind dbus polkit seatd NetworkManager sudo 2>&1 | sort

echo "=== DISPLAY STACK PRESENT ==="
chroot /mnt xbps-query -l 2>/dev/null | awk '{print $2}' | grep -E '^(xorg|wayland|mesa|xinit|xdm|lightdm|sddm|greetd|sway|niri|hyprland|labwc|river|wayfire)' | sort || echo NONE

echo "=== DRI DRIVERS ON DISK ==="
ls -1 /mnt/usr/lib/dri/ 2>/dev/null | tr '\n' ' ' || echo NONE
echo
echo "=== GPU FIRMWARE ==="
ls -1 /mnt/usr/lib/firmware/amdgpu/ 2>/dev/null | grep -c . || echo 0
ls -1 /mnt/usr/lib/firmware/amdgpu/ 2>/dev/null | grep -iE 'gc_12|psp_14|sdma_7|smu_14' | head -20 || true

echo "=== SESSION ENTRIES ==="
ls -1 /mnt/usr/share/xsessions/ /mnt/usr/share/wayland-sessions/ 2>/dev/null || echo NONE

echo CHECK_DONE
