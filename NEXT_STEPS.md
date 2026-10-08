# NEXT_STEPS

> **Nota (reconstrucción de mapas):** los mapas que se citan en este registro (Encrucijada, Base Militar, Cumbre, Puesto del Desierto, Harbor Heights, etc.) se retiraron al hacer los nueve mapas 5v5 nuevos. El estado actual de los mapas está en `MAP_DEVELOPMENT.md`.

Solo lo importante que todavía tiene sentido, por orden.

**Fase 1 (estabilidad) terminada fuera de Studio** — ver `FASE_01_ESTABILIDAD.md`. Lo siguiente es
**pasar su sección E en Roblox Studio** (1 jugador, 2 jugadores, 5 + bots, 5 partidas seguidas, cada
modo) y traer el texto de la Output de lo que falle. Antes de cada push: `tests/check.sh` y
`tests/run_all.sh` (ver `tests/README.md`). Publicar solo a mano (Actions → Publicar en Roblox, con el
Place ID de ShooterRob para confirmar).

**Fase 2 (gunplay) terminada fuera de Studio** — ver `FASE_02_GUNPLAY.md`. Perfiles de sensación por
tipo de arma (`WeaponFeel`), retroceso separado (juego / cámara / arma), efectos según la calidad y el
móvil, huecos de audio propio por arma e instrumentación de impactos (apagada). Lo siguiente es **pasar
su sección F en Studio** empezando por el ARX-27 y ajustar los perfiles jugando.

**Fase 3 (mapas gold standard) terminada fuera de Studio** — ver `FASE_03_VISUAL_MAPAS.md`. Mirar en
Studio Construction, Coastal y Mall Rush (sección F) antes de llevar las mismas mejoras al resto.

**Fase 4 (UI/UX) terminada fuera de Studio** — ver `FASE_04_UI_UX.md`. Revisar el flujo con el Device
Emulator (sección D). Para el audio propio de la interfaz, rellenar los huecos de `UISound.Custom`.

**Fase 5 (móvil y rendimiento) terminada fuera de Studio** — ver `FASE_05_MOVIL_RENDIMIENTO.md`.
No hay cifras de FPS: hay que medir con el MicroProfiler y en un móvil real (sección E).

**Fase 6 (bots y primeras partidas) terminada fuera de Studio** — ver `FASE_06_BOTS_ONBOARDING.md`.
Bots revisados, sin cambios. Consejos de contexto para jugadores nuevos (`Hints`): probar con una
cuenta nueva (sección E).

**Fase 8 (preparación para Studio)** — ver `FASE_08_VALIDACION_STUDIO.md`. **Lo siguiente es probar
de verdad en Studio:** activar el modo QA (`GameConfig.QA.Enabled = true` solo en local; solo funciona
dentro de Studio), seguir la guía (empezando por la sección C: ARX-27 en los tres mapas gold standard)
y apuntar cada fallo en `STUDIO_TEST_RESULTS.md`.

**Fase 9 (ARX-27 gold standard) terminada fuera de Studio** — ver `FASE_09_ARX27_GOLD_STANDARD.md`.
Brazos con IK, presets de pose por familia en `WeaponVisual`, marcadores de recarga/inspección/cuerpo a
cuerpo en `ClientState.WeaponEvent` y plantilla de modelo externo (`ReplicatedStorage.WeaponViewModels`).
Lo siguiente es **pasar su sección L en Studio** con el botón «ARX-27 Gold» del panel QA y, si se
consigue audio propio, pegar los ids en los 12 huecos del ARX-27 (`Sounds.WeaponAudio`).

**Fase 11 (pulido general) terminada fuera de Studio** — ver `FASE_11_PULIDO_GENERAL.md`. Audio real
por familia (biblioteca Pro Sound Effects de Roblox), impactos con sonido, interfaz con el set oficial
de Roblox, muesca en móvil, 6 fallos de UI y 5 de bots. **Lo siguiente es escucharlo y verlo en
Studio** siguiendo su sección M (sobre todo el audio: no se ha podido escuchar nada).

**Fase 12 (HUD e interfaz móvil) terminada fuera de Studio** — ver `FASE_12_MOVIL.md`. Controles
táctiles nuevos (disposición alrededor del salto de Roblox, jerarquía, iconos con formas, disparar
arrastrando, correr automático), HUD de partida sin tapar el centro y editor de HUD. **Lo siguiente es
jugarlo en un móvil de verdad** siguiendo su matriz de resoluciones y sus pruebas a mano, y ajustar las
distancias en `MobileHUD.Controls`.

0. **Monetización** (ver `ECONOMY.md`): crear los productos en el Creator Dashboard y pegar sus ids
   (todos están a `0` con `TODO: SET IN CREATOR DASHBOARD`); probar las compras de prueba de Studio
   (Robux, cancelar, pack parcial, pase); mirar la analítica (store_open → purchase_prompt →
   purchase_success) a la semana; y **preparar la Temporada 2 antes del 1 de enero de 2027** (nueva
   entrada en `BattlePassConfig.Seasons`, con cosméticos nuevos con monedas para mantener el sumidero).
1. **Probar en Studio real** siguiendo `FASE_01_ESTABILIDAD.md` (sección E): todo está validado con
   luau-lsp y pruebas Lune, pero no en el motor. Revisar además la killcam final, el contorno de
   enemigos y los nombres de zona; y, con latencia simulada, la tolerancia de impactos (sección F).
2. **Perfilar en móvil** (ver PERFORMANCE_NOTES): un tiroteo de 10 en Encrucijada con calidad Auto.
3. **Sonidos propios** (Fase 11: ya hay grabaciones reales por familia en `Sounds.FamilyAudio`): solo
   si al escucharlas en Studio alguna no convence, poner la propia en `Sounds.WeaponAudio`.
4. **Animaciones del viewmodel con Animator** (recarga, inspección, equipar) en vez de procedurales,
   empezando por el fusil de asalto y la pistola, que son las que más se ven. Engancharlas a
   `ClientState.WeaponEvent` (Equip, Fire, ReloadStart con Empty/Duration, ReloadCancel, Inspect).
5. **Nombres de zona más finos**: todos los mapas tienen ya nombres (Downtown usa el automático,
   «NORTE · LADO ROJO»); probar con gente qué nombres se usan de verdad al hablar y ajustarlos.
6. **Probar Puesto del Desierto con gente**: tiempos de cruce, líneas de tiro desde los puestos de
   tirador y si los callejones favorecen demasiado a un estilo.
7. **Accesorios de armas** (mira, cañón, empuñadura) con efecto real pequeño: profundidad tipo
   Phantom Forces sin romper el equilibrio. Solo se desbloquearían jugando (nunca con Robux ni monedas:
   ver las reglas de `ECONOMY.md`).
8. **Repetición del jugador destacado** al final de la partida (la killcam ya guarda el historial).
