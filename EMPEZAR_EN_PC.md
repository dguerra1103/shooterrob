# Trabajar en la PC (Windows + Roblox Studio + Rojo)

Todo se hace con doble clic en estos archivos de la carpeta `shooterrob`:

| Archivo | Para qué | Cuándo |
|---|---|---|
| `1_ACTUALIZAR.bat` | Baja lo último de GitHub (rama `claude/intelligent-fermi-cz7und`). Si guardaste `ShooterRob.rbxlx` desde Studio, antes lo copia a `ShooterRob_tuyo.rbxlx`. | Cada vez que empiezas a trabajar o cuando Claude te diga que subió algo. |
| `2_INSTALAR_PLUGIN_ROJO.bat` | Instala el plugin de Rojo en Roblox Studio. | Una sola vez (y luego cierras y abres Studio). |
| `3_INICIAR_ROJO.bat` | Conecta el código con Studio. **Deja la ventana abierta.** En Studio: Plugins → Rojo → Connect. | Siempre que trabajes con código. |
| `4_CONSTRUIR_Y_ABRIR_PLACE.bat` | Genera `ShooterRob.rbxlx` con todo el código actual y lo abre en Studio. | Si quieres el place completo sin Rojo. |

Los `.bat` buscan `rojo.exe` primero en esta carpeta y, si no, el que instaló `aftman install`.

## Orden la primera vez
1. `1_ACTUALIZAR.bat`
2. `2_INSTALAR_PLUGIN_ROJO.bat` → cierra y abre Roblox Studio
3. Abre `ShooterRob.rbxlx` en Studio
4. `3_INICIAR_ROJO.bat` → en Studio: Plugins → Rojo → Connect
5. Pulsa ▶ Probar. El mapa se construye al empezar la partida (en el editor solo se ve el cielo: es normal).
   Para verlo como en el teléfono: pestaña Prueba → Dispositivo → un teléfono apaisado.

## Reglas para no perder trabajo
- Los scripts NO se editan en Studio: Rojo los sobrescribe con lo de `src/`. El código se cambia en los
  archivos (con Claude Code abierto en esta carpeta).
- Lo que modeles (Forge, piezas, mapas a mano) sí va en Studio: guárdalo en tu propio archivo
  (`Archivo → Guardar como…`, por ejemplo `MiTrabajo.rbxlx`) o expórtalo como `.rbxm`. Así
  `1_ACTUALIZAR.bat` nunca lo pisa.
- Para subir cambios de código: `git add src` → `git commit -m "qué cambió"` → `git push`.
  No uses `git add .` (subirías `rojo.exe` o tus places).
- No se publica desde aquí: publicar es a mano (Studio o el workflow manual), cuando tú lo decidas.

## Si algo falla
Manda captura de la ventana negra o de Studio → Ventana → Salida (los errores en rojo).
