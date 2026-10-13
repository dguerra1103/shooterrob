# Monta las imágenes de promoción del juego en assets/promo a partir del arte generado con ChatGPT
# (assets/promo/arte, sin texto):   python -X utf8 scripts/promo/montar.py
#   portadas/  1920x1080 (miniaturas de la experiencia y anuncios): versión limpia y versión con título
#   iconos/    512x512 (icono de la experiencia): versión limpia y versión con título
import glob
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ART = os.path.join(ROOT, "assets", "promo", "arte")
OUT = os.path.join(ROOT, "assets", "promo")
RED = (255, 60, 90)


def font(size):
    for name in ("impact.ttf", "arialbd.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def title(img, x, y, size, anchor_right=False, tagline=None):
    """Escribe SHOOTERROB (ROB en rojo) con borde negro; (x, y) es la esquina superior izquierda."""
    draw = ImageDraw.Draw(img)
    fnt = font(size)
    stroke = max(4, size // 14)
    left = draw.textlength("SHOOTER", font=fnt)
    total = left + draw.textlength("ROB", font=fnt)
    if anchor_right:
        x -= total
    draw.text((x, y), "SHOOTER", font=fnt, fill=(255, 255, 255), stroke_width=stroke, stroke_fill=(0, 0, 0))
    draw.text((x + left, y), "ROB", font=fnt, fill=RED, stroke_width=stroke, stroke_fill=(0, 0, 0))
    if tagline:
        small = font(int(size * 0.3))
        draw.text((x + 4, y + size * 1.12), tagline, font=small, fill=(255, 255, 255), stroke_width=max(3, size // 30), stroke_fill=(0, 0, 0))
    return total


def shade(img, box, strength=150):
    """Oscurece suavemente una zona para que el título se lea."""
    x0, y0, x1, y1 = box
    layer = Image.new("L", (x1 - x0, y1 - y0), 0)
    for y in range(layer.height):
        t = 1 - abs((y / layer.height) * 2 - 1) ** 2
        ImageDraw.Draw(layer).line([(0, y), (layer.width, y)], fill=int(strength * t))
    img.paste((0, 0, 0), (x0, y0), layer)


def main():
    for folder in ("portadas", "iconos"):
        os.makedirs(os.path.join(OUT, folder), exist_ok=True)
    done = 0
    for path in sorted(glob.glob(os.path.join(ART, "portada_*.jpg"))):
        name = os.path.splitext(os.path.basename(path))[0]
        img = Image.open(path).convert("RGB").resize((1920, 1080), Image.LANCZOS)
        img.save(os.path.join(OUT, "portadas", name + "_limpia.jpg"), quality=92)
        shade(img, (0, 0, 1920, 330))
        title(img, 70, 50, 190, tagline="5 CONTRA 5  ·  SKINS  ·  PASE DE BATALLA")
        img.save(os.path.join(OUT, "portadas", name + "_titulo.jpg"), quality=92)
        done += 2
    for path in sorted(glob.glob(os.path.join(ART, "icono_*.jpg"))):
        name = os.path.splitext(os.path.basename(path))[0]
        img = Image.open(path).convert("RGB").resize((512, 512), Image.LANCZOS)
        img.save(os.path.join(OUT, "iconos", name + "_limpio.png"), optimize=True)
        shade(img, (0, 372, 512, 512), 190)
        width = ImageDraw.Draw(img).textlength("SHOOTERROB", font=font(92))
        title(img, (512 - width) / 2, 398, 92)
        img.save(os.path.join(OUT, "iconos", name + "_titulo.png"), optimize=True)
        done += 2
    print("%d imágenes en assets/promo" % done)


if __name__ == "__main__":
    main()
