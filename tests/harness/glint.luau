-- Destello de la mira de los bots tiradores enemigos
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 5; me.Parent = Players
Players.LocalPlayer = me
local t1 = mock.new("Team"); t1.Name = "Rojo"; t1.Parent = Teams
me.Team = t1
RS:SetAttribute("TeamMode", true)
game.Workspace.CurrentCamera.CFrame = CFrame.new(0, 5, 0)
local folder = mock.new("Folder"); folder.Name = "Bots"; folder.Parent = game.Workspace
-- (mirando hacia -Z: CFrame.new(p) mira a -Z por defecto)
local function bot(name, team, role, pos, facing)
	local m = mock.new("Model"); m.Name = name; m:SetAttribute("Team", team); m:SetAttribute("Role", role)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local cf = CFrame.new(pos)
	if facing == "away" then cf = cf * CFrame.Angles(0, math.pi, 0) end
	local r = mock.new("Part"); r.Name = "HumanoidRootPart"; r.CFrame = cf; r.AssemblyLinearVelocity = Vector3.zero; r.Parent = m
	local hd = mock.new("Part"); hd.Name = "Head"; hd.CFrame = cf + Vector3.new(0, 1.5, 0); hd.Parent = m
	m.Parent = folder
	return m, hd
end
local _, h1 = bot("Bot T", "Azul", "Tirador", Vector3.new(0, 5, 120), "toward")
local _, h2 = bot("Bot A", "Azul", "Asalto", Vector3.new(10, 5, 120), "toward")
local _, h3 = bot("Bot T2", "Rojo", "Tirador", Vector3.new(-10, 5, 120), "toward")
local _, h4 = bot("Bot T3", "Azul", "Tirador", Vector3.new(20, 5, 120), "away")
local ScopeGlint = req(game.StarterPlayer.Client.Modules.ScopeGlint)
ScopeGlint.Update()
check(h1:FindFirstChild("ScopeGlint") ~= nil, "el tirador enemigo que te mira brilla")
check(h2:FindFirstChild("ScopeGlint") == nil, "un bot de asalto no")
check(h3:FindFirstChild("ScopeGlint") == nil, "un tirador de tu equipo no")
check(h4:FindFirstChild("ScopeGlint") == nil, "si mira hacia otro lado no")
h1.Parent:FindFirstChildOfClass("Humanoid").Health = 0
ScopeGlint.Update()
check(h1:FindFirstChild("ScopeGlint") == nil, "al morir se apaga")
print("DESTELLO OK")
process.exit(0)
