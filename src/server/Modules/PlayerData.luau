-- Datos persistentes del jugador (nivel, XP, monedas, skins, trajes, armas) guardados con DataStore,
-- y toda la economía: tienda con monedas, compras con Robux, VIP, recompensa diaria y cajas.
-- En Studio activa: Game Settings > Security > "Enable Studio Access to API Services".
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Skins = require(Shared.Skins)
local Weapons = require(Shared.Weapons)
local Outfits = require(Shared.Outfits)
local Shop = require(Shared.Shop)
local Remotes = require(Shared.Remotes)

local PlayerData = {}

-- Callbacks que otros módulos pueden asignar
PlayerData.OnSkinChanged = nil -- function(player, skinId)
PlayerData.OnOutfitChanged = nil -- function(player, outfitId)

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("ShooterRobData_v1")
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore no disponible, el progreso no se guardará:", result)
	end
end

local profiles = {}
local noSave = {} -- jugadores cuya carga falló: no sobrescribimos sus datos
local cratesRestricted = {} -- países donde no se permiten objetos aleatorios de pago

local STARTING_COINS = 250
local MAX_PURCHASE_LOG = 60

local function defaults()
	return {
		Level = 1,
		XP = 0,
		Coins = STARTING_COINS,
		Skins = { Default = true },
		EquippedSkin = "Default",
		Primary = "ARX27",
		Secondary = "Viper",
		OwnedWeapons = {},
		Outfits = { Default = true },
		EquippedOutfit = "Default",
		ClaimedFree = {},
		ClaimedPremium = {},
		TotalKills = 0,
		Wins = 0,
		Premium = false,
		DailyStreak = 0,
		LastDailyDay = -1,
		FreeCrates = 0,
		Purchases = {},
	}
end

local function key(player)
	return "u_" .. player.UserId
end

local function publicView(player, data)
	return {
		Level = data.Level,
		XP = data.XP,
		XPPerLevel = GameConfig.XPPerLevel,
		Coins = data.Coins,
		Skins = data.Skins,
		EquippedSkin = data.EquippedSkin,
		Primary = data.Primary,
		Secondary = data.Secondary,
		OwnedWeapons = data.OwnedWeapons,
		Outfits = data.Outfits,
		EquippedOutfit = data.EquippedOutfit,
		TotalKills = data.TotalKills,
		Wins = data.Wins,
		Premium = data.Premium,
		VIP = player:GetAttribute("VIP") == true,
		DailyStreak = data.DailyStreak,
		DailyAvailable = data.LastDailyDay ~= Shop.DayNumber(),
		FreeCrates = data.FreeCrates,
		CratesRestricted = cratesRestricted[player] == true,
		Day = Shop.DayNumber(),
	}
end

local function sendUpdate(player)
	local data = profiles[player]
	if data then
		Remotes.DataUpdate:FireClient(player, publicView(player, data))
	end
end
PlayerData.SendUpdate = sendUpdate

