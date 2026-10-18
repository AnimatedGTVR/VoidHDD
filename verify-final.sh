#!/bin/sh
M=/mnt
R() { chroot $M "$@"; }
L=$M/root/niri-dms-install.log
echo "=== versions ==="
R sh -c 'for p in linux mesa niri dms dms-greeter quickshell xwayland-satellite pipewire wireplumber; do printf "%-22s %s\n" "$p" "$(xbps-query -p pkgver $p 2>/dev/null)"; done'
echo "=== kernel / dri ==="
ls -1 $M/boot/vmlinuz-* 2>/dev/null | tr '\n' ' '; echo
echo "dri drivers: $(ls $M/usr/lib/dri 2>/dev/null | wc -l)"
echo "=== services ==="
ls -1 /var/service 2>/dev/null >/dev/null; ls -1 $M/var/service | tr '\n' ' '; echo
echo "=== greetd ==="
R cat /etc/greetd/config.toml
echo "=== niri session ==="
ls $M/usr/share/wayland-sessions/
echo "=== user ==="
R id animated
R sh -c 'cat /home/animated/.config/niri/config.kdl'
echo "=== runit sv dirs ==="
R sh -c 'ls -1 /etc/sv | grep -E "dbus|elogind|greetd|seatd|NetworkManager|dhcpcd|wpa" | tr "\n" " "'; echo
echo "=== xbps health ==="
R xbps-pkgdb -a 2>&1 | tail -5
echo "package count: $(R sh -c 'xbps-query -l | wc -l')"
echo "=== install log summary ==="
grep -acE '' "$L" | sed 's/^/log lines: /'
grep -aE '^\[warn\]' "$L" | tr -d '\r'
echo FINAL_DONE
