-- Aviso de granada cercana
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local Vector3, CFrame, Vector2 = roblox.Vector3, roblox.CFrame, roblox.Vector2
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 5; me.Parent = Players
Players.LocalPlayer = me
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
local t1 = mock.new("Team"); t1.Name = "Rojo"; t1.Parent = Teams
me.Team = t1
RS:SetAttribute("TeamMode", true)
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(0, 3, 0); root.Parent = char
char.Parent = game.Workspace
me.Character = char
local cam = game.Workspace.CurrentCamera
cam.CFrame = CFrame.new(0, 5, 0)
cam.ViewportSize = Vector2.new(800, 400)
local folder = mock.new("Folder"); folder.Name = "Grenades"; folder.Parent = game.Workspace
local function grenade(pos, team, thrower)
	local g = mock.new("Part"); g.Name = "Grenade"; g.CFrame = CFrame.new(pos); g:SetAttribute("Team", team); g:SetAttribute("Thrower", thrower); g.Parent = folder
	return g
end
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local GW = req(game.StarterPlayer.Client.Modules.GrenadeWarning)
GW.Init()
local gui = pg:FindFirstChild("GrenadeWarning")
local function visible()
	local list = {}
	for _, c in gui:GetChildren() do if c.Visible then table.insert(list, c) end end
	return list
end
GW.Update()
check(#visible() == 0, "sin granadas no hay aviso")
local own = grenade(Vector3.new(3, 3, 0), "Rojo", "Yo")
local mate = grenade(Vector3.new(-3, 3, 0), "Rojo", "Bot Leo")
GW.Update()
check(#visible() == 0, "ni las tuyas ni las de tu equipo")
local enemyFront = grenade(Vector3.new(0, 3, -8), "Azul", "Bot Max")
GW.Update()
local v = visible()
check(#v == 1, "granada enemiga cerca: aviso")
check(v[1].Position.Y.Offset < 200, "delante: el icono va encima de la mira (" .. v[1].Position.Y.Offset .. ")")
enemyFront:Destroy()
local enemyRight = grenade(Vector3.new(8, 3, 0), "Azul", "Bot Max")
GW.Update()
v = visible()
check(#v == 1 and v[1].Position.X.Offset > 400, "a la derecha: el icono a la derecha (" .. v[1].Position.X.Offset .. ")")
enemyRight:Destroy()
grenade(Vector3.new(0, 3, 80), "Azul", "Bot Max")
GW.Update()
check(#visible() == 0, "lejos no avisa")
print("AVISO GRANADA OK")
process.exit(0)
