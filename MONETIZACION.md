# Monetización de SHOOTERROB: cómo ponerla a vender

Estado a 12 de octubre de 2026: **los 39 productos ya existen en Roblox y sus ids están en el juego**.
Falta probar una compra en Studio y publicar la versión que lleva los ids (pasos 3 y 4). El diseño (qué
se vende y por qué) está en `ECONOMY.md`.

- **Dónde**: experiencia «Shooter New» (universo `10769195462`, privada). 38 Developer Products y el
  Game Pass VIP (`2029778289`), creados a mano en el Creator Hub, cada uno con su icono.
- **Comprobado**: nombre y precio de los 39 en Roblox coinciden con la lista del juego, los 39 ids son
  distintos y `ProductIds.luau` no tiene ninguno a 0.
- **«Precios administrados» está desactivado en los 39.** Roblox lo trae activado y al guardar pide
  aceptar unos términos de uso que tiene que aceptar el dueño de la cuenta. Se activa después desde la
  página de productos o de pases («Gana más con Precios administrados» → *Comenzar*); es la decisión de
  precios regionales de la sección 6.
- **Los pasos 1 y 2 de la sección 2 ya están hechos.** Se dejan escritos por si hay que repetirlos en
  otra experiencia.

## 1. Qué hay construido

- **Tienda** con previsualización, compra con Robux (ventana nativa de Roblox) y con monedas del juego.
- **Pase de batalla** por temporadas: vía gratis y vía premium, 50 niveles, compra de niveles sueltos.
- **VIP** (Game Pass), **packs** de colección y de temporada, **pack de inicio**, **monedas** y
  **potenciadores**.
- **Entrega en el servidor**: cada compra se entrega una sola vez y se guarda antes de confirmarla a
  Roblox; si el guardado falla, se deshace y Roblox la reintenta.
- **Analítica** del embudo: abrir tienda, abrir compra, cancelar, comprar.

Nada de lo que se vende da ventaja en combate y no hay azar de pago. Es una decisión de diseño que vive
en `MonetizationConfig.Rules`; se comenta en la sección 6.

## 2. Lo que hay que hacer (una vez)

### Paso 1 · Publicar la experiencia

Los productos cuelgan de una experiencia publicada. Puede ser privada.

### Paso 2 · Crear los 39 productos

Hay dos caminos. Con cualquiera de los dos, **el único archivo del juego que cambia es
`src/shared/Economy/ProductIds.luau`**.

**A) Automático (unos minutos).** Hace falta una clave de Open Cloud tuya:

1. Creator Hub → *Open Cloud* → *API Keys* → *Create API Key*.
2. Permisos, limitados a la experiencia de SHOOTERROB: `developer-product:read`,
   `developer-product:write`, `game-pass:read`, `game-pass:write`.
3. Copia el id del universo: Creator Hub → la experiencia → menú «⋯» → *Copy Universe ID*.
4. Haz doble clic en **`5_CREAR_PRODUCTOS_TIENDA.bat`**. Te pide el id del universo y la clave (al
   pegarla no se ve, y no se guarda en ningún archivo), enseña la lista de lo que va a crear y **no crea
   nada hasta que escribes SI**. Sube también el icono de cada producto.

Para activar además los precios regionales (sección 6), en una terminal en la carpeta del proyecto:

```powershell
.\5_CREAR_PRODUCTOS_TIENDA.bat --regional
```

Se puede repetir: lo que ya existe con el mismo nombre no se duplica, solo se apunta su id (y se le
pone el icono, o el precio regional, si faltaba). Si Roblox falla a mitad, lo ya creado queda apuntado
y al repetir se termina el resto.

**El script no se ha ejecutado contra el Roblox real** (hace falta la clave). Está escrito sobre la
documentación oficial de Open Cloud y pasa 13 comprobaciones contra un Roblox simulado en el propio
ordenador (`scripts/monetizacion/prueba_api.py`): eso prueba su lógica, no que Roblox responda
exactamente como dice la documentación. Si falla al primer producto, manda la captura y se corrige; no
habrá cobrado ni roto nada.

**B) A mano (unos 40 minutos).** Creator Hub → la experiencia → *Monetization* → *Developer Products*
(y *Passes* para el VIP). Crea cada uno con el nombre y el precio de la tabla de la sección 3, súbele su
icono de `assets/tienda/iconos` y pega su id en la línea de su clave en `ProductIds.luau`.

### Paso 3 · Regenerar y probar

Doble clic en `4_CONSTRUIR_Y_ABRIR_PLACE.bat`. Con el place abierto en Studio, entra en TIENDA y compra algo: en Studio las compras son de prueba y no
cuestan Robux. Tiene que salir la escena de compra completada y el objeto en tu colección. Prueba al
menos un objeto suelto, un pack de monedas, el pase premium y el VIP.

