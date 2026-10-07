-- Fase 9 (ARX-27 gold standard) en el cliente: brazos con IK sobre las manos, ADS centrado, recarga
-- táctica y vacía con sus marcas en orden (y la palanca de carga), inspección y sus cancelaciones,
-- gesto de reposo, cambio de arma sin restos y limpieza al morir. No se mira nada en pantalla: solo la
-- lógica y las posiciones.
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


local WeaponVisual = req(RS.Shared.WeaponVisual)
local def = Weapons.Get("ARX27")
local visual = WeaponVisual.Get("ARX27", def)
local function names(from)
	local out = {}
	for i = from, #events do
		table.insert(out, events[i].Name)
	end
	return out
end
local function has(list, name)
	return table.find(list, name) ~= nil
end
local function order(list, a, b)
	local ia, ib = table.find(list, a), table.find(list, b)
	return ia ~= nil and ib ~= nil and ia < ib
end
local function viewmodels()
	local n = 0
	for _, child in cam:GetChildren() do
		if child.Name == "Viewmodel" then n += 1 end
	end
	return n
end
local function vm()
	return cam:FindFirstChild("Viewmodel")
end
local function part(model, name, side)
	for _, p in model:GetChildren() do
		if p.Name == name and (side == nil or p:GetAttribute("Side") == side) then return p end
	end
	return nil
end

-- 1) Sacar el ARX-27: brazos con codo, manos en su sitio
local tool = equip("ARX27")
task.wait(0.4)
render = mock.renderSteps.WeaponViewmodel
unblock()
frames(40)
local model = vm()
check(model ~= nil and part(model, "UpperArm", "Left") and part(model, "Forearm", "Right") and part(model, "Glove", "Left") and part(model, "Cuff", "Right"),
	"brazos con brazo, antebrazo, guante y puño")
local handle = model.PrimaryPart
local function handGap(side)
	local forearm = part(model, "Forearm", side)
	local tip = forearm.CFrame * roblox.CFrame.new(0, 0, -forearm.Size.Z / 2)
	local hand = handle.CFrame * (side == "Left" and def.LeftHand or def.RightHand)
	return (tip.Position - hand).Magnitude
end
check(handGap("Left") < 0.02 and handGap("Right") < 0.02, string.format("las manos agarran el arma (%.3f / %.3f)", handGap("Left"), handGap("Right")))
local function elbowBend(side)
	local upper = part(model, "UpperArm", side)
	local forearm = part(model, "Forearm", side)
	return upper.CFrame.LookVector:Dot(forearm.CFrame.LookVector)
end
check(elbowBend("Left") < 0.999 and elbowBend("Right") < 0.999, "los codos están doblados (no es un palo recto)")
local shoulder0 = cam.CFrame:PointToObjectSpace((part(model, "UpperArm", "Right").CFrame * roblox.CFrame.new(0, 0, part(model, "UpperArm", "Right").Size.Z / 2)).Position)

-- 2) ADS: el centro de la mira en el centro de la pantalla y el hombro quieto
mock.actions.Aim("Aim", roblox.Enum.UserInputState.Begin, { UserInputType = roblox.Enum.UserInputType.MouseButton2 })
frames(90)
local aim = cam.CFrame:PointToObjectSpace(handle.CFrame * def.AimPoint)
check(math.abs(aim.X) < 0.02 and math.abs(aim.Y) < 0.02 and math.abs(aim.Z + def.AimDistance) < 0.05,
	string.format("ADS: mira centrada (%.3f, %.3f, %.3f)", aim.X, aim.Y, aim.Z))
check(ClientState.WeaponAction == "ADS", "acción: ADS (" .. tostring(ClientState.WeaponAction) .. ")")
local shoulder1 = cam.CFrame:PointToObjectSpace((part(model, "UpperArm", "Right").CFrame * roblox.CFrame.new(0, 0, part(model, "UpperArm", "Right").Size.Z / 2)).Position)
check((shoulder1 - shoulder0).Magnitude < 0.1, string.format("el hombro no se mueve con el arma (%.3f)", (shoulder1 - shoulder0).Magnitude))
check(handGap("Right") < 0.02, "en ADS la mano sigue en la empuñadura")
mock.actions.Aim("Aim", roblox.Enum.UserInputState.End, { UserInputType = roblox.Enum.UserInputType.MouseButton2 })
frames(60)

-- 3) Recarga táctica: MagOut → MagIn → Ready, sin palanca
tool:SetAttribute("Ammo", 12)
frames(2)
unblock()
local from = #events + 1
tap("Reload")
local charge = part(model, "ChargingHandle")
local charge0 = handle.CFrame:ToObjectSpace(charge.CFrame).Position
local maxCharge = 0
local reloadAction = true
local t0 = os.clock()
while os.clock() - t0 < Weapons.ReloadDuration(def, false) + 0.15 do
	render(1 / 60)
	maxCharge = math.max(maxCharge, (handle.CFrame:ToObjectSpace(charge.CFrame).Position - charge0).Magnitude)
	if ClientState.Reloading and ClientState.WeaponAction ~= "Reload" then
		reloadAction = false
	end
	task.wait(1 / 60)
end
check(reloadAction, "acción durante la recarga: Reload")
local list = names(from)
check(order(list, "ReloadStart", "MagOut") and order(list, "MagOut", "MagIn") and order(list, "MagIn", "Ready") and not has(list, "Bolt"),
	"recarga táctica: " .. table.concat(list, " → "))
