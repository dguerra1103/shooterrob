# FASE 1 — Estabilidad, calidad del código y preparación para Studio

> **Importante:** todo lo de este documento se ha comprobado **fuera de Roblox Studio**: análisis
> estático (luau-lsp), `rojo build` y pruebas en Lune con una imitación de la API de Roblox. **Nada se
> ha probado en Studio** (no hay acceso a Studio desde este entorno). El juego **no** está listo
> para lanzamiento hasta pasar la sección E en Studio.

## A. Estado actual

| Área | Estado (fuera de Studio) |
|---|---|
| Publicación | Blindada: un push solo construye el `.rbxlx`; publicar es manual (Run workflow), con el Place ID escrito para confirmar y `Saved` por defecto. |
| Arranque | El servidor arranca cada módulo protegido (`xpcall`); los 10 modos arrancan sin errores (`serverboot`). El cliente arranca sin errores (`clientboot`). |
| Bucle de partidas | `Round.gameLoop` se recupera de un error en una ronda; el ciclo de 10 partidas seguidas con los 10 modos es estable (ver D). |
| Mapas | 9 mapas 5v5 (Construction, Coastal, Terminal, Mall Rush, Rooftop District, Metro Yard, Desert Base, Dockyard, Industrial Yard): se construyen, un solo mapa a la vez, zonas alcanzables desde las bases (`navcheck`). |
| Modos | TDM, DOM, SND, CTF, KOTH, FFA, GUN, ELIM, INF, CAL: arrancan y terminan; pruebas específicas para SND, DOM, ELIM, INF, CAL, CTF (bots con bandera) y GUN. |
| Combate | El servidor valida todo disparo (arma en la mano, munición, cadencia, origen junto a la cabeza y sin pared, alcance, impacto cerca de la pieza, línea de visión) y calcula el daño. |
| Bots | Rellenan hasta 10, se quitan al acabar cada partida (0 bots tras cada una en 10 partidas), compatibles con los 10 modos. |
| Datos | DataStore con bloqueo de sesión, recibos idempotentes, autoguardado y guardado al cerrar. Sin cambios en el esquema ni en las migraciones. |
| Economía | Todos los `ProductId`/Game Pass siguen a `0` (`TODO: SET IN CREATOR DASHBOARD`): no hay compras reales posibles. |
| Pruebas | Recuperadas al repositorio en `tests/` (ver `tests/README.md`). |

## B. Problemas encontrados

Por gravedad. ✅ = corregido en esta fase; 📝 = documentado, no se cambia (ver F).

### Críticos
1. ✅ **Cada push publicaba el juego** (`.github/workflows/publish.yml` publicaba como `Published` en cada
   push a `main` y `claude/**`, a un Place ID que no se puede verificar desde aquí). Riesgo de
   sustituir lo que juegan los jugadores o de escribir sobre otra experiencia (Streamer Tycoon).

### Altos (el servidor podía quedarse roto en silencio)
2. ✅ La recuperación de `Round.gameLoop` llamaba a `clearElimination()`/`clearInfection()` sin
   proteger: si una fallaba, el bucle de partidas moría y el servidor se quedaba sin rondas.
3. ✅ Bucles sin proteger en `HealthRegen`, `Hazards` (lava), `Event` (cambio de evento),
   `Gifts` (guardado del tiempo jugado) y en los hilos de los modos `Hardpoint` (KOTH),
   `Domination` y `Pumpkins` (CAL): un error puntual paraba ese sistema para el resto del servidor.
4. ✅ `PlayerData`: los bucles de potenciadores y temporadas recorrían a todos los jugadores sin
   proteger (un perfil raro paraba el bucle para todos).
5. ✅ `PlayerData`: si el jugador se iba mientras se cargaba su perfil, el bloqueo de sesión quedaba
   puesto (al volver a entrar tenía que esperar a que caducara).
6. ✅ `Leaderboard`: un error en una pasada paraba la clasificación global para siempre; los fallos
   al subir se tragaban sin aviso.

### Medios
7. ✅ Combate: un `Vector3` con NaN como origen o punto de impacto pasaba las comprobaciones de
   distancia (NaN no es mayor que nada). Ahora se rechazan NaN e infinitos; y un explosivo con
   origen = impacto ya no calcula una dirección NaN.
