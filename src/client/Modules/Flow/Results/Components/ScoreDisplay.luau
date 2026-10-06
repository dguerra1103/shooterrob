-- Marcador principal: "100 TU EQUIPO | 72 EQUIPO ENEMIGO" (azul y rojo) con los números contando
-- desde 0. En los modos de pocas rondas (Buscar y destruir: 4-2) van de uno en uno. En todos contra
-- todos: tus bajas y las del líder (o del segundo, si el líder eres tú).
local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local Anim = require(script.Parent.Parent.Anim)

local Colors = Theme.Colors
local ALLY = Color3.fromRGB(70, 160, 255)
local ENEMY = Color3.fromRGB(240, 70, 70)

local ScoreDisplay = {}

function ScoreDisplay.new(parent)
	local root = C.new("Frame", {
		Name = "ScoreDisplay",
		BackgroundColor3 = Colors.Bg,
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(420, 118),
		Parent = parent,
	}, { C.corner(6), C.stroke(Colors.Line, 1, 0.85) })
	-- Mitades con un degradado de su color
	local function half(xScale, color)
		local frame = C.new("Frame", { BackgroundColor3 = color, BackgroundTransparency = 0.78, BorderSizePixel = 0, Position = UDim2.fromScale(xScale, 0), Size = UDim2.fromScale(0.5, 1), Parent = root }, {
			C.corner(6),
			C.new("UIGradient", { Rotation = xScale == 0 and 0 or 180, Transparency = NumberSequence.new(0, 1) }),
		})
		return frame
	end
	half(0, ALLY)
	half(0.5, ENEMY)
	local mine = C.text({ Name = "MyScore", Text = "0", Role = "TitleItalic", TextSize = 72, Color = Color3.fromRGB(150, 205, 255), AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromScale(0, 0.04), Size = UDim2.new(0.5, 0, 0, 76), Stroke = 2, Parent = root })
	local enemy = C.text({ Name = "EnemyScore", Text = "0", Role = "TitleItalic", TextSize = 72, Color = Color3.fromRGB(255, 120, 120), AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.new(0.5, 0, 0, 76), Stroke = 2, Parent = root })
	local myLabel = C.text({ Name = "MyLabel", Text = "TU EQUIPO", Role = "Title", TextSize = 17, Color = ALLY, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 1, -32), Size = UDim2.new(0.5, 0, 0, 22), Parent = root })
	local enemyLabel = C.text({ Name = "EnemyLabel", Text = "EQUIPO ENEMIGO", Role = "Title", TextSize = 17, Color = ENEMY, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(0.5, 0, 1, -32), Size = UDim2.new(0.5, 0, 0, 22), Parent = root })
	C.new("Frame", { Name = "Divider", BackgroundColor3 = Colors.White, BackgroundTransparency = 0.7, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 2, 0.62, 0), Parent = root })
	local vs = C.text({ Name = "VS", Text = "VS", Role = "TitleItalic", TextSize = 18, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 24), Parent = root })
	vs.BackgroundColor3 = Colors.Bg
	vs.BackgroundTransparency = 0

	local view
	local api = { Frame = root }
	function api.Set(v)
		view = v
		mine.Text = "0"
		enemy.Text = "0"
		if v.TeamMode then
			myLabel.Text = "TU EQUIPO"
			enemyLabel.Text = "EQUIPO ENEMIGO"
		else
			myLabel.Text = "TUS BAJAS"
			enemyLabel.Text = (v.Allies[1] and v.Allies[1].Id == v.Me.Id) and "2.º PUESTO" or "LÍDER"
		end
	end
	function api.Play(token)
		Transition.SlideIn(root, Vector2.new(60, 0), 0.3)
		local time = view.SmallScore and 0.6 or 0.9
		Anim.Count(mine, 0, view.MyScore or 0, time, "%d", token, "Tick")
		Anim.Count(enemy, 0, view.EnemyScore or 0, time, "%d", token, nil)
		-- El ganador late al acabar de contar
		task.delay(time + 0.05, function()
			if not Anim.Alive(token) then
				return
			end
			if view.Outcome == "Victory" then
				Transition.Pulse(mine, 1.18, 0.25)
			elseif view.Outcome == "Defeat" then
				Transition.Pulse(enemy, 1.12, 0.25)
			end
		end)
	end
	function api.Layout(phone)
		root.Size = UDim2.fromOffset(phone and 300 or 420, phone and 84 or 118)
		for _, label in { mine, enemy } do
			label.TextSize = phone and 48 or 72
			label.Size = UDim2.new(0.5, 0, 0, phone and 52 or 76)
		end
		for _, label in { myLabel, enemyLabel } do
			label.TextSize = phone and 13 or 17
			label.Position = UDim2.new(label.Position.X.Scale, 0, 1, phone and -24 or -32)
		end
	end
	return api
end

return ScoreDisplay
