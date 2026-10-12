-- IDS DE LOS PRODUCTOS DE PAGO. Este es el ÚNICO archivo que hay que tocar para que la tienda venda.
--
-- Cada línea es un producto creado en el Creator Dashboard (Monetización) de la experiencia:
--   Products   = Developer Products (se pueden comprar muchas veces o una, según el producto)
--   GamePasses = Game Passes (se compran una vez y son para siempre)
-- Con 0 el producto sale en la tienda como «PRÓXIMAMENTE» y no se puede comprar. Con su id, se vende.
--
-- Cómo rellenarlo:
--   A mano: crea cada producto (nombre y precio en MONETIZACION.md) y pega aquí su id.
--   Automático: scripts/monetizacion/crear_productos.py los crea todos con tu clave de Open Cloud y
--   escribe los ids en este archivo.
--
-- Los ids NO son secretos (van en el juego); la clave de Open Cloud sí lo es y nunca se escribe aquí.
local ProductIds = {}

ProductIds.GamePasses = {
	VIP = 0,
}

ProductIds.Products = {
	-- Monedas
	["Coins:Puñado"] = 0,
	["Coins:Bolsa"] = 0,
	["Coins:Cofre"] = 0,
	["Coins:Bóveda"] = 0,
	-- Potenciadores (30 minutos)
	["Booster:XP2"] = 0,
	["Booster:Coins2"] = 0,
	-- Pack de inicio (solo jugadores nuevos, una vez)
	["Starter:Starter"] = 0,
	-- Pase de batalla
	["PassPremium:S1"] = 0,
	["TierSkip:TierSkip"] = 0,
	-- Packs
	["Bundle:RedOps"] = 0,
	["Bundle:Artico"] = 0,
	["Bundle:Vacio"] = 0,
	["Bundle:Aventurero"] = 0,
	["Bundle:Halloween"] = 0,
	["Bundle:Navidad"] = 0,
	-- Objetos sueltos
	["Item:Skin:Inferno"] = 0,
	["Item:Skin:Ciber"] = 0,
	["Item:Skin:ArticoTactico"] = 0,
	["Item:Skin:Callejero"] = 0,
	["Item:Skin:GrietaVacio"] = 0,
	["Item:Skin:OperacionRoja"] = 0,
	["Item:Outfit:OperacionRoja"] = 0,
	["Item:Outfit:ArticoTactico"] = 0,
	["Item:Charm:Chapa"] = 0,
	["Item:Charm:Bala"] = 0,
	["Item:Charm:Calaverita"] = 0,
	["Item:KillEffect:Pixel"] = 0,
	["Item:KillEffect:OroFlash"] = 0,
	["Item:KillEffect:ChoqueRojo"] = 0,
	["Item:Pose:Saludo"] = 0,
	["Item:Pose:Brazos"] = 0,
	["Item:Pose:Senala"] = 0,
	["Item:MVPIntro:Ascuas"] = 0,
	["Item:MVPIntro:Columna"] = 0,
	["Item:Card:Glaciar"] = 0,
	["Item:Card:Infierno"] = 0,
	["Item:Card:Oro"] = 0,
	["Item:Card:Vacio"] = 0,
}

-- Id de un producto (0 si aún no existe). kind y key como en Economy/Products (p. ej. "Item", "Skin:Inferno")
function ProductIds.Get(kind, key)
	local id = ProductIds.Products[tostring(kind) .. ":" .. tostring(key)]
	return type(id) == "number" and id or 0
end

-- Pone el id en la definición de un producto si ya existe (si no, la deja como estaba)
function ProductIds.Apply(def, kind, key)
	local id = ProductIds.Get(kind, key)
	if id ~= 0 and type(def) == "table" then
		def.ProductId = id
	end
end

return ProductIds
