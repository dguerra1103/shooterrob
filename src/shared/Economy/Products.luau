-- Productos con Robux (Developer Products y Game Passes): un solo registro con su ProductId y su
-- precio. La interfaz NUNCA lleva ids escritos: los pide aquí.
--
-- IMPORTANTE: los ids se crean en el Creator Dashboard (Monetización → Developer Products / Passes)
-- y se pegan aquí. Con ProductId = 0 el producto sale como "PRÓXIMAMENTE" y no se puede comprar.
-- Los precios de abajo son orientativos (los de verdad son los del Dashboard; la tienda los pide a
-- MarketplaceService:GetProductInfo cuando el id existe).
--
-- Ya existían (y se siguen configurando donde estaban, en Shared/Shop): packs de monedas
-- (Shop.CoinPacks), potenciadores (Shop.Boosters), pack de inicio (Shop.StarterPack), packs
-- (Shop.Bundles) y el VIP (Shop.VIPPassId). Aquí se juntan todos para buscarlos por id.
local Shared = script.Parent.Parent
local Shop = require(Shared.Shop)
local BattlePassConfig = require(script.Parent.BattlePassConfig)
local MonetizationConfig = require(script.Parent.MonetizationConfig)

local Products = {}

-- Objetos sueltos con Robux. Clave "Tipo:Id" (ver CosmeticCatalog). Tramos de precio:
--   29-49   colgantes, grafitis, tarjetas
--   59-99   efectos de baja, poses, intros de MVP
--   129-199 skins de arma y trajes de operador
Products.Items = {
	-- Skins de arma
	["Skin:Inferno"] = { ProductId = 0, Robux = 179 }, -- TODO: SET IN CREATOR DASHBOARD
	["Skin:Ciber"] = { ProductId = 0, Robux = 149 }, -- TODO: SET IN CREATOR DASHBOARD
	["Skin:ArticoTactico"] = { ProductId = 0, Robux = 129 }, -- TODO: SET IN CREATOR DASHBOARD
	["Skin:Callejero"] = { ProductId = 0, Robux = 129 }, -- TODO: SET IN CREATOR DASHBOARD
	["Skin:GrietaVacio"] = { ProductId = 0, Robux = 199 }, -- TODO: SET IN CREATOR DASHBOARD
	["Skin:OperacionRoja"] = { ProductId = 0, Robux = 179 }, -- TODO: SET IN CREATOR DASHBOARD
	-- Trajes de operador
	["Outfit:OperacionRoja"] = { ProductId = 0, Robux = 199 }, -- TODO: SET IN CREATOR DASHBOARD
	["Outfit:ArticoTactico"] = { ProductId = 0, Robux = 149 }, -- TODO: SET IN CREATOR DASHBOARD
	-- Colgantes
	["Charm:Chapa"] = { ProductId = 0, Robux = 29 }, -- TODO: SET IN CREATOR DASHBOARD
	["Charm:Bala"] = { ProductId = 0, Robux = 39 }, -- TODO: SET IN CREATOR DASHBOARD
	["Charm:Calaverita"] = { ProductId = 0, Robux = 49 }, -- TODO: SET IN CREATOR DASHBOARD
	-- Efectos de baja
	["KillEffect:Pixel"] = { ProductId = 0, Robux = 79 }, -- TODO: SET IN CREATOR DASHBOARD
	["KillEffect:OroFlash"] = { ProductId = 0, Robux = 99 }, -- TODO: SET IN CREATOR DASHBOARD
	["KillEffect:ChoqueRojo"] = { ProductId = 0, Robux = 99 }, -- TODO: SET IN CREATOR DASHBOARD
	-- Poses de victoria
	["Pose:Saludo"] = { ProductId = 0, Robux = 79 }, -- TODO: SET IN CREATOR DASHBOARD
	["Pose:Brazos"] = { ProductId = 0, Robux = 79 }, -- TODO: SET IN CREATOR DASHBOARD
	["Pose:Senala"] = { ProductId = 0, Robux = 99 }, -- TODO: SET IN CREATOR DASHBOARD
	-- Intros de MVP
	["MVPIntro:Ascuas"] = { ProductId = 0, Robux = 89 }, -- TODO: SET IN CREATOR DASHBOARD
	["MVPIntro:Columna"] = { ProductId = 0, Robux = 99 }, -- TODO: SET IN CREATOR DASHBOARD
	-- Tarjetas de jugador
	["Card:Glaciar"] = { ProductId = 0, Robux = 39 }, -- TODO: SET IN CREATOR DASHBOARD
	["Card:Infierno"] = { ProductId = 0, Robux = 49 }, -- TODO: SET IN CREATOR DASHBOARD
	["Card:Oro"] = { ProductId = 0, Robux = 49 }, -- TODO: SET IN CREATOR DASHBOARD
	["Card:Vacio"] = { ProductId = 0, Robux = 49 }, -- TODO: SET IN CREATOR DASHBOARD
}

