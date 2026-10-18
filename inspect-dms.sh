#!/bin/sh
L=/mnt/root/niri-dms-install.log
echo "=== user config section ==="
sed -n '/== user config/,/== flatpak/p' "$L" | tail -25 | tr -d '\r'
echo "=== animated home ==="
ls -la /mnt/home/animated/ 2>&1
echo "--- .config ---"
ls -la /mnt/home/animated/.config/ 2>&1
echo "--- niri ---"
ls -la /mnt/home/animated/.config/niri/ 2>&1
echo "=== groups ==="
grep -E '^(animated|_greeter):' /mnt/etc/group
echo "=== greetd run ==="
cat /mnt/etc/sv/greetd/run 2>&1
echo "=== dms pkgs ==="
chroot /mnt sh -c 'xbps-query -l 2>/dev/null | grep -iE "dms|quickshell|niri|xwayland" | sort' 2>&1
echo INSPECT_DONE
