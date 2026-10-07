-- Bots realistas (5 contra 5): roles, carriles, oído, cargador, granadas, coberturas y vida que se recupera
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, BrickColor, CFrame = roblox.Vector3, roblox.BrickColor, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.RespawnTime = 0.2
local CONFIG = GameConfig.Bots
CONFIG.Range = 60
local Weapons = req(Shared.Weapons)
local M = game.ServerScriptService.Server.Modules
local Combat = req(M.Combat)
local Grenades = req(M.Grenades)
local Bots = req(M.Bots)
local HealthRegen = req(M.HealthRegen)
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage

local function check(cond, msg)
	if not cond then
		print("FALLO: " .. msg)
		process.exit(1)
	end
	print("ok  " .. msg)
end

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
	s.Position = Vector3.new(i == 1 and -1000 or 1000, 0, 0)
	s.Parent = map
end
for _, p in { Vector3.new(-500, 0, 0), Vector3.new(500, 0, 0), Vector3.new(0, 0, 300) } do
	local ffa = mock.new("Part")
	ffa.Name = "FFASpawn"
	ffa.Position = p
	ffa.Parent = map
end

-- Jugador del equipo rojo
local p = mock.new("Player")
p.Name, p.UserId, p.Team = "P1", 1, teamA
p.Parent = Players
table.insert(mock.players, p)
p:SetAttribute("InMenu", true)
local char = mock.new("Model")
char.Name = "P1"
local hum = mock.new("Humanoid")
hum.MaxHealth, hum.Health = 100000, 100000
hum.Parent = char
local pHead
for _, n in { "HumanoidRootPart", "Head" } do
	local part = mock.new("Part")
	part.Name = n
	part.Position = Vector3.new(0, 3, -30)
	part.Parent = char
	if n == "Head" then pHead = part end
end
char.Parent = game.Workspace
p.Character = char

-- Puestos de vigilancia: uno en cada mitad
local spotA = mock.new("Part"); spotA.Name = "BotSpot"; spotA.Position = Vector3.new(-700, 8, 0); spotA:SetAttribute("Look", Vector3.new(0, 4, 0)); spotA.Parent = map
local spotB = mock.new("Part"); spotB.Name = "BotSpot"; spotB.Position = Vector3.new(700, 8, 0); spotB:SetAttribute("Look", Vector3.new(0, 4, 0)); spotB.Parent = map
-- Granadas: se apuntan (no hace falta la física)
local thrown = {}
Grenades.BotThrow = function(model, from, target)
	table.insert(thrown, { Model = model, Target = target })
	return true
end

