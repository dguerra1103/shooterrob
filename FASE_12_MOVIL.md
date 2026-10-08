# FASE 12 — HUD e interfaz móvil

Rehacer cómo se juega con el teléfono, **sin features, modos, mapas ni armas nuevos**. Daño, retroceso,
cadencia, equilibrio, economía, mapas, pase, bots, asistencia de apuntado y ProductIds (todos en `0`)
no se han tocado.

**Nada de esto se ha probado todavía en un móvil ni en Studio.** Todo se ha medido con el código, con
las pruebas Lune y con capturas del árbol de interfaz renderizado a HTML (con el salto y el joystick de
Roblox dibujados donde los pone Roblox). Que los pulgares estén cómodos **solo se puede saber jugando
en un móvil**: las pruebas comprueban la lógica y la geometría, no la ergonomía.

## A. Auditoría (cómo estaba)

Capturas a 844×390, 667×375, 932×430, 1024×768 y con el francotirador:

| Problema | Dónde |
|---|---|
| Centro sucio: nombre del arma, munición y «🔄 Recargar» justo debajo de la mira | HUD (panel del arma) |
| Habilidades como tres cuadrados grandes de colores con emoji, abajo en el centro | Abilities |
| Nueve círculos iguales con emoji a la derecha; disparar casi no se distinguía; correr flotando a media pantalla | TouchLayout |
| El dedo que dispara no podía girar la cámara (el botón se «comía» el toque) | TouchLayout |
| Botones de arriba a la derecha encima del registro de bajas; registro con texto de ~10 px | HUD/TouchLayout |
| Botón naranja «TIENDA» bajo el minimapa durante el combate | Menu |
| Marcador grande, fila de fotos y el «#1» encima de la línea del modo | HUD |
| «¡DOBLE BAJA!» a media altura a la izquierda; banderas A/B/C dentro del centro | HUD, DominationHUD |
| Tablet: el grupo de botones **encima del botón de saltar de Roblox** y el panel del arma pisándolo | posiciones fijas que ignoraban dónde está el salto |
| Iconos: emojis (cada móvil los dibuja distinto) mezclados con texto | todos los botones |

Lo que ya estaba bien y se ha conservado: la zona segura (con `IgnoreGuiInset` la interfaz va dentro
de `DeviceSafeInsets`), la máscara de la mira telescópica a pantalla completa (Fase 11), el hitmarker
y el indicador de daño, la asistencia de apuntado.

## B. Disposición por defecto

Todo sale de **`src/shared/MobileHUD.luau`** (lógica pura; el servidor la usa para validar).

- **Los botones de la derecha se miden desde el centro del botón de saltar de Roblox**, que no es
  nuestro y cambia de sitio y tamaño (70 px con el lado corto ≤ 500, 120 px en el resto; fórmula de
  `PlayerModule/TouchJump`). Se lee **el botón real** (`TouchGui.TouchControlFrame.JumpButton`) cuando
  existe; si no, la fórmula. Así nada lo pisa en ninguna pantalla.
- Los de la izquierda (habilidades, correr con botón, disparo izquierdo) se miden desde la esquina de
  abajo, **por encima del joystick**; los de poco uso desde arriba a la derecha.
- El **centro queda libre**: radio `0,17 × lado corto` (mira, hitmarker, indicadores de daño).

| Control | Papel | Tamaño (PHONE) | Dónde |
|---|---|---|---|
| Disparar | Principal | **84** (zona táctil ×1,25) | a la izquierda y por encima del salto |
| Apuntar | Principal | 56 | encima del salto, a la derecha del todo |
| Agacharse / deslizar | Acción | 50 | a la izquierda del salto, abajo |
| Recargar | Acción | 48 | junto a la tarjeta del arma |
| Granada | Acción (se apaga al apuntar) | 48 | arriba a la izquierda de disparar |
| Ataque aéreo | Acción (solo con cargas) | 46 | arco de arriba |
| Cuerpo a cuerpo | Acción (se apaga al apuntar) | 46 | encima de apuntar |
| Cambiar arma | Tarjeta 136×50 (128 en la Fase 12) | nombre, «30 / 120» y «1/2» | abajo, a la izquierda de agacharse |
| Impulso, supersalto, poción | Acción | 46 | fila sobre el joystick |
| Correr (solo con «Con botón») | Acción | 46 | misma fila |
| Disparo izquierdo (opcional) | Principal | 64 | encima de la fila de habilidades |
| Menú, grafiti, emotes, marcador | Poco uso (70 % de opacidad) | 38 | arriba a la derecha |

