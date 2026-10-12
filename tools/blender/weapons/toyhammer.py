# MARTILLO DE JUGUETE · mazo de feria que pita, convertido en arma arcade (cuerpo a cuerpo).
# Misma orientación que el diseño clásico: el mango va a lo largo de Z (la cabeza hacia -Z), la cabeza
# es un cilindro a lo largo de X centrado en z = -0.75 y la mano coge el mango en z = 0.35.
# Silueta: cabeza enorme roja con tapas amarillas y estrella blanca en cada cara, casquillo con anillo
# luminoso, mango amarillo con rayas de caramelo, empuñadura de goma azul con nervios y pomo redondo.
import math

NAME = "ToyHammer"

PALETTE = {
    "Panel": (0.83, 0.032, 0.026),  # rojo 235,50,45
    "Accent2": (1.0, 0.61, 0.021),  # amarillo 255,205,40
    "Trim": (0.032, 0.19, 1.0),  # azul 50,120,255
    "Accent": (0.85, 0.95, 1.0),  # blanco luminoso (anillo del casquillo y estrellas)
    "Rubber": (0.012, 0.035, 0.16),  # goma azul marino
    "Dark": (0.02, 0.02, 0.028),
}

HZ = -0.75  # centro de la cabeza


def build(w):
    # ---------------------------------------------------------------- cabeza (eje X)
    w.cyl("HeadCore", (-0.40, 0, HZ), (0.40, 0, HZ), 0.32, "Panel", 12)
    for s in (-1, 1):
        n = "L" if s < 0 else "R"
        w.cyl(f"Bellows{n}", (s * 0.235, 0, HZ), (s * 0.29, 0, HZ), 0.338, "Dark", 12)
        w.cyl(f"Cap{n}", (s * 0.37, 0, HZ), (s * 0.56, 0, HZ), 0.365, "Accent2", 12)
        w.cyl(f"Face{n}", (s * 0.56, 0, HZ), (s * 0.58, 0, HZ), 0.265, "Panel", 12)
    # Estrella blanca: una sola silueta que atraviesa la cabeza y asoma por las dos caras
    star = []
    for i in range(10):
        ang = math.pi / 2 + i * math.pi / 5
        r = 0.215 if i % 2 == 0 else 0.092
        star.append((HZ - r * math.cos(ang), r * math.sin(ang)))
    w.profile("Star", star, 1.20, "Accent", 0.0)
    # Dos rayas luminosas a lo largo del cuerpo rojo (arriba y abajo)
    for i, y in enumerate((0.312, -0.312)):
        w.box(f"BodyDash{i}", (0, y, HZ), (0.36, 0.04, 0.07), "Accent", 0.0)
    # Válvula del pito, en lo alto de la cabeza
    w.cyl("Squeaker", (0, 0, HZ - 0.33), (0, 0, HZ - 0.385), 0.075, "Dark", 6)
    w.cyl("SqueakerTip", (0, 0, HZ - 0.385), (0, 0, HZ - 0.42), 0.045, "Trim", 6)

    # ---------------------------------------------------------------- casquillo y mango (eje Z)
    w.cyl("Socket", (0, 0, -0.47), (0, 0, -0.33), 0.15, "Accent2", 10)
    w.cyl("GlowRing", (0, 0, -0.33), (0, 0, -0.285), 0.128, "Accent", 10)
    w.cyl("Collar", (0, 0, -0.285), (0, 0, -0.22), 0.105, "Dark", 6)
    w.cyl("Shaft", (0, 0, -0.46), (0, 0, 0.60), 0.078, "Accent2", 8)
    for i, z in enumerate((-0.12, 0.02)):
        w.cyl(f"Stripe{i}", (0, 0, z - 0.035), (0, 0, z + 0.035), 0.084, "Panel", 8)

    # ---------------------------------------------------------------- empuñadura y pomo
    w.cyl("GripGuard", (0, 0, 0.11), (0, 0, 0.15), 0.135, "Trim", 8)
    w.cyl("Grip", (0, 0, 0.15), (0, 0, 0.57), 0.10, "Rubber", 8)
    for i, z in enumerate((0.24, 0.36, 0.48)):
        w.cyl(f"GripRib{i}", (0, 0, z - 0.03), (0, 0, z + 0.03), 0.114, "Trim", 8)
    w.cyl("Pommel", (0, 0, 0.57), (0, 0, 0.68), 0.15, "Accent2", 10)
    w.cyl("PommelCap", (0, 0, 0.68), (0, 0, 0.71), 0.105, "Panel", 8)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0, HZ))
    w.point("AimPoint", (0, 0, HZ))
    w.point("Eject", (0.58, 0, HZ))
    w.point("RightHand", (0, 0, 0.35))
    w.point("LeftHand", (0, 0, 0.50))
    w.point("CharmPoint", (0, 0, 0.71))
