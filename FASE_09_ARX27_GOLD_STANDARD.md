# FASE 9 — ARX-27 «gold standard»

> **Sin Roblox Studio.** Todo esto está validado fuera del motor: build con Rojo, luau-lsp y pruebas
> Lune que comprueban la lógica y las posiciones (no el aspecto). **Cómo se siente hay que verlo
> jugando** (sección L). Fase de **presentación**:
> - no cambia el daño, la cadencia, la dispersión, el retroceso de juego, el cargador, los tiempos de
>   recarga del servidor, la velocidad ni el ADS de juego;
> - la prueba `weaponvisual` lo comprueba con los números del ARX-27.

## A. Estado anterior (auditoría del código real)

| Pieza | Cómo estaba |
|---|---|
| **Modelo** | Estilo «Clásico» (`Weapons.Style`): `WeaponDesignsClassic.ARX27` → fusil tipo M4 de **93 piezas** (Parts biseladas, sin mallas ni texturas). `Handle` en el origen y todo soldado a él. |
| **Piezas separadas** | **Cargador** (13 piezas `Mag*`): sí, ya salía y entraba en la recarga. **Palanca de carga** (`ChargingHandle`): existía pero **no se movía**. Sin cerrojo visible ni tapa de expulsión móviles (`EjectionPort` es una placa fija). |
| **Puntos** | Attachments `Muzzle`, `AimPoint` y `Eject` en el `Handle`. Manos (`LeftHand`, `RightHand`) y pose de cadera (`ViewOffset`) como números en `Weapons.luau`. Punto del colgante calculado (`WeaponModels.CharmPoint`). |
| **Brazos** | Procedurales: 4 bloques por lado (brazo, manga, guante y puño) **rígidos**, sin codo. En la recarga, el brazo entero se desplazaba como un palo, con el hombro incluido. |
| **Animación** | **Toda procedural** (no hay `AnimationController`, `Motor6D` ni AnimationIds en el viewmodel). |
| **Lo que ya se animaba** | Sacar (con rebote), recarga con el cargador y la mano, cartucho a cartucho, cerrojo, inspección (2,6 s), cuchillo y culatazo, sprint, pared, aire y caída, respiración, inercia del ratón y retroceso con muelles. |
| **Lo que no se animaba** | Guardar el arma (desaparecía). Gesto de reposo. Respuesta al saltar. |
| **Muelles** | El de la cámara ya era exacto (Fase 2). La inercia del ratón, el retroceso del arma y el colgante usaban un paso aproximado (Euler, con dt limitado), así que cambiaban un poco según los fps. |
| **Eventos** (`ClientState.WeaponEvent`) | Solo `Equip`, `Fire`, `ReloadStart`, `ReloadCancel`, `Inspect` e `InspectCancel`. Los sonidos de la recarga iban con tiempos fijos dentro del código. |
| **Poses** | CFrames escritos a mano dentro de `renderStep`: sprint, sacar, inspección e inclinación de la recarga. |
| **Audio** | 9 huecos por arma en `Sounds.WeaponAudio`, todos vacíos (se usaba el sonido genérico). Variación de tono de ±5 % en todo. |
| **VFX** | El fogonazo, la luz, el humo, la trazadora y los impactos ya existían y respetaban los presupuestos de calidad. Faltaba: luz del fogonazo también en calidad Baja, y casquillos que no heredaban la velocidad del jugador (corriendo se quedaban atrás). |
| **Skins** | Por papeles (`Role`: Body, Panel, Accent...), no por colores por pieza. **Pero** el ARX-27 clásico casi no tiene piezas `Accent`: una skin solo cambiaba el cuerpo y la culata. |

## B. Arquitectura encontrada (y que se mantiene)

| Módulo | Papel |
|---|---|
| `shared/Weapons.luau` | **Juego**: daño, cadencia, dispersión, cargador, tiempos de recarga, puntos del arma. |
| `shared/WeaponFeel.luau` | **Sensación**: los 3 retrocesos, ADS, sprint, balanceo, fogonazo, casquillos y presupuesto por calidad. |
| `shared/WeaponDesigns*.luau` + `WeaponModels.luau` | Modelo de piezas y pintura por papeles (skins). |
| `client/Modules/WeaponController.luau` | Viewmodel, disparo, recarga, ADS, cuchillo, inspección y animación por fotograma. |
| `client/Modules/Effects.luau`, `shared/Sounds.luau` | Efectos visuales y sonido. |
| `ClientState.WeaponEvent` | Momentos del arma para animación y audio. **Se reutiliza; no hay un sistema paralelo.** |