Jerarquía sin leer texto: disparar es el más grande y el más opaco; apuntar el segundo; el resto más
pequeño y algo más transparente; los de poco uso, pequeños y arriba. Fondo grafito translúcido con
borde blanco fino y **pictogramas dibujados con formas** (`TouchIcons.luau`: bala, mira, chevrón,
cargador, granada, cuchillo, engranaje…), sin emojis ni imágenes subidas (no se ha inventado ningún
AssetId). Estados con color: apuntando **amarillo**; pocas balas **naranja**; cargador vacío **rojo y
un 10 % más grande**, sin parpadeo; recarga de habilidad con un velo que baja y los segundos.

Resto del HUD en táctil (`HUD.luau`, se recoloca cada vez que cambian los botones):
- **Munición en la tarjeta del arma**, junto a recargar. El centro ya no tiene nada.
- **Vida** abajo en el centro con la barra de XP y la racha encima: se busca la posición más baja y
  centrada que no toque ningún botón (ni el salto).
- **Registro de bajas** bajo los botones de arriba a la derecha: texto de 14 px sin encoger, filas de
  19 px, 3 filas si caben sin llegar al grupo de la derecha (2 en pantallas muy bajas o con el ataque
  aéreo visible), y desaparece a los 5 s.
- **Marcador compacto** (EQUIPO A · TIEMPO · EQUIPO B, ×0,72 en teléfono) sin la fila de fotos; la
  línea del modo a 13 px. El marcador completo está en su botón.
- **Aviso de baja y medallas** arriba, bajo el marcador, sin pisar el registro de bajas ni el minimapa.
- **Dominio**: las banderas A/B/C bajo el minimapa (o a su derecha si tocarían las habilidades).
- **Menú**: en táctil el botón naranja «TIENDA» ya no sale en partida; el menú (tienda, ajustes…)
  se abre con el engranaje de arriba a la derecha.

## C. Toques y multitáctil

- Cada botón sigue a **su dedo** (`InputObject`) hasta que lo suelta, aunque salga del botón: se puede
  mover + apuntar + disparar, o saltar + disparar + girar la cámara, a la vez.
- **Disparar arrastrando** (por defecto, `FireDrag`): la zona de disparar es un `Frame` no activo, así
  que **el toque no se lo come**: la cámara gira con el mismo dedo que dispara (como en los shooters de
  móvil). El disparo se detecta con `UserInputService.InputBegan` (toques no procesados) dentro del
  círculo de la zona. Con «Solo tocar» es un botón normal.
- Un dedo que **empieza en la cámara** sigue siendo de la cámara: los botones solo reaccionan al
  empezar el toque, no cuando un dedo pasa por encima.
- Si un menú se abre con un dedo encima de un botón, el botón **se suelta** (no se queda disparando).
- Respuesta al tocar: el botón baja al 90 % en 0,08 s y su fondo se vuelve más opaco.
- **Correr**: «Auto (joystick a fondo)» por defecto. Corre con el joystick casi en el borde (≥ 0,9,
  leído de `PlayerModule:GetControls():GetMoveVector()`; `MoveDirection` siempre mide 1) y hacia
  delante; no corre apuntando. «Con botón» enseña el botón de correr (interruptor, como antes).
- **Agacharse** reutiliza el deslizamiento que ya existía (corriendo desliza; parado se agacha).
- **Disparo izquierdo** opcional (apagado por defecto): el mismo disparo en un botón a la izquierda.
- Granada: mantener para cocinar y soltar para lanzar (el globo enseña la mecha); su recarga, con el
  velo. Ataque aéreo: el globo enseña las cargas (x2).
- Al apuntar, lo secundario (granada, cuerpo a cuerpo, habilidades, poco uso) baja al 45 % de
  opacidad; nada se esconde. Con el francotirador los controles siguen ahí y la máscara cubre toda la
  pantalla (sin franja en la muesca, Fase 11).

## D. Zona segura y la interfaz de Roblox

- Todas las pantallas táctiles usan `IgnoreGuiInset = true`, que pone `ScreenInsets =
  DeviceSafeInsets`: lo de dentro queda fuera de la muesca, la Dynamic Island, el agujero de la cámara
  y la barra de inicio. No se ha inventado ninguna API.
- Arriba a la izquierda (botón de Roblox y chat) no hay nada nuestro: el minimapa empieza en y = 60.
- Los botones se recolocan si cambia el tamaño de la pantalla, si gira, o si el salto de Roblox se
  mueve más de 2 px (revisado 10 veces por segundo, sin coste si no cambia).

## E. Tipos de pantalla (responsive)

