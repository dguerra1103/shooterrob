# DEVELOPMENT_PROGRESS

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

## EN PROGRESO
- Feedback de combate (Fases 2-3).

## PENDIENTE
- Fase 5 UI/UX, Fase 7 rendimiento, docs finales (VISUAL_IMPROVEMENTS, PERFORMANCE_NOTES, NEXT_STEPS).

## DECISIONES TÉCNICAS
- No se reescribe nada que funcione: el estilo se cambia en un solo punto (MapKit.applyLighting).
- Mapas "diseñados" (Realistic = true) solo reciben límites de legibilidad, no un restyle.
- Contorno de enemigos con Highlight Occluded: legibilidad sin dar información a través de paredes.
