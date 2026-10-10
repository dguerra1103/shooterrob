# Hoja de contacto 2x2 de las capturas de un mapa: python sheet.py <tag> [Mapa ...]
import sys, glob, os
from PIL import Image
tag = sys.argv[1]
maps = sys.argv[2:] or ["Construction","Coastal","Terminal","MallRush","RooftopDistrict","MetroYard","DesertBase","Dockyard","IndustrialYard"]
for m in maps:
    files = sorted(glob.glob("map_%s_%s_*.png" % (tag, m)))
    if not files: continue
    ims = [Image.open(f).convert("RGB") for f in files[:4]]
    w, h = ims[0].size
    sheet = Image.new("RGB", (w, h))
    for i, im in enumerate(ims):
        sheet.paste(im.resize((w // 2, h // 2)), ((i % 2) * (w // 2), (i // 2) * (h // 2)))
    sheet.save("sheet_%s_%s.jpg" % (tag, m), quality=85)
    print("sheet_%s_%s.jpg" % (tag, m))
