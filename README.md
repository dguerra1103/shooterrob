# SHOOTER NEW 🔫 (ShooterRob)

Un shooter 5v5 en primera persona para Roblox, con el estilo del *concept pack*: mapas con mucho color e iluminación "Future", armas de neón (ARX-27 Pulse, Havoc Pump, Specter-9…), trajes de operador, **7 modos de juego** con votación, **pase de batalla** y una **tienda** con monedas y Robux.

Todo está hecho con código (Luau). Los mapas, las armas y los trajes se generan solos, así que puedes darle a **Play** y probarlo sin modelar nada.

## Qué trae

| Sistema | Detalles |
|---|---|
| **Mapas** | **Pastel Plaza** (arena compacta de estilo cartoon: paredes lavanda con pilares de colores, torre central de dos alturas, casas con azotea y plataformas de hierba), **Arena Caramelo** (arena pequeña para duelos rápidos: tarta de dos pisos en el centro, gominolas, tabletas de chocolate, magdalenas, muros de barquillo, cornisas laterales, plataformas de salto, bastones de caramelo y piruletas gigantes de fondo), **Mansión Encantada** (mapa de Halloween, de noche con luna y niebla violeta: mansión central con planta baja de lado a lado y azotea con almenas y torreones, cementerios con lápidas, criptas, caldero de bruja brillante, árboles secos, faroles y calabazas), **Caja de Juguetes** (eres del tamaño de un juguete: castillo de bloques con pasarela elevada, ladrillos de construcción gigantes, cubos con letras, tren de juguete, plataformas de ladrillos, ceras de colores y ositos de peluche gigantes), **Jardín Sakura** (jardín japonés: pagoda jugable de dos plantas, toriis, estanques con puentes, cerezos con pétalos cayendo, casas de té y linternas), **Harbor Heights** (puerto de día: canal con agua, puente central, torre de control, azoteas A y callejón B), **Container Clash** (puerto al atardecer: pila central de contenedores, pasarelas, grúas y pasillos de flanqueo), **Neon Foundry** (fundición de noche: lava que quema, horno, cintas transportadoras, letreros de neón y chispas), **Frost Station** (base polar: lago helado resbaladizo bajo la torre del radar, hangares, laboratorios sobre pilotes, montículos de nieve y nieve cayendo), **Jungle Temple** (selva: pirámide escalonada con santuario y gema de jade sobre un foso, salones de columnas en ruinas, plataformas con enredaderas, cabezas de piedra gigantes, antorchas y cascadas) y **Downtown** (arena urbana). Cada mapa trae spawns por equipo, puntos para todos contra todos, 5 zonas de control y 2 bases de bandera. |
| **Modos** | **Duelo por equipos** (40 bajas), **Captura la bandera** (3 capturas), **Zona de control** (150 puntos, la zona cambia cada minuto), **Todos contra todos** (25 bajas), **Escalada de armas** (subes de arma con cada baja; gana quien la complete con el cuchillo) y **Eliminación** (rondas de una sola vida al estilo de los duelos: gana la ronda el equipo que deje al otro sin nadie en pie; primero a 5 rondas) y **Infección** (Halloween: todos empiezan como supervivientes; a los 12 s alguien se convierte en zombi, con garras, 200 de vida y más velocidad. Quien cae ante los zombis se vuelve zombi. Si queda algún superviviente al acabar los 2:30, ganan ellos; si no, los zombis). |
| **Bots** | Si hay pocos jugadores, bots con arma de verdad rellenan la partida hasta 6 (`GameConfig.Bots`): recorren el mapa, buscan enemigos, fallan más de lejos, ocupan la zona de control y puntúan para su equipo. Dan menos XP y monedas, y las victorias contra bots no suben la clasificación. Se quitan solos al entrar gente y no salen en Escalada de armas. |
| **Evento de Halloween** | Durante las rondas aparecen caramelos brillantes por el mapa: cada uno da monedas y suma al contador del evento (abajo a la izquierda). Premios por el camino: 25 caramelos = monedas, 50 = traje **Cabeza de Calabaza**, 75 = más monedas, y con 100 la skin exclusiva **Embrujada** (mítica, no se vende). El contador dice cuánto falta para el siguiente premio. Calabazas con cara iluminada decoran los mapas. Se apaga con `GameConfig.Event.Enabled = false`. |
| **Etiquetas en el chat** | Cada mensaje lleva el nivel del jugador con color (gris → verde → azul → morado → dorado) y **[VIP]** dorado para quien tenga el pase. |
| **Bonus de amigos** | +10% de XP y monedas por cada amigo de Roblox en el mismo servidor (hasta +30%), se suma al VIP. Aviso al entrar el amigo. |
| **Primera partida** | Los jugadores nuevos ven una tarjeta con los controles (PC o móvil) la primera vez que entran en partida. |
| **Regalos por jugar** | Botón 🎁 a la izquierda con cuenta atrás: a los 2, 5, 10, 15, 20, 30 y 45 minutos de sesión hay un regalo (monedas, XP o revivir instantáneos). Se recoge con **H** o tocándolo; el servidor cuenta el tiempo (`GameConfig.PlaytimeGifts`). |
| **Fin de partida** | Pantalla de victoria con MVP y **resumen de tu partida**: bajas, muertes, mejor racha, la barra de nivel llenándose con la XP ganada (con aviso si subes) las monedas contando hacia arriba y tu rango con los RP ganados. **Racha de victorias**: cada victoria seguida da monedas extra (+10, +20… hasta +50). |
| **Votación** | En el descanso entre rondas salen 3 opciones de mapa + modo. Pulsa **V** para votar con el ratón. |
| **Armas** | Principales: **ARX-27 Pulse** (fusil), **Havoc Pump** (escopeta), **Specter-9** (subfusil), **Signal-7** (francotirador, nivel 3), **Vortex AR-9** (fusil de energía con ráfagas de 3, nivel 4), **Nova Drift** (subfusil ágil, nivel 5), **Raptor DMR** (tirador, nivel 7), **Breach Hammer** (escopeta semiautomática, nivel 8), **Titan Grind** (ametralladora pesada, nivel 10), **Ghostline XR** (francotirador con supresor, nivel 12), **Tempest Core** (lanzacohetes con explosión, nivel 14) y **Splat-X** (marcadora de paintball, nivel 2: las bolas dejan salpicaduras de pintura de colores en paredes y suelo). Secundarias: **Viper P9**, **Hand Cannon** (nivel 6) y **Phantom Sidewind** (pistola de ráfagas de 2 con mira de punto, nivel 9). Cuerpo a cuerpo (se elige en la pestaña **Armas**): **Colmillo** (cuchillo), **Martillo de juguete** (golpes rapidísimos, nivel 4) y **Katana** (más alcance y daño, nivel 6). Las armas bloqueadas se pueden comprar antes con monedas. |
| **Habilidades** | Iconos abajo en el centro con recarga: **Impulso** (E, acelerón corto), **Supersalto** (Z) y **Poción** (X, cura 50 en 2,5 s; la valida el servidor). En móvil se tocan los iconos. |
| **Pantalla de muerte** | Observas al que te eliminó (clic/clic derecho cambia de jugador) y ves cuánta vida le quedaba. **Revivir instantáneo** (B): vuelves donde caíste con escudo breve (3 de regalo y packs con Robux). **Regenerar ahora** (Espacio o F) y **Volver al menú**. En Eliminación no hay reaparición hasta la siguiente ronda: se observa a los compañeros. |
| **Emotes** | Tecla **N**: saludar, 3 bailes, celebrar, reír y señalar; la cámara pasa a tercera persona mientras dura. |
| **Retos diarios** | 3 retos al día distintos para cada jugador (bajas, tiros a la cabeza, victorias, capturas, zona, rachas, bajas con cierto tipo de arma…). Dan monedas y XP al completarse. Completar los 3 regala una caja, y se puede cambiar 1 reto al día. Pestaña **Retos** del menú y siempre a la vista a la izquierda de la pantalla, con barras de progreso. |
| **Maestría de armas** | Cada arma cuenta sus bajas y desbloquea camuflajes exclusivos para ella: **Carbono** (25), **Oro** (75), **Diamante** (150) y **Materia oscura** (300), más monedas. El camuflaje se equipa solo al ganarlo y se puede cambiar en la pestaña **Armas**. No se venden ni salen en cajas. |
| **Granadas** | Tecla **G**: granada de fragmentación que rebota y explota a los 2 s (daño en área). Una por jugador, se recarga en 15 s y vuelve al reaparecer. No hay en Escalada de armas. |
| **Skins temáticas** | **Caramelo** y **Juguete** (raras), **Tiki** (épica, con llamas) y **Salpicón** (legendaria, de pintura con destellos), a juego con los mapas nuevos. |
| **Skins animadas** | **Arcoíris** (mítica: paneles y detalles de neón que recorren todos los colores, con destellos) y **Prisma** (legendaria: el arma entera cambia de color en tonos pastel). Se animan en tu arma, en las de los demás y en los iconos de la tienda. Se compran con monedas o salen en la Caja Neón. |
| **Efectos de eliminación** | Lo que ven todos cuando eliminas a alguien: Confeti, Amor, Llamarada, Congelado, Fantasma, Calavera, Rayo, Lluvia de monedas, Agujero negro, Pintura y Arcoíris. Se compran con monedas en la pestaña **Efectos** (con botón para verlos antes). |
| **Rachas** | 3 bajas seguidas: **Radar** (tu equipo ve a los enemigos a través de las paredes 12 s). 5 bajas seguidas: **Ataque aéreo** (tecla T: marcas rojas y 5 bombas en línea donde apuntas). No hay en Escalada de armas. |
| **Clasificación global** | Top 10 mundial de bajas, de victorias y de rango (mejores RP) (todos los servidores) en la pantalla de inicio. Se actualiza cada 90 s; tu fila se resalta si estás dentro. |
| **Rangos competitivos** | 🥉 Bronce, 🥈 Plata, 🥇 Oro, 💠 Platino, 💎 Diamante y 👑 Campeón. Ganar da +25 RP, perder −12 (−5 en todos contra todos) y el MVP +5 extra; nunca se baja de rango. Solo cuenta para quien ha jugado de verdad (volver al menú no libra de la derrota). Al llegar a cada rango por primera vez hay premio: monedas y, en Oro, Diamante y Campeón, cajas gratis. Contra bots solo se gana un poco (+8) y no se pierde. Los bots apuntan peor contra los rangos bajos y mejor contra los altos (`GameConfig.Bots.SkillByRank`). Se ve en la pantalla de inicio, en el marcador, en el chat y al final de cada partida ("¡ASCIENDES A ORO!"). Se ajusta en `src/shared/Ranks.luau`. |
| **Trajes** | Blaze Runner, Neon Recon, Volt Bruiser (los del concept pack), Frost Byte, Toxic Rogue, Golden Ace y **Cabeza de Calabaza** (Halloween: cabeza de calabaza con ojos que brillan y capa; solo se consigue con 50 caramelos del evento). Se ven en la partida sobre tu avatar. |
| **Disparo** | Armas de estilo clásico (siluetas reales, madera y metal, miras de punto rojo, holográficas y telescópicas; `Weapons.Style = "SciFi"` vuelve al concept pack), inspeccionar arma (V), números de daño que saltan sobre el enemigo, viewmodel con brazos, retroceso, balanceo, apuntado (clic derecho), mira telescópica, recarga, trazadoras, fogonazo, hitmarkers, números de daño, disparos a la cabeza y cohetes con explosión. |
| **Anti-trampas** | El servidor revisa la cadencia, la munición, la distancia y la línea de visión de cada disparo. |
| **Movimiento** | Correr (Shift) y deslizarse (C), con impulso. |
| **Pase de batalla** | Niveles con vía gratis y premium (GamePass), skins de común a mítica y monedas. El progreso se guarda con DataStore. |
| **Tienda** | Packs de monedas con Robux, pase **VIP** (x2 XP y monedas), skins y trajes con monedas, **ofertas del día** con descuento, **recompensa diaria** (7 días, con caja el 7.º) y **Caja Neón** (solo monedas, con las probabilidades a la vista; si toca algo repetido te devuelve parte). En los países donde las cajas aleatorias no están permitidas se ocultan solas. |
| **Estilo** | `GameConfig.VisualStyle = "Cartoon"` (colores vivos, plástico liso, luz suave, como los shooters más jugados de Roblox) o `"Realista"`. Texturas propias para subir en `assets/textures` (cuadrícula de paredes y 6 camuflajes de armas). |
| **Gráficos** | Iluminación "Future", hierba 3D animada en el terreno (Jungle Temple), agua con reflejos y olas propias de cada mapa, cielo estrellado de noche, atmósfera, nubes, rayos de sol, bloom y corrección de color distinta por mapa, agua de Terrain, neón con luces, partículas (humo, chispas, lava), armas con skins de dos colores y efectos (destellos, llamas). Realismo: materiales PBR 2022 (yeso, ladrillo, hormigón, asfalto), colinas de terreno irregulares con roca, viento que mueve hierba, nubes y partículas, sombras de contacto bajo los objetos, óxido en contenedores, alcantarillas, grietas, aceite, rodadas y juntas en los suelos, charcos que reflejan, vapor, conos de luz, coches aparcados, pinos nevados, sotobosque en la jungla, algas en el canal, impactos de bala según el material (chispas, astillas, polvo, salpicaduras), huellas en nieve y barro y polvo al deslizarse. |
| **Interfaz** | Pantalla de inicio, menú con pestañas (Perfil con rango y estadísticas, Pase, Retos, Armas, Skins, Trajes, Efectos, Tienda, Ajustes), iconos 3D de las armas, killfeed, rachas, marcador, aviso de zona/bandera y pantalla de victoria con MVP. |
| **Ajustes** | Pestaña ⚙ del menú: calidad gráfica **Auto / Baja / Media / Alta / Ultra** (Auto: Baja en móvil, Media en PC) (sombras, brillo, rayos de sol, nubes, partículas del mapa y desenfoque de distancia en Ultra), **campo de visión** (70–100°), **sensibilidad** y **sensibilidad al apuntar** (baja en proporción al zoom). Se guardan con el progreso. |
| **Práctica** | Muñecos en el mapa para probar las armas aunque juegues solo en Studio. |

