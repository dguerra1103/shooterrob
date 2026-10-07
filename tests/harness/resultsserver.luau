-- Fin de partida en el servidor: el MatchResult (participantes con puntos, MVP, motivo) y las
-- copias de los avatares para la pantalla final; el resumen con lo que de verdad se ha dado
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.EndScreenTime = 0.5
GameConfig.MinPlayers = 1
GameConfig.Modes = { "TDM" }
for _, s in GameConfig.ModeSettings do
	s.RoundTime = 2
end
local M = game.ServerScriptService.Server.Modules
local MapBuilder = req(M.MapBuilder)
local PlayerData = req(M.PlayerData)
local Combat = req(M.Combat)
local Round = req(M.Round)
local Grenades = req(M.Grenades)
local Killstreaks = req(M.Killstreaks)
local MatchResults = req(Shared.MatchResults)
MapBuilder.Build()
PlayerData.Init()
Combat.Init()
Combat.OnKill = Round.RegisterKill
Grenades.Init()
Killstreaks.Init()
local players = {}
for i = 1, 3 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.DisplayName = "Jugador" .. i; p.UserId = 700 + i; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	players[i] = p
end
-- El 3 se queda en el lobby: no sale en el resultado
players[3]:SetAttribute("InMenu", true)
Round.Init()
local RS = game.ReplicatedStorage
local deadline = os.clock() + 30
local killed = false
local roundEnd
while os.clock() < deadline and not roundEnd do
	if RS:GetAttribute("State") == "Playing" and not killed and players[1].Team then
		killed = true
		players[1]:SetAttribute("InMenu", false)
		for _ = 1, 3 do
			Round.RegisterKill(players[1], players[2], "P2", "ARX27", true, nil)
		end
		players[1]:SetAttribute("MatchAssists", 2)
	end
	for _, b in mock.broadcast do
		if b.Remote == "RoundEnd" then
			roundEnd = b.Args[1]
		end
	end
	task.wait(0.05)
end
check(roundEnd ~= nil, "la partida termina y se manda RoundEnd")
local result = roundEnd.Result
check(type(result) == "table", "RoundEnd lleva el MatchResult")
check(result.Mode == "TDM" and type(result.ModeName) == "string" and type(result.Map) == "string", "modo y mapa: " .. tostring(result.ModeName) .. " / " .. tostring(result.Map))
check(type(result.ScoreA) == "number" and type(result.ScoreB) == "number", "marcador " .. result.ScoreA .. "-" .. result.ScoreB)
check(MatchResults.Reasons[result.Reason] ~= nil, "motivo del final: " .. tostring(result.Reason))
local p1, p3
for _, entry in result.Players do
	if entry.Id == "u701" then p1 = entry end
	if entry.Id == "u703" then p3 = entry end
	check(entry.Model == nil, "sin modelos en el remoto (" .. entry.Name .. ")")
end
check(p1 ~= nil and p1.Kills == 3 and p1.Assists == 2, "jugador 1 con sus bajas y asistencias")
check(p1.Points == MatchResults.Points(3, 2, 0), "puntos = bajas×100 + asistencias×50 (" .. tostring(p1.Points) .. ")")
check(p1.Weapon ~= nil and p1.Team ~= nil, "con su arma (" .. tostring(p1.Weapon) .. ") y equipo")
check(p3 == nil, "quien sigue en el lobby no sale")
check(result.MVP == result.Players[1].Id, "MVP = el primero por puntos (" .. tostring(result.MVP) .. ")")
for i = 2, #result.Players do
	check(not MatchResults.Better(result.Players[i], result.Players[i - 1]), "orden por puntos " .. i)
end
local cast = RS:FindFirstChild("ResultsCast")
check(cast ~= nil, "carpeta del reparto de la pantalla final")
-- Resumen personal con lo que de verdad se ha dado
local summary
for _, sent in mock.sent do
	if sent.Remote == "MatchSummary" then summary = sent.Args[1] end
end
check(summary ~= nil and type(summary.BonusCoins) == "number" and type(summary.Crates) == "number", "resumen con monedas extra y cajas")
check(type(summary.Challenges) == "table" and type(summary.Unlocks) == "table", "resumen con desafíos y desbloqueos")
-- Motivos por modo
check(MatchResults.ReasonFor("SND", true, true, "BombDefused") == "BombDefused", "S&D: bomba desactivada")
check(MatchResults.ReasonFor("SND", true, true, "Eliminated") == "DecisiveRound", "S&D: ronda decisiva")
check(MatchResults.ReasonFor("TDM", true, true) == "ScoreLimit", "TDM: límite de puntos")
check(MatchResults.ReasonFor("DOM", true, true) == "Objectives", "Dominio: objetivos")
check(MatchResults.ReasonFor("TDM", true, false) == "TimeLimit", "sin llegar a la meta: tiempo agotado")
check(MatchResults.ReasonFor("TDM", false, false) == "Draw", "empate")
print("RESULTADOS SERVIDOR OK")
process.exit(0)
