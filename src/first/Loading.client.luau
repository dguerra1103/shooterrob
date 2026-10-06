-- Pantalla de arranque (sustituye a la de Roblox). Vive en ReplicatedFirst para salir lo antes
-- posible, así que no usa los módulos del juego hasta que llegan. El progreso es real, por fases:
--   CARGANDO INTERFAZ   el juego descarga (cola de ContentProvider) y precarga los sonidos de la interfaz
--   CARGANDO ARMAS      módulos compartidos, tus datos (clases, armas) y los sonidos de las armas
--   CARGANDO MAPAS      el mapa existe y no se está construyendo (si se construye, lo dice)
--   PREPARANDO PARTIDA  el lobby está montado (PlayerGui.MainMenu con el atributo Ready)
-- Sin esperas inventadas: en cuanto todo está, se va con un fundido corto. Detrás, cuando el mapa
-- existe, se ve desenfocado; delante, unas partículas sutiles, el logo y un consejo.
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local LocalizationService = game:GetService("LocalizationService")

local TITLE = "SHOOTER NEW" -- (el mismo que GameConfig.GameTitle)
local LIMITS = { Loaded = 30, Data = 12, Map = 25, Lobby = 15 } -- (máximo por fase si algo falla)

local player = Players.LocalPlayer
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

-- Textos en el idioma del jugador (español si no hay)
local strings = require(script.Parent:WaitForChild("BootTips"))
local lang = "es"
pcall(function()
	local locale = string.lower(LocalizationService.RobloxLocaleId or "")
	local code = string.sub(locale, 1, 2)
	if strings[code] then
		lang = code
	end
end)
local TEXT = strings[lang] or strings.es

local YELLOW = Color3.fromRGB(255, 198, 26)
local BG = Color3.fromRGB(10, 11, 14)
local function font(weight, style)
	local ok, f = pcall(function()
		return Font.new("rbxasset://fonts/families/Oswald.json", weight, style or Enum.FontStyle.Normal)
	end)
	return ok and f or nil
end
local TITLE_FONT = font(Enum.FontWeight.Bold, Enum.FontStyle.Italic)
local LABEL_FONT = font(Enum.FontWeight.SemiBold)

local function new(className, props, children)
	local inst = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	inst.Parent = props.Parent
	return inst
end
local function label(props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = props.Color or Color3.new(1, 1, 1),
		TextSize = props.TextSize or 16,
		Text = props.Text or "",
		TextXAlignment = props.AlignX or Enum.TextXAlignment.Left,
		RichText = props.Rich == true,
		AnchorPoint = props.Anchor or Vector2.new(),
		Position = props.Position,
		Size = props.Size,
		ZIndex = props.ZIndex or 3,
		Parent = props.Parent,
	})
	if props.FontFace then
		l.FontFace = props.FontFace
	end
	return l
end

local gui = new("ScreenGui", { Name = "Loading", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 100 })
local background = new("Frame", { Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BG, BorderSizePixel = 0, Parent = gui }, {
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(26, 28, 34), Color3.fromRGB(6, 7, 9)),
	}),
})
-- Viñeta (bordes más oscuros) por encima del fondo: se queda aunque el fondo se aclare
new("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 1, Parent = gui }, {
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.3, 0.9),
			NumberSequenceKeypoint.new(0.7, 0.9),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
	}),
})

-- Contenido (logo, partículas, progreso)
local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = gui })

-- Partículas: motas pequeñas que suben despacio (pocas, sin texturas)
local motes = {}
for i = 1, 18 do
	local size = math.random(2, 4)
	local mote = new("Frame", {
		Name = "Mote",
		BorderSizePixel = 0,
		BackgroundColor3 = i % 4 == 0 and YELLOW or Color3.new(1, 1, 1),
		BackgroundTransparency = 0.55 + math.random() * 0.35,
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromScale(math.random(), math.random()),
		ZIndex = 2,
		Parent = content,
	})
	motes[i] = { Frame = mote, X = math.random(), Y = math.random(), Speed = 0.012 + math.random() * 0.025, Sway = math.random() * 6 }
end

-- Logo
local logo = new("Frame", { Name = "Logo", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.7, 0.22), ZIndex = 3, Parent = content })
local first, rest = string.match(TITLE, "^(%S+)%s*(.*)$")
local title = label({
	Text = string.format('%s <font color="#FFC61A">%s</font>', first or TITLE, rest or ""),
	Rich = true,
	FontFace = TITLE_FONT,
	AlignX = Enum.TextXAlignment.Center,
	Anchor = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromScale(1, 0.8),
	Parent = logo,
})
title.TextScaled = true
new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = title })
local underline = new("Frame", { BackgroundColor3 = YELLOW, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.92), Size = UDim2.new(0, 0, 0, 4), ZIndex = 3, Parent = logo })
local tag = label({ Text = "5 V 5  ·  TACTICAL", FontFace = LABEL_FONT, TextSize = 16, Color = Color3.fromRGB(160, 166, 178), AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 10), Size = UDim2.new(1, 0, 0, 20), Parent = logo })

