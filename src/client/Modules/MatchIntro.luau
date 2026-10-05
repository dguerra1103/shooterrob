-- Presentación de la partida (como en los shooters de móvil): al empezar cada ronda, unos segundos
-- con el mapa y el modo arriba y los dos equipos enfrentados (jugadores y bots; tú en amarillo).
-- En todos contra todos, la lista de participantes. Se va sola y no bloquea nada.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)
local RewardFX = require(script.Parent.RewardFX)

local player = Players.LocalPlayer

local MatchIntro = {}

local SHOW_TIME = 4.5
local MAX_ROWS = 6

local gui, panel, title, subtitle, columns
local showToken = 0

-- Miembros de cada equipo: { [nombreEquipo] = { { Name, Me, Bot } } }
local function rosters()
	local byTeam = {}
	local function add(teamName, entry)
		byTeam[teamName] = byTeam[teamName] or {}
		table.insert(byTeam[teamName], entry)
	end
	for _, other in Players:GetPlayers() do
		if not other:GetAttribute("InMenu") or other == player then
			add(other.Team and other.Team.Name or "", { Name = other.DisplayName, Me = other == player })
		end
	end
	local stats = ReplicatedStorage:FindFirstChild("BotStats")
	if stats then
		for _, entry in stats:GetChildren() do
			add(entry:GetAttribute("Team") or "", { Name = entry.Name, Bot = true })
		end
	end
	for _, list in byTeam do
		table.sort(list, function(a, b)
			if a.Me ~= b.Me then
				return a.Me == true
			end
			if (a.Bot == true) ~= (b.Bot == true) then
				return not a.Bot
			end
			return a.Name < b.Name
		end)
	end
	return byTeam
end

local function fillColumn(column, list, color)
	for _, child in column:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for i, entry in list do
		if i > MAX_ROWS then
			break
		end
		UI.label({
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 30),
			Text = (entry.Bot and "🤖 " or "") .. entry.Name,
			TextSize = 22,
			TextColor3 = entry.Me and Color3.fromRGB(255, 225, 80) or Color3.new(1, 1, 1),
			BackgroundTransparency = 0.15,
			BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.62),
			Parent = column,
		}, { UI.corner(6) })
	end
end

