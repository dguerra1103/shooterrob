local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.Event.SpawnEvery = 0.2
GameConfig.Event.Goal = 3
GameConfig.Event.Milestones = { { Count = 1, Coins = 10 }, { Count = 2, Outfit = "Calabaza", Compensate = 400 } }
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local MapBuilder = req(M.MapBuilder)
local Event = req(M.Event)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local roblox = require("@lune/roblox")
local ground = mock.new("Part")
mock.raycastImpl = function(origin, direction)
	local target = origin + direction
	if origin.Y >= 0 and target.Y <= 0 then
		return { Position = roblox.Vector3.new(origin.X, 0, origin.Z), Instance = ground, Normal = roblox.Vector3.new(0, 1, 0) }
	end
	return nil
end
MapBuilder.Build("Construction")
local pumpkins = 0
for _, d in game.Workspace.Map:GetDescendants() do
	if d.Name == "Pumpkin" then pumpkins += 1 end
end
check(pumpkins >= 3, "calabazas en el mapa (" .. pumpkins .. ")")
Event.Init()
local RS = game.ReplicatedStorage
RS:SetAttribute("State", "Playing")
task.wait(1.5)
local folder = game.Workspace.EventCandies
check(#folder:GetChildren() >= 3 and #folder:GetChildren() <= GameConfig.Event.MaxCandies, "aparecen caramelos (" .. #folder:GetChildren() .. ")")
local p = mock.new("Player"); p.Name = "P"; p.UserId = 9; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
local coins = data.Coins
local char = mock.new("Model"); char.Name = "P"
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = char
char.Parent = game.Workspace
p.Character = char
local far = folder:GetChildren()[1]
root.Position = far.Position + roblox.Vector3.new(50, 0, 0)
Event.Collect(p, far)
check(data.EventProgress.Count == 0 and far.Parent ~= nil, "desde lejos no se puede coger")
for i = 1, 3 do
	local candy = folder:GetChildren()[1]
	root.Position = candy.Position
	Event.Collect(p, candy)
	task.wait(0.3)
end
check(data.EventProgress.Count == 3 and data.Coins == coins + 25, "3 caramelos: +15 monedas, +10 del premio (sin VIP) y contador 3 (" .. data.Coins - coins .. ")")
check(data.Outfits.Calabaza == true, "premio intermedio: traje Calabaza")
check(data.Skins.Embrujada == true, "al llegar al objetivo se gana la skin Embrujada")
RS:SetAttribute("State", "Intermission")
check(#folder:GetChildren() == 0, "al acabar la ronda se quitan los caramelos")
-- Premio añadido con el evento ya empezado: se da en el siguiente caramelo, una sola vez
GameConfig.Event.Goal = 10
GameConfig.Event.Milestones = { { Count = 1, Coins = 10 }, { Count = 2, Outfit = "Calabaza", Compensate = 400 }, { Count = 3, Coins = 50 } }
RS:SetAttribute("State", "Playing")
task.wait(1)
local before = data.Coins
for i = 1, 2 do
	local candy = folder:GetChildren()[1]
	root.Position = candy.Position
	Event.Collect(p, candy)
	task.wait(0.3)
end
check(data.EventProgress.Count == 5 and data.Coins == before + 10 + 50, "premio atrasado (3) se da una vez; el traje repetido no se paga otra vez (" .. data.Coins - before .. ")")
-- Premio de arma añadido donde antes había monedas ya cobradas: también se da
GameConfig.Event.Milestones = { { Count = 3, Weapon = "Calabazooka", Compensate = 50 } }
data.EventProgress.Claimed.m3 = true
RS:SetAttribute("State", "Playing")
task.wait(1)
local candy = folder:GetChildren()[1]
root.Position = candy.Position
Event.Collect(p, candy)
check(data.OwnedWeapons.Calabazooka == true, "el arma del evento se da aunque ya se cobraran las monedas de ese premio")
-- Recompensa diaria durante el evento: regala objetos del evento
local countBefore = data.EventProgress.Count
data.LastDailyDay = -5
local Remotes = req(Shared.Remotes)
local okDaily = Remotes.ClaimDaily.OnServerInvoke(p)
task.wait(0.2)
check(okDaily and data.EventProgress.Count == countBefore + Event.DailyBonus, "la recompensa diaria regala " .. Event.DailyBonus .. " del evento (" .. countBefore .. " -> " .. data.EventProgress.Count .. ")")
print("EVENTO OK")
process.exit(0)
