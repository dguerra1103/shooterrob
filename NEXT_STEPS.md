# NEXT_STEPS

Solo lo importante que todavía tiene sentido, por orden.

1. **Probar en Studio real** (2 jugadores + bots): todo está validado con luau-lsp y pruebas Lune, pero
   no en el motor. Revisar sobre todo la killcam final, el contorno de enemigos y los nombres de zona.
2. **Perfilar en móvil** (ver PERFORMANCE_NOTES): un tiroteo de 10 en Encrucijada con calidad Auto.
3. **Sonidos propios**: los disparos usan sonidos de Roblox con capas; unos sonidos originales por
   familia (pistola, fusil, escopeta, francotirador) darían el mayor salto de "game feel".
4. **Animaciones del viewmodel con Animator** (recarga, inspección, equipar) en vez de procedurales,
   empezando por el fusil de asalto y la pistola, que son las que más se ven.
5. **Más nombres de zona** en los mapas de colores que aún usan el respaldo automático (Pastel Plaza,
   Caja de Juguetes, Feria...): 2-3 `Kit.callout` por mapa.
6. **Probar Puesto del Desierto con gente**: tiempos de cruce, líneas de tiro desde los puestos de
   tirador y si los callejones favorecen demasiado a un estilo.
7. **Accesorios de armas** (mira, cañón, empuñadura) con efecto real pequeño: profundidad tipo
   Phantom Forces sin romper el equilibrio.
8. **Repetición del jugador destacado** al final de la partida (la killcam ya guarda el historial).
