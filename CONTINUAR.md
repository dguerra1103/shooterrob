# CONTINUAR · por dónde seguir con SHOOTERROB

Este es el documento de entrada. Léelo primero; lo demás cuelga de aquí.

## Estado en una frase

Shooter 5v5 completo en código (Luau + Rojo), ya **probado en Roblox Studio** (antes solo con pruebas
fuera del motor), con **las 21 armas modeladas en Blender** dentro del juego y **60 iconos
propios**. Falta probar en un móvil real, medir rendimiento y pulir lo que se lista abajo.

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Código del juego | `src/` (`shared`, `server`, `client`, `first`), montado por `default.project.json` |
| Place para abrir en Studio | `ShooterRob.rbxlx` (se regenera con `rojo build -o ShooterRob.rbxlx`) |
| Armas: scripts de Blender | `tools/blender/weapons/<arma>.py` |
| Armas: archivos (.blend, .fbx, .glb, renders) | `assets/weapons/<Arma>/` |
| Armas: galería | `assets/weapons/_gallery/` (`01_poster.jpg`, `00_coleccion.jpg`, capturas `en_roblox_*`) |
| Armas: datos que usa el juego | `src/shared/WeaponMeshes/<Arma>.luau` (generados, no editar) |
| Armas: cómo se montan en el juego | `src/shared/WeaponMeshKit.luau` |
| Efectos de cada arma (llamaradas, luces) | `src/client/Modules/WeaponFX.luau` (tabla `WeaponFX.Weapons`) |
| Iconos | `assets/icons/` (PNG) y `src/shared/Icons.luau` (ids de Roblox) |
| Herramientas para Studio | `tools/studio/` (ver su `README.md`) |
| Pruebas automáticas | `tests/` (`check.sh`, `run_all.sh`; ver `tests/README.md`) |
| Informe de la misión 3D | `MISION_3D_INFORME.md` |
| Informe de estabilización de mapas | `ESTABILIZACION_INFORME.md` (evidencia en `assets/maps/diagnostico/`) |
| Repaso automático de cada mapa | `src/server/Modules/MapCheck.luau` |
| Economía, flujo de pantallas, mapas | `ECONOMY.md`, `UI_FLOW.md`, `MAP_DEVELOPMENT.md` |
| Historial de fases anteriores | `FASE_*.md`, `NEXT_STEPS.md` (anterior a las pruebas en Studio) |

## Cómo se trabaja

Herramientas (no están en el PATH): `export PATH="$HOME/.aftman/bin:$PATH"` (rojo, lune, luau-lsp).

1. **Cambiar código** en `src/`.
2. **Comprobar fuera de Studio:** `tests/check.sh` y la prueba que toque (`tests/run_all.sh <nombre>`).
3. **Ver en Studio:** con `ShooterRob.rbxlx` abierto,
   `cd tools/studio && node sync.js && node run.js sync.json`, y luego una lista de pasos con capturas
   (ejemplos en `tools/studio/README.md`).
4. **Antes de commitear:** `rojo build -o ShooterRob.rbxlx` y `tests/run_all.sh` completo.

### Armas nuevas (o retocar una)

```bash
"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/build_weapon.py -- arx27          # renders de diagnóstico
"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/build_weapon.py -- arx27 --final  # renders finales
python -X utf8 tools/blender/to_luau.py ARX27                      # datos para el juego
python -X utf8 tools/blender/register.py ARX27:Pulse               # solo la primera vez (registro + paleta)
```

- El modelo se escribe en coordenadas del juego (X derecha, Y arriba, el cañón hacia -Z) con el kit
  `tools/blender/sr_kit.py`. Los puntos `Muzzle`, `AimPoint`, `RightHand`, `LeftHand` tienen que
  coincidir con los de `Weapons.luau`.
- Para encargar un arma a un subagente: `tools/blender/BRIEF.md` es el encargo completo.
- Los renders salen en PNG; pásalos a JPEG (calidad 92) para no engordar el repo.
- Las paletas de fábrica están en `Weapons.luau` (`CLASSIC_PALETTES` y `CLASSIC_LOOK`).

### Probar armas en partida

```bash
cd tools/studio
node mk.js qa_on.json Edit qa_on.luau && node run.js qa_on.json   # modo QA, solo en la copia de Studio
node weapontest.js HavocPump Signal7 && node run.js weapontest.json
```

Deja `wt_<Arma>_1..4.png`: reposo, disparo, apuntando y recarga.

## Lo que hay que saber (comprobado en el motor)

