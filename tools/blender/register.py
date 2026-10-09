# Registra armas con modelo nuevo en el juego (WeaponMeshKit.Weapons, WeaponVisual.Weapons y su paleta de
# fábrica en Weapons.luau/CLASSIC_LOOK):  python -X utf8 tools/blender/register.py Specter9[:Paleta] ...
import io
import re
import sys

import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))).replace("\\", "/") + "/"


def load(p):
    return io.open(ROOT + p, encoding="utf-8", newline="").read()


def save(p, s):
    io.open(ROOT + p, "w", encoding="utf-8", newline="").write(s)


for arg in sys.argv[1:]:
    name, _, look = arg.partition(":")
    look = look or "Pulse"
    # 1) WeaponMeshKit.Weapons
    p = "src/shared/WeaponMeshKit.luau"
    s = load(p)
    m = re.search(r"WeaponMeshKit\.Weapons = \{([^}]*)\}", s)
    names = [n.strip().strip('"') for n in m.group(1).split(",") if n.strip()]
    if name not in names:
        names.append(name)
        s = s.replace(m.group(0), "WeaponMeshKit.Weapons = { " + ", ".join('"%s"' % n for n in names) + " }")
        save(p, s)
    # 2) WeaponVisual.Weapons
    p = "src/shared/WeaponVisual.luau"
    s = load(p)
    if not re.search(r"\n\t%s = \{ Model = " % name, s):
        m = re.search(r"\tARX27 = \{ Model = \"ARX27\" \},[^\n]*\n", s)
        s = s.replace(m.group(0), m.group(0) + '\t%s = { Model = "%s" },\n' % (name, name).replace("\n", "\r\n" if "\r\n" in s else "\n") if False else m.group(0) + ('\t%s = { Model = "%s" },' % (name, name)) + ("\r\n" if "\r\n" in s else "\n"))
        save(p, s)
    # 3) Paleta de fábrica
    p = "src/shared/Weapons.luau"
    s = load(p)
    s2, n = re.subn(r'(\b%s = )"[A-Za-z]+"' % name, r'\1"%s"' % look, s, count=1)
    assert n == 1, "no encuentro %s en CLASSIC_LOOK" % name
    save(p, s2)
    print("registrada", name, look)
