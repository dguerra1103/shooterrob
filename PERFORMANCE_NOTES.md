# PERFORMANCE_NOTES

> **Nota (reconstrucción de mapas):** los mapas que se citan en este registro (Encrucijada, Base Militar, Cumbre, Puesto del Desierto, Harbor Heights, etc.) se retiraron al hacer los nueve mapas 5v5 nuevos. El estado actual de los mapas está en `MAP_DEVELOPMENT.md`.

Sin acceso a Studio en esta sesión: no hay perfiles del MicroProfiler. Lo de abajo sale de leer el
código y de las pruebas Lune. **Antes de publicar, perfilar en un móvil modesto** (ver al final).

## Optimizaciones hechas (este pase y los anteriores)
- **Pooling**: fogonazos (anillo de 60 piezas + 16 bolas + una sola PointLight reutilizada), trazadoras,
  casquillos limitados (1 clic de casquillo cada 0,1 s), destello del enemigo impactado (un solo Highlight).
- **Calidad por niveles** (`Settings.luau`): Rendimiento apaga sombras globales, bloom, nubes, partículas
  del mapa, focos con sombra y detalles pequeños (`HIDE_BELOW`); Equilibrada usa el 40 % de partículas.
  Desde la Fase 2, los efectos cosméticos de las armas sí dependen de la calidad y del móvil
  (`WeaponFeel.Quality` y `WeaponFeel.MobileCap`): en Baja sin casquillos ni marcas de bala y con menos
  partículas de impacto; marcas como mucho 50 (Alta), 30 (Media) o 20 (móvil). Lo que es información de
  juego (trazadoras, hitmarkers, avisos de baja, impactos sobre personas) no cambia con la calidad.
- **Sombras**: `MapKit` solo deja `CastShadow` en piezas de más de 20 studs³ (ni neón ni cristal); los
  focos con `QualityShadow` solo dan sombra en Alta/Ultra.
- **Ventisca** (Estación Ártica): de ~2.500 a ~1.400 partículas y, además, escalada por la calidad.
- **Bucles por fotograma con freno**: callouts, sonidos de recarga enemigos, nombres de zona (0,25 s),
  linternas remotas (0,25 s), minimapa (30 Hz), killcam (muestras cada `SampleTime`).
- **Contorno de enemigos**: un Highlight por enemigo (5 en 5v5); Roblox dibuja como mucho 31 a la vez.
  Con compañeros (4) + enemigos (5) + destello (1) + radar sobra margen.
- **Red**: `AimPitch` cuantizado y limitado (0,2 s y cambio ≥ 3°); linterna limitada a 5/s aplicando el
  último valor; granada: un solo `GrenadePin` por lanzamiento.
- **Viewmodel (Fase 9)**: los brazos son 8 piezas ancladas (4 por brazo) colocadas con un IK analítico
  de dos huesos por fotograma (unas pocas operaciones de vectores: despreciable al lado del render). Los
  muelles y suavizados usan `WeaponFeel.StepSpring` exacto y `damp`/`decay` dependientes de `dt`, así
  que se comportan igual a 30, 60 o 240 FPS. Los marcadores de recarga son `task.delay` (3-6 por recarga),
  no trabajo por fotograma. En calidad Baja la luz del fogonazo está apagada (`MuzzleLight = false`); las
  animaciones no cambian con la calidad.
- **Fase 11**: la barra de munición del HUD y las balizas que parpadean (`WorldFX`) solo escriben al
  cambiar (antes, en cada fotograma). Impactos con sonido: como mucho uno cada 50 ms; casquillos, uno
  cada 0,16 s y solo si la calidad muestra casquillos; las tomas de cada sonido van en su pool.
- **Fase 12 (controles táctiles)**: los botones no hacen nada por fotograma; sus estados (apuntando,
  recarga necesaria, salto de Roblox movido) se revisan 10 veces por segundo y solo escriben si
  cambian; los iconos (formas) solo se redibujan si cambia su tamaño. La tarjeta del arma compara los
  valores en bruto antes de crear textos. Los ajustes de controles solo recolocan si cambian de verdad
  (no con cada actualización del perfil). Ver `FASE_12_MOVIL.md` (H).

## Problemas detectados / vigilar
- **Sonidos 2D (hecho)**: los sonidos que más se repiten (disparo, estampido, mecanismo, impacto, baja,
  clic...) van en un **pool** de 6 por nombre en `Sounds.Play` (los de las armas en uno aparte): al
  reutilizarse se les quitan los efectos y vuelven al principio; si los 6 suenan, el siguiente se crea
  aparte (no se corta ninguno). Antes cada disparo creaba y destruía 2-4 `Sound`.
- **HUD.luau (2.2k líneas) y Menu.luau (2.8k)**: muchos elementos; el HUD ya escribe textos solo cuando
  cambian (`hudCache`). Vigilar el coste de `UIStroke`/`UIGradient` en móviles.
- **Iconos 3D del killfeed** (`WeaponIcon`, ViewportFrame por entrada): desactivados en Rendimiento.
- **~30 conexiones Heartbeat/RenderStepped** en el cliente: casi todas salen pronto o van con freno; las
  más caras son `WeaponController` (viewmodel) y `HUD.render`.
- **Mapas por código**: los mapas grandes (Encrucijada, Base Militar) tienen miles de piezas; están
  ancladas y la mayoría sin colisión ni consulta. Si un móvil va justo, el primer candidato es
  `StreamingEnabled` o fusionar decoración.
- **Acabados de la Fase 14**: todo es decorado anclado sin colisión ni consulta y sin sombra (salvo
  volúmenes grandes); lo fino (banderines, bordillos, abrazaderas, lamas, líneas de luz) se oculta en
  calidad Baja. Piezas (variante por defecto / noche): Construction ~5850 / 6204 (tope 6400), Coastal
  ~4375 / 4407 (tope 4450), Mall Rush ~2255 (tope 2300). Coastal queda cerca del tope.
- **Lluvia**: el mojado de superficies recorre el mapa una vez repartido en varios fotogramas.

## Posibles cuellos de botella (por orden de sospecha)
1. Tiroteos con 10 bots + efectos (trazadoras, impactos, casquillos, sonidos con capas).
2. ViewportFrames del killfeed y del menú de armas.
3. Partículas ambientales en Ultra (factor 1,3).
4. Sombras globales en mapas con muchas piezas altas.

## Cómo perfilar
1. Studio → Test → Start (con 9 bots) → Ctrl+F6 (MicroProfiler) durante un tiroteo.
2. Buscar `Heartbeat`/`RenderStepped` largos: deberían salir `WeaponController` y `HUD` como mucho.
3. Device Emulator en un teléfono de gama baja + calidad Auto (= Rendimiento).
