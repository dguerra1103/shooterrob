# MAP_DEVELOPMENT

Nueva generación de mapas 5v5 reconstruidos a partir de las hojas de referencia. Todo por código
(Rojo + Luau), determinista, con el kit modular `src/server/Modules/TacKit/`.

**Respaldo de los mapas antiguos:** commit `6f78de8` de esta rama (22 mapas + RealKit). Para
recuperar uno: `git checkout 6f78de8 -- src/server/Modules/MapDefs/<Mapa>.luau src/server/Modules/RealKit.luau`
y añadirlo a `MapBuilder.Order`.

## Estado

- [x] Kit modular (TacKit: Geometry, Props, Materials, espejo exacto, spawns, sitios A/B, player clips)
- [x] Construction (Construcción)
    - [x] Blockout
    - [x] Gameplay (rutas, sitios, spawns, navegación verificada)
    - [x] Visual
    - [x] Lighting (atardecer por defecto; mediodía y noche)
    - [x] Optimization (detalle oculto en Rendimiento, skyline sin sombras, player clips)
    - [x] Tested (Lune: navegación, spawns, sitios, visibilidad de bases; falta Studio real)
- [x] Coastal (Costa)
    - [x] Blockout
    - [x] Gameplay
    - [x] Visual
    - [x] Lighting (tarde soleada; atardecer y noche)
    - [x] Optimization
    - [x] Tested (Lune; falta Studio real)
- [x] Terminal
    - [x] Blockout · [x] Gameplay · [x] Visual · [x] Lighting · [x] Optimization · [x] Tested (Lune)
- [x] Mall Rush
    - [x] Blockout · [x] Gameplay · [x] Visual · [x] Lighting · [x] Optimization · [x] Tested (Lune)
- [ ] Rooftop District
- [ ] Metro Yard
- [ ] Desert Base
- [ ] Dockyard
- [ ] Industrial Yard

## Cómo se valida cada mapa (Lune, sin Studio)
- `navcheck`: mapa de alturas (0,5 studs) desde las bases: andar ≤1,1, salto ≤6,8, supersalto
  ≤16,5. Falla si un punto de juego es inalcanzable o hay trampas sin vuelta; lista lo que se
  alcanza fuera de las alturas de diseño (0 / 10 / 20).
- `spawncheck`, `bombsites`, `botspots`, `zonename`, `sndround`, `votecheck`, `smoke`.
- Renders (three.js) desde los mismos ángulos que los paneles de la referencia.

## Fichas

### Construction — Construcción
- Tamaño: 300 x 260 en cruz (bases en ±X, sitios en ±Z). Base→sitio ~7 s corriendo; base→base ~13 s.
- Alturas: suelo 0, primera 10 (torre, ESTRUCTURA, terraza A, entreplanta B, pasarelas), segunda de la torre 20.
- Rutas: carril A (CONTENEDORES → ANDAMIOS → plaza A), centro (PATIO → TORRE → ESTRUCTURA o PATIO B),
  carril B (ACOPIO → MUELLE → nave B), interior (ALMACÉN), elevada (pasarelas de la primera).
- Sitios: A en la plaza exterior (cálido, lona roja); B dentro de la nave (frío, lona azul).
- Bases: recinto de obra con 3 salidas (norte, centro en zigzag tras contenedores, sur).
- Hitos: torre de hormigón con grúa torre, estructuras de acero rojo sobre A y B, lonas A/B, silo.
- Tiempos medidos (navcheck): base→A 6,5 s, base→B 6,7 s (igual para los dos equipos), rotación
  A→B 7,5 s, base→base 10,7 s. Base invisible desde todo el mapa (spawnsight).
- Piezas: ~5.700 (830 chocan), 33 luces.
- Pendiente: probar en Studio la grúa y el montacargas a distancia; ajustar si los bots usan poco
  las pasarelas de la primera.

### Coastal — Costa
- Tamaño: 300 x 260, isla con mar alrededor (el agua es decorado; barandillas en los muelles).
- Alturas: calle 0, parte alta 6 (muro de contención), azotea de la lonja 8,5, balcón del ayuntamiento 14.
- Rutas: callejón (norte, sube a la parte alta por escalera), calle mayor (centro, entra a la plaza
  por un arco desplazado de la puerta de la base), paseo marítimo (sur), interior (iglesia: de la
  plaza a la parte alta; taberna: del callejón a la calle mayor), elevada (mirador, balcón, azotea).
- Sitios: A en la plaza alta frente al ayuntamiento (lona roja); B en el espigón frente a la lonja.
- Bases: patio tras la muralla con 3 puertas (las laterales en L; la central tras un crucero).
- Hitos: campanario, fuente, lonja con soportales, faro en el islote, palmeras del paseo.
- Tiempos: base→A 6,9 s, base→B 6,8 s, rotación 7,5 s, base→base 10,6 s.
- Piezas: ~4.100 (580 chocan), 24 luces.
- Pendiente: Studio real (agua, reflejos y parras).

### Terminal
- Tamaño: 300 x 260. El avión (84 de largo) parte la plataforma: se cruza por el morro (lado A) o
  por la cola (lado B); no se pasa por debajo del fuselaje.
- Alturas: plataforma 0, muelle de carga 4, salidas de la terminal y pasarelas de embarque 10.
- Rutas: carretera de servicio y muelle cubierto (norte, a la terminal), plataforma (centro:
  cisterna, contenedores, deflectores), catering (sur, a la carga), interior (vestíbulo de la
  terminal entre el muelle cubierto y la plataforma A), elevada (salidas + dos pasarelas).
- Sitios: A en la plataforma delante de la terminal (lona roja, cristalera encima); B bajo la
  marquesina de carga (furgoneta, contenedores, muelle).
- Bases: hangares con tres portones; mamparas dentro (todas las salidas en zigzag).
- Hitos: avión con la deriva azul, torre de control, terminal de cristal, pista con marcas.
- Tiempos: base→A 6,1 s, base→B 6,6 s, rotación 6,4 s, base→base 11,0 s.
- Piezas: ~1.900 (360 chocan), ~20 luces.

### Mall Rush
- Tamaño: 236 x 160 de centro comercial + aparcamientos (300 x 180 en total). Dos plantas (0 y 12).
- Rutas: galería central (vestíbulo → patio → atrio), flancos por las tiendas grandes (BLOX MART al
  norte con el pasaje de servicio "A →", PIXEL WEAR al sur con el pasillo sur), pasillo de servicio
  hasta la zona de comida, planta alta (galería, anillos y el puente sobre el atrio, escaleras
  mecánicas desde la fuente).
- Sitios (como en la referencia): cada equipo defiende el de su mitad (A el Rojo en el patio oeste,
  B el Azul en el este). Aquí no hay ventaja de salida extra (el defensor ya está cerca).
- Bases: marquesina del aparcamiento; el camión, un tótem y la furgoneta tapan las puertas, y dentro
  hay un vestíbulo-esclusa con las puertas desplazadas.
- Hitos: cúpula de cristal y fuente con palmeras, banderolas MALL RUSH, puestos BITES/SODA/PIZZA/NOODLE.
- Tiempos: base→su sitio 3,8 s, base→sitio rival 7,7 s, rotación 3,9 s, base→base 11,5 s.
- Piezas: ~2.100 (480 chocan), 20 luces.

### Buscar y destruir con sitios compartidos
Los sitios A y B de los mapas nuevos están a la misma distancia de las dos bases. Para que los
defensores puedan colocarse, los atacantes salen `DefenderHeadStart` = 3 s después (GameConfig).
