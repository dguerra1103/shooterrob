# BREACH HAMMER · escopeta semiautomática rompepuertas de SHOOTERROB (diseño original).
# Silueta: cabeza de mazo cuadrada en la boca (más ancha y alta que el arma) con banda de peligro,
# cañón corto y gordo dentro de una camisa cuadrada con ventanas, cajón macizo con raíl y alza abierta
# de orejas, gran tambor colgado (eje paralelo al cañón) con banda amarilla, empuñadura delantera
# vertical y culata corta maciza. Sin corredera. Amarillo de peligro con franjas negras y brillo rojo.
NAME = "BreachHammer"

PALETTE = {
    "Body": (0.05, 0.053, 0.066),
    "Panel": (0.98, 0.80, 0.12),  # amarillo de peligro (≈ 250, 205, 30)
    "Accent": (1.0, 0.03, 0.015),  # rojo luminoso
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.5, 0.52, 0.58),
    "Trim": (0.98, 0.80, 0.12),
}

BY = 0.10  # altura del eje del cañón
DY = -0.59  # altura del eje del tambor


def stripes(w, name, x, y, z0, n, step, length, thick, angle, piece=None):
    """Franjas negras inclinadas sobre una placa amarilla (barras finas pegadas a la cara lateral)."""
    for i in range(n):
        w.box(f"{name}{i}", (x, y, z0 - i * step), (0.012, length, thick), "Dark", 0.0, piece=piece, rot=(angle, 0, 0))


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.profile("Body", [(0.88, 0.0), (0.88, 0.24), (0.80, 0.32), (-0.50, 0.32), (-0.50, 0.0)], 0.32, "Body", 0.024)
    w.profile("Lower", [(0.84, 0.02), (0.84, -0.14), (0.34, -0.24), (-0.50, -0.24), (-0.50, 0.02)], 0.29, "Dark", 0.018)
    w.box("Trunnion", (0, 0.10, -0.56), (0.37, 0.52, 0.16), "Body", 0.024)
    # Derecha: ventana de expulsión con cerrojo
    w.box("EjectionPort", (0.161, 0.17, -0.20), (0.012, 0.12, 0.40), "Dark", 0.0)
    w.box("Bolt", (0.164, 0.17, -0.20), (0.012, 0.08, 0.34), "Metal", 0.0, piece="Bolt")
    # Izquierda (la que se ve en primera persona): corredera de la palanca de montar
    w.box("ChargeSlot", (-0.161, 0.25, -0.12), (0.012, 0.04, 0.60), "Dark", 0.0)
    w.box("ChargingHandle", (-0.19, 0.25, -0.30), (0.07, 0.06, 0.09), "Metal", 0.0, piece="Charge")
    # Placas de peligro a los dos lados
    for side in (-1, 1):
        w.profile(f"SidePlate{side}", [(0.74, 0.21), (0.26, 0.21), (0.16, 0.05), (0.74, 0.05)], 0.012, "Panel", 0.0, x=side * 0.161)
        stripes(w, f"PlateStripe{side}_", side * 0.164, 0.13, 0.63, 3, 0.13, 0.19, 0.05, -32)
        w.box(f"GlowStrip{side}", (side * 0.147, -0.03, 0.14), (0.008, 0.026, 1.20), "Accent", 0.0)
    for z in (0.62, -0.38):
        w.cyl(f"Pin{z}", (-0.15, -0.12, z), (0.15, -0.12, z), 0.026, "Metal", 6)
    w.box("Safety", (-0.15, -0.10, 0.30), (0.016, 0.03, 0.10), "Panel", 0.0, rot=(20, 0, 0))

    # ---------------------------------------------------------------- raíl y alza abierta de orejas
    w.box("Rail", (0, 0.335, 0.02), (0.13, 0.04, 1.00), "Dark", 0.0)
    for i in range(4):
        w.box(f"RailTooth{i}", (0, 0.362, 0.36 - i * 0.24), (0.15, 0.022, 0.11), "Dark", 0.0)
    w.box("SightBase", (0, 0.35, 0.76), (0.26, 0.07, 0.24), "Dark", 0.012)
    for side in (-1, 1):
        w.profile(f"SightWing{side}", [(0.86, 0.37), (0.86, 0.50), (0.80, 0.57), (0.72, 0.57), (0.64, 0.37)], 0.05, "Body", 0.008, x=side * 0.105)
        w.box(f"SightDot{side}", (side * 0.105, 0.47, 0.863), (0.028, 0.028, 0.01), "Accent", 0.0)

    # ---------------------------------------------------------------- cañón gordo y camisa cuadrada con ventanas
    w.cyl("Barrel", (0, BY, -0.56), (0, BY, -2.20), 0.088, "Metal", 12)
    w.box("ShroudTop", (0, 0.265, -1.22), (0.34, 0.11, 1.20), "Body", 0.02)
    w.box("ShroudBottom", (0, -0.05, -1.22), (0.34, 0.12, 1.20), "Dark", 0.02)
    for i in range(6):
        w.box(f"ShroudPost{i}", (0, BY, -0.80 - i * 0.19), (0.325, 0.24, 0.075), "Body", 0.0)
    for i in range(5):
        w.box(f"TopVent{i}", (0, 0.321, -0.895 - i * 0.19), (0.16, 0.01, 0.10), "Dark", 0.0)
    for side in (-1, 1):
        w.box(f"ShroudBand{side}", (side * 0.171, -0.045, -1.22), (0.012, 0.05, 1.06), "Panel", 0.0)
        w.box(f"ShroudGlow{side}", (side * 0.171, 0.225, -1.22), (0.008, 0.02, 1.06), "Accent", 0.0)

    # ---------------------------------------------------------------- cabeza de mazo (boca)
    w.profile("HammerHead", [(-1.78, 0.39), (-2.18, 0.39), (-2.25, 0.32), (-2.25, -0.13), (-2.18, -0.20), (-1.78, -0.20)], 0.48, "Body", 0.026)
    w.box("HammerBand", (0, 0.095, -1.99), (0.492, 0.602, 0.30), "Panel", 0.01)
    for side in (-1, 1):
        stripes(w, f"HammerStripe{side}_", side * 0.248, BY, -1.905, 3, 0.085, 0.40, 0.04, -20)
    w.box("StrikeFace", (0, BY, -2.25), (0.40, 0.44, 0.03), "Metal", 0.0)
    for sx in (-1, 1):
        for sy in (-1, 1):
            w.box(f"Stud{sx}{sy}", (sx * 0.165, BY + sy * 0.185, -2.265), (0.10, 0.10, 0.05), "Dark", 0.0)
    w.ring("Bore", (0, BY, -2.20), (0, BY, -2.29), 0.16, 0.095, "Body", 10)
    for sy in (-1, 1):
        w.box(f"FaceGlow{sy}", (0, BY + sy * 0.192, -2.266), (0.17, 0.028, 0.012), "Accent", 0.0)
    w.profile("FrontSight", [(-1.80, 0.39), (-1.98, 0.39), (-1.98, 0.51), (-1.93, 0.51)], 0.05, "Dark", 0.0)
    w.box("FrontDot", (0, 0.475, -1.925), (0.03, 0.04, 0.02), "Accent", 0.0)

    # ---------------------------------------------------------------- empuñadura delantera vertical
    w.box("ForegripMount", (0, -0.13, -1.16), (0.20, 0.07, 0.40), "Dark", 0.014)
    w.profile("Foregrip", [(-1.04, -0.15), (-1.28, -0.15), (-1.27, -0.70), (-1.22, -0.78), (-1.09, -0.78), (-1.05, -0.70)], 0.16, "Rubber", 0.024)
    w.box("ForegripCollar", (0, -0.215, -1.16), (0.176, 0.07, 0.26), "Panel", 0.0)
    w.box("ForegripInlay", (0, -0.47, -1.16), (0.174, 0.24, 0.09), "Panel", 0.0)
    w.box("ForegripGlow", (0, -0.47, -1.16), (0.18, 0.16, 0.022), "Accent", 0.0)
    w.box("ForegripCap", (0, -0.775, -1.155), (0.17, 0.03, 0.15), "Metal", 0.0)

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.profile("Grip", [(0.35, -0.15), (0.65, -0.15), (0.80, -0.80), (0.52, -0.83)], 0.18, "Rubber", 0.028)
    w.profile("GripInlay", [(0.44, -0.30), (0.60, -0.30), (0.70, -0.70), (0.55, -0.72)], 0.194, "Panel", 0.0)
    w.box("TriggerGuard", (0, -0.41, 0.19), (0.05, 0.028, 0.44), "Dark", 0.0)
    w.box("TriggerGuardFront", (0, -0.33, -0.02), (0.05, 0.19, 0.03), "Dark", 0.0)
    w.box("Trigger", (0, -0.30, 0.22), (0.03, 0.14, 0.035), "Metal", 0.0, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- tambor (pieza Mag)
    w.box("MagTower", (0, -0.22, -0.33), (0.21, 0.20, 0.36), "Dark", 0.014, piece="Mag")
    w.cyl("Drum", (0, DY, -0.10), (0, DY, -0.58), 0.32, "Dark", 12, piece="Mag")
    w.cyl("DrumBand", (0, DY, -0.25), (0, DY, -0.43), 0.335, "Panel", 12, piece="Mag")
    w.cyl("DrumFacePlate", (0, DY, -0.58), (0, DY, -0.595), 0.22, "Panel", 10, piece="Mag")
    w.cyl("DrumHubFront", (0, DY, -0.59), (0, DY, -0.62), 0.11, "Metal", 8, piece="Mag")
    w.box("DrumKey", (0, DY, -0.63), (0.26, 0.05, 0.03), "Metal", 0.0, piece="Mag")
    w.cyl("DrumBackPlate", (0, DY, -0.085), (0, DY, -0.10), 0.22, "Panel", 10, piece="Mag")
    w.cyl("DrumHubRear", (0, DY, -0.07), (0, DY, -0.09), 0.11, "Metal", 8, piece="Mag")
    w.cyl("DrumGlow", (0, DY, -0.06), (0, DY, -0.075), 0.055, "Accent", 8, piece="Mag")

    # ---------------------------------------------------------------- culata corta maciza
    w.profile("Stock", [(0.86, 0.28), (1.42, 0.30), (1.50, 0.24), (1.50, -0.38), (1.40, -0.46), (1.22, -0.30), (0.86, -0.10)], 0.24, "Body", 0.024)
    for side in (-1, 1):
        w.profile(f"StockPlate{side}", [(1.00, 0.16), (1.40, 0.16), (1.40, -0.30), (1.28, -0.22), (1.00, -0.06)], 0.012, "Panel", 0.0, x=side * 0.121)
        stripes(w, f"StockStripe{side}_", side * 0.124, 0.04, 1.33, 3, 0.11, 0.17, 0.045, -32)
    w.box("ButtPad", (0, -0.07, 1.53), (0.25, 0.70, 0.07), "Rubber", 0.022)
    w.box("CheekRest", (0, 0.305, 1.16), (0.20, 0.05, 0.44), "Rubber", 0.014)
    w.cyl("StockBolt", (-0.125, 0.20, 0.96), (0.125, 0.20, 0.96), 0.032, "Metal", 6)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BY, -2.29))
    w.point("AimPoint", (0, 0.45, 0.80))
    w.point("Eject", (0.18, 0.17, -0.20))
    w.point("RightHand", (0, -0.50, 0.55))
    w.point("LeftHand", (0, -0.44, -1.15))
    w.point("CharmPoint", (-0.15, -0.06, 0.62))
