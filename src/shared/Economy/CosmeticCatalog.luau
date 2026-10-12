-- Catálogo único de cosméticos: una sola forma de preguntar por cualquier objeto (skin de arma,
-- traje, colgante, tarjeta, título, efecto de baja, intro de MVP, pose, grafiti) sin repetir la
-- lógica de cada lista. Las definiciones siguen en sus módulos de siempre (Skins, Outfits,
-- Charms...); aquí se juntan con su precio (monedas en Shop, Robux en Economy/Products), de dónde se
-- consigue, si lo tienes y si lo llevas puesto. Las rarezas son las de siempre y NUNCA cambian
-- estadísticas.
local Shared = script.Parent.Parent
local Skins = require(Shared.Skins)
local Icons = require(Shared.Icons)
local Outfits = require(Shared.Outfits)
local Charms = require(Shared.Charms)
local KillEffects = require(Shared.KillEffects)
local Sprays = require(Shared.Sprays)
local Titles = require(Shared.Titles)
local Poses = require(Shared.Poses)
local PlayerCards = require(Shared.PlayerCards)
local Shop = require(Shared.Shop)
local Products = require(script.Parent.Products)
local BattlePassConfig = require(script.Parent.BattlePassConfig)
local MonetizationConfig = require(script.Parent.MonetizationConfig)

local Catalog = {}

-- Tipo → su lista, dónde se guarda lo que tienes y lo que llevas, y su sección de la tienda
Catalog.Kinds = {
	Skin = { List = Skins.List, Owned = "Skins", Equipped = "EquippedSkin", Default = "Default", Label = "SKIN DE ARMA", Category = "ARMAS", Icon = Icons.Rifle },
	Outfit = { List = Outfits.List, Owned = "Outfits", Equipped = "EquippedOutfit", Default = "Default", Label = "TRAJE DE OPERADOR", Category = "OPERADORES", Icon = Icons.Helmet },
	Charm = { List = Charms.List, Owned = "Charms", Equipped = "EquippedCharm", Default = "Default", Label = "COLGANTE", Category = "CHARMS", Icon = Icons.Keychain },
	Card = { List = PlayerCards.List, Owned = "Cards", Equipped = "EquippedCard", Default = "Default", Label = "TARJETA DE JUGADOR", Category = "CHARMS", Icon = Icons.IdCard },
	Title = { List = Titles.List, Owned = "Titles", Equipped = "EquippedTitle", Default = "Novato", Label = "TÍTULO", Category = "CHARMS", Icon = Icons.Ribbon },
	KillEffect = { List = KillEffects.List, Owned = "KillEffects", Equipped = "EquippedKillEffect", Default = "Default", Label = "EFECTO DE BAJA", Category = "EFECTOS", Icon = Icons.Explosion },
	MVPIntro = { List = Poses.Intros, Owned = "MVPIntros", Equipped = "EquippedMVPIntro", Default = Poses.DefaultIntro, Label = "INTRO DE MVP", Category = "EFECTOS", Icon = Icons.Spotlight },
	Pose = { List = Poses.List, Owned = "Poses", Equipped = "EquippedPose", Default = Poses.Default, Label = "POSE DE VICTORIA", Category = "EMOTES", Icon = Icons.Pose },
	Spray = { List = Sprays.List, Owned = "Sprays", Equipped = "EquippedSpray", Default = "Default", Label = "GRAFITI", Category = "EMOTES", Icon = Icons.Spray },
}
Catalog.KindOrder = { "Skin", "Outfit", "Charm", "Card", "Title", "KillEffect", "MVPIntro", "Pose", "Spray" }

-- Secciones de la tienda
Catalog.Categories = {
	{ Id = "FEATURED", Text = "DESTACADO", Icon = "⭐" },
	{ Id = "ARMAS", Text = "ARMAS", Icon = "🔫", Kinds = { "Skin" } },
	{ Id = "OPERADORES", Text = "OPERADORES", Icon = "🎖", Kinds = { "Outfit" } },
	{ Id = "CHARMS", Text = "CHARMS", Icon = "🔑", Kinds = { "Charm", "Card", "Title" } },
	{ Id = "EFECTOS", Text = "EFECTOS", Icon = "💥", Kinds = { "KillEffect", "MVPIntro" } },
	{ Id = "EMOTES", Text = "POSES", Icon = "🙌", Kinds = { "Pose", "Spray" } },
	{ Id = "BUNDLES", Text = "PACKS", Icon = "📦" },
	{ Id = "PASS", Text = "PASE", Icon = "🎖️" },
	{ Id = "COINS", Text = "MONEDAS", Icon = "💰" },
}

