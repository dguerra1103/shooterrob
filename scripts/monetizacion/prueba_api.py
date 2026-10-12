# Prueba de crear_productos.py contra un Roblox DE MENTIRA que corre en este ordenador (127.0.0.1):
#   python -X utf8 scripts/monetizacion/prueba_api.py
# No sale a internet, no usa ninguna clave real y trabaja sobre una copia de ProductIds.luau.
# Comprueba la lógica del script (qué pide, en qué orden, qué escribe). NO demuestra que el Roblox real
# responda con esta misma forma: eso solo se ve ejecutándolo con una clave de verdad.
import contextlib
import email.parser
import importlib.util
import io
import json
import os
import shutil
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("crear_productos", os.path.join(HERE, "crear_productos.py"))
cp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cp)
CATALOG = json.load(io.open(cp.CATALOG, encoding="utf-8"))
REAL_IDS = cp.IDS_FILE
FAKE_KEY = "clave-de-mentira"


class Fake:
    """Estado del Roblox de mentira."""

    def __init__(self):
        self.products, self.passes, self.log, self.next_id, self.fail_at = [], [], [], 9000, None


def handler(state):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def reply(self, status, body=None):
            raw = json.dumps(body).encode("utf-8") if body is not None else b""
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def fields(self):
            raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
            head = ("Content-Type: %s\r\n\r\n" % self.headers.get("Content-Type")).encode("utf-8")
            out = {}
            for part in email.parser.BytesParser().parsebytes(head + raw).get_payload():
                name = part.get_param("name", header="content-disposition")
                payload = part.get_payload(decode=True)
                out[name] = payload if part.get_filename() else payload.decode("utf-8")
            return out

        def kind(self):
            path = urlparse(self.path).path
            if "/developer-products/v2/universes/123/developer-products" in path:
                return state.products, "productId", "developerProducts", path
            if "/game-passes/v1/universes/123/game-passes" in path:
                return state.passes, "gamePassId", "gamePasses", path
            return None, None, None, path

        def check_key(self):
            if self.headers.get("x-api-key") != FAKE_KEY:
                self.reply(401, {"message": "clave incorrecta"})
                return False
            return True

        def do_GET(self):
            items, _, field, path = self.kind()
            if items is None or not path.endswith("/creator") or not self.check_key():
                return items is None and self.reply(404, {})
            start = int(parse_qs(urlparse(self.path).query).get("pageToken", ["0"])[0])
            page = items[start:start + 7]  # (páginas cortas: obliga a seguir el nextPageToken)
            body = {field: page}
            if start + 7 < len(items):
                body["nextPageToken"] = str(start + 7)
            self.reply(200, body)

        def do_POST(self):
            items, id_field, _, path = self.kind()
            if items is None or not self.check_key():
                return items is None and self.reply(404, {})
            fields = self.fields()
            state.log.append(("POST", id_field, fields))
            if state.fail_at is not None and len([e for e in state.log if e[0] == "POST"]) == state.fail_at:
                return self.reply(429, {"message": "demasiadas peticiones"})
            if not fields.get("name") or len(fields["name"]) > 50 or any(i["name"] == fields["name"] for i in items):
                return self.reply(400, {"message": "nombre no válido o repetido"})
            state.next_id += 1
            item = {id_field: state.next_id, "name": fields["name"], "priceInformation": {"defaultPriceInRobux": int(fields["price"])}}
            items.append(item)
            self.reply(200, item)

        def do_PATCH(self):
            items, id_field, _, path = self.kind()
            if items is None or not self.check_key():
                return items is None and self.reply(404, {})
            fields = self.fields()
            state.log.append(("PATCH", id_field, fields))
            for item in items:
                if str(item[id_field]) == path.rsplit("/", 1)[1]:
                    if "price" in fields:
                        item["priceInformation"]["defaultPriceInRobux"] = int(fields["price"])
                    return self.reply(204)
            self.reply(404, {})

    return Handler


def run(state, *args):
    """Ejecuta el script con esos argumentos; devuelve (lo que ha impreso, las peticiones nuevas)."""
    before = len(state.log)
    sys.argv = ["crear_productos.py"] + list(args)
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        try:
            cp.main()
        except SystemExit:
            pass
    return out.getvalue(), state.log[before:]


