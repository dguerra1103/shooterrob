# TURNO NOCTURNO — Fases 3 a 7

> **Nada de esto se ha probado en Roblox Studio.** Todo se ha validado fuera del motor: build con Rojo,
> análisis con luau-lsp, pruebas con Lune sobre un simulador de Roblox y capturas aproximadas (mapas e
> interfaz) dibujadas en un navegador. **No está listo para lanzar:** falta la prueba real en Studio
> (sección 9).
>
> Rama: `claude/intelligent-fermi-cz7und`. Sin Pull Requests. **Nada publicado.**

## 1. Trabajo completado

| Fase | Resultado | Documento |
|---|---|---|
| 3. Mapas e iluminación | Construction, Coastal y Mall Rush pulidos como «gold standard» (con 3 o más hitos cada uno); sin desenfoque en combate; neblina y bloom limitados. Sin cambios de gameplay. | `FASE_03_VISUAL_MAPAS.md` |
| 4. UI/UX | 4 fallos visuales corregidos (misiones cortadas, tarjetas de clase en el teléfono, título de la votación, tarjetas de equipo que se recreaban) y huecos para audio propio de la interfaz. | `FASE_04_UI_UX.md` |
| 5. Móvil y rendimiento | Auditoría del sistema de calidad, del HUD táctil, de lo responsive y de los ~40 bucles por fotograma. 3 arreglos pequeños (historial de la killcam y escrituras del HUD). Plan de medición. | `FASE_05_MOVIL_RENDIMIENTO.md` |
| 6. Bots y primeras partidas | Bots revisados: cumplen las reglas, sin cambios. Consejos de contexto para jugadores nuevos (3 como mucho, una vez cada uno). La tarjeta de controles de PC explica cómo cambiar de arma. | `FASE_06_BOTS_ONBOARDING.md` |
| 7. QA final | Suite completa, comprobación de regresiones y este documento. | — |

## 2. Fase 3 — Mapas, iluminación y calidad visual

- **Construction** (gris + amarillo + rojo):
  - torre central con cantos amarillos y red de seguridad roja;
  - el amarillo pasa de metal a pintura (grúa, barandillas);
  - nave B con franjas de peligro, calle pintada y una «B» grande;
  - neblina de 0,30 a 0,25 y bloom de noche de 0,65 a 0,5.
- **Coastal** (el más luminoso):
  - más casas encaladas y contraventanas azules;
  - campanario encalado con azulejo y reloj;
  - fuente con azulejo azul;
  - faro más cerca (de 330 a 230 studs) y más alto;
  - más luz ambiente y menos neblina.
- **Mall Rush:**
  - cubierta clara (las zonas de doble altura dejan de verse oscuras);
  - fuente moderna (con la misma colisión);
  - franjas de suelo y tiras de luz de neón (sin luces nuevas);
  - franja de color y rótulo «MALL RUSH» en la azotea;
  - el rótulo de la entrada decía «SUNRISE MALL» y ahora dice «MALL RUSH».
- **Común:**
  - `GameConfig.AimDepthOfField = false`: apuntar ya no desenfoca;
  - el desenfoque lejano de Ultra solo se ve en los menús;
  - bloom como mucho 0,5 y neblina como mucho 0,26 en todas las luces de los tres mapas.
- **Rendimiento:**
  - presupuesto de piezas por mapa en las pruebas;
  - todos los detalles nuevos son decorado sin colisión;
  - los pequeños se ocultan en calidad Baja con el sistema que ya había;
  - 0 luces nuevas.

## 3. Fase 4 — UI/UX y flujo

- La identidad (grafito, amarillo, rojo, blanco y azul para el aliado), la jerarquía (JUGAR domina) y
  las microinteracciones ya eran coherentes. **No se rehizo nada.**
- **Corregido:**
  - misiones cortadas a media palabra en el teléfono;
  - textos montados en «Elige tu clase» en el teléfono;
  - el título de la votación pisaba el panel de búsqueda;
  - la presentación de equipos destruía y recreaba 10 tarjetas cada 0,6 s.
- **Audio:** `UISound.Custom`, un hueco por sonido para audio propio. Vacío = el de siempre.
- No había esperas artificiales que quitar (los tiempos los marca el servidor).

## 4. Fase 5 — Móvil y rendimiento

- **Ya había un único sistema de calidad** (Auto, Baja, Media, Alta, Ultra). No se ha creado otro.
  - En Baja se recortan partículas, casquillos, marcas, humo y detalle del mapa.
  - Nunca se recortan el hitmarker, el aviso de baja, la información del enemigo ni los objetivos
    (revisado).
- **Arreglado:**
  - el historial de la killcam desplazaba su lista entera en cada muestra (20 veces por segundo y por
    jugador);
  - el HUD reescribía textos iguales y movía la mira en cada fotograma.
