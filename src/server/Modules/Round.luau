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
local MapBuilder = require(script.Parent.MapBuilder)
local Loadout = require(script.Parent.Loadout)
local Killstreaks = require(script.Parent.Killstreaks)
local Grenades = require(script.Parent.Grenades)
local Respawn = require(script.Parent.Respawn)
local Bots = require(script.Parent.Bots)

local Round = {}

local teams = {}
local roundOver = false
local currentMode = "TDM"
local votes = {} -- [player] = índice
local voteOptions = {}

local STREAK_ANNOUNCE = { [3] = true, [5] = true, [7] = true, [10] = true, [15] = true, [20] = true }

local function setState(state)
	ReplicatedStorage:SetAttribute("State", state)
end

local function settings(mode)
	return GameConfig.ModeSettings[mode or currentMode]
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

local function smallestTeam(exclude)
	local best, bestCount = nil, math.huge
	for _, team in teams do
		local count = 0
		for _, p in team:GetPlayers() do
			if p ~= exclude then
				count += 1
			end
		end
		if count < bestCount or (count == bestCount and math.random() < 0.5) then
			best, bestCount = team, count
		end
	end
	return best
end

local function assignTeam(player)
	if isTeamMode() then
		player.Neutral = false
		player.Team = smallestTeam(player)
	else
		player.Team = nil
		player.Neutral = true
	end
end

