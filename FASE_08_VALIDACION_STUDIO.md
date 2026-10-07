# FASE 8 — Validación real en Roblox Studio

> Esta fase **no añade contenido**. Prepara un **modo QA** (solo Studio) y la lista de pruebas para
> encontrar problemas rápido en Roblox Studio. **Nada de esto se ha probado todavía en Studio**: las
> casillas están vacías a propósito. Los resultados se apuntan en `STUDIO_TEST_RESULTS.md`.
>
> Orden recomendado: **A → B → C** (un jugador con el ARX-27 en los tres mapas gold standard), después
> D, E y F. Los fallos, con el texto de la Output tal cual.

---

## A. Cómo activar el modo QA

1. En `src/shared/GameConfig.luau`, cambia **solo en tu copia local**:
   ```lua
   GameConfig.QA = { Enabled = true }
   ```
   (con Rojo conectado se aplica al momento; si usas el `.rbxlx`, edita el ModuleScript
   `ReplicatedStorage.Shared.GameConfig`).
2. Pulsa **Play** (o Test → Local Server). En la Output debe salir en naranja:
   `[QA] MODO QA ACTIVO (solo Studio). Abre el panel con F8, \ o el botón QA.`
3. **Al terminar, vuelve a dejarlo en `false`.** La prueba `qa` de `tests/run_all.sh` falla si se
   sube en `true`.

**Por qué es seguro** (comprobado en la prueba `qa`):
- Activo = `GameConfig.QA.Enabled == true` **y** `RunService:IsStudio()` (`src/shared/QA.luau`, la
  misma comprobación en el servidor y en el cliente).
- **Fuera de Studio no existe:**
  - el servidor no crea el RemoteEvent `QACommand`;
  - el cliente no crea el panel;
  - no hay comandos que mandar.
  - Pasa igual aunque alguien suba `Enabled = true` por error.
- **Doble cerrojo:** cada comando vuelve a comprobar `QA.IsActive()` en el servidor antes de hacer
  nada. Los comandos con datos que no valen (mapa, modo, arma, número) se rechazan.
- No depende de ninguna tecla secreta. La tecla solo abre un panel que ya tiene que existir.

**Cosas a saber:**
- **Progreso:** «Gana A / Gana B / Terminar» acaban la partida por el camino normal, con XP, monedas,
  rango y primera victoria. Si tienes activado *Enable Studio Access to API Services*, eso se guarda
  en tus datos reales. Para no tocarlos, déjalo desactivado.
- **Tiempos de espera:** ya no hace falta bajar `IntermissionTime` ni `RoundTime` en `GameConfig`.
  «Jugar ya» corta el descanso y «Terminar» acaba la partida.

## B. Cómo abrir el panel QA

- Botón rojo **«QA»** arriba a la izquierda (también en el Device Emulator), **F8** o **\\**. Si
  Studio se queda con F8, usa el botón.
- Con el panel abierto, el ratón queda libre.
- **Arriba:** estado, mapa y modo de ahora, y lo seleccionado.
- **Abajo:** registro de las últimas respuestas. Todo sale también en la Output con `[QA]`.

