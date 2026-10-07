-- Postura con dos manos (IKControl) y armas del mundo a escala de una persona
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
local Weapons = req(game.ReplicatedStorage.Shared.Weapons)
local Loadout = req(game.ServerScriptService.Server.Modules.Loadout)
local RiflePose = req(game.StarterPlayer.Client.Modules.RiflePose)

-- Arma del mundo más pequeña que la de primera persona
local tool = Loadout.MakeTool("ARX27", "Default")
local handle = tool:FindFirstChild("Handle")
local muzzle = handle:FindFirstChild("Muzzle")
local def = Weapons.Get("ARX27")
local scale = GameConfig.WorldWeaponScale
check(scale < 1 and tool:GetAttribute("WorldScale") == scale, "el arma del mundo va a escala (" .. scale .. ")")
check(math.abs(muzzle.Position.Z - def.Muzzle.Z * scale) < 1e-3, "el cañón (fogonazo y trazadoras) se mueve con la escala")
check((tool.Grip.Position - def.RightHand * scale).Magnitude < 1e-3, "y la mano agarra la empuñadura escalada")

-- Personaje R15 mínimo
local function rig(name)
	local m = mock.new("Model"); m.Name = name
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local animator = mock.new("Animator"); animator.Parent = h
	for _, partName in { "UpperTorso", "RightUpperArm", "LeftUpperArm", "RightHand", "LeftHand", "Head" } do
		local p = mock.new("Part"); p.Name = partName; p.Parent = m
	end
	local rg = mock.new("Attachment"); rg.Name = "RightGripAttachment"; rg.Parent = m.RightHand
	local lg = mock.new("Attachment"); lg.Name = "LeftGripAttachment"; lg.Parent = m.LeftHand
	m.Parent = game.Workspace
	return m, h