local function balanceTeams()
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
	while math.abs(#a:GetPlayers() - #b:GetPlayers()) > 1 do
		local big = #a:GetPlayers() > #b:GetPlayers() and a or b
		local small = big == a and b or a
		local list = big:GetPlayers()
		list[math.random(1, #list)].Team = small
	end
end

local function resetStats()
	for _, player in Players:GetPlayers() do
		local stats = PlayerData.GetLeaderstats(player)
		stats.Bajas.Value = 0
		stats.Muertes.Value = 0
		player:SetAttribute("Streak", 0)
		player:SetAttribute("BestStreak", 0)
		player:SetAttribute("Captures", 0)
		player:SetAttribute("Score", 0)
		player:SetAttribute("GunLevel", 1)
		PlayerData.StartMatch(player)
	end
	Killstreaks.Reset()
	Grenades.Reset()
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
function Round.RegisterKill(killer, victim, victimName, weaponName, headshot, position, killerBot, victimBot)
	if victim then
		PlayerData.GetLeaderstats(victim).Muertes.Value += 1
		victim:SetAttribute("Streak", 0)
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
	end
	-- Un bot hace una baja: punto para su equipo (en equipos) o para él (todos contra todos)
	if killerBot then
		Bots.AddStat(killerBot, "Kills", 1)
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
			if streak > (killer:GetAttribute("BestStreak") or 0) then
				killer:SetAttribute("BestStreak", streak)
			end

			if playing then
				if currentMode == "TDM" then
					addScore(killer.Team, 1)
				elseif currentMode == "FFA" then
					addPlayerScore(killer, 1)
				elseif currentMode == "GUN" and victim then
					gunGameKill(killer, victim, weaponName)
				end
			end

			local xp = GameConfig.XP.Kill + GameConfig.XP.StreakBonus * (streak - 1)
			if headshot then
				xp += GameConfig.XP.Headshot
			end
			PlayerData.AddXP(killer, math.floor(xp * botScale), headshot and "Disparo a la cabeza" or "Eliminación")
			PlayerData.AddCoins(killer, math.max(1, math.floor(GameConfig.Coins.Kill * botScale)))
			if victim then
				PlayerData.Increment(killer, "TotalKills", 1)
			end
			PlayerData.AddWeaponKill(killer, weaponName)
			PlayerData.Track(killer, "Kill", 1, weaponName)
			PlayerData.Track(killer, "Streak", streak)
			if headshot then
				PlayerData.Track(killer, "Headshot", 1, weaponName)
			end

			if STREAK_ANNOUNCE[streak] then
				Remotes.Notify:FireAllClients("Streak", killer.Name .. " tiene una racha de " .. streak .. " bajas")
			end
			Killstreaks.OnStreak(killer, streak)
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

	local weapon = weaponName and Weapons.Get(weaponName)
	Remotes.KillFeed:FireAllClients({
		Killer = (killer and killer.Name) or (killerBot and killerBot.Name) or nil,
		KillerColor = killerColor,
		Victim = victimName,
		VictimColor = victimColor,
		Weapon = weapon and weapon.DisplayName or "",
		Headshot = headshot,
	})
end

---------------------------------------------------------------------------
-- Aparición libre (FFA / Escalada): el punto más alejado de los demás
---------------------------------------------------------------------------

local ffaCache = { Map = nil, Points = {} }

local function ffaSpawnFor(player, character)
	if isTeamMode() then
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
	for _, mode in GameConfig.Modes do
		if GameConfig.ModeSettings[mode] then
			table.insert(list, mode)
		end
	end
	_ = mapId
	return list
end

local function makeVoteOptions()
	local maps = table.clone(MapBuilder.Order)
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
	local options = {}
	local usedModes = {}
	for i = 1, 3 do
		local mapId = maps[((i - 1) % #maps) + 1]
		local modes = availableModes(mapId)
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
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Mode", GameConfig.ModeSettings[option.Mode].Name)
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

local function isDeadPlayer(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return not humanoid or humanoid.Health <= 0
end

-- Limpia el estado de Eliminación (al acabar o si la ronda falla)
local function clearElimination()
	ReplicatedStorage:SetAttribute("NoRespawn", false)
	ReplicatedStorage:SetAttribute("Frozen", false)
	ReplicatedStorage:SetAttribute("AliveA", nil)
	ReplicatedStorage:SetAttribute("AliveB", nil)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("ElimIn", nil)
	end
end

-- Rondas de una vida hasta que un equipo llegue a ScoreToWin rondas ganadas (o se acabe el tiempo total)
local MIN_SUBROUND = 20 -- no se empieza una ronda si quedan menos segundos que esto (más la preparación)
local function eliminationRounds(s)
	local deadline = os.clock() + s.RoundTime
	local number = 0
	local a, b = teams[1], teams[2]
	while not roundOver and deadline - os.clock() >= s.PrepTime + MIN_SUBROUND do
		number += 1
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
			end
		end
		Bots.RespawnDead()
		ReplicatedStorage:SetAttribute("NoRespawn", true)
		ReplicatedStorage:SetAttribute("Frozen", false)
		Remotes.Notify:FireAllClients("Big", "¡YA!")
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
		if decided then
			if winner then
				addScore(winner, 1)
				Remotes.Notify:FireAllClients("Big", "¡RONDA PARA " .. string.upper(winner.Name) .. "!")
			else
				Remotes.Notify:FireAllClients("Big", "RONDA EMPATADA")
			end
			task.wait(3)
		end
	end
	clearElimination()
	-- Nadie se queda muerto durante la pantalla final
	respawnAll()
end

local function endRound()
	-- El líder se calcula antes de cambiar de estado (al cambiar, los bots se quitan)
	local leader, leaderScore = updateLeader()
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
	local winScale = soloMatch and GameConfig.Bots.RewardScale or 1

	-- Premios solo para quien ha jugado (no para quien sigue en la pantalla de inicio)
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InMenu") then
			continue
		end
		local won
		if teamMode then
			won = winner ~= nil and player.Team == winner
		else
			won = leader == player and leaderScore > 0
		end
		-- Rango: empate (por equipos) = sin cambios; el MVP gana un poco más
		local draw = teamMode and winner == nil
		local result = won and "Win" or (draw and "Draw" or "Loss")
		PlayerData.AddRankPoints(player, Ranks.Delta(result, not teamMode, soloMatch, mvp == player and mvpScore > 0))
		if won then
			PlayerData.AddXP(player, math.floor(GameConfig.XP.Win * winScale), "Victoria")
			PlayerData.AddCoins(player, math.floor(GameConfig.Coins.Win * winScale))
			if not soloMatch then
				PlayerData.Increment(player, "Wins", 1)
			end
			PlayerData.Track(player, "Win", 1)
		else
			PlayerData.AddXP(player, GameConfig.XP.Loss, "Partida completada")
		end
		PlayerData.Track(player, "Match", 1)
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
	ReplicatedStorage:SetAttribute("ModeName", s.Name)
	ReplicatedStorage:SetAttribute("TeamMode", s.Teams ~= false)
	ReplicatedStorage:SetAttribute("ScoreToWin", scoreToWin)
	Loadout.Override = mode == "GUN" and gunGameWeapons or nil
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
			Remotes.Notify:FireAllClients("Big", "Cargando " .. MapBuilder.Get(choice.Map).Name .. "...")
			Flags.Stop()
			Hardpoint.Stop()
			MapBuilder.Build(choice.Map)
		end
		if mode == "CTF" and not Flags.IsAvailable() then
			mode = "TDM"
		elseif mode == "KOTH" and not Hardpoint.IsAvailable() then
			mode = "TDM"
		end
		startMode(mode)

		roundOver = false
		balanceTeams()
		resetStats()
		setState("Playing")
		if mode == "CTF" then
			Flags.Start()
		elseif mode == "KOTH" then
			Hardpoint.Start()
		end
		if mode ~= "ELIM" then
			respawnAll() -- (Eliminación reaparece a todos al empezar cada ronda)
		end
		local s = settings(mode)
		local goal = ReplicatedStorage:GetAttribute("ScoreToWin")
		local intro = {
			TDM = "¡A LUCHAR! Primero a " .. goal .. " bajas",
			CTF = "¡CAPTURA LA BANDERA! Primero a " .. goal,
			KOTH = "¡ZONA DE CONTROL! Primero a " .. goal .. " puntos",
			FFA = "¡TODOS CONTRA TODOS! Primero a " .. goal .. " bajas",
			GUN = "¡ESCALADA DE ARMAS! Una baja con cada arma",
			ELIM = "¡ELIMINACIÓN! Una vida por ronda · primero a " .. goal .. " rondas",
		}
		Remotes.Notify:FireAllClients("Big", intro[mode] or s.Name)
		if mode == "ELIM" then
			task.wait(2)
			eliminationRounds(s)
		else
			countdown(s.RoundTime, function()
				return roundOver
			end)
		end
		Flags.Stop()
		Hardpoint.Stop()
		Loadout.Override = nil
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
			clearElimination()
			pcall(respawnAll)
			Loadout.Override = nil
			roundOver = true
			task.wait(3)
		end
	end
end

function Round.Init()
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
			end)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		votes[player] = nil
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
