# FASE 14 — Pulido visual de mapas y entorno

Pulido visual de los tres mapas «gold standard» (**Construction, Coastal y Mall Rush**) sin mapas,
modos, armas ni economía nuevos y **sin tocar el juego**: ni spawns, ni sitios A/B, ni rutas, ni
coberturas, ni objetivos. Todo lo añadido es **decorado** (`CanCollide = false`, `CanQuery = false`:
no choca ni para balas, comprobado por la prueba `mapvisual`).

> **Sin Roblox Studio.** Los cambios se han revisado con renders aproximados (la geometría exportada
> del simulador, dibujada con three.js). Ni la luz, ni los materiales, ni la atmósfera son los de
> Roblox: sirven para juzgar **estructura, composición y proporciones**, no el color fino ni la luz.
> **Ningún mapa está «terminado» hasta verlo en Studio**: cada cambio está implementado y pendiente
> de validar (sección 12).

## 1. Estado inicial

- Los 9 mapas existen y se generan por código con el kit modular **TacKit** (`src/server/Modules/
  TacKit/`) y una carpeta por mapa en `MapDefs/<Mapa>/` (Geometry = blockout jugable, Props =
  cobertura y decorado, Lighting = luz y variantes).
- La Fase 3 ya hizo una primera pasada a estos tres mapas (cantos amarillos y red de la torre,
  campanario encalado y faro más cerca, cubierta clara y fuente moderna del centro comercial).
- **Referencias visuales:** no había imágenes adjuntas en el encargo ni en el repositorio. Se ha
  trabajado con la descripción del encargo (paletas, hitos y zonas de cada mapa) y con la ficha de
  cada mapa en `MAP_DEVELOPMENT.md`.
- Lo que más pesaba, visto en los renders de antes:
  - **suelos de un solo material** en todo el mapa: la losa gris de Construction, el enlosado claro
    de Coastal y el mármol blanco de Mall Rush;
  - fachadas largas sin ritmo;
  - la identidad A/B solo en las lonas;
  - fondo genérico;
  - Mall Rush como una caja blanca por fuera, con bordes de forjado grises por dentro.

## 2. Auditoría del kit (TacKit / MapKit)

- **Bien resuelto y reutilizado:**
  - **Materiales:** biblioteca por paleta (`Materials.<Mapa>`, «looks» `{color, material}`).
  - **Construcción de piezas:** geometría con huecos de verdad (`G.wall`, `G.shell`), props de obra,
    pueblo, centro comercial e industria.
  - **Simetría:** espejo exacto (`T.mirrored`).
  - **Calidad gráfica:** detalle por nombre de pieza (`Settings.HIDE_BELOW`: lo fino desaparece en
    calidad Baja; no hay un sistema paralelo).
  - **Escala:** material realista automático en piezas grandes (`Kit.realisticMaterial`).
- **Faltaba:** piezas de acabado grandes y baratas. **Nuevo módulo `TacKit/Finish.luau`** (`T.F`):

| Función | Qué hace |
|---|---|
| `F.groundZone` | Zona de suelo con material propio, a 0,02 sobre el suelo: queda **por debajo** de juntas (0,03), líneas pintadas (0,04) y marcas de los sitios (0,05+). No hay parpadeo y todo eso se sigue viendo encima. |
| `F.zoneEdge` | Marco fino de una zona (bordillo pintado o azulejo) |
| `F.band` | Remate horizontal de fachada (cornisa, zócalo, franja, frente de forjado) |
| `F.pilasters` | Pilastras/esquinas a lo largo de una fachada, saltando huecos |
| `F.awning` | Toldo inclinado (preparado para los siguientes mapas) |
| `F.formwork` | Encofrado de madera con abrazaderas |
| `F.banner` | Lona grande con texto y franjas |
| `F.bunting` | Banderines entre dos puntos (con caída) |
| `F.climber` | Trepadora (buganvilla) en fachada |
| `F.gasHolder`, `F.skeleton` | Siluetas de fondo: gasómetro y esqueleto de edificio en obra |

- `Town.house`: opción `Plinth`, un zócalo pintado. **Sin piezas nuevas**: cambia el color y la
  altura del zócalo que ya existía.
- Cada mapa gold standard tiene ahora un módulo **`Dressing.luau`** (acabados), separado de su
  Geometry/Props: no se ha tocado el blockout.

## 3. Construction — fuerza industrial (gris + hormigón + amarillo + rojo)

- **Suelo por zonas** (lo que más cambia de lejos):
  - **plaza A:** adoquín cálido con bordillo;
  - **patio central:** hormigón gastado, más oscuro;
  - **patio B:** hormigón frío, azulado, con bordillo;
  - **bases:** grava de obra;
  - **carriles norte y sur:** asfalto.
