# Misión 3D · informe de la sesión (9 de octubre de 2026)

Rama: `claude/intelligent-fermi-cz7und`. Punto de recuperación anterior a la misión: etiqueta
`recovery/pre-mision-3d` (commit `06e2619`).

**Duración real:** la sesión de modelado e integración duró bastante menos de las 4 horas pedidas
(del orden de hora y media de trabajo efectivo, con seis modeladores en paralelo durante unos ocho
minutos). No se ha rellenado tiempo con cambios innecesarios: lo que queda está en las secciones H e I.

## A. Modelos 3D

Siete armas modeladas en Blender 5.2 por script (sin interfaz), todas con la misma identidad
(«stylized tactical arcade»: cuerpo negro azulado, paneles de color, testigos de luz).

| Arma | Familia | Triángulos (Blender) | Piezas en el juego | Piezas móviles |
|---|---|---|---|---|
| ARX-27 Pulse | Fusil de asalto | 2052 | 14 | Cargador, cerrojo, palanca de carga |
| Specter-9 | Subfusil | 2188 | 14 | Cargador, cerrojo, palanca |
| Havoc Pump | Escopeta | 2460 | 13 | Bomba, cerrojo |
| Signal-7 | Francotirador | 2508 | 12 | Cerrojo (maneta y pomo), cargador |
| Titan | Ametralladora | 2712 | 14 | Caja de munición con cinta, palanca |
| Viper P9 | Pistola | 1320 | 13 | Corredera, cargador |
| Vortex AR-9 | Energía (ráfagas) | 2176 | 12 | Célula de energía, palanca |

Por arma, en `assets/weapons/<Arma>/`: `<Arma>.blend` (editable), `.fbx`, `.glb`, `.mesh.json`
(geometría y primitivas) y `renders/`. Script de cada una en `tools/blender/weapons/<arma>.py`.

**Validación:** los archivos existen y se generan sin errores; los seis puntos de anclaje de cada arma
(boca, mira, expulsión, manos y colgante) coinciden con los de `Weapons.luau`. Los `.fbx` y `.glb`
se exportan pero **no se han vuelto a importar** en Blender ni en Studio para comprobarlos.

No se hizo el octavo modelo (se cubrieron las ocho familias pedidas con siete armas: la Vortex es a la
vez el rifle de ráfagas y el arma de energía).

## B. Renders

`assets/weapons/<Arma>/renders/`: ocho vistas a 1080p por arma (`hero`, `side`, `left`,
`threequarter`, `back34`, `front`, `top`, `firstperson`), en JPEG.

Galería: `assets/weapons/_gallery/`
- `00_coleccion.jpg`: las siete armas (héroe, lateral y primera persona).
- `<Arma>.jpg`: el render de presentación de cada una.
- `en_roblox_*.jpg`: capturas reales dentro de Roblox Studio (fila de armas, Armamento, ARX-27
  disparando y recargando).

## C. Animaciones

No se han creado animaciones nuevas ni AnimationIds. Las armas nuevas usan el sistema de animación por
código que ya tenía el juego (`WeaponController`): cada modelo marca sus piezas móviles con el atributo
`Piece` y el sistema las mueve.

- **Probado en partida (ARX-27):** apuntar con la mira (el punto rojo queda centrado), disparo,
  retroceso, recarga con el cargador y vuelta a 30 balas.
- **Probado en partida (Viper):** equipar y verla en primera persona. No se disparó.
- **Sin probar en partida:** la bomba de la escopeta, el cerrojo del francotirador, la corredera de la
  pistola al disparar y las recargas de las otras cinco. Usan el mismo mecanismo, pero no se han visto.

## D. Integración con Roblox

Roblox no permite subir una malla como recurso desde script en esta versión de Studio
(`AssetService:CreateAssetAsync` responde «not available yet»), y las mallas dinámicas (EditableMesh)
tienen un límite de 8 vivas en el cliente. La vía que quedó es otra:

- El kit de Blender emite, además de la malla, la descomposición del arma en bloques, cuñas y cilindros
  (`src/shared/WeaponMeshes/<Arma>.luau`).
- `Shared/WeaponMeshKit` las funde en el **servidor** al arrancar (GeometryService, ~0,15–0,3 s por arma)
  en una pieza por grupo y deja la plantilla en `ReplicatedStorage.WeaponViewModels`. Se replican a todos.
- `WeaponModels` ya sabía usar plantillas externas: primera persona, arma del personaje, lobby, tienda
  y registro de bajas usan el modelo nuevo. Si la fusión falla, se usan las piezas de siempre.

