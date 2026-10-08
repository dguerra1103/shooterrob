# FASE 13 — Cierre técnico y validación del HUD móvil

Sin features nuevas y sin rediseño: cerrar la Fase 12 (`FASE_12_MOVIL.md`), arreglar solo fallos
técnicos confirmados y dejar listo **qué comprobar en Studio y en un teléfono**. No se ha tocado
asistencia de apuntado, retroceso, daño, cadencia, movimiento, salto, velocidad de correr ni dispersión.
**No se ha movido ningún botón por estética**: las distancias se ajustarán con tu feedback del móvil.

## 1. Estado exacto de las pruebas

| Momento | `tests/check.sh` | `tests/run_all.sh` (completo) |
|---|---|---|
| Fin de la Fase 12 (antes del arreglo de Movement) | sin errores | **149 OK, 1 fallo** (`movement`) |
| Commit `cd08415` (Fase 12 cerrada, antes de tocar nada en esta fase) | luau-lsp sin errores, rojo build OK | **150 OK, 0 fallos** |
| Tras los arreglos de esta fase (`cdc04b4`) | sin errores | **149 OK, 1 fallo** (`botbrain`, intermitente; ver fallo 8) |
| Tras arreglar la prueba `botbrain` (`cad1255`, estado final) | luau-lsp sin errores, rojo build OK | **150 OK, 0 fallos** |

## 2. Regresiones y fallos encontrados (auditoría del código, paso 2)

Revisados `MobileHUD`, `TouchLayout`, `Movement`, `WeaponController`, `HUD`, `ClientState`, `Settings`,
`HUDEditor` y la validación de ajustes del servidor, buscando solo nil, conexiones duplicadas, toques
sin liberar, botones pegados, estados tras reaparecer, ajustes inválidos, arranque y vuelta al lobby.

| # | Fallo | Cuándo pasaba | Gravedad |
|---|---|---|---|
| 1 | Un botón escondido con el dedo encima (menú, muerte) se soltaba, pero **la conexión de ese dedo seguía viva**: al levantarlo más tarde soltaba la pulsación de **otro dedo** sobre el mismo botón | menú o muerte con el dedo en disparar y volver a disparar enseguida | media (dejaba de disparar sin soltar) |
| 2 | Dos dedos sobre el mismo botón: el segundo volvía a «pulsar» y el primero, al soltar, cortaba la acción con el segundo aún encima | tocar disparar con dos dedos | baja |
| 3 | **Disparar + disparo izquierdo** a la vez: soltar uno cortaba el disparo del otro | con disparo izquierdo activado | media |
| 4 | Correr automático: si el `PlayerModule` de Roblox no estaba aún en el primer fotograma, **no se volvía a buscar nunca** → el correr automático no funcionaba en toda la sesión | arranque lento del cliente | alta (posible, no confirmada en motor) |
| 5 | Editor de HUD abierto al **volver al lobby / acabar la partida**: podía quedar debajo de otra pantalla con `HUDEditorOpen = true` → el juego bloqueado (no se podía disparar) | abrir el editor al final de una partida | alta |
| 6 | La depuración (`MobileHUDDebug`) se dibujaba una vez y no se actualizaba al recolocar | girar / cambiar de resolución en Studio | baja (solo Studio) |
| 7 | (de la Fase 12, ya arreglado y subido) `ClientState.Settings` nil en el primer fotograma del correr automático | arranque | alta |

| 8 | Prueba `botbrain` **intermitente** (no es del HUD; la escribí en la Fase 11): el bot recibe un arma al azar y, si le tocaba la **escopeta**, a 40 studs casi todos los perdigones fallan y no llegaban 3 aciertos en 10 s; con fusil también fallaba ~1 de 6 veces por la puntería aleatoria en ráfagas. El juego estaba bien (el bot disparaba: cargador 199 → 187) | 1 de cada ~4 ejecuciones | prueba (no juego) |

Comprobado y **sin fallo**: los ajustes guardados no pueden sacar controles de la pantalla (cliente y
servidor recortan X/Y a 0–1, tamaño a 60–160 %, opacidad a 25–100 %, descartan NaN/∞, controles
desconocidos y posiciones a medias; además `Resolve` mete el control entero dentro de la zona segura);
al morir o abrir un menú los botones se esconden y se sueltan (`IsBlocked` → `RefreshVisibility`); al
reaparecer, apuntar se reinicia (`WeaponController.onCharacter`) y el botón de apuntar se repinta desde
`ClientState.Aiming`; las conexiones de `TouchLayout` se crean una sola vez (`watching`) y las del
editor se desconectan al cerrarlo; el ajuste del servidor va con el resto de ajustes (sin DataStore
aparte) y con su límite de peticiones.

