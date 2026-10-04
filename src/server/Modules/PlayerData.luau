-- Datos persistentes del jugador (nivel, XP, monedas, skins, trajes, armas) guardados con DataStore,
-- y toda la economía: tienda con monedas, compras con Robux, VIP, recompensa diaria, cajas,
-- retos diarios y maestría de armas.
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
local Ranks = require(Shared.Ranks)
local Shop = require(Shared.Shop)
local Friends = require(script.Parent.Friends)
local Badges = require(script.Parent.Badges)
local Challenges = require(Shared.Challenges)
local Mastery = require(Shared.Mastery)
local KillEffects = require(Shared.KillEffects)
local Remotes = require(Shared.Remotes)

local PlayerData = {}

-- Callbacks que otros módulos pueden asignar
PlayerData.OnSkinChanged = nil -- function(player, skinId)
PlayerData.OnOutfitChanged = nil -- function(player, outfitId)
PlayerData.OnLeaving = nil :: ((player: Player) -> ())? -- justo antes del guardado final al salir

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
-- Bloqueo de sesión: un servidor "reserva" los datos del jugador mientras está dentro, para que otro
-- servidor no lea datos viejos y los sobrescriba (por ejemplo al cambiar rápido de servidor).
local LOCK_TIMEOUT = 600 -- si el servidor que tenía el bloqueo se cayó, a los 10 min se puede quitar
local LOCK_WAIT = 25 -- segundos máximos esperando a que el otro servidor suelte los datos
local SAVE_COOLDOWN = 7 -- Roblox permite ~1 escritura por clave cada 6 s

local saving = {} -- jugadores con un guardado en curso
local dirty = {} -- jugadores con cambios pendientes de guardar
local saveScheduled = {}

local function defaults()
	return {
		Level = 1,
		XP = 0,
		Coins = STARTING_COINS,
		Skins = { Default = true },
		EquippedSkin = "Default",
		Primary = "ARX27",
		Secondary = "Viper",
		Melee = "Knife", -- arma cuerpo a cuerpo elegida (Weapons.Melees)
		OwnedWeapons = {},
		Outfits = { Default = true },
		EquippedOutfit = "Default",
		ClaimedFree = {},
		ClaimedPremium = {},
		TotalKills = 0,
		Wins = 0,
		RankPoints = 0, -- puntos de rango competitivo (ver Ranks)
		RankBest = 1, -- rango más alto alcanzado (sus premios ya se dieron)
		Premium = false,
		DailyStreak = 0,
		LastDailyDay = -1,
		FreeCrates = 0,
		Purchases = {},
		KillEffects = { Default = true }, -- efectos de eliminación comprados
		EquippedKillEffect = "Default",
		WeaponKills = {}, -- bajas con cada arma (maestría)
		WeaponCamos = {}, -- camuflaje de maestría elegido para cada arma
		Challenges = { Day = -1, List = {}, Rerolls = 0, Bonus = false },
		StarterPack = false, -- ya compró el pack de inicio
		TutorialDone = false, -- ya vio la tarjeta de controles de la primera partida
		EventProgress = { Id = "", Count = 0 }, -- caramelos del evento de temporada (ver Event)
		Revives = GameConfig.StartingRevives, -- "Revivir instantáneo" disponibles
		Gifts = { Day = -1, Claimed = 0, Seconds = 0 }, -- regalos por tiempo jugado de hoy (ver Gifts)
		Settings = table.clone(GameConfig.DefaultSettings),
	}
end

---------------------------------------------------------------------------
-- Retos diarios
---------------------------------------------------------------------------

-- Reparte retos nuevos si ha cambiado el día
local function ensureChallenges(player, data)
	local today = Shop.DayNumber()
	local state = data.Challenges
	if type(state) ~= "table" or state.Day ~= today or type(state.List) ~= "table" then
		local list = {}
		for _, id in Challenges.Pick(today, player.UserId, data.Level, Challenges.PerDay) do
			table.insert(list, { Id = id, Progress = 0, Done = false })
		end
		state = { Day = today, List = list, Rerolls = 0, Bonus = false }
		data.Challenges = state
	end
	return state
