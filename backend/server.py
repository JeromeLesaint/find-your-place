"""
Very simple HTTP server in python.
Usage::
    ./dummy-web-server.py [<port>]
Send a GET request::
    curl http://localhost
Send a HEAD request::
    curl -I http://localhost
Send a POST request::
    curl -d "foo=bar&bin=baz" http://localhost
"""
import sys                         
import json
# pyhton 3.9
from urllib.parse import urlparse, parse_qs
from socketserver import ThreadingMixIn
import os
import threading
import requests  
import time    
from functions import setup_logger,clean_response,verify_key  
from dotenv import load_dotenv
from db import db
import ssl

if sys.version_info[0] < 3:
    # python 2 import
    from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
else:
    # python 3 import
    from http.server import BaseHTTPRequestHandler, HTTPServer

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    pass

class BaseServer(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Headers",'Access-Control-Allow-Origin')
        self.end_headers()
    def do_GET(self):
        qs=parse_qs(urlparse(self.path).query)
        
        self._set_headers()
        if self.path == '/favicon.ico':
            self.send_response(200)
            self.send_header('Content-Type', 'image/x-icon')
            self.send_header('Content-Length', 0)
            self.end_headers()
            return
            
        load_dotenv()
        log = setup_logger("Trouves ta place - Server management")
        if ('action' in qs):
            if ('key' in qs):
                try:
                    if (verify_key(os.getenv('SECRET_PHRASE'),qs['key'][0])):
                        database=db()
                        database.connection()
                        if(qs['action'][0]=='searchbydistance'):
                            
                            self.wfile.write(clean_response(database.findbydistance(float(qs['lon'][0]),float(qs['lat'][0]))))
                        database.close()
                    else:
                        self.wfile.write(clean_response('{ "type":"error","message":"Wrong key" }'))
                except ValueError:
                    self.wfile.write(clean_response('{ "type":"error","message":"Wrong key" }'))
            else:
                self.wfile.write(clean_response('{ "type":"error","message":"No key in query" }'))
        else:
            self.wfile.write(clean_response('{ "type":"error","message":"No action" }'))
        
    def do_HEAD(self):
        self._set_headers()
        
    def do_POST(self):
        qs=parse_qs(urlparse(self.path).query)
def run(server_class=ThreadedHTTPServer, handler_class=BaseServer, port=8000):
    load_dotenv()
    log = setup_logger("Trouves ta place - Server management")
    
    if (os.getenv('PORT')!=""):
        port=int(os.getenv('PORT'))
    
    try:
        server_address = ('', port)
        httpd = server_class(server_address, handler_class)
        
        
        
        if (os.getenv('PROTOCOL')=="HTTPS"):
            # SSL context
            ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            ssl_context.load_cert_chain(certfile='cert.pem', keyfile='key.pem')
            # Wrap the server socket with SSL
            httpd.socket = ssl_context.wrap_socket(httpd.socket, server_side=True)
        
        log.info(os.getenv('PROTOCOL')+' server running on port %s'% port)
        httpd.serve_forever()
    except KeyboardInterrupt:
        log.info("Process interrupted by user.")
    finally:
        log.info("Exiting program.")
        
if __name__ == "__main__":
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else: run()
    