# NOVA DRIFT · subfusil bullpup ultraligero (el SMG ágil de SHOOTERROB).
# Silueta: cuña deportiva. Cargador DETRÁS de la empuñadura, morro plano en bisel con el cañón
# encerrado, empuñadura delantera inclinada que nace del propio cuerpo y se une a la trasera con un
# arco guardamanos, puente bajo tipo asa con visor de barra y culatín corto de dos varillas.
# Color: verde azulado con brillo verde lima, para distinguirse del Specter-9 naranja. Diseño original.
NAME = "NovaDrift"

PALETTE = {
    "Body": (0.045, 0.052, 0.066),
    "Panel": (0.021, 0.578, 0.305),  # sRGB 40,200,150
    "Accent": (0.70, 1.0, 0.12),  # verde lima luminoso
    "Dark": (0.015, 0.017, 0.022),
    "Metal": (0.5, 0.53, 0.58),
    "Rubber": (0.026, 0.03, 0.035),
    "Lens": (0.12, 0.75, 0.6),
    "Reticle": (1.0, 0.95, 0.2),
    "Trim": (0.75, 0.82, 0.78),  # blanco hueso
}


def build(w):
    # ---------------------------------------------------------------- cuerpo (cajón bullpup)
    w.profile("Body", [(1.04, -0.16), (1.04, 0.12), (0.96, 0.20), (-0.62, 0.20), (-0.62, -0.16)], 0.25, "Body", 0.022)
    w.box("Lower", (0, -0.17, 0.21), (0.225, 0.06, 1.62), "Dark", 0.012)
    w.box("Brow", (0, 0.182, 0.17), (0.262, 0.04, 1.50), "Dark", 0.0)
    w.box("RearCap", (0, 0.0, 1.045), (0.21, 0.24, 0.04), "Dark", 0.01)
    # Placa de color trasera (atraviesa el cuerpo: se ve por los dos lados) y tira luminosa
    w.profile("SidePlate", [(0.99, 0.13), (0.60, 0.13), (0.48, -0.03), (0.99, -0.03)], 0.264, "Panel", 0.0)
    w.box("PlateSlot", (0, 0.05, 0.86), (0.27, 0.03, 0.18), "Dark", 0.0)
    w.box("GlowStrip", (0, -0.095, 0.10), (0.258, 0.022, 0.86), "Accent", 0.0)
    w.box("TickA", (0, 0.07, 0.36), (0.258, 0.07, 0.03), "Trim", 0.0, rot=(-28, 0, 0))
    w.box("TickB", (0, 0.07, 0.29), (0.258, 0.07, 0.03), "Trim", 0.0, rot=(-28, 0, 0))
    # Lado izquierdo: ranura y tirador de carga. Lado derecho: ventana de expulsión (atrás, bullpup)
    # Tirador de carga en T sobre el cajón, bajo el puente; branquias en los costados
    w.box("ChargeSlot", (0, 0.203, 0.14), (0.06, 0.012, 0.66), "Dark", 0.0)
    w.box("ChargeKnob", (0, 0.235, -0.12), (0.19, 0.05, 0.07), "Metal", 0.01, piece="Charge")
    for i, z in enumerate((-0.16, -0.27, -0.38)):
        w.box(f"Gill{i}", (0, 0.065, z), (0.258, 0.12, 0.04), "Dark", 0.0, rot=(-28, 0, 0))
    w.box("BeltLine", (0, -0.168, -0.2), (0.232, 0.018, 0.5), "Panel", 0.0)
    w.box("EjectionPort", (0.133, 0.05, 0.80), (0.012, 0.12, 0.30), "Dark", 0.0)
    w.box("Bolt", (0.137, 0.05, 0.80), (0.012, 0.075, 0.24), "Metal", 0.0, piece="Bolt")
    for z in (0.52, -0.50):
        w.cyl(f"Pin{z}", (-0.128, -0.10, z), (0.128, -0.10, z), 0.022, "Metal", 8)
    w.box("Selector", (-0.128, -0.02, 0.20), (0.016, 0.03, 0.10), "Panel", 0.0, rot=(25, 0, 0))

    # ---------------------------------------------------------------- morro en bisel y boca
    w.profile("Nose", [(-0.58, 0.22), (-1.42, 0.17), (-1.55, 0.08), (-1.47, -0.17), (-0.58, -0.17)], 0.27, "Panel", 0.024)
    w.profile("NoseCut", [(-0.66, 0.09), (-1.28, 0.09), (-1.40, 0.01), (-1.28, -0.07), (-0.66, -0.07)], 0.282, "Dark", 0.0)
    w.box("NoseGlow", (0, 0.01, -1.0), (0.29, 0.022, 0.58), "Accent", 0.0)
    for i, z in enumerate((-0.74, -0.81)):
        w.box(f"NoseTick{i}", (0, 0.01, z), (0.29, 0.11, 0.028), "Trim", 0.0, rot=(-28, 0, 0))
    w.box("NoseSpine", (0, 0.20, -1.0), (0.11, 0.035, 0.80), "Dark", 0.0, rot=(-3.4, 0, 0))
    w.profile("FrontFin", [(-1.20, 0.19), (-1.40, 0.17), (-1.34, 0.27), (-1.26, 0.27)], 0.045, "Dark", 0.0)
    w.cyl("MuzzleCollar", (0, 0, -1.40), (0, 0, -1.535), 0.10, "Dark", 8)
    w.ring("MuzzleRing", (0, 0, -1.48), (0, 0, -1.57), 0.07, 0.038, "Metal", 10)
    w.box("NoseBezel", (0, -0.03, -1.495), (0.20, 0.21, 0.03), "Dark", 0.0, rot=(17.7, 0, 0))
    w.profile("Chin", [(-0.95, -0.15), (-1.46, -0.15), (-1.36, -0.25), (-1.00, -0.25)], 0.18, "Dark", 0.012)

    # ---------------------------------------------------------------- puente bajo y visor de barra
    w.profile("BridgeRear", [(0.98, 0.18), (0.98, 0.38), (0.92, 0.44), (0.78, 0.44), (0.74, 0.18)], 0.13, "Body", 0.012)
    w.box("BridgeBar", (0, 0.405, 0.32), (0.13, 0.07, 1.00), "Body", 0.012)
    w.profile("BridgeFront", [(-0.14, 0.44), (-0.24, 0.44), (-0.56, 0.18), (-0.40, 0.18)], 0.13, "Body", 0.012)
    w.box("BridgeGlow", (0, 0.40, 0.02), (0.138, 0.02, 0.34), "Accent", 0.0)
    w.box("BridgeStripe", (0, 0.443, 0.02), (0.07, 0.012, 0.38), "Panel", 0.0)
    w.box("SightBase", (0, 0.455, 0.47), (0.20, 0.035, 0.22), "Dark", 0.008)
    for side in (-1, 1):
        w.profile(f"SightWall{side}", [(0.57, 0.47), (0.51, 0.665), (0.41, 0.665), (0.28, 0.47)], 0.026, "Body", 0.0, x=side * 0.088)
    w.box("BridgeTail", (0, 0.443, 0.86), (0.07, 0.012, 0.12), "Panel", 0.0)
    w.box("SightBar", (0, 0.672, 0.46), (0.21, 0.03, 0.12), "Panel", 0.008)
    w.box("SightLens", (0, 0.56, 0.45), (0.152, 0.19, 0.014), "Lens", 0.0)
    w.box("Reticle", (0, 0.56, 0.44), (0.022, 0.022, 0.006), "Reticle", 0.0)

    # ---------------------------------------------------------------- empuñadura, gatillo, arco
    w.profile("Grip", [(0.10, -0.19), (0.38, -0.19), (0.55, -0.78), (0.31, -0.81)], 0.175, "Rubber", 0.028)
    w.profile("GripInlay", [(0.20, -0.31), (0.34, -0.31), (0.46, -0.68), (0.34, -0.70)], 0.19, "Panel", 0.0)
    w.profile("Beavertail", [(0.36, -0.19), (0.58, -0.19), (0.42, -0.36)], 0.16, "Dark", 0.012)
    w.profile("TriggerHousing", [(0.14, -0.19), (-0.24, -0.19), (-0.14, -0.26), (0.12, -0.26)], 0.13, "Dark", 0.0)
    w.box("ForegripEdge", (0, -0.35, -0.992), (0.166, 0.36, 0.02), "Trim", 0.0, rot=(13.4, 0, 0))
    w.box("Trigger", (0, -0.285, 0.04), (0.03, 0.14, 0.035), "Metal", 0.006, rot=(-18, 0, 0))
    w.box("GuardBow", (0, -0.47, -0.29), (0.075, 0.065, 1.0), "Body", 0.014, rot=(-5.8, 0, 0))
    w.box("BowGlow", (0, -0.47, -0.29), (0.081, 0.018, 0.5), "Accent", 0.0, rot=(-5.8, 0, 0))
    # Empuñadura delantera inclinada, parte del cuerpo
    w.profile("Foregrip", [(-0.58, -0.14), (-0.94, -0.14), (-1.04, -0.56), (-0.96, -0.63), (-0.78, -0.63)], 0.16, "Body", 0.022)
    w.profile("ForegripInlay", [(-0.70, -0.24), (-0.88, -0.24), (-0.96, -0.54), (-0.82, -0.56)], 0.174, "Panel", 0.0)

    # ---------------------------------------------------------------- cargador tras la empuñadura
    w.profile("Magwell", [(0.62, -0.19), (1.03, -0.19), (1.03, -0.36), (0.66, -0.36)], 0.235, "Body", 0.014)
    w.box("MagwellLip", (0, -0.355, 0.845), (0.25, 0.04, 0.40), "Dark", 0.0)
    w.profile("Mag", [(0.67, -0.24), (0.98, -0.24), (1.08, -0.84), (0.78, -0.87)], 0.16, "Dark", 0.02, piece="Mag")
    w.profile("MagPlate", [(0.74, -0.82), (1.11, -0.78), (1.13, -0.86), (1.07, -0.94), (0.76, -0.96)], 0.19, "Panel", 0.012, piece="Mag")
    w.box("MagGlow", (0, -0.55, 0.875), (0.168, 0.34, 0.045), "Accent", 0.0, piece="Mag", rot=(-9.5, 0, 0))
    w.box("MagRelease", (0.122, -0.27, 0.70), (0.02, 0.05, 0.07), "Metal", 0.0)

    # ---------------------------------------------------------------- culatín de varillas
    for side in (-1, 1):
        w.cyl(f"StockRod{side}", (side * 0.075, 0.04, 1.0), (side * 0.075, 0.04, 1.28), 0.028, "Metal", 8)
    w.box("StockCollar", (0, 0.04, 1.09), (0.22, 0.085, 0.06), "Panel", 0.0)
    w.profile("StockButt", [(1.25, 0.22), (1.33, 0.22), (1.35, -0.24), (1.29, -0.31), (1.23, -0.22)], 0.21, "Dark", 0.02)
    w.box("ButtGlow", (0, -0.02, 1.28), (0.216, 0.24, 0.02), "Accent", 0.0)
    w.box("ButtPad", (0, -0.01, 1.36), (0.20, 0.44, 0.04), "Rubber", 0.014)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0, -1.57))
    w.point("AimPoint", (0, 0.56, 0.45))
    w.point("Eject", (0.16, 0.05, 0.80))
    w.point("RightHand", (0, -0.45, 0.32))
    w.point("LeftHand", (0, -0.36, -0.85))
    w.point("CharmPoint", (-0.13, -0.08, 0.62))
