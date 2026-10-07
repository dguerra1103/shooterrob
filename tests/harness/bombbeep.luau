-- Bomba plantada: parpadea y pita
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 3; me.Parent = Players
Players.LocalPlayer = me
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local bomb = mock.new("Model"); bomb.Name = "PlantedBomb"
local light = mock.new("Part"); light.Name = "BombLight"; light.Transparency = 0.7; light.Parent = bomb
bomb.Parent = game.Workspace
RS:SetAttribute("Bomb_Attackers", "Rojo"); RS:SetAttribute("Bomb_State", "Planted"); RS:SetAttribute("Bomb_Site", "A"); RS:SetAttribute("Bomb_Timer", 3)
local BombHUD = req(game.StarterPlayer.Client.Modules.BombHUD)
BombHUD.Init()
task.wait(0.05)
BombHUD.Update()
local sounds = 0
for _, d in light:GetChildren() do if d.ClassName == "Sound" then sounds += 1 end end
check(sounds >= 1, "la bomba pita")
check(light.Transparency == 0, "y la luz se enciende")
print("PITIDO OK")
process.exit(0)
