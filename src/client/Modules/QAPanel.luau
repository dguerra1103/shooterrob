-- Modo QA (Fase 8): panel de pruebas para Roblox Studio. Solo se crea si Shared/QA dice que está activo
-- (GameConfig.QA.Enabled Y RunService:IsStudio()) y el servidor ha creado su RemoteEvent. Fuera de eso
-- Init no hace nada. Es una herramienta, no interfaz final: gris, sin animaciones.
--
-- F8, \ (barra invertida) o el botón «QA» (arriba a la izquierda) lo abren y cierran. Con el panel abierto el ratón queda
-- libre. Todo lo de depuración empieza apagado. Ver FASE_08_VALIDACION_STUDIO.md.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Weapons = require(Shared.Weapons)
local QA = require(Shared.QA)
local WeaponVisual = require(Shared.WeaponVisual)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local QAPanel = {}

-- Mapas: primero los tres «gold standard» (Fase 3), después el resto (los ids del servidor, MapBuilder)
QAPanel.GoldMaps = { "Construction", "Coastal", "MallRush" }
QAPanel.OtherMaps = { "Terminal", "RooftopDistrict", "MetroYard", "DesertBase", "Dockyard", "IndustrialYard" }

local remote = nil
local gui, panel, logLabel, statusLabel, perfLabel = nil, nil, nil, nil, nil
local logLines = {}
local selectedMap, selectedMode = "Construction", "TDM"
local mapButtons, modeButtons = {}, {}
local toggles = {} -- [nombre] = true/false
local weaponIndex = 1
local snapshots = 0
local debugFolder = nil
local shotParts = {}
local safeGuis = {}
local perfConnection = nil

local GREY = Color3.fromRGB(58, 60, 66)
local DARK = Color3.fromRGB(26, 27, 30)
local ON = Color3.fromRGB(46, 120, 70)
local PICK = Color3.fromRGB(150, 120, 30)

---------------------------------------------------------------------------
-- Registro (abajo del panel y en Output)
---------------------------------------------------------------------------

function QAPanel.Log(text)
	text = tostring(text)
	print("[QA] " .. text)
	table.insert(logLines, text)
	while #logLines > 9 do
		table.remove(logLines, 1)
	end
	if logLabel then
		logLabel.Text = table.concat(logLines, "\n")
	end
end

local function send(command, args)
	if remote then
		remote:FireServer(command, args or {})
	end
end
QAPanel.Send = send

---------------------------------------------------------------------------
-- Ayudas visuales (solo en este cliente: van dentro de la cámara, no se replican)
---------------------------------------------------------------------------

local function ensureDebugFolder()
	local camera = workspace.CurrentCamera
	if not debugFolder or not debugFolder.Parent then
		debugFolder = Instance.new("Folder")
		debugFolder.Name = "QADebug"
		debugFolder.Parent = camera
	end
	return debugFolder
end

local function label(part, text, color)
	local board = Instance.new("BillboardGui")
	board.Name = "QALabel"
	board.Adornee = part
	board.AlwaysOnTop = true
	board.Size = UDim2.fromOffset(150, 22)
	board.StudsOffset = Vector3.new(0, 3, 0)
	board.MaxDistance = 400
	local text_ = Instance.new("TextLabel")
	text_.Size = UDim2.fromScale(1, 1)
	text_.BackgroundTransparency = 0.35
	text_.BackgroundColor3 = DARK
	text_.TextColor3 = color
	text_.TextSize = 14
	text_.Font = Enum.Font.GothamBold
	text_.Text = text
	text_.Parent = board
	return board
end

local function box(part, color, transparency, onTop)
	local adorn = Instance.new("BoxHandleAdornment")
	adorn.Name = "QABox"
	adorn.Adornee = part
	adorn.Size = part.Size
	adorn.Color3 = color
	adorn.Transparency = transparency
	adorn.AlwaysOnTop = onTop
	adorn.ZIndex = 1
	return adorn
end

