-- Linternas de noche: la tuya (L para apagarla) y las de los demás más cercanos
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local camera = game.Workspace.CurrentCamera
camera.CFrame = CFrame.new(0, 5, 0)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
ClientState.EffectiveQuality = "Alta"
ClientState.CurrentDef = { Type = "Gun" }
local Flashlights = req(game.StarterPlayer.Client.Modules.Flashlights)
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local function bot(name, pos, zombie)
	local m = mock.new("Model"); m.Name = name
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local tool = mock.new("Tool"); tool:SetAttribute("Weapon", "ARX27")
	local handle = mock.new("Part"); handle.Name = "Handle"; handle.Position = pos; handle.CFrame = CFrame.new(pos); handle.Parent = tool
	tool.Parent = m
	if zombie then m:SetAttribute("Zombie", true) end
	m.Parent = bots
	return m, handle
end
local _, nearHandle = bot("Bot Cerca", Vector3.new(0, 5, -40))
local _, farHandle = bot("Bot Lejos", Vector3.new(0, 5, -400))
local _, zombieHandle = bot("Bot Zombi", Vector3.new(10, 5, -30), true)
local function lit(handle)
	local spot = handle:FindFirstChild("Flashlight")
	return spot ~= nil and spot.Enabled == true
end
-- De día: nada
Lighting.ClockTime = 13
Flashlights.Update(0.3)
local mine = camera:FindFirstChild("MyFlashlight")
check(mine ~= nil and mine:FindFirstChildOfClass("SpotLight").Enabled == false, "de día, sin linterna")
check(not lit(nearHandle), "ni la de los bots")
-- De noche: la tuya y las de los cercanos
Lighting.ClockTime = 23
Flashlights.Update(0.3)
local spot = mine:FindFirstChildOfClass("SpotLight")
check(spot.Enabled and spot.Shadows == true, "de noche, tu linterna encendida (con sombras)")
check((mine.Position - camera.CFrame.Position).Magnitude < 2, "sale de donde va el arma")
check(lit(nearHandle), "el bot cercano lleva la suya")
check(not lit(farHandle), "el muy lejano no (rendimiento)")
check(not lit(zombieHandle), "los zombis no llevan linterna")
-- Tecla L
local Remotes = req(game.ReplicatedStorage.Shared.Remotes)
check(Flashlights.Toggle() == false, "L la apaga")
Flashlights.Update(0.3)
check(spot.Enabled == false, "apagada")
local sent
for _, e in mock.serverSent do if e.Remote == "Flashlight" then sent = e.Args[1] end end
check(sent == false, "y se avisa al servidor (los demás ya no la ven)")
Flashlights.Toggle()
-- Un jugador con la suya apagada no la lleva encendida para los demás
local other = mock.new("Player"); other.Name = "Otro"; other.UserId = 2; other.Parent = Players
table.insert(mock.players, other)
local oc = mock.new("Model"); local oh = mock.new("Humanoid"); oh.Health = 100; oh.Parent = oc
local ot = mock.new("Tool"); ot:SetAttribute("Weapon", "ARX27")
local ohandle = mock.new("Part"); ohandle.Name = "Handle"; ohandle.Position = Vector3.new(5, 5, -20); ohandle.CFrame = CFrame.new(5, 5, -20); ohandle.Parent = ot
ot.Parent = oc; oc.Parent = game.Workspace; other.Character = oc
oc:SetAttribute("Flashlight", false)
Flashlights.Update(0.3)
check(not lit(ohandle), "si otro jugador la apaga, no se ve")
oc:SetAttribute("Flashlight", true)
Flashlights.Update(0.3)
check(lit(ohandle), "si la enciende, sí")
-- Calidad Baja: solo la tuya, sin sombras
ClientState.EffectiveQuality = "Baja"
Flashlights.Update(0.3)
check(spot.Enabled and spot.Shadows == false and not lit(nearHandle), "en calidad Baja: solo la tuya y sin sombras")
-- Muerto o con cuchillo: la tuya se apaga
ClientState.EffectiveQuality = "Alta"
ClientState.CurrentDef = { Type = "Melee" }
Flashlights.Update(0.3)
check(spot.Enabled == false, "con el cuchillo, sin linterna")
print("LINTERNAS OK")
process.exit(0)
