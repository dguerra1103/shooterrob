-- Killcam: al morir, repetición desde los ojos del que te eliminó y luego a observar
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
mock.policyInfo = { ArePaidRandomItemsRestricted = false }
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game.ReplicatedStorage
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local camera = game.Workspace.CurrentCamera
camera.ViewportSize = roblox.Vector2.new(1280, 720)
camera.FieldOfView = 80
local function character(name, pos, parent)
	local m = mock.new("Model"); m.Name = name
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local head = mock.new("Part"); head.Name = "Head"; head.Position = pos; head.CFrame = CFrame.new(pos); head.Parent = m
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Position = pos; root.CFrame = CFrame.new(pos); root.Parent = m
	m.Parent = parent or game.Workspace
	return m, head, h
end
local myChar, myHead, myHum = character("Yo", Vector3.new(0, 5, 0))
me.Character = myChar
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local killer, killerHead = character("Bot Max", Vector3.new(40, 5, 0), bots)
killer:SetAttribute("Bot", true)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local Remotes = req(RS.Shared.Remotes)
local Killcam = req(game.StarterPlayer.Client.Modules.Killcam)
Killcam.Init()
local DeathScreen = req(game.StarterPlayer.Client.Modules.DeathScreen)
DeathScreen.Init()
-- 2 s de partida: el bot se mueve
for i = 1, 40 do
	killerHead.Position = Vector3.new(40, 5, i * 0.2)
	RunService.Heartbeat:Fire(0.05)
	task.wait(0.05)
end
myHead.LocalTransparencyModifier = 1 -- (primera persona: tu cuerpo es invisible para ti)
myHum.Health = 0
Remotes.Died.OnClientEvent:Fire("Bot Max", "ARX27", 80)
task.wait(0.1)
local steps = mock.renderSteps or {}
local stepKillcam = steps.Killcam
check(stepKillcam ~= nil, "empieza la killcam")
stepKillcam(1 / 60)
check(camera.CameraType == roblox.Enum.CameraType.Scriptable, "cámara de repetición")
local look = camera.CFrame.LookVector
local toMe = (myHead.Position - camera.CFrame.Position).Unit
check(look:Dot(toMe) > 0.95, "desde los ojos del bot, mirando hacia ti")
check((camera.CFrame.Position - killerHead.Position).Magnitude < 12, "la cámara está donde estaba el bot")
local gui = pg:FindFirstChild("Killcam")
local banner
for _, d in gui:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "▶ KILLCAM" then banner = d end
end
check(banner ~= nil and banner.Parent.Visible, "con el cartel KILLCAM")
local nameLabel
for _, d in gui:GetDescendants() do
	if d.__className == "TextLabel" and type(d.Text) == "string" and string.find(d.Text, "Bot Max", 1, true) then nameLabel = d end
end
check(nameLabel ~= nil and string.find(nameLabel.Text, "ARX", 1, true) ~= nil, "dice quién y con qué arma (" .. tostring(nameLabel and nameLabel.Text) .. ")")
check(myHead.LocalTransparencyModifier == 0, "tu cuerpo se ve en la repetición")
check(killerHead.LocalTransparencyModifier == 1, "el del bot no (la cámara está en su cabeza)")
check(ClientState.KillcamActive == true, "el HUD sabe que hay killcam (oculta su «ELIMINADO POR»)")
-- Al acabar, a observar al bot como siempre
task.wait(3.2)
stepKillcam(1 / 60)
check(camera.CameraType == roblox.Enum.CameraType.Custom, "al acabar, la cámara vuelve")
check(not banner.Parent.Visible and camera.FieldOfView == 80, "sin cartel y con el campo de visión de antes")
check(killerHead.LocalTransparencyModifier == 0 and ClientState.KillcamActive == false, "y el bot se vuelve a ver")

-- Nueva vida y otra muerte
local DeathScreen = req(game.StarterPlayer.Client.Modules.DeathScreen)
local function dieAgain(weapon)
	local char, head, hum = character("Yo", Vector3.new(0, 5, 0))
	me.Character = char
	me.CharacterAdded:Fire(char)
	myChar, myHead, myHum = char, head, hum
	task.wait(0.05)
	for i = 1, 30 do
		killerHead.Position = Vector3.new(40, 5, i * 0.2)
		RunService.Heartbeat:Fire(0.05)
		task.wait(0.05)
	end
	myHum.Health = 0
	Remotes.Died.OnClientEvent:Fire("Bot Max", weapon, 80)
	task.wait(0.1)
	return DeathScreen.KillcamActive()
end
-- En el móvil, tocar la pantalla la salta
check(dieAgain("ARX27"), "otra muerte, otra killcam")
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Fire({ UserInputType = roblox.Enum.UserInputType.Touch, KeyCode = roblox.Enum.KeyCode.Unknown }, false)
check(not DeathScreen.KillcamActive(), "en el móvil, un toque la salta")
-- Con granada o ataque aéreo, no (el que te eliminó ni te veía)
check(not dieAgain("Grenade"), "con granada, sin killcam")
check(not dieAgain("Airstrike"), "con ataque aéreo, sin killcam")
-- Sin línea de visión al morir (pared en medio), no
local wall = mock.new("Part"); wall.Transparency = 0; wall.Parent = game.Workspace
mock.raycastImpl = function(origin, direction)
	return { Instance = wall, Position = origin + direction * 0.5, Normal = Vector3.new(1, 0, 0), Distance = direction.Magnitude * 0.5, Material = roblox.Enum.Material.Concrete }
end
check(not dieAgain("ARX27"), "con una pared en medio, sin killcam")
-- Un cristal en medio sí deja verla
wall.Transparency = 0.6
local glassOnce = false
mock.raycastImpl = function(origin, direction, params)
	for _, item in (params and params.FilterDescendantsInstances or {}) do
		if item == wall then return nil end
	end
	return { Instance = wall, Position = origin + direction * 0.5, Normal = Vector3.new(1, 0, 0), Distance = direction.Magnitude * 0.5, Material = roblox.Enum.Material.Glass }
end
check(dieAgain("ARX27"), "a través de un cristal, sí")
mock.raycastImpl = nil
-- En los modos de una sola vida, nunca (enseñaría dónde está el enemigo en directo)
RS:SetAttribute("NoRespawn", true)
check(not dieAgain("ARX27"), "en Eliminación / Buscar y destruir, sin killcam")
RS:SetAttribute("NoRespawn", nil)
print("KILLCAM OK")
process.exit(0)