Cuatro tipos y una **unidad** por tipo que multiplica todas las distancias y tamaños (todo en
píxeles de teléfono): `PHONE_SMALL` (lado corto < 360) ×0,8 · `PHONE` (≤ 500) ×1 · `TABLET` ×1,3 ·
`DESKTOP` (sin pantalla táctil: sin botones). Las posiciones guardadas por el jugador son fracciones de
la pantalla, así que valen al cambiar de móvil o girarlo.

## F. Editor de HUD

Ajustes → **🎮 Controles táctiles** → **PERSONALIZAR HUD** (`HUDEditor.luau`):
- Se ven todos los controles (también los apagados, marcados «(apagado)») con su nombre, sobre el
  juego oscurecido. Mientras está abierto **no se juega** (`ClientState.HUDEditorOpen`).
- Tocar elige; arrastrar mueve; **TAMAÑO** (60–160 %) y **OPACIDAD** (25–100 %) con dos barras;
  **RESTABLECER** (lo de fábrica), **CANCELAR** (como estaba), **GUARDAR**. El panel se pasa abajo con
  ABAJO/ARRIBA para llegar a lo que tapa.
- Se guarda en **los ajustes del perfil** (`Settings.HudLayout`, con el resto de ajustes; **no hay
  DataStore aparte**). El cliente y el servidor lo limpian con `MobileHUD.Validate`: solo controles
  conocidos, números finitos, recortados a sus límites y la posición por parejas X/Y.
- En la misma sección: correr (Auto / Con botón), disparar (Arrastrar para apuntar / Solo tocar) y
  disparo izquierdo (No / Sí).

La disposición por defecto no depende del editor: está pensada para jugar sin tocarlo.

## G. Menús en móvil

Revisados a 844×390: inicio (JUGAR grande arriba a la izquierda, nivel y personaje, armamento,
operador, tienda y pase en la columna), armamento (arma grande y estadísticas legibles), tienda
(tarjetas grandes, precio claro, COMPRAR separado y **confirmación aparte** para monedas), pase
(desplazamiento horizontal), resultados (VICTORIA/DERROTA, marcador, MVP, XP, JUGAR DE NUEVO y el
marcador completo en su botón). Ya estaban adaptados (fases 4, 5 y la economía); **no se han cambiado**.
Lo único nuevo en menús es la sección de controles táctiles en Ajustes.

## H. Rendimiento

- Botones: nada por fotograma. Estados (apuntando, recarga necesaria, salto movido) 10 veces por
  segundo y solo se escribe si cambian. Los iconos solo se redibujan si cambia su tamaño.
- HUD táctil: la tarjeta del arma compara los valores en bruto y solo crea textos cuando cambian; la
  colocación de vida, registro y avisos solo al recolocar los botones.
- Los ajustes de controles solo recolocan cuando cambian de verdad (antes de este cambio, cada
  actualización de datos del perfil los habría recolocado).
- Sin `UIGradient`, `ViewportFrame` ni bucles de tween nuevos en los botones. En calidad Baja el HUD
  está completo (el registro de bajas usa texto en vez de la silueta 3D del arma, como ya hacía).

## Depuración (solo Studio)

`GameConfig.MobileHUDDebug = false` por defecto. Puesto a `true` (y **solo dentro de Studio**) dibuja:
la zona segura con la resolución y el tipo de pantalla, el centro libre, la zona de cámara del pulgar
derecho y la zona táctil de cada botón. Los jugadores nunca lo ven.

## I. Pruebas automáticas

| Prueba | Qué comprueba |
|---|---|
| `mobilehud` | Tipos de pantalla; controles sin repetir y con icono; tamaños tocables hasta en PHONE_SMALL; ajustes por defecto; validación (rangos, NaN/∞, basura, X/Y por parejas); disposición completa en 7 resoluciones; posiciones propias relativas a la pantalla |
| `touchbtns` | Cada control existe una vez; jerarquía; zona de disparar mayor que el dibujo; sin solaparse; fuera del centro; visibilidad por ajustes y cargas; disparar deja pasar el toque; un menú suelta el disparo y esconde los botones; apuntar marca y apaga lo secundario; recarga resaltada; tarjeta, recargas y globos; disposición propia aplicada y validada; restablecer; editor |
| `hudeditor` | Abrir bloquea el juego; mover, tamaño y opacidad con topes; nunca fuera de la pantalla; CANCELAR no guarda; GUARDAR va a los ajustes y al servidor; el servidor recorta y descarta basura; RESTABLECER |
| `phonefx` | (actualizada) ningún botón pisa a otro, al salto ni a la mira en 5 resoluciones |

Las pruebas Lune **no demuestran que sea cómodo**: comprueban posiciones, estados y datos.

