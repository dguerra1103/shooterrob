# FASE 15 — Rediseño visual del HUD móvil (referencia: Galaxy S26 Ultra)

Pasada de **diseño** (composición, jerarquía, proporciones y ergonomía) del HUD táctil, con el Samsung
Galaxy S26 Ultra en horizontal (19,5:9) como pantalla de referencia. **No se ha tocado el juego**:
daño, retroceso, asistencia de apuntado, dispersión, velocidad, salto, cadencia, armas, bots, mapas y
economía están igual. Solo HUD móvil, controles táctiles, presentación y ergonomía.

> Todo lo de este documento está **implementado y comprobado fuera del motor** (pruebas Lune y capturas
> del renderizador). **Pendiente de validar en el S26 Ultra real** (sección 10). El renderizador
> aproxima fuentes, trazos y textos cortados; los colores y tamaños finos se juzgan en el teléfono.

## 1. ANTES

Capturas con el código anterior (`7060821`) en las mismas condiciones que las de después: perfil
`GALAXY_S26_ULTRA` (pantalla 892×412, 19,5:9), el mismo fondo de juego (patio de Construction a la
altura de los ojos) y la misma zona segura simulada. Ver la sección 7.

## 2. PROBLEMAS (lo que estaba visualmente mal)

| # | Problema | Por qué se veía feo / incómodo |
|---|---|---|
| 1 | El grupo derecho se medía desde el **botón de saltar de Roblox**, pegado al borde físico | En una pantalla larga, los botones acababan contra la esquina; el salto (gris, de Roblox) no tenía nuestro estilo |
| 2 | **Botones casi iguales** (círculos de 46-56 px con el mismo fondo y borde) | No había jerarquía: granada, recargar y cuerpo a cuerpo competían con disparar |
| 3 | Granada, cuerpo a cuerpo y ataque aéreo **flotando** en un arco alto | Se veían «sueltos» y se comían la zona donde gira el pulgar derecho |
| 4 | **Tarjeta del arma** grande (136×50) con nombre, «1/2» y munición | Una caja rectangular más en la parte de abajo |
| 5 | **Vida**: barra gruesa de 190 px con caja, brillo y cruz-emoji | Demasiado peso visual para un dato secundario |
| 6 | **Marcador**: cajas con borde negro grueso y brillo, más la línea fija «mapa · modo · primero a 50» | Grande y con texto que no cambia durante el combate |
| 7 | **Cuatro círculos de 38 px** arriba a la derecha (menú, grafiti, emotes, marcador) | Parecían botones de combate; en zona de la barra de Roblox |
| 8 | Iconos con **grosores distintos** (0,07 a 0,1 del icono) | Uno grueso junto a uno fino |
| 9 | Avisos de XP **junto a la mira** y emoji 💀 en el aviso de baja | Texto cerca del centro, estilo de prototipo |
| 10 | Zona segura: los botones usaban la del **dispositivo** (DeviceSafeInsets) | La tira de arriba podía caer bajo los botones de Roblox |
| 11 | Botones que **se pisaban** (hueco mínimo −3/−5 px entre dibujos) | Medido con la herramienta de métricas (sección 6) |

## 3. DISEÑO NUEVO

Cinco zonas, nada flotando al azar:

| Zona | Qué | Cómo |
|---|---|---|
| 1 · arriba izquierda | Minimapa + objetivo (A/B/C) debajo | Minimapa 96 px (84 en teléfonos bajos), separado del borde en pantallas alargadas; el objetivo (Dominio) y el nombre de la zona alineados con él |
| 2 · arriba centro | Marcador `[ 12 ]  05:12  [ 9 ]` | Pastillas pequeñas sin brillo; **tu equipo a la izquierda en azul, el rival a la derecha en rojo**; la línea del modo solo sale cuando dice algo que cambia (calentamiento, «en pie», infección) |
| 3 · arriba derecha | Tira de poco uso + registro de bajas | Tira de 4 iconos cuadrados de 30 px sobre una pastilla común (menú ⚙ al final); debajo, el registro de bajas: **3 filas como mucho**, 230 px de ancho fijo, 13 px, nombres de más de 12 letras cortados con «…» |
| 4 · abajo izquierda | Pulgar izquierdo | Joystick de Roblox; encima, **una fila**: impulso, supersalto y poción (tarjetas cuadradas de 40 px con velo de recarga) y la granada (círculo de 46 px) |
| 5 · abajo derecha | **Grupo de combate** | Ver sección 5 |

