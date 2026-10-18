import socket, sys, time
from pathlib import Path

HOST, PORT = '127.0.0.1', 55568
LOG = Path(__file__).resolve().parent / 'drive-recovery.log'


def log(msg):
    text = msg if msg.endswith('\n') else msg + '\n'
    sys.stdout.write(text)
    sys.stdout.flush()
    with LOG.open('a', encoding='utf-8', errors='replace') as f:
        f.write(text)


class Serial:
    def __init__(self):
        self.s = socket.create_connection((HOST, PORT), timeout=5)
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
    ser = Serial()
    ser.send_line('')
    out = ser.wait_for('$', timeout=60, progress=10, on_tick=lambda: ser.send_line(''))
    log(out)
    log('>>> running recovery with sudo...')
    ser.send_line("sudo sh /tmp/recover-v2.sh <<< 'RESTORE-WD20EZBX'")
    out = ser.wait_for('RECOVERY_COMPLETE_PASSWORDS_PENDING', timeout=7200, progress=60)
    log(out)
    ser.close()
    log('DONE')


if __name__ == '__main__':
    main()
