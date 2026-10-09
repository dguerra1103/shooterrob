-- Controles táctiles del juego (Fase 12: rehechos para el móvil). Roblox (ContextActionService) solo
-- crea 7 botones y los mete en un recuadro abajo a la derecha, así que en pantallas táctiles los
-- botones son nuestros. Las teclas y el mando siguen con ContextActionService.
--
-- Uso (como ContextActionService): TouchLayout.BindAction(nombre, función, conBotón, teclas...). La
-- función recibe (nombre, estado, input). Además: SetBadge (número pequeño: granadas, cargas),
-- SetCooldown (habilidades), SetCard (tarjeta del arma), SetActive (apuntando) y SetHidden.
--
-- Disposición: shared/MobileHUD (Fase 15: clase de pantalla por su forma, escala lógica y GRUPO DE
-- COMBATE del pulgar derecho metido hacia dentro en pantallas alargadas; jerarquía: DISPARAR >
-- APUNTAR > salto y agacharse > recargar > el resto; centro y zona de cámara libres). El jugador puede
-- moverlos, cambiar su tamaño y su opacidad (Ajustes → Controles → Personalizar HUD: HUDEditor), y se
-- guarda en sus ajustes (Settings.HudLayout, validado en el servidor).
--
-- Zona segura (Fase 15): los botones van en una ScreenGui con ScreenInsets = CoreUISafeInsets (la
-- zona que da el motor sin la muesca/cámara frontal NI los botones de Roblox de arriba); nada se
-- calcula con medidas inventadas de muesca. El salto es nuestro (va en el grupo) y el de Roblox se
-- esconde.
--
-- Toques: cada botón sigue a SU dedo (InputObject) hasta que lo suelta, aunque salga del botón. El de
-- DISPARAR, por defecto, deja además girar la cámara con el mismo dedo (Settings.FireDrag): no se
-- "come" el toque, así que se puede disparar y apuntar a la vez como en los shooters de móvil.
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MobileHUD = require(Shared.MobileHUD)
local InputMode = require(Shared.InputMode)
local GameConfig = require(Shared.GameConfig)
local TouchIcons = require(script.Parent.TouchIcons)

local TouchLayout = {}
-- Disposición que se está editando (HUDEditor) y aviso cuando cambia la disposición (HUD)
TouchLayout.EditingLayout = nil :: { [string]: any }?
TouchLayout.OnRelayout = nil :: ((layout: { [string]: any }, size: Vector2) -> ())?

local player = Players.LocalPlayer
local buttons: { [string]: any } = {} -- [acción] = entrada (ver createButton)
local registered = {} -- [acción] = posición pedida por el código (solo se guarda: manda MobileHUD)
local gui
local layout: { [string]: any } = {} -- disposición resuelta (MobileHUD.Resolve)
local breakpoint = "PHONE"
local hiddenBy = {} -- [acción] = true si su módulo la esconde (sin cargas, ajuste...)
local blockedNow = false
local onlyEmotesNow = false
local fireTouches = {} -- [InputObject] = acción (disparo arrastrando)
local editing = false

local COLORS = {
	Face = Color3.fromRGB(14, 16, 22), -- grafito
	Stroke = Color3.fromRGB(235, 238, 245),
	Active = Color3.fromRGB(255, 205, 60), -- amarillo de la marca: solo para estados
	Warn = Color3.fromRGB(255, 176, 64),
	Empty = Color3.fromRGB(255, 92, 72),
	Ally = Color3.fromRGB(70, 150, 255),
}
-- Estilo (Fase 15). Opacidad del fondo grafito según la importancia (20-40 %), borde muy fino y
-- claro, icono casi opaco. DISPARAR: centro más transparente y borde más visible (no tapa al
-- enemigo y se distingue de todo lo demás). Al pulsar, el fondo sube un poco.
local FILL = { Fire = 0.2, Primary = 0.36, Action = 0.32, Utility = 0.22 }
local FILL_PRESSED = 0.16
local STROKE = { Fire = { 2.5, 0.8 }, Default = { 1.5, 0.45 }, Accent = { 2, 0.95 } } -- grosor, opacidad
local ICON_OPACITY = 0.94
local PRESS_SCALE, PRESS_TIME = 0.95, 0.08

-- (botones táctiles cuando se juega con los dedos: shared/InputMode, el mismo criterio que el HUD)
local function touchDevice()
	return InputMode.TouchUI()
end

local function settings()
	local ok, ClientState = pcall(require, script.Parent.ClientState)
	return ok and ClientState.Settings or GameConfig.DefaultSettings, ok and ClientState or nil
end

local function ensureGui()
	if gui and gui.Parent then
		return gui
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "TouchButtons"
	gui.ResetOnSpawn = false
	-- (botones interactivos: zona segura del motor SIN la interfaz de Roblox de arriba ni la muesca o
	-- la cámara frontal, Enum.ScreenInsets.CoreUISafeInsets. IgnoreGuiInset = false es lo mismo en
	-- motores que no tengan ScreenInsets)
	gui.IgnoreGuiInset = false
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	gui.DisplayOrder = 3
	gui.Parent = player:WaitForChild("PlayerGui")
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		TouchLayout.Relayout()
	end)
	return gui
end