- **Torre central (hito):**
  - lonas amarillas «ROBUILD · TORRE 05» en las caras de la planta baja que miran a los sitios,
    partidas a los lados de los pilares de la pasarela;
  - lonas «OBRA 05» en las caras que miran a las bases, lo primero que se ve al salir;
  - zócalo oscuro;
  - encofrados de madera en los pilares de la última planta (obra en curso).
- **Identidad A / B** en las fachadas:
  - **edificio A:** cornisa y esquinas **terracota**, zócalo oscuro sin tapar puertas (cálido, como
    su lona roja);
  - **edificio B:** remate de cubierta y esquinas **azul acero**, zócalo oscuro (frío, como su lona
    azul).
- **Señalética:** «SALIDA NORTE · A» (rojo) y «SALIDA SUR · B» (azul) en las mamparas interiores de
  cada base. Nombran el sitio, no la dirección, así que valen igual en la base reflejada.
- **Fondo industrial:**
  - tres **chimeneas** de ladrillo;
  - dos **gasómetros**;
  - un **esqueleto de edificio** en obra junto a la grúa lejana;
  - ciudad en hormigón, gris azulado y ladrillo (antes, rosas pastel).
- **Hitos:** grúa, torre, estructuras rojas de A y B, silo y ahora las lonas de la torre y las
  chimeneas del horizonte («EN LA GRÚA», «EN LA TORRE», «EN LA ESTRUCTURA», «EN EL SILO»).
- **Coste:** +~115 piezas (5.783 → 5.901 de día; de noche, 6.204, presupuesto 6.400). **0 luces
  nuevas.**

## 4. Coastal — color + luz + personalidad (blanco, arena, terracota, azul, verde)

- **Suelo por zonas:**
  - **calle mayor y callejón:** adoquín cálido;
  - **plaza de la fuente:** arenisca clara con marco de **azulejo de barro** alrededor de la fuente;
  - **plaza alta (sitio A):** **barro cocido**, la identidad cálida de A;
  - **paseo marítimo:** claro, con franja de **azulejo azul** junto a la barandilla;
  - **espigón (sitio B):** borde de azulejo azul, la identidad azul de B;
  - **bases:** arena.
- **Casas encaladas** con **zócalo pintado azul u ocre**. Sin piezas nuevas: es el zócalo de antes,
  pintado y algo más alto.
- **Buganvillas** (magenta) en las esquinas entre casas de la calle mayor, el callejón, la manzana
  de la taberna y el paseo.
- **Banderines de fiesta:** cruzan la plaza en diagonal, la calle del puerto y la calle mayor (a
  9,5–11 de altura, por encima de la cabeza).
- **Hitos** (sin cambios en esta fase; ya reforzados en la Fase 3): **fuente**, **campanario**,
  **faro**, **muelle**.
- **Coste:** +~190 piezas (4.195 → 4.375 de día; de noche, 4.407, presupuesto 4.450). **0 luces
  nuevas.**

## 5. Mall Rush — energía + color + interior moderno

- **Suelo por zonas:**
  - **atrio:** granito gris bajo la cúpula con marco de azulejo **cian** alrededor de la fuente;
  - **zona de comida:** azulejo cálido con borde naranja;
  - **pasillo de servicio:** hormigón;
  - **patios de los sitios:** marco de su color (**A rojo, B azul**), fuera del espejo.
- **Frentes de forjado** de la planta alta en los huecos del patio y del atrio:
  - frente blanco con una **línea de luz de color** debajo: naranja en los patios, cian en el atrio
    y en los lados del puente;
  - es lo que más se ve desde abajo y da la energía de centro comercial;
  - **solo neón, sin luces nuevas**.
- **Rótulos:** «FOOD COURT» en el fondo de la zona de comida y «NIVEL 2» colgado bajo el puente,
  mirando al arranque de cada escalera mecánica.
- **Fachadas norte y sur** con **lamas verticales** gris oscuro cada 12 studs. La caja blanca deja de
  serlo vista desde la presentación del mapa.
- **Fondo urbano:** vallas publicitarias de **marcas ficticias** (NOVA, BYTE, FLUX) junto a las
  calles. No hay marcas ni logos reales.
- **Hitos:** fuente central, atrio con cúpula, escalera mecánica, zona de comida (ahora con su suelo
  y su rótulo).
- **Coste:** +~115 piezas (2.197 → 2.312; presupuesto 2.300 con margen en la variante más cara:
  ver sección 11). **0 luces nuevas.**

## 6. Otros mapas

**No se han tocado.** Terminal, Rooftop District, Metro Yard, Desert Base, Dockyard e Industrial
Yard siguen como estaban. El encargo pedía tres mapas muy bien hechos antes que nueve a medias, y
los tres necesitan antes una validación en Studio (sección 12). El kit `Finish` queda listo para
ellos (sección 13).

