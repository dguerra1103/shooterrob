# FASE 6 — Bots y primeras partidas

> **Sin Roblox Studio.** Los bots se revisaron leyendo el código (`Bots.luau`, `GameConfig.Bots`) y con
> las pruebas que ya había (`botspots`, `navcheck`, `sndround_*`, `smoke`). Los consejos nuevos tienen
> su prueba. Cómo se juega contra los bots y cómo se leen los consejos hay que verlo en Studio.

## A. Bots: auditoría

Qué hacen los bots y si cumplen las reglas del encargo (nada de puntería perfecta, ver a través de las
paredes, saberlo todo al instante, reacción de 0 ms ni todo a la cabeza).

| Regla | Cómo está | ¿Cumple? |
|---|---|---|
| Sin ver a través de las paredes | Para elegir objetivo y para disparar hace falta un rayo libre de cabeza a cabeza (`canSee`). | Sí |
| Sin saberlo todo | Solo se fijan en lo que tienen delante (cono de 140°), en quien está a menos de 14 studs (lo «notan»), en quien les acaba de disparar y en lo que oyen (disparos a 110 studs; 25 con silenciador). Por la espalda se les puede flanquear. | Sí |
| Sin reacción de 0 ms | 0,45 s de base, distinta en cada bot: entre 0,31 y 0,71 s. Contra un objetivo nuevo, los primeros tiros fallan más: la puntería tarda 0,9 s en asentarse. | Sí |
| Sin puntería perfecta | Acierto 55 % de cerca × habilidad (como mucho 95 %), que baja con la distancia (menos con fusiles de precisión), andando (×0,8) y si el objetivo corre (×0,7). | Sí |
| Sin todo a la cabeza | 12 % × habilidad (≈ 9-18 %). | Sí |
| Daño | 55 % del de un jugador (`DamageScale`). Con los rangos bajos son más blandos (`SkillByRank`: de 0,75 en Bronce a 1,3 en Campeón). | Sí |

**Dificultad:** ya es configurable y sencilla, en `GameConfig.Bots`: `Accuracy`, `AccuracyFalloff`,
`Reaction`, `DamageScale` y `SkillByRank`. **No se ha añadido nada.**

**Cambios en los bots: ninguno.** No se ha encontrado ningún problema claro. Tocar la puntería o la
reacción sin probarlo en Studio sería cambiar el equilibrio a ciegas.

## B. Primeras partidas: lo que había

- Tarjeta de controles la primera vez que entras en partida (`Tutorial`), adaptada a PC o a móvil. Se
  cierra con el botón, a los 20 s, al morir o al volver al menú. El servidor guarda `TutorialDone`.
- El objetivo de cada modo ya sale en la cuenta atrás antes de jugar («Captura y defiende las
  banderas», «Planta o desactiva la bomba»…, pantalla `Deploy`).
- No había ninguna ayuda durante la partida.
- En PC, la tarjeta no decía cómo cambiar de arma. **Arreglado:** la fila del cuchillo y la granada pasa
  a «1 2 3 o rueda: cambiar arma · R recargar · F golpe · G granada». En el móvil ya salía.

Con esto, lo que pide el encargo queda cubierto: moverse, disparar, apuntar, recargar y cambiar de arma
en la tarjeta; el objetivo en la cuenta atrás; y apuntar, recargar y cubrirse, con consejos en el
momento.

## C. Consejos de contexto (nuevo: `Hints.luau`)

Una línea discreta (💡) en partida cuando un jugador nuevo hace algo que un consejo arregla. Hay tres:

| Consejo | Cuándo sale |
|---|---|
| **Apuntar** («Mantén el clic derecho para apuntar…» / en el móvil, «Toca 🎯 para apuntar…») | 8 disparos a la cadera en 4 s sin acertar ninguno, con fusil, subfusil o pistola (con escopeta o francotirador, no). |
| **Recargar antes** («Pulsa R para recargar…» / en el móvil, «Toca 🔄 para recargar…») | Cuando vacías el cargador y la recarga empieza sola. |
| **Cubrirse** («Ponte a cubierto: si no te dan, la vida se recupera sola») | Con menos del 35 % de vida, y solo si la vida se recupera en ese modo (`HealthRegen`). |

**Límites (para que no sean 20 ventanas):**
- solo hasta el nivel 5 (`Hints.MaxLevel`);
- cada consejo, como mucho una vez por sesión;
- al menos 60 s entre dos consejos;
- 5 s en pantalla;
- nunca con un menú, la pantalla de muerte, la killcam, los resultados o la tarjeta de controles
  encima;
- no bloquea nada: ni suelta el ratón, ni para el juego, ni hay que pulsar nada.

**Sin cambios de datos:** no se guarda nada (ni migraciones ni campos nuevos). Por eso un jugador
nuevo puede volver a ver un consejo en otra sesión, mientras siga en nivel 5 o menos.

**Dónde sale:**
- escritorio: centrado, justo encima del aviso corto del HUD;
- teléfono: centrado, por debajo de la mira, lejos de los botones táctiles.

## D. Pruebas

`hints` (nueva):
- el consejo de apuntar sale con la ráfaga a la cadera, y no sale apuntando, con escopeta ni si
  aciertas;
- el de recargar sale solo con el cargador vacío;
- el de cubrirse sale con poca vida;
- cada consejo sale una vez y respeta el espacio entre consejos;
- ningún consejo con la muerte, un menú, la killcam, los resultados o el menú principal;
- ninguno por encima del nivel 5;
- no cambia los datos del jugador.

## E. Pendiente en Studio

1. Una partida con una cuenta nueva (nivel 1):
   - disparar a la cadera de lejos → sale el consejo de apuntar;
   - vaciar el cargador → sale el de recargar;
   - bajar de 35 de vida → sale el de cubrirse;
   - comprobar que no salen seguidos ni se repiten.
2. Que la línea no pise nada del HUD en PC, tablet y teléfono. En las capturas del simulador no pisa
   nada: en PC, encima de las habilidades; en el teléfono, entre la mira y las habilidades. Falta
   comprobarlo con el arma en la mano y la munición en pantalla.
3. La tarjeta de controles en PC con la fila nueva (que quepa en dos líneas).
4. Contra los bots, en Bronce y en Oro: que se sienta justo (que no maten al instante y que fallen al
   principio de cada pelea).

## F. No hecho (a propósito)

- Ningún cambio de puntería, reacción ni daño de los bots.
- Ningún tutorial nuevo ni ventanas que paren el juego.
- Sin guardar qué consejos ha visto cada jugador (habría que cambiar los datos guardados).