> 🧪 **¿Cómo pruebo las novedades?** Mira [PRUEBAS.md](PRUEBAS.md): lista rápida de qué probar en Studio y qué debería pasar.

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
| Granada | G | L1 |
| Ataque aéreo (racha de 5) | T | Cruceta derecha |
| Correr | Shift (mantener) | L3 |
| Deslizarse | C / Ctrl | R3 |
| Cambiar arma | 1 / 2 / 3 / rueda del ratón / Q | Y |
| Menú (pase, retos, armas, skins, trajes, efectos, tienda) | B | Select |
| Votar mapa (en el descanso) | V | Cruceta arriba |
| Inspeccionar arma | V | Cruceta arriba |
| Habilidades: Impulso / Supersalto / Poción | E / Z / X | Cruceta izquierda / abajo |
| Emotes | N (en móvil, botón 😀) | — |
| Recoger regalo por tiempo jugado | H (en móvil, tocar 🎁) | — |
| Marcador (equipos, bajas, muertes; bots incluidos) | Tab (mantener; en móvil, botón 📋) | — |
| Muerto: revivir instantáneo / regenerar ahora | B / Espacio o F | Y / A |

En el móvil aparecen botones táctiles automáticamente (disparar, apuntar, recargar, cuchillo, correr, deslizar, granada, cambiar arma ⇄ y ataque aéreo).

