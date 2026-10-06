-- ESCUADRA (party): tu personaje delante y los compañeros reales de tu equipo alrededor (hasta 5),
-- cada uno con su nombre, nivel, estado (listo, en el menú, en partida) y el líder (el primero que
-- llegó al servidor). Los amigos que estén en el servidor van en tu equipo (lo hace el servidor) y
-- salen primero. Cuando entra alguien su hueco pasa de vacío a ocupado con una animación corta; si
-- se va, se desvanece. Los huecos libres se rellenan con bots al empezar la partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Preview = require(Flow.Preview)

local player = Players.LocalPlayer
local Colors = Theme.Colors

local Squad = {}

local flow, screen, preview, cardsRow, toast, title
local cards = {} -- [hueco] = api de la tarjeta
local filling = false -- (al abrir la pantalla se rellena sin avisar de "se ha unido")
local shown = {} -- [hueco] = jugador que se ve
local SLOT_ORDER = { "s4", "s2", "me", "s3", "s5" } -- (de izquierda a derecha en pantalla)

-- Compañeros: tu equipo (o, sin equipos, tus amigos y los demás), tú primero, luego amigos
local function members()
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and (player.Team == nil or other.Team == player.Team) then
			table.insert(list, other)
		end
	end
	table.sort(list, function(a, b)
		local fa, fb = player:IsFriendsWith(a.UserId), player:IsFriendsWith(b.UserId)
		if fa ~= fb then
			return fa
		end
		return (a:GetAttribute("JoinOrder") or 0) < (b:GetAttribute("JoinOrder") or 0)
	end)
	local squad = { player }
	for i = 1, math.min(#list, 4) do
		table.insert(squad, list[i])
	end
	return squad
end

local function statusOf(member)
	if member:GetAttribute("Ready") then
		return "Ready"
	elseif member:GetAttribute("InMenu") then
		return "NotReady"
	end
	return "InMatch"
end

local function leaderOf(squad)
	local best, order = nil, math.huge
	for _, member in squad do
		local o = member:GetAttribute("JoinOrder") or math.huge
		if o < order then
			best, order = member, o
		end
	end
	return best
end

local function levelOf(member)
	local stats = member:FindFirstChild("leaderstats")
	local level = stats and stats:FindFirstChild("Nivel")
	return level and level.Value or nil
end

local function showToast(text)
	toast.Text = text
	toast.Visible = true
	toast.TextTransparency = 0
	Transition.Pop(toast, 0.85, 0.15)
	task.delay(1.1, function()
		Transition.Tween(toast, 0.25, { TextTransparency = 1 })
	end)
end

function Squad.Refresh()
	if not screen or not screen.Visible then
		return
	end
	local squad = members()
	local leader = leaderOf(squad)
	local bySlot = { me = squad[1], s2 = squad[2], s3 = squad[3], s4 = squad[4], s5 = squad[5] }
	for _, slot in SLOT_ORDER do
		local member = bySlot[slot]
		local card = cards[slot]
		if member ~= shown[slot] then
			local previous = shown[slot]
			shown[slot] = member
			if member then
				preview:SetCharacter(slot, member)
				preview:SetAnimation(slot, "SquadIdle")
				if previous == nil and member ~= player and not filling then
					-- Entra alguien: su tarjeta aparece y se avisa
					UISound.Play("Join")
					Transition.Pop(card.Frame, 0.8, 0.2)
					showToast("👤 " .. C.upper(member.DisplayName) .. " SE HA UNIDO")
				end
			else
				preview:SetCharacter(slot, nil)
			end
		end
		if member then
			card:Update({
				Name = member.DisplayName,
				Level = levelOf(member),
				Status = statusOf(member),
				Leader = member == leader and #squad > 1,
				Me = member == player,
			})
			card.Frame.BackgroundTransparency = Theme.PanelAlpha
		else
			card:Update({ Name = "HUECO LIBRE", Status = "Bot", Level = nil })
			card.Frame.BackgroundTransparency = 0.6
		end
	end
	local ready = 0
	for _, member in squad do
		if member:GetAttribute("Ready") then
			ready += 1
		end
	end
	title.Text = string.format("ESCUADRA  ·  %d/5", #squad)
	Squad.ReadyCount = ready
end

function Squad.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "Squad", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	preview = Preview.new(screen, { Name = "SquadPreview", Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -90), Size = UDim2.new(1, -40, 1, -150), Camera = "Squad" })
	title = C.text({ Text = "ESCUADRA", Role = "TitleItalic", TextSize = 44, Position = UDim2.fromOffset(28, 18), Size = UDim2.fromOffset(600, 50), Stroke = 2, Parent = screen })
	C.text({ Text = "Tu equipo en este servidor · los amigos juegan contigo · los huecos libres se llenan con bots", Role = "BodyBold", TextSize = 14, Color = Colors.TextDim, Position = UDim2.fromOffset(30, 68), Size = UDim2.new(1, -60, 0, 20), Parent = screen })
	cardsRow = C.new("Frame", {
		Name = "Cards",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -96),
		Size = UDim2.fromOffset(5 * 178, 62),
		Parent = screen,
	}, { C.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center) })
	for i, slot in SLOT_ORDER do
		cards[slot] = C.playerCard({ Size = UDim2.fromOffset(170, 62), Order = i, Parent = cardsRow }, { Name = "", Status = "Bot" })
	end
	toast = C.text({ Name = "Toast", Text = "", Role = "TitleItalic", TextSize = 22, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(600, 30), Stroke = 2, Parent = screen })
	toast.Visible = false
	-- Botones: JUGAR, invitar y volver
	local actions = C.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(760, 64),
		Parent = screen,
	}, { C.list(12, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center) })
	C.button({ Text = "VOLVER", Icon = "‹", Style = "Ghost", TextSize = 20, Size = UDim2.fromOffset(170, 56), Order = 1, Parent = actions, Sound = "Back", OnClick = function()
		flow.SetState("Home")
	end })
	C.button({ Text = "JUGAR", Icon = "▶", Sub = "PARTIDA 5 VS 5", Style = "Primary", TextSize = 30, Size = UDim2.fromOffset(300, 64), Order = 2, Parent = actions, OnClick = function()
		flow.Play()
	end })
	C.button({ Text = "INVITAR", Icon = "✉", Style = "Ghost", TextSize = 20, Size = UDim2.fromOffset(170, 56), Order = 3, Parent = actions, OnClick = function()
		local Home = flow.Screens.Home
		if Home and Home.OpenClan then
			flow.SetState("Home")
			Home.OpenClan()
		end
	end })
	-- Cambios en la escuadra: entra o sale alguien, cambia de equipo o de estado
	local function watch(other)
		for _, attr in { "Ready", "InMenu", "JoinOrder" } do
			other:GetAttributeChangedSignal(attr):Connect(Squad.Refresh)
		end
		other:GetPropertyChangedSignal("Team"):Connect(Squad.Refresh)
		other.CharacterAdded:Connect(function()
			task.wait(1)
			if shown.me == other or table.find({ shown.s2, shown.s3, shown.s4, shown.s5 }, other) then
				-- (personaje nuevo: se vuelve a copiar)
				for slot, member in shown do
					if member == other then
						shown[slot] = nil
					end
				end
				Squad.Refresh()
			end
		end)
	end
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerAdded:Connect(function(other)
		watch(other)
		task.wait(0.5)
		Squad.Refresh()
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(Squad.Refresh)
	end)
	local _ = GameConfig
end

function Squad.Show()
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.55)
	Transition.Blur(14, 0.25)
	screen.Visible = true
	table.clear(shown)
	preview:Clear()
	preview:SetActive(true)
	filling = true
	Squad.Refresh()
	filling = false
	Transition.SlideIn(cardsRow, Vector2.new(0, 40), 0.3)
	Transition.Pop(preview.Viewport, 0.95, 0.25)
end

function Squad.Hide()
	preview:SetActive(false)
	-- (las copias de los personajes no se guardan ocultas: se rehacen al volver)
	preview:Clear()
	table.clear(shown)
	screen.Visible = false
end

return Squad
