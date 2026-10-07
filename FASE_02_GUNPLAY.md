# FASE 2 — Gunplay premium

> **Importante:** todo se ha comprobado **fuera de Roblox Studio** (luau-lsp, `rojo build` y pruebas
> Lune con un mock de Roblox). **La sensación de disparar no se puede probar con un mock**: hay que
> pasar la sección F en Studio antes de dar nada por bueno. No se ha cambiado el equilibrio del juego
> (daño, cadencia, dispersión, subida de la mira, tolerancias del servidor).

## A. Estado inicial

La base ya era más completa de lo que parecía. El `WeaponController` tenía viewmodel procedural con
muelles, ADS, sprint con disparo pendiente al salir, recarga táctica y vacía con sonidos a tiempo,
cerrojo y bombeo, inspección (V), humo de cañón, casquillos e inercia del ratón. `Effects` tenía
impactos por material, marcas reutilizadas y fogonazo realista reutilizado. El HUD ya mostraba
hitmarker normal, de cabeza y de baja, aviso de baja con multibajas, asistencias y medallas.

Lo que faltaba:
- Casi todos los números estaban **fijos en el código** e iguales para todas las armas: ADS 14,
  sprint 10, muelles 260/220/180, sacar el arma en 0,4 s.
- El **retroceso de cámara era solo de juego** (la subida de la mira). No había un golpe visual que
  comunicara la potencia sin desviar las balas.
- Los efectos de las armas **no dependían de la calidad gráfica ni del móvil**: 80 marcas de bala,
  casquillos en móvil y todas las partículas en calidad Baja.
- **Audio**: capas genéricas por tipo (cuerpo, estampido, mecanismo, cola), pero ningún sitio donde
  poner el audio propio de cada arma.
- **Sin ganchos (hooks)** para futuras animaciones: recarga, recarga vacía, inspección, cambio de arma.
- Detalles sueltos:
  - la ballesta y el paintball soltaban casquillos;
  - la inspección no se cancelaba al correr ni al dar un golpe cuerpo a cuerpo;
  - en móvil, apuntar (interruptor) seguía activo al cambiar de arma;
  - al reaparecer quedaban restos de apuntado y sprint.

## B. Arquitectura encontrada

| Pieza | Dónde | Qué hace |
|---|---|---|
| Disparo, recoil, ADS, sprint, bob, sway, recarga, inspección, viewmodel | `src/client/Modules/WeaponController.luau` (`fire`, `renderStep`) | Todo procedural, cada fotograma |
| Fogonazo, trazadoras, impactos por material, marcas, casquillos, humo | `src/client/Modules/Effects.luau` | Local, con reutilización de piezas y emisores |
| Hitmarker, aviso de baja, multibaja, asistencia, medallas, killfeed | `src/client/Modules/HUD.luau` (`onHitConfirm`, `showKillBanner`, `onKillFeed`) | Lo confirma el servidor (`HitConfirm`, `KillFeed`) |
| Sonidos con capas y distancia (sordo y con retraso de lejos) | `src/shared/Sounds.luau` (`PlayShot`, `PlayGun`) | Grupo de armas con compresor |
| Validación del disparo, daño, cabeza, munición, recarga | `src/server/Modules/Combat.luau` (`onFire`, `onReload`) | Autoritativo: el servidor decide daño, bajas y balas |
| Estadísticas | `src/shared/Weapons.luau` | Daño, cadencia, `Recoil`, `Spread`, `AimFOV`… |

Remotos de armas: `Fire`, `Reload`, `Melee`, `HitConfirm`, `ShotFX` y `KillFeed`. No se ha añadido
ninguno: los efectos nuevos son locales.

## C. Cambios realizados

1. **`WeaponFeel` (nuevo, `src/shared/WeaponFeel.luau`)**: perfiles por tipo (Rifle, Pistol, SMG, LMG,
   Shotgun, Marksman, Sniper, Launcher, Melee) y ajustes por arma (`Overrides`). Arma de referencia:
   **ARX-27** (`ReferenceWeapon`). Todos los valores que antes estaban fijos salen de aquí.