**Resultado de la batería completa**: al terminar la fase, 149 OK y 1 fallo real (`movement`:
`ClientState.Settings` nil en el primer fotograma del correr automático), corregido en `cd08415`. Sobre
`cd08415`, `tests/run_all.sh` completo: **150 OK, 0 fallos**. Los arreglos posteriores y su resultado
están en `FASE_13_VALIDACION_MOVIL.md`.

## J. Matriz de resoluciones (Studio → Device Emulator)

Marcar en cada una: ☐ ningún botón tapa a otro ni al salto · ☐ mira y centro libres · ☐ la vida no
toca la tarjeta · ☐ registro de bajas legible y sin tapar botones · ☐ nada debajo de la muesca ·
☐ el editor se abre, guarda y restablece.

| Dispositivo | Resolución (puntos) | Tipo | Revisado |
|---|---|---|---|
| iPhone SE (1.ª) / estrecho | 568×320 | PHONE_SMALL | ☐ |
| iPhone 8 | 667×375 | PHONE | ☐ |
| iPhone 14 / 15 (muesca, Dynamic Island) | 844×390 / 852×393 | PHONE | ☐ |
| iPhone Pro Max | 932×430 | PHONE | ☐ |
| Android 20:9 (agujero de cámara) | 800×360 · 1080×480 | PHONE | ☐ |
| Móvil 16:9 | 640×360 | PHONE | ☐ |
| iPad 4:3 | 1024×768 · 1180×820 | TABLET | ☐ |
| Ordenador | 1920×1080 | DESKTOP (sin botones) | ☐ |

## Pruebas a mano (en un móvil de verdad)

| Prueba | Qué mirar |
|---|---|
| CORRER + APUNTAR | Con «Auto», al apuntar deja de correr; el joystick no se suelta |
| CORRER + DISPARAR | Disparar con el pulgar derecho mientras se corre; el dedo gira la cámara |
| APUNTAR + DISPARAR | Apuntar (interruptor) y disparar a la vez; lo secundario se apaga un poco |
| SALTAR + DISPARAR | Salto de Roblox y disparar sin pulsar uno por otro |
| AGACHARSE + APUNTAR | Agacharse parado; deslizar corriendo |
| RECARGAR | Cargador vacío: recargar en rojo y algo más grande, sin parpadeo; la tarjeta dice RECARGANDO… |
| CAMBIAR ARMA | Tocar la tarjeta; cambian nombre, munición y «1/2» |
| LANZAR GRANADA | Mantener (mecha en el globo), soltar; la cámara no se bloquea |
| MELEE | El cuchillo no se pulsa sin querer al girar la cámara |
| SNIPER SCOPE | Máscara a pantalla completa (sin franja en la muesca); disparar y apuntar siguen accesibles |
| Escopeta desde la cadera, subfusil corriendo + saltando + disparando | Sin pulsaciones fantasma |
| Morir y reaparecer | Los botones vuelven; apuntar no se queda marcado |
| Menú en partida | El engranaje abre el menú; los botones se esconden y vuelven al cerrar |

## Archivos

Nuevos: `src/shared/MobileHUD.luau`, `src/client/Modules/TouchIcons.luau`,
`src/client/Modules/HUDEditor.luau`, `tests/harness/mobilehud.luau`, `tests/harness/hudeditor.luau`.
Rehechos: `TouchLayout.luau`, `tests/harness/touchbtns.luau`. Cambiados: `HUD.luau`, `Abilities.luau`,
`Movement.luau` (correr automático), `Menu.luau` (sección de controles, botón de menú),
`DominationHUD.luau`, `Settings.luau`, `ClientState.luau` (`HUDEditorOpen`), `GameConfig.luau`
(`AutoSprint`, `LeftFire`, `FireDrag`, `HudLayout`, `MobileHUDDebug`), `PlayerData.luau` (validación),
y los que llamaban a `SetTitle` con emojis (arma, granada, ataque aéreo, marcador, emotes, grafiti).

## Pendiente / a revisar en Studio

1. Pasar la matriz de resoluciones y las pruebas a mano en un móvil de verdad (y con el Device Emulator).
2. ~~Nombre del arma en dos líneas~~: resuelto en la Fase 13 (una línea medida con `TextService`,
   mínimo 11 px y «…»). Falta verlo en el motor.
3. Si alguien lo pide, iconos con imagen propia: bastaría con subirlos y cambiar `TouchIcons`; ahora
   son formas (no hay AssetIds inventados).
4. Ajustar distancias jugando (todas en `MobileHUD.Controls`, en píxeles de teléfono).

La validación (matriz, checklists de Studio, teléfono, multitáctil y editor, y la tabla de ergonomía)
está en **`FASE_13_VALIDACION_MOVIL.md`**.
