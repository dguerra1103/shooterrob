# Resultados de las pruebas en Roblox Studio

> **Vacío a propósito.** Se rellena al probar en Studio siguiendo `FASE_08_VALIDACION_STUDIO.md`.
> No hay ningún resultado inventado: lo que no esté escrito aquí **no se ha probado**.

## Sesión

| Campo | Valor |
|---|---|
| Fecha | |
| Quién prueba | |
| Commit probado (`git log --oneline -1`) | |
| Versión de Roblox Studio | |
| Equipo (CPU / GPU / RAM) | |
| Modo QA activo (`GameConfig.QA.Enabled`) | |
| API Services activado (¿se guarda el progreso?) | |

## Resumen

| Sección de la guía | Estado (✅ / ❌ / sin probar) | Fallos (nº) |
|---|---|---|
| C. 1 jugador | | |
| D. 2 jugadores | | |
| E. 5 contra 5 | | |
| E2. 5 partidas seguidas | | |
| F. Device Emulator | | |
| G. Gunplay | | |
| H. Mapas | | |
| I. Bots | | |
| J. UI | | |
| K. Rendimiento | | |
| L. Networking | | |
| M. Resultados | | |

## Prueba de 5 partidas (E2): fotos de contadores

Copia los números de las líneas `[QA] Foto cliente` y `[QA] Foto servidor` de la Output.

| Foto | Mapa + modo | Memoria cliente (MB) | Memoria servidor (MB) | ScreenGui | Mapas en workspace | Bots en el descanso | ClientFX | Instancias cliente | Instancias servidor |
|---|---|---|---|---|---|---|---|---|---|
| Antes | | | | | | | | | |
| 1 | Construction + TDM | | | | | | | | |
| 2 | Coastal + DOM | | | | | | | | |
| 3 | MallRush + SND | | | | | | | | |
| 4 | | | | | | | | | |
| 5 | | | | | | | | | |

## Rendimiento (K)

| Dispositivo | Mapa | Calidad | Situación | FPS | Memoria (MB) | Notas |
|---|---|---|---|---|---|---|
| | | | | | | |

## Telemetría de impactos (L)

| Retraso simulado | Objetivo (quieto / corriendo) | Arma | Muestras | Holgura ≤ 4 | 4-6 | 6-8 | > 8 (rechazados) | Cabeza cliente sí / servidor no | Notas |
|---|---|---|---|---|---|---|---|---|---|
| 0 | | | | | | | | | |
| 0,1 s | | | | | | | | | |
| 0,2 s | | | | | | | | | |

---

## Problemas encontrados

**Severidad:**
- **Crítica:** el juego se rompe, se pierde progreso o hay una puerta a trampas o compras.
- **Alta:** impide jugar o terminar una partida, o se nota en todas.
- **Media:** molesta o confunde, pero se puede jugar.
- **Baja:** detalle visual o de texto.

Copia este bloque para cada problema:

### Problema 1

- **DISPOSITIVO:**
- **MAPA:**
- **MODO:**
- **PROBLEMA:**
- **SEVERIDAD:**
- **PASOS PARA REPRODUCIR:**
  1.
  2.
  3.
- **RESULTADO ESPERADO:**
- **RESULTADO REAL:**
- **FPS:**
- **NOTAS:** (texto de la Output tal cual, captura, sección de la guía)

### Problema 2

- **DISPOSITIVO:**
- **MAPA:**
- **MODO:**
- **PROBLEMA:**
- **SEVERIDAD:**
- **PASOS PARA REPRODUCIR:**
  1.
  2.
  3.
- **RESULTADO ESPERADO:**
- **RESULTADO REAL:**
- **FPS:**
- **NOTAS:**

### Problema 3

- **DISPOSITIVO:**
- **MAPA:**
- **MODO:**
- **PROBLEMA:**
- **SEVERIDAD:**
- **PASOS PARA REPRODUCIR:**
  1.
  2.
  3.
- **RESULTADO ESPERADO:**
- **RESULTADO REAL:**
- **FPS:**
- **NOTAS:**
