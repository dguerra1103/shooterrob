-- Flujo completo de menús: lobby → buscar → partida encontrada → mapa → equipos → clase → 3-2-1 →
-- juego; también Eliminación (la cuenta atrás es la preparación) y entrar con la partida empezada
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
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", roblox.BrickColor.new("Really red")
teamB.Name, teamB.TeamColor = "Azul", roblox.BrickColor.new("Really blue")
teamA.Parent, teamB.Parent = Teams, Teams
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId, me.Team = "Yo", "Yo", 1, teamB
me.Parent = Players
table.insert(mock.players, me)
me:SetAttribute("InMenu", true)
me:SetAttribute("JoinOrder", 1)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
RS:SetAttribute("TeamA", "Rojo"); RS:SetAttribute("TeamB", "Azul"); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("Mode", "TDM"); RS:SetAttribute("ModeName", "Duelo por equipos"); RS:SetAttribute("MapName", "Construcción")
RS:SetAttribute("State", "Intermission"); RS:SetAttribute("TimeLeft", 15)

-- RenderStepped con desconexión de verdad (el del mock no desconecta)
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
local classes = {}
for i, c in GameConfig.DefaultClasses do classes[i] = table.clone(c) end
ClientState.Data = { Level = 12, XP = 300, XPPerLevel = 1000, Coins = 900, RankPoints = 120, Primary = "ARX27", Secondary = "Viper", Classes = classes, ActiveClass = 2, Challenges = { List = { { Text = "Consigue 10 bajas", Progress = 4, Goal = 10, XP = 200 } } }, StarterPackAvailable = true, WheelFree = true }

local function visible(inst)
	while inst and inst ~= pg do
		if inst.Visible == false or inst.Enabled == false then return false end
		inst = inst.Parent
	end
	return true
end
-- Textos que se ven ahora mismo
local function texts()
	local t = {}
	for _, d in pg:GetDescendants() do
		if (d.__className == "TextLabel" or d.__className == "TextButton") and type(d.Text) == "string" and visible(d) then t[d.Text] = d end
	end
	return t
end
local function sent(name, value)
	for _, s in mock.serverSent do
		if s.Remote == name and (value == nil or s.Args[1] == value) then return true end
	end
	return false
end
local function waitState(flow, state, timeout)
	local t0 = os.clock()
	while flow.State ~= state and os.clock() - t0 < timeout do task.wait(0.05) end
	return flow.State == state, os.clock() - t0
end

local MainMenu = req(game.StarterPlayer.Client.Modules.MainMenu)
local ok, err = pcall(MainMenu.Init)
check(ok, "MainMenu.Init sin errores " .. tostring(err))
local Flow = MainMenu.Flow
check(Flow.State == "Home", "empieza en el lobby (" .. tostring(Flow.State) .. ")")
check(pg:FindFirstChild("MainMenu") and pg.MainMenu:GetAttribute("Ready") == true, "ScreenGui MainMenu lista (para la pantalla de arranque)")
for _, name in { "Home", "Squad", "Matchmaking", "MatchFound", "MapIntro", "TeamIntro", "Loadout", "Deploy" } do
	check(Flow.Screens[name] ~= nil, "pantalla " .. name .. " creada")
end
local t = texts()
check(t["JUGAR"] and visible(t["JUGAR"]), "botón JUGAR visible")
check(t["🎁 PACK DE INICIO"] and visible(t["🎁 PACK DE INICIO"]), "aviso del pack de inicio")
check(not (t["🎡 RULETA GRATIS"] and visible(t["🎡 RULETA GRATIS"])), "sin ruleta (estética de casino): no hay aviso de ruleta")
check(ClientState.InMainMenu == true, "HUD oculto en el lobby")

