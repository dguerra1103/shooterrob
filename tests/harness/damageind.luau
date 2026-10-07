-- Indicador de daño: marca hacia el atacante (jugador o bot) que se desvanece
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
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local camera = game.Workspace.CurrentCamera
camera.CFrame = CFrame.new(0, 5, 0) -- mira hacia -Z
local function character(pos)
	local char = mock.new("Model"); char.Parent = game.Workspace
	local hum = mock.new("Humanoid"); hum.Name = "Humanoid"; hum.Health = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(pos); root.Position = pos; root.Parent = char
	return char, hum
end
local myChar, myHum = character(Vector3.new(0, 3, 0))
me.Character = myChar
local enemy = mock.new("Player"); enemy.Name = "Enemigo"; enemy.UserId = 2; enemy.Parent = Players
table.insert(mock.players, enemy)
enemy.Character = character(Vector3.new(50, 3, 0)) -- a la derecha
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local botChar = character(Vector3.new(0, 3, 60)) -- detrás
botChar.Name = "Bot Max"; botChar.Parent = bots

local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
ClientState.Dead = false
local DamageIndicator = req(game.StarterPlayer.Client.Modules.DamageIndicator)
DamageIndicator.Init()
task.wait(0.05)
local gui = pg:FindFirstChild("DamageIndicator")
check(gui ~= nil, "interfaz creada")
local function marks()
	local list = {}
	for _, d in gui:GetDescendants() do
		if d.__className == "Frame" and d.Size and d.Size.X.Offset == 110 then table.insert(list, d) end
	end
	return list
end
local function step() RunService.RenderStepped:Fire(1 / 60) end
myHum:SetAttribute("LastAttacker", 2)
myHum:SetAttribute("LastHitTime", 1)
step()
local m = marks()
check(#m == 1, "una marca al recibir un disparo")
check(math.abs(m[1].Rotation - 90) < 1 and m[1].Position.X.Offset > 140, "apunta a la derecha (" .. m[1].Rotation .. ")")
myHum:SetAttribute("LastHitTime", 2)
step()
check(#marks() == 1, "el mismo atacante no duplica la marca")
myHum:SetAttribute("LastAttacker", nil)
myHum:SetAttribute("LastBot", "Bot Max")
myHum:SetAttribute("LastHitTime", 3)
step()
m = marks()
check(#m == 2, "otra marca para el bot")
local botMark
for _, f in m do if math.abs(math.abs(f.Rotation) - 180) < 1 then botMark = f end end
check(botMark ~= nil, "la del bot apunta hacia atrás")
myHum:SetAttribute("LastBot", nil)
myHum:SetAttribute("LastAttacker", 1)
myHum:SetAttribute("LastHitTime", 4)
step()
check(#marks() == 2, "tu propio cohete no marca")
task.wait(1.5)
step()
check(#marks() == 0, "se desvanecen")
local ff = mock.new("ForceField"); ff.Parent = myChar
myHum:SetAttribute("LastAttacker", 2)
myHum:SetAttribute("LastHitTime", 5)
step()
check(#marks() == 0, "con escudo no hay marca")
ff.Parent = nil
ClientState.InMainMenu = true
myHum:SetAttribute("LastHitTime", 6)
step()
check(#marks() == 0, "en la pantalla de inicio no hay marca")
print("INDICADOR OK")
process.exit(0)
