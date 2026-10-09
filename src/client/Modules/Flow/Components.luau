-- Componentes del flujo (lobby, party, matchmaking, presentaciones, loadout): raíz con escala
-- según la pantalla, textos con la jerarquía del tema, paneles oscuros con borde fino, botones con
-- respuesta al pasar y al pulsar, barras de estadística animadas, tarjetas de jugador.
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local Theme = require(script.Parent.Theme)
local UISound = require(script.Parent.UISound)
local PlayerCards = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlayerCards"))

local C = {}
local Colors = Theme.Colors

-- Mayúsculas que respetan las tildes
local ACCENTS = { ["á"] = "Á", ["é"] = "É", ["í"] = "Í", ["ó"] = "Ó", ["ú"] = "Ú", ["ñ"] = "Ñ", ["ü"] = "Ü" }
local function upper(text)
	local result = string.upper(tostring(text))
	return (string.gsub(result, "\195[\161\169\173\179\186\177\188]", ACCENTS))
end
C.upper = upper

-- Corta un texto largo con "…" (por caracteres UTF-8: no rompe tildes ni emojis)
function C.short(text, max)
	text = tostring(text)
	local length = utf8.len(text)
	if not length or length <= max then
		return text
	end
	local cut = utf8.offset(text, max) or (#text + 1)
	return string.sub(text, 1, cut - 1) .. "…"
end

local function new(className, props, children)
	local inst = Instance.new(className)
	local parent
	for key, value in props or {} do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
C.new = new

local function tween(inst, time, props, style)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
C.tween = tween

function C.corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 4) })
end