-- Armamento: categorías, arma en grande, estadísticas y editar la clase
Flow.SetState("Armory")
t = texts()
check(Flow.State == "Armory" and t["ARMAMENTO"] ~= nil, "pantalla de armamento")
for _, stat in { "DAÑO", "PRECISIÓN", "CADENCIA", "MOVILIDAD", "CONTROL" } do
	check(t[stat] ~= nil, "estadística " .. stat)
end
check(t["SUBFUSILES"] ~= nil and t["SECUNDARIAS"] ~= nil, "categorías")
local Armory = Flow.Screens.Armory
check(t["SPECTER-9"] ~= nil or t["CQB"] ~= nil, "clase activa (2: CQB) abierta para editar")
local stats = Armory.Stats(req(RS.Shared.Weapons).Get("Signal7"))
local statsSmg = Armory.Stats(req(RS.Shared.Weapons).Get("Specter9"))
check(stats.Damage > statsSmg.Damage and statsSmg.Rate > stats.Rate and statsSmg.Mobility > stats.Mobility, "estadísticas con sentido (francotirador vs subfusil)")
Armory.SelectCategory("AR")
Armory.SelectWeapon("ARX27")
t = texts()
check(t["EQUIPAR EN CLASE 2"] ~= nil, "EQUIPAR EN CLASE 2")
local action = t["EQUIPAR EN CLASE 2"]:FindFirstAncestorOfClass("TextButton")
action.Activated:Fire()
local edited = false
for _, s in mock.serverSent do
	if s.Remote == "EditClass" and s.Args[1] == 2 and s.Args[2] == "Primary" and s.Args[3] == "ARX27" then edited = true end
end
check(edited, "equipar pone el arma en la clase (EditClass)")
Armory.SelectClass(4)
check(texts()["USAR ESTA CLASE"] ~= nil, "otra clase: botón USAR ESTA CLASE")
Flow.SetState("Home")
-- Operador: roles, ficha, habilidades
Flow.SetState("Operator")
t = texts()
check(Flow.State == "Operator" and t["OPERADOR"] ~= nil and t["FRANCOTIRADOR"] ~= nil, "pantalla de operador con roles")
check(t["HABILIDADES"] ~= nil and t["IMPULSO  ·  E"] ~= nil, "habilidades con su tecla")
local Operator = Flow.Screens.Operator
Operator.SelectRole("HEAVY")
t = texts()
check(t["VOLT BRUISER"] ~= nil, "rol PESADO: Volt Bruiser")
Operator.Select("VoltBruiser")
t = texts()
local hasBuy
for text in t do if string.find(text, "COMPRAR", 1, true) then hasBuy = true end end
check(hasBuy, "traje sin comprar: precio")
local solo
for text in t do if string.find(text, "Solo estética", 1, true) then solo = true end end
check(solo, "dice que es solo estética")
Flow.SetState("Home")

-- Escuadra y vuelta
Flow.SetState("Squad")
check(Flow.State == "Squad" and texts()["INVITAR"] ~= nil, "pantalla de escuadra")
Flow.SetState("Home")

