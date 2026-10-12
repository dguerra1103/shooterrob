# BALLESTA · ballesta táctica compacta (primaria de un solo virote de SHOOTERROB).
# Silueta: raíl estrecho con culata esquelética, dos palas recurvas cortas que se abren a los lados
# desde el puente delantero (cajas giradas: sobreviven en Roblox), poleas en las puntas, cuerda
# tensada en V hasta la nuez, virote cargado con punta de acero y plumas de color (piece=Mag: se
# quita al recargar), visor compacto en AimPoint y empuñadura delantera angulosa.
import math

NAME = "Crossbow"

PALETTE = {
    "Body": (0.04, 0.048, 0.06),
    "Panel": (0.045, 0.40, 0.08),  # verde bosque (≈ RGB 60,170,80)
    "Accent": (1.0, 0.11, 0.0),  # ámbar luminoso
    "Accent2": (0.95, 0.16, 0.03),  # rojo anaranjado (pluma guía, bujes)
    "Dark": (0.015, 0.016, 0.02),
    "Metal": (0.55, 0.57, 0.62),
    "Rubber": (0.028, 0.03, 0.034),
    "Lens": (0.75, 0.22, 0.02),
}

BY = 0.06  # eje del virote (Muzzle.y)
SY = 0.30  # eje del visor (AimPoint.y)
STRING_Y = 0.065
NUT_Z = -0.09


