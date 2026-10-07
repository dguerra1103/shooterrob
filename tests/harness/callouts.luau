-- Avisos de los compañeros: «¡Recargando!» y «¡Granada!» sobre su cabeza (solo tu equipo)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local red = mock.new("Team"); red.Name = "Rojo"; red.Parent = Teams
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players; me.Team = red
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.ReplicatedStorage:SetAttribute("TeamMode", true)
game.Workspace.CurrentCamera.CFrame = CFrame.new(0, 5, 0)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local Callouts = req(game.StarterPlayer.Client.Modules.Callouts)
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local function bot(name, team, pos)
	local m = mock.new("Model"); m.Name = name; m:SetAttribute("Bot", true); m:SetAttribute("Team", team)
	local head = mock.new("Part"); head.Name = "Head"; head.Position = pos; head.CFrame = CFrame.new(pos); head.Parent = m
	local tool = mock.new("Tool"); tool:SetAttribute("Weapon", "ARX27"); tool:SetAttribute("Reloading", false); tool.Parent = m
	m.Parent = bots
	return m, tool, head
end
local mate, mateTool, mateHead = bot("Bot Leo", "Rojo", Vector3.new(0, 5, -20))
local enemy, enemyTool, enemyHead = bot("Bot Max", "Azul", Vector3.new(10, 5, -30))
local function bubbleFor(head)
	for _, g in pg:GetChildren() do
		if g.Name == "Callout" and g.Adornee == head and g.Enabled then
			return g:FindFirstChild("Text").Text
		end
	end
	return nil
end
Callouts.Update(0.2)
check(bubbleFor(mateHead) == nil, "sin nada que avisar, nada")
mateTool:SetAttribute("Reloading", true)
enemyTool:SetAttribute("Reloading", true)
Callouts.Update(0.2)
check(bubbleFor(mateHead) == "🔄 ¡Recargando!", "el compañero avisa de que recarga")
check(bubbleFor(enemyHead) == nil, "del enemigo no se sabe nada")
task.wait(1.8)
check(bubbleFor(mateHead) == nil, "el aviso se quita solo")
-- Granada de un compañero
local grenades = mock.new("Folder"); grenades.Name = "Grenades"; grenades.Parent = game.Workspace
local g = mock.new("Part"); g.Name = "Grenade"; g:SetAttribute("Thrower", "Bot Leo"); g.Parent = grenades
local g2 = mock.new("Part"); g2.Name = "Grenade"; g2:SetAttribute("Thrower", "Bot Max"); g2.Parent = grenades
Callouts.Update(0.2)
check(bubbleFor(mateHead) == "💣 ¡Granada!", "el compañero avisa de su granada")
check(bubbleFor(enemyHead) == nil, "la del enemigo no")
-- Todos contra todos: nada
game.ReplicatedStorage:SetAttribute("TeamMode", false)
mateTool:SetAttribute("Reloading", false)
Callouts.Update(0.2)
task.wait(1.8)
mateTool:SetAttribute("Reloading", true)
Callouts.Update(0.2)
check(bubbleFor(mateHead) == nil, "en todos contra todos no hay avisos")
print("AVISOS OK")
process.exit(0)
