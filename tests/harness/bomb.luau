-- Buscar y destruir: plantar, desactivar, explotar y bots que van a los sitios
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, BrickColor = roblox.Vector3, roblox.BrickColor
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
GameConfig.Bots.Range = 0
GameConfig.ModeSettings.SND.BombTime = 4
local M = game.ServerScriptService.Server.Modules
local Bomb = req(M.Bomb)
local Bots = req(M.Bots)
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = GameConfig.Teams[1].Name, BrickColor.new("Bright red")
teamB.Name, teamB.TeamColor = GameConfig.Teams[2].Name, BrickColor.new("Bright blue")
teamA.Parent, teamB.Parent = Teams, Teams
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
for i, team in { teamA, teamB } do
	local s = mock.new("SpawnLocation"); s.TeamColor = team.TeamColor; s.Position = Vector3.new(i == 1 and -150 or 150, 0, 0); s.Parent = map
end
for _, spec in { { Vector3.new(-80, 0, 60), "A", 1 }, { Vector3.new(-80, 0, -60), "B", 1 }, { Vector3.new(80, 0, -60), "A", 2 }, { Vector3.new(80, 0, 60), "B", 2 } } do
	local p = mock.new("Part"); p.Name = "BombSite"; p.Position = spec[1]; p:SetAttribute("Letter", spec[2]); p:SetAttribute("Defender", spec[3]); p:SetAttribute("Radius", 7); p.Parent = map
end
local ffa = mock.new("Part"); ffa.Name = "FFASpawn"; ffa.Position = Vector3.new(0, 0, 30); ffa.Parent = map
check(Bomb.IsAvailable(), "el mapa tiene sitios para los dos equipos")
local function player(name, id, team, pos)
	local p = mock.new("Player"); p.Name, p.UserId, p.Team = name, id, team; p.Parent = Players; table.insert(mock.players, p)
	local char = mock.new("Model"); char.Name = name
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Position = pos; root.Parent = char
	char.Parent = game.Workspace; p.Character = char
	return p, root, hum
end
-- Ataca el rojo: los sitios son los de la mitad azul
local att, attRoot, attHum = player("Atacante", 1, teamA, Vector3.new(0, 3, 0))
local def, defRoot = player("Defensor", 2, teamB, Vector3.new(200, 3, 0))
check(Bomb.Start(teamA, teamB), "empieza la ronda")
check(RS:GetAttribute("Bomb_A_Position") == Vector3.new(80, 0, -60), "sitio A en la mitad de los defensores")
check(RS:GetAttribute("Bomb_State") == "Idle", "bomba sin plantar")
attRoot.Position = Vector3.new(82, 3, -58)
task.wait(2)
check(RS:GetAttribute("Bomb_Action") == "Planting" and (RS:GetAttribute("Bomb_Progress") or 0) > 0.3, "plantando en A")
task.wait(2.6)
check(Bomb.Planted and RS:GetAttribute("Bomb_State") == "Planted" and RS:GetAttribute("Bomb_Site") == "A", "bomba plantada en A")
check(game.Workspace:FindFirstChild("BombSite_B") == nil and game.Workspace:FindFirstChild("BombSite_A") ~= nil, "solo queda marcado el sitio de la bomba")
local pb = game.Workspace:FindFirstChild("PlantedBomb")
check(pb ~= nil and pb:FindFirstChild("BombLight") ~= nil, "la bomba plantada está en el suelo, con su luz")
-- Explota si nadie la desactiva
task.wait(4.5)
check(Bomb.Result == "Exploded", "explota a los " .. GameConfig.ModeSettings.SND.BombTime .. " s")
check(attHum.Health <= 0, "la explosión elimina a quien está al lado")
check(game.Workspace:FindFirstChild("PlantedBomb") == nil, "al explotar desaparece la bomba")
attHum.Health = 100
Bomb.Stop()
check(RS:GetAttribute("Bomb_Attackers") == nil, "al acabar se limpia")
-- Otra ronda: el defensor la desactiva
GameConfig.ModeSettings.SND.BombTime = 30
attRoot.Position = Vector3.new(0, 3, 0)
Bomb.Start(teamA, teamB)
attRoot.Position = Vector3.new(80, 3, 60)
task.wait(4.6)
check(Bomb.Planted and RS:GetAttribute("Bomb_Site") == "B", "plantada en B")
attRoot.Position = Vector3.new(0, 3, 0)
defRoot.Position = Vector3.new(81, 3, 61)
task.wait(6.6)
check(Bomb.Result == "Defused", "el defensor la desactiva")
Bomb.Stop()
check(game.Workspace:FindFirstChild("PlantedBomb") == nil, "al acabar la ronda se quita la bomba")
-- Portador: solo él planta; si cae, la bomba queda en el suelo y otro atacante la recoge
local att2, att2Root, att2Hum = player("Atacante2", 3, teamA, Vector3.new(0, 3, 10))
attRoot.Position = Vector3.new(0, 3, 0)
defRoot.Position = Vector3.new(200, 3, 0)
Bomb.Start(teamA, teamB)
task.wait(0.4)
local carrierName = RS:GetAttribute("Bomb_Carrier")
check(carrierName == "Atacante" or carrierName == "Atacante2", "un atacante lleva la bomba (" .. tostring(carrierName) .. ")")
local cHum, otherRoot, otherName
if carrierName == "Atacante" then cHum, otherRoot, otherName = attHum, att2Root, "Atacante2" else cHum, otherRoot, otherName = att2Hum, attRoot, "Atacante" end
otherRoot.Position = Vector3.new(82, 3, -58)
task.wait(1)
check((RS:GetAttribute("Bomb_Progress") or 0) == 0 and not Bomb.Planted, "sin la bomba no se puede plantar")
-- (suelo bajo el portador: el simulador no tiene rayos si no se le dan)
local groundMaterial = require("@lune/roblox").Enum.Material.Plastic
mock.raycastImpl = function(origin, direction)
	return { Instance = map, Position = Vector3.new(origin.X, 0, origin.Z), Normal = Vector3.new(0, 1, 0), Distance = origin.Y, Material = groundMaterial }
