# FASE 4 — UI / UX / flujo / presentación

> **Sin Roblox Studio.** Las pantallas se revisaron con capturas generadas desde el mock: el árbol de
> interfaz real se vuelca a JSON y se dibuja en un navegador. Las posiciones, los tamaños y los
> textos son los reales. Las fuentes, el escalado de texto y los ViewportFrames 3D son
> aproximados (en las capturas, los recuadros punteados son las vistas 3D). Hay que confirmarlo en
> Studio con el emulador de dispositivos.

## A. Auditoría

Revisadas en escritorio (1280×720) y teléfono apaisado (844×390): Inicio, Escuadra, Armamento,
Operador, Buscando partida, Partida encontrada, Presentación del mapa, Presentación de equipos,
Elige tu clase, Prepárate y HUD de juego.

| Área | Estado |
|---|---|
| Identidad | Ya consistente: grafito/negro, amarillo (jugar, selección, premios), rojo (combate, alertas), blanco y azul para el aliado (`Theme.luau`), con Oswald para títulos y Gotham para textos. **No se rehizo.** |
| Jerarquía del inicio | JUGAR domina (botón amarillo grande arriba a la izquierda); el resto, en columnas. Sin publicidad invasiva. |
| Microinteracciones | Ya existían: `C.feel` (pasar por encima, pulsar y soltar con escala y sonido), selección (`C.setSelected`), partida encontrada (destello y sonido), recompensa, equipar. Duraciones rápidas (`Theme.Time`: 0,08–0,45 s). |
| Esperas | Los tiempos del flujo dependen del servidor (construcción del mapa, cuenta atrás de despliegue). Mínimos: búsqueda con partida en marcha 0,9 s, partida encontrada 1,4 s, presentación de equipos 3,2 s. **Sin esperas artificiales que quitar.** |
| Resultados | Ya cubierta por pruebas (`results`, `resultsserver`); no se ha tocado. |

## B. Problemas encontrados y corregidos

| # | Pantalla | Problema | Arreglo |
|---|---|---|---|
| 1 | Inicio (teléfono) | Los títulos de las misiones se cortaban a media palabra («Haz 5 bajas a la ca…»): el contador 0/5 les quitaba sitio. | El contador pasa a la línea de la barra de progreso. El título usa todo el ancho hasta el premio y se reduce un poco (hasta 11 px) antes de cortarse. |
| 2 | Elige tu clase (teléfono) | En tarjetas de ~150 de ancho, «Secundaria: Viper P9» saltaba de línea y se montaba sobre la ventaja. | En el teléfono: «+ Viper P9» y solo la ventaja («❤ Persistente»), porque la granada la llevan todas las clases. En escritorio, igual que antes. |
| 3 | Buscando partida (escritorio) | El título «ELIGE EL MAPA DE LA SIGUIENTE PARTIDA» pisaba el borde amarillo del panel (7 px). | El panel sube 8 y la votación baja 4: 5 px de aire. El teléfono, igual que antes. |
| 4 | Presentación de equipos | Cada 0,6 s destruía y volvía a crear las 10 tarjetas de jugador (parpadeo y objetos nuevos sin necesidad). | Las tarjetas se crean una vez por presentación y después se actualizan (`playerCard:Update`). `Update` ahora también aplica el estilo de «tú» (nombre amarillo y borde), que antes solo se ponía al crearla. |
| 5 | Audio de interfaz | Todo con sonidos incluidos con Roblox y sin sitio para los propios. | `UISound.Custom`: huecos por nombre (Hover, Click, Play, MatchFound, Countdown, Go, Reward, Equip, Purchase, Error, Victory, Defeat, LevelUp). Vacío = el de siempre. **TODO: AÑADIR AUDIO PROPIO.** |

## C. Pruebas

- `flow` (ampliada):
  - las tarjetas de la presentación de equipos se actualizan sin recrearse y la tuya queda resaltada;
  - el título de la votación queda por debajo del panel de búsqueda, con la posición final tras la
    animación.
- El resto del flujo (`flow`, `results`, `menu`, `econ_client` en PC y móvil, `hudclient`,
  `touchbtns`) sigue pasando.
- Suite completa: **143 OK, 0 fallos**. En una pasada anterior `smoke` agotó su tiempo (300 s) con la
  máquina al 98 % de CPU. Sola tarda ~1 s: 30 repeticiones sin fallo y 3 pasadas de la suite sin
  fallo. No se ha encontrado ningún bucle que pueda colgarse (`MapBuilder.FeaturedId` es una
  cuenta directa). Queda anotado como algo que vigilar si vuelve a pasar.

## D. Pendiente en Studio

1. **Device Emulator → un teléfono apaisado:**
   - inicio con las misiones legibles;
   - «Elige tu clase» sin textos montados;
   - buscando partida, presentación de equipos y HUD.
2. **Tablet (por ejemplo, iPad) y escritorio:** lo mismo; comprobar que el tablet usa el diseño
   intermedio (`TABLET`).
3. **Presentación de equipos con jugadores reales** (Local Server, 2-5): las tarjetas se llenan sin
   parpadear cuando entran los bots.
4. **Escalado real del texto:** en Roblox `TextScaled` funciona distinto que en las capturas.
   Comprobar las tarjetas de clase y las misiones con nombres largos.

## E. No hecho (a propósito)

- No se ha rediseñado ninguna pantalla ni añadido sistemas nuevos: la identidad, las transiciones y
  las microinteracciones ya eran coherentes.
- Resultados: sin cambios (sin inconsistencias en la auditoría).
- No hay sonidos nuevos: solo los huecos para el audio propio.
