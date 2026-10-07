-- Prueba de los bots: relleno y equilibrio de equipos, daño entre equipos y a quién se atribuye la baja
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

RS:SetAttribute("Mode", "TDM")
RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Playing")
Bots.Init()
task.wait(CONFIG.FillTo + 1)
check(#Bots.Agents == CONFIG.FillTo - 1, "rellena hasta " .. CONFIG.FillTo .. " (" .. #Bots.Agents .. " bots)")
local red, blue = 1, 0
local names = {}
for _, agent in Bots.Agents do
	if agent.Team == teamA then red += 1 elseif agent.Team == teamB then blue += 1 end
	check(not names[agent.Name], "nombre único " .. agent.Name)
	names[agent.Name] = true
	check(agent.Model.Parent == game.Workspace.Bots, agent.Name .. " está en workspace.Bots")
	check(agent.Model:GetAttribute("Team") == agent.Team.Name, agent.Name .. " lleva el atributo de equipo")
	check(agent.Tool and agent.Tool.Parent == agent.Model and Weapons.Get(agent.Weapon) ~= nil, agent.Name .. " lleva arma")
end
check(math.abs(red - blue) <= 1, "equipos equilibrados (" .. red .. " contra " .. blue .. ")")
check(#RS.BotStats:GetChildren() == #Bots.Agents, "estadísticas de cada bot para el marcador")

local ally, enemy
for _, agent in Bots.Agents do
	if agent.Team == teamA then ally = agent else enemy = agent end
end

-- El cohete del jugador daña al bot enemigo y no al aliado
local launcher = Weapons.Get("NovaLauncher")
ally.Root.Position = Vector3.new(0, 0, 0)
enemy.Root.Position = Vector3.new(1, 0, 0)
local allyHum, enemyHum = ally.Humanoid, enemy.Humanoid
Combat.Explode(p, Vector3.new(0.5, 0, 0), launcher, "NovaLauncher")
check(allyHum.Health == 100, "la explosión no daña a un bot aliado")
check(enemyHum.Health < 100, "la explosión daña a un bot enemigo")

-- Baja de un jugador a un bot: se le atribuye al jugador
if enemyHum.Health > 0 then
	enemyHum:TakeDamage(1000)
end
local k = kills[#kills]
check(k and k.Killer == p and k.VictimBot == enemy and k.VictimName == enemy.Name, "baja de jugador a bot")

-- Baja de un bot a un jugador
Combat.WatchHumanoid(hum, p, p.Name)
Combat.BotDamage(ally, hum, 500, "ARX27")
k = kills[#kills]
check(k and k.KillerBot == ally and k.VictimPlayer == p and k.Killer == nil, "baja de bot a jugador")
local died
for _, sent in mock.sent do
	if sent.Remote == "Died" then died = sent end
end
check(died and died.Args[1] == ally.Name, "la pantalla de muerte muestra el nombre del bot")
check(RS.BotStats[ally.Name]:GetAttribute("Kills") == 0, "BotStats sin Round no cambia (Round suma las bajas)")

-- Los bots disparan a los enemigos que ven
hum.Health = 100
p.Team = teamB
p:SetAttribute("InMenu", false)
CONFIG.Range, CONFIG.Accuracy, CONFIG.AccuracyFalloff, CONFIG.Reaction = 500, 1, 0, 0
task.wait(1.5)
check(hum.Health < 100 and hum:GetAttribute("LastBot") ~= nil, "un bot dispara al jugador enemigo (vida " .. hum.Health .. ")")
p.Team = teamA
CONFIG.Range = 0

-- El bot muerto reaparece
task.wait(GameConfig.RespawnTime + 1.5)
check(enemy.Humanoid ~= nil and enemy.Humanoid ~= enemyHum and enemy.Humanoid.Health > 0, "el bot eliminado reaparece (con un cuerpo nuevo)")

-- Eliminación: en plena ronda no reaparecen; al empezar la siguiente, sí
RS:SetAttribute("NoRespawn", true)
local victim = Bots.Agents[1]
victim.Humanoid.Health = 0
victim.Humanoid.Died:Fire()
task.wait(GameConfig.RespawnTime + 1.5)
check(victim.Humanoid == nil, "en plena ronda de Eliminación el bot no reaparece")
local count = #Bots.Agents
Bots.RespawnAll()
task.wait(0.2)
check(victim.Humanoid ~= nil and victim.Humanoid.Health == 100, "el bot reaparece al empezar la ronda siguiente")
check(#Bots.Agents == count, "sin bots duplicados")
RS:SetAttribute("NoRespawn", false)

-- Entra otro jugador: se quita un bot de su equipo (no de cualquiera) y los equipos siguen parejos
CONFIG.Range = 0
local p2 = mock.new("Player")
p2.Name, p2.UserId, p2.Team = "P2", 2, teamA
p2.Parent = Players
table.insert(mock.players, p2)
task.wait(1.5)
local r, b = #teamA:GetPlayers(), #teamB:GetPlayers()
for _, agent in Bots.Agents do
	if agent.Team == teamA then r += 1 elseif agent.Team == teamB then b += 1 end
end
check(#Bots.Agents == CONFIG.FillTo - 2, "un bot menos al entrar un jugador")
check(math.abs(r - b) <= 1, "equipos parejos tras entrar un jugador (" .. r .. " contra " .. b .. ")")

-- Fin de ronda: se van todos
RS:SetAttribute("State", "Intermission")
check(#Bots.Agents == 0, "al acabar la ronda no quedan bots")
task.wait(3.2) -- los cuerpos se quitan a los 3 s
check(#game.Workspace.Bots:GetChildren() == 0, "ni modelos de bots")
-- En Escalada de armas también hay bots (rivales para subir de arma)
RS:SetAttribute("Mode", "GUN")
RS:SetAttribute("TeamMode", false)
RS:SetAttribute("State", "Playing")
task.wait(CONFIG.FillTo + 1)
check(#Bots.Agents > 0, "bots en Escalada de armas (" .. #Bots.Agents .. ")")
print("BOTS OK")
process.exit(0)
