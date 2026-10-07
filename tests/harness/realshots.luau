-- Fogonazo, trazadoras y humo del cañón realistas (y los de antes en mapas no realistas)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame, Color3 = roblox.Vector3, roblox.CFrame, roblox.Color3
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.EffectiveQuality = "Alta"
local Effects = req(game.StarterPlayer.Client.Modules.Effects)
local fx = game.Workspace:FindFirstChild("ClientFX")
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
map:SetAttribute("Realistic", true)

local function parts()
	local list = {}
	for _, d in fx:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "FXAnchor" and d.Transparency < 1 then table.insert(list, d) end
	end
	return list
end
local function clear()
	for _, d in fx:GetChildren() do
		if d.Name ~= "FXAnchor" then d.Parent = nil end
	end
end

-- Trazadoras: 1 de cada 3 brillante y cálida, las demás tenues
local from, to = Vector3.new(0, 5, 0), Vector3.new(0, 5, -200)
local bright, faint = 0, 0
for _ = 1, 6 do
	clear()
	Effects.Tracer(from, to, Color3.fromRGB(255, 0, 255))
	for _, p in parts() do
		if p.Size.Z > 1 and p.Size.X < 0.1 then
			if p.Transparency < 0.2 then bright += 1 else faint += 1 end
			check(p.Color.G > 0.6 and p.Color.B < 0.9, "color cálido (no el de la skin)")
		end
	end
end
check(bright == 2 and faint == 4, "una de cada tres brilla (" .. bright .. " brillantes, " .. faint .. " tenues)")

-- Fogonazo: lenguas de fuego que cambian en cada disparo, núcleo con luz y humo
local holder = mock.new("Part"); holder.Name = "Gun"; holder.CFrame = CFrame.new(0, 5, 0); holder.Parent = game.Workspace
local muzzle = mock.new("Attachment"); muzzle.Name = "Muzzle"; muzzle.Parent = holder
muzzle.WorldCFrame = CFrame.new(0, 5, -2)
muzzle.WorldPosition = Vector3.new(0, 5, -2)
local sizes = {}
for _ = 1, 8 do
	clear()
	Effects.MuzzleFlash(muzzle)
	local list = parts()
	check(#list >= 5 and #list <= 7, "fogonazo: 3-5 lenguas + llama + núcleo (" .. #list .. ")")
	local holder = fx:FindFirstChild("FlashLight")
	local light = holder and holder:FindFirstChildOfClass("PointLight")
	check(light ~= nil and light.Enabled == true, "golpe de luz")
	sizes[#list .. ":" .. math.floor(list[1].Size.Y * 100)] = true
end
local variety = 0
for _ in sizes do variety += 1 end
check(variety >= 3, "cada fogonazo distinto (" .. variety .. " formas)")
clear()
Effects.MuzzleFlash(muzzle, nil, true)
check(fx:FindFirstChild("FlashLight") == nil, "el de los demás, sin luz (más barato)")
-- Las piezas del fogonazo se reutilizan (no se crean nuevas en cada disparo)
local before = #fx:GetChildren()
-- (en tandas: el simulador se cuelga con cientos de temporizadores a la vez; en Roblox no pasa)
for _ = 1, 4 do
	for _ = 1, 10 do Effects.MuzzleFlash(muzzle) end
	task.wait(0.06)
end
local after40 = #fx:GetChildren()
for _ = 1, 4 do
	for _ = 1, 10 do Effects.MuzzleFlash(muzzle) end
	task.wait(0.06)
end
check(#fx:GetChildren() == after40 and after40 - before < 110, "los fogonazos reutilizan sus piezas: 40 más no añaden ninguna (" .. (after40 - before) .. " en total)")
local smoke = false
for _, d in fx:GetDescendants() do
	if d:IsA("ParticleEmitter") and d.Name == "" or (d:IsA("ParticleEmitter") and d.Texture:find("smoke")) then smoke = true end
end
check(smoke, "humo del disparo")

-- Humo del cañón
local emitter = Effects.BarrelSmoke(muzzle, 1)
check(emitter ~= nil and emitter.Parent == muzzle and emitter.Enabled == true, "tras la ráfaga, humo del cañón")
Effects.StopBarrelSmoke(muzzle)
check(emitter.Enabled == false, "al volver a disparar se corta")
Effects.BarrelSmoke(muzzle, 0)
check(emitter.Enabled == true and muzzle:FindFirstChild("BarrelSmoke") == emitter, "reutiliza el mismo emisor")
task.wait(1)
check(emitter.Enabled == false, "y se acaba solo")
ClientState.EffectiveQuality = "Baja"
check(Effects.BarrelSmoke(muzzle, 1) == nil, "en calidad Baja, sin humo del cañón")

-- Explosión: en mapa realista, ola de polvo en vez del anillo de neón
ClientState.EffectiveQuality = "Alta"
game.Workspace.CurrentCamera.CFrame = CFrame.new(0, 5, 0)
local function ringCount()
	local n = 0
	for _, d in fx:GetChildren() do
		if d:IsA("BasePart") and d.Shape == roblox.Enum.PartType.Cylinder and d.Size.Y > 10 then n += 1 end
	end
	return n
end
clear()
Effects.Explosion(Vector3.new(0, 5, -60), 14)
check(ringCount() == 0, "explosión realista: sin anillo de neón (ola de polvo)")
-- Mapa no realista: lo de antes
map:SetAttribute("Realistic", nil)
clear()
Effects.Explosion(Vector3.new(0, 5, -60), 14)
check(ringCount() == 1, "en mapas no realistas, el anillo de siempre")
clear()
Effects.Tracer(from, to, Color3.fromRGB(255, 0, 255))
local magenta = false
for _, p in parts() do
	if p.Color.R > 0.9 and p.Color.G < 0.1 and p.Color.B > 0.9 then magenta = true end
end
check(magenta, "en mapas no realistas, la trazadora con el color de la skin")
print("DISPAROS REALISTAS OK")
process.exit(0)