## C. Cambios

1. **`shared/WeaponVisual.luau` (nuevo): la presentación separada del juego.** Contiene:
   - familias (Rifle = ARX-27, SMG, Pistol, Shotgun, Marksman, Sniper, LMG, Launcher, Melee);
   - poses;
   - marcas de la recarga;
   - reposo, salto y colgante;
   - prioridad de acciones;
   - piezas móviles;
   - cinemática inversa de los brazos;
   - contrato de modelo externo.
2. **Brazos con codo** (cinemática inversa de dos huesos): los hombros quedan fijos respecto a la
   cámara y las manos siguen al arma.
3. **Palanca de carga** animada en la recarga vacía. La mano izquierda va a ella, tira y vuelve.
4. **Recarga por marcas:** `MagOut`, `MagIn`, `Bolt` y `Ready`, o `ShellIn` en la escopeta. Cada
   marca dispara a la vez su evento, su sonido y un meneo del colgante. **Mismos instantes que
   antes** (0,12 / 0,55 / 0,85, comprobado en pruebas).
5. **Guardar el arma:** el arma vieja baja de lado en ~0,14 s mientras sube la nueva. **El cambio
   no espera** (la nueva ya se puede usar en el tiempo de siempre).
6. **Gesto de reposo:** tras 9 s quieto, la mano izquierda suelta y vuelve a agarrar y el arma se
   ladea un poco.
   - Como mucho uno cada 16 s.
   - Cualquier acción lo corta.
7. **Inspección por claves:** costado con la skin y el colgante, después de cerca, el otro costado y
   un remate. En el momento de cerca se lanza el evento `InspectMoment` y se menea el colgante.
8. **Salto:** al despegar, el arma se queda un instante atrás (muelle). La caída ya dependía de la
   altura.
9. **Cuchillo:** evento `MeleeHit` en el momento del golpe y tirón del colgante. (No se añadió golpe de
   cámara: en este juego la cámara es la mira y movería el siguiente disparo.)
10. **Colgante:** muelle exacto.
    - Lo empujan el giro de la cámara, el paso al correr, el disparo, la recarga, la caída, la
      inspección y el gesto de reposo.
    - Sigue sin atravesar el arma (topes).
11. **Muelles exactos e independientes de los fps** (`WeaponFeel.StepSpring`): inercia del ratón,
    retroceso del arma, salto y colgante.
    - Los suavizados visuales (pared, aire, alabeos de cámara, balanceo de cabeza, empujón de FOV y
      golpe de caída) usan `damp`/`decay`: a 60 fps dan exactamente lo de antes.
    - **No se tocan `aimAlpha` ni `sprintAlpha`**, que deciden cuándo se puede disparar.
12. **Eventos nuevos y cancelaciones:**
    - `InspectCancel` sale siempre que se corta la inspección (al disparar, apuntar, recargar,
      correr o con el cuchillo).
    - `ReloadCancel` también sale si el cuchillo corta una recarga.
13. **Audio:** huecos `Unequip`, `Inspect` y `Melee` y variación de tono de las armas de ±2 %.
14. **VFX:**
    - en calidad Baja, sin luz de fogonazo (el fogonazo se sigue viendo);
    - los casquillos heredan la velocidad del jugador y salen un poco hacia delante.
15. **Skins:** papel nuevo `Trim` (ribete). En el ARX-27, las 8 ranuras del guardamanos.
    - De fábrica, metal oscuro (igual que antes).
    - Con cualquier skin, su color de acento.
16. **QA:** interruptor «ARX-27 Gold» (el ARX-27 con la skin de muestra, solo en tu pantalla) y la
    acción actual del arma en el HUD de rendimiento.
17. **Modelos externos:** `WeaponVisual.Weapons.ARX27.Model = "Nombre"` usa una plantilla de
    `ReplicatedStorage.WeaponViewModels`. Si no cumple los requisitos, se usan las piezas de siempre
    y se avisa en la Output.

## D. Viewmodel

Estructura real (adaptada al modelo de piezas; no se ha inventado nada):

