local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local Vector3 = require("@lune/roblox").Vector3
local CFrame = require("@lune/roblox").CFrame
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local M = game.ServerScriptService.Server.Modules
local GameConfig = req(Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local Remotes = req(Shared.Remotes)
local Weapons = req(Shared.Weapons)
local Grenades = req(M.Grenades)
Grenades.Init()
local function check(c, m) if not c then error("FALLO: " .. m, 2) end print("ok  " .. m) end

local function makeChar(name, pos)
	local char = mock.new("Model"); char.Name = name; char.Parent = game.Workspace
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(pos); root.Size = Vector3.new(2, 2, 1); root.Parent = char
	local head = mock.new("Part"); head.Name = "Head"; head.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)); head.Size = Vector3.new(1, 1, 1); head.Parent = char
	return char, hum
end
local teams = game:GetService("Teams"):GetChildren()
local thrower = mock.new("Player"); thrower.Name = "A"; thrower.UserId = 1; thrower.Parent = game:GetService("Players"); thrower.Team = teams[1]
local victim = mock.new("Player"); victim.Name = "B"; victim.UserId = 2; victim.Parent = game:GetService("Players"); victim.Team = teams[2]
table.insert(mock.players, thrower); table.insert(mock.players, victim)
local c1 = makeChar("A", Vector3.new(0, 3, 0)); thrower.Character = c1
local c2, h2 = makeChar("B", Vector3.new(0, 3, -6)); victim.Character = c2
thrower:SetAttribute("InMenu", false)

local throwEv = Remotes.ThrowGrenade.OnServerEvent
local folder = game.Workspace.Grenades
throwEv:Fire(thrower, "x")
throwEv:Fire(thrower, Vector3.new(0, 0, -50))
check(#folder:GetChildren() == 0, "direcciones inválidas rechazadas")
thrower:SetAttribute("InMenu", true)
throwEv:Fire(thrower, Vector3.new(0, 0, -1))
check(#folder:GetChildren() == 0, "en el menú no se lanza")
thrower:SetAttribute("InMenu", false)
game.ReplicatedStorage:SetAttribute("Mode", "GUN")
throwEv:Fire(thrower, Vector3.new(0, 0, -1))
check(#folder:GetChildren() == 0, "en Escalada no hay granadas")
game.ReplicatedStorage:SetAttribute("Mode", "TDM")
throwEv:Fire(thrower, Vector3.new(0, 0, -1))
check(#folder:GetChildren() == 1, "granada lanzada")
check((thrower:GetAttribute("GrenadeReadyAt") or 0) > os.clock() + 10, "recarga activada")
throwEv:Fire(thrower, Vector3.new(0, 0, -1))
check(#folder:GetChildren() == 1, "no se lanza otra durante la recarga")
throwEv:Fire(thrower, Vector3.new(0 / 0, 0, 0))
check(#folder:GetChildren() == 1, "dirección NaN rechazada")
-- La granada del mock no se mueve: la ponemos junto a la víctima
local g = folder:GetChildren()[1]
g.CFrame = CFrame.new(0, 2.5, -5)
task.wait(Weapons.Grenade.Fuse + 0.6)
check(#folder:GetChildren() == 0, "la granada explota y desaparece")
check(h2.Health < 100, "la explosión hace daño al enemigo (" .. h2.Health .. ")")
check(h2:GetAttribute("LastWeapon") == "Grenade", "la baja se atribuye a la granada")
-- Cocinada: sale con menos mecha y explota antes
-- (sin quitar la anilla antes, el tiempo cocinado que diga el cliente no vale)
thrower:SetAttribute("GrenadeReadyAt", 0)
throwEv:Fire(thrower, Vector3.new(0, 0, -1), 1.5)
check(#folder:GetChildren() == 1, "granada lanzada sin anilla quitada")
task.wait(Weapons.Grenade.Fuse - 1.5 + 0.35)
check(#folder:GetChildren() == 1, "sin anilla quitada en el servidor no cuenta lo cocinado (trampa)")
task.wait(1.5 + 0.3)
thrower:SetAttribute("GrenadeReadyAt", 0)
Remotes.GrenadePin.OnServerEvent:Fire(thrower)
task.wait(1.5)
throwEv:Fire(thrower, Vector3.new(0, 0, -1), 1.5)
check(#folder:GetChildren() == 1, "granada cocinada lanzada")
task.wait(Weapons.Grenade.Fuse - 1.5 + 0.35)
check(#folder:GetChildren() == 0, "cocinada 1,5 s: explota mucho antes")
-- Cocinar de más no la hace explotar al instante en la mano del servidor (como mucho, casi sin mecha)
thrower:SetAttribute("GrenadeReadyAt", 0)
Remotes.GrenadePin.OnServerEvent:Fire(thrower)
task.wait(Weapons.Grenade.Fuse)
throwEv:Fire(thrower, Vector3.new(0, 0, -1), 999)
check(#folder:GetChildren() == 1, "aunque mande un tiempo enorme, sale lanzada")
task.wait(0.45)
check(#folder:GetChildren() == 0, "y explota enseguida")
thrower:SetAttribute("GrenadeReadyAt", 0)
throwEv:Fire(thrower, Vector3.new(0, 0, -1), 0 / 0)
check(#folder:GetChildren() == 1, "tiempo NaN: lanzada normal")
task.wait(0.5)
check(#folder:GetChildren() == 1, "con su mecha entera")
print("TODO OK")
process.exit(0)
