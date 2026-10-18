import socket, sys, time

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass


def main():
    s = socket.create_connection(('127.0.0.1', 55568), timeout=5)
    s.settimeout(0.2)
    for arg in sys.argv[1:]:
        if arg == '^C':
            s.sendall(b'\x03')
        elif arg == '^D':
            s.sendall(b'\x04')
        elif arg == '^[{}':
            s.sendall(b'\x1b[{')
        else:
            s.sendall((arg + '\r').encode())
        time.sleep(0.7)
        while True:
            try:
                d = s.recv(65536)
                if not d:
                    break
                sys.stdout.write(d.decode('utf-8', 'replace'))
            except socket.timeout:
                break
    s.close()


if __name__ == '__main__':
    main()
