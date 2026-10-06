-- PARTIDA ENCONTRADA: el momento de satisfacción (~1,4 s). Destello, barrido amarillo, golpe de
-- sonido y el panel que entra de golpe con el modo y el mapa. Sigue solo: no hay que pulsar nada.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)

local Colors = Theme.Colors

local MatchFound = {}

local flow, screen, band, title, sub
local token = 0

function MatchFound.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "MatchFound", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	band = C.new("Frame", {
		Name = "Band",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(1.2, 0, 0, 150),
		Rotation = -3,
		BackgroundColor3 = Colors.Bg,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = screen,
	}, { C.stroke(Colors.Yellow, 2, 0.2) })
	-- Franjas amarillas arriba y abajo de la banda
	for _, y in { 0, 1 } do
		C.new("Frame", { AnchorPoint = Vector2.new(0, y), Position = UDim2.fromScale(0, y), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, Parent = band })
	end
	title = C.text({ Text = "PARTIDA ENCONTRADA", Role = "TitleItalic", TextSize = 76, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -16), Size = UDim2.new(0.8, 0, 0, 84), Scaled = true, Stroke = 3, Parent = band })
	sub = C.text({ Text = "", Role = "Title", TextSize = 26, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 44), Size = UDim2.new(0.8, 0, 0, 30), Parent = band })
end

function MatchFound.Show(ctx)
	token += 1
	local my = token
	flow.SetBackdrop(0.55, 0.15)
	screen.Visible = true
	local mapName = ReplicatedStorage:GetAttribute("LoadingMap") or ReplicatedStorage:GetAttribute("MapName") or ""
	local modeName = ReplicatedStorage:GetAttribute("ModeName") or ""
	if ReplicatedStorage:GetAttribute("LoadingMap") then
		-- (el modo aún no está decidido del todo: el del voto ganador llega con el mapa)
		modeName = ""
	end
	sub.Text = C.upper(modeName ~= "" and (modeName .. "  ·  " .. mapName) or mapName) .. "  ·  5 VS 5"
	UISound.MatchFound()
	Transition.Flash(Colors.White, 0.55, 0.35)
	Transition.Wipe(Colors.Yellow, 0.4)
	Transition.Pop(band, 1.25, 0.2)
	Transition.Pop(title, 0.7, 0.25, 0.05)
	task.delay(flow.Times.MatchFound, function()
		if token == my and flow.State == "MatchFound" then
			flow.Advance("MatchFound")
		end
	end)
	local _ = ctx
end

function MatchFound.Hide()
	token += 1
	screen.Visible = false
end

return MatchFound
