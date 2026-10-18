import socket, sys, time

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

secs = float(sys.argv[1]) if len(sys.argv) > 1 else 10.0
s = socket.create_connection(('127.0.0.1', 55568), timeout=5)
s.settimeout(0.3)
end = time.monotonic() + secs
while time.monotonic() < end:
    try:
        d = s.recv(65536)
        if d:
            sys.stdout.write(d.decode('utf-8', 'replace'))
            sys.stdout.flush()
    except socket.timeout:
        pass
s.close()
