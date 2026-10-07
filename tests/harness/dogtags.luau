-- Fuera de Halloween el modo Calabazas es "Baja confirmada" con placas; en Halloween, calabazas
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local Pumpkins = req(game.ServerScriptService.Server.Modules.Pumpkins)
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local function icon()
	local folder = game.Workspace:FindFirstChild("Pumpkins")
	for _, d in folder:GetDescendants() do
		if d.ClassName == "TextLabel" then return d.Text end
	end
end
local team = mock.new("Team"); team.Name = "Rojo"; team.TeamColor = roblox.BrickColor.new("Bright red"); team.Parent = game:GetService("Teams")
mock.raycastImpl = function(origin, direction)
	return { Position = roblox.Vector3.new(origin.X, 0, origin.Z), Normal = roblox.Vector3.new(0, 1, 0), Instance = game.Workspace, Distance = origin.Y, Material = roblox.Enum.Material.Plastic }
end
RS:SetAttribute("EventName", nil)
Pumpkins.Start()
check(Pumpkins.Tags(), "sin evento: placas")
Pumpkins.Drop(roblox.Vector3.new(0, 3, 0), team, 1, false)
check(icon() == "🏷️", "la placa sale con 🏷️")
Pumpkins.Stop()
RS:SetAttribute("EventName", "Halloween")
Pumpkins.Start()
check(not Pumpkins.Tags(), "en Halloween: calabazas")
Pumpkins.Drop(roblox.Vector3.new(0, 3, 0), team, 1, false)
check(icon() == "🎃", "la calabaza sale con 🎃")
Pumpkins.Stop()
print("PLACAS OK")
process.exit(0)