8. ✅ Remotos de equipamiento y ajustes (skins, trajes, armas, clases, camuflajes, cosméticos,
   colgantes, títulos, grafitis, efectos, ajustes, listo, vistos) sin límite: un cliente modificado
   podía inundar el servidor y la red con `DataUpdate`. Ahora hay un cubo de fichas por jugador (20
   seguidas, 6/s) que no afecta a "EQUIPAR TODO" ni al guardado de ajustes (cada 1,5 s).
9. ✅ Votación de mapa: repetir el mismo voto volvía a publicar la votación a todos.
10. ✅ `PlayerData.ownsPass`: un fallo de `UserOwnsGamePassAsync` se trataba en silencio como "no lo
    tiene". Ahora reintenta una vez y avisa en la consola.
11. ✅ Errores silenciosos en `OnLeaving` (al salir y al cerrar el servidor): ahora se avisan.
12. ✅ Cliente — **pantalla en negro**: si se salía de la pantalla de Resultados en sus primeros
    0,25 s, el fundido quedaba opaco para siempre.
13. ✅ Cliente: al volver al menú con poca vida, el mundo se quedaba sin color (corrección de color
    de vida baja).
14. ✅ Cliente: los avisos de compañero (`Callouts`) de personajes que ya no existen se quedaban en
    `PlayerGui` partida tras partida.

### Bajos
15. ✅ `Round`: la tabla de "ya apareció en esta ronda" no se limpiaba al salir un jugador.
16. ✅ `Leaderboard`: la caché de valores subidos crecía toda la sesión.
17. ✅ `FlowController`: el centro del mapa (`GetBoundingBox` de todo el mapa) se calculaba en cada
    fotograma en el menú; ahora como mucho cada 2 s.
18. ✅ Revelado de compras en cola: el desenfoque del primero se destruía al empezar el segundo.
19. ✅ HUD: dos finales de ronda seguidos en menos de 7 s escondían el segundo antes de tiempo.
20. ✅ `Combat`: `WaitForChild("Humanoid")` sin límite al aparecer un personaje.

## C. Corregido (resumen por archivo)

| Archivo | Cambio |
|---|---|
| `.github/workflows/publish.yml`, `scripts/publish.sh`, `README.md` | Publicación solo manual, con confirmación del Place ID, `Saved` por defecto. Los identificadores siguen en Secrets/Variables; no se ha cambiado ninguno. |
| `src/server/Modules/Round.luau` | Recuperación protegida; voto repetido ignorado; limpieza al salir. |
| `src/server/Modules/PlayerData.luau` | Bucles protegidos; reintento de Game Pass; liberación del bloqueo al salir durante la carga; avisos de `OnLeaving`; límite de peticiones. **Sin tocar** esquema, migraciones ni guardado. |
| `src/server/Modules/Combat.luau` | Rechazo de NaN/infinitos; explosivo con distancia 0; espera con límite. |
| `HealthRegen`, `Hazards`, `Event`, `Gifts`, `Hardpoint`, `Domination`, `Pumpkins`, `Leaderboard` | Cuerpo de los bucles protegido con aviso en consola. |
| Cliente: `Results`, `HUD`, `Callouts`, `Reveal`, `FlowController` | Fallos 12–14 y 17–19. |
| `tests/` (nuevo) | 123 archivos `.luau` (pruebas y utilidades como el mock), `run_all.sh`, `check.sh`, `README.md`, prueba de ciclo `ciclo.luau`; el mock desconecta señales y destruye descendientes como Roblox (para medir fugas). |
| `aftman.toml`, `.gitignore` | Lune y luau-lsp fijados; caché de pruebas ignorada. |

## D. Pruebas realizadas (fuera de Studio)

Todas ejecutadas en este entorno (Linux, sin Roblox Studio). Cómo repetirlas: `tests/README.md`.