-- Tamaño de la zona donde van los botones (la zona segura), su esquina en pantalla y el tamaño de la
-- pantalla entera (ViewportSize: la forma de la pantalla decide la clase y la escala)
local function areaSize(): (Vector2, Vector2, Vector2)
	local g = ensureGui()
	local camera = workspace.CurrentCamera
	local screen = camera and camera.ViewportSize
	if typeof(screen) ~= "Vector2" or screen.X < 50 or screen.Y < 50 then
		screen = Vector2.new(844, 390)
	end
	local size, origin = g.AbsoluteSize, g.AbsolutePosition
	if typeof(size) ~= "Vector2" or size.X < 50 or size.Y < 50 then
		size = screen
		origin = Vector2.zero
	end
	if typeof(origin) ~= "Vector2" then
		origin = Vector2.zero
	end
	return size, origin, screen
end

-- El botón de saltar de Roblox (PlayerModule/TouchJump) se esconde mientras exista el nuestro: el
-- salto va en el grupo de combate con su tamaño y su estilo. Roblox lo vuelve a enseñar a veces
-- (al reaparecer, al cambiar el humanoide): se vigila su Visible.
local robloxJumpWatched = nil
local function hideRobloxJump()
	if not buttons.Jump then
		return
	end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	local touchGui = pg and pg:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	if not (jump and jump:IsA("GuiObject")) then
		return
	end
	if jump.Visible then
		jump.Visible = false
	end
	if robloxJumpWatched ~= jump then
		robloxJumpWatched = jump
		jump:GetPropertyChangedSignal("Visible"):Connect(function()
			if jump.Visible and buttons.Jump then
				jump.Visible = false
			end
		end)
	end
end

---------------------------------------------------------------------------
-- Aspecto
---------------------------------------------------------------------------

local function tween(object, time, goal)
	local ok, t = pcall(function()
		return TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	end)
	if ok and t then
		t:Play()
	end
end

-- Pinta un control según su estado (opacidad de su papel/ajuste, apuntando, pulsado, aviso)
local function paint(entry)
	local info = layout[entry.Id]
	local opacity = info and info.Opacity or 1
	local _, ClientState = settings()
	local control = MobileHUD.ById[entry.Id]
	if not editing and control and control.Fade and ClientState and ClientState.Aiming then
		opacity *= MobileHUD.AimFade
	end
	local role = entry.Id == "Fire" and "Fire" or (control and control.Role) or "Action"
	local fill = (FILL[role] or FILL.Action) + (entry.Pressed and FILL_PRESSED or 0)
	local accent = entry.Active and COLORS.Active or (entry.Emphasis == 2 and COLORS.Empty) or (entry.Emphasis == 1 and COLORS.Warn) or nil
	local stroke = accent and STROKE.Accent or (entry.Id == "Fire" and STROKE.Fire) or STROKE.Default
	local strokeAlpha = stroke[2]
	if entry.InStrip and not editing then
		-- (en su tira: el fondo es el de la tira; el botón solo se aclara al pulsarlo y solo lleva
		-- borde si tiene un estado que enseñar)
		fill = entry.Pressed and FILL_PRESSED or 0
		strokeAlpha = accent and strokeAlpha or 0
	end
	entry.Face.BackgroundTransparency = math.clamp(1 - fill * opacity, 0, 1)
	entry.Stroke.Color = accent or COLORS.Stroke
	entry.Stroke.Thickness = stroke[1]
	entry.Stroke.Transparency = math.clamp(1 - strokeAlpha * math.max(opacity, 0.4), 0, 1)
	if entry.Ring then
		-- (DISPARAR: anillo interior fino, como una retícula)
		entry.Ring.Color = accent or COLORS.Stroke
		entry.Ring.Transparency = math.clamp(1 - 0.35 * opacity, 0, 1)
	end
	local iconAlpha = math.clamp(1 - ICON_OPACITY * math.max(opacity, 0.35), 0, 1)
	for _, piece in entry.Icon:GetDescendants() do
		if piece:IsA("Frame") then
			if piece.BackgroundTransparency < 1 then
				piece.BackgroundTransparency = iconAlpha
			end
			local pieceStroke = piece:FindFirstChildOfClass("UIStroke")
			if pieceStroke then
				pieceStroke.Transparency = iconAlpha
			end
		elseif piece:IsA("TextLabel") then
			piece.TextTransparency = iconAlpha
		end
	end
	TouchIcons.Tint(entry.Icon, accent or Color3.new(1, 1, 1))
	-- (al pulsar baja un poco; la recarga necesaria se ve algo más grande, sin parpadear ni rebotar)
	local scale = (entry.Pressed and PRESS_SCALE or 1) * (entry.Emphasis == 2 and 1.06 or 1)
	if entry.Scale.Scale ~= scale then
		tween(entry.Scale, PRESS_TIME, { Scale = scale })
	end
end

local fitCard -- (más abajo)

-- Coloca un control (posición y tamaño en píxeles de la zona segura)
local function place(entry)
	local info = layout[entry.Id]
	if not info then
		return
	end
	local hit = info.Hit
	entry.Button.Position = UDim2.fromOffset(math.floor(info.Center.X - hit.X / 2 + 0.5), math.floor(info.Center.Y - hit.Y / 2 + 0.5))
	entry.Button.Size = UDim2.fromOffset(math.floor(hit.X + 0.5), math.floor(hit.Y + 0.5))
	entry.Face.Size = UDim2.fromOffset(math.floor(info.Size.X + 0.5), math.floor(info.Size.Y + 0.5))
	local control = MobileHUD.ById[entry.Id]
	-- (esquinas según la forma: círculo, tarjeta cuadrada o tarjeta del arma)
	local shape = control and control.Shape or "Round"
	local radius = shape == "Round" and UDim.new(0.5, 0) or UDim.new(0, math.floor(math.min(info.Size.X, info.Size.Y) * (shape == "Card" and 0.3 or 0.28) + 0.5))
	entry.Corner.CornerRadius = radius
	entry.CoverCorner.CornerRadius = radius
	local iconPx = math.min(info.Size.X, info.Size.Y)
	if not entry.CardTexts and entry.IconPx ~= math.floor(iconPx) then
		entry.IconPx = math.floor(iconPx)
		-- (los trazos de los iconos dependen del tamaño: se vuelven a dibujar)
		for _, child in entry.Icon:GetChildren() do
			child:Destroy()
		end
		if control and control.Icon ~= "Card" then
			-- (mismo tamaño de icono respecto a su botón en todos: 52 %; DISPARAR algo menos, 44 %)
			local fraction = entry.Id == "Fire" and 0.44 or 0.52
			entry.Icon.Size = UDim2.fromScale(fraction, fraction)
			TouchIcons.Draw(control.Icon, entry.Icon, iconPx * fraction)
		end
	end
	if entry.CardTexts then
		fitCard(entry)
	end
	paint(entry)
