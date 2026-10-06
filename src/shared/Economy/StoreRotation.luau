-- Rotación de la tienda: lo mismo para todos y calculado con la hora (sin servidor que guardar):
--   · Tienda diaria: MonetizationConfig.DailyStore.Size objetos; cambia a las 00:00 UTC. Las 3
--     primeras son las "ofertas del día" de siempre (Shop.GetDailyOffers, con su descuento real).
--   · Destacado: un pack por semana (cambia el lunes 00:00 UTC).
--   · Tienda de evento: objetos y pack de un evento entre dos fechas.
-- Los relojes cuentan hasta esas horas de verdad: no hay reinicios falsos ni "última oportunidad".
-- Lo que sale de la rotación vuelve a salir otro día (no hay escasez falsa).
local Shared = script.Parent.Parent
local Shop = require(Shared.Shop)
local Challenges = require(Shared.Challenges)
local Catalog = require(script.Parent.CosmeticCatalog)
local MonetizationConfig = require(script.Parent.MonetizationConfig)

local StoreRotation = {}

-- Packs que van rotando en el destacado (Shop.Bundles, por Id)
StoreRotation.FeaturedBundles = { "RedOps", "Artico", "Vacio" }

-- Eventos de la tienda (hora UTC). Mientras duran, su sección sale en DESTACADO y en EVENTOS.
StoreRotation.Events = {
	{
		Id = "RedZone",
		Name = "OPERACIÓN ZONA ROJA",
		Text = "Colección Operación Roja: skin, traje, efecto, tarjeta y pose.",
		StartsAt = 1791244800, -- 6 oct 2026 00:00 UTC
		EndsAt = 1793664000, -- 3 nov 2026 00:00 UTC
		Bundle = "RedOps",
		Items = { "Skin:OperacionRoja", "Outfit:OperacionRoja", "KillEffect:ChoqueRojo", "Card:Infierno", "Pose:Senala", "Skin:Inferno" },
		Colors = { Color3.fromRGB(200, 20, 30), Color3.fromRGB(20, 8, 10) },
	},
}

function StoreRotation.DayNumber(now)
	return Shop.DayNumber(now)
end

-- Cuándo cambia la tienda diaria (segundos UTC)
function StoreRotation.DayEndsAt(now)
	return (Shop.DayNumber(now) + 1) * 86400
end

function StoreRotation.WeekEndsAt(now)
	return Challenges.WeekEndsAt(Challenges.WeekNumber(Shop.DayNumber(now)))
end

-- Los objetos de la tienda diaria: { Kind, Id, Offer = true/false }
function StoreRotation.Daily(day)
	day = day or Shop.DayNumber()
	local size = MonetizationConfig.DailyStore.Size
	local list, used = {}, {}
	for _, offer in Shop.GetDailyOffers(day) do
		if #list < size then
			table.insert(list, { Kind = offer.Kind, Id = offer.Id, Offer = true })
			used[Catalog.Key(offer.Kind, offer.Id)] = true
		end
	end
	-- El resto: primero objetos de Robux y luego de monedas, al azar del día (igual para todos)
	local robuxPool, coinPool = {}, {}
	for _, item in Catalog.StoreItems() do
		if not used[item.Key] then
			table.insert(item.Robux and robuxPool or coinPool, item)
		end
	end
	local rng = Random.new(day * 104729 + 17)
	local function take(pool)
		if #pool > 0 and #list < size then
			local item = table.remove(pool, rng:NextInteger(1, #pool))
			table.insert(list, { Kind = item.Kind, Id = item.Id, Offer = false })
		end
	end
	local robuxSlots = math.max(0, size - #list - 1)
	for _ = 1, robuxSlots do
		take(robuxPool)
	end
	while #list < size and (#coinPool > 0 or #robuxPool > 0) do
		take(#coinPool > 0 and coinPool or robuxPool)
	end
	return list
end

-- Pack destacado de la semana (puede no estar a la venta aún: ProductId 0)
function StoreRotation.FeaturedBundle(now)
	local ids = StoreRotation.FeaturedBundles
	if #ids == 0 then
		return nil
	end
	local week = Challenges.WeekNumber(Shop.DayNumber(now))
	local id = ids[week % #ids + 1]
	for _, bundle in Shop.Bundles do
		if bundle.Id == id then
			return bundle
		end
	end
	return nil
end

-- Evento de la tienda en marcha (o nil)
function StoreRotation.ActiveEvent(now)
	now = now or os.time()
	for _, event in StoreRotation.Events do
		if now >= event.StartsAt and now < event.EndsAt then
			return event
		end
	end
	return nil
end

function StoreRotation.BundleById(id)
	for _, bundle in Shop.Bundles do
		if bundle.Id == id then
			return bundle
		end
	end
	return nil
end

return StoreRotation
