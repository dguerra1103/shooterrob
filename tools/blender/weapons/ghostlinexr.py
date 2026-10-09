# GHOSTLINE XR · fusil de francotirador bullpup con supresor integrado (el sigiloso de SHOOTERROB).
# Silueta: casco monolítico anguloso con la acción y el cargador DETRÁS de la empuñadura, supresor
# muy largo y grueso de sección cuadrada facetada con bandas, visor fino de perfil bajo sobre un
# puente integrado y con parasol largo, cantonera corta de goma y bípode plegado bajo el supresor.
# Color: casi negro, una "línea fantasma" gris pálido a lo largo del costado y brillo azul frío.
NAME = "GhostlineXR"

PALETTE = {
    "Body": (0.055, 0.062, 0.085),
    "Panel": (0.68, 0.716, 0.775),  # blanco fantasma (sRGB 215, 220, 228)
    "Accent": (0.08, 0.2, 1.0),  # azul frío
    "Dark": (0.014, 0.015, 0.02),
    "Metal": (0.42, 0.44, 0.5),
    "Rubber": (0.026, 0.028, 0.034),
    "Lens": (0.12, 0.3, 0.95),
}

BY = 0.04  # eje del cañón (Muzzle.y)
SY = 0.55  # eje del visor (AimPoint.y)
SLANT = -24  # inclinación común de costuras y cortes