def bar_xz(w, name, a, b, thick, height, y, role, piece=None):
    """Barra horizontal entre dos puntos (x, z): `thick` de ancho, `height` de alto, centrada en y."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dz)
    w.box(name, ((a[0] + b[0]) / 2, y, (a[1] + b[1]) / 2), (thick, height, length), role, 0.0, piece=piece, rot=(0, math.degrees(math.atan2(dx, dz)), 0))


def bar_yz(w, name, a, b, thick, role, piece=None):
    """Barra entre dos puntos (z, y) del plano lateral; thick = (ancho x, grosor)."""
    dz, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dz, dy)
    w.box(name, (0, (a[1] + b[1]) / 2, (a[0] + b[0]) / 2), (thick[0], thick[1], length), role, 0.0, piece=piece, rot=(math.degrees(math.atan2(-dy, dz)), 0, 0))


def build(w):
    # ---------------------------------------------------------------- cajón del disparador
    w.profile("Receiver", [(0.62, -0.12), (0.62, 0.08), (0.54, 0.14), (-0.04, 0.14), (-0.10, 0.09), (-0.10, -0.14)], 0.20, "Body", 0.02)
    w.profile("SidePlate", [(0.50, 0.09), (0.06, 0.09), (-0.03, -0.01), (0.41, -0.01)], 0.214, "Panel", 0.0)
    w.box("ReceiverGlow", (0, -0.065, 0.22), (0.208, 0.022, 0.44), "Accent", 0.0)
    w.box("Nut", (0, 0.075, NUT_Z - 0.02), (0.07, 0.07, 0.05), "Metal", 0.0)
    w.box("Safety", (0.104, 0.06, 0.52), (0.014, 0.035, 0.07), "Accent2", 0.0)
    for z in (0.50, 0.0):
        w.cyl(f"Pin{z}", (-0.105, -0.085, z), (0.105, -0.085, z), 0.02, "Metal", 6)

    # ---------------------------------------------------------------- raíl (pista del virote)
    w.box("Rail", (0, -0.03, -0.68), (0.12, 0.14, 1.18), "Body", 0.012)
    w.profile("RailPlate", [(-0.14, 0.01), (-0.50, 0.01), (-0.58, -0.07), (-0.22, -0.07)], 0.134, "Panel", 0.0)
    for i, z in enumerate((-0.66, -0.74, -0.82)):
        w.box(f"RailSlot{i}", (0, -0.03, z), (0.13, 0.1, 0.03), "Dark", 0.0, rot=(-35, 0, 0))
    w.box("RailGlow", (0, -0.03, -1.03), (0.128, 0.02, 0.30), "Accent", 0.0)
    for side in (-1, 1):
        w.box(f"DeckEdge{side}", (side * 0.05, 0.045, -0.66), (0.02, 0.012, 1.12), "Dark", 0.0)

    # ---------------------------------------------------------------- puente y palas
    w.profile("Riser", [(-1.20, 0.04), (-1.38, 0.04), (-1.45, -0.03), (-1.40, -0.15), (-1.20, -0.15)], 0.24, "Dark", 0.014)
    w.profile("RiserPlate", [(-1.24, 0.0), (-1.37, 0.0), (-1.41, -0.04), (-1.38, -0.11), (-1.24, -0.11)], 0.254, "Panel", 0.0)
    for side in (-1, 1):
        p0, p1, p2, p3 = (side * 0.09, -1.33), (side * 0.46, -1.22), (side * 0.74, -1.0), (side * 0.87, -1.08)
        bar_xz(w, f"LimbPocket{side}", (side * 0.07, -1.335), (side * 0.24, -1.285), 0.11, 0.13, -0.01, "Dark")
        bar_xz(w, f"LimbInner{side}", p0, p1, 0.075, 0.11, 0.0, "Panel")
        bar_xz(w, f"LimbBrace{side}", (side * 0.05, -1.17), (side * 0.47, -1.20), 0.035, 0.05, 0.0, "Dark")
        bar_xz(w, f"LimbOuter{side}", (side * 0.44, -1.228), p2, 0.06, 0.09, 0.0, "Panel")
        bar_xz(w, f"LimbTip{side}", (side * 0.72, -1.0), p3, 0.05, 0.07, 0.0, "Dark")
        bar_xz(w, f"LimbStripe{side}", (side * 0.20, -1.318), (side * 0.42, -1.252), 0.082, 0.024, 0.0, "Accent")
        # Polea en la punta
        cx, cz = side * 0.775, -0.975
        w.cyl(f"CamAxle{side}", (cx, -0.06, cz), (cx, 0.115, cz), 0.022, "Dark", 6)
        w.cyl(f"Cam{side}", (cx, 0.04, cz), (cx, 0.09, cz), 0.085, "Metal", 10)
        w.cyl(f"CamHub{side}", (cx, 0.09, cz), (cx, 0.102, cz), 0.04, "Accent2", 8)
        w.cyl(f"CamLow{side}", (cx, -0.065, cz), (cx, -0.04, cz), 0.06, "Metal", 8)
        # Cuerda tensada hasta la nuez
        bar_xz(w, f"String{side}", (side * 0.72, -0.91), (side * 0.01, NUT_Z), 0.018, 0.018, STRING_Y, "Dark")

    # ---------------------------------------------------------------- virote cargado (piece=Mag)
    M = "Mag"
    w.cyl("Shaft", (0, BY, NUT_Z), (0, BY, -1.42), 0.022, "Metal", 6, piece=M)
    w.cyl("Ferrule", (0, BY, -1.40), (0, BY, -1.48), 0.03, "Metal", 6, piece=M)
    w.profile("Broadhead", [(-1.60, BY), (-1.43, BY + 0.075), (-1.47, BY), (-1.43, BY - 0.075)], 0.014, "Metal", 0.0, piece=M)
    w.box("BroadheadFlat", (0, BY, -1.505), (0.095, 0.012, 0.095), "Metal", 0.0, piece=M, rot=(0, 45, 0))
    w.box("ShaftBand", (0, BY, -1.30), (0.05, 0.05, 0.04), "Accent", 0.0, piece=M)
    w.box("Nock", (0, BY, NUT_Z - 0.03), (0.05, 0.05, 0.05), "Accent", 0.0, piece=M)
    w.profile("FletchTop", [(-0.42, BY + 0.01), (-0.15, BY + 0.01), (-0.13, BY + 0.10), (-0.24, BY + 0.10)], 0.014, "Accent2", 0.0, piece=M)
    for side in (-1, 1):
        w.box(f"Fletch{side}", (side * 0.06, BY + 0.02, -0.27), (0.10, 0.014, 0.24), "Panel", 0.0, piece=M, rot=(0, 0, side * 25))

    # ---------------------------------------------------------------- visor compacto
    w.box("ScopeRail", (0, 0.155, 0.19), (0.09, 0.03, 0.60), "Dark", 0.0)
    for i, z in enumerate((0.20, 0.02)):
        w.box(f"ScopeMount{i}", (0, 0.205, z), (0.07, 0.09, 0.06), "Dark", 0.0)
    # Visor réflex ABIERTO (en el juego se mira a través de él: un tubo macizo tapaba la vista al apuntar)
    w.box("SightBase", (0, 0.2, 0.36), (0.16, 0.04, 0.16), "Dark", 0.0)
    for side in (-1, 1):
        w.box(f"SightPost{side}", (side * 0.082, SY, 0.38), (0.018, 0.2, 0.09), "Body", 0.0)
    w.box("SightHood", (0, SY + 0.108, 0.37), (0.2, 0.02, 0.12), "Panel", 0.0)
    w.box("SightLens", (0, SY, 0.37), (0.15, 0.19, 0.01), "Lens", 0.0)
    w.box("Reticle", (0, SY, 0.362), (0.014, 0.014, 0.005), "Reticle", 0.0)
    w.box("SightBattery", (0.06, 0.2, 0.22), (0.06, 0.05, 0.1), "Metal", 0.0)

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.profile("Grip", [(0.27, -0.11), (0.51, -0.11), (0.64, -0.72), (0.41, -0.75)], 0.165, "Rubber", 0.024)
    w.profile("GripInlay", [(0.35, -0.24), (0.47, -0.24), (0.56, -0.62), (0.44, -0.64)], 0.178, "Panel", 0.0)
    w.box("GuardBottom", (0, -0.34, 0.10), (0.04, 0.025, 0.40), "Dark", 0.0)
    w.box("GuardFront", (0, -0.235, -0.09), (0.04, 0.2, 0.03), "Dark", 0.0)
    w.box("Trigger", (0, -0.235, 0.16), (0.03, 0.15, 0.035), "Metal", 0.0, rot=(-16, 0, 0))

    # ---------------------------------------------------------------- empuñadura delantera
    w.profile("Foregrip", [(-0.64, -0.09), (-1.18, -0.09), (-1.14, -0.20), (-0.99, -0.31), (-0.74, -0.27)], 0.15, "Rubber", 0.02)
    w.profile("ForegripInlay", [(-0.78, -0.14), (-1.08, -0.14), (-1.06, -0.19), (-0.97, -0.25), (-0.82, -0.23)], 0.163, "Panel", 0.0)

    # ---------------------------------------------------------------- culata esquelética
    w.profile("StockSpine", [(0.58, 0.12), (1.30, 0.10), (1.30, 0.0), (0.58, -0.03)], 0.13, "Body", 0.016)
    bar_yz(w, "StockStrut", (0.60, -0.10), (1.27, -0.36), (0.10, 0.07), "Body")
    w.profile("Butt", [(1.25, 0.14), (1.39, 0.14), (1.41, -0.42), (1.31, -0.47), (1.21, -0.37)], 0.17, "Dark", 0.018)
    w.box("ButtPad", (0, -0.14, 1.425), (0.17, 0.56, 0.05), "Rubber", 0.016)
    w.box("CheekRest", (0, 0.135, 0.95), (0.145, 0.045, 0.42), "Panel", 0.012)
    w.box("StockGlow", (0, 0.045, 0.98), (0.136, 0.02, 0.34), "Accent", 0.0)

    # Carcaj lateral (derecha) con dos virotes de repuesto: fijos, no son el virote cargado
    w.box("QuiverCup", (0.085, 0.045, 0.70), (0.06, 0.15, 0.16), "Dark", 0.0)
    w.box("QuiverClip", (0.085, 0.045, 1.12), (0.05, 0.13, 0.05), "Dark", 0.0)
    for i, y in enumerate((0.085, 0.005)):
        w.cyl(f"SpareShaft{i}", (0.095, y, 0.72), (0.095, y, 1.24), 0.018, "Metal", 6)
        w.box(f"SpareFletch{i}", (0.112, y, 1.19), (0.045, 0.012, 0.13), "Accent2" if i == 0 else "Panel", 0.0)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BY, -1.6))
    w.point("AimPoint", (0, SY, 0.4))
    w.point("Eject", (0.13, 0.08, 0.1))
    w.point("RightHand", (0, -0.42, 0.4))
    w.point("LeftHand", (0, -0.18, -0.9))
    w.point("CharmPoint", (-0.105, -0.03, 0.5))