local function refresh()
	local byTeam = rosters()
	local teamMode = ReplicatedStorage:GetAttribute("TeamMode") == true
	if teamMode then
		local nameA = ReplicatedStorage:GetAttribute("TeamA") or ""
		local nameB = ReplicatedStorage:GetAttribute("TeamB") or ""
		local teamA, teamB = Teams:FindFirstChild(nameA), Teams:FindFirstChild(nameB)
		local colorA = teamA and teamA:IsA("Team") and teamA.TeamColor.Color or Color3.fromRGB(220, 50, 50)
		local colorB = teamB and teamB:IsA("Team") and teamB.TeamColor.Color or Color3.fromRGB(50, 110, 230)
		columns.Left.Header.Text = "EQUIPO " .. UI.upper(nameA)
		columns.Left.Bar.BackgroundColor3 = colorA
		columns.Right.Header.Text = "EQUIPO " .. UI.upper(nameB)
		columns.Right.Bar.BackgroundColor3 = colorB
		fillColumn(columns.Left.List, byTeam[nameA] or {}, colorA)
		fillColumn(columns.Right.List, byTeam[nameB] or {}, colorB)
		columns.Versus.Text = string.format("%d  VS  %d", #(byTeam[nameA] or {}), #(byTeam[nameB] or {}))
		columns.Right.Frame.Visible = true
	else
		local everyone = {}
		for _, list in byTeam do
			for _, entry in list do
				table.insert(everyone, entry)
			end
		end
		columns.Left.Header.Text = "TODOS CONTRA TODOS"
		columns.Left.Bar.BackgroundColor3 = Color3.fromRGB(255, 210, 90)
		fillColumn(columns.Left.List, everyone, Color3.fromRGB(90, 90, 100))
		columns.Versus.Text = #everyone .. " EN PARTIDA"
		columns.Right.Frame.Visible = false
	end
end

function MatchIntro.Show()
	if ClientState.InMainMenu then
		return
	end
	showToken += 1
	local token = showToken
	title.Text = UI.upper(ReplicatedStorage:GetAttribute("MapName") or "")
	-- (con la versión de luz del mapa si ha tocado una: "Atardecer", "Niebla"...)
	local map = workspace:FindFirstChild("Map")
	local variant = map and map:GetAttribute("Variant")
	local icons = { Atardecer = "🌅 ", Noche = "🌙 ", Niebla = "🌫 ", Tormenta = "⛈ ", ["Mediodía"] = "☀ ", Ventisca = "❄ " }
	subtitle.Text = (ReplicatedStorage:GetAttribute("ModeName") or "") .. (variant and ("  ·  " .. (icons[variant] or "") .. tostring(variant)) or "")
	refresh()
	gui.Enabled = true
	panel.GroupTransparency = 1
	TweenService:Create(panel, TweenInfo.new(0.35), { GroupTransparency = 0 }):Play()
	-- (los bots van entrando en el primer segundo: la lista se actualiza mientras se ve)
	task.spawn(function()
		local finish = os.clock() + SHOW_TIME
		while os.clock() < finish and token == showToken do
			task.wait(0.4)
			refresh()
		end
		if token ~= showToken then
			return
		end
		TweenService:Create(panel, TweenInfo.new(0.5), { GroupTransparency = 1 }):Play()
		task.wait(0.5)
		if token == showToken then
			gui.Enabled = false
			-- ¡A por ellos! (solo si la partida sigue en marcha)
			-- (no en Eliminación, Buscar y destruir ni Infección: ahí el servidor ya anuncia «¡YA!»,
			-- «ATACAS/DEFIENDES» o la fase de esconderse)
			local mode = ReplicatedStorage:GetAttribute("Mode")
			if ReplicatedStorage:GetAttribute("State") == "Playing" and not ClientState.InMainMenu
				and mode ~= "ELIM" and mode ~= "SND" and mode ~= "INF" and not ReplicatedStorage:GetAttribute("Frozen") then
				RewardFX.Punch("¡A LUCHAR!", Color3.fromRGB(255, 220, 90))
			end
		end
	end)
end

local function column(name, anchorX)
	local frame = UI.new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(anchorX, 0),
		Position = UDim2.new(anchorX == 0 and 0.08 or 0.92, 0, 0, 120),
		Size = UDim2.new(0.34, 0, 0, 260),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	local header = UI.label({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		TextSize = 28,
		Parent = frame,
	})
	local bar = UI.new("Frame", {
		Name = "Bar",
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 4),
		BorderSizePixel = 0,
		Parent = frame,
	})
	local list = UI.new("Frame", {
		Name = "List",
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 1, -42),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }) })
	return { Frame = frame, Header = header, Bar = bar, List = list }
end

function MatchIntro.Init()
	gui = UI.new("ScreenGui", {
		Name = "MatchIntro",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 8,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	panel = UI.new("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 12, 16),
		BackgroundTransparency = 0.12,
		GroupTransparency = 1,
		Parent = gui,
	})
	title = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 30),
		Size = UDim2.new(0.8, 0, 0, 50),
		Text = "",
		TextSize = 44,
		Parent = panel,
	})
	subtitle = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 80),
		Size = UDim2.new(0.8, 0, 0, 30),
		Text = "",
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 210, 90),
		Parent = panel,
	})
	columns = {
		Left = column("Left", 0),
		Right = column("Right", 1),
		Versus = UI.label({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 200),
			Size = UDim2.fromOffset(200, 50),
			Text = "VS",
			TextSize = 36,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Parent = panel,
		}),
	}
	local lastState = ReplicatedStorage:GetAttribute("State")
	ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
		local state = ReplicatedStorage:GetAttribute("State")
		if state == "Playing" and lastState ~= "Playing" then
			task.delay(0.8, MatchIntro.Show)
		elseif state ~= "Playing" then
			showToken += 1
			gui.Enabled = false
		end
		lastState = state
	end)
end

return MatchIntro