- **No se puede subir una malla desde script** en esta versión de Studio, y las mallas dinámicas tienen
  un límite de 8 en el cliente. Por eso las armas viajan como bloques, cuñas y cilindros que el servidor
  funde al arrancar. En el juego **no hay chaflanes**; para tenerlos hay que importar los `.fbx` a mano.
- **Los personajes de Roblox ya no usan Motor6D** sino `AnimationConstraint`: `C0` es de solo lectura,
  se escribe `Transform`.
- **Las pruebas con mock no bastan:** los fallos de esta etapa (pantalla colgada, espectador en la
  primera ronda, lobby sin personaje, iconos vacíos) solo salieron al ejecutar en Studio.
- **El modo QA** (`GameConfig.QA.Enabled`) solo funciona en Studio y no se deja activado en el repo.
  Ojo: `sync.js` vuelve a apagarlo en Studio si cambia `GameConfig.luau`; hay que repetir `qa_on`.
  Con él se fuerza mapa y modo (`NextMatch`, solo surte efecto en el descanso entre partidas) y se
  equipa cualquier arma (`Weapon`).
- **El terreno de Roblox queda 2 studs por encima** del bloque que se rellena (`Terrain:FillBlock`);
  `TacKit.terrain` ya lo compensa.
- **La ropa en capas del avatar oculta el cuerpo** aunque se esconda el accesorio: los trajes la quitan.
- **Los bots calculan ruta con radio 2 y, si no hay, con radio 1** (puertas de 4-5 studs); si en un
  mapa el 2 falla siempre, pasan a probar antes el 1.
- **La malla de navegación no sube rampas de más de ~30°**: `G.stairs` pone un enlace de ruta en las de
  más de 27°. Y tarda unos segundos en existir tras construir el mapa.
- **Cada mapa se repasa al construirse** (`MapCheck`): sombras de contacto, caras coplanarias, puntos de
  aparición dentro de objetos y rutas. Si algo falla, sale `[MapCheck]` en la consola del servidor.
- **Dos sesiones en el mismo Studio se cortan las pruebas**: cerrojo `tools/studio/.studio.lock`
  (ver `tools/studio/README.md`).
- **ForgeGUI** (plan gratis) quedó sin créditos y no deja generar 3D. Los iconos nuevos se generan con
  ChatGPT (hojas de 15 con fondo transparente) y se recortan con `assets/icons/slice.py`.

## Pendiente, por orden de impacto

1. **Móvil real:** nada de lo nuevo se ha probado en un teléfono ni se ha medido (FPS, memoria).
2. **Ver las armas en movimiento:** bomba, cerrojo, corredera y los golpes cuerpo a cuerpo solo se han
   visto en fotos fijas. Y recorrer los mapas enteros tras bajar el terreno 2 studs (medidos los nueve
   desde la base: correcto; no se han revisado los bordes).
3. **Pasar a mallas con chaflán:** importar a mano un `.fbx` con el importador 3D de Studio y decidir.
4. **Equilibrio visual de las armas en primera persona:** algunos visores son altos (Phantom, Titan) y
   la Ballesta ocupa mucho ancho.
5. **Animaciones propias** (AnimationIds): las armas usan las animaciones por código.
6. **Iconos sin colocar** y rangos/precios que siguen con emoji dentro de frases.
7. **Texto de muerte:** roza la ficha del líder de arriba; y la Katana no se ha visto en la mano en partida.
8. **Monetización:** crear los productos en el Creator Dashboard (todos los ids están a 0).
9. **Temporada 2 del pase** antes del 1 de enero de 2027; el evento de Halloween se apaga el 4 de
   noviembre de 2026.
10. **Mapas (ver `ESTABILIZACION_INFORME.md`, sección 4):** plataformas altas de Rooftop District sin
    ruta para los bots, puntos por recolocar en Construction e Industrial Yard, y toda la mejora visual
    (óxido de contenedores, variantes de noche muy oscuras) sin empezar.
11. **Multijugador:** nunca ha habido dos clientes en la misma partida (el MCP solo arranca uno).
12. **Rendimiento:** Terminal, Mall Rush y Dockyard pasan de 230 000 triángulos en escena en Studio.

## Reglas que se han seguido

- Nada se publica solo: el push solo construye y valida; publicar es manual en GitHub Actions.
- Sin force push. Etiqueta de recuperación anterior a las armas: `recovery/pre-mision-3d`.
- No se sustituye un sistema que funciona por un prototipo: los modelos nuevos tienen siempre de
  respaldo las piezas antiguas.
