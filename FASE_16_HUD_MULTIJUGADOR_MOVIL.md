# FASE 16 — HUD móvil en partidas multijugador

Objetivo: que una partida 5v5 en el teléfono (referencia: Galaxy S26 Ultra en horizontal,
`ULTRAWIDE_PHONE`) se pueda jugar sin que los controles ni lo que aparece en la partida se monten.
**Sin cambios de juego**: daño, retroceso, asistencia de apuntado, cadencia, mapas, bots, economía,
monetización, pase y armas siguen igual.

> Comprobado fuera del motor: lógica pura (Lune), un simulador del cliente con 10 jugadores ficticios
> y el renderizador de capturas. **No es multijugador real**: falta jugarlo en Studio y en el teléfono
> (sección 14).

## 1. Problemas reales encontrados

Reproducidos con el detector nuevo y con capturas del peor caso (`intense_*`) del código de la Fase 15:

| # | Problema | Causa |
|---|---|---|
| 1 | **Botones que se pisan al tocar**: 9 choques en todas las resoluciones (disparar con apuntar, con salto y con cuerpo a cuerpo; las tres habilidades entre sí; los cuatro iconos de la tira de arriba entre sí; disparar y agacharse con las cajas del dibujo cortándose) | Las pruebas de la Fase 15 medían **los dibujos como círculos**; la zona que recoge el toque es **una caja** algo mayor (como el botón de Roblox) y esas cajas se cortaban |
| 2 | **3 medallas encima unas de otras**, y «📡 RADAR 20s» encima de una medalla | Medallas con rebote al 160 % y hasta 3 a la vez; el radar con posición fija en el mismo sitio |
| 3 | Estado de la bomba, potenciadores y barra «DESACTIVANDO…» **apilados encima de la mira** | Cada uno con una posición fija (`(0.5, 118)`, `(0.5, 140)`, `(0.5, 0.5 − 30)`) que no conoce a los demás |
| 4 | **Avisos de XP encima de las habilidades** (izquierda) | Posición fija bajo el minimapa; las habilidades estaban debajo |
| 5 | «Reto completado…» **encima de la munición** | Ancho fijo, centrado sin mirar los botones |
| 6 | **«+300» dentro del centro libre** | Contador de puntos al lado de la mira |
| 7 | **Barra de racha vertical de ordenador** visible en táctil al tener racha | `Visible = streak > 0` sobrescribía el «solo en ordenador» |
| 8 | Regalo / evento junto al minimapa **en el sitio del aviso de baja** | Posición fija |
| 9 | Estamina **dentro del centro libre**; consejos pegados a la mira | `(0.5, 0.5 + 44)` y `(0.5, 0.5 + 64)` |
| 10 | Tarjeta de cambiar arma **vacía** con una sola arma al empezar | El estado inicial nunca se escondía |
| 11 | Aviso de baja con **pulso al 150-200 %** en multibajas | Rebote de ordenador, también en el teléfono |

## 2. Inventario del HUD (lo que puede aparecer a la vez en partida)

| Elemento | Módulo | Zona (táctil) | Puede coincidir con |
|---|---|---|---|
| Disparar, apuntar, salto, agacharse, recargar, cuerpo a cuerpo, ataque aéreo, cambiar arma | TouchLayout | BOTTOM_RIGHT (grupo de combate) | todo |
| Granada, impulso, supersalto, poción; correr y disparo izquierdo (opcionales) | TouchLayout | BOTTOM_LEFT | todo |
| Menú, marcador, emotes, grafiti | TouchLayout | TOP_RIGHT (tira) | todo |
| Munición, cambio de arma | HUD | BOTTOM_RIGHT, fuera de las cajas táctiles | todo |
| Vida, racha | HUD | BOTTOM_CENTER (izquierda del centro) | todo |
| Minimapa | Minimap | TOP_LEFT | todo |
| Marcador y tiempo; línea del modo (solo si cambia: en pie, infección...); estado de bandera/zona a los lados | HUD | TOP_CENTER | todo |
| Registro de bajas (3 filas) | HUD | TOP_RIGHT, bajo la tira | todo |
| Banderas A/B/C (DOM) | DominationHUD | TOP_LEFT | radar, zona |
| Estado de la bomba (SND) | BombHUD | TOP_LEFT | radar, zona |
| Radar propio | KillstreakController | TOP_LEFT | objetivo, zona |
| Nombre de la zona del mapa | ZoneName | TOP_LEFT | objetivo, radar |
| «¡Tienes la bandera!» (CTF), avisos de bandera | HUD | TOP_FEED | aviso de baja, medallas |
| Aviso de baja, medallas (≤ 2), avisos de XP | HUD | TOP_FEED | todo lo de arriba |
| Plantando/desactivando (SND) | BombHUD | BOTTOM_NOTICE | avisos, consejos, estamina |
| Avisos de texto, consejos, estamina | HUD, Hints, Movement | BOTTOM_NOTICE | progreso de la bomba |
| Mira, hitmarker, indicadores de daño, «+300» | HUD, DamageIndicator, RewardFX | CENTER (y justo fuera para «+300») | todo |
| Regalos, evento, potenciadores | PlaytimeGifts, EventHUD, BoostHUD | **ocultos en plena pelea** (se ven muerto, en calentamiento y en menús) | — |
| Marcador ampliado, menús, muerte, resultados | Scoreboard, Menu, DeathScreen, Flow | pantalla completa (esconden y sueltan los botones) | — |
| Chat y botones de Roblox | CoreGui | fuera de la zona segura de los botones | — |

