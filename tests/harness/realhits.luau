-- Impactos y bajas realistas en mapas realistas (y los de antes en los demás)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local Effects = req(game.StarterPlayer.Client.Modules.Effects)
local fx = game.Workspace:FindFirstChild("ClientFX")
local function emitters()
	local names = {}
	for _, d in fx:GetDescendants() do
		if d.ClassName == "ParticleEmitter" or d.__className == "ParticleEmitter" then names[d.Name] = true end
		if (d.ClassName == "Part" or d.__className == "Part") and d.Shape == roblox.Enum.PartType.Ball then names.Ball = true end
	end
	return names
end
local enemy = mock.new("Model"); enemy.Parent = game.Workspace
local hum = mock.new("Humanoid"); hum.Parent = enemy
local torso = mock.new("Part"); torso.Name = "UpperTorso"; torso.Parent = enemy
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
map:SetAttribute("Realistic", true)
local ok, err = pcall(Effects.Impact, roblox.Vector3.new(0, 3, 0), roblox.Vector3.new(0, 0, 1), torso, roblox.Enum.Material.Plastic)
check(ok, "impacto en persona sin errores " .. tostring(err))
-- ¿Hay algún emisor rojo (sangre)?
local function bloodEmitters()
	local n = 0
	for _, d in fx:GetDescendants() do
		if (d.ClassName == "ParticleEmitter" or d.__className == "ParticleEmitter") and typeof(d.Color) == "ColorSequence" then
			local c = d.Color.Keypoints[1].Value
			if c.R > 0.3 and c.G < 0.15 and c.B < 0.15 then n += 1 end
		end
	end
	return n
end
check(bloodEmitters() == 0, "sin sangre por defecto: polvo y fibras de la ropa")
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
GameConfig.RealisticBlood = true
Effects.Impact(roblox.Vector3.new(0, 3, 0), roblox.Vector3.new(0, 0, 1), torso, roblox.Enum.Material.Plastic)
check(bloodEmitters() > 0, "con RealisticBlood = true, la nube roja")
for _, d in fx:GetChildren() do d.Parent = nil end
GameConfig.RealisticBlood = false
local ok2, err2 = pcall(Effects.KillEffect, "Default", roblox.Vector3.new(0, 3, 0), roblox.Color3.new(1, 0, 0))
check(ok2, "baja normal sin errores " .. tostring(err2))
local names = emitters()
check(not names.Ball, "en mapa realista no hay bola de destello de colores")
map:SetAttribute("Realistic", nil)
pcall(Effects.KillEffect, "Default", roblox.Vector3.new(0, 3, 0), roblox.Color3.new(1, 0, 0))
names = emitters()
check(names.Ball, "en mapas no realistas, el estallido de siempre")
print("IMPACTOS REALISTAS OK")
process.exit(0)
