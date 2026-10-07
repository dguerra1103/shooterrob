-- PRESENTACIÓN DE EQUIPOS: tu equipo a la izquierda y el rival a la derecha, cinco personajes reales
-- de cada lado (copias 3D de los jugadores y de los bots, con su traje y su arma), sus nombres y
-- niveles debajo y VS en medio. Los personajes entran uno a uno (también cuida los móviles: nada de
-- diez modelos de golpe) y los bots, que el servidor crea justo al empezar, aparecen en cuanto
-- llegan. Dura ~3 s; luego, la elección rápida de clase.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Preview = require(Flow.Preview)

local player = Players.LocalPlayer
local Colors = Theme.Colors

local TeamIntro = {}

local flow, screen, vs, sides, ffaList
local token = 0

-- Miembros de un equipo: jugadores (sin los que siguen en el menú) y bots, tú primero
local function roster(teamName)
	local list = {}
	for _, other in Players:GetPlayers() do
		local inGame = not other:GetAttribute("InMenu") or other:GetAttribute("Ready") or other == player
		if other.Team and other.Team.Name == teamName and inGame then
			local stats = other:FindFirstChild("leaderstats")
			local level = stats and stats:FindFirstChild("Nivel")
			table.insert(list, { Name = other.DisplayName, Level = level and level.Value or nil, Source = other, Me = other == player, Card = other:GetAttribute("Card") })
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			if model:GetAttribute("Team") == teamName then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				table.insert(list, { Name = humanoid and humanoid.DisplayName or model.Name, Bot = true, Source = model, Role = model:GetAttribute("Role") })
			end
		end
	end
	table.sort(list, function(a, b)
		if (a.Me == true) ~= (b.Me == true) then
			return a.Me == true
		end
		if (a.Bot == true) ~= (b.Bot == true) then
			return not a.Bot
		end
		return a.Name < b.Name
	end)
	return list
end

local function buildSide(parent, anchorX, posX)
	local side = C.new("Frame", { Name = "Side", BackgroundTransparency = 1, AnchorPoint = Vector2.new(anchorX, 0), Position = UDim2.new(posX, 0, 0, 0), Size = UDim2.new(0.48, 0, 1, 0), Parent = parent })
	local header = C.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 70), Parent = side })
	local tag = C.text({ Name = "Tag", Text = "", Role = "Title", TextSize = 16, Color = Colors.TextDim, AlignX = anchorX == 0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -48, 0, 20), Parent = header })
	local name = C.text({ Name = "TeamName", Text = "", Role = "TitleItalic", TextSize = 46, AlignX = tag.TextXAlignment, Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -48, 0, 50), Stroke = 2, Parent = header })
	local bar = C.new("Frame", { Name = "Bar", BorderSizePixel = 0, AnchorPoint = Vector2.new(anchorX, 0), Position = UDim2.new(anchorX, anchorX == 0 and 24 or -24, 0, 70), Size = UDim2.fromOffset(160, 5), Parent = header })
	local preview = Preview.new(side, { Name = "Lineup", Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 1, -200), Camera = "Lineup" })
	local cards = C.new("Frame", { Name = "Cards", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.new(1, -20, 0, 58), Parent = side }, {
		C.list(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center),
	})
	return { Frame = side, Tag = tag, Name = name, Bar = bar, Preview = preview, Cards = cards, Shown = {}, CardApis = {}, CardColor = nil }
end

