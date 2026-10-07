-- Pantalla final en el cliente: todos los casos (victoria, derrota, TDM, S&D, nombres largos, menos de 5,
-- con y sin recompensas, subida de nivel, desbloqueo, desafíos, marcador, jugar de nuevo, lobby,
-- siguiente partida automática y cancelarla, móvil, limpieza de la escena)
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
local RunService = game:GetService("RunService")
local W, H = tonumber(process.args[2]) or 1280, tonumber(process.args[3]) or 720
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", roblox.BrickColor.new("Really red")
teamB.Name, teamB.TeamColor = "Azul", roblox.BrickColor.new("Really blue")
teamA.Parent, teamB.Parent = Teams, Teams
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId, me.Team = "DGSR", "DGSR", 1, teamB
me.Parent = Players
table.insert(mock.players, me)
me:SetAttribute("InMenu", false)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(W, H)
RS:SetAttribute("TeamA", "Rojo"); RS:SetAttribute("TeamB", "Azul"); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("Mode", "TDM"); RS:SetAttribute("ModeName", "Duelo por equipos"); RS:SetAttribute("MapName", "Construction")
RS:SetAttribute("State", "Playing")

-- RenderStepped con desconexión de verdad
local conns = {}
local stepped = {}
function stepped:Connect(fn)
	local c = { Connected = true }
	function c.Disconnect() c.Connected = false end
	c.Fn = fn
	table.insert(conns, c)
	return c
end
rawget(RunService, "__props").RenderStepped = stepped
local errors = {}
task.spawn(function()
	while true do
		for _, c in table.clone(conns) do
			if c.Connected then
				local ok, err = pcall(c.Fn, 0.05)
				if not ok then table.insert(errors, tostring(err)) end
			end
		end
		for name, fn in mock.renderSteps do
			local ok, err = pcall(fn, 0.05)
			if not ok then table.insert(errors, name .. ": " .. tostring(err)) end
		end
		task.wait(0.05)
	end
end)

local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local GameConfig = req(RS.Shared.GameConfig)
GameConfig.EndScreenTime = 8
local classes = {}
for i, c in GameConfig.DefaultClasses do classes[i] = table.clone(c) end
ClientState.Data = { Level = 42, XP = 350, XPPerLevel = 1000, Coins = 900, RankPoints = 300, Primary = "ARX27", Classes = classes, ActiveClass = 1 }

local function visible(inst)
	while inst and inst ~= pg do
		if inst.Visible == false or inst.Enabled == false then return false end
		inst = inst.Parent
	end
	return true
end
local function texts()
	local t = {}
	for _, d in pg:GetDescendants() do
		if (d.__className == "TextLabel" or d.__className == "TextButton") and type(d.Text) == "string" and visible(d) then t[d.Text] = d end
	end
	return t
end
local function has(pattern)
	for text in texts() do
		if string.find(text, pattern, 1, true) then return text end
	end
	return nil
end
local function sent(name, value)
	for _, s in mock.serverSent do
		if s.Remote == name and (value == nil or s.Args[1] == value) then return true end
	end
	return false
end
local function waitFor(fn, timeout)
	local t0 = os.clock()
	while not fn() and os.clock() - t0 < timeout do task.wait(0.05) end
	return fn()
end

local MainMenu = req(game.StarterPlayer.Client.Modules.MainMenu)
check(pcall(MainMenu.Init), "MainMenu.Init")
local Flow = MainMenu.Flow
check(Flow.Screens.Results ~= nil, "pantalla Results registrada")
check(ClientState.ResultsScreen == true, "el HUD sabe que hay pantalla final")
local Remotes = req(RS.Shared.Remotes)

-- Reparto: copias de avatar en ReplicatedStorage.ResultsCast (como las deja el servidor)
local function castModel(id)
	local folder = RS:FindFirstChild("ResultsCast") or mock.new("Folder")
	folder.Name = "ResultsCast"; folder.Parent = RS
	local model = mock.new("Model"); model.Name = id
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = model
	for _, n in { "HumanoidRootPart", "Head", "UpperTorso", "RightHand" } do
		local part = mock.new("Part"); part.Name = n; part.Parent = model
	end
	model.Parent = folder
end

local function entry(id, name, team, k, a, d, extra)
	local e = { Id = id, Name = name, Team = team, Kills = k, Assists = a, Deaths = d, Captures = 0, Points = k * 100 + a * 50, Weapon = "ARX27" }
	for key, v in extra or {} do e[key] = v end
	return e
