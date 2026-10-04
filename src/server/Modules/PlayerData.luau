-- Datos persistentes del jugador (nivel, XP, monedas, skins, trajes, armas) guardados con DataStore,
-- y toda la economía: tienda con monedas, compras con Robux, VIP, recompensa diaria, cajas,
-- retos diarios y maestría de armas.
-- En Studio activa: Game Settings > Security > "Enable Studio Access to API Services".
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local GroupService = game:GetService("GroupService")
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
local Charms = require(Shared.Charms)
local Sprays = require(Shared.Sprays)
local Titles = require(Shared.Titles)
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
		TotalDeaths = 0, -- estadísticas del perfil
		Matches = 0,
		BestStreak = 0,
		Headshots = 0,
		RankPoints = 0, -- puntos de rango competitivo (ver Ranks)
		RankBest = 1, -- rango más alto alcanzado (sus premios ya se dieron)
		Premium = false,
		DailyStreak = 0,
		LastDailyDay = -1,
		LastPlayDay = -1,
		FirstWinDay = -1, -- día de la última "primera victoria del día"
		BonusLevel = 0, -- último nivel revisado para los premios de después del pase (0 = sin empezar)
		CratePity = 0, -- partidas seguidas sin caja sorpresa -- último día (Shop.DayNumber) en que entró: para el premio de regreso
		FreeCrates = 0,
		Purchases = {},
		KillEffects = { Default = true }, -- efectos de eliminación comprados
		EquippedKillEffect = "Default",
		Charms = { Default = true }, -- colgantes de arma comprados
		EquippedCharm = "Default",
		Sprays = { Default = true }, -- grafitis comprados (tecla J)
		EquippedSpray = "Default",
		Assists = 0, -- asistencias (ver Combat)
		RankSeason = "", -- temporada de rango de sus RP (ver Ranks.Seasons)
		SeasonBest = 0, -- mejor rango alcanzado en esta temporada (0 = aún no ha jugado de rango)
		ReferredBy = 0, -- quién le invitó (UserId), ver GameConfig.Referral
		Referrals = 0, -- amigos nuevos que entraron con su invitación y le dieron premio
		Titles = {}, -- títulos comprados (los ganados jugando salen de las estadísticas)
		EquippedTitle = "Novato",
		WeaponKills = {}, -- bajas con cada arma (maestría)
		WeaponCamos = {}, -- camuflaje de maestría elegido para cada arma
		Challenges = { Day = -1, List = {}, Rerolls = 0, Bonus = false },
		WeeklyChallenges = { Week = -1, List = {}, Bonus = false }, -- retos semanales
		StarterPack = false, -- ya compró el pack de inicio
		Bundles = {}, -- packs de temporada comprados ([Id] = true, ver Shop.Bundles)
		TutorialDone = false, -- ya vio la tarjeta de controles de la primera partida
		NewsSeen = 0, -- última versión de las novedades que ha visto (GameConfig.News)
		Achievements = {}, -- logros reclamados ([Id] = true)
		GroupReward = false, -- ya reclamó el premio del grupo (GameConfig.Group)
		EventProgress = { Id = "", Count = 0 }, -- caramelos del evento de temporada (ver Event)
		Revives = GameConfig.StartingRevives, -- "Revivir instantáneo" disponibles
		BoostXP = 0, -- segundos de juego que quedan de XP doble (Shop.Boosters)
		BoostCoins = 0, -- segundos de juego que quedan de monedas dobles
		Gifts = { Day = -1, Claimed = 0, Seconds = 0 }, -- regalos por tiempo jugado de hoy (ver Gifts)
		WheelDay = -1, -- último día con giro gratis de la ruleta usado
		WheelSpins = 0, -- giros de ruleta comprados sin usar
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

-- Reparte retos semanales nuevos si ha empezado otra semana
local function ensureWeekly(player, data)
	local week = Challenges.WeekNumber(Shop.DayNumber())
	local state = data.WeeklyChallenges
	if type(state) ~= "table" or state.Week ~= week or type(state.List) ~= "table" then
		local list = {}
		for _, id in Challenges.Pick(week, player.UserId, data.Level, Challenges.WeeklyCount, nil, 17, Challenges.WeeklyPool) do
			table.insert(list, { Id = id, Progress = 0, Done = false })
		end
		state = { Week = week, List = list, Bonus = false }
		data.WeeklyChallenges = state
	end
	return state
end

local function entriesView(entries)
	local list = {}
	for _, entry in entries do
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
	return list
end

