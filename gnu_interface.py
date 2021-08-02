
import gnubg
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import json

try:
    from urllib.parse import urlparse, parse_qs
except ImportError:
    from urlparse import urlparse, parse_qs


class Handler(BaseHTTPRequestHandler):

    def _set_headers(self, response=200):
        self.send_response(response)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_POST(self):
        response = {'board': [], 'last_move': [], 'info': []}
        post_data = self.rfile.read(int(self.headers['Content-Length'])).decode('utf-8')
        data = parse_qs(post_data)

        command = data['command'][0]
        print(command)
        gnubg.command(command)

        # check if the game is started/exists (handle the case the command executed is set at the beginning)
        if gnubg.match(0):
            # get the board after the execution of a move
            response['board'] = gnubg.board()

            # get the last game after the execution of a move
            response['last_game'] = gnubg.match(0)['games'][-1]['game'][-1]
            print(gnubg.match(0)['games'][-1]['game'][-1])
            print(response['last_game'])

            response["info"] = gnubg.match(0)["games"][0]["info"]

        self._set_headers()
        self.wfile.write(json.dumps(response))

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if self.path:
            self._set_headers()
            self.wfile.write(bytes("Hello! Welcome to Backgammon WebGUI"))


def run(host, server_class=HTTPServer, handler_class=Handler, port=8001):
    server_address = (host, port)
    httpd = server_class(server_address, handler_class)
    print('Starting httpd ({}:{})...'.format(host, port))
    httpd.serve_forever()

if __name__ == "__main__":
    HOST = 'localhost'  # <-- YOUR HOST HERE
    PORT = 8001  # <-- YOUR PORT HERE
    run(host=HOST, port=PORT)