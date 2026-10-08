# VISUAL_IMPROVEMENTS

> **Nota (reconstrucción de mapas):** los mapas que se citan en este registro (Encrucijada, Base Militar, Cumbre, Puesto del Desierto, Harbor Heights, etc.) se retiraron al hacer los nueve mapas 5v5 nuevos. El estado actual de los mapas está en `MAP_DEVELOPMENT.md`.

Pase "Stylized Tactical Roblox". Qué cambió, por qué y dónde. Todo se puede apagar o ajustar en
`src/shared/GameConfig.luau`.

## Iluminación y color
| Qué | Por qué | Dónde |
|---|---|---|
| Estilo **Táctico** para todos los mapas (`VisualStyle = "Tactico"`): sombras rellenas (nada de zonas negras), niebla limitada (densidad ≤ 0,34), brillo contenido (bloom ≤ 0,5 de día, umbral ≥ 1,8), color algo más vivo (saturación 0,08–0,16) y cada mapa conserva su tinte. | Legibilidad competitiva + identidad Roblox moderna: ni gris militar ni dibujo animado. | `server/Modules/MapKit.luau` → `tacticalize` |
| Mapas 5v5 diseñados (Encrucijada, Base Militar, Cumbre): solo límites de legibilidad y saturación mínima 0,09. | Ya tenían su luz pensada; no se rehacen. | `MapKit.tacticalize(preset, true)` |
| Ultra: el desenfoque de profundidad solo actúa más allá de 250 studs. | Un enemigo a distancia de combate nunca sale borroso. | `client/Modules/Settings.luau` |

## Mapa nuevo
| Qué | Por qué | Dónde |
|---|---|---|
| **Puesto del Desierto** (5v5): aldea de adobe con identidad arena + turquesa (puertas, franjas, toldos, cúpula del caravasar). Tres carriles con carácter distinto: callejones estrechos (norte), calle mayor (centro), chatarrería abierta (sur). Zonas con nombre, sitios A/B, puestos de tirador y variantes de atardecer y tormenta de arena. | Un mapa reconocible por una captura, pensado para 5 contra 5. | `server/Modules/MapDefs/DesertOutpost.luau` |

## Legibilidad en combate
| Qué | Por qué | Dónde |
|---|---|---|
| **Contorno rojo fino** en enemigos (Highlight `Occluded`, borde semitransparente, sin relleno). Se quita al morir, se recalcula si cambia de bando y cede el sitio al radar y al destello de impacto (un resaltado por modelo). | Ver al enemigo al instante contra cualquier fondo, sin dar información a través de paredes. | `client/Modules/WorldFX.luau`, `GameConfig.EnemyOutline` |
| **Nombres de zona**: «📍 HOTEL CENTRAL», «AVENIDA», «BASE AZUL» bajo el minimapa; con nombres propios en Encrucijada, Base Militar, Cumbre, Puesto del Desierto, Puerto, Contenedores, Fundición, Feria, Pueblo Vaquero, Bahía Pirata, Castillo, Estación Ártica, Templo de la Selva, Mansión Encantada, Jardín Sakura, Base Lunar, Aldea Navideña, Pastel Plaza, Caja de Juguetes y Arena Caramelo; en el resto, «NORTE · LADO AZUL». | 5v5: poder decir dónde estás («en las obras») y orientarse. | `client/Modules/ZoneName.luau`, `Kit.callout`, `RealKit.building` (los edificios con cartel se nombran solos) |
| **Color del contorno enemigo elegible** (Ajustes → Efectos de pantalla): rojo, amarillo o magenta. | Accesibilidad (daltonismo) sin perder legibilidad. | `GameConfig.EnemyColors`, `Menu.luau`, `WorldFX.Restyle` |
| Sitios de bomba con nombre de zona («SITIO A · ROJO»). | En Buscar y destruir se sabe al instante qué sitio es y de quién. | `MapKit.bombSite` |
| HUD de combate limpio: retos y barra del evento salen solo un rato (al aparecer y al progresar); el botón de tienda se oculta en PC mientras luchas (tecla B); «Racha x0» no se muestra. | Menos ruido en pantalla durante el tiroteo. | `QuestTracker.luau`, `EventHUD.luau`, `Menu.luau`, `HUD.luau` |
| Botones de habilidades en PC compactos (oscuros con el color en el borde); en móvil siguen grandes. | Jerarquía: las habilidades no compiten con la mira. | `client/Modules/Abilities.luau` |

