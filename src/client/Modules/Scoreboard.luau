-- Marcador de la partida (mantén Tab; en móvil, botón 📋): los dos equipos en columnas (o una sola
-- lista en los modos sin equipos) con bajas, muertes y puntos. Incluye a los bots (ReplicatedStorage.
-- BotStats, que rellena el servidor) y resalta tu fila. Sustituye a la lista de jugadores de Roblox.
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Scoreboard = {}

local gui, panel, title, columns
local visible = false
local ROW_HEIGHT = 30
local MAX_ROWS = 10

-- Una fila por jugador o bot: { Name, Team, Kills, Deaths, Score, Captures, IsBot, IsMe }
local function collect()
	local rows = {}
	for _, p in Players:GetPlayers() do
		local stats = p:FindFirstChild("leaderstats")
		local kills = stats and stats:FindFirstChild("Bajas")
		local deaths = stats and stats:FindFirstChild("Muertes")
		table.insert(rows, {
			Name = p.DisplayName,
			Team = p.Team,
			Kills = kills and kills.Value or 0,
			Deaths = deaths and deaths.Value or 0,
			Score = p:GetAttribute("Score") or 0,
			Captures = p:GetAttribute("Captures") or 0,
			InMenu = p:GetAttribute("InMenu") == true,
			IsMe = p == player,
		})
	end
	local bots = ReplicatedStorage:FindFirstChild("BotStats")
	if bots then
		for _, entry in bots:GetChildren() do
			local teamName = entry:GetAttribute("Team")
			local team = teamName and teamName ~= "" and Teams:FindFirstChild(teamName) or nil
			table.insert(rows, {
				Name = "🤖 " .. entry.Name,
				Team = team,
				Kills = entry:GetAttribute("Kills") or 0,
				Deaths = entry:GetAttribute("Deaths") or 0,
				Score = entry:GetAttribute("Score") or 0,
				Captures = 0,
				IsBot = true,
			})
		end
	end
	return rows
end

local function header(parent, text, color)
	local bar = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = color,
		Parent = parent,
	}, { UI.corner(8) })
	UI.label({
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Text = text,
		TextSize = 22,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = bar,
	})
	return bar
end

local function columnTitles(parent, y, third)
	local frame = UI.new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	for i, text in { "JUGADOR", "BAJAS", "MUERTES", third } do
		UI.label({
			Position = i == 1 and UDim2.fromOffset(12, 0) or UDim2.new(1, -230 + (i - 2) * 76, 0, 0),
			Size = UDim2.fromOffset(i == 1 and 200 or 76, 22),
			Text = text,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(200, 200, 220),
			TextXAlignment = i == 1 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
			Parent = frame,
		})
	end
end

local function rowFrame(parent, y, row, thirdValue, color)
	local frame = UI.new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT - 2),
		BackgroundColor3 = row.IsMe and Color3.fromRGB(255, 205, 60) or color,
		BackgroundTransparency = row.IsMe and 0.25 or 0.65,
		Parent = parent,
	}, { UI.corner(6) })
	UI.label({
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -250, 1, 0),
		Text = row.Name .. (row.InMenu and "  💤" or ""),
		TextSize = 18,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = row.IsBot and Color3.fromRGB(215, 215, 230) or Color3.new(1, 1, 1),
		Parent = frame,
	})
	for i, value in { row.Kills, row.Deaths, thirdValue } do
		UI.label({
			Position = UDim2.new(1, -230 + (i - 1) * 76, 0, 0),
			Size = UDim2.fromOffset(76, ROW_HEIGHT - 2),
			Text = tostring(value),
			TextSize = 19,
			Parent = frame,
		})
	end
end

