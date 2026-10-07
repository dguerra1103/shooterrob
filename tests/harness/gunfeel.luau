-- Fase 2 (gunplay) en el cliente: eventos del arma, recarga autoritativa, cancelaciones, apuntado por tipo, FOV y casquillos según la calidad
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
local WeaponFeel = req(RS.Shared.WeaponFeel)
local Weapons = req(RS.Shared.Weapons)
-- (otros módulos del cliente abren y cierran sus pantallas solos: se desbloquea antes de cada paso)
local function unblock()
	for _, key in { "MenuOpen", "VoteOpen", "InMainMenu", "Dead", "EmoteMenuOpen", "TutorialOpen", "WheelOpen", "NewsOpen" } do
		ClientState[key] = false
	end
end
unblock()
ClientState.Settings = ClientState.Settings or {}
ClientState.Settings.AutoFire = 0
-- Momentos del arma (WeaponEvent)
local events = {}
ClientState.WeaponEvent.Event:Connect(function(name, weapon, info)
	table.insert(events, { Name = name, Weapon = weapon, Info = info })
end)
local function lastEvent(name)
	for i = #events, 1, -1 do
		if events[i].Name == name then return events[i] end
	end
	return nil
end
local render
local function frames(n, dt)
	for _ = 1, n do render(dt or 1 / 60) end
end
local current
local function equip(name, ammo)
	if current then
		current.Parent = nil
		char.ChildRemoved:Fire(current)
	end
	local tool = mock.new("Tool"); tool.Name = name
	tool:SetAttribute("Weapon", name); tool:SetAttribute("Slot", 1)
	tool:SetAttribute("Ammo", ammo or Weapons.Get(name).MagSize); tool:SetAttribute("Reserve", 90)
	tool.Parent = char
	char.ChildAdded:Fire(tool)
	current = tool
	return tool
end
local function tap(action)
	mock.actions[action](action, roblox.Enum.UserInputState.Begin, { UserInputType = roblox.Enum.UserInputType.MouseButton1 })
	mock.actions[action](action, roblox.Enum.UserInputState.End, { UserInputType = roblox.Enum.UserInputType.MouseButton1 })
end

-- 1) Sacar el arma: evento Equip con su nombre
local tool = equip("ARX27")
task.wait(0.4)
render = mock.renderSteps.WeaponViewmodel
check(render ~= nil, "render del arma enganchado")
frames(30)
check(lastEvent("Equip") and lastEvent("Equip").Weapon == "ARX27", "evento Equip (ARX27)")

-- 2) Disparo: evento Fire y casquillo según la calidad (Alta: sí; Baja: no)
local fxFolder = game.Workspace:FindFirstChild("ClientFX")
local function casings()
	local n = 0
	for _, part in fxFolder:GetChildren() do
		if part:IsA("BasePart") and part.Material == roblox.Enum.Material.Metal and part.CanCollide == true then n += 1 end
	end
	return n
end
ClientState.EffectiveQuality = "Alta"
unblock()
local c0 = casings()
tap("Fire")
frames(2)
check(lastEvent("Fire") ~= nil, "evento Fire")
check(casings() == c0 + 1, "calidad Alta: sale un casquillo")
task.wait(0.3)
ClientState.EffectiveQuality = "Baja"
local c1 = casings()
tap("Fire")
frames(2)
check(casings() == c1, "calidad Baja: sin casquillos")
ClientState.EffectiveQuality = "Alta"

-- 3) Recarga: la munición solo sube cuando la confirma el servidor (atributo Ammo)
task.wait(0.3)
local before = ClientState.Ammo
check(before < Weapons.Get("ARX27").MagSize, "se gastaron balas (" .. before .. ")")
tool:SetAttribute("Ammo", before) -- (el servidor confirma los disparos: aquí no hay servidor)
frames(1)
unblock()
tap("Reload")
frames(2)
local reloadEvent = lastEvent("ReloadStart")
check(reloadEvent and reloadEvent.Info.Empty == false and math.abs(reloadEvent.Info.Duration - Weapons.ReloadDuration(Weapons.Get("ARX27"), false)) < 1e-6,
	"evento ReloadStart (recarga táctica, con su duración)")
