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

## G. Control de versiones

Commits de la jornada en `claude/intelligent-fermi-cz7und`:
- `06e2619` Prueba en Studio: arreglos del motor real, iconos propios y acabado de armas
- `01b5243` Armas modeladas en Blender: kit, tubería a Roblox y ARX-27 Pulse
- `c92e4eb` Colección de armas modeladas en Blender: seis armas nuevas en el juego
- (este informe, en el commit siguiente)

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