**Consecuencia:** en el juego las armas tienen la misma silueta y colores que en Blender, pero **sin los
chaflanes** de los renders (las aristas son vivas).

**Comprobado en Studio:** las siete se construyen sin piezas sueltas; se ven en Armamento (ARX-27,
Specter-9, Havoc Pump, Signal-7, Viper) y en primera persona (ARX-27, Viper); escala, orientación y
puntos de agarre correctos. No se ha probado en un móvil ni en un servidor publicado.

## E. Mejoras de gameplay y arreglos (toda la jornada)

Encontrados probando en Studio y arreglados:
- Uniones nuevas de Roblox (`AnimationConstraint`): pose del lobby, muñeco de trapo, escena final
  (`Flow/Preview`, `Ragdoll`, `ResultsCast`).
- Pantalla del mapa colgada si el despliegue terminaba durante su tiempo mínimo (`Flow/Screens/MapIntro`).
- Espectador en la primera ronda de Eliminación y Buscar y destruir (`Round`). Confirmado en partida.
- Lobby sin personaje, accesorios del avatar que tapaban el traje (`Flow/Screens/Home`, `Outfits`).
- 60 iconos propios en lobby, pase, tienda, HUD y armamento (`Shared/Icons`, `IconText`).
- Emojis que Roblox no dibuja; estadísticas de Armamento que salían como cuadrados.

## F. Optimización

Sin mediciones de FPS ni de memoria: no se ha perfilado nada.

Datos que sí hay:
- Triángulos por arma en Blender: de 1320 a 2712.
- Triángulos de las piezas fundidas en Roblox: ARX-27 2236, Specter-9 2066, Viper 1618, Vortex 2836,
  Titan 3848, Havoc Pump 4142, Signal-7 4162 (los cilindros se teselan más al fundir).
- Piezas por arma: de 12 a 14 (antes, el ARX-27 de piezas tenía 93).

**Pruebas automáticas (Lune, fuera de Studio):** batería completa con las siete armas registradas:
151 OK y 1 fallo (`scopesway`, que ya fallaba antes de la sesión). `tests/check.sh` sin errores.

## G. Control de versiones

Commits de la jornada en `claude/intelligent-fermi-cz7und`:
- `06e2619` Prueba en Studio: arreglos del motor real, iconos propios y acabado de armas
- `01b5243` Armas modeladas en Blender: kit, tubería a Roblox y ARX-27 Pulse
- `c92e4eb` Colección de armas modeladas en Blender: seis armas nuevas en el juego
- `16a66b6` ARX-27: visor más abierto al apuntar; informe de la misión 3D

El flujo de GitHub Actions solo construye y valida en cada push; publicar es manual.

## H. Problemas pendientes

- **Chaflanes:** para que el juego muestre la malla de Blender tal cual hay que importar los `.fbx` con
  el importador 3D de Studio (paso manual) y registrar esos modelos como plantilla.
- **Animaciones sin ver** de cinco armas (sección C).
- **Bots parados en Desert Base:** vistos dos veces en ese mapa (Captura la bandera y Dominio), quietos
  en su base; en los demás mapas se mueven. Apunta a la navegación de ese mapa. Sin investigar.
- **Prueba `scopesway`:** falla, y ya fallaba en el commit original (comprobado en una copia limpia).
- **Avatar con extremidades finas:** con el uniforme solo se ven chaleco, casco y botas.
- **«HAS MUERTO»** se monta con el aviso del objetivo.
- **Móvil:** nada de esta sesión se ha probado en un teléfono.

## I. Próximas prioridades

1. Probar en partida las cinco armas que faltan (elegir cada clase) y ajustar bomba, cerrojo y corredera.
2. Importar un `.fbx` a mano y decidir si compensa pasar a mallas con chaflán.
3. Medir en un Android real (MicroProfiler): las siete armas y un tiroteo de 10.
4. Modelar las armas que siguen con piezas: Nova Drift, Raptor DMR, Breach Hammer, Ghostline XR,
   Tempest Core, Hand Cannon, Phantom Sidewind, las cuerpo a cuerpo.
5. Revisar al apuntar los visores de las otras seis (el del ARX-27 ya se abrió y se comprobó).
6. Bots de Desert Base.

## Cómo regenerar un arma

```bash
"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/build_weapon.py -- arx27 --final
python -X utf8 tools/blender/to_luau.py ARX27
```

