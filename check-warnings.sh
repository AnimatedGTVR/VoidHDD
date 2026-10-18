#!/bin/sh
L=/mnt/root/niri-dms-install.log
echo "--- last 5 lines:"
tail -5 "$L" | tr -d '\r'
echo "--- markers:"
grep -aE 'INSTALL_SCRIPT_FINISHED|^\[die\]' "$L" | tr -d '\r'
echo "--- warnings asked about:"
grep -aE '^\[warn\]' "$L" | tr -d '\r'
echo "--- unpack/config failures:"
grep -aiE 'error|cannot|not installed|failed to' "$L" | grep -aviE 'regulatory.db|errors above|not be executed|DRI' | tail -15 | tr -d '\r'
echo "--- greeter section:"
sed -n '/dms-greeter (greetd/,/user config/p' "$L" | tr -d '\r' | tail -20
echo ---FINAL
chroot /mnt sh -c 'xbps-query -l | wc -l; ls -l /var/service/ 2>/dev/null; cat /etc/greetd/config.toml 2>/dev/null; ls /usr/share/wayland-sessions/ 2>/dev/null'
echo CHECKWARN_DONE
