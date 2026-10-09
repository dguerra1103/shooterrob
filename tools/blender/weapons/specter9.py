# SPECTER-9 · subfusil compacto de cadencia alta (familia PULSE de SHOOTERROB).
# Silueta: cajón corto y alto, camisa de cañón con morro de tiburón y branquias inclinadas hacia la
# boca, compensador grueso, cargador recto y largo por delante de la empuñadura, empuñadura delantera
# vertical, culata de varillas y visor réflex bajo. Diseño original.
NAME = "Specter9"

PALETTE = {
    "Body": (0.05, 0.055, 0.068),
    "Panel": (1.0, 0.31, 0.035),  # naranja de la casa, un punto más rojo
    "Accent": (0.1, 0.95, 0.92),  # cian luminoso, un punto más verde
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.5, 0.52, 0.58),
    "Trim": (1.0, 0.31, 0.035),
}


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.profile("Body", [(0.66, -0.10), (0.66, 0.10), (0.52, 0.24), (-0.60, 0.24), (-0.60, -0.10)], 0.25, "Body", 0.022)
    w.box("Lower", (0, -0.15, 0.02), (0.225, 0.13, 1.24), "Dark", 0.018)
    w.profile("Magwell", [(-0.06, -0.19), (-0.09, -0.42), (-0.45, -0.42), (-0.50, -0.19)], 0.235, "Body", 0.014)
    w.box("MagwellLip", (0, -0.405, -0.27), (0.25, 0.045, 0.40), "Dark", 0.01)
    w.box("Brow", (0, 0.215, -0.045), (0.262, 0.05, 1.09), "Dark", 0.0)
    w.box("RearCap", (0, 0.03, 0.665), (0.21, 0.22, 0.05), "Dark", 0.012)
    # Lado izquierdo (el que ve el jugador): placa de acento, testigo y tirador de carga en su ranura
    w.profile("SidePlate", [(0.54, 0.17), (0.10, 0.17), (-0.02, 0.01), (0.54, 0.01)], 0.014, "Panel", 0.004, x=-0.127)
    w.box("PlateSlot", (-0.132, 0.09, 0.38), (0.008, 0.035, 0.2), "Dark", 0.0)
    w.box("ChargeSlot", (-0.127, 0.115, -0.30), (0.012, 0.04, 0.46), "Dark", 0.0)
    w.box("ChargeKnob", (-0.15, 0.115, -0.46), (0.06, 0.055, 0.075), "Metal", 0.01, piece="Charge")
    # Lado derecho: ventana de expulsión con cerrojo y placa corta
    w.box("EjectionPort", (0.126, 0.10, -0.25), (0.012, 0.115, 0.32), "Dark", 0.0)
    w.box("Bolt", (0.129, 0.10, -0.25), (0.012, 0.075, 0.26), "Metal", 0.0, piece="Bolt")
    w.profile("SidePlateR", [(0.54, 0.17), (0.20, 0.17), (0.10, 0.04), (0.54, 0.04)], 0.014, "Panel", 0.004, x=0.127)
    for side in (-1, 1):
        w.box(f"GlowStrip{side}", (side * 0.129, -0.045, 0.26), (0.008, 0.024, 0.52), "Accent", 0.0)
    for z in (0.50, -0.54):
        w.cyl(f"Pin{z}", (-0.118, -0.14, z), (0.118, -0.14, z), 0.022, "Metal", 8)
    w.box("Selector", (-0.12, -0.13, 0.20), (0.016, 0.03, 0.10), "Panel", 0.004, rot=(25, 0, 0))
    w.box("MagRelease", (0.118, -0.16, 0.02), (0.02, 0.05, 0.07), "Metal", 0.006)

    # ---------------------------------------------------------------- camisa del cañón y compensador
    w.profile("Shroud", [(-0.58, 0.255), (-1.16, 0.255), (-1.31, 0.13), (-1.31, -0.05), (-1.20, -0.17), (-0.58, -0.17)], 0.27, "Panel", 0.024)
    w.profile("ShroudCore", [(-0.64, 0.17), (-1.15, 0.17), (-1.24, -0.09), (-0.64, -0.09)], 0.282, "Dark", 0.0)
    for side in (-1, 1):
        for i, z in enumerate((-0.78, -0.93, -1.08)):
            w.box(f"Vent{side}_{i}", (side * 0.138, 0.045, z), (0.014, 0.19, 0.06), "Trim", 0.0, rot=(-24, 0, 0))
        w.box(f"ShroudGlow{side}", (side * 0.137, -0.125, -0.90), (0.008, 0.022, 0.52), "Accent", 0.0)
    w.box("NoseBlock", (0, 0.035, -1.305), (0.19, 0.19, 0.05), "Dark", 0.012)
    w.cyl("Barrel", (0, 0, -1.28), (0, 0, -1.40), 0.05, "Metal", 12)
    w.ring("Compensator", (0, 0, -1.33), (0, 0, -1.50), 0.12, 0.05, "Dark", 8)
    w.ring("CompBand", (0, 0, -1.395), (0, 0, -1.445), 0.132, 0.115, "Panel", 8)
    w.ring("CompCrown", (0, 0, -1.485), (0, 0, -1.52), 0.105, 0.05, "Metal", 8)

    # ---------------------------------------------------------------- raíl y visor réflex
    w.box("Rail", (0, 0.265, -0.475), (0.115, 0.05, 1.39), "Dark", 0.01)
    for i in range(4):
        w.box(f"RailTooth{i}", (0, 0.297, -0.05 - i * 0.26), (0.13, 0.024, 0.11), "Dark", 0.0)
    w.profile("Riser", [(0.62, 0.22), (0.62, 0.32), (0.54, 0.37), (0.30, 0.37), (0.18, 0.22)], 0.19, "Body", 0.014)
    w.box("SightBase", (0, 0.395, 0.445), (0.205, 0.05, 0.29), "Dark", 0.008)
    for side in (-1, 1):
        w.profile(f"SightWall{side}", [(0.58, 0.41), (0.58, 0.655), (0.45, 0.655), (0.32, 0.41)], 0.026, "Body", 0.008, x=side * 0.09)
        w.box(f"RiserGlow{side}", (side * 0.097, 0.295, 0.42), (0.008, 0.02, 0.22), "Accent", 0.0)
    w.box("SightHood", (0, 0.662, 0.51), (0.21, 0.03, 0.17), "Panel", 0.008)
    w.box("SightLens", (0, 0.53, 0.45), (0.16, 0.24, 0.016), "Lens", 0.0)
    w.box("Reticle", (0, 0.53, 0.438), (0.022, 0.022, 0.006), "Reticle", 0.0)
    w.box("SightKnob", (0.115, 0.47, 0.52), (0.035, 0.05, 0.07), "Metal", 0.008)
    w.box("FrontSight", (0, 0.335, -1.08), (0.05, 0.10, 0.06), "Dark", 0.01)

    # ---------------------------------------------------------------- empuñadura, gatillo, cargador
    w.profile("Grip", [(0.10, -0.19), (0.38, -0.19), (0.55, -0.80), (0.31, -0.83)], 0.175, "Rubber", 0.028)
    w.profile("GripInlay", [(0.20, -0.31), (0.34, -0.31), (0.46, -0.70), (0.34, -0.72)], 0.19, "Panel", 0.0)
    w.profile("Beavertail", [(0.36, -0.20), (0.57, -0.20), (0.42, -0.36)], 0.16, "Dark", 0.012)
    w.box("TriggerGuard", (0, -0.395, 0.035), (0.045, 0.026, 0.30), "Dark", 0.006)
    w.box("Trigger", (0, -0.285, 0.05), (0.03, 0.14, 0.035), "Metal", 0.006, rot=(-18, 0, 0))
    w.profile("Mag", [(-0.13, -0.24), (-0.40, -0.24), (-0.48, -0.99), (-0.21, -0.99)], 0.155, "Dark", 0.02, piece="Mag")
    w.profile("MagPlate", [(-0.19, -0.94), (-0.18, -1.02), (-0.24, -1.07), (-0.50, -1.07), (-0.52, -0.94)], 0.185, "Panel", 0.012, piece="Mag")
    for side in (-1, 1):
        w.box(f"MagGlow{side}", (side * 0.08, -0.66, -0.31), (0.008, 0.36, 0.04), "Accent", 0.0, piece="Mag", rot=(6, 0, 0))

    # ---------------------------------------------------------------- empuñadura delantera vertical
    w.profile("Foregrip", [(-0.53, -0.15), (-0.80, -0.15), (-0.86, -0.50), (-0.80, -0.56), (-0.66, -0.56)], 0.15, "Dark", 0.022)
    w.profile("ShroudChin", [(-0.90, -0.15), (-1.20, -0.15), (-1.13, -0.235), (-0.96, -0.235)], 0.17, "Dark", 0.014)
    w.profile("ForegripInlay", [(-0.61, -0.23), (-0.76, -0.23), (-0.80, -0.47), (-0.70, -0.49)], 0.164, "Panel", 0.0)

    # ---------------------------------------------------------------- culata de varillas
    for side in (-1, 1):
        w.cyl(f"StockRod{side}", (side * 0.085, 0.13, 0.60), (side * 0.085, 0.13, 1.14), 0.03, "Metal", 8)
    w.box("StockStrut", (0, -0.17, 0.86), (0.12, 0.07, 0.56), "Body", 0.016, rot=(14, 0, 0))
    w.profile("StockButt", [(1.08, 0.22), (1.21, 0.22), (1.24, -0.30), (1.14, -0.36), (1.06, -0.28)], 0.22, "Dark", 0.022)
    w.box("ButtPad", (0, -0.05, 1.255), (0.21, 0.56, 0.05), "Rubber", 0.018)
    for side in (-1, 1):
        w.box(f"ButtGlow{side}", (side * 0.112, -0.04, 1.15), (0.008, 0.26, 0.022), "Accent", 0.0)
    w.box("StockCollar", (0, 0.13, 0.725), (0.23, 0.085, 0.08), "Panel", 0.012)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0, -1.52))
    w.point("AimPoint", (0, 0.53, 0.45))
    w.point("Eject", (0.15, 0.10, -0.25))
    w.point("RightHand", (0, -0.45, 0.32))
    w.point("LeftHand", (0, -0.26, -0.65))
    w.point("CharmPoint", (-0.13, -0.08, 0.56))
