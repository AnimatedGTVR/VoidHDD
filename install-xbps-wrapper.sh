#!/bin/sh
# Install the xbps front-end into the offline root on /dev/vda2.
set -eu
mkdir -p /mnt
mountpoint -q /mnt || mount /dev/vda2 /mnt
install -D -m 0755 /tmp/xbps /mnt/usr/local/bin/xbps
chmod 0755 /mnt/usr/local/bin/xbps
ls -l /mnt/usr/local/bin/xbps
chroot /mnt /bin/sh -c 'PATH=/usr/local/bin:$PATH; command -v xbps; xbps --help >/dev/null && echo WRAPPER_OK; xbps -q -l 2>/dev/null | wc -l'
sync
echo INSTALL_DONE
