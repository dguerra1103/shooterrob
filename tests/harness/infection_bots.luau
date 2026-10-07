-- Prueba de los bots en el modo Infección: supervivientes al principio, zombis con garras que persiguen
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, BrickColor = roblox.Vector3, roblox.BrickColor
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.RespawnTime = 0.2
local CONFIG = GameConfig.Bots
CONFIG.Range = 0 -- sin peleas mientras se comprueba el relleno
local Weapons = req(Shared.Weapons)
local M = game.ServerScriptService.Server.Modules
local Combat = req(M.Combat)
local Bots = req(M.Bots)
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage

local function check(cond, msg)
	if not cond then
		print("FALLO: " .. msg)
		process.exit(1)
	end
	print("ok  " .. msg)
end

-- Equipos y mapa con puntos de aparición
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", BrickColor.new("Bright red")
teamB.Name, teamB.TeamColor = "Azul", BrickColor.new("Bright blue")
teamA.Parent, teamB.Parent = Teams, Teams
local map = mock.new("Model")
map.Name = "Map"
map.Parent = game.Workspace
for i, team in { teamA, teamB } do
	local s = mock.new("SpawnLocation")
	s.TeamColor = team.TeamColor
	s.Position = Vector3.new(i * 100, 0, 0)
	s.Parent = map
end
local ffa = mock.new("Part")
ffa.Name = "FFASpawn"
ffa.Parent = map

local kills = {}
Combat.OnKill = function(killer, victimPlayer, victimName, weaponName, headshot, position, killerBot, victimBot)
	table.insert(kills, { Killer = killer, VictimPlayer = victimPlayer, VictimName = victimName, KillerBot = killerBot, VictimBot = victimBot })
end

-- Un jugador en el equipo rojo, en el menú (los bots no le disparan)
local p = mock.new("Player")
p.Name, p.UserId, p.Team = "P1", 1, teamA
p.Parent = Players
table.insert(mock.players, p)
p:SetAttribute("InMenu", true)
local char = mock.new("Model")
char.Name = "P1"
local hum = mock.new("Humanoid")
hum.Health = 100
hum.Parent = char
for _, n in { "HumanoidRootPart", "Head" } do
	local part = mock.new("Part")
	part.Name = n
	part.Position = Vector3.new(0, 3, 0)
	part.Parent = char
end
char.Parent = game.Workspace
p.Character = char

RS:SetAttribute("TeamA", "Rojo")
RS:SetAttribute("TeamB", "Azul")
RS:SetAttribute("Mode", "INF")
RS:SetAttribute("TeamMode", true)
RS:SetAttribute("Infection", "Prep")
RS:SetAttribute("State", "Playing")
Bots.Init()
task.wait(CONFIG.FillTo + 1)
check(#Bots.Agents == CONFIG.FillTo - 1, "rellena con bots")
local allSurvivors = true
for _, agent in Bots.Agents do
	allSurvivors = allSurvivors and agent.Team == teamA and not agent.Zombie
end
check(allSurvivors, "antes de la infección todos los bots son supervivientes")
RS:SetAttribute("Infection", "On")
local zombie = Bots.Agents[1]
Bots.Infect(zombie, teamB)
task.wait(0.5)
check(zombie.Zombie and zombie.Team == teamB and zombie.Weapon == "Claws", "el bot infectado es zombi con garras")
check(zombie.Humanoid and zombie.Humanoid.MaxHealth == GameConfig.ModeSettings.INF.ZombieHealth and zombie.Model:GetAttribute("Zombie"), "reaparece como zombi con más vida")
check(RS.BotStats[zombie.Name]:GetAttribute("Team") == "Azul", "el marcador lo pone en el equipo zombi")
-- El zombi araña al jugador superviviente que tiene al lado
p:SetAttribute("InMenu", false)
Combat.WatchHumanoid(hum, p, p.Name)
CONFIG.Range = 500
zombie.Root.Position = Vector3.new(2, 3, 0)
task.wait(1.5)
check(hum.Health < 100, "el zombi araña al superviviente (vida " .. hum.Health .. ")")
-- Un bot nuevo durante la infección entra como zombi
local last = Bots.Agents[#Bots.Agents]
last.Model:Destroy()
table.remove(Bots.Agents, #Bots.Agents)
task.wait(2)
local newest = Bots.Agents[#Bots.Agents]
check(newest ~= last and newest.Team == teamB and newest.Zombie, "un bot que entra con la infección empezada es zombi")
print("INFECCION BOTS OK")
process.exit(0)
