# Sesión de pulido final (móvil primero)

Rama `claude/intelligent-fermi-cz7und`, desde `c952627` (Fase 16 subida y publicada a mano por el
usuario). Sin Studio ni teléfono en esta sesión: todo se ha comprobado con el simulador (Lune + mock),
`luau-lsp` y el renderizador de interfaz. **Nada de esto está validado en Studio ni en el Galaxy S26
Ultra real, ni en una partida multijugador real.** No se ha publicado.

Reglas que se han respetado: sin cambios de daño, cadencia, dispersión, retroceso, asistencia de
apuntado, economía, monetización, pase, armas, mapas ni bots; ProductIds en 0; UniverseId y PlaceId
sin tocar; QA y depuración apagados; nada nuevo (ni modos, ni mapas, ni armas, ni sistemas).

## 1. Estado inicial

- HUD táctil de la Fase 16: 0 solapes de dibujo y de toque en la disposición por defecto, zonas
  reservadas (`HUDZones`) para lo que aparece en partida, editor con validación, batería 152 OK.
- El usuario indicó que en el teléfono «todavía quedan problemas» sin detallar cuáles; no había
  capturas nuevas del S26. Se auditó todo con el perfil del S26 (892x412 lógico, 19,5:9, zonas seguras
  simuladas: cámara a la izquierda 32 px y barra de Roblox 58 px).
- No existe `FASE_17_REDISENO_VISUAL_HUD.md` (no se inventa).

## 2. Auditoría móvil (qué se miró)

Renders del HUD en S26, 568x320, 1024x768 y 1180x820, en normal, combate intenso por modo, ADS,
francotirador, cargador vacío, editor y depuración; renders de los menús con la zona segura del S26
(antes los menús se renderizaban sin zona segura: no se veía su fallo). Código de `TouchLayout`,
`HUD`, `HUDZones`, `HUDEditor`, `Movement`, `GrenadeController`, `RewardFX`, `QuestTracker`,
`DeathScreen`, `Tutorial`, `Flow/Components` y los ~55 bucles por fotograma del cliente.

Lo que se veía de prototipo o estaba mal:
1. 12-15 círculos casi iguales: la tira de poco uso y las habilidades llevaban cada una su círculo con
   borde.
2. Emojis a color en el HUD de partida (📡 RADAR, 💣 BOMBA, 📍 zona, 🚩, 🔥, 💰, ✈ en la racha, 💡 en
   los consejos), además de un aviso de granada con 💣.
3. El aviso grande (racha, ACE, «1 contra 3», «te buscan») ocupaba el 92 % del ancho arriba, por encima
   del aviso de baja, las medallas y el registro de bajas, y no estaba en ninguna zona.
4. La vida táctil en verde, fuera de la paleta del HUD.
5. Los fallos reales de la sección 12.

## 3. HUD

- **Tiras**: la de poco uso (menú, marcador, emotes, grafiti) y la de habilidades (impulso, supersalto,
  poción) se dibujan como una sola pieza: un fondo grafito con borde muy fino y solo los iconos encima.
  Pulsado, apuntando, en recarga o con aviso se sigue viendo en cada botón. La tira es la fila seguida
  más larga: si el jugador saca un botón en el editor, ese vuelve a llevar su fondo y los demás siguen
  juntos. En el editor cada botón lleva su fondo (se mueven sueltos). Apuntando, las tiras se aclaran.
- **Vida**: «100» + barra fina blanca; amarilla por debajo del 35 %, roja por debajo del 20 %; el daño
  recibido se ve en rojo detrás. La cruz es gris claro (sin verde).
- **Sin emojis en táctil** (`UI.HudText`/`UI.StripEmoji`): avisos, banners, bomba, radar, nombre de zona,
  consejos («Toca APUNTAR…», «Toca RECARGAR…»), estado de la bandera, infección, racha («radar en 2»,
  «ataque aéreo en 1»). El aviso de granada lleva el icono dibujado (el mismo que el botón). En PC y
  mando no cambia nada. Los menús (monedas, candados) y los efectos de baja comprados conservan sus
  iconos: no son el HUD de partida.
- **Aviso grande** en la zona de arriba (`HUDZones`, orden -2), 360x32 como mucho, texto hasta 26 px y
  sin rebote; solo ocupa sitio mientras se lee. Su línea de debajo (resultado de la ronda) igual.
- **Avisos pequeños** («+50 XP», asistencia): pulso corto sin rebote en táctil.
- **«+300» de la baja**: el HUD busca un hueco junto a la mira, justo fuera del centro libre, que no
  pise ni un botón ni el registro de bajas; si a la derecha no hay (568x320), a la izquierda.
- **Panel de retos**: no sale en táctil durante la partida (tampoco en tableta), y fija su estado desde
  el principio.
- Sin cambios en la geometría de los botones (`shared/MobileHUD.luau` igual que en la Fase 16).

Métricas (diagnóstico, `MobileHUD.Metrics`/`Collisions`; la geometría no ha cambiado):