```
Viewmodel (Model, en la cámara)
├── Handle (PrimaryPart) + Attachments: Muzzle · AimPoint · Eject
├── Arma: Receiver*, Handguard*, HgSlot (Trim), Rail*, Barrel, mira de punto (con Reticle),
│         Grip, Trigger, Stock*, ButtPad…
├── Cargador: Mag* (13 piezas; grupo «Mag»)                 → sale y entra en la recarga
├── Palanca de carga: ChargingHandle (grupo «Charge»)       → recarga vacía
├── Colgante: CharmRing + Charm* (si hay)                   → muelle sobre su anilla
└── Brazos (por lado, atributo Side):
    UpperArm (manga) · Forearm (piel o manga larga) · Glove · Cuff   → IK cada fotograma
```

Lo que pedía el esquema ideal y cómo queda:

| Pieza ideal | En el ARX-27 |
|---|---|
| Arms (Right/Left) | Sí, procedurales con codo. |
| Body | Sí. |
| Magazine | Sí. |
| Bolt | No hay cerrojo visible: se anima la palanca de carga (`ChargingHandle`). |
| Muzzle, Sight | Sí. |
| Charm | Sí, si se lleva colgante. |
| AimPoint, MuzzlePoint, EjectionPoint | Attachments `AimPoint`, `Muzzle` y `Eject`. |
| LeftHandPoint | Número en Weapons. Con un modelo externo, Attachment `LeftHand`. |
| CharmPoint | Calculado. Con un modelo externo, Attachment `CharmPoint`. |
| AnimationController | **No se usa:** no hay AnimationIds ni brazos riggeados, y el viewmodel se coloca por CFrame. |

**Poses (sin CFrames repartidos por los scripts):**
- **HipFire:** `ViewOffset` (Weapons, o `WeaponVisual.Weapons[arma].ViewOffset`).
- **ADS:** `AimPoint` + `AimDistance`.
- **Sprint, Equip, Unequip, Inspect y Reload.Tilt:** en `WeaponVisual` por familia.

**ADS:** el `AimPoint` queda en el centro exacto de la pantalla. La prueba `arx27` mide
(−0,002, 0,003) studs de desvío en reposo. El retroceso del arma se aplica el último y vuelve solo
con su muelle.

**Capas (de fuera a dentro; ninguna pelea con otra):**
1. Cámara.
2. Cuerpo: balanceo, respiración, inercia del ratón, salto y caída, inclinación al ir de lado.
3. Pose base (cadera ↔ ADS).
4. Locomoción: sprint y pared.
5. Acción: recarga, sacar, cuchillo, inspección y gesto de reposo.
6. Retroceso del arma, siempre el último.

**Prioridad de acciones** (`WeaponVisual.ActionPriority`): Melee > Reload > Equip > Inspect > Sprint >
IdleVariant > Idle.
- El disparo interrumpe lo que el juego ya dejaba interrumpir (inspección, reposo y sprint, con su
  disparo pendiente).
- `ClientState.WeaponAction` dice la acción actual (y «ADS» si apuntas en reposo).

## E. Animaciones

**Todas son procedurales** (CFrame, muelles y curvas). Ninguna usa AnimationIds.

| Animación | Cómo | Estado |
|---|---|---|
| Idle | Respiración (`Idle.Breath`); apuntando, casi nada | Ya estaba; configurable |
| IdleVariant | Curva: se ladea 7° y la mano izquierda suelta y vuelve a agarrar | **Nueva** |
| Fire / FireADS | 3 muelles (atrás, giro y lado), más suaves apuntando (`View.AimScale`) | Muelles ahora exactos; el evento dice si es ADS |
| ReloadTactical | Inclinación; cargador fuera, mano y cargador nuevo; golpe al encajar | Ahora por marcas |
| ReloadEmpty | Lo anterior + **palanca de carga** (la mano va, tira y vuelve) + tirón | **Palanca nueva** |
| Equip | Sube desde abajo girando, con rebote (`Equip` por familia) | Pose configurable |
| Unequip | El arma vieja baja de lado ~0,14 s (`Unequip` por familia) | **Nueva** |
| SprintEnter / Loop / Exit | Pose por familia + el «ocho» del balanceo al correr | Eventos nuevos; pose propia por familia |
| Inspect | 6 claves (2,6 s en el fusil, 2,1 en la pistola) | **Rehecha** con más fases |
| Melee | Golpe rápido, alternando lado (cuchillo) o culatazo | + `MeleeHit` (sin golpe de cámara: movería la mira) |
| JumpResponse | Muelle al despegar | **Nueva** |
| LandResponse | Hundimiento según la altura de la caída (`LandKick`) | Ya estaba; ahora igual a cualquier fps |

