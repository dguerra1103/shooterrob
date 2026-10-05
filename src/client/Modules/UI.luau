-- Pequeña utilidad para crear interfaces desde código.
local UI = {}

-- Letra de la interfaz: Oswald en negrita (condensada y sobria, como la de los shooters militares).
-- Enum.Font solo da el peso normal: cualquier texto con UI.Font pasa a la versión en negrita.
UI.Font = Enum.Font.Oswald
UI.FontBody = Enum.Font.GothamBold
local okBold, OSWALD_BOLD = pcall(function()
	return Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
end)
UI.FontFace = okBold and OSWALD_BOLD or nil

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
	if UI.FontFace and (className == "TextLabel" or className == "TextButton" or className == "TextBox") and inst.Font == UI.Font then
		inst.FontFace = UI.FontFace
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

-- Texto con borde negro (se lee sobre cualquier fondo)
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
	UI.pressFeel(button)
	return button
end

-- Respuesta al tocar un botón: crece un poco al pasar el ratón, se hunde al pulsar y vuelve al soltar
-- (rápido y pequeño: se nota sin distraer)
local PRESS_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
function UI.pressFeel(button)
	local TweenService = game:GetService("TweenService")
	local scale = Instance.new("UIScale")
	scale.Name = "PressScale"
	scale.Parent = button
	-- (Roblox usa una sola UIScale por objeto: si el botón trae su propia animación de escala, p. ej.
	-- un latido, esa manda y esta se quita)
	local yielded = false
	local watch
	watch = button.ChildAdded:Connect(function(child)
		if child:IsA("UIScale") and child ~= scale then
			yielded = true
			watch:Disconnect()
			scale:Destroy()
		end
	end)
	local hovering, pressed = false, false
	local function go(info)
		if yielded then
			return
		end
		local target = pressed and 0.94 or (hovering and 1.04 or 1)
		TweenService:Create(scale, info, { Scale = target }):Play()
	end
	button.MouseEnter:Connect(function()
		local UserInputService = game:GetService("UserInputService")
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			return -- (en el móvil MouseLeave casi nunca llega: se quedaría grande)
		end
		hovering = true
		go(RELEASE_INFO)
	end)
	button.MouseLeave:Connect(function()
		hovering, pressed = false, false
		go(RELEASE_INFO)
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			go(PRESS_INFO)
			-- (si el dedo se suelta fuera del botón, p. ej. al deslizar una lista, InputEnded no llega:
			-- se vigila el propio toque)
			local changed
			changed = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
				if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
					changed:Disconnect()
					if pressed then
						pressed = false
						if input.UserInputType == Enum.UserInputType.Touch then
							hovering = false
						end
						go(RELEASE_INFO)
					end
				end
			end)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressed = false
			-- (en el móvil no hay "pasar por encima": al soltar vuelve a su tamaño)
			if input.UserInputType == Enum.UserInputType.Touch then
				hovering = false
			end
			go(RELEASE_INFO)
		end
	end)
	return scale
end

function UI.formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

-- Espera a que la cámara sepa el tamaño de la pantalla (al arrancar puede valer 0 un instante y el
-- móvil se confundía con un ordenador: minimapa y paneles salían a tamaño de escritorio)
local viewportWaited = false
function UI.WaitViewport(timeout)
	-- (solo la primera vez se espera: si la pantalla no llega a saberse, los demás no esperan otra vez)
	if viewportWaited then
		return
	end
	local deadline = os.clock() + (timeout or 2)
	while os.clock() < deadline do
		local camera = workspace.CurrentCamera
		local size = camera and camera.ViewportSize
		if typeof(size) == "Vector2" and size.Y > 2 then
			viewportWaited = true
			return
		end
		task.wait(0.05)
	end
	viewportWaited = true
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
local topbarBottom = nil
function UI.TopbarBottom()
	-- (se guarda el primer valor bueno: así el minimapa, el regalo y el evento quedan alineados)
	if topbarBottom then
		return topbarBottom
	end
	local ok, inset = pcall(function()
		return game:GetService("GuiService").TopbarInset
	end)
	if ok and typeof(inset) == "Rect" and inset.Height > 0 then
		topbarBottom = math.floor(inset.Max.Y) + 6
		return topbarBottom
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

-- Color de equipo para la interfaz: los colores puros de Roblox (rojo 255,0,0 y azul 0,0,255) se ven
-- baratos y el azul apenas se lee sobre fondo oscuro. Se suavizan (el azul tira a celeste) y, para
-- textos, se aclaran
function UI.teamTint(color, forText)
	if typeof(color) ~= "Color3" then
		return color
	end
	local h, sat, v = color:ToHSV()
	if h > 0.58 and h < 0.72 then
		h = 0.6 -- (azul puro → azul más claro y legible)
	end
	if forText then
		return Color3.fromHSV(h, math.min(sat, 0.62), math.max(v, 0.95))
	end
	return Color3.fromHSV(h, math.min(sat, 0.8), math.min(math.max(v, 0.55), 0.9))
end

function UI.hex(color)
	return "#" .. color:ToHex()
end

return UI