end
local bot, botHum = rig("Bot Max")
RiflePose.Setup(bot)
local poseRig = RiflePose.Rig(bot)
check(poseRig ~= nil and poseRig.Right.Parent == botHum and poseRig.Left.Parent == botHum, "IK de los dos brazos en el personaje")
check(poseRig.Right.Type == roblox.Enum.IKControlType.Transform and poseRig.Right.ChainRoot == bot.RightUpperArm, "brazo derecho: la mano con el arma mirando al frente")
check(poseRig.Left.EndEffector == bot.LeftHand.LeftGripAttachment, "brazo izquierdo: la mano al guardamanos")
check(poseRig.Right.Enabled == false, "sin arma, la animación de siempre")
tool.Parent = bot
bot.ChildAdded:Fire(tool) -- (el simulador no lanza la señal solo)
check(poseRig.Right.Enabled and poseRig.Left.Enabled, "con el fusil, las dos manos en el arma")
-- La culata queda en el hombro y la mano izquierda delante y al alcance
local grip, hand = RiflePose.Targets("ARX27", scale)
local handlePos = grip.Position - def.RightHand * scale
local rear = 0
for _, spec in def.Parts do rear = math.max(rear, spec.CFrame.Position.Z + spec.Size.Z / 2) end
check(math.abs(handlePos.Z + rear * scale - RiflePose.ButtAt.Z) < 1e-3, "la culata apoya en el hombro")
check(hand.Z < grip.Position.Z - 0.2 and (hand - Vector3.new(-1, 0.56, 0)).Magnitude <= RiflePose.Reach + 0.01, "la mano izquierda delante y al alcance del brazo")
-- Francotirador largo: la mano izquierda se agarra más atrás si no llega
local g2, h2 = RiflePose.Targets("Signal7", scale)
check((h2 - Vector3.new(-1, 0.56, 0)).Magnitude <= RiflePose.Reach + 0.01, "con el francotirador, la mano llega")
-- Pistola: brazos estirados, manos juntas
local gp, hp = RiflePose.Targets("Viper", scale)
check(gp.Position.Z < -1.3 and (hp - gp.Position).Magnitude < 0.6, "con pistola, brazos estirados y las dos manos en la empuñadura")
-- Cuchillo: nada
check(RiflePose.Targets("Knife", scale) == nil, "con el cuchillo, la animación de siempre")
tool.Parent = nil
bot.ChildRemoved:Fire(tool)
check(poseRig.Right.Enabled == false, "al guardar el arma, se suelta")
tool.Parent = bot
bot.ChildAdded:Fire(tool)
-- Al disparar: el arma da el golpe del retroceso y vuelve
local restZ = poseRig.Grip.CFrame.Position.Z
check(RiflePose.Kick(bot), "disparo de otro: retroceso")
check(poseRig.Grip.CFrame.Position.Z > restZ + 0.1, "el arma va hacia atrás un instante")
task.wait(0.12)
check(math.abs(poseRig.Grip.CFrame.Position.Z - restZ) < 1e-3, "y vuelve a su sitio")
-- La cabeza mira hacia donde apunta
check(poseRig.Head ~= nil and poseRig.Head.Enabled and poseRig.Head.Type == roblox.Enum.IKControlType.LookAt, "la cabeza acompaña al arma")
-- Apuntando arriba o abajo: el arma se inclina (atributo AimPitch del personaje)
local gUp = RiflePose.Targets("ARX27", scale, 0.5)
check(gUp.LookVector.Y > 0.4 and gUp.Position.Y > grip.Position.Y, "apuntando arriba, el arma se inclina hacia arriba")
check(RiflePose.Targets("ARX27", scale, -0.5).LookVector.Y < -0.4, "y hacia abajo")
check(RiflePose.Targets("ARX27", scale, 3).LookVector.Y < 0.8, "sin pasarse (no se mete en la cabeza)")
bot:SetAttribute("AimPitch", 0.5)
check(poseRig.Grip.CFrame.LookVector.Y > 0.4, "el bot que apunta hacia arriba levanta el arma")
check(poseRig.Look.Position.Y > 4, "y mira hacia arriba")
bot:SetAttribute("AimPitch", 0)
-- Al morir: fuera (el cuerpo cae suelto)
botHum.Health = 0
botHum.Died:Fire()
check(RiflePose.Rig(bot) == nil and poseRig.Right.Parent == nil, "al morir, el IK se quita")
-- Tu propio personaje: no
local mine = rig("Yo")
me.Character = mine
RiflePose.Setup(mine)
check(RiflePose.Rig(mine) == nil, "tu propio personaje no (primera persona)")
-- Desactivado en la configuración: nada
GameConfig.TwoHandedPose = false
local other = rig("Bot Leo")
RiflePose.Setup(other)
check(RiflePose.Rig(other) == nil, "con TwoHandedPose = false, nada")
-- Lo que se manda al servidor: hacia dónde miras, solo si cambia
local AimPitch = req(game.StarterPlayer.Client.Modules.AimPitch)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local myChar = mock.new("Model"); local myHum = mock.new("Humanoid"); myHum.Health = 100; myHum.Parent = myChar
me.Character = myChar
local cam = game.Workspace.CurrentCamera
cam.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0.4, 0, 0)
local function sentPitches()
	local n, last = 0, nil
	for _, e in mock.serverSent do
		if e.Remote == "AimPitch" then n += 1; last = e.Args[1] end
	end
	return n, last
end
AimPitch.Update(0.25)
local n1, p1 = sentPitches()
check(n1 == 1 and math.abs(p1 - 0.4) < 0.02, "manda hacia dónde mira (" .. tostring(p1) .. ")")
AimPitch.Update(0.25)
check(sentPitches() == 1, "si no cambia, no lo vuelve a mandar")
cam.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(-0.3, 0, 0)
AimPitch.Update(0.25)
local n3, p3 = sentPitches()
check(n3 == 2 and p3 < -0.25, "al bajar la mira, lo manda")
print("POSTURA OK")
process.exit(0)