| Pantalla | Controles | Cubierto | Centro libre | Zona de cámara | Solapes dibujo | Solapes toque |
|---|---|---|---|---|---|---|
| 568x320 | 15 | 11,7 % | 5,1 % | 14,1 % | 0 | 0 |
| 667x375 | 15 | 11,7 % | 5,1 % | 14,3 % | 0 | 0 |
| 844x390 | 15 | 9,6 % | 4,2 % | 14,7 % | 0 | 0 |
| 892x412 (S26) | 15 | 9,6 % | 4,2 % | 14,7 % | 0 | 0 |
| 1024x768 | 15 | 6,3 % | 6,8 % | 24,2 % | 0 | 0 |

Lo que sí cambia es el número de piezas que se ven: 7 botones (4 de poco uso + 3 habilidades) pasan a
ser 2 tiras.

## 4. Multitouch

- **Correr con botón** (AutoSprint apagado) es de pulsar y soltar: quedaba puesto de la vida anterior y
  al reaparecer se seguía corriendo. Ahora se apaga al reaparecer y al perder el foco.
- **Correr y agacharse** se ven en amarillo mientras están puestos (antes no había forma de saberlo).
- Se mantiene de la Fase 16: un dedo por botón, todo se suelta al morir, reaparecer, abrir un menú y
  acabar la partida; sin botones duplicados en 5 partidas seguidas.

## 5. Multijugador (simulado)

`hudstress` (10 jugadores en el mock, 20 bajas, medallas, XP, aviso, racha, radar, estamina, vida 30)
en los 10 modos, más: aviso grande en plena pelea, HUD táctil sin emojis visibles, correr/agacharse al
reaparecer, menús dentro de la zona segura y editor con todos los controles a la vista tras varios
fotogramas. No es una partida real con 10 personas.

## 6. Menús

- **Fallo real (S26)**: la raíz del flujo (`Flow/Components.root`) medía la pantalla entera aunque su
  ScreenGui va con la zona segura (`CoreUISafeInsets`: cámara + barra de Roblox). En el S26 lo de abajo y
  lo de la derecha se salía: la barra de clases del armamento quedaba fuera y las estadísticas cortadas.
  Ahora mide lo que mide la ScreenGui y se recoloca si cambia. Afecta a inicio, armamento, operador,
  tienda, pase, escuadra, despliegue y revelado. Los textos quedan algo más pequeños en el S26 (la
  altura útil es 354 en vez de 412) pero todo cabe.
- **Observar al morir**: en táctil no había forma de cambiar de jugador (el texto decía «haz clic»;
  tocar solo salta la killcam). Dos flechas junto a DEJAR DE OBSERVAR.
- **Tarjeta de controles** para jugadores nuevos: describe la disposición actual (habilidades encima del
  joystick, tarjeta del arma, tira de arriba a la derecha).
- Tienda: comprar ya pasa por CONFIRMAR COMPRA (sin compras accidentales). Resultados: la jerarquía
  (victoria, puntos, MVP, recompensas, jugar de nuevo) ya era la pedida; el marcador completo va aparte.

## 7. Rendimiento

Ver `PERFORMANCE_NOTES.md`. Los ~55 bucles por fotograma del cliente ya salían pronto, iban con freno
o solo escribían al cambiar. Cambios: radar (texto y visibilidad solo al cambiar), granada (ya no
escribe la visibilidad de su botón en cada fotograma), `UI.HudText` con caché. No hay cifras de FPS:
hay que medir en el teléfono (sección 18).

## 8. Gameplay

Revisado sin cambios: el campo de visión se recalcula en cada fotograma desde el ajuste (no se queda
con el de un menú o la killcam), la inspección se cancela al disparar, recargar, apuntar o correr, y las
17 armas de fuego tienen todas sus estadísticas (ninguna falta). Sin cambios de balance.

## 9. UI general

Desenfoque del menú: se reutiliza uno solo y se destruye al llegar a 0 (no se queda puesto). Lo demás
de esta sesión en UI está en las secciones 3 y 6.

## 10. Mapas

No se tocaron. El renderizador no representa bien la luz ni los materiales de Roblox y no se encontró
ningún fallo de estructura o de rendimiento claro; cambiar color o luz a ciegas está prohibido.

## 11. Bots

No se tocaron: sus pruebas (`bots`, `botbrain`, `flagbots`, `gunbots`, `infection_bots`, `botspots`,
`botsteps`) pasan y no se encontró ningún fallo claro.

## 12. Fallos encontrados

1. Menús fuera de la zona segura en el S26 (barra de clases y estadísticas del armamento cortadas).
2. Correr con botón seguía puesto al reaparecer.
3. Con el editor de HUD abierto, la granada desaparecía (GrenadeController escribía su visibilidad
   con «bloqueado» en cada fotograma, y el editor cuenta como bloqueado).