Además: **vida compacta** («100» en 16 px + barra de 4 px, cruz dibujada sin emoji) abajo a la
izquierda del centro; **munición compacta** junto a recargar (`ARX-27 PULSE` en 12 px, `24 | 90` con el
cargador en 22 px y la reserva en 14 px: blanco normal, naranja con pocas balas, rojo vacío,
«RECARGANDO…» en amarillo); avisos de XP a la izquierda bajo el minimapa; avisos de texto bajo el centro
libre; aviso de baja sin emoji (la franja de color dice el tipo).

**El centro** solo lleva mira, hitmarker, indicadores de daño y avisos temporales (radio libre =
0,17 × lado corto, comprobado en las pruebas).

### Estilo

- Fondo grafito translúcido según importancia: DISPARAR 20 % (centro casi transparente), APUNTAR 36 %,
  acciones 32 %, poco uso 22 %. Al pulsar, +16 %.
- Borde muy fino (1,5 px) blanco al 45 %; DISPARAR 2,5 px al 80 % y un **anillo interior fino** (retícula),
  así se distingue de todo sin ser una pelota maciza.
- Estados: **amarillo** activo (apuntando, recargando), **naranja** pocas balas, **rojo** vacío, **azul**
  aliado. Sin parpadeos.
- Formas con significado: círculos para combate, **tarjetas cuadradas** para habilidades y la tira de poco
  uso, **pastilla** para cambiar de arma.
- Iconos: el mismo grosor de trazo para todos (`TouchIcons.Line` = 0,09 del icono; anillos igual), mismo
  tamaño relativo (52 % del botón; DISPARAR 44 %), misma opacidad. Nuevos: **saltar** (pareja de
  agacharse) y **cambiar** (dos flechas).
- Sin texto dentro de los botones (solo números en globos y recargas).
- Texto: información importante 16-22 px en negrita, secundaria 12-13 px; nada por debajo de 12 px.
- Animación: al pulsar baja a **0,95 en 0,08 s** y vuelve; sin rebotes ni brillos.
- Al apuntar, lo secundario (granada, cuerpo a cuerpo, habilidades, poco uso) baja al **60 %**; nada
  desaparece.

## 4. ULTRAWIDE (cómo se detecta y qué cambia)

`MobileHUD.Classify(zonaSegura, táctil, pantalla)` — **por la forma, nunca por el modelo**:

| Clase | Regla | Ejemplos |
|---|---|---|
| `TABLET` | lado corto ≥ 560 | 1024×768, 1180×820 |
| `COMPACT_PHONE` | lado corto < 350 | 568×320 |
| `ULTRAWIDE_PHONE` | proporción ≥ 1,95 | 844×390, 896×414, **perfil GALAXY_S26_ULTRA 892×412** (19,5:9), 20:9 |
| `STANDARD_PHONE` | el resto | 667×375 (16:9) |

La proporción y el lado corto salen de la **pantalla entera** (`workspace.CurrentCamera.ViewportSize`);
las posiciones, de la **zona segura**. Así la cámara frontal o la barra de Roblox no cambian la clase.

**Escala lógica** = lado corto / 390 (referencia 844×390), con topes por clase (compacto 0,78-0,9;
estándar 0,88-1; alargado 0,95-1,12; tableta 1,1-1,25). En el S26 (412 de alto): **1,06**.

**Grupo de combate metido hacia dentro**: margen desde el borde derecho de la zona segura =
(113 + 26) × escala + un extra en alargadas = `(proporción − 1,9) × lado corto × 0,2` (máx. 40 px). En el
S26: DISPARAR a **169 px** del borde (centro) y el botón más exterior (saltar) a **49 px**; antes el salto
de Roblox quedaba a ~25 px.

## 5. SAFE AREAS

- **Botones** (interactivos): ScreenGui con `ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets`
  (con `IgnoreGuiInset = false` como respaldo, que es lo mismo). El motor quita la muesca o el agujero
  de la cámara **y** la barra de botones de Roblox. No hay ningún valor de muesca inventado.
- **Información** (HUD, minimapa…): `DeviceSafeInsets` (fuera de la muesca, puede usar la franja de la
  barra de Roblox en el centro: ahí va el marcador).
- El editor de HUD y la capa de depuración usan la **misma** zona que los botones (lo que se arrastra
  cae donde queda el botón).
- La zona se vuelve a leer en cada recolocación y 10 veces por segundo (si cambia la barra de Roblox o
  se gira, se recoloca).
- **Mira telescópica**: sigue cubriendo toda la pantalla (`ClipToDeviceSafeArea = false`, Fase 11) y
  los botones quedan encima, accesibles.

