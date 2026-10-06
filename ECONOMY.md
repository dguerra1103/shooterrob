# Economía y monetización (sin pay-to-win)

Este documento explica cómo gana dinero el juego **sin romper la competición**: qué se vende, qué no,
cuánto cuesta, de dónde salen y adónde van las monedas, cómo funciona el pase, cómo se protegen las
compras y qué se mide. Todo está implementado; aquí se cuenta y se dice dónde se cambia.

## 1. Principios

- **Nada que se compra da ventaja.** Ni daño, ni vida, ni retroceso, ni velocidad, ni estadísticas, ni
  armas antes de tiempo. Con Robux se compra **estilo, colección y presentación**.
- **Un jugador que no paga puede jugarlo todo**, subir de nivel, desbloquear todas las armas y ganar.
- **Sin azar de pago.** No hay cajas, ruletas ni sobres que se paguen (ni directa ni indirectamente).
- **Sin trucos.** Precios siempre a la vista, relojes que cuentan hasta una hora real, ninguna oferta
  "solo hoy" falsa, ninguna ventana que salte sola, botones claros y confirmación en las compras.
- **El servidor decide.** El cliente solo pide; el servidor entrega cuando Roblox confirma el pago.

## 2. Lo que había y lo que ha cambiado

| Había | Problema | Ahora |
|---|---|---|
| Packs de "revivir instantáneo" con Robux (vuelves donde caíste) | Ventaja en combate pagando | No se venden (`Rules.SellRevives = false`). Los revivir se ganan jugando (regalos por tiempo jugado). La pantalla de muerte ya no abre la compra. |
| Ruleta diaria con giros de pago y premio "gordo" | Azar de pago y estética de casino | Apagada (`Rules.Wheel`, `Rules.PaidWheelSpins`). El premio diario y las misiones la sustituyen. |
| Cajas que se abrían con monedas | Las monedas se venden con Robux: azar de pago indirecto | Solo se abren las cajas ganadas jugando (`Rules.CoinCrates = false`). Las probabilidades siguen a la vista. Las cajas no dan objetos de Robux. |
| El VIP daba una caja diaria extra y el doble de cajas sorpresa | Azar ligado a un pase de pago | El VIP da +100 🪙 al día en vez de la caja; las cajas sorpresa, igual para todos (`Rules.VIPCrates = false`). |
| Armas que se podían comprar con monedas antes de su nivel | Pagar (monedas compradas) para tener armas antes | Las armas se desbloquean solo por nivel (`Rules.WeaponsForCoins = false`). |
| Pase de batalla atado al nivel de cuenta y con cajas | No se podía reclamar, no había temporadas y las cajas eran azar comprable con niveles | Pase por temporadas con su propia XP, recompensas que se reclaman y sin cajas. |
| Packs con "vale X monedas" escrito a mano | Valor no comprobable | El valor se calcula con los precios reales de la tienda; si no se puede calcular, no se enseña. |
| Etiquetas "MÁS VENDIDO" / "MEJOR VALOR" | Afirmaciones no comprobables | Etiquetas con la cuenta real (+19 %, +48 %, +75 % de monedas por Robux frente al pack pequeño). |
| "¡ÚLTIMO DÍA!" en los packs de temporada | Presión | "a la venta N días más" (las fechas son reales, sin dramatizar). |

Se ha mantenido lo que funcionaba: monedas, packs de monedas, VIP (x2 XP y monedas de cuenta), Roblox
Premium, potenciadores de XP/monedas, pack de inicio, packs de temporada, ofertas del día, maestría,
recompensa diaria, misiones, rangos, eventos y el registro de compras idempotente (ampliado).

## 3. Monedas: fuentes y sumideros

Hay **una** moneda gratis: las monedas 🪙 (créditos). Se ganan jugando y también se pueden comprar con
Robux (para ir más rápido a la estética, no a la ventaja). No existe otra moneda premium: lo de pago se
paga directamente en Robux.

