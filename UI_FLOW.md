# Flujo de interfaz (arranque → lobby → partida)

Interfaz nativa de Roblox (Frame, TextLabel, UIGradient, UIStroke, UICorner, UIScale, UIListLayout,
UIPadding, UIAspectRatioConstraint, ViewportFrame + WorldModel, TweenService), sin imágenes que finjan
interfaz. Identidad: negro/grafito, **amarillo** para jugar, premios y selección, **rojo** para combate,
eventos y alertas, blanco y algo de azul. Dos familias de letra: Oswald en negrita (títulos, botones,
números) y Gotham (textos).

## Secuencia

```
Boot ─► Home ─┬─► Squad / Armory / Operator (y vuelta con VOLVER, Esc o B)
              └─► JUGAR ─► Matchmaking ─► MatchFound ─► MapIntro ─► TeamIntro ─► Loadout ─► Deploy ─► Gameplay
                                                                                         (3-2-1 ¡YA!)
Gameplay ─(muerte: «menú»)─► Home
Gameplay ─(ronda nueva)─► MapIntro ─► TeamIntro ─► Loadout ─► Deploy ─► Gameplay
```

| Pantalla | Qué hace | Archivo |
|---|---|---|
| **Boot** | Fases reales: CARGANDO INTERFAZ (cola de descarga + `PreloadAsync` de los sonidos de la interfaz), CARGANDO ARMAS (tus datos y los sonidos de las armas), CARGANDO MAPAS (dice qué mapa se construye), PREPARANDO PARTIDA (el lobby montado). Consejos por idioma, partículas sutiles, mapa desenfocado detrás. Sin esperas inventadas. | `src/first/Loading.client.luau`, `src/first/BootTips.luau` |
| **Home** | Tu avatar real en 3D con tu arma y su skin (se gira arrastrando), JUGAR amarillo dominante, menú (Armamento, Operador, Escuadra, Tienda, Pase, Eventos, Clan, Ajustes), barra de arriba (perfil, nivel y XP, monedas, amigos, novedades, retos, ajustes), derecha (recompensa diaria, avisos, misiones diarias, evento o mapa destacado, arma nueva), abajo (modo, rango, inventario, armas, rachas, personalizar). Enter / A = JUGAR. | `Flow/Screens/Home.luau` |
| **Squad** | Tus compañeros reales (copias 3D), nombre, nivel, estado (LISTO / NO LISTO / EN PARTIDA / BOT), líder 👑 (el primero en llegar), aviso al unirse. | `Flow/Screens/Squad.luau` |
| **Armory** | Categorías, lista, arma en 3D con vaivén, DAÑO / PRECISIÓN / CADENCIA / MOVILIDAD / CONTROL animadas (0,25 s), maestría, equipar en cualquiera de las 5 clases, comprar, usar la clase. | `Flow/Screens/Armory.luau` |
| **Operator** | Roles (Asalto, Recon, Pesado, Francotirador, Especial) a partir de los trajes, el traje sobre tu avatar en 3D, ficha (dice que es solo estética), habilidades con tecla y recarga reales, la clase que le va, tira de selección, equipar/comprar. | `Flow/Screens/Operator.luau` |
| **Matchmaking** | BUSCANDO PARTIDA con escáner (barrido + pulso, sin rueda que gira), modo · 5 VS 5, tiempo, ping, votación del mapa, CANCELAR. | `Flow/Screens/Matchmaking.luau` |
| **MatchFound** | 1,4 s: destello, barrido amarillo, golpe de sonido, modo · mapa. Sigue solo. | `Flow/Screens/MatchFound.luau` |
| **MapIntro** | Nombre del mapa enorme, modo, 5 VS 5, luz (atardecer, noche), descripción, cámara sobre el mapa. Dura lo que tarda la carga real. | `Flow/Screens/MapIntro.luau` |
| **TeamIntro** | Tu equipo y el rival con 5 personajes reales cada uno (jugadores y bots), tarjetas con nombre/nivel/estado, VS. Carga progresiva. Solo estética. | `Flow/Screens/TeamIntro.luau` |
| **Loadout** | Las 5 clases (principal, secundaria, granada, ventaja), la última marcada; elegir equipa al momento; si no eliges, entras con ella. | `Flow/Screens/Loadout.luau` |
| **Deploy** | PREPÁRATE 3-2-1 ¡YA! con la cámara bajando a tu espalda; si tu personaje aún no existe, «SINCRONIZANDO PARTIDA…». | `Flow/Screens/Deploy.luau` |

## Sincronización con el servidor