## 6. CONTROLES

### Grupo de combate (S26, 892×412, escala 1,06; centros en px de la zona segura sin recortar)

| Control | Tamaño | Dónde | Por qué |
|---|---|---|---|
| **DISPARAR** | **97** (zona ×1,2) | (723, 298), el centro del grupo | Donde descansa el pulgar; el más grande |
| **APUNTAR** | 65 | arriba-izquierda de disparar (626, 244) | Segundo más importante, sin ir al borde |
| **SALTAR** | 61 | a la derecha (812, 286) | Medio; botón propio con nuestro estilo |
| **AGACHARSE** | 52 | debajo del salto (793, 364) | Pareja vertical salto/agacharse |
| **RECARGAR** | 48 | a la izquierda de disparar (621, 322), junto a la munición | Cerca del dato que lo pide |
| CUERPO A CUERPO | 42 | encima, entre apuntar y salto (708, 216) | El más pequeño del combate |
| Ataque aéreo | 42 | arco de arriba (solo con cargas) | — |
| CAMBIAR ARMA | pastilla 126×33 | abajo, bajo la munición (518, 372) | Muestra el **arma a la que se cambia** («⇄ SPECTER-9»); con una sola arma no se ve |

**Saltar**: el botón de Roblox (`TouchGui.TouchControlFrame.JumpButton`) se esconde mientras exista el
nuestro (se vigila su `Visible`). El nuestro hace **exactamente** lo mismo: mientras el dedo está encima,
`Humanoid.Jump = true` en cada fotograma, enganchado con `BindToRenderStep` justo después del
ControlModule de Roblox (`RenderPriority.Input + 1`). Misma altura, mismo coste de estamina, mismo
autosalto al mantener.

### Zona de cámara

`MobileHUD.Zones` calcula la **CAMERA SWIPE ZONE**: el rectángulo más grande a la derecha del centro
libre y por encima del grupo de combate **sin ningún botón** (se comprueba en las pruebas). En el S26
(sin recortes): x 488-888, y 44-187 → **15,5 % de la pantalla**, más todo el hueco entre el centro y el
grupo y el propio DISPARAR (que deja girar la cámara con el mismo dedo, «arrastrar para apuntar»).

### Métricas (herramientas de ayuda, no la verdad)

Misma herramienta para antes y después (antes incluye el salto de Roblox, que era parte del grupo):

| Pantalla | Cobertura de los botones | Zona de cámara | Hueco mínimo entre dibujos |
|---|---|---|---|
| 568×320 | 14,2 % → **11,5 %** | 7,5 % → **14,8 %** | −3 → **5 px** |
| 667×375 | 15,2 % → **11,5 %** | 7,0 % → **15,0 %** | −4 → **6 px** |
| 844×390 | 11,6 % → **9,4 %** | 8,6 % → **15,4 %** | −4 → **6 px** |
| 896×414 | 10,2 % → **9,4 %** | 10,7 % → **15,5 %** | −4 → **6 px** |
| **892×412 (S26)** | 10,3 % → **9,4 %** | 10,5 % → **15,5 %** | −4 → **6 px** |
| 1024×768 | 8,8 % → **6,2 %** | 15,4 % → **24,6 %** | −5 → **8 px** |

(El hueco de 5-6 px es entre los iconos de la tira de poco uso, que van juntos a propósito; en el grupo
de combate los huecos son de 10-20 px.)

### Capa de depuración (`GameConfig.MobileHUDDebug`, **false** por defecto, solo Studio)

Dibuja **SAFE RECT** (con pantalla, proporción, clase, escala e insets), **CENTER DEAD ZONE**,
**CAMERA SWIPE ZONE**, **LEFT THUMB ZONE**, **RIGHT THUMB ZONE** y **BUTTON HITBOXES** (nombre, tamaño
y opacidad de cada control). Usa los controles de la partida aunque un menú los tenga escondidos en ese
momento (antes se dibujaba vacía si se recolocaba con un menú abierto).

### Editor de HUD y versión de la disposición

- El editor sigue igual (mover, tamaño, opacidad) y ahora usa la misma zona segura que los botones.
- **RESTABLECER** vuelve a la disposición **nueva**.
- `GameConfig.DefaultSettings.HudLayoutVersion = 2` (`MobileHUD.LayoutVersion`). Al cargar el perfil, el
  **servidor** migra (`MobileHUD.MigrateLayout`):
  - sin personalizar (vacía) → usa la disposición nueva;
  - personalizada (versión 1) → **se conserva tal cual** (sus posiciones son fracciones de la zona segura y
    sus tamaños/opacidades multiplicadores; los controles que no tocó usan la nueva);
  - basura → se limpia (`Validate`). Nunca se borran los ajustes del jugador.
