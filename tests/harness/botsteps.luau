-- Pasos de los bots en el cliente: suenan al correr cerca, más fuerte los enemigos
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 5; me.Parent = Players
Players.LocalPlayer = me
local t1 = mock.new("Team"); t1.Name = "Rojo"; t1.Parent = Teams
me.Team = t1
RS:SetAttribute("TeamMode", true)
game.Workspace.CurrentCamera.CFrame = CFrame.new(0, 5, 0)
local folder = mock.new("Folder"); folder.Name = "Bots"; folder.Parent = game.Workspace
local function bot(name, team, pos, vel)
	local m = mock.new("Model"); m.Name = name; m:SetAttribute("Team", team)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local r = mock.new("Part"); r.Name = "HumanoidRootPart"; r.CFrame = CFrame.new(pos); r.AssemblyLinearVelocity = vel; r.Parent = m
	m.Parent = folder
	return m, r
end
local enemy, er = bot("Bot A", "Azul", Vector3.new(20, 3, 0), Vector3.new(18, 0, 0))
local ally, ar = bot("Bot B", "Rojo", Vector3.new(-20, 3, 0), Vector3.new(0, 0, 14))
local still, sr = bot("Bot C", "Azul", Vector3.new(0, 3, 20), Vector3.new(0, 0, 0))
local far, fr = bot("Bot D", "Azul", Vector3.new(400, 3, 0), Vector3.new(20, 0, 0))
local BotFootsteps = req(game.StarterPlayer.Client.Modules.BotFootsteps)
BotFootsteps.Update()
local se, sa = er:FindFirstChild("Pasos"), ar:FindFirstChild("Pasos")
check(se ~= nil and se.Looped, "el bot enemigo que corre lleva sonido de pasos")
check(sa ~= nil and sa.Volume < se.Volume, "el compañero suena más bajo que el enemigo")
check(se.PlaybackSpeed > sa.PlaybackSpeed, "corriendo más rápido, pasos más rápidos")
local sc = sr:FindFirstChild("Pasos")
check(sc == nil or not sc.IsPlaying, "quieto no suena")
check(fr:FindFirstChild("Pasos") == nil, "lejos no se crea sonido")
enemy:FindFirstChildOfClass("Humanoid").Health = 0
BotFootsteps.Update()
check(er:FindFirstChild("Pasos") == nil, "al morir se quita el sonido")
print("PASOS BOTS OK")
process.exit(0)
