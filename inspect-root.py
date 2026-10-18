import socket, time, sys

s = socket.create_connection(('127.0.0.1', 55568), timeout=5)
s.settimeout(0.5)
buf = bytearray()


def recv_some(sec):
    end = time.monotonic() + sec
    while time.monotonic() < end:
        try:
            data = s.recv(65536)
            if data:
                buf.extend(data)
        except socket.timeout:
            pass


def drain():
    out = buf.decode(errors='replace')
    buf.clear()
    return out


def wait_for(needle, timeout=180):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        recv_some(0.5)
        if needle.encode() in bytes(buf):
            return drain()
    raise SystemExit(f'TIMEOUT waiting for {needle!r}. Tail:\n{drain()[-1500:]}')


def send_line(line=''):
    s.sendall((line + '\r').encode())


got = None
for _ in range(10):
    send_line('')
    recv_some(3)
    out = drain()
    if 'login:' in out or '$' in out:
        got = out
        break
if got is None:
    raise SystemExit('no console activity')
print(got)
if 'login:' in got:
    send_line('anon')
    wait_for('assword')
    send_line('voidlinux')
    wait_for('$', timeout=60)

send_line("printf 'voidlinux\\n' | sudo -S sh -c 'mount /dev/vda2 /mnt && mount /dev/vda1 /mnt/boot/efi && echo MOUNT_OK'")
wait_for('MOUNT_OK', timeout=120)

cmds = [
    "grep -E '^\s*(linux|initrd|search)' /mnt/boot/grub/grub.cfg | head -8",
    "cat /mnt/boot/grub/grub.cfg | head -30",
    "cat /mnt/etc/fstab",
    "ls -la /mnt/boot/ | head -20",
    "cat /mnt/etc/default/grub 2>/dev/null | head -20",
]
for c in cmds:
    send_line(c)
    time.sleep(3)
    recv_some(6)
    print('### ' + c)
    print(drain())
s.close()