local function fill(side, team, isMine, my)
	local color = team and team.TeamColor.Color or Colors.White
	side.Tag.Text = isMine and "TU EQUIPO" or "RIVALES"
	side.Name.Text = team and ("EQUIPO " .. C.upper(team.Name)) or ""
	side.Bar.BackgroundColor3 = color
	local list = team and roster(team.Name) or {}
	-- Tarjetas (siempre 5: los huecos que faltan quedan "esperando"). Se crean una vez por
	-- presentación y después solo se actualizan: antes se destruían y se volvían a crear las diez cada
	-- 0,6 s (parpadeo y objetos nuevos sin necesidad)
	if side.CardColor ~= color or #side.CardApis == 0 then
		for _, child in side.Cards:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(side.CardApis)
		side.CardColor = color
		for i = 1, 5 do
			side.CardApis[i] = C.playerCard({ Size = UDim2.new(0.2, -6, 1, 0), Order = i, Parent = side.Cards }, {
				Name = "…",
				Status = "Loading",
				TeamColor = color,
			})
		end
	end
	for i = 1, 5 do
		local entry = list[i]
		side.CardApis[i]:Update({
			Name = entry and entry.Name or "…",
			Level = entry and entry.Level or nil,
			Status = entry and (entry.Bot and "Bot" or "Ready") or "Loading",
			Me = entry and entry.Me,
			Card = entry and entry.Card,
		})
	end
	-- Personajes: uno a uno (y los que ya estaban no se vuelven a copiar)
	for i = 1, 5 do
		if token ~= my then
			return
		end
		local entry = list[i]
		local slot = "line" .. i
		local source = entry and entry.Source or nil
		if side.Shown[slot] ~= source then
			side.Shown[slot] = source
			side.Preview:SetCharacter(slot, source)
			side.Preview:SetAnimation(slot, "SquadIdle")
			if source then
				task.wait(0.06)
			end
		end
	end
end

function TeamIntro.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "TeamIntro", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	sides = {
		Mine = buildSide(screen, 0, 0),
		Enemy = buildSide(screen, 1, 1),
	}
	vs = C.text({ Name = "VS", Text = "VS", Role = "TitleItalic", TextSize = 96, Color = Colors.Yellow, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(200, 110), Stroke = 3, Parent = screen })
	ffaList = C.text({ Name = "FFA", Text = "", Role = "Title", TextSize = 22, Wrap = true, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.new(0.7, 0, 0, 200), Parent = screen })
end

function TeamIntro.Show(ctx)
	token += 1
	local my = token
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.7, 0.25)
	Transition.Blur(12, 0.25)
	screen.Visible = true
	UISound.Play("Whoosh")
	local teamMode = ReplicatedStorage:GetAttribute("TeamMode") == true
	for _, side in sides do
		side.Frame.Visible = teamMode
		side.Preview:Clear()
		table.clear(side.Shown)
		side.Preview:SetActive(teamMode)
		side.CardColor = nil -- (tarjetas nuevas en cada presentación: el equipo puede ser otro)
	end
	vs.Visible = teamMode
	ffaList.Visible = not teamMode
	if teamMode then
		local mine = player.Team
		local enemy
		for _, team in game:GetService("Teams"):GetChildren() do
			if team ~= mine and (team.Name == ReplicatedStorage:GetAttribute("TeamA") or team.Name == ReplicatedStorage:GetAttribute("TeamB")) then
				enemy = team
			end
		end
		-- Tu equipo entra primero; el rival, un instante después; VS en medio
		Transition.SlideIn(sides.Mine.Frame, Vector2.new(-120, 0), 0.35)
		Transition.SlideIn(sides.Enemy.Frame, Vector2.new(120, 0), 0.35, 0.35)
		Transition.Pop(vs, 2, 0.3, 0.55)
		task.delay(0.55, function()
			if token == my then
				UISound.Play("Countdown", 0.6)
			end
		end)
		task.spawn(function()
			-- (se rellena varias veces: los bots llegan un segundo después de empezar)
			while token == my and flow.State == "TeamIntro" do
				fill(sides.Mine, mine, true, my)
				fill(sides.Enemy, enemy, false, my)
				task.wait(0.6)
			end
		end)
	else
		local names = {}
		for _, other in Players:GetPlayers() do
			table.insert(names, other.DisplayName)
		end
		ffaList.Text = "TODOS CONTRA TODOS\n" .. table.concat(names, "  ·  ")
	end
	-- Siguiente: la elección de clase (o la cuenta atrás si el servidor ya está en ella)
	task.spawn(function()
		local started = os.clock()
		while token == my and flow.State == "TeamIntro" do
			local countdownIn = flow.CountdownIn()
			if os.clock() - started >= flow.Times.TeamIntro then
				flow.Advance("TeamIntro")
				break
			end
			if countdownIn and countdownIn <= 0 then
				flow.SetState("Deploy")
				break
			end
			task.wait(0.1)
		end
	end)
	local _ = ctx
end

function TeamIntro.Hide()
	token += 1
	for _, side in sides do
		side.Preview:SetActive(false)
		-- (diez personajes copiados: fuera en cuanto empieza la partida)
		side.Preview:Clear()
		table.clear(side.Shown)
	end
	screen.Visible = false
end

return TeamIntro