## Feedback y momentos
| Qué | Por qué | Dónde |
|---|---|---|
| **ACE**: eliminar tú solo a todo el equipo rival (3+) en una ronda → celebración, aviso a todos y +250 XP. | Momento fuerte de los shooters por rondas. | `server/Modules/Round.luau`, `HUD.luau` (`Notify "Ace"`) |
| **Resultado de ronda**: RONDA GANADA / PERDIDA según tu equipo, marcador y el mejor de la ronda (3 s). | "¿Ganamos?" se responde al instante; no bloquea. | `Round.luau` (`Notify "Round"`), `HUD.luau` `roundResult` |
| **¡REMONTADA!** en la pantalla final si el ganador llegó a ir perdiendo por un 30 % de la meta. | Recompensa emocional al volver de atrás. | `Round.luau` (`maxDeficit`), `HUD.luau` |
| Botones con respuesta: crecen al pasar el ratón, se hunden al pulsar y vuelven con rebote (en móvil se sueltan aunque el dedo salga del botón). | Microinteracción en toda la interfaz desde un solo sitio. | `client/Modules/UI.luau` → `UI.pressFeel` |
| Aviso de baja con placa oscura y franja de color (rojo; dorado a la cabeza o en multibaja) que entra deslizando. | Confirmación de baja más "premium" sin agrandar la UI. | `HUD.luau` (`KillPlate`, `KillAccent`) |
| Hitmarker con tres lecturas: normal (corto, blanco), cabeza (largo, dorado, con «tin» agudo extra), baja (grueso, rojo, gira). | "¿Le pegué? ¿A la cabeza? ¿Lo maté?" sin pensar. | `HUD.luau` `onHitConfirm` |
| Colores de equipo legibles: el rojo/azul puros se suavizan en marcador, killfeed y contorno de compañeros (el azul tira a celeste). | El azul puro casi no se leía sobre fondo oscuro. | `UI.teamTint` |
| Resumen de partida y marcador (Tab) con **asistencias** (bajas / asist. / muertes). | Lectura K/A/D de los shooters competitivos. | `Round.luau` (`MatchAssists`), `HUD.luau`, `Scoreboard.luau` |
| **Desbloqueos con presentación**: arma nueva con celebración a pantalla completa; skins, trajes y efectos con aviso dorado. | Un premio tiene que sentirse premio. | `HUD.luau` (`Notify "Unlock"`) |
| Armas: **barras de estadísticas** (daño, cadencia, control; en cuerpo a cuerpo daño, velocidad, alcance) comparadas con la mejor del juego. | Elegir arma de un vistazo, como en un loadout. | `Menu.luau` `statRows` |

