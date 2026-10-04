# Cómo probar las novedades en Roblox Studio

Abre `ShooterRob.rbxlx` (o conecta Rojo) y usa estas dos formas de probar:

- **Jugar solo**: botón **Play** (F5). Con un solo jugador entran **bots** hasta llenar la partida (6), así
  que se puede probar casi todo sin nadie más.
- **Varios jugadores**: pestaña **Test → Clients and Servers → Local Server** con **2 o 3 jugadores**. Sirve
  para equipos, marcador, espectar y pantalla de muerte entre jugadores.

Para no esperar, en `src/shared/GameConfig.luau` puedes bajar temporalmente `IntermissionTime` (por
ejemplo a 5) y los `RoundTime` de `ModeSettings`. Para forzar un modo, pon `Modes = { "ELIM" }` (o el que
quieras probar) y vuelve a dejarlo como estaba al acabar.

## Lista rápida

| Qué | Cómo comprobarlo | Qué debería pasar |
|---|---|---|
| **Bots** | Play solo y pulsa JUGAR | Aparecen bots con nombre "Bot …" en los dos equipos; caminan, te disparan (fallan más de lejos) y se pueden eliminar. Al entrar un segundo jugador se quita un bot de su equipo. |
| **Eliminación** | `Modes = { "ELIM" }` | "RONDA 1 · ¡Una sola vida!", cuenta atrás con todos quietos (no se puede disparar ni saltar), "¡YA!". Al morir no hay Regenerar ni Revivir: se observa a compañeros. La ronda se la lleva el equipo que quede en pie. Arriba: "En pie: Rojo X – Y Azul". |
| **Marcador** | Mantén **Tab** | Dos columnas por equipo (o una lista en Todos contra todos) con bajas, muertes y K/D; los bots salen con 🤖 y tu fila en amarillo. |
| **Regalos por jugar** | Espera 2 minutos en partida | El botón 🎁 de la izquierda cuenta hacia atrás; al llegar a 0 late y se recoge con **H** (+40 monedas). Si sales y vuelves a entrar el mismo día, no se reinicia. |
| **Resumen de partida** | Termina una ronda | Debajo de VICTORIA/DERROTA: bajas, muertes, mejor racha, barra de nivel que se llena y monedas contando. |
| **Splat-X** | Menú (B) → Armas → Splat-X (nivel 2) | Dispara bolas de pintura: manchas de colores en paredes y suelo que se desvanecen a los 5 s. |
| **Skins animadas** | Menú → Skins → Arcoíris o Prisma (cómpralas con monedas: en Studio puedes darte monedas desde la consola, ver abajo) | El arma cambia de color sin parar (en la mano, en la tienda y en las armas de los demás). |
| **Mapas nuevos** | Vota Arena Caramelo o Caja de Juguetes en el descanso | Arena Caramelo: tarta central, gominolas, plataformas de salto (te lanzan hacia arriba). Caja de Juguetes: castillo de bloques con pasarela, ladrillos gigantes, tren. |
| **Armas cuerpo a cuerpo** | Menú → Armas → abajo: Martillo de juguete o Katana (dátelas con nivel/monedas, ver abajo) | Al reaparecer llevas esa arma en la ranura 3; la F golpea con ella (la katana llega más lejos). |
| **Tarjeta de controles** | Entra en partida con un jugador nuevo | Sale una tarjeta con los controles; "¡A JUGAR!" la cierra. En Studio sin DataStore activado sale cada vez (es normal). |
| **Tonos de los mapas antiguos** | Juega Harbor Heights o Frost Station | Los grises ahora tienen el tono del mapa (arena cálida, azul hielo…). |
| **Evento de Halloween** | Juega una ronda | Aparecen caramelos que flotan y brillan; al tocarlos: "🍬 Caramelo +5 🪙 (1/100)" y sube el contador de abajo a la izquierda, que dice el siguiente premio ("→ Traje" a los 50). Hay calabazas en el mapa. |
| **Infección (zombis)** | `Modes = { "INF" }` y Play solo | "La infección empieza en…", y al llegar a 0 un bot (o tú) se convierte en zombi verde con ojos rojos y garras. Arriba: supervivientes contra zombis. Si te alcanzan, reapareces como zombi (brazos verdes, solo garras, sin granadas). Ganan los supervivientes si queda alguno al acabar el tiempo. |
| **Calabazas** | `Modes = { "CAL" }` y Play solo | "🎃 ¡CALABAZAS!". Cada eliminado deja una calabaza flotando sobre un anillo de su color. Si pasas por encima de la de un enemigo: punto para tu equipo y "+60 XP 🎃 Calabaza confirmada"; la de un compañero: "Calabaza recuperada" sin punto. Los bots corren a por ellas. Desaparecen a los 30 s. |
| **Ruleta diaria** | Pantalla de inicio → 🎡 RULETA ¡GRATIS! | Gira unos segundos con clics y se para en un premio ("¡Has ganado 100 🪙!"). El segundo giro del día dice "Vuelve mañana" (los giros con Robux salen cuando pongas `Shop.Wheel.SpinProductId`). |
| **Colgantes** | Menú → Skins → abajo, compra la Calabacita y reaparece | Una calabacita cuelga del lateral del arma y se balancea al girar rápido la cámara. Los demás también la ven. |
| **Rangos** | Termina una partida | En el resumen sale tu rango (🥉 BRONCE) y los RP ganados; contra bots +8 si ganas. En la pantalla de inicio: "🥉 Bronce (8 RP)". El icono sale también en el marcador (Tab) y en el chat. |
| **Pantalla de carga** | Play | Antes del juego sale "SHOOTER NEW" con una calabaza que bota y consejos; se desvanece sola. |
| **Novedades** | Con datos guardados de antes (o pon `NewsSeen = 0` desde la consola) | En la pantalla de inicio sale la tarjeta "¡NOVEDADES DE HALLOWEEN!"; "¡A JUGAR!" la cierra y no vuelve a salir. |
| **Base Lunar** | Vota la Base Lunar | Noche con la Tierra en el cielo, cohete central con pasarela, cúpulas, rover, paneles solares y plataformas con propulsores. |
| **Feria** | Vota la Feria | Atardecer con tiovivo en el centro (se puede subir), casetas con premios, coches de choque, casa de la risa con escaleras a la azotea, noria y montaña rusa al fondo. |
| **Bots en Captura la bandera** | `Modes = { "CTF" }` y Play solo | Los bots van a por tu bandera, se la llevan a su base y puntúan; si los eliminas, la bandera cae. |
| **Escalada de armas solo** | `Modes = { "GUN" }` | Hay bots; cada baja (también a bots) te sube de arma. |
| **Guadaña y Calabazooka** | Menú → Armas | Guadaña (cuerpo a cuerpo, 1500 monedas). Calabazooka (lanzacohetes) sale bloqueada con "🎃 75 caramelos"; al conseguirla dispara calabazas. |
| **Mira** | Menú → Ajustes → Mira | Cambia el color (6) y el tamaño; se nota al momento en la mira. |
| **SE BUSCA** | Play solo, haz 5 bajas seguidas sin morir | Arriba: "💰 SE BUSCA: tú · 25 🪙 por su cabeza" y en grande "¡TE BUSCAN!". Los bots van más a por ti. Con 2 jugadores (Local Server), el otro ve un cartel rojo sobre tu cabeza; si te elimina, "¡RECOMPENSA COBRADA! +25 🪙". |
| **Retos semanales** | Menú → Retos | Debajo de los 3 retos de hoy: "📅 RETOS DE LA SEMANA · nuevos en Xd Yh" con 3 retos azules más largos (barras de progreso que avanzan al jugar) y la caja de premio por completarlos. |
| **Títulos** | Menú → Perfil → abajo | Rejilla de títulos: Novato elegido; los que no tienes con 🔒 y lo que falta ("100 bajas") o su precio. Compra "Payaso de feria" (800): queda elegido y en el marcador (Tab) sale rosa junto a tu nombre. |
| **Indicador de daño** | Play solo y deja que un bot te dispare de lado o por la espalda | Alrededor de la mira sale una marca roja con una flecha que apunta hacia el bot (a la derecha, abajo si está detrás…) y se desvanece en algo más de 1 s. Con el escudo de reaparición no sale. |
| **Asistencias** | Dispara a un bot y deja que otro bot o un compañero lo remate | "🤝 ASISTENCIA Bot …" en azul y "+20 XP Asistencia" (contra bots vale la mitad). Perfil → Asistencias sube. |
| **Pack de Halloween** | Pon un ID en el `ProductId` del pack de Halloween (`Shop.Bundles`, el primero) y abre la Tienda | Arriba del todo, tarjeta naranja-morada "🎃 PACK DE HALLOWEEN · quedan X días" con lo que trae. En Studio la compra de prueba entrega 2500 monedas, el efecto Calabazas, la Calabacita y el grafiti Calabaza, y la tarjeta desaparece. |
| **Pueblo Vaquero** | Vota el mapa 🤠 (o ponlo primero en `MapBuilder.Order`) | Calle del Oeste con el depósito de agua en el centro; sube por la escalera de detrás del saloon o del banco a la azotea: la fachada de madera te cubre hasta el pecho y se dispara por encima. Tren echando humo al fondo. |
| **Traje Sheriff Vaquero** | Menú → Trajes → Sheriff Vaquero (2200 monedas) | Sombrero de vaquero marrón con cinta dorada, pañuelo rojo, chaleco de cuero abierto con estrella dorada y cartuchera en la pierna derecha. |
| **Te faltan monedas** | Con algún pack de monedas con ID puesto, intenta comprar algo caro sin monedas suficientes | Sale "Te faltan N monedas" y al momento el menú pasa a la Tienda, bajado hasta los packs de 🪙 Monedas. |
| **Noria que gira** | Vota la Feria y mira al fondo | La noria gira despacio y las cabinas se mantienen derechas. |
| **Grafitis** | En partida, mira una pared cerca y pulsa **J** | Aparece un círculo azul con "GG" pintado en la pared. Menú → Efectos → abajo: compra la Calabaza y pulsa J otra vez (a los 6 s): el anterior desaparece y sale la calabaza con "BOO!". |
| **Premio del grupo** | Pon el ID de tu grupo en `GameConfig.Group.Id` y publica (en Studio el grupo puede no comprobarse) | En la pantalla de inicio sale ⭐ ÚNETE AL GRUPO +500 🪙. Si ya estás en el grupo: "✅ ¡+500 🪙! Gracias" y el botón desaparece. Si no, sale la ventana de Roblox para unirte. |
| **Pase de 50 niveles** | Menú → Pase | Los niveles cercanos al tuyo; al final "… y N niveles más". |
| **Pantalla de muerte** | Muere con la tienda abierta | La tienda se cierra sola y la B no gasta un revivir al cerrarla. |
| **Ballesta** | Menú → Armas → Ballesta (nivel 9 o 2000 monedas) | Arco de metal con cuerda y virote de punta roja. Un disparo y recarga sola; a la cabeza mata de un tiro. |
| **Invitaciones** | Hace falta publicar y una cuenta nueva: invita a un amigo con 👥 INVITA | Cuando entra por primera vez: a él "¡Te invitó …! +500 🪙" y a ti "¡… entró con tu invitación! +500 🪙". |
| **Potenciadores** | Pon un ID en `ProductId` de `Shop.Boosters` (en Studio la compra es de prueba) y cómpralo en la Tienda | "⚡ ¡XP DOBLE 30 MIN!", debajo del marcador "⚡ x2 XP 29:59" bajando (se para en la portada) y la XP de cada baja sale el doble. La tarjeta dice "✔ Activo: quedan N min". |
| **Primera victoria del día** | Pantalla de inicio, y luego gana una partida | En la portada, debajo de la ruleta: "🏆 1.ª victoria de hoy: +150 🪙". Al ganar: "🏆 ¡Primera victoria del día! +150 🪙" y el texto de la portada desaparece hasta mañana. |
| **Caja sorpresa** | Juega varias partidas enteras | De vez en cuando (y como mucho a las 15 partidas) sale en grande "🎁 ¡CAJA SORPRESA!" y en la Tienda tienes una caja gratis más. |
| **Premio de regreso** | Con el guardado activado, en la consola del servidor: `require(game.ServerScriptService.Server.Modules.PlayerData).Get(game.Players:GetPlayers()[1]).LastPlayDay -= 5`; para el juego y vuelve a darle a Play | A los pocos segundos de entrar: "👋 ¡BIENVENIDO DE VUELTA! Regalo por volver: +400 🪙, 1 caja gratis y ⚡ XP doble 30 min" (y debajo del marcador "⚡ x2 XP 30:00" al entrar en partida). |
| **Roblox Premium** | Menú → Tienda → abajo del VIP | Tarjeta "⭐ Roblox Premium · +20% monedas y XP" con el botón "Hazte Premium" (o "✔ Bonus activo" si tu cuenta ya es Premium). |
| **Tablet** | Studio → Test → **Device** → un iPad | Los botones táctiles (disparar, apuntar, recargar...) quedan a la izquierda del botón de saltar, que en tablet es más grande; ninguno lo tapa. |
| **Móvil** | Studio → Test → **Device** (emulador de teléfono) | Botones táctiles: 😀 emotes, 📋 marcador, 🎁 pequeño arriba a la izquierda; nada tapado por el joystick. |

## Probar la Navidad ahora (sin esperar a diciembre)

En `src/shared/GameConfig.luau`, dentro de `GameConfig.Events`: al de Halloween ponle `EndsAt = 0` y al
de Navidad `StartsAt = 0`. Al darle a Play: regalos (cajas de colores) en vez de caramelos, muñecos de
nieve en los mapas, la Villa Navideña en la votación, la tarjeta "🎄 ¡LLEGA LA NAVIDAD!" para quien ya
había jugado y los premios del evento (Papá Noel a los 50 regalos). **Vuelve a dejar las fechas como
estaban antes de publicar.**

## Darte monedas o nivel en Studio (para probar la tienda)

Con el juego en marcha, en la consola de **servidor** (Ver → Output / barra de comandos, en el lado
servidor):

```lua
local PD = require(game.ServerScriptService.Server.Modules.PlayerData)
local p = game.Players:GetPlayers()[1]
PD.AddCoins(p, 10000, false)
PD.AddXP(p, 5000, "Prueba")
```

## Si algo falla

Abre **Output** (Ver → Output): los errores del juego salen en rojo con el archivo y la línea. Copia ese
texto y pásamelo tal cual: con eso lo arreglo directamente.
