-- Tu cuerpo en primera persona: al mirar abajo se ven las piernas (y las botas del traje)
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
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local BodyView = req(game.StarterPlayer.Client.Modules.BodyView)
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local parts = {}
for _, name in { "Head", "UpperTorso", "LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "LeftUpperArm" } do
	local p = mock.new("Part"); p.Name = name; p.Position = Vector3.new(0, 3, 0); p.Parent = char
	parts[name] = p
end
parts.Head.Position = Vector3.new(0, 5, 0)
local boot = mock.new("Part"); boot.Name = "Boot"; boot.Parent = char
local w = mock.new("WeldConstraint"); w.Part0 = parts.LeftFoot; w.Part1 = boot; w.Parent = boot
local hat = mock.new("Part"); hat.Name = "Helmet"; hat.Parent = char
local w2 = mock.new("WeldConstraint"); w2.Part0 = parts.Head; w2.Part1 = hat; w2.Parent = hat
me.Character = char
char.Parent = game.Workspace
BodyView.Track(char)
local camera = game.Workspace.CurrentCamera
local function firstPerson()
	for _, p in char:GetDescendants() do
		if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
	end
end
camera.CFrame = CFrame.new(0, 5, 0)
firstPerson()
BodyView.Update()
check(parts.LeftUpperLeg.LocalTransparencyModifier == 0 and parts.LowerTorso.LocalTransparencyModifier == 0, "en primera persona se ven la cadera y las piernas")
check(boot.LocalTransparencyModifier == 0, "y las botas del traje")
check(parts.UpperTorso.LocalTransparencyModifier == 1 and parts.Head.LocalTransparencyModifier == 1 and hat.LocalTransparencyModifier == 1, "pero no el pecho, la cabeza ni el casco (taparían la vista)")
check(parts.LeftUpperArm.LocalTransparencyModifier == 1, "ni los brazos (están los del arma)")
ClientState.Crouching = true
firstPerson()
BodyView.Update()
check(parts.LeftUpperLeg.LocalTransparencyModifier == 1, "agachado no (la cámara baja y las atravesaría)")
ClientState.Crouching = false
camera.CFrame = CFrame.new(0, 8, 12)
firstPerson()
BodyView.Update()
check(parts.LeftUpperLeg.LocalTransparencyModifier == 1, "con la cámara lejos (emote), lo de siempre")
camera.CFrame = CFrame.new(0, 5, 0)
ClientState.Dead = true
firstPerson()
BodyView.Update()
check(parts.LeftUpperLeg.LocalTransparencyModifier == 1, "muerto, nada")
ClientState.Dead = false
-- Ropa que llega después (uniforme): también cuenta
local knee = mock.new("Part"); knee.Name = "KneePad"; knee.Parent = char
local w3 = mock.new("WeldConstraint"); w3.Part0 = parts.RightLowerLeg; w3.Part1 = knee; w3.Parent = knee
char.DescendantAdded:Fire(knee)
task.wait(0.05)
firstPerson()
BodyView.Update()
check(knee.LocalTransparencyModifier == 0, "la rodillera del uniforme puesta después también se ve")
print("CUERPO OK")
process.exit(0)
