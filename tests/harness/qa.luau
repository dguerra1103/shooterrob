-- Modo QA (Fase 8): inaccesible con la opción apagada y fuera de Studio (ni RemoteEvent, ni comandos, ni
-- panel); en Studio, los comandos hacen lo que dicen, rechazan lo que no vale, y el panel solo existe
-- con el modo activo. Incluye una partida forzada (Coastal + DOM) terminada con «gana B».
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Shared = RS.Shared
local GameConfig = req(Shared.GameConfig)
local QA = req(Shared.QA)
GameConfig.IntermissionTime = 30 -- (largo: «Jugar ya» tiene que cortarlo)
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.EndScreenTime = 0.5
GameConfig.MinPlayers = 1
for _, s in GameConfig.ModeSettings do
	s.RoundTime = 60 -- (larga: la termina el comando)
end

local M = game.ServerScriptService.Server.Modules
local MapBuilder = req(M.MapBuilder)
local PlayerData = req(M.PlayerData)
local Combat = req(M.Combat)
local Round = req(M.Round)
local Bots = req(M.Bots)
local QAServer = req(M.QAServer)
MapBuilder.Build()
PlayerData.Init()
Combat.Init()
Combat.OnKill = Round.RegisterKill
local players = {}
for i = 1, 2 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.UserId = 700 + i; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	players[i] = p
end
local p1 = players[1]
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = p1
game:GetService("Players").LocalPlayer = p1
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local QAPanel = req(game.StarterPlayer.Client.Modules.QAPanel)

local function replies(kind)
	local list = {}
	for _, sent in mock.sent do
		if sent.Remote == QA.RemoteName and (kind == nil or sent.Args[1] == kind) then
			table.insert(list, sent.Args[2])
		end
	end
	return list
end

-- 1. Por defecto: apagado. Nada existe y los comandos se rechazan
check(GameConfig.QA.Enabled == false, "GameConfig.QA.Enabled = false por defecto")
check(not QA.IsActive(), "sin la opción, el modo QA no está activo (aunque sea Studio)")
QAServer.Init()
check(RS:FindFirstChild(QA.RemoteName) == nil, "sin la opción: no se crea el RemoteEvent")
check(QAServer.Handle(p1, "Bots", { Set = 3 }) == false and Bots.QAFillTo == nil, "sin la opción: el servidor rechaza los comandos")
QAPanel.Init()
check(pg:FindFirstChild("QAPanel") == nil, "sin la opción: no hay panel")

-- 2. Opción encendida pero fuera de Studio (servidor publicado): sigue sin existir
GameConfig.QA.Enabled = true
mock.isStudio = false
check(not QA.IsActive(), "con la opción pero fuera de Studio: inactivo")
QAServer.Init()
check(RS:FindFirstChild(QA.RemoteName) == nil, "fuera de Studio: no se crea el RemoteEvent")
check(QAServer.Handle(p1, "NextMatch", { Map = "Coastal", Mode = "DOM", Now = true }) == false and Round.QANext == nil,
	"fuera de Studio: el servidor rechaza los comandos")
check(QAServer.Handle(p1, "HitTelemetry", { On = true }) == false and GameConfig.HitTelemetry.Enabled == false,
	"fuera de Studio: la telemetría no se puede encender")

-- 3. Studio + opción: activo
mock.isStudio = true
check(QA.IsActive(), "en Studio y con la opción: activo")
QAServer.Init()
local remote = RS:FindFirstChild(QA.RemoteName)
check(remote ~= nil, "en Studio: RemoteEvent creado")

