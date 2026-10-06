-- Cabecera de la pantalla final: "5V5 · DUELO POR EQUIPOS / MAPA: X", el VICTORIA / DERROTA enorme
-- (blanco con brillo azul si ganas; gris con un toque rojo si pierdes: sin dramatismo) y el motivo
-- del final que manda el servidor (LÍMITE DE PUNTOS ALCANZADO, BOMBA DESACTIVADA...).
local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)

local Colors = Theme.Colors

local ResultHeader = {}

local TITLES = { Victory = "VICTORIA", Defeat = "DERROTA", Draw = "EMPATE" }

-- "LÍMITE DE PUNTOS" → "L Í M I T E   D E   P U N T O S" (por caracteres UTF-8: las tildes enteras)
function ResultHeader.Spaced(text)
	local chars = {}
	for _, code in utf8.codes(text) do
		table.insert(chars, utf8.char(code))
	end
	return table.concat(chars, " ")
end

function ResultHeader.new(parent)
	local root = C.new("Frame", { Name = "ResultHeader", BackgroundTransparency = 1, Size = UDim2.fromOffset(640, 190), Parent = parent })
	-- Etiqueta de modo y mapa (barra amarilla a la izquierda)
	local tag = C.new("Frame", { Name = "ModeTag", BackgroundColor3 = Colors.Bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, Position = UDim2.new(), Size = UDim2.fromOffset(330, 44), Parent = root }, {
		C.new("Frame", { BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, 0) }),
	})
	local modeLabel = C.text({ Name = "Mode", Text = "", Role = "TitleItalic", TextSize = 17, Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -18, 0, 20), Parent = tag })
	local mapLabel = C.text({ Name = "Map", Text = "", Role = "Title", TextSize = 13, Color = Colors.TextDim, Position = UDim2.fromOffset(12, 23), Size = UDim2.new(1, -18, 0, 17), Parent = tag })
	-- Título enorme
	local title = C.text({ Name = "Title", Text = "", Role = "TitleItalic", TextSize = 118, Color = Colors.White, Position = UDim2.fromOffset(-4, 42), Size = UDim2.new(1, 0, 0, 116), Parent = root })
	title.TextScaled = true
	C.new("UITextSizeConstraint", { MaxTextSize = 118, MinTextSize = 40, Parent = title })
	local stroke = C.new("UIStroke", { Thickness = 3, Color = Color3.fromRGB(4, 12, 30), Transparency = 0.15, Parent = title })
	local gradient = C.new("UIGradient", { Rotation = 90, Parent = title })
	-- Raya de acento y motivo
	local bar = C.new("Frame", { Name = "Accent", BorderSizePixel = 0, Position = UDim2.fromOffset(2, 160), Size = UDim2.fromOffset(420, 3), Parent = root }, {
		C.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	local reason = C.text({ Name = "Reason", Text = "", Role = "TitleItalic", TextSize = 21, Color = Colors.Text, Position = UDim2.fromOffset(4, 165), Size = UDim2.new(1, 0, 0, 24), Stroke = 1, Parent = root })

	local api = { Frame = root, Title = title, Reason = reason, Tag = tag }
	function api.Set(view)
		modeLabel.Text = (view.TeamMode and "5V5  ·  " or "") .. C.upper(view.ModeName)
		mapLabel.Text = "MAPA: " .. C.upper(view.Map)
		title.Text = TITLES[view.Outcome] or "FIN"
		-- (letras separadas: se lee como un rótulo)
		reason.Text = ResultHeader.Spaced(view.Reason or "")
		if view.Outcome == "Victory" then
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(226, 238, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 175, 255)),
			})
			stroke.Color = Color3.fromRGB(6, 22, 60)
			bar.BackgroundColor3 = Colors.Blue
		elseif view.Outcome == "Defeat" then
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(232, 232, 236)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(196, 196, 204)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 110, 110)),
			})
			stroke.Color = Color3.fromRGB(34, 10, 12)
			bar.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
		else
			gradient.Color = ColorSequence.new(Color3.fromRGB(240, 240, 244), Color3.fromRGB(190, 192, 200))
			stroke.Color = Colors.Black
			bar.BackgroundColor3 = Colors.TextDim
		end
	end
	-- Entrada: el título cae grande y se asienta; luego el motivo
	function api.Play()
		root.Visible = true
		Transition.SlideIn(tag, Vector2.new(-40, 0), 0.3)
		Transition.Pop(title, 1.7, 0.32)
		bar.Size = UDim2.fromOffset(0, 3)
		Transition.Tween(bar, 0.45, { Size = UDim2.fromOffset(420, 3) })
		reason.TextTransparency = 1
		task.delay(0.22, function()
			Transition.Tween(reason, 0.3, { TextTransparency = 0 })
		end)
	end
	function api.Layout(phone)
		root.Size = UDim2.fromOffset(phone and 460 or 640, phone and 132 or 190)
		title.Position = UDim2.fromOffset(-3, phone and 36 or 42)
		title.Size = UDim2.new(1, 0, 0, phone and 74 or 116)
		bar.Position = UDim2.fromOffset(2, phone and 110 or 160)
		reason.Position = UDim2.fromOffset(4, phone and 113 or 165)
		reason.TextSize = phone and 15 or 21
		tag.Size = UDim2.fromOffset(phone and 260 or 330, phone and 34 or 44)
		modeLabel.TextSize = phone and 14 or 17
		mapLabel.Position = UDim2.fromOffset(12, phone and 18 or 23)
		mapLabel.TextSize = phone and 11 or 13
	end
	return api
end

return ResultHeader
