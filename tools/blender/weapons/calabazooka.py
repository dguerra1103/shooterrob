# CALABAZOOKA · lanzacalabazas del evento de Halloween de SHOOTERROB (diseño original).
# Misma sujeción que el Tempest Core (tubo al hombro, empuñaduras, boca y mira en el mismo sitio), pero
# es otra arma: tubo de hierro oscuro atado con cuerda y enredadera con espinas, boca acampanada naranja
# con dientes (boca tallada de calabaza) y rabito verde, una calabaza con cara luminosa cargada en la boca
# (pieza Mag: desaparece y vuelve al recargar), cara tallada que brilla en el costado derecho, mira con
# sombrero de bruja torcido, vela encendida al costado izquierdo y aletas de ala de murciélago en la cola.
import math

NAME = "Calabazooka"

PALETTE = {
    "Body": (0.05, 0.036, 0.085),  # hierro oscuro violáceo
    "Panel": (1.0, 0.19, 0.008),  # naranja calabaza (≈ RGB 255,120,20)
    "Accent": (1.0, 0.58, 0.045),  # amarillo cálido de vela (≈ 255,200,60)
    "Accent2": (0.30, 0.06, 0.72),  # morado (≈ 150,70,220)
    "Dark": (0.016, 0.013, 0.024),
    "Metal": (0.92, 0.86, 0.66),  # hueso / cera
    "Rubber": (0.17, 0.10, 0.045),  # cuerda de cáñamo y cuero
    "Lens": (0.25, 0.95, 0.35),  # cristal verde fantasma
    "Trim": (0.156, 0.58, 0.045),  # verde enfermizo (≈ 110,200,60)
}

TY = 0.12  # eje del tubo
R = 0.20  # radio del tubo
PZ = -2.13  # centro de la calabaza cargada


def rope(w, name, z0, radius=0.25):
    for i in range(3):
        z = z0 + i * 0.05
        w.cyl(f"{name}{i}", (0, TY, z), (0, TY, z + 0.052), radius if i != 1 else radius - 0.01, "Rubber", 8)


