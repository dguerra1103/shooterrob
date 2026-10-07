local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local Weapons = req(Shared.Weapons)
local Remotes = req(Shared.Remotes)
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Combat = req(M.Combat)
Combat.Init()
local Loadout = req(M.Loadout)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
check(#Weapons.Melees == 4 and Weapons.Get("Katana").Type == "Melee" and #Weapons.Get("Katana").Parts > 5 and #Weapons.Get("Scythe").Parts > 8, "Katana, Martillo y Guadaña definidos")
local p = mock.new("Player"); p.Name = "P"; p.UserId = 5; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
check(data.Melee == "Knife", "por defecto, el cuchillo")
check(Loadout.DefaultList(data)[3] == "Knife", "en el equipo va el cuchillo")
Remotes.SetMelee.OnServerEvent:Fire(p, "Katana")
check(data.Melee == "Knife", "la katana bloqueada no se puede equipar")
data.Level = 10
Remotes.SetMelee.OnServerEvent:Fire(p, "Katana")
check(data.Melee == "Katana" and Loadout.DefaultList(data)[3] == "Katana", "con nivel 6+ se equipa la katana")
Remotes.SetMelee.OnServerEvent:Fire(p, "ARX27")
check(data.Melee == "Katana", "no se puede poner un fusil como arma cuerpo a cuerpo")
-- Golpe con la katana: daño de la katana y baja con su nombre
local char = mock.new("Model"); char.Name = "P"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(0, 3, 0); root.Parent = char
char.Parent = game.Workspace
p.Character = char
local tool = Loadout.MakeTool("Katana", "Default"); tool.Parent = char
local dummy = mock.new("Model"); dummy.Name = "Dummy"
local dh = mock.new("Humanoid"); dh.Health = 100; dh.Parent = dummy
local droot = mock.new("Part"); droot.Name = "HumanoidRootPart"; droot.Position = Vector3.new(0, 3, -8); droot.Parent = dummy
dummy.Parent = game.Workspace
Remotes.Melee.OnServerEvent:Fire(p, droot)
check(dh.Health == 30, "la katana quita 70 a 8 studs (vida " .. dh.Health .. ")")
check(dh:GetAttribute("LastWeapon") == "Katana", "la baja cuenta como katana")
print("MELEE OK")
process.exit(0)
