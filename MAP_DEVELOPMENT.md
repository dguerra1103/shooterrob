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
- [ ] Terminal
- [ ] Mall Rush
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

### Buscar y destruir con sitios compartidos
Los sitios A y B de los mapas nuevos están a la misma distancia de las dos bases. Para que los
defensores puedan colocarse, los atacantes salen `DefenderHeadStart` = 3 s después (GameConfig).
