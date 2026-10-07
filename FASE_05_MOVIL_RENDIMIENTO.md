# FASE 5 — Móvil y rendimiento

> **Sin Roblox Studio ni dispositivos.** Esta fase es una auditoría del código y unos pocos arreglos
> pequeños con pruebas. **No hay mediciones de FPS** y no se promete ninguna cifra: los números de
> rendimiento hay que sacarlos en Studio y en un móvil real (sección E).

## A. Lo que ya había (y se ha comprobado)

| Área | Estado |
|---|---|
| Niveles de calidad | Un solo sistema: `Settings` (Auto, Baja, Media, Alta, Ultra) → `ClientState.EffectiveQuality`. «Auto» = Baja en dispositivos solo táctiles y Media en PC. **No se ha creado ningún sistema paralelo.** |
| Qué recorta Baja | Partículas del mapa (×0), fuegos del mapa, sombras de los focos, detalles pequeños del mapa (`HIDE_BELOW`), casquillos, marcas de bala (0), humo del fogonazo y del cañón, partículas de impacto (×0,4) y del fogonazo (×0,5), chispas de la baja, siluetas 3D de la lista de bajas (pasan a texto). |
| Qué **no** recorta nunca | El hitmarker, el aviso de baja, el número de daño, los nombres e indicadores del enemigo, los objetivos y los sitios A/B, la mira, el minimapa y la lista de bajas (en Baja, con texto). Revisado en `HUD`, `CombatFX`, `RewardFX` y `Effects`. |
| Tope de móvil | `WeaponFeel.MobileCap`: aunque la calidad sea alta, en un móvil no hay casquillos, hay como mucho 20 marcas de bala y las partículas de impacto bajan a ×0,6. |
| HUD táctil | `TouchLayout`: disposición propia para teléfono (racimo alrededor del salto, disparar grande de 76, el resto de 52 y los de poco uso de 40). Controles: disparar, apuntar, recargar, deslizar o agacharse, cambiar de arma, correr, cuchillo, granada, ataque aéreo, marcador, emotes y grafiti; el joystick y el salto son los de Roblox. Se revisó que ningún botón pisa a otro. Tablet con su desplazamiento. **No se han rehecho** (ya funcionaban). |
| Bucles por fotograma | Revisados los ~40 (`RenderStepped`, `Heartbeat`, `BindToRenderStep`). Ninguno recorre todo el `workspace` cada fotograma ni crea objetos cada fotograma. La mayoría tiene salida rápida en el menú o va a 4-30 Hz. |
| Conexiones | Las pantallas del flujo (Armamento, Despliegue, Resultados, Revelado, vista previa 3D) desconectan su bucle al cerrarse. No se han encontrado conexiones que se queden colgando. |
| Luces | Las fases 3-4 no añadieron ninguna luz. Las sombras de los focos solo existen en Alta y Ultra. |
| Responsive (menús) | El flujo nuevo usa tres diseños (`C.Breakpoint()`: PHONE, TABLET, DESKTOP) y un `UIScale` según la altura de la pantalla (`C.root`). Su ScreenGui usa la zona segura de Roblox (`ScreenInsets = CoreUISafeInsets`). |
| Responsive (HUD) | El HUD de partida coloca las piezas con `Offset` y una disposición propia de teléfono (`phone`). Ocupa la pantalla entera (`IgnoreGuiInset`) y **no** respeta la muesca. Ver la sección E. |
| Vistas 3D (ViewportFrames) | En partida: los iconos de las 3 ranuras de arma (se rehacen solo al cambiar de arma o de skin) y las siluetas de la lista de bajas (en Baja, texto). Las de los menús (vista previa del operador, tienda, resultados) se apagan al cerrar su pantalla. |

## B. Arreglos de esta fase

