-- VER MARCADOR: la tabla completa en una ventana encima (lo detallado no compite con el momento de la
-- victoria). TU EQUIPO en azul y EQUIPO ENEMIGO en rojo, cada uno ordenado por puntos: puesto,
-- nombre, PUNTOS, KILLS, ASIST., MUERTES; el MVP con su placa y tu fila resaltada. Sin equipos, una
-- sola tabla con todos.
local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)

local Colors = Theme.Colors
local ALLY = Color3.fromRGB(70, 160, 255)
local ENEMY = Color3.fromRGB(240, 70, 70)
local DARK = Color3.fromRGB(16, 14, 8)

local ScoreboardPanel = {}

local COLUMNS = { { "PUNTOS", "Points", 0.16 }, { "KILLS", "Kills", 0.12 }, { "ASIST.", "Assists", 0.12 }, { "MUERTES", "Deaths", 0.14 } }

local function table_(parent, title, color, entries, view, order)
	local panel = C.new("Frame", { Name = "Table_" .. title, BackgroundColor3 = Colors.Bg, BackgroundTransparency = 0.12, BorderSizePixel = 0, Size = UDim2.new(0.5, -6, 1, 0), LayoutOrder = order, Parent = parent }, {
		C.corner(5),
		C.stroke(color, 1.5, 0.3),
	})
	local head = C.new("Frame", { Name = "Head", BackgroundColor3 = color, BackgroundTransparency = 0.25, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40), Parent = panel }, {
		C.corner(5),
		C.new("UIGradient", { Transparency = NumberSequence.new(0, 0.7) }),
	})
	C.text({ Text = title, Role = "TitleItalic", TextSize = 20, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.44, -14, 1, 0), Parent = head })
	local x = 0.46
	for _, col in COLUMNS do
		C.text({ Text = col[1], Role = "Title", TextSize = 12, Color = Colors.Text, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(col[3], 0, 1, 0), Parent = head })
		x += col[3]
	end
	local list = C.new("Frame", { Name = "Rows", BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 44), Size = UDim2.new(1, -8, 1, -48), Parent = panel }, { C.list(2) })
	for i, entry in entries do
		if i > 10 then
			break
		end
		local me = entry.Id == view.Me.Id
		local row = C.new("Frame", { Name = "Row", BackgroundColor3 = me and color or Colors.PanelLight, BackgroundTransparency = me and 0.55 or (i % 2 == 0 and 0.75 or 0.6), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = i, Parent = list }, { C.corner(3) })
		C.text({ Text = tostring(i), Role = "TitleItalic", TextSize = 18, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Center, Size = UDim2.new(0, 34, 1, 0), Parent = row })
		local nameLabel = C.text({ Text = (entry.Bot and "🤖 " or "") .. C.short(entry.Name, 22), Role = "Title", TextSize = 16, Color = me and Colors.YellowText or Colors.White, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(0.46, -40, 1, 0), Parent = row })
		if entry.Id == view.MVP then
			nameLabel.Size = UDim2.new(0.46, -86, 1, 0)
			local mvp = C.new("Frame", { BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.46, -4, 0.5, 0), Size = UDim2.fromOffset(40, 20), Parent = row }, { C.corner(3) })
			C.text({ Text = "MVP", Role = "TitleItalic", TextSize = 13, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = mvp })
		end
		local cx = 0.46
		for _, col in COLUMNS do
			C.text({ Text = tostring(entry[col[2]] or 0), Role = "Number", TextSize = 16, Color = col[2] == "Points" and Colors.White or Colors.Text, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(cx, 0, 0, 0), Size = UDim2.new(col[3], 0, 1, 0), Parent = row })
			cx += col[3]
		end
	end
	return panel
end

function ScoreboardPanel.new(parent)
	local overlay = C.new("Frame", { Name = "Scoreboard", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.15, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 1, Parent = parent })
	-- (clic fuera: cerrar)
	local blocker = C.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = overlay })
	local window = C.new("Frame", { Name = "Window", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -60, 0, 470), Parent = overlay })
	local title = C.text({ Name = "Title", Text = "MARCADOR", Role = "TitleItalic", TextSize = 34, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -150, 0, 40), Parent = window })
	local close = C.button({ Name = "Close", Text = "CERRAR", Icon = "✕", Style = "Ghost", TextSize = 15, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(130, 38), Parent = window, Sound = "Back" })
	local tables = C.new("Frame", { Name = "Tables", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), Parent = window }, {
		C.list(12, Enum.FillDirection.Horizontal),
	})
	local api = { Frame = overlay }
	function api.Set(view)
		for _, child in tables:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		title.Text = "MARCADOR  ·  " .. C.upper(view.ModeName) .. "  ·  " .. C.upper(view.Map)
		if view.TeamMode then
			table_(tables, "TU EQUIPO", ALLY, view.Allies, view, 1)
			table_(tables, "EQUIPO ENEMIGO", ENEMY, view.Enemies, view, 2)
		else
			local t = table_(tables, "CLASIFICACIÓN", ALLY, view.Allies, view, 1)
			t.Size = UDim2.fromScale(1, 1)
		end
	end
	function api.Open()
		overlay.Visible = true
		Transition.Pop(window, 0.94, 0.2)
	end
	function api.Close()
		overlay.Visible = false
	end
	function api.Layout(phone)
		window.Size = UDim2.new(1, phone and -24 or -60, 0, phone and 410 or 470)
	end
	blocker.Activated:Connect(api.Close)
	close.Activated:Connect(api.Close)
	return api
end

return ScoreboardPanel
