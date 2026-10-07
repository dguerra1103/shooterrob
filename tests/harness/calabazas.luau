-- Modo Calabazas: el caído suelta una calabaza; el enemigo que la recoge suma, el compañero la niega
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
local GameConfig = req(RS.Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.MinPlayers = 1
GameConfig.Modes = { "CAL" }
GameConfig.Bots.Enabled = false
local M = game.ServerScriptService.Server.Modules
req(M.MapBuilder).Build()
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Round = req(M.Round)
local function makePlayer(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	return p
end
local a, b, c = makePlayer(41), makePlayer(42), makePlayer(43)
Round.Init()
local deadline = os.clock() + 10
while RS:GetAttribute("State") ~= "Playing" and os.clock() < deadline do task.wait(0.1) end
check(RS:GetAttribute("Mode") == "CAL" and RS:GetAttribute("State") == "Playing", "partida de Calabazas")
local function body(p, pos)
	local char = mock.new("Model"); char.Parent = game.Workspace
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(pos); root.Position = pos; root.Parent = char
	p.Character = char
	return root
end
-- a y c en un equipo, b en el otro
local teams = game:GetService("Teams"):GetChildren()
a.Team, c.Team, b.Team = teams[1], teams[1], teams[2]
local rootA = body(a, Vector3.new(60, 3, 60))
local rootB = body(b, Vector3.new(-60, 3, -60))
local rootC = body(c, Vector3.new(60, 3, -60))
local function pumpkins()
	local f = game.Workspace:FindFirstChild("Pumpkins")
	return f and #f:GetChildren() or 0
end
-- Suelo simulado a y = 0
local floor = mock.new("Part"); floor.Name = "Floor"; floor.Parent = game.Workspace.Map
local function floorRay(origin) return { Instance = floor, Position = Vector3.new(origin.X, 0, origin.Z), Normal = Vector3.new(0, 1, 0) } end
mock.raycastImpl = floorRay
local scoreA0 = RS:GetAttribute("Score_" .. teams[1].Name) or 0
Round.RegisterKill(a, b, b.Name, "ARX27", false, Vector3.new(10, 3, 10))
task.wait(0.2)
check(pumpkins() == 1, "b cae y suelta una calabaza")
check((RS:GetAttribute("Score_" .. teams[1].Name) or 0) == scoreA0, "la baja sola no suma")
rootA.Position = Vector3.new(11, 3, 10); rootA.CFrame = CFrame.new(rootA.Position)
task.wait(0.3)
check(pumpkins() == 0 and (RS:GetAttribute("Score_" .. teams[1].Name) or 0) == scoreA0 + 1, "a la recoge: punto para su equipo")
-- Negada por un compañero del caído
Round.RegisterKill(b, c, c.Name, "ARX27", false, Vector3.new(-20, 3, 0))
task.wait(0.2)
local scoreB0 = RS:GetAttribute("Score_" .. teams[2].Name) or 0
rootA.Position = Vector3.new(-20, 3, 1); rootA.CFrame = CFrame.new(rootA.Position)
task.wait(0.3)
check(pumpkins() == 0 and (RS:GetAttribute("Score_" .. teams[2].Name) or 0) == scoreB0, "un compañero de c la recupera: no puntúa nadie")
-- Caducan
Round.RegisterKill(a, b, b.Name, "ARX27", false, Vector3.new(0, 3, 40))
task.wait(0.2)
check(pumpkins() == 1, "otra calabaza")
-- Sobre lava no cae ninguna
local lava = mock.new("Part"); lava.Name = "Lava"; lava:SetAttribute("Hazard", "Lava"); lava.Parent = game.Workspace.Map
mock.raycastImpl = function(origin) return { Instance = lava, Position = Vector3.new(origin.X, 0, origin.Z), Normal = Vector3.new(0, 1, 0) } end
local before = pumpkins()
Round.RegisterKill(nil, b, b.Name, nil, false, Vector3.new(30, 3, 30))
task.wait(0.2)
check(pumpkins() == before, "sobre lava no se suelta calabaza")
mock.raycastImpl = nil
Round.RegisterKill(a, b, b.Name, "ARX27", false, Vector3.new(30, 3, -30))
task.wait(0.2)
check(pumpkins() == before, "sin suelo debajo (vacío) tampoco")
mock.raycastImpl = floorRay
_ = rootB; _ = rootC
print("CALABAZAS OK")
process.exit(0)
