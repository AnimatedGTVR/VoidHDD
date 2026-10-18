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


def wait_for(needle, timeout=120):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        recv_some(0.5)
        if needle.encode() in bytes(buf):
            return drain()
    raise SystemExit(f'TIMEOUT waiting for {needle!r}. Tail:\n{drain()[-1500:]}')


for _ in range(5):
    s.sendall(b'\r')
    recv_some(2)
    if 'Shell>' in drain():
        break
else:
    raise SystemExit('no UEFI shell prompt')
s.sendall(b'FS0:\r')
time.sleep(1)
recv_some(2)
print(drain())
s.sendall(b'EFI\\BOOT\\BOOTX64.EFI\r')
time.sleep(2)
recv_some(5)
print(drain())
s.close()
