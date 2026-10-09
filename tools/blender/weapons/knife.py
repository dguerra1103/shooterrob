# COLMILLO · cuchillo de combate táctico (cuerpo a cuerpo por defecto de SHOOTERROB).
# Silueta: hoja "clip point" con la punta remangada como un colmillo, dientes de sierra en el lomo junto
# a la guarda, vaceo luminoso a lo largo de la hoja, guarda angulosa con gavilán inferior adelantado,
# mango de goma con inserto naranja y pomo de acero con anilla para el fiador.
# Orientación del juego: la hoja va hacia -Z, el filo hacia -Y, el origen en el centro del mango.
NAME = "Knife"

PALETTE = {
    "Body": (0.045, 0.05, 0.065),
    "Panel": (1.0, 0.38, 0.03),  # naranja de la casa
    "Accent": (0.1, 0.9, 1.0),  # cian
    "Dark": (0.02, 0.021, 0.027),
    "Metal": (0.78, 0.8, 0.86),
    "Rubber": (0.03, 0.032, 0.038),
}


def build(w):
    # ---------------------------------------------------------------- hoja
    # Acero: lomo recto, rebaje cóncavo (clip) y punta que vuelve a subir; vientre curvo
    w.profile("Blade", [(-0.34, 0.12), (-1.00, 0.12), (-1.26, 0.07), (-1.50, 0.17), (-1.44, 0.02), (-1.30, -0.09), (-1.06, -0.145), (-0.34, -0.145)], 0.045, "Metal", 0.0)
    # Plano superior oscuro (más grueso): deja el bisel del filo en acero vivo
    w.profile("BladeFlat", [(-0.36, 0.125), (-0.98, 0.125), (-1.20, 0.085), (-1.06, -0.02), (-0.36, -0.02)], 0.058, "Body", 0.0)
    # Vaceo luminoso
    w.box("Fuller", (0, 0.05, -0.74), (0.066, 0.028, 0.62), "Accent", 0.0)
    w.box("FullerTip", (0, 0.045, -1.10), (0.066, 0.028, 0.14), "Accent", 0.0, rot=(-8, 0, 0))
    # Sierra del lomo (dientes con la cara vertical hacia la guarda)
    for i in range(3):
        z = -0.44 - i * 0.11
        w.profile(f"Tooth{i}", [(z, 0.115), (z, 0.185), (z - 0.11, 0.115)], 0.052, "Dark", 0.0)
    # Ricasso con muesca de color
    w.box("Ricasso", (0, -0.085, -0.43), (0.062, 0.07, 0.10), "Panel", 0.0)

    # ---------------------------------------------------------------- guarda
    w.profile("Guard", [(-0.27, 0.15), (-0.36, 0.20), (-0.38, -0.17), (-0.45, -0.28), (-0.37, -0.28), (-0.27, -0.16)], 0.19, "Body", 0.014)
    w.box("GuardPlate", (0, 0.0, -0.325), (0.204, 0.22, 0.035), "Panel", 0.0)

    # ---------------------------------------------------------------- mango
    w.box("Handle", (0, -0.005, 0.02), (0.165, 0.235, 0.60), "Rubber", 0.028)
    w.profile("HandleInlay", [(-0.20, 0.055), (0.20, 0.055), (0.26, -0.045), (-0.14, -0.045)], 0.18, "Panel", 0.0)
    for i, z in enumerate((-0.09, 0.03, 0.15)):
        w.box(f"Rib{i}", (0, -0.005, z), (0.188, 0.20, 0.034), "Rubber", 0.0, rot=(31, 0, 0))
    # Luz en el lomo del mango (se ve en primera persona) y talón inferior que encaja el meñique
    w.box("HandleGlow", (0, 0.113, 0.02), (0.028, 0.014, 0.36), "Accent", 0.0)
    w.profile("HandleHeel", [(0.31, -0.11), (0.31, -0.17), (0.14, -0.17), (0.03, -0.11)], 0.165, "Rubber", 0.0)

    # ---------------------------------------------------------------- pomo
    w.profile("Pommel", [(0.30, 0.135), (0.39, 0.135), (0.46, 0.03), (0.42, -0.19), (0.30, -0.18)], 0.19, "Metal", 0.014)
    w.ring("LanyardRing", (-0.07, -0.03, 0.455), (0.07, -0.03, 0.455), 0.062, 0.032, "Metal", 10)

    # ---------------------------------------------------------------- puntos
    w.point("Muzzle", (0, 0.17, -1.50))
    w.point("AimPoint", (0, 0.17, -1.50))
    w.point("Eject", (0.11, 0.0, -0.33))
    w.point("RightHand", (0, 0, 0.1))
    w.point("LeftHand", (0, 0, 0.24))
    w.point("CharmPoint", (0, -0.03, 0.47))