-- JUGAR: buscando (aún en el descanso)
Flow.Play()
check(Flow.State == "Matchmaking", "JUGAR → buscando partida")
check(sent("SetReady", true), "avisa al servidor de que está listo")
t = texts()
check(t["BUSCANDO PARTIDA"] and visible(t["BUSCANDO PARTIDA"]), "texto BUSCANDO PARTIDA")
task.wait(1.2)
check(Flow.State == "Matchmaking", "sigue buscando mientras dura el descanso")
-- Cancelar y volver a buscar
Flow.CancelSearch()
check(Flow.State == "Home" and sent("SetReady", false), "CANCELAR vuelve al lobby")
Flow.Play()
-- El servidor construye el mapa: partida encontrada
RS:SetAttribute("State", "LoadingMap"); RS:SetAttribute("LoadingMap", "Metro Yard")
check(Flow.State == "MatchFound", "mapa en construcción → PARTIDA ENCONTRADA")
check(texts()["PARTIDA ENCONTRADA"] ~= nil, "texto PARTIDA ENCONTRADA")
local okState, took = waitState(Flow, "MapIntro", 3)
check(okState and took > 1.1 and took < 2, string.format("pasa sola a la presentación del mapa (%.2f s)", took))
check(texts()["METRO YARD"] ~= nil, "nombre del mapa en grande")
check(texts()["CONSTRUYENDO EL MAPA…"] ~= nil, "estado real de la carga")
task.wait(0.6)
-- Mapa listo y despliegue (presentación de equipos + clase + 3-2-1, todo con los tiempos del servidor)
local now = os.clock()
RS:SetAttribute("LoadingMap", nil); RS:SetAttribute("MapName", "Metro Yard"); RS:SetAttribute("MapDescription", "Andenes y cocheras")
RS:SetAttribute("State", "Playing"); RS:SetAttribute("Frozen", true)
RS:SetAttribute("CountdownAt", now + 6); RS:SetAttribute("DeployEndsAt", now + 9)
RS:SetAttribute("Deploy", "Lineup")
okState, took = waitState(Flow, "TeamIntro", 3)
check(okState, string.format("presentación de equipos tras el mínimo del mapa (%.2f s)", took))
-- Bots del rival y de tu equipo
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
for i = 1, 4 do
	for _, team in { "Rojo", "Azul" } do
		local bot = mock.new("Model"); bot.Name = "Bot" .. team .. i; bot:SetAttribute("Team", team)
		local h = mock.new("Humanoid"); h.DisplayName = "Bot " .. team .. " " .. i; h.Parent = bot
		bot.Parent = bots
	end
end
task.wait(1)
t = texts()
check(t["TU EQUIPO"] and t["RIVALES"] and t["VS"], "TU EQUIPO · VS · RIVALES")
check(t["EQUIPO AZUL"] and t["EQUIPO ROJO"], "nombres de los equipos")
check(t["BOT ROJO 1"] ~= nil and t["YO"] ~= nil, "tarjetas con jugadores y bots")
okState = waitState(Flow, "Loadout", 4)
check(okState, "elección de clase")
t = texts()
check(t["ELIGE TU CLASE"] ~= nil, "ELIGE TU CLASE")
check(t["CQB"] ~= nil and t["PESADO"] ~= nil, "las 5 clases")
local LoadoutScreen = Flow.Screens.Loadout
LoadoutScreen.Select(4)
check(sent("SelectClass", 4), "elegir la clase 4 la equipa en el servidor")
-- Personaje listo para la cuenta atrás
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100; hum.Parent = char
for _, n in { "HumanoidRootPart", "Head" } do
	local part = mock.new("Part"); part.Name = n; part.Position = roblox.Vector3.new(0, 3, 0); part.Parent = char
end
char.Parent = game.Workspace
me.Character = char
while os.clock() < now + 6 do task.wait(0.05) end
RS:SetAttribute("Deploy", "Countdown")
check(Flow.State == "Deploy", "cuenta atrás del servidor")
task.wait(0.3)
t = texts()
check(t["PREPÁRATE"] ~= nil, "PREPÁRATE")
local seen = {}
local t0 = os.clock()
while Flow.State == "Deploy" and os.clock() - t0 < 5 do
	for text in texts() do
		if text == "3" or text == "2" or text == "1" or text == "¡YA!" then seen[text] = true end
	end
	task.wait(0.05)
end
check(seen["2"] and seen["1"], "3 · 2 · 1")
check(Flow.State == "Gameplay", "entra a jugar al acabar")
local late = os.clock() - (now + 9)
check(math.abs(late) < 0.5, string.format("a la vez que el servidor (%.2f s de diferencia)", late))
check(ClientState.InMainMenu == false, "vuelve el HUD")
check(sent("LeaveMenu"), "sale del escudo del menú")
me:SetAttribute("InMenu", false)
RS:SetAttribute("Deploy", nil); RS:SetAttribute("Frozen", false)

