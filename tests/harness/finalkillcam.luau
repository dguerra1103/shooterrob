-- Killcam final: la última baja de la partida/ronda, para todos (también si no eres ni el asesino ni la víctima)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local camera = game.Workspace.CurrentCamera
camera.ViewportSize = roblox.Vector2.new(1280, 720)
camera.FieldOfView = 80
camera.CFrame = CFrame.new(0, 50, 0)
local function character(name, pos, parent)
	local m = mock.new("Model"); m.Name = name
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local head = mock.new("Part"); head.Name = "Head"; head.Position = pos; head.CFrame = CFrame.new(pos); head.Parent = m
	m.Parent = parent or game.Workspace
	return m, head, h
end
local myChar = character("Yo", Vector3.new(0, 5, 80))
me.Character = myChar
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local killer, killerHead = character("Bot Max", Vector3.new(40, 5, 0), bots)
local victim, victimHead = character("Bot Leo", Vector3.new(0, 5, 0), bots)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local Remotes = req(game.ReplicatedStorage.Shared.Remotes)
local Killcam = req(game.StarterPlayer.Client.Modules.Killcam)
Killcam.Init()
for i = 1, 40 do
	killerHead.Position = Vector3.new(40, 5, i * 0.2)
	RunService.Heartbeat:Fire(0.05)
	task.wait(0.05)
end
Remotes.KillFeed.OnClientEvent:Fire({ Killer = "Bot Max", Victim = "Bot Leo", Weapon = "ARX-27" })
-- (el bot caído se quita del mapa antes de que llegue la final)
victim.Parent = nil
RunService.Heartbeat:Fire(0.05)
task.wait(0.06)
Remotes.FinalKillcam.OnClientEvent:Fire({ Killer = "Bot Max", Victim = "Bot Leo", Weapon = "ARX27" })
check(Killcam.Active() and ClientState.KillcamFinal == true, "empieza la killcam final para todos")
local step = mock.renderSteps.Killcam
step(1 / 60)
check(camera.CameraType == roblox.Enum.CameraType.Scriptable, "cámara de repetición")
local toVictim = (victimHead.Position - camera.CFrame.Position).Unit
check(camera.CFrame.LookVector:Dot(toVictim) > 0.95, "desde los ojos del que hizo la baja, mirando a su víctima (aunque ya no esté)")
local gui = pg:FindFirstChild("Killcam")
local title
for _, d in gui:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "▶ KILLCAM FINAL" then title = d end
end
check(title ~= nil and title.Parent.Visible, "con el cartel KILLCAM FINAL")
-- Un clic la salta y la cámara vuelve a donde estaba (sigues vivo)
UIS.InputBegan:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton1, KeyCode = roblox.Enum.KeyCode.Unknown }, false)
check(not Killcam.Active() and ClientState.KillcamFinal == false, "un clic la salta")
check((camera.CFrame.Position - Vector3.new(0, 50, 0)).Magnitude < 0.01 and camera.CameraType == roblox.Enum.CameraType.Custom, "y la cámara vuelve a donde estaba")
check(camera.FieldOfView == 80, "con su campo de visión")
-- Sin historia de esos nombres: nada
check(not Killcam.PlayFinal({ Killer = "Nadie", Victim = "Tampoco" }), "si no hay con qué, no hay killcam")
-- En la pantalla de inicio: nada
ClientState.InMainMenu = true
Remotes.FinalKillcam.OnClientEvent:Fire({ Killer = "Bot Max", Victim = "Bot Leo", Weapon = "ARX27" })
check(not Killcam.Active(), "en la pantalla de inicio no sale")
print("KILLCAM FINAL OK")
process.exit(0)
