# Prueba sin conexion de la parte de crear_productos.py que escribe los ids (sobre una copia del archivo):
#   python -X utf8 scripts/monetizacion/prueba_escritura.py
import importlib.util
import io
import os
import shutil
import sys
import tempfile

here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("crear_productos", os.path.join(here, "crear_productos.py"))
cp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cp)

copy = os.path.join(tempfile.mkdtemp(), "ProductIds.luau")
shutil.copy(cp.IDS_FILE, copy)
cp.IDS_FILE = copy
written = cp.write_ids({"Coins:Puñado": 111, "Item:Skin:Inferno": 222, "VIP": 333, "PassPremium:S1": 444, "Coins:Bóveda": 555})
text = io.open(copy, encoding="utf-8").read()
expected = ['["Coins:Puñado"] = 111,', '["Item:Skin:Inferno"] = 222,', "VIP = 333,", '["PassPremium:S1"] = 444,', '["Coins:Bóveda"] = 555,']
ok = written == 5 and all(line in text for line in expected) and text.count(" = 0,") == 39 - 5
print("escritos %d de 5 · %s" % (written, "OK" if ok else "FALLO"))
sys.exit(0 if ok else 1)
