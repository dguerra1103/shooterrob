-- Datos persistentes del jugador (nivel, XP, monedas, skins) guardados con DataStore.
-- En Studio activa: Game Settings > Security > "Enable Studio Access to API Services".
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Skins = require(Shared.Skins)
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local PlayerData = {}

-- Callbacks que otros módulos pueden asignar
PlayerData.OnSkinChanged = nil -- function(player, skinId)

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

local function defaults()
	return {
		Level = 1,
		XP = 0,
		Coins = 0,
		Skins = { Default = true },
		EquippedSkin = "Default",
		Primary = "Rifle",
		ClaimedFree = {},
		ClaimedPremium = {},
		TotalKills = 0,
		Wins = 0,
		Premium = false,
	}
end

local function key(player)
	return "u_" .. player.UserId
end

local function publicView(data)
	return {
		Level = data.Level,
		XP = data.XP,
		XPPerLevel = GameConfig.XPPerLevel,
		Coins = data.Coins,
		Skins = data.Skins,
		EquippedSkin = data.EquippedSkin,
		Primary = data.Primary,
		TotalKills = data.TotalKills,
		Wins = data.Wins,
		Premium = data.Premium,
	}
end

local function sendUpdate(player)
	local data = profiles[player]
	if data then
		Remotes.DataUpdate:FireClient(player, publicView(data))
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

local function ownsPremium(player)
	if GameConfig.PremiumPassId == 0 then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.PremiumPassId)
	end)
	return ok and owns
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
	if type(data) == "table" then
		for k, v in data do
			merged[k] = v
		end
	end
	if not Skins.List[merged.EquippedSkin] or not merged.Skins[merged.EquippedSkin] then
		merged.EquippedSkin = "Default"
	end
	if not table.find(Weapons.Primaries, merged.Primary) then
		merged.Primary = "Rifle"
	end
	merged.Premium = merged.Premium or ownsPremium(player)

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
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(key(player), data)
	end)
	if not ok then
		warn("[PlayerData] Error al guardar", player.Name, err)
	end
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

function PlayerData.AddXP(player, amount, reason)
	local data = profiles[player]
	if not data or amount <= 0 then
		return
	end
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
		Remotes.Notify:FireClient(player, "Big", "¡NIVEL " .. data.Level .. "!")
		grantTierRewards(player)
	end
	sendUpdate(player)
end

function PlayerData.AddCoins(player, amount)
	local data = profiles[player]
	if data then
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
		return data and publicView(data)
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

	Remotes.SetPrimary.OnServerEvent:Connect(function(player, weaponName)
		local data = profiles[player]
		if not data or type(weaponName) ~= "string" or not table.find(Weapons.Primaries, weaponName) then
			return
		end
		data.Primary = weaponName
		Remotes.Notify:FireClient(
			player,
			"Info",
			Weapons.Get(weaponName).DisplayName .. " equipada (al reaparecer)"
		)
		sendUpdate(player)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passId == GameConfig.PremiumPassId then
			local data = profiles[player]
			if data then
				data.Premium = true
				Remotes.Notify:FireClient(player, "Big", "¡PASE PREMIUM ACTIVADO!")
				grantTierRewards(player)
				sendUpdate(player)
				save(player)
			end
		end
	end)
end

return PlayerData
