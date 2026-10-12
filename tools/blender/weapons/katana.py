# KATANA · katana táctica de ciencia ficción (cuerpo a cuerpo de SHOOTERROB).
# Silueta: hoja larga de un solo filo con una curva suave hecha de cuatro tramos rectos, lomo oscuro
# superpuesto, línea de filo luminosa, tsuba cuadrada carmesí, mango largo a dos manos con rombos
# alternos (carmesí / oscuro) y pomo con casquillo.
# Orientación del juego: la hoja va hacia -Z, el filo hacia -Y, la punta sube hacia +Y; el origen está
# en el mango (la mano derecha en z = 0.15).
import math

NAME = "Katana"

PALETTE = {
    "Body": (0.045, 0.048, 0.062),
    "Panel": (0.68, 0.022, 0.032),  # carmesí (≈ RGB 215, 40, 50)
    "Accent": (0.1, 0.9, 1.0),  # cian
    "Dark": (0.018, 0.018, 0.024),
    "Metal": (0.78, 0.8, 0.86),
    "Rubber": (0.03, 0.031, 0.038),
}

# Lomo (arriba) y filo (abajo) de la hoja en el plano lateral (z, y)
SPINE = [(-0.44, 0.10), (-1.06, 0.111), (-1.66, 0.142), (-2.25, 0.195), (-2.76, 0.262)]
EDGE = [(-0.44, -0.115), (-1.06, -0.104), (-1.66, -0.066), (-2.25, 0.0), (-2.56, 0.055)]


def strip(w, name, line, offset, height, width, role, trim=0.0):
    """Tira de cajas que sigue una línea quebrada (z, y), desplazada `offset` en Y."""
    for i in range(len(line) - 1):
        (z0, y0), (z1, y1) = line[i], line[i + 1]
        length = math.hypot(z1 - z0, y1 - y0)
        angle = math.degrees(math.atan2(y1 - y0, z0 - z1))
        w.box(f"{name}{i}", (0, (y0 + y1) / 2 + offset, (z0 + z1) / 2), (width, height, length - trim), role, 0.0, rot=(angle, 0, 0))


def build(w):
    # ---------------------------------------------------------------- hoja
    w.profile("Blade", SPINE + list(reversed(EDGE)), 0.04, "Metal", 0.0)
    # Lomo oscuro superpuesto (hasta el arranque de la punta) y línea de filo luminosa
    strip(w, "Spine", SPINE[:4] + [(-2.50, 0.228)], -0.03, 0.075, 0.056, "Body", trim=-0.01)
    strip(w, "EdgeGlow", EDGE, 0.034, 0.02, 0.05, "Accent", trim=-0.004)
    # El brillo sigue por el filo de la punta (kissaki)
    w.box("TipGlow", (0, 0.169, -2.648), (0.05, 0.02, 0.20), "Accent", 0.0, rot=(46, 0, 0))
    # Muescas tácticas en el lomo, junto al habaki
    for i, z in enumerate((-0.66, -0.76)):
        w.box(f"SpineNotch{i}", (0, 0.10, z), (0.062, 0.05, 0.035), "Panel", 0.0, rot=(-25, 0, 0))
    w.box("Habaki", (0, -0.005, -0.50), (0.07, 0.25, 0.14), "Metal", 0.0)
    w.box("HabakiBand", (0, -0.005, -0.53), (0.078, 0.258, 0.03), "Dark", 0.0)

    # ---------------------------------------------------------------- tsuba cuadrada
    w.box("Tsuba", (0, 0.0, -0.38), (0.44, 0.42, 0.06), "Panel", 0.018)
    w.box("TsubaCore", (0, 0.0, -0.38), (0.30, 0.28, 0.085), "Dark", 0.0)
    w.box("TsubaGlow", (0, 0.0, -0.38), (0.452, 0.05, 0.022), "Accent", 0.0)

    # ---------------------------------------------------------------- mango a dos manos
    w.box("Handle", (0, 0.0, 0.10), (0.15, 0.20, 0.90), "Rubber", 0.022)
    w.box("Fuchi", (0, 0.0, -0.31), (0.17, 0.22, 0.08), "Metal", 0.0)
    w.box("HandleStripe", (0, 0.101, 0.11), (0.05, 0.012, 0.66), "Panel", 0.0)
    for i in range(6):
        w.box(f"Diamond{i}", (0, 0.0, -0.20 + i * 0.13), (0.166, 0.085, 0.085), "Panel" if i % 2 == 0 else "Dark", 0.0, rot=(45, 0, 0))

    # ---------------------------------------------------------------- pomo (kashira)
    w.box("PommelBand", (0, 0.0, 0.535), (0.172, 0.222, 0.035), "Panel", 0.0)
    w.profile("Pommel", [(0.55, 0.115), (0.62, 0.115), (0.66, 0.05), (0.66, -0.08), (0.62, -0.125), (0.55, -0.125)], 0.18, "Metal", 0.012)
    w.box("PommelGlow", (0, -0.005, 0.662), (0.07, 0.07, 0.012), "Accent", 0.0)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0.262, -2.76))
    w.point("AimPoint", (0, 0.262, -2.76))
    w.point("Eject", (0.1, 0.0, -0.38))
    w.point("RightHand", (0, 0, 0.15))
    w.point("LeftHand", (0, 0, 0.40))
    w.point("CharmPoint", (0, -0.005, 0.67))
