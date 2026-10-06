# DEVELOPMENT_PROGRESS

> **Nota (reconstrucción de mapas):** los mapas que se citan en este registro (Encrucijada, Base Militar, Cumbre, Puesto del Desierto, Harbor Heights, etc.) se retiraron al hacer los nueve mapas 5v5 nuevos. El estado actual de los mapas está en `MAP_DEVELOPMENT.md`.

Estado del pase "Stylized Tactical Roblox" (shooter 5v5). Corto a propósito: sirve para recuperar contexto.

## Auditoría (lo que ya existe y funciona)
- **Armas**: 20+ armas con modelo propio (WeaponModels/WeaponDesigns), viewmodel con sway, bob, recoil
  procedural, ADS, sprint, recarga táctica/vacía, inspección, calor del cañón (humo), camuflajes y skins.
- **Combate**: hitscan validado en servidor (Combat), headshots, asistencias, granadas (cocinables),
  rachas (radar, ataque aéreo), killcam de muerte y killcam final, asistencia de apuntado (mando/móvil).
- **Feedback**: hitmarker normal/cabeza/baja (color, escala, giro), destello del enemigo impactado,
  números de daño, banner de baja con multibajas (doble → imparable), clutch, MVP de ronda, podio final.
- **Modos**: TDM, FFA, Dominio, Hardpoint, CTF, Escalada, Eliminación, Buscar y destruir, Infección,
  Calabazas/Baja confirmada, Duelo. Bots que rellenan.
- **Mapas**: ~25 mapas por código (MapKit/RealKit), variantes de luz (atardecer, tormenta, niebla,
  ventisca), lluvia, ambiente sonoro por mapa.
- **Gráficos**: calidad Auto/Baja/Media/Alta/Ultra (Settings.luau), escala de partículas por calidad,
  sombras de focos solo en Alta/Ultra, detalles pequeños ocultos en Baja.
- **Meta**: tienda, pase, retos diarios/semanales, maestría, rangos, logros, ruleta, cajas.

## Riesgos detectados
- HUD.luau (2.2k líneas) y Menu.luau (2.8k) son grandes: cambios quirúrgicos, nada de refactor.
- Nada probado aún en Studio real: todo validado con luau-lsp + pruebas Lune con mocks.

## COMPLETADO (este pase)
- Arreglos de la 3ª revisión (killcam final con la baja decisiva, cuerpo en 1ª persona, granada
  validada en servidor, linterna, terreno mojado).
- Estilo visual **Táctico** (GameConfig.VisualStyle = "Tactico", MapKit.tacticalize): luz limpia y
  legible en todos los mapas, color algo más vivo, brillo contenido, niebla limitada.
- Contorno rojo fino de enemigos (no atraviesa paredes) — GameConfig.EnemyOutline.
- Ultra: el desenfoque lejano solo afecta más allá de 250 studs (nunca a un enemigo en combate).
- ACE, resultado de ronda personal (GANADA/PERDIDA + mejor de la ronda), ¡REMONTADA!.
- HUD de combate limpio (retos/evento/tienda/racha solo cuando aportan), habilidades compactas en PC.
- Microanimaciones en todos los botones (UI.pressFeel).
- Nombres de zona (callouts) en el HUD.
- Cola de eco en los disparos, cámara más estable al apuntar, reacción al recibir daño.
- Presets Rendimiento/Equilibrada/Alta/Ultra con nombre.
- VISUAL_IMPROVEMENTS.md, PERFORMANCE_NOTES.md, NEXT_STEPS.md.
- Revisión de código del pase (9 hallazgos, todos arreglados) y batería completa: 110 pruebas + 10 modos OK.
- Asistencias en resumen y marcador, barras de estadísticas de armas, color de enemigo elegible,
  sitios de bomba con nombre, desbloqueos con presentación, aviso de baja adaptado al teléfono.
- Mapa 5v5 nuevo **Puesto del Desierto** (arena + turquesa) con SND probado con bots.
- Pool de sonidos 2D (armas aparte de la interfaz), luz de relleno del arma de noche.
- Justicia: en Cumbre y Base Militar el edificio central tiene una puerta para cada equipo.
- Cuatro revisiones de código del pase (la última, de integración de todo): sin fallos graves;
  todos los hallazgos arreglados (p. ej. el resultado de ronda ahora sale tras la killcam).
- Nombres de zona en 20 mapas (y automáticos en Downtown); Puesto del Desierto con molino de aspas y ventilador animados.

## EN PROGRESO
- Bucle de pulido (cambios pequeños y probados).

## PENDIENTE
- Ver NEXT_STEPS.md.

## DECISIONES TÉCNICAS
- No se reescribe nada que funcione: el estilo se cambia en un solo punto (MapKit.applyLighting).
- Mapas "diseñados" (Realistic = true) solo reciben límites de legibilidad, no un restyle.
- Contorno de enemigos con Highlight Occluded: legibilidad sin dar información a través de paredes.
