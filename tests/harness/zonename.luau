-- Nombres de zona: en los mapas 5v5 cada sitio tiene nombre (bases, avenida, edificios con cartel) y
-- en los demás, la parte del mapa
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local V = roblox.Vector3.new
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local MapBuilder = req(game.ServerScriptService.Server.Modules.MapBuilder)
local ZoneName = req(game.StarterPlayer.Client.Modules.ZoneName)
-- (readMap es interno: se prueba con Update sobre un personaje)
ZoneName.Init()
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local char = mock.new("Model"); char.Name = "Yo"
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = char
char.Parent = game.Workspace
me.Character = char
local label
for _, d in pg:GetDescendants() do if d.__className == "TextLabel" and d.Parent.Name == "ZoneName" then label = d end end
local function at(p)
	root.Position = p; root.CFrame = roblox.CFrame.new(p)
	ZoneName.Update(1)
	return (string.gsub(label.Text, "📍 ", ""))
end
MapBuilder.Build("Construction")
check(at(V(-131, 3, 0)) == "BASE ROJA", "base roja (" .. at(V(-131, 3, 0)) .. ")")
check(at(V(131, 3, 0)) == "BASE AZUL", "base azul")
check(at(V(0, 5, 12)) == "TORRE", "torre (" .. at(V(0, 5, 12)) .. ")")
check(at(V(0, 23, 8)) == "SEGUNDA DE LA TORRE", "arriba de la torre (" .. at(V(0, 23, 8)) .. ")")
check(at(V(-77, 3, 0)) == "ALMACÉN", "almacén (" .. at(V(-77, 3, 0)) .. ")")
check(at(V(77, 3, 0)) == "ALMACÉN", "el almacén del otro lado")
check(at(V(-70, 3, -45)) == "CONTENEDORES", "contenedores (" .. at(V(-70, 3, -45)) .. ")")
check(at(V(-10, 3, -50)) == "ESTRUCTURA", "estructura (" .. at(V(-10, 3, -50)) .. ")")
check(at(V(-10, 13, -50)) == "FORJADO", "forjado de la estructura (" .. at(V(-10, 13, -50)) .. ")")
check(at(V(-20, 13, -105)) == "TERRAZA A", "terraza A (" .. at(V(-20, 13, -105)) .. ")")
check(at(V(-30, 13, 100)) == "ENTREPLANTA B", "entreplanta B")
check(at(V(-40, 3, 0)) == "PATIO", "patio (" .. at(V(-40, 3, 0)) .. ")")
game.ReplicatedStorage:SetAttribute("Mode", "SND")
check(at(V(0, 3, -88)) == "SITIO A", "sitio de bomba (" .. at(V(0, 3, -88)) .. ")")
check(at(V(0, 3, 96)) == "SITIO B", "sitio B (" .. at(V(0, 3, 96)) .. ")")
game.ReplicatedStorage:SetAttribute("Mode", "TDM")
check(at(V(0, 3, -88)) == "PLAZA A", "fuera de Buscar y destruir, el nombre de la zona (" .. at(V(0, 3, -88)) .. ")")
check(at(V(0, 3, 96)) == "NAVE B", "nave B (" .. at(V(0, 3, 96)) .. ")")
print("ZONAS OK")
process.exit(0)
