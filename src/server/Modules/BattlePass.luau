-- Pase de batalla (servidor): XP del pase, niveles, reclamar recompensas, misiones de temporada y
-- cambio de temporada. Funciones sobre los datos del jugador (PlayerData las llama y se encarga de
-- avisar al cliente y guardar). Config en Shared/Economy/BattlePassConfig.
--
-- data.Pass = { Season, XP, Free = { ["n"] = true }, Premium = { ["n"] = true }, HasPremium,
--               Missions = { [Id] = progreso }, Done = { [Id] = true } }
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Config = require(Shared.Economy.BattlePassConfig)
local Catalog = require(Shared.Economy.CosmeticCatalog)

local BattlePass = {}

local function sameReward(a, b)
	if a == nil or b == nil then
		return a == b
	end
	return a.Type == b.Type and a.Id == b.Id and a.Amount == b.Amount
end

local function emptyPass(seasonId)
	return { Season = seasonId, XP = 0, Free = {}, Premium = {}, HasPremium = false, Missions = {}, Done = {} }
end

-- Da una recompensa (monedas u objeto). Devuelve una ficha para la interfaz.
function BattlePass.GrantReward(data, reward)
	if not reward then
		return nil
	end
	if reward.Type == "Coins" then
		data.Coins += reward.Amount
		return { Type = "Coins", Amount = reward.Amount }
	elseif reward.Type == "Crate" then
		data.FreeCrates = (data.FreeCrates or 0) + (reward.Amount or 1) -- (temporadas antiguas)
		return { Type = "Crate", Amount = reward.Amount or 1 }
	elseif Catalog.Exists(reward.Type, reward.Id) then
		local new = Catalog.Grant(data, reward.Type, reward.Id)
		local item = Catalog.Item(reward.Type, reward.Id)
		-- (si ya lo tenía, monedas a cambio: lo ganado no se pierde)
		local coins = 0
		if not new then
			coins = math.min(Catalog.Compensation(reward.Type, reward.Id), 1500)
			data.Coins += coins
		end
		return { Type = reward.Type, Id = reward.Id, Name = item and item.Name, Rarity = item and item.Rarity, Duplicate = not new, Coins = coins }
	end
	return nil
end

function BattlePass.Tier(data)
	local pass = data.Pass
	return Config.TierFor(pass and pass.XP or 0)
end

-- ¿Puede reclamar? (nivel alcanzado, no reclamado, premium si es de la vía premium)
local function canClaim(pass, season, tier, track)
	local entry = season.Tiers[tier]
	local reward = entry and entry[track]
	if not reward then
		return false
	end
	if tier > Config.TierFor(pass.XP) then
		return false
	end
	if track == "Premium" and not pass.HasPremium then
		return false
	end
	return not pass[track][tostring(tier)]
end

-- Prepara el pase de la temporada en curso. Si cambió de temporada, entrega sola lo que quedó sin
-- reclamar de la anterior. Devuelve la lista de lo entregado así (para avisar) o nil.
function BattlePass.Ensure(data, now)
	local season = Config.Current(now)
	local pass = data.Pass
	if type(pass) ~= "table" or type(pass.Season) ~= "string" then
		pass = nil
	end
	if not season then
		return nil -- (entre temporadas el pase anterior se queda como está)
	end
	if pass and pass.Season == season.Id then
		pass.XP = math.max(0, tonumber(pass.XP) or 0)
		for _, field in { "Free", "Premium", "Missions", "Done" } do
			if type(pass[field]) ~= "table" then
				pass[field] = {}
			end
		end
		return nil
	end
	local granted
	if pass then
		local old = Config.Get(pass.Season)
		if old then
			granted = {}
			for tier = 1, Config.TierFor(pass.XP) do
				for _, track in { "Free", "Premium" } do
					if canClaim(pass, old, tier, track) then
						pass[track][tostring(tier)] = true
						table.insert(granted, BattlePass.GrantReward(data, old.Tiers[tier][track]))
					end
				end
			end
		end
	end
	local fresh = emptyPass(season.Id)
	if season.LegacyPremium and data.Premium == true then
		fresh.HasPremium = true
	end
	-- Primera vez con pase por temporadas: el de antes iba por nivel de cuenta. Empieza en el nivel
	-- que tenía y lo que ya le dio el pase antiguo cuenta como reclamado (si es lo mismo)
	if not pass and season.MigrateFromLevel and (tonumber(data.Level) or 1) > 1 then
		local level = math.min(tonumber(data.Level) or 1, Config.Tiers)
		fresh.XP = Config.XPFor(level)
		for tier = 1, level do
			local old = GameConfig.BattlePass[tier] or {}
			local new = season.Tiers[tier]
			local k = tostring(tier)
			if type(data.ClaimedFree) == "table" and data.ClaimedFree[k] and sameReward(old.Free, new.Free) then
				fresh.Free[k] = true
			end
			if type(data.ClaimedPremium) == "table" and data.ClaimedPremium[k] and sameReward(old.Premium, new.Premium) then
				fresh.Premium[k] = true
			end
		end
	end
	data.Pass = fresh
	return granted
