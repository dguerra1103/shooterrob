# FASE 11 — Pulido general

Sesión de pulido sobre lo que ya existía: sin mapas, modos, armas ni economía nuevos. Orden: audio →
armas/animaciones → móvil/rendimiento → UI → mapas → bots → QA. **Nada de esto se ha visto ni oído
todavía en Studio** (en este entorno no hay Roblox): todo se ha medido con el código, las pruebas Lune
y, en el audio, analizando los archivos reales.

## A. Estado inicial

| Área | Cómo estaba |
|---|---|
| Audio de armas | 12 huecos por arma, **todos vacíos**. Disparos con `paintball.wav` y `Rocket shot.wav` cambiados de tono; cargador, cerrojo y sacar el arma con **clics de pinball** (`Audio/Roblox_Pinball_*`). |
| Impactos | **Sin sonido**: las balas que daban en el escenario solo tenían partículas y marcas. |
| Interfaz | `button.wav` y `electronicpingshort.wav` con el tono cambiado para casi todo. |
| Armas/animaciones | ARX-27 gold standard (Fase 9) y la misma infraestructura en todas las familias. |
| Móvil | Riesgo apuntado en las fases 5 y 8: «el HUD no respeta la muesca». |
| Rendimiento | Pendientes de la Fase 5: la barra de munición se redimensionaba cada fotograma; resto ya con freno. |
| Pruebas | 148 OK. |

## B. Audio

### De dónde sale (sin inventar ningún id)
Roblox licencia para **todos los juegos** la biblioteca de **Pro Sound Effects** (creador
`ProSoundEffects`, cada audio dice «Courtesy of Pro Sound Effects» y está marcado como de dominio
público dentro de Roblox), además de su propio set de interfaz (creador `Roblox`). Se buscó con la API
de la Toolbox de Roblox, se **descargó cada candidato y se midió** (duración, número de disparos por
archivo, ataque, caída a −30 dB, cola) y se miraron las envolventes en gráficas para distinguir un
disparo suelto de una ráfaga. **Los 62 ids que usa el juego se han comprobado uno a uno con la API de
Roblox** (nombre, creador, dominio público). No se han usado sonidos subidos por otros usuarios
(muchos están sacados de otros juegos) ni nada de CoD, Battlefield, CS, Valorant, Fortnite o RIVALS.

`Region = { inicio, fin }` usa `Sound.PlaybackRegion` para quedarse solo con el trozo bueno de un
archivo (un disparo de una toma con varios, quitar un silencio o ruido de fondo). `Variants` alterna
tomas al azar sin repetir la anterior (dos disparos seguidos nunca suenan idénticos), además de la
variación de tono de ±2 %.

### Armas (`Sounds.FamilyAudio`, `Sounds.WeaponAudioFamily`)
Orden: hueco propio del arma (`Sounds.WeaponAudio`, sigue vacío para poner audio propio) → el de su
familia → el genérico. `false` apaga una capa (las grabaciones reales ya llevan el mecanismo, así que
el clic genérico se quita).

| Familia (armas) | Disparo | Identidad |
|---|---|---|
| Fusil (ARX-27, Vortex BR) | AK-47, disparos sueltos de cerca (2 tomas) | equilibrado |
| Subfusil (Specter 9, Nova Drift) | Mini Uzi, un disparo del archivo | ligero y rápido |
| Pistola (Viper, Phantom Sidewind) | Beretta 9 mm (4 tomas) | seco e inmediato |
| Magnum (Hand Cannon) | Smith & Wesson .357 Magnum | crujido grande |
| Escopeta (Havoc Pump, Breach Hammer) | Remington 870 y Savage semiautomática | pesada y agresiva |
| Tirador (Raptor DMR) | «Gun Retort» (disparo seco con eco) | contundente |
| Francotirador (Signal 7) | Barrett .50 | lento y contundente |
| Suprimida (Ghostline XR) | H&K SOCOM Mk 23 suprimida, más grave | apagado |
| Ametralladora (Titan LMG) | AK-47 más grave | muy pesada |

