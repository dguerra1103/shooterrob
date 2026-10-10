# Misión de estabilización, mapas y calidad visual · informe (9 de octubre de 2026)

Rama: `claude/intelligent-fermi-cz7und`. Punto de recuperación anterior: etiqueta local
`recovery/pre-estabilizacion` (commit `328a150`).

**Alcance real.** La sesión se dedicó casi entera a la prioridad 1 (mapas) y a parte de la 5 (sistemas
pendientes). Las prioridades 2 (rediseño visual de mapas), 4 (animaciones) y 6 (multijugador) no se
hicieron, y la 3 (armas) la lleva otra sesión abierta en paralelo («Armas llamativas con fuegos en
Blender»), con la que se repartieron los archivos para no pisarse. No fueron cuatro horas de trabajo.

## 1. Diagnóstico de los mapas

Método: `tools/studio/mapaudit` construye cada mapa en Studio con el constructor real y mide geometría,
colisiones, caras coplanarias, piezas flotantes, suelo, puntos de aparición y rutas; después se jugó una
partida en cada uno (`tools/studio/maptest`). Evidencia en `assets/maps/diagnostico/`
(`auditoria_antes.txt`, `auditoria_despues.txt`, `prueba_en_partida.txt` y capturas).

| Fallo | Dónde | Causa | Cómo se comprobó |
|---|---|---|---|
| Muro invisible en la ruta principal | Rooftop District | El pretil este de la azotea oeste queda dentro de la plataforma; su tope invisible («PlayerClip», hasta el techo) subía por encima y cerraba la boca del puente de cristal | Rayos a lo largo del puente: chocaban con una pieza invisible de 1,4 × 56,8 × 73,4 |
| Los bots no navegaban por las azoteas | Rooftop District | Con terreno en la calle (40 studs más abajo) las rutas se calculaban por ahí: todos los puntos de paso salían a y = −40 | Puntos de paso de las rutas; al quitar el terreno dejó de haber ruta hasta arreglar lo anterior |
| Plantas altas sin ruta para los bots | Construction, Terminal, Mall Rush, Industrial Yard, Rooftop District | La malla de navegación del motor no da por transitable una escalera de más de unos 30° (26,6°: sí; 32° y 33,7°: no) | Rutas a cada punto; coincide con todas las escaleras de esa pendiente |
| Apariciones dentro de objetos | 7 de 9 mapas (bancos, cajas, muros, un contenedor, un depósito, un techo bajo) | Puntos de aparición libres (`FFASpawn`) colocados a mano encima de props. Se usan también al reaparecer en Duelo, Zona, Dominio y Calabazas | Caja del tamaño de un personaje en cada punto |
| Superficies que parpadean (z-fighting) | Los 9 | Las sombras de contacto iban todas a la misma altura (coplanarias entre sí y con las losas, o enterradas bajo ellas) y había suelos y marcos enrasados con otra pieza de distinto color | Búsqueda de caras coplanarias que miran al mismo lado y se solapan |
| Título contradictorio al final | Modos sin equipos | Sin ningún punto, el servidor daba por ganador al primer jugador: «VICTORIA» con el motivo «EMPATE» | Captura de la pantalla final de Escalada de armas |
| Textos encima de las armas | HUD de PC | La lista de teclas caía entera sobre las ranuras de armas | Capturas en partida |

No se encontró: suelo que falte, piezas sin anclar, mapas duplicados ni restos de la partida anterior al
cambiar de mapa (en nueve cambios seguidos solo quedó una carpeta `Map` y los objetos del modo en curso).

## 2. Correcciones

- **`MapCheck` (nuevo, `src/server/Modules/MapCheck.luau`)**: repasa cada mapa al construirlo.
  Apoya las sombras de contacto en su suelo y separa las que se pisan; saca 1 cm la cara de la pieza
  pequeña cuando dos caras de distinto aspecto coinciden; lleva al hueco libre más cercano los puntos de
  aparición y puestos de bots metidos en un objeto (o los retira si no hay hueco); y, en segundo plano,
  comprueba las rutas desde las bases y lo deja escrito en la consola (`[MapCheck]`) y en atributos de
  `workspace.Map`. Los puntos de aparición a los que no se llega a pie se retiran.
- **Rooftop District**: hueco en el pretil donde está la plataforma; la calle pasa a ser solo decorado.
- **Escaleras** (`TacKit/Geometry`): enlace de ruta en las de más de 27°; barandilla al borde y de
  choque fino en las de 5 o menos de ancho.
- **Bots**: recuerdan por mapa si el radio ancho falla siempre, para no calcular cada ruta dos veces.
- **Fin de partida sin equipos**: sin puntos no gana nadie (empate).
- **HUD**: la lista de teclas va encima de las ranuras de armas. *Sin ver en Studio todavía.*
- **Rangos**: en la pantalla final el emoji del rango pasa a ser su emblema. *Sin ver en Studio todavía.*
- **Prueba `scopesway`**: el visor medía el aire con dt y el «sin aire» con el reloj real; ahora usa un
  solo reloj. La prueba pasa.

