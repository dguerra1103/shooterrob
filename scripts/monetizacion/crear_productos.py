#!/usr/bin/env python3
"""Crea en Roblox todos los productos de pago de SHOOTERROB y apunta sus ids en el juego.

Lee scripts/monetizacion/productos.json (generado desde la configuracion del juego), crea los
Developer Products y el Game Pass que falten con Open Cloud y escribe los ids en
src/shared/Economy/ProductIds.luau.

    Sin argumentos   -> solo ENSENA lo que haria (no crea nada).
    --crear          -> crea los que falten y escribe los ids.
    --apuntar        -> sin crear nada, escribe los ids de los que ya existen en Roblox.
    --precios        -> con --crear, corrige el precio de los que ya existan y no coincida.
    --regional       -> con --crear, activa los precios regionales de Roblox en lo que se cree
                        (Roblox baja el precio en paises con menos poder de compra).

Necesita dos variables de entorno (la clave NUNCA se escribe en ningun archivo):
    ROBLOX_API_KEY       clave de Open Cloud con permisos developer-product:read, developer-product:write,
                         game-pass:read y game-pass:write sobre la experiencia
    ROBLOX_UNIVERSE_ID   id del universo (la experiencia)

Es seguro repetirlo: lo que ya existe (mismo nombre) no se vuelve a crear, solo se apunta su id.
"""
import io
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CATALOG = os.path.join(ROOT, "scripts", "monetizacion", "productos.json")
IDS_FILE = os.path.join(ROOT, "src", "shared", "Economy", "ProductIds.luau")
API = "https://apis.roblox.com"


def fail(text):
    print("ERROR: " + text)
    sys.exit(1)


def request(method, url, key, fields=None):
    headers = {"x-api-key": key}
    data = None
    if fields is not None:
        boundary = "----shooterrob" + uuid.uuid4().hex
        body = io.BytesIO()
        for name, value in fields.items():
            if isinstance(value, bool):
                value = "true" if value else "false"
            part = '--%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n' % (boundary, name, value)
            body.write(part.encode("utf-8"))
        body.write(("--%s--\r\n" % boundary).encode("utf-8"))
        data = body.getvalue()
        headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=40) as response:
            raw = response.read().decode("utf-8")
            return response.status, (json.loads(raw) if raw.strip() else {})
    except urllib.error.HTTPError as error:
        return error.code, {"error": error.read().decode("utf-8", "replace")[:600]}
    except urllib.error.URLError as error:
        return 0, {"error": str(error)}


def list_all(url, key, field):
    items, token = [], None
    while True:
        page = url + "?pageSize=50" + ("&pageToken=" + token if token else "")
        status, body = request("GET", page, key)
        if status != 200:
            fail("no se ha podido leer la lista (%s): %s" % (status, body.get("error")))
        items += body.get(field) or []
        token = body.get("nextPageToken")
        if not token:
            return items
        time.sleep(0.15)


def current_price(config):
    info = config.get("priceInformation") or {}
    return info.get("defaultPriceInRobux")


def write_ids(found):
    text = io.open(IDS_FILE, encoding="utf-8", newline="").read()
    written = 0
    for key, value in found.items():
        if key == "VIP":
            pattern = r"(\bVIP = )\d+(,)"
        else:
            pattern = r'(\["%s"\] = )\d+(,)' % re.escape(key)
        new, count = re.subn(pattern, lambda m, v=value: "%s%d%s" % (m.group(1), v, m.group(2)), text, count=1)
        if count == 1:
            text, written = new, written + 1
        else:
            print("  AVISO: no encuentro la linea de %s en ProductIds.luau" % key)
    io.open(IDS_FILE, "w", encoding="utf-8", newline="").write(text)
    return written


def main():
    create = "--crear" in sys.argv
    note_only = "--apuntar" in sys.argv
    fix_prices = "--precios" in sys.argv
    regional = "--regional" in sys.argv
    if not os.path.exists(CATALOG):
        fail("falta %s (se genera con tools/economy/productos.luau)" % CATALOG)
    catalog = json.load(io.open(CATALOG, encoding="utf-8"))
    key = os.environ.get("ROBLOX_API_KEY", "").strip()
    universe = os.environ.get("ROBLOX_UNIVERSE_ID", "").strip()
    if not key or not universe.isdigit():
        print(__doc__)
        fail("faltan ROBLOX_API_KEY y ROBLOX_UNIVERSE_ID en el entorno")

    products_url = "%s/developer-products/v2/universes/%s/developer-products" % (API, universe)
    passes_url = "%s/game-passes/v1/universes/%s/game-passes" % (API, universe)
    existing_products = {p.get("name"): p for p in list_all(products_url + "/creator", key, "developerProducts")}
    existing_passes = {p.get("name"): p for p in list_all(passes_url + "/creator", key, "gamePasses")}
    print("En Roblox ahora: %d Developer Products y %d Game Passes" % (len(existing_products), len(existing_passes)))

    found, todo = {}, 0
    for item in catalog:
        is_pass = item["type"] == "GamePass"
        existing = (existing_passes if is_pass else existing_products).get(item["name"])
        id_field = "gamePassId" if is_pass else "productId"
        base = passes_url if is_pass else products_url
        if existing:
            found[item["key"]] = existing[id_field]
            price = current_price(existing)
            differs = price not in (None, item["price"])
            note = "  (precio en Roblox: %s; en el juego: %s)" % (price, item["price"]) if differs else ""
            print("  ya existe  %-28s %s%s" % (item["key"], existing[id_field], note))
            if differs and fix_prices and create:
                status, body = request("PATCH", "%s/%s" % (base, existing[id_field]), key, {"price": item["price"]})
                if status in (200, 204):
                    print("             precio corregido")
                else:
                    print("             no se ha podido corregir (%s): %s" % (status, body.get("error")))
                time.sleep(0.4)
            continue
        todo += 1
        if not create:
            print("  CREARIA    %-28s R$ %-4s %s" % (item["key"], item["price"], item["name"]))
            continue
        fields = {"name": item["name"], "description": item["description"], "price": item["price"], "isForSale": True}
        if regional:
            fields["isRegionalPricingEnabled"] = True
        status, body = request("POST", base, key, fields)
        if status not in (200, 201) or not body.get(id_field):
            print("  FALLO      %-28s (%s): %s" % (item["key"], status, body.get("error") or body))
            print("Se para aqui. Lo ya creado queda apuntado; se puede repetir el comando.")
            break
        found[item["key"]] = body[id_field]
        print("  creado     %-28s %s" % (item["key"], body[id_field]))
        time.sleep(0.4)  # (limite de la API: 3 escrituras por segundo)

    if (create or note_only) and found:
        written = write_ids(found)
        print("Ids escritos en src/shared/Economy/ProductIds.luau: %d de %d productos" % (written, len(catalog)))
    if not create:
        print("")
        print("No se ha creado nada (%d por crear). Para crearlos: python scripts/monetizacion/crear_productos.py --crear" % todo)


if __name__ == "__main__":
    main()