**Fuentes** (números de `GameConfig.Coins`, `Shop.DailyRewards`, `Challenges`, pase):

| Fuente | Cantidad |
|---|---|
| Partida | 5 por baja, 2 por asistencia, 20 por captura, 50 por victoria (+10 por victoria seguida, máx. +50) |
| Primera victoria del día | 150 |
| Recompensa diaria (7 días) | 100 → 800 (media 314) |
| Misiones diarias (3) | ~230 cada una |
| Misiones semanales (3) | ~880 cada una |
| Pase, vía gratis | 8.615 en toda la temporada |
| Maestría, rangos, logros, grupo, invitaciones, regreso | puntuales |

Estimación diaria:

- **Jugador muy activo** (6 partidas, todas las misiones): ~2.100 🪙/día.
- **Jugador ocasional** (2 partidas, el premio diario y una misión): ~860 🪙/día.

**Sumideros**: 86 cosméticos con monedas por un total de **117.700 🪙** (skins 40.600, trajes 22.900,
efectos 20.300, títulos 19.000, grafitis 5.900, colgantes 4.900, tarjetas 1.600, poses 1.300, intros
1.200). Al ritmo de arriba, comprarlo todo lleva unos 2 meses jugando mucho y unos 4-5 meses jugando
poco: hay metas largas sin grind absurdo.

**Control de la inflación**: las monedas solo compran estética (no hay nada de poder que se encarezca),
el catálogo con monedas crece cada temporada (nuevo sumidero) y los premios son fijos (no escalan con el
nivel). Si hiciera falta, los mandos son `GameConfig.Coins`, `Shop.DailyRewards` y las monedas de
`Challenges`.

## 4. Precios en Robux

Todos los productos están en `src/shared/Economy/Products.luau` (objetos sueltos, nivel del pase) y
`src/shared/Shop.luau` (monedas, potenciadores, pack de inicio, packs, VIP). **Ninguno tiene id: todos
están a `ProductId = 0` con `-- TODO: SET IN CREATOR DASHBOARD`.** Con 0 la tienda enseña
"PRÓXIMAMENTE" y no deja comprar. Cuando el id existe, la tienda pide el precio de verdad a
`MarketplaceService:GetProductInfo` y enseña ese.

| Tramo | Precio | Qué |
|---|---|---|
| Colgantes, tarjetas | 29-49 R$ | Chapa 29, Bala 39, Calavera roja 49, Glaciar 39, Infierno 49, Oro real 49, Vacío 49 |
| Efectos, poses, intros de MVP | 59-99 R$ | Píxel 79, Destello dorado 99, Choque rojo 99, Saludo 79, Brazos cruzados 79, Señala al frente 99, Lluvia de ascuas 89, Columna de luz 99 |
| Skins y trajes | 129-199 R$ | Skins: Ártico táctico 129, Callejero 129, Ciber 149, Inferno 179, Operación Roja 179, Grieta del vacío 199. Trajes: Ártico táctico 149, Operación Roja 199 |
| Packs | 249-399 R$ | Pack Ártico 249 (por separado 346, -28 %), Pack del Vacío 299 (396, -24 %), Pack Operación Roja 399 (625, -36 %) |
| Pase premium | 399 R$ | Temporada 1 |
| Otros | — | Pack de inicio 99, nivel del pase 49, monedas 49/99/199/449, potenciadores 49/69, VIP 299 (Game Pass), packs de temporada 199/199/299 |

**Familias de skins originales** (colecciones propias, no copiadas de otros juegos): INFERNO (llamas),
CYBER (neón que late), ARCTIC (camuflaje de nieve), STREET (colores de grafiti), VOID (cristal oscuro
con destellos) y RED OPS (negro y rojo). Cambian material, colores, detalles, el fogonazo cosmético y la
vuelta de inspección; **nunca** la forma (la caja de impacto), el retroceso, el daño ni los trazadores.

## 5. Tienda

Pantalla **TIENDA** del lobby (`Flow/Screens/Store.luau`):

