-- El HUD usa los efectos de recompensa: bajas seguidas, XP, subir de nivel y próximo premio
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId = "Yo", "Yo", 1
me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
RS:SetAttribute("State", "Playing"); RS:SetAttribute("TeamMode", true)
local Remotes = req(RS.Shared.Remotes)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.Data = { Level = 3, XP = 10, XPPerLevel = 1000, Coins = 500, TotalKills = 4, RankPoints = 240 }
ClientState.InMainMenu = false
local RewardFX = req(game.StarterPlayer.Client.Modules.RewardFX)
RewardFX.Init()
local HUD = req(game.StarterPlayer.Client.Modules.HUD)
local ok, err = pcall(HUD.Init)
check(ok, "HUD.Init sin errores " .. tostring(err))
local function find(root, pred)
	for _, d in root:GetDescendants() do
		if (d.__className == "TextLabel") and type(d.Text) == "string" and pred(d.Text) then return d end
	end
end
-- Próximo premio del pase en la barra de nivel (nivel 4: Free = nil → el premium)
local level = find(pg, function(t) return string.find(t, "Nivel 3", 1, true) ~= nil end)
check(level and not string.find(level.Text, "👑", 1, true), "sin pase premium a la venta, no anuncia sus premios (" .. tostring(level and level.Text) .. ")")
ClientState.Data = { Level = 4, XP = 10, XPPerLevel = 1000, Coins = 500 }
ClientState.DataChanged:Fire(ClientState.Data)
level = find(pg, function(t) return string.find(t, "Nivel 4", 1, true) ~= nil end)
check(level and string.find(level.Text, "Próximo: 🎨 Skin", 1, true), "la barra de nivel enseña el próximo premio (" .. tostring(level and level.Text) .. ")")
ClientState.Data = { Level = 3, XP = 10, XPPerLevel = 1000, Coins = 500 }
ClientState.DataChanged:Fire(ClientState.Data)
-- El enemigo al que das destella (y luego se suelta el resaltado)
local enemy = mock.new("Model"); enemy.Name = "Bot Max"; enemy.Parent = game.Workspace
ClientState.LastHitModel = enemy; ClientState.LastHitTime = os.clock()
Remotes.HitConfirm.OnClientEvent:Fire(30, false, false, nil)
local flash = game.Workspace.CurrentCamera:FindFirstChild("HitFlash")
check(flash ~= nil and flash.Adornee == enemy, "el enemigo impactado destella")
task.wait(0.3)
check(flash.Adornee == nil and flash.Enabled == false, "y el destello se suelta enseguida")
task.wait(1)
ClientState.LastHitModel = nil
-- Daño que se suma sobre el mismo enemigo
local function boards()
	local n, texts = 0, {}
	for _, c in pg:GetChildren() do
		if c.__className == "BillboardGui" then n += 1; local l = c:FindFirstChildOfClass("TextLabel"); table.insert(texts, l and l.Text) end
	end
	return n, texts
