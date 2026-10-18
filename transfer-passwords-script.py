import base64, socket, time, sys
from pathlib import Path

b64 = base64.b64encode(Path(r'C:\Users\jaxso\Work\void-diagnostics\finish-void-passwords.sh').read_bytes()).decode()

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
    raise SystemExit(f'TIMEOUT waiting for {needle!r}. Tail:\n{drain()[-1000:]}')


def send_line(line=''):
    s.sendall((line + '\r').encode())


send_line('')
wait_for('login:', timeout=60)
send_line('anon')
wait_for('assword')
send_line('voidlinux')
wait_for('$', timeout=60)

send_line('cat > /tmp/fvp.b64 << \'ENDB64\'')
time.sleep(1)
recv_some(1)
drain()
for i in range(0, len(b64), 200):
    send_line(b64[i:i + 200])
    time.sleep(0.15)
send_line('ENDB64')
send_line('base64 -d /tmp/fvp.b64 > /tmp/finish-void-passwords.sh && chmod +x /tmp/finish-void-passwords.sh && sh -n /tmp/finish-void-passwords.sh && echo SCRIPT_READY')
print(wait_for('SCRIPT_READY', timeout=60), end='')
s.close()
print('DONE', flush=True)
