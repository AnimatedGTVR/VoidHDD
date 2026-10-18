#!/bin/sh
echo "--- what is /mnt/var/service ---"
ls -ld /mnt/var/service
readlink -f /mnt/var/service
echo "--- installed (host path) ---"
ls -1 /mnt/var/service | tr '\n' ' '; echo
echo "--- installed (chroot view) ---"
chroot /mnt ls -1 /var/service | tr '\n' ' '; echo
echo "--- live ISO (for comparison) ---"
ls -1 /var/service | tr '\n' ' '; echo
echo "--- mounts on /mnt ---"
grep -E ' /mnt' /proc/mounts | awk '{print $1, $2, $3}'
echo SERVICES_CHECK_DONE
