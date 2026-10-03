# ShooterRob 🔫

Un shooter en primera persona para Roblox, inspirado en juegos como *Disparo Hiper*: partidas por equipos (Rojo contra Azul) en los modos **Captura la bandera** y **Duelo por equipos**, armas con skins de neón, rachas de bajas y un **pase de batalla** con niveles y recompensas.

Todo está hecho con código (Luau). Incluso el mapa y las armas se generan solos, así que puedes darle a **Play** y probarlo sin tener que modelar nada.

## Qué trae

| Sistema | Detalles |
|---|---|
| **Captura la bandera** | Roba la bandera enemiga y llévala a tu base mientras la tuya siga allí. Gana el primer equipo en hacer 3 capturas (10 min). Si matan al portador la bandera cae: tu equipo la devuelve tocándola y, si nadie la toca, vuelve sola a los 20 s. Las banderas se ven a través de las paredes y el portador va un poco más lento. |
| **Duelo por equipos** | El primer equipo que llega a 40 bajas gana (o el que más tenga cuando se acaben los 8 min). |
| **Rondas** | Los modos se turnan en cada ronda. Hay calentamiento entre rondas, pantalla de victoria o derrota y un MVP (en CTF cada captura cuenta como 3 bajas). |
| **Armas** | Rifle automático *AR-7 Hiper*, escopeta *Trueno SG*, francotirador *Halcón X* (con mira telescópica), pistola *Víbora P9* y cuchillo *Colmillo*. |
| **Disparo** | Viewmodel en primera persona con brazos, retroceso, balanceo al caminar, apuntado (clic derecho), recarga, trazadoras, fogonazo, hitmarkers, números de daño y disparos a la cabeza. |
| **Anti-trampas** | El servidor revisa la cadencia, la munición, la distancia y la línea de visión de cada disparo. |
| **Movimiento** | Correr (Shift) y deslizarse (C), con impulso. |
| **HUD** | Marcador arriba con el top 10 de jugadores (foto, puesto y bajas), munición, vida, barra de racha, killfeed, nivel/XP y aviso de controles. |
| **Pase de batalla** | 15 niveles con una vía gratis y otra premium (GamePass), 13 skins (de común a mítica) y monedas. El progreso se guarda con DataStore. |
| **Mapa** | Arena urbana simétrica: calles con pasos de cebra, aceras con farolas y árboles, plaza central de baldosas, edificios con tiendas y rótulos de neón, contenedores rotulados, pasarela con barandillas, holograma giratorio, carteles gigantes y dos filas de rascacielos. |
| **Gráficos** | Iluminación "Future", nubes volumétricas, rayos de sol, bloom y corrección de color. Armas detalladas con skins de dos colores, destellos, llamas y brillo que late (míticas). Fogonazo con fuego y humo, balas que viajan, chispas y polvo al impactar, casquillos y explosión de partículas al eliminar a alguien. |
| **Interfaz** | Pantalla de inicio con la cámara girando sobre el mapa. Iconos 3D de las armas (en la partida y en el menú de skins), aviso de "ELIMINADO" y de doble/triple baja, vida con efecto de daño, contorno de los compañeros y nombres de los enemigos ocultos. |
| **Práctica** | Muñecos en el mapa para probar las armas aunque juegues solo en Studio. |

## Cómo abrirlo (opción rápida)

1. Descarga el archivo **`ShooterRob.rbxlx`** de este repositorio.
2. Ábrelo con **Roblox Studio** (doble clic, o en Studio: *File → Open from File*).
3. Pulsa **Play** (F5).

Para que el progreso del pase de batalla se guarde mientras pruebas en Studio, ve a **Game Settings → Security** y activa **Enable Studio Access to API Services**. Antes tendrás que publicar el juego al menos una vez. Si no lo activas, todo funciona igual, solo que el progreso no se guarda.

## Cómo trabajar con el código (opción recomendada: Rojo)

