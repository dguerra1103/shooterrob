-- Rondas, modos de juego, votación de mapa/modo, equipos, marcador, rachas y recompensas.
-- Modos: TDM (duelo por equipos), CTF (captura la bandera), KOTH (zona de control),
--        FFA (todos contra todos), GUN (escalada de armas) y ELIM (eliminación: rondas de una vida).
--
-- Estado publicado en ReplicatedStorage para la interfaz:
--   State ("Intermission" | "Playing" | "Ended"), Mode, ModeName, TeamMode, TimeLeft, ScoreToWin,
--   Score_<Equipo>, LeaderName, LeaderScore, MapName,
--   NoRespawn (true en plena ronda de Eliminación), AliveA / AliveB (vivos de cada equipo en Eliminación),
--   VoteN_Map, VoteN_Mode, VoteN_Count (N = 1..3) durante el descanso
-- En cada jugador: atributo Score (bajas en FFA / nivel en Escalada), Streak, Captures, GunLevel
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)
local Ranks = require(Shared.Ranks)

local PlayerData = require(script.Parent.PlayerData)
local Flags = require(script.Parent.Flags)
local Hardpoint = require(script.Parent.Hardpoint)
local Domination = require(script.Parent.Domination)
local Bomb = require(script.Parent.Bomb)
local MapBuilder = require(script.Parent.MapBuilder)
local Loadout = require(script.Parent.Loadout)
local Killstreaks = require(script.Parent.Killstreaks)
local Grenades = require(script.Parent.Grenades)
local Respawn = require(script.Parent.Respawn)
local Bots = require(script.Parent.Bots)
local SpawnPicker = require(script.Parent.SpawnPicker)
local Zombie = require(script.Parent.Zombie)
local Bounty = require(script.Parent.Bounty)
local Pumpkins = require(script.Parent.Pumpkins)
local Loot = require(script.Parent.Loot)
local Combat = require(script.Parent.Combat)
local Friends = require(script.Parent.Friends)

local Round = {}

local teams = {}
local roundOver = false
local currentMode = "TDM"
local votes = {} -- [player] = índice
local voteOptions = {}

local onInfectionDeath -- (Infección: quien cae ante los zombis se convierte; ver más abajo)

-- ¿Ha ganado la partida este jugador? En Infección, si ganan los zombis solo cuentan como ganadores
-- los que ya eran zombis al empezar (los supervivientes convertidos han perdido)
local function wonTeam(player, winner)
	if winner == nil or player.Team ~= winner then
		return false
	end
	if currentMode == "INF" and winner == teams[2] then
		return player:GetAttribute("InfZombieStart") == true
	end
	return true
end

-- Rivales distintos eliminados en la racha actual (para SE BUSCA: matar al mismo amigo varias veces
-- no cuenta como "racha contra jugadores")
local streakVictims = {} -- [player] = { [UserId] = true }
local firstBlood = false -- ya hubo la primera baja de la partida (medalla Primera sangre)
local lastKill = nil -- { Killer, Victim, Weapon, Time }: la última baja (para la killcam final)
local decidingKill = nil -- la baja que cerró la partida (desde ahí todo queda congelado hasta su repetición)

local STREAK_ANNOUNCE = { [3] = true, [5] = true, [7] = true, [10] = true, [15] = true, [20] = true }

local function setState(state)
	ReplicatedStorage:SetAttribute("State", state)
end

local function settings(mode)
	return GameConfig.ModeSettings[mode or currentMode]
end

-- Nombre del modo para la interfaz (Calabazas es "Baja confirmada" fuera de Halloween)
local function modeName(mode)
	if mode == "CAL" and Pumpkins.Tags() then
		return "Baja confirmada"
	end
	return GameConfig.ModeSettings[mode].Name
end

local function isTeamMode(mode)
	return settings(mode).Teams ~= false
end

local function getScore(teamName)
	return ReplicatedStorage:GetAttribute("Score_" .. teamName) or 0
end

local function setupTeams()
	for _, cfg in GameConfig.Teams do
		local team = Teams:FindFirstChild(cfg.Name)
		if not team then
			team = Instance.new("Team")
			team.Name = cfg.Name
			team.TeamColor = cfg.Color
			team.AutoAssignable = false
			team.Parent = Teams
		end
		table.insert(teams, team)
		ReplicatedStorage:SetAttribute("Score_" .. cfg.Name, 0)
	end
	ReplicatedStorage:SetAttribute("TeamA", teams[1].Name)
	ReplicatedStorage:SetAttribute("TeamB", teams[2].Name)
end

local function addScore(team, amount)
	if ReplicatedStorage:GetAttribute("State") ~= "Playing" or not team then
		return
	end
	local score = getScore(team.Name) + amount
	ReplicatedStorage:SetAttribute("Score_" .. team.Name, score)
	if score >= (ReplicatedStorage:GetAttribute("ScoreToWin") or math.huge) then
		roundOver = true
	end
end

-- Líder individual (modos sin equipos). Puede ser un bot (tabla de Bots, con Name y Score).
local function updateLeader(leaving)
	local best, bestScore = nil, -1
	for _, player in Players:GetPlayers() do
		local score = player:GetAttribute("Score") or 0
		if player ~= leaving and score > bestScore then
			best, bestScore = player, score
		end
	end
	for _, agent in Bots.Agents do
		if (agent.Score or 0) > bestScore then
			best, bestScore = agent, agent.Score or 0
		end
	end
	ReplicatedStorage:SetAttribute("LeaderName", best and best.Name or "")
	ReplicatedStorage:SetAttribute("LeaderScore", math.max(bestScore, 0))
	return best, bestScore
end

local function addPlayerScore(player, amount)
	local score = (player:GetAttribute("Score") or 0) + amount
	player:SetAttribute("Score", score)
	updateLeader()
	if ReplicatedStorage:GetAttribute("State") == "Playing" and score >= (ReplicatedStorage:GetAttribute("ScoreToWin") or math.huge) then
		roundOver = true
	end
end

---------------------------------------------------------------------------
-- Equipos
---------------------------------------------------------------------------

-- Amigos de Roblox de player que hay en ese equipo
local function friendsIn(team, player)
	local count = 0
	for _, p in team:GetPlayers() do
		if p ~= player and Friends.AreFriends(player, p) then
			count += 1
		end
	end
	return count
end

-- El equipo con menos jugadores (sin contar a exclude). Si empatan, el que tiene amigos suyos
-- (los amigos juegan juntos) y si no, al azar.
local function smallestTeam(exclude)
	local best, bestCount, bestFriends = nil, math.huge, -1
	for _, team in teams do
		local count = 0
		for _, p in team:GetPlayers() do
			if p ~= exclude then
				count += 1
			end
		end
		local friends = exclude and friendsIn(team, exclude) or 0
		if count < bestCount or (count == bestCount and (friends > bestFriends or (friends == bestFriends and math.random() < 0.5))) then
			best, bestCount, bestFriends = team, count, friends
		end
	end
	return best
end

local function assignTeam(player)
	-- Infección: quien entra antes de la infección es superviviente; después, zombi
	local infection = ReplicatedStorage:GetAttribute("Infection")
	if infection then
		player.Neutral = false
		player.Team = infection == "On" and teams[2] or teams[1]
		if infection == "On" then
			player:SetAttribute("InfZombieStart", true)
		end
		return
	end
	if isTeamMode() then
		player.Neutral = false
		player.Team = smallestTeam(player)
	else
		player.Team = nil
		player.Neutral = true
	end
end

