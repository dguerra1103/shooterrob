-- Noria de la Feria: la rueda gira en el cliente y las cabinas siguen derechas colgando de la rueda
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
-- (noria de prueba hecha a mano: los mapas actuales no tienen ninguna; WorldFX la sigue moviendo)
local V3, CF = roblox.Vector3, roblox.CFrame
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
local center = V3.new(0, 30, 0)
local cabins, rims = {}, {}
for i = 1, 7 do
	local a = i / 7 * math.pi * 2
	local anchor = center + V3.new(math.cos(a) * 12, math.sin(a) * 12, 0)
	local cabin = mock.new("Part"); cabin.Name = "WheelCabin"; cabin.Anchored = true
	cabin.Size = V3.new(2, 2, 2); cabin.CFrame = CF.new(anchor - V3.new(0, 2, 0))
	cabin:SetAttribute("Orbit", 20); cabin:SetAttribute("OrbitCenter", center); cabin:SetAttribute("OrbitAxis", V3.new(0, 0, 1))
	cabin:SetAttribute("OrbitUpright", true); cabin:SetAttribute("OrbitAnchor", anchor)
	cabin.Parent = map
	table.insert(cabins, cabin)
	local rim = mock.new("Part"); rim.Name = "WheelRim"; rim.Anchored = true
	rim.Size = V3.new(1, 1, 4); rim.CFrame = CF.lookAt(anchor, center)
	rim:SetAttribute("Orbit", 20); rim:SetAttribute("OrbitCenter", center); rim:SetAttribute("OrbitAxis", V3.new(0, 0, 1))
	rim.Parent = map
	table.insert(rims, rim)
end
check(#cabins == 7 and #rims == 7, "noria con 7 cabinas y 7 tramos")
local before = {}
for _, c in cabins do before[c] = c.CFrame end
local rimBefore = rims[1].CFrame
local WorldFX = req(game.StarterPlayer.Client.Modules.WorldFX)
WorldFX.Init()
local RunService = game:GetService("RunService")
task.wait(1)
RunService.RenderStepped:Fire(1 / 60)
RunService.RenderStepped:Fire(1 / 60)
local moved = 0
for _, c in cabins do
	local anchor = c:GetAttribute("OrbitAnchor")
	local offsetBefore = before[c].Position - anchor
	-- el enganche nuevo está a la misma distancia del centro
	local hang = c.Position - offsetBefore
	check(math.abs((hang - center).Magnitude - (anchor - center).Magnitude) < 0.05, "la cabina sigue en la rueda")
	check(c.CFrame.UpVector:Dot(before[c].UpVector) > 0.999 and c.Position.Y < hang.Y, "la cabina sigue derecha y colgando")
	if (c.Position - before[c].Position).Magnitude > 0.01 then moved += 1 end
end
check(moved == 7, "las cabinas se mueven")
local r = rims[1]
check(math.abs((r.Position - center).Magnitude - (rimBefore.Position - center).Magnitude) < 0.05 and r.CFrame.UpVector:Dot(rimBefore.UpVector) < 0.99999, "la rueda gira")
local axis = r:GetAttribute("OrbitAxis")
check(math.abs((r.Position - center):Dot(axis)) - math.abs((rimBefore.Position - center):Dot(axis)) < 0.05, "gira en su plano")
print("NORIA OK")
process.exit(0)