task.wait(Weapons.ReloadDuration(Weapons.Get("ARX27"), false) + 0.2)
frames(5)
check(ClientState.Ammo == before, "al acabar la animación no se regalan balas (" .. ClientState.Ammo .. ")")
tool:SetAttribute("Ammo", 30)
frames(2)
check(ClientState.Ammo == 30, "las balas llegan cuando el servidor las confirma")

-- 4) Cambiar de arma a mitad de recarga: la recarga se cancela
tool:SetAttribute("Ammo", 10)
frames(2)
tap("Reload")
frames(2)
local startCount = #events
equip("Specter9")
local cancelled = false
for i = startCount + 1, #events do
	if events[i].Name == "ReloadCancel" then cancelled = true end
end
check(cancelled, "cambiar de arma cancela la recarga (evento ReloadCancel)")
check(not ClientState.Reloading, "y ya no se está recargando")

-- 5) Apuntar: cada tipo a su ritmo (subfusil > fusil > ametralladora) y el FOV vuelve al soltar
local baseFov = cam.FieldOfView
local function aimAfter(name, n)
	equip(name)
	task.wait(0.05)
	unblock()
	frames(40)
	mock.actions.Aim("Aim", roblox.Enum.UserInputState.Begin, { UserInputType = roblox.Enum.UserInputType.MouseButton2 })
	frames(n)
	local alpha = ClientState.AimAlpha
	mock.actions.Aim("Aim", roblox.Enum.UserInputState.End, { UserInputType = roblox.Enum.UserInputType.MouseButton2 })
	frames(60)
	return alpha
end
local smgAlpha, rifleAlpha, lmgAlpha = aimAfter("Specter9", 6), aimAfter("ARX27", 6), aimAfter("TitanLMG", 6)
print(string.format("apuntado tras 0,1 s: subfusil %.2f, fusil %.2f, ametralladora %.2f", smgAlpha, rifleAlpha, lmgAlpha))
check(smgAlpha > rifleAlpha and rifleAlpha > lmgAlpha, "apuntar: subfusil más rápido que fusil y fusil que ametralladora")
check(ClientState.AimAlpha < 0.01, "al soltar se deja de apuntar")
check(math.abs(cam.FieldOfView - baseFov) < 0.5, string.format("el FOV vuelve al de siempre (%.1f / %.1f)", cam.FieldOfView, baseFov))

-- 6) Inspeccionar (V) y cancelar corriendo
equip("ARX27")
task.wait(0.05)
unblock()
frames(40)
mock.actions.Inspect("Inspect", roblox.Enum.UserInputState.Begin, {})
check(lastEvent("Inspect") ~= nil, "V inspecciona el arma (evento Inspect)")
ClientState.Sprinting = true
frames(30)
check(lastEvent("InspectCancel") ~= nil, "correr cancela la inspección")
ClientState.Sprinting = false
frames(30)

-- 7) Morir: sin restos de apuntado ni de golpes de cámara; el FOV vuelve
unblock()
mock.actions.Aim("Aim", roblox.Enum.UserInputState.Begin, { UserInputType = roblox.Enum.UserInputType.MouseButton2 })
frames(20)
tap("Fire")
frames(1)
hum.Health = 0
hum.Died:Fire()
frames(60)
check(ClientState.AimAlpha < 0.01, "muerto ya no se apunta")
check(math.abs(cam.FieldOfView - baseFov) < 0.5, string.format("muerto el FOV vuelve al de siempre (%.1f)", cam.FieldOfView))
check((ClientState.FovKick or 0) == 0 and (ClientState.Shake or 0) == 0, "sin empujones de FOV ni temblores pendientes")
print("GUNPLAY CLIENTE OK")
process.exit(0)
