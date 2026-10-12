# Tabla en Markdown de los productos (para MONETIZACION.md):  python -X utf8 scripts/monetizacion/tabla.py
import io
import json
import os

here = os.path.dirname(os.path.abspath(__file__))
catalog = json.load(io.open(os.path.join(here, "productos.json"), encoding="utf-8"))
print("| Nombre en Roblox | Tipo | Precio (R$) | Clave en ProductIds |")
print("|---|---|---|---|")
for p in catalog:
    kind = "Game Pass" if p["type"] == "GamePass" else "Developer Product"
    print("| {} | {} | {} | `{}` |".format(p["name"], kind, p["price"], p["key"]))