4. El panel del editor tapaba el disparo izquierdo y no se podía coger; el nombre de un control pisaba
   la línea de estado del panel.
5. El «+300» caía encima del registro de bajas en teléfonos pequeños.
6. En táctil no se podía cambiar a quién observar (y el texto decía «haz clic»).
7. El panel de retos podía salir en táctil durante la partida (tableta, o si el tamaño de pantalla aún
   no era el definitivo al arrancar).
8. El aviso grande cruzaba la pantalla por encima del aviso de baja, las medallas y el registro.
9. Correr y agacharse (de pulsar y soltar) no enseñaban si estaban puestos.
10. Consejos táctiles y tarjeta de controles desfasados respecto a la disposición actual.

## 13. Fallos corregidos

Todos los de la sección 12. Los 1, 2 y 3 tienen una prueba que falla con el código anterior y pasa con
el nuevo (comprobado). Un cambio que resultó innecesario (dar `DeviceSafeInsets` al menú de partida: en
Roblox `IgnoreGuiInset = true` ya equivale a eso) se revirtió en su propio commit.

## 14. Pruebas

Nuevas o ampliadas:
- `hudstress`: aviso grande en plena pelea en su zona; ningún emoji visible en el HUD táctil; correr y
  agacharse se ven puestos y no siguen al reaparecer; menús dentro de la zona segura del S26; con el
  editor abierto se ven todos los controles tras varios fotogramas.
- `touchbtns`: tira de poco uso como una pieza; un botón separado vuelve a su fondo y la tira sigue con
  los demás; restablecer y editor.
- `hudeditor`: el panel no deja ningún control debajo (cambia de lado al elegir uno que tapa).

Resultado de la batería: ver «Resultado final».

## 15. Commits

Ver el informe final y `git log c952627..HEAD`.

## 16. Riesgos

- Todo está comprobado en simulación. En el S26 real pueden cambiar las zonas seguras que da Roblox
  (alto de la barra, lado de la cámara) y el tamaño real de las letras.
- Los menús en el S26 se ven algo más pequeños que antes (caben enteros, pero hay menos altura útil).
- Quitar los emojis depende de una lista de rangos Unicode: un símbolo nuevo fuera de esos rangos se
  vería; la prueba de `hudstress` lo detectaría en los avisos que simula.
- **Dos pruebas de servidor al límite (anteriores a esta sesión)**: en la primera batería completa
  fallaron `rounds` («deberían jugarse varias rondas») y `bomb` («los defensores protegen los sitios
  2/5»). Ninguna toca código de esta sesión (cero cambios en `src/server`, `src/shared`, `src/first`).
  Medido, 4 veces cada una con el código nuevo y con el del inicio de la sesión (`c952627`): `rounds`
  juega 5-7 rondas en una ventana fija de ~40 s de reloj y pide 5 (salió justo 5 en una de cada
  versión); `bomb` depende de a qué sitio decide ir cada bot defensor (4-5 de 5, pide 3). Pasan solas y
  en las 16 repeticiones; la batería se repitió entera. No se han tocado (no se debilitan pruebas sin
  más); quedan como siguiente paso: darles margen de tiempo o fijar la semilla de los bots.
- El aviso grande puede quedar apartado unos segundos si la zona de arriba está llena (prioridad para
  él; lo que no cabe se aparta, no se monta encima).

## 17. Pendiente de Studio

1. Abrir el editor de HUD en el Device Emulator y comprobar que la granada se ve y se mueve.
2. Morir con correr puesto (AutoSprint apagado) y reaparecer: no se corre solo.
3. Recorrer inicio, armamento, tienda y pase con el emulador de un teléfono con muesca: nada cortado.
4. Ver una racha de 5 y un ACE en táctil: el aviso arriba, pequeño, sin tapar el registro.

## 18. Pendiente del S26 Ultra real

1. Partida 5v5 completa: ¿algún toque cae en el botón equivocado? ¿Se gira y se hace flick sin chocar
   con botones?
2. Arriba a la derecha y encima del joystick deben verse dos tiras (no círculos sueltos).
3. Ningún emoji durante la partida (bomba, radar, nombre de zona, consejos, racha).
4. Armamento: la barra de las 5 clases abajo debe verse entera; las estadísticas, enteras a la derecha.
5. Inicio, tienda y pase: nada cortado abajo ni a la derecha; ¿se lee bien el texto (algo más pequeño)?
6. Ajustes → correr con botón: pulsarlo (se pone amarillo), morir, reaparecer: no se corre solo.
7. Editor de HUD con el disparo izquierdo puesto: el panel no tapa ningún botón; la granada se ve.
8. Muerto y observando: las flechas cambian de jugador.
9. Varias bajas seguidas: el «+300» junto a la mira, sin tapar el registro de bajas.
10. Medir con el MicroProfiler: FPS en un tiroteo 5v5 en Construction y Coastal (Auto y Alta), memoria
    tras 5 partidas seguidas y temperatura a los 10-15 minutos.