function C.stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color or Colors.Line,
		Thickness = thickness or 1,
		Transparency = transparency or Theme.LineAlpha,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function C.padding(top, right, bottom, left)
	right = right or top
	bottom = bottom or top
	left = left or right
	return new("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	})
end

function C.list(padding, direction, align)
	return new("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})
end

---------------------------------------------------------------------------
-- Pantalla: tipo de dispositivo y raíz escalada
---------------------------------------------------------------------------

-- PHONE (pantalla baja y táctil), TABLET (táctil grande) o DESKTOP
function C.Breakpoint()
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local touch = InputMode.TouchUI()
	-- (pantalla baja: teléfono apaisado o ventana pequeña; se compacta igual)
	if size.Y < 520 then
		return "PHONE"
	elseif touch then
		return "TABLET"
	end
	return "DESKTOP"
end

-- Alto de diseño por tipo de pantalla: en el teléfono todo se ve más grande (menos "píxeles
-- virtuales" en la misma altura), así ningún texto queda diminuto
local DESIGN_HEIGHT = { PHONE = 460, TABLET = 680, DESKTOP = 720 }

-- Raíz de una pantalla: un Frame del tamaño de la pantalla en píxeles virtuales con su UIScale.
-- Los hijos se colocan con Scale y AnchorPoint (izquierda/centro/derecha) y medidas en píxeles
-- virtuales; la raíz se reajusta sola al girar o cambiar el tamaño de la ventana.
function C.root(parent, name)
	local frame = new("Frame", {
		Name = name or "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	local scale = new("UIScale", { Parent = frame })
	local function refresh()
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		if viewport.Y < 2 then
			viewport = Vector2.new(1280, 720)
		end
		-- (zona segura: muesca y barra de Roblox; la ScreenGui ya usa ScreenInsets si existe)
		local insetTop = 0
		local ok, inset = pcall(function()
			return GuiService.TopbarInset
		end)
		if ok and typeof(inset) == "Rect" and parent and parent:IsA("ScreenGui") and parent.IgnoreGuiInset then
			insetTop = 0
		end
		local design = DESIGN_HEIGHT[C.Breakpoint()]
		local s = math.clamp(viewport.Y / design, 0.45, 2)
		scale.Scale = s
		frame.Size = UDim2.fromOffset(viewport.X / s, (viewport.Y - insetTop) / s)
		frame:SetAttribute("Breakpoint", C.Breakpoint())
		frame:SetAttribute("VirtualWidth", viewport.X / s)
	end
	refresh()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
	return frame, refresh
end

---------------------------------------------------------------------------
-- Texto
---------------------------------------------------------------------------

-- role: "Title" | "TitleItalic" | "Number" | "Body" | "BodyBold"
function C.text(props)
	local role = props.Role or "Body"
	local label = new("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = props.Color or Colors.Text,
		TextSize = props.TextSize or Theme.Size.Body,
		Text = props.Text or "",
		TextXAlignment = props.AlignX or Enum.TextXAlignment.Left,
		TextYAlignment = props.AlignY or Enum.TextYAlignment.Center,
		TextWrapped = props.Wrap == true,
		TextTruncate = props.Wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
		RichText = props.Rich == true,
		Font = Theme.FontEnums[role] or Enum.Font.Gotham,
		Size = props.Size or UDim2.new(1, 0, 0, (props.TextSize or Theme.Size.Body) + 6),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.Anchor or props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.Order or 0,
		ZIndex = props.ZIndex or 1,
		Name = props.Name or "Text",
		Parent = props.Parent,
	})
	if Theme.Fonts[role] then
		label.FontFace = Theme.Fonts[role]
	end
	if props.Scaled then
		label.TextScaled = true
		new("UITextSizeConstraint", { MaxTextSize = props.TextSize or Theme.Size.Body, MinTextSize = props.MinTextSize or 11, Parent = label })
	end
	if props.Stroke then
		new("UIStroke", { Thickness = props.Stroke, Color = Colors.Black, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = label })
	end
	return label
end

---------------------------------------------------------------------------
-- Paneles
---------------------------------------------------------------------------

-- Panel oscuro semitransparente con borde fino y un brillo arriba (profundidad sin ser plano).
-- opts.Accent = color de una franja a la izquierda; opts.Alpha = transparencia del fondo
function C.panel(props, opts)
	opts = opts or {}
	local frame = new("Frame", {
		Name = props.Name or "Panel",
		BackgroundColor3 = opts.Color or Colors.Panel,
		BackgroundTransparency = opts.Alpha or Theme.PanelAlpha,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(200, 100),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.Anchor or props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.Order or 0,
		ClipsDescendants = props.Clip == true,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}, {
		C.corner(opts.Radius or 4),
		C.stroke(opts.StrokeColor or Colors.Line, opts.StrokeThickness or 1, opts.StrokeAlpha or Theme.LineAlpha),
		new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 0.12),
			}),
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 192, 200)),
		}),
	})
	if opts.Accent then
		new("Frame", {
			Name = "Accent",
			Size = UDim2.new(0, 3, 1, -8),
			Position = UDim2.fromOffset(0, 4),
			BackgroundColor3 = opts.Accent,
			BorderSizePixel = 0,
			ZIndex = (props.ZIndex or 1) + 1,
			Parent = frame,
		})
	end
	return frame
end

