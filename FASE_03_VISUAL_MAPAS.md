# FASE 3 — Mapas gold standard, iluminación y calidad visual

> **Sin Roblox Studio.** Los cambios se revisaron con renders aproximados: la geometría del mapa se
> exporta desde el mock y se dibuja con three.js. Ni la luz, ni los materiales, ni la atmósfera son
> los de Roblox: sirven para juzgar formas, colores y composición, **no** el aspecto final. Todo hay
> que mirarlo en Studio (sección F).

## A. Alcance

Tres mapas «gold standard»: **Construction, Coastal y Mall Rush**, más reglas de luz comunes.

- **Sin cambios en gameplay:**
  - no se ha tocado ningún spawn, sitio, ruta, objetivo ni colisión;
  - todo lo nuevo es decorado (`CanCollide = false`, `CanQuery = false`, comprobado en pruebas);
  - la fuente de Mall Rush mantiene exactamente el bloque de colisión de la anterior.
- **Sin mapas nuevos** y sin rehacer los existentes.

## B. Auditoría (estado inicial)

| Mapa | Lo que funcionaba | Lo que fallaba |
|---|---|---|
| Construction | Composición clara, grúa visible, estructuras rojas en A y B, contenedores con marcas. | La torre central, el hito principal, era hormigón gris liso. Las barandillas amarillas eran de metal (se ven oliva). La nave B por dentro era gris y vacía. La neblina del atardecer (0,30) podía tapar enemigos lejos. |
| Coastal | Tejados de teja, palmeras, paseo, puestos con toldos: buena base. | Ambiente bajo (98): callejones, iglesia y taberna en penumbra, en el mapa que debía ser el más luminoso. Paleta con muchos rosas y ocres y poco azul. El campanario, color arena, se perdía. El faro (a 330 studs) se diluía en la neblina. |
| Mall Rush | Rótulos de tiendas, banderolas y puestos de comida con color. | El interior era gris y oscuro: la cubierta, gris oscuro, hacía de techo de las zonas de doble altura. Fuente de piedra de pueblo en un centro comercial. El suelo, liso. El rótulo de la entrada decía **«SUNRISE MALL»** (no el nombre del mapa). Desde la presentación, la cubierta era una losa sin identidad. |
| Común | — | **DOF en combate:** al apuntar se desenfocaba el fondo y, en calidad Ultra, había un desenfoque lejano desde ~250 studs, dentro de la distancia de combate de mapas de 300. Bloom de noche de 0,6-0,65. |

## C. Cambios por mapa

### Construction — gris + amarillo + rojo
- **Torre central (hito 1):**
  - canto de cada forjado en amarillo de seguridad (cuatro franjas por fuera, nada coplanar con los
    suelos, así no hay parpadeo);
  - red de seguridad roja en las dos plantas sin terminar de arriba (decorado, por encima de las
    alturas de juego).
  - Se lee por plantas y como obra desde cualquier punto.
- **Grúa (hito 2)** y **estructuras de acero rojo sobre A y B (hito 3)**: ya existían. El amarillo de
  la paleta pasa de metal a **pintura** (`SmoothPlastic`): grúa, barandillas y andamios se leen
  vivos.
- **Nave B por dentro:**
  - franjas de peligro en la base de los pilares;
  - calle de carretillas pintada alrededor del atrio;
  - una «B» grande en el muro del fondo.
- **Luz:**
  - ambiente interior algo más alto (los interiores de la nave y el almacén menos oscuros);
  - neblina de 0,30 a 0,25 (variantes: 0,26);
  - bloom de noche de 0,65 a 0,5.

### Coastal — blanco + arena + terracota + azul (el más luminoso)
- **Paleta:**
  - más casas encaladas: la rotación pasa de 2 blancas de 7 a 3 de 7, y el rosa se sustituye;
  - contraventanas en azul mediterráneo (dos azules y un verde).
- **Campanario (hito 1):**
  - encalado (antes, arena), con esquinas de piedra;
  - franja de azulejo azul bajo la cornisa;
  - reloj con aro azul y agujas.
- **Fuente (hito 2):** franja de azulejo azul y anillo azul en el suelo de la plaza (opción `accent`
  de `Town.fountain`).
- **Faro (hito 3):** de 330 a 230 studs y un 30 % más alto, con galería. Ahora se ve claro desde el
  paseo y el espigón (render). La luz de noche se movió con él.
- **Luz:**
  - ambiente de 98 a 124 y ambiente exterior de 150 a 166;
  - exposición de −0,05 a 0;
  - neblina de 0,26 a 0,20 y bruma de 1,0 a 0,6;
  - es el mapa con más ambiente y menos neblina de los tres (comprobado en pruebas).

