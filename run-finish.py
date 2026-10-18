import socket, time, sys
from pathlib import Path

LOG = Path(__file__).resolve().parent / 'finish-run.log'


def log(msg):
    text = msg if msg.endswith('\n') else msg + '\n'
    sys.stdout.write(text)
    sys.stdout.flush()
    with LOG.open('a', encoding='utf-8', errors='replace') as f:
        f.write(text)


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


def wait_for(needle, timeout=7200, progress=60):
    end = time.monotonic() + timeout
    last = time.monotonic()
    while time.monotonic() < end:
        recv_some(0.5)
        if needle.encode() in bytes(buf):
            return drain()
        if time.monotonic() - last >= progress:
            log(f'... still waiting for {needle!r}')
            last = time.monotonic()
    raise SystemExit(f'TIMEOUT waiting for {needle!r}. Tail:\n{drain()[-2000:]}')


s.sendall(b'\r')
wait_for('#', timeout=60, progress=5)
log('>>> sh /tmp/finish-recovery.sh')
s.sendall(b'sh /tmp/finish-recovery.sh\r')
out = wait_for('RECOVERY_COMPLETE_PASSWORDS_PENDING')
log(out)
s.close()
log('DONE')