| Sección | Botones | Qué hacen |
|---|---|---|
| MAPA | ★ Construction, ★ Coastal, ★ MallRush, y los otros seis | Elegir mapa (★ = gold standard). |
| MODO | TDM, DOM, SND, CTF, KOTH, FFA, GUN, ELIM, INF, CAL | Elegir modo. |
| PARTIDA | Jugar ya · Al acabar · Empezar votado | **Jugar ya:** el mapa y el modo elegidos, cortando el descanso. **Al acabar:** los mismos, en la siguiente partida (la actual sigue). **Empezar votado:** corta el descanso con lo votado. |
| | Gana A · Gana B · Terminar | Termina la partida en curso. **Gana A/B:** ese equipo queda un punto por delante. **Terminar:** con el marcador que haya. En ELIM/SND acaba al terminar la ronda corta en curso. |
| JUGADOR | Reaparecer · ARX-27 · Arma ▶ · Munición · ARX-27 Gold | **ARX-27:** lo equipa (con la secundaria y el cuchillo de siempre). **Arma ▶:** pasa por las armas principales. **Munición:** llena cargadores y reserva. **ARX-27 Gold** (Fase 9): equipa el ARX-27 y lo enseña solo en tu pantalla con la skin de referencia Operación Roja, sin dártela (ver `FASE_09_ARX27_GOLD_STANDARD.md`, sección L). **Al reaparecer vuelve la clase elegida.** |
| BOTS | +1 · −1 · 5v5 (10) · Sin bots | Total de jugadores + bots (de 0 a 16; normal = 10). Los bots entran o salen en ~1 s y solo durante la partida. |
| GRÁFICOS Y RENDIMIENTO | Calidad ▶ · HUD rendimiento · Zona segura | **Calidad ▶:** pasa por Auto, Baja, Media, Alta y Ultra (el sistema de ajustes de siempre). **HUD rendimiento** y **Zona segura:** ver K y F2. |
| DEPURACIÓN | Spawns · Objetivos A/B · Límites · Puntos bots · Rutas bots · Disparos · Telemetría | Todo **apagado** al empezar. Ver H, I, G y L. |
| ONBOARDING Y 5 PARTIDAS | Jugador nuevo · Foto contadores | **Jugador nuevo:** los consejos salen como si fueras nivel 1, sin tocar tus datos. **Foto contadores:** ver E2. |

**Ayudas visuales** (solo las ves tú; van dentro de la cámara y no se replican):
- **Spawns:** cajas en los puntos de aparición, con su equipo o «FFA».
- **Objetivos A/B:** sitios de bomba (con su letra), bases de bandera y zonas de dominio o control.
- **Límites:** paredes invisibles del mapa, en rojo.
- **Puntos bots:** posiciones a las que van los bots (`BotSpot`).
- **Rutas bots:** el camino que sigue cada bot (bolitas azules, las ya pasadas en gris). Las dibuja
  el servidor cada segundo; sin colisión, no paran balas.
- **Disparos:** una línea por bala durante 2 s. Verde = ha dado a alguien; blanca = no. Sin colisión,
  no estorban a los rayos.
- **Telemetría:** ver L.

---

## C. Prueba con 1 jugador (Play)

**Preparación:** modo QA activo · Output visible · panel → ★ Construction + TDM → **Jugar ya** →
**ARX-27**.

### C1. ARX-27 (referencia de todo el gunplay)
- [ ] **Disparo suelto:**
  - fogonazo, sonido y casquillo a la derecha;
  - el arma retrocede y vuelve; la cámara da un golpe arriba y vuelve sola;
  - sin retraso entre la tecla y la reacción.
- [ ] **Recoil (ráfaga contra una pared):**
  - la mira sube y se controla tirando hacia abajo;
  - recupera algo al soltar;
  - con **Disparos** encendido, las líneas caen donde apunta la mira (no más arriba por el golpe de
    cámara).
- [ ] **ADS (clic derecho):** transición suave, FOV sin saltos, sensibilidad proporcional; apuntando
      casi no se balancea.
- [ ] **Sprint (Shift):** el arma baja de lado con algo más de FOV; disparar corriendo saca del
      sprint enseguida y el disparo no se pierde.
- [ ] **Sway (quieto, mirando alrededor):** el arma sigue al ratón con un retraso pequeño, sin
      «flotar».
- [ ] **Bob (andar y correr):** balanceo leve al andar y mayor al correr, sin efecto barco.
- [ ] **Recarga con balas (R):** táctica, más corta.
- [ ] **Recarga vacía** (vacía el cargador): más larga, con el tirón de montar el arma; recarga sola
      al vaciar.
- [ ] **Cancelación:** cambiar de arma a mitad de recarga la corta, deja de sonar y las balas no
      suben.
- [ ] **Inspección (V):** gira el arma; se cancela al disparar, recargar, apuntar o correr.
- [ ] **Cambio de arma (1/2/3, Q, rueda):** sube rápido y se puede disparar enseguida.
- [ ] **FOV:** Ajustes → FOV cambia el de la cámara; al soltar el apuntado y al morir vuelve al valor
      elegido.
