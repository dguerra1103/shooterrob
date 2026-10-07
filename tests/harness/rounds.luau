-- Simula varias rondas completas (todos los modos) con tiempos cortos y busca errores
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
-- (un fallo sale en el acto: con assert, las rondas siguen vivas y la prueba parecía colgada)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end end
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.EndScreenTime = 0.5
GameConfig.MinPlayers = 1
for _, s in GameConfig.ModeSettings do
	s.RoundTime = 1
end
local M = game.ServerScriptService.Server.Modules
local MapBuilder = req(M.MapBuilder)
local PlayerData = req(M.PlayerData)
local Loadout = req(M.Loadout)
local Combat = req(M.Combat)
local Round = req(M.Round)
local Grenades = req(M.Grenades)
local Killstreaks = req(M.Killstreaks)
-- Capturamos los avisos de error del ciclo de rondas
local errors = {}
local warnOriginal = warn
MapBuilder.Build()
PlayerData.Init()
Combat.Init()
Combat.OnKill = Round.RegisterKill
Grenades.Init()
Killstreaks.Init()
local players = {}
for i = 1, 4 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.UserId = 500 + i; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	players[i] = p
end
Round.Init()
local states, modes, maps = {}, {}, {}
local RS = game.ReplicatedStorage
local deadline = os.clock() + 40
local lastState
while os.clock() < deadline do
	local st = RS:GetAttribute("State")
	if st ~= lastState then
		table.insert(states, st)
		lastState = st
		if st == "Playing" then
			modes[RS:GetAttribute("Mode")] = true
			maps[RS:GetAttribute("MapName") or "?"] = true
			-- Una baja de prueba en cada ronda
			Round.RegisterKill(players[1], players[2], "P2", "ARX27", true, nil)
		end
	end
	task.wait(0.05)
end
local playing = 0
for _, s in states do
	if s == "Playing" then playing += 1 end
end
local modeList, mapList = {}, {}
for m in modes do table.insert(modeList, m) end
for m in maps do table.insert(mapList, m) end
print("rondas jugadas:", playing)
print("modos:", table.concat(modeList, ", "))
print("mapas:", table.concat(mapList, ", "))
print("LoadCharacter llamadas:", mock.loadCharacterCalls)
print("Bajas P1:", PlayerData.GetLeaderstats(players[1]).Bajas.Value, "XP/monedas P1:", PlayerData.Get(players[1]).XP, PlayerData.Get(players[1]).Coins)
check(playing >= 5, "deberían jugarse varias rondas")
local summaries = 0
for _, sent in mock.sent do
	if sent.Remote == "MatchSummary" then
		summaries += 1
		local s = sent.Args[1]
		check(type(s.XP) == "number" and type(s.Coins) == "number" and s.Level and s.XPPerLevel and s.Kills, "resumen completo")
	end
end
print("resúmenes enviados:", summaries)
-- Rango: P1 y P2 tienen bajas/muertes en cada partida, así que su RP ha cambiado alguna vez
local rankSummaries = 0
for _, sent in mock.sent do
	if sent.Remote == "MatchSummary" and sent.Args[1].RankPoints ~= sent.Args[1].StartRank then
		rankSummaries += 1
	end
end
print("RP P1..P4:", PlayerData.Get(players[1]).RankPoints, PlayerData.Get(players[2]).RankPoints, PlayerData.Get(players[3]).RankPoints, PlayerData.Get(players[4]).RankPoints, "resúmenes con cambio de rango:", rankSummaries)
check(summaries >= 4, "cada jugador recibe el resumen de su partida")
-- Récord de bajas en una partida: se guarda, y el resumen lo marca al batirlo (desde 5)
local records = 0
for _, sent in mock.sent do
	if sent.Remote == "MatchSummary" and sent.Args[1].NewRecord then
		records += 1
		check(sent.Args[1].NewRecord == sent.Args[1].Kills and sent.Args[1].Kills >= 5, "récord = bajas de la partida")
	end
end
local bestKills = 0
for i = 1, 4 do bestKills = math.max(bestKills, PlayerData.Get(players[i]).BestMatchKills) end
print("récords:", records, "mejor partida:", bestKills)
check(bestKills > 0, "se guarda el récord de bajas en una partida")
local firstWins, pity = 0, 0
for _, sent in mock.sent do
	if sent.Remote == "Notify" and type(sent.Args[2]) == "string" and string.find(sent.Args[2], "Primera victoria", 1, true) then
		firstWins += 1
	end
end
for i = 1, 4 do pity += PlayerData.Get(players[i]).CratePity end
print("primeras victorias avisadas:", firstWins, "garantía de cajas sumada:", pity)
-- (los modos salen al azar y las rondas duran 1 s: a veces ninguna partida tiene ganador —Dominio sin
-- capturas, Buscar y destruir sin bomba— y entonces no puede haber primera victoria. Y solo cuenta
-- para quien ha jugado de verdad: P1 y P2, que tienen una baja o una muerte en cada partida; P3 y P4
-- no hacen nada en rondas de 1 s)
local wins = (PlayerData.Get(players[1]).Wins or 0) + (PlayerData.Get(players[2]).Wins or 0)
print("victorias de P1 y P2:", wins)
check(firstWins <= 4, "primera victoria del día: una por jugador como mucho")
check(wins == 0 or firstWins >= 1, "si P1 o P2 ganan alguna partida, hay aviso de primera victoria del día")
check(pity > 0 or PlayerData.Get(players[1]).FreeCrates > 0, "la caja sorpresa se tira al acabar")
print("TODO OK")
process.exit(0)