## 3. Correcciones (commit «Fase 13: arreglos técnicos…»)

1–2. **Cada botón es de un solo dedo** (`entry.Owner`): un segundo dedo encima no hace nada; al soltar
por menú/muerte se desconecta la escucha de ese dedo, así que un dedo viejo nunca suelta una pulsación
nueva.
3. **Gatillo compartido**: disparar y disparo izquierdo empiezan con el primer dedo y se sueltan con el
último.
4. Correr automático: el `PlayerModule` se reintenta cada segundo hasta encontrarlo.
5. Editor: **se cancela solo** (sin guardar y sin reabrir Ajustes) si se vuelve al lobby, empiezan los
resultados o mueres con él abierto.
6. Depuración: se redibuja en cada recolocación y enseña más datos (ver sección 5).
7. **Nombre del arma** (paso 3): ver la sección siguiente.

8. `botbrain`: esa fase de la prueba usa un fusil fijo y espera hasta 25 s (sale en cuanto hay 3
aciertos). **Lo que comprueba no cambia** (≥ 3 aciertos en la cabeza y 0 en el cuerpo). Verificado:
con la escopeta forzada falla siempre; con el fusil y 25 s, 8 de 8 ejecuciones bien.

Pruebas nuevas: dedos (segundo dedo, dedo viejo tras un menú), gatillo compartido, nombres cortos /
`ARX-27` / muy largos, y editor cerrado al volver al lobby.

## 4. Nombre del arma en la tarjeta

Antes: `TextScaled` (el texto se ajusta solo); el renderizador de capturas lo partía en dos líneas y no
estaba garantizado que el motor no lo hiciera.

Ahora: **nunca dos líneas** (`TextWrapped = false`, `TextScaled = false`). El texto se mide con
`TextService:GetTextSize` y se encoge desde 13 px (× el tamaño de la tarjeta) **hasta 11 px**; si aun
así no cabe, `TextTruncate.AtEnd` lo corta con «…». El «1/2» de la derecha ocupa solo lo que mide y
el nombre usa el resto. La tarjeta pasa de 128 a **136 px** de ancho (mismo borde derecho: crece hacia
la izquierda; sigue sin pisar nada en las 7 resoluciones). Se ven siempre **ARMA · «1/2»** arriba y
**CARGADOR / RESERVA** abajo en grande (`30 / 120`, rojo con pocas balas, azul recargando).

Nombres reales más largos: «Martillo de juguete» (19), «Phantom Sidewind» (16). En PHONE caben a
11–12 px o se cortan al final; en PHONE_SMALL (568×320) se cortarán («Phantom S…»). **Confirmar en
Studio** (el renderizador de capturas no hace el «…» ni mide como Roblox).

## 5. Modo de validación (`MobileHUDDebug`)

`GameConfig.MobileHUDDebug = false` por defecto. Solo se dibuja si está a `true` **y**
`RunService:IsStudio()`; un jugador nunca lo ve. Con él activado en Studio:

- verde: **zona segura** con su tamaño, el de la pantalla, el **tipo** (PHONE_SMALL / PHONE / TABLET) y
  los **insets** (lo que quitan la muesca y las barras);
- rojo: **centro que debe quedar libre** (mira, hitmarker, avisos de daño);
- azul: **zona de cámara** del pulgar derecho;
- amarillo: **zona táctil** de cada control visible con su **nombre, tamaño real en px y opacidad %**.

Se redibuja al girar, al cambiar de resolución, al aparecer el salto de Roblox y al cambiar la
disposición.

## 6. Matriz de resoluciones (Studio → Test → Device Emulator)

En cada fila, marcar cada columna. Activa `MobileHUDDebug` para ver las cajas.

| Resolución | Tipo esperado | Ningún botón fuera | Ningún solape | Minimapa | Marcador | Killfeed legible | Arma/munición | Vida | Centro libre | Salto Roblox libre | CoreGui libre | Menú (engranaje) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 568×320 | PHONE_SMALL | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 667×375 | PHONE | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 844×390 | PHONE | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 896×414 | PHONE | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 1024×768 | TABLET | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 1280×720 táctil | TABLET | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 1280×720 sin táctil | DESKTOP (sin botones) | — | — | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | — | ☐ | ☐ (tecla B) |
| 1920×1080 | DESKTOP | — | — | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | — | ☐ | ☐ (tecla B) |
| Preset del emulador con muesca (p. ej. un iPhone reciente) | PHONE | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Preset Android alargado (20:9) | PHONE | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Preset iPad | TABLET | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