- Riesgo conocido: alguien que movió DISPARAR en la Fase 12 lo tendrá donde lo dejó, y el salto nuevo
  (que antes era de Roblox) va a su sitio de fábrica; si se pisan, se arregla con RESTABLECER o
  moviéndolo.

## 7. RENDERS

Renderizador de interfaz (volcado del simulador → HTML → Chromium) sobre un fondo de juego real
(Construction a la altura de los ojos). Perfil `GALAXY_S26_ULTRA` **solo de simulación**: pantalla
892×412 (19,5:9), cámara frontal a la izquierda (32 px) y barra de Roblox arriba (58 px). El juego no usa
estos números: lee los del motor.

| Lámina | Qué |
|---|---|
| `01_s26_antes_despues.png` | S26, partida normal con killfeed: antes / después |
| `02_s26_cargador_vacio.png` | S26, cargador vacío: antes / después |
| `03_s26_estados.png` | S26: apuntando, recargando, habilidades y granada en recarga |
| `04_s26_sniper_debug.png` | S26: francotirador (mira a pantalla completa con controles encima) y la capa de depuración |
| `05_matriz_*.png` | 568×320, 667×375, 844×390 (muesca simulada), 896×414, 1024×768: antes / después |

Limitaciones del renderizador: no corta texto con «…» (se ve cortado a pelo), aproxima fuentes y
sombras, no dibuja el 3D del minimapa ni la máscara exacta de la mira. En el simulador el arma no queda
equipada dentro del WeaponController, así que los estados (apuntar, munición) se aplican a mano en el
script de capturas.

## 8. TESTS

Pruebas nuevas o actualizadas (todas en `tests/run_all.sh`):

- `mobilehud`: clases (S26 → ULTRAWIDE_PHONE, también con zona segura recortada y en vertical), escala,
  jerarquía completa, formas, tira de poco uso, iconos nuevos, **versión y migración**, y en 10
  combinaciones de pantalla/zona segura: dentro de la zona segura, **sin solapes** (4 px de aire), centro
  libre, **zona de cámara ≥ 9 % sin ningún botón**, grupo derecho a ≥ 18 px del borde (≥ 36 en
  alargadas) y más hacia dentro que en 16:9; métricas del S26.
- `touchbtns`: clase ULTRAWIDE en 844×390, jerarquía, **salto propio** (salta, mantiene, suelta; el de
  Roblox se esconde), recargar marcado al recargar, tarjeta con el arma siguiente (una línea, ≥ 12 px,
  «…»), sin solapes.
- `hudeditor`: tamaños con la escala nueva; restablecer → disposición nueva.
- `phonefx`: vida compacta; botones dentro, sin solapes y fuera del centro en 6 pantallas (con el salto
  en el grupo).
- `datastore`: migración de la disposición en el servidor (sin personalizar, personalizada, basura) y
  guardado migrado.
- Simulador (`mock.luau`): zona segura por ScreenGui (`ScreenInsets` / `IgnoreGuiInset`) e
  `ImageButton` como GuiObject.

Se mantienen: `touchbtns`, `hudeditor`, `mobilehud`, `phonefx`, `movement`, `abilities`, `clientboot`,
`hudclient`.

Resultado de la batería completa: ver «Resultado final» al final del documento.

## 9. MATRIZ

| Pantalla | Clase | Escala | Revisado en captura | Notas |
|---|---|---|---|---|
| **892×412 (S26, 19,5:9)** | ULTRAWIDE_PHONE | 1,06 | ✔ (7 estados) | Referencia |
| 568×320 | COMPACT_PHONE | 0,82 | ✔ | Minimapa 84 px; aviso de baja bajo el marcador |
| 667×375 | STANDARD_PHONE | 0,96 | ✔ | — |
| 844×390 (muesca simulada) | ULTRAWIDE_PHONE | 1,0 | ✔ | Zona segura 750×369 |
| 896×414 | ULTRAWIDE_PHONE | 1,06 | ✔ | — |
| 1024×768 | TABLET | 1,25 | ✔ | El panel de retos sigue en tableta (como antes) |

Las 10 combinaciones de `mobilehud` (incluidas 932×430, 1180×820 y la del S26 con la zona recortada)
pasan las comprobaciones geométricas.

