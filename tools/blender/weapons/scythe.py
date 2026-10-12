# GUADAÑA (Halloween) · guadaña de segador con detalles técnicos (cuerpo a cuerpo).
# Misma orientación que el diseño clásico: el mango va a lo largo de Z (la cabeza hacia -Z), la mano
# lo coge en z = 0.45 y la hoja sale de la cabeza hacia +X y se curva hacia atrás (+Z), tumbada en el
# plano XZ (fina en Y).
# Silueta: media luna grande de acero en cinco tramos con el filo interior verde luminoso, abrazadera
# naranja en forma de ala de murciélago con un ojo luminoso, pincho en el lomo, mango oscuro con dos
# empuñaduras de goma, virola de acero y regatón.
import math

import bmesh
from mathutils import Vector

import sr_kit

NAME = "Scythe"

PALETTE = {
    "Body": (0.03, 0.028, 0.045),  # mango casi negro, algo morado
    "Panel": (1.0, 0.19, 0.006),  # naranja calabaza 255,120,20
    "Accent": (0.05, 0.9, 0.02),  # verde tóxico (en el juego 120,255,80; aquí más saturado: la emisión lo aclara)
    "Dark": (0.014, 0.013, 0.02),
    "Metal": (0.5, 0.52, 0.58),
    "Rubber": (0.02, 0.02, 0.025),
}


def flat(w, name, points, thickness, role, y=0.0):
    """Como Weapon.profile, pero la silueta [(x, z), ...] está en el plano XZ y se extruye en Y (la
    hoja de la guadaña va tumbada). Deja las mismas cuñas para Roblox que deja el kit."""
    bm = bmesh.new()
    h = thickness / 2
    low = [bm.verts.new(sr_kit.g2b((px, y - h, pz))) for px, pz in points]
    high = [bm.verts.new(sr_kit.g2b((px, y + h, pz))) for px, pz in points]
    bm.faces.new(low)
    bm.faces.new(list(reversed(high)))
    n = len(points)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((low[j], low[i], high[i], high[j]))
    for tri in sr_kit._triangulate(points):
        pts = [Vector((px, y, pz)) for px, pz in tri]
        best = max(range(3), key=lambda i: (pts[(i + 1) % 3] - pts[i]).length)
        p, q, r = pts[best], pts[(best + 1) % 3], pts[(best + 2) % 3]
        base = q - p
        foot = p + base * ((r - p).dot(base) / base.length_squared)
        for end in (p, q):
            leg_a, leg_b = end - foot, r - foot
            if leg_a.length < 0.004 or leg_b.length < 0.004:
                continue
            ya = leg_b.normalized()
            za = -leg_a.normalized()
            xa = ya.cross(za)
            rot = [xa.x, ya.x, za.x, xa.y, ya.y, za.y, xa.z, ya.z, za.z]
            w._solid("W", role, None, tuple((end + r) / 2), (thickness, leg_b.length, leg_a.length), rot)
    return w._finish(bm, name, role, None, 0.0)


