-- Datos de la tienda en el cliente: estado de cada objeto (tuyo, equipado, NUEVO), precios reales de
-- Robux (MarketplaceService:GetProductInfo cuando el producto existe), relojes que cuentan hasta la
-- hora real de cambio, analítica y el arranque de las compras:
--   · Robux: la ventana de compra NATIVA de Roblox (PromptProductPurchase). Nada más: el servidor
--     entrega cuando Roblox le manda el recibo y avisa con PurchaseGranted.
--   · Monedas: ventana de confirmación propia (dos pasos: no se compra por un toque sin querer).
-- El cliente nunca da nada: solo pide y enseña lo que el servidor confirma.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Shop = require(Shared.Shop)
local Catalog = require(Shared.Economy.CosmeticCatalog)
local Products = require(Shared.Economy.Products)
local StoreRotation = require(Shared.Economy.StoreRotation)
local BattlePassConfig = require(Shared.Economy.BattlePassConfig)

local ClientState = require(script.Parent.Parent.Parent.ClientState)

local player = Players.LocalPlayer

local StoreData = {}
StoreData.Changed = Instance.new("BindableEvent") -- (compra pendiente que empieza o acaba)

-- Hora del servidor (los relojes de la tienda no dependen del reloj del dispositivo)
function StoreData.Now()
	local ok, now = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return ok and type(now) == "number" and now > 1e9 and now or os.time()
end

function StoreData.Day()
	return Shop.DayNumber(math.floor(StoreData.Now()))
end

-- "5 H 12 MIN", "2 D 4 H", "12 MIN 03 S"
function StoreData.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local days = seconds // 86400
	local hours = (seconds % 86400) // 3600
	local minutes = (seconds % 3600) // 60
	if days > 0 then
		return string.format("%d D %d H", days, hours)
	elseif hours > 0 then
		return string.format("%d H %02d MIN", hours, minutes)
	end
	return string.format("%d MIN %02d S", minutes, seconds % 60)
end

function StoreData.IsVIP()
	local data = ClientState.Data
	return data ~= nil and data.VIP == true
end

---------------------------------------------------------------------------
-- Precios de Robux reales
---------------------------------------------------------------------------

local realPrices = {} -- [ProductId] = Robux (lo que dice Roblox)
local asked = {}

local function askPrice(productId, infoType)
	if type(productId) ~= "number" or productId == 0 or asked[productId] then
		return
	end
	asked[productId] = true
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(productId, infoType or Enum.InfoType.Product)
		end)
		if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
			realPrices[productId] = info.PriceInRobux
			StoreData.Changed:Fire()
		end
	end)
end

-- Precio en Robux de un producto ({ ProductId, Robux }): el real si ya se sabe, si no el de config
function StoreData.Robux(entry, infoType)
	if type(entry) ~= "table" then
		return nil
	end
	askPrice(entry.ProductId, infoType)
	return realPrices[entry.ProductId] or entry.Robux
end

---------------------------------------------------------------------------
-- Estado de un objeto
---------------------------------------------------------------------------

-- "Equipped" | "Owned" | "Buy" | "Soon" (Robux sin id aún) | "Pass" | "Event" | "Locked"
function StoreData.State(item)
	local data = ClientState.Data
	if data and Catalog.Owns(data, item.Kind, item.Id, StoreData.IsVIP()) then
		if Catalog.Equippable(item.Kind, item.Id) and Catalog.IsEquipped(data, item.Kind, item.Id) then
			return "Equipped"
		end
		return "Owned"
	end
	if item.Robux then
		return Products.Enabled(Products.Item(item.Kind, item.Id)) and "Buy" or "Soon"
	end
	if item.Coins then
		return "Buy"
	end
	if item.Source == "Pass" then
		return "Pass"
	end
	if item.Source == "Event" then
		return "Event"
	end
	return "Locked"
end

function StoreData.IsNew(item)
	return Catalog.IsNew(ClientState.Data, item.Kind, item.Id)
end

-- Quita NUEVO de lo que ya se ha visto (se manda al servidor en grupo)
local seenQueue, seenScheduled = {}, false
function StoreData.MarkSeen(keys)
	local data = ClientState.Data
	for _, key in keys do
		if key == "Starter" or (Catalog.IsNewItem(key) and not (data and data.SeenItems and data.SeenItems[key])) then
			seenQueue[key] = true
		end
	end
	if seenScheduled or next(seenQueue) == nil then
		return
	end
	seenScheduled = true
	task.delay(1.5, function()
		seenScheduled = false
		local list = {}
		for key in seenQueue do
			table.insert(list, key)
		end
		table.clear(seenQueue)
		if #list > 0 then
			pcall(function()
				Remotes.MarkSeen:FireServer(list)
			end)
		end
	end)
end

-- Novedades sin ver o tienda diaria nueva (punto rojo de TIENDA: solo cosas nuevas de verdad)
function StoreData.HasNews()
	local data = ClientState.Data
	if not data then
		return false
	end
	for _, item in Catalog.StoreItems() do
		if Catalog.IsNew(data, item.Kind, item.Id) and not Catalog.Owns(data, item.Kind, item.Id, StoreData.IsVIP()) then
			return true
		end
	end
	return false
end