## 10. PENDIENTE EN DISPOSITIVO REAL (Galaxy S26 Ultra, horizontal)

1. **Zona segura real**: activa `MobileHUDDebug` en Studio con el emulador o mira dónde cae la tira de
   arriba en el teléfono: ¿queda bajo la barra de Roblox, sin pisarla? ¿Nada detrás de la cámara frontal
   (gira el móvil a los dos lados)?
2. **Salto**: ¿se ve **un solo** botón de saltar (el nuestro, a la derecha de DISPARAR)? Si aparece
   también el gris de Roblox, dímelo: es la única pieza que depende del nombre interno de Roblox.
   Mantener saltar: ¿salta seguido como antes?
3. **Pulgar derecho**: con el agarre normal, ¿DISPARAR cae bajo el pulgar sin estirar? ¿APUNTAR,
   saltar y agacharse se alcanzan sin soltar el móvil? ¿El grupo está demasiado dentro o demasiado
   fuera? (se ajusta con un número: `ClusterReach`/margen en `MobileHUD`).
4. **Girar la cámara**: el dedo derecho en la zona de arriba a la derecha, ¿gira sin tocar ningún botón
   por accidente?
5. **Centro**: ¿nada tapa la mira?
6. **Lectura**: munición (`24 | 90`), vida (`100`), marcador y killfeed, ¿se leen sin esfuerzo? ¿El
   nombre del arma de la pastilla se corta con «…» y no en dos líneas?
7. **Estados**: cargador vacío (recargar en rojo), recargando (amarillo), apuntando (apuntar en amarillo,
   lo secundario algo más tenue).
8. **Francotirador**: la mira cubre todo y los botones siguen usables.
9. **Escopeta/SMG**: disparar sin apuntar, cómodo.
10. **Editor**: mover un botón cae donde sueltas; RESTABLECER deja la disposición nueva.
11. **Rendimiento**: sin tirones al abrir/cerrar menús o al girar (la recolocación solo ocurre al cambiar
    algo).

Capturas que necesito del teléfono: partida normal, apuntando, cargador vacío, francotirador y (si
puedes) el editor abierto.

## Resultado final

Batería completa sobre `1b739ab` (el código final de la fase; después solo cambia documentación):
- `tests/check.sh`: Rojo compila, luau-lsp **sin errores** (exit 0).
- `tests/run_all.sh`: **OK: 150 · FALLOS: 0** (exit 0). Incluye `mobilehud`, `touchbtns`, `hudeditor`,
  `phonefx`, `movement`, `abilities`, `clientboot`, `hudclient`, `datastore`, la navegación de los 9
  mapas, el arranque de los 10 modos y el **ciclo de 10 partidas**.
- Visual: **cambio implementado, pendiente de validar en el S26 Ultra** (sección 10).

## 11. Primera captura del S26 Ultra (fallo encontrado y arreglado)

La primera captura del teléfono es de **la versión publicada**, anterior a la Fase 12 (botones redondos
con emoji, que se quitaron en `af79102`): no incluye las Fases 12-15 porque no se ha publicado nada.
Pero mostraba un **fallo real que también tenía la rama**: el HUD de **ordenador** en el teléfono
(ranuras de armas, «PASE · TIENDA», vida grande, habilidades con emoji). Por las proporciones de la
captura la pantalla lógica es de unos 830×383, así que no era el tamaño: **el S26 Ultra dice
`KeyboardEnabled = true`**, y 23 sitios decidían «móvil» con `TouchEnabled and not KeyboardEnabled`.

Arreglo: `shared/InputMode.TouchUI()`, un solo criterio para todo el cliente. Con pantalla táctil manda
`UserInputService.PreferredInput` (API del motor: Touch en un teléfono aunque declare teclado); si el
motor no la tiene, táctil cuando no hay teclado **o no hay ratón** (un teléfono no tiene ratón; un
portátil táctil con ratón sigue con la interfaz de ordenador). Lo usan el HUD, los botones táctiles,
el minimapa, las habilidades, la granada, el ataque aéreo, la asistencia de apuntado, el visor, los
efectos, los ajustes, los consejos, el tutorial y el resto de módulos que lo calculaban por su cuenta.
Prueba nueva `inputmode` (táctil + «teclado» sin ratón = HUD táctil completo, ULTRAWIDE_PHONE).

**Para verlo en el teléfono hay que publicar** (Actions → Publicar en Roblox, a mano y con el Place
ID; no lo hago yo) o probar en Studio con el emulador. Hasta entonces el teléfono enseña la versión
vieja.