## 3. Resultado medido

Auditoría en modo Edit (los nueve mapas):

| Mapa | Caras coplanarias antes → después | Puntos mal antes → después | Sin ruta antes → después |
|---|---|---|---|
| Construction | 679 → 0 | 2 → 0 | 3 → 4 |
| Coastal | 427 → 20 | 4 → 0 | 0 → 0 |
| Terminal | 266 → 0 | 6 → 4 | 2 → 0 |
| Mall Rush | 403 → 0 | 4 → 0 | 4 → 0 |
| Rooftop District | 296 → 0 | 0 → 0 | 11 → 4 |
| Metro Yard | 698 → 0 | 2 → 2 | 0 → 0 |
| Desert Base | 612 → 0 | 4 → 4 | 0 → 0 |
| Dockyard | 1546 → 0 | 2 → 0 | 0 → 0 |
| Industrial Yard | 342 → 0 | 2 → 0 | 4 → 0 |

Notas: el recuento de «antes» usaba una tolerancia más ancha (1,2 cm frente a 0,4 cm), así que la
comparación de caras es orientativa. Los «puntos mal» que quedan (Terminal, Metro Yard, Desert Base) son
puntos con el techo entre 5,7 y 6,6 studs: un personaje cabe y el repaso del juego los da por buenos; la
auditoría mide con una caja un stud más alta. Los «sin ruta» de Construction son dos puntos de aparición
que el repaso retira y dos puestos de bots.

En partida (una por mapa, con cambio de mapa entre ellas): los nueve cargan, la malla de navegación
está lista entre 0 y 4,4 s, los bots se mueven en todos, ninguno cae al vacío, sin errores en la
consola. Modos vistos funcionando: Escalada de armas (por primera vez), Todos contra todos, Bandera,
Dominio, Zona, Buscar y destruir, Duelo, Infección y Eliminación. La pantalla final se vio por primera
vez, en cinco modos.

## 4. Lo que queda abierto en mapas

- **Rooftop District**: los bots siguen sin subir a las cuatro plataformas altas de las esquinas (el
  enlace existe, pero su arranque queda en una franja de 3,5 studs sin malla). Solo afecta a cuatro
  puestos de francotirador de los bots.
- **Construction**: tres puntos de las plantas de la torre siguen sin ruta, y un punto de aparición
  recolocado quedó sin ruta; el repaso los retira, pero conviene recolocarlos a mano.
- **Industrial Yard**: dos puntos de aparición sobre una pieza con tope quedan retirados.
- **Coastal**: quedan 20 caras coplanarias en las casas del decorado del fondo.
- El repaso tarda 0,05–0,66 s al construir (Construction es el más lento); ocurre tras la pantalla de carga.
- La prioridad 2 (arquitectura, coberturas, iluminación, identidad) no se tocó. Vistos y sin corregir: el
  óxido muy saturado de contenedores y vallas (Dockyard, Terminal) y las variantes de noche, muy oscuras.

## 5. Armas y chaflanes

No se modificó ningún modelo: los lleva la otra sesión. Lo investigado sobre la importación:

- El MCP de Studio no tiene herramienta para importar mallas (`upload_image` solo sube imágenes).
- `AssetService:CreateAssetAsync` no está disponible en esta versión (comprobado en la sesión anterior).
- Vías que quedan: importar cada `.fbx` a mano con *Import 3D* de Studio, o subirlos con Open Cloud
  usando una clave de API tuya (yo no manejo credenciales). Ninguna se ha probado.
- Los chaflanes de los modelos miden 0,012–0,028 studs: en el juego serían un brillo de 1–3 píxeles en
  el canto. Reproducirlos con piezas fundidas triplicaría las primitivas por arma; no lo recomiendo.

## 6. Animaciones, multijugador y Android

- **Animaciones**: sin cambios y sin verificar en movimiento.
- **Multijugador**: el MCP solo arranca una partida de un jugador; no se pudo lanzar una prueba con dos
  clientes. Hay que hacerla a mano en Studio (Test → Start, 2 jugadores).
- **Medidas del cliente en Studio** (no sustituyen a un teléfono):

| Mapa (modo) | Llamadas de dibujo | Triángulos en escena |
|---|---|---|
| Terminal (Bandera) | 147 | 266 000 |
| Mall Rush (Dominio) | 187 | 250 000 |
| Dockyard (Infección) | 355 | 234 000 |
| Coastal (Todos contra todos) | 227 | 134 000 |
| Rooftop District (Zona) | 102 | 49 000 |
| Metro Yard (Buscar y destruir) | 94 | 38 000 |
| Desert Base (Duelo) | 80 | 36 000 |
| Industrial Yard (Eliminación) | 64 | 22 000 |
| Construction (Escalada) | 44 | 13 000 |

  Son una sola muestra desde donde estaba la cámara. Terminal, Mall Rush y Dockyard son los primeros a
  mirar en un Android real.

## 7. Por validar en Android