def strip(w, name, a, b, width, thickness, role, y=0.0):
    """Listón entre dos puntos (x, z) del plano de la hoja."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dz)
    angle = math.degrees(math.atan2(-dz, dx))
    w.box(name, ((a[0] + b[0]) / 2, y, (a[1] + b[1]) / 2), (length, thickness, width), role, 0.0, rot=(0, angle, 0))


# Lomo (arco exterior) y filo (arco interior) de la media luna, en (x, z)
OUTER = [(0.04, -1.70), (0.50, -1.77), (0.95, -1.67), (1.30, -1.38), (1.47, -1.00)]
INNER = [(0.08, -1.30), (0.48, -1.38), (0.80, -1.30), (1.05, -1.11), (1.24, -0.90)]
TIP = (1.49, -0.52)


def build(w):
    # ---------------------------------------------------------------- mango (eje Z)
    w.cyl("Shaft", (0, 0, -1.80), (0, 0, 0.84), 0.055, "Body", 8)
    w.cyl("Socket", (0, 0, -1.78), (0, 0, -1.02), 0.092, "Dark", 8)
    w.cyl("Finial", (0, 0, -1.84), (0, 0, -1.78), 0.075, "Metal", 8)
    w.cyl("Ferrule", (0, 0, -1.02), (0, 0, -0.84), 0.074, "Metal", 8)
    w.cyl("FerruleGlow", (0, 0, -0.84), (0, 0, -0.805), 0.08, "Accent", 8)
    # Empuñadura delantera
    w.cyl("GripFront", (0, 0, -0.52), (0, 0, -0.14), 0.074, "Rubber", 8)
    w.cyl("GripFrontRingA", (0, 0, -0.555), (0, 0, -0.52), 0.088, "Panel", 8)
    w.cyl("GripFrontRingB", (0, 0, -0.14), (0, 0, -0.105), 0.088, "Panel", 8)
    # Empuñadura principal (la mano derecha en z = 0.45)
    w.cyl("GripMain", (0, 0, 0.22), (0, 0, 0.72), 0.078, "Rubber", 8)
    w.cyl("GripMainRingA", (0, 0, 0.185), (0, 0, 0.22), 0.092, "Panel", 8)
    w.cyl("GripMainRingB", (0, 0, 0.72), (0, 0, 0.755), 0.092, "Panel", 8)
    # Regatón
    w.cyl("ButtCap", (0, 0, 0.80), (0, 0, 0.88), 0.086, "Metal", 8)
    w.cyl("ButtSpike", (0, 0, 0.88), (0, 0, 0.92), 0.045, "Accent", 6)

    # ---------------------------------------------------------------- hoja
    for i in range(4):
        flat(w, f"Blade{i}", [OUTER[i], OUTER[i + 1], INNER[i + 1], INNER[i]], 0.05, "Metal")
    flat(w, "BladeTip", [OUTER[4], TIP, INNER[4]], 0.05, "Metal")
    # Púa en el lomo de la hoja
    flat(w, "SpineBarb", [(0.78, -1.71), (1.04, -1.60), (1.06, -1.88)], 0.05, "Metal")
    # Filo luminoso por dentro de la curva
    edge = INNER + [TIP]
    for i in range(5):
        strip(w, f"Edge{i}", edge[i], edge[i + 1], 0.07, 0.032, "Accent")
    # Vaciado oscuro en el centro de los primeros tramos
    mid = [((o[0] + n[0]) / 2, (o[1] + n[1]) / 2 - 0.03) for o, n in zip(OUTER, INNER)]
    strip(w, "Fuller0", (0.62, mid[1][1] + 0.01), mid[2], 0.07, 0.058, "Dark")
    strip(w, "Fuller1", mid[2], mid[3], 0.06, 0.058, "Dark")

    # ---------------------------------------------------------------- abrazadera de ala de murciélago
    flat(w, "Bracket", [(0.0, -1.78), (0.34, -1.83), (0.64, -1.77), (0.46, -1.60), (0.56, -1.20), (0.32, -1.42), (0.30, -1.00), (0.13, -1.30), (0.0, -1.12)], 0.14, "Panel")
    w.cyl("EyeRim", (0.24, -0.082, -1.61), (0.24, 0.082, -1.61), 0.105, "Dark", 8)
    w.cyl("Eye", (0.24, -0.094, -1.61), (0.24, 0.094, -1.61), 0.065, "Accent", 8)
    # Pincho del lomo (hacia -X) con su placa
    flat(w, "BackPlate", [(-0.02, -1.76), (-0.02, -1.38), (-0.24, -1.60)], 0.14, "Panel")
    flat(w, "BackSpike", [(-0.04, -1.72), (-0.04, -1.50), (-0.52, -1.74)], 0.05, "Metal")

    # Punta de lanza en lo alto
    flat(w, "TopSpike", [(-0.07, -1.82), (0.07, -1.82), (0.0, -1.96)], 0.05, "Metal")

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (TIP[0], 0, TIP[1]))
    w.point("AimPoint", (TIP[0], 0, TIP[1]))
    w.point("Eject", (0.24, 0.1, -1.61))
    w.point("RightHand", (0, 0, 0.45))
    w.point("LeftHand", (0, 0, 0.62))
    w.point("CharmPoint", (0, 0, 0.90))
