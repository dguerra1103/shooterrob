# Monta el icono (512x512) de cada producto de pago en assets/tienda/iconos:
#   python -X utf8 scripts/monetizacion/iconos.py
# El dibujo sale de las hojas de assets/tienda/arte (rejillas de 3x3 generadas con ChatGPT, sin texto);
# este script recorta cada casilla y le pone encima la categoría y el nombre, que salen de productos.json.
# Para cambiar un dibujo: sustituye la hoja (o la casilla en ART) y vuelve a ejecutarlo.
import io
import json
import os
import re

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "assets", "tienda", "iconos")
ART_DIR = os.path.join(ROOT, "assets", "tienda", "arte")
SIZE = 512
CELL_AT, CELL_SIZE = (11, 427, 843), 400  # (dónde empieza cada casilla en una hoja de 1254 px)

# clave del producto -> (hoja, casilla 0..8 de izquierda a derecha y de arriba abajo)
ART = {
    "Coins:Puñado": (1, 0), "Coins:Bolsa": (1, 1), "Coins:Cofre": (1, 2), "Coins:Bóveda": (1, 3),
    "Booster:XP2": (1, 4), "Booster:Coins2": (1, 5), "Starter:Starter": (1, 6), "PassPremium:S1": (1, 7), "VIP": (1, 8),
    "Bundle:Halloween": (2, 0), "Bundle:Navidad": (2, 1), "Bundle:Aventurero": (2, 2), "Bundle:RedOps": (2, 3),
    "Bundle:Artico": (2, 4), "Bundle:Vacio": (2, 5), "TierSkip:TierSkip": (2, 6), "Item:Card:Glaciar": (2, 7), "Item:Card:Infierno": (2, 8),
    "Item:Card:Oro": (3, 0), "Item:Card:Vacio": (3, 1), "Item:Charm:Bala": (3, 2), "Item:Charm:Calaverita": (3, 3),
    "Item:Charm:Chapa": (3, 4), "Item:KillEffect:ChoqueRojo": (3, 5), "Item:KillEffect:OroFlash": (3, 6),
    "Item:KillEffect:Pixel": (3, 7), "Item:MVPIntro:Ascuas": (3, 8),
    "Item:MVPIntro:Columna": (4, 0), "Item:Outfit:ArticoTactico": (4, 1), "Item:Outfit:OperacionRoja": (4, 2),
    "Item:Pose:Brazos": (4, 3), "Item:Pose:Saludo": (4, 4), "Item:Pose:Senala": (4, 5),
    "Item:Skin:ArticoTactico": (4, 6), "Item:Skin:Callejero": (4, 7), "Item:Skin:Ciber": (4, 8),
    "Item:Skin:GrietaVacio": (5, 0), "Item:Skin:Inferno": (5, 1), "Item:Skin:OperacionRoja": (5, 2),
}

# (prefijo de la clave, rótulo de categoría, color de acento)
STYLES = [
    ("Coins:", "MONEDAS", (255, 190, 40)),
    ("Booster:", "POTENCIADOR", (80, 220, 130)),
    ("Starter:", "OFERTA DE INICIO", (255, 130, 40)),
    ("PassPremium:", "PASE DE BATALLA", (255, 60, 90)),
    ("TierSkip:", "PASE DE BATALLA", (255, 60, 90)),
    ("Bundle:", "PACK", (190, 80, 255)),
    ("Item:Skin:", "SKIN DE ARMA", (70, 160, 255)),
    ("Item:Outfit:", "TRAJE", (70, 160, 255)),
    ("Item:KillEffect:", "EFECTO DE BAJA", (255, 60, 90)),
    ("Item:MVPIntro:", "INTRO DE MVP", (255, 180, 30)),
    ("Item:Pose:", "POSE DE VICTORIA", (80, 220, 130)),
    ("Item:Charm:", "COLGANTE", (255, 180, 30)),
    ("Item:Card:", "TARJETA", (190, 80, 255)),
    ("VIP", "PASE VIP", (255, 190, 40)),
]
# (lo que se quita del nombre porque ya lo dice la categoría)
PREFIXES = ["Skin de arma ", "Traje de operador ", "Efecto de baja ", "Intro de MVP ", "Pose de victoria ", "Colgante ", "Tarjeta de jugador ", "Pack de ", "Pack ", "Pase premium · "]