-- Cabecera de panel: título corto en mayúsculas (amarillo) y, opcional, un texto a la derecha
function C.header(parent, text, right, order)
	local row = new("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	C.text({ Text = text, Role = "Title", TextSize = 18, Color = Colors.YellowText, Size = UDim2.new(0.7, 0, 1, 0), Parent = row })
	if right then
		C.text({ Name = "Right", Text = right, Role = "Number", TextSize = 15, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.fromScale(0.7, 0), Parent = row })
	end
	return row
end

---------------------------------------------------------------------------
-- Botones
---------------------------------------------------------------------------

-- Respuesta al ratón y al dedo: crece un poco al pasar (1,03), se hunde al pulsar (0,97) y vuelve;
-- el borde se ilumina. Rápido (0,08-0,16 s) y con sonido central (UISound).
function C.feel(button, opts)
	opts = opts or {}
	local scale = new("UIScale", { Name = "FeelScale", Parent = button })
	local stroke = button:FindFirstChildOfClass("UIStroke")
	local baseStroke = stroke and stroke.Transparency or 1
	local hovering, pressed = false, false
	local function apply(info)
		local target = pressed and 0.97 or (hovering and (opts.HoverScale or 1.03) or 1)
		TweenService:Create(scale, info, { Scale = target }):Play()
		if stroke then
			TweenService:Create(stroke, info, { Transparency = hovering and math.max(0, baseStroke - 0.45) or baseStroke }):Play()
		end
	end
	local hoverInfo = TweenInfo.new(Theme.Time.Hover, Enum.EasingStyle.Quad)
	local pressInfo = TweenInfo.new(Theme.Time.Press, Enum.EasingStyle.Quad)
	local releaseInfo = TweenInfo.new(Theme.Time.Release, Enum.EasingStyle.Back)
	button.MouseEnter:Connect(function()
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			return
		end
		hovering = true
		apply(hoverInfo)
		if not opts.Silent then
			UISound.Play("Hover")
		end
	end)
	button.MouseLeave:Connect(function()
		hovering, pressed = false, false
		apply(hoverInfo)
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			apply(pressInfo)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressed = false
			if input.UserInputType == Enum.UserInputType.Touch then
				hovering = false
			end
			apply(releaseInfo)
		end
	end)
	return scale
end

-- Botón del flujo. opts: Text, Icon, Style ("Primary" amarillo | "Menu" lateral | "Ghost" | "Danger"),
-- Size, Position, Anchor, Order, Parent, OnClick, TextSize, Sub (texto pequeño debajo), Sound
function C.button(opts)
	local style = opts.Style or "Ghost"
	local bg, fg, alpha, strokeColor, strokeAlpha
	if style == "Primary" then
		bg, fg, alpha, strokeColor, strokeAlpha = Colors.Yellow, Color3.fromRGB(16, 14, 8), 0, Colors.White, 0.55
	elseif style == "Danger" then
		bg, fg, alpha, strokeColor, strokeAlpha = Colors.Red, Colors.White, 0, Colors.White, 0.6
	elseif style == "Menu" then
		bg, fg, alpha, strokeColor, strokeAlpha = Colors.Panel, Colors.Text, 0.12, Colors.Line, 0.86
	else
		bg, fg, alpha, strokeColor, strokeAlpha = Colors.PanelLight, Colors.Text, 0.25, Colors.Line, 0.8
	end
	local button = new("TextButton", {
		Name = opts.Name or ("Button_" .. tostring(opts.Text)),
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = bg,
		BackgroundTransparency = alpha,
		BorderSizePixel = 0,
		Size = opts.Size or UDim2.fromOffset(220, 48),
		Position = opts.Position or UDim2.new(),
		AnchorPoint = opts.Anchor or Vector2.new(),
		LayoutOrder = opts.Order or 0,
		ZIndex = opts.ZIndex or 2,
		Parent = opts.Parent,
	}, {
		C.corner(opts.Radius or 4),
		C.stroke(strokeColor, style == "Primary" and 2 or 1, strokeAlpha),
	})
	button:SetAttribute("BaseColor", bg)
	button:SetAttribute("BaseTextColor", fg)
	button:SetAttribute("BaseAlpha", alpha)
	if style == "Primary" then
		-- Brillo de arriba y sombra de abajo: el botón amarillo tiene volumen
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 120)),
				ColorSequenceKeypoint.new(0.5, Colors.Yellow),
				ColorSequenceKeypoint.new(1, Colors.YellowDark),
			}),
			Parent = button,
		})
	end
	local textSize = opts.TextSize or (style == "Primary" and 30 or 18)
	local hasIcon = opts.Icon ~= nil and opts.Icon ~= ""
	local inner = new("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = button.ZIndex + 1,
		Parent = button,
	}, { C.padding(0, 14, 0, style == "Menu" and 16 or 14) })
	if hasIcon then
		C.text({
			Name = "Icon",
			Text = opts.Icon,
			Role = "TitleItalic",
			TextSize = textSize,
			Color = fg,
			AlignX = Enum.TextXAlignment.Center,
			Size = UDim2.new(0, textSize + 8, 1, 0),
			ZIndex = button.ZIndex + 1,
			Parent = inner,
		})
	end
	local label = C.text({
		Name = "Label",
		Text = opts.Text or "",
		Role = style == "Primary" and "TitleItalic" or "Title",
		TextSize = textSize,
		Color = fg,
		Scaled = true,
		AlignX = opts.AlignX or (style == "Menu" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center),
		Size = UDim2.new(1, hasIcon and -(textSize + 14) or 0, opts.Sub and 0.62 or 1, 0),
		Position = UDim2.fromOffset(hasIcon and textSize + 14 or 0, 0),
		ZIndex = button.ZIndex + 1,
		Parent = inner,
	})
	if opts.Sub then
		C.text({
			Name = "Sub",
			Text = opts.Sub,
			Role = "BodyBold",
			TextSize = 12,
			Color = style == "Primary" and Color3.fromRGB(80, 60, 10) or Colors.TextDim,
			AlignX = label.TextXAlignment,
			Size = UDim2.new(1, hasIcon and -(textSize + 14) or 0, 0.38, 0),
			Position = UDim2.new(0, hasIcon and textSize + 14 or 0, 0.6, 0),
			ZIndex = button.ZIndex + 1,
			Parent = inner,
		})
	end
	C.feel(button, { HoverScale = opts.HoverScale })
	if opts.OnClick then
		button.Activated:Connect(function()
			UISound.Play(opts.Sound or (style == "Primary" and "Play" or "Click"))
			opts.OnClick(button)
		end)
	end
	return button
