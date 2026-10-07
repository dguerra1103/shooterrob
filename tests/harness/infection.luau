-- Prueba del modo Infección: todos supervivientes, paciente cero, los caídos se vuelven zombis
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local roblox = require("@lune/roblox")
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.EndScreenTime = 0.5
GameConfig.MinPlayers = 1
GameConfig.RespawnTime = 0.3
GameConfig.Modes = { "INF" }
GameConfig.Bots.Enabled = false
local I = GameConfig.ModeSettings.INF
I.RoundTime, I.PrepTime, I.ZombieRatio = 4, 2, 5
local M = game.ServerScriptService.Server.Modules
local MapBuilder = req(M.MapBuilder)
local PlayerData = req(M.PlayerData)
local Combat = req(M.Combat)
local Respawn = req(M.Respawn)
local Round = req(M.Round)
local Loadout = req(M.Loadout)
local RS = game.ReplicatedStorage
local Remotes = req(Shared.Remotes)

local function check(cond, msg)
	if not cond then
		print("FALLO: " .. msg)
		process.exit(1)
	end
	print("ok  " .. msg)
end

local loads = {}
mock.onLoadCharacter = function(p)
	loads[p] = (loads[p] or 0) + 1
	local char = mock.new("Model")
	char.Name = p.Name
	local hum = mock.new("Humanoid")
	hum.Health = 100
	hum.MaxHealth = 100
	hum.Parent = char
	local root = mock.new("Part")
	root.Name = "HumanoidRootPart"
	root.Parent = char
	char.Parent = game.Workspace
	p.Character = char
	p.CharacterAdded:Fire(char)
end

MapBuilder.Build()
PlayerData.Init()
Combat.Init()
Combat.OnKill = Round.RegisterKill
Respawn.Init()
local players = {}
for i = 1, 3 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.UserId = 700 + i; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	players[i] = p
end
Round.Init()

local function waitFor(cond, timeout, msg)
	local deadline = os.clock() + timeout
	while not cond() do
		if os.clock() > deadline then
			check(false, "tiempo agotado esperando: " .. msg)
		end
		task.wait(0.05)
	end
end


waitFor(function() return RS:GetAttribute("State") == "Playing" end, 10, "inicio de la partida")
check(RS:GetAttribute("Mode") == "INF" and RS:GetAttribute("Infection") == "Prep", "modo Infección en preparación")
local A, B = RS:GetAttribute("TeamA"), RS:GetAttribute("TeamB")
check(players[1].Team.Name == A and players[2].Team.Name == A and players[3].Team.Name == A, "todos empiezan como supervivientes")
check(Loadout.Override(players[1]) == nil, "los supervivientes llevan sus armas")
waitFor(function() return RS:GetAttribute("Infection") == "On" end, 5, "empieza la infección")
task.wait(0.1)
local zombies = {}
for _, p in players do
	if p.Team.Name == B then table.insert(zombies, p) end
end
check(#zombies == 1, "un paciente cero (3 jugadores)")
local zombie = zombies[1]
local zl = Loadout.Override(zombie)
check(zl and zl[1] == "Claws", "el zombi solo lleva garras")
task.wait(0.3)
check(zombie.Character and zombie.Character:GetAttribute("Zombie") == true, "el paciente cero reaparece como zombi")
local zh = zombie.Character:FindFirstChildOfClass("Humanoid")
check(zh.MaxHealth == I.ZombieHealth, "los zombis tienen más vida")
check(RS:GetAttribute("AliveA") == 2 and RS:GetAttribute("AliveB") == 1, "contador 2 supervivientes · 1 zombi")
-- Un superviviente cae: se convierte en zombi
local victim
for _, p in players do
	if p ~= zombie then victim = p break end
end
local hum = victim.Character:FindFirstChildOfClass("Humanoid")
hum.Health = 0
hum.Died:Fire()
task.wait(0.5)
check(victim.Team.Name == B, "el superviviente caído se convierte en zombi")
check(zombie:GetAttribute("InfZombieStart") == true and victim:GetAttribute("InfZombieStart") == nil, "se recuerda quién empezó como zombi")
local okRevive = Remotes.InstantRevive.OnServerInvoke(victim)
check(okRevive ~= true or victim.Team.Name == B, "revivir no le devuelve como superviviente")
check(RS:GetAttribute("AliveA") == 1, "queda 1 superviviente")
local last
for _, p in players do
	if p.Team.Name == A then last = p end
end
check(last.Character:FindFirstChildOfClass("Humanoid").MaxHealth == 150, "el último superviviente recibe más vida")
-- El último aguanta hasta el final: ganan los supervivientes
waitFor(function() return RS:GetAttribute("State") == "Ended" end, 8, "fin de la partida por tiempo")
check(RS:GetAttribute("Score_" .. A) == 1 and (RS:GetAttribute("Score_" .. B) or 0) == 0, "ganan los supervivientes")
check(RS:GetAttribute("Infection") == nil and RS:GetAttribute("AliveA") == nil, "estado de Infección limpio al acabar")
check(Loadout.Override == nil, "armas normales al acabar")
print("INFECCION OK")
process.exit(0)
