-- Muñeco de trapo al morir
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local mock = require("./mock")
local task = require("@lune/task")
mock.taskImpl = task
local V, CF = roblox.Vector3.new, roblox.CFrame.new
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Ragdoll = req(game.ServerScriptService.Server.Modules.Ragdoll)
local char = mock.new("Model")
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local function part(name, pos)
	local p = mock.new("Part"); p.Name = name; p.Size = V(1, 1, 1); p.CFrame = CF(pos); p.CanCollide = false; p.Parent = char
	return p
end
local root = part("HumanoidRootPart", V(0, 3, 0))
local lower = part("LowerTorso", V(0, 2.8, 0))
local upper = part("UpperTorso", V(0, 3.8, 0))
local head = part("Head", V(0, 5, 0))
local function motor(name, p0, p1)
	local m = mock.new("Motor6D"); m.Name = name; m.Part0 = p0; m.Part1 = p1; m.C0 = CF(0, 0.5, 0); m.C1 = CF(0, -0.5, 0); m.Enabled = true; m.Parent = p1
	return m
end
local rootJoint = motor("Root", root, lower)
local waist = motor("Waist", lower, upper)
local neck = motor("Neck", upper, head)
char.Parent = game.Workspace
Ragdoll.Prepare(hum)
check(hum.BreakJointsOnDeath == false, "no se rompe en piezas al morir")
check(Ragdoll.Apply(char, V(10, 3, 0)) == true, "se convierte en muñeco de trapo")
check(not waist.Enabled and not neck.Enabled and not rootJoint.Enabled, "las uniones rígidas se sueltan")
local sockets = 0
for _, d in char:GetDescendants() do if d.ClassName == "BallSocketConstraint" then sockets += 1 end end
check(sockets == 3, "una rótula con límites por cada unión (" .. sockets .. ")")
check(upper.CanCollide and head.CanCollide and not root.CanCollide, "el cuerpo choca con el suelo; la raíz no")
check(Ragdoll.Apply(char) == false, "no se aplica dos veces")
local nc = 0
for _, d in char:GetDescendants() do if d.ClassName == "NoCollisionConstraint" then nc += 1 end end
check(nc == 3, "las piezas unidas no chocan entre sí")
Ragdoll.SettleTime = 0.2
local char2 = mock.new("Model")
local h2 = mock.new("Humanoid"); h2.Parent = char2
local a = mock.new("Part"); a.Name = "UpperTorso"; a.Parent = char2
local b = mock.new("Part"); b.Name = "Head"; b.Parent = char2
local m2 = mock.new("Motor6D"); m2.Name = "Neck"; m2.Part0 = a; m2.Part1 = b; m2.C0 = CF(); m2.C1 = CF(); m2.Parent = b
char2.Parent = game.Workspace
Ragdoll.Apply(char2)
task.wait(0.4)
check(a.Anchored and not a.CanCollide and b.Anchored and not b.CanCollide, "tras caer queda quieto y sin estorbar")
print("MUÑECO OK")
process.exit(0)
