# MAP_DEVELOPMENT

Nueva generación de mapas 5v5 reconstruidos a partir de las hojas de referencia. Todo por código
(Rojo + Luau), determinista, con el kit modular `src/server/Modules/TacKit/`.

**Respaldo de los mapas antiguos:** commit `6f78de8` de esta rama (22 mapas + RealKit). Para
recuperar uno: `git checkout 6f78de8 -- src/server/Modules/MapDefs/<Mapa>.luau src/server/Modules/RealKit.luau`
y añadirlo a `MapBuilder.Order`.

## Estado

- [x] Kit modular (TacKit: Geometry, Props, Materials, espejo exacto, spawns, sitios A/B, player clips)
- [~] Construction (Construcción)
    - [x] Blockout
    - [x] Gameplay (rutas, sitios, spawns, navegación verificada)
    - [ ] Visual
    - [ ] Lighting
    - [ ] Optimization
    - [ ] Tested
- [ ] Coastal
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
