# SHOOTER NEW 🔫 (ShooterRob)

Un shooter 5v5 en primera persona para Roblox, con el estilo del *concept pack*: mapas con mucho color e iluminación "Future", armas de neón (ARX-27 Pulse, Havoc Pump, Specter-9…), trajes de operador, **5 modos de juego** con votación, **pase de batalla** y una **tienda** con monedas y Robux.

Todo está hecho con código (Luau). Los mapas, las armas y los trajes se generan solos, así que puedes darle a **Play** y probarlo sin modelar nada.

## Qué trae

| Sistema | Detalles |
|---|---|
| **Mapas** | **Harbor Heights** (puerto de día: canal con agua, puente central, torre de control, azoteas A y callejón B), **Container Clash** (puerto al atardecer: pila central de contenedores, pasarelas, grúas y pasillos de flanqueo), **Neon Foundry** (fundición de noche: lava que quema, horno, cintas transportadoras, letreros de neón y chispas) y **Downtown** (arena urbana). Cada mapa trae spawns por equipo, puntos para todos contra todos, 5 zonas de control y 2 bases de bandera. |
| **Modos** | **Duelo por equipos** (40 bajas), **Captura la bandera** (3 capturas), **Zona de control** (150 puntos, la zona cambia cada minuto), **Todos contra todos** (25 bajas) y **Escalada de armas** (subes de arma con cada baja; gana quien la complete con el cuchillo). |
| **Votación** | En el descanso entre rondas salen 3 opciones de mapa + modo. Pulsa **V** para votar con el ratón. |
| **Armas** | Principales: **ARX-27 Pulse** (fusil), **Havoc Pump** (escopeta), **Specter-9** (subfusil), **Signal-7** (francotirador, nivel 3), **Vortex BR** (ráfaga de 3, nivel 4), **Raptor DMR** (tirador, nivel 7), **Titan LMG** (ametralladora, nivel 10) y **Nova** (lanzacohetes con explosión, nivel 14). Secundarias: **Viper P9** y **Hand Cannon** (nivel 6). Cuerpo a cuerpo: **Colmillo**. Las armas bloqueadas se pueden comprar antes con monedas. |
| **Trajes** | Blaze Runner, Neon Recon, Volt Bruiser (los del concept pack), Frost Byte, Toxic Rogue y Golden Ace. Se ven en la partida sobre tu avatar. |
| **Disparo** | Viewmodel con brazos, retroceso, balanceo, apuntado (clic derecho), mira telescópica, recarga, trazadoras, fogonazo, hitmarkers, números de daño, disparos a la cabeza y cohetes con explosión. |
| **Anti-trampas** | El servidor revisa la cadencia, la munición, la distancia y la línea de visión de cada disparo. |
| **Movimiento** | Correr (Shift) y deslizarse (C), con impulso. |
| **Pase de batalla** | Niveles con vía gratis y premium (GamePass), skins de común a mítica y monedas. El progreso se guarda con DataStore. |
| **Tienda** | Packs de monedas con Robux, pase **VIP** (x2 XP y monedas), skins y trajes con monedas, **ofertas del día** con descuento, **recompensa diaria** (7 días, con caja el 7.º) y **Caja Neón** (solo monedas, con las probabilidades a la vista; si toca algo repetido te devuelve parte). En los países donde las cajas aleatorias no están permitidas se ocultan solas. |
| **Gráficos** | Iluminación "Future", atmósfera, nubes, rayos de sol, bloom y corrección de color distinta por mapa, agua de Terrain, neón con luces, partículas (humo, chispas, lava), armas con skins de dos colores y efectos (destellos, llamas). |
| **Interfaz** | Pantalla de inicio, menú con pestañas (Pase, Armas, Skins, Trajes, Tienda), iconos 3D de las armas, killfeed, rachas, marcador, aviso de zona/bandera y pantalla de victoria con MVP. |
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
| Menú (pase, armas, skins, trajes, tienda) | B | Select |
| Votar mapa (en el descanso) | V | Cruceta arriba |

En el móvil aparecen botones táctiles automáticamente.

## Personalizar

Todo lo importante está en `src/shared/`:

- **`GameConfig.luau`**:
  - Modos que entran en la votación (`Modes`). Pon `{ "CTF" }` para jugar solo a Captura la bandera. Códigos: `TDM`, `CTF`, `KOTH`, `FFA`, `GUN`.
  - Puntos para ganar y duración de cada modo (`ModeSettings`).
  - Ajustes de la bandera (`Flag`), XP, monedas, recompensas del pase y el ID del GamePass premium (`PremiumPassId`).
- **`Weapons.luau`**: daño, cadencia, cargador, retroceso, dispersión, nivel de desbloqueo y precio de cada arma, y el orden de *Escalada de armas* (`GunGameOrder`).
- **`WeaponDesigns.luau`**: la forma de cada arma (piezas). Para añadir un arma nueva, copia una entrada aquí y en `Weapons.luau` y añádela a `Weapons.Primaries`.
- **`Skins.luau`** y **`Outfits.luau`**: skins de armas y trajes de operador.
- **`Shop.luau`**: precios, packs de Robux, VIP, recompensa diaria, cajas y ofertas.
- **`Sounds.luau`**: sonidos. Para que suene mejor busca audios en el *Creator Store* y pega su `rbxassetid://`.

