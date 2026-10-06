-- PRESENTACIÓN DEL MAPA: nombre del mapa muy grande, modo en una placa amarilla, 5 VS 5, versión de
-- luz (atardecer, noche) y la descripción, con la cámara pasando por encima del mapa real. Mientras
-- el servidor construye el mapa nuevo el fondo queda oscuro con la tarjeta; en cuanto existe, se ve
-- el mapa detrás. Dura lo que tarda la preparación real (con un mínimo para que se lea).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)

local Colors = Theme.Colors

local MapIntro = {}

local flow, screen, block, nameLabel, modePlate, modeLabel, infoLabel, descLabel, statusLabel
local shownAt = 0
local token = 0

local VARIANT_ICONS = { Atardecer = "🌇", Noche = "🌙", ["Día"] = "☀", ["Mediodía"] = "☀", Niebla = "🌫", Tormenta = "⛈" }

local function refresh()
	local loading = ReplicatedStorage:GetAttribute("LoadingMap")
	local name = loading or ReplicatedStorage:GetAttribute("MapName") or ""
	nameLabel.Text = C.upper(name)
	local mode = ReplicatedStorage:GetAttribute("ModeName") or ""
	modeLabel.Text = C.upper(mode)
	modePlate.Visible = not loading and mode ~= ""
	local map = workspace:FindFirstChild("Map")
	local variant = map and map:GetAttribute("Variant")
	infoLabel.Text = "5 VS 5" .. (variant and not loading and ("   ·   " .. (VARIANT_ICONS[variant] or "") .. " " .. C.upper(variant)) or "")
	descLabel.Text = loading and "" or tostring(ReplicatedStorage:GetAttribute("MapDescription") or "")
	statusLabel.Text = loading and "CONSTRUYENDO EL MAPA…" or "PREPARANDO PARTIDA…"
	-- Sin mapa (se está construyendo): fondo oscuro; con mapa: se ve la pasada de cámara
	flow.SetBackdrop(loading and 0.85 or 0.2, 0.4)
end

function MapIntro.ReadyToLeave()
	return os.clock() - shownAt >= flow.Times.MapIntroMin and ReplicatedStorage:GetAttribute("LoadingMap") == nil
end

function MapIntro.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "MapIntro", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	-- Bloque abajo a la izquierda (como un rótulo de cine)
	block = C.new("Frame", { Name = "Block", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 48, 1, -60), Size = UDim2.fromOffset(820, 260), Parent = screen })
	C.new("Frame", { BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(120, 6), Parent = block })
	modePlate = C.new("Frame", { Name = "ModePlate", BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 18), Size = UDim2.fromOffset(330, 36), Parent = block }, { C.corner(3) })
	modeLabel = C.text({ Text = "", Role = "TitleItalic", TextSize = 24, Color = Color3.fromRGB(16, 14, 8), Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Scaled = true, Parent = modePlate })
	nameLabel = C.text({ Text = "", Role = "TitleItalic", TextSize = 104, Color = Colors.White, Position = UDim2.fromOffset(-4, 56), Size = UDim2.new(1, 0, 0, 110), Scaled = true, Stroke = 3, Parent = block })
	infoLabel = C.text({ Text = "", Role = "Title", TextSize = 24, Color = Colors.YellowText, Position = UDim2.fromOffset(2, 166), Size = UDim2.new(1, 0, 0, 28), Stroke = 1, Parent = block })
	descLabel = C.text({ Text = "", Role = "BodyBold", TextSize = 16, Color = Colors.Text, Position = UDim2.fromOffset(2, 198), Size = UDim2.new(0.8, 0, 0, 22), Stroke = 1, Parent = block })
	statusLabel = C.text({ Text = "", Role = "Title", TextSize = 16, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 1), Position = UDim2.new(1, -48, 1, -28), Size = UDim2.fromOffset(400, 22), Parent = screen })
	for _, attr in { "LoadingMap", "MapName", "ModeName", "MapDescription" } do
		ReplicatedStorage:GetAttributeChangedSignal(attr):Connect(function()
			if screen.Visible then
				refresh()
			end
		end)
	end
end

function MapIntro.Show(ctx)
	token += 1
	local my = token
	shownAt = os.clock()
	flow.SetCamera("Flyover")
	Transition.Blur(0, 0.3)
	screen.Visible = true
	refresh()
	UISound.Play("Whoosh")
	Transition.SlideIn(block, Vector2.new(-80, 0), 0.4)
	Transition.Pop(nameLabel, 1.08, 0.5)
	-- Salida: quien entra con la partida empezada, a su ritmo; si no, cuando el servidor empieza el
	-- despliegue (y ya pasó el mínimo para leer el nombre)
	task.spawn(function()
		while token == my and flow.State == "MapIntro" do
			local deploying = ReplicatedStorage:GetAttribute("Deploy") ~= nil
			local playing = ReplicatedStorage:GetAttribute("State") == "Playing"
			if MapIntro.ReadyToLeave() and (deploying or (ctx.Late and playing)) then
				flow.Advance("MapIntro")
				break
			end
			task.wait(0.1)
		end
	end)
end

function MapIntro.Hide()
	token += 1
	screen.Visible = false
end

return MapIntro
