# Corta una hoja de iconos con fondo transparente en iconos sueltos de 256x256.
#   python assets/icons/slice.py assets/icons/src/sheet1.png helmet,rifle,squad,... [hueco]
# hueco = píxeles transparentes que separan dos iconos (6 por defecto; más si un icono tiene piezas sueltas).
# Detecta las filas y columnas por los huecos transparentes entre iconos.
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SIZE = 256
PAD = 16


def bands(mask, min_gap=6):
    """Tramos consecutivos con contenido en un perfil 1D (huecos pequeños se unen)."""
    out, start, gap = [], None, 0
    for i, on in enumerate(mask):
        if on:
            if start is None:
                start = i
            gap = 0
        elif start is not None:
            gap += 1
            if gap > min_gap:
                out.append((start, i - gap + 1))
                start, gap = None, 0
    if start is not None:
        out.append((start, len(mask)))
    return out


def save(icon, path):
    scale = (SIZE - 2 * PAD) / max(icon.size)
    icon = icon.resize((max(1, round(icon.width * scale)), max(1, round(icon.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(icon, ((SIZE - icon.width) // 2, (SIZE - icon.height) // 2), icon)
    canvas.save(path)


def main():
    sheet = Path(sys.argv[1])
    names = sys.argv[2].split(",")
    out_dir = sheet.parent.parent
    image = Image.open(sheet).convert("RGBA")
    alpha = np.array(image)[..., 3] > 24
    if len(sys.argv) > 3 and "x" in sys.argv[3]:
        # Modo rejilla ("5x3"): celdas iguales; para hojas donde los iconos casi se tocan
        cols, rws = (int(v) for v in sys.argv[3].split("x"))
        h, w = alpha.shape
        row_bands = bands(alpha.any(axis=1), 2)
        if len(row_bands) != rws:
            row_bands = [(h * r // rws, h * (r + 1) // rws) for r in range(rws)]
        index = 0
        for y0, y1 in row_bands:
            # Cortes entre columnas: la columna de píxeles más vacía cerca de cada frontera esperada
            density = alpha[y0:y1].sum(axis=0)
            cuts = [0]
            for c in range(1, cols):
                mid, span = w * c // cols, w // (cols * 3)
                window = density[mid - span:mid + span]
                best = np.where(window == window.min())[0]
                cuts.append(mid - span + int(best[len(best) // 2]))
            cuts.append(w)
            for c in range(cols):
                x0, x1 = cuts[c], cuts[c + 1]
                cell = alpha[y0:y1, x0:x1]
                ys, xs = np.where(cell.any(axis=1))[0], np.where(cell.any(axis=0))[0]
                save(image.crop((x0 + xs[0], y0 + ys[0], x0 + xs[-1] + 1, y0 + ys[-1] + 1)), out_dir / (names[index] + ".png"))
                index += 1
        print("iconos:", index, "de", len(names))
        return
    gap = int(sys.argv[3]) if len(sys.argv) > 3 else 6
    rows = bands(alpha.any(axis=1), gap)
    index = 0
    for top, bottom in rows:
        for left, right in bands(alpha[top:bottom].any(axis=0), gap):
            if index >= len(names):
                print("sobran iconos en la hoja")
                return
            # (recorte ajustado al icono, por si su fila es más alta que él)
            cell = alpha[top:bottom, left:right]
            ys = np.where(cell.any(axis=1))[0]
            box = (left, top + ys[0], right, top + ys[-1] + 1)
            save(image.crop(box), out_dir / (names[index] + ".png"))
            index += 1
    print("iconos:", index, "de", len(names))


main()