## Personalizar

Todo lo importante está en `src/shared/`:

- **`GameConfig.luau`**:
  - Modos que entran en la votación (`Modes`). Pon `{ "CTF" }` para jugar solo a Captura la bandera. Códigos: `TDM`, `CTF`, `KOTH`, `FFA`, `GUN`, `ELIM`.
  - Bots (`Bots`): `Enabled`, hasta cuántos rellenan (`FillTo`), armas, puntería (`Accuracy`), daño (`DamageScale`) y premio por eliminarlos (`RewardScale`).
  - Puntos para ganar y duración de cada modo (`ModeSettings`).
  - Ajustes de la bandera (`Flag`), XP, monedas, recompensas del pase y el ID del GamePass premium (`PremiumPassId`).
- **`Weapons.luau`**: daño, cadencia, cargador, retroceso, dispersión, nivel de desbloqueo y precio de cada arma, y el orden de *Escalada de armas* (`GunGameOrder`).
- **`WeaponDesigns.luau`**: la forma de cada arma (piezas). Para añadir un arma nueva, copia una entrada aquí y en `Weapons.luau` y añádela a `Weapons.Primaries`.
- **`Skins.luau`** y **`Outfits.luau`**: skins de armas y trajes de operador.
- **`Ranks.luau`**: rangos competitivos y puntos por partida.
- **`Shop.luau`**: precios, packs de Robux, VIP, recompensa diaria, cajas y ofertas.
- **`Challenges.luau`**: lista de retos diarios (objetivo, texto y premio).
- **`Mastery.luau`**: bajas necesarias y premio de cada nivel de maestría.
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
2. **Revivir instantáneo**: crea 2 productos (5 revivir a 25 Robux y 15 a 59 Robux) y pega sus IDs en `Shop.RevivePacks[i].ProductId`. Cada jugador empieza con 3 gratis; al morir, "REVIVIR INSTANTÁNEO" (tecla B) le devuelve donde cayó.
3. **Pack de inicio**: crea otro Developer Product (por ejemplo 99 Robux) y pon su ID en `Shop.StarterPack.ProductId`. Da 1500 monedas, el traje Blaze Runner, la skin Sakura y el efecto Confeti, se compra una sola vez y solo se ofrece hasta el nivel 15.
4. **Passes**: crea el pase **VIP** (299 Robux) y pon su ID en `Shop.VIPPassId`. Crea otro para el **pase de batalla premium** y pon su ID en `GameConfig.PremiumPassId`.