-- Comandos que no valen
QAServer.Handle(p1, "NextMatch", { Map = "NoExiste", Mode = "TDM" })
check(Round.QANext == nil and #replies("Error") == 1, "mapa desconocido: rechazado")
QAServer.Handle(p1, "NextMatch", { Map = "Coastal", Mode = "XYZ" })
check(Round.QANext == nil and #replies("Error") == 2, "modo desconocido: rechazado")
QAServer.Handle(p1, "Weapon", { Id = "NoExiste" })
check(#replies("Error") == 3, "arma desconocida: rechazada")
QAServer.Handle(p1, "Bots", { Set = "mucho" })
check(Bots.QAFillTo == nil and #replies("Error") == 4, "cantidad de bots no válida: rechazada")
QAServer.Handle(p1, "EndMatch", { Winner = 3 })
check(#replies("Error") == 5, "ganador no válido: rechazado")
check(QAServer.Handle(p1, "Borrar todo", {}) == false, "comando desconocido: rechazado")

-- Bots, telemetría y foto
QAServer.Handle(p1, "Bots", { Set = 4 })
check(Bots.QAFillTo == 4, "bots: total fijado a 4")
QAServer.Handle(p1, "Bots", { Delta = 100 })
check(Bots.QAFillTo == 16, "bots: con tope de 16")
QAServer.Handle(p1, "Bots", { Delta = -100 })
check(Bots.QAFillTo == 0, "bots: sin bajar de 0")
remote.OnServerEvent:Fire(p1, "Bots", { Set = 10 })
check(Bots.QAFillTo == 10, "por el RemoteEvent: 5v5 (10)")
QAServer.Handle(p1, "HitTelemetry", { On = true })
check(GameConfig.HitTelemetry.Enabled == true, "telemetría de impactos encendida desde QA")
Combat.OnHitSample({ Player = p1, Weapon = "ARX27", Distance = 31, Slack = 0.4, ReportedHead = true, Headshot = true, Accepted = true })
local hits = replies("Hit")
check(#hits == 1 and hits[1].Weapon == "ARX27" and hits[1].Headshot == true and hits[1].Slack == 0.4, "cada impacto medido llega a quien disparó")
QAServer.Handle(p1, "HitTelemetry", { On = false })
check(GameConfig.HitTelemetry.Enabled == false, "telemetría apagada")
QAServer.Handle(p1, "Snapshot")
local snaps = replies("Snapshot")
check(#snaps == 1 and snaps[1].Maps == 1 and snaps[1].Players == 2, "foto: un mapa y dos jugadores")
check(#replies("Ack") >= 1, "los comandos responden")

-- Partida forzada: Coastal + Dominio, ya; después «gana B»
Round.Init()
task.wait(0.3)
check(RS:GetAttribute("State") == "Intermission", "descanso (30 s)")
QAServer.Handle(p1, "EndMatch", { Winner = 1 })
check(string.find(replies("Ack")[#replies("Ack")], "No hay partida", 1, true) ~= nil, "terminar en el descanso: avisa y no hace nada")
QAServer.Handle(p1, "NextMatch", { Map = "Coastal", Mode = "DOM", Now = true })
local deadline = os.clock() + 15
while RS:GetAttribute("State") ~= "Playing" and os.clock() < deadline do
	task.wait(0.1)
end
check(RS:GetAttribute("State") == "Playing", "«Jugar ya» corta el descanso")
check(RS:GetAttribute("MapName") == MapBuilder.Defs.Coastal.Name, "mapa pedido: " .. tostring(RS:GetAttribute("MapName")))
check(RS:GetAttribute("Mode") == "DOM", "modo pedido: " .. tostring(RS:GetAttribute("Mode")))
check(Round.QANext == nil, "la petición se gasta (la siguiente vuelve a la votación)")
task.wait(0.6) -- (despliegue)
QAServer.Handle(p1, "EndMatch", { Winner = 2 })
deadline = os.clock() + 10
while RS:GetAttribute("State") == "Playing" and os.clock() < deadline do
	task.wait(0.1)
end
check(RS:GetAttribute("State") ~= "Playing", "«Gana B» termina la partida")
local teamA, teamB = RS:GetAttribute("TeamA"), RS:GetAttribute("TeamB")
local scoreA, scoreB = RS:GetAttribute("Score_" .. teamA) or 0, RS:GetAttribute("Score_" .. teamB) or 0
check(scoreB > scoreA, string.format("gana el equipo B (%d - %d)", scoreA, scoreB))

-- Panel (cliente): solo con el modo activo; mapas iguales a los del servidor
QAPanel.Init()
local gui = pg:FindFirstChild("QAPanel")
check(gui ~= nil, "en Studio con la opción: panel creado")
local listed = {}
for _, id in QAPanel.GoldMaps do listed[id] = true end
for _, id in QAPanel.OtherMaps do listed[id] = true end
local same = #QAPanel.GoldMaps + #QAPanel.OtherMaps == #MapBuilder.Order
for _, id in MapBuilder.Order do
	same = same and listed[id] == true
end
check(same, "los mapas del panel son los del servidor")
check(QAPanel.GoldMaps[1] == "Construction" and QAPanel.GoldMaps[2] == "Coastal" and QAPanel.GoldMaps[3] == "MallRush", "primero los tres gold standard")
local function click(text)
	for _, d in gui:GetDescendants() do
		if d.ClassName == "TextButton" and d.Text == text then
			d.Activated:Fire()
			return true
		end
	end
	return false
end
-- Todo lo de depuración empieza apagado
check(ClientState.QAShotHook == nil, "disparos: apagado por defecto")
local camera = game.Workspace.CurrentCamera
check(camera:FindFirstChild("QADebug") == nil or #camera.QADebug:GetChildren() == 0, "ayudas visuales: apagadas por defecto")
-- Botones
mock.serverSent = {}
click("★ MallRush")
click("SND")
click("Jugar ya")
local sentNext = false
for _, sent in mock.serverSent do
	local args = sent.Args
	if sent.Remote == QA.RemoteName and args[1] == "NextMatch" and args[2].Map == "MallRush" and args[2].Mode == "SND" and args[2].Now == true then
		sentNext = true
	end
end
check(sentNext, "botones: MallRush + SND + «Jugar ya» manda el comando")
check(click("Spawns"), "botón de spawns")
local spawns = camera:FindFirstChild("QADebug") and camera.QADebug:FindFirstChild("QASpawns")
check(spawns ~= nil and #spawns:GetChildren() > 0, "spawns dibujados (" .. (spawns and #spawns:GetChildren() or 0) .. ")")
check(click("Objetivos A/B"), "botón de objetivos")
local objectives = camera.QADebug:FindFirstChild("QAObjectives")
check(objectives ~= nil and #objectives:GetChildren() > 0, "objetivos dibujados (" .. (objectives and #objectives:GetChildren() or 0) .. ")")
click("Spawns")
check(camera.QADebug:FindFirstChild("QASpawns") == nil, "al apagarlo, desaparecen")
click("Disparos")
check(ClientState.QAShotHook ~= nil, "disparos: encendido")
local roblox = require("@lune/roblox")
ClientState.QAShotHook(roblox.Vector3.new(0, 5, 0), { { Position = roblox.Vector3.new(0, 5, -40) } })
local shots = camera.QADebug:FindFirstChild("QAShots")
check(shots ~= nil and #shots:GetChildren() == 1 and shots:GetChildren()[1].CanQuery == false, "un disparo = una línea (que no estorba a los rayos)")
click("Disparos")
check(ClientState.QAShotHook == nil, "disparos: apagado")
click("Jugador nuevo")
local Hints = req(game.StarterPlayer.Client.Modules.Hints)
check(Hints.QAForceNew == true, "jugador nuevo simulado (consejos)")
click("Jugador nuevo")
check(Hints.QAForceNew == false, "y vuelta al nivel real")
QAPanel.OnServer("Hit", { Weapon = "ARX27", Distance = 31, Slack = 0.4, ReportedHead = true, Headshot = true, Accepted = true, PingMs = 50 })
local log = ""
for _, d in gui:GetDescendants() do
	if d.ClassName == "TextLabel" and string.find(tostring(d.Text), "Impacto ARX27", 1, true) then
		log = d.Text
	end
end
check(log ~= "", "el impacto sale en el registro del panel")
local snap = QAPanel.Snapshot()
check(snap.Maps == 1, "foto del cliente: un mapa en workspace")
print("QA OK")
process.exit(0)