-- Qué se dibuja de cada categoría: lista de { pieza, texto, color, transparencia, encima }
local CATEGORIES = {
	Spawns = function(map)
		local list = {}
		for _, d in map:GetDescendants() do
			if d:IsA("SpawnLocation") then
				local team = d.TeamColor and d.TeamColor.Name or ""
				table.insert(list, { d, "SPAWN " .. team, d.TeamColor and d.TeamColor.Color or Color3.new(1, 1, 1), 0.4, true })
			elseif d:IsA("BasePart") and d.Name == "FFASpawn" then
				table.insert(list, { d, "SPAWN FFA", Color3.fromRGB(220, 220, 220), 0.4, true })
			end
		end
		return list
	end,
	Objectives = function(map)
		local list = {}
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "BombSite" then
					table.insert(list, { d, "SITIO " .. tostring(d:GetAttribute("Letter") or "?"), Color3.fromRGB(255, 150, 40), 0.5, true })
				elseif d.Name == "FlagBase" then
					table.insert(list, { d, "BANDERA " .. tostring(d:GetAttribute("Team") or "?"), Color3.fromRGB(255, 230, 80), 0.5, true })
				elseif d.Name == "HardpointZone" then
					table.insert(list, { d, "ZONA", Color3.fromRGB(120, 200, 255), 0.6, true })
				end
			end
		end
		return list
	end,
	Bounds = function(map)
		local list = {}
		local boundary = map:FindFirstChild("Boundary")
		if boundary then
			for _, d in boundary:GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(list, { d, nil, Color3.fromRGB(255, 60, 60), 0.75, false })
				end
			end
		end
		return list
	end,
	BotSpots = function(map)
		local list = {}
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "BotSpot" then
				table.insert(list, { d, "BOT", Color3.fromRGB(80, 220, 255), 0.2, true })
			end
		end
		return list
	end,
}
QAPanel.Categories = CATEGORIES

-- Rehace las ayudas visuales encendidas (al cambiar de mapa o de interruptor)
function QAPanel.RefreshDebug()
	local folder = ensureDebugFolder()
	for _, child in folder:GetChildren() do
		if child.Name ~= "QAShots" then
			child:Destroy()
		end
	end
	local map = workspace:FindFirstChild("Map")
	if not map then
		return 0
	end
	local count = 0
	for name, collect in CATEGORIES do
		if toggles[name] then
			local group = Instance.new("Folder")
			group.Name = "QA" .. name
			for _, entry in collect(map) do
				local adorn = box(entry[1], entry[3], entry[4], entry[5])
				adorn.Parent = group
				if entry[2] then
					label(entry[1], entry[2], entry[3]).Parent = group
				end
				count += 1
			end
			group.Parent = folder
		end
	end
	return count
end

-- Disparos: una línea por bala (verde si dio a alguien, blanca si no) durante 2 s
local function drawShot(origin, rays)
	local folder = ensureDebugFolder()
	local shots = folder:FindFirstChild("QAShots")
	if not shots then
		shots = Instance.new("Folder")
		shots.Name = "QAShots"
		shots.Parent = folder
	end
	for _, ray in rays do
		if type(ray) == "table" and typeof(ray.Position) == "Vector3" then
			local hitModel = if typeof(ray.Part) == "Instance" then ray.Part:FindFirstAncestorOfClass("Model") else nil
			local hitSomeone = hitModel ~= nil and hitModel:FindFirstChildOfClass("Humanoid") ~= nil
			local length = (ray.Position - origin).Magnitude
			if length > 0.05 then
				local line = Instance.new("Part")
				line.Name = "QAShot"
				line.Anchored = true
				line.CanCollide = false
				line.CanQuery = false -- (que no estorbe a los rayos del juego)
				line.CanTouch = false
				line.CastShadow = false
				line.Material = Enum.Material.Neon
				line.Color = hitSomeone and Color3.fromRGB(60, 255, 120) or Color3.fromRGB(240, 240, 240)
				line.Transparency = 0.3
				line.Size = Vector3.new(0.06, 0.06, length)
				line.CFrame = CFrame.lookAt(origin, ray.Position) * CFrame.new(0, 0, -length / 2)
				line.Parent = shots
				table.insert(shotParts, line)
				task.delay(2, function()
					line:Destroy()
				end)
			end
		end
	end
	-- (tope: en una ráfaga larga no se acumulan cientos)
	while #shotParts > 80 do
		local old = table.remove(shotParts, 1)
		if old then
			old:Destroy()
		end
	end
end
QAPanel.DrawShot = drawShot

