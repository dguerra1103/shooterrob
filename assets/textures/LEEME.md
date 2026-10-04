# Texturas del juego (subir a Roblox)

Estas imágenes las usa el juego como **MaterialVariant**: una sola imagen se aplica a cientos de
piezas sin crear nada extra, así que no gasta rendimiento.

| Archivo | Variante | Para qué | Tamaño de repetición |
|---|---|---|---|
| `grid.png` | `Grid` | Cuadrícula de paredes y suelos de los mapas (se tiñe del color de cada pieza) | 4 studs |
| `camo_bosque.png` | `CamoBosque` | Skin de arma "Bosque" | 2 studs |
| `camo_desierto.png` | `CamoDesierto` | Skin de arma "Desierto" | 2 studs |
| `camo_digital.png` | `CamoDigital` | Skin de arma "Digital urbano" | 2 studs |
| `camo_artico.png` | `CamoArtico` | Skin de arma "Ártico" | 2 studs |
| `camo_tigre.png` | `CamoTigre` | Skin de arma "Tigre" | 2 studs |
| `camo_nebulosa.png` | `CamoNebulosa` | Skin de arma "Nebulosa" | 2 studs |

Mientras una variante no exista, el juego usa colores normales: no se rompe nada. Las skins de
camuflaje se pueden comprar desde ya; al subir la imagen, todas las que ya se compraron pasan a
verse con el dibujo.

## Cómo subirlas

1. Abre Roblox Studio → pestaña **Ver** → **Gestor de recursos** (Asset Manager) → **Importar** y
   elige los 7 PNG de esta carpeta (se pueden elegir todos a la vez).
2. Cuando terminen, clic derecho sobre cada imagen → **Copiar ID del recurso**.
3. Pasa los ID a Claude (no son secretos: son solo imágenes). Claude los añade a
   `default.project.json` así:

```json
"MaterialService": {
  "$properties": { "Use2022Materials": true },
  "Grid": {
    "$className": "MaterialVariant",
    "$properties": { "BaseMaterial": { "Enum": 272 }, "ColorMap": "rbxassetid://ID", "StudsPerTile": 4 }
  },
  "CamoBosque": {
    "$className": "MaterialVariant",
    "$properties": { "BaseMaterial": { "Enum": 256 }, "ColorMap": "rbxassetid://ID", "StudsPerTile": 2 }
  }
}
```

(`272` = SmoothPlastic para la cuadrícula de los mapas; `256` = Plastic para los camuflajes.)

Los mapas marcan sus superficies lisas con `MaterialVariant = "Grid"` (`Kit.applyStyle` en
`src/server/Modules/MapKit.luau`) y las armas usan `Camo<nombre>` (`src/shared/WeaponModels.luau`).
