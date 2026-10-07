-- Apariciones dinámicas: lejos de los enemigos y cerca del equipo; solo en los modos que tocan
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Vector3, BrickColor = roblox.Vector3, roblox.BrickColor
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local SpawnPicker = req(game.ServerScriptService.Server.Modules.SpawnPicker)
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", BrickColor.new("Bright red")
teamB.Name, teamB.TeamColor = "Azul", BrickColor.new("Bright blue")
teamA.Parent, teamB.Parent = Teams, Teams
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
for _, x in { -100, 0, 100 } do
	local p = mock.new("Part"); p.Name = "FFASpawn"; p.Position = Vector3.new(x, 0, 0); p.Parent = map
end
local s = mock.new("SpawnLocation"); s.TeamColor = teamA.TeamColor; s.Position = Vector3.new(-300, 0, 0); s.Parent = map
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local function bot(team, pos)
	local m = mock.new("Model"); m:SetAttribute("Team", team)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local r = mock.new("Part"); r.Name = "HumanoidRootPart"; r.Position = pos; r.Parent = m
	m.Parent = bots
end
bot("Azul", Vector3.new(95, 0, 5)) -- enemigo junto al punto de la derecha
bot("Azul", Vector3.new(10, 0, 0)) -- y otro en el centro
bot("Rojo", Vector3.new(-90, 0, 0)) -- compañero a la izquierda
RS:SetAttribute("TeamMode", true)
RS:SetAttribute("Mode", "TDM")
check(SpawnPicker.Enabled(), "activas en Duelo por equipos")
local counts = {}
for _ = 1, 30 do
	local p = SpawnPicker.Pick(teamA, nil)
	counts[p.X] = (counts[p.X] or 0) + 1
end
check((counts[-100] or 0) >= 20, "casi siempre junto a su compañero (" .. (counts[-100] or 0) .. "/30; el resto en la base, también segura)")
check((counts[-100] or 0) + (counts[-300] or 0) == 30, "siempre en un punto seguro")
check((counts[100] or 0) == 0 and (counts[0] or 0) == 0, "nunca junto a un enemigo")
RS:SetAttribute("Mode", "CTF")
check(not SpawnPicker.Enabled(), "en Captura la bandera, siempre en la base")
RS:SetAttribute("Mode", "TDM")
RS:SetAttribute("TeamMode", false)
check(not SpawnPicker.Enabled(), "en todos contra todos lo hace el sistema de siempre")
print("APARICIONES OK")