- [ ] **Muerte:** pantalla de muerte con killcam, «Regenerar» y «Menú». El mundo no se queda gris al
      volver al menú.
- [ ] **Respawn:** Regenerar (o **Reaparecer** del panel) te pone en un punto de tu equipo, no junto a
      un enemigo.

### C2. Mapas (repetir en ★ Construction, ★ Coastal y ★ MallRush; después los otros seis)
- [ ] **Colisiones:** recorre el borde y las coberturas. No te atascas ni atraviesas paredes; lo
      decorativo (franjas, rótulos, neones) no choca.
- [ ] **Escaleras y rampas:** se suben andando sin saltar ni quedarse enganchado.
- [ ] **Alturas:** las plataformas altas se alcanzan por su camino previsto y no hay huecos para salir
      del mapa (**Límites** encendido para verlo).
- [ ] **A/B:** con **Objetivos A/B**, los sitios de bomba están donde dicen los letreros y se leen
      desde lejos.
- [ ] **Visibilidad:** un enemigo al otro lado del mapa se distingue. Con la neblina y en la variante
      de noche, la luz no deslumbra.
- [ ] **Spawns** (encendido): ninguno dentro de una pared ni a la vista directa del spawn enemigo.

---

## D. Prueba con 2 jugadores (Test → Clients and Servers → Local Server, 2 jugadores)

**Preparación:** en las dos ventanas, panel → **Sin bots** (para no confundir) → ★ Coastal + TDM →
**Jugar ya**.

- [ ] **Daño:** cada disparo baja la vida del otro; a través de una pared fina, **no**.
- [ ] **Headshot:** más daño, hitmarker dorado y sonido distinto.
- [ ] **Hitmarker:** blanco al acertar, en el mismo instante del disparo.
- [ ] **Kill confirm:** X roja, aviso «ELIMINADO» (con «DISPARO A LA CABEZA» si toca) y sonido de baja.
- [ ] **Killfeed:** la baja sale arriba a la derecha con el arma (o su nombre en calidad Baja) y 🎯 si
      fue a la cabeza.
- [ ] **Sonidos espaciales:** el disparo del otro suena desde su posición; de lejos más sordo; las
      balas que pasan cerca hacen «fiuu».
- [ ] **Latencia:**
  - File → Studio Settings → Network → **Incoming Replication Lag** = 0,1 y después 0,2;
  - el daño a un jugador que corre se sigue registrando;
  - activa **Telemetría** (ver L).
- [ ] **HitTelemetry:** cada impacto sale en el registro del panel (ver L). Apunta 20-30 muestras
      corriendo y quieto.
- [ ] **Killcam:** al morir se ve la repetición desde quien te mató.
- [ ] **Respawn:** los dos reaparecen bien tras morir.
- [ ] **Resultados:** panel → **Gana A**. Los dos ven Resultados: el ganador «Victoria», el otro
      «Derrota», cada uno con sus números.

---

## E. Prueba 5 contra 5

**Preparación:** Local Server con 1-5 jugadores + panel → **5v5 (10)** → ★ MallRush + SND → **Jugar ya**.
Abre el MicroProfiler (Ctrl+F6) y la consola de desarrollo (F9).

- [ ] **CPU:** en el MicroProfiler, sin picos largos al disparar todos a la vez ni al cambiar de ronda.
- [ ] **FPS:** **HUD rendimiento** encendido; anota los FPS en un tiroteo (cliente) en
      `STUDIO_TEST_RESULTS.md`.
- [ ] **Memoria:** consola F9 → Memory (cliente y servidor); no sube sin parar durante la partida.
- [ ] **Navegación:** con **Rutas bots**:
  - los bots siguen caminos con sentido;
  - no se quedan atascados contra una pared ni dando vueltas;
  - no salen del mapa.
