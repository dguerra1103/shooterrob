# SPLAT-X · marcadora de paintball arcade (primaria de SHOOTERROB).
# Silueta: cuerpo bajo y afilado, tolva grande translúcida arriba a la izquierda (deja libre la línea
# de mira) con bolas de colores, carenado rosa con branquias, cañón largo con bocacha porteada,
# botella de aire inclinada como culata con su regulador y manómetro, y empuñadura delantera con
# una mancha de pintura a cada lado.
import math

NAME = "SplatX"

PALETTE = {
    "Body": (0.045, 0.05, 0.075),
    "Panel": (1.0, 0.05, 0.40),  # rosa chicle (≈ RGB 255,60,170)
    "Accent": (0.45, 1.0, 0.08),  # lima luminoso
    "Accent2": (0.045, 0.72, 1.0),  # cian (≈ RGB 60,220,255)
    "Trim": (1.0, 0.72, 0.03),  # amarillo (≈ RGB 255,220,50)
    "Dark": (0.016, 0.017, 0.024),
    "Metal": (0.55, 0.57, 0.63),
    "Rubber": (0.028, 0.03, 0.038),
    "Lens": (0.16, 0.42, 0.7),  # carcasa translúcida de la tolva
}

HX, HY, HZ = -0.31, 0.50, -0.12  # eje de la tolva (a la izquierda del raíl)


def bar_yz(w, name, a, b, thick, role, piece=None, x=0.0):
    """Barra de sección `thick` (x, grosor) entre dos puntos (z, y) del plano lateral."""
    dz, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dz, dy)
    ang = math.degrees(math.atan2(-dy, dz))
    w.box(name, (x, (a[1] + b[1]) / 2, (a[0] + b[0]) / 2), (thick[0], thick[1], length), role, 0.0, piece=piece, rot=(ang, 0, 0))


def splat(w, name, x, y, z, r, role, side):
    """Mancha de pintura: disco central, gotas alrededor y un chorretón que cae."""
    a, b = x, x + side * 0.014
    w.cyl(name, (a, y, z), (b, y, z), r, role, 10)
    for i, (dz, dy, k) in enumerate(((-1.0, 0.35, 0.5), (0.85, 0.7, 0.32), (-0.55, -0.9, 0.3), (1.05, -0.2, 0.42), (-0.2, 1.08, 0.26))):
        w.cyl(f"{name}Drop{i}", (a, y + dy * r, z + dz * r), (b, y + dy * r, z + dz * r), r * k, role, 6)
    w.box(f"{name}Drip", (x + side * 0.007, y - r * 1.4, z + r * 0.2), (0.014, r * 1.5, r * 0.36), role, 0.0)


