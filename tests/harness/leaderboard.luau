local process = require("@lune/process")
local serde = require("@lune/serde")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
local Leaderboard = req(M.Leaderboard)
PlayerData.Init()
local function check(c, m) if not c then error("FALLO: " .. m, 2) end print("ok  " .. m) end
local players = {}
for i = 1, 3 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.UserId = 100 + i; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	PlayerData.Get(p).TotalKills = i * 10
	PlayerData.Get(p).Wins = 4 - i
	players[i] = p
end
-- Clasificación previa de otros servidores
mock.ordered = mock.ordered or {}
Leaderboard.Init()
mock.ordered.TopBajas_v1["999"] = 500
task.wait(10.5)
local rows = serde.decode("json", game.ReplicatedStorage:GetAttribute("Leaderboard_Kills"))
check(#rows == 4, "4 filas en el top de bajas")
check(rows[1].UserId == 999 and rows[1].Value == 500 and rows[1].Name == "Usuario999", "jugador de otro servidor primero, con su nombre")
check(rows[2].Name == "P3" and rows[2].Value == 30, "ordenado por bajas")
local wins = serde.decode("json", game.ReplicatedStorage:GetAttribute("Leaderboard_Wins"))
check(wins[1].Name == "P1" and wins[1].Value == 3, "top de victorias")
-- Un récord nunca baja
mock.ordered.TopBajas_v1["101"] = 9999
task.wait(0.1)
PlayerData.Get(players[1]).TotalKills = 11
print("TODO OK")
process.exit(0)