## 7. Materiales

Paletas ampliadas en `TacKit/Materials.luau`; no hay un material por pared, sino uno por zona:

| Mapa | Nuevos looks |
|---|---|
| Construction | `Pavers` (Pavement), `ConcreteWorn`, `ConcreteCool` (Concrete), `Gravel` (Pebble), `Terracotta` (Concrete), `SteelBlue` (Metal), `Brick` (Brick, chimeneas) |
| Coastal | `StreetCobble` (Cobblestone), `PlazaStone`, `Promenade` (Sandstone), `UpperPaving` (Pavement), `BaseSand` (Sand), `TileBlue`, `TileTerracotta` (CeramicTiles), `Bougainvillea` (Grass) |
| Mall Rush | `AtriumStone` (Granite), `FoodFloor` (CeramicTiles), `Fascia` (SmoothPlastic) |

## 8. Iluminación

**Sin cambios en los valores.** Se revisó la de los tres mapas (atardecer industrial en
Construction; tarde soleada y la más luminosa en Coastal; interior claro en Mall Rush). Ya cumplen
las reglas de la Fase 3, que sigue comprobando `mapvisual`:
- neblina ≤ 0,26;
- bloom ≤ 0,5;
- Coastal más luminosa que Construction.

El color que se buscaba (identidad por zonas) viene de los materiales y los suelos, no de filtros.
**Pendiente en Studio:** ver si los suelos nuevos (adoquín, granito, azulejo) se leen con la luz real
o necesitan un ajuste de tono.

## 9. Props

- **Pocos y con propósito.** Más del 80 % del cambio es suelo, fachadas, color y fondo:
  - **identidad / landmark:** lonas, remates, chimeneas, vallas;
  - **guía:** suelos por zona y marcos de los sitios;
  - **escala / ambientación:** banderines, buganvillas y encofrados.
- **Ninguna cobertura nueva:** ningún prop añadido choca.

## 10. Optimización

- **Sombras:** ningún acabado proyecta sombra (`CastShadow = false`). Las piezas de fondo, tampoco.
- **Luces y efectos:** **0 luces nuevas** en los tres mapas (los frentes y la línea de luz son
  neón), sin partículas y sin transparencias nuevas.
- **Calidad Baja** (`Settings.HIDE_BELOW`, ya existente): oculta `Bunting`, `FormworkClamp`,
  `ZoneEdge`, `BannerStripe`, `FacadeFin` y `FasciaGlow`. Los suelos por zona, los remates y los
  hitos se ven siempre (dan la forma del mapa).
- **Coste:** pocas piezas grandes en vez de muchas pequeñas:
  - un suelo de zona es **una** pieza de 70 × 30;
  - todo el pulido suma +115 / +190 / +115 piezas en los tres mapas.

## 11. Pruebas

- `mapvisual` (ampliada):
  - **acabados presentes:** los de la Fase 14 de cada mapa (adoquín de la plaza A, lonas de la
    torre, remates A/B, grava de las bases, fondo industrial y encofrados; plaza, plaza alta,
    buganvillas, banderines y paseo; atrio, comida, frentes y lamas);
  - **ninguno choca ni para balas;**
  - **presupuestos:** el presupuesto de piezas de cada mapa;
  - **luz:** las reglas de luz de siempre.
- Recuento de piezas en todas las variantes de luz (simulador):

  | Mapa | Variantes | Presupuesto |
  |---|---|---|
  | Construction | Día/Mediodía 5.850, Noche 6.204 | 6.400 |
  | Coastal | 4.375, Noche 4.407 | 4.450 |
  | Mall Rush | 2.241 en las tres (sin vallas) | 2.300 |

  Con las vallas, Mall Rush queda en ~2.256.
- Regresión de mapas: ver el resultado de la batería completa al final del documento (navegación de
  los 9 mapas, 10 modos, spawns, sitios, puestos de bots, nombres de zona, votación, ciclo de 10
  partidas).
- **Lo visual no se prueba con Lune:** las pruebas comprueban reglas (decorado, presupuesto, luz),
  no si «se ve bonito».

## 12. Checklist para Studio

Abre cada mapa (modo QA o servidor local), en calidad Alta y luego en **Baja**, y con las variantes
de luz (día, atardecer, noche).

**Construction**
- [ ] Spawn A (Rojo) y Spawn B (Azul): las lonas «OBRA 05» de la torre se ven al salir; carteles
  «SALIDA NORTE · A» / «SALIDA SUR · B» legibles; grava sin parpadeo
- [ ] Mid (patio): hormigón gastado distinto del resto; la torre se lee como obra (lonas, encofrados,
  cantos amarillos)