end
cHum.Health = 0
task.wait(0.4)
check(typeof(RS:GetAttribute("Bomb_Dropped")) == "Vector3" and RS:GetAttribute("Bomb_Carrier") == nil, "al caer el portador la bomba queda en el suelo")
check(game.Workspace:FindFirstChild("DroppedBomb") ~= nil, "se ve la bomba en el suelo")
otherRoot.Position = RS:GetAttribute("Bomb_Dropped")
task.wait(0.4)
check(RS:GetAttribute("Bomb_Carrier") == otherName and RS:GetAttribute("Bomb_Dropped") == nil, "otro atacante la recoge")
check(game.Workspace:FindFirstChild("DroppedBomb") == nil, "y desaparece del suelo")
otherRoot.Position = Vector3.new(82, 3, -58)
task.wait(4.6)
check(Bomb.Planted and RS:GetAttribute("Bomb_Carrier") == nil, "el nuevo portador la planta")
cHum.Health = 100
Bomb.Stop()
-- Si el portador cae en la lava, la bomba pasa a otro atacante en el acto
attRoot.Position = Vector3.new(0, 3, 0)
att2Root.Position = Vector3.new(0, 3, 10)
Bomb.Start(teamA, teamB)
task.wait(0.4)
local first = RS:GetAttribute("Bomb_Carrier")
groundMaterial = require("@lune/roblox").Enum.Material.CrackedLava
if first == "Atacante" then attHum.Health = 0 else att2Hum.Health = 0 end
task.wait(0.4)
check(RS:GetAttribute("Bomb_Dropped") == nil and RS:GetAttribute("Bomb_Carrier") ~= nil and RS:GetAttribute("Bomb_Carrier") ~= first, "cae en la lava: la bomba pasa a otro atacante")
attHum.Health = 100; att2Hum.Health = 100
mock.raycastImpl = nil
Bomb.Stop()
check(RS:GetAttribute("Bomb_Carrier") == nil and RS:GetAttribute("Bomb_Dropped") == nil, "al acabar se limpia el portador")
att2.Parent = nil
-- Bots: los atacantes van al mismo sitio y los defensores a los suyos
att.Parent = nil; def.Parent = nil
table.clear(mock.players)
RS:SetAttribute("Mode", "SND")
RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Playing")
Bomb.Start(teamA, teamB)
Bots.Init()
task.wait(GameConfig.Bots.FillTo + 3)
local attackSites, defendNear, attackers, defenders = {}, 0, 0, 0
local sites = { A = RS:GetAttribute("Bomb_A_Position"), B = RS:GetAttribute("Bomb_B_Position") }
for _, agent in Bots.Agents do
	if agent.GoalPosition then
		for letter, pos in sites do
			if (agent.GoalPosition - pos).Magnitude <= 6 then
				if agent.Team == teamA then
					attackSites[letter] = true
					attackers += 1
				else
					defendNear += 1
				end
			end
		end
		if agent.Team == teamB then defenders += 1 end
	end
end
local count = 0
for _ in attackSites do count += 1 end
check(attackers >= 3 and count == 1, "los atacantes van juntos a un sitio (" .. attackers .. " bots)")
check(type(RS:GetAttribute("Bomb_Carrier")) == "string", "un bot atacante lleva la bomba (" .. tostring(RS:GetAttribute("Bomb_Carrier")) .. ")")
check(defendNear >= 3, "los defensores protegen los sitios (" .. defendNear .. "/" .. defenders .. ")")
print("BOMBA OK")
process.exit(0)
