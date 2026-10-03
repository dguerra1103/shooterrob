-- Rondas, modos de juego, votación de mapa/modo, equipos, marcador, rachas y recompensas.
-- Modos: TDM (duelo por equipos), CTF (captura la bandera), KOTH (zona de control),
--        FFA (todos contra todos) y GUN (escalada de armas).
--
-- Estado publicado en ReplicatedStorage para la interfaz:
--   State ("Intermission" | "Playing" | "Ended"), Mode, ModeName, TeamMode, TimeLeft, ScoreToWin,
--   Score_<Equipo>, LeaderName, LeaderScore, MapName,
--   VoteN_Map, VoteN_Mode, VoteN_Count (N = 1..3) durante el descanso
-- En cada jugador: atributo Score (bajas en FFA / nivel en Escalada), Streak, Captures, GunLevel
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)
local Flags = require(script.Parent.Flags)
local Hardpoint = require(script.Parent.Hardpoint)
local MapBuilder = require(script.Parent.MapBuilder)
local Loadout = require(script.Parent.Loadout)

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

-- Líder individual (modos sin equipos)
local function updateLeader()
	local best, bestScore = nil, -1
	for _, player in Players:GetPlayers() do
		local score = player:GetAttribute("Score") or 0
		if score > bestScore then
			best, bestScore = player, score
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
		player:SetAttribute("Captures", 0)
		player:SetAttribute("Score", 0)
		player:SetAttribute("GunLevel", 1)
	end
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

function Round.RegisterKill(killer, victim, victimName, weaponName, headshot)
	if victim then
		PlayerData.GetLeaderstats(victim).Muertes.Value += 1
		victim:SetAttribute("Streak", 0)
	end

	local killerColor, victimColor = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
	if victim and victim.Team then
		victimColor = victim.TeamColor.Color
	end

	if killer and killer ~= victim then
		if killer.Team then
			killerColor = killer.TeamColor.Color
		end
		if victim then
			PlayerData.GetLeaderstats(killer).Bajas.Value += 1
			local streak = (killer:GetAttribute("Streak") or 0) + 1
			killer:SetAttribute("Streak", streak)

			if ReplicatedStorage:GetAttribute("State") == "Playing" then
				if currentMode == "TDM" then
					addScore(killer.Team, 1)
				elseif currentMode == "FFA" then
					addPlayerScore(killer, 1)
				elseif currentMode == "GUN" then
					gunGameKill(killer, victim, weaponName)
				end
			end

			local xp = GameConfig.XP.Kill + GameConfig.XP.StreakBonus * (streak - 1)
			if headshot then
				xp += GameConfig.XP.Headshot
			end
			PlayerData.AddXP(killer, xp, headshot and "Disparo a la cabeza" or "Eliminación")
			PlayerData.AddCoins(killer, GameConfig.Coins.Kill)
			PlayerData.Increment(killer, "TotalKills", 1)

			if STREAK_ANNOUNCE[streak] then
				Remotes.Notify:FireAllClients("Streak", killer.Name .. " tiene una racha de " .. streak .. " bajas")
			end
		end
	end

	local weapon = weaponName and Weapons.Get(weaponName)
	Remotes.KillFeed:FireAllClients({
		Killer = killer and killer.Name or nil,
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

local function ffaSpawnFor(player, character)
	if isTeamMode() then
		return
	end
	local map = workspace:FindFirstChild("Map")
	if not map then
		return
	end
	local points = {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "FFASpawn" then
			table.insert(points, d)
		end
	end
	if #points == 0 then
		return
	end
	local others = {}
	for _, p in Players:GetPlayers() do
		local root = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root then
			table.insert(others, root.Position)
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
		ReplicatedStorage:SetAttribute("Vote" .. i .. "_Map", def and def.Name or "Mapa propio")
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
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end

local function endRound()
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
	local leader, leaderScore = updateLeader()

	-- MVP = más bajas (en CTF cada captura cuenta como 3 bajas)
	local mvp, mvpKills, mvpScore = nil, 0, -1
	for _, player in Players:GetPlayers() do
		local kills = PlayerData.GetLeaderstats(player).Bajas.Value
		local score = kills + (player:GetAttribute("Captures") or 0) * 3
		if score > mvpScore then
			mvp, mvpKills, mvpScore = player, kills, score
		end
	end

	for _, player in Players:GetPlayers() do
		local won
		if teamMode then
			won = winner ~= nil and player.Team == winner
		else
			won = leader == player and leaderScore > 0
		end
		if won then
			PlayerData.AddXP(player, GameConfig.XP.Win, "Victoria")
			PlayerData.AddCoins(player, GameConfig.Coins.Win)
			PlayerData.Increment(player, "Wins", 1)
		else
			PlayerData.AddXP(player, GameConfig.XP.Loss, "Partida completada")
		end
	end

	Remotes.RoundEnd:FireAllClients({
		TeamMode = teamMode,
		Winner = teamMode and (winner and winner.Name) or (leader and leader.Name),
		WinnerColor = winner and winner.TeamColor.Color or Color3.fromRGB(255, 200, 60),
		ScoreA = scoreA,
		ScoreB = scoreB,
		LeaderScore = leaderScore,
		MVP = mvp and mvp.Name or nil,
		MVPKills = mvpKills,
		MVPCaptures = mvp and mvp:GetAttribute("Captures") or 0,
	})
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

local function gameLoop()
	while true do
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

		-- Resultado de la votación (empate = al azar)
		local counts = publishVotes()
		local bestIndex, bestCount = math.random(1, #voteOptions), -1
		for i, c in counts do
			if c > bestCount or (c == bestCount and math.random() < 0.5) then
				bestIndex, bestCount = i, c
			end
		end
		local choice = voteOptions[bestIndex]
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
		respawnAll()
		local s = settings(mode)
		local goal = ReplicatedStorage:GetAttribute("ScoreToWin")
		local intro = {
			TDM = "¡A LUCHAR! Primero a " .. goal .. " bajas",
			CTF = "¡CAPTURA LA BANDERA! Primero a " .. goal,
			KOTH = "¡ZONA DE CONTROL! Primero a " .. goal .. " puntos",
			FFA = "¡TODOS CONTRA TODOS! Primero a " .. goal .. " bajas",
			GUN = "¡ESCALADA DE ARMAS! Una baja con cada arma",
		}
		Remotes.Notify:FireAllClients("Big", intro[mode] or s.Name)
		countdown(s.RoundTime, function()
			return roundOver
		end)
		Flags.Stop()
		Hardpoint.Stop()
		Loadout.Override = nil
		endRound()
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
			task.spawn(ffaSpawnFor, player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		votes[player] = nil
		updateLeader()
	end)
	for _, player in Players:GetPlayers() do
		if not player.Team then
			onPlayer(player)
			player:LoadCharacter()
		end
	end

	task.spawn(gameLoop)
end

return Round
