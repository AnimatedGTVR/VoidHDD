import socket, time

s = socket.create_connection(('127.0.0.1', 55568), timeout=5)
s.settimeout(0.5)


def recv(sec):
    b = b''
    end = time.time() + sec
    while time.time() < end:
        try:
            d = s.recv(65536)
            if d:
                b += d
        except socket.timeout:
            pass
    return b.decode(errors='replace')


recv(2)
cmds = [
    "printf 'voidlinux\\n' | sudo -S sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=4 console=ttyS0,115200\"/' /mnt/etc/default/grub",
    "printf 'voidlinux\\n' | sudo -S chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg",
    "grep '^GRUB_CMDLINE_LINUX_DEFAULT' /mnt/etc/default/grub; grep 'vmlinuz' /mnt/boot/grub/grub.cfg | head -2",
    "printf 'voidlinux\\n' | sudo -S sh -c 'sync; sync; poweroff'",
]
for c in cmds:
    s.sendall((c + '\r').encode())
    print(recv(20))
s.close()
