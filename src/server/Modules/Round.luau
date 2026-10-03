-- Equipos, rondas (Team Deathmatch), marcador, rachas y recompensas.
-- El estado se publica como atributos de ReplicatedStorage para que la interfaz lo lea:
--   State ("Intermission" | "Playing" | "Ended"), TimeLeft, ScoreToWin, Score_<Equipo>
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)

local Round = {}

local teams = {}
local roundOver = false

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
	ReplicatedStorage:SetAttribute("ScoreToWin", GameConfig.ScoreToWin)
	ReplicatedStorage:SetAttribute("TeamA", teams[1].Name)
	ReplicatedStorage:SetAttribute("TeamB", teams[2].Name)
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

			if ReplicatedStorage:GetAttribute("State") == "Playing" and killer.Team then
				local teamName = killer.Team.Name
				local score = getScore(teamName) + 1
				ReplicatedStorage:SetAttribute("Score_" .. teamName, score)
				if score >= GameConfig.ScoreToWin then
					roundOver = true
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

	-- MVP = más bajas
	local mvp, mvpKills = nil, -1
	for _, player in Players:GetPlayers() do
		local kills = PlayerData.GetLeaderstats(player).Bajas.Value
		if kills > mvpKills then
			mvp, mvpKills = player, kills
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
		MVPKills = math.max(mvpKills, 0),
	})
	task.wait(GameConfig.EndScreenTime)
end

local function gameLoop()
	while true do
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
		respawnAll()
		Remotes.Notify:FireAllClients("Big", "¡A LUCHAR! Primero en llegar a " .. GameConfig.ScoreToWin)
		countdown(GameConfig.RoundTime, function()
			return roundOver
		end)
		endRound()
	end
end

function Round.Init()
	Players.RespawnTime = GameConfig.RespawnTime
	setupTeams()
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