end
for _ = 1, 3 do Remotes.HitConfirm.OnClientEvent:Fire(30, false, false, roblox.Vector3.new(10, 3, -20)); task.wait(0.1) end
local n, texts = boards()
check(n == 1 and texts[1] == "90", "el daño al mismo enemigo se va sumando en un solo número (" .. n .. ", " .. tostring(texts[1]) .. ")")
Remotes.HitConfirm.OnClientEvent:Fire(25, false, false, roblox.Vector3.new(60, 3, -20))
n = boards()
check(n == 2, "otro enemigo lejos lleva su propio número")
task.wait(1.3)
n = boards()
check(n == 0, "y se recogen solos")
-- Dos bajas seguidas
ok, err = pcall(function()
	Remotes.HitConfirm.OnClientEvent:Fire(100, true, true, roblox.Vector3.new(0, 3, -20))
	Remotes.KillFeed.OnClientEvent:Fire({ KillerColor = roblox.Color3.new(0, 0, 1), VictimColor = roblox.Color3.new(1, 0, 0), Killer = "Yo", Victim = "Bot Max", Weapon = "ARX-27", WeaponId = "ARX27", Headshot = true })
	task.wait(0.2)
	Remotes.KillFeed.OnClientEvent:Fire({ KillerColor = roblox.Color3.new(0, 0, 1), VictimColor = roblox.Color3.new(1, 0, 0), Killer = "Yo", Victim = "Bot Leo", Weapon = "ARX-27", WeaponId = "ARX27" })
end)
check(ok, "bajas sin errores " .. tostring(err))
check(find(pg, function(t) return t == "¡DOBLE BAJA!" end) ~= nil, "doble baja")
check(game:GetService("Lighting"):FindFirstChild("KillPulseCC") ~= nil, "con el destello de la baja")
-- XP: el contador de la jugada
Remotes.Notify.OnClientEvent:Fire("XP", "+100 XP  Baja")
Remotes.Notify.OnClientEvent:Fire("XP", "+50 XP  Disparo a la cabeza")
local fxGui = pg:FindFirstChild("RewardFX")
local RunService = game:GetService("RunService")
for _ = 1, 120 do RunService.RenderStepped:Fire(1 / 60) end
check(fxGui:FindFirstChild("ScoreTotal").Text == "+150", "suma la XP de la jugada")
-- Subir de nivel: celebración
Remotes.Notify.OnClientEvent:Fire("LevelUp", 4)
check(fxGui:FindFirstChild("Celebration") ~= nil, "subir de nivel se celebra a pantalla completa")
-- Ganar XP hace destellar la barra (y no rompe nada)
ClientState.Data = { Level = 3, XP = 200, XPPerLevel = 1000, Coins = 500 }
ok, err = pcall(function() ClientState.DataChanged:Fire(ClientState.Data) end)
check(ok, "la barra se actualiza " .. tostring(err))
-- Victoria: confeti (y el título entra de golpe)
local teamA = mock.new("Team"); teamA.Name = "Azul"; teamA.Parent = game:GetService("Teams")
me.Team = teamA
task.wait(3.5) -- (que termine la celebración del nivel)
Remotes.RoundEnd.OnClientEvent:Fire({ TeamMode = true, Winner = "Azul", ScoreA = 0, ScoreB = 1, MVP = "Yo", MVPKills = 3, Top = {} })
check(fxGui:FindFirstChild("Confetti") ~= nil, "al ganar, confeti")
task.wait(1)
check(find(pg, function(t) return t == "⭐ ¡ERES EL MVP! (3 bajas)" end) ~= nil, "si eres el MVP, lo dice a lo grande")
task.wait(3.6)
-- Resumen sin subir de nivel: cuánto falta
Remotes.MatchSummary.OnClientEvent:Fire({ XP = 300, Coins = 80, StartLevel = 3, StartXP = 10, Level = 3, LevelXP = 310, XPPerLevel = 1000, Kills = 3, Deaths = 1, BestStreak = 2, WinStreak = 0, StartRank = 240, RankPoints = 240 })
task.wait(1.6)
local near = find(pg, function(t) return string.find(t, "Solo te faltan 690 XP para el nivel 4", 1, true) ~= nil end)
check(near ~= nil and near.Visible, "el resumen dice cuánto falta para el siguiente nivel (" .. tostring(near and near.Text) .. ")")
-- Récord personal de bajas: celebración en el resumen
task.wait(4)
Remotes.MatchSummary.OnClientEvent:Fire({ XP = 300, Coins = 80, StartLevel = 3, StartXP = 10, Level = 3, LevelXP = 310, XPPerLevel = 1000, Kills = 12, Deaths = 1, BestStreak = 6, WinStreak = 0, StartRank = 240, RankPoints = 240, NewRecord = 12, PrevRecord = 9 })
task.wait(1.6)
check(find(fxGui, function(t) return t == "🏆 ¡NUEVO RÉCORD!" end) ~= nil, "récord de bajas: celebración")
check(find(fxGui, function(t) return t == "12 bajas en una partida  (antes 9)" end) ~= nil, "dice el récord nuevo y el anterior")
-- Racha: a las 10 bajas sin morir, aviso grande
RS:SetAttribute("State", "Playing")
me:SetAttribute("Streak", 9)
for _ = 1, 5 do RunService.RenderStepped:Fire(1 / 60); RunService.Heartbeat:Fire(1 / 60) end
me:SetAttribute("Streak", 10)
for _ = 1, 5 do RunService.RenderStepped:Fire(1 / 60); RunService.Heartbeat:Fire(1 / 60) end
check(find(pg, function(t) return t == "🔥 ¡RACHA DE 10!" end) ~= nil, "racha de 10: aviso grande")
-- Clutch en Eliminación: último en pie contra 3
task.wait(4)
RS:SetAttribute("TeamA", "Azul"); RS:SetAttribute("TeamB", "Rojo"); RS:SetAttribute("Mode", "ELIM"); RS:SetAttribute("ModeName", "Eliminación")
local char = mock.new("Model"); local hum = mock.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100; hum.Parent = char; char.Parent = game.Workspace
me.Character = char
me:SetAttribute("ElimIn", true)
RS:SetAttribute("AliveA", 3); RS:SetAttribute("AliveB", 3)
for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 60) end
RS:SetAttribute("AliveA", 1)
for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 60) end
check(find(pg, function(t) return t == "⚔ 1 CONTRA 3" end) ~= nil, "último en pie: «1 CONTRA 3»")
RS:SetAttribute("AliveB", 0)
for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 60) end
check(find(fxGui, function(t) return t == "🔥 ¡CLUTCH!" end) ~= nil, "y si ganas tú solo, ¡CLUTCH!")
task.wait(4)
-- Con la bomba plantada no es victoria todavía; y quien no juega la ronda no recibe nada
me:SetAttribute("ElimIn", nil)
RS:SetAttribute("AliveA", 3); RS:SetAttribute("AliveB", 3)
for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 60) end
RS:SetAttribute("AliveA", 1); RS:SetAttribute("AliveB", 2)
for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 60) end
RS:SetAttribute("AliveB", 0)
for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 60) end
check(find(fxGui, function(t) return t == "🔥 ¡CLUTCH!" end) == nil, "fuera de la ronda (en el menú) no hay clutch")
RS:SetAttribute("AliveA", nil); RS:SetAttribute("AliveB", nil); RS:SetAttribute("Mode", "TDM")
-- Logro completado en partida
ClientState.Data = { Level = 3, XP = 200, XPPerLevel = 1000, Coins = 500, TotalKills = 9, Achievements = {} }
ClientState.DataChanged:Fire(ClientState.Data)
ClientState.Data = { Level = 3, XP = 220, XPPerLevel = 1000, Coins = 500, TotalKills = 10, Achievements = {} }
ClientState.DataChanged:Fire(ClientState.Data)
check(find(pg, function(t) return t == "🏅 ¡LOGRO! 🎯 Consigue 10 bajas" end) ~= nil, "logro conseguido en partida: aviso")
-- Botín
ok, err = pcall(function()
	Remotes.Notify.OnClientEvent:Fire("LootDrop", "Épico")
	Remotes.Notify.OnClientEvent:Fire("Loot", { Rarity = "Épico", Coins = 100, XP = 100, Color = roblox.Color3.new(0.7, 0.3, 1) })
end)
check(ok, "avisos de botín sin errores " .. tostring(err))
check(find(pg, function(t) return string.find(t, "Botín Épico  +100 💰  +100 XP", 1, true) ~= nil end) ~= nil, "al coger el botín dice qué te ha dado")
print("HUD RECOMPENSAS OK")
process.exit(0)