| # | Dónde | Antes | Ahora |
|---|---|---|---|
| 1 | `Killcam.Record` (20 veces por segundo, en el menú también) | Quitaba la muestra más vieja con `table.remove(list, 1)` en cada muestra: desplazaba la lista entera (~120 entradas) por cada jugador o bot, 20 veces por segundo. | Lo viejo se quita de golpe cuando sobra más de un segundo (`table.move`, una vez por segundo). Siempre cubre los 6 s de historial; la repetición (2,4 s) no cambia. |
| 2 | `HUD` (cada fotograma) | Reescribía el nombre del arma y el aviso de recarga cada fotograma, aunque no cambiaran, y los 4 textos sin arma cada fotograma mientras estás muerto. El propio archivo ya explica que cada escritura de texto recoloca la interfaz. | `setText`: solo escribe si el texto cambia. |
| 3 | `HUD` mira (cada fotograma) | Movía las 4 rayas de la mira cada fotograma. | Solo cuando cambia la apertura o si se ven o no. Quieto y sin disparar, no se tocan. |

No cambia nada de lo que se ve.

## C. Pruebas

- `rendimiento` (nueva): el historial de la killcam está en orden y sin huecos, cubre su tiempo, no
  crece sin límite, la última muestra es la posición actual y la interpolación sigue funcionando.
- `hudclient`, `killcam` y `finalkillcam` siguen pasando (comportamiento del HUD y de las dos
  killcams sin cambios).

## D. Candidatos que no se han tocado (poco beneficio para el riesgo, o hay que medir antes)

1. `Minimap` (30 Hz): busca el `UICorner` y la letra de cada punto en cada pasada. Se podría guardar
   en una tabla.
2. `WorldFX`: escucha `DescendantAdded` en todo el `workspace` (huellas y efectos también pasan
   por ahí). Se podría limitar a `workspace.Map`, pero no se ha comprobado que todas las piezas
   animadas vivan dentro del mapa.
3. `HUD`: la barra de munición (`AmmoFill`) se redimensiona cada fotograma; solo cambia al disparar
   o recargar.
4. `Killcam.Record` sigue grabando en el menú. Puede que la killcam final lo necesite, así que no se ha
   cortado.
5. **Muesca del teléfono (HUD):** si en un iPhone apaisado la vida, la munición o la lista de bajas
   quedan bajo la muesca, el arreglo es separar el HUD en dos ScreenGui: la información con
   `ScreenInsets = DeviceSafeInsets` y los velos de pantalla completa (visor, viñeta de daño) sin
   zona segura. Cambiar el HUD entero de golpe dejaría una franja sin cubrir por el visor. Los
   botones táctiles se colocan alrededor del salto de Roblox, así que no se tocan sin verlos en un
   dispositivo.

## E. Medir en Studio y en un móvil (pendiente)

1. **MicroProfiler (Ctrl+F6)** en una partida 5v5 con bots en Construction, Coastal y Mall Rush:
   apuntar el tiempo de `RenderStepped` y `Heartbeat` del cliente. Comparar Baja y Alta.
2. **Developer Console → Memory**: la memoria de `Instances` y `PlaceMemory` tras 5 partidas
   seguidas (que no suba de partida a partida).
3. **Developer Console → Scripts**: actividad de `HUD`, `Killcam`, `Minimap` y `WorldFX`.
4. **Móvil real (Android modesto y un iPhone):**
   - calidad Auto (debe quedar en Baja);
   - FPS en un tiroteo de 5 contra 5;
   - temperatura tras 15 minutos;
   - botones táctiles alcanzables con los pulgares;
   - que el hitmarker, la mira y los avisos de baja se ven en Baja.
5. **Device Emulator:** iPhone SE (pantalla pequeña), un teléfono apaisado grande y un iPad, con el HUD
   de partida.
6. **Muesca:** un iPhone con muesca (por ejemplo, un iPhone 14), apaisado hacia los dos lados. Que la
   vida, la munición, el minimapa y la lista de bajas no queden tapados (sección D.5).