- **Documentado sin tocar:**
  - el HUD no respeta la muesca de los iPhone (hay que verlo en un dispositivo y separar los velos de
    pantalla completa);
  - el minimapa y `WorldFX` tienen mejoras pequeñas posibles.
- **Sin cifras de FPS:** el plan de medición está en `FASE_05_MOVIL_RENDIMIENTO.md` (sección E).

## 5. Fase 6 — Bots y primeras partidas

- **Bots** (sin cambios), comprobado en el código:
  - necesitan línea de visión y tienen un cono de 140°;
  - reaccionan en 0,31-0,71 s;
  - su puntería se asienta en 0,9 s y aciertan como mucho un 95 %, con menos acierto de lejos,
    andando o contra un objetivo que corre;
  - 12 % de disparos a la cabeza × habilidad;
  - hacen un 55 % del daño de un jugador y se ajustan al rango del jugador.
  - La dificultad ya es configurable en `GameConfig.Bots`.
- **Consejos de contexto** (`Hints.luau`): apuntar, recargar antes y cubrirse.
  - Solo hasta el nivel 5, cada uno una vez por sesión y 60 s entre ellos.
  - Nunca encima de un menú, la muerte, la killcam o los resultados (si aparecen, el consejo se quita).
  - No guardan nada: sin cambios de datos.
- **Tarjeta de controles (PC):** ahora dice cómo cambiar de arma (1 2 3 o la rueda). El objetivo de cada
  modo ya salía en la cuenta atrás.

## 6. Pruebas

- `tests/check.sh`: build de Rojo correcto y **luau-lsp sin errores**.
- `tests/run_all.sh`: **(pendiente: resultado de la última pasada)**. Incluye:
  - todas las pruebas de sistemas (flujo, resultados, economía, pase, tienda, combate, gunplay, killcam,
    bots…);
  - la navegación de los 9 mapas (`navcheck`);
  - arrancar el servidor en los 10 modos (`serverboot`);
  - **10 partidas seguidas** con los 10 modos (`ciclo`);
  - la economía en el móvil.
- **Pruebas nuevas esta noche:**
  - `mapvisual`: hitos, decorado sin colisión, luz y presupuesto de piezas;
  - `rendimiento`: historial de la killcam;
  - `hints`: consejos.
- **Pruebas ampliadas:** `aimfx` (sin desenfoque en partida) y `flow` (tarjetas de equipo estables y
  votación sin solaparse).
- **Ninguna prueba borrada ni desactivada.**
- **Prueba arreglada en la Fase 7: `rounds`.** Fallaba de vez en cuando como «TIEMPO AGOTADO» (en la primera pasada final y en 1 de cada 3-8
  repeticiones sueltas).
  - Causa: los modos salen al azar y, con rondas de 1 s, a veces ningún jugador que haya «jugado de
    verdad» (P1 y P2) gana una partida (Dominio sin capturas, Buscar y destruir sin bomba). Entonces
    no hay «primera victoria del día» y el `assert` fallaba. Además, con `assert` el proceso no
    terminaba (las rondas seguían vivas), así que parecía colgado.
  - Arreglo: las comprobaciones salen en el acto con `FALLO:`, y la primera victoria se exige solo si
    P1 o P2 ganaron alguna partida (el tope de una por jugador se sigue comprobando).
  - **El juego no tenía ningún fallo:** la regla de «haber jugado de verdad» es la correcta.
  - 10 de 10 pasadas sin fallo, incluida una sin victorias.
- **Prueba ajustada en la Fase 7: `variants`.** Falló una vez («Construction: a veces sale Noche»).
  - Causa: la noche sale el 17,5 % de las veces (`Chance` 0,25 tras el 0,3 del mediodía; esto no ha
    cambiado esta noche) y la prueba solo construía el mapa 30 veces. 1 de cada ~300 pasadas no salía
    ninguna noche.
  - Arreglo: 60 construcciones (≈ 1 de cada 100.000).
- En una pasada de la Fase 4, `smoke` agotó su tiempo con la CPU al 98 %. Sola tarda ~1 s, con 30
  repeticiones y las demás pasadas completas sin fallo. Hay que vigilarla.

## 7. Commits (todos en `claude/intelligent-fermi-cz7und`, con push)

