import socket, sys, time

with socket.create_connection(('127.0.0.1', 55568), timeout=5) as s:
    s.settimeout(0.5)
    s.sendall((sys.argv[1] + '\r').encode())
    until = time.monotonic() + 4
    output = bytearray()
    while time.monotonic() < until:
        try:
            data = s.recv(65536)
            if not data:
                break
            output.extend(data)
        except socket.timeout:
            pass
    print(output.decode(errors='replace'))
