-- Botín: paquetes con rayo de luz que suelta a veces el enemigo eliminado
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local Remotes = req(RS.Shared.Remotes)
_ = Remotes
local function lastNote()
	for i = #mock.sent, 1, -1 do
		local m = mock.sent[i]
		if m.Remote == "Notify" then return m.Args[1], m.Args[2] end
	end
end
local Loot = req(game.ServerScriptService.Server.Modules.Loot)
local function newPlayer(name, id, pos)
	local p = mock.new("Player"); p.Name = name; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	local char = mock.new("Model"); char.Parent = game.Workspace
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Position = pos; root.CFrame = CFrame.new(pos); root.Parent = char
	p.Character = char
	return p, root, PlayerData.WaitFor(p, 3)
end
local me, myRoot, data = newPlayer("Yo", 1, Vector3.new(50, 3, 0))
local other, otherRoot = newPlayer("Otro", 2, Vector3.new(0, 3, 0))
mock.raycastImpl = function(origin)
	return { Position = Vector3.new(origin.X, 0, origin.Z), Normal = Vector3.new(0, 1, 0), Instance = game.Workspace, Distance = 2, Material = roblox.Enum.Material.Plastic }
end
-- Rarezas: los pesos suman y la tirada cae en cada una
check(Loot.RollTier(0).Name == "Común" and Loot.RollTier(0.999).Name == "Legendario", "las tiradas cubren de Común a Legendario")
local counts = {}
for _ = 1, 4000 do local t = Loot.RollTier(); counts[t.Name] = (counts[t.Name] or 0) + 1 end
check(counts["Común"] > counts["Raro"] and counts["Raro"] > counts["Épico"] and counts["Épico"] > (counts["Legendario"] or 0), "lo común sale más que lo raro")
-- Sin suerte: nada
check(Loot.MaybeDrop(Vector3.new(0, 3, 0), me, false, 0.99) == nil, "sin suerte no suelta nada")
check(Loot.MaybeDrop(Vector3.new(0, 3, 0), nil, false, 0) == nil, "sin jugador que lo gane, nada")
-- Con suerte: paquete en el suelo con rayo de luz, solo para quien hizo la baja
local model, tier = Loot.MaybeDrop(Vector3.new(0, 3, 0), me, false, 0)
check(model ~= nil and model.Parent and model.Parent.Name == "Loot", "con suerte suelta un paquete")
check(model:FindFirstChild("LootBeam") ~= nil and model:FindFirstChild("LootBox") ~= nil, "con su rayo de luz")
check(lastNote() == "LootDrop", "avisa a quien lo ha ganado")
-- Otro jugador encima: no lo coge
Loot.Step()
check(model.Parent ~= nil, "otro jugador no puede cogerlo")
-- El dueño pasa por encima: monedas
local coins0 = data.Coins
myRoot.Position = Vector3.new(1, 3, 0)
Loot.Step()
check(model.Parent == nil, "el dueño lo recoge al pasar por encima")
check(data.Coins > coins0, "y le da monedas (+" .. (data.Coins - coins0) .. ")")
local kind, info = lastNote()
check(kind == "Loot" and type(info) == "table" and info.Rarity == tier.Name, "con aviso de la rareza")
-- Caduca
local m2 = Loot.MaybeDrop(Vector3.new(100, 3, 0), me, true, 0)
check(m2 ~= nil and Loot.Active[#Loot.Active].Scale == 0.5, "contra bots también, con el premio a la mitad")
Loot.LIFETIME = 0
local m3 = Loot.MaybeDrop(Vector3.new(200, 3, 0), me, false, 0)
Loot.Step()
check(m3.Parent == nil, "desaparece si no se recoge a tiempo")
Loot.Clear()
check(m2.Parent == nil and #Loot.Active == 0, "al acabar la partida se limpia todo")
-- Sin suelo (vacío o lava): nada
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
mock.raycastImpl = function() return nil end
check(Loot.MaybeDrop(Vector3.new(0, 3, 0), me, false, 0) == nil, "si cae al vacío, no hay botín")
print("BOTÍN OK")
process.exit(0)
