-- Tarjeta pequeña debajo de cada personaje: puesto, nombre, bajas, asistencias y puntos. Marco azul
-- (tu equipo) o rojo (rival); la tuya con el nombre en amarillo. El 👍 de reconocimiento solo sale si
-- existe el sistema (GameConfig.ResultsHonor): hoy no lo hay, así que no se enseña.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local UISound = require(Flow.UISound)
local ItemArt = require(Flow.Store.ItemArt)

local Colors = Theme.Colors
local ALLY = Color3.fromRGB(70, 160, 255)
local ENEMY = Color3.fromRGB(240, 70, 70)

local PlayerResultCard = {}

-- Una cifra con su nombre debajo ("18" / "KILLS")
local function stat(parent, name, x, width)
	local value = C.text({ Name = name .. "Value", Text = "0", Role = "Number", TextSize = 19, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(x, 0, 0, 34), Size = UDim2.new(width, 0, 0, 22), Parent = parent })
	C.text({ Name = name, Text = name, Role = "Title", TextSize = 13, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(x, 0, 0, 56), Size = UDim2.new(width, 0, 0, 14), Parent = parent })
	return value
end

-- opts = { Rank, Entry, Enemy, Me, OnHonor }
function PlayerResultCard.new(parent, opts)
	local color = opts.Enemy and ENEMY or ALLY
	local card = C.new("Frame", {
		Name = "PlayerCard",
		BackgroundColor3 = Colors.Bg,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Position = UDim2.new(),
		Size = UDim2.fromOffset(176, 80),
		LayoutOrder = opts.Order or 0,
		Parent = parent,
	}, {
		C.corner(4),
		C.stroke(color, 1.5, 0.25),
		-- (raya de color abajo)
		C.new("Frame", { Name = "Bottom", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 3) }),
	})
	-- Su tarjeta de jugador de fondo (si lleva una)
	if opts.Entry and opts.Entry.Card and opts.Entry.Card ~= "Default" then
		local art = ItemArt.Card(card, opts.Entry.Card, { Name = "CardArt", Size = UDim2.fromScale(1, 1), ZIndex = 0, BackgroundTransparency = 0.25 })
		local emblem = art:FindFirstChild("Emblem")
		if emblem then
			emblem.TextTransparency = 0.6
		end
	end
	local badge = C.new("Frame", { Name = "Rank", BackgroundColor3 = color, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(24, 24), Parent = card }, { C.corner(3) })
	C.text({ Text = tostring(opts.Rank or ""), Role = "TitleItalic", TextSize = 17, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = badge })
	local entry = opts.Entry
	local name = C.text({ Name = "PlayerName", Text = (entry.Bot and "🤖 " or "") .. C.short(entry.Name, 14), Role = "Title", TextSize = 17, Color = opts.Me and Colors.YellowText or Colors.White, Scaled = true, Position = UDim2.fromOffset(36, 6), Size = UDim2.new(1, -44, 0, 24), Parent = card })
	local kills = stat(card, "KILLS", 0, 0.3)
	local assists = stat(card, "ASIST.", 0.3, 0.3)
	local points = stat(card, "PUNTOS", 0.6, 0.4)
	kills.Text = tostring(entry.Kills or 0)
	assists.Text = tostring(entry.Assists or 0)
	points.Text = tostring(entry.Points or 0)
	-- Reconocimiento (preparado; oculto si no hay sistema detrás)
	if GameConfig.ResultsHonor == true and opts.OnHonor and not opts.Me and not entry.Bot then
		local honor = C.new("TextButton", { Name = "Honor", Text = "👍", TextSize = 15, Font = Enum.Font.GothamBold, TextColor3 = Colors.White, BackgroundColor3 = Colors.PanelLight, AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(24, 24), Parent = card }, { C.corner(3) })
		name.Size = UDim2.new(1, -72, 0, 24)
		honor.Activated:Connect(function()
			UISound.Play("Click")
			honor.BackgroundColor3 = Colors.Yellow
			honor.Active = false
			opts.OnHonor(entry)
		end)
	end
	return { Frame = card, Name = name }
end

return PlayerResultCard