end

-- Entra en partida y acaba
local function endMatch(result, summary)
	Flow.SetState("Gameplay")
	RS:SetAttribute("State", "Playing")
	task.wait(0.1)
	RS:SetAttribute("State", "Ended")
	check(ClientState.ResultsActive == true, "al acabar, el HUD deja de celebrar (ResultsActive)")
	Remotes.RoundEnd.OnClientEvent:Fire({ Result = result, TeamMode = result.TeamMode, ScoreA = result.ScoreA, ScoreB = result.ScoreB })
	if summary then
		task.wait(0.1)
		Remotes.MatchSummary.OnClientEvent:Fire(summary)
	end
end

-------------------------------------------------------------------------
-- 1. VICTORIA en Duelo por equipos, 5 jugadores, recompensas, sube de nivel, desbloqueo y desafíos
-------------------------------------------------------------------------
local allies = {
	entry("u1", "DGSR", "Azul", 32, 6, 8),
	entry("u2", "MateoPro", "Azul", 18, 9, 12),
	entry("bCarlos", "Carlos123", "Azul", 15, 0, 14, { Bot = true }),
	entry("u4", "LuisF", "Azul", 12, 8, 16),
	entry("u5", "Axel", "Azul", 10, 7, 18),
}
local enemies = {
	entry("u6", "Sebas", "Rojo", 28, 12, 15),
	entry("bDiego", "Diego", "Rojo", 20, 0, 18, { Bot = true }),
	entry("u8", "Reaper", "Rojo", 16, 8, 19),
}
local all = {}
for _, e in allies do table.insert(all, e); castModel(e.Id) end
for _, e in enemies do table.insert(all, e) end
local victory = { Mode = "TDM", ModeName = "Duelo por equipos", Map = "Construction", TeamMode = true, TeamA = "Rojo", TeamB = "Azul", ScoreA = 72, ScoreB = 100, Winner = "Azul", Reason = "ScoreLimit", MVP = "u1", Players = all }
local summary = {
	XP = 520, Coins = 200, BonusCoins = 50, Crates = 1, StartLevel = 42, StartXP = 350, Level = 43, LevelXP = 870 + 350 - 1000, XPPerLevel = 1000,
	StartRank = 300, RankPoints = 325,
	Challenges = { { Text = "Consigue 15 bajas", Goal = 15, Coins = 150 }, { Text = "Gana 2 partidas", Goal = 2, Coins = 250, Weekly = true } },
	Unlocks = { { Kind = "Weapon", Id = "VortexBR", Name = "Vortex AR-9", Sub = "FUSIL DE ASALTO" } },
}
local t0 = os.clock()
endMatch(victory, summary)
check(Flow.State == "Results", "fin de partida → pantalla final (" .. Flow.State .. ")")
check(ClientState.InMainMenu == true, "HUD de partida fuera y controles bloqueados")
task.wait(1.0)
local t = texts()
check(t["VICTORIA"] ~= nil, "VICTORIA")
check(has("L Í M I T E   D E   P U N T O S") ~= nil, "motivo del servidor (tildes enteras): " .. tostring(has("L Í M")))
check(t["5V5  ·  DUELO POR EQUIPOS"] ~= nil and t["MAPA: CONSTRUCTION"] ~= nil, "modo y mapa")
check(game.Workspace:FindFirstChild("PresentationScenes") and game.Workspace.PresentationScenes:FindFirstChild("ResultsStage"), "escena 3D montada")
local stageFolder = game.Workspace.PresentationScenes.ResultsStage
local placed = 0
for _, child in stageFolder:GetChildren() do
	if string.sub(child.Name, 1, 7) == "Result_" then placed += 1 end
end
check(placed == 5, "los 5 de tu equipo en escena (" .. placed .. ")")
check(stageFolder:FindFirstChild("Result_u1") ~= nil, "el MVP en escena")
local mvpModel = stageFolder:FindFirstChild("Result_u1")
local hasWeapon = false
for _, c in mvpModel:GetChildren() do
	if c.__className == "Tool" then hasWeapon = true end
