-- Icono propio delante de un texto. Roblox no admite imágenes dentro de una línea de texto, así que
-- los rótulos que empezaban por un emoji ("💰 1500", "💣 G") se enlazan aquí: mientras el texto
-- empiece por ese emoji, se quita del texto y se dibuja la imagen en su sitio, pegada al texto
-- (alineado a la izquierda o centrado). Si el texto deja de empezar por el emoji, la imagen se esconde.
--   IconText.Bind(label, "💰", Icons.Coin)
local IconText = {}

local GAP = 4

function IconText.Bind(label, emoji, image, scale)
	if not (label and label:IsA("TextLabel")) or type(image) ~= "string" or image == "" then
		return
	end
	local icon = Instance.new("ImageLabel")
	icon.Name = "IconText"
	icon.BackgroundTransparency = 1
	icon.Image = image
	icon.ScaleType = Enum.ScaleType.Fit
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.ZIndex = label.ZIndex
	icon.Visible = false
	icon.Parent = label
	local padding = Instance.new("UIPadding")
	padding.Name = "IconTextPadding"
	padding.Parent = label

	local busy = false
	local function place()
		local side = math.floor(label.TextSize * (scale or 1.15) + 0.5)
		local pad = side + GAP
		if not icon.Visible then
			padding.PaddingLeft = UDim.new(0, 0)
			return
		end
		padding.PaddingLeft = UDim.new(0, pad)
		icon.Size = UDim2.fromOffset(side, side)
		-- (los hijos se colocan dentro del relleno: la X se mide desde donde empieza el texto útil)
		-- (antes de dibujarse por primera vez el rótulo aún no tiene medidas)
		local size, bounds = label.AbsoluteSize, label.TextBounds
		local width = size and size.X or 0
		local textWidth = bounds and bounds.X or 0
		local inner = math.max(0, width - pad)
		local start = 0
		if label.TextXAlignment == Enum.TextXAlignment.Center then
			start = math.max(0, (inner - textWidth) / 2)
		elseif label.TextXAlignment == Enum.TextXAlignment.Right then
			start = math.max(0, inner - textWidth)
		end
		icon.Position = UDim2.new(0, start - pad, 0.5, 0)
	end

	local function refresh()
		if busy then
			return
		end
		local text = label.Text
		local prefix = emoji .. " "
		if string.sub(text, 1, #prefix) == prefix then
			busy = true
			label.Text = string.sub(text, #prefix + 1)
			busy = false
			icon.Visible = true
		elseif string.sub(text, 1, #emoji) == emoji then
			busy = true
			label.Text = string.sub(text, #emoji + 1)
			busy = false
			icon.Visible = true
		else
			-- (un texto nuevo sin el emoji: fuera la imagen)
			icon.Visible = false
		end
		place()
	end

	label:GetPropertyChangedSignal("Text"):Connect(function()
		if not busy then
			refresh()
		end
	end)
	label:GetPropertyChangedSignal("TextBounds"):Connect(place)
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	refresh()
	return icon
end

return IconText
