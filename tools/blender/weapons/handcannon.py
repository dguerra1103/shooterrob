# HAND CANNON · revólver magnum sobredimensionado (secundaria pesada de SHOOTERROB).
# Silueta: cañón largo y alto de costados planos con contrapeso completo y banda ventilada, tambor
# hexagonal de acero (tres bloques girados: sobrevive tal cual en Roblox), armazón oscuro con escudo
# de retroceso, martillo a la vista, empuñadura gruesa e inclinada con cacha roja, cantonera de acero
# y anilla de correa. Sin piezas móviles (el diseño del juego no tiene corredera ni cargador).
import math

NAME = "HandCannon"

PALETTE = {
    "Body": (0.045, 0.048, 0.06),
    "Panel": (0.58, 0.022, 0.022),  # rojo profundo (sRGB 200, 40, 40)
    "Accent": (1.0, 0.62, 0.12),  # ámbar
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.82, 0.84, 0.9),  # acero cepillado
    "Rubber": (0.03, 0.03, 0.036),
}

BORE_Y = 0.06
CYL_Y = -0.04  # eje del tambor
CYL_A = 0.215  # apotema del hexágono
CYL_Z0, CYL_Z1 = -0.29, 0.09


def build(w):
    # ---------------------------------------------------------------- cañón (acero)
    w.profile("Barrel", [(-0.44, 0.19), (-1.385, 0.19), (-1.415, 0.16), (-1.415, -0.03), (-1.30, -0.17), (-0.44, -0.17)], 0.17, "Metal", 0.02)
    w.ring("MuzzleCrown", (0, BORE_Y, -1.37), (0, BORE_Y, -1.43), 0.078, 0.046, "Metal", 10)
    w.cyl("Bore", (0, BORE_Y, -1.40), (0, BORE_Y, -1.426), 0.046, "Dark", 10)
    w.box("MuzzleBlock", (0, 0.065, -1.31), (0.192, 0.262, 0.12), "Body", 0.012)
    w.cyl("EjectorRod", (0, -0.105, -1.27), (0, -0.105, -1.37), 0.036, "Dark", 8)
    for side in (-1, 1):
        x = side * 0.086
        w.box(f"Fuller{side}", (x, BORE_Y, -0.88), (0.012, 0.075, 0.62), "Dark", 0.0)
        w.box(f"FullerGlow{side}", (side * 0.09, BORE_Y, -0.88), (0.01, 0.018, 0.54), "Accent", 0.0)
        w.profile(f"LugStripe{side}", [(-0.60, -0.075), (-1.14, -0.075), (-1.215, -0.15), (-0.60, -0.15)], 0.012, "Panel", 0.0, x=x)
    for i, z in enumerate((-1.335, -1.285)):
        w.box(f"Port{i}", (0, 0.125, z), (0.198, 0.11, 0.024), "Dark", 0.0, rot=(-22, 0, 0))

    # Banda ventilada
    w.box("RibTop", (0, 0.25, -0.92), (0.085, 0.03, 0.96), "Body", 0.008)
    for i in range(7):
        w.box(f"RibPost{i}", (0, 0.212, -0.47 - i * 0.152), (0.085, 0.05, 0.06), "Body", 0.0)
    w.box("RibStripe", (0, 0.267, -0.80), (0.03, 0.008, 0.62), "Panel", 0.0)
    # Punto de mira alto en rampa
    w.profile("FrontSight", [(-1.16, 0.262), (-1.40, 0.262), (-1.40, 0.305), (-1.33, 0.305)], 0.036, "Dark", 0.0)
    w.box("FrontDot", (0, 0.293, -1.322), (0.022, 0.024, 0.012), "Accent", 0.0)

    # ---------------------------------------------------------------- armazón (oscuro)
    w.profile("FrameFront", [(-0.30, 0.26), (-0.45, 0.26), (-0.45, -0.28), (-0.39, -0.36), (-0.30, -0.36)], 0.20, "Body", 0.016)
    w.box("TopStrap", (0, 0.22, -0.09), (0.15, 0.08, 0.44), "Body", 0.01)
    w.box("FrameBottom", (0, -0.323, -0.09), (0.20, 0.075, 0.44), "Body", 0.0)
    w.profile("FrameRear", [(0.10, 0.26), (0.55, 0.26), (0.60, 0.18), (0.61, -0.02), (0.48, -0.16), (0.22, -0.36), (0.10, -0.36)], 0.20, "Body", 0.018)
    w.box("RecoilShield", (0, -0.04, 0.135), (0.37, 0.40, 0.07), "Body", 0.014)
    w.box("StrapStripe", (0, 0.262, -0.05), (0.05, 0.008, 0.36), "Panel", 0.0)
    for side in (-1, 1):
        w.box(f"FrameGlow{side}", (side * 0.101, -0.325, -0.10), (0.008, 0.02, 0.32), "Accent", 0.0)
        w.profile(f"SidePlate{side}", [(0.20, 0.17), (0.50, 0.17), (0.53, 0.02), (0.44, -0.08), (0.26, -0.08)], 0.012, "Metal", 0.0, x=side * 0.101)
    w.box("Latch", (-0.112, 0.05, 0.30), (0.02, 0.06, 0.11), "Panel", 0.0)
    w.cyl("FramePin", (-0.108, -0.22, 0.24), (0.108, -0.22, 0.24), 0.024, "Metal", 6)

    # ---------------------------------------------------------------- tambor hexagonal (acero)
    side_len = 2 * CYL_A / math.sqrt(3)
    zc, length = (CYL_Z0 + CYL_Z1) / 2, CYL_Z1 - CYL_Z0
    for i in range(3):
        w.box(f"Cylinder{i}", (0, CYL_Y, zc), (2 * CYL_A, side_len, length), "Metal", 0.0, rot=(0, 0, 30 + i * 60))
    for i in (0, 2, 3, 5):
        a = math.radians(30 + i * 60)
        w.box(f"Flute{i}", (math.cos(a) * CYL_A, CYL_Y + math.sin(a) * CYL_A, CYL_Z0 + 0.13), (0.014, 0.12, 0.24), "Dark", 0.0, rot=(0, 0, 30 + i * 60))
    w.cyl("CylinderNeck", (0, CYL_Y, -0.31), (0, CYL_Y, 0.11), 0.13, "Dark", 8)

    # ---------------------------------------------------------------- martillo y alza
    w.profile("Hammer", [(0.54, 0.02), (0.54, 0.20), (0.76, 0.245), (0.77, 0.20), (0.64, 0.15), (0.64, 0.02)], 0.05, "Metal", 0.0)
    w.box("HammerGrip", (0, 0.236, 0.70), (0.075, 0.014, 0.10), "Dark", 0.0, rot=(-11.5, 0, 0))
    for side in (-1, 1):
        w.box(f"RearSightPost{side}", (side * 0.055, 0.29, 0.50), (0.05, 0.06, 0.07), "Dark", 0.0)
        w.box(f"RearSightDot{side}", (side * 0.055, 0.295, 0.537), (0.02, 0.02, 0.006), "Accent", 0.0)

    # ---------------------------------------------------------------- guardamonte y gatillo
    w.box("GuardFront", (0, -0.47, -0.20), (0.06, 0.27, 0.04), "Body", 0.0, rot=(-18, 0, 0))
    w.box("GuardBottom", (0, -0.595, 0.04), (0.06, 0.04, 0.44), "Body", 0.0)
    w.box("Trigger", (0, -0.45, 0.07), (0.036, 0.17, 0.045), "Panel", 0.0, rot=(-14, 0, 0))

    # ---------------------------------------------------------------- empuñadura
    w.profile("Grip", [(0.12, -0.15), (0.47, -0.10), (0.60, -0.36), (0.66, -0.62), (0.77, -0.82), (0.73, -0.88), (0.36, -0.88), (0.31, -0.72), (0.21, -0.45)], 0.20, "Rubber", 0.026)
    w.profile("GripInlay", [(0.25, -0.27), (0.46, -0.23), (0.64, -0.74), (0.41, -0.78)], 0.216, "Panel", 0.0)
    for i, y in enumerate((-0.60, -0.67)):
        w.box(f"GripGroove{i}", (0, y, 0.46 - 0.3 * (y + 0.5)), (0.222, 0.018, 0.26), "Rubber", 0.0, rot=(-9, 0, 0))
    w.profile("GripCap", [(0.33, -0.86), (0.76, -0.86), (0.79, -0.925), (0.36, -0.925)], 0.215, "Metal", 0.01)
    w.ring("LanyardRing", (-0.018, -0.965, 0.58), (0.018, -0.965, 0.58), 0.06, 0.036, "Metal", 8)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BORE_Y, -1.43))
    w.point("AimPoint", (0, 0.29, 0.5))
    w.point("Eject", (0.26, CYL_Y, -0.1))
    w.point("RightHand", (0, -0.45, 0.3))
    w.point("LeftHand", (-0.16, -0.5, 0.28))
    w.point("CharmPoint", (-0.105, -0.12, 0.42))
