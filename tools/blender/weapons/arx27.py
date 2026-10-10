# ARX-27 PULSE · fusil de asalto equilibrado (el arma principal de SHOOTERROB), acabado MÍTICO ELEMENTAL.
# La misma arma de siempre (cajón anguloso, guardamanos con branquias, culata esquelética, visor
# holográfico de marco cuadrado, cargador curvo) con dos energías: FUEGO en la mitad trasera (aletas de
# llama y vetas de magma en la culata) y HIELO/PLASMA en la delantera (cristales en el guardamanos y una
# corona de cristales en la boca). Se encuentran en el núcleo del cajón y en el cargador.
import math

NAME = "ARX27"

PALETTE = {
    "Body": (0.04, 0.045, 0.07),
    "Panel": (1.0, 0.5, 0.05),  # oro anaranjado de la casa
    "Accent": (0.0, 0.2, 0.3),  # plasma cian (la emisión del render lo aclara)
    "Accent2": (1.0, 0.1, 0.0),  # magma (la emisión del render lo aclara)
    "Emission": {"Accent2": 4.0},
    "Lens": (0.3, 0.8, 1.0),  # hielo
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.5, 0.52, 0.58),
}


def vein(w, name, x, points, thick=0.028, role="Accent2", piece=None):
    """Veta en zigzag: points = [(z, y), ...]; un listón por tramo que atraviesa el arma y asoma por
    los dos costados (x = a qué distancia del centro está la superficie)."""
    for i in range(len(points) - 1):
        (z0, y0), (z1, y1) = points[i], points[i + 1]
        if z1 < z0:
            (z0, y0), (z1, y1) = (z1, y1), (z0, y0)
        length = math.hypot(z1 - z0, y1 - y0)
        angle = -math.degrees(math.atan2(y1 - y0, z1 - z0))
        w.box(f"{name}{i}", (0, (y0 + y1) / 2, (z0 + z1) / 2), (2 * x + 0.008, thick, length + thick * 0.6), role, 0.0, piece=piece, rot=(angle, 0, 0))


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.profile("Body", [(0.80, 0.02), (0.80, 0.24), (0.66, 0.33), (-0.72, 0.33), (-0.82, 0.24), (-0.82, 0.02)], 0.25, "Body", 0.022)
    w.profile("Lower", [(0.74, 0.04), (0.74, -0.13), (0.22, -0.20), (-0.12, -0.20), (-0.14, -0.37), (-0.57, -0.37), (-0.63, -0.21), (-0.82, -0.15), (-0.82, 0.04)], 0.225, "Dark", 0.018)
    # Núcleo: fuego detrás, plasma delante, cada uno con una lengua metida en el otro
    w.box("CoreFire", (0, 0.15, 0.45), (0.262, 0.15, 0.26), "Accent2", 0.0)
    w.box("CoreIce", (0, 0.15, 0.19), (0.262, 0.15, 0.26), "Accent", 0.0)
    w.box("CoreFireTongue", (0, 0.115, 0.22), (0.266, 0.04, 0.16), "Accent2", 0.0, rot=(-14, 0, 0))
    w.box("CoreIceTongue", (0, 0.185, 0.42), (0.266, 0.04, 0.16), "Accent", 0.0, rot=(-14, 0, 0))
    for i, y in enumerate((0.238, 0.062)):
        w.box(f"CoreFrame{i}", (0, y, 0.32), (0.272, 0.028, 0.62), "Panel", 0.0)
    w.profile("CoreCapRear", [(0.60, 0.25), (0.68, 0.15), (0.60, 0.05), (0.56, 0.05), (0.56, 0.25)], 0.272, "Panel", 0.0)
    w.profile("CoreCapFront", [(0.04, 0.25), (0.08, 0.25), (0.08, 0.05), (0.04, 0.05), (-0.04, 0.15)], 0.272, "Panel", 0.0)
    w.box("EjectionPort", (0.126, 0.19, -0.42), (0.012, 0.11, 0.32), "Dark", 0.0)
    w.box("Bolt", (0.129, 0.19, -0.42), (0.012, 0.075, 0.26), "Metal", 0.0, piece="Bolt")
    w.box("ChargingHandle", (0, 0.305, 0.78), (0.21, 0.05, 0.11), "Metal", 0.012, piece="Charge")
    w.profile("Brow", [(0.62, 0.335), (0.70, 0.29), (0.70, 0.26), (-0.76, 0.26), (-0.76, 0.335)], 0.262, "Dark", 0.0)
    w.profile("MagwellFlare", [(-0.10, -0.30), (-0.12, -0.40), (-0.60, -0.40), (-0.64, -0.30)], 0.245, "Body", 0.012)
    w.cyl("Pin", (-0.118, -0.04, 0.52), (0.118, -0.04, 0.52), 0.022, "Metal", 8)
    w.box("FrontGlow", (0, 0.055, -0.46), (0.258, 0.026, 0.5), "Accent", 0.0)

    # ---------------------------------------------------------------- guardamanos (hielo) y cañón
    w.profile("Handguard", [(-0.82, 0.33), (-1.86, 0.33), (-2.02, 0.20), (-2.02, 0.0), (-1.84, -0.15), (-0.82, -0.15)], 0.27, "Panel", 0.024)
    w.profile("HandguardCore", [(-0.84, 0.25), (-1.92, 0.25), (-1.99, 0.19), (-1.99, 0.02), (-1.86, -0.08), (-0.84, -0.08)], 0.282, "Dark", 0.0)
    for i, z in enumerate((-1.02, -1.22, -1.42, -1.62)):
        w.box(f"Vent{i}", (0, 0.11, z), (0.29, 0.21, 0.075), "Accent", 0.0, rot=(24, 0, 0))
    w.box("HandguardCap", (0, 0.335, -1.32), (0.2, 0.03, 0.9), "Dark", 0.008)
    # Cristales: tres en el lomo (por debajo de la línea de mira) y uno bajo la punta
    for i, (z, h) in enumerate(((-0.98, 0.13), (-1.28, 0.17), (-1.58, 0.14))):
        w.profile(f"Crystal{i}", [(z, 0.34), (z - 0.22, 0.34), (z - 0.32, 0.34 + h)], 0.075, "Lens", 0.0)
    w.profile("CrystalChin", [(-1.56, -0.12), (-1.86, -0.10), (-1.98, -0.34)], 0.085, "Lens", 0.0)
    w.cyl("Barrel", (0, 0.06, -1.95), (0, 0.06, -2.26), 0.046, "Metal", 12)
    w.cyl("GasBlock", (0, 0.06, -2.02), (0, 0.06, -2.14), 0.07, "Dark", 8)
    # Boca: compensador grande con corona de cristales
    w.ring("MuzzleBrake", (0, 0.06, -2.20), (0, 0.06, -2.46), 0.105, 0.05, "Dark", 8)
    w.ring("MuzzleBand", (0, 0.06, -2.27), (0, 0.06, -2.33), 0.118, 0.1, "Panel", 8)
    w.cyl("MuzzleCore", (0, 0.06, -2.44), (0, 0.06, -2.50), 0.062, "Accent", 8)
    w.profile("CrownTop", [(-2.14, 0.14), (-2.36, 0.14), (-2.52, 0.29)], 0.07, "Lens", 0.0)
    w.profile("CrownBottom", [(-2.14, -0.02), (-2.52, -0.17), (-2.36, -0.02)], 0.07, "Lens", 0.0)
    for side in (-1, 1):
        w.box(f"CrownSide{side}", (side * 0.15, 0.06, -2.33), (0.05, 0.075, 0.34), "Lens", 0.0, rot=(0, side * 16, 0))

    # ---------------------------------------------------------------- raíl y visor holográfico
    w.box("Rail", (0, 0.352, -0.60), (0.115, 0.05, 2.5), "Dark", 0.01)
    for i in range(4):
        w.box(f"RailTooth{i}", (0, 0.384, -0.05 - i * 0.26), (0.13, 0.024, 0.11), "Dark", 0.0)
    w.box("SightBase", (0, 0.415, 0.35), (0.17, 0.07, 0.46), "Dark", 0.014)
    w.box("SightWallL", (-0.108, 0.60, 0.33), (0.016, 0.31, 0.22), "Body", 0.006)
    w.box("SightWallR", (0.108, 0.60, 0.33), (0.016, 0.31, 0.22), "Body", 0.006)
    w.box("SightHood", (0, 0.768, 0.34), (0.236, 0.024, 0.2), "Panel", 0.006)
    w.box("SightLens", (0, 0.61, 0.33), (0.2, 0.26, 0.012), "Lens", 0.0)
    w.box("Reticle", (0, 0.62, 0.318), (0.022, 0.022, 0.006), "Reticle", 0.0)
    w.box("FrontSight", (0, 0.42, -1.74), (0.05, 0.12, 0.07), "Dark", 0.0)

    # ---------------------------------------------------------------- empuñadura, gatillo, cargador
    w.profile("Grip", [(0.27, -0.17), (0.54, -0.17), (0.69, -0.80), (0.44, -0.83)], 0.175, "Rubber", 0.028)
    w.profile("GripInlay", [(0.36, -0.30), (0.50, -0.30), (0.60, -0.70), (0.47, -0.72)], 0.19, "Panel", 0.0)
    w.box("TriggerGuard", (0, -0.385, 0.06), (0.045, 0.026, 0.46), "Dark", 0.006)
    w.box("Trigger", (0, -0.275, 0.12), (0.03, 0.14, 0.035), "Metal", 0.0, rot=(-18, 0, 0))
    # Cargador: célula con las dos energías (plasma delante, fuego detrás)
    w.profile("Mag", [(-0.17, -0.25), (-0.54, -0.25), (-0.68, -0.90), (-0.60, -0.99), (-0.33, -0.95), (-0.24, -0.86)], 0.155, "Dark", 0.02, piece="Mag")
    w.profile("MagPlate", [(-0.63, -0.86), (-0.71, -0.93), (-0.61, -1.03), (-0.30, -0.99), (-0.21, -0.88), (-0.26, -0.83)], 0.185, "Dark", 0.012, piece="Mag")
    w.box("MagIce", (0, -0.57, -0.475), (0.166, 0.46, 0.1), "Accent", 0.0, piece="Mag", rot=(-12.5, 0, 0))
    w.box("MagFire", (0, -0.57, -0.365), (0.166, 0.46, 0.1), "Accent2", 0.0, piece="Mag", rot=(-12.5, 0, 0))
    w.box("MagRelease", (0.118, -0.16, -0.02), (0.02, 0.05, 0.07), "Metal", 0.0)

    # ---------------------------------------------------------------- empuñadura delantera
    w.profile("Foregrip", [(-1.02, -0.13), (-1.50, -0.13), (-1.44, -0.30), (-1.20, -0.44), (-1.08, -0.40)], 0.15, "Dark", 0.022)
    w.profile("ForegripInlay", [(-1.14, -0.19), (-1.40, -0.19), (-1.37, -0.28), (-1.21, -0.36)], 0.164, "Panel", 0.0)

    # ---------------------------------------------------------------- culata esquelética (fuego)
    w.profile("StockTop", [(0.78, 0.27), (1.50, 0.31), (1.50, 0.17), (0.78, 0.11)], 0.17, "Body", 0.018)
    w.profile("StockLower", [(0.72, -0.12), (0.72, 0.03), (1.46, -0.19), (1.46, -0.35)], 0.15, "Body", 0.018)
    w.profile("StockButt", [(1.42, 0.33), (1.63, 0.33), (1.66, -0.36), (1.52, -0.42), (1.40, -0.36)], 0.2, "Dark", 0.022)
    w.profile("ButtPlate", [(1.47, 0.27), (1.59, 0.27), (1.61, -0.30), (1.52, -0.35), (1.47, -0.30)], 0.212, "Panel", 0.0)
    w.box("ButtPad", (0, -0.03, 1.685), (0.2, 0.7, 0.06), "Rubber", 0.02)
    w.box("CheekRest", (0, 0.335, 1.16), (0.19, 0.05, 0.52), "Panel", 0.014)
    w.cyl("StockPin", (-0.09, 0.0, 1.08), (0.09, 0.0, 1.08), 0.035, "Metal", 8)
    vein(w, "VeinTop", 0.086, [(0.82, 0.20), (1.02, 0.25), (1.22, 0.19), (1.44, 0.25)])
    vein(w, "VeinLow", 0.076, [(0.80, -0.03), (1.04, -0.12), (1.22, -0.14), (1.42, -0.26)])
    vein(w, "VeinButt", 0.107, [(1.53, 0.22), (1.50, 0.04), (1.56, -0.12), (1.52, -0.28)], 0.024, "Dark")
    # Aletas de llama: dos sobre la culata y una por debajo, barridas hacia atrás
    w.profile("FlameFin0", [(0.92, 0.36), (1.16, 0.36), (1.30, 0.47)], 0.06, "Accent2", 0.0)
    w.profile("FlameFin1", [(1.22, 0.36), (1.46, 0.36), (1.66, 0.52)], 0.06, "Accent2", 0.0)
    w.profile("FlameFin2", [(1.02, -0.13), (1.26, -0.21), (1.40, -0.50)], 0.06, "Accent2", 0.0)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0.06, -2.52))
    w.point("AimPoint", (0, 0.62, 0.35))
    w.point("Eject", (0.15, 0.19, -0.42))
    w.point("RightHand", (0, -0.48, 0.47))
    w.point("LeftHand", (0, -0.30, -1.25))
    w.point("CharmPoint", (-0.13, 0.0, 0.72))
