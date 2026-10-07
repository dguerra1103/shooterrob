-- Fase 2: instrumentación de impactos (GameConfig.HitTelemetry). Solo mide: con ella encendida o
-- apagada, los mismos disparos hacen exactamente el mismo daño.
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
local GameConfig = req(Shared.GameConfig)
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Combat = req(M.Combat)
Combat.Init()
local Loadout = req(M.Loadout)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end

local p = mock.new("Player"); p.Name = "P"; p.UserId = 8; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
PlayerData.WaitFor(p, 3)
local char = mock.new("Model"); char.Name = "P"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local head = mock.new("Part"); head.Name = "Head"; head.Position = Vector3.new(0, 5, 0); head.Parent = char
char.Parent = game.Workspace
p.Character = char
local tool = Loadout.MakeTool("ARX27", "Default"); tool.Parent = char
tool:SetAttribute("Ammo", 30)

local function dummy(z)
	local m = mock.new("Model"); m.Name = "Dummy" .. z
	local h = mock.new("Humanoid"); h.Health = 100; h.MaxHealth = 100; h.Parent = m
	local torso = mock.new("Part"); torso.Name = "UpperTorso"; torso.Position = Vector3.new(0, 5, z); torso.Size = Vector3.new(2, 2, 1); torso.Parent = m
	m.Parent = game.Workspace
	return h, torso
end
local origin = Vector3.new(0, 5, -0.5)
local function shoot(torso, offset)
	Remotes.Fire.OnServerEvent:Fire(p, tool, origin, { { Position = torso.Position + offset, Part = torso } })
	task.wait(0.3)
end

local T = Combat.HitTelemetry
check(GameConfig.HitTelemetry.Enabled == false, "apagada por defecto")
local h1, t1 = dummy(-20)
shoot(t1, Vector3.zero)
check(T.Samples == 0, "apagada no mide nada")
local damageOff = 100 - h1.Health

GameConfig.HitTelemetry.Enabled = true
GameConfig.HitTelemetry.ReportEvery = 2
local h2, t2 = dummy(-21)
shoot(t2, Vector3.zero) -- en el centro de la pieza: holgura 0
check(T.Samples == 1 and T.Accepted == 1 and T.Buckets[1] == 1, "un impacto exacto: holgura ≤ 0,5")
check(100 - h2.Health == damageOff, "mismo daño con la instrumentación encendida (" .. damageOff .. ")")
local h3, t3 = dummy(-22)
shoot(t3, Vector3.new(0, 6, 0)) -- 6 studs por encima: dentro de la tolerancia de 8 + media diagonal
check(T.Samples == 2 and T.Accepted == 2 and T.MaxSlack > 4 and T.MaxSlack <= 6, string.format("impacto a 6 studs: aceptado y medido (%.2f)", T.MaxSlack))
check(h3.Health < 100, "la tolerancia no ha cambiado: sigue valiendo")
check(string.find(T.LastReport, "Holgura de impactos (2)", 1, true) ~= nil, "resumen en la consola cada ReportEvery impactos")
local h4, t4 = dummy(-23)
shoot(t4, Vector3.new(0, 12, 0)) -- 12 studs: fuera de la tolerancia
check(T.Rejected == 1 and h4.Health == 100, "impacto a 12 studs: rechazado (como antes) y medido")
GameConfig.HitTelemetry.Enabled = false
print("INSTRUMENTACION OK")
process.exit(0)
