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
