# INFERNO AR · fusil de asalto de magma (colección Elemental).
# Silueta: cañón dentro de una camisa rectangular que brilla por la boca, blindaje de obsidiana con
# púas en el lomo, grietas de magma en zigzag por todo el cuerpo, culata maciza angulosa y cargador
# recto y ancho que es una célula de lava.
import math

NAME = "InfernoAR"

PALETTE = {
    "Body": (0.045, 0.04, 0.045),
    "Panel": (0.72, 0.09, 0.02),  # rojo brasa
    "Accent": (1.0, 0.1, 0.0),  # magma (la emisión del render lo aclara)
    "Accent2": (1.0, 0.72, 0.12),  # núcleo al blanco
    "Dark": (0.016, 0.015, 0.018),
    "Metal": (0.42, 0.4, 0.42),
    "Trim": (0.13, 0.11, 0.11),  # obsidiana
    "Lens": (1.0, 0.5, 0.15),
}


def vein(w, name, x, points, thick=0.028, role="Accent", piece=None, depth=0.008):
    """Grieta en zigzag: points = [(z, y), ...]; un listón por tramo que atraviesa el arma y asoma
    por los dos costados (x = a qué distancia del centro está la superficie)."""
    for i in range(len(points) - 1):
        (z0, y0), (z1, y1) = points[i], points[i + 1]
        if z1 < z0:
            (z0, y0), (z1, y1) = (z1, y1), (z0, y0)
        length = math.hypot(z1 - z0, y1 - y0)
        angle = -math.degrees(math.atan2(y1 - y0, z1 - z0))
        w.box(f"{name}{i}", (0, (y0 + y1) / 2, (z0 + z1) / 2), (2 * x + depth, thick, length + thick * 0.6), role, 0.0, piece=piece, rot=(angle, 0, 0))


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.profile("Body", [(0.82, 0.0), (0.82, 0.22), (0.70, 0.34), (-0.86, 0.34), (-0.86, 0.0)], 0.26, "Body", 0.022)
    w.profile("Lower", [(0.76, 0.02), (0.76, -0.14), (0.24, -0.20), (-0.10, -0.20), (-0.10, -0.34), (-0.66, -0.34), (-0.70, -0.18), (-0.86, -0.14), (-0.86, 0.02)], 0.235, "Dark", 0.018)
    w.box("EjectionPort", (0.131, 0.2, -0.3), (0.012, 0.1, 0.34), "Dark", 0.0)
    w.box("Bolt", (0.134, 0.2, -0.3), (0.012, 0.068, 0.28), "Metal", 0.0, piece="Bolt")
    w.box("ChargingHandle", (0, 0.31, 0.8), (0.22, 0.05, 0.1), "Metal", 0.012, piece="Charge")
    # Blindaje de obsidiana y ventanas de calor (atraviesan el cajón: se ven por los dos costados)
    w.profile("Shard", [(0.74, 0.30), (0.30, 0.30), (0.16, 0.12), (0.52, 0.04), (0.74, 0.10)], 0.282, "Trim", 0.0)
    for i, z in enumerate((-0.02, -0.26)):
        w.box(f"HeatSlot{i}", (0, 0.275, z), (0.27, 0.045, 0.17), "Accent2", 0.0)
    vein(w, "VeinBody", 0.131, [(0.14, 0.05), (-0.08, 0.14), (-0.34, 0.04), (-0.58, 0.13), (-0.84, 0.05)])
    vein(w, "VeinLow", 0.119, [(0.70, -0.04), (0.44, -0.12), (0.22, -0.05)], 0.024)
    w.profile("MagwellCollar", [(-0.08, -0.27), (-0.08, -0.36), (-0.68, -0.36), (-0.71, -0.27)], 0.25, "Panel", 0.01)
    w.cyl("PinRear", (-0.121, -0.05, 0.56), (0.121, -0.05, 0.56), 0.022, "Metal", 8)

    # ---------------------------------------------------------------- guardamanos de obsidiana
    w.profile("Handguard", [(-0.86, 0.34), (-1.70, 0.34), (-1.84, 0.24), (-1.84, -0.04), (-1.64, -0.17), (-0.86, -0.17)], 0.28, "Trim", 0.024)
    w.profile("HandguardBelly", [(-0.90, -0.10), (-1.66, -0.10), (-1.58, -0.21), (-0.94, -0.21)], 0.2, "Panel", 0.012)
    for i, z in enumerate((-1.02, -1.22, -1.42)):
        w.box(f"Vent{i}", (0, 0.19, z), (0.29, 0.17, 0.06), "Accent", 0.0, rot=(-26, 0, 0))
    vein(w, "VeinHg", 0.141, [(-0.90, 0.02), (-1.16, -0.06), (-1.40, 0.03), (-1.62, -0.05), (-1.80, 0.06)])
    # Púas del lomo (silueta) con la rejilla que escupe las llamas entre ellas
    for i, z in enumerate((-0.98, -1.30)):
        w.profile(f"Spike{i}", [(z, 0.37), (z - 0.26, 0.37), (z - 0.06, 0.50)], 0.07, "Trim", 0.0)
        w.box(f"TopVent{i}", (0, 0.378, z - 0.2), (0.12, 0.012, 0.09), "Accent", 0.0)

    # ---------------------------------------------------------------- camisa del cañón («boca de horno»)
    w.profile("Shroud", [(-1.80, 0.29), (-2.44, 0.29), (-2.56, 0.20), (-2.56, -0.06), (-2.44, -0.15), (-1.80, -0.15)], 0.23, "Dark", 0.02)
    w.profile("ShroudFin", [(-1.84, 0.29), (-2.38, 0.29), (-2.26, 0.36), (-1.84, 0.36)], 0.08, "Panel", 0.0)
    w.profile("ShroudChin", [(-1.84, -0.15), (-2.36, -0.15), (-2.20, -0.21), (-1.84, -0.21)], 0.1, "Panel", 0.0)
    w.box("ShroudBand", (0, 0.07, -1.93), (0.245, 0.455, 0.07), "Panel", 0.008)
    for side in (-1, 1):
        w.box(f"MuzzleFrameV{side}", (side * 0.092, 0.07, -2.563), (0.022, 0.24, 0.012), "Accent", 0.0)
        w.box(f"MuzzleFrameH{side}", (0, 0.07 + side * 0.109, -2.563), (0.2, 0.022, 0.012), "Accent", 0.0)
    for i, z in enumerate((-2.12, -2.36)):
        w.box(f"ShroudSlot{i}", (0, 0.07, z), (0.24, 0.07, 0.17), "Accent", 0.0)
    w.box("MuzzleCore", (0, 0.07, -2.561), (0.14, 0.17, 0.01), "Accent2", 0.0)
    w.ring("Bore", (0, 0.07, -2.50), (0, 0.07, -2.60), 0.062, 0.036, "Metal", 10)

    # ---------------------------------------------------------------- raíl y visor
    w.box("Rail", (0, 0.36, -0.02), (0.115, 0.05, 1.56), "Dark", 0.01)
    for i in range(4):
        w.box(f"RailTooth{i}", (0, 0.392, -0.02 - i * 0.2), (0.13, 0.024, 0.09), "Dark", 0.0)
    w.box("SightBase", (0, 0.41, 0.4), (0.18, 0.06, 0.4), "Dark", 0.012)
    for side in (-1, 1):
        w.profile(f"SightWall{side}", [(0.54, 0.44), (0.30, 0.44), (0.30, 0.66), (0.40, 0.70), (0.48, 0.66)], 0.018, "Trim", 0.0, x=side * 0.105)
    w.box("SightHood", (0, 0.705, 0.4), (0.228, 0.022, 0.16), "Panel", 0.0)
    w.box("SightLens", (0, 0.56, 0.4), (0.196, 0.24, 0.012), "Lens", 0.0)
    w.box("Reticle", (0, 0.56, 0.388), (0.022, 0.022, 0.006), "Reticle", 0.0)
    w.box("FrontSight", (0, 0.41, -1.72), (0.05, 0.12, 0.07), "Dark", 0.0)
    w.box("FrontSightTip", (0, 0.478, -1.72), (0.03, 0.02, 0.04), "Accent2", 0.0)

    # ---------------------------------------------------------------- empuñadura, gatillo
    w.profile("Grip", [(0.27, -0.17), (0.55, -0.17), (0.71, -0.80), (0.45, -0.84)], 0.18, "Rubber", 0.028)
    vein(w, "VeinGrip", 0.092, [(0.42, -0.28), (0.52, -0.46), (0.47, -0.60), (0.58, -0.74)], 0.024)
    w.box("TriggerGuard", (0, -0.385, 0.07), (0.045, 0.026, 0.44), "Dark", 0.006)
    w.box("Trigger", (0, -0.275, 0.12), (0.03, 0.14, 0.035), "Metal", 0.0, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- cargador: célula de lava
    w.profile("Mag", [(-0.14, -0.24), (-0.63, -0.24), (-0.73, -0.96), (-0.66, -1.04), (-0.30, -1.04), (-0.24, -0.98)], 0.17, "Dark", 0.02, piece="Mag")
    w.profile("MagLava", [(-0.22, -0.38), (-0.58, -0.38), (-0.65, -0.92), (-0.31, -0.92)], 0.184, "Accent", 0.0, piece="Mag")
    # Costra oscura sobre la lava: parte la ventana en celdas
    vein(w, "Crusta", 0.094, [(-0.24, -0.52), (-0.40, -0.60), (-0.60, -0.54)], 0.022, "Dark", "Mag", 0.006)
    vein(w, "Crustb", 0.094, [(-0.28, -0.76), (-0.46, -0.70), (-0.63, -0.78)], 0.022, "Dark", "Mag", 0.006)
    vein(w, "Crustc", 0.094, [(-0.40, -0.60), (-0.46, -0.70)], 0.022, "Dark", "Mag", 0.006)
    vein(w, "Crustd", 0.094, [(-0.38, -0.39), (-0.40, -0.60)], 0.022, "Dark", "Mag", 0.006)
    vein(w, "Cruste", 0.094, [(-0.46, -0.70), (-0.48, -0.91)], 0.022, "Dark", "Mag", 0.006)

    # ---------------------------------------------------------------- empuñadura delantera
    w.profile("Foregrip", [(-1.04, -0.19), (-1.44, -0.19), (-1.52, -0.50), (-1.34, -0.56), (-1.14, -0.44)], 0.15, "Dark", 0.02)
    w.profile("ForegripInlay", [(-1.16, -0.26), (-1.38, -0.26), (-1.43, -0.46), (-1.33, -0.50), (-1.21, -0.42)], 0.164, "Panel", 0.0)

    # ---------------------------------------------------------------- culata maciza
    w.profile("Stock", [(0.78, 0.26), (1.16, 0.34), (1.60, 0.34), (1.70, 0.24), (1.70, -0.40), (1.52, -0.46), (1.26, -0.16), (0.78, -0.10)], 0.19, "Body", 0.022)
    w.profile("StockPlate", [(1.20, 0.30), (1.58, 0.30), (1.64, 0.22), (1.64, -0.34), (1.52, -0.38), (1.30, -0.10), (1.20, 0.06)], 0.206, "Trim", 0.0)
    vein(w, "VeinStock", 0.104, [(0.82, 0.10), (1.04, 0.02), (1.22, 0.16), (1.40, -0.02), (1.50, -0.24), (1.62, -0.32)], 0.03)
    w.profile("StockToe", [(1.30, -0.16), (1.52, -0.46), (1.44, -0.48), (1.22, -0.20)], 0.2, "Panel", 0.0)
    w.box("ButtPad", (0, -0.06, 1.725), (0.2, 0.66, 0.06), "Rubber", 0.02)
    w.box("CheekRest", (0, 0.345, 1.36), (0.2, 0.04, 0.44), "Panel", 0.012)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0.07, -2.6))
    w.point("AimPoint", (0, 0.56, 0.4))
    w.point("Eject", (0.15, 0.2, -0.3))
    w.point("RightHand", (0, -0.48, 0.47))
    w.point("LeftHand", (0, -0.36, -1.3))
    w.point("CharmPoint", (-0.135, -0.02, 0.6))