Para añadir una: `tools/blender/weapons/<arma>.py` (copiar una existente), generar, y registrarla en
`WeaponMeshKit.Weapons`, `WeaponVisual.Weapons` y la paleta en `Weapons.luau` (`CLASSIC_LOOK`).

---

# Segunda tanda (misma jornada, 9 de octubre de 2026)

## Armas

Siete modelos más, con lo que **las 14 armas de fuego principales y secundarias tienen modelo nuevo**:

| Arma | Familia | Triángulos (Blender) | En Roblox | Identidad |
|---|---|---|---|---|
| Nova Drift | Subfusil bullpup | 1660 | 1888 | Verde azulado, luz lima |
| Raptor DMR | Tirador | 2016 | 3066 | Dorado desierto, visor prismático hueco |
| Breach Hammer | Escopeta semiautomática | 2128 | 2706 | Amarillo de obra, tambor, luz roja |
| Ghostline XR | Francotirador con supresor | 1912 | 3626 | Blanco fantasma, luz azul fría |
| Tempest Core | Lanzacohetes | 2564 | 4418 | Naranja, cabeza roja, franjas amarillas |
| Hand Cannon | Revólver | 1304 | 1864 | Acero, rojo oscuro, luz ámbar |
| Phantom Sidewind | Pistola de ráfagas | 1280 | 1634 | Magenta y cian |

Siguen con el modelo de piezas antiguo: Splat-X, Ballesta, Calabazooka y las cuerpo a cuerpo.

Galería actualizada: `assets/weapons/_gallery/01_poster.jpg` (las 14) y `00_coleccion.jpg`.

## Probado en partida (modo QA, Studio)

Las 14 armas se equiparon una a una dentro de una partida y se capturó reposo, disparo, apuntado y
recarga (`tools/studio/weapontest.js`). Las 14 se ven, disparan y recargan. Lo que salió y se arregló:

- **Havoc Pump:** la carrillera de la culata tapaba media pantalla al apuntar. Culata rebajada.
- **Raptor DMR:** el visor era macizo y tapaba la vista al apuntar. Rehecho como túnel hueco con lente
  y retículo; comprobado.
- **ARX-27:** ventana del visor más abierta (de la primera tanda).

Sin verificar: que la bomba, el cerrojo y la corredera se muevan con buen aspecto (las capturas son
fotos fijas, no se ha visto la animación), y el aspecto de cada arma en el personaje de los demás.

## Bots parados en Desert Base: arreglado

Dos causas, las dos medidas en Studio:

1. **El terreno quedaba 2 studs alto en todos los mapas.** `Terrain:FillBlock` deja la superficie 2
   studs por encima del tope del bloque. `TacKit.terrain` no lo compensaba, así que la arena o la
   hierba tapaban las losas y dejaban las puertas bajas. Corregido en `TacKit/init.luau`
   (`T.TERRAIN_RISE`).
2. **Las puertas y el pasillo de la base cerrada miden 4-5 studs**, y el cálculo de rutas de los bots
   pedía holgura de radio 2: «sin ruta», y los bots empujaban contra la pared. Ahora `Bots.computePath`
   reintenta con el radio justo de un personaje.

Resultado en una partida forzada en Desert Base: 8 de 9 bots en movimiento, ninguno dentro de la base,
marcador 8–2 a los dos minutos.

## Organización

- `CONTINUAR.md`: documento de entrada (estado, dónde está cada cosa, cómo se trabaja, pendientes).
- `tools/studio/`: herramientas para manejar Studio desde la terminal, con su `README.md`.
- `tools/blender/BRIEF.md`: encargo completo para modelar un arma; `register.py` la registra.

---

# Tercera tanda (misma jornada)

## Armas

Las siete que quedaban, con lo que **las 21 armas del juego tienen modelo de Blender**:

| Arma | Tipo | Triángulos (Blender) | En Roblox | Identidad |
|---|---|---|---|---|
| Splat-X | Marcadora de pintura | 2000 | 4850 | Rosa, cian, amarillo; tolva con bolas |
| Ballesta | Ballesta | 1740 | 3424 | Verde bosque, luz ámbar |
| Calabazooka | Lanzador de Halloween | 2644 | 5354 | Calabaza, enredadera, sombrero de bruja |
| Colmillo | Cuchillo | 432 | 718 | Naranja y cian |
| Katana | Cuerpo a cuerpo | 488 | 572 | Carmesí, filo cian |
| Martillo de juguete | Cuerpo a cuerpo | 788 | 2082 | Rojo, amarillo y azul |
| Guadaña | Cuerpo a cuerpo | 616 | 1726 | Calabaza y filo verde tóxico |