end
check(hasWeapon, "con su arma en las manos")
check(game.Lighting:FindFirstChild("ResultsDepth") and game.Lighting:FindFirstChild("ResultsGrade"), "profundidad de campo y color solo durante la pantalla")
task.wait(1.2)
t = texts()
check(t["100"] and t["72"], "marcador 100 VS 72")
check(t["TU EQUIPO"] and t["EQUIPO ENEMIGO"], "TU EQUIPO / EQUIPO ENEMIGO")
task.wait(1.3)
t = texts()
check(t["MVP"] ~= nil, "placa MVP")
check(t["32"] and t["3500"], "MVP: 32 eliminaciones, 3500 puntos (32×100 + 6×50)")
check(t["ELIMINACIONES"] and t["ASISTENCIAS"], "cifras del MVP con su nombre")
check(t["MATEOPRO"] == nil and t["MateoPro"] ~= nil, "tarjetas de los compañeros")
check(t["🤖 Carlos123"] ~= nil, "bots marcados")
task.wait(2.2)
t = texts()
check(t["+520"] ~= nil, "+520 XP (" .. tostring(has("+5")) .. ")")
check(t["+250"] ~= nil, "+250 monedas (jugar + retos)")
check(t["+1"] ~= nil and t["CAJA GRATIS"], "caja gratis")
check(has("+25 RP") ~= nil, "rango +25 RP")
check(t["NIVEL 43"] ~= nil, "barra de nivel: sube al 43")
check(has("220 / 1000 XP") ~= nil, "y sigue con lo que sobra (220/1000)")
check(t["DESAFÍOS COMPLETADOS"] and t["Consigue 15 bajas"] and t["SEMANAL · Gana 2 partidas"], "desafíos completados")
check(t["DESBLOQUEO"] and t["VORTEX AR-9"], "desbloqueo: Vortex AR-9")
check(t["JUGAR DE NUEVO"] ~= nil, "JUGAR DE NUEVO")
check(has("SIGUIENTE PARTIDA EN") ~= nil, "siguiente partida en … s")
check(t["VOLVER AL LOBBY"] and t["VER MARCADOR"], "volver al lobby y ver marcador")
check(os.clock() - t0 < 7, "todo visible en pocos segundos")
-- Marcador completo
Flow.Screens.Results.Screen:FindFirstChild("Scoreboard", true).Visible = false
local board = Flow.Screens.Results.Screen:FindFirstChild("Scoreboard", true)
for _, b in Flow.Screens.Results.Screen:GetDescendants() do
	if b.Name == "Scoreboard" and b.__className == "TextButton" then b.Activated:Fire() end
end
check(board.Visible, "VER MARCADOR abre la tabla")
t = texts()
check(t["PUNTOS"] and t["KILLS"] and t["ASIST."] and t["MUERTES"], "columnas de la tabla")
check(t["Sebas"] and t["🤖 Diego"], "equipo enemigo en la tabla")
local rows = {}
for _, d in board:GetDescendants() do
	if d.Name == "Row" then table.insert(rows, d) end
