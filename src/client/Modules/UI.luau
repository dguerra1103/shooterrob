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

function UI.hex(color)
	return "#" .. color:ToHex()
end

return UI
