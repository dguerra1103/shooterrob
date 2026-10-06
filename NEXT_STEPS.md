# NEXT_STEPS

> **Nota (reconstrucción de mapas):** los mapas que se citan en este registro (Encrucijada, Base Militar, Cumbre, Puesto del Desierto, Harbor Heights, etc.) se retiraron al hacer los nueve mapas 5v5 nuevos. El estado actual de los mapas está en `MAP_DEVELOPMENT.md`.

Solo lo importante que todavía tiene sentido, por orden.

0. **Monetización** (ver `ECONOMY.md`): crear los productos en el Creator Dashboard y pegar sus ids
   (todos están a `0` con `TODO: SET IN CREATOR DASHBOARD`); probar las compras de prueba de Studio
   (Robux, cancelar, pack parcial, pase); mirar la analítica (store_open → purchase_prompt →
   purchase_success) a la semana; y **preparar la Temporada 2 antes del 1 de enero de 2027** (nueva
   entrada en `BattlePassConfig.Seasons`, con cosméticos nuevos con monedas para mantener el sumidero).
1. **Probar en Studio real** (2 jugadores + bots): todo está validado con luau-lsp y pruebas Lune, pero
   no en el motor. Revisar sobre todo la killcam final, el contorno de enemigos y los nombres de zona.
2. **Perfilar en móvil** (ver PERFORMANCE_NOTES): un tiroteo de 10 en Encrucijada con calidad Auto.
3. **Sonidos propios**: los disparos usan sonidos de Roblox con capas; unos sonidos originales por
   familia (pistola, fusil, escopeta, francotirador) darían el mayor salto de "game feel".
4. **Animaciones del viewmodel con Animator** (recarga, inspección, equipar) en vez de procedurales,
   empezando por el fusil de asalto y la pistola, que son las que más se ven.
5. **Nombres de zona más finos**: todos los mapas tienen ya nombres (Downtown usa el automático,
   «NORTE · LADO ROJO»); probar con gente qué nombres se usan de verdad al hablar y ajustarlos.
6. **Probar Puesto del Desierto con gente**: tiempos de cruce, líneas de tiro desde los puestos de
   tirador y si los callejones favorecen demasiado a un estilo.
7. **Accesorios de armas** (mira, cañón, empuñadura) con efecto real pequeño: profundidad tipo
   Phantom Forces sin romper el equilibrio. Solo se desbloquearían jugando (nunca con Robux ni monedas:
   ver las reglas de `ECONOMY.md`).
8. **Repetición del jugador destacado** al final de la partida (la killcam ya guarda el historial).