## F. Eventos (`ClientState.WeaponEvent`: nombre, arma, info)

| Evento | Cuándo |
|---|---|
| `Equip`, `Unequip { Animated }` | Al sacar y al guardar (Animated = false al morir o al cambiar de personaje). |
| `Fire { ADS }` | Cada disparo. |
| `ReloadStart { Empty, Duration }` | Al empezar la recarga. |
| `MagOut`, `MagIn`, `Bolt`, `Ready` | Las marcas de la recarga. |
| `ShellIn { Index }` | Cada cartucho de la escopeta. |
| `ReloadCancel` | Cambiar de arma, cuchillo o morir a mitad de recarga. |
| `Inspect`, `InspectMoment`, `InspectCancel` | Inspección. |
| `Melee { Knife }`, `MeleeHit` | Cuerpo a cuerpo. |
| `SprintEnter`, `SprintExit` | Entrar y salir del sprint. |
| `IdleVariant` | Gesto de reposo. |

Los eventos de las marcas se programan con la duración real de la recarga y se anulan solos si la
recarga se corta.

## G. Huecos de audio (`Sounds.WeaponAudio.ARX27`)

12 huecos: `ShotClose`, `ShotMechanical`, `ShotTail`, `Reload`, `MagOut`, `MagIn`, `Bolt`,
`Empty` (gatillo en vacío), `Equip`, `Unequip`, `Inspect` y `Melee`. **Todos vacíos** (no se han
inventado SoundIds).

| Hueco | Si está vacío suena |
|---|---|
| `ShotClose` | «Shot» genérico con el tono del ARX-27 |
| `ShotMechanical` | «Mech» |
| `ShotTail` | Eco grave filtrado |
| `MagOut`, `MagIn`, `Bolt`, `Empty`, `Equip` | Genéricos de siempre |
| `Unequip`, `Inspect` | Nada (como antes) |
| `Melee` | «Swing» |

- **Disparo por capas:** cuerpo + mecanismo + cola. Como mucho 3 sonidos por disparo más el
  estampido genérico, y la cola como mucho cada 0,2 s.
- **Variación de tono:** ±2 % en las armas (`Sounds.GunPitchVariation`); el resto, ±5 %.
- **Para poner un sonido propio:** `"rbxassetid://<id>"` en el hueco. Con sonido propio no se cambia
  el tono, salvo la variación.

## H. VFX del ARX-27

| Efecto | Estado |
|---|---|
| Fogonazo | Perfil Rifle: tamaño 1 y 0,04 s; estrella de puntas al azar en los mapas realistas. No tapa la mira (es muy corto). Sin cambios. |
| Luz | Una sola PointLight reutilizada que se apaga a ~0,045 s. **En calidad Baja, ninguna** (nuevo). |
| Humo | Del fogonazo y del cañón caliente tras una ráfaga larga. En Baja, no. Sin cambios. |
| Casquillos | Salen de `Eject` (ventana de expulsión, fuera del cuerpo) a la derecha y hacia arriba, ahora también un poco hacia delante. **Heredan la velocidad del jugador** (nuevo). 1,5 s de vida, como mucho 8 a la vez, solo locales (no se replican). En Baja o en móvil, no hay. |
| Trazadora e impactos | Sin cambios (ya iban por material y por presupuesto). |

## I. Skins

- Siguen funcionando **por papeles** (`Role`), nunca por colores de piezas concretas. Un modelo nuevo
  solo tiene que marcar sus piezas con `Role` para que todas las colecciones (INFERNO, CYBER, ARCTIC,
  STREET, VOID, RED OPS…) le valgan sin tocar código.
- **Papel nuevo `Trim` (ribete):** de fábrica es metal oscuro; con skin, el color y material de
  acento. Con él, el ARX-27 clásico enseña de verdad la skin. En el ARX-27 son las 8 ranuras del
  guardamanos.
- **Skin de muestra del gold standard:** **Operación Roja (RED OPS)**, en
  `WeaponVisual.GoldSkin`: cuerpo negro metálico, culata roja y ribetes de neón rojo.
  - En Studio se ve con el modo QA → «ARX-27 Gold».
  - **Solo en tu pantalla:** no da la skin, no cambia la tienda ni nada guardado.
  - INFERNO lleva llamas alrededor del arma, que en primera persona estorban, así que se eligió
    RED OPS.