2. **Tres retrocesos separados** (en `WeaponController.fire` y `renderStep`):
   - **Juego** (`WeaponFeel.Gameplay`): dispersión, apertura y subida de la mira con patrón propio y
     recuperación del 65 %. **Mismos valores que antes**, iguales para todas las armas.
   - **Cámara (nuevo, visual)**: un muelle sube la cámara unos grados, con algo de giro lateral y
     alabeo, y vuelve del todo. Se aplica como diferencia respecto al fotograma anterior y **se
     descuenta al calcular la dirección del disparo**, así que no cambia dónde van las balas.
     - El muelle usa la solución exacta, así que se siente igual a 30, 60 o 240 fps.
     - Su fuerza se calibra para que el pico sea exactamente `Camera.Punch` grados.
     - Apuntando se reduce (`AimScale`); con «Efectos de pantalla: Reducidos», al 30 %.
   - **Arma en la mano**: los muelles de antes, ahora por perfil (rigidez y amortiguación) y con
     multiplicadores de retroceso, subida y lado.
3. **ADS, sprint y sacar el arma por tipo**:
   - **ADS**: subfusil 16, pistola 17, fusil 14, tirador 13, francotirador y lanzacohetes 12,
     ametralladora 11.
   - **Salir del sprint**: pistola 13, subfusil 12, ametralladora 7.
   - **Animación de sacar el arma**: pistola 0,32 s, fusil 0,4 s, ametralladora 0,5 s.
   - **Cuándo se puede disparar tras sacarla**: sigue en 0,25 s para todas (`EQUIP_READY`).
4. **Balanceo y sway por tipo**: la ametralladora se balancea menos y el subfusil algo más. Apuntando,
   la inercia baja al 25 % y el balanceo al 10 %, como antes.
5. **Fogonazo por arma**:
   - **Tamaño y duración**: de 0,03 s (subfusil) a 0,08 s (lanzacohetes).
   - **Luz**: con supresor (Ghostline XR) no hay golpe de luz; la ballesta no tiene fogonazo.
   - **Humo**: proporcional al tipo de arma.
6. **Presupuesto de efectos por calidad y móvil** (`WeaponFeel.Quality` y `MobileCap`, en `Effects`):
   - **Baja**: sin casquillos, sin marcas, con el 40 % de partículas de impacto y sin humo.
   - **Media**: 30 marcas.
   - **Alta/Ultra**: 50 marcas.
   - **Móvil**: sin casquillos, como mucho 20 marcas y el 60 % de partículas.
   - Al pasar el límite de marcas se reutiliza la más antigua.
   - **No se reducen** el hitmarker, los avisos de baja, las trazadoras ni los impactos sobre
     personas.
7. **Audio por capas con huecos propios** (`Sounds.WeaponAudio`):
   - **Huecos**: 9 por arma (`ShotClose`, `ShotMechanical`, `ShotTail`, `Reload`, `MagIn`, `MagOut`,
     `Bolt`, `Empty`, `Equip`), todos a `""`, que significa usar el genérico de siempre.
   - **Uso**: `Sounds.PlayWeapon` y `PlayShot` usan el sonido propio si existe, y si no el de antes.
   - **Reutilización**: los sonidos propios también se reutilizan.
8. **Ganchos para animaciones y audio**: `ClientState.WeaponEvent` emite `Equip`, `Fire`,
   `ReloadStart` (con `Empty` y `Duration`), `ReloadCancel`, `Inspect` e `InspectCancel`.
9. **Inspección** (V, ya existía): ahora también se cancela al correr y al dar un golpe cuerpo a
   cuerpo, además de al disparar, recargar, apuntar y cambiar de arma.
10. **Limpieza de estado**:
    - al reaparecer o morir se reinician el apuntado, el sprint, el golpe de cámara y el empujón de FOV;
    - en móvil, el apuntado por interruptor se suelta al cambiar de arma;
    - la ballesta y el paintball ya no sueltan casquillos.
11. **Instrumentación de impactos** (`GameConfig.HitTelemetry`, apagada): mide en el servidor cuánto
    se separa el impacto del cliente de la pieza tocada. Agrupa los resultados en tramos de
    0,5/1/2/4/6/8 studs y más de 8, aceptados y rechazados, y la holgura máxima en tiros a la cabeza.
    Saca un resumen en la consola y en `Combat.HitTelemetry.LastReport`. **No cambia ninguna
    tolerancia.**

Lo que **no** se ha cambiado:
- daño, cadencia, dispersión, cargadores, tolerancias del servidor y validaciones NaN de la Fase 1;
- la recarga, que sigue siendo autoritativa: el cliente solo sube las balas cuando el servidor cambia
  el atributo `Ammo`;
- las skins, que no cambian nada del combate (comprobado en pruebas).

## D. Configuraciones añadidas