- **DESTACADO**: tienda del evento (si hay), pack de la semana, pack de inicio (solo jugadores nuevos) y
  **tienda diaria** (6 objetos: las 3 "ofertas del día" de siempre con su descuento real y 3 más).
  Relojes: la diaria cambia a las 00:00 UTC, el destacado el lunes 00:00 UTC, el evento en su fecha de
  fin. Los relojes usan la hora del servidor y al llegar a 0 la tienda cambia de verdad.
- **ARMAS, OPERADORES, CHARMS (colgantes, tarjetas, títulos), EFECTOS (de baja e intros de MVP),
  POSES (poses de victoria y grafitis), PACKS, PASE, MONEDAS** (packs de monedas, potenciadores, VIP,
  Roblox Premium).
- Cada tarjeta: imagen grande, NUEVO (hasta que lo ves), rareza, nombre, **precio siempre visible** (con
  el de siempre tachado si hay descuento real), 👁 PREVISUALIZAR y COMPRAR. Lo que ya tienes sale como
  EQUIPAR / EQUIPADO ✓: nunca se vuelve a ofrecer.
- **Packs**: lo que traen, lo que ya tienes (✓ TUYO), lo que vale por separado y el descuento **solo si
  la cuenta es real**, y cuántas monedas se te devuelven por lo que ya tenías. Si ya lo tienes todo:
  "✓ EN TU COLECCIÓN" (no se vende).
- **Previsualizar** (`Flow/Store/Inspect.luau`): armas en 3D que se giran arrastrando y se acercan
  (rueda, pellizco o + / −) y se pueden ver en cualquiera de tus armas; trajes y poses sobre tu personaje
  completo; intros de MVP en bucle; efectos de baja con PROBAR; tarjetas, grafitis y títulos en grande.
- **Comprar**: con Robux se abre la ventana nativa de Roblox (su confirmación); con monedas, una
  confirmación propia de dos pasos con lo que te queda. CANCELAR a la izquierda, CONFIRMAR a la derecha.
- **Escena de compra** (`Flow/Store/Reveal.luau`), solo cuando el servidor confirma: COMPRA COMPLETADA →
  el objeto → brillo → nombre → rareza → EQUIPAR AHORA → EQUIPADO ✓ (pulso y sonido). Legendario o más:
  desenfoque, el objeto entra girando y sale el sello LEGENDARIO (menos de 2 s). Packs: los objetos entran
  uno tras otro y EQUIPAR TODO.
- **Primera compra**: una línea al pie ("Tu primera compra incluye la tarjeta PRIMER GOLPE"), sin
  ventanas. La tarjeta solo se consigue así.
- **Pack de inicio**: skin Sakura, traje Blaze Runner, efecto Confeti, colgante Bala, tarjeta Táctico,
  pose Arma baja y 1.500 🪙 por 99 R$. Solo hasta el nivel 15, una vez. En el lobby es un aviso pequeño
  (no una ventana); la tarjeta grande se ve en DESTACADO.

## 6. Pase de batalla

Config: `src/shared/Economy/BattlePassConfig.luau`. Servidor: `src/server/Modules/BattlePass.luau`.
Pantalla: `Flow/Screens/Pass.luau`.

- Temporada 1 "ZONA ROJA": 1 oct 2026 → 1 ene 2027. 50 niveles, vía GRATIS y PREMIUM (399 R$).
- XP del pase: la **mitad de la XP de cada partida** (`MatchXPRate`), +600 por misión diaria, +2.500 por
  misión semanal y 6 **misiones de temporada** (24.000 en total). El VIP y los potenciadores de pago no
  aceleran el pase. 3.000 XP por nivel (147.000 para el 50): unas 3 semanas jugando mucho, unos 2 meses
  jugando poco. La temporada dura 3 meses.
- Recompensas: monedas, skins, trajes, efectos, tarjeta Zona Roja (exclusiva del pase), pose Al cielo e
  intro Media vuelta. **Sin cajas** (comprar niveles no puede dar azar).
