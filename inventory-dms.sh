#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
R() { chroot $M "$@"; }

echo "=== dms package files (top level) ==="
R xbps-query -L dms 2>/dev/null | sed "s|^$M||" | awk -F/ '{print "/"$2"/"$3"/"$4}' | sort -u | head -30
echo "=== dms package files (interesting) ==="
R xbps-query -L dms 2>/dev/null | sed "s|^$M||" | grep -iE 'settings|schema|theme|wallpaper|share/|\.json|\.qml$' | head -40
echo "=== dank dirs ==="
find $M/usr/share $M/usr/lib $M/etc $M/var/lib -maxdepth 3 -iname '*dank*' -o -maxdepth 3 -iname '*quickshell*' 2>/dev/null | head -20
echo "=== dms help (as animated) ==="
R su -l animated -c "dms --help" 2>&1 | head -40
echo "=== terminals ==="
R sh -c 'xbps-query -l | grep -E "^ii (foot|kitty|alacritty|ghostty|wezterm|st|xterm)" '
echo "=== wayland-sessions ==="
R ls /usr/share/wayland-sessions 2>/dev/null
echo "=== icon themes ==="
R ls /usr/share/icons 2>/dev/null
echo "=== fonts ==="
R sh -c 'fc-list 2>/dev/null | wc -l; ls /usr/share/fonts 2>/dev/null; fc-list 2>/dev/null | grep -ciE "nerd|jetbrains|firacode|inter|noto sans"'
echo INV2_DONE