end

-- Ancho en píxeles de un texto de una línea (TextService; si no responde, una estimación)
local function textWidth(text: string, size: number, font: Enum.Font): number
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(4000, 200))
	end)
	if ok and typeof(bounds) == "Vector2" then
		return bounds.X
	end
	return (utf8.len(text) or #text) * size * 0.62
end

-- Tarjeta del arma (Fase 15: muestra el ARMA A LA QUE SE CAMBIA, pequeña; la munición va aparte,
-- junto a recargar): icono de cambiar y el nombre en UNA línea; se encoge desde 13 px (× el tamaño de
-- la tarjeta) hasta 12 px y, si aun así no cabe, lo corta TextTruncate («…»)
local MIN_CARD_TEXT = 12
fitCard = function(entry)
	local info = layout[entry.Id]
	if not entry.CardTexts or not info then
		return
	end
	local scale = info.Size.Y / 32
	local swapSize = math.floor(info.Size.Y * 0.5 + 0.5)
	entry.CardIcon.Size = UDim2.fromOffset(swapSize, swapSize)
	entry.CardIcon.Position = UDim2.new(0, 10, 0.5, 0)
	if entry.CardIconPx ~= swapSize then
		entry.CardIconPx = swapSize
		for _, child in entry.CardIcon:GetChildren() do
			child:Destroy()
		end
		TouchIcons.Draw("Swap", entry.CardIcon, swapSize)
	end
	local title = entry.CardTexts.Title
	local left = 10 + swapSize + 8
	local width = info.Size.X - left - 10
	title.Position = UDim2.fromOffset(left, 0)
	title.Size = UDim2.new(0, math.max(10, width), 1, 0)
	local size = math.max(MIN_CARD_TEXT, math.floor(13 * scale + 0.5))
	while size > MIN_CARD_TEXT and title.Text ~= "" and textWidth(title.Text, size, title.Font) > width do
		size -= 1
	end
	if title.TextSize ~= size then
		title.TextSize = size
	end
end

-- Botón de un control: zona táctil (algo mayor que el dibujo) con su cara, icono, globo y recarga
local function createButton(actionName, handler)
	local control = MobileHUD.ById[actionName]
	local isCard = control and control.Shape == "Card"
	-- (DISPARAR con «arrastrar para apuntar»: la zona no se come el toque y la cámara también lo usa)
	local passThrough = actionName == "Fire" and (settings().FireDrag or 1) == 1
	local button
	if passThrough then
		button = Instance.new("Frame")
		button.Active = false
	else
		button = Instance.new("TextButton")
		button.AutoButtonColor = false
		button.Text = ""
	end
	button.Name = actionName
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.BackgroundColor3 = COLORS.Face
	face.BorderSizePixel = 0
	face.Active = false
	face.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = face
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Stroke
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = face
	local scale = Instance.new("UIScale")
	scale.Parent = face
	-- (DISPARAR: anillo interior fino; el centro queda casi transparente)
	local ring
	if actionName == "Fire" or actionName == "LeftFire" then
		local inner = Instance.new("Frame")
		inner.Name = "InnerRing"
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.Position = UDim2.fromScale(0.5, 0.5)
		inner.Size = UDim2.fromScale(0.78, 0.78)
		inner.BackgroundTransparency = 1
		inner.Parent = face
		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0.5, 0)
		innerCorner.Parent = inner
		ring = Instance.new("UIStroke")
		ring.Color = COLORS.Stroke
		ring.Thickness = 1
		ring.Parent = inner
	end
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(isCard and 1 or 0.52, isCard and 1 or 0.52)
	icon.BackgroundTransparency = 1
	icon.Parent = face
	-- Globo (cantidad: granadas, cargas) arriba a la derecha
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.86, 0.14)
	badge.Size = UDim2.fromOffset(26, 18)
	badge.BackgroundColor3 = COLORS.Face
	badge.BackgroundTransparency = 0.15
	badge.TextColor3 = Color3.new(1, 1, 1)
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 12
	badge.Text = ""
	badge.Visible = false
	badge.ZIndex = 4
	badge.Parent = face
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0.5, 0)
	badgeCorner.Parent = badge
	-- Recarga de una habilidad: velo que baja y segundos
	local cover = Instance.new("Frame")
	cover.Name = "Cooldown"
	cover.AnchorPoint = Vector2.new(0, 1)
	cover.Position = UDim2.fromScale(0, 1)
	cover.Size = UDim2.fromScale(1, 0)
	cover.BackgroundColor3 = Color3.new(0, 0, 0)
	cover.BackgroundTransparency = 0.4
	cover.BorderSizePixel = 0
	cover.ZIndex = 2
	cover.Visible = false
	cover.Parent = face
	local coverCorner = Instance.new("UICorner")
	coverCorner.CornerRadius = UDim.new(0.5, 0)
	coverCorner.Parent = cover
	local timer = Instance.new("TextLabel")
	timer.Name = "CooldownText"
	timer.BackgroundTransparency = 1
	timer.Size = UDim2.fromScale(1, 1)
	timer.Font = Enum.Font.GothamBold
	timer.TextColor3 = Color3.new(1, 1, 1)
	timer.TextSize = 14
	timer.Text = ""
	timer.ZIndex = 3
	timer.Parent = face

	local entry = {
		Id = actionName,
		Button = button,
		Face = face,
		Corner = corner,
		CoverCorner = coverCorner,
		Stroke = stroke,
		Ring = ring,
		Scale = scale,
		Icon = icon,
		Badge = badge,
		Cover = cover,
		Timer = timer,
		Handler = handler,
		Pressed = false,
		Active = false,
		Emphasis = 0,
		PassThrough = passThrough,
		Owner = nil :: InputObject?, -- el dedo que lo tiene pulsado
		OwnerConnection = nil :: RBXScriptConnection?,
		CardTexts = nil :: { [string]: TextLabel }?,
		CardIcon = nil :: Frame?,
		InStrip = false,
	}
	-- Tarjeta del arma (cambiar arma): icono de cambiar y el arma a la que se cambia, en una línea
	if isCard then
		local swap = Instance.new("Frame")
		swap.Name = "SwapIcon"
		swap.AnchorPoint = Vector2.new(0, 0.5)
		swap.BackgroundTransparency = 1
		swap.Parent = icon
		entry.CardIcon = swap
		local label = Instance.new("TextLabel")
		label.Name = "Weapon"
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(225, 228, 236)
		label.TextScaled = false
		label.TextWrapped = false
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ClipsDescendants = true
		label.Text = ""
		label.Parent = icon
		entry.CardTexts = { Title = label }
	end

	-- Un botón es de un solo dedo a la vez (entry.Owner): un segundo dedo encima no hace nada y, si el
	-- botón se suelta por otra causa (menú, muerte), el dedo viejo ya no puede soltar una pulsación nueva
	local function press(input)
		if entry.Owner then
			return
		end
		entry.Owner = input
		entry.Pressed = true
		paint(entry)
		task.spawn(entry.Handler, actionName, Enum.UserInputState.Begin, input)
		local connection
		connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			local state = input.UserInputState
			if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				connection:Disconnect()
				if entry.Owner ~= input then
					return
				end
				entry.Owner = nil
				entry.OwnerConnection = nil
				entry.Pressed = false
				paint(entry)
				task.spawn(entry.Handler, actionName, state, input)
			end
		end)
		entry.OwnerConnection = connection
	end
	entry.Press = press
	if not passThrough then
		-- (cada toque es su dedo: se sigue hasta que lo suelta aunque salga del botón)
		button.InputBegan:Connect(function(input)
			if editing then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			press(input)
		end)
	end
	button.Parent = ensureGui()
	buttons[actionName] = entry
	place(entry)
	-- (que respete enseguida si hay un menú abierto o la pantalla de inicio)
	task.defer(TouchLayout.RefreshVisibility)
	return button