-- Columna de un equipo (o de todos en los modos sin equipos)
local function buildColumn(x, width, headerText, headerColor, rows, thirdTitle, thirdOf)
	local column = UI.new("Frame", {
		Position = UDim2.fromOffset(x, 56),
		Size = UDim2.fromOffset(width, 60 + MAX_ROWS * ROW_HEIGHT),
		BackgroundTransparency = 1,
		Parent = columns,
	})
	header(column, headerText, headerColor)
	columnTitles(column, 38, thirdTitle)
	-- Si no caben todos, tu fila siempre sale (en el último hueco)
	local shown = table.move(rows, 1, math.min(#rows, MAX_ROWS), 1, {})
	for i = MAX_ROWS + 1, #rows do
		if rows[i].IsMe then
			shown[MAX_ROWS] = rows[i]
		end
	end
	for i, row in shown do
		rowFrame(column, 60 + (i - 1) * ROW_HEIGHT, row, thirdOf(row), headerColor:Lerp(Color3.new(0, 0, 0), 0.4))
	end
	return column
end

local lastSignature = ""

local function refresh()
	if not visible then
		return
	end
	local mode = ReplicatedStorage:GetAttribute("Mode")
	local teamMode = ReplicatedStorage:GetAttribute("TeamMode") ~= false
	local mapName = ReplicatedStorage:GetAttribute("MapName") or ""
	local modeName = ReplicatedStorage:GetAttribute("ModeName") or ""
	title.Text = string.upper(modeName) .. "  ·  " .. mapName .. "  ·  " .. UI.formatTime(ReplicatedStorage:GetAttribute("TimeLeft") or 0)
	local rows = collect()
	-- Solo se reconstruye si ha cambiado algo (si no, cada medio segundo se crearían ~150 objetos)
	local parts = { tostring(mode), tostring(ReplicatedStorage:GetAttribute("TeamMode")), tostring(ReplicatedStorage:GetAttribute("LeaderName")) }
	for _, row in rows do
		table.insert(parts, string.format("%s/%s/%d/%d/%d/%d/%s", row.Name, tostring(row.Team), row.Kills, row.Deaths, row.Score, row.Captures, tostring(row.InMenu)))
	end
	for _, teamName in { ReplicatedStorage:GetAttribute("TeamA"), ReplicatedStorage:GetAttribute("TeamB") } do
		table.insert(parts, tostring(teamName and ReplicatedStorage:GetAttribute("Score_" .. teamName)))
	end
	local signature = table.concat(parts, "|")
	if signature == lastSignature and #columns:GetChildren() > 0 then
		return
	end
	lastSignature = signature
	columns:ClearAllChildren()
	local thirdTitle, thirdOf = "PUNTOS", function(row)
		return row.Score
	end
	if mode == "CTF" then
		thirdTitle, thirdOf = "CAPTURAS", function(row)
			return row.Captures
		end
	elseif teamMode then
		thirdTitle, thirdOf = "K/D", function(row)
			return string.format("%.1f", row.Kills / math.max(1, row.Deaths))
		end
	end
	local function byKills(a, b)
		if a.Kills ~= b.Kills then
			return a.Kills > b.Kills
		end
		return a.Deaths < b.Deaths
	end
	if teamMode then
		local nameA = ReplicatedStorage:GetAttribute("TeamA")
		local nameB = ReplicatedStorage:GetAttribute("TeamB")
		for i, teamName in { nameA, nameB } do
			local team = teamName and Teams:FindFirstChild(teamName)
			local list = {}
			for _, row in rows do
				if team and row.Team == team then
					table.insert(list, row)
				end
			end
			table.sort(list, byKills)
			local color = team and team:IsA("Team") and team.TeamColor.Color or Color3.fromRGB(80, 80, 100)
			local score = teamName and (ReplicatedStorage:GetAttribute("Score_" .. teamName) or 0) or 0
			local text = string.format("<b>%s</b>   %d", string.upper(teamName or "?"), score)
			buildColumn((i - 1) * 472, 440, text, color, list, thirdTitle, thirdOf)
		end
		panel.Size = UDim2.fromOffset(940, 56 + 60 + MAX_ROWS * ROW_HEIGHT + 16)
	else
		table.sort(rows, function(a, b)
			if a.Score ~= b.Score then
				return a.Score > b.Score
			end
			return byKills(a, b)
		end)
		local leader = ReplicatedStorage:GetAttribute("LeaderName")
		buildColumn(0, 572, "<b>TODOS CONTRA TODOS</b>" .. ((leader and leader ~= "") and ("   👑 " .. leader) or ""), Color3.fromRGB(200, 120, 40), rows, thirdTitle, thirdOf)
		panel.Size = UDim2.fromOffset(600, 56 + 60 + MAX_ROWS * ROW_HEIGHT + 16)
	end
end

local function setVisible(on)
	on = on and not ClientState.InMainMenu
	if on == visible then
		return
	end
	visible = on
	gui.Enabled = on
	refresh()
end

function Scoreboard.Init()
	-- La lista de jugadores de Roblox no enseña a los bots ni los equipos así: se usa esta
	task.spawn(function()
		for _ = 1, 20 do
			if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList, false) then
				return
			end
			task.wait(0.5)
		end
	end)
	gui = UI.new("ScreenGui", {
		Name = "Scoreboard",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 4,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(940, 420),
		BackgroundColor3 = Color3.fromRGB(18, 20, 34),
		BackgroundTransparency = 0.12,
		Parent = gui,
	}, { UI.corner(16), UI.stroke(Color3.new(1, 1, 1), 3, 0.6), UI.padding(14) })
	local scale = UI.new("UIScale", { Parent = panel })
	local function fit()
		local viewport = workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(math.min((viewport.X - 30) / panel.Size.X.Offset, (viewport.Y - 30) / panel.Size.Y.Offset), 0.4, 1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	panel:GetPropertyChangedSignal("Size"):Connect(fit)
	title = UI.label({
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextSize = 26,
		Parent = panel,
	})
	columns = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = panel })
	fit()

	-- Tab: se ve mientras se mantiene pulsado. En móvil el botón 📋 lo abre y lo cierra.
	ContextActionService:BindAction("Scoreboard", function(_, state, input)
		if input.UserInputType == Enum.UserInputType.Touch then
			if state == Enum.UserInputState.Begin then
				setVisible(not visible)
			end
		elseif state == Enum.UserInputState.Begin then
			setVisible(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			setVisible(false)
		end
		return Enum.ContextActionResult.Pass
	end, UserInputService.TouchEnabled, Enum.KeyCode.Tab)
	-- Si la ventana pierde el foco con Tab pulsado, no llega el "soltar": se cierra igualmente
	UserInputService.WindowFocusReleased:Connect(function()
		if not UserInputService.TouchEnabled then
			setVisible(false)
		end
	end)
	ContextActionService:SetTitle("Scoreboard", "📋")
	ContextActionService:SetPosition("Scoreboard", UDim2.new(1, -60, 0, 70))

	task.spawn(function()
		while true do
			task.wait(0.5)
			if visible and ClientState.InMainMenu then
				setVisible(false)
			end
			refresh()
		end
	end)
end

return Scoreboard
