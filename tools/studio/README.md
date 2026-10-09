# Herramientas para manejar Roblox Studio desde la terminal

Hablan con el servidor MCP que instala Roblox Studio (`%LOCALAPPDATA%\Roblox\mcp.bat`), sin depender de
que la sesión de Claude tenga cargadas sus herramientas. Studio tiene que estar abierto con
`ShooterRob.rbxlx`. Necesitan Node.

| Archivo | Para qué |
|---|---|
| `run.js` | Ejecuta una lista de pasos (`node run.js pasos.json`). |
| `sync.js` | Empuja a Studio los `.luau` de `src/` cambiados desde la última vez (`node sync.js && node run.js sync.json`). Crea los módulos y carpetas que falten. Detiene la partida antes. |
| `mk.js` | Convierte un `.luau` en un paso: `node mk.js salida.json Edit|Client|Server script.luau`. |
| `qa_on.luau` | Activa el modo QA **solo en la copia de Studio** (no toca el repo). |
| `weapontest.js` | Prueba armas en partida con el modo QA: `node weapontest.js HavocPump Signal7` y luego `node run.js weapontest.json`. Deja capturas `wt_<Arma>_<n>.png` (reposo, disparo, apuntado, recarga). |
| `showcase.luau` | En modo Edit, construye todas las armas nuevas con su acabado de fábrica y las pone en fila en `workspace.SR_Showcase` (para capturarlas). |

## Pasos de `run.js`

```json
[
  { "tool": "start_stop_play", "args": { "is_start": true } },
  { "sleep": 25000 },
  { "clickText": "JUGAR" },
  { "tool": "screen_capture", "args": { "capture_id": "c1" }, "img": "c1.png" },
  { "tool": "get_console_output", "max": 3000, "tail": true },
  { "tool": "start_stop_play", "args": { "is_start": false } }
]
```

- `tool` + `args`: cualquier herramienta del MCP de Studio (`execute_luau`, `screen_capture`,
  `user_mouse_input`, `user_keyboard_input`, `get_console_output`, `start_stop_play`, `upload_image`...).
  `studio_id` se pone solo.
- `clickText`: busca en la interfaz del cliente un botón por su texto exacto y hace clic en su centro.
- `sleep`: milisegundos. `img`: dónde guardar la captura. `max`/`tail`: recorte del texto devuelto.
- Las coordenadas del ratón son las de `AbsolutePosition` (sin sumar la barra superior).

## Cosas que conviene saber

- `execute_luau` tiene su propia caché de módulos: un `require` desde ahí **no** es el mismo módulo que
  usa el juego. Para cambiar el estado del juego hay que usar sus remotos (por ejemplo `QACommand`).
- Para ver un cambio hay que parar la partida, sincronizar y volver a arrancar.
- `rojo build -o ShooterRob.rbxlx` regenera el place desde `src/`; lo que solo esté en Studio se pierde.
- El modo QA nunca se deja activado en el repo (`GameConfig.QA.Enabled` es `false`).
- Los `.json` y `.png` de esta carpeta no se guardan en git.