Todo lo anterior: rendimiento por mapa (los tres de arriba primero), parpadeo de superficies a
distancia, interfaz táctil, efectos de las armas y memoria.

## 8. Cómo probar

1. Abre `ShooterRob.rbxlx` en Studio (si hay cambios de armas sin commitear de la otra sesión, regenera
   antes con `rojo build -o ShooterRob.rbxlx`).
2. Play. En la consola del servidor, cada mapa deja una línea `[MapCheck]` si tiene avisos.
3. Para repetir la auditoría: `cd tools/studio && node mapaudit.js && node run.js mapaudit.json > informe.txt`.
4. Para una partida por mapa: `node maptest.js && node run.js maptest.json` (con el modo QA activado en
   la copia de Studio; ver `tools/studio/README.md`).

---

# Mejora visual de los mapas (10 de octubre de 2026)

Sin Blender: las mallas no se pueden importar por script, así que la mejora se hizo sobre el generador
(materiales, luz y terreno). Capturas a la altura de los ojos, siempre desde los mismos puntos, en
`assets/maps/visual/` (arriba, antes; abajo, después). Herramienta: `tools/studio/mapshots.js`.

## El fallo del vídeo (Mall Rush)

La puerta que se veía como un rectángulo negro era la marquesina de la base: paredes y techo de metal
oscuro y ninguna luz dentro. El metal a la sombra refleja lo oscuro y la base entera se dibujaba negra;
al salir, aparecía el mapa de golpe. No era un fallo de carga.

- Todas las bases tienen ahora dos puntos de luz suaves y sin sombras (`T.spawnZone`).
- La marquesina de Mall Rush lleva tubos de luz y su material pasa a hormigón pintado.

Comprobado con capturas dentro de la base antes y después (`MallRush_base_*.jpg`). **No comprobado en
partida**: el Studio principal estaba en uso y se trabajó en la copia de recuperación.

## Resto de cambios

| Qué se veía | Causa | Cambio |
|---|---|---|
| Hierba alta dentro del centro comercial y de la terminal | El relleno de terreno bajo el mapa era de hierba y sus briznas 3D atravesaban los suelos | Mall Rush: relleno de pavimento, más hondo. Terminal: césped sin briznas |
| Contenedores, vallas y hangares con un moteado naranja | El material de óxido de 2022 tapa el color y los rótulos | Chapa pintada; el óxido queda solo en chorretones pequeños |
| Dockyard y Metro Yard lavados, casi blancos | Mucha bruma azul a corta distancia y sol duro sobre hormigón claro | Menos bruma, algo más de contraste y saturación, suelo un punto más oscuro |
| Suelo de Metro Yard y de Mall Rush con vetas que parecían agua | El mármol de 2022 | Hormigón pulido en Metro Yard, caliza en Mall Rush |
| Roca asomando por la plaza de Coastal | El relleno de roca quedaba a 0,3 del pavimento | Relleno más hondo |

Quitar la hierba 3D de Terminal y Mall Rush debería bajar además sus triángulos (eran los dos mapas más
pesados); no se ha vuelto a medir.

## Pendiente

- Verlo todo en partida y en un móvil.
- Variantes de noche y de atardecer: no se han revisado.
- Arquitectura, coberturas y decoración: sin tocar.
- Dos instancias de Studio abiertas a la vez hacían que las herramientas las mezclaran: ahora se elige
  con `SR_STUDIO=<trozo del nombre>`.

## Segunda tanda visual (mismo día)

- **Asfalto con el color equivocado**: el color de asfalto que pide cada mapa no se aplicaba nunca (faltaba
  en la lista de materiales de terreno) y salía el del motor, un gris verdoso claro. Por eso Dockyard se
  veía tan pálido. Afectaba a Dockyard, Metro Yard, Rooftop District y Terminal. Corregido en `MapKit`.
- **Detalle de suelo** (módulo nuevo `MapDress`): manchas de aceite, grietas, rodadas, charcos y tapas de
  alcantarilla repartidos por las zonas abiertas de ocho mapas (Mall Rush no: es un interior limpio).
  Mismo reparto en todas las partidas y simétrico. Son 60–170 piezas finas por mapa, sin colisión ni
  sombra. `MapCheck` las apoya en su suelo y evita que se pisen.
- **Charcos** menos brillantes; **luz de las bases** en blanco neutro (teñida de azul, la base azul tiraba
  a lila de noche).
- **Aviso falso del repaso** cuando había un personaje encima de un punto de aparición: corregido.

Comprobado: auditoría de los nueve mapas sin caras coplanarias nuevas ni rutas rotas, y tres partidas
(Dockyard, Industrial Yard, Mall Rush) sin errores. Mall Rush pasa de unos 250 000 a 57 000 triángulos
en escena al quitar la hierba 3D (una muestra, en Studio). La lista de teclas del HUD ya no pisa las
ranuras de armas (visto en partida).

Visto y sin tocar: en las variantes de noche las superficies claras tiran a violeta; ya era así.
