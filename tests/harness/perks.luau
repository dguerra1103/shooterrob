-- Ventajas: Persistente (regenera antes), Fantasma (los bots le oyen menos)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local M = game.ServerScriptService.Server.Modules
local HealthRegen = req(M.HealthRegen)
local Combat = req(M.Combat)
local Players = game:GetService("Players")
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local function player(name, id, perk)
	local p = mock.new("Player"); p.Name, p.UserId = name, id; p.Parent = Players; table.insert(mock.players, p)
	p:SetAttribute("Perk", perk)
	local char = mock.new("Model"); char.Name = name
	local hum = mock.new("Humanoid"); hum.MaxHealth = 100; hum.Health = 40; hum.Parent = char
	char.Parent = game.Workspace; p.Character = char
	return p, char, hum
end
local _, _, normal = player("Normal", 1, 0)
local _, _, tough = player("Duro", 2, 2)
local _, ghostChar = player("Fantasma", 3, 3)
local _, loudChar = player("Ruidoso", 4, 0)
local t = os.clock()
normal:SetAttribute("LastHitTime", t - 3)
tough:SetAttribute("LastHitTime", t - 3)
HealthRegen.Init()
task.wait(0.6)
check(normal.Health == 40, "sin ventaja: a los 3 s aún no se recupera")
check(tough.Health > 40, "Persistente: a los 3 s ya se recupera (" .. tough.Health .. ")")
Combat.ReportNoise(roblox.Vector3.new(0, 0, 0), nil, ghostChar, "ARX27")
local ghostRange = Combat.Noise[#Combat.Noise].Range
Combat.ReportNoise(roblox.Vector3.new(0, 0, 0), nil, loudChar, "ARX27")
local loudRange = Combat.Noise[#Combat.Noise].Range
check(ghostRange < loudRange, "Fantasma: sus disparos se oyen la mitad de lejos (" .. ghostRange .. " vs " .. loudRange .. ")")
print("VENTAJAS OK")
process.exit(0)