## Gun feel y cámara
| Qué | Por qué | Dónde |
|---|---|---|
| Capa de **cola** en tus disparos (eco grave filtrado en el grupo de armas, 1 cada 0,2 s como mucho). | El disparo suena con cuerpo y entorno, sin saturar en ráfaga. | `shared/Sounds.luau` → `ShotTails` |
| Temblor/alabeo de cámara un 60 % menor al apuntar y casi nulo con "Efectos reducidos". | Competitivo > cinemático. | `WeaponController.luau` |
| Reacción al recibir daño: alabeo corto (≤ 1,5°) y tirón del arma; no mueve la mira. | Sentir el impacto sin perder el control. | `WeaponController.luau` |
| **ARX-27 gold standard** (Fase 9): brazos con IK de dos huesos, recarga táctica/vacía con marcadores (cargador fuera/dentro, cerrojo), palanca de carga, inspección por claves, variante de reposo, salto/aterrizaje con muelle, enfundar animado y charm con muelle. | El arma que más se ve tiene que verse y moverse como la de un shooter grande, sin assets nuevos. | `shared/WeaponVisual.luau`, `WeaponController.luau` (ver `FASE_09_ARX27_GOLD_STANDARD.md`) |
| Rol de pintura **Trim** (oscuro de fábrica, acento con skin) y skin de referencia **Operación Roja**. | Las skins pintan por zonas con sentido en vez de todo igual. | `WeaponModels.luau` (`paint`), `Skins.luau` (`TrimAccent`) |
| Casquillos con la velocidad del jugador; luz del fogonazo apagada en calidad Baja. | Casquillos creíbles al correr; menos coste en móvil. | `Effects.luau`, `WeaponFeel.Quality.MuzzleLight` |
| **Audio real por familia** (Fase 11): disparos, cola, cargador, cerrojo, vacío, sacar y guardar con grabaciones de la biblioteca Pro Sound Effects de Roblox; impactos por material; casquillos. | El mayor salto de «game feel» sin comprar nada. | `shared/Sounds.luau` (`FamilyAudio`, `Impacts`), `Effects.luau` |
| Mira telescópica y viñetas que cubren también la franja de la muesca del móvil. | Antes se veía el mundo junto a la muesca al apuntar. | `HUD.luau`, `AimFX.luau`, `RewardFX.luau` |

## Ajustes
- Calidad: **Auto / Rendimiento / Equilibrada / Alta / Ultra** (los valores guardados siguen siendo Baja/Media/Alta/Ultra, compatibles con las partidas guardadas).

## Móvil (Fase 12)
| Qué | Por qué | Dónde |
|---|---|---|
| Controles táctiles con jerarquía: disparar el más grande, apuntar el segundo, el resto más pequeño; colocados alrededor del botón de saltar de Roblox (el real). | Antes eran nueve círculos iguales con emoji y en tablet pisaban el salto. | `shared/MobileHUD.luau`, `TouchLayout.luau` |
| Pictogramas dibujados con formas en vez de emojis; fondo grafito translúcido con borde; estados en amarillo (apuntando), naranja (pocas balas) y rojo (vacío, sin parpadeo). | Un solo estilo que se lee igual en todos los móviles. | `TouchIcons.luau` |
| Munición en la tarjeta del arma junto a recargar; vida abajo en el centro sin tocar botones; registro de bajas a 14 px; aviso de baja, medallas y banderas fuera del centro. | La mira y el centro limpios. | `HUD.luau`, `DominationHUD.luau` |
| Editor de HUD (mover, tamaño, opacidad) guardado en los ajustes del perfil. | Cada mano es distinta, pero lo de fábrica ya tiene que ser bueno. | `HUDEditor.luau` |

## Mapas (Fase 14)
| Qué | Por qué | Dónde |
|---|---|---|
| Suelo por zonas (láminas de 0,02 bajo juntas y marcas) con bordillo pintado. | El mapa deja de ser una losa gris y cada zona se reconoce por el suelo. | `TacKit/Finish.luau`, `MapDefs/*/Dressing.luau` |
| Remates de fachada (cornisa, esquinas, zócalo) en el color de cada sitio: A cálido, B frío. | Identidad A/B sin tocar coberturas. | `Construction/Dressing.luau` |
| Detalle de ambiente: lonas, encofrados, buganvillas, banderines, frentes con luz, lamas, rótulos. | Lectura de "lugar diseñado"; lo fino se oculta en calidad Baja. | `Finish.luau`, `Settings.HIDE_BELOW` |
| Fondo: silueta industrial (Construction) y vallas de marcas ficticias (Mall Rush). | Que el mapa no flote en el vacío. | `Dressing.luau` |