end

---------------------------------------------------------------------------
-- Disposición
---------------------------------------------------------------------------

local drawDebug -- (depuración, más abajo)
local wanted: (string, boolean?) -> boolean -- (visibilidad, más abajo)
TouchLayout.LastCollisions = {} :: { any }
local areaOrigin = Vector2.zero
local stripBacks: { [string]: Frame } = {}

-- Tiras (Fase 17): los controles de poco uso (menú, marcador, emotes, grafiti) y las habilidades
-- (impulso, supersalto, poción) van como UNA pieza: un solo fondo grafito detrás y, encima, solo los
-- iconos (sin un círculo con borde por botón). Si el jugador los separó en el editor, cada uno vuelve
-- a llevar su propio fondo. Pulsado, apuntando, en recarga o con aviso se sigue viendo en cada botón.
local STRIPS = {
	-- (Gap: hueco máximo entre dos vecinos para ir juntos, en fracción de su tamaño: la escala de la
	-- pantalla no lo cambia)
	Utility = { Gap = 0.55, Pad = 4, Round = true },
	Abilities = { Ids = { AbilityDash = true, AbilityJump = true, AbilityPotion = true }, Gap = 0.55, Pad = 3, Round = false },
}

local function stripOf(id: string): string?
	local control = MobileHUD.ById[id]
	if control and control.Role == "Utility" then
		return "Utility"
	end
	if STRIPS.Abilities.Ids[id] then
		return "Abilities"
	end
	return nil
end