local function balanceTeams()
	-- Infección: todos empiezan como supervivientes
	if ReplicatedStorage:GetAttribute("Infection") then
		for _, player in Players:GetPlayers() do
			player.Neutral = false
			player.Team = teams[1]
		end
		return
	end
	if not isTeamMode() then
		for _, player in Players:GetPlayers() do
			player.Team = nil
			player.Neutral = true
		end
		return
	end
	for _, player in Players:GetPlayers() do
		if not player.Team then
			player.Neutral = false
			player.Team = smallestTeam(player)
		end
	end
	local a, b = teams[1], teams[2]
	-- Amigos separados: se intercambian con alguien del otro equipo que no tenga amigos allí (los
	-- tamaños no cambian)
	for _, p in Players:GetPlayers() do
		local mine = p.Team
		local other = mine == a and b or (mine == b and a or nil)
		if other and friendsIn(mine, p) == 0 and friendsIn(other, p) > 0 then
			for _, q in other:GetPlayers() do
				if not Friends.AreFriends(q, p) and friendsIn(other, q) == 0 then
					p.Team, q.Team = other, mine
					break
				end
			end
		end
	end
	while math.abs(#a:GetPlayers() - #b:GetPlayers()) > 1 do
		local big = #a:GetPlayers() > #b:GetPlayers() and a or b
		local small = big == a and b or a
		-- (se cambia preferiblemente a quien tiene menos amigos en su equipo)
		local list = big:GetPlayers()
		local pick, pickFriends = nil, math.huge
		for _, p in list do
			local friends = friendsIn(big, p) - friendsIn(small, p) + math.random() * 0.5
			if friends < pickFriends then
				pick, pickFriends = p, friends
			end
		end
		pick.Team = small
	end
end

local function resetStats()
	for _, player in Players:GetPlayers() do
		local stats = PlayerData.GetLeaderstats(player)
		stats.Bajas.Value = 0
		stats.Muertes.Value = 0
		player:SetAttribute("Streak", 0)
		player:SetAttribute("StreakPlayers", 0)
		streakVictims[player] = nil
		player:SetAttribute("BestStreak", 0)
		Bounty.Reset(player)
		player:SetAttribute("Captures", 0)
		player:SetAttribute("Score", 0)
		player:SetAttribute("GunLevel", 1)
		-- Participación para el rango: desde cuándo juega esta partida (Loadout lo pone al salir del menú)
		player:SetAttribute("MatchJoinedAt", if player:GetAttribute("InMenu") then nil else workspace:GetServerTimeNow())
		player:SetAttribute("ElimPlayed", nil)
		player:SetAttribute("InfZombieStart", nil)
		player:SetAttribute("LastKiller", nil)
		PlayerData.StartMatch(player)
	end
	Killstreaks.Reset()
	Grenades.Reset()
	firstBlood = false
	lastKill = nil
	decidingKill = nil
	for _, team in teams do
		ReplicatedStorage:SetAttribute("Score_" .. team.Name, 0)
	end
	updateLeader()
end

---------------------------------------------------------------------------
-- Escalada de armas
---------------------------------------------------------------------------

local function gunGameWeapons(player)
	local order = Weapons.GunGameOrder
	local level = math.clamp(player:GetAttribute("GunLevel") or 1, 1, #order)
	local weapon = order[level]
	if weapon == Weapons.Melee then
		return { weapon }
	end
	return { weapon, Weapons.Melee }
end

local function gunGameKill(killer, victim, weaponName)
	local order = Weapons.GunGameOrder
	local level = (killer:GetAttribute("GunLevel") or 1) + 1
	killer:SetAttribute("GunLevel", level)
	killer:SetAttribute("Score", level - 1)
	updateLeader()
	if level > #order then
		roundOver = true
		return
	end
	Remotes.Notify:FireClient(killer, "Info", "Nueva arma: " .. Weapons.Get(order[level]).DisplayName)
	Loadout.Give(killer, gunGameWeapons(killer))
	-- Humillación: una baja con cuchillo hace bajar un nivel a la víctima
	if victim and weaponName == Weapons.Melee then
		local vLevel = math.max(1, (victim:GetAttribute("GunLevel") or 1) - 1)
		victim:SetAttribute("GunLevel", vLevel)
		victim:SetAttribute("Score", vLevel - 1)
		Remotes.Notify:FireClient(victim, "Info", "¡Te han bajado de nivel con el cuchillo!")
	end
end

---------------------------------------------------------------------------
-- Bajas
---------------------------------------------------------------------------

-- killerBot / victimBot: el bot (ver Bots) cuando quien hace la baja o quien muere es un bot
-- Medalla de baja: aviso y XP (scale: menos contra bots)
local function medal(player, id, scale)
	local def = GameConfig.Medals and GameConfig.Medals[id]
	if def then
		Remotes.Notify:FireClient(player, "Medal", def.Text)
		PlayerData.AddXP(player, math.max(1, math.floor(def.XP * scale)), def.Name)
	end
end

-- Medallas que gana un jugador con esta baja
local function awardMedals(killer, victimName, victimStreak, weaponName, position, scale)
	local medals = GameConfig.Medals or {}
	if not firstBlood then
		firstBlood = true
		medal(killer, "FirstBlood", scale)
	end
	-- (no en un intercambio: si los dos caen a la vez no es venganza)
	if victimName and killer:GetAttribute("LastKiller") == victimName and os.clock() - (killer:GetAttribute("LastKilledAt") or 0) >= 1 then
		killer:SetAttribute("LastKiller", nil)
		medal(killer, "Revenge", scale)
	end
	if medals.StreakEnder and victimStreak >= medals.StreakEnder.Streak then
		medal(killer, "StreakEnder", scale)
	end
	local character = killer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 then
		medal(killer, "Afterlife", scale)
	elseif root and typeof(position) == "Vector3" and medals.LongShot then
		local weapon = weaponName and Weapons.Get(weaponName)
		if weapon and not weapon.Explosive and weapon.Type ~= "Melee" and (root.Position - position).Magnitude >= medals.LongShot.Distance then
			medal(killer, "LongShot", scale)
		end
	end
end

function Round.RegisterKill(killer, victim, victimName, weaponName, headshot, position, killerBot, victimBot)
	local wasOver = roundOver
	local bounty = 0
	-- (la racha que llevaba el caído, antes de ponerla a 0: para la medalla Cazarrachas)
	local victimStreak = (victim and victim:GetAttribute("Streak")) or (victimBot and victimBot.Streak) or 0
	-- Para la medalla Venganza: quién eliminó a este jugador la última vez
	if victim then
		local by = (killer and killer ~= victim and killer.Name) or (killerBot and killerBot.Name) or nil
		victim:SetAttribute("LastKiller", by)
		victim:SetAttribute("LastKilledAt", os.clock())
	end
	if victim then
		PlayerData.GetLeaderstats(victim).Muertes.Value += 1
		PlayerData.Increment(victim, "TotalDeaths", 1)
		bounty = Bounty.Clear(victim)
		-- (si casi toda la racha fue contra bots, la recompensa vale menos: no se puede inflar
		-- matando bots para que un amigo la cobre)
		if bounty > 0 and (victim:GetAttribute("StreakPlayers") or 0) < 3 then
			bounty = math.max(1, math.floor(bounty * GameConfig.Bots.RewardScale))
		end
		victim:SetAttribute("Streak", 0)
		victim:SetAttribute("StreakPlayers", 0)
		streakVictims[victim] = nil
	end
	local playing = ReplicatedStorage:GetAttribute("State") == "Playing"

	local killerColor, victimColor = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
	if victim and victim.Team then
		victimColor = victim.TeamColor.Color
	elseif victimBot and victimBot.Team then
		victimColor = victimBot.Team.TeamColor.Color
	end

	if victimBot then
		Bots.AddStat(victimBot, "Deaths", 1)
		victimBot.Streak = 0
	end
	-- Racha del bot (sin morir): con 3 bajas su equipo tiene radar (no los zombis)
	if killerBot and killerBot ~= victimBot and playing and not killerBot.Zombie then
		killerBot.Streak = (killerBot.Streak or 0) + 1
		if Killstreaks.OnBotStreak(killerBot.Name, killerBot.Team, killerBot.Streak) then
			Bots.Radar(Bots.RadarKey(killerBot), Killstreaks.RadarTime)
		end
	end
	-- Un bot hace una baja: punto para su equipo (en equipos) o para él (todos contra todos)
	if killerBot then
		Bots.AddStat(killerBot, "Kills", 1)
		if playing then
			firstBlood = true -- (la primera sangre de un bot cuenta: ya no la gana nadie más)
		end
		if killerBot.Team then
			killerColor = killerBot.Team.TeamColor.Color
			if playing and currentMode == "TDM" then
				addScore(killerBot.Team, 1)
			end
		elseif playing and currentMode == "FFA" then
			killerBot.Score = (killerBot.Score or 0) + 1
			Bots.AddStat(killerBot, "Score", 1)
			updateLeader()
			if killerBot.Score >= (ReplicatedStorage:GetAttribute("ScoreToWin") or math.huge) then
				roundOver = true
			end
		end
	end

	if killer and killer ~= victim then
		if killer.Team then
			killerColor = killer.TeamColor.Color
		end
		if victim or victimBot then
			-- Contra bots: misma emoción (marcador, racha, retos, maestría) pero menos XP y monedas,
			-- y no cuentan para la clasificación global
			local botScale = victimBot and GameConfig.Bots.RewardScale or 1
			PlayerData.GetLeaderstats(killer).Bajas.Value += 1
			local streak = (killer:GetAttribute("Streak") or 0) + 1
			killer:SetAttribute("Streak", streak)
			if victim then
				local seen = streakVictims[killer] or {}
				streakVictims[killer] = seen
				if not seen[victim.UserId] then
					seen[victim.UserId] = true
					killer:SetAttribute("StreakPlayers", (killer:GetAttribute("StreakPlayers") or 0) + 1)
				end
			end
			if streak > (killer:GetAttribute("BestStreak") or 0) then
				killer:SetAttribute("BestStreak", streak)
			end

			if playing then
				if currentMode == "TDM" then
					addScore(killer.Team, 1)
				elseif currentMode == "FFA" then
					addPlayerScore(killer, 1)
				elseif currentMode == "GUN" then
					-- (también cuentan las bajas a bots: así se puede jugar solo)
					gunGameKill(killer, victim, weaponName)
				end
			end

			local xp = GameConfig.XP.Kill + GameConfig.XP.StreakBonus * (streak - 1)
			if headshot then
				xp += GameConfig.XP.Headshot
			end
			PlayerData.AddXP(killer, math.floor(xp * botScale), headshot and "Disparo a la cabeza" or "Eliminación")
			if playing then
				awardMedals(killer, victimName, victimStreak, weaponName, position, botScale)
			end
			PlayerData.AddCoins(killer, math.max(1, math.floor(GameConfig.Coins.Kill * botScale)))
			if victim then
				PlayerData.Increment(killer, "TotalKills", 1)
			end
			PlayerData.AddWeaponKill(killer, weaponName)
			PlayerData.Track(killer, "Kill", 1, weaponName)
			PlayerData.Track(killer, "Streak", streak)
			PlayerData.SetBest(killer, "BestStreak", streak)
			if headshot then
				PlayerData.Increment(killer, "Headshots", 1)
				PlayerData.Track(killer, "Headshot", 1, weaponName)
			end

			if STREAK_ANNOUNCE[streak] then
				Remotes.Notify:FireAllClients("Streak", killer.Name .. " tiene una racha de " .. streak .. " bajas")
			end
			Killstreaks.OnStreak(killer, streak)
			-- (el radar de un jugador también lo usan los bots de su equipo)
			if streak == Killstreaks.RadarStreak and killer.Team and isTeamMode()
				and currentMode ~= "GUN" and not (killer.Character and killer.Character:GetAttribute("Zombie")) then
				Bots.Radar(killer.Team.Name, Killstreaks.RadarTime)
			end
			-- (los zombis de la Infección no tienen recompensa por su cabeza)
			if not (ReplicatedStorage:GetAttribute("Infection") == "On" and killer.Team == teams[2]) then
				Bounty.OnStreak(killer, streak)
			end
		end
	end

	-- "SE BUSCA": quien elimina al buscado cobra su recompensa (si lo mata un bot o muere solo, se pierde)
	if bounty > 0 and victim then
		if killer and killer ~= victim then
			local given = PlayerData.AddCoins(killer, bounty, false) -- (premio fijo: no lo multiplican VIP ni amigos)
			PlayerData.AddXP(killer, GameConfig.Bounty.XP or 0, "Recompensa cobrada")
			Remotes.Notify:FireClient(killer, "BountyClaimed", given)
			Bounty.Announce(victim.Name, bounty, killer.Name)
		else
			Bounty.Announce(victim.Name, bounty, nil)
		end
	end

	-- Efecto de eliminación: el que tenga equipado quien ha hecho la baja (o el normal)
	if typeof(position) == "Vector3" then
		local effect = "Default"
		local killerData = killer and killer ~= victim and PlayerData.Get(killer)
		if killerData and killerData.EquippedKillEffect then
			effect = killerData.EquippedKillEffect
		end
		-- Los muñecos (sin jugador ni equipo) estallan en amarillo, como antes
		local burstColor = (victim or (victimBot and victimBot.Team)) and victimColor or Color3.fromRGB(255, 200, 60)
		Remotes.KillFX:FireAllClients(position, effect, burstColor)
	end

	-- La última baja de verdad (de alguien a otro): si cierra la partida o la ronda, se repite para todos
	local killerName = (killer and killer ~= victim and killer.Name) or (killerBot and killerBot.Name) or nil
	if killerName and victimName and killerName ~= victimName then
		lastKill = { Killer = killerName, Victim = victimName, Weapon = weaponName, Time = os.clock() }
		-- (si esta baja cierra la partida, se guarda tal cual y se congela todo ya: ninguna baja de
		-- después, hasta que la ronda se dé cuenta, la sustituye en la repetición)
		if roundOver and not wasOver and not decidingKill and GameConfig.FinalKillcam ~= false then
			decidingKill = lastKill
			ReplicatedStorage:SetAttribute("Frozen", true)
		end
	end
	local weapon = weaponName and Weapons.Get(weaponName)
	Remotes.KillFeed:FireAllClients({
		Killer = (killer and killer.Name) or (killerBot and killerBot.Name) or nil,
		KillerColor = killerColor,
		Victim = victimName,
		VictimColor = victimColor,
		Weapon = weapon and weapon.DisplayName or "",
		WeaponId = weapon and weaponName or nil, -- (el cliente dibuja la silueta del arma)
		Headshot = headshot,
	})
	-- Botín: a veces el caído suelta un paquete para quien le eliminó (no en Calabazas: ya sueltan algo)
	-- (solo bajas a jugadores o bots de verdad: los muñecos de práctica no cuentan)
	if playing and currentMode ~= "CAL" and killer and killer ~= victim and (victim or victimBot) and typeof(position) == "Vector3" then
		Loot.MaybeDrop(position, killer, victimBot ~= nil)
	end
	-- Calabazas: el caído suelta una calabaza con el color de su equipo
	-- (solo si alguien le eliminó: caerse o la lava no regala puntos al rival)
	if playing and currentMode == "CAL" and typeof(position) == "Vector3" and ((killer and killer ~= victim) or killerBot) then
		local team = (victim and victim.Team) or (victimBot and victimBot.Team)
		Pumpkins.Drop(position, team, victim and victim.UserId or nil, victimBot ~= nil)
	end
	-- Infección: el superviviente que cae se convierte en zombi en el acto (antes de que pueda revivir)
	if ReplicatedStorage:GetAttribute("Infection") == "On" and onInfectionDeath then
		onInfectionDeath(victim, victimBot)
	end
end

-- Asistencias (ver Combat): XP y monedas a quien ayudó a eliminar (menos si la víctima era un bot)
function Round.RegisterAssist(helpers, victimName, victimBot, victimPlayer)
	if not victimBot and not victimPlayer then
		return -- (los muñecos de práctica no dan asistencias)
	end
	local scale = victimBot and GameConfig.Bots.RewardScale or 1
	for _, helper in helpers do
		PlayerData.AddXP(helper, math.floor((GameConfig.XP.Assist or 0) * scale), "Asistencia")
		PlayerData.AddCoins(helper, math.max(1, math.floor((GameConfig.Coins.Assist or 0) * scale)))
		PlayerData.Increment(helper, "Assists", 1)
		Remotes.Notify:FireClient(helper, "Assist", tostring(victimName or ""))
	end
end

---------------------------------------------------------------------------
-- Aparición libre (FFA / Escalada): el punto más alejado de los demás
---------------------------------------------------------------------------

local ffaCache = { Map = nil, Points = {} }
local spawnedThisRound = {} -- [player] = true: ya apareció en esta ronda (la siguiente vez, dinámica)

local function ffaSpawnFor(player, character)
	if isTeamMode() then
		-- Por equipos: la primera vez en la base; al reaparecer, en el punto más seguro (SpawnPicker)
		local first = not spawnedThisRound[player]
		if ReplicatedStorage:GetAttribute("State") == "Playing" then
			spawnedThisRound[player] = true
		end
		if first or not SpawnPicker.Enabled() then
			return
		end
		local point = SpawnPicker.Pick(player.Team, character)
		local root = point and character:WaitForChild("HumanoidRootPart", 5)
		if root then
			task.wait()
			character:PivotTo(CFrame.new(point + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
		end
		return
	end
	local map = workspace:FindFirstChild("Map")
	if not map then
		return
	end
	-- Puntos libres del mapa (se guardan mientras no cambie el mapa)
	if ffaCache.Map ~= map then
		ffaCache.Map, ffaCache.Points = map, {}
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "FFASpawn" then
				table.insert(ffaCache.Points, d)
			end
		end
	end
	local points = ffaCache.Points
	if #points == 0 then
		return
	end
	-- Lejos de los demás jugadores y de los bots
	local others = {}
	for _, p in Players:GetPlayers() do
		local root = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root then
			table.insert(others, root.Position)
		end
	end
	for _, agent in Bots.Agents do
		if agent.Root and agent.Root.Parent then
			table.insert(others, agent.Root.Position)
		end
	end
	local best, bestDistance = points[math.random(1, #points)], -1
	for _, point in points do
		local nearest = math.huge
		for _, pos in others do
			nearest = math.min(nearest, (pos - point.Position).Magnitude)
		end
		nearest += math.random() * 10 -- un poco de azar entre puntos parecidos
		if nearest > bestDistance then
			best, bestDistance = point, nearest
		end
	end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root then
		task.wait()
		character:PivotTo(CFrame.new(best.Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	end
end

---------------------------------------------------------------------------
-- Votación de mapa + modo
---------------------------------------------------------------------------

local function availableModes(mapId)
	local list = {}
	local def = MapBuilder.Get(mapId)
	for _, mode in GameConfig.Modes do
		-- (Buscar y destruir, solo en los mapas con sitios para la bomba)
		if GameConfig.ModeSettings[mode] and (mode ~= "SND" or (def and def.Bomb)) then
			table.insert(list, mode)
		end
	end
	if #list == 0 then
		table.insert(list, GameConfig.Modes[1] or "TDM")
	end
	return list
end

local function makeVoteOptions()
	local maps = {}
	for _, id in MapBuilder.Order do
		if MapBuilder.InSeason(id) then -- (los mapas de temporada, solo en su evento)
			table.insert(maps, id)
		end
	end
	if MapBuilder.IsCustom() then
		maps = { "Custom" }
	end
	-- Prioriza mapas distintos al actual
	for i = #maps, 2, -1 do
		local j = math.random(1, i)
		maps[i], maps[j] = maps[j], maps[i]
	end
	table.sort(maps, function(a, b)
		return (a ~= MapBuilder.Current and 0 or 1) < (b ~= MapBuilder.Current and 0 or 1)
	end)
	-- Siempre hay un mapa de 5 contra 5 estilo shooter militar (Encrucijada, Base Militar...) en la
	-- votación, con Duelo por equipos o Dominio (GameConfig.VoteRealisticMap)
	local realisticFirst = false
	if GameConfig.VoteRealisticMap ~= false then
		for i, id in maps do
			local def = MapBuilder.Get(id)
			if def and def.Realistic then
				table.insert(maps, 1, table.remove(maps, i))
				realisticFirst = true
				break
			end
		end
	end
	local options = {}
	local usedModes = {}
	for i = 1, 3 do
		local mapId = maps[((i - 1) % #maps) + 1]
		local modes = availableModes(mapId)
		if i == 1 and realisticFirst then
			local classic = {}
			for _, mode in modes do
				if mode == "TDM" or mode == "DOM" or mode == "SND" then
					table.insert(classic, mode)
				end
			end
			if #classic > 0 then
				modes = classic
			end
		end
		local mode = modes[math.random(1, #modes)]
		for _ = 1, 6 do
			if not usedModes[mode] then
				break
			end
			mode = modes[math.random(1, #modes)]
		end
		usedModes[mode] = true
		table.insert(options, { Map = mapId, Mode = mode })
	end
	return options
end

local function publishVotes()
	local counts = { 0, 0, 0 }
	for _, choice in votes do
		counts[choice] = (counts[choice] or 0) + 1
	end
	for i, option in voteOptions do
		local def = MapBuilder.Get(option.Map)
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Map", def and ((def.Icon and def.Icon .. " " or "") .. def.Name) or "Mapa propio")
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Mode", modeName(option.Mode))
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Count", counts[i])
	end
	return counts
end

local function clearVotes()
	for i = 1, 3 do
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Map", nil)
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Mode", nil)
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Count", nil)
	end
end

---------------------------------------------------------------------------
-- Ciclo de rondas
---------------------------------------------------------------------------

local function countdown(seconds, stopWhen)
	for t = seconds, 0, -1 do
		ReplicatedStorage:SetAttribute("TimeLeft", t)
		if stopWhen and stopWhen() then
			return
		end
		task.wait(1)
	end
end

local function respawnAll()
	for _, player in Players:GetPlayers() do
		task.spawn(Respawn.Load, player) -- con la protección contra cargas dobles
	end
end

local function isDeadPlayer(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return not humanoid or humanoid.Health <= 0
end

---------------------------------------------------------------------------
-- Infección (INF): supervivientes (equipo A) contra zombis (equipo B)
---------------------------------------------------------------------------

-- Los zombis solo llevan garras; los supervivientes, sus armas de siempre
local function infectionLoadout(player)
	if ReplicatedStorage:GetAttribute("Infection") == "On" and player.Team == teams[2] then
		return { "Claws" }
	end
	return nil
end

-- Aspecto de zombi al aparecer (después de cargar la ropa del avatar, que si no lo taparía)
local function zombify(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or player.Character ~= character then
		return
	end
	Zombie.Apply(character, settings("INF").ZombieHealth)
	local started = os.clock()
	while not player:HasAppearanceLoaded() and os.clock() - started < 5 do
		task.wait(0.2)
	end
	if player.Character == character then
		Zombie.Apply(character, nil)
	end
end

-- Convierte en zombi a un jugador. Si sigue vivo (paciente cero) reaparece ya como zombi.
local function infectPlayer(player, announce)
	if player.Team == teams[2] then
		return
	end
	player.Neutral = false
	player.Team = teams[2]
	player:SetAttribute("Airstrikes", 0) -- (los zombis no tienen recompensas por racha)
	player:SetAttribute("Streak", 0)
	player:SetAttribute("StreakPlayers", 0)
	streakVictims[player] = nil
	player:SetAttribute("RadarUntil", 0)
	Bounty.Reset(player)
	if announce then
		Remotes.Notify:FireAllClients("Streak", "🧟 " .. player.Name .. " se ha convertido en zombi")
	end
	if not isDeadPlayer(player) and not player:GetAttribute("InMenu") then
		task.spawn(Respawn.Load, player)
	end
end

local function infectionCounts()
	local survivors, zombies = 0, 0
	for _, player in Players:GetPlayers() do
		if not player:GetAttribute("InMenu") then
			if player.Team == teams[1] then
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if Respawn.IsLoading(player) or (humanoid and humanoid.Health > 0) then
					survivors += 1
				end
			elseif player.Team == teams[2] then
				zombies += 1
			end
		end
	end
	for _, agent in Bots.Agents do
		if agent.Team == teams[1] then
			if agent.Spawning or (agent.Humanoid and agent.Humanoid.Health > 0) then
				survivors += 1
			end
		elseif agent.Team == teams[2] then
			zombies += 1
		end
	end
	return survivors, zombies
end

-- Elige pacientes cero al azar entre los supervivientes (jugadores fuera del menú y bots)
local function infectRandom(count)
	local pool = {}
	for _, player in Players:GetPlayers() do
		if player.Team == teams[1] and not player:GetAttribute("InMenu") then
			table.insert(pool, player)
		end
	end
	for _, agent in Bots.Agents do
		if agent.Team == teams[1] and agent.Humanoid then
			table.insert(pool, agent)
		end
	end
	local infected = 0
	for _ = 1, math.min(count, #pool - 1) do
		local chosen = table.remove(pool, math.random(1, #pool))
		infected += 1
		if typeof(chosen) == "Instance" then
			chosen:SetAttribute("InfZombieStart", true)
			infectPlayer(chosen, true)
		else
			Bots.Infect(chosen, teams[2])
			Remotes.Notify:FireAllClients("Streak", "🧟 " .. chosen.Name .. " se ha convertido en zombi")
		end
	end
	return infected
end

onInfectionDeath = function(victim, victimBot)
	if victim and victim.Team == teams[1] then
		infectPlayer(victim, true)
	elseif victimBot and victimBot.Team == teams[1] then
		Bots.Infect(victimBot, teams[2])
		Remotes.Notify:FireAllClients("Streak", "🧟 " .. victimBot.Name .. " se ha convertido en zombi")
	end
end

local function infectionRound(s)
	local a, b = teams[1], teams[2]
	-- Preparación: todos son supervivientes y se reparten por el mapa
	for t = s.PrepTime, 1, -1 do
		ReplicatedStorage:SetAttribute("TimeLeft", t)
		if t == s.PrepTime or t <= 3 then
			Remotes.Notify:FireAllClients("Big", "🧟 La infección empieza en " .. t .. "…")
		end
		local survivors = infectionCounts()
		ReplicatedStorage:SetAttribute("AliveA", survivors)
		ReplicatedStorage:SetAttribute("AliveB", 0)
		task.wait(1)
	end
	ReplicatedStorage:SetAttribute("Infection", "On")
	-- Quien sigue en la pantalla de inicio no es superviviente: si entra, lo hará como zombi
	for _, player in Players:GetPlayers() do
		if player.Team == a and player:GetAttribute("InMenu") then
			player.Team = b
			player:SetAttribute("InfZombieStart", true)
		end
	end
	local survivors = infectionCounts()
	if infectRandom(math.max(1, math.floor(survivors / (s.ZombieRatio or 5)))) == 0 then
		Remotes.Notify:FireAllClients("Big", "Hacen falta al menos 2 jugadores para la infección")
		task.wait(2)
		return
	end
	Remotes.Notify:FireAllClients("Big", "🧟 ¡HAN LLEGADO LOS ZOMBIS! ¡Sobrevive!")
	local roundEnd = os.clock() + s.RoundTime
	local winner
	local lastAnnounced = false
	while not roundOver do
		-- Los supervivientes que caen (por lo que sea) se convierten en zombis; quien vuelve al menú
		-- deja de ser superviviente
		for _, player in Players:GetPlayers() do
			if player.Team == a then
				if player:GetAttribute("InMenu") then
					infectPlayer(player, false)
				elseif not Respawn.IsLoading(player) and isDeadPlayer(player) then
					infectPlayer(player, true)
				end
			end
		end
		for _, agent in table.clone(Bots.Agents) do
			if agent.Team == a and not agent.Humanoid and not agent.Spawning then
				Bots.Infect(agent, b)
			end
		end
		local alive, zombies = infectionCounts()
		-- ¡Último superviviente! Se anuncia y recibe más vida para el final
		if alive == 1 and not lastAnnounced then
			lastAnnounced = true
			for _, player in Players:GetPlayers() do
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if player.Team == a and not player:GetAttribute("InMenu") and humanoid and humanoid.Health > 0 then
					humanoid.MaxHealth = 150
					humanoid.Health = 150
					Remotes.Notify:FireAllClients("Big", "🧑 ¡" .. string.upper(player.Name) .. " ES EL ÚLTIMO SUPERVIVIENTE!")
				end
			end
			for _, agent in Bots.Agents do
				if agent.Team == a and agent.Humanoid and agent.Humanoid.Health > 0 then
					agent.Humanoid.MaxHealth = 150
					agent.Humanoid.Health = 150
					Remotes.Notify:FireAllClients("Big", "🧑 ¡" .. string.upper(agent.Name) .. " ES EL ÚLTIMO SUPERVIVIENTE!")
				end
			end
		end
		ReplicatedStorage:SetAttribute("AliveA", alive)
		ReplicatedStorage:SetAttribute("AliveB", zombies)
		ReplicatedStorage:SetAttribute("TimeLeft", math.max(0, math.ceil(roundEnd - os.clock())))
		if alive == 0 then
			winner = b
			break
		elseif zombies == 0 and alive >= 2 then
			-- Se fueron todos los zombis: nuevo paciente cero
			infectRandom(1)
		end
		if os.clock() >= roundEnd then
			winner = a
			break
		end
		task.wait(0.25)
	end
	if winner then
		addScore(winner, 1)
		Remotes.Notify:FireAllClients("Big", winner == a and "🧑 ¡GANAN LOS SUPERVIVIENTES!" or "🧟 ¡GANAN LOS ZOMBIS!")
		task.wait(2)
	end
end

-- Limpia el estado de Infección (al acabar o si la ronda falla)
local function clearInfection()
	ReplicatedStorage:SetAttribute("Infection", nil)
	ReplicatedStorage:SetAttribute("AliveA", nil)
	ReplicatedStorage:SetAttribute("AliveB", nil)
end

---------------------------------------------------------------------------
-- Eliminación (ELIM)
---------------------------------------------------------------------------

-- Vivos y participantes de un equipo (jugadores fuera del menú + bots)
-- Vivos y participantes de un equipo. Solo cuentan los jugadores que empezaron la ronda (atributo
-- ElimIn) y los bots; un bot que aún se está creando cuenta como vivo.
local function aliveCount(team)
	local alive, members = 0, 0
	for _, player in team:GetPlayers() do
		if player:GetAttribute("ElimIn") then
			members += 1
			-- Quien vuelve al menú no cuenta como vivo (si no, su equipo no se podría eliminar);
			-- quien está reapareciendo justo al empezar, sí
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not player:GetAttribute("InMenu") and (Respawn.IsLoading(player) or (humanoid and humanoid.Health > 0)) then
				alive += 1
			end
		end
	end
	for _, agent in Bots.Agents do
		if agent.Team == team then
			members += 1
			if agent.Spawning or (agent.Humanoid and agent.Humanoid.Health > 0) then
				alive += 1
			end
		end
	end
	return alive, members
end

-- Limpia el estado de Eliminación (al acabar o si la ronda falla)
local function clearElimination()
	Bomb.Stop()
	ReplicatedStorage:SetAttribute("NoRespawn", false)
	ReplicatedStorage:SetAttribute("Frozen", false)
	ReplicatedStorage:SetAttribute("AliveA", nil)
	ReplicatedStorage:SetAttribute("AliveB", nil)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("ElimIn", nil)
	end
end

-- Killcam final (como en los shooters): si la partida o la ronda la acaba de cerrar una baja, todos
-- ven la repetición desde los ojos de quien la hizo. Mientras, todo queda congelado (nadie dispara
-- ni se mueven los bots). Devuelve true si la hubo.
local function playFinalKillcam()
	-- La que cerró la partida; si no la hubo (p. ej. la ronda la decidió quién quedaba vivo), la última
	-- baja solo si fue justo antes (si se acabó el tiempo o por puntos de zona, no hay repetición)
	local kill = decidingKill
	if not kill and lastKill and os.clock() - lastKill.Time <= 1.2 then
		kill = lastKill
	end
	decidingKill = nil
	lastKill = nil
	if GameConfig.FinalKillcam == false or not kill or os.clock() - kill.Time > 4 then
		if kill then
			ReplicatedStorage:SetAttribute("Frozen", false)
		end
		return false
	end
	ReplicatedStorage:SetAttribute("Frozen", true)
	Remotes.FinalKillcam:FireAllClients({ Killer = kill.Killer, Victim = kill.Victim, Weapon = kill.Weapon })
	task.wait(GameConfig.FinalKillcamTime or 3.4)
	ReplicatedStorage:SetAttribute("Frozen", false)
	return true
end
Round.PlayFinalKillcam = playFinalKillcam -- (para las pruebas)

-- Rondas de una vida hasta que un equipo llegue a ScoreToWin rondas ganadas (o se acabe el tiempo total)
local MIN_SUBROUND = 20 -- no se empieza una ronda si quedan menos segundos que esto (más la preparación)
-- Buscar y destruir (SND) usa las mismas rondas con la bomba: atacan y defienden por turnos
local function eliminationRounds(s)
	local deadline = os.clock() + s.RoundTime
	local number = 0
	local a, b = teams[1], teams[2]
	local snd = currentMode == "SND"
	while not roundOver and deadline - os.clock() >= s.PrepTime + MIN_SUBROUND do
		number += 1
		local attackers = number % 2 == 1 and a or b
		local defenders = attackers == a and b or a
		-- Preparación: todos vuelven a su base con la vida llena y quietos (no se puede disparar)
		ReplicatedStorage:SetAttribute("Frozen", true)
		ReplicatedStorage:SetAttribute("NoRespawn", false)
		for _, player in Players:GetPlayers() do
			player:SetAttribute("ElimIn", nil)
		end
		-- (sin contador de vivos durante la preparación)
		ReplicatedStorage:SetAttribute("AliveA", nil)
		ReplicatedStorage:SetAttribute("AliveB", nil)
		respawnAll()
		Bots.RespawnAll()
		Remotes.Notify:FireAllClients("Big", "RONDA " .. number .. " · ¡Una sola vida!")
		countdown(s.PrepTime)
		-- Que nadie empiece muerto (p. ej. un bot que aún se estaba creando o alguien que cayó en la preparación)
		local waitUntil = os.clock() + 5
		while os.clock() < waitUntil do
			local spawning = false
			for _, agent in Bots.Agents do
				spawning = spawning or agent.Spawning == true
			end
			if not spawning then
				break
			end
			task.wait(0.2)
		end
		for _, player in Players:GetPlayers() do
			if not player:GetAttribute("InMenu") then
				if isDeadPlayer(player) then
					task.spawn(Respawn.Load, player)
				end
				player:SetAttribute("ElimIn", true) -- participa en esta ronda
				player:SetAttribute("ElimPlayed", true)
			end
		end
		Bots.RespawnDead()
		ReplicatedStorage:SetAttribute("NoRespawn", true)
		ReplicatedStorage:SetAttribute("Frozen", false)
		if snd and Bomb.Start(attackers, defenders) then
			-- Cada equipo sabe qué le toca
			for _, player in Players:GetPlayers() do
				if player.Team == attackers then
					Remotes.Notify:FireClient(player, "Big", "💣 ATACAS: planta la bomba en A o B")
				elseif player.Team == defenders then
					Remotes.Notify:FireClient(player, "Big", "🛡️ DEFIENDES: protege A y B")
				end
			end
		else
			snd = false -- (sin sitios en el mapa: como Eliminación)
			Remotes.Notify:FireAllClients("Big", "¡YA!")
		end
		task.wait(0.5)

		local roundEnd = math.min(os.clock() + s.SubRoundTime, deadline)
		local winner, decided = nil, false
		while not roundOver do
			local aliveA, membersA = aliveCount(a)
			local aliveB, membersB = aliveCount(b)
			ReplicatedStorage:SetAttribute("AliveA", aliveA)
			ReplicatedStorage:SetAttribute("AliveB", aliveB)
			ReplicatedStorage:SetAttribute("TimeLeft", math.max(0, math.ceil(roundEnd - os.clock())))
			local contest = membersA > 0 and membersB > 0
			if snd then
				-- Bomba: explota = atacantes; desactivada = defensores. Sin bomba plantada, si caen todos
				-- los atacantes o se acaba el tiempo, ganan los defensores; si caen todos los defensores,
				-- los atacantes. Con la bomba plantada, los defensores tienen que desactivarla.
				local aliveAtt = attackers == a and aliveA or aliveB
				local aliveDef = attackers == a and aliveB or aliveA
				if Bomb.Planted then
					ReplicatedStorage:SetAttribute("TimeLeft", ReplicatedStorage:GetAttribute("Bomb_Timer") or 0)
				end
				local result = nil
				if Bomb.Result == "Exploded" then
					result = attackers
				elseif Bomb.Result == "Defused" then
					result = defenders
				elseif contest and aliveDef == 0 then
					result = attackers
				elseif contest and aliveAtt == 0 and not Bomb.Planted then
					result = defenders
				elseif not Bomb.Planted and os.clock() >= roundEnd then
					result = defenders
				elseif Bomb.Planted and os.clock() >= roundEnd + (s.BombTime or 35) + 5 then
					result = defenders -- (por si la bomba dejara de contar: la ronda nunca se queda colgada)
				end
				if result or (not contest and os.clock() >= roundEnd) then
					winner = contest and result or nil
					decided = true
					break
				end
				task.wait(0.25)
				continue
			end
			-- Solo hay ronda si los dos equipos tienen a alguien
			if contest and (aliveA == 0 or aliveB == 0) then
				winner = (aliveA > 0 and a) or (aliveB > 0 and b) or nil
				decided = true
				break
			end
			if os.clock() >= roundEnd then
				-- Se acaba el tiempo: gana el equipo con más supervivientes (sin rival no gana nadie)
				winner = contest and ((aliveA > aliveB and a) or (aliveB > aliveA and b)) or nil
				decided = true
				break
			end
			task.wait(0.25)
		end
		Bomb.Stop()
		if decided then
			if winner then
				addScore(winner, 1)
				Remotes.Notify:FireAllClients("Big", "¡RONDA PARA " .. string.upper(winner.Name) .. "!")
			else
				Remotes.Notify:FireAllClients("Big", "RONDA EMPATADA")
			end
			-- (si la ronda la cerró una baja: su repetición, como en Buscar y destruir)
			if not playFinalKillcam() then
				task.wait(3)
			end
		end
	end
	clearElimination()
	-- Nadie se queda muerto durante la pantalla final
	respawnAll()
end

-- Los 3 mejores de la partida (jugadores y bots, por bajas y luego menos muertes), para el podio
-- de la pantalla final. Hay que calcularlo antes de cambiar de estado: al cambiar, los bots se quitan
local function topPlayers()
	local list = {}
	for _, player in Players:GetPlayers() do
		local stats = PlayerData.GetLeaderstats(player)
		local kills, deaths = stats.Bajas.Value, stats.Muertes.Value
		if not player:GetAttribute("InMenu") or kills + deaths > 0 then
			table.insert(list, { Name = tostring(player.DisplayName), Kills = kills, Deaths = deaths, Team = player.Team and player.Team.Name or nil })
		end
	end
	local botStats = ReplicatedStorage:FindFirstChild("BotStats")
	if botStats then
		for _, entry in botStats:GetChildren() do
			table.insert(list, {
				Name = entry.Name,
				Kills = entry:GetAttribute("Kills") or 0,
				Deaths = entry:GetAttribute("Deaths") or 0,
				Team = entry:GetAttribute("Team"),
				Bot = true,
			})
		end
	end
	table.sort(list, function(x, y)
		if x.Kills ~= y.Kills then
			return x.Kills > y.Kills
		end
		if x.Deaths ~= y.Deaths then
			return x.Deaths < y.Deaths
		end
		return x.Name < y.Name
	end)
	local top = {}
	for i = 1, math.min(3, #list) do
		top[i] = list[i]
	end
	return top
end

local function endRound()
	-- Antes de nada (al cambiar de estado se quitan los bots): la repetición de la baja final
	playFinalKillcam()
	-- El líder se calcula antes de cambiar de estado (al cambiar, los bots se quitan)
	local leader, leaderScore = updateLeader()
	-- (el podio es un extra: si fallara, la partida termina igual)
	local okTop, top = pcall(topPlayers)
	if not okTop then
		warn("[Round] podio:", top)
		top = nil
	end
	setState("Ended")
	local teamMode = isTeamMode()
	local a, b = teams[1], teams[2]
	local scoreA, scoreB = getScore(a.Name), getScore(b.Name)
	local winner = nil
	if teamMode then
		if scoreA > scoreB then
			winner = a
		elseif scoreB > scoreA then
			winner = b
		end
	end

	-- MVP = más bajas (en CTF cada captura cuenta como 3 bajas)
	local mvp, mvpKills, mvpScore = nil, 0, -1
	for _, player in Players:GetPlayers() do
		local kills = PlayerData.GetLeaderstats(player).Bajas.Value
		local score = kills + (player:GetAttribute("Captures") or 0) * 3
		if score > mvpScore then
			mvp, mvpKills, mvpScore = player, kills, score
		end
	end

	-- Contra bots (menos de 2 jugadores de verdad) la victoria da menos premio y no cuenta para
	-- la clasificación global de victorias
	local humans = 0
	for _, player in Players:GetPlayers() do
		local stats = PlayerData.GetLeaderstats(player)
		-- Ha jugado: está fuera del menú o tiene alguna baja o muerte en esta partida
		if not player:GetAttribute("InMenu") or stats.Bajas.Value + stats.Muertes.Value > 0 then
			humans += 1
		end
	end
	local soloMatch = humans < 2
	-- Por equipos, si todos los jugadores de verdad están en el mismo equipo, es contra bots
	-- (para el rango: dos amigos juntos contra bots no suben como en una partida de verdad)
	local botsOnly = soloMatch
	-- (en Infección los equipos cambian durante la ronda: basta con que jueguen dos personas)
	if teamMode and not soloMatch and currentMode ~= "INF" then
		local humansA, humansB = 0, 0
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("MatchJoinedAt") then
				if player.Team == a then
					humansA += 1
				elseif player.Team == b then
					humansB += 1
				end
			end
		end
		botsOnly = humansA == 0 or humansB == 0
	end
	-- Rango: solo para quien ha jugado de verdad (lleva un rato en la partida, ha tenido bajas o
	-- muertes, o ha jugado alguna ronda de Eliminación). También si ha vuelto al menú (no se esquiva
	-- la derrota así). Empate (por equipos, o nadie puntúa en todos contra todos) = sin cambios.
	local now = workspace:GetServerTimeNow()
	local elim = currentMode == "ELIM" or currentMode == "SND"
	local playedMatch = {} -- [player] = true si ha jugado de verdad (para la primera victoria del día y la caja sorpresa)
	for _, player in Players:GetPlayers() do
		local joined = player:GetAttribute("MatchJoinedAt")
		local stats = PlayerData.GetLeaderstats(player)
		local active = stats.Bajas.Value + stats.Muertes.Value > 0
		local played = joined ~= nil
			and (active or (if elim then player:GetAttribute("ElimPlayed") == true else now - joined >= 60))
		if played then
			playedMatch[player] = true
			PlayerData.Increment(player, "Matches", 1)
			local won
			if teamMode then
				won = wonTeam(player, winner)
			else
				won = leader == player and leaderScore > 0
			end
			local draw = (teamMode and winner == nil) or (not teamMode and leaderScore <= 0)
			local result = won and "Win" or (draw and "Draw" or "Loss")
			PlayerData.AddRankPoints(player, Ranks.Delta(result, not teamMode, botsOnly, mvp == player and mvpScore > 0))
		end
	end
	local winScale = soloMatch and GameConfig.Bots.RewardScale or 1

	-- Premios solo para quien ha jugado (no para quien sigue en la pantalla de inicio)
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InMenu") then
			continue
		end
		local won
		if teamMode then
			won = wonTeam(player, winner)
		else
			won = leader == player and leaderScore > 0
		end
		if won then
			PlayerData.AddXP(player, math.floor(GameConfig.XP.Win * winScale), "Victoria")
			PlayerData.AddCoins(player, math.floor(GameConfig.Coins.Win * winScale))
			-- Racha de victorias (en esta sesión): cada victoria seguida da un poco más
			local winStreak = (player:GetAttribute("WinStreak") or 0) + 1
			player:SetAttribute("WinStreak", winStreak)
			local extra = math.floor((GameConfig.Coins.WinStreak or 0) * math.min(winStreak - 1, GameConfig.Coins.WinStreakMax or 5) * winScale)
			if extra > 0 then
				local given = PlayerData.AddCoins(player, extra)
				Remotes.Notify:FireClient(player, "Challenge", "🔥 ¡" .. winStreak .. " victorias seguidas!  +" .. given .. " 🪙")
			end
			if not soloMatch then
				PlayerData.Increment(player, "Wins", 1)
			end
			if playedMatch[player] then
				-- (completa también contra bots: es una vez al día, no se puede abusar)
				local firstWin = PlayerData.ClaimFirstWin(player, 1)
				if firstWin then
					Remotes.Notify:FireClient(player, "Challenge", "🏆 ¡Primera victoria del día!  +" .. firstWin .. " 🪙")
				end
			end
			PlayerData.Track(player, "Win", 1)
			-- (reto semanal: ganar en el mapa destacado del día)
			local featured = ReplicatedStorage:GetAttribute("FeaturedMap")
			if featured and featured == ReplicatedStorage:GetAttribute("MapName") then
				PlayerData.Track(player, "FeaturedWin", 1)
			end
			if currentMode == "INF" and winner == teams[1] then
				PlayerData.Track(player, "Survive", 1)
			end
		else
			player:SetAttribute("WinStreak", 0)
			PlayerData.AddXP(player, GameConfig.XP.Loss, "Partida completada")
		end
		PlayerData.Track(player, "Match", 1)
		if playedMatch[player] and PlayerData.RollSurpriseCrate(player) then
			task.delay(2.5, function()
				if player.Parent then
					Remotes.Notify:FireClient(player, "Big", "🎁 ¡CAJA SORPRESA! Tienes una caja gratis en la Tienda")
				end
			end)
		end
	end

	Remotes.RoundEnd:FireAllClients({
		TeamMode = teamMode,
		Winner = if teamMode then (winner and winner.Name) else (leader and leader.Name),
		WinnerColor = winner and winner.TeamColor.Color or Color3.fromRGB(255, 200, 60),
		ScoreA = scoreA,
		ScoreB = scoreB,
		LeaderScore = leaderScore,
		MVP = mvp and mvp.Name or nil,
		MVPKills = mvpKills,
		MVPCaptures = mvp and mvp:GetAttribute("Captures") or 0,
		Top = top,
	})
	-- Resumen personal: lo ganado en esta partida (el cliente lo anima: barra de nivel, monedas...)
	for _, player in Players:GetPlayers() do
		local summary = not player:GetAttribute("InMenu") and PlayerData.MatchSummary(player)
		if summary then
			local stats = PlayerData.GetLeaderstats(player)
			summary.Kills = stats.Bajas.Value
			summary.Deaths = stats.Muertes.Value
			summary.BestStreak = player:GetAttribute("BestStreak") or 0
			summary.Captures = player:GetAttribute("Captures") or 0
			summary.WinStreak = player:GetAttribute("WinStreak") or 0
			-- ¿Récord personal de bajas en una partida? (desde 5, para que no salte en las primeras)
			local data = PlayerData.Get(player)
			local record = data and data.BestMatchKills or 0
			if data and summary.Kills >= 5 and summary.Kills > record then
				summary.NewRecord = summary.Kills
				summary.PrevRecord = record
			end
			PlayerData.SetBest(player, "BestMatchKills", summary.Kills)
			Remotes.MatchSummary:FireClient(player, summary)
		end
	end
	task.wait(GameConfig.EndScreenTime)
end

local function startMode(mode)
	currentMode = mode
	local s = settings(mode)
	local scoreToWin = s.ScoreToWin
	if mode == "GUN" then
		scoreToWin = #Weapons.GunGameOrder
	end
	ReplicatedStorage:SetAttribute("Mode", mode)
	ReplicatedStorage:SetAttribute("ModeName", modeName(mode))
	ReplicatedStorage:SetAttribute("TeamMode", s.Teams ~= false)
	ReplicatedStorage:SetAttribute("ScoreToWin", scoreToWin)
	-- (antes de empezar: así los bots que entran al empezar ya son supervivientes)
	ReplicatedStorage:SetAttribute("Infection", if mode == "INF" then "Prep" else nil)
	if mode == "GUN" then
		Loadout.Override = gunGameWeapons
	elseif mode == "INF" then
		Loadout.Override = infectionLoadout
	else
		Loadout.Override = nil
	end
end

-- Una ronda completa: descanso con votación, partida y pantalla final
local function playRound()
	do
		-- Descanso con votación
		setState("Intermission")
		table.clear(votes)
		voteOptions = makeVoteOptions()
		publishVotes()
		countdown(GameConfig.IntermissionTime)
		while #Players:GetPlayers() < GameConfig.MinPlayers do
			ReplicatedStorage:SetAttribute("TimeLeft", 0)
			task.wait(1)
		end

		-- Resultado de la votación (empate = al azar entre los empatados)
		local counts = publishVotes()
		local bestCount = -1
		local ties = {}
		for i = 1, #voteOptions do
			local c = counts[i] or 0
			if c > bestCount then
				bestCount = c
				ties = { i }
			elseif c == bestCount then
				table.insert(ties, i)
			end
		end
		local choice = voteOptions[ties[math.random(1, #ties)]]
		clearVotes()

		local mode = choice.Mode
		-- Comprueba que el mapa soporta el modo
		if choice.Map ~= "Custom" and choice.Map ~= MapBuilder.Current then
			-- Pantalla de carga en los clientes (ver LoadingScreen): se tapa la construcción del mapa
			ReplicatedStorage:SetAttribute("LoadingMap", MapBuilder.Get(choice.Map).Name)
			task.wait(0.6)
			Flags.Stop()
			Hardpoint.Stop()
			Domination.Stop()
			local built, buildError = pcall(MapBuilder.Build, choice.Map)
			task.wait(0.3)
			ReplicatedStorage:SetAttribute("LoadingMap", nil)
			if not built then
				error(buildError, 0)
			end
		end
		if mode == "CTF" and not Flags.IsAvailable() then
			mode = "TDM"
		elseif mode == "KOTH" and not Hardpoint.IsAvailable() then
			mode = "TDM"
		elseif mode == "DOM" and not Domination.IsAvailable() then
			mode = "TDM"
		elseif mode == "SND" and not Bomb.IsAvailable() then
			mode = "ELIM" -- (mapa sin sitios para la bomba)
		end
		startMode(mode)

		roundOver = false
		balanceTeams()
		resetStats()
		table.clear(spawnedThisRound)
		setState("Playing")
		-- Mapa destacado del día: aviso al empezar
		local featured = ReplicatedStorage:GetAttribute("FeaturedMap")
		if featured and featured == ReplicatedStorage:GetAttribute("MapName") and GameConfig.FeaturedMap then
			Remotes.Notify:FireAllClients("Big", "⭐ ¡MAPA DESTACADO DE HOY! +" .. math.floor((GameConfig.FeaturedMap.XPBonus - 1) * 100 + 0.5) .. "% XP")
		end
		if mode == "CTF" then
			Flags.Start()
		elseif mode == "KOTH" then
			Hardpoint.Start()
		elseif mode == "DOM" then
			Domination.Start()
		elseif mode == "CAL" then
			Pumpkins.Start()
		end
		if mode ~= "ELIM" and mode ~= "SND" then
			respawnAll() -- (Eliminación reaparece a todos al empezar cada ronda)
		end
		local s = settings(mode)
		local goal = ReplicatedStorage:GetAttribute("ScoreToWin")
		local intro = {
			TDM = "¡A LUCHAR! Primero a " .. goal .. " bajas",
			CTF = "¡CAPTURA LA BANDERA! Primero a " .. goal,
			KOTH = "¡ZONA DE CONTROL! Primero a " .. goal .. " puntos",
			DOM = "🚩 ¡DOMINIO! Captura A, B y C · primero a " .. goal .. " puntos",
			FFA = "¡TODOS CONTRA TODOS! Primero a " .. goal .. " bajas",
			GUN = "¡ESCALADA DE ARMAS! Una baja con cada arma",
			ELIM = "¡ELIMINACIÓN! Una vida por ronda · primero a " .. goal .. " rondas",
			SND = "💣 ¡BUSCAR Y DESTRUIR! Una vida · planta o desactiva la bomba · primero a " .. goal .. " rondas",
			INF = "🧟 ¡INFECCIÓN! Escóndete y prepárate",
			CAL = Pumpkins.Tags() and ("🏷️ ¡BAJA CONFIRMADA! Recoge las placas de tus enemigos caídos · primero a " .. goal)
				or ("🎃 ¡CALABAZAS! Recoge las de tus enemigos caídos · primero a " .. goal),
		}
		Remotes.Notify:FireAllClients("Big", intro[mode] or s.Name)
		if mode == "ELIM" or mode == "SND" then
			task.wait(2)
			eliminationRounds(s)
		elseif mode == "INF" then
			infectionRound(s)
		else
			countdown(s.RoundTime, function()
				return roundOver
			end)
		end
		-- La repetición de la baja final, antes de limpiar el modo (en la Infección, por ejemplo, todos
		-- reaparecen al acabar y ya no estarían donde fue la baja)
		playFinalKillcam()
		Flags.Stop()
		Hardpoint.Stop()
		Domination.Stop()
		Pumpkins.Stop()
		Loot.Clear()
		Loadout.Override = nil
		if mode == "INF" then
			clearInfection()
			-- Fuera de la Infección todos vuelven a ser normales (los zombis reaparecen)
			respawnAll()
		end
		if mode == "GUN" then
			-- Fuera de la Escalada cada uno recupera sus armas
			for _, player in Players:GetPlayers() do
				Loadout.GiveDefault(player)
			end
		end
		endRound()
	end
end

local function gameLoop()
	while true do
		-- Si algo falla en una ronda, el servidor no se queda colgado: se limpia y empieza otra
		local ok, err = xpcall(playRound, debug.traceback)
		if not ok then
			warn("[Round] Error en la ronda, se reinicia:", err)
			pcall(Flags.Stop)
			pcall(Hardpoint.Stop)
			pcall(Domination.Stop)
			pcall(Pumpkins.Stop)
			pcall(Loot.Clear)
			clearElimination()
			clearInfection()
			-- (primero las armas normales: si no, tras un fallo en Escalada se quedarían las de esa ronda)
			Loadout.Override = nil
			for _, player in Players:GetPlayers() do
				pcall(Loadout.GiveDefault, player)
			end
			pcall(respawnAll)
			roundOver = true
			task.wait(3)
		end
	end
end

-- Amistad detectada (Friends tarda un poco al entrar alguien): si el que acaba de entrar sigue en
-- la portada y su amigo está en el otro equipo, se le cambia con él si el reparto sigue igualado
local function onFriendship(newcomer, friend)
	if not isTeamMode() or ReplicatedStorage:GetAttribute("Infection") then
		return
	end
	if not newcomer.Parent or not friend.Parent or newcomer:GetAttribute("InMenu") ~= true then
		return
	end
	local target = friend.Team
	local current = newcomer.Team
	if not target or target == current or not table.find(teams, target) then
		return
	end
	local after = #target:GetPlayers() + 1
	local left = current and (#current:GetPlayers() - 1) or 0
	if current == nil or math.abs(after - left) <= 1 then
		newcomer.Team = target
	end
end

function Round.Init()
	Friends.OnFriendship = onFriendship
	Players.RespawnTime = GameConfig.RespawnTime
	setupTeams()
	startMode("TDM")
	setState("Intermission")
	ReplicatedStorage:SetAttribute("TimeLeft", GameConfig.IntermissionTime)
	Flags.OnCapture = function(_, team)
		addScore(team, 1)
	end
	Hardpoint.OnScore = function(team, amount)
		addScore(team, amount)
	end
	Domination.OnScore = function(team, amount)
		addScore(team, amount)
	end
	-- Calabazas: quién puede recogerlas (jugadores vivos en partida y bots) y qué pasa al recogerlas
	Pumpkins.Collectors = function()
		local list = {}
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and humanoid and humanoid.Health > 0 and player.Team and not player:GetAttribute("InMenu") then
				table.insert(list, { Position = root.Position, Team = player.Team, Player = player })
			end
		end
		for _, agent in Combat.BotsByName do
			if agent.Root and agent.Root.Parent and agent.Humanoid and agent.Humanoid.Health > 0 and agent.Team then
				table.insert(list, { Position = agent.Root.Position, Team = agent.Team, Bot = agent })
			end
		end
		return list
	end
	Pumpkins.OnCollect = function(collector, confirmed, _, fromBot)
		if confirmed then
			addScore(collector.Team, 1)
		end
		local player = collector.Player
		if player then
			Remotes.Notify:FireClient(player, "Pumpkin", confirmed)
			-- (la calabaza de un bot vale menos, como la baja)
			local scale = fromBot and GameConfig.Bots.RewardScale or 1
			if confirmed then
				PlayerData.AddXP(player, math.floor((GameConfig.XP.PumpkinConfirm or 0) * scale), Pumpkins.Tags() and "🏷️ Baja confirmada" or "🎃 Calabaza confirmada")
				PlayerData.AddCoins(player, math.max(1, math.floor((GameConfig.Coins.Pumpkin or 2) * scale)))
				PlayerData.Track(player, "Pumpkin", 1)
			else
				PlayerData.AddXP(player, math.floor((GameConfig.XP.PumpkinDeny or 0) * scale), Pumpkins.Tags() and "🏷️ Placa recuperada" or "🎃 Calabaza recuperada")
			end
		end
	end

	Remotes.VoteMap.OnServerEvent:Connect(function(player, index)
		if ReplicatedStorage:GetAttribute("State") ~= "Intermission" then
			return
		end
		if type(index) ~= "number" or not voteOptions[index] then
			return
		end
		votes[player] = index
		publishVotes()
	end)

	local function onPlayer(player)
		assignTeam(player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(function()
				-- Revivir instantáneo: aparece donde murió; si no, punto normal (FFA)
				if not Respawn.ApplyRevive(player, character) then
					ffaSpawnFor(player, character)
				end
				if ReplicatedStorage:GetAttribute("Infection") == "On" and player.Team == teams[2] then
					zombify(player, character)
				end
			end)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		votes[player] = nil
		streakVictims[player] = nil
		updateLeader(player)
	end)
	for _, player in Players:GetPlayers() do
		if not player.Team then
			onPlayer(player)
			Respawn.Load(player)
		end
	end

	task.spawn(gameLoop)
end

return Round