| Prueba | Herramienta | Resultado |
|---|---|---|
| Análisis estático de todo `src/` | luau-lsp 1.70.1 (`tests/check.sh`) | **0 errores** |
| Construcción del lugar | Rojo 7.4.4 (`rojo build`) | **OK** |
| Batería completa | Lune 0.8.9 (`tests/run_all.sh`) | **139 OK, 0 fallos** (antes de los cambios: 137 OK, 0 fallos) |
| Arranque del servidor en los 10 modos | `serverboot` ×10 | OK en TDM, DOM, SND, CTF, KOTH, FFA, GUN, ELIM, INF, CAL |
| 9 mapas: construcción y navegación | `navcheck` ×9 | OK: Construction, Coastal, Terminal, MallRush, RooftopDistrict, MetroYard, DesertBase, Dockyard, IndustrialYard |
| **Ciclo de estabilidad: 10 partidas seguidas** (3 jugadores + bots, los 10 modos, sin reiniciar) | `ciclo` (nueva) | OK. En cada partida: 1 solo mapa, 0 bots al acabar, 1 resumen por jugador, 7 bots dentro (10 − 3 jugadores). Conexiones de señales: 80 → 80 (no crecen). Objetos sueltos en workspace: 2 → 2. Ningún aviso de error del servidor. |
| Correcciones de esta fase | `fase1` (nueva) | OK: disparo válido hace daño; origen NaN/infinito e impacto NaN rechazados; 60 peticiones seguidas → 20 aceptadas; 6 tras una pausa → todas. **Con el código anterior la prueba falla** (el origen NaN gastaba munición). |
| Flujo completo de la interfaz | `flow`, `results`, `resultsserver`, `clientboot`, `menu` | OK: cubren las pantallas del flujo de partida (inicio, búsqueda, presentación, equipos, clase, cuenta atrás) y Resultados con datos reales del servidor; el paso Resultados → lobby/siguiente partida en el motor real queda para Studio (E1.6) |
| Datos | `datastore`, `progress`, `seasons`, `boosters` | OK: bloqueo de sesión, recibos idempotentes, migraciones, sin pérdida de progreso |
| Economía (sin compras reales) | `econ_catalog`, `econ_server`, `econ_client` (PC y móvil) | OK; todos los ids a 0 |
| Combate y bots | `shooting`, `realshots`, `realhits`, `melee`, `grenade`, `killcam`, `bots`, `botbrain`, `gunbots`, `flagbots`, `infection_bots`… | OK |

**Mejora del simulador**: el mock ahora desconecta de verdad las señales (`Disconnect`, `Once`) y al
destruir un objeto desconecta sus señales y destruye sus descendientes, como Roblox. Así la prueba de
ciclo puede medir fugas de conexiones.

**Lo que estas pruebas NO demuestran**: física, colisiones reales, red y replicación, latencia,
render, rendimiento real, móvil, DataStores y MarketplaceService reales. Eso es la sección E.

## E. Pendiente en Roblox Studio (paso a paso)

Antes de empezar: abre el lugar de **ShooterRob** (no otro) con Rojo conectado o con el
`ShooterRob.rbxlx` del artefacto de GitHub Actions. Abre la **Output** (View → Output) y déjala
visible: cualquier línea roja o que empiece por `[Round]`, `[PlayerData]`, `[Combat]`,
`[Leaderboard]`, `[HealthRegen]`, `[Hazards]`, `[Event]`, `[Gifts]`, `[Hardpoint]`,
`[Domination]`, `[Pumpkins]` es un fallo que hay que apuntar (copia el texto completo).

Para ir rápido (y **deshacerlo al terminar**): en `src/shared/GameConfig.luau` baja
`IntermissionTime` a 5 y los `RoundTime` de `ModeSettings` a 60.

Para probar el guardado: Home → Game Settings → Security → **Enable Studio Access to API Services**
(solo en el lugar de ShooterRob). Sin esto, el progreso no se guarda en Studio (es normal).

### E1. Un jugador (Play, F5)
1. Arranca: sale la pantalla de inicio sin errores en Output.
2. JUGAR → buscando partida → partida encontrada → nombre del mapa → equipos (tú + 4 bots contra 5
   bots) → elige clase → 3-2-1 → apareces en tu base.
3. Dispara a un bot: marca de impacto, número de daño, baja con «ELIMINADO». Prueba un tiro a la
   cabeza (más daño).
4. Deja que te maten: pantalla de muerte (killcam, Regenerar). Pulsa Regenerar: reapareces por el
   mapa, no junto a un enemigo.
5. Muere y pulsa **Menú**: vuelves al lobby; el mundo **no** se queda gris (fallo 13).
6. Acaba la partida (baja `ScoreToWin`): killcam final → Resultados (escena 3D, recompensas, nivel) →
   vuelve a buscar partida sola. Prueba también **salir de Resultados nada más aparecer** (botón
   o Esc): la pantalla **no** debe quedarse negra (fallo 12).
7. Tienda: abre la tienda, prueba un objeto con monedas. Los de Robux tienen `ProductId = 0`:
   el botón no debe abrir ninguna compra real.