Manejo: cargador fuera/dentro (AK-47 en fusiles; cargador de pistola en pistolas y subfusiles),
palanca de carga (cámara de una M85), cerrojo (Machine Gun Bolt), corredera, bombeo de escopeta
(con el cartucho saliendo), montar un subfusil (MP 40), cartucho entrando, agarrar el arma, sacar de
la funda, guardar, inspeccionar, clic en vacío y «fium» de golpe. **Cola**: disparo lejano real
(Desert Eagle a distancia) a poco volumen, más grave en las armas pesadas.

Sin familia (a propósito): Splat-X (paintball), ballesta y lanzacohetes siguen con sus genéricos.

### Disparos de los demás
Ahora usan la **misma grabación** que el arma; de lejos, apagada (sin agudos) y con retraso, como
antes. Antes de lejos sonaba el genérico.

### Impactos (nuevo)
`Sounds.Impacts` + `Effects.Impact`: hormigón/ladrillo/asfalto (y el plástico de los mapas, que hace
de pared), madera, metal (con rebote), cristal, tierra y nieve. En 3D donde da la bala, como mucho uno
cada 50 ms. Es información de juego: suena también en calidad Baja.

### Casquillos (nuevo)
Tintineo corto de casquillos al caer (4 tomas), solo cuando la calidad muestra casquillos y como
mucho uno cada 0,16 s.

### Interfaz (`UISound`)
Set oficial de Roblox: hover (RBLX UI Hover 03), clic (Roblox_UI_Bright_Click), atrás (RBLX UI Back),
jugar (RBLX UI Select 01), whoosh (Roblox_UI_Whoosh_04), equipar (Roblox GUI - Equip), recompensa,
reclamar y partida encontrada (Roblox GUI - Notification High), compra (RBLX UI Purchase), error
(Roblox_UI_Delete), unirse (RBLX UI Select 02), tic (Roblox_UI_Small_Click). La cuenta atrás, el
golpe de VICTORIA/DERROTA y el MVP no se han cambiado. `UISound.Custom` sigue libre para audio propio.

### Feedback de combate
Hitmarker, headshot y baja **no se han cambiado** (`snap.wav` y `electronicpingshort.wav`): son
cortos, distintos entre sí y rápidos, que es lo que importa. No se ha encontrado en la biblioteca un
«tink» de headshot claramente mejor sin poder escucharlo.

### Qué no se ha podido hacer
**No se ha escuchado nada**: la selección es por descripción y por medidas. Los volúmenes están
igualados por medida, pero el balance final se tiene que hacer con los oídos (sección M).

## C. Armas

Se recorrieron **las 17 armas de fuego** en el simulador con el mismo banco del ARX-27:

| Medida | Resultado |
|---|---|
| Manos en el arma (cadera, ADS, recarga vacía, inspección) | 0,000-0,005 studs en todas |
| ADS centrado | ≤ 0,004 studs en todas las que se ven al apuntar. Francotiradores: se desvían 0,09 pero el arma **se oculta** con la mira telescópica (a partir del 85 %), así que no se ve |
| NaN o posiciones rotas en recargas e inspección | ninguno |
| Mayor salto por fotograma (sacar, sprint, ADS, disparo, recarga, inspección, cancelar inspección, golpe) | sacar ≤ 0,14 studs / 8,7°; ADS ≤ 0,19 studs (velocidad de ADS de juego, no se toca); el resto ≤ 0,05 studs / 6° |

No se cambió ningún valor de juego (daño, cadencia, dispersión, cargador, retroceso, velocidades,
tiempos del servidor). Las armas tienen ya identidad por familia también en el sonido (B).

## D. Animaciones

Sin cambios de código: la auditoría (C) no encontró saltos, brazos que no lleguen ni cortes raros.
Un salto aparente de 0,8-1 studs al cambiar de arma resultó ser un **error de la medida** (se medían a
la vez el arma que se guarda y la nueva); con el modelo correcto, sacar el arma da ~0,1 studs por
fotograma en todas las familias.

## E. UI

[se completa con la auditoría del flujo]

## F. Mapas

Sin cambios de geometría ni de jugabilidad (spawns, sitios A/B, rutas, objetivos intactos).