Las cuerpo a cuerpo mantienen la orientación, el punto de agarre y el largo de las originales para que
valgan las animaciones de golpe que ya había.

Galería: `assets/weapons/_gallery/01_poster.jpg` (las 21) y `00_coleccion.jpg`.

## Mapas tras bajar el terreno

Se forzaron los nueve mapas uno a uno con el modo QA (Duelo por equipos) y en todos se midió el
terreno y el movimiento de los bots: superficie entre -0,3 y 0 (antes 1,7–2), ningún bot dentro de su
base y marcador avanzando. No se recorrió cada mapa entero: la comprobación es una captura desde la
base y las medidas, no una revisión visual de los bordes.

## Probado en partida (tercera tanda)

- **Splat-X, Ballesta y Calabazooka:** equipadas con el modo QA; se ven, disparan y apuntan. Dos
  arreglos tras verlas: el visor de la Ballesta era un tubo macizo (ahora es un réflex abierto) y las
  aletas de murciélago de la Calabazooka tapaban la vista al apuntar (ahora van hacia abajo).
- **Colmillo:** al equiparlo con el modelo nuevo no se veía nada y la consola daba un error en cada
  fotograma (`WeaponController`: las cuerpo a cuerpo traen el punto de mira que exige la plantilla, pero
  no tienen distancia de apuntado). Corregido; el cuchillo se ve y golpea.
- **Katana, Martillo y Guadaña:** se construyen en Studio pero **no se han equipado en partida** (el
  modo QA no da armas cuerpo a cuerpo y hay que equiparlas desde el menú). Usan el mismo camino que el
  cuchillo.

## Efectos de las armas (`src/client/Modules/WeaponFX.luau`)

Módulo nuevo, solo cosmético y solo en primera persona. Escucha los avisos del arma
(`ClientState.WeaponEvent`), no toca `WeaponController`.

- **Llamarada de boca por arma:** color, tamaño, número de lenguas y chispas propios (tabla
  `WeaponFX.Weapons`). Fuego en las de pólvora; energía violeta en la Vortex; gotas de pintura de dos
  colores en la Splat-X; rebufo por detrás en los lanzacohetes.
- **Luces de neón vivas:** laten en reposo, destellan en blanco con cada disparo, se van poniendo al
  color «caliente» con el fuego sostenido y, al recargar, se apagan y vuelven a encenderse con un destello.
- **Llamas permanentes:** vela y resplandor que parpadea en la Calabazooka, chispas eléctricas en la
  boca de la Vortex, brasa en el Tempest Core, volutas verdes en la Guadaña, chispas en el filo de la Katana.
- **Golpe cuerpo a cuerpo:** estela de chispas del color del arma.
- Se recorta con la calidad (Baja 45 %, Media 80 %) y un 30 % más en pantallas táctiles.
  `WeaponFX.Enabled = false` lo apaga; `WeaponFX.Scale` cambia el tamaño general.

**Probado en partida** (ARX-27, Titan, Vortex, Nova Drift, Calabazooka): se ven la llamarada, las
chispas, el destello de las luces y el apagado en la recarga; sin errores en la consola. No se han visto
en movimiento (son capturas) ni se ha medido su coste en un móvil. Las otras 16 armas usan el mismo
código con su fila de la tabla y no se han mirado una a una.

## Cuarta tanda: pulido tras probar

- **Personaje sin brazos ni piernas con el uniforme:** la causa era la ropa en capas del avatar (un
  disfraz de cuerpo entero): Roblox deja de dibujar el cuerpo que queda debajo, y esconder el accesorio
  no lo devuelve. Ahora los trajes quitan la ropa en capas (`Outfits`), y quien lleva traje o uniforme
  juega con el cuerpo de bloques estándar (`GameConfig.StandardBody`, en `Loadout`): mismas proporciones
  para todos. Comprobado en el lobby y en el servidor.
- **«HAS MUERTO»** ya no se monta con el aviso del objetivo (bajado en `HUD`).
- **Modo QA:** el comando `Weapon` acepta también armas cuerpo a cuerpo (`QAServer`).
- **Martillo de juguete y Guadaña:** equipados en partida y vistos en primera persona.
  **Katana:** equipada (sale en la lista de armas), pero me eliminaron antes de la captura; no se ha
  visto en la mano.
- Pendiente nuevo: en el texto «ELIMINADO POR…» la silueta del arma tapa parte del nombre.
