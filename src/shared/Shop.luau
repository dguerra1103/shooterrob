-- Catálogo de la tienda: precios en monedas, packs de Robux, VIP, recompensas diarias y cajas.
--
-- IMPORTANTE (Robux): crea los productos en el Creator Hub (Monetización) y pega sus IDs aquí.
--   Developer Products -> CoinPacks[i].ProductId y RevivePacks[i].ProductId
--   Game Pass VIP      -> VIPPassId
-- Con ID 0 el botón aparece desactivado ("Próximamente").
local Shop = {}

-- Packs de monedas (Developer Products, se pueden comprar varias veces)
Shop.CoinPacks = {
	{ Name = "Puñado", Coins = 500, Robux = 49, ProductId = 0 },
	{ Name = "Bolsa", Coins = 1200, Robux = 99, ProductId = 0, Tag = "+20%" },
	{ Name = "Cofre", Coins = 3000, Robux = 199, ProductId = 0, Tag = "MÁS VENDIDO" },
	{ Name = "Bóveda", Coins = 8000, Robux = 449, ProductId = 0, Tag = "MEJOR VALOR" },
}

-- Packs de "Revivir instantáneo" (Developer Products): vuelves a la acción justo donde caíste
Shop.RevivePacks = {
	{ Name = "5 revivir", Revives = 5, Robux = 25, ProductId = 0 },
	{ Name = "15 revivir", Revives = 15, Robux = 59, ProductId = 0, Tag = "MEJOR VALOR" },
}

-- Pack de inicio (Developer Product de compra única): solo se ofrece a jugadores nuevos.
-- Vale mucho más que su precio en Robux para que sea la primera compra fácil.
Shop.StarterPack = {
	ProductId = 0, -- pega aquí el ID del Developer Product
	Robux = 99,
	MaxLevel = 15, -- se deja de ofrecer a partir de este nivel
	Coins = 1500,
	Outfit = "BlazeRunner",
	Skin = "Sakura",
	KillEffect = "Confeti",
}

-- Ruleta diaria: un giro gratis al día y giros extra con Robux (Developer Product SpinProductId,
-- da SpinsPerPurchase giros). Los premios salen según su peso (Weight); las probabilidades se ven en
-- la propia ruleta. En los países donde los premios al azar de pago no están permitidos solo hay
-- giro gratis.
Shop.Wheel = {
	SpinProductId = 0, -- pega aquí el ID del Developer Product
	SpinRobux = 25,
	SpinsPerPurchase = 3,
	Prizes = {
		{ Kind = "Coins", Amount = 50, Weight = 28, Color = Color3.fromRGB(90, 160, 255) },
		{ Kind = "Coins", Amount = 100, Weight = 24, Color = Color3.fromRGB(255, 200, 60) },
		{ Kind = "Revives", Amount = 1, Weight = 12, Color = Color3.fromRGB(80, 210, 120) },
		{ Kind = "Coins", Amount = 250, Weight = 12, Color = Color3.fromRGB(255, 120, 60) },
		{ Kind = "XP", Amount = 400, Weight = 10, Color = Color3.fromRGB(120, 220, 255) },
		{ Kind = "Crate", Amount = 1, Weight = 8, Color = Color3.fromRGB(180, 100, 255) },
		{ Kind = "Coins", Amount = 600, Weight = 5, Color = Color3.fromRGB(255, 80, 140) },
		{ Kind = "Coins", Amount = 2000, Weight = 1, Color = Color3.fromRGB(255, 230, 90), Jackpot = true },
	},
}

-- Texto corto de un premio de la ruleta
function Shop.WheelPrizeText(prize)
	if prize.Kind == "Coins" then
		return prize.Amount .. " 🪙"
	elseif prize.Kind == "Revives" then
		return prize.Amount .. " ❤️"
	elseif prize.Kind == "XP" then
		return prize.Amount .. " XP"
	elseif prize.Kind == "Crate" then
		return prize.Amount .. " 📦"
	end
	return "?"
end

