-- Controles táctiles del juego (Fase 12: rehechos para el móvil). Roblox (ContextActionService) solo
-- crea 7 botones y los mete en un recuadro abajo a la derecha, así que en pantallas táctiles los
-- botones son nuestros. Las teclas y el mando siguen con ContextActionService.
--
-- Uso (como ContextActionService): TouchLayout.BindAction(nombre, función, conBotón, teclas...). La
-- función recibe (nombre, estado, input). Además: SetBadge (número pequeño: granadas, cargas),
-- SetCooldown (habilidades), SetCard (tarjeta del arma), SetActive (apuntando) y SetHidden.
--
-- Disposición: shared/MobileHUD (alrededor del botón de saltar de Roblox, leído en vivo; jerarquía:
-- DISPARAR > APUNTAR > acciones > poco uso; centro libre). El jugador puede moverlos, cambiar su
-- tamaño y su opacidad (Ajustes → Controles → Personalizar HUD: HUDEditor), y se guarda en sus
-- ajustes (Settings.HudLayout, validado en el servidor).
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

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MobileHUD = require(Shared.MobileHUD)
local GameConfig = require(Shared.GameConfig)
local TouchIcons = require(script.Parent.TouchIcons)

local TouchLayout = {}
-- Disposición que se está editando (HUDEditor) y aviso cuando cambia la disposición (HUD)
TouchLayout.EditingLayout = nil :: { [string]: any }?
TouchLayout.OnRelayout = nil :: ((layout: { [string]: any }, size: Vector2) -> ())?

local player = Players.LocalPlayer
local buttons = {} -- [acción] = entrada (ver createButton)
local registered = {} -- [acción] = posición pedida por el código (solo se guarda: manda MobileHUD)
local gui
local layout = {} -- disposición resuelta (MobileHUD.Resolve)
local breakpoint = "PHONE"
local hiddenBy = {} -- [acción] = true si su módulo la esconde (sin cargas, ajuste...)
local blockedNow = false
local onlyEmotesNow = false
local fireTouches = {} -- [InputObject] = acción (disparo arrastrando)
local editing = false

local COLORS = {
	Face = Color3.fromRGB(14, 16, 22),
	Stroke = Color3.fromRGB(235, 238, 245),
	Active = Color3.fromRGB(255, 205, 60), -- amarillo de la marca: solo para estados
	Warn = Color3.fromRGB(255, 176, 64),
	Empty = Color3.fromRGB(255, 92, 72),
	Ally = Color3.fromRGB(70, 150, 255),
}
-- Transparencia del fondo, el borde y el icono con opacidad 1 (se suman a la del control)
local FACE_ALPHA, STROKE_ALPHA, ICON_ALPHA = 0.42, 0.5, 0.02

local function touchDevice()
	return UserInputService.TouchEnabled
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
	-- (IgnoreGuiInset → ScreenInsets = DeviceSafeInsets: todo dentro de la zona segura del
	-- dispositivo, fuera de la muesca y de la barra de inicio)
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 3
	gui.Parent = player:WaitForChild("PlayerGui")
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		TouchLayout.Relayout()
	end)
	return gui
end

-- Tamaño de la zona donde van los botones (la zona segura) y su esquina en pantalla
local function areaSize(): (Vector2, Vector2)
	local g = ensureGui()
	local size, origin = g.AbsoluteSize, g.AbsolutePosition
	if typeof(size) ~= "Vector2" or size.X < 50 or size.Y < 50 then
		local camera = workspace.CurrentCamera
		size = camera and camera.ViewportSize or Vector2.new(844, 390)
		origin = Vector2.zero
	end
	if typeof(origin) ~= "Vector2" then
		origin = Vector2.zero
	end
	return size, origin
end

-- Centro (y diámetro) del botón de saltar de Roblox en nuestra zona (el real si existe y se ve)
local function jumpCenter(size: Vector2, origin: Vector2): (Vector2, number)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	local touchGui = pg and pg:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	if jump and jump:IsA("GuiObject") and jump.Visible then
		local p, s = jump.AbsolutePosition, jump.AbsoluteSize
		if typeof(p) == "Vector2" and typeof(s) == "Vector2" and s.X > 10 then
			return p + s / 2 - origin, s.X
		end
	end
	return MobileHUD.JumpRect(size)
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
	local pressed = entry.Pressed and 0.2 or 0
	local face = entry.Face
	face.BackgroundTransparency = math.clamp(1 - (1 - FACE_ALPHA + pressed) * opacity, 0, 1)
	local accent = entry.Active and COLORS.Active or (entry.Emphasis == 2 and COLORS.Empty) or (entry.Emphasis == 1 and COLORS.Warn) or nil
	entry.Stroke.Color = accent or COLORS.Stroke
	entry.Stroke.Thickness = accent and 3 or 2
	entry.Stroke.Transparency = math.clamp(1 - (1 - (accent and 0.05 or STROKE_ALPHA)) * opacity, 0, 1)
	local iconAlpha = math.clamp(1 - (1 - ICON_ALPHA) * math.max(opacity, 0.35), 0, 1)
	for _, piece in entry.Icon:GetDescendants() do
		if piece:IsA("Frame") then
			if piece.BackgroundTransparency < 1 then
				piece.BackgroundTransparency = iconAlpha
			end
			local stroke = piece:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = iconAlpha
			end
		elseif piece:IsA("TextLabel") then
			piece.TextTransparency = iconAlpha
		end
	end
	if entry.CardTexts then
		for _, label in entry.CardTexts do
			label.TextTransparency = iconAlpha
		end
	end
	TouchIcons.Tint(entry.Icon, accent or Color3.new(1, 1, 1))
	-- (la recarga necesaria se ve algo más grande, sin parpadear)
	local scale = (entry.Pressed and 0.9 or 1) * (entry.Emphasis == 2 and 1.1 or 1)
	if entry.Scale.Scale ~= scale then
		tween(entry.Scale, 0.08, { Scale = scale })
	end
