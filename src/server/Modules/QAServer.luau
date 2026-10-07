-- Modo QA (Fase 8): comandos de prueba para Roblox Studio. Solo existe si Shared/QA dice que está activo
-- (GameConfig.QA.Enabled Y RunService:IsStudio()). Fuera de eso Init no hace nada: no se crea el
-- RemoteEvent y no hay forma de mandar comandos. Además, cada comando vuelve a comprobarlo.
--
-- Comandos (cliente -> servidor, por el RemoteEvent QA.RemoteName):
--   NextMatch { Map, Mode, Now }   siguiente partida en ese mapa y modo (Now = acabar el descanso ya)
--   StartNow                       acabar el descanso ya (con lo votado)
--   EndMatch { Winner = 1|2|nil }  terminar la partida (gana el equipo A, el B, o como vaya)
--   Respawn                        reaparecer
--   Bots { Delta = n | Set = n }   más o menos bots (total de jugadores + bots, de 0 a 16)
--   Weapon { Id }                  equipar esa arma principal (con la secundaria y el cuchillo de siempre)
--   Ammo                           cargadores y reserva llenos
--   HitTelemetry { On }            medir los impactos (GameConfig.HitTelemetry) y mandar cada muestra
--   BotRoutes { On }               dibujar la ruta de cada bot (piezas sin colisión, se ven en Studio)
--   Snapshot                       contadores del servidor (para la prueba de 5 partidas)
-- Respuestas (servidor -> cliente, el mismo RemoteEvent): ("Ack", texto), ("Hit", muestra),
-- ("Snapshot", tabla), ("Error", texto).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Weapons = require(Shared.Weapons)
local QA = require(Shared.QA)

local Modules = script.Parent
local Round = require(Modules.Round)
local Bots = require(Modules.Bots)
local Combat = require(Modules.Combat)
local Loadout = require(Modules.Loadout)
local Respawn = require(Modules.Respawn)
local PlayerData = require(Modules.PlayerData)
local MapBuilder = require(Modules.MapBuilder)

local QAServer = {}

local MAX_FILL = 16
local remote = nil
local routesOn = false
local snapshots = 0

local function reply(player, kind, payload)
	if remote then
		remote:FireClient(player, kind, payload)
	end
end

local function totalBots()
	local folder = workspace:FindFirstChild("Bots")
	return folder and #folder:GetChildren() or 0
end

-- Rutas de los bots: una bolita por punto del camino que siguen (se rehace cada segundo)
local function drawRoutes()
	local folder = workspace:FindFirstChild("QABotRoutes")
	if folder then
		folder:Destroy()
	end
	if not routesOn then
		return
	end
	folder = Instance.new("Folder")
	folder.Name = "QABotRoutes"
	for _, agent in Bots.Agents do
		local waypoints = agent.Waypoints
		if type(waypoints) == "table" then
			for i, waypoint in waypoints do
				if i > 40 then
					break
				end
				local dot = Instance.new("Part")
				dot.Name = "QARoute"
				dot.Shape = Enum.PartType.Ball
				dot.Size = Vector3.new(0.6, 0.6, 0.6)
				dot.Anchored = true
				dot.CanCollide = false
				dot.CanQuery = false
				dot.CanTouch = false
				dot.Material = Enum.Material.Neon
				dot.Color = (i >= (agent.WaypointIndex or 1)) and Color3.fromRGB(80, 220, 255) or Color3.fromRGB(90, 90, 110)
				dot.Position = waypoint.Position + Vector3.new(0, 0.5, 0)
				dot.Parent = folder
			end
		end
	end
	folder.Parent = workspace
end

local function snapshot()
	snapshots += 1
	local maps = 0
	for _, child in workspace:GetChildren() do
		if child.Name == "Map" then
			maps += 1
		end
	end
	local memory = nil
	local okStats, stats = pcall(function()
		return game:GetService("Stats")
	end)
	if okStats and stats then
		local okMemory, value = pcall(function()
			return stats:GetTotalMemoryUsageMb()
		end)
		memory = okMemory and value or nil
	end
	return {
		N = snapshots,
		State = ReplicatedStorage:GetAttribute("State"),
		Map = ReplicatedStorage:GetAttribute("MapName"),
		Mode = ReplicatedStorage:GetAttribute("Mode"),
		Maps = maps,
		BotAgents = #Bots.Agents,
		BotModels = totalBots(),
		Players = #Players:GetPlayers(),
		WorkspaceInstances = #workspace:GetDescendants(),
		MemoryMb = memory,
	}
end

local COMMANDS = {}

function COMMANDS.NextMatch(player, args)
	local map, mode = args.Map, args.Mode
	if type(map) ~= "string" or not MapBuilder.Defs[map] then
		reply(player, "Error", "Mapa desconocido: " .. tostring(map))
		return
	end
	if not QA.IsMode(mode) then
		reply(player, "Error", "Modo desconocido: " .. tostring(mode))
		return
	end
	Round.QANext = { Map = map, Mode = mode }
	local now = args.Now == true and Round.QAStartNow()
	reply(player, "Ack", "Siguiente partida: " .. map .. " · " .. mode .. (now and " (empieza ya)" or " (al acabar la actual)"))
end