-- Zona segura: el rectángulo útil del dispositivo (muesca, barra de inicio) en verde y el que deja
-- libre la barra de Roblox en amarillo. Lo que quede fuera del verde puede quedar tapado.
local function setSafeArea(on)
	for _, existing in safeGuis do
		existing:Destroy()
	end
	table.clear(safeGuis)
	if not on then
		return
	end
	for _, spec in { { "DeviceSafeInsets", Color3.fromRGB(60, 255, 120), "zona segura del dispositivo" }, { "CoreUISafeInsets", Color3.fromRGB(255, 220, 60), "libre de la barra de Roblox" } } do
		local screen = Instance.new("ScreenGui")
		screen.Name = "QASafeArea_" .. spec[1]
		screen.ResetOnSpawn = false
		screen.DisplayOrder = 60
		local ok = pcall(function()
			screen.ScreenInsets = Enum.ScreenInsets[spec[1]]
		end)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundTransparency = 1
		frame.Parent = screen
		local stroke = Instance.new("UIStroke")
		stroke.Color = spec[2]
		stroke.Thickness = 2
		stroke.Parent = frame
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Position = spec[1] == "DeviceSafeInsets" and UDim2.new(0, 6, 1, -20) or UDim2.new(0, 6, 0, 2)
		text.Size = UDim2.fromOffset(260, 18)
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextColor3 = spec[2]
		text.TextSize = 12
		text.Font = Enum.Font.GothamBold
		text.Text = ok and spec[3] or (spec[3] .. " (ScreenInsets no disponible)")
		text.Parent = frame
		screen.Parent = player:WaitForChild("PlayerGui")
		table.insert(safeGuis, screen)
	end
end

---------------------------------------------------------------------------
-- Rendimiento (solo lo que Roblox da de verdad)
---------------------------------------------------------------------------

local function memoryMb()
	local ok, value = pcall(function()
		return game:GetService("Stats"):GetTotalMemoryUsageMb()
	end)
	return ok and type(value) == "number" and value or nil
end

local function pingMs()
	local ok, value = pcall(function()
		return player:GetNetworkPing()
	end)
	return ok and type(value) == "number" and value * 1000 or nil
end

local function countBots()
	local folder = workspace:FindFirstChild("Bots")
	return folder and #folder:GetChildren() or 0
end

local function countMapParts()
	local map = workspace:FindFirstChild("Map")
	if not map then
		return 0
	end
	local parts = 0
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	return parts
end

local function countFx()
	local fx = workspace:FindFirstChild("ClientFX")
	return fx and #fx:GetDescendants() or 0
end

local function setPerf(on)
	if perfConnection then
		perfConnection:Disconnect()
		perfConnection = nil
	end
	perfLabel.Visible = on
	if not on then
		return
	end
	local frames, windowStart, mapParts, partsAt = 0, os.clock(), 0, -math.huge
	perfConnection = RunService.RenderStepped:Connect(function()
		frames += 1
		local now = os.clock()
		if now - windowStart < 0.5 then
			return
		end
		local fps = frames / (now - windowStart)
		frames, windowStart = 0, now
		-- (contar las piezas del mapa cuesta: cada 5 s)
		if now - partsAt > 5 then
			mapParts, partsAt = countMapParts(), now
		end
		local memory, ping = memoryMb(), pingMs()
		perfLabel.Text = table.concat({
			string.format("FPS ~%.0f", fps),
			"Memoria: " .. (memory and string.format("%.0f MB", memory) or "no disponible"),
			"Ping (GetNetworkPing): " .. (ping and string.format("%.0f ms", ping) or "no disponible"),
			"Mapa: " .. tostring(ReplicatedStorage:GetAttribute("MapName")) .. " · " .. tostring(ReplicatedStorage:GetAttribute("Mode")),
			"Estado: " .. tostring(ReplicatedStorage:GetAttribute("State")),
			"Calidad: " .. tostring(ClientState.EffectiveQuality),
			string.format("Jugadores %d · bots %d", #Players:GetPlayers(), countBots()),
			string.format("Piezas del mapa %d · efectos (ClientFX) %d", mapParts, countFx()),
			"Arma: " .. tostring(ClientState.CurrentDef and ClientState.CurrentDef.DisplayName or "-") .. " · " .. tostring(ClientState.WeaponAction),
		}, "\n")
	end)
end

---------------------------------------------------------------------------
-- Foto de contadores (prueba de 5 partidas): cliente aquí, servidor por el RemoteEvent
---------------------------------------------------------------------------

function QAPanel.Snapshot()
	snapshots += 1
	local pg = player:FindFirstChildOfClass("PlayerGui")
	local screens = {}
	for _, child in pg and pg:GetChildren() or {} do
		if child:IsA("ScreenGui") then
			table.insert(screens, child.Name)
		end
	end
	table.sort(screens)
	local maps = 0
	for _, child in workspace:GetChildren() do
		if child.Name == "Map" then
			maps += 1
		end
	end
	local memory = memoryMb()
	local data = {
		N = snapshots,
		Memory = memory,
		ScreenGuis = #screens,
		Maps = maps,
		Bots = countBots(),
		Fx = countFx(),
		Instances = #workspace:GetDescendants(),
	}
	QAPanel.Log(string.format(
		"Foto cliente #%d · memoria %s · ScreenGui %d · mapas %d · bots %d · ClientFX %d · instancias %d",
		data.N, memory and string.format("%.0f MB", memory) or "n/d", data.ScreenGuis, data.Maps, data.Bots, data.Fx, data.Instances
	))
	print("[QA] ScreenGui: " .. table.concat(screens, ", "))
	send("Snapshot")
	return data
end

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------

local function button(parent, text, onClick)
	local b = UI.new("TextButton", {
		BackgroundColor3 = GREY,
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true, -- (los nombres largos se encogen en vez de cortarse)
		Font = Enum.Font.Gotham,
		Text = text,
		AutoButtonColor = true,
		Parent = parent,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 8, Parent = b })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), Parent = b })
	b.Activated:Connect(function()
		onClick(b)
	end)
	return b