map:SetAttribute("Realistic", true) -- (mapa tipo shooter militar: los bots van de soldado)
RS:SetAttribute("Mode", "TDM")
RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Playing")
Bots.Init()
task.wait(CONFIG.FillTo + 1)
check(#Bots.Agents == 9, "5 contra 5: 9 bots con un jugador (" .. #Bots.Agents .. ")")
local perTeam = { [teamA] = { n = 1, roles = {}, lanes = { [-1] = 0, [0] = 0, [1] = 0 } }, [teamB] = { n = 0, roles = {}, lanes = { [-1] = 0, [0] = 0, [1] = 0 } } }
for _, agent in Bots.Agents do
	local t = perTeam[agent.Team]
	t.n += 1
	t.roles[agent.Role] = (t.roles[agent.Role] or 0) + 1
	t.lanes[agent.Lane] += 1
	check(agent.Skill and agent.Skill >= 0.85 and agent.Skill <= 1.15, agent.Name .. " (" .. agent.Role .. ", carril " .. agent.Lane .. ", " .. agent.Weapon .. ") tiene su puntería")
	local def = Weapons.Get(agent.Weapon)
	check(def and agent.Mag == def.MagSize, agent.Name .. " sale con el cargador lleno")
	check(agent.Humanoid.WalkSpeed == CONFIG.SprintSpeed, agent.Name .. " corre de camino")
end
check(perTeam[teamA].n == 5 and perTeam[teamB].n == 5, "equipos de 5")
for _, agent in Bots.Agents do
	local outfit = agent.Model:FindFirstChild("Outfit")
	local helmet = outfit and outfit:FindFirstChild("Helmet")
	local band = outfit and outfit:FindFirstChild("Armband")
	check(helmet ~= nil and band ~= nil and band.Color == agent.Team.TeamColor.Color, agent.Name .. " va de soldado (casco y brazalete de su equipo)")
	check(agent.Tool:GetAttribute("Skin") == nil or agent.Tool:GetAttribute("Skin") == "Default", agent.Name .. " sin skin llamativa")
end
for team, t in perTeam do
	for _, role in CONFIG.Roles do
		if role.Max then
			check((t.roles[role.Name] or 0) <= role.Max, team.Name .. ": como mucho " .. role.Max .. " " .. role.Name)
		end
	end
	local mn, mx = math.huge, 0
	for _, c in t.lanes do mn = math.min(mn, c); mx = math.max(mx, c) end
	check(mx - mn <= 1, team.Name .. ": repartidos por los 3 carriles")
end

-- Un bot enemigo (azul) en el centro mirando hacia +Z; el jugador detrás (no le ve)
local e
for _, agent in Bots.Agents do
	if agent.Team == teamB then e = agent break end
end
e.Role = "Asalto"
local function place(agent, position, look)
	-- (mirando hacia +Z o hacia -Z; el CFrame.lookAt de Lune no sirve aquí)
	agent.Root.CFrame = CFrame.new(position) * (look.Z > position.Z and CFrame.Angles(0, math.pi, 0) or CFrame.new())
	local head = agent.Model:FindFirstChild("Head")
	head.Position = position + Vector3.new(0, 1.5, 0)
end
place(e, Vector3.new(0, 3, 0), Vector3.new(0, 3, 10))
p:SetAttribute("InMenu", false)
task.wait(0.5)
check(e.Target == nil, "no ve al jugador que tiene a la espalda")
-- El jugador dispara: el bot lo oye y va hacia allí
Combat.ReportNoise(pHead.Position, teamA, char, "ARX27")
task.wait(0.5)
check(e.GoalPosition and (e.GoalPosition - pHead.Position).Magnitude < 1, "oye el disparo y va hacia allí")
-- Con silenciador, de lejos, no se oye
place(e, Vector3.new(0, 3, 0), Vector3.new(0, 3, 10))
e.GoalPosition, e.NextHeard = nil, 0
pHead.Position = Vector3.new(0, 3, -40)
char.HumanoidRootPart.Position = Vector3.new(0, 3, -40)
Combat.ReportNoise(pHead.Position, teamA, char, "GhostlineXR")
task.wait(0.5)
check(e.GoalPosition == nil or (e.GoalPosition - pHead.Position).Magnitude > 1, "el silenciador no se oye a 40 studs")

-- Lo ve: dispara y gasta cargador (ráfagas)
place(e, Vector3.new(0, 3, 0), Vector3.new(0, 3, -40))
local before = hum.Health
local magBefore = e.Mag
task.wait(2)
check(e.Target == char, "ve al jugador de frente y le apunta")
check(e.Mag < magBefore, "dispara (cargador " .. magBefore .. " -> " .. e.Mag .. ")")
print("  vida del jugador: " .. before .. " -> " .. hum.Health)
-- Sin balas: recarga y no dispara mientras
e.Mag = 0
-- (entre ráfagas espera hasta ~0,5 s antes de volver a apretar el gatillo)
local tr = os.clock()
while not (e.ReloadUntil > os.clock()) and os.clock() - tr < 1 do task.wait(0.05) end
check(e.ReloadUntil > os.clock() and e.Tool:GetAttribute("Reloading") == true, "recarga al vaciar el cargador")
local shotsDuring = 0
local sentBefore = #mock.sent
task.wait(0.5)
for i = sentBefore + 1, #mock.sent do
	local sent = mock.sent[i]
	if sent.Remote == "ShotFX" and sent.Args and sent.Args[1] == e.Tool then shotsDuring += 1 end
end
check(shotsDuring == 0, "no dispara mientras recarga")

-- Poca vida: se retira a cubierto (el jugador no ve el sitio)
e.ReloadUntil = 0
e.Mag = 30
e.NextRetreat = 0
e.Humanoid.Health = 20
mock.raycastImpl = function(origin, direction)
	if (origin - pHead.Position).Magnitude < 0.01 and direction.Magnitude < 60 and math.abs(direction.Z) < 60 and (origin + direction - pHead.Position).Magnitude > 20 then
		return { Instance = map, Position = origin + direction * 0.5, Normal = Vector3.new(0, 1, 0), Distance = direction.Magnitude * 0.5, Material = roblox.Enum.Material.Plastic }
	end
	return nil
end
task.wait(0.4)
mock.raycastImpl = nil
check(e.RetreatUntil > os.clock() - 0.5, "con poca vida se retira a cubierto")
e.Humanoid.Health = 100
e.RetreatUntil = 0
task.wait(0.3)

-- Tirador quieto: se agacha para apuntar (baja la cadera) y se levanta al perder de vista
e.Role = "Tirador"

e.BaseHip = nil
e.NextStrafe = 0
place(e, Vector3.new(0, 3, 0), Vector3.new(0, 3, -40))
local base = e.Humanoid.HipHeight
local crouched = false
local t1 = os.clock()
while os.clock() - t1 < 6 and not crouched do
	task.wait(0.1)
	if e.Crouched and e.Humanoid.HipHeight < base - 1 then crouched = true end
	if not e.Crouched then e.NextStrafe = math.min(e.NextStrafe, os.clock()) end -- (que vuelva a decidir)
end
check(crouched, "el tirador quieto se agacha para apuntar")
p:SetAttribute("InMenu", true)
task.wait(0.4)
check(not e.Crouched and math.abs(e.Humanoid.HipHeight - base) < 0.01, "se levanta al perder de vista al enemigo")
p:SetAttribute("InMenu", false)
e.Role = "Asalto"
task.wait(0.3)

-- Se esconde: granada a donde lo vio por última vez
e.NextGrenade = 0
place(e, Vector3.new(0, 3, 0), Vector3.new(0, 3, -40))
task.wait(0.5)
p:SetAttribute("InMenu", true) -- (deja de ser objetivo: como si se hubiera escondido)
local t0 = os.clock()
while #thrown == 0 and os.clock() - t0 < 3 do task.wait(0.1) end
check(#thrown > 0 and thrown[1].Model == e.Model and (thrown[1].Target - pHead.Position).Magnitude < 3, "lanza una granada donde se escondió")

-- El tirador va a un puesto de vigilancia de su mitad
local sniper
for _, agent in Bots.Agents do
	if agent.Team == teamA and agent ~= e then sniper = agent break end
end
sniper.Role = "Tirador"
sniper.Waypoints, sniper.GoalDeadline, sniper.HoldUntil, sniper.Target = nil, 0, 0, nil
sniper.AlertPosition, sniper.LastSeenTime = nil, nil
task.wait(1)
check(sniper.GoalPosition and (sniper.GoalPosition - spotA.Position).Magnitude < 1, "el tirador va al puesto de vigilancia de su mitad")
check(sniper.SpotLook == Vector3.new(0, 4, 0), "y sabe hacia dónde vigilar")
-- Vida que se recupera sola
HealthRegen.Init()
local h2 = e.Humanoid
h2.MaxHealth = 100
h2.Health = 40
h2:SetAttribute("LastHitTime", os.clock() - 10)
task.wait(1)
check(h2.Health > 40, "la vida se recupera sola (" .. h2.Health .. ")")
h2.Health = 40
h2:SetAttribute("LastHitTime", os.clock())
task.wait(1)
check(h2.Health == 40, "no se recupera justo después de recibir daño")
print("BOTS REALISTAS OK")
process.exit(0)
