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
| **Ruleta diaria** | Pantalla de inicio → 🎡 RULETA ¡GRATIS! | Gira unos segundos con clics y se para en un premio ("¡Has ganado 100 🪙!"). El segundo giro del día dice "Vuelve mañana" (los giros con Robux salen cuando pongas `Shop.Wheel.SpinProductId`). |
| **Colgantes** | Menú → Skins → abajo, compra la Calabacita y reaparece | Una calabacita cuelga del lateral del arma y se balancea al girar rápido la cámara. Los demás también la ven. |
| **Rangos** | Termina una partida | En el resumen sale tu rango (🥉 BRONCE) y los RP ganados; contra bots +8 si ganas. En la pantalla de inicio: "🥉 Bronce (8 RP)". El icono sale también en el marcador (Tab) y en el chat. |
| **Pantalla de carga** | Play | Antes del juego sale "SHOOTER NEW" con una calabaza que bota y consejos; se desvanece sola. |
| **Novedades** | Con datos guardados de antes (o pon `NewsSeen = 0` desde la consola) | En la pantalla de inicio sale la tarjeta "¡NOVEDADES DE HALLOWEEN!"; "¡A JUGAR!" la cierra y no vuelve a salir. |
| **Base Lunar** | Vota la Base Lunar | Noche con la Tierra en el cielo, cohete central con pasarela, cúpulas, rover, paneles solares y plataformas con propulsores. |
| **Bots en Captura la bandera** | `Modes = { "CTF" }` y Play solo | Los bots van a por tu bandera, se la llevan a su base y puntúan; si los eliminas, la bandera cae. |
| **Escalada de armas solo** | `Modes = { "GUN" }` | Hay bots; cada baja (también a bots) te sube de arma. |
| **Guadaña y Calabazooka** | Menú → Armas | Guadaña (cuerpo a cuerpo, 1500 monedas). Calabazooka (lanzacohetes) sale bloqueada con "🎃 75 caramelos"; al conseguirla dispara calabazas. |
| **Mira** | Menú → Ajustes → Mira | Cambia el color (6) y el tamaño; se nota al momento en la mira. |
| **Pase de 50 niveles** | Menú → Pase | Los niveles cercanos al tuyo; al final "… y N niveles más". |
| **Pantalla de muerte** | Muere con la tienda abierta | La tienda se cierra sola y la B no gasta un revivir al cerrarla. |
| **Móvil** | Studio → Test → **Device** (emulador de teléfono) | Botones táctiles: 😀 emotes, 📋 marcador, 🎁 pequeño arriba a la izquierda; nada tapado por el joystick. |

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
