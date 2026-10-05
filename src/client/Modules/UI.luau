-- Pequeña utilidad para crear interfaces desde código.
local UI = {}

UI.Font = Enum.Font.FredokaOne
UI.FontBody = Enum.Font.GothamBold

function UI.new(className, props, children)
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

function UI.corner(radius)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function UI.stroke(color, thickness, transparency)
	return UI.new("UIStroke", {
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- Degradado brillante (de claro arriba a más oscuro abajo) sobre el color de fondo
function UI.gloss(bottom)
	return UI.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), bottom or Color3.fromRGB(185, 185, 195)),
		Rotation = 90,
	})
end

function UI.padding(px)
	return UI.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

-- Texto con borde negro estilo "cartoon"
function UI.label(props, children)
	local defaults = {
		BackgroundTransparency = 1,
		Font = UI.Font,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4,
		TextSize = 18,
	}
	for key, value in props or {} do
		defaults[key] = value
	end
	return UI.new("TextLabel", defaults, children)
end

function UI.button(props, children)
	local defaults = {
		Font = UI.Font,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 18,
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(40, 120, 255),
	}
	for key, value in props or {} do
		defaults[key] = value
	end
	local button = UI.new("TextButton", defaults, children)
	UI.corner(8).Parent = button
	return button
end

function UI.formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

-- Espera a que la cámara sepa el tamaño de la pantalla (al arrancar puede valer 0 un instante y el
-- móvil se confundía con un ordenador: minimapa y paneles salían a tamaño de escritorio)
function UI.WaitViewport(timeout)
	local deadline = os.clock() + (timeout or 2)
	while os.clock() < deadline do
		local camera = workspace.CurrentCamera
		local size = camera and camera.ViewportSize
		if typeof(size) == "Vector2" and size.Y > 2 then
			return
		end
		task.wait(0.05)
	end
end

-- ¿Teléfono? (táctil, sin teclado y pantalla baja; las tablets usan la disposición normal)
function UI.IsPhone()
	local UserInputService = game:GetService("UserInputService")
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and typeof(size) == "Vector2" and size.Y > 2 and size.Y < 500
end

-- Dónde acaba la barra de botones de Roblox (menú, chat...) arriba a la izquierda: lo nuestro de esa
-- esquina va debajo para no quedar tapado
function UI.TopbarBottom()
	local ok, inset = pcall(function()
		return game:GetService("GuiService").TopbarInset
	end)
	if ok and typeof(inset) == "Rect" and inset.Height > 0 then
		return math.floor(inset.Max.Y) + 6
	end
	return 60
end

-- Mayúsculas que respetan las tildes (string.upper solo cambia las letras sin acento: «Mítico» saldría
-- «MíTICO»)
local ACCENTS = { ["á"] = "Á", ["é"] = "É", ["í"] = "Í", ["ó"] = "Ó", ["ú"] = "Ú", ["ñ"] = "Ñ", ["ü"] = "Ü" }
function UI.upper(text)
	local upper = string.upper(tostring(text))
	return (string.gsub(upper, "\195[\161\169\173\179\186\177\188]", ACCENTS))
end

function UI.hex(color)
	return "#" .. color:ToHex()
end

return UI
