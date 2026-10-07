-- Arranca el cliente entero (Main.client) en el simulador: ningún sistema debe fallar al iniciar
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", roblox.BrickColor.new("Really red")
teamB.Name, teamB.TeamColor = "Azul", roblox.BrickColor.new("Really blue")
teamA.Parent, teamB.Parent = Teams, Teams
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId, me.Team = "Yo", "Yo", 1, teamA
me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
PlayerData.WaitFor(me, 3)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
RS:SetAttribute("TeamA", "Rojo"); RS:SetAttribute("TeamB", "Azul"); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Intermission"); RS:SetAttribute("Mode", "TDM"); RS:SetAttribute("ModeName", "Duelo por equipos")
RS:SetAttribute("EventName", "Halloween"); game.ReplicatedStorage:SetAttribute("EventId", "Halloween2026"); RS:SetAttribute("EventGoal", 100)
local warnings = {}
mock.onWarn = function(...)
	table.insert(warnings, table.concat({ ... }, " "))
end
local ok, err = pcall(req, game.StarterPlayer.Client.Main)
print("Main.client:", ok, err)
task.wait(3)
-- Datos del servidor
local view
for _, sent in mock.sent do
	if sent.Remote == "DataUpdate" then view = sent.Args[1] end
end
local Remotes = req(RS.Shared.Remotes)
if view then
	Remotes.DataUpdate.OnClientEvent:Fire(view)
end
task.wait(2)
-- Entra en partida: personaje, estado Playing e Infección
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100; hum.Parent = char
for _, n in { "HumanoidRootPart", "Head", "RightHand", "UpperTorso" } do
	local part = mock.new("Part"); part.Name = n; part.Position = roblox.Vector3.new(0, 3, 0); part.Parent = char
end
char.Parent = game.Workspace
me.Character = char
me.CharacterAdded:Fire(char)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
RS:SetAttribute("State", "Playing")
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end

local cam = game.Workspace.CurrentCamera
cam.CFrame = roblox.CFrame.new(0, 5, 0)
local RunService = game:GetService("RunService")
hum.MoveDirection = roblox.Vector3.new(0, 0, 0)
hum.FloorMaterial = roblox.Enum.Material.Plastic
local Minimap = req(game.StarterPlayer.Client.Modules.Minimap)
local function beat() Minimap.Update() end
-- Mapa: un muro (sale en el plano) y un suelo (no sale)
local map = mock.new("Folder"); map.Name = "Map"
local wall = mock.new("Part"); wall.Name = "Wall"; wall.Size = roblox.Vector3.new(20, 10, 2); wall.CFrame = roblox.CFrame.new(10, 5, 0); wall.CanCollide = true; wall.Transparency = 0; wall.Parent = map
local floor = mock.new("Part"); floor.Name = "Floor"; floor.Size = roblox.Vector3.new(200, 1, 200); floor.CFrame = roblox.CFrame.new(0, -0.5, 0); floor.CanCollide = true; floor.Transparency = 0; floor.Parent = map
map.Parent = game.Workspace
beat()
local gui = pg:FindFirstChild("Minimap")
check(gui ~= nil and gui.Enabled, "minimapa visible en partida")
local frame = gui:FindFirstChildOfClass("Frame")
local function find(container, name)
	for _, d in container:GetDescendants() do if d.Name == name then return d end end
