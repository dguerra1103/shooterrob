# TEMPEST CORE · lanzacohetes de hombro de SHOOTERROB (diseño original).
# Silueta: tubo ancho con camisa naranja, morro acampanado y blindado con placas de aviso, cabeza de
# guerra roja asomando por la boca (pieza Mag: desaparece y vuelve al recargar), anillo de energía cian
# alrededor del tubo, cono de escape trasero con aletas de ventilación, visor de caja con módulo
# telemétrico al costado izquierdo, empuñadura de pistola, empuñadura delantera y hombrera bajo la cola.
import math

NAME = "NovaLauncher"

PALETTE = {
    "Body": (0.045, 0.05, 0.068),
    "Panel": (0.97, 0.36, 0.04),  # naranja de la casa
    "Accent": (0.12, 0.88, 1.0),  # cian luminoso
    "Accent2": (1.0, 0.78, 0.08),  # amarillo de aviso
    "Dark": (0.016, 0.017, 0.022),
    "Metal": (0.5, 0.52, 0.58),
    "Trim": (0.86, 0.06, 0.05),  # rojo de la cabeza de guerra
}

TY = 0.12  # eje del tubo
R = 0.20  # radio del tubo


def build(w):
    # ---------------------------------------------------------------- tubo principal y camisa
    w.cyl("MainTube", (0, TY, -1.66), (0, TY, 1.14), R, "Body", 12)
    w.cyl("Sleeve", (0, TY, -0.62), (0, TY, 0.66), 0.228, "Panel", 12)
    for i, z in enumerate((-0.66, 0.62)):
        w.cyl(f"SleeveBand{i}", (0, TY, z), (0, TY, z + 0.08), 0.245, "Dark", 12)
    w.cyl("SleeveGroove", (0, TY, -0.16), (0, TY, -0.11), 0.234, "Dark", 12)
    # Placa de aviso en el costado derecho de la camisa (a la vista en primera persona)
    w.box("SidePlateR", (0.222, TY, 0.26), (0.03, 0.17, 0.50), "Dark", 0.0)
    for i in range(4):
        w.box(f"SideStripe{i}", (0.236, TY, 0.09 + i * 0.115), (0.012, 0.19, 0.045), "Accent2", 0.0, rot=(32, 0, 0))
    w.box("EjectPort", (0.226, TY + 0.02, -0.38), (0.02, 0.11, 0.26), "Dark", 0.0)
    w.box("SidePlateL", (-0.222, TY - 0.02, -0.36), (0.03, 0.15, 0.34), "Dark", 0.0)
    w.box("SideGlowL", (-0.238, TY - 0.02, -0.36), (0.008, 0.028, 0.26), "Accent", 0.0)

    w.box("TopRail", (0, TY + 0.235, -0.30), (0.11, 0.05, 0.56), "Dark", 0.0)
    for i in range(3):
        w.box(f"TopRailTooth{i}", (0, TY + 0.268, -0.12 - i * 0.18), (0.125, 0.022, 0.09), "Dark", 0.0)

    # ---------------------------------------------------------------- anillo de energía
    w.cyl("CoreHousing", (0, TY, -1.50), (0, TY, -0.98), 0.232, "Dark", 12)
    for i, z in enumerate((-1.40, -1.165)):
        w.cyl(f"CoreGlow{i}", (0, TY, z), (0, TY, z + 0.055), 0.246, "Accent", 12)
    w.cyl("CoreClamp", (0, TY, -1.30), (0, TY, -1.205), 0.262, "Panel", 8)
    for side in (-1, 1):
        w.box(f"CoreBolt{side}", (side * 0.255, TY, -1.2525), (0.05, 0.10, 0.13), "Metal", 0.0)

    # ---------------------------------------------------------------- morro acampanado y blindado
    w.cyl("ShroudNeck", (0, TY, -1.58), (0, TY, -1.74), 0.25, "Body", 12)
    w.ring("Shroud", (0, TY, -1.72), (0, TY, -1.98), 0.30, 0.205, "Body", 12)
    w.ring("ShroudLip", (0, TY, -1.89), (0, TY, -1.95), 0.325, 0.28, "Panel", 12)
    w.profile("ShroudTop", [(-1.50, TY + 0.19), (-1.50, TY + 0.25), (-1.70, TY + 0.36), (-1.93, TY + 0.36), (-2.03, TY + 0.30), (-2.03, TY + 0.24), (-1.70, TY + 0.24)], 0.26, "Panel", 0.014)
    w.box("ShroudTopInset", (0, TY + 0.362, -1.81), (0.12, 0.014, 0.22), "Dark", 0.0)
    w.box("ShroudTopGlow", (0, TY + 0.368, -1.81), (0.03, 0.012, 0.16), "Accent", 0.0)
    w.profile("ShroudChin", [(-1.50, TY - 0.19), (-1.70, TY - 0.24), (-2.03, TY - 0.24), (-2.03, TY - 0.30), (-1.93, TY - 0.36), (-1.70, TY - 0.36), (-1.50, TY - 0.25)], 0.24, "Body", 0.014)
    for side in (-1, 1):
        w.profile(f"CheekArmor{side}", [(-1.56, TY + 0.13), (-1.56, TY - 0.13), (-1.70, TY - 0.17), (-2.04, TY - 0.17), (-2.04, TY + 0.17), (-1.70, TY + 0.17)], 0.07, "Dark", 0.01, x=side * 0.30)
        for i in range(3):
            w.box(f"Hazard{side}_{i}", (side * 0.338, TY, -1.75 - i * 0.10), (0.012, 0.26, 0.046), "Accent2", 0.0, rot=(30, 0, 0))

    # ---------------------------------------------------------------- cohete cargado (pieza Mag)
    w.cyl("RocketBody", (0, TY, -1.66), (0, TY, -2.14), 0.172, "Trim", 12, piece="Mag")
    w.cyl("RocketBand", (0, TY, -2.03), (0, TY, -2.07), 0.18, "Accent", 12, piece="Mag")
    w.cyl("RocketCone1", (0, TY, -2.14), (0, TY, -2.25), 0.172, "Trim", 12, piece="Mag", radius_b=0.115)
    w.cyl("RocketCone2", (0, TY, -2.25), (0, TY, -2.34), 0.115, "Trim", 12, piece="Mag", radius_b=0.055)
    w.cyl("RocketFuse", (0, TY, -2.34), (0, TY, -2.40), 0.042, "Metal", 8, piece="Mag", radius_b=0.024)

    # ---------------------------------------------------------------- cono de escape con aletas
    w.cyl("RearCollar", (0, TY, 1.10), (0, TY, 1.22), 0.24, "Dark", 12)
    w.cyl("ExhaustThroat", (0, TY, 1.20), (0, TY, 1.38), 0.255, "Body", 12)
    w.ring("ExhaustBell", (0, TY, 1.36), (0, TY, 1.64), 0.31, 0.235, "Body", 12)
    w.ring("ExhaustBand", (0, TY, 1.40), (0, TY, 1.46), 0.322, 0.24, "Panel", 12)
    w.cyl("TailRing", (0, TY, 0.86), (0, TY, 0.91), 0.215, "Metal", 12)
    w.ring("ExhaustLip", (0, TY, 1.62), (0, TY, 1.68), 0.33, 0.27, "Metal", 12)
    for i in range(6):
        a = math.radians(30 + i * 60)
        w.box(f"ExhaustFin{i}", (0.285 * math.sin(a), TY + 0.285 * math.cos(a), 1.33), (0.045, 0.13, 0.30), "Dark", 0.0, rot=(0, 0, -math.degrees(a)))

    # ---------------------------------------------------------------- carcasa inferior, gatillo y empuñadura
    w.profile("Housing", [(0.68, 0.0), (0.68, -0.20), (0.46, -0.28), (-0.34, -0.28), (-0.96, -0.19), (-0.96, 0.0)], 0.28, "Body", 0.018)
    for side in (-1, 1):
        w.box(f"HousingGlow{side}", (side * 0.142, -0.15, 0.06), (0.008, 0.026, 0.56), "Accent", 0.0)
    w.cyl("HousingPin", (-0.148, -0.19, 0.50), (0.148, -0.19, 0.50), 0.026, "Metal", 6)
    w.profile("Grip", [(-0.08, -0.24), (0.21, -0.24), (0.36, -0.84), (0.05, -0.87)], 0.185, "Rubber", 0.026)
    w.box("GripInlay", (0, -0.56, 0.135), (0.20, 0.38, 0.12), "Panel", 0.0, rot=(-12, 0, 0))
    w.box("TriggerGuard", (0, -0.44, -0.24), (0.045, 0.028, 0.40), "Dark", 0.0)
    w.box("TriggerGuardFront", (0, -0.36, -0.43), (0.045, 0.19, 0.03), "Dark", 0.0)
    w.box("Trigger", (0, -0.34, -0.17), (0.03, 0.14, 0.035), "Metal", 0.0, rot=(-18, 0, 0))
    # Empuñadura delantera
    w.profile("Foregrip", [(-0.54, -0.20), (-0.86, -0.20), (-0.83, -0.62), (-0.75, -0.72), (-0.59, -0.68)], 0.18, "Rubber", 0.022)
    w.box("ForegripInlay", (0, -0.43, -0.705), (0.194, 0.24, 0.10), "Panel", 0.0, rot=(3, 0, 0))

    # ---------------------------------------------------------------- hombrera bajo la cola
    w.box("PadStrut", (0, -0.10, 1.00), (0.20, 0.16, 0.56), "Body", 0.014)
    w.profile("ShoulderPad", [(0.72, -0.14), (0.72, -0.34), (0.86, -0.48), (1.28, -0.48), (1.40, -0.34), (1.40, -0.14)], 0.32, "Rubber", 0.024)
    w.box("PadPlate", (0, -0.23, 1.06), (0.332, 0.08, 0.46), "Panel", 0.0)
    w.box("PadGlow", (0, -0.38, 1.07), (0.328, 0.022, 0.32), "Accent", 0.0)

    # ---------------------------------------------------------------- visor de caja con módulo telemétrico
    w.box("OpticRail", (0, TY + 0.25, 0.40), (0.14, 0.07, 0.62), "Dark", 0.0)
    w.box("OpticBase", (0, 0.45, 0.41), (0.27, 0.07, 0.44), "Dark", 0.014)
    for side in (-1, 1):
        w.profile(f"OpticWall{side}", [(0.61, 0.47), (0.61, 0.82), (0.33, 0.82), (0.21, 0.47)], 0.032, "Body", 0.008, x=side * 0.118)
    w.box("OpticHood", (0, 0.825, 0.46), (0.27, 0.035, 0.32), "Panel", 0.008)
    w.box("OpticLens", (0, 0.64, 0.40), (0.205, 0.31, 0.016), "Lens", 0.0)
    w.box("Reticle", (0, 0.64, 0.388), (0.024, 0.024, 0.006), "Reticle", 0.0)
    # Módulo telemétrico (izquierda) con su lente delantera y su brazo al tubo
    w.box("RangeUnit", (-0.215, 0.56, 0.38), (0.17, 0.21, 0.56), "Body", 0.02)
    w.box("RangeCap", (-0.215, 0.672, 0.40), (0.13, 0.02, 0.36), "Panel", 0.0)
    w.cyl("RangeLens", (-0.215, 0.56, 0.11), (-0.215, 0.56, 0.06), 0.07, "Lens", 8)
    w.box("RangeGlow", (-0.303, 0.56, 0.42), (0.008, 0.026, 0.34), "Accent", 0.0)
    w.box("RangeArm", (-0.20, 0.38, 0.42), (0.10, 0.20, 0.26), "Dark", 0.0)
    w.box("OpticKnob", (0.155, 0.52, 0.46), (0.05, 0.07, 0.10), "Metal", 0.0)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, TY, -2.40))
    w.point("AimPoint", (0, 0.64, 0.40))
    w.point("Eject", (0.25, TY + 0.02, -0.38))
    w.point("RightHand", (0, -0.45, 0.12))
    w.point("LeftHand", (0, -0.40, -0.70))
    w.point("CharmPoint", (-0.145, -0.12, 0.42))
