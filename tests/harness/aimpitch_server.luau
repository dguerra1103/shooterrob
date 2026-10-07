-- El servidor guarda hacia dónde mira cada jugador (redondeado, limitado y sin aceptar basura)
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local M = game.ServerScriptService.Server.Modules
local Combat = req(M.Combat)
local Remotes = req(game.ReplicatedStorage.Shared.Remotes)
Combat.Init()
local p = mock.new("Player"); p.Name = "P1"; p.UserId = 1; p.Parent = game:GetService("Players")
local char = mock.new("Model"); char.Parent = game.Workspace
p.Character = char
local ev = Remotes.AimPitch.OnServerEvent
ev:Fire(p, 0.43)
check(char:GetAttribute("AimPitch") == 0.45, "se guarda redondeado (" .. tostring(char:GetAttribute("AimPitch")) .. ")")
ev:Fire(p, -0.2)
check(char:GetAttribute("AimPitch") == 0.45, "como mucho ~10 veces por segundo")
task.wait(0.1)
ev:Fire(p, 9)
check(char:GetAttribute("AimPitch") == 1.3, "limitado (no más de 75°)")
task.wait(0.1)
ev:Fire(p, 0 / 0)
ev:Fire(p, "x")
check(char:GetAttribute("AimPitch") == 1.3, "valores raros, ignorados")
print("INCLINACION OK")
process.exit(0)