Las presentaciones se ven **mientras** pasa algo real, no se suman a la espera:

- `State = LoadingMap` + `LoadingMap = <mapa>`: el servidor construye el mapa → PARTIDA ENCONTRADA y presentación del mapa.
- `State = Playing` + `Deploy = "Lineup"`: todos quietos (`Frozen`), presentación de equipos y elección de clase hasta `CountdownAt`.
- `Deploy = "Countdown"`: 3-2-1 hasta `DeployEndsAt` (hora del servidor): todos salen a la vez.
- Eliminación y Buscar y destruir: tras la presentación, la cuenta atrás es la preparación de la ronda (`Frozen` + `TimeLeft`).
- Quien entra con la partida empezada hace la misma secuencia, corta y a su ritmo (encontrada → mapa → equipos → clase 5 s → 3 s).

Tiempos: `GameConfig.Deploy` (`LineupTime` 7 s, `CountdownTime` 3 s) y `Flow.Times` en el cliente.

## Piezas comunes

| Módulo | Para qué |
|---|---|
| `Flow/FlowController.luau` (UIFlowController) | `SetState(estado, ctx)`, una sola fuente de verdad. Oculta HUD y bloquea controles fuera de `Gameplay`, cámara del lobby (órbita, pasada del mapa, bajada al personaje), fondo, Esc/B para volver. |
| `Flow/Transition.luau` (UITransitionController) | Fade, SlideIn, Pop (escala), Pulse, Flash, Wipe y Blur (0 → 10-16 en menús, **0 en combate**). 0,12-0,35 s; pantallas grandes 0,3-0,6 s. |
| `Flow/UISound.luau` (UISoundController) | Hover, Click, Back, Play, MatchFound, Reward, Error, Equip, Countdown, Go, Join… Un `Sound` reutilizado por nombre. |
| `Flow/Components.luau` | Raíz escalada, textos con jerarquía, paneles, botones con respuesta (hover 1 → 1,03, pulsar → 0,97 → 1), barras animadas, tarjetas de jugador, puntos de aviso. |
| `Flow/Preview.luau` (PreviewController) | `SetCharacter`, `SetWeapon`, `SetPose`, `SetAnimation`, `SetCameraPreset`, `SetActive`, `Turn`, `Clear`. Copias sin scripts de los personajes (nunca los reales). |
| `Flow/Theme.luau` | Colores, letras, tamaños y duraciones. |

### Animaciones de los personajes del menú

`Preview:SetAnimation(slot, nombre)` con `MenuIdle` (lobby), `OperatorIdle` (operador), `SquadIdle`
(escuadra y equipos), `WeaponInspect` y `VictoryPose`. Mientras no haya animaciones subidas se usa
la pose por código (arma lista). Para usar las tuyas: sube la animación R15 a Roblox y pega
`"rbxassetid://<id>"` en `GameConfig.UIAnimations`.

## Pantallas y móvil

- Raíz con `UIScale`: se diseña en píxeles virtuales (720 de alto en escritorio, 680 en tableta,
  **460 en teléfono**, así los textos no quedan diminutos) y se reescala sola al girar o cambiar la ventana.
- `PHONE` (pantalla de menos de 520 de alto, o ventana pequeña), `TABLET` (táctil) y `DESKTOP`. En el
  teléfono: menú y columnas compactos, sin lo secundario, botones más bajos pero tocables.
- Zona segura: la ScreenGui usa `ScreenInsets = CoreUISafeInsets` (muesca y barra de Roblox).
- El HUD de partida en móvil (joystick y salto de Roblox; disparo, apuntar, recargar, granada,
  agacharse, correr, cambiar arma, cuerpo a cuerpo, marcador, minimapa, killfeed, habilidades) no cambia.

## Rendimiento

- Las vistas 3D solo se animan mientras se ven (`SetActive`); al ocultarse la escuadra y la presentación
  de equipos se borran sus copias (hasta 10 personajes).
- Ninguna pantalla actualiza nada por fotograma cuando está oculta.
- Roblox no dibuja ViewportFrames dentro de un CanvasGroup: las pantallas con 3D son Frames.

## Pruebas automáticas

En el simulador (`harness/`): `flow` (secuencia completa, Eliminación, entrar tarde, sin personaje,
armamento y operador), `boot` (fases y salida sin esperas), `hudclient`, `clientboot`, `menu`.
Las capturas de escritorio (1280×720) y teléfono (844×390) se generan con `flowshots` +
`render/guirender2.py`; `listaudit` avisa si algo está colocado a mano dentro de una lista.