def build(w):
    # ---------------------------------------------------------------- casco monolítico
    w.profile("Shell", [(1.84, 0.23), (1.71, 0.34), (0.94, 0.34), (0.78, 0.27), (-1.12, 0.27), (-1.74, 0.17), (-1.74, 0.0), (1.84, 0.0)], 0.26, "Body", 0.022)
    w.profile("Lower", [(0.84, 0.02), (-1.74, 0.02), (-1.74, -0.07), (-1.58, -0.20), (-0.62, -0.20), (-0.42, -0.13), (0.84, -0.13)], 0.232, "Dark", 0.016)
    # Vientre trasero: aloja la acción y el brocal del cargador (lo que hace bullpup la silueta)
    w.profile("ActionBelly", [(0.78, 0.02), (0.78, -0.10), (0.95, -0.31), (1.66, -0.31), (1.84, -0.13), (1.84, 0.02)], 0.25, "Body", 0.02)
    # Línea fantasma: una hoja pálida y fina a lo largo de los dos costados + filo luminoso debajo
    w.profile("GhostBlade", [(0.52, 0.215), (-1.22, 0.215), (-1.56, 0.15), (0.44, 0.15)], 0.272, "Panel", 0.0)
    w.box("GhostGlow", (0, 0.105, -0.50), (0.268, 0.018, 1.80), "Accent", 0.0)
    w.box("ActionGlow", (0, 0.06, 1.34), (0.268, 0.018, 0.62), "Accent", 0.0)
    # Costuras oscuras (paneles del casco) y remate superior del guardamanos
    for i, z in enumerate((0.70, -1.02)):
        w.box(f"Seam{i}", (0, 0.125, z), (0.276, 0.25, 0.022), "Dark", 0.0, rot=(SLANT, 0, 0))
    w.box("ForendSpine", (0, 0.216, -1.43), (0.12, 0.03, 0.58), "Dark", 0.0, rot=(-9.2, 0, 0))
    # Branquias de acero delante del gatillo y galón pálido en la acción
    for i, z in enumerate((-0.74, -0.86, -0.98)):
        w.box(f"Gill{i}", (0, -0.06, z), (0.24, 0.12, 0.035), "Metal", 0.0, rot=(SLANT, 0, 0))
    w.profile("ActionChevron", [(1.63, -0.05), (1.71, -0.05), (1.58, -0.24), (1.50, -0.24)], 0.258, "Panel", 0.0)
    for z in (0.60, -1.40):
        w.cyl(f"Pin{z}", (-0.122, -0.06, z), (0.122, -0.06, z), 0.022, "Metal", 8)

    # ---------------------------------------------------------------- acción (detrás de la empuñadura)
    w.box("EjectionPort", (0.129, 0.19, 1.34), (0.012, 0.09, 0.42), "Dark", 0.0)
    w.box("BoltBody", (0.132, 0.19, 1.34), (0.012, 0.055, 0.36), "Metal", 0.0)
    w.cyl("BoltHandle", (0.11, 0.19, 1.00), (0.26, 0.09, 1.03), 0.026, "Metal", 8, piece="Bolt")
    w.cyl("BoltKnob", (0.24, 0.103, 1.026), (0.33, 0.043, 1.044), 0.054, "Panel", 8, piece="Bolt")

    # ---------------------------------------------------------------- carrillera y cantonera corta
    w.box("CheekPad", (0, 0.352, 1.36), (0.15, 0.03, 0.58), "Panel", 0.01)
    w.profile("ButtPlate", [(1.80, 0.25), (1.90, 0.25), (1.90, -0.20), (1.80, -0.20), (1.72, -0.30), (1.66, -0.30), (1.80, -0.12)], 0.24, "Dark", 0.016)
    w.box("ButtPad", (0, 0.02, 1.925), (0.25, 0.50, 0.06), "Rubber", 0.02)

    # ---------------------------------------------------------------- supresor integrado
    w.cyl("SuppCollar", (0, BY, -1.68), (0, BY, -1.86), 0.158, "Dark", 8)
    w.cyl("Suppressor", (0, BY, -1.70), (0, BY, -3.42), 0.13, "Body", 8)
    w.cyl("SuppBandPanel", (0, BY, -1.86), (0, BY, -1.91), 0.15, "Panel", 8)
    w.cyl("SuppGlow", (0, BY, -1.91), (0, BY, -1.935), 0.144, "Accent", 8)
    sections = ((-1.95, -2.42), (-2.49, -2.96), (-3.03, -3.38))
    for i, (za, zb) in enumerate(sections):
        zc, ln = (za + zb) / 2, za - zb
        w.box(f"SuppTop{i}", (0, BY + 0.12, zc), (0.155, 0.04, ln), "Body", 0.0)
        w.box(f"SuppBottom{i}", (0, BY - 0.12, zc), (0.155, 0.04, ln), "Body", 0.0)
        for side in (-1, 1):
            w.box(f"SuppSide{side}_{i}", (side * 0.12, BY, zc), (0.04, 0.155, ln), "Body", 0.0)
    for i, z in enumerate((-2.455, -2.995)):
        w.cyl(f"SuppBand{i}", (0, BY, z + 0.035), (0, BY, z - 0.035), 0.15, "Dark", 8)
    for side in (-1, 1):
        for i, z in enumerate((-3.12, -3.20, -3.28)):
            w.box(f"SuppSlit{side}_{i}", (side * 0.141, BY, z), (0.006, 0.09, 0.02), "Accent", 0.0)
    w.ring("MuzzleCap", (0, BY, -3.38), (0, BY, -3.50), 0.118, 0.042, "Dark", 8)

    # ---------------------------------------------------------------- visor fino de perfil bajo
    w.profile("ScopeBridge", [(0.74, 0.26), (0.62, 0.47), (0.02, 0.47), (-0.34, 0.26)], 0.11, "Dark", 0.012)
    w.box("BridgeClamp", (0, SY, 0.50), (0.16, 0.15, 0.10), "Dark", 0.0)
    w.cyl("ScopeTube", (0, SY, 0.74), (0, SY, -0.26), 0.064, "Body", 10)
    w.cyl("Eyepiece", (0, SY, 0.94), (0, SY, 0.70), 0.09, "Body", 10)
    w.cyl("Eyecup", (0, SY, 1.0), (0, SY, 0.92), 0.102, "Rubber", 10)
    w.cyl("EyeLens", (0, SY, 1.006), (0, SY, 0.985), 0.078, "Lens", 10)
    w.box("Saddle", (0, SY, 0.16), (0.15, 0.15, 0.17), "Body", 0.014)
    w.cyl("TurretTop", (0, 0.62, 0.16), (0, 0.67, 0.16), 0.052, "Metal", 8)
    w.cyl("TurretSide", (0.07, SY, 0.16), (0.125, SY, 0.16), 0.048, "Metal", 8)
    w.cyl("Sunshade", (0, SY, -0.22), (0, SY, -1.06), 0.09, "Body", 10)
    w.cyl("ShadeBand", (0, SY, -0.30), (0, SY, -0.35), 0.098, "Panel", 10)
    w.cyl("ShadeLip", (0, SY, -1.0), (0, SY, -1.08), 0.098, "Dark", 10)
    w.cyl("FrontLens", (0, SY, -1.07), (0, SY, -1.086), 0.078, "Lens", 10)

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.profile("Grip", [(0.45, -0.11), (0.72, -0.11), (0.81, -0.76), (0.56, -0.80)], 0.17, "Rubber", 0.026)
    w.profile("GripInlay", [(0.555, -0.30), (0.665, -0.30), (0.715, -0.62), (0.61, -0.64)], 0.184, "Dark", 0.0)
    w.box("GuardFront", (0, -0.26, 0.06), (0.045, 0.32, 0.03), "Dark", 0.0, rot=(-32, 0, 0))
    w.box("GuardBottom", (0, -0.395, 0.32), (0.045, 0.028, 0.36), "Dark", 0.0)
    w.box("GripStrut", (0, -0.56, 0.865), (0.10, 0.05, 0.58), "Body", 0.012, rot=(-49, 0, 0))
    w.box("Trigger", (0, -0.24, 0.30), (0.034, 0.15, 0.04), "Metal", 0.0, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- cargador (detrás de la empuñadura)
    w.profile("Magwell", [(1.02, -0.29), (1.58, -0.29), (1.54, -0.39), (1.06, -0.39)], 0.262, "Dark", 0.012)
    w.box("Mag", (0, -0.47, 1.30), (0.16, 0.36, 0.40), "Dark", 0.016, piece="Mag", rot=(5, 0, 0))
    w.box("MagPlate", (0, -0.665, 1.317), (0.19, 0.06, 0.46), "Panel", 0.012, piece="Mag", rot=(5, 0, 0))
    w.box("MagGlow", (0, -0.52, 1.30), (0.17, 0.16, 0.035), "Accent", 0.0, piece="Mag", rot=(5, 0, 0))
    w.box("MagRelease", (0, -0.34, 0.985), (0.07, 0.09, 0.03), "Metal", 0.0, rot=(22, 0, 0))

    # ---------------------------------------------------------------- bípode plegado bajo el supresor
    w.box("BipodMount", (0, -0.10, -1.70), (0.20, 0.10, 0.20), "Dark", 0.0)
    w.cyl("BipodHinge", (-0.135, -0.105, -1.80), (0.135, -0.105, -1.80), 0.036, "Metal", 8)
    for side in (-1, 1):
        w.box(f"BipodLeg{side}", (side * 0.09, -0.115, -2.22), (0.05, 0.05, 0.84), "Metal", 0.0)
        w.box(f"BipodFoot{side}", (side * 0.09, -0.115, -2.68), (0.066, 0.07, 0.11), "Rubber", 0.0)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BY, -3.50))
    w.point("AimPoint", (0, SY, 1.0))
    w.point("Eject", (0.15, 0.19, 1.34))
    w.point("RightHand", (0, -0.45, 0.62))
    w.point("LeftHand", (0, -0.2, -1.5))
    w.point("CharmPoint", (-0.135, -0.04, 0.95))
