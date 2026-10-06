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
- [x] Rooftop District
    - [x] Blockout · [x] Gameplay · [x] Visual · [x] Lighting · [x] Optimization · [x] Tested (Lune)
- [x] Metro Yard
    - [x] Blockout · [x] Gameplay · [x] Visual · [x] Lighting · [x] Optimization · [x] Tested (Lune)
- [ ] Desert Base
- [ ] Dockyard
- [ ] Industrial Yard

## Cómo se valida cada mapa (Lune, sin Studio)
- `navcheck`: mapa de alturas (0,5 studs) desde las bases: andar ≤1,1, salto ≤6,8, supersalto
  ≤16,5. Falla si un punto de juego es inalcanzable o hay trampas sin vuelta; lista lo que se
  alcanza fuera de las alturas de diseño (0 / 10 / 20 por defecto; cada ficha dice las suyas).
- `longlines`: rayos a la altura de los ojos de un extremo al otro del mapa (a lo largo de X): avisa
  de líneas de vista de base a base o de túnel a túnel.
- `spawnsight`: rayos desde una rejilla del mapa (a la altura de los ojos) a los puntos de
  aparición: falla si la base se ve desde fuera de su zona.
- Clips de jugador (`T.cap`): cajas invisibles que dejan pasar las balas, desde lo alto de muros,
  pretiles y montones hasta el techo del mapa (60): nadie se sube a donde no debe con el supersalto.
  En piezas inclinadas (barandillas de escaleras y rampas) el clip va en tramos verticales.
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

### Rooftop District
- Tamaño: 300 x 200 de azoteas sobre una manzana; la calle queda 40 studs abajo (decorado, todos los
  bordes con pretil y clip: no se cae nadie).
- Alturas: 0 (base, bloque oeste, azotea B), 4 (azotea A), 6 (centro, torre NO, plataforma del
  puente de cristal), 8 (depósito SO) y 14 (plataforma alta de la antena). navcheck con 0,4,6,8,14.
- Rutas: puente de cristal (centro, cubierto) hasta la azotea de la pantalla; pasarelas norte y sur
  del centro a A y B; flancos por las esquinas (torre NO → puente → A; suroeste → puente → B);
  el bloque oeste con tres puentes desde la base; zonas altas (antena 14, depósito 8).
- Sitios: A en la azotea norte (franja roja, cuarto de escalera con toldo rojo); B en la azotea sur
  entre lucernarios (franja azul, depósito de agua). Compartidos (salida 3 s antes del defensor).
- Bases: caseta cerrada sobre la azotea, frente ciego al mapa, puertas norte y sur con vestíbulo en L.
- Hitos: pantalla gigante del centro, puente de cristal, antena de la torre, depósitos de agua, grúa
  lejana y la ciudad alrededor (dos anillos de torres con ventanas encendidas de noche).
- Tiempos: base→A 7,0 s, base→B 6,9 s, rotación 6,1 s, base→base 13,8 s.
- Piezas: ~3.050 (680 chocan), 4 luces (la ciudad no proyecta sombras).
- Pendiente: en Studio, comprobar que el vacío entre azoteas no confunde a los bots.

### Metro Yard
- Tamaño: 300 x 220. Suelo 0; las vías van en dos zanjas a −3 (se baja de un salto y se sube por
  cualquier sitio: 3 studs); a 10 la entreplanta de la estación, la pasarela, la galería de las
  cocheras y el techo de los túneles. navcheck con −3,0,10.
- Rutas: plaza de la estación → puerta oeste del vestíbulo (A); patio de servicio → puerta oeste de
  las cocheras (B); túnel (interior: andén central y zanjas) → playa de vías; andenes norte y sur
  (puertas del vestíbulo y portones de las cocheras); pasarela elevada de la estación a las cocheras
  con escaleras al andén central; techo del túnel (posición alta propia sobre la playa de vías).
- Bajo la pasarela hay núcleos y una pila-muro que, con las casetas de relés de cada mitad, forman
  una chicana en cada zanja: se cruza, pero no hay línea de vista de túnel a túnel. El faldón opaco
  de la pasarela corta la línea entre los techos de los dos túneles; una taquilla delante de cada
  puerta del vestíbulo corta la línea de puerta a puerta por el sitio A.
- Sitios: A en el vestíbulo (torniquetes, columnas, máquinas, cabina de información); B en el
  taller de las cocheras (coches en mantenimiento, banco de trabajo, cajas). Compartidos.
- Bases: cochera de autobuses cerrada, frente ciego hacia el túnel, puertas norte y sur con
  vestíbulo en L.
- Hitos: trenes con franja naranja/azul, pasarela azul con letreros, letrero METRO · CENTRAL,
  tótems "M", viaducto con tren al fondo, autobús y contenedor METRO.
- Tiempos: base→A 6,7 s, base→B 6,6 s, rotación 7,1 s, base→base 11,8 s.
- Piezas: ~3.070 (760 chocan), 28 luces.
- Pendiente: en Studio, comprobar que los bots saltan bien a las zanjas y salen de ellas.

### Buscar y destruir con sitios compartidos
Los sitios A y B de los mapas nuevos están a la misma distancia de las dos bases. Para que los
defensores puedan colocarse, los atacantes salen `DefenderHeadStart` = 3 s después (GameConfig).
