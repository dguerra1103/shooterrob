-- Killcam final (servidor): la última baja, si cierra la partida o la ronda, se manda a todos
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local roblox = require("@lune/roblox")
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.FinalKillcamTime = 0.5
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
local Round = req(M.Round)
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
PlayerData.Init()
local players = {}
for i = 1, 2 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.UserId = 900 + i; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	players[i] = p
end
task.wait(0.2)
local function finals()
	local n, last = 0, nil
	for _, b in mock.broadcast do
		if b.Remote == "FinalKillcam" then n += 1; last = b.Args[1] end
	end
	return n, last
end
-- Sin bajas: no hay
check(Round.PlayFinalKillcam() == false and finals() == 0, "sin bajas, no hay killcam final")
-- Una baja de P1 a P2
Round.RegisterKill(players[1], players[2], "P2", "ARX27", false, roblox.Vector3.new(0, 3, 0))
local frozenDuring = nil
task.spawn(function()
	task.wait(0.2)
	frozenDuring = RS:GetAttribute("Frozen")
end)
local played = Round.PlayFinalKillcam()
local n, info = finals()
check(played and n == 1, "la última baja se repite para todos")
check(info.Killer == "P1" and info.Victim == "P2" and info.Weapon == "ARX27", "con quién, a quién y con qué")
check(frozenDuring == true and RS:GetAttribute("Frozen") == false, "mientras dura, todo congelado; luego no")
check(Round.PlayFinalKillcam() == false, "no se repite dos veces la misma")
-- Una baja vieja (hace más de 3 s) no cuenta
Round.RegisterKill(players[2], players[1], "P1", "ARX27", false, roblox.Vector3.new(0, 3, 0))
task.wait(3.2)
check(Round.PlayFinalKillcam() == false, "si la partida acaba mucho después de la última baja, no hay")
-- Morir solo (sin asesino) no cuenta
Round.RegisterKill(nil, players[1], "P1", nil, false, roblox.Vector3.new(0, 3, 0))
check(Round.PlayFinalKillcam() == false, "una caída o un suicidio no tienen killcam")
-- La baja que cierra la partida: se congela todo al instante y es la que se repite, aunque haya otra después
local teamA = mock.new("Team"); teamA.Name = "Rojo"
local teamB = mock.new("Team"); teamB.Name = "Azul"
players[1].Team = teamA; players[2].Team = teamB
RS:SetAttribute("State", "Playing")
RS:SetAttribute("ScoreToWin", 1)
RS:SetAttribute("Score_Rojo", 0)
RS:SetAttribute("Frozen", false)
Round.RegisterKill(players[1], players[2], "P2", "ARX27", false, roblox.Vector3.new(0, 3, 0))
check(RS:GetAttribute("Frozen") == true, "la baja que gana la partida lo congela todo ya")
Round.RegisterKill(players[2], players[1], "P1", "Sniper", false, roblox.Vector3.new(0, 3, 0))
local before = finals()
check(Round.PlayFinalKillcam() == true, "hay repetición")
local n2, info2 = finals()
check(n2 == before + 1 and info2.Killer == "P1" and info2.Weapon == "ARX27", "la de la baja decisiva, no la de después")
check(RS:GetAttribute("Frozen") == false, "y luego se descongela")
RS:SetAttribute("State", "Lobby")
-- Si se acaba por tiempo o por puntos, con la última baja hace rato: no hay
Round.RegisterKill(players[1], players[2], "P2", "ARX27", false, roblox.Vector3.new(0, 3, 0))
task.wait(1.5)
check(Round.PlayFinalKillcam() == false, "acabar por tiempo o por puntos un rato después de una baja: sin repetición")
-- Desactivada en la configuración
GameConfig.FinalKillcam = false
Round.RegisterKill(players[1], players[2], "P2", "ARX27", false, roblox.Vector3.new(0, 3, 0))
check(Round.PlayFinalKillcam() == false, "con FinalKillcam = false, nada")
print("KILLCAM FINAL SERVIDOR OK")
process.exit(0)
