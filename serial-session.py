import socket, sys, time

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

HOST, PORT = '127.0.0.1', 55568


class Serial:
    def __init__(self, host=HOST, port=PORT):
        self.s = socket.create_connection((host, port), timeout=5)
        self.s.settimeout(0.2)
        self.buf = bytearray()

    def pump(self, seconds):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            try:
                data = self.s.recv(65536)
                if data:
                    self.buf.extend(data)
            except socket.timeout:
                pass
        return self.drain()

    def wait_for(self, needle, timeout=60):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            try:
                data = self.s.recv(65536)
                if data:
                    self.buf.extend(data)
            except socket.timeout:
                pass
            if needle.encode() in bytes(self.buf):
                return self.drain()
        return self.drain()

    def drain(self):
        out = self.buf.decode(errors='replace')
        self.buf.clear()
        return out

    def send_line(self, line=''):
        self.s.sendall((line + '\r').encode())

    def send_text(self, text):
        self.s.sendall(text.encode())

    def close(self):
        try:
            self.s.close()
        except Exception:
            pass


def main():
    cmds = sys.argv[1:]
    ser = Serial()
    ser.send_line('')
    print('--- initial state ---')
    initial = ser.wait_for('login:', timeout=10)
    print(initial, end='')
    if 'login:' in initial:
        ser.send_line('anon')
        print('--- password ---')
        print(ser.wait_for('assword', timeout=15), end='')
        ser.send_line('voidlinux')
        time.sleep(1)
        print('--- after login ---')
        print(ser.pump(3), end='')
    for c in cmds:
        print('\n>>> ' + c)
        ser.send_line(c)
        time.sleep(0.5)
        print(ser.pump(6), end='')
    ser.close()


if __name__ == '__main__':
    main()
