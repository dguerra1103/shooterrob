# Pruebas automáticas (fuera de Roblox Studio)

Estas pruebas cargan los módulos reales de `src/` en [Lune](https://lune-org.github.io/docs) con una
imitación (mock) de la API de Roblox (`harness/mock.luau`). Sirven para cazar errores de lógica y
regresiones rápido, **pero un mock no demuestra que el juego funcione en Studio**: no hay física real,
ni red, ni replicación, ni render, ni DataStores ni MarketplaceService de verdad. Lo que solo se puede
comprobar en Studio está en `FASE_01_ESTABILIDAD.md` (sección E).

## Herramientas

Las versiones están fijadas en `aftman.toml` (Rojo 7.4.4, Lune 0.8.9, luau-lsp 1.70.1):

```bash
aftman install
```

## Ejecutar

```bash
tests/check.sh          # rojo build + luau-lsp analyze (tipos y errores de todo src/)
tests/run_all.sh        # todas las pruebas Lune (tarda varios minutos)
tests/run_all.sh flow   # solo una prueba (nombre del archivo sin .luau)
```

- Ejecuta las pruebas **de una en una** (no lances dos `run_all.sh` a la vez): varias usan tiempos
  reales cortos y, con la CPU saturada, pueden pasarse del tiempo límite y dar un falso fallo.
- `run_all.sh` termina con `OK: n   FALLOS: m` y sale con código distinto de 0 si algo falla.
- Una prueba falla si sale con error, imprime `FALLO`, deja una traza (`Stack Begin`) o se pasa
  del tiempo límite.
- `tests/.cache/` (ignorado por git) guarda el `.rbxlx` de comprobación y los tipos globales.

## Qué cubren (resumen)

| Grupo | Pruebas |
|---|---|
| Arranque | `serverboot` (los 10 modos), `clientboot`, `boot` |
| Ciclo de partidas | `ciclo` (10 partidas seguidas, todos los modos: mapas, bots, conexiones y objetos sueltos que no crecen), `rounds`, `sndround`, `elim`, `infection`, `domination`, `bomb`, `calabazas` |
| Mapas | `navcheck` (9 mapas: zonas alcanzables, aparición), `spawncheck`, `sightcheck`, `botspots`, `votecheck` |
| Combate | `shooting`, `realshots`, `realhits`, `melee`, `grenade`, `killcam`, `finalkillcam*` |
| Gunplay (Fase 2) | `weaponfeel` (perfiles, golpe de cámara igual a cualquier fps, presupuestos, audio por capas, juego limpio), `gunfeel` (eventos del arma, recarga autoritativa, cancelaciones, apuntado por tipo, FOV, casquillos por calidad), `hittelemetry` (instrumentación de impactos) |
| Bots | `bots`, `botbrain`, `gunbots`, `flagbots`, `infection_bots` |
| Datos | `datastore` (bloqueo de sesión, recibos idempotentes, migraciones), `progress`, `seasons` |
| Economía | `econ_catalog`, `econ_server`, `econ_client` (ProductId = 0: nunca hay compras reales) |
| Interfaz | `flow`, `results`, `hudclient`, `menu`, `scoreboard`, `phonefx`, `touchbtns`… |
| Móvil (Fase 12) | `mobilehud` (disposición pura y validación), `touchbtns` (controles táctiles), `hudeditor` (editor de HUD y validación en el servidor), `phonefx` |

## Si una prueba falla

No se borra ni se cambia su expectativa para que pase: primero se averigua si el fallo es del
código o de la prueba (por ejemplo, una limitación del mock), y se documenta.
