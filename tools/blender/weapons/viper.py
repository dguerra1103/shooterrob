# VIPER P9 · pistola semiautomática por defecto (secundaria de SHOOTERROB).
# Silueta: corredera angulosa con tres cortes de aligeramiento inclinados que dejan ver el cañón de
# acero, compensador con puertos, módulo de luz bajo el raíl, empuñadura inclinada con inserto de
# color, brocal ensanchado y cargador prolongado con base de color.
NAME = "Viper"

PALETTE = {
    "Body": (0.05, 0.055, 0.07),
    "Panel": (1.0, 0.36, 0.03),  # naranja de la casa, un punto más caliente
    "Accent": (0.1, 0.95, 0.9),  # cian veneno
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.52, 0.54, 0.6),
    "Rubber": (0.028, 0.03, 0.036),
    "Lens": (0.2, 0.6, 1.0),
}

SLANT = -22.6  # inclinación común de cortes y estrías (la parte alta hacia delante)
GRIP = -13.6  # ángulo de la empuñadura


def build(w):
    S = "Slide"
    # ---------------------------------------------------------------- corredera (todo piece=Slide)
    w.profile("SlideRear", [(0.60, -0.09), (0.60, 0.09), (0.57, 0.15), (-0.06, 0.15), (0.04, -0.09)], 0.19, "Body", 0.02, piece=S)
    w.profile("SlideNose", [(-0.46, -0.09), (-0.46, 0.15), (-0.41, 0.15), (-0.31, -0.09)], 0.19, "Body", 0.018, piece=S)
    w.box("SlideTopBar", (0, 0.115, -0.22), (0.18, 0.07, 0.46), "Body", 0.012, piece=S)
    w.box("SlideBottomBar", (0, -0.0675, -0.2), (0.18, 0.045, 0.5), "Body", 0.01, piece=S)
    for i, z in enumerate((-0.238, -0.122)):
        w.box(f"SlidePillar{i}", (0, 0.0175, z), (0.18, 0.15, 0.036), "Body", 0.0, piece=S, rot=(SLANT, 0, 0))
    w.box("SlideCore", (0, 0.02, -0.2), (0.09, 0.13, 0.4), "Dark", 0.0, piece=S)
    w.box("TopRib", (0, 0.155, 0.03), (0.10, 0.03, 0.94), "Dark", 0.008, piece=S)
    w.box("TopStripe", (0, 0.168, 0.22), (0.05, 0.012, 0.36), "Panel", 0.0, piece=S)
    w.profile("SlidePlate", [(0.085, -0.065), (0.30, -0.065), (0.26, 0.03), (0.045, 0.03)], 0.198, "Panel", 0.0, piece=S)
    w.box("EjectionPort", (0.075, 0.105, 0.13), (0.045, 0.095, 0.18), "Dark", 0.0, piece=S)
    for i, z in enumerate((0.36, 0.405, 0.45, 0.495)):
        w.box(f"RearSerration{i}", (0, 0.03, z), (0.196, 0.2, 0.022), "Dark", 0.0, piece=S, rot=(SLANT, 0, 0))
    for i, z in enumerate((-0.385, -0.425)):
        w.box(f"FrontSerration{i}", (0, 0.025, z), (0.196, 0.17, 0.018), "Dark", 0.0, piece=S, rot=(SLANT, 0, 0))
    w.box("BackPlate", (0, 0.0, 0.602), (0.10, 0.10, 0.01), "Panel", 0.0, piece=S)
    # Miras: alza de dos postes con puntos y punto de mira
    w.box("RearSightBase", (0, 0.165, 0.54), (0.16, 0.04, 0.06), "Dark", 0.008, piece=S)
    for side in (-1, 1):
        w.box(f"RearSightPost{side}", (side * 0.055, 0.21, 0.54), (0.05, 0.06, 0.06), "Dark", 0.0, piece=S)
        w.box(f"RearSightDot{side}", (side * 0.055, 0.215, 0.572), (0.022, 0.022, 0.006), "Accent", 0.0, piece=S)
    w.box("FrontSight", (0, 0.185, -0.42), (0.035, 0.07, 0.05), "Dark", 0.0, piece=S)
    w.box("FrontSightDot", (0, 0.2, -0.393), (0.02, 0.022, 0.006), "Accent", 0.0, piece=S)

    # ---------------------------------------------------------------- cañón y compensador (fijos)
    w.cyl("Barrel", (0, 0.02, -0.59), (0, 0.02, 0.05), 0.06, "Metal", 10)
    w.profile("Compensator", [(-0.462, -0.09), (-0.462, 0.165), (-0.585, 0.165), (-0.61, -0.09)], 0.2, "Body", 0.018)
    for i, z in enumerate((-0.505, -0.545)):
        w.box(f"CompPort{i}", (0, 0.125, z), (0.204, 0.09, 0.02), "Dark", 0.0, rot=(SLANT, 0, 0))
    w.ring("MuzzleRing", (0, 0.02, -0.585), (0, 0.02, -0.62), 0.07, 0.036, "Metal", 10)

    # ---------------------------------------------------------------- armazón
    w.box("Frame", (0, -0.1475, -0.01), (0.17, 0.125, 1.18), "Body", 0.018)
    w.profile("Beavertail", [(0.50, -0.09), (0.655, -0.10), (0.675, -0.15), (0.50, -0.23)], 0.15, "Body", 0.012)
    w.box("FrameGlow", (0, -0.155, -0.215), (0.176, 0.02, 0.47), "Accent", 0.0)
    w.box("SlideStop", (-0.088, -0.115, 0.10), (0.014, 0.03, 0.14), "Metal", 0.0)
    w.cyl("TakedownPin", (-0.09, -0.115, -0.1), (0.09, -0.115, -0.1), 0.02, "Metal", 8)
    w.box("ThumbLedge", (-0.092, -0.19, 0.0), (0.03, 0.022, 0.13), "Dark", 0.0)
    # Raíl y módulo de luz
    w.box("Rail", (0, -0.22, -0.37), (0.19, 0.03, 0.38), "Dark", 0.0)
    w.profile("FrameChin", [(-0.602, -0.08), (-0.47, -0.08), (-0.53, -0.212), (-0.602, -0.212)], 0.176, "Panel", 0.0)
    w.profile("LightModule", [(-0.52, -0.20), (-0.18, -0.20), (-0.24, -0.37), (-0.52, -0.37)], 0.15, "Dark", 0.014)
    w.box("LightGlow", (0, -0.295, -0.37), (0.156, 0.016, 0.18), "Accent", 0.0)
    w.cyl("LightBezel", (0, -0.29, -0.50), (0, -0.29, -0.53), 0.052, "Metal", 10)
    w.cyl("LightLens", (0, -0.29, -0.52), (0, -0.29, -0.536), 0.038, "Lens", 10)
    w.box("LightSwitch", (0, -0.33, -0.22), (0.162, 0.04, 0.03), "Metal", 0.0)
    # Guardamonte y gatillo
    w.box("GuardFront", (0, -0.31, -0.15), (0.06, 0.25, 0.04), "Body", 0.008, rot=(-16, 0, 0))
    w.box("GuardBottom", (0, -0.42, 0.03), (0.06, 0.04, 0.32), "Body", 0.008)
    w.box("Trigger", (0, -0.275, 0.03), (0.034, 0.15, 0.04), "Panel", 0.0, rot=(-14, 0, 0))

    # ---------------------------------------------------------------- empuñadura
    w.profile("Grip", [(0.10, -0.19), (0.39, -0.19), (0.523, -0.74), (0.233, -0.74)], 0.18, "Rubber", 0.024)
    w.profile("GripInlay", [(0.199, -0.33), (0.339, -0.27), (0.428, -0.64), (0.273, -0.64)], 0.192, "Panel", 0.0)
    for i, y in enumerate((-0.52, -0.58)):
        w.box(f"GripGroove{i}", (0, y, 0.247 + 0.242 * (-0.2 - y)), (0.196, 0.018, 0.22), "Rubber", 0.0, rot=(GRIP, 0, 0))
    w.profile("Magwell", [(0.20, -0.67), (0.54, -0.67), (0.58, -0.76), (0.20, -0.76)], 0.215, "Body", 0.012)
    w.cyl("MagRelease", (-0.095, -0.265, 0.175), (0.095, -0.265, 0.175), 0.022, "Metal", 8)

    # ---------------------------------------------------------------- cargador (piece=Mag)
    w.box("Mag", (0, -0.52, 0.324), (0.12, 0.62, 0.2), "Dark", 0.0, piece="Mag", rot=(GRIP, 0, 0))
    w.profile("MagPlate", [(0.17, -0.76), (0.60, -0.76), (0.63, -0.81), (0.58, -0.85), (0.14, -0.83)], 0.20, "Panel", 0.012, piece="Mag")

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0.02, -0.62))
    w.point("AimPoint", (0, 0.21, 0.55))
    w.point("Eject", (0.11, 0.105, 0.13))
    w.point("RightHand", (0, -0.5, 0.32))
    w.point("LeftHand", (-0.16, -0.56, 0.3))
    w.point("CharmPoint", (-0.09, -0.15, 0.5))