### Paso 4 · Publicar la versión con los ids

Sin este paso los jugadores siguen viendo «PRÓXIMAMENTE».

## 3. Los 39 productos

Lista generada desde la configuración del juego (`tools/economy/productos.luau`), no escrita a mano.

| Nombre en Roblox | Tipo | Precio (R$) | Clave en ProductIds |
|---|---|---|---|
| 500 monedas · Puñado | Developer Product | 49 | `Coins:Puñado` |
| 1200 monedas · Bolsa | Developer Product | 99 | `Coins:Bolsa` |
| 3000 monedas · Cofre | Developer Product | 199 | `Coins:Cofre` |
| 8000 monedas · Bóveda | Developer Product | 449 | `Coins:Bóveda` |
| XP doble · 30 min | Developer Product | 49 | `Booster:XP2` |
| Monedas dobles · 30 min | Developer Product | 69 | `Booster:Coins2` |
| Pack de inicio | Developer Product | 99 | `Starter:Starter` |
| Pase premium · Temporada 1 | Developer Product | 399 | `PassPremium:S1` |
| Nivel del pase | Developer Product | 49 | `TierSkip:TierSkip` |
| Pack de halloween | Developer Product | 199 | `Bundle:Halloween` |
| Pack de navidad | Developer Product | 199 | `Bundle:Navidad` |
| Pack aventurero | Developer Product | 299 | `Bundle:Aventurero` |
| Pack operación roja | Developer Product | 399 | `Bundle:RedOps` |
| Pack ártico | Developer Product | 249 | `Bundle:Artico` |
| Pack del vacío | Developer Product | 299 | `Bundle:Vacio` |
| Tarjeta de jugador Glaciar | Developer Product | 39 | `Item:Card:Glaciar` |
| Tarjeta de jugador Infierno | Developer Product | 49 | `Item:Card:Infierno` |
| Tarjeta de jugador Oro real | Developer Product | 49 | `Item:Card:Oro` |
| Tarjeta de jugador Vacío | Developer Product | 49 | `Item:Card:Vacio` |
| Colgante Bala dorada | Developer Product | 39 | `Item:Charm:Bala` |
| Colgante Calavera roja | Developer Product | 49 | `Item:Charm:Calaverita` |
| Colgante Chapa militar | Developer Product | 29 | `Item:Charm:Chapa` |
| Efecto de baja Choque rojo | Developer Product | 99 | `Item:KillEffect:ChoqueRojo` |
| Efecto de baja Destello dorado | Developer Product | 99 | `Item:KillEffect:OroFlash` |
| Efecto de baja Estallido píxel | Developer Product | 79 | `Item:KillEffect:Pixel` |
| Intro de MVP Lluvia de ascuas | Developer Product | 89 | `Item:MVPIntro:Ascuas` |
| Intro de MVP Columna de luz | Developer Product | 99 | `Item:MVPIntro:Columna` |
| Traje de operador Ártico táctico | Developer Product | 149 | `Item:Outfit:ArticoTactico` |
| Traje de operador Operación Roja | Developer Product | 199 | `Item:Outfit:OperacionRoja` |
| Pose de victoria Brazos cruzados | Developer Product | 79 | `Item:Pose:Brazos` |
| Pose de victoria Saludo | Developer Product | 79 | `Item:Pose:Saludo` |
| Pose de victoria Señala al frente | Developer Product | 99 | `Item:Pose:Senala` |
| Skin de arma Ártico táctico | Developer Product | 129 | `Item:Skin:ArticoTactico` |
| Skin de arma Callejero | Developer Product | 129 | `Item:Skin:Callejero` |
| Skin de arma Ciber | Developer Product | 149 | `Item:Skin:Ciber` |
| Skin de arma Grieta del vacío | Developer Product | 199 | `Item:Skin:GrietaVacio` |
| Skin de arma Inferno | Developer Product | 179 | `Item:Skin:Inferno` |
| Skin de arma Operación Roja | Developer Product | 179 | `Item:Skin:OperacionRoja` |
| VIP | Game Pass | 299 | `VIP` |

Las descripciones completas están en `scripts/monetizacion/productos.json`. La tabla se regenera con
`python -X utf8 scripts/monetizacion/tabla.py`.

### Iconos

Cada producto tiene su icono de 512×512 en `assets/tienda/iconos` (vista de todos:
`assets/tienda/iconos_vista.jpg`). El dibujo se generó con ChatGPT en hojas de 3×3 sin texto
(`assets/tienda/arte`); `scripts/monetizacion/iconos.py` recorta cada casilla y le pone la categoría y
el nombre. Estos iconos son los que salen en la ventana de compra de Roblox y en la página de la
experiencia; dentro del juego la tienda sigue usando sus propias vistas en 3D.

