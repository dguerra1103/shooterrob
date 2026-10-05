# VISUAL_IMPROVEMENTS

Pase "Stylized Tactical Roblox". Qué cambió, por qué y dónde. Todo se puede apagar o ajustar en
`src/shared/GameConfig.luau`.

## Iluminación y color
| Qué | Por qué | Dónde |
|---|---|---|
| Estilo **Táctico** para todos los mapas (`VisualStyle = "Tactico"`): sombras rellenas (nada de zonas negras), niebla limitada (densidad ≤ 0,34), brillo contenido (bloom ≤ 0,5 de día, umbral ≥ 1,8), color algo más vivo (saturación 0,08–0,16) y cada mapa conserva su tinte. | Legibilidad competitiva + identidad Roblox moderna: ni gris militar ni dibujo animado. | `server/Modules/MapKit.luau` → `tacticalize` |
| Mapas 5v5 diseñados (Encrucijada, Base Militar, Cumbre): solo límites de legibilidad y saturación mínima 0,09. | Ya tenían su luz pensada; no se rehacen. | `MapKit.tacticalize(preset, true)` |
| Ultra: el desenfoque de profundidad solo actúa más allá de 250 studs. | Un enemigo a distancia de combate nunca sale borroso. | `client/Modules/Settings.luau` |

## Legibilidad en combate
| Qué | Por qué | Dónde |
|---|---|---|
| **Contorno rojo fino** en enemigos (Highlight `Occluded`, borde semitransparente, sin relleno). Se quita al morir y se recalcula si cambia de bando. | Ver al enemigo al instante contra cualquier fondo, sin dar información a través de paredes. | `client/Modules/WorldFX.luau`, `GameConfig.EnemyOutline` |
| **Nombres de zona**: «📍 HOTEL CENTRAL», «AVENIDA», «BASE AZUL» bajo el minimapa; en mapas sin nombres, «NORTE · LADO AZUL». | 5v5: poder decir dónde estás («en las obras») y orientarse. | `client/Modules/ZoneName.luau`, `Kit.callout`, `RealKit.building` (los edificios con cartel se nombran solos) |
| HUD de combate limpio: retos y barra del evento salen solo un rato (al aparecer y al progresar); el botón de tienda se oculta en PC mientras luchas (tecla B); «Racha x0» no se muestra. | Menos ruido en pantalla durante el tiroteo. | `QuestTracker.luau`, `EventHUD.luau`, `Menu.luau`, `HUD.luau` |
| Botones de habilidades en PC compactos (oscuros con el color en el borde); en móvil siguen grandes. | Jerarquía: las habilidades no compiten con la mira. | `client/Modules/Abilities.luau` |

## Feedback y momentos
| Qué | Por qué | Dónde |
|---|---|---|
| **ACE**: eliminar tú solo a todo el equipo rival (3+) en una ronda → celebración, aviso a todos y +250 XP. | Momento fuerte de los shooters por rondas. | `server/Modules/Round.luau`, `HUD.luau` (`Notify "Ace"`) |
| **Resultado de ronda**: RONDA GANADA / PERDIDA según tu equipo, marcador y el mejor de la ronda (3 s). | "¿Ganamos?" se responde al instante; no bloquea. | `Round.luau` (`Notify "Round"`), `HUD.luau` `roundResult` |
| **¡REMONTADA!** en la pantalla final si el ganador llegó a ir perdiendo por un 30 % de la meta. | Recompensa emocional al volver de atrás. | `Round.luau` (`maxDeficit`), `HUD.luau` |
| Botones con respuesta: crecen al pasar el ratón, se hunden al pulsar y vuelven con rebote. | Microinteracción en toda la interfaz desde un solo sitio. | `client/Modules/UI.luau` → `UI.pressFeel` |

## Gun feel y cámara
| Qué | Por qué | Dónde |
|---|---|---|
| Capa de **cola** en tus disparos (eco grave filtrado, 1 cada 0,12 s como mucho). | El disparo suena con cuerpo y entorno, sin saturar en ráfaga. | `shared/Sounds.luau` → `ShotTails` |
| Temblor/alabeo de cámara un 60 % menor al apuntar y casi nulo con "Efectos reducidos". | Competitivo > cinemático. | `WeaponController.luau` |
| Reacción al recibir daño: alabeo corto (≤ 1,5°) y tirón del arma; no mueve la mira. | Sentir el impacto sin perder el control. | `WeaponController.luau` |

## Ajustes
- Calidad: **Auto / Rendimiento / Equilibrada / Alta / Ultra** (los valores guardados siguen siendo Baja/Media/Alta/Ultra, compatibles con las partidas guardadas).
