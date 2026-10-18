#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
R() { chroot $M "$@"; }

echo "=== home dirs ==="
ls -1 $M/home $M/root 2>&1
echo "=== wallpaper hunt (candidate dirs only) ==="
find $M/home $M/root $M/opt $M/srv $M/usr/local/share \
     $M/usr/share/backgrounds $M/usr/share/wallpapers $M/usr/share/dankmaterialshell \
     -maxdepth 4 -xdev -type f \
     \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \) \
     2>/dev/null | head -60
echo "=== any big images anywhere else on / (excluding icons/theme noise) ==="
find $M -xdev -type f -size +400k \
     \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
     2>/dev/null | grep -viE '/usr/share/(icons|pixmaps|gnome|flatpak)|/usr/lib/|/share/doc|node_modules' | head -40
echo "=== DMS / quickshell files ==="
ls -1d $M/usr/share/dankmaterialshell $M/usr/share/quickshell $M/etc/xdg/DankMaterialShell 2>/dev/null
find $M/usr/share/dankmaterialshell -maxdepth 2 2>/dev/null | head -40
echo "=== dms binary + help ==="
R sh -c 'command -v dms dms-greeter; dms --help 2>&1 | head -40'
echo INVENTORY_DONE