def build(w):
    # ---------------------------------------------------------------- tubo, camisa y cuerdas
    w.cyl("MainTube", (0, TY, -1.66), (0, TY, 1.14), R, "Body", 12)
    w.cyl("Sleeve", (0, TY, -0.56), (0, TY, 0.62), 0.228, "Panel", 12)
    w.cyl("SleeveGroove", (0, TY, -0.16), (0, TY, -0.11), 0.234, "Dark", 12)
    rope(w, "RopeA", -0.71)
    rope(w, "RopeB", 0.62)
    rope(w, "RopeC", -1.63)
    w.box("RopeKnot", (0.25, TY - 0.03, 0.695), (0.06, 0.08, 0.09), "Rubber", 0.0)
    w.box("RopeEnd0", (0.262, TY - 0.13, 0.72), (0.03, 0.17, 0.035), "Rubber", 0.0, rot=(16, 0, 0))
    w.box("RopeEnd1", (0.262, TY - 0.11, 0.665), (0.03, 0.13, 0.035), "Rubber", 0.0, rot=(-14, 0, 0))

    # Cara tallada que brilla en el costado derecho (a la vista en primera persona)
    w.box("FacePlate", (0.222, TY, 0.24), (0.03, 0.23, 0.52), "Dark", 0.0)
    for i, z in enumerate((0.05, 0.31)):
        w.profile(f"FaceEye{i}", [(z, TY + 0.015), (z + 0.13, TY + 0.015), (z + (0.0 if i == 0 else 0.13), TY + 0.095)], 0.014, "Accent", 0.0, x=0.238)
    w.profile("FaceNose", [(0.215, TY - 0.012), (0.265, TY - 0.012), (0.24, TY + 0.03)], 0.014, "Accent", 0.0, x=0.238)
    w.profile(
        "FaceMouth",
        [(0.04, TY - 0.025), (0.16, TY - 0.06), (0.24, TY - 0.03), (0.32, TY - 0.06), (0.44, TY - 0.025), (0.35, TY - 0.10), (0.13, TY - 0.10)],
        0.014, "Accent", 0.0, x=0.238,
    )
    w.box("EjectPort", (0.226, TY + 0.02, -0.38), (0.02, 0.11, 0.26), "Dark", 0.0)

    # Enredadera del costado izquierdo, con hojas, y tira de vela
    w.box("VineL", (-0.232, TY + 0.02, 0.02), (0.03, 0.04, 1.10), "Trim", 0.0, rot=(5, 0, 0))
    for i, (z, dy, ang) in enumerate(((-0.40, 0.085, 28), (-0.02, 0.0, -28), (0.34, 0.03, 28))):
        w.box(f"LeafL{i}", (-0.238, TY + dy, z), (0.016, 0.05, 0.15), "Trim", 0.0, rot=(ang, 0, 0))
    w.box("SideGlowL", (-0.236, TY - 0.09, -0.02), (0.008, 0.026, 0.60), "Accent", 0.0)

    w.box("TopRail", (0, TY + 0.235, -0.30), (0.11, 0.05, 0.56), "Dark", 0.0)

    # ---------------------------------------------------------------- tramo delantero: aros de vela y nudo de enredadera
    w.cyl("CoreHousing", (0, TY, -1.50), (0, TY, -0.98), 0.232, "Dark", 12)
    for i, z in enumerate((-1.42, -1.14)):
        w.cyl(f"CoreGlow{i}", (0, TY, z), (0, TY, z + 0.05), 0.246, "Accent", 12)
    w.cyl("VineClamp", (0, TY, -1.32), (0, TY, -1.22), 0.262, "Trim", 8)
    w.box("ClampBolt", (0, TY, -1.27), (0.56, 0.10, 0.13), "Accent2", 0.0)
    # Enredadera con espinas por el lomo
    w.box("VineTop", (0, TY + 0.225, -1.02), (0.06, 0.07, 0.72), "Trim", 0.0)
    for i, z in enumerate((-0.74, -0.92, -1.10, -1.33)):
        w.profile(f"Thorn{i}", [(z, TY + 0.25), (z - 0.12, TY + 0.25), (z - 0.12, TY + 0.38)], 0.045, "Trim", 0.0)
    w.profile("ThornBelly", [(-1.20, TY - 0.25), (-1.34, TY - 0.37), (-1.34, TY - 0.25)], 0.045, "Trim", 0.0)

    # ---------------------------------------------------------------- boca de calabaza con dientes
    w.cyl("BellNeck", (0, TY, -1.60), (0, TY, -1.72), 0.262, "Dark", 12)
    w.ring("Bell", (0, TY, -1.70), (0, TY, -2.02), 0.335, 0.275, "Panel", 12)
    w.ring("MouthGlow", (0, TY, -2.012), (0, TY, -2.032), 0.30, 0.275, "Accent", 12)
    for i, deg in enumerate((45, 135, 225, 315)):
        a = math.radians(deg)
        w.box(f"BellRib{i}", (0.326 * math.sin(a), TY + 0.326 * math.cos(a), -1.86), (0.035, 0.02, 0.28), "Dark", 0.0, rot=(0, 0, -deg))
    # Rabito y hoja de la boca
    w.cyl("BellStem", (0, TY + 0.30, -1.87), (0.035, TY + 0.42, -1.80), 0.045, "Trim", 6)
    w.box("BellStemTip", (0.055, TY + 0.435, -1.775), (0.075, 0.04, 0.06), "Trim", 0.0, rot=(0, 0, -25))
    w.profile("BellLeaf", [(-1.74, TY + 0.25), (-1.74, TY + 0.37), (-1.50, TY + 0.25)], 0.10, "Trim", 0.0)
    # Dientes: dos arriba (hueco en el centro), tres abajo, dos por lado
    for side in (-1, 1):
        w.profile(f"ToothTop{side}", [(-2.0, TY + 0.32), (-2.0, TY + 0.215), (-2.18, TY + 0.215)], 0.11, "Metal", 0.0, x=side * 0.13)
        w.profile(f"ToothLow{side}", [(-2.0, TY - 0.29), (-2.15, TY - 0.20), (-2.0, TY - 0.20)], 0.10, "Metal", 0.0, x=side * 0.18)
        for j, s in enumerate((-1, 1)):
            w.profile(f"ToothSide{side}_{j}", [(-2.0, TY + s * 0.17), (-2.0, TY + s * 0.03), (-2.15, TY + s * 0.03)], 0.06, "Metal", 0.0, x=side * 0.295)
    w.profile("ToothLowMid", [(-2.0, TY - 0.335), (-2.19, TY - 0.225), (-2.0, TY - 0.225)], 0.11, "Metal", 0.0)

    # ---------------------------------------------------------------- calabaza cargada (pieza Mag)
    w.cyl("PumpkinCore", (0, TY - 0.235, PZ), (0, TY + 0.235, PZ), 0.15, "Panel", 10, piece="Mag")
    w.cyl("PumpkinShoulder", (0, TY - 0.195, PZ), (0, TY + 0.195, PZ), 0.215, "Panel", 10, piece="Mag")
    for i, deg in enumerate((0, 60, 300)):
        a = math.radians(deg)
        x, z = 0.095 * math.sin(a), PZ - 0.095 * math.cos(a)
        w.cyl(f"PumpkinLobe{i}", (x, TY - 0.14, z), (x, TY + 0.14, z), 0.165, "Panel", 8, piece="Mag")
    w.cyl("PumpkinStem", (0, TY + 0.21, PZ), (0.02, TY + 0.325, PZ + 0.03), 0.04, "Trim", 6, piece="Mag")
    w.box("PumpkinStemTip", (0.035, TY + 0.335, PZ + 0.04), (0.07, 0.035, 0.05), "Trim", 0.0, piece="Mag", rot=(0, 0, -20))
    for side in (-1, 1):
        w.box(f"PumpkinEye{side}", (side * 0.085, TY + 0.065, -2.37), (0.09, 0.055, 0.07), "Accent", 0.0, piece="Mag", rot=(0, 0, side * 22))
        w.box(f"PumpkinGrin{side}", (side * 0.115, TY - 0.065, -2.365), (0.07, 0.04, 0.07), "Accent", 0.0, piece="Mag", rot=(0, 0, side * -35))
    w.box("PumpkinNose", (0, TY - 0.005, -2.375), (0.035, 0.035, 0.05), "Accent", 0.0, piece="Mag", rot=(0, 0, 45))
    w.box("PumpkinMouth", (0, TY - 0.09, -2.37), (0.20, 0.045, 0.07), "Accent", 0.0, piece="Mag")

    # ---------------------------------------------------------------- escape con alas de murciélago
    w.cyl("RearCollar", (0, TY, 1.10), (0, TY, 1.22), 0.24, "Dark", 12)
    w.cyl("ExhaustThroat", (0, TY, 1.20), (0, TY, 1.38), 0.255, "Body", 12)
    w.ring("ExhaustBell", (0, TY, 1.36), (0, TY, 1.64), 0.31, 0.235, "Body", 12)
    w.ring("ExhaustBand", (0, TY, 1.40), (0, TY, 1.46), 0.322, 0.24, "Accent2", 12)
    w.cyl("TailRing", (0, TY, 0.86), (0, TY, 0.91), 0.215, "Metal", 12)
    w.ring("ExhaustLip", (0, TY, 1.62), (0, TY, 1.68), 0.33, 0.27, "Metal", 12)
    for side in (-1, 1):
        w.profile(
            f"BatWing{side}",
            [(1.10, TY - 0.15), (1.64, TY - 0.15), (1.68, TY - 0.35), (1.52, TY - 0.31), (1.50, TY - 0.44), (1.34, TY - 0.35), (1.22, TY - 0.50)],  # (hacia abajo: hacia arriba tapaban la vista al apuntar)
            0.04, "Accent2", 0.0, x=side * 0.17,
        )

    # ---------------------------------------------------------------- carcasa inferior, gatillo y empuñadura
    w.profile("Housing", [(0.68, 0.0), (0.68, -0.20), (0.46, -0.28), (-0.34, -0.28), (-0.96, -0.19), (-0.96, 0.0)], 0.28, "Body", 0.018)
    w.box("HousingGlow", (0, -0.15, 0.06), (0.292, 0.026, 0.56), "Accent", 0.0)
    w.cyl("HousingPin", (-0.148, -0.19, 0.50), (0.148, -0.19, 0.50), 0.026, "Metal", 6)
    w.profile("Grip", [(-0.08, -0.24), (0.21, -0.24), (0.36, -0.84), (0.05, -0.87)], 0.185, "Rubber", 0.026)
    w.box("GripInlay", (0, -0.56, 0.135), (0.20, 0.38, 0.12), "Panel", 0.0, rot=(-12, 0, 0))
    w.box("GripBand", (0, -0.80, 0.20), (0.20, 0.05, 0.31), "Accent2", 0.0, rot=(-5, 0, 0))
    w.box("TriggerGuard", (0, -0.44, -0.24), (0.045, 0.028, 0.40), "Dark", 0.0)
    w.box("TriggerGuardFront", (0, -0.36, -0.43), (0.045, 0.19, 0.03), "Dark", 0.0)
    w.box("Trigger", (0, -0.34, -0.17), (0.03, 0.14, 0.035), "Metal", 0.0, rot=(-18, 0, 0))
    # Empuñadura delantera con forma de raíz retorcida
    w.profile("Foregrip", [(-0.54, -0.20), (-0.86, -0.20), (-0.84, -0.56), (-0.92, -0.76), (-0.74, -0.69), (-0.60, -0.64)], 0.18, "Rubber", 0.022)
    w.box("ForegripInlay", (0, -0.40, -0.705), (0.194, 0.22, 0.10), "Trim", 0.0, rot=(3, 0, 0))

    # ---------------------------------------------------------------- hombrera bajo la cola
    w.box("PadStrut", (0, -0.10, 1.00), (0.20, 0.16, 0.56), "Body", 0.014)
    w.profile("ShoulderPad", [(0.72, -0.14), (0.72, -0.34), (0.86, -0.48), (1.28, -0.48), (1.40, -0.34), (1.40, -0.14)], 0.32, "Rubber", 0.024)
    w.box("PadPlate", (0, -0.23, 1.06), (0.332, 0.08, 0.46), "Panel", 0.0)
    w.box("PadGlow", (0, -0.38, 1.07), (0.328, 0.022, 0.32), "Accent", 0.0)

    # ---------------------------------------------------------------- mira con sombrero de bruja torcido
    w.box("OpticRail", (0, TY + 0.25, 0.40), (0.14, 0.07, 0.62), "Dark", 0.0)
    w.box("OpticBase", (0, 0.45, 0.41), (0.27, 0.07, 0.44), "Dark", 0.014)
    for side in (-1, 1):
        w.profile(f"OpticWall{side}", [(0.61, 0.47), (0.61, 0.82), (0.33, 0.82), (0.21, 0.47)], 0.032, "Body", 0.008, x=side * 0.118)
    w.box("OpticLens", (0, 0.64, 0.40), (0.205, 0.31, 0.016), "Lens", 0.0)
    w.box("Reticle", (0, 0.64, 0.388), (0.024, 0.024, 0.006), "Reticle", 0.0)
    w.box("HatBrim", (0, 0.825, 0.44), (0.40, 0.035, 0.50), "Body", 0.008)
    w.profile(
        "HatCone",
        [(0.62, 0.84), (0.24, 0.84), (0.30, 0.96), (0.40, 1.06), (0.55, 1.12), (0.73, 1.07), (0.58, 1.05), (0.54, 0.96)],
        0.22, "Body", 0.0,
    )
    w.box("HatBand", (0, 0.868, 0.43), (0.23, 0.05, 0.37), "Accent2", 0.0)
    w.box("HatBuckle", (0, 0.868, 0.43), (0.246, 0.06, 0.08), "Accent", 0.0)
    # Vela encendida al costado izquierdo
    w.box("CandleArm", (-0.20, 0.45, 0.42), (0.16, 0.05, 0.20), "Dark", 0.0)
    w.cyl("Candle", (-0.225, 0.47, 0.42), (-0.225, 0.65, 0.42), 0.052, "Accent2", 8)
    w.box("CandleFlame", (-0.225, 0.70, 0.42), (0.055, 0.055, 0.04), "Accent", 0.0, rot=(0, 0, 45))
    w.box("OpticKnob", (0.155, 0.52, 0.46), (0.05, 0.07, 0.10), "Accent2", 0.0)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, TY, -2.40))
    w.point("AimPoint", (0, 0.64, 0.40))
    w.point("Eject", (0.25, TY + 0.02, -0.38))
    w.point("RightHand", (0, -0.45, 0.12))
    w.point("LeftHand", (0, -0.40, -0.70))
    w.point("CharmPoint", (-0.145, -0.12, 0.42))


