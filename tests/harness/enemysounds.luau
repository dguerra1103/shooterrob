-- Sonidos de los demás: se oye a quien recarga cerca (y el tintineo de tus casquillos)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local camera = game.Workspace.CurrentCamera
camera.CFrame = CFrame.new(0, 5, 0)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local Sounds = req(game.ReplicatedStorage.Shared.Sounds)
local EnemySounds = req(game.StarterPlayer.Client.Modules.EnemySounds)
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local function bot(name, pos)
	local m = mock.new("Model"); m.Name = name
	local tool = mock.new("Tool"); tool:SetAttribute("Weapon", "ARX27"); tool:SetAttribute("Reloading", false)
	local handle = mock.new("Part"); handle.Name = "Handle"; handle.Position = pos; handle.CFrame = CFrame.new(pos); handle.Parent = tool
	tool.Parent = m
	m.Parent = bots
	return m, tool, handle
end
local _, nearTool, nearHandle = bot("Bot Cerca", Vector3.new(0, 5, -30))
local _, farTool, farHandle = bot("Bot Lejos", Vector3.new(0, 5, -300))
local function soundsIn(part, id)
	local n = 0
	for _, c in part:GetChildren() do
		if c:IsA("Sound") and c.SoundId == id then n += 1 end
	end
	return n
end
EnemySounds.Update(1)
check(soundsIn(nearHandle, Sounds.MagOut.Id) == 0, "sin recargar, nada")
nearTool:SetAttribute("Reloading", true)
farTool:SetAttribute("Reloading", true)
EnemySounds.Update(1)
check(soundsIn(nearHandle, Sounds.MagOut.Id) == 1, "el de cerca recarga: se oye su cargador")
check(soundsIn(farHandle, Sounds.MagOut.Id) == 0, "el de lejos, no")
EnemySounds.Update(1)
check(soundsIn(nearHandle, Sounds.MagOut.Id) == 1, "una vez por recarga")
task.wait(1.2)
check(soundsIn(nearHandle, Sounds.MagIn.Id) == 1, "y luego el cargador entrando")
nearTool:SetAttribute("Reloading", false)
EnemySounds.Update(1)
nearTool:SetAttribute("Reloading", true)
EnemySounds.Update(1)
check(soundsIn(nearHandle, Sounds.MagOut.Id) >= 1, "la siguiente recarga vuelve a sonar")
-- Casquillos: tintineo al caer
local Effects = req(game.StarterPlayer.Client.Modules.Effects)
local gun = mock.new("Part"); gun.CFrame = CFrame.new(0, 5, -2); gun.Parent = game.Workspace
local eject = mock.new("Attachment"); eject.Parent = gun
Effects.ShellCasing(eject, camera.CFrame)
task.wait(0.8)
local clinks = 0
for _, d in game.Workspace:GetDescendants() do
	if d:IsA("Sound") and d.SoundId == Sounds.Mech.Id then clinks += 1 end
end
check(clinks == 1, "el casquillo tintinea al caer")
print("SONIDOS DE LOS DEMAS OK")
process.exit(0)
