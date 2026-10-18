#!/bin/sh
# Run interactively from the live environment after recover-hdd-offline.sh.
# Password input remains inside the guest console and is not logged by scripts.
set -eu

[ -f /mnt/etc/os-release ] || {
    echo '/mnt is not the repaired Void root.' >&2
    exit 1
}
[ "$(cat /mnt/etc/hostname)" = 'void' ] || {
    echo 'Hostname verification failed.' >&2
    exit 1
}
chroot /mnt id animated >/dev/null

echo 'Set the root password:'
chroot /mnt passwd root
echo 'Set the animated user password:'
chroot /mnt passwd animated

chroot /mnt passwd -S root
chroot /mnt passwd -S animated
sync
echo 'PASSWORDS_SET_VOID_READY'