En `src/shared/WeaponFeel.luau`:

```lua
WeaponFeel.Gameplay = { ClimbBase = 0.75, ClimbGrowth = 0.5, Recover = 0.65, ... } -- equilibrio: no tocar sin probar
WeaponFeel.Profiles.Rifle = {}  -- = perfil base (arma de referencia ARX-27)
-- Perfil base:
Camera = { Punch = 0.3, PunchSide = 0.1, PunchRoll = 0.35, Stiffness = 320, Damping = 30, AimScale = 0.55, Shake = 0, FovKick = 0 }
View   = { Back = 1, Rise = 1, Side = 1, Stiffness = 260, Damping = 24, RotStiffness = 220, RotDamping = 20, AimScale = 0.5 }
Aim    = { Speed = 14, Sway = 0.25, Bob = 0.1 }
Sprint = { Fov = 6, Speed = 10 }
Equip  = { Time = 0.4 }
Flash  = { Scale = 1, Duration = 0.04, Light = 1, Smoke = 1 }
Shells = { Enabled = true }
Heat   = { PerShot = 1 }
WeaponFeel.Overrides.HandCannon = { Camera = { Punch = 0.8, Shake = 0.05, FovKick = 0.22 }, ... }
WeaponFeel.Quality = { Baja = {...}, Media = {...}, Alta = {...}, Ultra = Alta }
WeaponFeel.MobileCap = { Shells = false, BulletMarks = 20, ImpactParticles = 0.6 }
```

Golpe de cámara por tipo (grados): subfusil 0,18 · ametralladora 0,25 · fusil 0,3 · pistola 0,45 ·
tirador 0,6 · revólver 0,8 · escopeta y lanzacohetes 1,0 · francotirador 1,2.

Otros ajustes:
- En `src/shared/Sounds.luau`: `Sounds.WeaponAudio[arma][hueco] = "rbxassetid://..."` (o `{ Id, Volume, Pitch }`).
- En `src/shared/GameConfig.luau`: `GameConfig.HitTelemetry = { Enabled = false, ReportEvery = 200 }`.

**Por qué cambiar el ADS y la salida del sprint por tipo no rompe el equilibrio:**
- Los cambios son pequeños: de ±0,05 a ±0,1 s.
- Siguen el papel de cada arma: el subfusil es débil a distancia y va más rápido; la ametralladora
  (80 balas, más daño) y el francotirador (baja de un tiro a la cabeza) van algo más lentos.
- La dispersión y el daño no cambian.
- Si en Studio se nota injusto, basta con poner `Aim.Speed = 14` y `Sprint.Speed = 10` en el
  perfil.

## E. Pruebas automáticas

Todas en `tests/harness/`, ejecutadas con `tests/run_all.sh`. Resultado y forma de repetirlas en
`tests/README.md`.

| Prueba | Qué comprueba (lógica, no sensación) |
|---|---|
| `weaponfeel` (nueva) | Las 17 armas de fuego tienen perfil completo y con valores razonables. El golpe de cámara llega a sus grados (±25 %) y **vuelve a 0 en 1 s**, igual a 30 y 240 fps. Cada tipo difiere en el sentido esperado. Sacudida, FOV y calor del cañón son iguales que antes. Los perfiles no tocan estadísticas y el retroceso de juego conserva sus valores. Las skins no cambian el combate. Los presupuestos son coherentes (el móvil nunca tiene más que el PC). Los 9 huecos de audio existen y el genérico es el respaldo. La instrumentación viene apagada. |
| `gunfeel` (nueva) | Cliente completo en el mock. Comprueba los eventos `Equip`, `Fire`, `ReloadStart`, `ReloadCancel`, `Inspect` e `InspectCancel`. Hay casquillo en calidad Alta y no en Baja. **La recarga no regala balas al acabar la animación**: llegan cuando el servidor cambia `Ammo`. Cambiar de arma cancela la recarga. A los 0,1 s el subfusil apunta más que el fusil y el fusil más que la ametralladora. El FOV vuelve al soltar y al morir, y no quedan temblores pendientes. |
| `hittelemetry` (nueva) | Apagada no mide nada. Encendida mide sin cambiar el daño. Un impacto a 6 studs se sigue aceptando y uno a 12 se sigue rechazando, como antes. Emite el resumen. |
| `shooting`, `realshots`, `realhits`, `weaponanims`, `weaponsounds`, `scopesway`, `combatfx`, `phonefx`… | Siguen pasando: la mira sube con el retroceso y recupera parte, el sprint retrasa el disparo sin perderlo y el disparo automático no dispara a compañeros ni a escudos. |

