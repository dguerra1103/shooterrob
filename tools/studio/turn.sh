#!/usr/bin/env bash
# Espera el turno de Studio (cerrojo compartido con la otra sesión), sincroniza lo mío y lanza los pasos.
#   turn.sh salida.txt pasos.json [pasos2.json ...]
cd "$(dirname "$0")"
out="$1"; shift
for i in $(seq 1 90); do
  if [ ! -f .studio.lock ] || [ $(( $(date +%s) - $(stat -c %Y .studio.lock) )) -gt 1200 ]; then break; fi
  sleep 20
done
echo "sesion mapas $(date '+%Y-%m-%d %H:%M')" > .studio.lock
node sync.js src/server/Modules/MapCheck.luau src/server/Modules/MapBuilder.luau src/server/Modules/MapDefs/RooftopDistrict/Geometry.luau src/server/Modules/TacKit/Geometry.luau src/server/Modules/TacKit/init.luau src/server/Modules/Bots.luau src/client/Modules/ScopeSway.luau src/client/Modules/IconText.luau src/client/Modules/HUD.luau src/client/Modules/Flow/Results/Components/RewardsPanel.luau src/server/Modules/Round.luau src/server/Modules/SpawnPicker.luau > /dev/null
node run.js sync.json > sync_out.txt 2>&1
node mk.js qa_on.json Edit qa_on.luau && node run.js qa_on.json >> sync_out.txt 2>&1
: > "$out"
for f in "$@"; do touch .studio.lock; node run.js "$f" >> "$out" 2>&1; done
rm -f .studio.lock
echo "TURNO TERMINADO"
