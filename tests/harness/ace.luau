-- ACE (eliminar solo a todo el equipo rival en una ronda) y remontada al final de la partida
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local roblox = require("@lune/roblox")
local game, req = mock.buildGame(process.args[1])
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
local Round = req(M.Round)
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
PlayerData.Init()
local red = mock.new("Team"); red.Name = "Rojo"
local blue = mock.new("Team"); blue.Name = "Azul"
local players = {}
for i = 1, 4 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.UserId = 700 + i; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	p.Team = i == 1 and red or blue
	players[i] = p
end
task.wait(0.2)
RS:SetAttribute("State", "Playing")
RS:SetAttribute("ScoreToWin", 99)
local function aces()
	local list = {}
	for _, b in mock.broadcast do
		if b.Remote == "Notify" and b.Args[1] == "Ace" then table.insert(list, b.Args[2]) end
	end
	return list
end
local pos = roblox.Vector3.new(0, 3, 0)
Round.StartAceRound({ Rojo = 1, Azul = 3 })
Round.RegisterKill(players[1], players[2], "P2", "ARX27", false, pos)
Round.RegisterKill(players[1], players[3], "P3", "ARX27", false, pos)
check(#aces() == 0, "dos de tres: aún no")
Round.RegisterKill(players[1], players[4], "P4", "ARX27", true, pos)
check(#aces() == 1 and aces()[1] == "P1", "los tres: ¡ACE! para todos (" .. #aces() .. ")")
Round.RegisterKill(players[1], players[4], "P4", "ARX27", true, pos)
check(#aces() == 1, "solo una vez por ronda")
-- Equipo rival de solo 2: no cuenta
Round.StartAceRound({ Rojo = 2, Azul = 2 })
Round.RegisterKill(players[2], players[1], "P1", "ARX27", false, pos)
check(#aces() == 1, "contra 1 o 2 no hay ACE")
print("ACE OK")
process.exit(0)