end
check(#rows == 8, "una fila por jugador (" .. #rows .. ")")
-- (la primera fila de tu equipo es la del MVP con la placa)
local foundMVPBadge = false
for _, d in board:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "MVP" then foundMVPBadge = true end
end
check(foundMVPBadge, "placa MVP en la tabla")
board.Visible = false
-- Siguiente partida automática al empezar el descanso
RS:SetAttribute("State", "Intermission")
check(Flow.State == "Matchmaking", "al acabar la pantalla final: buscando la siguiente (" .. Flow.State .. ")")
check(game.Workspace.PresentationScenes:FindFirstChild("ResultsStage") == nil, "la escena se borra al salir")
check(game.Lighting:FindFirstChild("ResultsDepth") == nil and game.Lighting:FindFirstChild("ResultsGrade") == nil, "efectos de luz quitados")
check(ClientState.ResultsActive == false, "ResultsActive se apaga")

-------------------------------------------------------------------------
-- 2. DERROTA en Buscar y destruir (4-2, bomba desactivada), sin recompensas, 3 compañeros, nombre largo
-------------------------------------------------------------------------
RS:SetAttribute("State", "Playing")
local longName = "ElNombreMasLargoDelServidor_2026"
local sndAllies = {
	entry("u1", "DGSR", "Azul", 3, 1, 4),
	entry("u9", longName, "Azul", 5, 0, 3),
	entry("bRook", "Rook", "Azul", 1, 0, 4, { Bot = true }),
}
local sndAll = {}
for _, e in sndAllies do table.insert(sndAll, e); castModel(e.Id) end
table.insert(sndAll, entry("u6", "Sebas", "Rojo", 9, 2, 2))
local defeat = { Mode = "SND", ModeName = "Buscar y destruir", Map = "Desert Base", TeamMode = true, TeamA = "Rojo", TeamB = "Azul", ScoreA = 4, ScoreB = 2, Winner = "Rojo", Reason = "BombDefused", MVP = "u6", Players = sndAll }
endMatch(defeat, { XP = 0, Coins = 0, BonusCoins = 0, Crates = 0, StartLevel = 43, StartXP = 220, Level = 43, LevelXP = 220, XPPerLevel = 1000, StartRank = 325, RankPoints = 325, Challenges = {}, Unlocks = {} })
check(Flow.State == "Results", "derrota → pantalla final")
task.wait(3.6)
t = texts()
check(t["DERROTA"] ~= nil, "DERROTA")
check(has("B O M B A   D E S A C T I V A D A") ~= nil, "motivo de Buscar y destruir (no 'límite de puntos')")
check(t["2"] and t["4"], "marcador pequeño 2 - 4")
check(t["DESTACADO"] ~= nil and t["MVP"] == nil, "tu mejor jugador como DESTACADO (el MVP es rival)")
check(has("ElNombreMasLargo") and string.find(has("ElNombreMasLargo"), "…", 1, true), "nombre largo recortado con … (" .. tostring(has("ElNombreMasLargo")) .. ")")
local cards = 0
for _, d in Flow.Screens.Results.Screen:GetDescendants() do
	if d.Name == "PlayerCard" and visible(d) then cards += 1 end
end
check(cards == 2, "con 3 en el equipo: destacado + 2 tarjetas (" .. cards .. ")")
check(t["RECOMPENSAS"] == nil, "sin recompensas: el panel no sale")
check(t["DESBLOQUEO"] == nil and t["DESAFÍOS COMPLETADOS"] == nil, "sin desbloqueos ni desafíos: no ocupan sitio")
check(t["NIVEL 43"] ~= nil, "el progreso de nivel sigue saliendo")
check(t["JUGAR DE NUEVO"] ~= nil, "JUGAR DE NUEVO también en la derrota")
-- Cancelar la siguiente automática: se queda; al cargar el mapa siguiente, su presentación
for _, b in Flow.Screens.Results.Screen:GetDescendants() do
	if b.Name == "CancelAuto" and b.__className == "TextButton" then b.Activated:Fire() end
end
RS:SetAttribute("State", "Intermission")
check(Flow.State == "Results", "CANCELAR: sigue en la pantalla final durante el descanso")
RS:SetAttribute("State", "LoadingMap"); RS:SetAttribute("LoadingMap", "Dockyard")
check(Flow.State == "MapIntro", "llega la partida siguiente: presentación del mapa")
RS:SetAttribute("LoadingMap", nil)

-------------------------------------------------------------------------
-- 3. VOLVER AL LOBBY y JUGAR DE NUEVO con botón
-------------------------------------------------------------------------
endMatch(victory, nil)
task.wait(3.2)
for _, b in Flow.Screens.Results.Screen:GetDescendants() do
	if b.Name == "Lobby" and b.__className == "TextButton" then b.Activated:Fire() end
end
check(Flow.State == "Home" and sent("EnterMenu"), "VOLVER AL LOBBY → lobby (y el servidor lo sabe)")
endMatch(victory, nil)
task.wait(3.2)
check(has("RECOMPENSAS") == nil, "sin resumen del servidor: no se inventan recompensas")
for _, b in Flow.Screens.Results.Screen:GetDescendants() do
	if b.Name == "PlayAgain" and b.__className == "TextButton" then b.Activated:Fire() end
end
check(Flow.State == "Matchmaking", "JUGAR DE NUEVO → buscando la siguiente")

-------------------------------------------------------------------------
-- 4. Quien no jugó (en el lobby) no ve la pantalla
-------------------------------------------------------------------------
Flow.SetState("Home")
Remotes.RoundEnd.OnClientEvent:Fire({ Result = victory })
check(Flow.State == "Home", "en el lobby no se interrumpe")
Flow.SetState("Gameplay")
local other = table.clone(victory)
other.Players = { entry("u99", "Otro", "Azul", 1, 0, 1) }
Remotes.RoundEnd.OnClientEvent:Fire({ Result = other })
check(Flow.State == "Gameplay", "si no estás en el resultado, no sale")

check(#errors == 0, "sin errores por fotograma " .. (errors[1] or ""))
print("RESULTADOS OK")
process.exit(0)