-- Pase VIP (Game Pass): x2 XP y x2 monedas, nombre dorado y caja diaria extra
Shop.VIPPassId = 0
Shop.VIPRobux = 299
Shop.VIPMultiplier = 2

-- Precio en monedas de cada skin de arma
Shop.SkinPrices = {
	Toxico = 400,
	Selva = 300,
	Oceano = 600,
	Atardecer = 600,
	Sakura = 800,
	Hielo = 800,
	Calabaza = 1200,
	Vacio = 1500,
	Dorado = 2000,
	Galaxia = 2500,
	Dragon = 3000,
	Magma = 3000,
	CamoBosque = 700,
	CamoDesierto = 700,
	CamoDigital = 1200,
	CamoArtico = 1200,
	CamoTigre = 2200,
	CamoNebulosa = 3200,
	Prisma = 2800,
	Caramelo = 450,
	Juguete = 450,
	Tiki = 900,
	Pintura = 2200,
	Arcoiris = 4500,
}

-- Precio en monedas de cada traje de operador (ver Outfits)
Shop.OutfitPrices = {
	BlazeRunner = 1500,
	NeonRecon = 1500,
	VoltBruiser = 2000,
	FrostByte = 1200,
	ToxicRogue = 1200,
	GoldenAce = 4000,
}

-- Recompensa diaria: un día por entrada (al 7.º día se vuelve a empezar)
Shop.DailyRewards = { 100, 150, 200, 250, 300, 400, 800 }
Shop.DailyCrateDay = 7 -- ese día también regala una caja

-- Cajas (solo con monedas). Las probabilidades se muestran en la tienda.
-- Si te toca algo repetido te devolvemos parte de las monedas.
Shop.Crates = {
	Neon = {
		Name = "Caja Neón",
		Price = 600,
		Odds = {
			{ Rarity = "Raro", Weight = 55 },
			{ Rarity = "Épico", Weight = 30 },
			{ Rarity = "Legendario", Weight = 12 },
			{ Rarity = "Mítico", Weight = 3 },
		},
		DuplicateRefund = 0.4,
	},
}

-- Ofertas del día: 3 objetos con descuento, iguales para todos y distintos cada día
Shop.OfferDiscount = 0.3

local function dayNumber(time)
	return math.floor((time or os.time()) / 86400)
end
Shop.DayNumber = dayNumber

local KillEffects = require(script.Parent.KillEffects)
local Charms = require(script.Parent.Charms)

function Shop.GetDailyOffers(day)
	day = day or dayNumber()
	local pool = {}
	for id in Shop.SkinPrices do
		table.insert(pool, { Kind = "Skin", Id = id })
	end
	for id in Shop.OutfitPrices do
		table.insert(pool, { Kind = "Outfit", Id = id })
	end
	for id, effect in KillEffects.List do
		if effect.Price then
			table.insert(pool, { Kind = "KillEffect", Id = id })
		end
	end
	table.sort(pool, function(a, b)
		return a.Kind .. a.Id < b.Kind .. b.Id
	end)
	local rng = Random.new(day * 7919)
	local offers = {}
	for _ = 1, math.min(3, #pool) do
		local item = table.remove(pool, rng:NextInteger(1, #pool))
		table.insert(offers, item)
	end
	return offers
end

-- Precio actual (con descuento si está en oferta hoy)
function Shop.GetPrice(kind, id, day)
	local base
	if kind == "Skin" then
		base = Shop.SkinPrices[id]
	elseif kind == "Outfit" then
		base = Shop.OutfitPrices[id]
	elseif kind == "KillEffect" then
		local effect = KillEffects.List[id]
		base = effect and effect.Price
	elseif kind == "Charm" then
		local charm = Charms.List[id]
		base = charm and charm.Price
	end
	if not base then
		return nil, false
	end
	for _, offer in Shop.GetDailyOffers(day) do
		if offer.Kind == kind and offer.Id == id then
			return math.floor(base * (1 - Shop.OfferDiscount) / 10 + 0.5) * 10, true
		end
	end
	return base, false
end

return Shop