check(maxCharge < 0.01, "táctica: la palanca de carga no se mueve")
-- (el servidor acaba la recarga: aquí no hay servidor)
tool:SetAttribute("Ammo", 30); tool.AttributeChanged:Fire("Ammo")
tool:SetAttribute("Reloading", false); tool.AttributeChanged:Fire("Reloading")
frames(5)

-- 4) Recarga vacía: MagOut → MagIn → Bolt → Ready, y la palanca de carga va atrás y vuelve
tool:SetAttribute("Ammo", 0); tool.AttributeChanged:Fire("Ammo")
frames(2)
unblock()
from = #events + 1
local gloveL0 = handle.CFrame:ToObjectSpace(part(model, "Glove", "Left").CFrame).Position
tap("Reload")
maxCharge = 0
local gloveTravel = 0
t0 = os.clock()
while os.clock() - t0 < Weapons.ReloadDuration(def, true) + 0.15 do
	render(1 / 60)
	maxCharge = math.max(maxCharge, (handle.CFrame:ToObjectSpace(charge.CFrame).Position - charge0).Magnitude)
	gloveTravel = math.max(gloveTravel, (handle.CFrame:ToObjectSpace(part(model, "Glove", "Left").CFrame).Position - gloveL0).Magnitude)
	task.wait(1 / 60)
end
list = names(from)
check(order(list, "MagOut", "MagIn") and order(list, "MagIn", "Bolt") and order(list, "Bolt", "Ready"), "recarga vacía: " .. table.concat(list, " → "))
check(maxCharge > 0.1, string.format("vacía: la palanca de carga va atrás (%.2f)", maxCharge))
check(gloveTravel > 0.5, string.format("vacía: la mano izquierda viaja al cargador y a la palanca (%.2f)", gloveTravel))
tool:SetAttribute("Ammo", 30); tool.AttributeChanged:Fire("Ammo")
tool:SetAttribute("Reloading", false); tool.AttributeChanged:Fire("Reloading")
frames(20)
check((handle.CFrame:ToObjectSpace(charge.CFrame).Position - charge0).Magnitude < 0.01, "la palanca vuelve a su sitio")

-- 5) Inspección: Inspect → InspectMoment; disparar la corta con su evento
unblock()
from = #events + 1
mock.actions.Inspect("Inspect", roblox.Enum.UserInputState.Begin, {})
t0 = os.clock()
while os.clock() - t0 < visual.Inspect.Duration * visual.Inspect.Moment + 0.15 do
	render(1 / 60)
	task.wait(1 / 60)
end
check(ClientState.WeaponAction == "Inspect", "acción: Inspect")
list = names(from)
check(order(list, "Inspect", "InspectMoment"), "inspección: " .. table.concat(list, " → "))
unblock()
from = #events + 1
tap("Fire")
frames(3)
check(has(names(from), "InspectCancel") and ClientState.WeaponAction ~= "Inspect", "disparar corta la inspección (InspectCancel)")
check(lastEvent("Fire") and lastEvent("Fire").Info and lastEvent("Fire").Info.ADS == false, "evento Fire con ADS = false (de cadera)")
-- Apuntar también la corta
task.wait(visual.Inspect.Duration + 0.1)
frames(5)
unblock()
mock.actions.Inspect("Inspect", roblox.Enum.UserInputState.Begin, {})
frames(10)
from = #events + 1
mock.actions.Aim("Aim", roblox.Enum.UserInputState.Begin, { UserInputType = roblox.Enum.UserInputType.MouseButton2 })
frames(3)
check(has(names(from), "InspectCancel"), "apuntar corta la inspección")
mock.actions.Aim("Aim", roblox.Enum.UserInputState.End, { UserInputType = roblox.Enum.UserInputType.MouseButton2 })
frames(60)

-- 6) Gesto de reposo: tras un rato quieto; cualquier acción lo corta al momento
visual.Idle.VariantAfter = 0.6
visual.Idle.VariantCooldown = 0
from = #events + 1
t0 = os.clock()
while os.clock() - t0 < 1.0 do
	render(1 / 60)
	task.wait(1 / 60)
end
check(has(names(from), "IdleVariant") and ClientState.WeaponAction == "IdleVariant", "quieto un rato: gesto de reposo (IdleVariant)")
unblock()
tap("Fire")
frames(2)
check(ClientState.WeaponAction ~= "IdleVariant", "disparar corta el gesto de reposo (" .. tostring(ClientState.WeaponAction) .. ")")
visual.Idle.VariantAfter = 9
visual.Idle.VariantCooldown = 16

-- 7) Cambio de arma: el ARX-27 baja mientras sube la otra y no queda nada
from = #events + 1
equip("Specter9")
task.wait(0.05)
frames(2)
check(has(names(from), "Unequip") and has(names(from), "Equip"), "cambio de arma: Unequip y Equip")
check(viewmodels() == 2, "un instante se ven las dos (la vieja bajando)")
task.wait(0.25)
frames(3)
check(viewmodels() == 1, "y después solo la nueva")

-- 8) Morir: el arma desaparece al momento (sin animación de guardar) y no queda ninguna
equip("ARX27")
task.wait(0.4)
frames(10)
hum.Health = 0
hum.Died:Fire()
frames(2)
check(viewmodels() == 0, "al morir no queda ningún viewmodel")
check(ClientState.WeaponAction == "None", "y no hay acción del arma")
print("ARX27 GOLD OK")
process.exit(0)
