# HAVOC PUMP · escopeta de corredera pesada de SHOOTERROB.
# Silueta: cañón gordo sobre tubo cargador, guardamanos de corredera con costillas de color, escudo
# térmico con branquias, bocacha rompepuertas con dientes, culata maciza angulosa con cartuchera y
# cartuchos rojos de culote de latón (canana lateral a la izquierda, a la vista en primera persona).
NAME = "HavocPump"

PALETTE = {
    "Body": (0.05, 0.052, 0.066),
    "Panel": (0.97, 0.27, 0.035),  # naranja de la casa, más caliente (rojo-naranja)
    "Accent": (0.15, 0.9, 1.0),  # cian luminoso
    "Accent2": (0.95, 0.68, 0.16),  # latón (culotes de los cartuchos)
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.5, 0.52, 0.58),
    "Trim": (0.78, 0.05, 0.05),  # rojo de los cartuchos
}

BARREL_Y = 0.12
TUBE_Y = -0.085


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.profile("Body", [(0.88, 0.02), (0.88, 0.22), (0.78, 0.30), (-0.47, 0.30), (-0.55, 0.24), (-0.55, 0.02)], 0.26, "Body", 0.022)
    w.profile("Lower", [(0.82, 0.04), (0.82, -0.14), (0.30, -0.20), (0.12, -0.27), (-0.47, -0.27), (-0.55, -0.20), (-0.55, 0.04)], 0.235, "Dark", 0.018)
    # Ventana de expulsión con cerrojo (derecha) y placa de acento detrás
    w.box("EjectionPort", (0.131, 0.17, -0.22), (0.012, 0.11, 0.40), "Dark", 0.0)
    w.box("Bolt", (0.134, 0.17, -0.22), (0.012, 0.072, 0.34), "Metal", 0.0, piece="Bolt")
    w.profile("SidePlate", [(0.72, 0.25), (0.26, 0.25), (0.16, 0.11), (0.72, 0.11)], 0.014, "Panel", 0.004, x=0.129)
    for side in (-1, 1):
        w.box(f"GlowStrip{side}", (side * 0.131, 0.05, 0.44), (0.008, 0.026, 0.44), "Accent", 0.0)
    for z in (0.56, -0.36):
        w.cyl(f"Pin{z}", (-0.122, -0.09, z), (0.122, -0.09, z), 0.022, "Metal", 6)
    w.box("Safety", (0.122, -0.10, 0.30), (0.016, 0.03, 0.10), "Panel", 0.0, rot=(20, 0, 0))
    w.box("LoadGate", (0, -0.272, -0.20), (0.15, 0.02, 0.42), "Metal", 0.0)

    # Canana lateral izquierda: cinco cartuchos de pie, culote arriba
    w.box("SaddleBand", (-0.165, 0.105, -0.14), (0.08, 0.085, 0.63), "Dark", 0.012)
    for i in range(5):
        z = -0.38 + i * 0.12
        w.cyl(f"SaddleShell{i}", (-0.166, 0.02, z), (-0.166, 0.205, z), 0.046, "Trim", 6)
        w.cyl(f"SaddleBrass{i}", (-0.166, 0.205, z), (-0.166, 0.262, z), 0.05, "Accent2", 6)

    # ---------------------------------------------------------------- raíl corto y mira de anillo
    w.box("Rail", (0, 0.315, -0.06), (0.11, 0.04, 0.88), "Dark", 0.008)
    for i in range(4):
        w.box(f"RailTooth{i}", (0, 0.341, 0.30 - i * 0.24), (0.125, 0.02, 0.10), "Dark", 0.0)
    w.box("SightBase", (0, 0.32, 0.72), (0.18, 0.05, 0.28), "Dark", 0.012)
    for side in (-1, 1):
        w.profile(f"SightWing{side}", [(0.85, 0.33), (0.85, 0.47), (0.79, 0.545), (0.70, 0.545), (0.60, 0.33)], 0.03, "Body", 0.006, x=side * 0.076)
    w.box("SightHood", (0, 0.53, 0.745), (0.18, 0.03, 0.10), "Panel", 0.006)
    w.profile("FrontSight", [(-1.58, 0.27), (-1.82, 0.27), (-1.82, 0.41), (-1.77, 0.41)], 0.04, "Dark", 0.006)
    w.box("FrontDot", (0, 0.385, -1.742), (0.024, 0.04, 0.022), "Accent", 0.0)

    # ---------------------------------------------------------------- cañón, tubo cargador y escudo térmico
    w.cyl("Barrel", (0, BARREL_Y, -0.50), (0, BARREL_Y, -2.12), 0.09, "Metal", 12)
    w.cyl("Tube", (0, TUBE_Y, -0.50), (0, TUBE_Y, -2.02), 0.07, "Metal", 12)
    w.cyl("TubeNut", (0, TUBE_Y, -0.53), (0, TUBE_Y, -0.62), 0.088, "Dark", 8)
    w.cyl("TubeCap", (0, TUBE_Y, -2.0), (0, TUBE_Y, -2.06), 0.082, "Panel", 8)
    w.box("Clamp", (0, 0.01, -1.95), (0.24, 0.38, 0.09), "Body", 0.022)
    w.profile("HeatShield", [(-0.53, 0.27), (-1.80, 0.27), (-1.88, 0.21), (-1.88, 0.11), (-0.53, 0.11)], 0.225, "Body", 0.02)
    for side in (-1, 1):
        for i in range(6):
            w.box(f"Vent{side}_{i}", (side * 0.113, 0.195, -0.72 - i * 0.18), (0.012, 0.115, 0.066), "Metal", 0.0, rot=(24, 0, 0))
        w.box(f"ShieldGlow{side}", (side * 0.113, 0.125, -1.20), (0.008, 0.02, 1.06), "Accent", 0.0)
    w.box("ShieldSpine", (0, 0.277, -1.08), (0.09, 0.022, 0.94), "Panel", 0.006)

    # Bocacha rompepuertas con dientes
    w.ring("Breacher", (0, BARREL_Y, -2.07), (0, BARREL_Y, -2.27), 0.125, 0.078, "Body", 10)
    w.ring("BreacherBand", (0, BARREL_Y, -2.12), (0, BARREL_Y, -2.18), 0.137, 0.12, "Panel", 10)
    w.profile("ToothTop", [(-2.26, BARREL_Y + 0.125), (-2.38, BARREL_Y + 0.125), (-2.26, BARREL_Y + 0.06)], 0.085, "Metal", 0.0)
    w.profile("ToothBottom", [(-2.26, BARREL_Y - 0.125), (-2.26, BARREL_Y - 0.06), (-2.38, BARREL_Y - 0.125)], 0.085, "Metal", 0.0)
    for side in (-1, 1):
        w.profile(f"ToothSide{side}", [(-2.26, BARREL_Y + 0.055), (-2.26, BARREL_Y - 0.055), (-2.38, BARREL_Y)], 0.055, "Metal", 0.0, x=side * 0.096)

    # ---------------------------------------------------------------- corredera (todo piece="Pump")
    w.profile("PumpBody", [(-0.90, 0.03), (-1.58, 0.03), (-1.65, -0.07), (-1.57, -0.42), (-0.99, -0.42), (-0.90, -0.30)], 0.30, "Dark", 0.026, piece="Pump")
    w.profile("PumpStop", [(-1.47, -0.40), (-1.585, -0.40), (-1.575, -0.50), (-1.52, -0.50)], 0.20, "Dark", 0.014, piece="Pump")
    for side in (-1, 1):
        for i in range(6):
            w.box(f"PumpRib{side}_{i}", (side * 0.153, -0.19, -1.01 - i * 0.11), (0.016, 0.28, 0.06), "Panel", 0.0, piece="Pump", rot=(-14, 0, 0))
        w.box(f"PumpGlow{side}", (side * 0.153, -0.008, -1.26), (0.008, 0.018, 0.60), "Accent", 0.0, piece="Pump")
        w.box(f"ActionBar{side}", (side * 0.088, TUBE_Y, -0.74), (0.02, 0.05, 0.36), "Metal", 0.0, piece="Pump")

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.profile("Grip", [(0.35, -0.15), (0.64, -0.15), (0.79, -0.80), (0.52, -0.83)], 0.175, "Rubber", 0.028)
    w.profile("GripInlay", [(0.44, -0.28), (0.60, -0.28), (0.70, -0.70), (0.55, -0.72)], 0.19, "Panel", 0.0)
    w.box("TriggerGuard", (0, -0.40, 0.165), (0.045, 0.026, 0.52), "Dark", 0.006)
    w.box("TriggerGuardFront", (0, -0.33, -0.08), (0.045, 0.15, 0.03), "Dark", 0.006)
    w.box("Trigger", (0, -0.29, 0.20), (0.03, 0.14, 0.035), "Metal", 0.006, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- culata maciza con cartuchera
    w.profile("Stock", [(0.84, 0.24), (1.02, 0.13), (1.62, 0.15), (1.70, 0.10), (1.70, -0.42), (1.58, -0.48), (1.40, -0.40), (0.84, -0.02)], 0.20, "Body", 0.022)
    w.profile("StockPlate", [(1.04, -0.05), (1.62, -0.05), (1.62, -0.38), (1.44, -0.36), (1.04, -0.10)], 0.214, "Panel", 0.004)
    w.box("ButtPad", (0, -0.17, 1.725), (0.21, 0.60, 0.06), "Rubber", 0.02)
    w.box("CheekRest", (0, 0.165, 1.32), (0.17, 0.04, 0.46), "Panel", 0.012)  # (baja: por encima tapaba la mira al apuntar)
    w.box("StockGlow", (-0.102, 0.04, 1.30), (0.008, 0.022, 0.46), "Accent", 0.0)
    w.box("ShellBand", (0.125, 0.09, 1.28), (0.075, 0.085, 0.50), "Dark", 0.012)
    for i in range(4):
        z = 1.10 + i * 0.12
        w.cyl(f"StockShell{i}", (0.127, -0.13, z), (0.127, 0.055, z), 0.046, "Trim", 6)
        w.cyl(f"StockBrass{i}", (0.127, 0.055, z), (0.127, 0.112, z), 0.05, "Accent2", 6)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BARREL_Y, -2.38))
    w.point("AimPoint", (0, 0.43, 0.75))
    w.point("Eject", (0.15, 0.17, -0.22))
    w.point("RightHand", (0, -0.48, 0.55))
    w.point("LeftHand", (0, -0.38, -1.15))
    w.point("CharmPoint", (-0.13, -0.05, 0.55))