def build(w):
    # ---------------------------------------------------------------- cuerpo
    w.profile("Body", [(0.55, -0.12), (0.55, 0.13), (0.44, 0.24), (-0.40, 0.24), (-0.50, 0.16), (-0.50, -0.14)], 0.24, "Body", 0.022)
    w.profile("SidePlate", [(0.42, 0.19), (-0.26, 0.19), (-0.40, 0.05), (0.28, 0.05)], 0.256, "Panel", 0.0)
    w.box("BodyGlow", (0, -0.03, 0.02), (0.25, 0.024, 0.66), "Accent", 0.0)
    for i, z in enumerate((0.30, 0.22, 0.14)):
        w.box(f"PlateSlot{i}", (0, 0.12, z), (0.262, 0.09, 0.028), "Dark", 0.0, rot=(-35, 0, 0))
    w.box("TopRail", (0, 0.255, 0.02), (0.11, 0.035, 0.86), "Dark", 0.0)
    w.cyl("BodyPin", (-0.126, -0.08, 0.42), (0.126, -0.08, 0.42), 0.024, "Metal", 6)
    for side in (-1, 1):
        w.box(f"RearTab{side}", (side * 0.122, -0.075, 0.33), (0.012, 0.05, 0.2), "Accent2", 0.0)
    w.box("EjectPort", (0.122, 0.12, -0.12), (0.012, 0.07, 0.16), "Dark", 0.0)
    # Miras: alza de dos postes y punto de mira, con puntos lima
    w.box("RearSightBase", (0, 0.29, 0.45), (0.17, 0.04, 0.09), "Dark", 0.0)
    for side in (-1, 1):
        w.box(f"RearSightPost{side}", (side * 0.06, 0.35, 0.45), (0.045, 0.09, 0.07), "Dark", 0.0)
        w.box(f"RearSightDot{side}", (side * 0.06, 0.365, 0.487), (0.022, 0.022, 0.006), "Accent", 0.0)
    w.box("FrontSight", (0, 0.32, -0.40), (0.035, 0.10, 0.06), "Dark", 0.0)
    w.box("FrontSightDot", (0, 0.35, -0.368), (0.02, 0.022, 0.006), "Accent", 0.0)

    # ---------------------------------------------------------------- carenado y cañón
    w.profile("Shroud", [(-0.50, 0.20), (-0.86, 0.20), (-0.98, 0.10), (-0.98, 0.02), (-0.88, -0.10), (-0.50, -0.14)], 0.20, "Panel", 0.02)
    w.profile("ShroudCore", [(-0.52, 0.13), (-0.89, 0.13), (-0.95, 0.08), (-0.95, 0.03), (-0.89, -0.03), (-0.52, -0.03)], 0.212, "Dark", 0.0)
    for i, z in enumerate((-0.60, -0.70, -0.80)):
        w.box(f"Gill{i}", (0, 0.05, z), (0.218, 0.2, 0.04), "Panel", 0.0, rot=(-30, 0, 0))
    w.cyl("Barrel", (0, 0.08, -0.94), (0, 0.08, -1.34), 0.058, "Metal", 10)
    w.cyl("BarrelCollar", (0, 0.08, -0.96), (0, 0.08, -1.03), 0.08, "Dark", 8)
    w.cyl("BarrelBand", (0, 0.08, -1.13), (0, 0.08, -1.17), 0.072, "Accent2", 8)
    w.cyl("BarrelBand2", (0, 0.08, -1.22), (0, 0.08, -1.26), 0.072, "Panel", 8)
    w.ring("Tip", (0, 0.08, -1.31), (0, 0.08, -1.55), 0.088, 0.05, "Trim", 10)
    for i, z in enumerate((-1.37, -1.43, -1.49)):
        w.box(f"PortH{i}", (0, 0.08, z), (0.19, 0.035, 0.03), "Dark", 0.0)
        w.box(f"PortV{i}", (0, 0.08, z), (0.035, 0.19, 0.03), "Dark", 0.0)

    # ---------------------------------------------------------------- tolva (piece=Mag) y su cuello
    # Tambor redondo visto de lado (eje X) con morro y cola: silueta de "bola de chicles"
    w.box("FeedNeck", (-0.15, 0.27, HZ), (0.16, 0.12, 0.16), "Dark", 0.0, rot=(0, 0, 30))
    M = "Mag"
    w.cyl("Hopper", (HX - 0.15, HY, HZ), (HX + 0.15, HY, HZ), 0.23, "Lens", 14, piece=M)
    w.cyl("HopperSeam", (HX - 0.02, HY, HZ), (HX + 0.02, HY, HZ), 0.24, "Dark", 14, piece=M)
    w.cyl("HopperNose", (HX, HY - 0.03, HZ - 0.17), (HX, HY - 0.06, HZ - 0.40), 0.135, "Lens", 10, piece=M)
    w.cyl("HopperTip", (HX, HY - 0.058, HZ - 0.39), (HX, HY - 0.07, HZ - 0.48), 0.08, "Lens", 8, piece=M)
    w.cyl("HopperTail", (HX, HY - 0.02, HZ + 0.17), (HX, HY - 0.03, HZ + 0.32), 0.115, "Lens", 10, piece=M)
    w.box("HopperLid", (HX, HY + 0.225, HZ), (0.2, 0.05, 0.2), "Dark", 0.0, piece=M)
    w.box("HopperLatch", (HX, HY + 0.24, HZ + 0.12), (0.08, 0.04, 0.05), "Trim", 0.0, piece=M)
    w.box("HopperFoot", (HX + 0.03, HY - 0.2, HZ), (0.12, 0.09, 0.18), "Dark", 0.0, piece=M)
    balls = ((-0.12, 0.06), (-0.02, 0.135), (0.11, 0.08), (0.135, -0.05), (0.01, 0.0), (-0.11, -0.085), (0.04, -0.125))
    for i, (dz, dy) in enumerate(balls):
        w.cyl(f"PaintBall{i}", (HX - 0.162, HY + dy, HZ + dz), (HX + 0.162, HY + dy, HZ + dz), 0.05, ("Panel", "Accent2", "Trim")[i % 3], 8, piece=M)

    # ---------------------------------------------------------------- botella de aire (culata)
    w.cyl("Regulator", (0, 0.03, 0.50), (0, 0.01, 0.68), 0.075, "Metal", 8)
    w.cyl("TankNeck", (0, 0.012, 0.66), (0, 0.0, 0.74), 0.115, "Dark", 10)
    w.cyl("AirTank", (0, 0.0, 0.72), (0, -0.09, 1.32), 0.155, "Accent2", 12)
    w.cyl("TankBand", (0, -0.03, 0.92), (0, -0.039, 0.98), 0.163, "Trim", 12)
    w.cyl("TankBand2", (0, -0.063, 1.14), (0, -0.0675, 1.17), 0.161, "Dark", 12)
    w.cyl("TankDome", (0, -0.088, 1.31), (0, -0.098, 1.38), 0.115, "Accent2", 10)
    w.cyl("TankButt", (0, -0.097, 1.37), (0, -0.102, 1.41), 0.07, "Rubber", 8)
    # Válvula con manómetro y latiguillo hasta la base de la empuñadura
    w.cyl("Valve", (0, 0.0, 0.61), (0, -0.2, 0.61), 0.034, "Metal", 6)
    w.cyl("Gauge", (-0.075, -0.2, 0.61), (0.075, -0.2, 0.61), 0.055, "Dark", 8)
    for side in (-1, 1):
        w.cyl(f"GaugeFace{side}", (side * 0.07, -0.2, 0.61), (side * 0.082, -0.2, 0.61), 0.04, "Trim", 8)
    bar_yz(w, "Hose", (0.615, -0.22), (0.555, -0.78), (0.045, 0.045), "Dark")

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.profile("Grip", [(0.18, -0.12), (0.44, -0.12), (0.58, -0.78), (0.35, -0.80)], 0.17, "Rubber", 0.026)
    w.profile("GripInlay", [(0.27, -0.26), (0.40, -0.26), (0.49, -0.66), (0.37, -0.68)], 0.184, "Panel", 0.0)
    w.profile("GripBase", [(0.31, -0.76), (0.62, -0.74), (0.63, -0.83), (0.33, -0.86)], 0.19, "Dark", 0.012)
    w.box("GuardBottom", (0, -0.37, -0.02), (0.045, 0.026, 0.44), "Dark", 0.0)
    w.box("GuardFront", (0, -0.255, -0.24), (0.045, 0.24, 0.03), "Dark", 0.0, rot=(-10, 0, 0))
    w.box("Trigger", (0, -0.25, 0.06), (0.032, 0.17, 0.035), "Trim", 0.0, rot=(-14, 0, 0))

    # ---------------------------------------------------------------- empuñadura delantera con mancha
    w.box("ForegripMount", (0, -0.135, -0.70), (0.15, 0.06, 0.30), "Dark", 0.0)
    w.profile("Foregrip", [(-0.60, -0.15), (-0.82, -0.15), (-0.86, -0.56), (-0.67, -0.56)], 0.15, "Rubber", 0.022)
    w.profile("ForegripCap", [(-0.65, -0.54), (-0.88, -0.54), (-0.89, -0.60), (-0.67, -0.61)], 0.165, "Trim", 0.0)
    for side in (-1, 1):
        splat(w, f"Splat{side}", side * 0.073, -0.33, -0.735, 0.085, "Accent2", side)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0.08, -1.55))
    w.point("AimPoint", (0, 0.36, 0.45))
    w.point("Eject", (0.14, 0.12, -0.12))
    w.point("RightHand", (0, -0.45, 0.32))
    w.point("LeftHand", (0, -0.26, -0.7))
    w.point("CharmPoint", (-0.13, -0.08, 0.3))