## 3. Sistema de zonas

`TOP_LEFT · TOP_CENTER · TOP_RIGHT · CENTER_LEFT · CENTER · CENTER_RIGHT · BOTTOM_LEFT ·
BOTTOM_CENTER · BOTTOM_RIGHT · RIGHT_CAMERA_ZONE`

- Las fijas las colocan quienes ya lo hacían: `MobileHUD` (grupos de los pulgares y la tira),
  `HUD` (marcador, munición, vida, registro de bajas), `Minimap`.
- `MobileHUD.Zones` calcula **CENTER** (centro libre, radio 0,17 × lado corto) y
  **RIGHT_CAMERA_ZONE** (rectángulo sin ningún botón).
- **`HUDZones`** (módulo nuevo y pequeño, **no es otro HUD**) reparte el sitio de lo que aparece y
  desaparece durante la partida en tres zonas apiladas:
  - **TOP_LEFT** bajo el minimapa, hasta la fila de habilidades: objetivo (A/B/C o bomba) → radar →
    nombre de la zona;
  - **TOP_FEED** bajo el marcador, entre el minimapa y el registro de bajas, por encima del centro
    libre: «tienes la bandera» → avisos de bandera → aviso de baja → medallas → XP;
  - **BOTTOM_NOTICE** bajo el centro libre: progreso de plantar/desactivar → avisos → consejos →
    estamina; cada línea usa **el hueco libre entre los botones a su altura** (`MobileHUD.FreeSpan`).
- Reglas: por orden de importancia; **nada encima de la caja táctil de un botón** ni de la munición,
  la vida, el minimapa o el registro de bajas (si choca, baja); lo que no cabe **se aparta** (no se
  monta) hasta que vuelva a caber. Se recoloca 10 veces por segundo y solo escribe si algo cambia.
- `HUDZones.Validate()` dice si algo se pisa, toca un botón o entra en el centro (pruebas y
  depuración).

## 4. Touch rects

- **VISUAL RECT** = `Center ± Size/2` (el dibujo). **TOUCH RECT** = `Center ± Hit/2` (la caja que
  recoge el toque; es la caja del botón, no un círculo).
- Las zonas táctiles son algo mayores que el dibujo (×1,13-×1,2) y en la disposición por defecto dejan
  **al menos 6 px de aire a escala 1** entre cajas (mínimo exigido `MinTouchGap` = 4 px, también en
  568×320).

## 5. Detector de solapes

- `MobileHUD.Collisions(layout, ids, gap)` → `{ A, B, Kind = "Visual" | "Touch", Area }`.
- Se ejecuta **en cada recolocación** (giro, cambio de resolución, cargar o restablecer la disposición,
  reaparecer, ajustes de correr y disparo izquierdo, menús): `TouchLayout.LastCollisions`. En Studio
  con `MobileHUDDebug`, se avisa en la salida.
- **MobileHUDDebug** (false por defecto, solo Studio): SAFE RECT, VISUAL RECT (blanco), TOUCH RECT
  (amarillo), CAMERA SWIPE ZONE, CENTER DEAD ZONE, LEFT/RIGHT THUMB ZONE y los elementos de las zonas
  (cian); **en rojo** todo lo que choca. Se redibuja cada segundo.

## 6. Layout nuevo (escala 1; se multiplica por la escala de la pantalla)

Grupo de combate, desde DISPARAR (centro del grupo):

| Control | Dibujo | Caja táctil | Dónde |
|---|---|---|---|
| DISPARAR | 92 | 104 | centro |
| APUNTAR | 62 | 70 | izquierda, algo arriba (−96, −44) |
| SALTAR | 58 | 66 | derecha (92, −10) |
| AGACHARSE | 50 | 58 | debajo del salto (88, 62) |
| RECARGAR | 46 | 54 | izquierda, abajo (−92, 34), junto a la munición |
| CUERPO A CUERPO | 40 | 48 | arriba (0, −84) |
| Ataque aéreo | 40 | 46 | arriba a la derecha (64, −84), solo con cargas |
| Cambiar arma | 120×32 | 132×35 | abajo a la izquierda (−210, 76) |

