#!/bin/sh
# finish-dms.sh — the steps that could not complete from a pipe.
# Runs on the live ISO, operating on the installed system at /mnt.
set -u
U=animated
UID_=1000
C="/mnt/home/$U/.config/niri/config.kdl"
R() { chroot /mnt "$@"; }

echo "== groups =="
if R getent group _greeter >/dev/null 2>&1; then
    R usermod -aG _greeter "$U" && echo "ok: $U added to _greeter"
else
    echo "warn: no _greeter group"
fi
R getent group input >/dev/null 2>&1 && R usermod -aG input "$U" && echo "ok: $U in input"
# the greeter itself needs DRM + input access
for g in video render input; do
    R getent group "$g" >/dev/null 2>&1 && R usermod -aG "$g" _greeter && echo "ok: _greeter in $g"
done

echo "== niri config ownership =="
R chown -R "$UID_:$UID_" "/home/$U/.config" && echo "ok: .config owned by $UID_"

echo "== greeter sync (as $U) =="
R su -l "$U" -c "dms-greeter sync" 2>&1 | tail -8

echo "== groups now =="
grep -E "$U|_greeter" /mnt/etc/group | tr '\n' ' '; echo
echo "== _greeter primary groups =="
R id _greeter
echo FINISH_DMS_DONE
