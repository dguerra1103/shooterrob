-- Escalada de armas con bots: matar a un bot sube de arma
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local GameConfig = req(RS.Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.MinPlayers = 1
GameConfig.Modes = { "GUN" }
local M = game.ServerScriptService.Server.Modules
req(M.MapBuilder).Build()
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Round = req(M.Round)
local p = mock.new("Player"); p.Name = "P"; p.UserId = 11; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
p:SetAttribute("InMenu", false)
Round.Init()
local deadline = os.clock() + 10
while RS:GetAttribute("State") ~= "Playing" and os.clock() < deadline do task.wait(0.1) end
check(RS:GetAttribute("Mode") == "GUN", "Escalada de armas en juego")
Round.RegisterKill(p, nil, "Bot Max", "ARX27", false, nil, nil, { Name = "Bot Max", Team = nil })
check(p:GetAttribute("GunLevel") == 2, "una baja a un bot sube de arma")
print("ESCALADA BOTS OK")
process.exit(0)