Pulgar izquierdo: fila de habilidades (40, caja 46) a 52 px de distancia y la granada (46) al final de
la fila; correr (si se elige «con botón») encima; disparo izquierdo (si se activa) más arriba a la
derecha, sin pisar joystick, habilidades ni minimapa. **Si están apagados, ni se ven ni reservan
sitio.** Tira de arriba: 4 iconos de 32 (caja 38) cada 46 px.

Métricas (misma herramienta, Fase 15 → Fase 16; controles por defecto):

| Pantalla | Controles | Cobertura | Centro libre | Cámara libre | Solapes visuales | Solapes táctiles |
|---|---|---|---|---|---|---|
| 568×320 | 15 → 15 | 11,5 % → 11,7 % | 5,1 % | 14,8 % → 14,1 % | 1 → **0** | 8 → **0** |
| 667×375 | 15 → 15 | 11,5 % → 11,7 % | 5,1 % | 15,0 % → 14,3 % | 1 → **0** | 8 → **0** |
| 844×390 | 15 → 15 | 9,4 % → 9,6 % | 4,2 % | 15,4 % → 14,7 % | 1 → **0** | 8 → **0** |
| **892×412 (S26)** | 15 → 15 | 9,4 % → 9,6 % | 4,2 % | 15,5 % → 14,7 % | 1 → **0** | 8 → **0** |
| 1024×768 | 15 → 15 | 6,2 % → 6,3 % | 6,8 % | 24,6 % → 24,2 % | 1 → **0** | 8 → **0** |

(La zona de cámara baja un poco porque el aire entre cajas abre el grupo; sigue siendo todo el
cuadrante de arriba a la derecha sin botones, más el hueco entre la mira y el grupo y el propio
DISPARAR, que deja girar la cámara con el mismo dedo.)

## 7. Ultrawide

Sin cambios de criterio respecto a la Fase 15 (clase por forma de `ViewportSize`, zona segura del
motor, nunca el modelo): `ULTRAWIDE_PHONE` con proporción ≥ 1,95. **RIGHT_THUMB_INSET**: el grupo se
mete `(proporción − 1,9) × lado corto × 0,2` px más hacia dentro (máx. 40). En el S26 (892×412, escala
1,06): DISPARAR en (716, 301), a 176 px del borde; lo más exterior (SALTAR) a 47 px.

## 8. Multijugador (simulado)

`tests/harness/hudstress.luau`: S26 simulado (cámara frontal y barra de Roblox), `KeyboardEnabled =
true` como el S26 real, 10 jugadores (5 contra 5) y:

- 20 bajas seguidas en el registro → **3 filas**; 4 medallas seguidas → **2 a la vez**; XP, avisos,
  racha, radar, poca vida, estamina baja, ataque aéreo disponible;
- **0 choques** entre controles y **0 problemas** de las zonas en cada estado.

## 9. Los 10 modos

| Modo | Qué sale (táctil) | Comprobado |
|---|---|---|
| TDM | marcador; aviso de baja, medallas, avisos | ✔ |
| DOM | banderas A/B/C bajo el minimapa (pequeñas), captura en curso | ✔ |
| SND | estado de la bomba bajo el minimapa; «desactivando» bajo la mira; en pie en la línea del modo | ✔ |
| CTF | estado de las banderas a los lados del marcador; «¡tienes la bandera!» arriba (fuera del centro) | ✔ |
| KOTH | «◆ ¡DISPUTADA!» y «Se mueve en Ns» a los lados del marcador | ✔ |
| FFA | TÚ contra el LÍDER (sin «5 VS 5») | ✔ |
| GUN | TÚ contra el LÍDER; sin granada (como antes) | ✔ |
| ELIM | en pie de cada equipo en la línea del modo | ✔ |
| INF | supervivientes contra zombis | ✔ |
| CAL | avisos de calabazas como XP | ✔ |

En los diez: 0 choques entre controles y nada encima de botones, munición, vida, registro de bajas ni
centro libre.

## 10. Multitouch

Reglas (se mantienen las de las Fases 12 y 13):

- Un dedo (`InputObject`) pertenece a **un solo** control hasta que lo levanta (`entry.Owner`); un
  segundo dedo encima no hace nada; un dedo viejo nunca suelta una pulsación nueva.