- [ ] **Disparos:** los bots aciertan de forma creíble (ver I) y su daño llega.
- [ ] **Granadas:** los bots las lanzan de vez en cuando (no en bucle) y el aviso de granada sale.
- [ ] **Objetivos:** en SND plantan y desactivan la bomba en los sitios A/B (**Objetivos A/B**
      encendido).
- [ ] **Partículas:** con Alta y con Baja (**Calidad ▶**), los efectos se reducen en Baja pero el
      hitmarker y los avisos no.
- [ ] **ClientFX:** en el Explorer, `Workspace.ClientFX` no crece sin parar (como mucho ~50 marcas y 8
      casquillos a la vez).
- [ ] **Cambios de ronda (SND):**
  - todos vuelven a su base;
  - los muertos reaparecen;
  - no quedan bots de más (**Foto contadores**: bots ≤ 10 − jugadores).

### E2. Prueba de 5 partidas seguidas (sin parar el servidor)

Con 1 jugador + bots. Antes de empezar y **en el descanso tras cada partida**, pulsa **Foto
contadores**. Deja escrita en la Output una línea del cliente y otra del servidor con:
- memoria;
- ScreenGui abiertas;
- mapas en el workspace;
- bots;
- efectos de ClientFX;
- número de instancias.

| # | Mapa + modo | Cómo |
|---|---|---|
| 1 | Construction + TDM | ★ Construction + TDM → **Jugar ya**; juega un rato → **Gana A** |
| 2 | Coastal + DOM | ★ Coastal + DOM → **Jugar ya**; → **Gana B** |
| 3 | MallRush + SND | ★ MallRush + SND → **Jugar ya**; juega 2-3 rondas → **Terminar** |
| 4 | Aleatorio | Deja que vote el juego (no pidas nada) → **Empezar votado** |
| 5 | Aleatorio | Igual que la 4 |

Después de cada partida:
- [ ] **Mapas anteriores destruidos:** «mapas en workspace» = 1 en todas las fotos.
- [ ] **Bots anteriores destruidos:** en el descanso, bots = 0 (se quitan al acabar la partida).
- [ ] **ClientFX estable:** en el descanso vuelve a un número parecido (sin crecer partida a partida).
- [ ] **UI limpia:** el número de ScreenGui es el mismo en todos los descansos (la lista sale en la
      Output).
- [ ] **Conexiones:** Roblox no deja contarlas desde un script. Se miden de forma indirecta: memoria
      e instancias parecidas entre la foto de la partida 2 y la de la 5 (la 1 calienta cachés).
- [ ] **Memoria:** sin subida continua de la foto 2 a la 5 (anota los MB de cada foto).
- [ ] **Results:** sale en cada partida con los datos de esa partida.
- [ ] **Retorno al lobby:** tras Resultados se vuelve a buscar partida o al inicio sin pantalla negra.
- [ ] La Output no tiene líneas rojas ni `[Round] Error en la ronda`.

---

## F. Device Emulator (Test → Device)

Para cada pantalla y dispositivo:
- [ ] nada cortado;
- [ ] nada fuera de la pantalla;
- [ ] los botones se pueden pulsar;
- [ ] los textos se leen.

| Pantalla | PC 1920×1080 | Tablet (iPad) | Móvil grande | Móvil pequeño (iPhone SE) | Con muesca (iPhone 14 o similar) |
|---|---|---|---|---|---|
| Home (inicio) | [ ] | [ ] | [ ] | [ ] | [ ] |
| Loadout (elige tu clase / Armamento) | [ ] | [ ] | [ ] | [ ] | [ ] |
| HUD de partida | [ ] | [ ] | [ ] | [ ] | [ ] |
| Party (Escuadra) | [ ] | [ ] | [ ] | [ ] | [ ] |
| MatchFound (partida encontrada) | [ ] | [ ] | [ ] | [ ] | [ ] |
| MapIntro (presentación del mapa) | [ ] | [ ] | [ ] | [ ] | [ ] |
| TeamIntro (presentación de equipos) | [ ] | [ ] | [ ] | [ ] | [ ] |
| Results (resultados) | [ ] | [ ] | [ ] | [ ] | [ ] |
| Store (tienda) | [ ] | [ ] | [ ] | [ ] | [ ] |
| Pass (pase) | [ ] | [ ] | [ ] | [ ] | [ ] |