Catalog.RarityOrder = { "Común", "Raro", "Épico", "Legendario", "Mítico" }
Catalog.RarityColors = Skins.RarityColors

function Catalog.RarityRank(rarity)
	return table.find(Catalog.RarityOrder, rarity) or 1
end

-- Legendario o más: presentación algo mejor (escena de compra con desenfoque y giro)
function Catalog.IsPremiumRarity(rarity)
	return Catalog.RarityRank(rarity) >= 4
end

function Catalog.Key(kind, id)
	return tostring(kind) .. ":" .. tostring(id)
end

function Catalog.ParseKey(key)
	if type(key) ~= "string" then
		return nil, nil
	end
	return string.match(key, "^(%w+):(.+)$")
end

function Catalog.Def(kind, id)
	local spec = Catalog.Kinds[kind]
	return spec and type(id) == "string" and spec.List[id] or nil
end

function Catalog.Exists(kind, id)
	return Catalog.Def(kind, id) ~= nil
end

-- Objetos que salen en el pase (de cualquier temporada): no se venden en la tienda
local passItems = {}
for _, season in BattlePassConfig.Seasons do
	for _, tier in season.Tiers do
		for _, reward in { tier.Free, tier.Premium } do
			if reward and reward.Id then
				passItems[Catalog.Key(reward.Type, reward.Id)] = season.Id
			end
		end
	end
end

-- De dónde se consigue: "Robux", "Coins", "Pass", "Event", "Mastery", "Bonus", "Default", "Stat",
-- "VIP" o "None"
function Catalog.Source(kind, id)
	local def = Catalog.Def(kind, id)
	if not def then
		return "None"
	end
	local spec = Catalog.Kinds[kind]
	if id == spec.Default then
		return "Default"
	end
	if Products.Item(kind, id) then
		return "Robux"
	end
	if def.Mastery then
		return "Mastery"
	end
	if def.Event then
		return "Event"
	end
	if def.Bonus then
		return "Bonus"
	end
	if def.VIPOnly then
		return "VIP"
	end
	if Shop.BasePrice(kind, id) then
		return "Coins"
	end
	if def.Stat then
		return "Stat"
	end
	if def.Pass or passItems[Catalog.Key(kind, id)] then
		return "Pass"
	end
	return "None"
end

-- ¿Lo tiene? data = datos del jugador (servidor) o su vista (cliente)
function Catalog.Owns(data, kind, id, isVIP)
	local spec = Catalog.Kinds[kind]
	if not spec or not data or not Catalog.Exists(kind, id) then
		return false
	end
	if kind == "Title" then
		return Titles.Owns(data, id, isVIP)
	end
	if kind == "Spray" and Sprays.List[id].VIPOnly then
		return isVIP == true
	end
	if id == spec.Default then
		return true
	end
	local owned = data[spec.Owned]
	return type(owned) == "table" and owned[id] == true
end

function Catalog.Equipped(data, kind)
	local spec = Catalog.Kinds[kind]
	if not spec or not data then
		return nil
	end
	return data[spec.Equipped] or spec.Default
end

function Catalog.IsEquipped(data, kind, id)
	return Catalog.Equipped(data, kind) == id
end

-- ¿Se puede llevar puesto? (los camuflajes de maestría van por arma, no aquí)
function Catalog.Equippable(kind, id)
	local def = Catalog.Def(kind, id)
	return def ~= nil and not def.Mastery
end

-- Precio en monedas (con la oferta del día si la hay) y precio en Robux (si se vende con Robux)
function Catalog.CoinPrice(kind, id, day)
	if Products.Item(kind, id) then
		return nil, false -- (lo de Robux no se vende con monedas)
	end
	return Shop.GetPrice(kind, id, day)
end

function Catalog.BaseCoinPrice(kind, id)
	if Products.Item(kind, id) then
		return nil
	end
	return Shop.BasePrice(kind, id)
end

function Catalog.Robux(kind, id)
	return Products.Item(kind, id)
