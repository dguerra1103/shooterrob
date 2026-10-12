# TITAN GRIND · ametralladora pesada de SHOOTERROB (diseño original).
# Silueta: cañón pesado dentro de una camisa de costillas inclinadas (se ve el acero entre ellas), morro
# naranja con freno de boca cuadrado, tapa de alimentación naranja con bisagra, caja de munición colgada
# y desplazada a la izquierda con la cinta de cartuchos subiendo a la bandeja, asa de transporte baja,
# bípode plegado a los lados, culata maciza con apoyo de hombro abatible y visor de marco grande.
NAME = "TitanLMG"

PALETTE = {
    "Body": (0.045, 0.052, 0.07),
    "Panel": (0.98, 0.33, 0.03),  # naranja de la casa, un punto más rojo (más "pesado")
    "Accent": (0.15, 0.9, 1.0),
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.5, 0.52, 0.58),
    "Trim": (0.95, 0.62, 0.14),  # latón de los cartuchos
}

BY = 0.08  # altura del eje del cañón


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.box("Receiver", (0, 0.09, 0.04), (0.30, 0.50, 1.68), "Body", 0.026)
    w.box("LowerHousing", (0, -0.22, 0.42), (0.24, 0.17, 0.92), "Dark", 0.02)
    w.box("ReceiverBelly", (0, -0.165, -0.38), (0.25, 0.05, 0.80), "Dark", 0.0)
    # Tapa de alimentación (naranja) con bisagra delante y pestillo detrás
    w.profile("FeedCover", [(0.14, 0.33), (0.14, 0.46), (-0.60, 0.46), (-0.78, 0.38), (-0.78, 0.33)], 0.31, "Panel", 0.02)
    w.box("CoverInset", (0, 0.462, -0.24), (0.17, 0.014, 0.52), "Dark", 0.0)
    w.box("CoverGlow", (0, 0.468, -0.24), (0.03, 0.01, 0.40), "Accent", 0.0)
    w.cyl("CoverHinge", (-0.17, 0.365, -0.80), (0.17, 0.365, -0.80), 0.04, "Metal", 8)
    for i in range(3):
        w.box(f"CoverSlot{i}", (0, 0.40, -0.16 - i * 0.16), (0.316, 0.035, 0.09), "Dark", 0.0)
    w.box("CoverLatch", (0, 0.42, 0.17), (0.12, 0.07, 0.07), "Metal", 0.01)
    w.box("FeedTray", (-0.165, 0.30, -0.31), (0.07, 0.035, 0.36), "Metal", 0.0)
    # Lado derecho: ventana de expulsión, corredera de la palanca de montar
    w.box("EjectionPort", (0.151, 0.10, -0.35), (0.012, 0.13, 0.32), "Dark", 0.0)
    w.box("ChargeSlot", (0.151, 0.24, 0.20), (0.012, 0.035, 0.78), "Dark", 0.0)
    w.box("ChargingHandle", (0.185, 0.24, 0.42), (0.07, 0.06, 0.09), "Metal", 0.012, piece="Charge")
    for side in (-1, 1):
        w.profile(f"SidePlate{side}", [(0.76, 0.17), (0.36, 0.17), (0.24, 0.03), (0.64, 0.03)], 0.012, "Panel", 0.0, x=side * 0.152)
        w.box(f"GlowStrip{side}", (side * 0.153, -0.04, 0.42), (0.008, 0.026, 0.60), "Accent", 0.0)
    w.cyl("Pin", (-0.158, -0.09, 0.78), (0.158, -0.09, 0.78), 0.026, "Metal", 6)
    # Bloque del muñón (delante, más ancho) con sus dos tornillos pasantes
    w.box("Trunnion", (0, 0.08, -0.73), (0.33, 0.50, 0.20), "Body", 0.024)
    for y in (0.22, -0.06):
        w.cyl(f"TrunnionBolt{y}", (-0.172, y, -0.73), (0.172, y, -0.73), 0.03, "Metal", 6)

    # ---------------------------------------------------------------- cañón pesado y camisa de costillas
    w.cyl("Barrel", (0, BY, -0.80), (0, BY, -2.10), 0.08, "Metal", 10)
    for i in range(6):
        z = -0.93 - i * 0.13
        w.box(f"Rib{i}", (0, BY, z), (0.275, 0.41, 0.068), "Body", 0.012, rot=(18, 0, 0))
    w.box("ShroudTop", (0, 0.255, -1.26), (0.23, 0.10, 0.96), "Body", 0.02)
    w.box("ShroudBottom", (0, -0.105, -1.26), (0.24, 0.10, 0.96), "Dark", 0.02)
    w.profile("Nose", [(-1.64, 0.31), (-1.78, 0.31), (-1.90, 0.18), (-1.90, 0.0), (-1.80, -0.15), (-1.64, -0.15)], 0.29, "Panel", 0.022)
    for side in (-1, 1):
        w.box(f"NoseGlow{side}", (side * 0.147, BY, -1.75), (0.008, 0.026, 0.18), "Accent", 0.0)
    w.box("FrontSightBase", (0, 0.32, -1.74), (0.14, 0.04, 0.14), "Dark", 0.0)
    w.box("FrontSightPost", (0, 0.39, -1.74), (0.035, 0.12, 0.05), "Dark", 0.0)
    w.cyl("BarrelCollar", (0, BY, -1.88), (0, BY, -1.97), 0.105, "Dark", 8)
    # Freno de boca cuadrado con collar naranja y dos lumbreras de acero
    w.box("Brake", (0, BY, -2.18), (0.24, 0.24, 0.32), "Dark", 0.034)
    w.box("BrakeCollar", (0, BY, -2.045), (0.262, 0.262, 0.05), "Panel", 0.008)
    for i, z in enumerate((-2.15, -2.25)):
        w.box(f"BrakePort{i}", (0, BY, z), (0.256, 0.07, 0.05), "Metal", 0.0)
    w.ring("Bore", (0, BY, -2.30), (0, BY, -2.36), 0.085, 0.048, "Metal", 8)

    # ---------------------------------------------------------------- asa de transporte (baja: no tapa la mira)
    w.box("HandleStrutR", (0, 0.36, -0.93), (0.05, 0.20, 0.05), "Dark", 0.0, rot=(-20, 0, 0))
    w.box("HandleStrutF", (0, 0.36, -1.39), (0.05, 0.20, 0.05), "Dark", 0.0, rot=(20, 0, 0))
    w.cyl("HandleBar", (0, 0.45, -0.90), (0, 0.45, -1.42), 0.04, "Rubber", 8)
    w.cyl("HandleBand", (0, 0.45, -1.10), (0, 0.45, -1.22), 0.046, "Panel", 8)

    # ---------------------------------------------------------------- bípode plegado a los lados
    w.cyl("BipodHinge", (-0.18, -0.125, -1.74), (0.18, -0.125, -1.74), 0.036, "Metal", 8)
    for side in (-1, 1):
        w.box(f"BipodLeg{side}", (side * 0.156, -0.13, -1.39), (0.05, 0.075, 0.72), "Metal", 0.012)
        w.box(f"BipodFoot{side}", (side * 0.158, -0.13, -1.01), (0.066, 0.11, 0.13), "Rubber", 0.014)

    # ---------------------------------------------------------------- empuñadura delantera
    w.profile("Foregrip", [(-1.14, -0.12), (-1.46, -0.12), (-1.42, -0.56), (-1.34, -0.66), (-1.20, -0.62)], 0.16, "Rubber", 0.024)
    w.box("ForegripInlay", (0, -0.38, -1.30), (0.174, 0.26, 0.10), "Panel", 0.0, rot=(4, 0, 0))

    # ---------------------------------------------------------------- visor de marco grande
    w.box("SightRail", (0, 0.36, 0.50), (0.13, 0.05, 0.66), "Dark", 0.0)
    w.box("SightBase", (0, 0.43, 0.41), (0.25, 0.09, 0.40), "Dark", 0.016)
    for side in (-1, 1):
        w.profile(f"SightWall{side}", [(0.56, 0.46), (0.56, 0.78), (0.32, 0.78), (0.22, 0.46)], 0.03, "Body", 0.008, x=side * 0.11)
    w.box("SightHood", (0, 0.785, 0.44), (0.26, 0.035, 0.28), "Panel", 0.008)
    w.box("SightLens", (0, 0.62, 0.40), (0.19, 0.28, 0.016), "Lens", 0.0)
    w.box("Reticle", (0, 0.62, 0.388), (0.024, 0.024, 0.006), "Reticle", 0.0)
    w.box("SightKnob", (0.14, 0.50, 0.46), (0.04, 0.06, 0.09), "Metal", 0.008)

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.profile("Grip", [(0.42, -0.26), (0.74, -0.26), (0.91, -0.86), (0.62, -0.90)], 0.18, "Rubber", 0.028)
    w.box("GripInlay", (0, -0.58, 0.675), (0.194, 0.40, 0.12), "Panel", 0.0, rot=(-17, 0, 0))
    w.box("TriggerGuard", (0, -0.50, 0.28), (0.05, 0.03, 0.48), "Dark", 0.0)
    w.box("TriggerGuardFront", (0, -0.40, 0.055), (0.05, 0.22, 0.03), "Dark", 0.0)
    w.box("Trigger", (0, -0.38, 0.32), (0.03, 0.15, 0.04), "Metal", 0.0, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- caja de munición y cinta (pieza Mag)
    w.profile("AmmoBox", [(-0.04, -0.16), (-0.74, -0.16), (-0.74, -0.68), (-0.62, -0.83), (-0.16, -0.83), (-0.04, -0.68)], 0.44, "Body", 0.028, piece="Mag", x=-0.08)
    w.profile("AmmoBand", [(-0.10, -0.34), (-0.56, -0.34), (-0.68, -0.48), (-0.68, -0.60), (-0.10, -0.60)], 0.452, "Panel", 0.0, piece="Mag", x=-0.08)
    w.box("AmmoGlow", (-0.08, -0.52, -0.36), (0.458, 0.03, 0.34), "Accent", 0.0, piece="Mag")
    w.box("AmmoLid", (-0.235, -0.14, -0.39), (0.15, 0.05, 0.62), "Metal", 0.008, piece="Mag")
    w.box("AmmoLatch", (0.145, -0.24, -0.39), (0.02, 0.10, 0.16), "Metal", 0.006, piece="Mag")
    w.box("AmmoRib", (-0.08, -0.70, -0.39), (0.456, 0.035, 0.50), "Metal", 0.0, piece="Mag")
    w.box("BeltBacking", (-0.20, 0.09, -0.31), (0.05, 0.44, 0.16), "Metal", 0.0, piece="Mag")
    belt = [(-0.185, 0.295), (-0.228, 0.245), (-0.25, 0.185), (-0.255, 0.12), (-0.255, 0.055), (-0.255, -0.01), (-0.255, -0.075)]
    for i, (x, y) in enumerate(belt):
        w.cyl(f"Round{i}", (x, y, -0.20), (x, y, -0.40), 0.032, "Trim", 6, piece="Mag")
        w.cyl(f"Tip{i}", (x, y, -0.40), (x, y, -0.47), 0.02, "Metal", 6, piece="Mag")

    # ---------------------------------------------------------------- culata maciza con apoyo de hombro
    w.profile("Stock", [(0.84, 0.30), (1.62, 0.30), (1.74, 0.22), (1.74, -0.40), (1.60, -0.48), (1.44, -0.22), (0.84, -0.10)], 0.22, "Body", 0.024)
    w.box("CheekRest", (0, 0.305, 1.20), (0.20, 0.05, 0.50), "Rubber", 0.014)
    for side in (-1, 1):
        w.box(f"StockInset{side}", (side * 0.112, 0.08, 1.24), (0.01, 0.20, 0.56), "Dark", 0.0)
        w.box(f"StockGlow{side}", (side * 0.115, 0.08, 1.24), (0.008, 0.024, 0.44), "Accent", 0.0)
    w.box("ButtPad", (0, -0.10, 1.77), (0.23, 0.70, 0.07), "Rubber", 0.022)
    w.cyl("RestHinge", (-0.115, 0.30, 1.60), (0.115, 0.30, 1.60), 0.04, "Metal", 6)
    w.profile("ShoulderRest", [(1.56, 0.29), (1.76, 0.29), (1.86, 0.43), (1.78, 0.46)], 0.17, "Metal", 0.012)
    w.cyl("StockBolt", (-0.115, -0.12, 1.50), (0.115, -0.12, 1.50), 0.035, "Metal", 6)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, BY, -2.36))
    w.point("AimPoint", (0, 0.62, 0.40))
    w.point("Eject", (0.16, 0.10, -0.35))
    w.point("RightHand", (0, -0.52, 0.62))
    w.point("LeftHand", (0, -0.45, -1.30))
    w.point("CharmPoint", (-0.155, 0.02, 0.70))
