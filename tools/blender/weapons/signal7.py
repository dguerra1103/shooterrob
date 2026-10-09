# SIGNAL-7 · fusil de francotirador de cerrojo (el arma más larga de SHOOTERROB).
# Silueta: chasis esquelético con culata de ojal y carrillera regulable, guardamanos afilado con
# placa de acento, cañón con funda hexagonal y freno de boca anguloso, visor grande con campana,
# torretas y lente de color, bípode plegado y celdas de carga luminosas a lo largo del cajón.
NAME = "Signal7"

PALETTE = {
    "Body": (0.045, 0.052, 0.07),
    "Panel": (1.0, 0.33, 0.03),  # naranja de la casa, un punto más rojo (ámbar de señal)
    "Accent": (0.1, 0.95, 0.9),  # cian algo más verde
    "Dark": (0.015, 0.016, 0.021),
    "Metal": (0.5, 0.52, 0.58),
    "Lens": (0.05, 0.42, 0.7),
}

BY = 0.05  # eje del cañón
SY = 0.52  # eje del visor (AimPoint.y)


def build(w):
    # ---------------------------------------------------------------- cajón y chasis
    w.profile("Receiver", [(0.78, 0.02), (0.78, 0.20), (0.68, 0.27), (-0.80, 0.27), (-0.88, 0.20), (-0.88, 0.02)], 0.24, "Body", 0.02)
    w.profile("Chassis", [(0.82, 0.04), (0.82, -0.15), (0.34, -0.19), (-0.90, -0.19), (-0.90, 0.04)], 0.215, "Dark", 0.016)
    # Placa lateral de acento (izquierda), ventana de expulsión y cerrojo (derecha)
    w.profile("SidePlate", [(0.62, 0.225), (-0.50, 0.225), (-0.62, 0.125), (0.50, 0.125)], 0.012, "Panel", 0.0, x=-0.122)
    w.box("EjectionPort", (0.119, 0.17, -0.25), (0.012, 0.095, 0.44), "Dark", 0.0)
    w.box("BoltBody", (0.122, 0.17, -0.25), (0.012, 0.06, 0.38), "Metal", 0.0)
    w.cyl("BoltShroud", (0, 0.185, 0.70), (0, 0.185, 0.90), 0.062, "Metal", 8)
    w.cyl("BoltHandle", (0.10, 0.17, 0.36), (0.27, 0.05, 0.40), 0.027, "Metal", 8, piece="Bolt")
    w.cyl("BoltKnob", (0.25, 0.064, 0.395), (0.345, -0.003, 0.417), 0.058, "Panel", 8, piece="Bolt")
    # Celdas de carga (atraviesan el cajón: se ven por los dos lados)
    for i in range(5):
        w.box(f"ChargeCell{i}", (0, 0.072, 0.50 - i * 0.25), (0.25, 0.03, 0.17), "Accent", 0.0)
    for z in (0.62, -0.72):
        w.cyl(f"Pin{z}", (-0.112, -0.07, z), (0.112, -0.07, z), 0.022, "Metal", 8)

    # ---------------------------------------------------------------- guardamanos
    w.profile("Forend", [(-0.86, 0.21), (-2.18, 0.17), (-2.44, 0.03), (-2.44, -0.05), (-2.24, -0.20), (-0.86, -0.20)], 0.26, "Body", 0.022)
    w.profile("ForendPlate", [(-1.00, 0.13), (-2.12, 0.10), (-2.30, -0.01), (-1.14, -0.04)], 0.276, "Panel", 0.0)
    for i, z in enumerate((-1.30, -1.50, -1.70, -1.90)):
        w.box(f"Vent{i}", (0, 0.045, z), (0.288, 0.13, 0.05), "Dark", 0.0, rot=(-28, 0, 0))
    w.box("ForendGlow", (0, -0.125, -1.55), (0.268, 0.022, 1.20), "Accent", 0.0)
    w.box("ForendTop", (0, 0.20, -1.50), (0.10, 0.035, 1.20), "Dark", 0.008, rot=(-1.7, 0, 0))

    for i in range(3):
        w.box(f"ForendTooth{i}", (0, 0.222 - i * 0.011, -1.12 - i * 0.38), (0.115, 0.022, 0.10), "Dark", 0.0)
    w.cyl("SlingStud", (-0.12, -0.14, -2.20), (0.12, -0.14, -2.20), 0.024, "Metal", 8)

    # ---------------------------------------------------------------- cañón y freno de boca
    w.cyl("Barrel", (0, BY, -2.30), (0, BY, -3.45), 0.046, "Metal", 10)
    w.cyl("BarrelNut", (0, BY, -2.40), (0, BY, -2.56), 0.088, "Dark", 8)
    w.cyl("BarrelSleeve", (0, BY, -2.56), (0, BY, -3.20), 0.074, "Body", 6)
    for i, z in enumerate((-2.76, -3.02)):
        w.box(f"SleeveSlot{i}", (0, BY, z), (0.152, 0.03, 0.18), "Dark", 0.0)
    w.cyl("SleeveBand", (0, BY, -3.20), (0, BY, -3.26), 0.084, "Panel", 8)
    # Freno de boca grande y anguloso: cuña con aleta superior, banda de acento y dos lumbreras
    w.profile("Brake", [(-3.34, 0.15), (-3.62, 0.24), (-3.775, 0.17), (-3.775, -0.05), (-3.66, -0.11), (-3.40, -0.08)], 0.20, "Body", 0.016)
    w.box("BrakeBand", (0, 0.04, -3.385), (0.222, 0.25, 0.04), "Panel", 0.0, rot=(-12, 0, 0))
    for i, z in enumerate((-3.50, -3.62)):
        w.box(f"BrakePort{i}", (0, 0.06, z), (0.212, 0.15, 0.05), "Dark", 0.0, rot=(-16, 0, 0))
    w.box("BrakeGlow", (0, -0.06, -3.57), (0.208, 0.016, 0.20), "Accent", 0.0, rot=(-5, 0, 0))
    w.cyl("Bore", (0, BY, -3.70), (0, BY, -3.78), 0.045, "Dark", 8)

    # ---------------------------------------------------------------- raíl y visor
    w.box("Rail", (0, 0.29, -0.06), (0.11, 0.05, 1.60), "Dark", 0.008)
    for i in range(4):
        w.box(f"RailTooth{i}", (0, 0.322, 0.62 - i * 0.44), (0.125, 0.022, 0.10), "Dark", 0.0)
    for i, z in enumerate((0.42, -0.26)):
        w.box(f"MountBase{i}", (0, 0.385, z), (0.14, 0.15, 0.11), "Dark", 0.0)
        w.cyl(f"MountRing{i}", (0, SY, z - 0.055), (0, SY, z + 0.055), 0.108, "Dark", 10)
        w.box(f"MountScrew{i}", (0, 0.64, z), (0.05, 0.03, 0.07), "Metal", 0.0)
    w.cyl("ScopeTube", (0, SY, 0.74), (0, SY, -0.42), 0.085, "Body", 12)
    w.cyl("Eyepiece", (0, SY, 0.92), (0, SY, 0.66), 0.118, "Body", 12)
    w.cyl("ZoomRing", (0, SY, 0.66), (0, SY, 0.58), 0.108, "Panel", 12)
    w.cyl("Eyecup", (0, SY, 1.0), (0, SY, 0.90), 0.132, "Rubber", 12)
    w.cyl("EyeLens", (0, SY, 1.006), (0, SY, 0.985), 0.104, "Lens", 12)
    w.box("Saddle", (0, SY, 0.08), (0.20, 0.20, 0.22), "Body", 0.02)
    w.cyl("TurretTop", (0, 0.60, 0.08), (0, 0.71, 0.08), 0.062, "Metal", 10)
    w.cyl("TurretTopCap", (0, 0.71, 0.08), (0, 0.735, 0.08), 0.068, "Panel", 10)
    w.cyl("TurretSide", (0.09, SY, 0.08), (0.185, SY, 0.08), 0.058, "Metal", 10)
    w.cyl("TurretSideCap", (0.185, SY, 0.08), (0.205, SY, 0.08), 0.064, "Panel", 10)
    w.cyl("ParallaxKnob", (-0.09, SY, 0.08), (-0.17, SY, 0.08), 0.07, "Dark", 10)
    w.cyl("BellNeck", (0, SY, -0.40), (0, SY, -0.56), 0.112, "Body", 12)
    w.cyl("Bell", (0, SY, -0.54), (0, SY, -0.92), 0.148, "Body", 12)
    w.cyl("BellBand", (0, SY, -0.62), (0, SY, -0.68), 0.156, "Panel", 12)
    w.cyl("Sunshade", (0, SY, -0.92), (0, SY, -1.08), 0.158, "Dark", 12)
    w.cyl("FrontLens", (0, SY, -1.07), (0, SY, -1.088), 0.134, "Lens", 12)

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.box("Grip", (0, -0.46, 0.62), (0.17, 0.70, 0.25), "Rubber", 0.03, rot=(-14, 0, 0))
    w.box("GripInlay", (0, -0.48, 0.625), (0.186, 0.40, 0.12), "Panel", 0.0, rot=(-14, 0, 0))
    w.box("TriggerGuard", (0, -0.335, 0.27), (0.04, 0.026, 0.42), "Dark", 0.0)
    w.box("GuardFront", (0, -0.26, 0.07), (0.04, 0.17, 0.03), "Dark", 0.0)
    w.box("Trigger", (0, -0.25, 0.30), (0.034, 0.14, 0.045), "Metal", 0.0, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- cargador de petaca
    w.box("Magwell", (0, -0.19, -0.27), (0.235, 0.09, 0.56), "Body", 0.014)
    w.box("Mag", (0, -0.36, -0.27), (0.16, 0.40, 0.42), "Dark", 0.02, piece="Mag", rot=(6, 0, 0))
    w.box("MagPlate", (0, -0.575, -0.293), (0.19, 0.07, 0.47), "Panel", 0.014, piece="Mag", rot=(6, 0, 0))
    w.box("MagGlow", (0, -0.39, -0.27), (0.17, 0.20, 0.04), "Accent", 0.0, piece="Mag", rot=(6, 0, 0))
    w.box("MagRelease", (0, -0.26, 0.01), (0.06, 0.10, 0.03), "Metal", 0.0, rot=(20, 0, 0))

    # ---------------------------------------------------------------- bípode plegado hacia delante
    w.box("BipodMount", (0, -0.20, -2.20), (0.23, 0.12, 0.26), "Body", 0.014)
    w.cyl("BipodHinge", (-0.13, -0.20, -2.27), (0.13, -0.20, -2.27), 0.036, "Metal", 8)
    for side in (-1, 1):
        w.box(f"BipodLeg{side}", (side * 0.085, -0.20, -2.66), (0.05, 0.05, 0.80), "Metal", 0.0)
        w.box(f"BipodFoot{side}", (side * 0.085, -0.20, -3.07), (0.066, 0.07, 0.11), "Rubber", 0.0)

    # ---------------------------------------------------------------- culata de ojal
    w.profile("StockSpine", [(0.76, 0.22), (1.06, 0.15), (1.80, 0.15), (1.80, 0.0), (0.76, -0.04)], 0.16, "Body", 0.02)
    w.box("StockStrut", (0, -0.57, 1.24), (0.13, 0.10, 1.10), "Body", 0.02, rot=(-15.4, 0, 0))
    w.profile("Butt", [(1.72, 0.25), (1.90, 0.25), (1.92, -0.52), (1.84, -0.64), (1.70, -0.62), (1.66, -0.46)], 0.19, "Dark", 0.02)
    w.box("ButtPad", (0, -0.16, 1.94), (0.20, 0.78, 0.06), "Rubber", 0.02)
    w.box("ButtStripe", (0, -0.20, 1.80), (0.20, 0.05, 0.20), "Panel", 0.0)
    w.cyl("Monopod", (0, -0.60, 1.80), (0, -0.73, 1.80), 0.03, "Metal", 8)
    w.cyl("MonopodFoot", (0, -0.73, 1.80), (0, -0.77, 1.80), 0.048, "Rubber", 8)
    w.box("StockGlow", (0, 0.075, 1.42), (0.168, 0.022, 0.46), "Accent", 0.0)
    w.box("CheekRest", (0, 0.31, 1.42), (0.18, 0.09, 0.58), "Panel", 0.018)
    for z in (1.25, 1.59):
        w.cyl(f"CheekPost{z}", (0, 0.13, z), (0, 0.28, z), 0.026, "Metal", 8)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BY, -3.78))
    w.point("AimPoint", (0, SY, 1.0))
    w.point("Eject", (0.15, 0.17, -0.25))
    w.point("RightHand", (0, -0.45, 0.62))
    w.point("LeftHand", (0, -0.2, -1.4))
    w.point("CharmPoint", (-0.13, 0.0, 0.55))
