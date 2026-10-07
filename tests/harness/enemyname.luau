-- Nombre del enemigo al que apuntas
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 3; me.Parent = Players
Players.LocalPlayer = me
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
local red = mock.new("Team"); red.Name = "Rojo"; red.Parent = Teams
me.Team = red
RS:SetAttribute("TeamMode", true)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local function bot(name, team)
	local m = mock.new("Model"); m.Name = name; m:SetAttribute("Bot", true); m:SetAttribute("Team", team)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local head = mock.new("Part"); head.Name = "Head"; head.Parent = m
	m.Parent = game.Workspace
	return m, head
end
local enemy, enemyHead = bot("Bot Max", "Azul")
local mate, mateHead = bot("Bot Leo", "Rojo")
local aim = enemyHead
mock.raycastImpl = function(origin, direction)
	if not aim then return nil end
	return { Instance = aim, Position = origin + direction.Unit * 20, Normal = roblox.Vector3.new(0, 0, 1), Distance = 20, Material = roblox.Enum.Material.Plastic }
end
game.Workspace.CurrentCamera.CFrame = roblox.CFrame.new(0, 5, 0)
local EN = req(game.StarterPlayer.Client.Modules.EnemyName)
EN.Init()
local board = pg:FindFirstChild("EnemyName")
EN.Update()
check(board.Enabled and board:FindFirstChildOfClass("TextLabel").Text == "Bot Max", "apuntando a un enemigo sale su nombre")
aim = mateHead
task.wait(0.5)
EN.Update()
check(not board.Enabled, "a un compañero no (ya lleva su nombre) y se va al dejar de apuntar")
aim = nil
EN.Update()
check(not board.Enabled, "sin nadie en la mira, nada")
print("NOMBRE ENEMIGO OK")
process.exit(0)
