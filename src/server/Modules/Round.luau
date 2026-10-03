-- Equipos, rondas, modos de juego (Duelo por equipos / Captura la bandera), marcador, rachas y recompensas.
-- El estado se publica como atributos de ReplicatedStorage para que la interfaz lo lea:
--   State ("Intermission" | "Playing" | "Ended"), Mode ("TDM" | "CTF"), ModeName,
--   TimeLeft, ScoreToWin, Score_<Equipo>
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)
local Flags = require(script.Parent.Flags)

local Round = {}

local teams = {}
local roundOver = false
local modeIndex = 0

local STREAK_ANNOUNCE = { [3] = true, [5] = true, [7] = true, [10] = true, [15] = true, [20] = true }

local function setState(state)
	ReplicatedStorage:SetAttribute("State", state)
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

-- Elige el siguiente modo de la rotación (salta CTF si el mapa no tiene bases de bandera)
local function nextMode()
	local modes = GameConfig.Modes
	for _ = 1, #modes do
		modeIndex = modeIndex % #modes + 1
		local mode = modes[modeIndex]
		if GameConfig.ModeSettings[mode] and (mode ~= "CTF" or Flags.IsAvailable()) then
			return mode
		end
		if mode == "CTF" then
			warn("[Round] El mapa no tiene piezas FlagBase para cada equipo; se salta Captura la bandera")
		end
	end
	return "TDM"
end

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
	player.Neutral = false
	player.Team = smallestTeam(player)
end

local function balanceTeams()
	-- Mueve jugadores del equipo grande al pequeño si la diferencia es > 1
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
	end
	for _, team in teams do
		ReplicatedStorage:SetAttribute("Score_" .. team.Name, 0)
	end
end

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

			-- En duelo por equipos cada baja es un punto; en CTF solo cuentan las capturas
			if ReplicatedStorage:GetAttribute("Mode") == "TDM" then
				addScore(killer.Team, 1)
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
	local a, b = teams[1], teams[2]
	local scoreA, scoreB = getScore(a.Name), getScore(b.Name)
	local winner = nil
	if scoreA > scoreB then
		winner = a
	elseif scoreB > scoreA then
		winner = b
	end

	-- MVP = más bajas (en CTF cada captura vale como 3 bajas)
	local mvp, mvpKills, mvpScore = nil, 0, -1
	for _, player in Players:GetPlayers() do
		local kills = PlayerData.GetLeaderstats(player).Bajas.Value
		local score = kills + (player:GetAttribute("Captures") or 0) * 3
		if score > mvpScore then
			mvp, mvpKills, mvpScore = player, kills, score
		end
	end

	for _, player in Players:GetPlayers() do
		if winner and player.Team == winner then
			PlayerData.AddXP(player, GameConfig.XP.Win, "Victoria")
			PlayerData.AddCoins(player, GameConfig.Coins.Win)
			PlayerData.Increment(player, "Wins", 1)
		else
			PlayerData.AddXP(player, GameConfig.XP.Loss, "Partida completada")
		end
	end

	Remotes.RoundEnd:FireAllClients({
		Winner = winner and winner.Name or nil,
		WinnerColor = winner and winner.TeamColor.Color or Color3.new(1, 1, 1),
		ScoreA = scoreA,
		ScoreB = scoreB,
		MVP = mvp and mvp.Name or nil,
		MVPKills = mvpKills,
		MVPCaptures = mvp and mvp:GetAttribute("Captures") or 0,
	})
	task.wait(GameConfig.EndScreenTime)
end

local function gameLoop()
	while true do
		local mode = nextMode()
		local settings = GameConfig.ModeSettings[mode]
		ReplicatedStorage:SetAttribute("Mode", mode)
		ReplicatedStorage:SetAttribute("ModeName", settings.Name)
		ReplicatedStorage:SetAttribute("ScoreToWin", settings.ScoreToWin)

		setState("Intermission")
		countdown(GameConfig.IntermissionTime)
		while #Players:GetPlayers() < GameConfig.MinPlayers do
			ReplicatedStorage:SetAttribute("TimeLeft", 0)
			task.wait(1)
		end

		roundOver = false
		balanceTeams()
		resetStats()
		setState("Playing")
		if mode == "CTF" then
			Flags.Start()
		end
		respawnAll()
		if mode == "CTF" then
			Remotes.Notify:FireAllClients("Big", "¡CAPTURA LA BANDERA! Primero a " .. settings.ScoreToWin)
		else
			Remotes.Notify:FireAllClients("Big", "¡A LUCHAR! Primero a " .. settings.ScoreToWin .. " bajas")
		end
		countdown(settings.RoundTime, function()
			return roundOver
		end)
		Flags.Stop()
		endRound()
	end
end

function Round.Init()
	Players.RespawnTime = GameConfig.RespawnTime
	setupTeams()
	Flags.OnCapture = function(_, team)
		addScore(team, 1)
	end
	setState("Intermission")
	ReplicatedStorage:SetAttribute("TimeLeft", GameConfig.IntermissionTime)

	Players.PlayerAdded:Connect(assignTeam)
	for _, player in Players:GetPlayers() do
		if not player.Team then
			assignTeam(player)
			player:LoadCharacter()
		end
	end

	task.spawn(gameLoop)
end

return Round