end

local function challengesView(player, data)
	local state = ensureChallenges(player, data)
	local list = {}
	for _, entry in state.List do
		local def = Challenges.Get(entry.Id)
		if def then
			table.insert(list, {
				Id = entry.Id,
				Text = def.Text,
				Goal = def.Goal,
				Progress = math.min(entry.Progress, def.Goal),
				Done = entry.Done,
				Coins = def.Coins,
				XP = def.XP,
			})
		end
	end
	return {
		List = list,
		RerollsLeft = math.max(0, Challenges.RerollsPerDay - (state.Rerolls or 0)),
		Bonus = state.Bonus == true,
		BonusCrates = Challenges.BonusCrates,
	}
end

-- Skin con la que se ve un arma: el camuflaje de maestría elegido para ella (si lo tiene) o la skin general
function PlayerData.SkinFor(data, weaponName)
	if not data then
		return "Default"
	end
	local camo = data.WeaponCamos and data.WeaponCamos[weaponName]
	if camo and Mastery.HasCamo(data.WeaponKills and data.WeaponKills[weaponName] or 0, camo) then
		return camo
	end
	return data.EquippedSkin or "Default"
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
		Melee = data.Melee,
		OwnedWeapons = data.OwnedWeapons,
		Outfits = data.Outfits,
		EquippedOutfit = data.EquippedOutfit,
		TotalKills = data.TotalKills,
		Wins = data.Wins,
		RankPoints = data.RankPoints,
		Premium = data.Premium,
		VIP = player:GetAttribute("VIP") == true,
		DailyStreak = data.DailyStreak,
		DailyAvailable = data.LastDailyDay ~= Shop.DayNumber(),
		FreeCrates = data.FreeCrates,
		CratesRestricted = cratesRestricted[player] == true,
		Day = Shop.DayNumber(),
		WeaponKills = data.WeaponKills,
		WeaponCamos = data.WeaponCamos,
		KillEffects = data.KillEffects,
		EquippedKillEffect = data.EquippedKillEffect,
		Settings = data.Settings,
		Revives = data.Revives,
		-- (si sus datos no se guardan, no se le enseña el tutorial: probablemente ya lo vio)
		TutorialDone = data.TutorialDone == true or noSave[player] == true,
		EventCandy = (type(data.EventProgress) == "table" and data.EventProgress.Id == GameConfig.Event.Id) and data.EventProgress.Count or 0,
		StarterPackAvailable = Shop.StarterPack.ProductId ~= 0 and not data.StarterPack and data.Level <= Shop.StarterPack.MaxLevel,
		Challenges = challengesView(player, data),
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
		local started = os.clock()
		local attempt = 0
		while player.Parent do
			attempt += 1
			local locked = false
			local force = os.clock() - started > LOCK_WAIT
			loaded, result = pcall(function()
				return store:UpdateAsync(key(player), function(old)
					local lock = type(old) == "table" and old.SessionLock
					if type(lock) == "table" and lock.Job ~= game.JobId and not force and os.time() - (lock.Time or 0) < LOCK_TIMEOUT then
						locked = true
						return nil -- otro servidor aún tiene los datos: no tocamos nada
					end
					old = type(old) == "table" and old or {}
					old.SessionLock = { Job = game.JobId, Time = os.time() }
					return old
				end)
			end)
			if loaded and not locked then
				break
			end
			if not loaded and attempt >= 3 then
				break
			end
			task.wait(loaded and 3 or attempt)
		end
		if loaded then
			data = result
		else
			warn("[PlayerData] No se pudieron cargar los datos de", player.Name, result)
			noSave[player] = true
		end
	end

	local merged = defaults()
	local isNew = type(data) ~= "table" or data.Level == nil
	if not isNew then
		for k, v in data do
			merged[k] = v
		end
		if data.Coins == nil then
			merged.Coins = 0
		end
	end
	if type(merged.WeaponKills) ~= "table" then
		merged.WeaponKills = {}
	end
	if type(merged.WeaponCamos) ~= "table" then
		merged.WeaponCamos = {}
	end
	if type(merged.Revives) ~= "number" or merged.Revives ~= merged.Revives then
		merged.Revives = GameConfig.StartingRevives
	end
	if type(merged.Settings) ~= "table" then
		merged.Settings = table.clone(GameConfig.DefaultSettings)
	end
	if type(merged.Gifts) ~= "table" or type(merged.Gifts.Claimed) ~= "number" or type(merged.Gifts.Seconds) ~= "number" then
		merged.Gifts = { Day = -1, Claimed = 0, Seconds = 0 }
	end
	-- Antes la calidad por defecto era "Alta" (daba lag en equipos modestos): pasa a "Auto" una vez
	if merged.Settings.QualityVersion ~= GameConfig.DefaultSettings.QualityVersion then
		merged.Settings.Quality = "Auto"
		merged.Settings.QualityVersion = GameConfig.DefaultSettings.QualityVersion
	end
	if type(merged.KillEffects) ~= "table" then
		merged.KillEffects = { Default = true }
	end
	if not KillEffects.List[merged.EquippedKillEffect] or not merged.KillEffects[merged.EquippedKillEffect] then
		merged.EquippedKillEffect = "Default"
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
	if not table.find(Weapons.Melees, merged.Melee) or not Weapons.IsUnlocked(merged.Melee, merged) then
		merged.Melee = Weapons.Melee
	end
	if type(merged.RankPoints) ~= "number" or merged.RankPoints ~= merged.RankPoints then
		merged.RankPoints = 0
	end
	if type(merged.RankBest) ~= "number" then
		merged.RankBest = Ranks.Index(merged.RankPoints)
	end
	if type(merged.EventProgress) ~= "table" or type(merged.EventProgress.Count) ~= "number" then
		merged.EventProgress = { Id = "", Count = 0 }
	end
	-- Quien ya jugaba antes de existir el tutorial no lo ve
	if not isNew and data.TutorialDone == nil and ((merged.Level or 1) > 1 or (merged.TotalKills or 0) > 0) then
		merged.TutorialDone = true
	end
	merged.Premium = merged.Premium or ownsPass(player, GameConfig.PremiumPassId)
	player:SetAttribute("VIP", ownsPass(player, Shop.VIPPassId))
	checkPolicy(player)

	if not player.Parent then
		noSave[player] = nil
		cratesRestricted[player] = nil
		return
	end
	profiles[player] = merged
	Badges.Check(player, merged)
	PlayerData.GetLeaderstats(player).Nivel.Value = merged.Level
	player:SetAttribute("Rank", Ranks.Index(merged.RankPoints))
	grantTierRewards(player)
	sendUpdate(player)
