# VORTEX AR-9 · fusil de energía de ráfagas (el arma de ciencia ficción de SHOOTERROB).
# Silueta: boca partida en dos púas (raíles) con el núcleo de energía y sus bobinas a la vista entre
# ellas, blindaje claro de cortes angulosos, célula de energía luminosa enjaulada en lugar de cargador,
# reactor circular sobre la empuñadura, culata integrada de ojo de pulgar y visor holográfico con visera.
NAME = "VortexBR"

PALETTE = {
    "Body": (0.045, 0.05, 0.066),
    "Panel": (0.70, 0.75, 0.82),  # blindaje gris hielo
    "Accent": (0.10, 0.04, 0.27),  # energía violeta
    "Dark": (0.016, 0.017, 0.024),
    "Metal": (0.5, 0.53, 0.6),
    "Lens": (0.25, 0.6, 1.0),
    "Reticle": (0.3, 1.0, 0.9),
    "Trim": (0.70, 0.75, 0.82),
}

CORE_Y = 0.06  # eje del núcleo (altura de la boca)


def build(w):
    # ---------------------------------------------------------------- cajón de mecanismos
    w.profile("Body", [(0.76, 0.0), (0.76, 0.22), (0.64, 0.33), (-0.80, 0.33), (-0.80, 0.0)], 0.26, "Body", 0.022)
    w.box("Lower", (0, -0.085, -0.04), (0.225, 0.21, 1.52), "Dark", 0.016)
    w.profile("CellWell", [(-0.05, -0.16), (-0.10, -0.39), (-0.62, -0.39), (-0.72, -0.16)], 0.245, "Body", 0.014)
    w.box("CellLatch", (0, -0.32, -0.36), (0.253, 0.026, 0.34), "Metal", 0.0)
    w.box("MagRelease", (0.118, -0.12, 0.02), (0.02, 0.05, 0.08), "Metal", 0.0)
    # Blindaje lateral (un solo perfil que atraviesa el cajón y asoma por los dos lados)
    w.profile("ArmorPlate", [(0.38, 0.30), (-0.56, 0.30), (-0.72, 0.12), (0.22, 0.12)], 0.284, "Panel", 0.006)
    w.box("PlateCut", (0, 0.21, -0.02), (0.288, 0.2, 0.022), "Dark", 0.0, rot=(-41.6, 0, 0))
    # Conducto de energía bajo el blindaje
    w.box("Conduit", (0, 0.055, -0.14), (0.268, 0.024, 1.0), "Accent", 0.0)
    # Reactor: cubo metálico con el núcleo luminoso, sobre la empuñadura
    w.cyl("ReactorHub", (-0.139, 0.17, 0.56), (0.139, 0.17, 0.56), 0.105, "Metal", 10)
    w.cyl("ReactorRim", (-0.144, 0.17, 0.56), (0.144, 0.17, 0.56), 0.078, "Dark", 10)
    w.cyl("ReactorCore", (-0.149, 0.17, 0.56), (0.149, 0.17, 0.56), 0.048, "Accent", 10)
    # Lado derecho: rejilla de ventilación (expulsa el calor). Lado izquierdo: palanca de carga
    w.box("EjectVent", (0.143, 0.21, -0.26), (0.012, 0.09, 0.30), "Dark", 0.0)
    for i in range(3):
        w.box(f"VentFin{i}", (0.147, 0.21, -0.17 - i * 0.09), (0.01, 0.07, 0.03), "Metal", 0.0)
    w.box("ChargeSlot", (-0.143, 0.21, -0.26), (0.012, 0.04, 0.34), "Dark", 0.0)
    w.box("ChargeLever", (-0.158, 0.21, -0.38), (0.036, 0.06, 0.09), "Metal", 0.008, piece="Charge")
    w.box("Selector", (-0.118, -0.07, 0.24), (0.016, 0.03, 0.11), "Panel", 0.0, rot=(25, 0, 0))
    for z in (0.56, -0.7):
        w.cyl(f"Pin{z}", (-0.116, -0.08, z), (0.116, -0.08, z), 0.022, "Metal", 8)

    # ---------------------------------------------------------------- frente: bloque, púas y núcleo
    w.box("Fore", (0, 0.055, -1.10), (0.27, 0.55, 0.66), "Body", 0.022)
    # Coraza clara que envuelve el bloque por arriba y por los lados
    w.profile("Shroud", [(-0.84, 0.375), (-1.30, 0.375), (-1.45, 0.27), (-1.45, 0.06), (-1.26, -0.12), (-0.96, -0.12), (-0.84, 0.10)], 0.288, "Panel", 0.008)
    for i, z in enumerate((-1.00, -1.12, -1.24)):
        w.box(f"Gill{i}", (0, 0.13, z), (0.292, 0.2, 0.045), "Dark", 0.0, rot=(24, 0, 0))
    w.profile("UpperProng", [(-1.38, 0.33), (-1.92, 0.33), (-2.28, 0.25), (-2.28, 0.21), (-1.38, 0.21)], 0.20, "Body", 0.016)
    w.profile("LowerProng", [(-1.38, -0.09), (-2.20, -0.09), (-2.20, -0.13), (-2.02, -0.22), (-1.38, -0.22)], 0.20, "Body", 0.016)
    w.profile("ProngArmor", [(-1.50, 0.335), (-1.90, 0.335), (-2.14, 0.282), (-2.14, 0.25), (-1.58, 0.25)], 0.214, "Panel", 0.005)
    w.box("ProngConduit", (0, -0.155, -1.72), (0.208, 0.024, 0.56), "Accent", 0.0)
    # Raíles interiores (acero) y núcleo con sus bobinas, a la vista entre las dos púas
    w.box("RailUpper", (0, 0.205, -1.82), (0.12, 0.03, 0.84), "Metal", 0.0)
    w.box("RailLower", (0, -0.085, -1.78), (0.12, 0.03, 0.76), "Metal", 0.0)
    w.cyl("Core", (0, CORE_Y, -1.40), (0, CORE_Y, -2.19), 0.042, "Accent", 10)
    for i, z in enumerate((-1.52, -1.70, -1.88)):
        w.cyl(f"Coil{i}", (0, CORE_Y, z), (0, CORE_Y, z - 0.075), 0.088, "Metal", 10)
        w.cyl(f"CoilBand{i}", (0, CORE_Y, z - 0.026), (0, CORE_Y, z - 0.049), 0.096, "Dark", 10)
    # Yugo que sujeta el emisor a las dos púas
    w.box("Yoke", (0, CORE_Y, -2.10), (0.07, 0.32, 0.05), "Dark", 0.0)
    w.cyl("Emitter", (0, CORE_Y, -2.05), (0, CORE_Y, -2.17), 0.085, "Dark", 8)
    w.cyl("EmitterTip", (0, CORE_Y, -2.17), (0, CORE_Y, -2.25), 0.06, "Metal", 8)
    w.cyl("EmitterGlow", (0, CORE_Y, -2.19), (0, CORE_Y, -2.256), 0.034, "Accent", 8)
    # Conductos a la vista desde arriba (primera persona)
    w.box("TopConduit", (0, 0.338, -1.72), (0.05, 0.012, 0.34), "Accent", 0.0)
    w.box("ShroudSlot", (0, 0.376, -1.07), (0.11, 0.012, 0.38), "Dark", 0.0)
    w.box("ShroudConduit", (0, 0.380, -1.07), (0.04, 0.012, 0.30), "Accent", 0.0)
    # Apoyo de la mano izquierda
    w.profile("Foregrip", [(-0.82, -0.20), (-1.32, -0.20), (-1.24, -0.33), (-0.94, -0.40), (-0.82, -0.34)], 0.19, "Rubber", 0.022)
    w.profile("ForegripInlay", [(-0.90, -0.25), (-1.22, -0.25), (-1.18, -0.31), (-0.96, -0.35)], 0.204, "Panel", 0.0)

    # ---------------------------------------------------------------- raíl y visor holográfico
    w.box("Rail", (0, 0.352, -0.20), (0.115, 0.05, 1.36), "Dark", 0.01)
    for i in range(3):
        w.box(f"RailTooth{i}", (0, 0.384, -0.12 - i * 0.26), (0.13, 0.024, 0.11), "Dark", 0.0)
    w.box("SightBase", (0, 0.41, 0.35), (0.18, 0.08, 0.48), "Dark", 0.014)
    w.box("SightSill", (0, 0.475, 0.35), (0.20, 0.05, 0.30), "Body", 0.008)
    for side in (-1, 1):
        w.profile(f"SightWall{side}", [(0.50, 0.46), (0.50, 0.84), (0.26, 0.84), (0.18, 0.46)], 0.026, "Body", 0.006, x=side * 0.098)
    w.profile("SightHood", [(0.52, 0.82), (0.52, 0.86), (0.30, 0.88), (0.10, 0.84), (0.14, 0.82)], 0.232, "Panel", 0.006)
    w.box("SightLens", (0, 0.66, 0.33), (0.17, 0.32, 0.016), "Lens", 0.0)
    w.box("SightKnob", (0.122, 0.50, 0.40), (0.03, 0.05, 0.08), "Metal", 0.0)
    w.box("Reticle", (0, 0.66, 0.318), (0.022, 0.022, 0.006), "Reticle", 0.0)

    # ---------------------------------------------------------------- empuñadura y gatillo
    w.profile("Grip", [(0.26, -0.16), (0.54, -0.16), (0.68, -0.78), (0.42, -0.82)], 0.175, "Rubber", 0.028)
    w.profile("GripInlay", [(0.36, -0.30), (0.49, -0.30), (0.585, -0.68), (0.47, -0.70)], 0.19, "Panel", 0.0)
    w.box("TriggerGuard", (0, -0.375, 0.08), (0.045, 0.026, 0.50), "Dark", 0.0)
    w.box("Trigger", (0, -0.275, 0.14), (0.03, 0.14, 0.035), "Metal", 0.0, rot=(-18, 0, 0))

    # ---------------------------------------------------------------- célula de energía (cargador)
    w.profile("Cell", [(-0.14, -0.22), (-0.58, -0.22), (-0.72, -0.76), (-0.28, -0.76)], 0.15, "Dark", 0.016, piece="Mag")
    w.box("CellCore", (0, -0.52, -0.43), (0.162, 0.30, 0.22), "Accent", 0.0, piece="Mag", rot=(-14.5, 0, 0))
    for i, y in enumerate((-0.45, -0.59)):
        w.box(f"CellBar{i}", (0, y, -0.43 + (y + 0.52) * 0.26), (0.168, 0.028, 0.25), "Dark", 0.0, piece="Mag", rot=(-14.5, 0, 0))
    w.profile("CellCap", [(-0.24, -0.72), (-0.74, -0.72), (-0.78, -0.82), (-0.66, -0.88), (-0.30, -0.84)], 0.185, "Panel", 0.012, piece="Mag")

    # ---------------------------------------------------------------- culata integrada (ojo de pulgar)
    w.profile("StockSpine", [(0.72, 0.31), (1.50, 0.33), (1.50, 0.12), (0.98, 0.10), (0.72, 0.02)], 0.20, "Body", 0.018)
    w.profile("StockStrut", [(0.50, -0.66), (1.50, -0.30), (1.50, -0.50), (0.64, -0.83), (0.44, -0.83)], 0.15, "Body", 0.018)
    w.profile("StockButt", [(1.44, 0.34), (1.62, 0.34), (1.66, -0.46), (1.54, -0.56), (1.42, -0.46)], 0.21, "Dark", 0.022)
    w.box("ButtPad", (0, -0.07, 1.685), (0.2, 0.78, 0.06), "Rubber", 0.02)
    w.box("CheekRest", (0, 0.335, 1.10), (0.16, 0.05, 0.44), "Panel", 0.014)
    w.profile("StockPlate", [(1.46, 0.27), (1.59, 0.27), (1.62, -0.14), (1.50, -0.30)], 0.222, "Panel", 0.005)
    w.box("StockConduit", (0, 0.19, 1.14), (0.208, 0.024, 0.46), "Accent", 0.0)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, CORE_Y, -2.28))
    w.point("AimPoint", (0, 0.66, 0.35))
    w.point("Eject", (0.15, 0.21, -0.26))
    w.point("RightHand", (0, -0.48, 0.44))
    w.point("LeftHand", (0, -0.30, -1.0))
    w.point("CharmPoint", (-0.13, -0.02, 0.36))