## J. Móvil

- Todas las animaciones (brazos con codo incluidos) funcionan igual en el móvil y en calidad Baja.
- Coste de los brazos: 2 cálculos de cinemática inversa y ~8 CFrames por fotograma.
- **En Baja se recorta** lo de siempre (sin casquillos ni marcas, menos partículas) y, ahora, la luz
  del fogonazo.
- **No se recorta nunca:** hitmarker, kill confirm, killfeed ni trazadoras.

## K. Pruebas

| Prueba | Qué comprueba |
|---|---|
| `weaponvisual` (nueva) | Las 9 familias y las 22 armas con su presentación completa. Marcas de la recarga en orden y en los tiempos de siempre. Prioridad de acciones. IK (200 casos al azar: medidas y alcance; polo; sin alcance; sin NaN). Piezas móviles. ARX-27: cargador, palanca, sin cerrojo inventado, puntos y ribetes. Skin de muestra. Modelo externo (vale con requisitos; si no, piezas de siempre y aviso). Los 12 huecos de audio. ±2 %. Luz del fogonazo por calidad. **Balance del ARX-27 sin cambios.** |
| `arx27` (nueva, cliente) | Manos en el arma (error 0,000). Codos doblados. ADS centrado. Hombro quieto. Recarga táctica (`MagOut → MagIn → Ready`) y vacía (`… → Bolt → Ready`) con la palanca, que va 0,22 studs atrás y vuelve. Inspección y sus cortes (disparar, apuntar). Gesto de reposo y su corte. Cambio de arma (se ven las dos un instante y luego solo la nueva). Al morir no queda nada. |
| `weaponfeel` (ampliada) | 12 huecos de audio (los 9 de la Fase 2 + 3). |
| `gunfeel`, `weaponanims`, `shooting`, `weaponsounds`, `touchbtns`, `clientboot`, `hudclient`, `qa`, `killcam`, `finalkillcam` | Siguen pasando: todas las armas recargan, se mueven y vuelven a su sitio. |

## L. Qué necesita prueba real (Studio o el juego)

1. **Sensación general del ARX-27**, en orden: equipar → correr → ADS → disparar → retroceso →
   impactar → recargar (táctica y vacía) → inspeccionar. En QA, «ARX-27 Gold».
2. **Brazos:**
   - que los antebrazos entren desde abajo de forma natural;
   - que los codos no se vean raros en el sprint, la inspección y la recarga;
   - en teléfono (`PHONE_HIP`) y con FOV alto (Ajustes).
3. **ADS:** el punto rojo centrado, sin saltos al entrar y salir, y con recoil que no descoloque la
   mira.
4. **Recarga vacía:** que la mano llegue a la palanca y el tirón se lea.
5. **Gesto de reposo:** que no moleste (9 s quieto) ni salga a destiempo.
6. **Guardar el arma:** que las dos armas un instante a la vez no se vean raras.
7. **Colgante:** que se mueva poco, sin atravesar el arma.
8. **RED OPS en el ARX-27:** que los ribetes se lean sin quemar (neón).
9. **A 30 y a 144+ fps** (limitador de Roblox): que los muelles se sientan iguales.
10. **Audio:** los genéricos con ±2 % (que no suenen idénticos ni a dibujo animado).
11. **Móvil:** calidad Baja sin luz de fogonazo; el resto de animaciones, igual.

## M. Qué faltaría si compramos modelos externos

**El código ya está preparado.** Pasos para cambiar el ARX-27 por un modelo comprado
(ITHappy, PStudio, etc.):

1. Importar el modelo en `ReplicatedStorage/WeaponViewModels/<Nombre>` (un `Model`).
2. `PrimaryPart` = una pieza llamada `Handle`, con todas las demás soldadas a ella.
3. Attachments en el `Handle`:
   - **obligatorios:** `Muzzle` (boca del cañón, mirando hacia delante), `AimPoint` (centro de la
     mira) y `Eject` (ventana de expulsión);
   - **opcionales:** `LeftHand`, `RightHand` y `CharmPoint`.
4. Atributo `Role` en las piezas (Body, Panel, Accent, Accent2, Dark, Metal, Rubber, Lens, Reticle,
   Trim) para que funcionen las skins.