- Se **reclaman** (casilla a casilla o RECLAMAR TODO); lo reclamado entra deslizándose. Si ya tenías un
  objeto, monedas a cambio.
- Comprar el premium o **un nivel** (49 R$) solo se ofrece dentro de la pantalla del pase, en un botón.
- Cambio de temporada: lo que quedó sin reclamar se entrega solo. Nadie pierde lo que ganó.
- Migración: quien ya jugaba empieza la temporada 1 en su nivel (el pase antiguo iba por nivel) y lo que
  ya le dio el pase antiguo cuenta como reclamado. Quien compró el Game Pass premium antiguo tiene el
  premium de la temporada 1.

## 7. Recompensas, puntos rojos y pantalla final

- **Puntos rojos solo por algo real**: TIENDA (novedades sin ver), PASE (recompensas sin reclamar).
- **Pantalla final**: XP, monedas, cajas ganadas y **XP del pase** (con ¡NIVEL N! si sube), poses de
  victoria del equipo ganador, intro del MVP y tarjetas de jugador en las fichas.
- **Oferta de después de la partida** (`MonetizationConfig.PostMatchOffer`): pequeña, a la derecha, con ✕.
  Solo a partir de 3 partidas, una de cada 4, si hiciste 6+ bajas con un arma: "DOMINASTE CON
  PHANTOM-X" y una skin que no tienes para esa arma (VER = previsualizar). Solo usa lo que hiciste en la
  partida.
- **Cosméticos visibles en todas partes**: lobby (personaje con skin, traje y colgante; tarjeta en el
  perfil), armamento y operador, partida (skin, colgante, efecto de baja, título), escuadra y presentación
  de equipos (tarjeta), marcador (franja de la tarjeta), pantalla final (pose, intro de MVP, tarjeta).

## 8. Seguridad de las compras

`PlayerData.processReceipt` + `src/server/Modules/Entitlements.luau`:

1. Roblox llama a `ProcessReceipt`. Si el jugador no está en el servidor → `NotProcessedYet` (Roblox lo
   reintenta cuando vuelva, en este servidor o en otro).
2. Una compra por jugador a la vez (cola): dos recibos seguidos no se pisan.
3. Si el `PurchaseId` ya está en `data.Purchases` → `PurchaseGranted` sin entregar otra vez.
4. `Products.Resolve(ProductId)` dice qué es; `Entitlements.Plan` decide qué entregar **solo con los
   datos del servidor** (lo que ya tienes se devuelve en monedas; bonus de primera compra).
5. Se entrega, se apunta el `PurchaseId` y **se guarda**. Solo si el guardado sale bien se confirma a
   Roblox. Si el DataStore falla, se deshace exactamente lo entregado y se devuelve `NotProcessedYet`.
6. Después: aviso al cliente (`PurchaseGranted`, escena de compra) y analítica.

Game Passes (VIP, premium antiguo): el servidor comprueba con `UserOwnsGamePassAsync` antes de activar
nada; el aviso del cliente no basta. Las compras con monedas (`BuyItem`) las valida el servidor (existe,
se vende con monedas, no lo tienes, te llega). Equipar (`EquipCosmetic`) comprueba que lo tienes. Los
RemoteEvents nunca entregan nada.

## 9. Analítica

`src/server/Modules/Analytics.luau` con `AnalyticsService` (eventos propios y de economía). Solo nombres
de evento y datos del juego (ids de objetos, precios, pestañas): **nada personal**.

| Evento | Quién lo manda | Cuándo |
|---|---|---|
| `store_open` | cliente | abrir la tienda o cambiar de pestaña |
| `item_preview` | cliente | previsualizar un objeto |
| `purchase_prompt` | cliente | abrir la ventana de compra / confirmación |
| `purchase_cancel` | cliente | cerrar la ventana de Roblox sin comprar |
| `bundle_view` | cliente | ver los packs o pulsar comprar un pack |
| `battlepass_open` | cliente | abrir el pase |
| `starter_pack_view` | cliente | ver el pack de inicio |
| `purchase_success` | servidor | compra entregada (Robux o monedas) |
| `battlepass_purchase` | servidor | premium o nivel del pase entregado |
| `starter_pack_purchase` | servidor | pack de inicio entregado |
| `coin_purchase` | servidor | pack de monedas entregado |
| `battlepass_claim` | servidor | recompensas del pase reclamadas |