end

-- Marca de "selección" en un botón de menú: fondo amarillo y texto oscuro (o vuelve a normal)
function C.setSelected(button, selected)
	local label = button:FindFirstChild("Label", true)
	local icon = button:FindFirstChild("Icon", true)
	-- (sin seleccionar vuelve a su estilo de origen, guardado al crearlo)
	local baseBg = button:GetAttribute("BaseColor")
	local baseFg = button:GetAttribute("BaseTextColor")
	local baseAlpha = button:GetAttribute("BaseAlpha")
	local bg = selected and Colors.Yellow or (typeof(baseBg) == "Color3" and baseBg or Colors.Panel)
	local fg = selected and Color3.fromRGB(16, 14, 8) or (typeof(baseFg) == "Color3" and baseFg or Colors.Text)
	tween(button, Theme.Time.Fast, { BackgroundColor3 = bg, BackgroundTransparency = selected and 0 or (tonumber(baseAlpha) or 0.12) })
	if label then
		tween(label, Theme.Time.Fast, { TextColor3 = fg })
	end
	if icon then
		tween(icon, Theme.Time.Fast, { TextColor3 = fg })
	end
end

-- Punto rojo de aviso (algo nuevo) en la esquina de un botón
function C.dot(parent, visible)
	local dot = parent:FindFirstChild("Dot") or new("Frame", {
		Name = "Dot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Colors.Red,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = parent,
	}, { C.corner(5), C.stroke(Colors.White, 1, 0.3) })
	dot.Visible = visible ~= false
	return dot
end

---------------------------------------------------------------------------
-- Barras
---------------------------------------------------------------------------