local function placeStrip()
	for name, def in STRIPS do
		local ids = {}
		for id, entry in buttons do
			if stripOf(id) == name and entry.Button.Visible and layout[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return layout[a].Center.X < layout[b].Center.X
		end)
		-- (la tira es la fila seguida más larga: si el jugador saca uno, los demás siguen juntos)
		local run, best = {}, {}
		for i, id in ids do
			local prev = ids[i - 1]
			if prev then
				local a, b = layout[prev], layout[id]
				local gap = (b.Center.X - a.Center.X) - (a.Size.X + b.Size.X) / 2
				if math.abs(a.Center.Y - b.Center.Y) > 2 or gap > def.Gap * math.min(a.Size.X, b.Size.X) then
					run = {}
				end
			end
			table.insert(run, id)
			if #run > #best then
				best = table.clone(run)
			end
		end
		local together = #best >= 2 and not editing
		ids = best
		-- (los botones de la tira se pintan sin fondo propio; los que no, con el suyo)
		for id, entry in buttons do
			if stripOf(id) == name then
				local inStrip = together and table.find(ids, id) ~= nil
				if entry.InStrip ~= inStrip then
					entry.InStrip = inStrip
					paint(entry)
				end
			end
		end
		local back = stripBacks[name]
		if not together then
			if back then
				back.Visible = false
			end
			continue
		end
		if not back then
			local frame = Instance.new("Frame")
			frame.Name = name .. "Strip"
			frame.BackgroundColor3 = COLORS.Face
			frame.BorderSizePixel = 0
			frame.Active = false
			frame.ZIndex = 0
			local frameCorner = Instance.new("UICorner")
			frameCorner.Parent = frame
			local frameStroke = Instance.new("UIStroke")
			frameStroke.Color = COLORS.Stroke
			frameStroke.Thickness = 1
			frameStroke.Transparency = 0.8
			frameStroke.Parent = frame
			frame.Parent = gui
			stripBacks[name] = frame
			back = frame
		end
		local first, last = layout[ids[1]], layout[ids[#ids]]
		local pad = def.Pad
		local x0 = first.Center.X - first.Size.X / 2 - pad
		local x1 = last.Center.X + last.Size.X / 2 + pad
		local h = first.Size.Y + pad * 2
		local strip = back :: Frame
		strip.Position = UDim2.fromOffset(math.floor(x0), math.floor(first.Center.Y - h / 2))
		strip.Size = UDim2.fromOffset(math.floor(x1 - x0), math.floor(h))
		local corner = strip:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = def.Round and UDim.new(0.5, 0) or UDim.new(0, math.floor(h * 0.28 + 0.5))
		end
		local _, ClientState = settings()
		strip.BackgroundTransparency = (ClientState and ClientState.Aiming) and 0.86 or 0.7
		local stroke = strip:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = (ClientState and ClientState.Aiming) and 0.92 or 0.8
		end
		strip.Visible = true
	end
end

-- Vuelve a colocar todo (pantalla girada, cambio de zona segura, disposición del jugador cambiada)
function TouchLayout.Relayout()
	if not gui then
		return
	end
	local size, origin, screen = areaSize()
	areaOrigin = origin
	breakpoint = MobileHUD.Classify(size, touchDevice(), screen)
	local s = settings()
	layout = MobileHUD.Resolve(size, {
		Breakpoint = breakpoint ~= "DESKTOP" and breakpoint or nil,
		Screen = screen,
		Custom = editing and TouchLayout.EditingLayout or s.HudLayout,
	})
	for _, entry in buttons do
		place(entry)
	end
	placeStrip()
	hideRobloxJump()
	-- Detector de solapes (Fase 16): en cada recolocación (giro, resolución, disposición propia,
	-- restablecer, reaparecer...) se revisan las cajas de los controles que se ven en partida
	local visible = {}
	for name in buttons do
		if layout[name] and wanted(name, true) then
			table.insert(visible, name)
		end
	end
	TouchLayout.LastCollisions = MobileHUD.Collisions(layout, visible, editing and 0 or MobileHUD.MinTouchGap)
	if #TouchLayout.LastCollisions > 0 and GameConfig.MobileHUDDebug and RunService:IsStudio() then
		local text = {}
		for _, c in TouchLayout.LastCollisions do
			table.insert(text, c[1] .. "/" .. c[2] .. " (" .. c.Kind .. ")")
		end
		warn("[MobileHUD] controles que se pisan: " .. table.concat(text, ", "))
	end
	if TouchLayout.OnRelayout then
		TouchLayout.OnRelayout(layout, size)
	end
	if GameConfig.MobileHUDDebug then
		task.defer(drawDebug)
	end
end

-- Botón de saltar (el nuestro, Fase 15) en la última disposición: centro y diámetro
function TouchLayout.JumpRect(): (Vector2?, number?)
	local info = layout.Jump
	if info and buttons.Jump then
		return info.Center, info.Size.X
	end
	return nil, nil
end

-- Esquina de la zona de botones en la pantalla (para pasar a las coordenadas de otra ScreenGui)
function TouchLayout.Origin(): Vector2
	return areaOrigin
end

-- Disposición resuelta (para el HUD, el editor y las pruebas)
function TouchLayout.GetLayout()
	return layout, breakpoint
end

-- Rectángulo de un control en la zona de botones: centro y tamaño (nil si no hay)
function TouchLayout.Rect(actionName: string): (Vector2?, Vector2?)
	local info = layout[actionName]
	if not info then
		return nil, nil
	end
	return info.Center, info.Size
end

---------------------------------------------------------------------------
-- Visibilidad
---------------------------------------------------------------------------

wanted = function(name: string, ignoreBlocked: boolean?): boolean
	if editing then
		return true
	end
	if hiddenBy[name] then
		return false
	end
	if blockedNow and not ignoreBlocked then
		return name == "Emotes" and onlyEmotesNow
	end
	local s = settings()
	if name == "Sprint" then
		return (s.AutoSprint or 1) == 0
	elseif name == "LeftFire" then
		return (s.LeftFire or 0) == 1
	elseif name == "Airstrike" then
		return (player:GetAttribute("Airstrikes") or 0) > 0
	end
	return true
end

-- Suelta un botón sin esperar al dedo (se esconde, se destruye o se cambia de tipo)
local function release(entry)
	if entry.OwnerConnection then
		entry.OwnerConnection:Disconnect()
	end
	entry.Owner = nil
	entry.OwnerConnection = nil
	entry.Pressed = false
	paint(entry)
end

-- Enseña u oculta los controles según los menús abiertos, las cargas y los ajustes
function TouchLayout.RefreshVisibility()
	local _, ClientState = settings()
	if ClientState then
		blockedNow = ClientState.IsBlocked()
		onlyEmotesNow = ClientState.EmoteMenuOpen
			and not (ClientState.MenuOpen or ClientState.VoteOpen or ClientState.InMainMenu or ClientState.Dead or ClientState.TutorialOpen or ClientState.WheelOpen or ClientState.NewsOpen)
	end
	for name, entry in buttons do
		entry.Button.Visible = wanted(name)
		if not entry.Button.Visible and entry.Pressed then
			-- (si se esconde con el dedo encima, se suelta: no se queda disparando; ese dedo deja de ser
			-- del botón)
			release(entry)
			task.spawn(entry.Handler, name, Enum.UserInputState.Cancel, nil)
		end
	end
	placeStrip()
end

-- Si un control se ve en partida (sus ajustes, cargas y módulo; sin contar los menús abiertos, que
-- lo esconden un momento). Para colocar lo demás alrededor de los botones.
function TouchLayout.InPlay(actionName: string): boolean
	return buttons[actionName] ~= nil and wanted(actionName, true)
end

-- Suelta todos los controles pulsados (al morir, al reaparecer, al acabar la partida): ningún botón
-- se queda «pulsado», disparando o apuntando, y los dedos viejos ya no pueden soltar nada nuevo
function TouchLayout.ReleaseAll()
	for name, entry in buttons do
		if entry.Pressed or entry.Owner then
			release(entry)
			task.spawn(entry.Handler, name, Enum.UserInputState.Cancel, nil)
		end
	end
	table.clear(fireTouches)
end

function TouchLayout.SetHidden(actionName: string, hidden: boolean)
	local changed = (hiddenBy[actionName] == true) ~= (hidden == true)
	hiddenBy[actionName] = hidden or nil
	TouchLayout.RefreshVisibility()
	if changed and TouchLayout.OnRelayout and gui then
		-- (lo que se coloca alrededor de los botones se recoloca: un hueco más o menos)
		TouchLayout.OnRelayout(layout, (areaSize()))
	end
end

---------------------------------------------------------------------------
-- Estados
---------------------------------------------------------------------------

function TouchLayout.SetBadge(actionName: string, text: string?)
	local entry = buttons[actionName]
	if entry then
		entry.Badge.Text = text or ""
		entry.Badge.Visible = text ~= nil and text ~= ""
		if entry.Badge.Visible then
			entry.Badge.Size = UDim2.fromOffset(math.max(22, 9 * #entry.Badge.Text + 8), 18)
		end
	end
end

-- (compatibilidad: antes era el texto del botón; ahora un número va al globo y lo demás se ignora)
function TouchLayout.SetTitle(actionName: string, title: any)
	local text = tostring(title or "")
	local number = string.match(text, "%d+%.?%d*")
	TouchLayout.SetBadge(actionName, number)
end

function TouchLayout.SetActive(actionName: string, active: boolean)
	local entry = buttons[actionName]
	if entry and entry.Active ~= active then
		entry.Active = active
		paint(entry)
	end
end

-- 0 nada, 1 aviso (pocas balas), 2 necesario (cargador vacío)
function TouchLayout.SetEmphasis(actionName: string, level: number)
	local entry = buttons[actionName]
	if entry and entry.Emphasis ~= level then
		entry.Emphasis = level
		paint(entry)
	end
end

-- Recarga de una habilidad: fracción que falta (0 = lista) y texto (segundos)
function TouchLayout.SetCooldown(actionName: string, fraction: number, text: string?)
	local entry = buttons[actionName]
	if entry then
		local f = math.clamp(fraction or 0, 0, 1)
		entry.Cover.Visible = f > 0
		entry.Cover.Size = UDim2.fromScale(1, f)
		entry.Timer.Text = f > 0 and (text or "") or ""
	end
end

-- Tarjeta del arma: { Title = el arma a la que se cambia } (Fase 15: la munición va aparte)
function TouchLayout.SetCard(actionName: string, info: { [string]: any })
	local entry = buttons[actionName]
	if entry and entry.CardTexts then
		local changed = false
		for key, label in entry.CardTexts do
			local value = info[key]
			if type(value) == "string" and label.Text ~= value then
				label.Text = value
				changed = true
			end
		end
		if changed then
			fitCard(entry)
		end
	end
end

-- Pinta otra vez todos (al apuntar o dejar de hacerlo: los de poco uso se apagan un poco)
function TouchLayout.Repaint()
	for _, entry in buttons do
		paint(entry)
	end
end

---------------------------------------------------------------------------
-- Disparo arrastrando (el dedo dispara y gira la cámara a la vez)
---------------------------------------------------------------------------

local function insideFire(position: Vector3): string?
	local _, origin = areaSize()
	for _, name in { "Fire" } do
		local entry = buttons[name]
		local info = layout[name]
		if entry and entry.PassThrough and info and entry.Button.Visible and (not gui or gui.Enabled) then
			local p = Vector2.new(position.X, position.Y) - origin
			local d = p - info.Center
			local radius = math.max(info.Hit.X, info.Hit.Y) / 2
			if d.Magnitude <= radius then
				return name
			end
		end
	end
	return nil
end
TouchLayout.HitFire = insideFire

local function watchFireDrag()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or editing or input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local name = insideFire(input.Position)
		if name then
			fireTouches[input] = name
			buttons[name].Press(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		fireTouches[input] = nil
	end)
end

---------------------------------------------------------------------------
-- Depuración (GameConfig.MobileHUDDebug = true Y Studio; nunca en un servidor publicado): SAFE RECT,
-- CENTER DEAD ZONE, CAMERA SWIPE ZONE, LEFT/RIGHT THUMB ZONE y BUTTON HITBOXES, con la clase de
-- pantalla, su proporción, la escala y los insets
---------------------------------------------------------------------------

local debugGui, debugZoneGui
drawDebug = function()
	if not (GameConfig.MobileHUDDebug and RunService:IsStudio()) then
		return
	end
	if debugGui then
		debugGui:Destroy()
	end
	if debugZoneGui then
		debugZoneGui:Destroy()
	end
	debugGui = Instance.new("ScreenGui")
	debugGui.Name = "MobileHUDDebug"
	-- (las mismas coordenadas que los botones: su misma zona segura)
	debugGui.IgnoreGuiInset = false
	pcall(function()
		debugGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	debugGui.DisplayOrder = 90
	debugGui.ResetOnSpawn = false
	debugGui.Parent = gui.Parent
	local size, origin, screen = areaSize()
	local function box(position, s, color, label, fill)
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = color
		frame.BackgroundTransparency = fill and 0.85 or 1
		frame.Position = UDim2.fromOffset(position.X, position.Y)
		frame.Size = UDim2.fromOffset(s.X, s.Y)
		frame.Active = false
		frame.Parent = debugGui
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 1
		stroke.Parent = frame
		if label then
			local text = Instance.new("TextLabel")
			text.BackgroundTransparency = 1
			text.Size = UDim2.new(1, 0, 0, 14)
			text.TextColor3 = color
			text.TextSize = 11
			text.Font = Enum.Font.GothamBold
			text.TextXAlignment = Enum.TextXAlignment.Left
			text.Text = label
			text.Parent = frame
		end
	end
	-- SAFE RECT: la zona segura (CoreUISafeInsets) respecto a la pantalla entera
	box(Vector2.zero, size, Color3.fromRGB(60, 255, 120), string.format(" SAFE RECT %dx%d · pantalla %dx%d (%.2f:1) · %s · escala %.2f · inset %d,%d", size.X, size.Y, screen.X, screen.Y, math.max(screen.X, screen.Y) / math.max(1, math.min(screen.X, screen.Y)), breakpoint, MobileHUD.Scale(breakpoint, screen), origin.X, origin.Y))
	-- Zonas (las de los controles visibles)
	-- (los controles de la partida, aunque un menú los esconda en este momento)
	local visible = {}
	for name in buttons do
		if layout[name] and wanted(name, true) then
			table.insert(visible, name)
		end
	end
	local zones = MobileHUD.Zones(size, layout, visible)
	local clear = zones.Center.Radius
	box(zones.Center.Center - Vector2.new(clear, clear), Vector2.new(clear * 2, clear * 2), Color3.fromRGB(255, 80, 80), " CENTER DEAD ZONE", true)
	box(zones.Swipe.Min, zones.Swipe.Max - zones.Swipe.Min, Color3.fromRGB(80, 160, 255), " CAMERA SWIPE ZONE", true)
	if zones.LeftThumb then
		box(zones.LeftThumb.Min, zones.LeftThumb.Max - zones.LeftThumb.Min, Color3.fromRGB(190, 120, 255), " LEFT THUMB ZONE")
	end
	if zones.RightThumb then
		box(zones.RightThumb.Min, zones.RightThumb.Max - zones.RightThumb.Min, Color3.fromRGB(255, 150, 60), " RIGHT THUMB ZONE")
	end
	-- VISUAL RECT (blanco) y TOUCH RECT (amarillo) de cada control; en ROJO los que chocan
	local bad = {}
	for _, c in MobileHUD.Collisions(layout, visible, MobileHUD.MinTouchGap) do
		bad[c[1]], bad[c[2]] = true, true
	end
	for _, name in visible do
		local info = layout[name]
		local red = bad[name]
		box(info.Center - info.Size / 2, info.Size, red and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(240, 240, 240), nil, red)
		box(info.Center - info.Hit / 2, info.Hit, red and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 220, 60), string.format(" %s %d %d%%", name, info.Size.X, info.Opacity * 100))
	end
	-- Elementos de las zonas del HUD (otra pantalla: la zona segura del dispositivo); en ROJO si pisan
	-- algo
	local okZones, HUDZones = pcall(require, script.Parent.HUDZones)
	if okZones then
		local zoneGui = Instance.new("ScreenGui")
		zoneGui.Name = "Zones"
		zoneGui.IgnoreGuiInset = true
		zoneGui.DisplayOrder = 91
		zoneGui.ResetOnSpawn = false
		zoneGui.Parent = gui.Parent
		debugZoneGui = zoneGui
		local wrong = {}
		for _, issue in HUDZones.Validate() do
			wrong[issue[1]] = true
		end
		local saved = debugGui
		debugGui = zoneGui
		for id, rect in HUDZones.Placed do
			box(rect.Min, rect.Max - rect.Min, wrong[id] and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(60, 230, 230), " " .. id, wrong[id])
		end
		debugGui = saved
	end
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

-- Estados que cambian solos: apuntando (los secundarios bajan un poco), recarga necesaria o en curso,
-- la zona segura y el botón de saltar de Roblox (aparece un poco después: se esconde). Solo se toca
-- algo si cambia.
local lastAim, lastArea = nil, nil
local lastDebugDraw = 0
function TouchLayout.Tick()
	local _, ClientState = settings()
	if not ClientState or not gui then
		return
	end
	if ClientState.IsBlocked() ~= blockedNow then
		TouchLayout.RefreshVisibility()
	end
	if GameConfig.MobileHUDDebug and os.clock() - lastDebugDraw > 1 then
		lastDebugDraw = os.clock()
		task.defer(drawDebug)
	end
	local aiming = ClientState.Aiming == true
	if aiming ~= lastAim then
		lastAim = aiming
		TouchLayout.SetActive("Aim", aiming)
		TouchLayout.Repaint()
		placeStrip()
	end
	local def = ClientState.CurrentDef
	local level = 0
	if def and def.Type == "Gun" and def.MagSize then
		local ammo = ClientState.Ammo or 0
		if ClientState.Reloading then
			level = 0
		elseif ammo <= 0 then
			level = 2
		elseif ammo <= math.ceil(def.MagSize * 0.25) then
			level = 1
		end
	end
	TouchLayout.SetEmphasis("Reload", level)
	TouchLayout.SetActive("Reload", ClientState.Reloading == true)
	-- (los que son de pulsar y soltar enseñan si están puestos: agachado, correr con botón)
	TouchLayout.SetActive("Slide", ClientState.Crouching == true)
	TouchLayout.SetActive("Sprint", ClientState.SprintToggled == true)
	-- (la zona segura puede cambiar sin cambiar el tamaño de la pantalla: barra de Roblox, giro)
	local size, origin = areaSize()
	local key = size + origin * 10000
	if lastArea == nil or (key - lastArea).Magnitude > 1 then
		lastArea = key
		TouchLayout.Relayout()
	end
	hideRobloxJump()
end

local watching = false
local function watch()
	if watching then
		return
	end
	watching = true
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(TouchLayout.Relayout)
	end
	watchFireDrag()
	-- Al morir y al reaparecer, todo suelto (Fase 16)
	local function onCharacter(character)
		TouchLayout.ReleaseAll()
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(TouchLayout.ReleaseAll)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	-- Ajustes de controles: disposición, correr solo, disparo izquierdo y disparar arrastrando
	local _, ClientState = settings()
	if ClientState then
		local CONTROL_KEYS = { Controls = true, HudLayout = true, AutoSprint = true, LeftFire = true, FireDrag = true }
		ClientState.SettingsChanged.Event:Connect(function(key)
			if key ~= nil and not CONTROL_KEYS[key] then
				return
			end
			if (key == "FireDrag" or key == "Controls") and buttons.Fire and buttons.Fire.PassThrough ~= ((settings().FireDrag or 1) == 1) then
				-- (el botón cambia de tipo: con arrastre no se come el toque)
				local handler = buttons.Fire.Handler
				buttons.Fire.Button:Destroy()
				buttons.Fire = nil
				createButton("Fire", handler)
			end
			TouchLayout.Relayout()
			TouchLayout.RefreshVisibility()
		end)
	end
	-- Estados que cambian solos (TouchLayout.Tick): diez veces por segundo
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			TouchLayout.Tick()
		end
	end)
	task.defer(drawDebug)
end

-- Como ContextActionService:BindAction; si conBotón y la pantalla es táctil, el botón es nuestro
function TouchLayout.BindAction(actionName, handler, withButton, ...)
	ContextActionService:BindAction(actionName, handler, false, ...)
	if withButton and touchDevice() then
		if buttons[actionName] then
			buttons[actionName].Button:Destroy()
		end
		-- Disparo con la mano izquierda (opcional, para jugar con tres o cuatro dedos): mismo disparo.
		-- Los dos botones comparten el gatillo: empieza con el primer dedo y se suelta con el último
		-- (soltar uno no corta el disparo del otro)
		if actionName == "Fire" then
			local held = {}
			local touchHandler = function(name, state, input)
				if state == Enum.UserInputState.Begin then
					local first = next(held) == nil
					held[name] = true
					if first then
						return handler(name, state, input)
					end
				else
					held[name] = nil
					if next(held) == nil then
						return handler(name, state, input)
					end
				end
				return nil
			end
			createButton(actionName, touchHandler)
			if buttons.LeftFire then
				buttons.LeftFire.Button:Destroy()
			end
			createButton("LeftFire", touchHandler)
		else
			createButton(actionName, handler)
		end
		watch()
		TouchLayout.Relayout()
	end
end

-- Solo el botón (sin teclas): las habilidades y otros que llevan sus teclas por su cuenta
function TouchLayout.BindButton(actionName, handler)
	if not touchDevice() then
		return nil
	end
	if buttons[actionName] then
		buttons[actionName].Button:Destroy()
	end
	local button = createButton(actionName, handler)
	watch()
	TouchLayout.Relayout()
	return button
end

function TouchLayout.UnbindAction(actionName)
	ContextActionService:UnbindAction(actionName)
	local entry = buttons[actionName]
	if entry then
		entry.Button:Destroy()
		buttons[actionName] = nil
	end
end

-- El botón de una acción (nil si no hay: sin pantalla táctil o sin enlazar)
function TouchLayout.GetButton(actionName)
	local entry = buttons[actionName]
	return entry and entry.Button or nil
end

-- (compatibilidad: la posición la decide MobileHUD; se guarda por si alguien la consulta)
function TouchLayout.Set(actionName, position)
	registered[actionName] = position
	watch()
end

-- Modo editor: se ven todos los controles y no disparan nada; la disposición que se ve es la que se
-- está editando (TouchLayout.EditingLayout)
function TouchLayout.SetEditing(on: boolean, editingLayout)
	editing = on
	TouchLayout.EditingLayout = editingLayout
	TouchLayout.RefreshVisibility()
	TouchLayout.Relayout()
end

function TouchLayout.IsEditing()
	return editing
end

-- Todos los controles creados (para el editor)
function TouchLayout.Entries()
	return buttons
end

return TouchLayout
