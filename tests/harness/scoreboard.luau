-- Prueba del marcador (Tab): equipos, jugadores y bots, sin errores de propiedades
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local GameConfig = req(RS.Shared.GameConfig)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", roblox.BrickColor.new("Really red")
teamB.Name, teamB.TeamColor = "Azul", roblox.BrickColor.new("Really blue")
teamA.Parent, teamB.Parent = Teams, Teams
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId, me.Team = "Yo", "Yo", 1, teamA
me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
local ls = mock.new("Folder"); ls.Name = "leaderstats"; ls.Parent = me
for _, n in { "Bajas", "Muertes" } do local v = mock.new("IntValue"); v.Name = n; v.Value = 3; v.Parent = ls end
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
local stats = mock.new("Folder"); stats.Name = "BotStats"; stats.Parent = RS
for i, team in { "Rojo", "Azul", "Azul" } do
	local e = mock.new("Folder"); e.Name = "Bot " .. i; e:SetAttribute("Team", team); e:SetAttribute("Kills", i); e:SetAttribute("Deaths", 1); e:SetAttribute("Score", 0); e.Parent = stats
end
RS:SetAttribute("TeamA", "Rojo"); RS:SetAttribute("TeamB", "Azul"); RS:SetAttribute("Mode", "TDM"); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("ModeName", "Duelo por equipos"); RS:SetAttribute("MapName", "Arena Caramelo"); RS:SetAttribute("TimeLeft", 95)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local Scoreboard = req(game.StarterPlayer.Client.Modules.Scoreboard)
Scoreboard.Init()
local action = mock.actions.Scoreboard
check(action ~= nil, "Tab enlazado")
action("Scoreboard", roblox.Enum.UserInputState.Begin, { UserInputType = roblox.Enum.UserInputType.Keyboard })
local gui = pg:FindFirstChild("Scoreboard")
check(gui and gui.Enabled, "se abre al pulsar Tab")
local texts = {}
for _, d in gui:GetDescendants() do
	if d.__className == "TextLabel" then texts[d.Text] = true end
end
check(texts["🤖 Bot 1"] and texts["🤖 Bot 2"] and texts["Yo"], "salen jugadores y bots")
check(texts["DUELO POR EQUIPOS  ·  Arena Caramelo  ·  01:35"] ~= nil, "título con modo, mapa y tiempo")
-- Modo sin equipos
RS:SetAttribute("TeamMode", false); RS:SetAttribute("Mode", "FFA")
task.wait(0.6)
action("Scoreboard", roblox.Enum.UserInputState.End, { UserInputType = roblox.Enum.UserInputType.Keyboard })
check(not gui.Enabled, "se cierra al soltar Tab")
print("MARCADOR OK")
process.exit(0)