end

-- Guarda los datos. release = true al salir el jugador: suelta el bloqueo de sesión.
local function save(player, release)
	local data = profiles[player]
	if not data or not store or noSave[player] then
		return false
	end
	-- Espera a que acabe otro guardado de este jugador (no pisar escrituras)
	local waited = 0
	while saving[player] and waited < 15 do
		task.wait(0.5)
		waited += 0.5
	end
	saving[player] = true
	dirty[player] = nil
	local stolen = false
	local ok, err = pcall(function()
		store:UpdateAsync(key(player), function(old)
			local lock = type(old) == "table" and old.SessionLock
			if type(lock) == "table" and lock.Job ~= game.JobId then
				stolen = true
				return nil -- otro servidor tiene ahora los datos: no los sobrescribimos
			end
			data.SessionLock = if release then nil else { Job = game.JobId, Time = os.time() }
			return data
		end)
	end)
	saving[player] = nil
	if not ok then
		warn("[PlayerData] Error al guardar", player.Name, err)
		dirty[player] = true
	elseif stolen then
		warn("[PlayerData] Otro servidor tiene los datos de", player.Name, "- no se guardan aquí")
		noSave[player] = true
		return false
	end
	return ok
end

-- Pide un guardado pronto, agrupando varios cambios seguidos en una sola escritura
local function requestSave(player)
	dirty[player] = true
	if saveScheduled[player] then
		return
	end
	saveScheduled[player] = true
	task.delay(SAVE_COOLDOWN, function()
		saveScheduled[player] = nil
		if dirty[player] and player.Parent then
			save(player)
		end
	end)
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