**Lo que no se puede probar con el mock** (necesita Studio):
- la sensación del golpe de cámara, de los muelles, del sway y del bob;
- la sincronía real de fogonazo, sonido y casquillo;
- el audio espacial;
- el rendimiento con 10 jugadores disparando;
- la red y la latencia.

## F. Pruebas obligatorias en Studio

Abre el lugar de **ShooterRob** con Rojo y deja la ventana Output visible. Para comparar, prueba
siempre primero el **ARX-27** (referencia) y luego el resto.

### 1 jugador (Play)
1. **Disparo suelto con el ARX-27**:
   - fogonazo breve con golpe de luz, sonido, casquillo a la derecha, el arma retrocede y vuelve, y la
     cámara da un pequeño golpe hacia arriba que vuelve sola;
   - todo en el mismo instante, sin retraso entre la tecla y la reacción.
2. **Ráfaga larga** contra una pared:
   - la mira sube, se puede controlar tirando hacia abajo y recupera parte al soltar;
   - los impactos caen donde apunta la mira, no más arriba por el golpe de cámara;
   - al acabar sale humo del cañón.
3. **Apuntar (clic derecho)**:
   - transición suave sin saltos, FOV sin cambios bruscos y sensibilidad proporcional;
   - apuntando, el arma casi no se balancea.
   - Compara subfusil (Specter-9), fusil (ARX-27) y ametralladora (Titan): se nota algo más rápido o
     más lento, pero no injusto.
4. **Andar, correr y saltar**:
   - balanceo leve al andar y mayor al correr, sin efecto barco;
   - al correr, el arma baja de lado con algo más de FOV;
   - disparar corriendo saca del sprint enseguida y el disparo no se pierde;
   - al caer desde alto, pequeño golpe.
5. **Recarga**:
   - **con balas**: táctica, más corta;
   - **vacía**: tirón de montar el arma;
   - **cancelación**: cambiar de arma a mitad (1/2/Q) la corta, deja de sonar y las balas no suben;
   - **escopeta**: cartucho a cartucho.
6. **Cambio de arma (1/2/3, Q, rueda)**: el arma sube rápido con un pequeño rebote y se puede
   disparar enseguida.
7. **Inspección (V)**:
   - gira el arma y enseña la skin, el camuflaje y el colgante;
   - se cancela al disparar, recargar, apuntar, correr, dar un cuchillazo (F) o cambiar de arma.
8. **Cada tipo**: pistola (Viper), revólver (HandCannon), escopeta (Havoc), tirador (Raptor), francotirador
   (Signal 7, Ghostline XR con supresor: casi sin fogonazo), lanzacohetes, ballesta (sin casquillo ni
   fogonazo).
9. **Ajustes → Calidad**:
   - en **Baja** no hay casquillos ni marcas de bala y hay menos partículas;
   - en **Alta** como mucho 50 marcas a la vez (las viejas desaparecen).
   - El hitmarker y los avisos de baja no cambian.
10. **Ajustes → Efectos de pantalla: Reducidos**: el golpe de cámara casi desaparece.

### 2 jugadores (Test → Local Server, 2 jugadores)
1. Disparaos:
   - **impacto normal**: hitmarker blanco y «clic»;
   - **a la cabeza**: hitmarker dorado más largo y «tin»;
   - **baja**: X roja que gira, aviso «ELIMINADO» con «DISPARO A LA CABEZA» y 🎯 en el registro de bajas.
2. El daño solo cuenta si de verdad os veis.
3. **Sonido espacial**: el disparo del otro suena desde su posición; de lejos se oye sordo y con
   retraso, y las balas que pasan cerca hacen «fiuu».
4. Su fogonazo se ve (más pequeño); el casquillo no, porque es solo local.
5. **Instrumentación**:
   - pon `GameConfig.HitTelemetry.Enabled = true` (solo en Studio) y simula latencia
     (Studio → Settings → Network → Incoming Replication Lag = 0,1-0,2 s);
   - disparaos a un jugador que corre y apunta lo que diga «Holgura de impactos» en la Output;
   - **vuelve a ponerlo a `false`**.

### 5 contra 5 (Local Server con 5 jugadores, o 1 jugador con bots)
1. Tiroteo largo con todos disparando a la vez. Abre el MicroProfiler (Ctrl+F6) y las estadísticas
   (Shift+F5): sin picos largos al disparar.