function PlayerData.GetLeaderstats(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		for _, name in { "Bajas", "Muertes", "Nivel" } do
			local value = Instance.new("IntValue")
			value.Name = name
			value.Parent = stats
		end
		stats.Parent = player
	end
	return stats
end

local function grant(player, data, reward)
	if not reward then
		return
	end
	if reward.Type == "Skin" then
		data.Skins[reward.Id] = true
		Remotes.Notify:FireClient(player, "Unlock", "¡Skin desbloqueada: " .. Skins.Get(reward.Id).Name .. "!")
	elseif reward.Type == "Outfit" then
		data.Outfits[reward.Id] = true
		Remotes.Notify:FireClient(player, "Unlock", "¡Traje desbloqueado: " .. Outfits.Get(reward.Id).Name .. "!")
	elseif reward.Type == "Crate" then
		data.FreeCrates += reward.Amount or 1
	elseif reward.Type == "Coins" then
		data.Coins += reward.Amount
	end
end

-- Entrega todas las recompensas del pase hasta el nivel actual que aún no se hayan reclamado
local function grantTierRewards(player)
	local data = profiles[player]
	if not data then
		return
	end
	local maxTier = math.min(data.Level, #GameConfig.BattlePass)
	for tier = 1, maxTier do
		local t = GameConfig.BattlePass[tier]
		local k = tostring(tier)
		if not data.ClaimedFree[k] then
			data.ClaimedFree[k] = true
			grant(player, data, t.Free)
		end
		if data.Premium and not data.ClaimedPremium[k] then
			data.ClaimedPremium[k] = true
			grant(player, data, t.Premium)
		end
	end
end

local function ownsPass(player, passId)
	if not passId or passId == 0 then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return ok and owns
end

local function checkPolicy(player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	-- Si no podemos comprobarlo, por seguridad tratamos las cajas de pago como restringidas
	cratesRestricted[player] = not ok or (info and info.ArePaidRandomItemsRestricted == true)
end

local function load(player)
	local data
	if store then
		local loaded, result = false, nil
		for attempt = 1, 3 do
			loaded, result = pcall(function()
				return store:GetAsync(key(player))
			end)
			if loaded then
				break
			end
			task.wait(attempt)
		end
		if loaded then
			data = result
		else
			warn("[PlayerData] No se pudieron cargar los datos de", player.Name, result)
			noSave[player] = true
		end
	end

	local merged = defaults()
	local isNew = type(data) ~= "table"
	if not isNew then
		for k, v in data do
			merged[k] = v
		end
		if data.Coins == nil then
			merged.Coins = 0
		end
	end
	-- Nombres de armas antiguos -> nuevos
	merged.Primary = Weapons.Legacy[merged.Primary] or merged.Primary
	merged.Secondary = Weapons.Legacy[merged.Secondary] or merged.Secondary
	if not Skins.List[merged.EquippedSkin] or not merged.Skins[merged.EquippedSkin] then
		merged.EquippedSkin = "Default"
	end
	if not Outfits.List[merged.EquippedOutfit] or not merged.Outfits[merged.EquippedOutfit] then
		merged.EquippedOutfit = "Default"
	end
	if not table.find(Weapons.Primaries, merged.Primary) or not Weapons.IsUnlocked(merged.Primary, merged) then
		merged.Primary = "ARX27"
	end
	if not table.find(Weapons.Secondaries, merged.Secondary) or not Weapons.IsUnlocked(merged.Secondary, merged) then
		merged.Secondary = Weapons.Secondary
	end
	merged.Premium = merged.Premium or ownsPass(player, GameConfig.PremiumPassId)
	player:SetAttribute("VIP", ownsPass(player, Shop.VIPPassId))
	checkPolicy(player)

	if not player.Parent then
		return
	end
	profiles[player] = merged
	PlayerData.GetLeaderstats(player).Nivel.Value = merged.Level
	grantTierRewards(player)
	sendUpdate(player)
end

local function save(player)
	local data = profiles[player]
	if not data or not store or noSave[player] then
		return false
	end
	local ok, err = pcall(function()
		store:SetAsync(key(player), data)
	end)
	if not ok then
		warn("[PlayerData] Error al guardar", player.Name, err)
	end
	return ok
end

function PlayerData.Get(player)
	return profiles[player]
end

-- Espera a que los datos del jugador estén cargados (máx. timeout segundos)
function PlayerData.WaitFor(player, timeout)
	local start = os.clock()
	while not profiles[player] and player.Parent and os.clock() - start < (timeout or 15) do
		task.wait(0.1)
	end
	return profiles[player]
end

local function multiplier(player)
	return player:GetAttribute("VIP") and Shop.VIPMultiplier or 1
end

function PlayerData.AddXP(player, amount, reason)
	local data = profiles[player]
	if not data or amount <= 0 then
		return
	end
	amount = math.floor(amount * multiplier(player))
	data.XP += amount
	Remotes.Notify:FireClient(player, "XP", "+" .. amount .. " XP  " .. (reason or ""))
	local leveled = false
	while data.XP >= GameConfig.XPPerLevel do
		data.XP -= GameConfig.XPPerLevel
		data.Level += 1
		leveled = true
	end
	if leveled then
		PlayerData.GetLeaderstats(player).Nivel.Value = data.Level
		Remotes.Notify:FireClient(player, "LevelUp", data.Level)
		-- ¿Desbloquea alguna arma este nivel?
		for name, def in Weapons.List do
			if def.UnlockLevel == data.Level then
				Remotes.Notify:FireClient(player, "Unlock", "¡Arma desbloqueada: " .. def.DisplayName .. "!")
			end
		end
		grantTierRewards(player)
	end
	sendUpdate(player)
end

-- earned = true para monedas ganadas jugando (el VIP las duplica)
function PlayerData.AddCoins(player, amount, earned)
	local data = profiles[player]
	if data then
		if earned ~= false then
			amount = math.floor(amount * multiplier(player))
		end
		data.Coins += amount
		sendUpdate(player)
	end
end

function PlayerData.Increment(player, field, amount)
	local data = profiles[player]
	if data and type(data[field]) == "number" then
		data[field] += amount or 1
	end
end

---------------------------------------------------------------------------
-- Tienda
---------------------------------------------------------------------------

local function buyItem(player, kind, id)
	local data = profiles[player]
	if not data or type(kind) ~= "string" or type(id) ~= "string" then
		return false, "Datos no cargados"
	end
	local price
	if kind == "Weapon" then
		local def = Weapons.List[id]
		if not def or not def.Price then
			return false, "No está a la venta"
		end
		if Weapons.IsUnlocked(id, data) then
			return false, "Ya la tienes"
		end
		price = def.Price
	elseif kind == "Skin" then
		if not Skins.List[id] then
			return false, "No existe"
		end
		if data.Skins[id] then
			return false, "Ya la tienes"
		end
		price = Shop.GetPrice("Skin", id)
	elseif kind == "Outfit" then
		if not Outfits.List[id] then
			return false, "No existe"
		end
		if data.Outfits[id] then
			return false, "Ya lo tienes"
		end
		price = Shop.GetPrice("Outfit", id)
	end
	if not price then
		return false, "No está a la venta"
	end
	if data.Coins < price then
		return false, "Te faltan " .. (price - data.Coins) .. " monedas"
	end
	data.Coins -= price
	if kind == "Weapon" then
		data.OwnedWeapons[id] = true
	elseif kind == "Skin" then
		data.Skins[id] = true
	else
		data.Outfits[id] = true
	end
	sendUpdate(player)
	task.spawn(save, player)
	return true, "¡Comprado!"
end

local function claimDaily(player)
	local data = profiles[player]
	if not data then
		return false
	end
	local today = Shop.DayNumber()
	if data.LastDailyDay == today then
		return false
	end
	local streak = (data.LastDailyDay == today - 1) and data.DailyStreak + 1 or 1
	if streak > #Shop.DailyRewards then
		streak = 1
	end
	data.DailyStreak = streak
	data.LastDailyDay = today
	local coins = Shop.DailyRewards[streak]
	PlayerData.AddCoins(player, coins, true)
	local crate = streak == Shop.DailyCrateDay
	if crate then
		data.FreeCrates += 1
	end
	if player:GetAttribute("VIP") then
		data.FreeCrates += 1 -- caja diaria extra del VIP
	end
	sendUpdate(player)
	return true, { Streak = streak, Coins = coins * multiplier(player), Crate = crate }
end

-- Abre una caja. Devuelve lo que ha tocado para la animación del cliente.
local function openCrate(player, crateId, useFree)
	local data = profiles[player]
	local crate = Shop.Crates[crateId]
	if not data or not crate then
		return false, "No existe"
	end
	if useFree then
		if data.FreeCrates <= 0 then
			return false, "No tienes cajas gratis"
		end
		data.FreeCrates -= 1
	else
		if cratesRestricted[player] then
			return false, "Las cajas de pago no están disponibles en tu región"
		end
		if data.Coins < crate.Price then
			return false, "Te faltan " .. (crate.Price - data.Coins) .. " monedas"
		end
		data.Coins -= crate.Price
	end

	-- Rareza según probabilidades
	local total = 0
	for _, entry in crate.Odds do
		total += entry.Weight
	end
	local roll = math.random() * total
	local rarity = crate.Odds[#crate.Odds].Rarity
	for _, entry in crate.Odds do
		roll -= entry.Weight
		if roll <= 0 then
			rarity = entry.Rarity
			break
		end
	end
	-- Objeto aleatorio de esa rareza (skins y trajes)
	local pool = {}
	for id, skin in Skins.List do
		if id ~= "Default" and skin.Rarity == rarity then
			table.insert(pool, { Kind = "Skin", Id = id })
		end
	end
	for id, outfit in Outfits.List do
		if id ~= "Default" and outfit.Rarity == rarity then
			table.insert(pool, { Kind = "Outfit", Id = id })
		end
	end
	if #pool == 0 then
		for id in Skins.List do
			if id ~= "Default" then
				table.insert(pool, { Kind = "Skin", Id = id })
			end
		end
	end
	local prize = pool[math.random(1, #pool)]
	local owned
	if prize.Kind == "Skin" then
		owned = data.Skins[prize.Id] == true
	else
		owned = data.Outfits[prize.Id] == true
	end
	local refund = 0
	if owned then
		refund = math.floor(crate.Price * crate.DuplicateRefund)
		data.Coins += refund
	elseif prize.Kind == "Skin" then
		data.Skins[prize.Id] = true
	else
		data.Outfits[prize.Id] = true
	end
	sendUpdate(player)
	task.spawn(save, player)
	return true, { Kind = prize.Kind, Id = prize.Id, Rarity = rarity, Duplicate = owned, Refund = refund }
end

-- Compras con Robux (Developer Products). Idempotente: cada PurchaseId se entrega una sola vez.
local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = PlayerData.WaitFor(player, 20)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(data.Purchases, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local pack
	for _, p in Shop.CoinPacks do
		if p.ProductId ~= 0 and p.ProductId == receipt.ProductId then
			pack = p
		end
	end
	if not pack then
		warn("[PlayerData] Producto desconocido:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.Coins += pack.Coins
	table.insert(data.Purchases, receipt.PurchaseId)
	while #data.Purchases > MAX_PURCHASE_LOG do
		table.remove(data.Purchases, 1)
	end
	if store and not noSave[player] and not save(player) then
		-- No se pudo guardar: deshacemos y Roblox lo reintentará más tarde
		data.Coins -= pack.Coins
		table.remove(data.Purchases)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Remotes.Notify:FireClient(player, "Big", "+" .. pack.Coins .. " MONEDAS")
	sendUpdate(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------------

function PlayerData.Init()
	Players.PlayerAdded:Connect(function(player)
		PlayerData.GetLeaderstats(player)
		load(player)
	end)
	for _, player in Players:GetPlayers() do
		PlayerData.GetLeaderstats(player)
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		noSave[player] = nil
		cratesRestricted[player] = nil
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
		task.wait(3)
	end)

	-- Autoguardado
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)

	Remotes.GetData.OnServerInvoke = function(player)
		local data = PlayerData.WaitFor(player, 20)
		return data and publicView(player, data)
	end

	Remotes.EquipSkin.OnServerEvent:Connect(function(player, skinId)
		local data = profiles[player]
		if not data or type(skinId) ~= "string" or not Skins.List[skinId] or not data.Skins[skinId] then
			return
		end
		data.EquippedSkin = skinId
		if PlayerData.OnSkinChanged then
			PlayerData.OnSkinChanged(player, skinId)
		end
		sendUpdate(player)
	end)

	Remotes.EquipOutfit.OnServerEvent:Connect(function(player, outfitId)
		local data = profiles[player]
		if not data or type(outfitId) ~= "string" or not Outfits.List[outfitId] or not data.Outfits[outfitId] then
			return
		end
		data.EquippedOutfit = outfitId
		if PlayerData.OnOutfitChanged then
			PlayerData.OnOutfitChanged(player, outfitId)
		end
		sendUpdate(player)
	end)

	local function setWeapon(player, weaponName, field, list)
		local data = profiles[player]
		if not data or type(weaponName) ~= "string" or not table.find(list, weaponName) then
			return
		end
		if not Weapons.IsUnlocked(weaponName, data) then
			return
		end
		data[field] = weaponName
		Remotes.Notify:FireClient(player, "Info", Weapons.Get(weaponName).DisplayName .. " equipada (al reaparecer)")
		sendUpdate(player)
	end
	Remotes.SetPrimary.OnServerEvent:Connect(function(player, weaponName)
		setWeapon(player, weaponName, "Primary", Weapons.Primaries)
	end)
	Remotes.SetSecondary.OnServerEvent:Connect(function(player, weaponName)
		setWeapon(player, weaponName, "Secondary", Weapons.Secondaries)
	end)

	Remotes.BuyItem.OnServerInvoke = buyItem
	Remotes.ClaimDaily.OnServerInvoke = claimDaily
	Remotes.OpenCrate.OnServerInvoke = openCrate
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local data = profiles[player]
		if not data then
			return
		end
		if passId == GameConfig.PremiumPassId and GameConfig.PremiumPassId ~= 0 then
			data.Premium = true
			Remotes.Notify:FireClient(player, "Big", "¡PASE PREMIUM ACTIVADO!")
			grantTierRewards(player)
		elseif passId == Shop.VIPPassId and Shop.VIPPassId ~= 0 then
			player:SetAttribute("VIP", true)
			Remotes.Notify:FireClient(player, "Big", "¡VIP ACTIVADO! x2 XP y monedas")
		end
		sendUpdate(player)
		save(player)
	end)
end

return PlayerData
