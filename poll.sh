#!/bin/sh
echo "--- running: $(pgrep -fc install-niri-dms.sh 2>/dev/null || echo 0) process(es)"
echo "--- log size: $(wc -c < /mnt/root/niri-dms-install.log 2>/dev/null || echo 0) bytes"
echo "--- progress:"
grep -aE '^==|^\[ (ok|warn|info|info)\]|update pass|rewrote|enabled:|INSTALL_SCRIPT_FINISHED' /mnt/root/niri-dms-install.log 2>/dev/null | tail -25
echo "--- tail:"
tail -c 800 /mnt/root/niri-dms-install.log 2>/dev/null | tr -d '\r'
echo
echo POLLDONE