-- Ronda siguiente de Eliminación para quien ya jugaba: mapa → equipos → preparación de la ronda
RS:SetAttribute("State", "Ended")
task.wait(0.2)
check(Flow.State == "Gameplay", "el final de la partida no cambia de pantalla")
RS:SetAttribute("State", "LoadingMap"); RS:SetAttribute("LoadingMap", "Dockyard")
check(Flow.State == "MapIntro", "ronda nueva: presentación del mapa")
task.wait(0.3)
now = os.clock()
RS:SetAttribute("LoadingMap", nil); RS:SetAttribute("MapName", "Dockyard"); RS:SetAttribute("Mode", "ELIM"); RS:SetAttribute("ModeName", "Eliminación")
RS:SetAttribute("State", "Playing"); RS:SetAttribute("Frozen", true)
RS:SetAttribute("CountdownAt", now + 6); RS:SetAttribute("DeployEndsAt", now + 6)
RS:SetAttribute("Deploy", "Lineup")
okState = waitState(Flow, "TeamIntro", 3)
check(okState, "Eliminación: presentación de equipos")
while os.clock() < now + 6 do task.wait(0.05) end
-- (fin de la presentación: el servidor quita Deploy y empieza la preparación de la primera ronda)
RS:SetAttribute("Deploy", nil); RS:SetAttribute("Frozen", false)
RS:SetAttribute("Frozen", true); RS:SetAttribute("TimeLeft", 4)
check(Flow.State == "Deploy", "Eliminación: la preparación es la cuenta atrás (" .. Flow.State .. ")")
for left = 3, 0, -1 do
	task.wait(1)
	RS:SetAttribute("TimeLeft", left)
	check(Flow.State == "Deploy", "sigue en la cuenta atrás (" .. left .. ") " .. Flow.State)
end
task.wait(0.4)
okState = waitState(Flow, "Gameplay", 2)
check(okState, "Eliminación: al llegar a 0 se juega")
RS:SetAttribute("Frozen", false)

-- Desde la pantalla de muerte, al lobby; y entrar con la partida ya empezada
Flow.ReturnToLobby()
check(Flow.State == "Home" and sent("EnterMenu"), "volver al lobby")
RS:SetAttribute("Mode", "TDM"); RS:SetAttribute("ModeName", "Duelo por equipos")
Flow.Play()
okState, took = waitState(Flow, "MatchFound", 3)
check(okState and took > 0.7, string.format("con partida en marcha: encontrada enseguida (%.2f s)", took))
okState = waitState(Flow, "MapIntro", 3)
check(okState, "presentación del mapa (tarde)")
okState = waitState(Flow, "TeamIntro", 4)
check(okState, "equipos (tarde)")
okState = waitState(Flow, "Loadout", 5)
check(okState, "clase (tarde)")
okState, took = waitState(Flow, "Deploy", 7)
check(okState and took > 4, string.format("clase con su tiempo (%.1f s)", took))
okState, took = waitState(Flow, "Gameplay", 5)
check(okState and took > 2.5, string.format("cuenta atrás propia (%.1f s)", took))

-- Sin personaje: SINCRONIZANDO PARTIDA…
Flow.ReturnToLobby()
me.Character = nil
Flow.SetState("Deploy", { Late = true })
task.wait(0.3)
t = texts()
check(t["SINCRONIZANDO PARTIDA…"] and visible(t["SINCRONIZANDO PARTIDA…"]), "sin personaje: SINCRONIZANDO PARTIDA…")
me.Character = char
okState = waitState(Flow, "Gameplay", 5)
check(okState, "en cuanto llega el personaje, cuenta atrás y a jugar")

check(#errors == 0, "sin errores por fotograma " .. (errors[1] or ""))
print("FLUJO OK")
process.exit(0)
