#!/bin/sh
sync
umount -R /mnt 2>/dev/null
echo SHUTDOWN_ISSUED
poweroff
