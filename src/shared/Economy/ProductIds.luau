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
	VIP = 2029778289,
}

ProductIds.Products = {
	-- Monedas
	["Coins:Puñado"] = 3718230744,
	["Coins:Bolsa"] = 3718230940,
	["Coins:Cofre"] = 3718231061,
	["Coins:Bóveda"] = 3718231243,
	-- Potenciadores (30 minutos)
	["Booster:XP2"] = 3718231535,
	["Booster:Coins2"] = 3718231655,
	-- Pack de inicio (solo jugadores nuevos, una vez)
	["Starter:Starter"] = 3718231826,
	-- Pase de batalla
	["PassPremium:S1"] = 3718231935,
	["TierSkip:TierSkip"] = 3718232594,
	-- Packs
	["Bundle:RedOps"] = 3718237941,
	["Bundle:Artico"] = 3718238031,
	["Bundle:Vacio"] = 3718238126,
	["Bundle:Aventurero"] = 3718237666,
	["Bundle:Halloween"] = 3718233032,
	["Bundle:Navidad"] = 3718236488,
	-- Objetos sueltos
	["Item:Skin:Inferno"] = 3718242767,
	["Item:Skin:Ciber"] = 3718242356,
	["Item:Skin:ArticoTactico"] = 3718241820,
	["Item:Skin:Callejero"] = 3718242122,
	["Item:Skin:GrietaVacio"] = 3718242575,
	["Item:Skin:OperacionRoja"] = 3718242970,
	["Item:Outfit:OperacionRoja"] = 3718240271,
	["Item:Outfit:ArticoTactico"] = 3718240172,
	["Item:Charm:Chapa"] = 3718239198,
	["Item:Charm:Bala"] = 3718238890,
	["Item:Charm:Calaverita"] = 3718239001,
	["Item:KillEffect:Pixel"] = 3718239913,
	["Item:KillEffect:OroFlash"] = 3718239803,
	["Item:KillEffect:ChoqueRojo"] = 3718239702,
	["Item:Pose:Saludo"] = 3718240449,
	["Item:Pose:Brazos"] = 3718240366,
	["Item:Pose:Senala"] = 3718241590,
	["Item:MVPIntro:Ascuas"] = 3718239998,
	["Item:MVPIntro:Columna"] = 3718240091,
	["Item:Card:Glaciar"] = 3718238259,
	["Item:Card:Infierno"] = 3718238469,
	["Item:Card:Oro"] = 3718238578,
	["Item:Card:Vacio"] = 3718238758,
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