Para llegar rápido a cada pantalla:
- **MatchFound, MapIntro, TeamIntro y Loadout:** **Jugar ya** desde el inicio.
- **Results:** **Gana A**.
- **Store y Pass:** desde el inicio.

### F2. Zona segura (muesca)
Panel → **Zona segura**:
- **verde:** el área segura del dispositivo (fuera de la muesca y la barra de inicio);
- **amarillo:** el área libre de la barra de Roblox.

Comprueba, por este orden de prioridad:
- [ ] **Vida** (abajo a la izquierda) dentro del verde.
- [ ] **Munición** dentro del verde.
- [ ] **Killfeed** dentro del verde.
- [ ] **Objetivos y marcador** (arriba) dentro del amarillo.
- [ ] **Botones táctiles** dentro del verde y alineados con el salto de Roblox.

**Estado del código:**
- Los menús del flujo ya usan la zona segura (`ScreenInsets = CoreUISafeInsets`).
- El **HUD** de partida y los **botones táctiles** ocupan la pantalla entera (`IgnoreGuiInset`).
- **No se ha cambiado** porque sería una modificación amplia sin haber reproducido el problema.

**Arreglo previsto, si algo queda fuera del verde:**
- separar el HUD en dos ScreenGui:
  - la información (vida, munición, killfeed, objetivos) con `ScreenInsets = DeviceSafeInsets`;
  - los velos de pantalla completa (visor, viñeta de daño) sin zona segura, para que no quede una
    franja sin tapar;
- los botones táctiles se colocan alrededor del salto de Roblox: primero hay que ver dónde lo pone
  Roblox en un iPhone con muesca.

---

## G. Gunplay (afinado, después de C1)

- [ ] **Arma ▶** por cada principal: repite C1 abreviado. Cada tipo se nota distinto pero ninguno
      injusto:
  - subfusil más rápido al apuntar;
  - ametralladora más lenta;
  - escopeta, recarga cartucho a cartucho;
  - francotirador, con visor.
- [ ] Con **Disparos**, a 10, 30 y 60 studs: la dispersión de cada arma es la esperada; la línea va
      de la boca del arma hacia la mira.
- [ ] **Calidad Baja:** sin casquillos ni marcas; hitmarker, kill confirm y killfeed iguales.
- [ ] **Ajustes → Efectos de pantalla: Reducidos:** el golpe de cámara casi desaparece.
- [ ] Apuntar no desenfoca nada (`GameConfig.AimDepthOfField = false`).
- [ ] Anota lo que haya que ajustar en `STUDIO_TEST_RESULTS.md`. Los valores están en
      `src/shared/WeaponFeel.luau` (no se cambian sin probarlos).

## H. Mapas

Para cada mapa gold standard (de `FASE_03_VISUAL_MAPAS.md`, sección F):
- [ ] **Construction:**
  - las franjas amarillas de la torre no parpadean;
  - la red roja se ve de lejos;
  - las barandillas no son chillonas al atardecer.
- [ ] **Coastal:**
  - es el más luminoso sin quemar el blanco;
  - el faro se ve desde el paseo;
  - las contraventanas azules contrastan.
- [ ] **MallRush:**
  - el techo de doble altura se ve claro;
  - la fuente destaca;
  - los rótulos dicen «MALL RUSH»;
  - las tiras de neón no queman.
- [ ] **Variantes de luz** (repite **Jugar ya** hasta que salga cada una: atardecer, mediodía,
      noche): enemigos visibles en todas.
- [ ] **Calidad Baja:** desaparecen los detalles pequeños, pero no los letreros A/B ni los objetivos.
- [ ] **Los otros seis mapas:** C2 abreviado (colisiones, spawns y objetivos con las ayudas
      visuales).

## I. Bots