-- Progreso
local bottom = new("Frame", { Name = "Progress", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -64), Size = UDim2.new(0.62, 0, 0, 60), ZIndex = 3, Parent = content })
local phaseLabel = label({ Text = TEXT.Phases.Interface, FontFace = LABEL_FONT, TextSize = 18, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0.75, 0, 0, 24), Parent = bottom })
local percentLabel = label({ Text = "0%", FontFace = LABEL_FONT, TextSize = 18, Color = YELLOW, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.25, 0, 0, 24), Parent = bottom })
local track = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.88, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 4), ZIndex = 3, Parent = bottom })
local fill = new("Frame", { BackgroundColor3 = YELLOW, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = track })
-- Brillo en la punta de la barra
new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 240, 170), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.new(0, 14, 2.4, 0), ZIndex = 5, Parent = fill }, {
	new("UIGradient", { Transparency = NumberSequence.new(1, 0) }),
})
local tipLabel = label({ Text = "", TextSize = 15, Color = Color3.fromRGB(200, 204, 214), AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 44), Size = UDim2.new(1, 0, 0, 20), Parent = bottom })
tipLabel.TextWrapped = true

-- Tamaños según la pantalla (móvil: todo un poco más grande en proporción)
local function fit()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local scale = math.clamp(viewport.Y / 720, 0.5, 2)
	local phone = math.min(viewport.X, viewport.Y) < 500
	bottom.Size = UDim2.new(phone and 0.86 or 0.62, 0, 0, 60 * scale)
	bottom.Position = UDim2.new(0.5, 0, 1, -(phone and 30 or 64) * scale)
	logo.Size = UDim2.fromScale(phone and 0.86 or 0.7, phone and 0.26 or 0.22)
	for _, l in { phaseLabel, percentLabel } do
		l.TextSize = math.floor(18 * scale)
	end
	tipLabel.TextSize = math.floor(15 * scale)
	tag.TextSize = math.floor(16 * scale)
end
fit()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end

gui.Parent = player:WaitForChild("PlayerGui")