### Mall Rush — colorido sin RGB gamer
- **Cubierta clara** (de gris 78 a 206): por dentro hace de techo de las zonas de doble altura, que
  dejan de verse oscuras. Desde fuera, cubierta blanca de centro comercial.
- **Fuente moderna (hito 1):**
  - mármol blanco, franja y corona de azulejo cian;
  - dos platos de acero y dos chorros;
  - anillo cian en el suelo que la marca desde la planta alta.
  - **Misma colisión** que la de antes (pilón de 2,4 y columna de 5).
- **Atrio con cúpula (hito 2)** y **escaleras mecánicas (hito 3)**: la escalera lleva una franja
  cian en el costado y se reconoce de lejos.
- **Galería:**
  - franjas de mármol cálido en el suelo (guían hacia el patio y el atrio);
  - tiras de luz en el techo de doble altura (solo neón: **sin luces nuevas**).
- **Identidad exterior:**
  - franja de color bajo el pretil (magenta, cian y naranja);
  - rótulo «MALL RUSH» en la azotea, que se lee en la presentación del mapa;
  - el de la entrada dice **«MALL RUSH»** (antes «SUNRISE MALL»).
- **Luz:** bloom de noche de 0,6 a 0,5.

### Común (reglas visuales)
- **DOF fuera del combate:**
  - `GameConfig.AimDepthOfField = false`: al apuntar ya no se desenfoca nada; la viñeta de los bordes
    sigue.
  - El desenfoque lejano de Ultra (`QualityDOF`) solo se activa en los menús (`AimFX`).
  - La prueba `aimfx` cubre las dos cosas, y el comportamiento antiguo sigue disponible con la opción.
- **Bloom** como mucho 0,5 y **neblina** como mucho 0,26 en las tres luces de cada mapa gold
  standard (comprobado en pruebas).
- **Calidad gráfica:** los detalles pequeños nuevos (franjas del suelo, anillo interior de la fuente,
  patas del rótulo, agujas del reloj) se ocultan en calidad Baja con el sistema que ya había
  (`HIDE_BELOW` en `Settings`). No hay sistema paralelo.

## D. MapKit / TacKit

- `Mall.mallFountain` (nueva pieza del kit Mall). No se llama `fountain` para no tapar `Town.fountain`:
  `TacKit` copia los módulos en orden y el último gana.
- `Mall.escalator`: franja de color en el costado.
- `Town.fountain(cf, d, accent)`: azulejo opcional; sin `accent`, igual que antes.
- `Kit.lighthouse(position, scale)`: escala opcional y galería; sin `scale`, igual que antes.
- `Materials`:
  - **Construction:** `Yellow` pintado y `SafetyNet`.
  - **Mall Rush:** `RoofTop` claro, `Inlay` y `TileAccent`.

## E. Rendimiento

| Mapa | Piezas | Presupuesto (prueba) | Luces nuevas |
|---|---|---|---|
| Construction | ~5.780 (día) / ~6.090 (noche) | 6.400 | 0 |
| Coastal | ~4.190 | 4.450 | 0 (la del faro se movió) |
| Mall Rush | ~2.150 | 2.300 | 0 |

- Los añadidos son pocos y grandes: franjas largas en vez de muchos detalles.
- Sin transparencias nuevas, salvo el agua de la fuente, que ya existía.
- Partículas: solo un chorro más en la fuente de Mall Rush.

## F. Pendiente en Studio

1. **Mall Rush:**
   - que el techo de las zonas de doble altura se vea claro;
   - que la fuente y su anillo destaquen sin deslumbrar;
   - que los rótulos (entrada y azotea) digan «MALL RUSH»;
   - las tiras de luz con bloom 0,4 (no deben quemar).
2. **Coastal:**
   - que sea el más luminoso sin quemar el blanco (exposición 0);
   - que el faro se vea desde el paseo;
   - el contraste de las contraventanas azules.
3. **Construction:**
   - que las franjas amarillas de la torre no parpadeen;
   - que la red roja se vea de lejos;
   - que las barandillas pintadas no sean demasiado chillonas al atardecer.
4. **En los tres:**
   - un enemigo al otro lado del mapa se ve (neblina);
   - apuntar no desenfoca nada;
   - en calidad Baja desaparecen los detalles pequeños pero no la información (sitios, letreros A/B).
5. Las variantes de luz (atardecer, mediodía, noche) de cada uno, con la neblina y el bloom nuevos.

## G. No hecho (a propósito)

- Los otros seis mapas no se han tocado (prioridad del encargo: 3 mapas bien, no 9 por encima). Las
  piezas del kit mejoradas son compatibles hacia atrás.
- Sin texturas ni decals nuevos: no hay assets propios. Las marcas, los azulejos y los suelos son
  materiales de Roblox.
