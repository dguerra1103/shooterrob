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
local tool = mock.new("Tool"); tool.Name = "ARX27"
tool:SetAttribute("Weapon", "ARX27"); tool:SetAttribute("Slot", 1); tool:SetAttribute("Ammo", 30); tool:SetAttribute("Reserve", 90)
tool.Parent = char
print("dbg2", char:FindFirstChildOfClass("Tool"), tool:IsA("Tool"))
pcall(function() char.ChildAdded:Fire(tool) end)
task.wait(0.5)
local render = mock.renderSteps.WeaponViewmodel
check(render ~= nil, "render del arma enganchado")
for _ = 1, 10 do render(1 / 60) end
local function pitch() local x = cam.CFrame:ToEulerAnglesYXZ() return math.deg(x) end
print("dbg", ClientState.CurrentDef and ClientState.CurrentDef.DisplayName, ClientState.IsBlocked(), ClientState.Frozen(), mock.actions.Fire ~= nil)
local p0 = pitch()
-- Ráfaga de 8 disparos
mock.actions.Fire("Fire", roblox.Enum.UserInputState.Begin, {})
for _ = 1, 50 do render(1 / 60); task.wait(1 / 60) end
mock.actions.Fire("Fire", roblox.Enum.UserInputState.End, {})
for _ = 3, 6 do render(1 / 60) end
local pTop = pitch()
print(string.format("mira: antes %.2f°, tras la ráfaga %.2f°", p0, pTop))
check(pTop > p0 + 1, "el retroceso sube la mira")
task.wait(0.2)
for _ = 1, 90 do render(1 / 60) end
local pAfter = pitch()
print(string.format("tras soltar: %.2f°", pAfter))
check(pAfter < pTop - 0.3 and pAfter > p0, "al soltar, la mira recupera parte (no toda)")
-- Salida del sprint: corriendo, el disparo espera a que el arma suba (y no se pierde)
task.wait(0.6)
for _, key in { "MenuOpen", "VoteOpen", "InMainMenu", "Dead", "EmoteMenuOpen", "TutorialOpen", "WheelOpen", "NewsOpen" } do
	ClientState[key] = false
end
ClientState.Sprinting = true
for _ = 1, 40 do render(1 / 60) end
render(1 / 60)
local ammo0 = ClientState.Ammo
mock.actions.Fire("Fire", roblox.Enum.UserInputState.Begin, {})
mock.actions.Fire("Fire", roblox.Enum.UserInputState.End, {})
render(1 / 60)
check(ClientState.Ammo == ammo0, "corriendo no dispara al instante (el arma está bajada)")
check(not ClientState.Sprinting, "apretar el gatillo deja de correr")
for _ = 1, 15 do render(1 / 60) end
check(ClientState.Ammo == ammo0 - 1, "el disparo sale en cuanto sube el arma (" .. ammo0 .. " -> " .. ClientState.Ammo .. ")")
-- Disparo automático (modo sencillo): con la mira sobre un enemigo dispara solo; sobre un compañero, no
task.wait(0.6)
ClientState.Settings = ClientState.Settings or {}
ClientState.Settings.AutoFire = 1
local function botModel(team)
	local m = mock.new("Model"); m:SetAttribute("Team", team)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local p = mock.new("Part"); p.Name = "HumanoidRootPart"; p.Parent = m
	m.Parent = game.Workspace
	return m, p
end
local enemyBot, enemyPart = botModel("Azul")
local friendBot, friendPart = botModel("Rojo")
local aimAt = enemyPart
mock.raycastImpl = function(origin, direction)
	return { Instance = aimAt, Position = origin + direction.Unit * 20, Normal = roblox.Vector3.new(0, 0, 1), Distance = 20, Material = roblox.Enum.Material.Plastic }
end
local a0 = ClientState.Ammo
for _ = 1, 20 do render(1 / 60); task.wait(1 / 60) end
check(ClientState.Ammo < a0, "con un enemigo en la mira dispara solo (" .. a0 .. " -> " .. ClientState.Ammo .. ")")
aimAt = friendPart
task.wait(0.3)
render(1 / 60)
local a1 = ClientState.Ammo
for _ = 1, 20 do render(1 / 60); task.wait(1 / 60) end
check(ClientState.Ammo == a1, "con un compañero en la mira no dispara")
-- Enemigo con protección de aparición: no gasta balas en el escudo
local shielded, shieldedPart = botModel("Azul")
local ff = mock.new("ForceField"); ff.Parent = shielded
aimAt = shieldedPart
render(1 / 60)
local a1b = ClientState.Ammo
for _ = 1, 20 do render(1 / 60); task.wait(1 / 60) end
check(ClientState.Ammo == a1b, "con la protección de aparición no dispara solo")
ClientState.Settings.AutoFire = 0
aimAt = enemyPart
render(1 / 60)
local a2 = ClientState.Ammo
for _ = 1, 20 do render(1 / 60); task.wait(1 / 60) end
check(ClientState.Ammo == a2, "desactivado en Ajustes: no dispara solo")
mock.raycastImpl = nil
print("DISPAROS OK")
process.exit(0)