end

local grids = {}
local CELL_H, GAP, PER_ROW = 26, 4, 3

local function section(parent, title, order)
	UI.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 210, 60),
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		LayoutOrder = order,
		Parent = parent,
	})
	local grid = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, CELL_H),
		BackgroundTransparency = 1,
		LayoutOrder = order + 1,
		Parent = parent,
	})
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(104, CELL_H), CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	table.insert(grids, grid)
	return grid
end

-- Alto de cada rejilla según sus botones (sin depender de AutomaticSize) y del lienzo con scroll
local function fitGrids(scroll)
	local total = 0
	for _, grid in grids do
		local buttons = 0
		for _, child in grid:GetChildren() do
			if child:IsA("TextButton") then
				buttons += 1
			end
		end
		local rows = math.max(1, math.ceil(buttons / PER_ROW))
		local height = rows * CELL_H + (rows - 1) * GAP
		grid.Size = UDim2.new(1, 0, 0, height)
		total += height + 18 + 8 -- (rejilla + título + separación)
	end
	scroll.CanvasSize = UDim2.fromOffset(0, total)
end

local function paintSelection()
	for id, b in mapButtons do
		b.BackgroundColor3 = id == selectedMap and PICK or GREY
	end
	for mode, b in modeButtons do
		b.BackgroundColor3 = mode == selectedMode and PICK or GREY
	end
end

local function toggle(grid, name, text, apply)
	toggles[name] = false
	button(grid, text, function(b)
		toggles[name] = not toggles[name]
		b.BackgroundColor3 = toggles[name] and ON or GREY
		apply(toggles[name])
	end)
end

