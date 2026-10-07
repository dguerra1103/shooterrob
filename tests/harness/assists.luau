-- Asistencias: quien le quitó vida a la víctima (y no la remató) recibe la asistencia
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
RS:SetAttribute("TeamMode", false); RS:SetAttribute("Mode", "FFA"); RS:SetAttribute("State", "Playing")
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Combat = req(M.Combat)
local Round = req(M.Round)
local function makePlayer(id, pos)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	local char = mock.new("Model"); char.Parent = game.Workspace
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(pos); root.Position = pos; root.Parent = char
	p.Character = char
	return p, hum
end
local a = makePlayer(31, Vector3.new(0, 3, 40))
local b = makePlayer(32, Vector3.new(0, 3, -40))
local victim, victimHum = makePlayer(33, Vector3.new(0, 3, 0))
PlayerData.WaitFor(a, 3); PlayerData.WaitFor(b, 3); PlayerData.WaitFor(victim, 3)
local got
Combat.OnKill = function() end
Combat.OnAssist = function(helpers, name, bot, victimPlayer) got = { helpers, name, bot, victimPlayer } end
Combat.WatchHumanoid(victimHum, victim, victim.Name, nil)
local rocket = { Explosive = { Radius = 10, Damage = 60, MinDamage = 60 } }
Combat.Explode(a, Vector3.new(0, 3, 0), rocket, "NovaLauncher")
check(victimHum.Health == 40, "A le quita 60")
Combat.Explode(b, Vector3.new(0, 3, 0), rocket, "NovaLauncher")
check(victimHum.Health == 0, "B lo remata")
task.wait(0.1)
check(got and #got[1] == 1 and got[1][1] == a and got[2] == victim.Name, "asistencia para A (y no para B)")
-- Poco daño no cuenta
got = nil
local v2, h2 = makePlayer(34, Vector3.new(100, 3, 0))
PlayerData.WaitFor(v2, 3)
Combat.WatchHumanoid(h2, v2, v2.Name, nil)
Combat.Explode(a, Vector3.new(100, 3, 0), { Explosive = { Radius = 10, Damage = 10, MinDamage = 10 } }, "Grenade")
Combat.Explode(b, Vector3.new(100, 3, 0), { Explosive = { Radius = 10, Damage = 200, MinDamage = 200 } }, "NovaLauncher")
task.wait(0.1)
check(got == nil, "con 10 de daño no hay asistencia")
-- Premio
local data = PlayerData.Get(a)
local xp, level, coins, assists = data.XP, data.Level, data.Coins, data.Assists
Round.RegisterAssist({ a }, "Muñeco", nil, nil)
check(data.Assists == assists, "los muñecos no dan asistencias")
Round.RegisterAssist({ a }, "P33", nil, victim)
check(data.Coins > coins and (data.XP > xp or data.Level > level) and data.Assists == assists + 1, "la asistencia da XP, monedas y cuenta")
print("ASISTENCIAS OK")
process.exit(0)