end

-- Suma XP del pase. Devuelve nivel antes y después.
function BattlePass.AddXP(data, amount, now)
	local season = Config.Current(now)
	local pass = data.Pass
	if not season or type(pass) ~= "table" or pass.Season ~= season.Id or (tonumber(amount) or 0) <= 0 then
		local tier = pass and Config.TierFor(pass.XP) or 1
		return tier, tier, 0
	end
	local before = Config.TierFor(pass.XP)
	local maxXP = Config.MaxXP()
	local added = math.max(0, math.min(math.floor(amount), maxXP - pass.XP))
	pass.XP += added
	return before, Config.TierFor(pass.XP), added
end

-- Reclama una recompensa. track = "Free" | "Premium"
function BattlePass.Claim(data, tier, track)
	local pass = data.Pass
	local season = pass and Config.Get(pass.Season)
	if not season or type(tier) ~= "number" or tier ~= tier or (track ~= "Free" and track ~= "Premium") then
		return nil, "No existe"
	end
	tier = math.floor(tier)
	if tier > Config.TierFor(pass.XP) then
		return nil, "Aún no has llegado a ese nivel"
	end
	if track == "Premium" and not pass.HasPremium then
		return nil, "Es del pase premium"
	end
	if not canClaim(pass, season, tier, track) then
		return nil, "Ya está reclamado"
	end
	pass[track][tostring(tier)] = true
	local granted = BattlePass.GrantReward(data, season.Tiers[tier][track])
	if granted then
		granted.Tier = tier
		granted.Track = track
	end
	return granted
end

-- Reclama todo lo que se pueda
function BattlePass.ClaimAll(data)
	local list = {}
	local pass = data.Pass
	local season = pass and Config.Get(pass.Season)
	if not season then
		return list
	end
	for tier = 1, Config.TierFor(pass.XP) do
		for _, track in { "Free", "Premium" } do
			if canClaim(pass, season, tier, track) then
				local granted = BattlePass.Claim(data, tier, track)
				if granted then
					table.insert(list, granted)
				end
			end
		end
	end
	return list
end

-- Cuántas recompensas hay por reclamar (para el punto rojo)
function BattlePass.Claimable(data)
	local pass = data.Pass
	local season = pass and Config.Get(pass.Season)
	if not season then
		return 0
	end
	local count = 0
	for tier = 1, Config.TierFor(pass.XP) do
		for _, track in { "Free", "Premium" } do
			if canClaim(pass, season, tier, track) then
				count += 1
			end
		end
	end
	return count
end

-- Progreso de las misiones de temporada. Devuelve las completadas ahora (ya suman su XP).
function BattlePass.Track(data, stat, amount, now)
	local season = Config.Current(now)
	local pass = data.Pass
	local done = {}
	if not season or type(pass) ~= "table" or pass.Season ~= season.Id then
		return done
	end
	for _, mission in season.Missions or {} do
		if mission.Stat == stat and not pass.Done[mission.Id] then
			local progress = tonumber(pass.Missions[mission.Id]) or 0
			if stat == "Streak" then
				progress = math.max(progress, tonumber(amount) or 0)
			else
				progress += tonumber(amount) or 1
			end
			pass.Missions[mission.Id] = math.min(progress, mission.Goal)
			if progress >= mission.Goal then
				pass.Done[mission.Id] = true
				BattlePass.AddXP(data, mission.XP, now)
				table.insert(done, mission)
			end
		end
	end
	return done
end

-- Lo que ve el cliente
function BattlePass.View(data, now)
	local pass = data.Pass
	local season = pass and Config.Get(pass.Season)
	if not season then
		return nil
	end
	now = now or os.time()
	local missions = {}
	for _, mission in season.Missions or {} do
		table.insert(missions, {
			Id = mission.Id,
			Text = mission.Text,
			Goal = mission.Goal,
			XP = mission.XP,
			Progress = math.min(tonumber(pass.Missions[mission.Id]) or 0, mission.Goal),
			Done = pass.Done[mission.Id] == true,
		})
	end
	return {
		Season = season.Id,
		Name = season.Name,
		Title = season.Title,
		EndsAt = season.EndsAt,
		Active = now >= season.StartsAt and now < season.EndsAt,
		XP = pass.XP,
		Tier = Config.TierFor(pass.XP),
		XPPerTier = Config.XPPerTier,
		Tiers = Config.Tiers,
		HasPremium = pass.HasPremium == true,
		Free = pass.Free,
		Premium = pass.Premium,
		Claimable = BattlePass.Claimable(data),
		Missions = missions,
	}
end

return BattlePass