Reglas del juego (de `FASE_06_BOTS_ONBOARDING.md`); cada una se comprueba así:
- [ ] **Sin wallhack:** escóndete detrás de una pared con un bot cerca. No te dispara mientras no te
      vea (el rayo de cabeza a cabeza está tapado).
- [ ] **Sin conocimiento instantáneo:** acércate por la espalda de un bot (fuera de su cono de 140°)
      sin disparar. No se gira hasta que estás a ~14 studs o disparas.
- [ ] **Sin reacción de 0 ms:** al aparecer delante de un bot, tarda un momento (0,3-0,7 s) en
      disparar, y los primeros tiros fallan más.
- [ ] **Sin puntería perfecta:** de lejos (más de 60 studs) fallan bastante; andando y contra un
      objetivo que corre, más.
- [ ] **Sin headshots perfectos:** en la killcam y el killfeed, pocas bajas de bot a la cabeza.
- [ ] **Roles:** asalto, subfusil, tirador (se aposta lejos), escopeta (agresivo de cerca) y
      ametralladora; como mucho uno de los tres últimos por equipo.
- [ ] **Navegación** (**Rutas bots** y **Puntos bots**): sin atascos ni bucles; van a los
      objetivos del modo (DOM, CTF, SND).
- [ ] **Dificultad:** con una cuenta Bronce son más blandos que con una Oro (`SkillByRank`). Para
      probarlo, cambia el rango en la consola del servidor. Se ajusta en `GameConfig.Bots`.

## J. UI

- [ ] **Flujo completo:**
  - inicio → JUGAR → buscando partida → partida encontrada → mapa → equipos → clase → 3-2-1 →
    partida → Resultados → vuelta;
  - sin pantallas negras ni pantallas que se quedan colgadas.
- [ ] **Presentación de equipos:** las tarjetas se llenan sin parpadear cuando entran los bots.
- [ ] **Consejos** (panel → **Jugador nuevo**):
  - dispara a la cadera de lejos 8 veces → consejo de apuntar;
  - vacía el cargador → consejo de recargar;
  - baja de 35 de vida → consejo de cubrirse;
  - no se repiten, no salen seguidos y se quitan al morir.
- [ ] **Tarjeta de controles (PC):** incluye «1 2 3 o rueda: cambiar arma» y cabe en dos líneas.
- [ ] **Textos escalados (`TextScaled`):** las misiones con nombres largos y las tarjetas de clase se
      leen en el teléfono.
- [ ] **Tienda:** los objetos de Robux tienen `ProductId = 0`; el botón **no** abre ninguna compra.

## K. Rendimiento

**HUD rendimiento** (panel). Solo enseña lo que Roblox da de verdad; si algo no está disponible,
dice «no disponible».

| Dato | De dónde sale | Fiable |
|---|---|---|
| FPS | Fotogramas contados en el cliente cada 0,5 s | Aproximado. En Studio, el editor también consume |
| Memoria | `Stats:GetTotalMemoryUsageMb()` (cliente) | Sí (memoria total del proceso) |
| Ping | `Player:GetNetworkPing()` | Lo que da Roblox. En Studio local es ~0; con Incoming Replication Lag, sube |
| Jugadores · bots | `Players` y `Workspace.Bots` | Sí |
| Piezas del mapa | Recuento de `Workspace.Map` cada 5 s | Sí |
| Efectos | Descendientes de `Workspace.ClientFX` | Sí |
| Calidad | `ClientState.EffectiveQuality` (la aplicada de verdad) | Sí |

- [ ] Anota FPS y memoria en Construction, Coastal y MallRush con **Calidad** Baja y Alta.
- [ ] **MicroProfiler (Ctrl+F6)** en un 5 contra 5: anota las etiquetas que más tarden.
- [ ] **Consola F9 → Scripts:** actividad de `HUD`, `Killcam`, `Minimap` y `WorldFX` (candidatos de
      `FASE_05_MOVIL_RENDIMIENTO.md`, sección D).
- [ ] **Móvil real** (no el emulador): calidad Auto (debe quedar en Baja), FPS en un tiroteo y
      temperatura tras 15 minutos.
