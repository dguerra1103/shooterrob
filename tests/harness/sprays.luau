-- Grafitis: comprar, equipar y pintar (el servidor comprueba distancia, superficie y recarga)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Sprays = req(RS.Shared.Sprays)
local Shop = req(RS.Shared.Shop)
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Graffiti = req(M.Graffiti)
Graffiti.Init()
local Remotes = req(RS.Shared.Remotes)
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 8; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
me:SetAttribute("InMenu", false)
local char = mock.new("Model"); char.Parent = game.Workspace
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local head = mock.new("Part"); head.Name = "Head"; head.Position = Vector3.new(0, 5, 0); head.Parent = char
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(0, 3, 0); root.Parent = char
me.Character = char
local map = mock.new("Model"); map.Name = "Map"; map.Parent = game.Workspace
local wall = mock.new("Part"); wall.Name = "Wall"; wall.Anchored = true; wall.Transparency = 0; wall.Parent = map
-- Pared en z = -8: el rayo choca ahí
mock.raycastImpl = function(origin, direction)
	if direction.Z >= 0 then return nil end
	local t = (-8 - origin.Z) / direction.Z
	if t < 0 or t > 1 then return nil end
	return { Instance = wall, Position = origin + direction * t, Normal = Vector3.new(0, 0, 1) }
end

-- Comprar y equipar
for id, spray in Sprays.List do
	check(id == "Default" or spray.VIPOnly or (Shop.GetPrice("Spray", id) or 0) > 0, "precio de " .. id)
	_ = spray
end
data.Coins = 1000
local ok = Remotes.BuyItem.OnServerInvoke(me, "Spray", "Calabaza")
check(ok == true and data.Sprays.Calabaza and data.EquippedSpray == "Calabaza" and data.Coins == 1000 - Sprays.List.Calabaza.Price, "comprar grafiti lo equipa")
check(Remotes.BuyItem.OnServerInvoke(me, "Spray", "Calabaza") == false, "no se compra dos veces")
check(Remotes.BuyItem.OnServerInvoke(me, "Spray", "Diamante") == false, "sin monedas no se compra")
Remotes.EquipSpray.OnServerEvent:Fire(me, "Diamante")
check(data.EquippedSpray == "Calabaza", "no se equipa lo que no tienes")
Remotes.EquipSpray.OnServerEvent:Fire(me, "Default")
check(data.EquippedSpray == "Default", "equipar el de serie")
-- Grafiti VIP: no se vende y solo lo equipa quien es VIP
check(Remotes.BuyItem.OnServerInvoke(me, "Spray", "VIP") == false, "el de VIP no se vende")
Remotes.EquipSpray.OnServerEvent:Fire(me, "VIP")
check(data.EquippedSpray == "Default", "sin VIP no se equipa")
me:SetAttribute("VIP", true)
Remotes.EquipSpray.OnServerEvent:Fire(me, "VIP")
check(data.EquippedSpray == "VIP", "con VIP sí")
me:SetAttribute("VIP", nil)
Remotes.EquipSpray.OnServerEvent:Fire(me, "Calabaza")

-- Pintar
local function sprays()
	local n = 0
	for _, c in map:GetChildren() do
		if string.find(c.Name, "^Spray_") then n += 1 end
	end
	return n
end
check(Graffiti.Paint(me, Vector3.new(0, 5, -60)) == false, "demasiado lejos: no")
check(Graffiti.Paint(me, Vector3.new(0 / 0, 5, -8)) == false, "punto NaN: no")
task.wait(0.3)
check(Graffiti.Paint(me, Vector3.new(0, 5, -8)) == true and sprays() == 1, "pinta en la pared")
local part = map:FindFirstChild("Spray_8")
check(part.Anchored and not part.CanCollide and not part.CanQuery, "el grafiti no estorba")
local look = part.CFrame.LookVector
check(look.Z > 0.99, "mira hacia fuera de la pared")
local gui = part:FindFirstChildOfClass("SurfaceGui")
local text = gui and gui:FindFirstChild("Spray", true)
check(text ~= nil, "dibujo en la pared")
check(Graffiti.Paint(me, Vector3.new(1, 5, -8)) == false, "recarga entre grafitis")
task.wait(Sprays.Cooldown + 0.1)
check(Graffiti.Paint(me, Vector3.new(1, 5, -8)) == true and sprays() == 1, "el nuevo sustituye al anterior")
task.wait(Sprays.Cooldown + 0.1)
check(Graffiti.Paint(me, Vector3.new(0, 5, -4.5)) == false, "el punto debe ser la pared de verdad")
task.wait(0.3)
wall.Anchored = false
check(Graffiti.Paint(me, Vector3.new(0, 5, -8)) == false, "no se pinta en cosas que se mueven")
wall.Anchored = true
task.wait(0.3)
check(Graffiti.Paint(me, Vector3.new(0, 5, -8)) == true, "tras el freno vuelve a pintar")
task.wait(Sprays.Cooldown + 0.1)
check(Graffiti.Paint(me, Vector3.new(0, 5, -8)) == true and Graffiti.Paint(me, Vector3.new(0, 5, -8)) == false, "freno a peticiones seguidas")
task.wait(Sprays.Cooldown + 0.1)
hum.Health = 0
check(Graffiti.Paint(me, Vector3.new(0, 5, -8)) == false, "muerto no se pinta")
print("GRAFITIS OK")
process.exit(0)