| Commit | Fase | Qué |
|---|---|---|
| `7895ae6` | 3 | Sin desenfoque (DOF) en partida |
| `1123208` | 3 | Construction, Coastal y Mall Rush (visual, sin tocar el gameplay) |
| `063ea59` | 3 | Prueba `mapvisual` |
| `e401217` | 3 | Documentos de la Fase 3 |
| `a2fee75` | 4 | UI/UX: textos en el móvil, votación, presentación de equipos y huecos de audio |
| `2f44391` | 5 | Arreglos por fotograma (killcam y HUD) y prueba `rendimiento` |
| `f9223c7` | 5 | Documento: responsive, controles táctiles, vistas 3D y muesca |
| `b51e18e` | 6 | Bots revisados, consejos de contexto y tarjeta de controles |
| `352ceb3` | 7 | `TURNO_NOCTURNO.md` (borrador) |
| `cf7d112` | 6-7 | Consejos: se quitan en el acto si mueres o se abre algo encima |
| `c1f18bf` | 7 | Prueba `rounds`: sin azar en la primera victoria y falla en el acto |
| `df57c1b` | 7 | Este documento: frecuencia real del fallo de `rounds` |
| (este) | 7 | Prueba `variants` con 60 construcciones; resultado final en este documento |

**Comprobado antes de cada push:**
- `publish.yml` solo publica con `workflow_dispatch` (un push solo construye y valida);
- ningún ProductId distinto de 0;
- sin cambios en `PlayerData`, en las migraciones, en los workflows, en `default.project.json` ni en
  los IDs de publicación;
- sin cambios en la economía, los precios, el pase ni las temporadas.

Desde el final de la Fase 2, en `GameConfig` solo hay una línea nueva: `AimDepthOfField`.

## 8. Riesgos restantes

1. **Todo lo visual es aproximado.** Las capturas no tienen la luz, los materiales ni la atmósfera de
   Roblox. Los colores de los tres mapas pueden verse distintos en el motor (sobre todo el amarillo
   pintado de Construction al atardecer y el blanco de Coastal con la exposición nueva).
2. **Neblina más baja:** se ve más lejos. Es bueno para ver enemigos, pero puede dejar ver los bordes
   de los mapas.
3. **Muesca del iPhone:** la vida, la munición o la lista de bajas pueden quedar bajo la muesca
   (sin verificar).
4. **Consejos:**
   - la posición está comprobada sin arma en la mano; con la munición en pantalla, falta verla;
   - el de apuntar usa «8 disparos sin acertar» como señal: puede salir también de cerca.
5. **`TextScaled`** se comporta distinto en Roblox: los títulos de misiones y las tarjetas de clase
   pueden necesitar ajuste.
6. **`smoke`** agotó su tiempo una vez bajo carga (ver sección 6).
7. Lo que ya decían las fases 1 y 2 sigue pendiente (prueba en Studio, latencia real, audio propio).

## 9. Cosas que necesitan Roblox Studio

Por orden. El detalle está en la sección «Pendiente en Studio» de cada documento.

1. **Fase 1 (sección E):** 1 jugador, 2 jugadores, 5 + bots y 5 partidas seguidas. Copiar la Output de
   lo que falle.
2. **Mapas (Fase 3, F):**
   - Construction, Coastal y Mall Rush en sus variantes de luz;
   - que un enemigo lejano se vea;
   - que apuntar no desenfoque;
   - que en Baja no se pierdan los letreros A/B.
3. **Gunplay (Fase 2, F):** empezando por el ARX-27.
4. **Interfaz (Fase 4, D):**
   - Device Emulator con un teléfono apaisado, una tablet y PC;
   - la presentación de equipos con jugadores reales.
5. **Móvil y rendimiento (Fase 5, E):**
   - MicroProfiler en un 5 contra 5;
   - memoria tras 5 partidas;
   - un móvil real con calidad Auto;
   - un iPhone con muesca.
6. **Consejos (Fase 6, E):** con una cuenta nueva (nivel 1), forzar los tres consejos y comprobar que
   no se repiten ni pisan el HUD.
7. **Bots:** que se sientan justos en Bronce y en Oro.

## 10. Assets externos que faltan

No se ha inventado ningún asset. Lo que falta tiene ya su hueco:

| Qué | Dónde se pone | Estado |
|---|---|---|
| Sonidos propios de la interfaz (pasar por encima, clic, jugar, partida encontrada, cuenta atrás, premio, equipar, compra, error, victoria, derrota, subir de nivel) | `UISound.Custom` (Fase 4) | TODO: vacío, se usan los de Roblox |
| Sonidos propios de cada arma (disparo, mecánica, cola, recarga) | `Sounds.WeaponAudio` (Fase 2) | TODO: vacío, se usan los de Roblox con capas |
| Animaciones propias (recarga, inspección, equipar) | Momentos ya emitidos por `ClientState.WeaponEvent` (Fase 2) | TODO: no hay animaciones propias |
| Texturas o decals de los mapas (azulejo, marcas de suelo, carteles) | — | No hay: se usan materiales de Roblox y piezas de color |
| Productos de la tienda | Creator Dashboard → `ProductId` | Todos a 0 (TODO: SET IN CREATOR DASHBOARD). No se han tocado. |