-- VIP (x2) y bonus de amigos en el servidor (+10% por amigo, ver Friends)
local function multiplier(player)
	local vip = player:GetAttribute("VIP") and Shop.VIPMultiplier or 1
	return vip * Friends.Multiplier(player)
end

-- Envía los datos al cliente (cambios hechos desde fuera, p. ej. el evento)
function PlayerData.SendUpdate(player)
	sendUpdate(player)
end

-- Da una skin (premios de evento); devuelve true si es nueva
function PlayerData.GiveSkin(player, skinId)
	local data = profiles[player]
	if not data or not Skins.List[skinId] or data.Skins[skinId] then
		return false
	end
	data.Skins[skinId] = true
	dirty[player] = true
	sendUpdate(player)
	return true
end

-- Da un traje (recompensas de evento). Devuelve false si ya lo tenía
function PlayerData.GiveOutfit(player, outfitId)
	local data = profiles[player]
	if not data or not Outfits.List[outfitId] or data.Outfits[outfitId] then
		return false
	end
	data.Outfits[outfitId] = true
	dirty[player] = true
	sendUpdate(player)
	return true
end

-- Marca los datos para guardarlos en el próximo guardado automático (cambios hechos desde fuera)
function PlayerData.MarkDirty(player)
	if profiles[player] then
		dirty[player] = true
	end
end

-- Da revivir instantáneos (regalos por tiempo jugado)
function PlayerData.AddRevives(player, amount)
	local data = profiles[player]
	if not data or amount <= 0 then
		return
	end
	data.Revives = (data.Revives or 0) + amount
	dirty[player] = true
	sendUpdate(player)
end

-- Gasta un "Revivir instantáneo". Devuelve false si no le quedan.
function PlayerData.UseRevive(player)
	local data = profiles[player]
	if not data or (data.Revives or 0) <= 0 then
		return false
	end
	data.Revives -= 1
	dirty[player] = true
	sendUpdate(player)
	return true
end

-- Lo ganado en la partida actual (para el resumen del final de la ronda)
local match = {} -- [player] = { XP, Coins, StartLevel, StartXP }

local function matchOf(player, data)
	local entry = match[player]
	if not entry then
		entry = { XP = 0, Coins = 0, StartLevel = data.Level, StartXP = data.XP, StartRank = data.RankPoints }
		match[player] = entry
	end
	return entry
end

-- Empieza una partida: se pone a cero lo ganado
function PlayerData.StartMatch(player)
	match[player] = nil
	local data = profiles[player]
	if data then
		matchOf(player, data)
	end
end

-- Resumen de lo ganado desde StartMatch
function PlayerData.MatchSummary(player)
	local data = profiles[player]
	if not data then
		return nil
	end
	local entry = matchOf(player, data)
	return {
		XP = entry.XP,
		Coins = entry.Coins,
		StartLevel = entry.StartLevel,
		StartXP = entry.StartXP,
		Level = data.Level,
		LevelXP = data.XP,
		XPPerLevel = GameConfig.XPPerLevel,
		StartRank = entry.StartRank or data.RankPoints,
		RankPoints = data.RankPoints,
	}
end

-- Suma (o resta) puntos de rango al acabar una partida; nunca baja del inicio del rango actual
function PlayerData.AddRankPoints(player, delta)
	local data = profiles[player]
	if not data or delta == 0 then
		return 0
	end
	matchOf(player, data) -- (el resumen de la partida guarda el rango de antes)
	local before = data.RankPoints
	data.RankPoints = Ranks.Apply(before, delta)
	local index = Ranks.Index(data.RankPoints)
	player:SetAttribute("Rank", index)
	-- Premios de los rangos alcanzados por primera vez
	while (data.RankBest or 1) < index do
		data.RankBest = (data.RankBest or 1) + 1
		local tier = Ranks.Tiers[data.RankBest]
		local reward = tier.Reward or {}
		local text = tier.Icon .. " ¡Rango " .. tier.Name .. "!"
		if reward.Coins then
			data.Coins += reward.Coins
			text ..= "  +" .. reward.Coins .. " 🪙"
		end
		if reward.Crates then
			data.FreeCrates += reward.Crates
			text ..= "  +" .. reward.Crates .. (reward.Crates == 1 and " caja" or " cajas")
		end
		Remotes.Notify:FireClient(player, "Challenge", text)
	end
	Badges.Check(player, data)
	dirty[player] = true
	sendUpdate(player)
	return data.RankPoints - before