-- Pack de inicio para este jugador (nuevo, sin comprarlo)
function StoreData.StarterVisible()
	local data = ClientState.Data
	return data ~= nil and data.StarterPackEligible == true
end

---------------------------------------------------------------------------
-- Analítica (solo los eventos permitidos; el servidor limita)
---------------------------------------------------------------------------

function StoreData.Track(name, fields)
	pcall(function()
		Remotes.Track:FireServer(name, fields)
	end)
end

---------------------------------------------------------------------------
-- Compras
---------------------------------------------------------------------------

StoreData.Pending = nil -- { ProductId, Key } mientras está abierta la ventana de Roblox

-- Producto con Robux de lo que se quiere comprar: { ProductId, Robux, Key, GamePass }
function StoreData.ProductFor(what)
	if what.Type == "Item" then
		local entry = Products.Item(what.Item.Kind, what.Item.Id)
		return entry and { ProductId = entry.ProductId, Robux = entry.Robux, Key = what.Item.Key }
	elseif what.Type == "Bundle" then
		return { ProductId = what.Bundle.ProductId, Robux = what.Bundle.Robux, Key = "Bundle:" .. what.Bundle.Id }
	elseif what.Type == "Starter" then
		return { ProductId = Shop.StarterPack.ProductId, Robux = Shop.StarterPack.Robux, Key = "Starter" }
	elseif what.Type == "Coins" or what.Type == "Booster" then
		return { ProductId = what.Def.ProductId, Robux = what.Def.Robux, Key = what.Type .. ":" .. tostring(what.Def.Name or what.Def.Id) }
	elseif what.Type == "PassPremium" then
		local season = BattlePassConfig.Get(what.Season)
		return season and { ProductId = season.Premium.ProductId, Robux = season.Premium.Robux, Key = "Pass:" .. season.Id }
	elseif what.Type == "TierSkip" then
		return { ProductId = Products.TierSkip.ProductId, Robux = Products.TierSkip.Robux, Key = "TierSkip" }
	elseif what.Type == "VIP" then
		return { ProductId = Shop.VIPPassId, Robux = Shop.VIPRobux, Key = "VIP", GamePass = true }
	end
	return nil
end

-- Abre la ventana de compra de Roblox. Devuelve false, motivo si no se puede.
function StoreData.PromptRobux(what)
	local product = StoreData.ProductFor(what)
	if not product or not Products.Enabled(product) then
		return false, "PRÓXIMAMENTE"
	end
	if StoreData.Pending then
		return false, "COMPRA EN CURSO"
	end
	StoreData.Pending = { ProductId = product.ProductId, Key = product.Key, Started = os.clock() }
	StoreData.Changed:Fire()
	StoreData.Track("purchase_prompt", { key = product.Key, robux = product.Robux })
	local ok = pcall(function()
		if product.GamePass then
			MarketplaceService:PromptGamePassPurchase(player, product.ProductId)
		else
			MarketplaceService:PromptProductPurchase(player, product.ProductId)
		end
	end)
	if not ok then
		StoreData.Pending = nil
		StoreData.Changed:Fire()
		return false, "NO SE PUDO ABRIR LA COMPRA"
	end
	return true
end

-- Compra con monedas (después de confirmar). Devuelve ok, mensaje.
local buying = false
function StoreData.BuyWithCoins(item)
	if buying then
		return false, "Espera un momento"
	end
	buying = true
	StoreData.Track("purchase_prompt", { key = item.Key, coins = item.Coins })
	local ok, result, message = pcall(function()
		return Remotes.BuyItem:InvokeServer(item.Kind, item.Id)
	end)
	buying = false
	if not ok then
		return false, "Error de conexión"
	end
	if not result then
		StoreData.Track("purchase_cancel", { key = item.Key, reason = "server" })
	end
	return result == true, message
end

function StoreData.Equip(kind, id)
	pcall(function()
		Remotes.EquipCosmetic:FireServer(kind, id)
	end)
end

-- Lo de hoy en la tienda (todos ven lo mismo)
function StoreData.Daily()
	local list = {}
	for _, entry in StoreRotation.Daily(StoreData.Day()) do
		local item = Catalog.Item(entry.Kind, entry.Id, StoreData.Day())
		if item then
			table.insert(list, item)
		end
	end
	return list
end

local initialized = false
function StoreData.Init()
	if initialized then
		return
	end
	initialized = true
	-- La ventana de Roblox se cerró: si no compró, se dice (y se apunta); si compró, se espera a
	-- que el servidor lo entregue (PurchaseGranted)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
		local pending = StoreData.Pending
		if userId ~= player.UserId or not pending or pending.ProductId ~= productId then
			return
		end
		if not purchased then
			StoreData.Track("purchase_cancel", { key = pending.Key })
		end
		StoreData.Pending = nil
		StoreData.Changed:Fire(purchased and "Waiting" or "Cancelled")
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId, purchased)
		local pending = StoreData.Pending
		if who ~= player or not pending or pending.ProductId ~= passId then
			return
		end
		if not purchased then
			StoreData.Track("purchase_cancel", { key = pending.Key })
		end
		StoreData.Pending = nil
		StoreData.Changed:Fire(purchased and "Waiting" or "Cancelled")
	end)
end

return StoreData