local function challengesView(player, data)
	local state = ensureChallenges(player, data)
	local weekly = ensureWeekly(player, data)
	local list = entriesView(state.List)
	return {
		List = list,
		RerollsLeft = math.max(0, Challenges.RerollsPerDay - (state.Rerolls or 0)),
		Bonus = state.Bonus == true,
		BonusCrates = Challenges.BonusCrates,
		Weekly = {
			List = entriesView(weekly.List),
			Bonus = weekly.Bonus == true,
			BonusCrates = Challenges.WeeklyBonusCrates,
			EndsAt = Challenges.WeekEndsAt(weekly.Week),
		},
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
	-- (la temporada en curso; tras la última de Ranks.Seasons no se muestra)
	local season = Ranks.CurrentSeason()
	local seasonView = os.time() < season.EndsAt and data.RankSeason == season.Id and season or nil
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
		TotalDeaths = data.TotalDeaths,
		Assists = data.Assists,
		Matches = data.Matches,
		BestStreak = data.BestStreak,
		Headshots = data.Headshots,
		RankPoints = data.RankPoints,
		Premium = data.Premium,
		VIP = player:GetAttribute("VIP") == true,
		DailyStreak = data.DailyStreak,
		DailyAvailable = data.LastDailyDay ~= Shop.DayNumber(),
		FirstWinAvailable = data.FirstWinDay ~= Shop.DayNumber(),
		FreeCrates = data.FreeCrates,
		CratesRestricted = cratesRestricted[player] == true,
		Day = Shop.DayNumber(),
		WeaponKills = data.WeaponKills,
		WeaponCamos = data.WeaponCamos,
		KillEffects = data.KillEffects,
		EquippedKillEffect = data.EquippedKillEffect,
		Charms = data.Charms,
		EquippedCharm = data.EquippedCharm,
		Sprays = data.Sprays,
		EquippedSpray = data.EquippedSpray,
		Titles = data.Titles,
		EquippedTitle = data.EquippedTitle,
		Settings = data.Settings,
		Revives = data.Revives,
		BoostXP = data.BoostXP,
		BoostCoins = data.BoostCoins,
		WheelFree = data.WheelDay ~= Shop.DayNumber(),
		WheelSpins = data.WheelSpins,
		-- (si sus datos no se guardan, no se le enseña el tutorial: probablemente ya lo vio)
		TutorialDone = data.TutorialDone == true or noSave[player] == true,
		NewsSeen = data.NewsSeen,
		Achievements = data.Achievements,
		GroupReward = data.GroupReward == true,
		RankBest = data.RankBest,
		RankSeasonName = seasonView and seasonView.Name or nil,
		RankSeasonEndsAt = seasonView and seasonView.EndsAt or nil,
		EventCandy = (type(data.EventProgress) == "table" and data.EventProgress.Id == GameConfig.Event.Id) and data.EventProgress.Count or 0,
		StarterPackAvailable = Shop.StarterPack.ProductId ~= 0 and not data.StarterPack and data.Level <= Shop.StarterPack.MaxLevel,
		BundlesAvailable = (function()
			local list = {}
			for _, bundle in Shop.Bundles do
				if Shop.BundleOnSale(bundle) and not data.Bundles[bundle.Id] then
					table.insert(list, bundle.Id)
				end
			end
			return list
		end)(),
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
	elseif reward.Type == "KillEffect" then
		data.KillEffects[reward.Id] = true
		Remotes.Notify:FireClient(player, "Unlock", "¡Efecto desbloqueado: " .. KillEffects.Get(reward.Id).Name .. "!")
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
	-- Tras el pase: premio cada pocos niveles (GameConfig.PostPassRewards). BonusLevel = último nivel
	-- ya revisado; 0 = sin empezar (los que ya estaban por encima del pase empiezan a contar desde ahora)
	local bonus = GameConfig.PostPassRewards
	local passLevels = #GameConfig.BattlePass
	if bonus then
		local checked = tonumber(data.BonusLevel) or 0
		if checked <= 0 then
			data.BonusLevel = math.max(data.Level, passLevels)
		elseif data.Level > checked then
			for level = checked + 1, data.Level do
				if level > passLevels and (level - passLevels) % bonus.Every == 0 then
					data.Coins += bonus.Coins
					data.FreeCrates += bonus.Crates
					Remotes.Notify:FireClient(player, "Challenge", "⭐ ¡Nivel " .. level .. "! +" .. bonus.Coins .. " 🪙 y " .. bonus.Crates .. (bonus.Crates == 1 and " caja" or " cajas"))
				end
			end
			data.BonusLevel = data.Level
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
	-- Ajustes nuevos que aún no tenía guardados (después de la migración de calidad)
	for key, value in GameConfig.DefaultSettings do
		if merged.Settings[key] == nil then
			merged.Settings[key] = value
		end
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
	if type(merged.Charms) ~= "table" then
		merged.Charms = { Default = true }
	end
	if not Charms.List[merged.EquippedCharm] or not merged.Charms[merged.EquippedCharm] then
		merged.EquippedCharm = "Default"
	end
	if type(merged.Achievements) ~= "table" then
		merged.Achievements = {}
	end
	if type(merged.Bundles) ~= "table" then
		merged.Bundles = {}
	end
	if merged.HalloweenBundle == true then
		merged.Bundles.Halloween = true -- (antes se guardaba aparte)
	end
	merged.HalloweenBundle = nil
	if type(merged.Titles) ~= "table" then
		merged.Titles = {}
	end
	if not Titles.List[merged.EquippedTitle] then
		merged.EquippedTitle = "Novato"
	end
	if type(merged.Sprays) ~= "table" then
		merged.Sprays = { Default = true }
	end
	-- (el de VIP se comprueba al pintar: el atributo VIP aún no está puesto al cargar)
	local equippedSpray = Sprays.List[merged.EquippedSpray]
	if not equippedSpray or not (merged.Sprays[merged.EquippedSpray] or equippedSpray.VIPOnly) then
		merged.EquippedSpray = "Default"
	end
	merged.GroupReward = merged.GroupReward == true
	if type(merged.WheelSpins) ~= "number" or merged.WheelSpins < 0 then
		merged.WheelSpins = 0
	end
	if type(merged.WheelDay) ~= "number" then
		merged.WheelDay = -1
	end
	-- (los guardados de antes de existir RankBest: su rango actual)
	if type(merged.RankBest) ~= "number" or (not isNew and type(data) == "table" and data.RankBest == nil) then
		merged.RankBest = math.max(type(merged.RankBest) == "number" and merged.RankBest or 1, Ranks.Index(merged.RankPoints))
	end
	if type(merged.EventProgress) ~= "table" or type(merged.EventProgress.Count) ~= "number" then
		merged.EventProgress = { Id = "", Count = 0 }
	end
	-- Quien ya jugaba antes de existir el tutorial no lo ve
	-- Los nuevos no ven las novedades (ven la tarjeta de controles)
	if isNew or type(merged.NewsSeen) ~= "number" then
		merged.NewsSeen = isNew and GameConfig.ActiveNews().Version or 0
	end
	if not isNew and data.TutorialDone == nil and ((merged.Level or 1) > 1 or (merged.TotalKills or 0) > 0) then
		merged.TutorialDone = true
	end
	merged.Premium = merged.Premium or ownsPass(player, GameConfig.PremiumPassId)
	player:SetAttribute("VIP", ownsPass(player, Shop.VIPPassId))
	PlayerData.UpdatePremium(player)
	checkPolicy(player)

	if not player.Parent then
		noSave[player] = nil
		cratesRestricted[player] = nil
		return
	end
	-- Temporada de rango (premio de la que acabó mientras no jugaba; el aviso, cuando ya ve la pantalla)
	local seasonText = PlayerData.RollSeason(merged)
	if seasonText then
		task.delay(8, function()
			if player.Parent then
				Remotes.Notify:FireClient(player, "Big", seasonText)
			end
		end)
	end
	-- Premio de regreso (tras unos días sin jugar)
	local comebackText = PlayerData.RollComeback(merged)
	if comebackText then
		task.delay(seasonText and 12 or 8, function()
			if player.Parent then
				Remotes.Notify:FireClient(player, "Big", comebackText)
			end
		end)
	end
	profiles[player] = merged
	Badges.Check(player, merged)
	PlayerData.GetLeaderstats(player).Nivel.Value = merged.Level
	player:SetAttribute("Rank", Ranks.Index(merged.RankPoints))
	PlayerData.PublishTitle(player)
	grantTierRewards(player)
	if isNew and not noSave[player] then -- (si no se pudieron cargar sus datos, quizá no es nuevo)
		PlayerData.HandleReferral(player)
	end
	sendUpdate(player)
end

-- Invitación de un amigo (GameConfig.Referral): la invitación lleva "ref:<UserId>" en LaunchData.
-- Solo para jugadores nuevos y una vez; el que invitó cobra si está en este servidor.
function PlayerData.HandleReferral(player)
	local data = profiles[player]
	local config = GameConfig.Referral
	if not data or not config or (data.ReferredBy or 0) ~= 0 then
		return
	end
	local ok, joinData = pcall(player.GetJoinData, player)
	local launch = ok and type(joinData) == "table" and joinData.LaunchData
	local inviterId = type(launch) == "string" and tonumber(string.match(launch, "^ref:(%d+)$"))
	if not inviterId or inviterId == player.UserId or inviterId <= 0 then
		return
	end
	data.ReferredBy = inviterId
	dirty[player] = true
	local inviter = Players:GetPlayerByUserId(inviterId)
	local given = PlayerData.AddCoins(player, config.NewPlayerCoins or 0, false)
	Remotes.Notify:FireClient(player, "Big", "👥 ¡Te invitó " .. (inviter and inviter.DisplayName or "un amigo") .. "! +" .. given .. " 🪙")
	local inviterData = inviter and profiles[inviter]
	-- (cuentas recién creadas no dan premio al que invita: así no se abusa con cuentas de usar y tirar)
	if inviterData and (inviterData.Referrals or 0) < (config.MaxRewards or 0) and (player.AccountAge or 0) >= (config.MinAccountAge or 0) then
		inviterData.Referrals = (inviterData.Referrals or 0) + 1
		local bonus = PlayerData.AddCoins(inviter, config.InviterCoins or 0, false)
		dirty[inviter] = true
		Remotes.Notify:FireClient(inviter, "Big", "👥 ¡" .. player.DisplayName .. " entró con tu invitación! +" .. bonus .. " 🪙")
	end
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

-- Potenciador comprado activo (Shop.Boosters) para "XP" o "Coins"
-- (solo cuenta en partida: lo que se reclama desde la portada, como la recompensa diaria, no se dobla)
local function boosterMultiplier(player, data, kind)
	if player:GetAttribute("InMenu") ~= false then
		return 1
	end
	for _, booster in Shop.Boosters do
		if booster.Kind == kind and (tonumber(data[booster.Field]) or 0) > 0 then
			return booster.Multiplier
		end
	end
	return 1
end

-- VIP (x2), Roblox Premium (x1,2) y bonus de amigos en el servidor (+10% por amigo, ver Friends)
local function multiplier(player)
	local vip = player:GetAttribute("VIP") and Shop.VIPMultiplier or 1
	local premium = player:GetAttribute("RobloxPremium") and GameConfig.RobloxPremium and GameConfig.RobloxPremium.Multiplier or 1
	return vip * premium * Friends.Multiplier(player)
end

-- XP extra de hoy (GameConfig.XPBoost: fin de semana de XP doble)
local function xpBoost()
	local boost = GameConfig.XPBoost
	if not boost or not boost.Enabled then
		return 1
	end
	local today = os.date("!*t").wday
	return table.find(boost.Days, today) and boost.Multiplier or 1
end
PlayerData.XPBoost = xpBoost

-- Lo pone Event: se llama al recoger la recompensa diaria
PlayerData.OnDailyClaimed = nil :: ((Player) -> ())?

-- Roblox Premium (atributo RobloxPremium: lo leen el multiplicador y la Tienda)
function PlayerData.UpdatePremium(player)
	local ok, premium = pcall(function()
		return player.MembershipType == Enum.MembershipType.Premium
	end)
	player:SetAttribute("RobloxPremium", ok and premium == true)
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

-- Da un arma (premios de evento). Devuelve false si ya la tenía
function PlayerData.GiveWeapon(player, weaponName)
	local data = profiles[player]
	if not data or not Weapons.List[weaponName] or data.OwnedWeapons[weaponName] then
		return false
	end
	data.OwnedWeapons[weaponName] = true
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

-- Cambio de temporada de rango: premio por el mejor rango de la anterior y RP a la mitad.
-- Devuelve el texto del aviso (o nil si no tocaba).
function PlayerData.RollSeason(data)
	local season = Ranks.CurrentSeason()
	if data.RankSeason == season.Id then
		return nil
	end
	if type(data.RankSeason) ~= "string" or data.RankSeason == "" then
		-- (jugador nuevo o guardado de antes de las temporadas: empieza en la actual sin premio)
		data.RankSeason = season.Id
		data.SeasonBest = 0
		return nil
	end
	-- (SeasonBest = 0: no jugó ninguna partida de rango esa temporada, así que no hay premio)
	local best = math.clamp(math.floor(tonumber(data.SeasonBest) or 0), 0, #Ranks.Tiers)
	local coins = best > 0 and Ranks.SeasonRewards[best] or 0
	local finished = Ranks.SeasonName(data.RankSeason)
	data.Coins += coins
	data.RankPoints = math.floor((data.RankPoints or 0) * Ranks.SeasonCarry)
	data.RankSeason = season.Id
	data.SeasonBest = 0
	if best == 0 then
		return "🏁 ¡Empieza la " .. season.Name .. "! Tus RP pasan a la mitad: juega para subir"
	end
	local tier = Ranks.Tiers[best]
	return "🏁 ¡Fin de la " .. finished .. "! Llegaste a " .. tier.Icon .. " " .. tier.Name .. ": +" .. coins .. " 🪙. Empieza la " .. season.Name
end

-- Premio de regreso (GameConfig.Comeback): se apunta el día de hoy; si hacía Days días o más que no
-- entraba, monedas y cajas gratis. Los guardados sin LastPlayDay (nuevos o de antes) solo se apuntan.
function PlayerData.RollComeback(data, today)
	today = today or Shop.DayNumber()
	local last = tonumber(data.LastPlayDay) or -1
	data.LastPlayDay = today
	local config = GameConfig.Comeback
	if not config or last < 0 or today - last < config.Days then
		return nil
	end
	data.Coins += config.Coins
	data.FreeCrates = (data.FreeCrates or 0) + config.Crates
	data.BoostXP = (tonumber(data.BoostXP) or 0) + (config.BoostXPMinutes or 0) * 60
	return "👋 ¡BIENVENIDO DE VUELTA! Regalo por volver: +" .. config.Coins .. " 🪙"
		.. (config.Crates > 0 and (", " .. config.Crates .. (config.Crates == 1 and " caja gratis" or " cajas gratis")) or "")
		.. ((config.BoostXPMinutes or 0) > 0 and (" y ⚡ XP doble " .. config.BoostXPMinutes .. " min") or "")
end

-- Primera victoria del día (GameConfig.FirstWinOfDay): premio extra una vez al día (hora UTC).
-- Devuelve las monedas dadas (o nil si ya la tuvo hoy).
function PlayerData.ClaimFirstWin(player, scale)
	local data = profiles[player]
	local config = GameConfig.FirstWinOfDay
	if not data or not config then
		return nil
	end
	local today = Shop.DayNumber()
	if data.FirstWinDay == today then
		return nil
	end
	data.FirstWinDay = today
	dirty[player] = true
	scale = scale or 1
	PlayerData.AddXP(player, math.floor(config.XP * scale), "Primera victoria del día")
	return PlayerData.AddCoins(player, math.floor(config.Coins * scale))
end

-- Caja sorpresa (GameConfig.SurpriseCrate): al acabar una partida jugada, una probabilidad pequeña de
-- una caja gratis; tras Pity partidas sin ninguna, sale seguro. Devuelve true si toca.
function PlayerData.RollSurpriseCrate(player, roll)
	local data = profiles[player]
	local config = GameConfig.SurpriseCrate
	if not data or not config then
		return false
	end
	data.CratePity = (tonumber(data.CratePity) or 0) + 1
	local chance = config.Chance * (player:GetAttribute("VIP") and (config.VIPMultiplier or 1) or 1)
	if (roll or math.random()) >= chance and data.CratePity < config.Pity then
		return false
	end
	data.CratePity = 0
	data.FreeCrates += 1
	dirty[player] = true
	sendUpdate(player)
	return true
end

-- Cambia de temporada a un jugador conectado (al acabar una partida o desde el bucle del servidor).
-- Devuelve true si ha cambiado.
function PlayerData.CheckSeason(player)
	local data = profiles[player]
	if not data then
		return false
	end
	local text = PlayerData.RollSeason(data)
	if not text then
		return false
	end
	player:SetAttribute("Rank", Ranks.Index(data.RankPoints))
	-- (el resumen de la partida compara con los RP ya recortados: el recorte no es de la partida)
	if match[player] then
		match[player].StartRank = data.RankPoints
	end
	Remotes.Notify:FireClient(player, "Big", text)
	dirty[player] = true
	sendUpdate(player)
	return true
end

-- Suma (o resta) puntos de rango al acabar una partida; nunca baja del inicio del rango actual
function PlayerData.AddRankPoints(player, delta)
	local data = profiles[player]
	if not data or delta == 0 then
		return 0
	end
	matchOf(player, data) -- (el resumen de la partida guarda el rango de antes)
	-- (si la temporada acabó con el servidor encendido, se cambia antes de sumar)
	PlayerData.CheckSeason(player)
	local before = data.RankPoints
	data.RankPoints = Ranks.Apply(before, delta)
	local index = Ranks.Index(data.RankPoints)
	data.SeasonBest = math.max(tonumber(data.SeasonBest) or 0, index)
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

-- fixed = true: premio fijo (no lo multiplican VIP ni amigos y no cuenta en el resumen de la partida)
function PlayerData.AddXP(player, amount, reason, fixed)
	local data = profiles[player]
	if not data or amount <= 0 then
		return
	end
	if not fixed then
		amount = math.floor(amount * multiplier(player) * xpBoost() * boosterMultiplier(player, data, "XP"))
		matchOf(player, data).XP += amount
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
-- noBoost = true: le aplican VIP y amigos pero no los potenciadores (p. ej. la recompensa diaria)
function PlayerData.AddCoins(player, amount, earned, noBoost)
	local data = profiles[player]
	if data then
		if earned ~= false then
			amount = math.floor(amount * multiplier(player) * (noBoost and 1 or boosterMultiplier(player, data, "Coins")))
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

-- Guarda un récord (por ejemplo la mejor racha de bajas) si lo supera
function PlayerData.SetBest(player, field, value)
	local data = profiles[player]
	if data and type(data[field]) == "number" and value > data[field] then
		data[field] = value
		dirty[player] = true
	end
end

-- Título que ven los demás (atributos Title y TitleColor). Si ya no lo tiene (p. ej. el de VIP), Novato.
function PlayerData.PublishTitle(player)
	local data = profiles[player]
	if not data then
		return
	end
	local id = data.EquippedTitle
	if not Titles.Owns(data, id, player:GetAttribute("VIP") == true) then
		id = "Novato"
	end
	local title = Titles.Get(id)
	player:SetAttribute("Title", id ~= "Novato" and title.Name or nil)
	player:SetAttribute("TitleColor", title.Color)
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
	-- Retos semanales
	local weekly = ensureWeekly(player, data)
	local weeklyChanged = false
	for _, entry in weekly.List do
		local def = Challenges.Get(entry.Id)
		if def and not entry.Done and Challenges.Matches(def, stat, weaponName) then
			if stat == "Streak" then
				entry.Progress = math.max(entry.Progress, amount or 0)
			else
				entry.Progress += amount or 1
			end
			if entry.Progress >= def.Goal then
				entry.Done = true
				weeklyChanged = true
				Remotes.Notify:FireClient(player, "Challenge", "¡RETO SEMANAL COMPLETADO! +" .. def.Coins .. " 🪙")
				PlayerData.AddCoins(player, def.Coins, false)
				PlayerData.AddXP(player, def.XP, "Reto semanal")
			end
		end
	end
	if weeklyChanged and not weekly.Bonus then
		local all = #weekly.List > 0
		for _, entry in weekly.List do
			all = all and entry.Done
		end
		if all then
			weekly.Bonus = true
			data.FreeCrates += Challenges.WeeklyBonusCrates
			Remotes.Notify:FireClient(player, "Unlock", "¡Retos de la semana completados! " .. Challenges.WeeklyBonusCrates .. " cajas gratis 🎁")
		end
	end
	if changed or weeklyChanged then
		sendUpdate(player)
	end
end

-- Cuenta una baja con un arma y entrega la maestría al subir de nivel
function PlayerData.AddWeaponKill(player, weaponName)
	local data = profiles[player]
	if not data or type(weaponName) ~= "string" or not Weapons.List[weaponName] or Weapons.List[weaponName].Hidden then
		return -- (las garras de zombi no tienen maestría)
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
	elseif kind == "Charm" then
		if not Charms.List[id] then
			return false, "No existe"
		end
		if data.Charms[id] then
			return false, "Ya lo tienes"
		end
		price = Shop.GetPrice("Charm", id)
	elseif kind == "Spray" then
		if not Sprays.List[id] then
			return false, "No existe"
		end
		if data.Sprays[id] then
			return false, "Ya lo tienes"
		end
		price = Shop.GetPrice("Spray", id)
	elseif kind == "Title" then
		if not Titles.List[id] then
			return false, "No existe"
		end
		if data.Titles[id] then
			return false, "Ya lo tienes"
		end
		price = Shop.GetPrice("Title", id)
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
	elseif kind == "Charm" then
		data.Charms[id] = true
		data.EquippedCharm = id -- se equipa al comprarlo (se ve al reaparecer)
	elseif kind == "Spray" then
		data.Sprays[id] = true
		data.EquippedSpray = id -- se equipa al comprarlo
	elseif kind == "Title" then
		data.Titles[id] = true
		data.EquippedTitle = id
		PlayerData.PublishTitle(player)
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
	local given = PlayerData.AddCoins(player, coins, true, true)
	local crate = streak == Shop.DailyCrateDay
	if crate then
		data.FreeCrates += 1
	end
	if player:GetAttribute("VIP") then
		data.FreeCrates += 1 -- caja diaria extra del VIP
	end
	sendUpdate(player)
	-- (el evento en marcha regala también unos objetos; lo pone Event)
	if PlayerData.OnDailyClaimed then
		task.spawn(PlayerData.OnDailyClaimed, player)
	end
	return true, { Streak = streak, Coins = given, Crate = crate }
end

local pendingReceipt = {} -- [player] = true mientras se guarda una compra con Robux

-- Ruleta: gasta el giro gratis de hoy (o uno comprado) y da un premio al azar según su peso.
-- Devuelve el índice del premio para que el cliente pare la ruleta en él.
local lastSpin = {} -- [player] = os.clock() (no más de un giro cada 3 s: dura la animación)
local function spinWheel(player)
	local data = profiles[player]
	if not data then
		return false, "Cargando..."
	end
	if os.clock() - (lastSpin[player] or 0) < 3 then
		return false, "Espera a que pare la ruleta"
	end
	local today = Shop.DayNumber()
	if data.WheelDay ~= today then
		data.WheelDay = today
	elseif data.WheelSpins > 0 and not cratesRestricted[player] and not pendingReceipt[player] then
		-- (los giros comprados son premios al azar de pago: no donde no se permiten; y no mientras se
		-- guarda una compra, por si hay que deshacerla)
		data.WheelSpins -= 1
	else
		return false, "Vuelve mañana para otro giro gratis"
	end
	lastSpin[player] = os.clock()
	local prizes = Shop.Wheel.Prizes
	local total = 0
	for _, prize in prizes do
		total += prize.Weight
	end
	local roll = math.random() * total
	local index = #prizes
	for i, prize in prizes do
		roll -= prize.Weight
		if roll <= 0 then
			index = i
			break
		end
	end
	local prize = prizes[index]
	-- (premio fijo: no lo multiplica el VIP)
	if prize.Kind == "Coins" then
		data.Coins += prize.Amount
	elseif prize.Kind == "Revives" then
		data.Revives += prize.Amount
	elseif prize.Kind == "Crate" then
		data.FreeCrates += prize.Amount
	elseif prize.Kind == "XP" then
		PlayerData.AddXP(player, prize.Amount, "Ruleta", true)
	elseif prize.Kind == "Boost" then
		data[prize.Field] = (tonumber(data[prize.Field]) or 0) + prize.Amount * 60
	end
	sendUpdate(player)
	requestSave(player)
	return true, index
end
Players.PlayerRemoving:Connect(function(player)
	lastSpin[player] = nil
end)

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
	local wheel = Shop.Wheel
	local bundle
	for _, b in Shop.Bundles do
		if b.ProductId ~= 0 and b.ProductId == receipt.ProductId then
			bundle = b
		end
	end
	local booster
	for _, b in Shop.Boosters do
		if b.ProductId ~= 0 and b.ProductId == receipt.ProductId then
			booster = b
		end
	end
	if bundle then
		-- Pack de temporada (si ya lo tenía, Roblox ya cobró: se entregan solo las monedas). Al
		-- deshacer solo se quita lo que se dio.
		local repeated = data.Bundles[bundle.Id] == true
		local had = {
			Effect = data.KillEffects[bundle.KillEffect] == true,
			Charm = data.Charms[bundle.Charm] == true,
			Spray = data.Sprays[bundle.Spray] == true,
		}
		grant = function()
			data.Coins += bundle.Coins
			if not repeated then
				data.KillEffects[bundle.KillEffect] = true
				data.Charms[bundle.Charm] = true
				data.Sprays[bundle.Spray] = true
				data.Bundles[bundle.Id] = true
			end
		end
		undo = function()
			data.Coins -= bundle.Coins
			if not repeated then
				if not had.Effect then
					data.KillEffects[bundle.KillEffect] = nil
				end
				if not had.Charm then
					data.Charms[bundle.Charm] = nil
				end
				if not had.Spray then
					data.Sprays[bundle.Spray] = nil
				end
				data.Bundles[bundle.Id] = nil
			end
		end
		message = repeated and ("+" .. bundle.Coins .. " MONEDAS") or (bundle.Icon .. " ¡" .. bundle.Name .. " DESBLOQUEADO!")
	elseif booster then
		local seconds = booster.Minutes * 60
		grant = function()
			data[booster.Field] = (tonumber(data[booster.Field]) or 0) + seconds
		end
		undo = function()
			data[booster.Field] = math.max(0, (tonumber(data[booster.Field]) or 0) - seconds)
		end
		message = booster.Icon .. " ¡" .. string.upper(booster.Name) .. " " .. booster.Minutes .. " MIN!"
	elseif wheel.SpinProductId ~= 0 and receipt.ProductId == wheel.SpinProductId then
		grant = function()
			data.WheelSpins += wheel.SpinsPerPurchase
		end
		undo = function()
			data.WheelSpins -= wheel.SpinsPerPurchase
		end
		message = "+" .. wheel.SpinsPerPurchase .. " GIROS DE RULETA"
	elseif starter.ProductId ~= 0 and receipt.ProductId == starter.ProductId and data.StarterPack then
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
	pendingReceipt[player] = true
	grant()
	table.insert(data.Purchases, receipt.PurchaseId)
	while #data.Purchases > MAX_PURCHASE_LOG do
		table.remove(data.Purchases, 1)
	end
	local saved = store and not noSave[player] and save(player)
	pendingReceipt[player] = nil
	if not saved then
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
	-- Publica si hay XP extra hoy (la pantalla de inicio lo anuncia); se revisa cada minuto
	-- Potenciadores: su tiempo corre solo mientras se juega (no en la portada)
	task.spawn(function()
		local STEP = 5
		while true do
			task.wait(STEP)
			for player, data in profiles do
				if player:GetAttribute("InMenu") ~= false then
					continue -- (en la portada o aún sin entrar en partida)
				end
				local changed, update = false, false
				for _, booster in Shop.Boosters do
					local left = tonumber(data[booster.Field]) or 0
					if left > 0 then
						data[booster.Field] = math.max(0, left - STEP)
						changed = true
						if data[booster.Field] == 0 then
							Remotes.Notify:FireClient(player, "Challenge", booster.Icon .. " Se acabó tu " .. booster.Name)
							update = true
						elseif data[booster.Field] % 60 < STEP then
							update = true -- (el cliente cuenta los segundos; se corrige cada minuto)
						end
					end
				end
				if changed then
					dirty[player] = true
				end
				if update then
					sendUpdate(player)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			ReplicatedStorage:SetAttribute("XPBoost", xpBoost())
			-- (la temporada de rango puede acabar con el servidor encendido)
			for player in profiles do
				PlayerData.CheckSeason(player)
			end
			task.wait(60)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		PlayerData.GetLeaderstats(player)
		load(player)
	end)
	for _, player in Players:GetPlayers() do
		PlayerData.GetLeaderstats(player)
		task.spawn(load, player)
	end
	-- Se hace Premium sin salir del juego (botón de la Tienda)
	pcall(function()
		Players.PlayerMembershipChanged:Connect(function(player)
			PlayerData.UpdatePremium(player)
			local config = GameConfig.RobloxPremium
			if player:GetAttribute("RobloxPremium") and config then
				Remotes.Notify:FireClient(player, "Big", utf8.char(0xE001) .. " ¡ROBLOX PREMIUM! +" .. math.floor((config.Multiplier - 1) * 100 + 0.5) .. "% monedas y XP")
			end
			if profiles[player] then
				sendUpdate(player) -- (la Tienda se vuelve a dibujar con el bonus activo)
			end
		end)
	end)

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
	Remotes.NewsSeen.OnServerEvent:Connect(function(player)
		local data = profiles[player]
		local version = GameConfig.ActiveNews().Version
		if data and (data.NewsSeen or 0) < version then
			data.NewsSeen = version
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

	Remotes.EquipCharm.OnServerEvent:Connect(function(player, charmId)
		local data = profiles[player]
		if not data or type(charmId) ~= "string" or not Charms.List[charmId] or not data.Charms[charmId] then
			return
		end
		data.EquippedCharm = charmId
		dirty[player] = true
		sendUpdate(player)
	end)

	Remotes.EquipTitle.OnServerEvent:Connect(function(player, titleId)
		local data = profiles[player]
		if not data or type(titleId) ~= "string" or not Titles.Owns(data, titleId, player:GetAttribute("VIP") == true) then
			return
		end
		data.EquippedTitle = titleId
		dirty[player] = true
		PlayerData.PublishTitle(player)
		sendUpdate(player)
	end)

	Remotes.EquipSpray.OnServerEvent:Connect(function(player, sprayId)
		local data = profiles[player]
		if not data or type(sprayId) ~= "string" or not Sprays.Owns(data.Sprays, sprayId, player:GetAttribute("VIP") == true) then
			return
		end
		data.EquippedSpray = sprayId
		dirty[player] = true
		sendUpdate(player)
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
	Remotes.SpinWheel.OnServerInvoke = spinWheel
	-- Logros: se reclaman si el dato llega a la meta y no se habían reclamado
	Remotes.ClaimAchievement.OnServerInvoke = function(player, id)
		local data = profiles[player]
		if not data or type(id) ~= "string" then
			return false, "No se pudo reclamar"
		end
		for _, achievement in GameConfig.Achievements do
			if achievement.Id == id then
				if data.Achievements[id] then
					return false, "Ya lo tienes"
				end
				if (tonumber(data[achievement.Stat]) or 0) < achievement.Goal then
					return false, "Aún no lo has conseguido"
				end
				data.Achievements[id] = true
				data.Coins += achievement.Coins
				dirty[player] = true
				sendUpdate(player)
				return true, achievement.Coins
			end
		end
		return false, "No existe"
	end
	-- Premio por unirse al grupo (una vez). IsInGroup se guarda en caché en el servidor, así que si
	-- dice que no se pregunta también a GroupService (por si se acaba de unir sin salir del juego)
	local groupChecked = {}
	Remotes.ClaimGroup.OnServerInvoke = function(player)
		local data = profiles[player]
		local group = GameConfig.Group
		if not data or not group or group.Id == 0 then
			return false, "No disponible"
		end
		if data.GroupReward then
			return false, "Ya lo tienes"
		end
		local now = os.clock()
		if groupChecked[player] and now - groupChecked[player] < 3 then
			return false, "Espera un momento"
		end
		groupChecked[player] = now
		local ok, member = pcall(player.IsInGroup, player, group.Id)
		if not (ok and member) then
			local found, groups = pcall(GroupService.GetGroupsAsync, GroupService, player.UserId)
			member = false
			if found and type(groups) == "table" then
				for _, info in groups do
					if info.Id == group.Id then
						member = true
					end
				end
			end
		end
		if not member or profiles[player] ~= data or data.GroupReward then
			return false, "NotMember"
		end
		data.GroupReward = true
		data.Coins += group.Coins
		dirty[player] = true
		sendUpdate(player)
		return true, group.Coins
	end
	Players.PlayerRemoving:Connect(function(player)
		groupChecked[player] = nil
	end)
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
			PlayerData.PublishTitle(player)
			Remotes.Notify:FireClient(player, "Big", "¡VIP ACTIVADO! x2 XP y monedas")
		end
		sendUpdate(player)
		save(player)
	end)
end

return PlayerData
