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
from functions import setup_logger, clean_response
from dotenv import load_dotenv
from db import db
import ssl
import hmac

if sys.version_info[0] < 3:
    # python 2 import
    from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
else:
    # python 3 import
    from http.server import BaseHTTPRequestHandler, HTTPServer


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    pass


class BaseServer(BaseHTTPRequestHandler):

    def _is_authorized_app(self):
        """
        Vérifie que la requête provient bien
        de l'application frontend attendue.
        """

        expected_id = os.getenv("APP_ID", "")
        expected_key = os.getenv("APP_KEY", "")

        received_id = self.headers.get("X-App-Id", "")
        received_key = self.headers.get("X-App-Key", "")

        if not expected_id or not expected_key:
            return False

        return (
            hmac.compare_digest(received_id, expected_id)
            and hmac.compare_digest(received_key, expected_key)
        )

    def _send_json_error(self, status_code, message):
        """
        Retourne une erreur HTTP au format JSON.
        """

        self.send_response(status_code)
        self.send_header(
            "Content-Type",
            "application/json"
        )
        self.send_header(
            "Access-Control-Allow-Origin",
            "*"
        )
        self.end_headers()

        self.wfile.write(
            json.dumps(
                {
                    "error": message
                },
                ensure_ascii=False
            ).encode("utf-8")
        )

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header(
            "Access-Control-Allow-Headers",
            "Content-Type, X-Requested-With, X-App-Id, X-App-Key"
        )
        self.end_headers()

    def do_GET(self):
        qs = parse_qs(urlparse(self.path).query)

        if self.path == '/favicon.ico':
            self.send_response(200)
            self.send_header('Content-Type', 'image/x-icon')
            self.send_header('Content-Length', 0)
            self.end_headers()
            return

        load_dotenv()
        log = setup_logger("Trouves ta place - Server management")

        if not self._is_authorized_app():

            log.error(
                "Requête refusée : application cliente non autorisée."
            )

            self.send_response(403)
            self.send_header(
                "Content-Type",
                "application/json"
            )
            self.send_header(
                "Access-Control-Allow-Origin",
                "*"
            )
            self.end_headers()

            self.wfile.write(
                json.dumps({
                    "error": "Application non autorisée"
                }).encode("utf-8")
            )

            return

        # Récupération de l'action demandée.
        action = qs.get(
            "action",
            [None]
        )[0]

        if action is None:
            self._send_json_error(
                400,
                "Paramètre 'action' manquant."
            )
            return

        # VALIDATION DE LA RECHERCHE PAR VÉHICULE

        if action == "searchbyvehicle":

            parametres_obligatoires = [
                "lon",
                "lat",
                "hauteur",
                "largeur",
                "longueur",
                "type"
            ]

            parametres_manquants = [
                parametre
                for parametre in parametres_obligatoires
                if (
                    parametre not in qs
                    or not qs[parametre]
                    or not str(qs[parametre][0]).strip()
                )
            ]

            if parametres_manquants:
                self._send_json_error(
                    400,
                    "Paramètre(s) manquant(s) : "
                    + ", ".join(parametres_manquants)
                )
                return

            # Conversion des paramètres numériques.
            try:
                lon = float(qs["lon"][0])
                lat = float(qs["lat"][0])
                hauteur = float(qs["hauteur"][0])
                largeur = float(qs["largeur"][0])
                longueur = float(qs["longueur"][0])

            except (ValueError, TypeError):
                self._send_json_error(
                    400,
                    "Les coordonnées et dimensions "
                    "doivent être des nombres."
                )
                return

            # Vérification des dimensions.
            if (
                hauteur <= 0
                or largeur <= 0
                or longueur <= 0
            ):
                self._send_json_error(
                    400,
                    "Les dimensions du véhicule "
                    "doivent être positives."
                )
                return

            # Uniformisation du type.
            type_vehicule = (
                qs["type"][0]
                .strip()
                .lower()
            )

            types_autorises = [
                "velo",
                "moto",
                "voiture",
                "suv"
            ]

            if type_vehicule not in types_autorises:
                self._send_json_error(
                    400,
                    "Type de véhicule non reconnu."
                )
                return

        self._set_headers()

        database = db()
        database.connection()

        if (action == 'searchbydistance'):
            self.wfile.write(
                clean_response(
                    database.findbydistance(
                        float(qs['lon'][0]),
                        float(qs['lat'][0])
                    )
                )
            )

        elif (action == 'searchbyvehicle'):
            self.wfile.write(
                clean_response(
                    database.findbyvehicle(
                        float(qs['lon'][0]),
                        float(qs['lat'][0]),
                        float(qs['hauteur'][0]),
                        float(qs['largeur'][0]),
                        float(qs['longueur'][0]),
                        qs['type'][0]
                    )
                )
            )

        database.close()

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        qs = parse_qs(urlparse(self.path).query)


def run(server_class=ThreadedHTTPServer, handler_class=BaseServer, port=8000):
    load_dotenv()
    log = setup_logger("Trouves ta place - Server management")

    if (os.getenv('PORT') != ""):
        port = int(os.getenv('PORT'))

    try:
        server_address = ('', port)
        httpd = server_class(server_address, handler_class)

        if (os.getenv('PROTOCOL') == "HTTPS"):
            # SSL context
            ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            ssl_context.load_cert_chain(certfile='cert.pem', keyfile='key.pem')
            # Wrap the server socket with SSL
            httpd.socket = ssl_context.wrap_socket(httpd.socket,
                                                   server_side=True)

        log.info(os.getenv('PROTOCOL')+' server running on port %s' % port)
        httpd.serve_forever()
    except KeyboardInterrupt:
        log.info("Process interrupted by user.")
    finally:
        log.info("Exiting program.")


if __name__ == "__main__":
    from sys import argv

    # Permet d'activer le mode debug directement
    # depuis la ligne de commande.
    if "--debug" in argv:
        os.environ["DEBUG"] = "true"
        argv.remove("--debug")

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