def fresh_ids():
    copy = os.path.join(tempfile.mkdtemp(), "ProductIds.luau")
    shutil.copy(REAL_IDS, copy)
    # (la copia empieza siempre a 0, aunque el archivo real ya tenga ids)
    import re
    text = io.open(copy, encoding="utf-8", newline="").read()
    io.open(copy, "w", encoding="utf-8", newline="").write(re.sub(r"= \d+,", "= 0,", text))
    cp.IDS_FILE = copy
    return copy


def zeros(path):
    return io.open(path, encoding="utf-8").read().count(" = 0,")


def main():
    failures = []

    def check(name, ok):
        print(("ok    " if ok else "FALLO ") + name)
        if not ok:
            failures.append(name)

    state = Fake()
    server = HTTPServer(("127.0.0.1", 0), handler(state))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    cp.API = "http://127.0.0.1:%d" % server.server_port
    cp.time.sleep = lambda seconds: None
    os.environ["ROBLOX_API_KEY"] = FAKE_KEY
    os.environ["ROBLOX_UNIVERSE_ID"] = "123"
    total = len(CATALOG)
    ids = fresh_ids()

    text, calls = run(state)
    check("sin --crear no crea nada ni toca el archivo", calls == [] and zeros(ids) == total and text.count("CREARIA") == total)

    text, calls = run(state, "--crear", "--regional", "--iconos")
    posts = [c for c in calls if c[0] == "POST"]
    check("--crear crea los %d (38 productos y 1 pase)" % total, len(posts) == total and len(state.products) == total - 1 and len(state.passes) == 1)
    check("cada uno con su nombre, precio y descripción", all(
        any(f["name"] == item["name"] and int(f["price"]) == item["price"] and f["description"] == item["description"] and f["isForSale"] == "true" for _, _, f in posts)
        for item in CATALOG))
    check("--regional y --iconos se envían en todos", all(f.get("isRegionalPricingEnabled") == "true" and f.get("imageFile", b"")[:4] == b"\x89PNG" for _, _, f in posts))
    written = io.open(ids, encoding="utf-8").read()
    check("todos los ids quedan escritos", zeros(ids) == 0 and "VIP = %d," % state.passes[0]["gamePassId"] in written
        and all('["%s"] = %d,' % (i["key"], next(p["productId"] for p in state.products if p["name"] == i["name"])) in written for i in CATALOG if i["type"] != "GamePass"))

    text, calls = run(state, "--crear")
    check("repetirlo no duplica nada", calls == [] and text.count("ya existe") == total)

    state.products[3]["priceInformation"]["defaultPriceInRobux"] = 1
    text, calls = run(state, "--crear")
    check("avisa de un precio distinto sin tocarlo", calls == [] and "precio en Roblox: 1" in text)
    text, calls = run(state, "--crear", "--precios")
    check("--precios lo corrige", len(calls) == 1 and calls[0][0] == "PATCH" and state.products[3]["priceInformation"]["defaultPriceInRobux"] == CATALOG[3]["price"])

    text, calls = run(state, "--crear", "--regional", "--iconos")
    check("--regional y --iconos se aplican tambien a los que ya existen", len(calls) == total and all(
        c[0] == "PATCH" and c[2].get("isRegionalPricingEnabled") == "true" and c[2].get("imageFile", b"")[1:4] == b"PNG" for c in calls))

    ids = fresh_ids()
    text, calls = run(state, "--apuntar")
    check("--apuntar escribe los ids sin crear", calls == [] and zeros(ids) == 0)

    os.environ["ROBLOX_API_KEY"] = "otra"
    ids = fresh_ids()
    text, calls = run(state, "--crear")
    check("con la clave mal se para y no escribe nada", "ERROR" in text and zeros(ids) == total)
    os.environ["ROBLOX_API_KEY"] = FAKE_KEY

    state.products, state.passes, state.log, state.fail_at = [], [], [], 5
    ids = fresh_ids()
    text, calls = run(state, "--crear")
    check("si Roblox falla a mitad, se para y apunta lo ya creado", len(calls) == 5 and zeros(ids) == total - 4 and "FALLO" in text)
    state.fail_at = None
    text, calls = run(state, "--crear")
    check("y al repetir termina lo que faltaba", len(calls) == total - 4 and zeros(ids) == 0 and len(state.products) == total - 1)

    server.shutdown()
    print("%d de %d · %s" % (13 - len(failures), 13, "OK" if not failures else "FALLOS"))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
