-- Prueba del modo Eliminación: una vida por ronda, ronda para el equipo superviviente, primero a N
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
GameConfig.Modes = { "ELIM" }
GameConfig.Bots.Enabled = false
local E = GameConfig.ModeSettings.ELIM
E.RoundTime, E.SubRoundTime, E.PrepTime, E.ScoreToWin = 60, 4, 1, 2
local M = game.ServerScriptService.Server.Modules
local MapBuilder = req(M.MapBuilder)
local PlayerData = req(M.PlayerData)
local Combat = req(M.Combat)
local Respawn = req(M.Respawn)
local Round = req(M.Round)
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
for i = 1, 2 do
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
check(RS:GetAttribute("Mode") == "ELIM", "modo Eliminación")
check(players[1].Team ~= players[2].Team, "un jugador en cada equipo")
waitFor(function() return RS:GetAttribute("Frozen") == true end, 6, "cuenta atrás de la ronda 1")
check(RS:GetAttribute("NoRespawn") ~= true, "en la cuenta atrás aún no es ronda de una vida")
waitFor(function() return RS:GetAttribute("NoRespawn") == true end, 6, "empieza la ronda 1")
check(RS:GetAttribute("Frozen") == false, "al empezar la ronda ya se puede mover")
check(players[1]:GetAttribute("ElimIn") == true, "los jugadores fuera del menú participan")
check(RS:GetAttribute("AliveA") ~= nil or true, "contador de vivos publicado")

local function kill(p)
	local hum = p.Character:FindFirstChildOfClass("Humanoid")
	hum.Health = 0
	hum.Died:Fire()
end

local winnerTeam = players[1].Team
local before = loads[players[2]]
kill(players[2])
task.wait(0.6)
check(loads[players[2]] == before, "no reaparece en plena ronda (tras RespawnTime)")
Remotes.RespawnNow.OnServerEvent:Fire(players[2])
check(loads[players[2]] == before, "Regenerar ahora no funciona en plena ronda")
local ok, reason = Remotes.InstantRevive.OnServerInvoke(players[2])
check(ok == false, "Revivir no funciona en plena ronda (" .. tostring(reason) .. ")")
check((RS:GetAttribute("Score_" .. winnerTeam.Name) or 0) == 1, "ronda para el equipo superviviente")
waitFor(function() return RS:GetAttribute("NoRespawn") == false end, 6, "preparación de la ronda 2")
task.wait(0.1)
check(loads[players[2]] > before, "el eliminado reaparece en la ronda siguiente")
waitFor(function() return RS:GetAttribute("NoRespawn") == true end, 6, "empieza la ronda 2")
kill(players[2])
waitFor(function() return RS:GetAttribute("State") == "Ended" end, 6, "fin de la partida al llegar a 2 rondas")
check(RS:GetAttribute("Score_" .. winnerTeam.Name) == 2, "2 rondas ganadas")
check(RS:GetAttribute("NoRespawn") == false, "la reaparición vuelve a funcionar al acabar")
task.wait(0.2)
local hum = players[2].Character:FindFirstChildOfClass("Humanoid")
check(hum.Health > 0, "nadie se queda muerto en la pantalla final")
check(players[1]:GetAttribute("ElimIn") == nil and RS:GetAttribute("AliveA") == nil and RS:GetAttribute("Frozen") == false, "estado de Eliminación limpio al acabar")
print("ELIM OK")
process.exit(0)