- No hay profiler propio: para el detalle, el MicroProfiler de Roblox.

## L. Networking

- [ ] **Telemetría** (panel, encendida desde QA; se apaga sola al cerrar Studio porque el valor del
      archivo sigue en `false`). Por cada impacto sale una línea como esta:
  `Impacto ARX27 · 31.0 st · holgura 0.40 · cabeza: cliente sí / servidor sí · aceptado · ping 50 ms`
  - **st:** distancia del tiro;
  - **holgura:** distancia entre el punto que dice el cliente y la pieza tocada;
  - **cabeza cliente:** el cliente dice que tocó la cabeza;
  - **cabeza servidor:** el servidor lo da por tiro a la cabeza;
  - **ping:** `GetNetworkPing` de quien disparó.
- [ ] Cada 200 muestras, la Output del servidor resume el reparto: `[Combat] Holgura de impactos…`.
- [ ] Prueba sin retraso y con Incoming Replication Lag a 0,1 y 0,2, contra un objetivo quieto y otro
      corriendo. Anota cuántos impactos pasan de 4, 6 y 8 de holgura.
- [ ] **La tolerancia (~8 studs) NO se cambia ahora.** Solo se mide. Con los datos se decide en otra
      fase.
- [ ] Si hay «cabeza cliente sí / servidor no» a menudo, anótalo con el arma y la distancia.

## M. Resultados

- [ ] **Gana A:** el equipo A ve «VICTORIA» y el B «DERROTA».
- [ ] **Gana B:** lo contrario.
- [ ] **Terminar** con el marcador igualado: «EMPATE» (si alguien va ganando, gana ese).
- [ ] **Datos de la partida:** bajas, muertes, asistencias, MVP y podio coinciden con lo que pasó.
- [ ] **Recompensas:** XP, monedas y progreso del pase. Primera victoria del día solo una vez.
- [ ] **Escena 3D:** los personajes con sus trajes y la cámara sin atravesar paredes.
- [ ] **Salir enseguida** (botón o Esc nada más aparecer): no se queda la pantalla negra.
- [ ] **Retorno:** tras Resultados, vuelta a buscar partida o al inicio, sin restos de la partida
      anterior (marcador, bots, efectos).

## N. Checklist final

- [ ] A. Modo QA activado, y desactivado al terminar (`Enabled = false` antes de cualquier commit).
- [ ] C. Un jugador: ARX-27 (C1) y los tres mapas gold standard (C2).
- [ ] D. Dos jugadores, con latencia simulada.
- [ ] E. 5 contra 5 y prueba de 5 partidas (E2) con las fotos de contadores.
- [ ] F. Device Emulator: las 10 pantallas en 5 dispositivos, y la zona segura (F2).
- [ ] G. Gunplay de cada tipo de arma.
- [ ] H. Mapas: los 3 gold standard a fondo y los otros 6 por encima.
- [ ] I. Bots: las 5 reglas, los roles y la navegación.
- [ ] J. UI: flujo, consejos, textos y tienda sin compras.
- [ ] K. Rendimiento: FPS y memoria anotados; MicroProfiler; móvil real.
- [ ] L. Telemetría con 0, 0,1 y 0,2 s de retraso.
- [ ] M. Resultados en victoria, derrota y empate.
- [ ] Todos los fallos están en `STUDIO_TEST_RESULTS.md` con pasos, severidad y texto de la Output.

## Límites del modo QA (lo que no hace)

- No sustituye a jugar: no mide sensaciones (gunplay, dificultad, lectura del mapa).
- No hay profiler propio. Los FPS son aproximados y las conexiones no se pueden contar desde un
  script.
- No toca datos guardados, economía, pase ni compras. Pero las partidas terminadas con el panel dan
  los premios normales (ver A).
- «Rutas bots» enseña el camino calculado, no la decisión del bot (por qué va ahí).
- Las ayudas visuales se rehacen al cambiar de mapa. Si el mapa cambia piezas durante la partida,
  vuelve a pulsar el interruptor.
