-- Tarjeta del MVP (o de tu jugador destacado si el MVP es rival): corona y placa amarilla "MVP",
-- nombre y tres cifras grandes (ELIMINACIONES · ASISTENCIAS · PUNTOS). Al destacarlo: destello dorado,
-- brillo que cruza, salto y su sonido.
local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local ItemArt = require(Flow.Store.ItemArt)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Anim = require(script.Parent.Parent.Anim)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)

local MVPCard = {}

function MVPCard.new(parent, opts)
	local card = C.new("Frame", {
		Name = "MVPCard",
		BackgroundColor3 = Color3.fromRGB(22, 19, 8),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Position = UDim2.new(),
		Size = UDim2.fromOffset(250, 112),
		LayoutOrder = opts.Order or 0,
		Parent = parent,
	}, {
		C.corner(5),
		C.new("UIStroke", { Color = Colors.Yellow, Thickness = 2, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		C.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 236, 170), Color3.fromRGB(150, 120, 40)) }),
	})
	-- Su tarjeta de jugador de fondo, suave (el dorado del MVP manda)
	if opts.Entry and opts.Entry.Card and opts.Entry.Card ~= "Default" then
		local art = ItemArt.Card(card, opts.Entry.Card, { Name = "CardArt", Size = UDim2.fromScale(1, 1), ZIndex = 0, BackgroundTransparency = 0.55 })
		local emblem = art:FindFirstChild("Emblem")
		if emblem then
			emblem.TextTransparency = 0.5
		end
	end
	-- Placa con corona arriba, sobresaliendo
	local plate = C.new("Frame", { Name = "Plate", BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(110, 30), ZIndex = 3, Parent = card }, {
		C.corner(3),
		C.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 236, 120), Colors.YellowDark) }),
	})
	local plateText = C.text({ Name = "PlateText", Text = opts.IsMVP and "MVP" or "DESTACADO", Role = "TitleItalic", TextSize = opts.IsMVP and 24 or 17, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = plate })
	local crown = C.text({ Name = "Crown", Text = "👑", TextSize = 30, AlignX = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -16), Size = UDim2.fromOffset(40, 34), ZIndex = 4, Parent = card })
	crown.Visible = opts.IsMVP == true
	local entry = opts.Entry
	C.text({ Name = "PlayerName", Text = (entry.Bot and "🤖 " or "") .. C.short(entry.Name, 18), Role = "TitleItalic", TextSize = 24, Color = opts.Me and Colors.YellowText or Colors.White, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromOffset(10, 14), Size = UDim2.new(1, -20, 0, 28), Stroke = 1, Parent = card })
	local values = {}
	for i, spec in { { "ELIMINACIONES", entry.Kills }, { "ASISTENCIAS", entry.Assists }, { "PUNTOS", entry.Points } } do
		local x = (i - 1) / 3
		values[i] = C.text({ Name = spec[1] .. "Value", Text = "0", Role = "TitleItalic", TextSize = 30, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(x, 0, 0, 46), Size = UDim2.new(1 / 3, 0, 0, 34), Stroke = 1, Parent = card })
		C.text({ Name = spec[1], Text = spec[1], Role = "Title", TextSize = 13, Color = Color3.fromRGB(255, 226, 150), AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(x, 0, 0, 82), Size = UDim2.new(1 / 3, 0, 0, 14), Parent = card })
		if i > 1 then
			C.new("Frame", { BackgroundColor3 = Colors.White, BackgroundTransparency = 0.75, BorderSizePixel = 0, Position = UDim2.new(x, 0, 0, 52), Size = UDim2.fromOffset(1, 40), Parent = card })
		end
	end
	local api = { Frame = card, Plate = plate, Crown = crown }
	-- El momento MVP: salto, destello dorado, brillo, corona y sonido; las cifras cuentan
	function api.Highlight(token)
		Transition.Pop(card, 1.25, 0.28)
		Transition.Pop(plate, 0.4, 0.25, 0.08)
		if crown.Visible then
			Transition.Pop(crown, 0.2, 0.3, 0.12)
		end
		Anim.Glow(card, Colors.Yellow, 0.55, 0.5)
		task.delay(0.15, function()
			Anim.Sheen(card, 0.6)
		end)
		UISound.Play(opts.IsMVP and "MVP" or "Reward")
		Anim.Count(values[1], 0, entry.Kills or 0, 0.6, "%d", token)
		Anim.Count(values[2], 0, entry.Assists or 0, 0.6, "%d", token)
		Anim.Count(values[3], 0, entry.Points or 0, 0.8, "%d", token)
	end
	-- (sin animación: cifras finales)
	function api.Final()
		values[1].Text = tostring(entry.Kills or 0)
		values[2].Text = tostring(entry.Assists or 0)
		values[3].Text = tostring(entry.Points or 0)
	end
	local _ = plateText
	return api
end

return MVPCard