end

function PlayerData.AddXP(player, amount, reason)
	local data = profiles[player]
	if not data or amount <= 0 then
		return
	end
	amount = math.floor(amount * multiplier(player))
	matchOf(player, data).XP += amount
	data.XP += amount
	Remotes.Notify:FireClient(player, "XP", "+" .. amount .. " XP  " .. (reason or ""))
	local leveled = false
	while data.XP >= GameConfig.XPPerLevel do
		data.XP -= GameConfig.XPPerLevel
		data.Level += 1
		leveled = true
	end
	if leveled then
		Badges.Check(player, data)
		PlayerData.GetLeaderstats(player).Nivel.Value = data.Level
		Remotes.Notify:FireClient(player, "LevelUp", data.Level)
		-- ¿Desbloquea alguna arma este nivel?
		for name, def in Weapons.List do
			if def.UnlockLevel == data.Level and not def.Hidden then
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
			matchOf(player, data).Coins += amount
		end
		data.Coins += amount
		sendUpdate(player)
		return amount -- lo que se ha sumado de verdad (con VIP y amigos)
	end
	return 0
end

function PlayerData.Increment(player, field, amount)
	local data = profiles[player]
	if data and type(data[field]) == "number" then
		data[field] += amount or 1
		if field == "TotalKills" or field == "Wins" then
			Badges.Check(player, data)
		end
	end
end

-- Progreso de los retos diarios. stat: ver Challenges.luau. Para "Streak" amount es la racha actual.
function PlayerData.Track(player, stat, amount, weaponName)
	local data = profiles[player]
	if not data then
		return
	end
	local state = ensureChallenges(player, data)
	local changed = false
	for _, entry in state.List do
		local def = Challenges.Get(entry.Id)
		if def and not entry.Done and Challenges.Matches(def, stat, weaponName) then
			if stat == "Streak" then
				entry.Progress = math.max(entry.Progress, amount or 0)
			else
				entry.Progress += amount or 1
			end
			if entry.Progress >= def.Goal then
				entry.Done = true
				changed = true
				Remotes.Notify:FireClient(player, "Challenge", "¡RETO COMPLETADO! +" .. def.Coins .. " 🪙")
				PlayerData.AddCoins(player, def.Coins, false)
				PlayerData.AddXP(player, def.XP, "Reto diario")
			end
		end
	end
	if changed and not state.Bonus then
		local all = #state.List > 0
		for _, entry in state.List do
			all = all and entry.Done
		end
		if all then
			state.Bonus = true
			data.FreeCrates += Challenges.BonusCrates
			Remotes.Notify:FireClient(player, "Unlock", "¡Todos los retos de hoy completados! Caja gratis 🎁")
		end
	end
	if changed then
		sendUpdate(player)
	end
end

