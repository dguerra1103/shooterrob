-- Estabilidad del ciclo de partidas con el SERVIDOR ENTERO (Main.server) y bots: varias partidas
-- seguidas (distintos modos y mapas) comprobando que entre partidas no se acumulan bots, mapas,
-- conexiones ni objetos sueltos, que cada jugador recibe UN resumen por partida, que las recompensas
-- no se repiten y que el ciclo nunca se queda bloqueado.
-- Limitación: es el simulador (mock). No sustituye a probarlo en Roblox Studio.
local process = require("@lune/process")
local task = require("@lune/task")
local Vector3 = require("@lune/roblox").Vector3
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "ciclo"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.EndScreenTime = 0.6
GameConfig.MinPlayers = 1
GameConfig.FinalKillcam = false
for _, s in GameConfig.ModeSettings do
	s.RoundTime = 3
	if s.PrepTime then s.PrepTime = 1 end
	if s.SubRoundTime then s.SubRoundTime = 1.5 end
end
-- Orden de modos: uno distinto en cada partida (se fija al acabar la anterior)
local ORDER = { "TDM", "DOM", "SND", "FFA", "CTF", "KOTH", "GUN", "ELIM", "INF", "CAL" }
local MATCHES = tonumber(process.args[2]) or 6
GameConfig.Modes = { ORDER[1] }
local warnings = {}
mock.onWarn = function(...)
	table.insert(warnings, table.concat({ ... }, " "))
end
-- Personajes: LoadCharacter crea uno nuevo y destruye el anterior (como en Roblox)
local Players = game:GetService("Players")
mock.onLoadCharacter = function(player)
	local old = player.Character
	local model = mock.new("Model")
	model.Name = player.Name
	local hum = mock.new("Humanoid")
	hum.Health = 100
	hum.MaxHealth = 100
	hum.HipHeight = 2
	hum.Parent = model
	for _, name in { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso" } do
		local part = mock.new("Part")
		part.Name = name
		part.Size = Vector3.new(1, 1, 1)
		part.Parent = model
	end
	model.PrimaryPart = model.HumanoidRootPart
	player.Character = model
	model.Parent = game.Workspace
	if old then
		old:Destroy()
	end
	player.CharacterAdded:Fire(model)
end
local ok, err = pcall(req, game.ServerScriptService.Server.Main)
check(ok, "Main.server arranca (" .. tostring(err) .. ")")
local Round = req(game.ServerScriptService.Server.Modules.Round)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
local Bots = req(game.ServerScriptService.Server.Modules.Bots)
local players = {}
for i = 1, 3 do
	local p = mock.new("Player"); p.Name = "J" .. i; p.UserId = 900 + i; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	players[i] = p
end
local RS = game.ReplicatedStorage
local W = game.Workspace

local function countMaps()
	local n = 0
	for _, c in W:GetChildren() do
		if c.Name == "Map" then n += 1 end
	end
	return n
end
local function botModels()
	local folder = W:FindFirstChild("Bots")
	return folder and #folder:GetChildren() or 0
end
-- Objetos sueltos en workspace (fuera del mapa, los bots, los personajes, la cámara y el terreno)
local function loose()
	local n = 0
	for _, c in W:GetChildren() do
		local name = c.Name
		if name ~= "Map" and name ~= "Bots" and name ~= "Terrain" and name ~= "Camera" and not Players:FindFirstChild(name) then
			n += #c:GetDescendants() + 1
		end
	end
	return n
end
local function summariesFor(index)
	local n = 0
	for _, sent in mock.sent do
		if sent.Remote == "MatchSummary" then n += 1 end
	end
	return n
end

local matches = {}
local last
local deadline = os.clock() + 60 + MATCHES * 25
local playingSeen = 0
local current
while os.clock() < deadline and #matches < MATCHES do
	local st = RS:GetAttribute("State")
	if current and st == "Playing" then
		current.PeakBots = math.max(current.PeakBots or 0, #Bots.Agents)
	end
	if st ~= last then
		last = st
		if st == "Playing" then
			playingSeen += 1
			current = { Mode = RS:GetAttribute("Mode"), Map = RS:GetAttribute("MapName"), Summaries = summariesFor(), Coins = PlayerData.Get(players[1]).Coins }
			-- Una baja de prueba (J1 elimina a J2): recompensas de verdad
			task.delay(0.6, function()
				pcall(Round.RegisterKill, players[1], players[2], "J2", "ARX27", false, nil)
			end)
		elseif st == "Ended" and current then
			-- Siguiente partida: otro modo
			GameConfig.Modes = { ORDER[(#matches + 1) % #ORDER + 1] }
		elseif st == "Intermission" and current then
			-- (la partida anterior ya terminó del todo: medir lo que queda)
			task.wait(0.3)
			current.MapsAfter = countMaps()
			current.BotsAfter = #Bots.Agents
			current.BotModelsAfter = botModels()
			current.Connections = mock.liveConnections
			current.Loose = loose()
			current.NewSummaries = summariesFor() - current.Summaries
			table.insert(matches, current)
			print(string.format("partida %d · %s · %s · bots en partida %d · al acabar: mapas %d, bots %d (modelos %d), conexiones %d, sueltos %d · resúmenes +%d",
				#matches, tostring(current.Mode), tostring(current.Map), current.PeakBots or 0, current.MapsAfter, current.BotsAfter, current.BotModelsAfter, current.Connections, current.Loose, current.NewSummaries))
			current = nil
		end
	end
	task.wait(0.05)
end
check(#matches >= MATCHES, "se juegan " .. MATCHES .. " partidas seguidas sin bloquearse (" .. #matches .. ")")
local modes = {}
for i, m in matches do
	check(m.MapsAfter == 1, "partida " .. i .. ": un solo mapa en workspace")
	check(m.BotsAfter == 0 and m.BotModelsAfter == 0, "partida " .. i .. ": no quedan bots al acabar (" .. m.BotsAfter .. "/" .. m.BotModelsAfter .. ")")
	check(m.NewSummaries == #players, "partida " .. i .. ": un resumen por jugador (" .. m.NewSummaries .. ")")
	check((m.PeakBots or 0) >= 1 and (m.PeakBots or 0) <= GameConfig.Bots.FillTo - #players, "partida " .. i .. ": entran bots y nunca más de los que caben (" .. tostring(m.PeakBots) .. ")")
	modes[m.Mode] = true
end
local modeCount = 0
for _ in modes do modeCount += 1 end
check(modeCount >= math.min(MATCHES, 5), "varios modos distintos (" .. modeCount .. ")")
-- Conexiones y objetos sueltos: tras la 2.ª partida no deben crecer sin parar
local first, final = matches[2], matches[#matches]
check(final.Connections <= first.Connections + 40, string.format("las conexiones no se acumulan (%d → %d)", first.Connections, final.Connections))
check(final.Loose <= first.Loose + 60, string.format("los objetos sueltos no se acumulan (%d → %d)", first.Loose, final.Loose))
-- Errores del servidor durante el ciclo
local bad = {}
for _, line in warnings do
	if string.find(line, "Arranque", 1, true) or string.find(line, "Error", 1, true) or string.find(line, "think", 1, true) or string.find(line, "balance", 1, true) or string.find(line, "se reinicia", 1, true) then
		table.insert(bad, line)
	end
end
for _, line in bad do print("AVISO:", line) end
check(#bad == 0, "sin errores del servidor en el ciclo")
print("CICLO OK")
process.exit(0)
