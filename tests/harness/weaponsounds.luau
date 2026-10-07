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
local Sounds = req(RS.Shared.Sounds)
local played = {}
local origPlay = Sounds.Play
Sounds.Play = function(name, parent, ...)
	local sound = origPlay(name, parent, ...)
	table.insert(played, { Name = name, Parent = parent, Sound = sound, Time = os.clock() })
	return sound
end
local function count(name) local n = 0 for _, p in played do if p.Name == name then n += 1 end end return n end
local function clear() table.clear(played) end
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
clear()
pcall(function() char.ChildAdded:Fire(tool) end)
check(count("Equip") == 1, "suena al sacar el arma")
task.wait(0.5)
local render = mock.renderSteps.WeaponViewmodel
for _ = 1, 10 do render(1 / 60) end
-- Un disparo: cuerpo + estampido + mecanismo, todos en el grupo de armas
clear()
mock.actions.Fire("Fire", roblox.Enum.UserInputState.Begin, {})
render(1 / 60)
mock.actions.Fire("Fire", roblox.Enum.UserInputState.End, {})
print("disparo:", count("Shot"), count("Boom"), count("Mech"))
check(count("Shot") == 1 and count("Boom") == 1 and count("Mech") == 1, "disparo con 3 capas (cuerpo, estampido, mecanismo)")
local group = game:GetService("SoundService"):FindFirstChild("Armas")
check(group ~= nil and group:FindFirstChildOfClass("CompressorSoundEffect") ~= nil and group:FindFirstChildOfClass("ReverbSoundEffect") ~= nil, "grupo Armas con compresor y eco")
check(played[1].Sound and played[1].Sound.SoundGroup == group, "el disparo va por el grupo Armas")
check(count("LowAmmo") == 0, "sin aviso con el cargador lleno")
-- Pocas balas
tool:SetAttribute("Ammo", 5)
tool.AttributeChanged:Fire("Ammo")
task.wait(0.3)
clear()
mock.actions.Fire("Fire", roblox.Enum.UserInputState.Begin, {})
render(1 / 60)
mock.actions.Fire("Fire", roblox.Enum.UserInputState.End, {})
check(count("LowAmmo") == 1, "aviso de pocas balas")
-- Recarga en vacío: sacar, meter y montar
tool:SetAttribute("Ammo", 0)
tool.AttributeChanged:Fire("Ammo")
task.wait(0.3)
clear()
mock.actions.Reload("Reload", roblox.Enum.UserInputState.Begin, {})
task.wait(1.9 * 0.3)
check(count("MagOut") == 1 and count("MagIn") == 0, "primero sale el cargador")
task.wait(1.9 * 0.7)
print("recarga:", count("MagOut"), count("MagIn"), count("Bolt"))
check(count("MagIn") == 1 and count("Bolt") == 1, "luego entra el nuevo y se monta el arma")
-- Disparo de un enemigo lejos: con retraso y apagado
local enemy = mock.new("Model"); enemy.Name = "Bot"; enemy:SetAttribute("Team", "Azul"); enemy.Parent = game.Workspace
local etool = mock.new("Tool"); etool.Name = "Signal7"; etool:SetAttribute("Weapon", "Signal7")
local handle = mock.new("Part"); handle.Name = "Handle"; handle.Position = roblox.Vector3.new(0, 5, -400); handle.Parent = etool
local muzzle = mock.new("Attachment"); muzzle.Name = "Muzzle"; muzzle.Parent = handle
muzzle.WorldPosition = roblox.Vector3.new(0, 5, -400)
etool.Parent = enemy
cam.CFrame = roblox.CFrame.new(0, 5, 0)
clear()
-- La bala pasa a 3 studs de la cámara y sigue
Remotes.ShotFX.OnClientEvent:Fire(etool, { roblox.Vector3.new(3, 5, 200) })
check(count("ShotHeavy") == 0, "de lejos el disparo aún no se oye (el sonido viaja)")
check(count("Whiz") == 1, "la bala que pasa rozando hace fiuu")
task.wait(0.6)
check(count("ShotHeavy") == 1 and count("Boom") == 1 and count("Mech") == 0, "llega el disparo lejano (sin clic del mecanismo)")
local body
for _, p in played do if p.Name == "ShotHeavy" then body = p.Sound end end
check(body and body:FindFirstChildOfClass("EqualizerSoundEffect") ~= nil, "el disparo lejano suena apagado")
-- Un compañero no hace fiuu
local friend = mock.new("Model"); friend:SetAttribute("Team", "Rojo"); friend.Parent = game.Workspace
etool.Parent = friend
task.wait(0.2)
clear()
Remotes.ShotFX.OnClientEvent:Fire(etool, { roblox.Vector3.new(3, 5, 200) })
check(count("Whiz") == 0, "las balas de tu equipo no hacen fiuu")
-- Bala que acaba en ti (te da): sin fiuu
etool.Parent = enemy
task.wait(0.2)
clear()
Remotes.ShotFX.OnClientEvent:Fire(etool, { roblox.Vector3.new(0, 4, 1) })
check(count("Whiz") == 0, "si te da, no hace fiuu")
print("SONIDOS OK")
process.exit(0)