end

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
	local iconPx = math.min(info.Size.X, info.Size.Y)
	if not entry.CardTexts and entry.IconPx ~= math.floor(iconPx) then
		entry.IconPx = math.floor(iconPx)
		-- (los trazos de los iconos dependen del tamaño: se vuelven a dibujar)
		for _, child in entry.Icon:GetChildren() do
			child:Destroy()
		end
		local control = MobileHUD.ById[entry.Id]
		if control and control.Icon ~= "Card" then
			TouchIcons.Draw(control.Icon, entry.Icon, iconPx * 0.56)
		end
	end
	paint(entry)
end

-- Botón de un control: zona táctil (algo mayor que el dibujo) con su cara, icono, globo y recarga
local function createButton(actionName, handler)
	local control = MobileHUD.ById[actionName]
	local isCard = control and typeof(control.Size) == "Vector2"
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
	corner.CornerRadius = isCard and UDim.new(0, 12) or UDim.new(0.5, 0)
	corner.Parent = face
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Stroke
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = face
	local scale = Instance.new("UIScale")
	scale.Parent = face
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(isCard and 1 or 0.56, isCard and 1 or 0.56)
	icon.BackgroundTransparency = 1
	icon.Parent = face
	-- Globo (cantidad: granadas, cargas) arriba a la derecha
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.86, 0.14)
	badge.Size = UDim2.fromOffset(26, 18)
	badge.BackgroundColor3 = COLORS.Face
	badge.BackgroundTransparency = 0.1
	badge.TextColor3 = Color3.new(1, 1, 1)
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 13
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
	cover.BackgroundTransparency = 0.35
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
	timer.TextSize = 16
	timer.Text = ""
	timer.ZIndex = 3
	timer.Parent = face

	local entry = {
		Id = actionName,
		Button = button,
		Face = face,
		Stroke = stroke,
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
	}
	-- Tarjeta del arma (cambiar arma): nombre, munición y la otra arma
	if isCard then
		-- (arriba: el arma y, a la derecha, qué arma es de cuántas «1/2»; abajo, grande, la munición
		-- «30 / 120». Una sola línea cada uno: el texto se encoge en vez de partirse)
		local function text(name, x, y, w, h, size, font, color, align)
			local label = Instance.new("TextLabel")
			label.Name = name
			label.BackgroundTransparency = 1
			label.Position = UDim2.new(x, x == 0 and 10 or 0, y, 0)
			label.Size = UDim2.new(w, x == 0 and -10 or -10, h, 0)
			label.Font = font
			label.TextColor3 = color
			label.TextScaled = true
			label.TextWrapped = false
			label.TextXAlignment = align or Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Text = ""
			label.Parent = icon
			local fit = Instance.new("UITextSizeConstraint")
			fit.MaxTextSize = size
			fit.MinTextSize = 11
			fit.Parent = label
			return label
		end
		entry.CardTexts = {
			Title = text("Weapon", 0, 0.07, 0.78, 0.32, 13, Enum.Font.GothamBold, Color3.fromRGB(225, 228, 236)),
			Sub = text("Slot", 0.78, 0.07, 0.22, 0.32, 12, Enum.Font.GothamBold, Color3.fromRGB(160, 166, 180), Enum.TextXAlignment.Right),
			Value = text("Ammo", 0, 0.42, 1, 0.5, 22, Enum.Font.GothamBlack, Color3.new(1, 1, 1)),
		}
	end

	local function press(input)
		entry.Pressed = true
		paint(entry)
		task.spawn(entry.Handler, actionName, Enum.UserInputState.Begin, input)
		local connection
		connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			local state = input.UserInputState
			if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				connection:Disconnect()
				entry.Pressed = false
				paint(entry)
				task.spawn(entry.Handler, actionName, state, input)
			end
		end)
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

local lastJumpCenter: Vector2?, lastJumpSize: number? = nil, nil