8. Para y vuelve a darle a Play (con API Services activado): tu nivel, monedas y equipamiento
   siguen ahí.

### E2. Dos jugadores (Test → Clients and Servers → Local Server, 2 jugadores)
1. Los dos en equipos distintos (o el reparto equilibrado); un bot menos por cada jugador.
2. Disparaos: el daño solo cuenta si de verdad os veis (prueba a disparar a través de una pared
   fina: no debe hacer daño).
3. Votación: los dos votáis en el descanso; el mapa ganador es el que sale.
4. Uno se va (cierra su ventana) en mitad de la partida: el otro sigue jugando, entra un bot en su
   lugar y no hay errores.
5. Cambio de equipamiento a la vez (skins, clases) en el lobby: se ve en el otro jugador.

### E3. Cinco jugadores + bots (Local Server, 5 jugadores)
1. 5 jugadores + 5 bots (5 contra 5). Los bots no se acumulan: tras cada partida, en el Explorer
   `Workspace.Bots` debe quedar vacío o con los de la siguiente, nunca más de 10 personajes.
2. Juega una partida entera; mira el **MicroProfiler** (Ctrl+F6) y `Stats` (Shift+F5): sin picos
   largos y memoria estable entre partidas.

### E4. Ciclo de partidas, cambio de mapa y de modo
1. Con `Modes` normal, juega **5 partidas seguidas** sin parar el servidor. En cada una apunta el
   mapa y el modo. Debe cambiar el mapa (solo uno en `Workspace.Map` a la vez) y el modo según la
   votación.
2. Fuerza cada modo (`Modes = { "SND" }`, etc.) al menos una partida: TDM, DOM, SND, CTF, KOTH, FFA,
   GUN, ELIM, INF, CAL. Cada uno termina y pasa a Resultados.
3. Tras las 5 partidas: Output sin errores; memoria del servidor (Shift+F5 → Server) parecida a la de
   la partida 2.

### E5. Compras (solo de prueba)
Mientras los ids sigan a `0` no hay nada que comprar con Robux. Cuando se creen los productos
(ver `ECONOMY.md`), en Studio las compras son de prueba (no cobran): comprar, cancelar y comprobar
que lo comprado aparece una sola vez, también tras volver a entrar.

### Qué anotar
Para cada paso: ✅ o ❌, y si es ❌, el texto de la Output y qué estabas haciendo. Con eso se corrige
en la Fase 2.

## F. Riesgos que quedan

- **Nada probado en el motor real**: física, red, replicación, latencia, render, móvil. El mock no
  lo sustituye.
- **Validación de impactos con tolerancia** (documentado, no cambiado sin pruebas reales de latencia):
  el impacto que dice el cliente puede estar hasta ~8 studs de la pieza para compensar el retardo, y
  la línea de visión se comprueba hasta ese punto; el tiro a la cabeza lo decide la pieza tocada.
  Endurecerlo sin medir en Studio con latencia real podría quitar impactos legítimos.
- **Bajas fuera de la fase de juego**: las recompensas de una baja no comprueban el estado de la
  ronda (en la práctica no se puede disparar en el lobby; revisar en Studio si en la pantalla final
  se puede hacer daño).
- **Doble guardado al cerrar** el servidor (`PlayerRemoving` + `BindToClose`): inofensivo (mismo dato,
  `UpdateAsync`), pero gasta peticiones de DataStore.
- **Rendimiento del cliente** sin medir en dispositivos: la killcam graba siempre, Resultados recorre
  descendientes cada 0,5 s, varios controladores con conexiones por vida (dependen de que el
  personaje se destruya, `PlayerCharacterDestroyBehavior = Enabled`).
- **Productos sin crear**: todos los ids a `0`.
- **Place/Universe ID de publicación**: no se pueden verificar desde aquí; hay que confirmarlos a mano
  antes de la primera publicación manual.

## G. Recomendaciones para la Fase 2

1. Pasar la sección E en Studio y traer los fallos (texto de Output) — es lo primero.
2. Con latencia real (Studio: Network → Incoming Replication Lag), medir cuánto se separa el impacto
   del cliente y ajustar la tolerancia de 8 studs y el tiro a la cabeza.
3. Perfilar en móvil (killcam, Resultados, efectos) y quitar lo que pese.
4. Crear los productos reales y probar las compras de prueba de Studio.
5. Ejecutar `tests/check.sh` y `tests/run_all.sh` antes de cada push (o añadirlos al workflow de
   validación).
