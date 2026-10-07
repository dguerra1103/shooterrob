-- Prueba del HUD y la pantalla de inicio en el cliente: resumen con rango, Infección y tarjeta de rango
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", roblox.BrickColor.new("Really red")
teamB.Name, teamB.TeamColor = "Azul", roblox.BrickColor.new("Really blue")
teamA.Parent, teamB.Parent = Teams, Teams
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId, me.Team = "Yo", "Yo", 1, teamB
me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
RS:SetAttribute("TeamA", "Rojo"); RS:SetAttribute("TeamB", "Azul"); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("ModeName", "Infección"); RS:SetAttribute("Mode", "INF"); RS:SetAttribute("MapName", "Mansión Encantada")
local Remotes = req(RS.Shared.Remotes)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.Data = { Level = 3, XP = 10, XPPerLevel = 1000, Coins = 500, TotalKills = 4, RankPoints = 240, DailyAvailable = false }
ClientState.InMainMenu = false
local HUD = req(game.StarterPlayer.Client.Modules.HUD)
local ok, err = pcall(HUD.Init)
check(ok, "HUD.Init sin errores " .. tostring(err))
local function texts(root)
	local t = {}
	for _, d in root:GetDescendants() do
		if d.__className == "TextLabel" or d.__className == "TextButton" then t[d.Text] = d end
	end
	return t
end
-- Infección en marcha: contadores y aviso de zombi
RS:SetAttribute("State", "Playing"); RS:SetAttribute("Infection", "On"); RS:SetAttribute("AliveA", 3); RS:SetAttribute("AliveB", 2)
task.wait(1.2)
local t = texts(pg)
check(t["🧑 Supervivientes"] and t["🧟 Zombis"], "marcador de supervivientes y zombis")
check(t["Infección · 🧟 Eres un zombi: ¡atrapa a los supervivientes!"], "aviso de que eres zombi")
-- Resumen de partida que sube de rango (240 -> 265 = Oro)
RS:SetAttribute("Infection", nil)
RS:SetAttribute("State", "Ended")
Remotes.RoundEnd.OnClientEvent:Fire({ TeamMode = true, Winner = "Azul", ScoreA = 0, ScoreB = 1, MVP = "Yo", MVPKills = 3, Top = { { Name = "Bot Max", Kills = 9, Deaths = 2, Bot = true }, { Name = "Yo", Kills = 7, Deaths = 3 }, { Name = "Bot Leo", Kills = 5, Deaths = 5, Bot = true } } })
do
	local found = false
	for _, d in pg:GetDescendants() do
		if d.ClassName == "TextLabel" and type(d.Text) == "string" and string.find(d.Text, "Bot Max 9/2", 1, true) and string.find(d.Text, "#FFE150", 1, true) then found = true end
	end
	check(found, "podio en la pantalla final (tú en amarillo)")
end
Remotes.MatchSummary.OnClientEvent:Fire({ XP = 300, Coins = 80, StartLevel = 3, StartXP = 10, Level = 3, LevelXP = 310, XPPerLevel = 1000, Kills = 3, Deaths = 1, BestStreak = 2, WinStreak = 2, StartRank = 240, RankPoints = 265 })
task.wait(2.5)
t = texts(pg)
local rankLabel
for text in t do
	if string.find(text, "ORO", 1, true) and string.find(text, "+25 RP", 1, true) then rankLabel = text end
end
check(rankLabel ~= nil, "resumen con rango y RP ganados (" .. tostring(rankLabel) .. ")")
check(t["🥇 ¡ASCIENDES A ORO!"], "aviso de subir de rango")
local stats
for text in t do
	if string.find(text, "🏆 x2", 1, true) then stats = text end
end
check(stats ~= nil, "racha de victorias en el resumen")
-- Pantalla de inicio: tarjeta de rango
ClientState.InMainMenu = true
local MainMenu = req(game.StarterPlayer.Client.Modules.MainMenu)
ok, err = pcall(MainMenu.Init)
check(ok, "MainMenu.Init sin errores " .. tostring(err))
task.wait(1.5)
t = texts(pg)
local card, nextText
for text in t do
	if string.find(text, "240 RP", 1, true) and string.find(text, "PLATA", 1, true) then card = text end
	if string.find(text, "Faltan 10 RP", 1, true) then nextText = text end
end
check(card ~= nil and nextText ~= nil, "tarjeta de rango en la pantalla de inicio (" .. tostring(nextText) .. ")")
-- Resultado de ronda: GANADA para tu equipo (Azul), con marcador y el mejor de la ronda
Remotes.Notify.OnClientEvent:Fire("Round", { Winner = "Azul", Number = 2, ScoreA = 1, ScoreB = 2, MVP = "Yo", MVPKills = 3 })
local big, sub
for _, d in pg:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "RONDA GANADA" then big = d end
	if d.__className == "TextLabel" and type(d.Text) == "string" and string.find(d.Text, "⭐ Yo", 1, true) then sub = d end
end
check(big ~= nil, "ronda de tu equipo: RONDA GANADA")
check(sub ~= nil and sub.Visible and string.find(sub.Text, "Rojo 1", 1, true) ~= nil, "con el marcador y el mejor de la ronda")
Remotes.Notify.OnClientEvent:Fire("Round", { Winner = "Rojo", Number = 3, ScoreA = 2, ScoreB = 2 })
local lost
for _, d in pg:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "RONDA PERDIDA" then lost = d end
end
check(lost ~= nil, "ronda del rival: RONDA PERDIDA")
-- Desbloqueo de arma: no se queda en un aviso pequeño
local ok = pcall(function() Remotes.Notify.OnClientEvent:Fire("Unlock", "¡Arma desbloqueada: Vortex AR-9!") end)
check(ok, "desbloquear un arma no rompe el HUD")
Remotes.Notify.OnClientEvent:Fire("Unlock", "¡Skin desbloqueada: Atardecer!")
local unlock
for _, d in pg:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "🔓 ¡Skin desbloqueada: Atardecer!" then unlock = d end
end
check(unlock ~= nil, "una skin desbloqueada sale en grande")
print("HUD CLIENTE OK")
process.exit(0)
