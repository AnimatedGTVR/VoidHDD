import socket
import sys
import time
import base64
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8', errors='replace')
log_path = Path(__file__).with_name('recovery-console.log')

def record(text):
    print(text, end='', flush=True)
    with log_path.open('a', encoding='utf-8') as log:
        log.write(text)

def wait_for(sock, needle, timeout):
    end = time.monotonic() + timeout
    data = bytearray()
    while time.monotonic() < end:
        try:
            chunk = sock.recv(65536)
            if not chunk:
                raise RuntimeError('serial connection closed')
            data.extend(chunk)
            text = chunk.decode(errors='replace')
            record(text)
            if needle.encode() in data:
                return
        except socket.timeout:
            pass
    raise TimeoutError(f'timed out waiting for {needle!r}')

def send(sock, line):
    sock.sendall((line + '\r').encode())

log_path.write_text('', encoding='utf-8')
with socket.create_connection(('127.0.0.1', 55568), timeout=15) as serial:
    serial.settimeout(0.5)
    send(serial, '')
    wait_for(serial, 'login:', 180)
    send(serial, 'anon')
    wait_for(serial, 'Password', 30)
    send(serial, 'voidlinux')
    wait_for(serial, '$', 30)
    script = Path(__file__).with_name('recover-hdd-offline.sh').read_bytes()
    encoded = base64.b64encode(script).decode()
    send(serial, f"printf '%s' '{encoded}' | base64 -d > /tmp/recover-hdd.sh")
    wait_for(serial, '$', 60)
    send(serial, 'sudo sh /tmp/recover-hdd.sh')
    wait_for(serial, 'Type RESTORE-WD20EZBX to continue:', 180)
    send(serial, 'RESTORE-WD20EZBX')
    wait_for(serial, 'RECOVERY_COMPLETE_PASSWORDS_PENDING', 7200)