[Rojo](https://rojo.space) sincroniza la carpeta `src/` con Studio en tiempo real, así que puedes editar el código en VS Code.

```bash
# 1. Instala Rojo (con Aftman, Rokit o descargando el ejecutable)
aftman install

# 2. Arranca el servidor de Rojo
rojo serve
```

3. En Studio instala el plugin de Rojo, abre un *Baseplate* vacío y dale a **Connect**.

Si cambias el código y quieres regenerar el archivo del juego:

```bash
rojo build -o ShooterRob.rbxlx
```

## Controles

| Acción | PC | Mando |
|---|---|---|
| Disparar | Clic izquierdo | R2 |
| Apuntar | Clic derecho | L2 |
| Recargar | R | X |
| Cuchillo rápido | F | B |
| Correr | Shift (mantener) | L3 |
| Deslizarse | C / Ctrl | R3 |
| Cambiar arma | 1 / 2 / 3 / rueda del ratón | Y |
| Pase de batalla | B | Select |

En el móvil aparecen botones táctiles automáticamente.

## Personalizar

Todo lo importante está en `src/shared/`:

- **`GameConfig.luau`**:
  - Modos y su orden (`Modes`). Pon `{ "CTF" }` para jugar solo a Captura la bandera.
  - Puntos para ganar y duración de cada modo (`ModeSettings`).
  - Ajustes de la bandera: radios, tiempo de vuelta y velocidad del portador (`Flag`).
  - Velocidades, XP (también la de capturar o devolver la bandera), recompensas del pase y el ID del GamePass premium.
- **`Weapons.luau`**: daño, cadencia, cargador, retroceso, dispersión… y la forma de cada arma (piezas). Para crear un arma nueva, copia una entrada y añádela a `Weapons.Primaries`.
- **`Skins.luau`**: colores y materiales de cada skin.
- **`Sounds.luau`**: sonidos. Los que vienen ya incluidos en Roblox funcionan, pero para que suene mejor busca audios en el *Creator Store* y pega su `rbxassetid://`.

### Usar tu propio mapa

Construye tu mapa en Studio dentro de una carpeta o modelo llamado **`Map`** en `Workspace`. Si existe `workspace.Map`, el generador no crea el suyo. Pon dentro:

- **SpawnLocations** con `TeamColor = Really red` y otras con `Really blue`, y quítales la casilla `Neutral`.
- Para Captura la bandera, una pieza llamada **`FlagBase`** por equipo, con un atributo **`Team`** (texto) igual a `Rojo` o `Azul`. La bandera aparece encima de esa pieza. Si faltan, el modo se salta automáticamente.

## Publicar en Roblox

### 1. Primera vez (desde Roblox Studio, unos 2 minutos)

1. Abre `ShooterRob.rbxlx` en Roblox Studio.
2. **File → Publish to Roblox → Create new experience**. Ponle nombre y descripción.
3. En **Game Settings → Security**, activa **Enable Studio Access to API Services** (para que se guarde el progreso).
4. Mientras lo pruebas, deja la experiencia en **Private**. En el Creator Hub puedes invitar a amigos para probar con más gente.

### 2. Publicación automática (cada cambio sube solo)

El workflow `.github/workflows/publish.yml` construye el juego con Rojo y lo publica en cada push. Para activarlo:

1. En [create.roblox.com](https://create.roblox.com/dashboard/creations), abre tu experiencia y copia:
   - el **Universe ID**: en la URL o en *⋯ → Copy Universe ID*.
   - el **Place ID**: en *Places → ⋯ → Copy Place ID*.
2. En [Credenciales → API Keys](https://create.roblox.com/dashboard/credentials), crea una clave:
   - Añade la API **universe-places**, elige tu experiencia y marca **write**.
   - En *Accepted IP Addresses* pon `0.0.0.0/0`, porque GitHub cambia de IP.
3. En GitHub, abre el repositorio y ve a **Settings → Secrets and variables → Actions**:
   - Pestaña **Secrets**: crea `ROBLOX_API_KEY` con la clave.
   - Pestaña **Variables**: crea `ROBLOX_UNIVERSE_ID` y `ROBLOX_PLACE_ID`.

A partir de ahí, cada cambio que se suba aparece en Roblox en un par de minutos. En la pestaña **Actions** de GitHub ves si se publicó bien.

También puedes publicar a mano desde tu ordenador:

```bash
rojo build -o ShooterRob.rbxlx
ROBLOX_API_KEY=... ROBLOX_UNIVERSE_ID=... ROBLOX_PLACE_ID=... scripts/publish.sh
```

> ⚠️ Cada publicación sustituye lo que haya en Roblox. Si cambias cosas a mano en Studio (por ejemplo el mapa), cópialas también al código, o se perderán en la siguiente publicación automática.

## Antes de abrirlo al público

1. En `GameConfig.luau`:
   - `MinPlayers = 2` (o más).
   - `TrainingDummies = false`.
2. Crea un **GamePass** en el Creator Hub para el pase premium y pon su número en `PremiumPassId`.
3. Cambia la experiencia a **Public** en el Creator Hub.
4. Ponle un icono y miniaturas llamativas (como las de la captura) para atraer jugadores.

## Estructura del proyecto

```
src/
├── shared/                 → ReplicatedStorage.Shared
│   ├── GameConfig.luau      configuración general y pase de batalla
│   ├── Weapons.luau         estadísticas y modelos de las armas
│   ├── WeaponModels.luau    construye las armas a partir de piezas
│   ├── Skins.luau           skins
│   ├── Sounds.luau          sonidos
│   └── Remotes.luau         RemoteEvents
├── server/                 → ServerScriptService.Server
│   ├── Main.server.luau     arranque
│   └── Modules/
│       ├── MapBuilder.luau  mapa e iluminación
│       ├── PlayerData.luau  guardado, nivel, XP, skins, premium
│       ├── Loadout.luau     da las armas al aparecer
│       ├── Combat.luau      valida disparos, daño y bajas
│       ├── Round.luau       equipos, rondas, modos, marcador, rachas
│       ├── Flags.luau       modo Captura la bandera
│       └── Dummies.luau     muñecos de práctica
└── client/                 → StarterPlayerScripts.Client
    ├── Main.client.luau     arranque
    └── Modules/
        ├── WeaponController.luau  viewmodel, disparo, recarga, apuntar
        ├── Movement.luau          correr y deslizarse
        ├── HUD.luau               interfaz de partida
        ├── Menu.luau              pase de batalla, skins y armas
        ├── MainMenu.luau          pantalla de inicio
        ├── WeaponIcon.luau        iconos 3D de las armas
        ├── WorldFX.luau           animaciones del mapa, contornos y efectos de baja
        ├── Effects.luau           fogonazo, balas, impactos y casquillos
        ├── ClientState.luau       estado compartido
        └── UI.luau                utilidades de interfaz
```

## Ideas para seguir

- **Habilidades Q/E/X**: granada, dash o escudo, con tiempo de recarga.
- **Modelos y animaciones de verdad**: importa armas con *MeshPart* desde el Toolbox y cambia `Parts` en `Weapons.luau` por el modelo.
- **Tienda**: gastar las monedas en skins.
- **Más mapas** con votación al final de cada ronda.