«CoreGui libre»: nada nuestro encima del botón de Roblox, el chat ni las notificaciones (arriba a la
izquierda). «Tipo»: el que pone el recuadro verde de depuración. Las 7 primeras resoluciones están
comprobadas geométricamente por `phonefx`/`mobilehud` y el script de capturas (sin solapes, dentro de
la pantalla, sin pisar el salto ni el centro); falta verlas **en el motor**.

## 7. Checklist para Studio

1. `GameConfig.MobileHUDDebug = true` **solo en local** (no hacer commit), Play con el Device Emulator.
2. Recorrer la matriz de la sección 6 (girar el dispositivo en cada uno).
3. En 844×390: comprobar que el **nombre del arma** está en una línea con ARX-27, Phantom Sidewind y
   Martillo de juguete (sección 4) y que se ve «1/2» con dos armas.
4. Ajustes → Controles táctiles: cambiar **Correr** a «Con botón» (aparece el botón), **Disparo
   izquierdo** a «Sí» (aparece a la izquierda) y **Disparar** a «Solo tocar» y volver.
5. Pasar la checklist del editor (sección 10) con el ratón.
6. Output: **sin errores** rojos de `TouchLayout`, `HUD`, `HUDEditor`, `Movement`, `Abilities`.
7. Volver a poner `MobileHUDDebug = false`.

## 8. Checklist para tu teléfono (Roblox app, partida real)

Para cada caso: hazlo 3 veces y apunta ✔ / ✘ y qué pasó.

| # | Caso | Cómo | Qué tiene que pasar |
|---|---|---|---|
| 1 | Joystick + cámara | Pulgar izquierdo mueve, pulgar derecho gira en el lado derecho (fuera de botones) | Se mueve y gira a la vez, sin saltos |
| 2 | Mover + girar + disparar | Pulgar derecho **empieza en DISPARAR** y se arrastra | Dispara mientras gira con el mismo dedo |
| 3 | Mover + ADS + disparar | Toca APUNTAR (queda amarillo), luego dispara arrastrando | Apunta sin soltar; granada/cuchillo/habilidades se ven más tenues; correr se para al apuntar |
| 4 | Mover + saltar + girar + disparar | Tres dedos: joystick, SALTO de Roblox, disparar arrastrando | Salta y dispara a la vez; ningún botón se queda pulsado |
| 5 | Subfusil | Joystick a fondo (corre solo) + salto + disparo | Corre sin botón, salta y dispara; al disparar deja de correr un momento |
| 6 | Escopeta | Toques rápidos en DISPARAR | Cada toque, un disparo; la cámara no da tirones |
| 7 | Francotirador | APUNTAR → máscara a pantalla completa (sin franja en la muesca) → disparar → APUNTAR otra vez | Disparar y apuntar siguen accesibles con la mira puesta; al quitarla vuelve todo |
| 8 | Recargar moviéndote | Gastar el cargador: RECARGAR en rojo y algo más grande (sin parpadeo); tocarlo corriendo | La tarjeta dice «RECARGANDO…» y luego la munición |
| 9 | Granada | Mantener GRANADA (sale la mecha en el globo), soltar | Se lanza al soltar; luego el velo de recarga baja con los segundos |
| 10 | Cuerpo a cuerpo | Tocar el CUCHILLO | Ataca; no se pulsa sin querer al girar la cámara |
| 11 | Cambiar arma | Tocar la TARJETA del arma | Cambian nombre, munición y «1/2» |
| 12 | Morir disparando | Mantener DISPARAR hasta morir | Al morir deja de disparar; los botones desaparecen |
| 13 | Reaparecer | Volver a la partida | Botones de vuelta; APUNTAR no se queda amarillo; nada pulsado solo |
| 14 | Menú con dedo encima | Mantener DISPARAR y con otro dedo tocar el ENGRANAJE | El menú se abre, deja de disparar; al cerrarlo y volver a disparar funciona normal |
| 15 | Lobby y otra partida | Acabar la partida, volver al lobby, empezar otra | Todo igual que en la primera; tu disposición del editor se mantiene |

## 9. Checklist multitáctil (lo más delicado)

