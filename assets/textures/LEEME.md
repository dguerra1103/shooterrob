# Textura de cuadrícula ("Grid")

`grid.png` es una cuadrícula en escala de grises (como la de los shooters más jugados de Roblox).
Roblox la tiñe del color de cada pieza: la misma imagen sirve para paredes lavanda, columnas rosas,
suelos verdes, etc.

## Cómo activarla

1. Sube `grid.png` a Roblox (con la misma cuenta o grupo que publica el juego):
   - **Opción fácil (Studio):** abre Roblox Studio → pestaña *Ver* → *Gestor de recursos* (Asset Manager)
     → botón *Importar* → elige `grid.png`. Cuando termine, clic derecho sobre la imagen →
     *Copiar ID del recurso*.
   - **Opción web:** create.roblox.com → *Creaciones* → *Elementos de desarrollo* → *Calcomanías*
     (Decals) → *Subir recurso*.
2. Pasa ese número a Claude (no es secreto: es solo el ID de una imagen).
3. Claude añade la variante a `default.project.json`:

```json
"MaterialService": {
  "$properties": { "Use2022Materials": true },
  "Grid": {
    "$className": "MaterialVariant",
    "$properties": {
      "BaseMaterial": { "Enum": 272 },
      "ColorMap": "rbxassetid://ID_DE_LA_IMAGEN",
      "StudsPerTile": 4
    }
  }
}
```

Los mapas ya marcan todas sus superficies lisas con `MaterialVariant = "Grid"`
(`Kit.applyStyle` en `src/server/Modules/MapKit.luau`). Mientras la variante no exista, Roblox usa
el plástico liso normal, así que no se rompe nada.