- **Iluminación de Construction, Coastal y Mall Rush revisada** (`MapDefs/*/Lighting.luau`): bloom
  0,35-0,5 con umbral alto, niebla 0,2-0,26 (no tapa enemigos a la distancia de un mapa 5v5), SunRays
  ≤ 0,12, sin desenfoque de profundidad en combate (`GameConfig.AimDepthOfField = false`). No hay nada
  exagerado que bajar.
- Las capturas que hay de la Fase 3 son de un visor aproximado (sin la luz ni los materiales reales de
  Roblox), así que **no se han retocado colores ni materiales a ciegas**. Lo que hay que mirar en
  Studio está en la sección M.

## G. Móvil

- **Muesca**: según la documentación oficial de Roblox, con `IgnoreGuiInset = true` una ScreenGui
  pasa a `ScreenInsets = DeviceSafeInsets`. Es decir: **la información del HUD ya queda fuera de la
  muesca** (el riesgo de las fases 5 y 8 lo resuelve el motor). El problema real era el contrario: el
  borde negro de la mira telescópica y las viñetas se **recortaban** a la zona segura y dejaban ver el
  mundo en la franja de la muesca.
  - HUD: `ClipToDeviceSafeArea = false` (el contenido sigue dentro de la zona segura; solo lo que se
    sale a propósito, el borde de la mira, llega al borde real). Comprobado que ningún elemento del
    HUD se esconde fuera de la pantalla.
  - Viñeta de apuntado y destellos de borde: `ScreenInsets = None` (son velos decorativos).
- Calidad Baja: sigue igual (sin casquillos, marcas ni luz de fogonazo; hitmarker, objetivos,
  enemigos y avisos de baja intactos). Los impactos suenan también en Baja (información de juego).

## H. Rendimiento

- **Barra de munición**: se redimensionaba y recoloreaba en cada fotograma (pendiente de la Fase 5);
  ahora solo cuando cambia (a medio punto) o cambia de estado.
- **Balizas que parpadean** (`WorldFX`): escribían `Transparency` cada fotograma; ahora solo al
  encenderse o apagarse.
- Revisadas las 44 conexiones por fotograma del cliente: las pantallas del flujo desconectan su
  `RenderStepped` al cerrarse; el resto sale pronto o va con freno (30 Hz, 4 Hz). El minimapa busca
  algún hijo por punto a 30 Hz con ~20 puntos: coste despreciable, no se tocó.
- Audio: los sonidos 2D que más se repiten siguen en su pool (también las tomas de cada variante); los
  impactos llevan freno de 50 ms y los casquillos de 0,16 s.
- **No hay cifras de FPS**: hay que medir en Studio y en un móvil (sección M).

## I. Bots

[se completa con la auditoría de bots]

## J. Bugs

| Bug | Dónde | Estado |
|---|---|---|
| Impactos de bala sin sonido | `Effects.Impact` | corregido (B) |
| Disparos lejanos con el sonido genérico en vez del del arma | `Sounds.PlayShot` | corregido (B) |
| Borde de la mira y viñetas recortados junto a la muesca | `HUD`, `AimFX`, `RewardFX` | corregido (G) |
| Material de impacto sin reconocer en el simulador (los `Enum` de Lune no son únicos) | `Effects` | robustecido: también se busca por nombre (inocuo en Roblox) |

## K. Tests

- `weaponfeel`: familias de audio completas, el hueco propio manda sobre la familia, al quitarlo
  vuelve la familia, armas sin familia usan el genérico, capa de mecanismo apagada, variantes que se
  alternan sin repetir.
- `weaponsounds`: disparo con grabación real + estampido + cola (sin el clic genérico), recarga con
  los sonidos de la familia, disparo lejano del enemigo con su grabación apagada, **impactos por
  material** (madera, metal, plástico) en 3D y con freno.
- `weaponvisual`: el ARX-27 usa la familia Fusil.
- Estas pruebas antes comprobaban «todavía no hay audio propio»; se han cambiado porque ese era
  justo el comportamiento que había que cambiar, no para conseguir verde.

## L. Trabajo pendiente

[se completa al final]

## M. Qué necesita validación real jugando

[se completa al final]
