-- Economía (compartido): catálogo, productos, rotación y pase
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Eco = game.ReplicatedStorage.Shared.Economy
local Catalog = req(Eco.CosmeticCatalog)
local Products = req(Eco.Products)
local Rotation = req(Eco.StoreRotation)
local BP = req(Eco.BattlePassConfig)
local Config = req(Eco.MonetizationConfig)
local Shop = req(game.ReplicatedStorage.Shared.Shop)
-- Productos: ningún id inventado; todo a 0 con precio en su tramo
for key, entry in Products.Items do
	check(entry.ProductId == 0, key .. " sin id inventado")
	local kind = string.match(key, "^(%w+):")
	local lo, hi = 29, 49
	if kind == "KillEffect" or kind == "Pose" or kind == "MVPIntro" then lo, hi = 59, 99 elseif kind == "Skin" or kind == "Outfit" then lo, hi = 129, 199 end
	check(entry.Robux >= lo and entry.Robux <= hi, key .. " precio en su tramo (" .. entry.Robux .. ")")
	local k, id = Catalog.ParseKey(key)
	check(Catalog.Exists(k, id), key .. " existe en el catálogo")
	check(Shop.BasePrice(k, id) == nil, key .. " no tiene también precio en monedas")
end
-- Packs: valor real por separado
for _, bundle in Shop.Bundles do
	local value = Catalog.BundleValue(bundle)
	check(value.Complete, bundle.Id .. ": todo lo del pack tiene precio real")
	for _, item in Products.BundleItems(bundle) do
		check(Catalog.Exists(item.Kind, item.Id), bundle.Id .. " trae " .. item.Kind .. ":" .. item.Id .. " que existe")
	end
	if bundle.Items then
		check(value.Robux > bundle.Robux, bundle.Id .. ": por separado " .. value.Robux .. " R$ > pack " .. bundle.Robux .. " R$")
		check(bundle.Robux >= 249 and bundle.Robux <= 399, bundle.Id .. " en el tramo de packs")
	end
end
-- Parcial: ya tienes uno
local data = { Skins = { Default = true, OperacionRoja = true }, Outfits = { Default = true }, KillEffects = {}, Cards = {}, Poses = {} }
local red = Rotation.BundleById("RedOps")
local status = Catalog.BundleStatus(data, red)
check(status.Owned == 1 and status.Total == 5 and #status.Missing == 4, "pack parcial: 1 de 5")
check(status.Compensation == 179 * Config.Bundles.CoinsPerRobux, "se devuelven monedas reales por lo que ya tenías")
-- Fuentes
check(Catalog.Source("Skin", "Inferno") == "Robux", "Inferno se vende con Robux")
check(Catalog.Source("Skin", "Sakura") == "Coins", "Sakura con monedas")
check(Catalog.Source("Card", "ZonaRoja") == "Pass", "tarjeta Zona Roja: del pase")
check(Catalog.Source("Card", "PrimerGolpe") == "Bonus", "Primer golpe: solo regalo")
check(Catalog.Source("Pose", "AlCielo") == "Coins", "pose con monedas")
check(Catalog.Owns(data, "Pose", "Ready") and Catalog.Owns(data, "Card", "Default") and Catalog.Owns(data, "MVPIntro", "Destello"), "lo básico se tiene siempre")
check(Catalog.Grant(data, "Card", "Oro") and data.Cards.Oro and not Catalog.Grant(data, "Card", "Oro"), "dar una tarjeta (una vez)")
-- Rotación diaria determinista
local d1 = Rotation.Daily(20000)
local d2 = Rotation.Daily(20000)
check(#d1 == Config.DailyStore.Size, "tienda diaria con " .. #d1 .. " objetos")
local seen = {}
for i, item in d1 do
	check(item.Kind == d2[i].Kind and item.Id == d2[i].Id, "la misma para todos ese día")
	check(not seen[item.Kind .. item.Id], "sin repetidos")
	seen[item.Kind .. item.Id] = true
end
check(Rotation.DayEndsAt(20000 * 86400 + 5) == 20001 * 86400, "cambia a medianoche UTC")
check(Rotation.ActiveEvent(1791244800 + 10) ~= nil and Rotation.ActiveEvent(1793664000) == nil, "evento entre sus fechas")
-- Pase
local s1 = BP.Get("S1")
check(#s1.Tiers == 50, "50 niveles")
for tier, t in s1.Tiers do
	for _, r in { t.Free, t.Premium } do
		if r then
			check(r.Type ~= "Crate", "nivel " .. tier .. ": sin cajas (azar) en el pase")
			if r.Id then check(Catalog.Exists(r.Type, r.Id), "nivel " .. tier .. ": " .. r.Type .. ":" .. r.Id .. " existe") end
		end
	end
end
check(BP.TierFor(0) == 1 and BP.TierFor(BP.XPPerTier - 1) == 1 and BP.TierFor(BP.XPPerTier) == 2 and BP.TierFor(10 ^ 9) == 50, "niveles por XP")
check(Products.Resolve(0) == nil, "id 0 no es nada")
print("CATALOGO OK")
process.exit(0)
