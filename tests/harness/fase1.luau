-- Fase 1 (estabilidad): disparos con NaN rechazados sin error y límite de peticiones de equipamiento
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local Remotes = req(Shared.Remotes)
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Combat = req(M.Combat)
Combat.Init()
local Loadout = req(M.Loadout)
local warnings = {}
mock.onWarn = function(...)
	table.insert(warnings, table.concat({ ... }, " "))
end
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end

local p = mock.new("Player"); p.Name = "P"; p.UserId = 7; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
check(data ~= nil, "perfil cargado")

-- Personaje con cabeza y un muñeco enemigo delante
local char = mock.new("Model"); char.Name = "P"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local head = mock.new("Part"); head.Name = "Head"; head.Position = Vector3.new(0, 5, 0); head.Parent = char
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0); root.Parent = char
char.Parent = game.Workspace
p.Character = char
local tool = Loadout.MakeTool("ARX27", "Default"); tool.Parent = char
tool:SetAttribute("Ammo", 30)
local dummy = mock.new("Model"); dummy.Name = "Dummy"
local dh = mock.new("Humanoid"); dh.Health = 100; dh.MaxHealth = 100; dh.Parent = dummy
local dtorso = mock.new("Part"); dtorso.Name = "UpperTorso"; dtorso.Position = Vector3.new(0, 5, -20); dtorso.Size = Vector3.new(2, 2, 1); dtorso.Parent = dummy
dummy.Parent = game.Workspace

local origin = Vector3.new(0, 5, -0.5)
local nan = 0 / 0
-- 1) Disparo válido: hace daño (comprueba que la prueba está bien montada)
Remotes.Fire.OnServerEvent:Fire(p, tool, origin, { { Position = dtorso.Position, Part = dtorso } })
task.wait(0.3)
check(dh.Health < 100, "un disparo válido hace daño (vida " .. dh.Health .. ")")
local healthAfter = dh.Health
local ammoAfter = tool:GetAttribute("Ammo")

-- 2) Origen con NaN: se rechaza (no gasta munición, no hace daño, no da error)
Remotes.Fire.OnServerEvent:Fire(p, tool, Vector3.new(nan, 5, 0), { { Position = dtorso.Position, Part = dtorso } })
task.wait(0.3)
check(tool:GetAttribute("Ammo") == ammoAfter and dh.Health == healthAfter, "origen NaN rechazado")

-- 3) Origen infinito: rechazado
Remotes.Fire.OnServerEvent:Fire(p, tool, Vector3.new(math.huge, 5, 0), { { Position = dtorso.Position, Part = dtorso } })
task.wait(0.3)
check(tool:GetAttribute("Ammo") == ammoAfter and dh.Health == healthAfter, "origen infinito rechazado")

-- 4) Impacto con NaN: el rayo no cuenta (no hace daño)
Remotes.Fire.OnServerEvent:Fire(p, tool, origin, { { Position = Vector3.new(nan, nan, nan), Part = dtorso } })
task.wait(0.3)
check(dh.Health == healthAfter, "impacto NaN no hace daño")

-- 5) Límite de peticiones: 60 cambios de arma seguidos no producen 60 DataUpdate
data.Level = 50
local function updates()
	local n = 0
	for _, sent in mock.sent do
		if sent.Remote == "DataUpdate" then n += 1 end
	end
	return n
end
local before = updates()
for i = 1, 60 do
	Remotes.SetMelee.OnServerEvent:Fire(p, i % 2 == 0 and "Katana" or "Knife")
end
local burst = updates() - before
check(burst >= 15 and burst <= 22, "ráfaga limitada (" .. burst .. " de 60 aceptadas)")
-- ... y unas pocas seguidas (EQUIPAR TODO de un paquete) pasan todas tras recuperar fichas
task.wait(2)
before = updates()
for i = 1, 6 do
	Remotes.SetMelee.OnServerEvent:Fire(p, i % 2 == 0 and "Katana" or "Knife")
end
check(updates() - before == 6, "6 peticiones seguidas tras una pausa pasan todas")

for _, w in warnings do
	check(not string.find(w, "Stack Begin", 1, true), "sin trazas de error: " .. w)
end
print("FASE1 OK")
process.exit(0)
