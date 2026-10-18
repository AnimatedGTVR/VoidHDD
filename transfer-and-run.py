"""Transfer a local file to the live guest over serial (base64 heredoc) and run it.

Usage: python transfer-and-run.py <local-file> <remote-path> <run-cmd> [wait-marker]
"""
import base64
import socket
import sys
import time
from pathlib import Path

HOST, PORT = '127.0.0.1', 55568
local, remote, run_cmd = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
marker = sys.argv[4] if len(sys.argv) > 4 else None
b64 = base64.b64encode(local.read_bytes()).decode()

s = socket.create_connection((HOST, PORT), timeout=5)
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


def wait_for(needle, timeout=600, progress=30):
    end = time.monotonic() + timeout
    last = time.monotonic()
    while time.monotonic() < end:
        recv_some(0.5)
        if needle.encode() in bytes(buf):
            return drain()
        if time.monotonic() - last >= progress:
            print(f'... still waiting for {needle!r}', flush=True)
            s.sendall(b'\r')
            last = time.monotonic()
    raise SystemExit(f'TIMEOUT waiting for {needle!r}. Tail:\n{drain()[-2000:]}')


def send_line(line=''):
    s.sendall((line + '\r').encode())


send_line('')
recv_some(3)
out = drain()
if 'login:' in out:
    send_line('anon')
    wait_for('assword', timeout=60)
    send_line('voidlinux')
    out = wait_for('$', timeout=60)
    print(out, end='', flush=True)
elif '$' not in out and '#' not in out:
    for _ in range(10):
        send_line('')
        recv_some(3)
        out = drain()
        if 'login:' in out:
            send_line('anon')
            wait_for('assword', timeout=60)
            send_line('voidlinux')
            print(wait_for('$', timeout=60), end='', flush=True)
            break
        if '$' in out or '#' in out:
            break

send_line(f'cat > {remote}.b64 << \'ENDB64\'')
time.sleep(1)
recv_some(1)
drain()
for i in range(0, len(b64), 200):
    send_line(b64[i:i + 200])
    time.sleep(0.15)
send_line('ENDB64')
send_line(f'base64 -d {remote}.b64 > {remote} && chmod +x {remote} && sh -n {remote} && grep -q RECOVERY_COMPLETE_PASSWORDS_PENDING {remote} && echo SYNTAX_OK')
wait_for('SYNTAX_OK', timeout=60)

print(f'>>> running: {run_cmd}', flush=True)
send_line(run_cmd)
if marker:
    print(wait_for(marker, timeout=7200, progress=60), end='', flush=True)
else:
    time.sleep(5)
    recv_some(10)
    print(drain(), end='', flush=True)
s.close()
print('DONE', flush=True)