2. En el Explorer, `Workspace.ClientFX` no debe crecer sin parar: como mucho unas 50 marcas y 8
   casquillos a la vez.
3. Sin errores en la Output y sin avisos de red por exceso de remotos (los efectos no se replican).

### Móvil (Device Emulator, teléfono apaisado)
1. Mira los FPS al disparar (Shift+F5):
   - sin casquillos;
   - como mucho 20 marcas;
   - impactos más simples.
2. Hitmarker, avisos de baja y trazadoras se ven igual que en PC.
3. **Controles**:
   - el botón 🎯 apunta y quita el apuntado (interruptor);
   - al cambiar de arma (⇄) se deja de apuntar;
   - 🔄 recarga.
4. La asistencia de apuntado sigue funcionando y el golpe de cámara no la estropea.
5. Con el teléfono, el arma de cadera no tapa los botones táctiles.

## G. Limitaciones

- **No se ha probado en Studio**: los valores de los perfiles son un punto de partida razonable y
  hay que ajustarlos jugando.
- **La inspección no tiene botón en móvil**: había poco sitio entre los botones táctiles. Se puede
  añadir con `TouchLayout.BindAction` si hace falta.
- **Al cambiar de arma** no hay animación de bajar la vieja: se cambia al instante y la nueva sube.
  Añadirla retrasaría el cambio; mejor hacerlo con animaciones de verdad.
- **Correr no cancela la recarga** (decisión existente: la recarga tiene prioridad y no se puede
  correr mientras tanto). Cambiarlo es una decisión de diseño.
- **El aviso de baja** sigue siendo el que había («ELIMINADO» + víctima + medallas + XP aparte). No
  se ha duplicado con otro «ELIMINACIÓN +100».
- **Tolerancia de impactos y tiro a la cabeza** sin cambios (~8 studs, cabeza = pieza `Head`
  tocada). Primero hay que medirla con la instrumentación y latencia real.
- **El golpe de cámara** cambia de verdad la cámara durante unas décimas (se recupera solo). Si al
  morir quedaba un golpe a medias, la cámara podría reaparecer desviada como mucho ~1°. Se limpia al
  reaparecer.

## H. Audio y animaciones que requieren assets reales

**Audio** (TODO: AÑADIR AUDIO PROPIO; grabado o con licencia, nunca sacado de otros juegos):
- Por cada arma, los huecos de `Sounds.WeaponAudio`. Prioridad:
  1. **ARX-27** (referencia): `ShotClose`, `ShotMechanical`, `ShotTail`, `MagOut`, `MagIn`, `Bolt`,
     `Empty` y `Equip`.
  2. Un disparo por familia: pistola, subfusil, escopeta, francotirador, ametralladora y lanzacohetes.
  3. Las colas (`ShotTail`) de interior y exterior: hoy hay una sola.
- **Hitmarker**: hoy usa sonidos incluidos con Roblox (`snap` y `electronicpingshort`) con distinto
  tono. Faltan tres sonidos propios cortos y muy distintos entre sí: impacto, cabeza y baja.
- **Impactos por material**: metal, hormigón, madera, tierra y cristal. Hoy no hay sonido de impacto
  en superficies.

**Animaciones** (hoy son procedurales):
- Recarga normal, recarga vacía e inspección del ARX-27 y de la pistola con `Animator`, enganchadas a
  `ClientState.WeaponEvent` (`ReloadStart` trae `Empty` y `Duration`).
- Sacar y guardar el arma.

**Texturas**:
- Marca de bala con textura (hoy es una pieza plana oscura).
- Chispa y polvo propios (hoy son las texturas de partículas que trae Roblox).

## I. Recomendaciones para la Fase 3

1. Pasar la sección F en Studio y ajustar los perfiles: primero el ARX-27 y luego un arma de cada
   tipo. Anotar los valores que se cambien.
2. Medir la holgura de impactos con latencia real y decidir con datos si se baja la tolerancia de
   8 studs o se valida el tiro a la cabeza por distancia a la cabeza.
3. Añadir el audio propio del ARX-27 y de una pistola, y comprobar la mezcla en Studio.
4. Animaciones con `Animator` usando los ganchos de `WeaponEvent`.
5. Sonidos de impacto por material, con límite de uno cada 0,05 s para no saturar.
6. Perfilar en un móvil real un tiroteo de 10 con calidad Auto.
