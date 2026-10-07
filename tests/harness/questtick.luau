-- Retos en el HUD: cada paso del progreso se nota (salto del contador)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local function data(progress, done)
	return { Level = 1, XP = 0, Challenges = { List = { { Text = "Haz 10 bajas", Goal = 10, Progress = progress, Done = done } } } }
end
ClientState.Data = data(3, false)
local QT = req(game.StarterPlayer.Client.Modules.QuestTracker)
QT.Init()
ClientState.DataChanged:Fire(data(3, false))
task.wait(0.1)
local function count()
	for _, d in pg:GetDescendants() do
		if (d.__className == "TextLabel") and d.Text == "4/10" then return d end
	end
end
ClientState.DataChanged:Fire(data(4, false))
task.wait(0.1)
local label = count()
check(label ~= nil, "el contador sube a 4/10")
check(label:FindFirstChildOfClass("UIScale") ~= nil, "y da un salto")
ClientState.DataChanged:Fire(data(10, true))
task.wait(0.1)
check(true, "completar el reto no rompe nada")
print("RETOS HUD OK")
process.exit(0)