Los mapas están en `src/server/Modules/MapDefs/` (uno por archivo) y usan las piezas de `MapKit.luau`. El orden de la rotación está en `MapBuilder.Order`.

### Usar tu propio mapa

Construye tu mapa en Studio dentro de una carpeta o modelo llamado **`Map`** en `Workspace`. Si existe `workspace.Map`, el generador no crea los suyos. Pon dentro:

- **SpawnLocations** con `TeamColor = Really red` y otras con `Really blue`, y quítales la casilla `Neutral`.
- Para Captura la bandera, una pieza llamada **`FlagBase`** por equipo, con un atributo **`Team`** (texto) igual a `Rojo` o `Azul`.
- Para Zona de control, piezas llamadas **`HardpointZone`** con los atributos `Order` (número) y `Radius`.
- Para Todos contra todos y Escalada, piezas llamadas **`FFASpawn`** repartidas por el mapa.
- Si una pieza usa el material **CrackedLava**, quema a quien la pise.

Si falta algo, ese modo se salta automáticamente.

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

## Monetización (Robux)

En el [Creator Hub](https://create.roblox.com/dashboard/creations), abre tu experiencia → **Monetización**:

1. **Developer Products**: crea 4 productos (por ejemplo 500, 1200, 3000 y 8000 monedas a 49, 99, 199 y 449 Robux) y pega cada ID en `Shop.CoinPacks[i].ProductId` (`src/shared/Shop.luau`).
2. **Passes**: crea el pase **VIP** (299 Robux) y pon su ID en `Shop.VIPPassId`. Crea otro para el **pase de batalla premium** y pon su ID en `GameConfig.PremiumPassId`.

Mientras un ID valga `0`, su botón aparece como "Próximamente". Las compras se guardan con un registro para no entregar dos veces la misma.

## Antes de abrirlo al público

1. En `GameConfig.luau`:
   - `MinPlayers = 2` (o más).
   - `TrainingDummies = false`.
2. Configura los IDs de la tienda (apartado anterior).
3. En el Creator Hub, rellena el **cuestionario de madurez** y, como hay cajas, marca que tiene artículos aleatorios de pago (aunque solo se compren con monedas, las monedas se venden por Robux).
4. Cambia la experiencia a **Public** y ponle un icono y miniaturas llamativas (puedes usar las imágenes del concept pack).

## Estructura del proyecto

```
src/
├── shared/                 → ReplicatedStorage.Shared
│   ├── GameConfig.luau      configuración general, modos y pase de batalla
│   ├── Weapons.luau         estadísticas, desbloqueos y precios de las armas
│   ├── WeaponDesigns.luau   forma de cada arma (piezas)
│   ├── WeaponModels.luau    construye las armas y les aplica la skin
│   ├── Skins.luau           skins de armas
│   ├── Outfits.luau         trajes de operador
│   ├── Shop.luau            tienda, VIP, diarias, cajas y ofertas
│   ├── Sounds.luau          sonidos
│   └── Remotes.luau         RemoteEvents y RemoteFunctions
├── server/                 → ServerScriptService.Server
│   ├── Main.server.luau     arranque
│   └── Modules/
│       ├── MapBuilder.luau  registro de mapas e iluminación
│       ├── MapKit.luau      piezas para construir mapas
│       ├── MapDefs/         HarborHeights, ContainerClash, NeonFoundry, Downtown
│       ├── PlayerData.luau  guardado, nivel, XP, monedas, compras
│       ├── Loadout.luau     armas y traje al aparecer
│       ├── Combat.luau      valida disparos, daño, explosiones y bajas
│       ├── Round.luau       equipos, votación, rondas, modos, marcador, rachas
│       ├── Flags.luau       Captura la bandera
│       ├── Hardpoint.luau   Zona de control
│       ├── Hazards.luau     lava
│       └── Dummies.luau     muñecos de práctica
└── client/                 → StarterPlayerScripts.Client
    ├── Main.client.luau     arranque
    └── Modules/
        ├── WeaponController.luau  viewmodel, disparo, recarga, apuntar
        ├── Movement.luau          correr y deslizarse
        ├── HUD.luau               interfaz de partida
        ├── Menu.luau              pase, armas, skins, trajes y tienda
        ├── MainMenu.luau          pantalla de inicio
        ├── VoteUI.luau            votación de mapa y modo
        ├── WeaponIcon.luau        iconos 3D de las armas
        ├── WorldFX.luau           animaciones del mapa y efectos de baja
        ├── Effects.luau           fogonazo, balas, impactos, cohetes y explosiones
        ├── ClientState.luau       estado compartido
        └── UI.luau                utilidades de interfaz
```

## Ideas para seguir

- **Modelos de verdad**: cuando tengas armas o trajes en *MeshPart* (por ejemplo hechos en Blender a partir del concept pack), súbelos y sustituye las piezas en `WeaponDesigns.luau`.
- **Habilidades Q/E**: granada, dash o escudo, con tiempo de recarga.
- **Sonidos propios** para cada arma.
- **Clasificación global** (OrderedDataStore) y misiones semanales.