| Prueba | ✔/✘ |
|---|---|
| Dedo 1 joystick + dedo 2 cámara + dedo 3 DISPARAR (botón) | ☐ |
| Dedo 1 joystick + dedo 2 DISPARAR arrastrando (gira) + dedo 3 SALTO | ☐ |
| Dos dedos sobre DISPARAR: el botón es del primer dedo; poner y quitar el segundo no corta ni repite el disparo | ☐ |
| Disparo izquierdo activado: mantener los dos disparos, soltar uno → sigue disparando; soltar el otro → para | ☐ |
| Un dedo que empieza en la cámara y pasa por encima de un botón **no** lo pulsa | ☐ |
| Ningún botón deja la cámara «muerta» después de soltarlo | ☐ |
| Morir / abrir menú / reaparecer con dedos encima: nada se queda pulsado ni disparando | ☐ |

## 10. Checklist del editor de HUD

Ajustes → 🎮 Controles táctiles → PERSONALIZAR HUD.

| Paso | ✔/✘ |
|---|---|
| Mover DISPARAR | ☐ |
| Mover APUNTAR | ☐ |
| Cambiar TAMAÑO (entre 60 % y 160 %) | ☐ |
| Cambiar OPACIDAD (entre 25 % y 100 %) | ☐ |
| Pasar el panel ABAJO/ARRIBA para llegar a lo que tapa | ☐ |
| GUARDAR → vuelve a Ajustes; en partida, los botones donde los dejaste | ☐ |
| Cerrar y volver a abrir el editor: sigue igual | ☐ |
| Morir: sigue igual | ☐ |
| Nueva partida: sigue igual | ☐ |
| Salir del juego y volver a entrar: sigue igual (se guarda con tu perfil) | ☐ |
| RESTABLECER + GUARDAR → vuelve lo de fábrica | ☐ |
| Mover algo y CANCELAR → nada cambia | ☐ |
| Intentar sacar un control de la pantalla: no se puede (se queda en el borde) | ☐ |
| Con el editor abierto, acabar la partida o volver al lobby: el editor se cierra solo y el juego no se queda bloqueado | ☐ |

## 11. Ergonomía (solo con tu feedback real)

Lune **no** prueba ergonomía. Tras jugar, marca una columna y propón el cambio:

| Control | Fácil | Aceptable | Incómodo | Cambio propuesto |
|---|---|---|---|---|
| Disparo | ☐ | ☐ | ☐ | |
| ADS (apuntar) | ☐ | ☐ | ☐ | |
| Salto (Roblox) | ☐ | ☐ | ☐ | |
| Agacharse | ☐ | ☐ | ☐ | |
| Recargar | ☐ | ☐ | ☐ | |
| Granada | ☐ | ☐ | ☐ | |
| Melee | ☐ | ☐ | ☐ | |
| Cambio de arma (tarjeta) | ☐ | ☐ | ☐ | |
| Habilidades (izquierda) | ☐ | ☐ | ☐ | |
| Menú / marcador / emotes / grafiti | ☐ | ☐ | ☐ | |

## 12. Lo que no se puede verificar sin dispositivo

- Comodidad de los pulgares, tamaño real en mm de los botones y pulsaciones accidentales.
- Que `TextService` mida como se espera y el «…» del nombre del arma (el renderizador no lo hace).
- Que el `PlayerModule` de tu versión de Roblox devuelva `GetMoveVector` con el empuje real (correr
  automático) y a qué empuje se siente natural (ahora 0,9).
- Posición real de los `DeviceSafeInsets` en tu modelo (muesca, Dynamic Island, agujero de cámara).
- Rendimiento en tu móvil (FPS en un tiroteo con bots).
- El orden real de los toques procesados entre los controles de Roblox y los nuestros.

## 13. Lo que necesito que me mandes

1. **Modelo del teléfono** y si juegas en horizontal (resolución si la sabes).
2. **Capturas** de: partida normal, apuntando con francotirador, menú abierto, editor abierto.
3. La tabla de **ergonomía** (sección 11) rellena.
4. Los casos de la sección 8 y 9 que salgan ✘, con lo que pasó.
5. Si algún botón **se pulsa sin querer** al girar la cámara: cuál y desde dónde.
6. Si el **correr automático** se activa demasiado pronto o demasiado tarde.
7. Si el **nombre del arma** sale cortado con alguna arma en concreto.
8. Cualquier **error rojo** de la consola de Roblox (en el móvil: escribe `/console` en el chat → Log).

## Resultado final

Sobre el código final (`cad1255`): `tests/check.sh` → rojo build OK, **luau-lsp sin errores**;
`tests/run_all.sh` completo → **150 OK, 0 fallos**. (Después de esa batería solo se ha cambiado este
documento.)

**Fin de la fase.** No se moverá ningún botón ni se cambiará el diseño hasta tener tu feedback del
teléfono (sección 13).