Mientras un ID valga `0`, su botón aparece como "Próximamente". Las compras se guardan con un registro para no entregar dos veces la misma.

## Antes de abrirlo al público

1. En `GameConfig.luau`:
   - `MinPlayers = 2` (o más).
   - `TrainingDummies = false`.
   - Si no quieres bots con gente de verdad, baja `Bots.FillTo` (por ejemplo a 4) o pon `Bots.Enabled = false`.
2. Configura los IDs de la tienda (apartado anterior).
   - Opcional: crea **insignias** en el Creator Hub (Bienvenida, Primera baja, 100 bajas, Primera victoria, Nivel 10, Rango Oro, Rango Diamante y Rango Campeón) y pega sus ID en `GameConfig.Badges`; se dan solas.
3. En el Creator Hub, rellena el **cuestionario de madurez** y, como hay cajas, marca que tiene artículos aleatorios de pago (aunque solo se compren con monedas, las monedas se venden por Robux).
4. En **Game Settings → Places**, pon el máximo de jugadores por servidor en **20** (10 contra 10) o menos de 30: Roblox solo dibuja 31 contornos a la vez (compañeros y radar).
5. Cambia la experiencia a **Public** y ponle un icono y miniaturas llamativas (puedes usar las imágenes del concept pack).

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
│   ├── Challenges.luau      retos diarios
│   ├── Mastery.luau         maestría de armas (camuflajes por bajas)
│   ├── KillEffects.luau     efectos de eliminación
│   ├── Sounds.luau          sonidos
│   └── Remotes.luau         RemoteEvents y RemoteFunctions
├── server/                 → ServerScriptService.Server
│   ├── Main.server.luau     arranque
│   └── Modules/
│       ├── MapBuilder.luau  registro de mapas e iluminación
│       ├── MapKit.luau      piezas para construir mapas
│       ├── MapDefs/         HarborHeights, ContainerClash, NeonFoundry, FrostStation, JungleTemple, Downtown
│       ├── PlayerData.luau  guardado, nivel, XP, monedas, compras
│       ├── Loadout.luau     armas y traje al aparecer
│       ├── Combat.luau      valida disparos, daño, explosiones y bajas
│       ├── Round.luau       equipos, votación, rondas, modos, marcador, rachas
│       ├── Respawn.luau     reaparición, "Regenerar ahora" y "Revivir instantáneo"
│       ├── Flags.luau       Captura la bandera
│       ├── Hardpoint.luau   Zona de control
│       ├── Hazards.luau     lava
│       ├── Bots.luau        bots que rellenan la partida (caminos, puntería, equipos)
│       ├── Gifts.luau       regalos por tiempo jugado
│       ├── Friends.luau     bonus por jugar con amigos
│       ├── Badges.luau      insignias de Roblox (IDs en GameConfig.Badges)
│       ├── Event.luau       evento de temporada (caramelos de Halloween, calabazas)
│       ├── Grenades.luau    granadas
│       ├── Leaderboard.luau clasificación global
│       ├── Killstreaks.luau recompensas por racha (radar y ataque aéreo)
│       └── Dummies.luau     muñecos de práctica
└── client/                 → StarterPlayerScripts.Client
    ├── Main.client.luau     arranque
    └── Modules/
        ├── WeaponController.luau  viewmodel, disparo, recarga, apuntar
        ├── Movement.luau          correr y deslizarse
        ├── HUD.luau               interfaz de partida
        ├── Menu.luau              pase, retos, armas, skins, trajes y tienda
        ├── MainMenu.luau          pantalla de inicio
        ├── VoteUI.luau            votación de mapa y modo
        ├── GrenadeController.luau granada (tecla G) e indicador
        ├── KillstreakController.luau radar y ataque aéreo (tecla T)
        ├── WeaponIcon.luau        iconos 3D de las armas
        ├── WorldFX.luau           animaciones del mapa y efectos de baja
        ├── Footprints.luau        huellas en nieve, arena y barro
        ├── DeathScreen.luau       pantalla de muerte: observar, revivir, regenerar, menú
        ├── Effects.luau           fogonazo, balas, impactos, cohetes y explosiones
        ├── Settings.luau          ajustes: calidad gráfica, FOV, sensibilidad
        ├── ClientState.luau       estado compartido
        └── UI.luau                utilidades de interfaz
```

## Ideas para seguir

- **Modelos de verdad**: cuando tengas armas o trajes en *MeshPart* (por ejemplo hechos en Blender a partir del concept pack), súbelos y sustituye las piezas en `WeaponDesigns.luau`.
- **Habilidades Q/E**: granada, dash o escudo, con tiempo de recarga.
- **Sonidos propios** para cada arma.
- **Clasificación global** (OrderedDataStore) y misiones semanales.