-- Cuenta una baja con un arma y entrega la maestría al subir de nivel
function PlayerData.AddWeaponKill(player, weaponName)
	local data = profiles[player]
	if not data or type(weaponName) ~= "string" or not Weapons.List[weaponName] then
		return
	end
	local before = data.WeaponKills[weaponName] or 0
	local after = before + 1
	data.WeaponKills[weaponName] = after
	local oldLevel, newLevel = Mastery.Level(before), Mastery.Level(after)
	if newLevel > oldLevel then
		local tier = Mastery.Tiers[newLevel]
		-- Equipa el camuflaje nuevo automáticamente: ¡que se vea!
		data.WeaponCamos[weaponName] = tier.Camo
		Remotes.Notify:FireClient(player, "Mastery", "MAESTRÍA " .. string.upper(tier.Name) .. ": " .. Weapons.List[weaponName].DisplayName)
		PlayerData.AddCoins(player, tier.Coins, false)
		if PlayerData.OnSkinChanged then
			PlayerData.OnSkinChanged(player)
		end
		sendUpdate(player)
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
	elseif kind == "KillEffect" then
		if not KillEffects.List[id] then
			return false, "No existe"
		end
		if data.KillEffects[id] then
			return false, "Ya lo tienes"
		end
		price = Shop.GetPrice("KillEffect", id)
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
	elseif kind == "KillEffect" then
		data.KillEffects[id] = true
		data.EquippedKillEffect = id -- se equipa al comprarlo
	else
		data.Outfits[id] = true
	end
	sendUpdate(player)
	requestSave(player)
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
	return true, { Streak = streak, Coins = math.floor(coins * multiplier(player)), Crate = crate }
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
		if id ~= "Default" and not skin.Mastery and not skin.Event and skin.Rarity == rarity then
			table.insert(pool, { Kind = "Skin", Id = id })
		end
	end
	for id, outfit in Outfits.List do
		if id ~= "Default" and not outfit.Event and outfit.Rarity == rarity then
			table.insert(pool, { Kind = "Outfit", Id = id })
		end
	end
	if #pool == 0 then
		for id, skin in Skins.List do
			if id ~= "Default" and not skin.Mastery and not skin.Event then
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
	requestSave(player)
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
	-- Qué se entrega: un pack de monedas, de revivir o el pack de inicio
	local revivePack
	for _, p in Shop.RevivePacks do
		if p.ProductId ~= 0 and p.ProductId == receipt.ProductId then
			revivePack = p
		end
	end
	local grant, undo, message
	local starter = Shop.StarterPack
	if starter.ProductId ~= 0 and receipt.ProductId == starter.ProductId and data.StarterPack then
		-- Ya lo tenía (compra repetida): Roblox ya cobró, así que se entregan solo las monedas
		grant = function()
			data.Coins += starter.Coins
		end
		undo = function()
			data.Coins -= starter.Coins
		end
		message = "+" .. starter.Coins .. " MONEDAS"
	elseif starter.ProductId ~= 0 and receipt.ProductId == starter.ProductId then
		-- Al deshacer solo se quita lo que se dio (no se vuelve a un saldo antiguo:
		-- mientras se guardaba pudo ganar o gastar monedas)
		local had = {
			Outfit = data.Outfits[starter.Outfit] == true,
			Skin = data.Skins[starter.Skin] == true,
			Effect = data.KillEffects[starter.KillEffect] == true,
		}
		grant = function()
			data.Coins += starter.Coins
			data.Outfits[starter.Outfit] = true
			data.Skins[starter.Skin] = true
			data.KillEffects[starter.KillEffect] = true
			data.StarterPack = true
		end
		undo = function()
			data.Coins -= starter.Coins
			if not had.Outfit then
				data.Outfits[starter.Outfit] = nil
			end
			if not had.Skin then
				data.Skins[starter.Skin] = nil
			end
			if not had.Effect then
				data.KillEffects[starter.KillEffect] = nil
			end
			data.StarterPack = false
		end
		message = "¡PACK DE INICIO DESBLOQUEADO!"
	elseif revivePack then
		local pack = revivePack
		grant = function()
			data.Revives += pack.Revives
		end
		undo = function()
			data.Revives -= pack.Revives
		end
		message = "+" .. pack.Revives .. " REVIVIR INSTANTÁNEO"
	else
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
		grant = function()
			data.Coins += pack.Coins
		end
		undo = function()
			data.Coins -= pack.Coins
		end
		message = "+" .. pack.Coins .. " MONEDAS"
	end
	grant()
	table.insert(data.Purchases, receipt.PurchaseId)
	while #data.Purchases > MAX_PURCHASE_LOG do
		table.remove(data.Purchases, 1)
	end
	if not store or noSave[player] or not save(player) then
		-- No se pudo guardar: deshacemos y Roblox lo reintentará más tarde (así nunca se pierden Robux)
		undo()
		local index = table.find(data.Purchases, receipt.PurchaseId)
		if index then
			table.remove(data.Purchases, index)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Remotes.Notify:FireClient(player, "Big", message)
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

	local pending = 0
	Players.PlayerRemoving:Connect(function(player)
		pending += 1
		-- Últimos cambios de otros módulos antes del guardado final (p. ej. el tiempo de los regalos)
		if PlayerData.OnLeaving then
			pcall(PlayerData.OnLeaving, player)
		end
		save(player, true)
		pending -= 1
		profiles[player] = nil
		Badges.Forget(player)
		noSave[player] = nil
		match[player] = nil
		cratesRestricted[player] = nil
		dirty[player] = nil
		saveScheduled[player] = nil
	end)

	-- Al cerrar el servidor espera a que terminen todos los guardados (máx. ~25 s)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			if PlayerData.OnLeaving then
				pcall(PlayerData.OnLeaving, player)
			end
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local start = os.clock()
		while pending > 0 and os.clock() - start < 25 do
			task.wait(0.2)
		end
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
		if Skins.List[skinId].Mastery then
			return
		end
		data.EquippedSkin = skinId
		if PlayerData.OnSkinChanged then
			PlayerData.OnSkinChanged(player)
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
	Remotes.TutorialDone.OnServerEvent:Connect(function(player)
		local data = profiles[player]
		if data and not data.TutorialDone then
			data.TutorialDone = true
			dirty[player] = true
			sendUpdate(player)
		end
	end)
	Remotes.SetMelee.OnServerEvent:Connect(function(player, weaponName)
		setWeapon(player, weaponName, "Melee", Weapons.Melees)
	end)

	-- Ajustes del jugador: se validan y se guardan con su progreso
	Remotes.SaveSettings.OnServerEvent:Connect(function(player, settings)
		local data = profiles[player]
		if not data or type(settings) ~= "table" then
			return
		end
		local clean = table.clone(data.Settings)
		if type(settings.Quality) == "string" and table.find(GameConfig.QualityLevels, settings.Quality) then
			clean.Quality = settings.Quality
		end
		for key, limits in GameConfig.SettingsLimits do
			local value = settings[key]
			if type(value) == "number" and value == value then
				clean[key] = math.clamp(math.floor(value * 100 + 0.5) / 100, limits[1], limits[2])
			end
		end
		data.Settings = clean
		dirty[player] = true
	end)

	Remotes.EquipKillEffect.OnServerEvent:Connect(function(player, effectId)
		local data = profiles[player]
		if not data or type(effectId) ~= "string" or not KillEffects.List[effectId] or not data.KillEffects[effectId] then
			return
		end
		data.EquippedKillEffect = effectId
		sendUpdate(player)
	end)

	-- Camuflaje de maestría para un arma ("Default" = usar la skin general)
	Remotes.SetCamo.OnServerEvent:Connect(function(player, weaponName, camoId)
		local data = profiles[player]
		if not data or type(weaponName) ~= "string" or not Weapons.List[weaponName] or type(camoId) ~= "string" then
			return
		end
		if camoId == "Default" then
			data.WeaponCamos[weaponName] = nil
		elseif Mastery.HasCamo(data.WeaponKills[weaponName] or 0, camoId) then
			data.WeaponCamos[weaponName] = camoId
		else
			return
		end
		if PlayerData.OnSkinChanged then
			PlayerData.OnSkinChanged(player)
		end
		sendUpdate(player)
	end)

	-- Cambiar un reto diario sin completar por otro (1 al día)
	Remotes.RerollChallenge.OnServerInvoke = function(player, index)
		local data = profiles[player]
		if not data or type(index) ~= "number" then
			return false
		end
		local state = ensureChallenges(player, data)
		local entry = state.List[index]
		if not entry or entry.Done or (state.Rerolls or 0) >= Challenges.RerollsPerDay then
			return false
		end
		local exclude = {}
		for _, e in state.List do
			exclude[e.Id] = true
		end
		state.Rerolls = (state.Rerolls or 0) + 1
		local new = Challenges.Pick(state.Day, player.UserId, data.Level, 1, exclude, state.Rerolls)[1]
		if not new then
			return false
		end
		state.List[index] = { Id = new, Progress = 0, Done = false }
		sendUpdate(player)
		return true
	end

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