-- Vuelve a colocar todo (pantalla girada, disposición del jugador cambiada, salto de Roblox visible)
function TouchLayout.Relayout()
	if not gui then
		return
	end
	local size, origin = areaSize()
	breakpoint = MobileHUD.Breakpoint(size, touchDevice())
	local s = settings()
	local jump, jumpSize = jumpCenter(size, origin)
	lastJumpCenter, lastJumpSize = jump, jumpSize
	layout = MobileHUD.Resolve(size, {
		Breakpoint = breakpoint,
		Jump = jump,
		Custom = editing and TouchLayout.EditingLayout or s.HudLayout,
	})
	for _, entry in buttons do
		place(entry)
	end
	if TouchLayout.OnRelayout then
		TouchLayout.OnRelayout(layout, size)
	end
end

-- Botón de saltar de Roblox usado en la última disposición: centro y diámetro
function TouchLayout.JumpRect(): (Vector2?, number?)
	return lastJumpCenter, lastJumpSize
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

local function wanted(name: string): boolean
	if editing then
		return true
	end
	if hiddenBy[name] then
		return false
	end
	if blockedNow then
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
			-- (si se esconde con el dedo encima, se suelta: no se queda disparando)
			entry.Pressed = false
			task.spawn(entry.Handler, name, Enum.UserInputState.Cancel, nil)
			paint(entry)
		end
	end
end

function TouchLayout.SetHidden(actionName: string, hidden: boolean)
	hiddenBy[actionName] = hidden or nil
	TouchLayout.RefreshVisibility()
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

-- Tarjeta del arma: { Title = nombre o estado, Value = "24 / 90", Sub = "1/2", ValueColor = color }
function TouchLayout.SetCard(actionName: string, info: { [string]: any })
	local entry = buttons[actionName]
	if entry and entry.CardTexts then
		for key, label in entry.CardTexts do
			local value = info[key]
			if type(value) == "string" and label.Text ~= value then
				label.Text = value
			end
		end
		local color = info.ValueColor
		if typeof(color) == "Color3" and entry.CardTexts.Value.TextColor3 ~= color then
			entry.CardTexts.Value.TextColor3 = color
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
	local size, origin = areaSize()
	local _ = size
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
-- Depuración (GameConfig.MobileHUDDebug, solo en Studio): zona segura, zonas táctiles, centro libre,
-- zona de cámara del pulgar derecho, resolución y tipo de pantalla
---------------------------------------------------------------------------

local debugGui
local function drawDebug()
	if not (GameConfig.MobileHUDDebug and RunService:IsStudio()) then
		return
	end
	if debugGui then
		debugGui:Destroy()
	end
	debugGui = Instance.new("ScreenGui")
	debugGui.Name = "MobileHUDDebug"
	debugGui.IgnoreGuiInset = true
	debugGui.DisplayOrder = 90
	debugGui.ResetOnSpawn = false
	debugGui.Parent = gui.Parent
	local size = areaSize()
	local function box(position, s, color, label)
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Position = UDim2.fromOffset(position.X, position.Y)
		frame.Size = UDim2.fromOffset(s.X, s.Y)
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
			text.Text = label
			text.Parent = frame
		end
	end
	box(Vector2.zero, size, Color3.fromRGB(60, 255, 120), string.format("%dx%d · %s", size.X, size.Y, breakpoint))
	local clear = MobileHUD.CenterClear(size)
	box(size / 2 - Vector2.new(clear, clear), Vector2.new(clear * 2, clear * 2), Color3.fromRGB(255, 80, 80), "centro libre")
	box(Vector2.new(size.X * 0.5, 0), Vector2.new(size.X * 0.5, size.Y * 0.62), Color3.fromRGB(80, 160, 255), "cámara (pulgar derecho)")
	for name, info in layout do
		if buttons[name] then
			box(info.Center - info.Hit / 2, info.Hit, Color3.fromRGB(255, 220, 60), name)
		end
	end
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

-- Estados que cambian solos: apuntando (los de poco uso se apagan), recarga necesaria y el botón de
-- saltar de Roblox (aparece un poco después). Solo se toca algo si cambia.
local lastAim, lastJump = nil, nil
function TouchLayout.Tick()
	local _, ClientState = settings()
	if not ClientState or not gui then
		return
	end
	local aiming = ClientState.Aiming == true
	if aiming ~= lastAim then
		lastAim = aiming
		TouchLayout.SetActive("Aim", aiming)
		TouchLayout.Repaint()
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
	local size, origin = areaSize()
	local jump = jumpCenter(size, origin)
	if lastJump == nil or (jump - lastJump).Magnitude > 2 then
		lastJump = jump
		TouchLayout.Relayout()
	end
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
	-- Ajustes de controles: disposición, correr solo, disparo izquierdo y disparar arrastrando
	local _, ClientState = settings()
	if ClientState then
		ClientState.SettingsChanged.Event:Connect(function(key)
			if key == "FireDrag" and buttons.Fire then
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
		createButton(actionName, handler)
		-- Disparo con la mano izquierda (opcional, para jugar con tres o cuatro dedos): mismo disparo
		if actionName == "Fire" then
			if buttons.LeftFire then
				buttons.LeftFire.Button:Destroy()
			end
			createButton("LeftFire", handler)
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