sheets = {}


def font(size):
    for name in ("impact.ttf", "arialbd.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def file_name(key):
    return re.sub(r"[^A-Za-z0-9]+", "_", key.encode("ascii", "ignore").decode()) + ".png"


def art(key):
    spot = ART.get(key)
    path = spot and os.path.join(ART_DIR, "hoja_%d.jpg" % spot[0])
    if not spot or not os.path.exists(path):
        return None
    if spot[0] not in sheets:
        sheets[spot[0]] = Image.open(path).convert("RGB")
    x, y = CELL_AT[spot[1] % 3], CELL_AT[spot[1] // 3]
    return sheets[spot[0]].crop((x, y, x + CELL_SIZE, y + CELL_SIZE)).resize((SIZE, SIZE), Image.LANCZOS)


def wrap(draw, text, fnt, width):
    lines, line = [], ""
    for word in text.split():
        trial = (line + " " + word).strip()
        if draw.textlength(trial, font=fnt) <= width or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def icon(item):
    label, accent = "SHOOTERROB", (255, 60, 90)
    for prefix, text, color in STYLES:
        if item["key"].startswith(prefix):
            label, accent = text, color
            break
    title = item["name"]
    for prefix in PREFIXES:
        if title.startswith(prefix) and not item["key"].startswith("Starter:"):
            title = title[len(prefix):]
            break
    title = title.replace(" · ", " ").upper()

    picture = art(item["key"])
    img = picture or Image.new("RGB", (SIZE, SIZE), (16, 16, 20))
    if picture:  # sombra abajo para que el nombre se lea encima del dibujo
        shade = Image.new("L", (1, SIZE), 0)
        for y in range(SIZE):
            shade.putpixel((0, y), int(235 * max(0.0, (y - 300) / 212) ** 0.8))
        img.paste((8, 8, 12), (0, 0, SIZE, SIZE), shade.resize((SIZE, SIZE)))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, SIZE - 1, SIZE - 1], outline=accent, width=8)
    small = font(34)
    width = draw.textlength(label, font=small) + 44
    draw.polygon([(0, 0), (width + 26, 0), (width, 54), (0, 54)], fill=accent)
    draw.text((22, 27), label, font=small, fill=(16, 16, 20), anchor="lm")

    box = 150 if picture else 300  # (alto que puede ocupar el nombre)
    size = 84 if picture else 118
    while size > 34:
        big = font(size)
        lines = wrap(draw, title, big, SIZE - 56)
        widest = max(draw.textlength(line, font=big) for line in lines)
        if len(lines) <= (2 if picture else 3) and widest <= SIZE - 56 and len(lines) * size * 1.05 <= box:
            break
        size -= 4
    step = size * 1.05
    y = (SIZE - 26 - step * (len(lines) - 0.5)) if picture else (270 - (len(lines) - 1) * step / 2)
    for line in lines:
        draw.text((SIZE / 2, y), line, font=big, fill=(255, 255, 255), anchor="mm", stroke_width=4, stroke_fill=(0, 0, 0))
        y += step
    return img


def main():
    catalog = json.load(io.open(os.path.join(HERE, "productos.json"), encoding="utf-8"))
    os.makedirs(OUT, exist_ok=True)
    names, plain = set(), []
    for item in catalog:
        name = file_name(item["key"])
        assert name not in names, name
        names.add(name)
        if art(item["key"]) is None:
            plain.append(item["key"])
        icon(item).save(os.path.join(OUT, name), optimize=True)
    print("%d iconos en assets/tienda/iconos · sin dibujo (solo rótulo): %d %s" % (len(names), len(plain), ", ".join(plain)))


if __name__ == "__main__":
    main()