-- Barra de progreso (fraction 0..1) que se anima al cambiar
function C.progress(props)
	local back = new("Frame", {
		Name = props.Name or "Progress",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.new(1, 0, 0, 6),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.Anchor or props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.Order or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}, { C.corner(2) })
	local fill = new("Frame", {
		Name = "Fill",
		BackgroundColor3 = props.Color or Colors.Yellow,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(math.clamp(props.Value or 0, 0, 1), 1),
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = back,
	}, { C.corner(2) })
	local bar = { Frame = back, Fill = fill }
	function bar.Set(_, fraction, animate)
		fraction = math.clamp(fraction or 0, 0, 1)
		if animate == false then
			fill.Size = UDim2.fromScale(fraction, 1)
		else
			tween(fill, Theme.Time.Stat, { Size = UDim2.fromScale(fraction, 1) }, Enum.EasingStyle.Quint)
		end
	end
	return bar
end

-- Fila de estadística: icono, nombre, barra animada y número (0..100)
function C.statRow(parent, name, icon, order)
	local row = new("Frame", {
		Name = "Stat_" .. name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	C.text({ Text = icon or "", Role = "Title", TextSize = 18, AlignX = Enum.TextXAlignment.Center, Size = UDim2.new(0, 24, 1, 0), Color = Colors.White, Parent = row })
	C.text({ Text = name, Role = "Title", TextSize = Theme.Size.Stat - 2, Scaled = true, Size = UDim2.new(0.38, -28, 1, 0), Position = UDim2.fromOffset(30, 0), Parent = row })
	local bar = C.progress({ Size = UDim2.new(0.5, -44, 0, 8), Position = UDim2.new(0.38, 6, 0.5, 0), Anchor = Vector2.new(0, 0.5), Parent = row })
	local number = C.text({ Text = "0", Role = "Number", TextSize = Theme.Size.Stat, AlignX = Enum.TextXAlignment.Right, Size = UDim2.new(0.12, 0, 1, 0), Position = UDim2.new(0.88, 0, 0, 0), Parent = row })
	local current = 0
	local stat = { Frame = row }
	function stat.Set(_, value, animate)
		value = math.clamp(math.floor((value or 0) + 0.5), 0, 100)
		bar:Set(value / 100, animate)
		if animate == false then
			current = value
			number.Text = tostring(value)
			return
		end
		-- El número cuenta hasta el valor nuevo a la vez que la barra (~0,25 s)
		local from = current
		current = value
		task.spawn(function()
			local start = os.clock()
			while os.clock() - start < Theme.Time.Stat do
				local a = (os.clock() - start) / Theme.Time.Stat
				number.Text = tostring(math.floor(from + (value - from) * a + 0.5))
				task.wait()
			end
			number.Text = tostring(value)
		end)
	end
	return stat
end

---------------------------------------------------------------------------
-- Tarjetas
---------------------------------------------------------------------------

-- Moneda/divisa de la barra superior: icono, cantidad y botón "+" amarillo
function C.currency(parent, icon, order, onPlus)
	local box = C.panel({ Size = UDim2.fromOffset(150, 40), Order = order, Parent = parent })
	C.text({ Text = icon, Role = "Title", TextSize = 22, AlignX = Enum.TextXAlignment.Center, Size = UDim2.new(0, 36, 1, 0), Parent = box })
	local amount = C.text({ Name = "Amount", Text = "0", Role = "Number", TextSize = 22, Size = UDim2.new(1, -78, 1, 0), Position = UDim2.fromOffset(36, 0), Parent = box })
	if onPlus then
		local plus = new("TextButton", {
			Name = "Plus",
			AutoButtonColor = false,
			Text = "+",
			TextSize = 24,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(16, 14, 8),
			BackgroundColor3 = Colors.Yellow,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			Parent = box,
		}, { C.corner(3) })
		C.feel(plus)
		plus.Activated:Connect(function()
			UISound.Play("Click")
			onPlus()
		end)
	end
	return box, amount
end

-- Estados de un jugador en el party / la presentación
C.Status = {
	Ready = { Text = "LISTO", Color = Colors.Green, Icon = "✔" },
	NotReady = { Text = "NO LISTO", Color = Colors.TextDim, Icon = "•" },
	Loading = { Text = "CARGANDO", Color = Colors.YellowText, Icon = "◌" },
	InMatch = { Text = "EN PARTIDA", Color = Colors.Red, Icon = "⚔" },
	Bot = { Text = "BOT", Color = Colors.TextDim, Icon = "🤖" },
	Offline = { Text = "DESCONECTADO", Color = Colors.TextFaint, Icon = "✕" },
}

-- Tarjeta de jugador (nombre, nivel, estado, líder): se usa en el party y en la presentación de
-- equipos. info = { Name, Level, Status, Leader, Me, TeamColor, Card (tarjeta de jugador elegida) }
function C.playerCard(props, info)
	local card = C.panel({ Name = "PlayerCard", Size = props.Size or UDim2.fromOffset(170, 58), Position = props.Position, Anchor = props.Anchor, Order = props.Order, Parent = props.Parent, ZIndex = props.ZIndex }, {
		Accent = info.TeamColor or (info.Me and Colors.Yellow or nil),
		StrokeColor = info.Me and Colors.Yellow or Colors.Line,
		StrokeAlpha = info.Me and 0.3 or Theme.LineAlpha,
	})
	-- Fondo con su tarjeta de jugador (lo primero: queda detrás del nombre)
	local cardSlot = new("Frame", { Name = "CardSlot", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = props.ZIndex or 1, Parent = card }, { C.corner(4) })
	local cardGradient = new("UIGradient", { Rotation = 90, Parent = cardSlot })
	local z = (props.ZIndex or 1) + 1
	local name = C.text({ Name = "PlayerName", Text = upper(info.Name or ""), Role = "Title", TextSize = 18, Color = info.Me and Colors.YellowText or Colors.White, Scaled = true, Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(10, 5), ZIndex = z, Parent = card })
	local level = C.text({ Name = "Level", Text = info.Level and ("NV. " .. tostring(info.Level)) or "", Role = "Number", TextSize = 14, Color = Colors.TextDim, Size = UDim2.new(0.5, -10, 0, 18), Position = UDim2.new(0, 10, 1, -22), ZIndex = z, Parent = card })
	local status = C.text({ Name = "Status", Text = "", Role = "Title", TextSize = 14, Scaled = true, AlignX = Enum.TextXAlignment.Right, Size = UDim2.new(0.6, -10, 0, 18), Position = UDim2.new(0.4, 0, 1, -22), ZIndex = z, Parent = card })
	local leader = C.text({ Name = "Leader", Text = "👑", TextSize = 14, AlignX = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -24, 0, 4), ZIndex = z, Parent = card })
	local api = { Frame = card }
	function api.Update(_, newInfo)
		local def = newInfo.Card and newInfo.Card ~= "Default" and PlayerCards.List[newInfo.Card]
		cardSlot.BackgroundTransparency = def and 0.3 or 1
		if def then
			cardSlot.BackgroundColor3 = def.Top
			cardGradient.Color = ColorSequence.new(def.Top, def.Bottom)
		end
		name.Text = upper(newInfo.Name or "")
		-- (quién eres tú también se actualiza: la tarjeta puede crearse vacía y llenarse después)
		name.TextColor3 = newInfo.Me and Colors.YellowText or Colors.White
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = newInfo.Me and Colors.Yellow or Colors.Line
			stroke.Transparency = newInfo.Me and 0.3 or Theme.LineAlpha
		end
		level.Text = newInfo.Level and ("NV. " .. tostring(newInfo.Level)) or ""
		local st = C.Status[newInfo.Status or "NotReady"] or C.Status.NotReady
		status.Text = st.Icon .. " " .. st.Text
		status.TextColor3 = st.Color
		leader.Visible = newInfo.Leader == true
	end
	api:Update(info)
	return api
end

return C