-- Consejos (uno cada pocos segundos, sin repetir el anterior)
local tipIndex = math.random(1, #TEXT.Tips)
local function showTip()
	tipLabel.Text = '<font color="#FFC61A">' .. (lang == "es" and "CONSEJO" or "TIP") .. "</font>   " .. TEXT.Tips[tipIndex]
	tipLabel.RichText = true
end
showTip()

-- Animación: logo, partículas, barra suave hacia el progreso real
local shown = 0 -- (lo que se dibuja; persigue a "progress")
local progress = 0
local alive = true
TweenService:Create(underline, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { Size = UDim2.new(0.34, 0, 0, 4) }):Play()
local animation = RunService.RenderStepped:Connect(function(dt)
	shown += (progress - shown) * math.min(1, dt * 8)
	fill.Size = UDim2.fromScale(math.clamp(shown, 0, 1), 1)
	percentLabel.Text = string.format("%d%%", math.floor(math.clamp(shown, 0, 1) * 100 + 0.5))
	local t = os.clock()
	for _, m in motes do
		m.Y -= m.Speed * dt
		if m.Y < -0.02 then
			m.Y, m.X = 1.02, math.random()
		end
		m.Frame.Position = UDim2.new(m.X, math.sin(t * 0.6 + m.Sway) * 8, m.Y, 0)
	end
end)
task.spawn(function()
	while alive do
		task.wait(4.5)
		tipIndex = tipIndex % #TEXT.Tips + 1
		showTip()
	end
end)

-- Fases: cada una ocupa un tramo de la barra; dentro, avanza con lo que de verdad ha terminado
local function setPhase(text)
	phaseLabel.Text = text
end
local function segment(from, to, fraction)
	progress = math.max(progress, from + (to - from) * math.clamp(fraction, 0, 1))
end
local function preload(list, from, to)
	if #list == 0 then
		segment(from, to, 1)
		return
	end
	local done = 0
	pcall(function()
		ContentProvider:PreloadAsync(list, function()
			done += 1
			segment(from, to, done / #list)
		end)
	end)
	segment(from, to, 1)
end
local function soundIds(defs)
	local ids, seen = {}, {}
	for _, def in defs or {} do
		if type(def) == "table" and type(def.Id) == "string" and not seen[def.Id] then
			seen[def.Id] = true
			table.insert(ids, def.Id)
		end
	end
	return ids
end
-- Espera a que se cumpla algo (con un máximo); tick(fracciónDelTiempo) por si hay algo que mostrar
local function waitFor(condition, limit, tick)
	local started = os.clock()
	while not condition() and os.clock() - started < limit do
		if tick then
			tick((os.clock() - started) / limit)
		end
		task.wait(0.05)
	end
end

-- 1. Interfaz: descarga del juego y sonidos de la interfaz
setPhase(TEXT.Phases.Interface)
local queueStart = math.max(1, ContentProvider.RequestQueueSize)
waitFor(function()
	return game:IsLoaded()
end, LIMITS.Loaded, function()
	segment(0, 0.22, 1 - ContentProvider.RequestQueueSize / queueStart)
end)
local modules
pcall(function()
	local scripts = player:WaitForChild("PlayerScripts", 5)
	local client = scripts and scripts:WaitForChild("Client", 5)
	modules = client and client:WaitForChild("Modules", 5)
end)
local uiSounds = {}
pcall(function()
	local flow = modules and modules:WaitForChild("Flow", 3)
	local module = flow and flow:WaitForChild("UISound", 3)
	uiSounds = module and require(module).Defs or {}
end)
preload(soundIds(uiSounds), 0.22, 0.32)

-- 2. Armas: módulos compartidos, tus datos y los sonidos de las armas
setPhase(TEXT.Phases.Weapons)
local shared = ReplicatedStorage:WaitForChild("Shared", LIMITS.Data)
segment(0.32, 0.5, 0.25)
local clientState
pcall(function()
	local module = modules and modules:WaitForChild("ClientState", 3)
	clientState = module and require(module)
end)
waitFor(function()
	return clientState == nil or clientState.Data ~= nil
end, LIMITS.Data, function(f)
	segment(0.32, 0.5, 0.25 + f * 0.5)
end)
segment(0.32, 0.5, 1)
local weaponSounds = {}
pcall(function()
	local module = shared and shared:WaitForChild("Sounds", 3)
	weaponSounds = module and require(module) or {}
end)
preload(soundIds(weaponSounds), 0.5, 0.6)

-- 3. Mapas: el mapa existe (si el servidor lo está construyendo, se dice cuál)
setPhase(TEXT.Phases.Maps)
local blur
local function mapReady()
	local map = workspace:FindFirstChild("Map")
	return map ~= nil and ReplicatedStorage:GetAttribute("LoadingMap") == nil
end
waitFor(mapReady, LIMITS.Map, function(f)
	local building = ReplicatedStorage:GetAttribute("LoadingMap")
	if building then
		setPhase(string.format(TEXT.Phases.Building, string.upper(tostring(building))))
	end
	segment(0.6, 0.8, f)
end)
segment(0.6, 0.8, 1)
-- Con el mapa ya hecho se ve detrás, desenfocado (el lobby seguirá con el mismo desenfoque)
if mapReady() then
	blur = Lighting:FindFirstChild("FlowBlur") or new("BlurEffect", { Name = "FlowBlur", Size = 0, Parent = Lighting })
	TweenService:Create(blur, TweenInfo.new(0.5), { Size = 18 }):Play()
	TweenService:Create(background, TweenInfo.new(0.5), { BackgroundTransparency = 0.3 }):Play()
end

-- 4. Partida: el lobby (la interfaz nueva) está montado
setPhase(TEXT.Phases.Match)
local playerGui = player:WaitForChild("PlayerGui")
-- (mientras tanto, el lobby no se ve por detrás de la pantalla de arranque)
local hidden = {}
local function hideLobby()
	for _, name in { "MainMenu", "FlowBackdrop" } do
		local other = playerGui:FindFirstChild(name)
		if other and other:IsA("ScreenGui") and not hidden[other] then
			hidden[other] = other.Enabled
			other.Enabled = false
		end
	end
end
waitFor(function()
	hideLobby()
	local menu = playerGui:FindFirstChild("MainMenu")
	return menu ~= nil and menu:GetAttribute("Ready") == true
end, LIMITS.Lobby, function(f)
	segment(0.8, 1, f * 0.8)
end)
hideLobby()
progress = 1
setPhase(TEXT.Phases.Ready)

-- Fuera: fundido corto y el lobby aparece
task.wait(0.15)
for other, enabled in hidden do
	if other.Parent then
		-- (el lobby decide qué se ve: si ya no está en el menú, que siga oculto)
		other.Enabled = enabled
	end
end
local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad)
TweenService:Create(background, fade, { BackgroundTransparency = 1 }):Play()
for _, d in gui:GetDescendants() do
	if d:IsA("TextLabel") then
		TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
	elseif d:IsA("UIStroke") then
		TweenService:Create(d, fade, { Transparency = 1 }):Play()
	elseif d:IsA("Frame") and d ~= background then
		TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
	end
end
task.wait(0.42)
alive = false
animation:Disconnect()
gui:Destroy()