El cliente solo puede mandar los de la lista de cliente y como mucho 30 por minuto; los de compras solo
los manda el servidor. Además, `LogEconomyEvent` registra las monedas que entran (compras) y salen
(tienda) para vigilar la inflación.

## 10. Cómo configurarlo (Creator Dashboard)

Crea cada producto en el [Creator Hub](https://create.roblox.com/dashboard/creations) → tu experiencia →
**Monetización** y pega su id donde pone `TODO: SET IN CREATOR DASHBOARD`:

| Qué | Tipo | Dónde |
|---|---|---|
| 23 objetos sueltos | Developer Product | `Economy/Products.luau` → `Products.Items["Tipo:Id"].ProductId` |
| Nivel del pase | Developer Product | `Products.TierSkip.ProductId` |
| Pase premium de cada temporada | Developer Product | `Economy/BattlePassConfig.luau` → `Seasons[i].Premium.ProductId` |
| Packs Operación Roja / Ártico / Vacío y de temporada | Developer Product | `Shop.luau` → `Shop.Bundles[i].ProductId` |
| Pack de inicio | Developer Product | `Shop.StarterPack.ProductId` |
| 4 packs de monedas, 2 potenciadores | Developer Product | `Shop.CoinPacks[i]`, `Shop.Boosters[i]` |
| VIP | Game Pass | `Shop.VIPPassId` |

Usa en el Dashboard los mismos precios que en la config (o cámbialos aquí): la tienda enseña el precio
real que devuelve Roblox.

## 11. Operación en vivo

- **Novedades**: añade el objeto a su lista (Skins, Outfits, Charms, KillEffects, Poses, PlayerCards…),
  su precio en monedas (`Price` o `Shop.SkinPrices`/`OutfitPrices`) **o** en Robux (`Products.Items`), y
  su clave en `MonetizationConfig.NewItems` para la etiqueta NUEVO.
- **Tienda diaria**: tamaño en `MonetizationConfig.DailyStore.Size`; packs del destacado en
  `StoreRotation.FeaturedBundles`.
- **Evento de tienda**: añade una entrada a `StoreRotation.Events` (nombre, fechas UTC, pack y objetos).
- **Temporada nueva**: añade una entrada a `BattlePassConfig.Seasons` con fechas que no se pisen, sus 50
  niveles y misiones, y su producto premium.
- **Reglas**: todo lo de la sección 2 se cambia en `MonetizationConfig.Rules` (no se recomienda volver a
  encender lo que da ventaja o azar de pago).

## 12. Pruebas

Ver `PRUEBAS.md` (sección "Tienda y pase") y las pruebas automáticas del simulador:

- `econ_catalog`: productos sin ids inventados y en su tramo, packs con valor real, rotación diaria
  determinista, reloj real, pase sin cajas.
- `econ_server`: compra correcta, recibo repetido, ya lo tienes, equipar al momento, pack parcial,
  desconexión durante la compra, fallo del DataStore, dos recibos a la vez, producto desconocido / sin
  productos, servidor nuevo, compras con monedas, cajas con monedas apagadas, pase (XP, reclamar,
  premium, nivel, misiones, migración, cambio de temporada), pack de inicio y analítica con límite.
- `econ_client` (PC y móvil): lobby y puntos rojos, tienda y pestañas, compra con Robux y cancelarla,
  escena de compra y EQUIPAR AHORA, compra con monedas con confirmación, sin monedas, pack parcial,
  productos sin id, previsualización de todos los tipos con zoom y giro, pase (reclamar, reclamar todo,
  premium), NUEVO, oferta de después de la partida y XP del pase en las recompensas.