function COMMANDS.StartNow(player)
	reply(player, "Ack", Round.QAStartNow() and "El descanso termina ya" or "No hay descanso en curso")
end

function COMMANDS.EndMatch(player, args)
	local winner = args.Winner
	if winner ~= nil and winner ~= 1 and winner ~= 2 then
		reply(player, "Error", "Ganador no válido")
		return
	end
	local ok = Round.QAEnd(winner)
	reply(player, "Ack", ok and ("Partida terminada" .. (winner and (" · gana el equipo " .. (winner == 1 and "A" or "B")) or "")) or "No hay partida en juego")
end

function COMMANDS.Respawn(player)
	task.spawn(Respawn.Load, player)
	reply(player, "Ack", "Reapareciendo")
end

function COMMANDS.Bots(player, args)
	local current = Bots.QAFillTo or GameConfig.Bots.FillTo
	local target
	if args.Set ~= nil then
		target = tonumber(args.Set)
	else
		local delta = tonumber(args.Delta)
		target = delta and current + delta
	end
	if not target or target ~= target then
		reply(player, "Error", "Cantidad no válida")
		return
	end
	Bots.QAFillTo = math.clamp(math.floor(target), 0, MAX_FILL)
	reply(player, "Ack", string.format("Jugadores + bots: %d (ahora %d bots; tardan ~1 s en entrar o salir)", Bots.QAFillTo, totalBots()))
end

function COMMANDS.Weapon(player, args)
	local id = args.Id
	local def = type(id) == "string" and Weapons.Get(id)
	if not def or def.Type ~= "Gun" then
		reply(player, "Error", "Arma desconocida: " .. tostring(id))
		return
	end
	local list = Loadout.DefaultList(PlayerData.Get(player))
	list[1] = id
	Loadout.Give(player, list)
	reply(player, "Ack", "Equipada: " .. (def.DisplayName or id))
end

function COMMANDS.Ammo(player)
	local count = 0
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, tool in container:GetChildren() do
				local def = tool:IsA("Tool") and Weapons.Get(tool:GetAttribute("Weapon") or "")
				if def and def.MagSize then
					tool:SetAttribute("Ammo", def.MagSize)
					tool:SetAttribute("Reserve", def.ReserveAmmo)
					count += 1
				end
			end
		end
	end
	reply(player, "Ack", "Munición llena (" .. count .. " armas)")
end

function COMMANDS.HitTelemetry(player, args)
	GameConfig.HitTelemetry.Enabled = args.On == true
	reply(player, "Ack", "Telemetría de impactos: " .. (GameConfig.HitTelemetry.Enabled and "ENCENDIDA" or "apagada"))
end

function COMMANDS.BotRoutes(player, args)
	routesOn = args.On == true
	drawRoutes()
	reply(player, "Ack", "Rutas de bots: " .. (routesOn and "visibles" or "ocultas"))
end

function COMMANDS.Snapshot(player)
	local data = snapshot()
	print(string.format(
		"[QA] Foto servidor #%d · estado %s · %s · %s · mapas en workspace %d · bots %d (modelos %d) · jugadores %d · instancias %d · memoria %s",
		data.N, tostring(data.State), tostring(data.Map), tostring(data.Mode), data.Maps, data.BotAgents, data.BotModels,
		data.Players, data.WorkspaceInstances, data.MemoryMb and string.format("%.0f MB", data.MemoryMb) or "no disponible"
	))
	reply(player, "Snapshot", data)
end

-- Ejecuta un comando (también lo usan las pruebas). Devuelve false si se rechaza.
function QAServer.Handle(player, command, args)
	-- (doble cerrojo: aunque el RemoteEvent existiera, fuera de Studio o con QA apagado no se hace nada)
	if not QA.IsActive() then
		warn("[QA] Comando rechazado (el modo QA no está activo):", tostring(command))
		return false
	end
	local handler = type(command) == "string" and COMMANDS[command]
	if not handler then
		return false
	end
	local ok, err = pcall(handler, player, type(args) == "table" and args or {})
	if not ok then
		warn("[QA] " .. command .. ":", err)
		reply(player, "Error", command .. ": " .. tostring(err))
	end
	return ok
end

function QAServer.Init()
	if not QA.IsActive() then
		return -- (producción: nada)
	end
	warn("[QA] MODO QA ACTIVO (solo Studio). Abre el panel con F8, \\ o el botón QA.")
	remote = Instance.new("RemoteEvent")
	remote.Name = QA.RemoteName
	remote.Parent = ReplicatedStorage
	remote.OnServerEvent:Connect(QAServer.Handle)
	-- Cada impacto medido, a quien disparó (con su latencia aproximada según Roblox)
	Combat.OnHitSample = function(sample)
		local player = sample.Player
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return
		end
		local okPing, ping = pcall(function()
			return player:GetNetworkPing()
		end)
		reply(player, "Hit", {
			Weapon = sample.Weapon,
			Distance = sample.Distance,
			Slack = sample.Slack,
			ReportedHead = sample.ReportedHead,
			Headshot = sample.Headshot,
			Accepted = sample.Accepted,
			PingMs = okPing and type(ping) == "number" and ping * 1000 or nil,
		})
	end
	task.spawn(function()
		while true do
			task.wait(1)
			if routesOn then
				pcall(drawRoutes)
			end
		end
	end)
end

return QAServer