- [ ] Site A: adoquín cálido con bordillo, cornisa y esquinas terracota del edificio A
- [ ] Site B: patio B frío, remate azul acero del edificio B; dentro de la nave, sin cambios
- [ ] Vista exterior / elevada: chimeneas, gasómetros y esqueleto de edificio en el horizonte; ciudad
  en gris y ladrillo
- [ ] Vista interior: almacén y nave B sin cambios ni parpadeos
- [ ] Grúa: sigue siendo el hito más visible
- [ ] Asfalto de los carriles: se lee como acceso de obra
- [ ] FPS (MicroProfiler) en un tiroteo, comparado con antes

**Coastal**
- [ ] Plaza: arenisca clara, marco de barro alrededor de la fuente, banderines por encima de la cabeza
- [ ] Callejones y calle mayor: adoquín, buganvillas, zócalos azules y ocres
- [ ] Fuente, campanario, faro (desde el paseo y el espigón), muelle
- [ ] Plaza alta (sitio A) en barro cocido; espigón (sitio B) con el borde azul
- [ ] Que el blanco no se queme y que los banderines no despisten como si fueran enemigos
- [ ] FPS

**Mall Rush**
- [ ] Atrio: granito con marco cian; la fuente sigue destacando
- [ ] Planta baja: patio A con marco rojo, patio B con marco azul
- [ ] Planta alta: los frentes de forjado con su línea de color, que **no deslumbren** con bloom
- [ ] Tiendas: sin cambios (rótulos, escaparates)
- [ ] Food court: suelo cálido y rótulo «FOOD COURT»
- [ ] «NIVEL 2» bajo el puente: legible desde la escalera mecánica
- [ ] Fachadas con lamas y vallas NOVA/BYTE/FLUX desde la presentación del mapa
- [ ] FPS

**En los tres:** un enemigo se distingue sobre los suelos nuevos (contraste); nada nuevo bloquea el
paso; en calidad Baja desaparecen los detalles finos pero no los suelos ni los hitos.

## 13. Capturas que necesito

Por mapa (Construction, Coastal, Mall Rush), con la luz por defecto:
1. Vista desde **Spawn A** (Rojo), mirando al mapa.
2. Vista desde **Spawn B** (Azul).
3. **Mid** (Construction: patio con la torre; Coastal: plaza de la fuente; Mall Rush: atrio).
4. **Site A**.
5. **Site B**.
6. **Vista elevada / general** (cámara libre o la presentación del mapa).
7. **Cualquier zona que se vea mal** (parpadeos, colores que no encajan, piezas flotando).

Si puedes, también una captura de noche de cada uno y la cifra de FPS en un tiroteo. Con eso
haremos la siguiente iteración visual sobre Studio real.

**Capturas de esta fase:** los renders de antes y después (three.js, aproximados) se usaron solo
para la estructura; no se han subido al repositorio porque no representan la luz ni los materiales
de Roblox.

## 14. Riesgos

- **Color en el motor:** los tonos de los suelos nuevos se eligieron con un renderizador que no es
  Roblox. Pueden quedar demasiado parecidos o demasiado distintos al suelo de alrededor. Se arreglan
  cambiando una línea de la paleta.
- **Parpadeo** (z-fighting) entre las zonas de suelo (0,02) y el suelo, mirando muy de lado y a
  mucha distancia. Si pasa, basta con subir la lámina a 0,03 en `F.groundZone`.
- **Línea de luz de Mall Rush** con el bloom de la noche: si deslumbra, bajar el neón (color más
  oscuro) o quitar `FasciaGlow`.
- **Banderines de Coastal:** si a alguien le parecen ruido visual en combate, se ocultan en calidad
  Baja y se pueden quitar de la plaza.
- **Presupuestos de piezas:** Coastal queda a 43 piezas del suyo. La siguiente iteración de ese mapa
  tendrá que quitar algo o justificar subirlo.
- **Sonido ambiente:** sin cambios. Ya hay eco por zonas (interior/exterior) y presets por mapa con
  sonidos de Roblox; un ambiente industrial propio para Construction (maquinaria) necesitaría audio
  propio (hueco documentado, no se ha inventado ningún SoundId).

## Resultado final

Batería completa sobre d9f311d (código final de la fase; solo cambia este documento después):
- `tests/check.sh`: Rojo compila, luau-lsp **sin errores** (exit 0).
- `tests/run_all.sh`: **OK: 150 · FALLOS: 0** (exit 0). Incluye `mapvisual`, `navcheck` de los 9
  mapas (NAVEGACION OK), `serverboot` de los 10 modos (SERVIDOR OK), `spawncheck`, `bombsites`,
  `botspots` y el **ciclo de 10 partidas (CICLO OK)**.
- Visual: **cambio implementado, pendiente de validar en Studio** (secciones 12 y 13).
