#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
A() { chroot $M su -l animated -c "$1"; }

echo "=== download the two new wallpapers ==="
for f in sunset-over-the-mountains.jpg hidden-temple.jpg; do
    A "dms dl -o /home/animated/Pictures/Wallpapers/$f http://10.0.2.2:8000/$f" 2>&1 | tail -2
done

echo "=== set default wallpaper: The Hidden Temple ==="
cat > $M/home/animated/.local/state/DankMaterialShell/session.json <<'JSONEOF'
{
  "wallpaperPath": "/home/animated/Pictures/Wallpapers/hidden-temple.jpg",
  "wallpaperFillMode": "PreserveAspectCrop",
  "monitorWallpapers": {}
}
JSONEOF

chown -R 1000:1000 $M/home/animated/Pictures $M/home/animated/.local
echo "--- session.json ---"
cat $M/home/animated/.local/state/DankMaterialShell/session.json
echo "--- wallpaper dir ---"
ls -l $M/home/animated/Pictures/Wallpapers/
echo WALLPAPER_DONE
