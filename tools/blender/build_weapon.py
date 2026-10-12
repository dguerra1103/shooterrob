# Construye un arma de SHOOTERROB en Blender, la exporta y saca sus renders.
#   blender -b -P tools/blender/build_weapon.py -- arx27            (renders de diagnóstico)
#   blender -b -P tools/blender/build_weapon.py -- arx27 --final    (renders finales 1080p)
#   blender -b -P tools/blender/build_weapon.py -- arx27 --no-render
# Salida: assets/weapons/<ARMA>/{<ARMA>.blend, .fbx, .glb, .mesh.json, renders/*.png}
import importlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

import sr_kit  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if not args:
    raise SystemExit("falta el nombre del arma")
module = importlib.import_module("weapons." + args[0].lower())
final = "--final" in args
weapon = sr_kit.Weapon(module.NAME, getattr(module, "PALETTE", None))
module.build(weapon)
out_dir = os.path.join(ROOT, "assets", "weapons", module.NAME)
stats = weapon.export(out_dir)
print("SR_STATS " + json.dumps(stats))
if "--no-render" not in args:
    renders = weapon.render_set(os.path.join(out_dir, "renders" if final else "renders_diag"), final)
    print("SR_RENDERS " + json.dumps(renders))