-- Un nivel del pase (solo se ofrece dentro de la pantalla del pase)
Products.TierSkip = { ProductId = 0, Robux = 49, Tiers = 1 } -- TODO: SET IN CREATOR DASHBOARD

function Products.Key(kind, id)
	return tostring(kind) .. ":" .. tostring(id)
end

function Products.Item(kind, id)
	return Products.Items[Products.Key(kind, id)]
end

-- ¿Se puede comprar ya? (id puesto)
function Products.Enabled(entry)
	return type(entry) == "table" and type(entry.ProductId) == "number" and entry.ProductId ~= 0
end

-- Lo que trae un pack, como lista de { Kind, Id } (los packs antiguos lo tienen en campos sueltos)
function Products.BundleItems(bundle)
	local list = {}
	local function add(kind, id)
		if id then
			table.insert(list, { Kind = kind, Id = id })
		end
	end
	for _, key in bundle.Items or {} do
		local kind, id = string.match(key, "^(%w+):(.+)$")
		add(kind, id)
	end
	for _, outfitId in bundle.Outfits or {} do
		add("Outfit", outfitId)
	end
	add("Outfit", bundle.Outfit)
	add("Skin", bundle.Skin)
	add("KillEffect", bundle.KillEffect)
	add("Charm", bundle.Charm)
	add("Spray", bundle.Spray)
	add("Card", bundle.Card)
	add("Pose", bundle.Pose)
	add("MVPIntro", bundle.MVPIntro)
	return list
end

-- Lo que vale por separado lo de un pack (solo precios que existen de verdad): Robux de los objetos
-- que se venden con Robux y monedas de los que se venden con monedas. coinPrice(kind, id) da el
-- precio en monedas (sin ofertas); lo pasa CosmeticCatalog para no depender de él aquí.
function Products.BundleValue(bundle, coinPrice)
	local robux, coins, priced, total = 0, bundle.Coins or 0, 0, 0
	for _, item in Products.BundleItems(bundle) do
		total += 1
		local entry = Products.Item(item.Kind, item.Id)
		local price = coinPrice and coinPrice(item.Kind, item.Id)
		if entry then
			robux += entry.Robux
			priced += 1
		elseif price then
			coins += price
			priced += 1
		end
	end
	-- (Complete = todo tiene precio: solo entonces se puede enseñar "por separado: X")
	return { Robux = robux, Coins = coins, Complete = priced == total }
end

-- Todos los productos con id (para buscarlos al llegar un recibo)
local function each(callback)
	for _, pack in Shop.CoinPacks do
		callback("Coins", pack, pack.Name)
	end
	for _, booster in Shop.Boosters do
		callback("Booster", booster, booster.Id)
	end
	callback("Starter", Shop.StarterPack, "Starter")
	for _, bundle in Shop.Bundles do
		callback("Bundle", bundle, bundle.Id)
	end
	for key, entry in Products.Items do
		callback("Item", entry, key)
	end
	for _, season in BattlePassConfig.Seasons do
		callback("PassPremium", season.Premium, season.Id)
	end
	callback("TierSkip", Products.TierSkip, "TierSkip")
	-- (ya no se venden, pero un recibo pendiente se sigue entregando)
	for _, pack in Shop.RevivePacks do
		callback("Revives", pack, pack.Name)
	end
	callback("WheelSpins", { ProductId = Shop.Wheel.SpinProductId }, "Wheel")
end

-- Qué es un ProductId: { Type, Def, Key } o nil
function Products.Resolve(productId)
	if type(productId) ~= "number" or productId == 0 then
		return nil
	end
	local found
	each(function(kind, def, key)
		if not found and def and def.ProductId == productId then
			found = { Type = kind, Def = def, Key = key }
		end
	end)
	return found
end

-- Lista de todos (para comprobar que no hay ids repetidos)
function Products.All()
	local list = {}
	each(function(kind, def, key)
		table.insert(list, { Type = kind, Def = def, Key = key })
	end)
	return list
end

-- ¿Se vende ahora? (los apagados en MonetizationConfig.Rules no se ofrecen)
function Products.ForSale(kind)
	local rules = MonetizationConfig.Rules
	if kind == "Revives" then
		return rules.SellRevives
	elseif kind == "WheelSpins" then
		return rules.PaidWheelSpins
	end
	return true
end

return Products