## 4. Cuánto llega de cada venta

- Roblox se queda el **30 %** de cada venta dentro de la experiencia; al creador le llega el **70 %**,
  en Robux.
- Para convertir Robux en dinero (DevEx) hacen falta al menos **30 000 Robux ganados** y cumplir los
  requisitos de la cuenta. El cambio que citan las guías es de **0,0035 a 0,0038 USD por Robux**.
  **Confírmalo en la página oficial de DevEx antes de hacer cuentas**: estas cifras salen de guías de
  terceros, no coinciden entre sí y cambian.

Con el cambio de 0,0038 USD, como orden de magnitud:

| Venta | Precio | Te llega | Aprox. en USD |
|---|---|---|---|
| Colgante | 29 R$ | 20 R$ | 0,08 |
| Skin de arma | 179 R$ | 125 R$ | 0,48 |
| VIP | 299 R$ | 209 R$ | 0,80 |
| Pase premium | 399 R$ | 279 R$ | 1,06 |
| Monedas «Bóveda» | 449 R$ | 314 R$ | 1,19 |

Para llegar al mínimo de DevEx hacen falta unos 43 000 R$ en ventas: por ejemplo, 108 pases premium.
**Aquí no hay ninguna previsión de ingresos**: depende de cuánta gente juegue y de cuántos compren, y
eso no se sabe hasta tener jugadores.

## 5. Qué mirar cuando haya jugadores

En el Creator Hub (*Analytics* → *Monetization*) y con los eventos propios del juego:

1. **Cuántos abren la tienda** (`store_open`) frente a cuántos entran al juego.
2. **Cuántos abren una compra** (`purchase_prompt`) y **cuántos la cancelan** (`purchase_cancel`). Si
   casi todos cancelan en un producto, ese precio está alto.
3. **Qué se vende** (`purchase_success` por producto). Lo que no se vende en un mes se baja o se cambia.
4. **Compradores sobre jugadores** e **ingreso por comprador**: los dos números que dicen si es
   rentable.

## 6. Decisiones que son tuyas

Ninguna está tomada por mí; lo que hay hoy en el juego es la columna «Ahora».

| Decisión | Ahora | La alternativa | Recomendación |
|---|---|---|---|
| **Precios regionales** | Sin activar | Roblox baja el precio en países con menos poder de compra | Activarlos (`5_CREAR_PRODUCTOS_TIENDA.bat --regional`): más compradores en Latinoamérica, y lo gestiona Roblox |
| **Pagar por ventaja** (armas, daño, revivir) | Apagado | Venderlo | Mantenerlo apagado: en un shooter competitivo espanta a quien no paga, y sin jugadores no hay compradores |
| **Cajas o ruleta de pago** | Apagado | Venderlas | Mantenerlo apagado: el azar de pago tiene normas propias en Roblox y restricciones por país |
| **VIP** | Game Pass, pago único de 299 R$ | Suscripción mensual de Roblox | Empezar con el Game Pass; la suscripción solo compensa con jugadores fieles |
| **Anuncios** (vídeo con recompensa, vallas en el mapa) | No hay | Añadirlos | Esperar a tener jugadores |
| **Servidores privados de pago** | Sin decidir | Cobrarlos (se configura en el Dashboard, sin código) | Probarlo: sirve para jugar con amigos |

## 7. Lo que no está comprobado

- **Ninguna compra real.** Todo está probado con pruebas automáticas (compra correcta, recibo repetido,
  desconexión, fallo de guardado) y con ids ficticios; nunca con un producto de verdad.
- **El guardado de lo comprado**, que depende de publicar.
- **El script de creación** contra el Roblox real (solo contra uno simulado): al final los productos
  se crearon a mano en el Creator Hub.
- **Que Roblox apruebe los iconos**: están subidos, pero pasan por su moderación de imágenes.
- **La tienda en un móvil.**

## 8. Mantenimiento

- **Producto nuevo**: se añade donde vive su definición (`ECONOMY.md`, sección 11), se añade su línea
  a 0 en `ProductIds.luau` y se regenera la lista. El comando falla si a `ProductIds.luau` le falta o le
  sobra alguna línea:

```bash
cd tests/harness && lune run ../../tools/economy/productos.luau ../../src
```

- **Temporada 2 del pase**: antes del 1 de enero de 2027 (nueva entrada en `BattlePassConfig.Seasons` y
  su línea `PassPremium:S2`).
- **Pack de Halloween**: deja de venderse solo el 4 de noviembre de 2026. El de Navidad se vende del
  1 de diciembre al 8 de enero.
