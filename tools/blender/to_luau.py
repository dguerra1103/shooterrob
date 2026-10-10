# Convierte assets/weapons/<ARMA>/<ARMA>.mesh.json (salida del kit de Blender) en el módulo Luau que usa
# el juego: src/shared/WeaponMeshes/<ARMA>.luau
#   python tools/blender/to_luau.py ARX27 [HAVOC ...]
# El juego no puede cargar la malla de Blender sin subirla como recurso, así que el arma viaja como su
# descomposición en primitivas (bloques, cuñas y cilindros: la misma silueta, sin los chaflanes) y el
# servidor las funde en una sola pieza por grupo (papel + pieza móvil). Ver Shared/WeaponMeshKit.
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
POINT_ORDER = ["Muzzle", "AimPoint", "Eject", "RightHand", "LeftHand", "CharmPoint"]


def num(v):
    text = ("%.4f" % v).rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def convert(name):
    src = os.path.join(ROOT, "assets", "weapons", name, name + ".mesh.json")
    data = json.load(open(src, encoding="utf-8"))
    groups = {}
    for solid in data["solids"]:
        groups.setdefault((solid.get("piece") or "", solid["role"]), []).append(solid)
    lines = [
        "-- GENERADO por tools/blender/to_luau.py a partir de assets/weapons/%s/%s.mesh.json. No editar a mano:" % (name, name),
        "-- el arma se modela en tools/blender/weapons/%s.py y se regenera." % name.lower(),
        "-- Cada primitiva: forma (B bloque, W cuña, C cilindro), tamaño (3), centro (3) y rotación (9).",
        "return {",
        '\tName = "%s",' % name,
        "\tPoints = {",
    ]
    # (los puntos propios de un arma, como las bocas de fuego Vent del Inferno AR, van detrás)
    for key in POINT_ORDER + sorted(k for k in data["points"] if k not in POINT_ORDER):
        if key in data["points"]:
            p = data["points"][key]
            lines.append("\t\t%s = Vector3.new(%s, %s, %s)," % (key, num(p[0]), num(p[1]), num(p[2])))
    lines += ["\t},", "\tGroups = {"]
    count = 0
    for (piece, role), solids in sorted(groups.items()):
        lines.append('\t\t{ Name = "%s", Role = "%s", %sPrims = {' % ((piece + role) if piece else role, role, ('Piece = "%s", ' % piece) if piece else ""))
        for s in solids:
            values = s["size"] + s["c"] + s["r"]
            lines.append('\t\t\t{ "%s", %s },' % (s["s"], ", ".join(num(v) for v in values)))
            count += 1
        lines.append("\t\t} },")
    lines += ["\t},", "}", ""]
    out_dir = os.path.join(ROOT, "src", "shared", "WeaponMeshes")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, name + ".luau")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("%s: %d grupos, %d primitivas -> %s (%d bytes)" % (name, len(groups), count, os.path.relpath(out, ROOT), os.path.getsize(out)))


for weapon in sys.argv[1:]:
    convert(weapon)
