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
RS:SetAttribute("State", "Playing"); RS:SetAttribute("Mode", "INF"); RS:SetAttribute("ModeName", "Infección")
RS:SetAttribute("Infection", "Prep"); RS:SetAttribute("AliveA", 4); RS:SetAttribute("AliveB", 0); RS:SetAttribute("TimeLeft", 10)
task.wait(1.5)
RS:SetAttribute("Infection", "On"); RS:SetAttribute("AliveA", 3); RS:SetAttribute("AliveB", 1)
me.Team = teamB
task.wait(1.5)
Remotes.Notify.OnClientEvent:Fire("Big", "🧟 ¡HAN LLEGADO LOS ZOMBIS! ¡Sobrevive!")
Remotes.Notify.OnClientEvent:Fire("Challenge", "🥇 ¡Rango Oro!  +300 🪙  +1 caja")
Remotes.Notify.OnClientEvent:Fire("Streak", "🧟 Bot Max se ha convertido en zombi")
task.wait(1.5)
-- Muerte: pantalla de muerte con el asesino
hum.Health = 0
hum.Died:Fire()
Remotes.Died.OnClientEvent:Fire("Bot Max", "Garras", 150)
task.wait(1.5)
-- Menú abierto en cada pestaña
local Menu = req(game.StarterPlayer.Client.Modules.Menu)
for _, tab in { "Perfil", "Pase", "Retos", "Armas", "Skins", "Trajes", "Efectos", "Tienda", "Ajustes" } do
	Menu.Open(tab)
	task.wait(0.1)
end
Menu.Close()
-- Fin de partida con resumen
RS:SetAttribute("Infection", nil)
RS:SetAttribute("State", "Ended")
Remotes.RoundEnd.OnClientEvent:Fire({ TeamMode = true, Winner = "Rojo", ScoreA = 1, ScoreB = 0, MVP = "Yo", MVPKills = 2 })
Remotes.MatchSummary.OnClientEvent:Fire({ XP = 900, Coins = 80, StartLevel = 1, StartXP = 500, Level = 2, LevelXP = 400, XPPerLevel = 1000, Kills = 2, Deaths = 1, BestStreak = 2, WinStreak = 3, StartRank = 90, RankPoints = 115 })
task.wait(3)
-- Descanso con votación
RS:SetAttribute("State", "Intermission")
for i = 1, 3 do
	RS:SetAttribute("Vote" .. i .. "_Map", "🎃 Mansión Encantada"); RS:SetAttribute("Vote" .. i .. "_Mode", "Infección"); RS:SetAttribute("Vote" .. i .. "_Count", i - 1)
end
task.wait(1.5)
-- Killfeed, impactos y avisos
Remotes.KillFeed.OnClientEvent:Fire({ Killer = "Yo", KillerColor = roblox.Color3.new(1, 0, 0), Victim = "Bot Max", VictimColor = roblox.Color3.new(0, 0, 1), Weapon = "Garras", Headshot = false })
Remotes.HitConfirm.OnClientEvent:Fire(true, false, roblox.Vector3.new(0, 3, -5))
Remotes.Notify.OnClientEvent:Fire("LevelUp", 2)
Remotes.Notify.OnClientEvent:Fire("Unlock", "¡Arma desbloqueada: Katana!")
task.wait(1)
local failed = 0
for _, line in warnings do
	if string.find(line, "Arranque", 1, true) then
		failed += 1
		print(line)
	end
end
print("arranques fallidos:", failed)
print(failed == 0 and "CLIENTE OK" or "FALLO")
process.exit(failed == 0 and 0 or 1)