- Excepción explícita: **DISPARAR + cámara** («arrastrar para apuntar», por defecto): el mismo dedo
  dispara y gira la cámara. Los botones solo reaccionan **al empezar** el toque, así que arrastrar el
  dedo de disparar por encima de otro botón **no lo activa**.
- Disparar y disparo izquierdo comparten el gatillo (empieza con el primero, se suelta con el último).
- Joystick (dedo 1) + cámara (dedo 2) + disparar (dedo 3) + saltar/apuntar (dedo 4): cada uno con su
  dedo; el `InputEnded` de uno no cancela otro.
- **Nuevo**: al **morir** y al **reaparecer** se sueltan todos los controles (`TouchLayout.ReleaseAll`);
  si el bloqueo (menú, muerte, resultados) cambia sin aviso, el siguiente tick lo corrige. Menús: al
  abrir se suelta todo; al cerrar no se reactiva nada. Fin de partida: los botones desaparecen bajo los
  resultados; partida siguiente: los mismos botones, sin duplicados.

## 11. Editor

- Sigue permitiendo mover, cambiar tamaño y opacidad libremente; **nada puede quedar fuera de la
  pantalla** (como antes).
- **No deja guardar** dos controles de combate (disparar, apuntar, salto, agacharse, recargar,
  granada, cuerpo a cuerpo) **uno encima del otro** (sus cajas se tapan en más de la mitad).
- **Avisa** (pero deja guardar) si dos de combate se tocan o si un control entra en el centro libre.
- Línea de estado en el panel («Sin choques» / «Aviso: …» / «No se puede guardar: …»).
- RESTABLECER = disposición nueva (sin choques).

## 12. Renders

Perfil `GALAXY_S26_ULTRA` (892×412, 19,5:9; cámara frontal y barra de Roblox simuladas) sobre un fondo
de Construction. Láminas: antes/después del **combate intenso** (SND y DOM), y después: normal, TDM,
DOM, SND, CTF, KOTH en combate intenso, ADS, cargador vacío, francotirador, editor y depuración.

## 13. Tests

- `mobilehud`: detector (cajas visual y táctil), **0 choques con 4 px de aire en 10 pantallas**
  también con correr y disparo izquierdo, zonas táctiles mayores que el dibujo, choques detectados
  cuando los hay, revisión del editor (bloquear / avisar / centro), hueco libre.
- `hudstress` (nuevo): todo lo de las secciones 8-11.
- Se mantienen: `touchbtns`, `hudeditor`, `phonefx`, `inputmode`, `movement`, `abilities`,
  `clientboot`, `hudclient` y el resto de la batería.
- Resultado: ver «Resultado final».

## 14. Pendiente en Studio / teléfono real

1. Jugar una partida 5v5 entera en el S26: ¿algún toque cae en el botón equivocado?
2. Arrastrar el dedo de DISPARAR por encima de APUNTAR/SALTAR: no deben activarse.
3. Cuatro dedos (joystick, cámara, disparar, saltar) a la vez.
4. Morir con el dedo en disparar y reaparecer: nada se queda disparando ni apuntando.
5. SND con la bomba plantada y desactivando: ¿se lee el estado bajo el minimapa y la barra bajo la mira?
6. DOM: ¿las banderas A/B/C bajo el minimapa se leen sin tapar las habilidades?
7. Una racha de bajas seguidas: aviso de baja + 2 medallas sin tapar nada.
8. Editor: intentar poner DISPARAR encima de APUNTAR (no debe guardar) y dejarlos solo cerca (debe
   avisar y guardar).
9. Con `MobileHUDDebug = true` en Studio (no en el commit): nada en rojo durante la partida.

## Resultado final

- `tests/check.sh`: Rojo build y luau-lsp sin errores.
- `tests/run_all.sh` completo: **OK 152, FALLOS 0** (incluye `mobilehud`, `hudeditor`, `hudstress`, navegación de los 9 mapas, arranque de los 10 modos y ciclo de 10 partidas).
- Layout por defecto: 0 solapes visuales y 0 táctiles (separación mínima 4 px) en las 10 resoluciones de la matriz, con y sin opcionales (Fase 15: 9 por tamaño).
- S26 simulado (892x412): solapes visuales 1 → 0, táctiles 8 → 0; ULTRAWIDE_PHONE; 0 controles fuera de la zona segura.
- HUDZones: 0 problemas (`Validate` vacío) en combate intenso en los 10 modos.
- Sin cambios en daño, retroceso, asistencia de apuntado, cadencia, mapas, bots, economía, monetización, pase ni armas. ProductIds en 0, UniverseId/PlaceId sin tocar, QA y depuración desactivados. Sin publicar.
- Multijugador probado en simulación (10 jugadores en el mock), no en un servidor real: pendiente de validar en Studio y en el teléfono (sección 14).
