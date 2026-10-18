import socket, time

s = socket.create_connection(('127.0.0.1', 55568), timeout=5)
s.settimeout(0.5)
s.sendall(b"printf 'voidlinux\\n' | sudo -S sh -c 'sync; poweroff'\r")
time.sleep(3)
s.close()
print('sent')
