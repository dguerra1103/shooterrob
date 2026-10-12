-- Lista de todos los productos de pago del juego, sacada de la configuración real (no a mano):
--   cd tests/harness && lune run ../../tools/economy/productos.luau ../../src
-- Escribe scripts/monetizacion/productos.json (lo usa crear_productos.py) y comprueba que
-- Economy/ProductIds tiene una línea por producto, ni una más ni una menos.
local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local task = require("@lune/task")
local mock = require("../../tests/harness/mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local Shop = req(Shared.Shop)
local Products = req(Shared.Economy.Products)
local Catalog = req(Shared.Economy.CosmeticCatalog)
local BP = req(Shared.Economy.BattlePassConfig)
local ProductIds = req(Shared.Economy.ProductIds)

local FAIR = "Solo estética: no cambia daño, vida ni estadísticas."
local KIND = {
	Skin = "Skin de arma", Outfit = "Traje de operador", Charm = "Colgante", Card = "Tarjeta de jugador",
	KillEffect = "Efecto de baja", Pose = "Pose de victoria", MVPIntro = "Intro de MVP", Spray = "Grafiti", Title = "Título",
}
-- (string.lower no toca las letras con tilde: se bajan a mano)
local ACCENTS = { ["Á"] = "á", ["É"] = "é", ["Í"] = "í", ["Ó"] = "ó", ["Ú"] = "ú", ["Ñ"] = "ñ", ["Ü"] = "ü" }
local function lower(text)
	text = string.lower(tostring(text))
	for upper, low in ACCENTS do
		text = string.gsub(text, upper, low)
	end
	return text
end
local function title(text)
	text = lower(text)
	for upper, low in ACCENTS do
		if string.sub(text, 1, #low) == low then
			return upper .. string.sub(text, #low + 1)
		end
	end
	return (string.gsub(text, "^%l", string.upper))
end
local function itemName(kind, id)
	local def = Catalog.Def(kind, id)
	return def and def.Name or id
end

local list = {}
local function add(key, name, price, description, pass)
	table.insert(list, { key = key, type = pass and "GamePass" or "DeveloperProduct", name = name, price = price, description = description, id = pass and ProductIds.GamePasses[key] or ProductIds.Products[key] or 0 })
end

for _, pack in Shop.CoinPacks do
	add("Coins:" .. pack.Name, ("%d monedas · %s"):format(pack.Coins, pack.Name), pack.Robux, ("%d monedas del juego. Las monedas solo compran estética."):format(pack.Coins))
end
for _, b in Shop.Boosters do
	add("Booster:" .. b.Id, ("%s · %d min"):format(b.Name, b.Minutes), b.Robux, ("%s durante %d minutos de partida. No acelera el pase de batalla ni da ventaja en combate."):format(b.Name, b.Minutes))
end
add("Starter:Starter", "Pack de inicio", Shop.StarterPack.Robux, ("Skin, traje, efecto de baja, colgante, tarjeta, pose y %d monedas. Solo jugadores nuevos, una vez. %s"):format(Shop.StarterPack.Coins, FAIR))
for _, season in BP.Seasons do
	add("PassPremium:" .. season.Id, ("Pase premium · %s"):format(title(season.Name)), season.Premium.Robux, ("Vía premium del pase de batalla de la %s (%s): %d niveles de recompensas. %s"):format(lower(season.Name), title(season.Title), BP.Tiers, FAIR))
end
add("TierSkip:TierSkip", "Nivel del pase", Products.TierSkip.Robux, "Sube un nivel del pase de batalla de la temporada en curso.")
for _, bundle in Shop.Bundles do
	local names = {}
	for _, item in Products.BundleItems(bundle) do
		table.insert(names, lower(KIND[item.Kind] or item.Kind) .. " " .. itemName(item.Kind, item.Id))
	end
	local extra = bundle.Coins and (" y %d monedas"):format(bundle.Coins) or ""
	add("Bundle:" .. bundle.Id, title(bundle.Name), bundle.Robux, ("Incluye: %s%s. %s"):format(table.concat(names, ", "), extra, FAIR))
end
local keys = {}
for key in Products.Items do
	table.insert(keys, key)
end
table.sort(keys)
for _, key in keys do
	local kind, id = Catalog.ParseKey(key)
	add("Item:" .. key, ("%s %s"):format(KIND[kind] or kind, itemName(kind, id)), Products.Items[key].Robux, ("%s «%s». %s"):format(KIND[kind] or kind, itemName(kind, id), FAIR))
end
add("VIP", "VIP", Shop.VIPRobux, "Doble de XP y de monedas de cuenta para siempre y un extra de monedas en la recompensa diaria. No acelera el pase de batalla ni da ventaja en combate.", true)

-- ProductIds: una línea por producto
local problems = {}
local seen = {}
for _, p in list do
	seen[p.key] = true
	if p.type == "DeveloperProduct" and ProductIds.Products[p.key] == nil then
		table.insert(problems, "falta en ProductIds.Products: " .. p.key)
	end
	if #p.name > 50 then
		table.insert(problems, "nombre de más de 50 caracteres: " .. p.name)
	end
end
for key in ProductIds.Products do
	if not seen[key] then
		table.insert(problems, "sobra en ProductIds.Products: " .. key)
	end
end
if ProductIds.GamePasses.VIP == nil then
	table.insert(problems, "falta ProductIds.GamePasses.VIP")
end

local out = process.args[2] or "../../scripts/monetizacion/productos.json"
fs.writeFile(out, serde.encode("json", list, true))
local total, missing = 0, 0
for _, p in list do
	total += p.price
	if p.id == 0 then
		missing += 1
	end
end
print(("%d productos (%d Developer Products y %d Game Pass) · sin id: %d · escrito %s"):format(#list, #list - 1, 1, missing, out))
for _, text in problems do
	print("PROBLEMA: " .. text)
end
process.exit(#problems == 0 and 0 or 1)
