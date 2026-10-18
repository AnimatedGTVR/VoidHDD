from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

root = Path(__file__).resolve().parent

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        files = {
            '/repair.sh': 'repair-overlay.sh',
            '/recover-hdd.sh': 'recover-hdd-offline.sh',
            '/recover-v2.sh': 'recover-hdd-offline-v2.sh',
            '/finish-passwords.sh': 'finish-void-passwords.sh',
        }
        if self.path not in files:
            self.send_error(404)
            return
        body = (root / files[self.path]).read_bytes()
        self.send_response(200)
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path != '/result':
            self.send_error(404)
            return
        size = int(self.headers.get('Content-Length', '0'))
        if not 0 < size <= 1048576:
            self.send_error(400)
            return
        (root / 'repair-result.txt').write_bytes(self.rfile.read(size))
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')

HTTPServer(('127.0.0.1', 18887), Handler).serve_forever()