end

-- Ficha completa para la tienda y la escena de compra
function Catalog.Item(kind, id, day)
	local def = Catalog.Def(kind, id)
	if not def then
		return nil
	end
	local spec = Catalog.Kinds[kind]
	local coins, onSale = Catalog.CoinPrice(kind, id, day)
	local robux = Products.Item(kind, id)
	return {
		Kind = kind,
		Id = id,
		Key = Catalog.Key(kind, id),
		Name = def.Name or id,
		Rarity = def.Rarity or "Común",
		Icon = def.Icon or spec.Icon,
		Description = def.Description,
		Collection = def.Collection,
		Label = spec.Label,
		Category = spec.Category,
		Coins = coins,
		BaseCoins = Catalog.BaseCoinPrice(kind, id),
		OnSale = onSale,
		Robux = robux and robux.Robux or nil,
		ProductId = robux and robux.ProductId or nil,
		Source = Catalog.Source(kind, id),
	}
end

-- Lo que se vende (con monedas o Robux) de unos tipos, de más a menos raro
function Catalog.StoreItems(kinds, day)
	local list = {}
	for _, kind in kinds or Catalog.KindOrder do
		for id in Catalog.Kinds[kind].List do
			local source = Catalog.Source(kind, id)
			if source == "Coins" or source == "Robux" then
				table.insert(list, Catalog.Item(kind, id, day))
			end
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = Catalog.RarityRank(a.Rarity), Catalog.RarityRank(b.Rarity)
		if ra ~= rb then
			return ra > rb
		end
		if (a.Robux ~= nil) ~= (b.Robux ~= nil) then
			return a.Robux ~= nil
		end
		return a.Key < b.Key
	end)
	return list
end

-- Da un objeto (devuelve true si es nuevo). Solo lo llama el servidor.
function Catalog.Grant(data, kind, id)
	local spec = Catalog.Kinds[kind]
	if not spec or not Catalog.Exists(kind, id) then
		return false
	end
	if Catalog.Owns(data, kind, id) then
		return false
	end
	if type(data[spec.Owned]) ~= "table" then
		data[spec.Owned] = {}
	end
	data[spec.Owned][id] = true
	return true
end

-- Quita un objeto (para deshacer una compra que no se pudo guardar)
function Catalog.Revoke(data, kind, id)
	local spec = Catalog.Kinds[kind]
	if spec and type(data[spec.Owned]) == "table" then
		data[spec.Owned][id] = nil
		if data[spec.Equipped] == id then
			data[spec.Equipped] = spec.Default
		end
	end
end

-- NUEVO: está en la lista de novedades y aún no lo has visto en la tienda
local newSet = {}
for _, key in MonetizationConfig.NewItems do
	newSet[key] = true
end
function Catalog.IsNewItem(key)
	return newSet[key] == true
end
function Catalog.IsNew(data, kind, id)
	local key = Catalog.Key(kind, id)
	if not newSet[key] then
		return false
	end
	local seen = data and data.SeenItems
	return not (type(seen) == "table" and seen[key] == true)
end

-- Monedas que se devuelven por un objeto que ya tenías al comprar un pack con Robux
function Catalog.Compensation(kind, id)
	local coins = Shop.BasePrice(kind, id)
	if coins and not Products.Item(kind, id) then
		return coins
	end
	local robux = Products.Item(kind, id)
	return math.floor((robux and robux.Robux or 0) * MonetizationConfig.Bundles.CoinsPerRobux)
end

-- Lo que vale por separado un pack (precios reales)
function Catalog.BundleValue(bundle)
	return Products.BundleValue(bundle, function(kind, id)
		return Catalog.BaseCoinPrice(kind, id)
	end)
end

-- Qué tienes ya de un pack: { Owned = n, Total = n, Missing = {items}, Compensation = monedas }
function Catalog.BundleStatus(data, bundle, isVIP)
	local status = { Owned = 0, Total = 0, Missing = {}, Compensation = 0 }
	for _, item in Products.BundleItems(bundle) do
		status.Total += 1
		if Catalog.Owns(data, item.Kind, item.Id, isVIP) then
			status.Owned += 1
			status.Compensation += Catalog.Compensation(item.Kind, item.Id)
		else
			table.insert(status.Missing, item)
		end
	end
	return status
end

return Catalog