end
local shapes = find(frame, "Shapes")
check(shapes and #shapes:GetChildren() == 1, "el muro sale en el plano (y el suelo no): " .. (shapes and #shapes:GetChildren() or -1))
local function visibleDots(color)
	local n = 0
	for _, d in frame:GetChildren() do
		if d.ClassName == "Frame" and d.Name ~= "Shapes" and d.Visible and d.ZIndex == 3 and (not color or d.BackgroundColor3 == color) then n += 1 end
	end
	return n
end
-- Compañero (bot rojo) y enemigo (bot azul)
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local function bot(name, team, pos)
	local m = mock.new("Model"); m.Name = name; m:SetAttribute("Team", team)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local r = mock.new("Part"); r.Name = "HumanoidRootPart"; r.Position = pos; r.Parent = m
	m.Parent = bots
	return m
end
local friend = bot("Bot Amigo", "Rojo", roblox.Vector3.new(20, 3, 10))
local foe = bot("Bot Rival", "Azul", roblox.Vector3.new(-30, 3, 20))
beat()
check(visibleDots(roblox.Color3.fromRGB(70, 160, 255)) == 1, "compañero en azul")
check(visibleDots(roblox.Color3.fromRGB(255, 40, 40)) == 0, "el enemigo no sale si no dispara")
local tool = mock.new("Tool"); tool:SetAttribute("Weapon", "ARX27"); tool.Parent = foe
local Remotes = req(RS.Shared.Remotes)
Remotes.ShotFX.OnClientEvent:Fire(tool, { roblox.Vector3.new(0, 3, 0) })
beat()
check(visibleDots(roblox.Color3.fromRGB(255, 40, 40)) == 1, "el enemigo que dispara sale en rojo")
local foe2 = bot("Bot Sigilo", "Azul", roblox.Vector3.new(-10, 3, -20))
local silent = mock.new("Tool"); silent:SetAttribute("Weapon", "GhostlineXR"); silent.Parent = foe2
Remotes.ShotFX.OnClientEvent:Fire(silent, { roblox.Vector3.new(0, 3, 0) })
beat()
check(visibleDots(roblox.Color3.fromRGB(255, 40, 40)) == 1, "con silenciador no sale")
local friendTool = mock.new("Tool"); friendTool:SetAttribute("Weapon", "ARX27"); friendTool.Parent = friend
Remotes.ShotFX.OnClientEvent:Fire(friendTool, { roblox.Vector3.new(0, 3, 0) })
beat()
check(visibleDots(roblox.Color3.fromRGB(255, 40, 40)) == 1, "los disparos de tu equipo no salen en rojo")
task.wait(2.7)
beat()
check(visibleDots(roblox.Color3.fromRGB(255, 40, 40)) == 0, "el punto rojo se borra a los pocos segundos")
-- Zona de control
RS:SetAttribute("ZonePosition", roblox.Vector3.new(500, 0, 0))
beat()
check(visibleDots(roblox.Color3.fromRGB(255, 210, 40)) == 1, "la zona sale (pegada al borde si está lejos)")
-- Botón del pase debajo del minimapa
task.wait(0.5)
local menuGui = pg:FindFirstChild("Menu")
local pass
for _, d in menuGui:GetDescendants() do if d.ClassName == "TextButton" and tostring(d.Text):find("PASE") then pass = d end end
check(pass and pass.Position.Y.Offset >= ClientState.MinimapBottom, "PASE · TIENDA queda debajo del minimapa")
-- Dominio: insignias A B C y letras en el minimapa
RS:SetAttribute("Dom_A_Position", roblox.Vector3.new(-20, 0, 0))
RS:SetAttribute("Dom_B_Position", roblox.Vector3.new(0, 0, 30))
RS:SetAttribute("Dom_C_Position", roblox.Vector3.new(400, 0, 0))
RS:SetAttribute("Dom_A_Owner", "Rojo")
RS:SetAttribute("Dom_B_Capturing", "Azul")
RS:SetAttribute("Dom_B_Progress", 0.5)
local DominationHUD = req(game.StarterPlayer.Client.Modules.DominationHUD)
DominationHUD.Update()
local domGui = pg:FindFirstChild("DominationHUD")
check(domGui and domGui.Enabled, "Dominio: insignias A B C visibles")
local boxA = find(domGui, "A")
local boxB = find(domGui, "B")
check(boxA.BackgroundColor3 == teamA.TeamColor.Color, "A con el color de su dueño")
local barB
for _, d in boxB:GetChildren() do if d.ClassName == "Frame" then barB = d end end
check(barB and barB.Visible and math.abs(barB.Size.X.Scale - 0.5) < 0.01, "B con la barra de captura a la mitad")
beat()
local letters = 0
for _, d in frame:GetDescendants() do if d.Name == "Letter" and d.Text ~= "" then letters += 1 end end
check(letters == 3, "las tres letras en el minimapa (" .. letters .. ")")
-- Presentación de la partida: al pasar a "Playing", los dos equipos
local bstats = mock.new("Folder"); bstats.Name = "BotStats"; bstats.Parent = RS
for i, team in { "Rojo", "Azul", "Azul" } do
	local e = mock.new("Folder"); e.Name = "Bot " .. i; e:SetAttribute("Team", team); e.Parent = bstats
end
RS:SetAttribute("MapName", "Encrucijada")
RS:SetAttribute("State", "Ended")
RS:SetAttribute("State", "Playing")
-- (la presentación de equipos es ahora la del flujo: Flow/Screens/TeamIntro, ver flow.luau)
-- Radar enemigo: borde rojo y aviso
local function radarLabel()
	for _, d in frame:GetChildren() do
		if d.ClassName == "TextLabel" and d.Text == "📡 RADAR ENEMIGO" then return d end
	end
end
check(radarLabel() and not radarLabel().Visible, "sin radar enemigo no hay aviso")
RS:SetAttribute("Radar_Azul", game.Workspace:GetServerTimeNow() + 10)
task.wait(0.35); beat()
check(radarLabel().Visible, "radar enemigo: aviso en el minimapa")
RS:SetAttribute("Radar_Azul", nil)
RS:SetAttribute("Radar_Rojo", game.Workspace:GetServerTimeNow() + 10)
task.wait(0.35); beat()
check(not radarLabel().Visible, "el radar de tu equipo no avisa")
RS:SetAttribute("Radar_Rojo", nil)
-- En el menú de inicio no se ve
ClientState.InMainMenu = true
beat()
check(not gui.Enabled, "oculto en la pantalla de inicio")
print("MINIMAPA OK")
process.exit(0)