local function build()
	gui = UI.new("ScreenGui", {
		Name = "QAPanel",
		ResetOnSpawn = false,
		DisplayOrder = 50,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local open = UI.new("TextButton", {
		Name = "QAToggle",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(44, 26),
		BackgroundColor3 = Color3.fromRGB(150, 40, 40),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Text = "QA",
		Parent = gui,
	})
	panel = UI.new("Frame", {
		Name = "Panel",
		Position = UDim2.fromOffset(8, 40),
		Size = UDim2.new(0, 352, 1, -52),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	})
	-- (botón Modal invisible: con el panel abierto el ratón queda libre en primera persona)
	UI.new("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Parent = panel })
	statusLabel = UI.new("TextLabel", {
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.new(1, -16, 0, 40),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = "MODO QA (solo Studio)",
		Parent = panel,
	})
	-- (pantallas bajas, como un móvil apaisado: registro más corto para que quepan los botones)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize
	local height = if typeof(viewport) == "Vector2" and viewport.Y > 1 then viewport.Y else 720
	local compact = height < 500
	local logHeight = compact and 52 or 126
	local scroll = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 48),
		Size = UDim2.new(1, -16, 1, -(48 + logHeight + 12)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	logLabel = UI.new("TextLabel", {
		Position = UDim2.new(0, 8, 1, -(logHeight + 6)),
		Size = UDim2.new(1, -16, 0, logHeight),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		BorderSizePixel = 0,
		TextColor3 = Color3.fromRGB(200, 230, 200),
		TextSize = 11,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextWrapped = true,
		Text = "",
		Parent = panel,
	})

	-- Partida
	local maps = section(scroll, "MAPA (★ = gold standard)", 1)
	for _, id in QAPanel.GoldMaps do
		mapButtons[id] = button(maps, "★ " .. id, function()
			selectedMap = id
			paintSelection()
		end)
	end
	for _, id in QAPanel.OtherMaps do
		mapButtons[id] = button(maps, id, function()
			selectedMap = id
			paintSelection()
		end)
	end
	local modes = section(scroll, "MODO", 3)
	for _, mode in GameConfig.Modes do
		modeButtons[mode] = button(modes, mode, function()
			selectedMode = mode
			paintSelection()
		end)
	end
	local match = section(scroll, "PARTIDA", 5)
	button(match, "Jugar ya", function()
		send("NextMatch", { Map = selectedMap, Mode = selectedMode, Now = true })
	end)
	button(match, "Al acabar", function()
		send("NextMatch", { Map = selectedMap, Mode = selectedMode, Now = false })
	end)
	button(match, "Empezar votado", function()
		send("StartNow")
	end)
	button(match, "Gana A", function()
		send("EndMatch", { Winner = 1 })
	end)
	button(match, "Gana B", function()
		send("EndMatch", { Winner = 2 })
	end)
	button(match, "Terminar", function()
		send("EndMatch", {})
	end)

	-- Jugador y armas
	local me = section(scroll, "JUGADOR", 7)
	button(me, "Reaparecer", function()
		send("Respawn")
	end)
	button(me, "ARX-27", function()
		send("Weapon", { Id = "ARX27" })
	end)
	local primaries = Weapons.Primaries or { "ARX27" }
	button(me, "Arma ▶", function(b)
		weaponIndex = weaponIndex % #primaries + 1
		local id = primaries[weaponIndex]
		local def = Weapons.Get(id)
		b.Text = (def and def.DisplayName or id) .. " ▶"
		send("Weapon", { Id = id })
	end)
	button(me, "Munición", function()
		send("Ammo")
	end)
	-- ARX-27 «gold standard» (Fase 9): el arma de referencia con su skin de muestra, SOLO en esta
	-- pantalla (no da la skin ni cambia nada guardado). Apagado: vuelve tu skin.
	toggle(me, "Gold", "ARX-27 Gold", function(on)
		ClientState.QASkinPreview = on and WeaponVisual.GoldSkin or nil
		send("Weapon", { Id = WeaponVisual.ReferenceWeapon })
		QAPanel.Log(on and ("ARX-27 con la skin de muestra " .. WeaponVisual.GoldSkin .. " (solo en tu pantalla)") or "ARX-27 con tu skin")
	end)

	-- Bots
	local bots = section(scroll, "BOTS (total jugadores + bots)", 9)
	button(bots, "+1 bot", function()
		send("Bots", { Delta = 1 })
	end)
	button(bots, "-1 bot", function()
		send("Bots", { Delta = -1 })
	end)
	button(bots, "5v5 (10)", function()
		send("Bots", { Set = 10 })
	end)
	button(bots, "Sin bots", function()
		send("Bots", { Set = 0 })
	end)

	-- Gráficos y rendimiento
	local gfx = section(scroll, "GRÁFICOS Y RENDIMIENTO", 11)
	button(gfx, "Calidad ▶", function(b)
		local okSettings, Settings = pcall(require, script.Parent.Settings)
		if not okSettings then
			QAPanel.Log("Settings no disponible")
			return
		end
		local levels = GameConfig.QualityLevels
		local currentLevel = Settings.Get().Quality
		local nextLevel = levels[(table.find(levels, currentLevel) or 0) % #levels + 1]
		Settings.Set("Quality", nextLevel)
		b.Text = "Calidad: " .. nextLevel
		QAPanel.Log("Calidad: " .. nextLevel .. " (aplicada: " .. tostring(ClientState.EffectiveQuality) .. ")")
	end)
	toggle(gfx, "Perf", "HUD rendimiento", setPerf)
	toggle(gfx, "Safe", "Zona segura", setSafeArea)

	-- Depuración visual
	local dbg = section(scroll, "DEPURACIÓN (apagado por defecto)", 13)
	toggle(dbg, "Spawns", "Spawns", function()
		QAPanel.RefreshDebug()
	end)
	toggle(dbg, "Objectives", "Objetivos A/B", function()
		QAPanel.RefreshDebug()
	end)
	toggle(dbg, "Bounds", "Límites", function()
		QAPanel.RefreshDebug()
	end)
	toggle(dbg, "BotSpots", "Puntos bots", function()
		QAPanel.RefreshDebug()
	end)
	toggle(dbg, "Routes", "Rutas bots", function(on)
		send("BotRoutes", { On = on })
	end)
	toggle(dbg, "Shots", "Disparos", function(on)
		ClientState.QAShotHook = on and drawShot or nil
	end)
	toggle(dbg, "Hits", "Telemetría", function(on)
		send("HitTelemetry", { On = on })
	end)

	-- Primeras partidas y prueba de 5 partidas
	local misc = section(scroll, "ONBOARDING Y PRUEBA DE 5 PARTIDAS", 15)
	toggle(misc, "NewPlayer", "Jugador nuevo", function(on)
		local okHints, Hints = pcall(require, script.Parent.Hints)
		if okHints then
			Hints.QAForceNew = on
			Hints.Reset()
		end
		QAPanel.Log(on and "Consejos como jugador de nivel 1 (sin tocar los datos)" or "Consejos: nivel real")
	end)
	button(misc, "Foto contadores", function()
		QAPanel.Snapshot()
	end)

	fitGrids(scroll)
	paintSelection()
	local function setOpen(visible)
		panel.Visible = visible
		open.BackgroundColor3 = visible and ON or Color3.fromRGB(150, 40, 40)
	end
	open.Activated:Connect(function()
		setOpen(not panel.Visible)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.KeyCode == Enum.KeyCode.F8 or input.KeyCode == Enum.KeyCode.BackSlash) then
			setOpen(not panel.Visible)
		end
	end)

	-- Rendimiento: etiqueta arriba a la derecha (apagada hasta que se pida)
	perfLabel = UI.new("TextLabel", {
		Name = "QAPerf",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 56),
		Size = UDim2.fromOffset(300, 146),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
		Visible = false,
		Parent = gui,
	})
end

local function updateStatus()
	if statusLabel then
		statusLabel.Text = string.format(
			"MODO QA (solo Studio) · %s · %s · %s\nSeleccionado: %s · %s",
			tostring(ReplicatedStorage:GetAttribute("State")),
			tostring(ReplicatedStorage:GetAttribute("MapName")),
			tostring(ReplicatedStorage:GetAttribute("Mode")),
			selectedMap,
			selectedMode
		)
	end
end

local function onServer(kind, payload)
	if kind == "Ack" or kind == "Error" then
		QAPanel.Log((kind == "Error" and "ERROR: " or "") .. tostring(payload))
	elseif kind == "Hit" and type(payload) == "table" then
		QAPanel.Log(string.format(
			"Impacto %s · %.1f st · holgura %.2f · cabeza: cliente %s / servidor %s · %s · ping %s",
			tostring(payload.Weapon),
			tonumber(payload.Distance) or 0,
			tonumber(payload.Slack) or 0,
			payload.ReportedHead and "sí" or "no",
			payload.Headshot and "sí" or "no",
			payload.Accepted and "aceptado" or "RECHAZADO",
			payload.PingMs and string.format("%.0f ms", payload.PingMs) or "n/d"
		))
	elseif kind == "Snapshot" and type(payload) == "table" then
		QAPanel.Log(string.format(
			"Foto servidor #%s · %s · %s · mapas %s · bots %s (modelos %s) · jugadores %s · instancias %s",
			tostring(payload.N), tostring(payload.Map), tostring(payload.Mode), tostring(payload.Maps),
			tostring(payload.BotAgents), tostring(payload.BotModels), tostring(payload.Players), tostring(payload.WorkspaceInstances)
		))
	end
end
QAPanel.OnServer = onServer

function QAPanel.Init()
	if not QA.IsActive() then
		return -- (producción: nada)
	end
	remote = ReplicatedStorage:WaitForChild(QA.RemoteName, 10)
	if not remote then
		warn("[QA] El servidor no ha creado el RemoteEvent del modo QA: panel desactivado")
		return
	end
	remote.OnClientEvent:Connect(onServer)
	build()
	QAPanel.Log("Modo QA activo. F8, \\ o el botón QA abren el panel.")
	-- Ayudas visuales: se rehacen con cada mapa nuevo
	ReplicatedStorage:GetAttributeChangedSignal("MapName"):Connect(function()
		task.wait(1)
		QAPanel.RefreshDebug()
	end)
	for _, attribute in { "State", "MapName", "Mode" } do
		ReplicatedStorage:GetAttributeChangedSignal(attribute):Connect(updateStatus)
	end
	updateStatus()
end

return QAPanel