5. Atributo `Piece` en las que se mueven: `Mag`, `Charge`, `Bolt`, `Slide` o `Pump`.
6. `WeaponVisual.Weapons.ARX27 = { Model = "<Nombre>" }` y, si hace falta, `ViewOffset` y
   `AimDistance`.
7. Ya está: el viewmodel, el ADS, la recarga, las skins y el colgante lo usan sin tocar
   `WeaponController`, `Combat` ni `WeaponFeel`. El servidor (el arma que ven los demás) usa el mismo
   modelo.

**Si falta algo:** no se rompe nada. Se usan las piezas de siempre y la Output dice qué falta.

**No cubre (habría que hacerlo):**
- brazos riggeados con manos y dedos de un pack: los brazos siguen siendo los procedurales;
- AnimationIds propias: no hay `AnimationController`. Habría que añadir un reproductor de
  animaciones a la capa «Acción», donde ya están los eventos.

## Gold standard check (en el código; **falta verlo jugando**)

- [x] buena pose de cadera (la de siempre, configurable)
- [x] ADS alineado (prueba: 0,002 studs)
- [x] idle (respiración) y gesto de reposo
- [x] respuesta al disparo (muelles exactos)
- [x] recarga táctica
- [x] recarga vacía con palanca de carga
- [x] equip y unequip
- [x] sprint (entrar, mantener y salir, con eventos)
- [x] inspect (4 fases + remate)
- [x] melee (MeleeHit; la cámara no se mueve para no tocar la mira)
- [x] respuesta al saltar y aterrizar
- [x] respuesta del colgante
- [x] fogonazo (y sin luz en Baja)
- [x] casquillos (heredan la velocidad)
- [x] huecos de audio (12)
- [x] skins (papel Trim y skin de muestra)
- [x] cancelaciones correctas (InspectCancel y ReloadCancel siempre)
- [x] limpieza al morir (prueba `arx27`)
- [x] limpieza al cambiar de arma (prueba `arx27`)
- [x] limpieza al acabar la ronda (las armas se quitan → Unequip; al morir o reaparecer, al momento)
- [ ] **verlo y sentirlo en Studio** (sección L)

## Familias (infraestructura aplicada; sin pulido individual)

| Familia | Qué cambia respecto al fusil |
|---|---|
| SMG | Sprint y equip más cortos, guarda en 0,12 s, inspección de 2,3 s |
| Pistol | Corre con el arma recogida arriba, saca y guarda muy rápido, inspección propia de 2,1 s, gesto de reposo más marcado |
| Shotgun | Más peso (equip y salto); recarga cartucho a cartucho con ShellIn y bombeo |
| Sniper | Más lento (equip, guardar, salto); el cerrojo se anima al disparar (ya estaba) |
| LMG | Sprint bajo y pegado al cuerpo, guarda en 0,18 s, salto más pesado, inclinación de recarga mayor |
| Marksman, Launcher, Melee | Ajustes pequeños de sprint y guardar |

**Los tiempos de juego no cambian.** El tiempo de sacar el arma lo siguen marcando WeaponFeel y
`EQUIP_READY`.

## Decisión sobre comprar assets (según lo encontrado en el código)

- **Pack de armas: NO por ahora.**
  - El ARX-27 de piezas ya tiene cargador separado, palanca de carga, mira con punto y puntos
    correctos, y ahora las skins se notan.
  - Lo que le falta físicamente es detalle (mallas, texturas, cerrojo visible), no funcionalidad.
  - La arquitectura deja cambiarlo más tarde en 8 pasos sin tocar el código.
  - Comprar tendría sentido solo si, **jugando**, el aspecto low-poly no da la calidad buscada.
- **Pack de animaciones: NO.**
  - No hay brazos riggeados ni `AnimationController` que las reproduzcan.
  - Un pack de animaciones sin un rig de brazos compatible no se puede usar.
  - Lo procedural cubre todas las acciones de la lista.
  - Si un día se compran **brazos riggeados**, entonces sí tendría sentido, junto con ellos (ver M).
- **Audio: SÍ.**
  - Los 12 huecos del ARX-27 están vacíos y todo suena con los sonidos genéricos de Roblox con capas.
  - Es la mayor diferencia entre «funciona» y «hero weapon».
  - Lista exacta en `TURNO_NOCTURNO.md` / informe de la fase.
