# RAPTOR DMR · fusil de tirador semiautomático (entre el ARX-27 y el Signal-7).
# Silueta: fusil de batalla largo y esbelto. Guardamanos flotante fino con ranuras horizontales largas
# y punta en bisel invertido, visor prismático CUADRADO de aumento medio con lente frontal visible,
# cargador recto de 20, culata fija de precisión con carrillera regulable y cantonera con gancho,
# cañón largo con freno plano y bípode corto plegado hacia atrás (hace de tope de mano).
NAME = "RaptorDMR"

PALETTE = {
    "Body": (0.045, 0.052, 0.068),
    "Panel": (0.84, 0.47, 0.05),  # oro desierto / ámbar (≈ RGB 235,170,50 en pantalla)
    "Accent": (0.1, 0.9, 1.0),  # cian luminoso
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.5, 0.52, 0.58),
    "Lens": (0.06, 0.5, 0.75),
    "Trim": (0.95, 0.66, 0.16),  # oro claro (remates pequeños)
}

BY = 0.04  # eje del cañón (Muzzle.y)
SY = 0.55  # eje del visor (AimPoint.y)
GA = -12  # inclinación de la empuñadura
MA = 5  # inclinación del cargador


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.profile("Receiver", [(0.80, 0.0), (0.80, 0.18), (0.70, 0.26), (-0.70, 0.26), (-0.78, 0.22), (-0.78, 0.0)], 0.22, "Body", 0.02)
    w.box("Lower", (0, -0.06, -0.01), (0.20, 0.16, 1.54), "Dark", 0.016)
    w.profile("Magwell", [(-0.07, -0.08), (-0.09, -0.23), (-0.56, -0.23), (-0.63, -0.08)], 0.222, "Body", 0.014)
    # Placa lateral (izquierda), ventana de expulsión y cerrojo (derecha)
    w.profile("SidePlate", [(0.62, 0.215), (-0.04, 0.215), (-0.16, 0.10), (0.50, 0.10)], 0.012, "Panel", 0.0, x=-0.112)
    w.profile("SidePlateR", [(0.62, 0.215), (0.20, 0.215), (0.08, 0.10), (0.50, 0.10)], 0.012, "Panel", 0.0, x=0.112)
    w.box("EjectionPort", (0.109, 0.16, -0.27), (0.012, 0.095, 0.38), "Dark", 0.0)
    w.box("BoltCarrier", (0.112, 0.16, -0.27), (0.012, 0.062, 0.30), "Metal", 0.0, piece="Bolt")
    w.box("GlowStrip", (0, 0.045, 0.30), (0.228, 0.022, 0.52), "Accent", 0.0)
    # Palanca de montar lateral (izquierda, adelantada) con su carril
    w.box("ChargeTrack", (-0.109, 0.17, -0.47), (0.012, 0.032, 0.42), "Dark", 0.0)
    w.box("ChargeHandle", (-0.14, 0.17, -0.60), (0.07, 0.05, 0.08), "Metal", 0.008, piece="Charge")
    for z in (0.60, -0.70):
        w.cyl(f"Pin{z}", (-0.104, -0.05, z), (0.104, -0.05, z), 0.02, "Metal", 8)
    w.box("Selector", (-0.106, -0.04, 0.24), (0.016, 0.028, 0.10), "Trim", 0.0, rot=(25, 0, 0))
    w.box("MagRelease", (0.106, -0.10, 0.03), (0.02, 0.05, 0.07), "Metal", 0.0)
    w.box("RearCap", (0, 0.10, 0.81), (0.17, 0.14, 0.04), "Dark", 0.0)

    # ---------------------------------------------------------------- guardamanos flotante
    w.profile("Handguard", [(-0.76, 0.24), (-1.90, 0.24), (-1.90, 0.17), (-1.76, -0.105), (-0.76, -0.125)], 0.20, "Body", 0.02)
    w.profile("HgPlate", [(-0.88, 0.165), (-1.77, 0.165), (-1.69, -0.03), (-0.88, -0.05)], 0.212, "Panel", 0.0)
    for i, (z, y) in enumerate(((-1.11, 0.107), (-1.52, 0.107), (-1.09, 0.012), (-1.48, 0.012))):
        w.box(f"HgSlot{i}", (0, y, z), (0.222, 0.052, 0.35), "Dark", 0.0)
    w.box("HgGlow", (0, -0.088, -1.24), (0.206, 0.018, 0.80), "Accent", 0.0)
    w.box("HgRail", (0, 0.25, -1.33), (0.09, 0.03, 1.12), "Dark", 0.0)
    for i in range(3):
        w.box(f"HgTooth{i}", (0, 0.272, -1.00 - i * 0.36), (0.105, 0.02, 0.10), "Dark", 0.0)
    w.cyl("BarrelNut", (0, BY, -1.80), (0, BY, -1.93), 0.072, "Dark", 8)
    w.cyl("BarrelHeavy", (0, BY, -1.90), (0, BY, -2.16), 0.054, "Body", 8)

    # ---------------------------------------------------------------- cañón y freno plano
    w.cyl("Barrel", (0, BY, -1.80), (0, BY, -2.50), 0.042, "Metal", 10)
    w.cyl("GasBlock", (0, BY, -2.16), (0, BY, -2.25), 0.066, "Dark", 8)
    w.profile("Brake", [(-2.38, 0.10), (-2.45, 0.15), (-2.70, 0.125), (-2.70, -0.045), (-2.45, -0.07), (-2.38, -0.02)], 0.12, "Body", 0.012)
    w.box("BrakeBand", (0, BY, -2.44), (0.132, 0.205, 0.03), "Trim", 0.0)
    for i, z in enumerate((-2.52, -2.61)):
        w.box(f"BrakePort{i}", (0, BY, z), (0.13, 0.085, 0.045), "Dark", 0.0)
    w.cyl("Bore", (0, BY, -2.62), (0, BY, -2.701), 0.034, "Dark", 8)

    # ---------------------------------------------------------------- raíl y visor prismático
    w.box("Rail", (0, 0.283, -0.05), (0.10, 0.046, 1.40), "Dark", 0.008)
    for i in range(3):
        w.box(f"RailTooth{i}", (0, 0.312, 0.56 - i * 0.56), (0.115, 0.02, 0.10), "Dark", 0.0)
    for i, z in enumerate((0.20, -0.22)):
        w.box(f"MountBase{i}", (0, 0.375, z), (0.15, 0.13, 0.12), "Dark", 0.0)
        w.cyl(f"MountBolt{i}", (0.07, 0.36, z), (0.10, 0.36, z), 0.03, "Metal", 8)
    # Visor prismático HUECO: en el juego se mira a través de él (no hay superposición de mira como en
    # los francotiradores), así que es un túnel de cuatro paredes con la lente delante y el retículo dentro
    w.box("ScopeFloor", (0, 0.445, -0.07), (0.23, 0.02, 0.78), "Body", 0.0)
    w.box("ScopeRoof", (0, 0.665, -0.07), (0.23, 0.02, 0.78), "Body", 0.006)
    for side in (-1, 1):
        w.box(f"ScopeWall{side}", (side * 0.106, 0.555, -0.07), (0.018, 0.2, 0.78), "Body", 0.0)
        w.box(f"ObjectiveWall{side}", (side * 0.118, 0.555, -0.37), (0.03, 0.27, 0.18), "Body", 0.0)
        w.box(f"ObjectiveBand{side}", (side * 0.135, 0.555, -0.31), (0.012, 0.278, 0.035), "Panel", 0.0)
        w.box(f"EyeRim{side}", (side * 0.112, 0.555, 0.335), (0.022, 0.22, 0.05), "Rubber", 0.0)
    w.box("ObjectiveRoof", (0, 0.69, -0.37), (0.266, 0.03, 0.18), "Body", 0.0)
    w.box("ObjectiveFloor", (0, 0.425, -0.37), (0.266, 0.03, 0.18), "Body", 0.0)
    w.box("EyeRimTop", (0, 0.672, 0.335), (0.245, 0.022, 0.05), "Rubber", 0.0)
    w.box("Brow", (0, 0.712, -0.39), (0.262, 0.02, 0.24), "Dark", 0.0)
    w.box("ObjectiveBandTop", (0, 0.708, -0.31), (0.27, 0.012, 0.035), "Panel", 0.0)
    w.box("FrontLens", (0, 0.555, -0.455), (0.21, 0.23, 0.01), "Lens", 0.0)
    w.box("Reticle", (0, SY, -0.2), (0.014, 0.014, 0.006), "Reticle", 0.0)
    w.box("ScopePlateL", (-0.116, 0.52, 0.02), (0.01, 0.07, 0.42), "Panel", 0.0)
    w.box("ScopeGlowL", (-0.116, 0.60, 0.02), (0.01, 0.018, 0.42), "Accent", 0.0)
    w.box("ScopeGlowR", (0.116, 0.60, 0.02), (0.01, 0.018, 0.42), "Accent", 0.0)
    w.cyl("TurretTop", (0, 0.67, 0.04), (0, 0.735, 0.04), 0.058, "Metal", 10)
    w.cyl("TurretTopCap", (0, 0.735, 0.04), (0, 0.76, 0.04), 0.064, "Trim", 10)
    w.cyl("TurretSide", (0.11, 0.535, 0.04), (0.17, 0.535, 0.04), 0.055, "Metal", 10)
    w.cyl("TurretSideCap", (0.17, 0.535, 0.04), (0.19, 0.535, 0.04), 0.061, "Trim", 10)

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.box("Grip", (0, -0.46, 0.44), (0.165, 0.70, 0.25), "Rubber", 0.028, rot=(GA, 0, 0))
    w.box("GripInlay", (0, -0.47, 0.445), (0.18, 0.40, 0.12), "Panel", 0.0, rot=(GA, 0, 0))
    w.box("GripHeel", (0, -0.805, 0.525), (0.175, 0.05, 0.30), "Dark", 0.0, rot=(GA, 0, 0))
    w.box("TriggerGuard", (0, -0.335, 0.12), (0.04, 0.026, 0.42), "Dark", 0.0)
    w.box("GuardFront", (0, -0.24, -0.08), (0.04, 0.21, 0.03), "Dark", 0.0)
    w.box("Trigger", (0, -0.235, 0.14), (0.03, 0.14, 0.04), "Metal", 0.0, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- cargador recto de 20
    w.box("Mag", (0, -0.49, -0.335), (0.15, 0.60, 0.40), "Dark", 0.018, piece="Mag", rot=(MA, 0, 0))
    w.box("MagPlate", (0, -0.80, -0.362), (0.176, 0.06, 0.45), "Panel", 0.012, piece="Mag", rot=(MA, 0, 0))
    w.box("MagBand", (0, -0.36, -0.324), (0.162, 0.035, 0.41), "Panel", 0.0, piece="Mag", rot=(MA, 0, 0))
    w.box("MagGlow", (0, -0.57, -0.26), (0.16, 0.26, 0.035), "Accent", 0.0, piece="Mag", rot=(MA, 0, 0))

    # ---------------------------------------------------------------- bípode corto plegado hacia atrás
    w.box("BipodMount", (0, -0.145, -1.66), (0.17, 0.09, 0.16), "Dark", 0.0)
    w.cyl("BipodHinge", (-0.115, -0.165, -1.69), (0.115, -0.165, -1.69), 0.032, "Trim", 8)
    for side in (-1, 1):
        w.box(f"BipodLeg{side}", (side * 0.08, -0.165, -1.52), (0.045, 0.055, 0.34), "Metal", 0.0)
        w.box(f"BipodFoot{side}", (side * 0.08, -0.165, -1.35), (0.06, 0.10, 0.09), "Rubber", 0.0)

    # ---------------------------------------------------------------- culata fija de precisión
    w.profile("StockBeam", [(0.78, 0.20), (1.08, 0.13), (1.72, 0.13), (1.72, -0.18), (1.30, -0.07), (0.78, -0.11)], 0.15, "Body", 0.018)
    w.profile("Butt", [(1.66, 0.22), (1.84, 0.22), (1.84, -0.58), (1.50, -0.63), (1.40, -0.50), (1.66, -0.28)], 0.18, "Dark", 0.018)
    w.box("ButtPad", (0, -0.18, 1.865), (0.19, 0.84, 0.05), "Rubber", 0.016)
    w.profile("StockPlate", [(0.94, 0.095), (1.62, 0.085), (1.62, -0.10), (1.30, -0.025), (0.94, -0.05)], 0.162, "Panel", 0.0)
    w.box("StockGlow", (0, 0.03, 1.27), (0.168, 0.02, 0.50), "Accent", 0.0)
    w.box("ButtStripe", (0, -0.47, 1.66), (0.188, 0.04, 0.30), "Panel", 0.0, rot=(-9, 0, 0))
    w.box("CheekRest", (0, 0.27, 1.30), (0.17, 0.07, 0.56), "Panel", 0.014)
    w.box("CheekPad", (0, 0.312, 1.30), (0.15, 0.022, 0.50), "Rubber", 0.0)
    for z in (1.14, 1.46):
        w.cyl(f"CheekPost{z}", (0, 0.12, z), (0, 0.25, z), 0.026, "Metal", 8)
    w.cyl("CheekKnob", (0.07, 0.06, 1.46), (0.115, 0.06, 1.46), 0.045, "Trim", 8)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BY, -2.70))
    w.point("AimPoint", (0, SY, 0.40))
    w.point("Eject", (0.14, 0.16, -0.27))
    w.point("RightHand", (0, -0.45, 0.42))
    w.point("LeftHand", (0, -0.18, -1.20))
    w.point("CharmPoint", (-0.125, 0.0, 0.55))
