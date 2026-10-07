-- Dominio: A junto a la base roja, B en el centro, C junto a la azul; captura, disputa, puntos y bots
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, BrickColor = roblox.Vector3, roblox.BrickColor
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
GameConfig.Bots.Range = 0 -- (sin peleas)
local M = game.ServerScriptService.Server.Modules
local Domination = req(M.Domination)
local Bots = req(M.Bots)
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", BrickColor.new("Bright red")
teamB.Name, teamB.TeamColor = "Azul", BrickColor.new("Bright blue")
teamA.Parent, teamB.Parent = Teams, Teams
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
for i, team in { teamA, teamB } do
	local s = mock.new("SpawnLocation"); s.TeamColor = team.TeamColor; s.Position = Vector3.new(i == 1 and -120 or 120, 0, 0); s.Parent = map
end
for i, p in { Vector3.new(0, 0, 60), Vector3.new(-80, 0, 0), Vector3.new(0, 0, 2), Vector3.new(80, 0, 0), Vector3.new(0, 0, -60) } do
	local z = mock.new("Part"); z.Name = "HardpointZone"; z.Position = p; z:SetAttribute("Radius", 10); z:SetAttribute("Order", i); z.Parent = map
end
local ffa = mock.new("Part"); ffa.Name = "FFASpawn"; ffa.Position = Vector3.new(0, 0, 30); ffa.Parent = map
check(Domination.IsAvailable(), "hay sitio para tres banderas")
local scores = { Rojo = 0, Azul = 0 }
Domination.OnScore = function(team, amount) scores[team.Name] += amount end
check(Domination.Start(), "empieza")
check(RS:GetAttribute("Dom_A_Position") == Vector3.new(-80, 0, 0), "A junto a la base roja")
check(RS:GetAttribute("Dom_B_Position") == Vector3.new(0, 0, 2), "B en el centro")
check(RS:GetAttribute("Dom_C_Position") == Vector3.new(80, 0, 0), "C junto a la base azul")
check(game.Workspace:FindFirstChild("DomFlag_B") ~= nil, "bandera con su letra en el mapa")

-- Un jugador rojo en A: la captura en ~5 s
local p = mock.new("Player"); p.Name, p.UserId, p.Team = "P1", 1, teamA; p.Parent = Players; table.insert(mock.players, p)
local char = mock.new("Model"); char.Name = "P1"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Position = Vector3.new(-78, 3, 0); root.Parent = char
char.Parent = game.Workspace; p.Character = char
task.wait(2.6)
check(RS:GetAttribute("Dom_A_Capturing") == "Rojo" and (RS:GetAttribute("Dom_A_Progress") or 0) > 0.3, "capturando A (" .. tostring(RS:GetAttribute("Dom_A_Progress")) .. ")")
task.wait(3)
check(RS:GetAttribute("Dom_A_Owner") == "Rojo", "A es roja")
local before = scores.Rojo
task.wait(3.3)
check(scores.Rojo > before, "la bandera suma puntos (" .. before .. " -> " .. scores.Rojo .. ")")
-- Un bot azul entra: disputada (no avanza)
local bots = game.Workspace:FindFirstChild("Bots") or mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local enemy = mock.new("Model"); enemy:SetAttribute("Team", "Azul")
local eh = mock.new("Humanoid"); eh.Health = 100; eh.Parent = enemy
local er = mock.new("Part"); er.Name = "HumanoidRootPart"; er.Position = Vector3.new(-82, 3, 2); er.Parent = enemy
enemy.Parent = bots
task.wait(1)
check(RS:GetAttribute("Dom_A_Contested") == true and RS:GetAttribute("Dom_A_Owner") == "Rojo", "con los dos equipos dentro, disputada")
-- El rojo se va: el azul la captura
root.Position = Vector3.new(-200, 3, 0)
task.wait(5.6)
check(RS:GetAttribute("Dom_A_Owner") == "Azul", "el azul le quita A al rojo")
enemy.Parent = nil
Domination.Stop()
check(RS:GetAttribute("Dom_A_Position") == nil and game.Workspace:FindFirstChild("DomFlag_A") == nil, "al acabar se limpia")

-- Bots en Dominio: van a por las banderas
RS:SetAttribute("Mode", "DOM")
RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Playing")
p:SetAttribute("InMenu", true)
Domination.Start()
Bots.Init()
task.wait(GameConfig.Bots.FillTo + 3)
local toFlags, total = 0, 0
for _, agent in Bots.Agents do
	if agent.GoalPosition then
		total += 1
		for _, letter in { "A", "B", "C" } do
			if (agent.GoalPosition - RS:GetAttribute("Dom_" .. letter .. "_Position")).Magnitude <= 10 then
				toFlags += 1
				break
			end
		end
	end
end
check(total > 0 and toFlags >= total * 0.6, "los bots van a las banderas (" .. toFlags .. "/" .. total .. ")")
print("DOMINIO OK")
process.exit(0)
