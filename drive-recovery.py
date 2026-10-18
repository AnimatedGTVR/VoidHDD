import socket, sys, time
from pathlib import Path

HOST, PORT = '127.0.0.1', 55568
ROOT = Path(__file__).resolve().parent
LOG = ROOT / 'drive-recovery.log'
B64 = (ROOT / 'recover-v2.b64').read_text(encoding='ascii')


def log(msg):
    text = msg if msg.endswith('\n') else msg + '\n'
    sys.stdout.write(text)
    sys.stdout.flush()
    with LOG.open('a', encoding='utf-8', errors='replace') as f:
        f.write(text)


class Serial:
    def __init__(self):
        for _ in range(60):
            try:
                self.s = socket.create_connection((HOST, PORT), timeout=5)
                break
            except OSError:
                time.sleep(2)
        else:
            raise SystemExit('serial port never came up')
        self.s.settimeout(0.5)
        self.buf = bytearray()

    def recv_some(self, seconds):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            try:
                data = self.s.recv(65536)
                if data:
                    self.buf.extend(data)
            except socket.timeout:
                pass

    def drain(self):
        out = self.buf.decode(errors='replace')
        self.buf.clear()
        return out

    def wait_for(self, needle, timeout=600, progress=30, on_tick=None):
        end = time.monotonic() + timeout
        last = time.monotonic()
        while time.monotonic() < end:
            self.recv_some(0.5)
            if needle.encode() in bytes(self.buf):
                return self.drain()
            if time.monotonic() - last >= progress:
                log(f'... still waiting for {needle!r}')
                if on_tick:
                    on_tick()
                last = time.monotonic()
        raise SystemExit(f'TIMEOUT waiting for {needle!r}. Tail:\n{self.drain()[-2000:]}')

    def send_line(self, line=''):
        self.s.sendall((line + '\r').encode())

    def close(self):
        try:
            self.s.close()
        except Exception:
            pass


def main():
    LOG.write_text('', encoding='utf-8')
    ser = Serial()
    ser.send_line('')
    out = ser.wait_for('$', timeout=180, progress=15, on_tick=lambda: ser.send_line(''))
    log(out)

    ser.send_line('rm -f /tmp/r.b64 /tmp/recover-v2.sh; cat > /tmp/r.b64 << \'ENDB64\'')
    time.sleep(1)
    ser.recv_some(1)
    ser.drain()
    for i in range(0, len(B64), 200):
        ser.send_line(B64[i:i + 200])
        time.sleep(0.15)
    ser.send_line('ENDB64')
    ser.send_line('base64 -d /tmp/r.b64 > /tmp/recover-v2.sh && chmod +x /tmp/recover-v2.sh && sh -n /tmp/recover-v2.sh && wc -c /tmp/recover-v2.sh && echo DECODE_OK')
    out = ser.wait_for('DECODE_OK', timeout=120)
    log(out)

    log('>>> starting recovery (long e2fsck expected)...')
    ser.send_line('printf "RESTORE-WD20EZBX\\n" | sh /tmp/recover-v2.sh')
    out = ser.wait_for('RECOVERY_COMPLETE_PASSWORDS_PENDING', timeout=5400, progress=30)
    log(out)
    ser.close()
    log('DONE')


if __name__ == '__main__':
    main()
