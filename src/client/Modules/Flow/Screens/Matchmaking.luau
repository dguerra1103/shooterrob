-- MATCHMAKING: "BUSCANDO PARTIDA" con el modo, 5 VS 5, el ping, el tiempo buscando y un escáner
-- (líneas que barren y un pulso, nada de rueda girando). Es la espera real del servidor: si hay una
-- partida en marcha, entras enseguida; si está en el descanso entre partidas, votas aquí el mapa de
-- la siguiente (las tres opciones del servidor) y se ve cuánto falta. CANCELAR vuelve al lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local Flow = script.Parent.Parent

-- "5 VS 5" solo en los modos por equipos (no en Todos contra todos ni en Escalada de armas)
local ModeSettings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig")).ModeSettings
local function versus(modeName)
	for _, mode in ModeSettings do
		if mode.Name == modeName and mode.Teams == false then
			return ""
		end
	end
	return "  ·  5 VS 5"
end
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)

local player = Players.LocalPlayer
local Colors = Theme.Colors

local Matchmaking = {}

local cancelButton
local flow, screen, panel, timerLabel, modeLabel, statusLabel, pingLabel, scanBar, pulse, votesRow
local voteCards = {}
local myVote
local startedAt = 0
local connection

local function voteOptions()
	local list = {}
	for i = 1, 3 do
		local map = ReplicatedStorage:GetAttribute("Vote" .. i .. "_Map")
		if map then
			list[i] = { Map = map, Mode = ReplicatedStorage:GetAttribute("Vote" .. i .. "_Mode") or "", Count = ReplicatedStorage:GetAttribute("Vote" .. i .. "_Count") or 0 }
		end
	end
	return list
end

local function refreshVotes()
	local options = voteOptions()
	local any = options[1] ~= nil and ReplicatedStorage:GetAttribute("State") == "Intermission"
	votesRow.Visible = any
	local best, bestCount = nil, -1
	for i = 1, 3 do
		local card = voteCards[i]
		local option = options[i]
		card.Frame.Visible = option ~= nil
		if option then
			card.Map.Text = C.upper(option.Map)
			card.Mode.Text = C.upper(option.Mode)
			card.Count.Text = tostring(option.Count) .. (option.Count == 1 and " VOTO" or " VOTOS")
			C.setSelected(card.Frame, myVote == i)
			if option.Count > bestCount then
				best, bestCount = option, option.Count
			end
		end
	end
	-- Modo: el más votado de la siguiente partida, o el de la que está en marcha
	if any and best then
		modeLabel.Text = C.upper(best.Mode) .. versus(best.Mode)
	else
		local modeName = ReplicatedStorage:GetAttribute("ModeName") or "Duelo por equipos"
		modeLabel.Text = C.upper(modeName) .. versus(modeName)
	end
end

local function step()
	if flow.State ~= "Matchmaking" then
		return
	end
	local elapsed = os.clock() - startedAt
	timerLabel.Text = string.format("%02d:%02d", elapsed // 60, elapsed % 60)
	-- Escáner: una línea que barre el panel y un pulso que crece y se desvanece
	local t = (elapsed % 1.6) / 1.6
	scanBar.Position = UDim2.new(t, 0, 0, 0)
	local p = (elapsed % 1.2) / 1.2
	pulse.Size = UDim2.fromOffset(40 + p * 120, 40 + p * 120)
	pulse.BackgroundTransparency = 0.55 + p * 0.45
	local ok, ping = pcall(function()
		return player:GetNetworkPing()
	end)
	pingLabel.Text = ok and ping and string.format("PING %d ms", math.floor(ping * 1000 + 0.5)) or ""
	local state = ReplicatedStorage:GetAttribute("State")
	local loading = ReplicatedStorage:GetAttribute("LoadingMap")
	if loading then
		statusLabel.Text = "Partida encontrada · preparando " .. C.upper(loading)
		-- (si pulsaste JUGAR con el mapa ya construyéndose, el atributo no cambia: no se esperaba a que
		-- acabara la carga para seguir)
		if elapsed >= flow.Times.SearchMin then
			flow.SetState("MatchFound")
		end
	elseif state == "Intermission" then
		local left = ReplicatedStorage:GetAttribute("TimeLeft") or 0
		statusLabel.Text = string.format("Siguiente partida en %d s · elige el mapa", left)
	elseif state == "Ended" then
		statusLabel.Text = "Terminando la partida anterior…"
	else
		statusLabel.Text = "Partida en curso · uniéndote"
		-- Con partida en marcha (sin despliegue): entra en cuanto se ha visto que busca
		if elapsed >= flow.Times.SearchMin then
			flow.SetState("MatchFound", { Late = ReplicatedStorage:GetAttribute("Deploy") == nil })
		end
	end
end

function Matchmaking.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "Matchmaking", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	panel = C.panel({ Name = "Search", Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.42, -8), Size = UDim2.fromOffset(560, 230), Clip = true, Parent = screen }, { Alpha = 0.08, StrokeColor = Colors.Yellow, StrokeAlpha = 0.55 })
	scanBar = C.new("Frame", { Name = "Scan", BackgroundColor3 = Colors.Yellow, BackgroundTransparency = 0.75, BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, 0), Parent = panel })
	for i = 1, 5 do
		-- Líneas de fondo del escáner (rejilla tenue)
		C.new("Frame", { BackgroundColor3 = Colors.White, BackgroundTransparency = 0.94, BorderSizePixel = 0, Position = UDim2.new(0, 0, i / 6, 0), Size = UDim2.new(1, 0, 0, 1), Parent = panel })
	end
	pulse = C.new("Frame", { Name = "Pulse", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 70, 0.5, 0), Size = UDim2.fromOffset(60, 60), BackgroundColor3 = Colors.Yellow, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = panel }, { C.corner(999) })
	C.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 70, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, Parent = panel }, { C.corner(999) })
	C.text({ Text = "BUSCANDO PARTIDA", Role = "TitleItalic", TextSize = 40, Position = UDim2.fromOffset(140, 26), Size = UDim2.new(1, -160, 0, 46), Parent = panel })
	modeLabel = C.text({ Text = "", Role = "Title", TextSize = 22, Color = Colors.YellowText, Position = UDim2.fromOffset(142, 76), Size = UDim2.new(1, -160, 0, 26), Parent = panel })
	statusLabel = C.text({ Text = "", Role = "BodyBold", TextSize = 15, Color = Colors.TextDim, Position = UDim2.fromOffset(142, 108), Size = UDim2.new(1, -160, 0, 22), Parent = panel })
	timerLabel = C.text({ Text = "00:00", Role = "Number", TextSize = 46, Position = UDim2.fromOffset(142, 140), Size = UDim2.fromOffset(160, 54), Parent = panel })
	pingLabel = C.text({ Text = "", Role = "Number", TextSize = 16, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 160), Size = UDim2.fromOffset(160, 24), Parent = panel })
	-- Votación del mapa de la siguiente partida
	-- (título y tarjetas en un contenedor: la lista solo ordena las tarjetas)
	votesRow = C.new("Frame", { Name = "Votes", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.42, 112), Size = UDim2.fromOffset(780, 140), Parent = screen })
	C.text({ Name = "VotesTitle", Text = "ELIGE EL MAPA DE LA SIGUIENTE PARTIDA", Role = "Title", TextSize = 16, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(600, 20), Parent = votesRow })
	local cardsRow = C.new("Frame", { Name = "Cards", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 104), Parent = votesRow }, {
		C.list(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center),
	})
	for i = 1, 3 do
		local card = C.button({ Name = "Vote" .. i, Text = "", Style = "Menu", Size = UDim2.fromOffset(250, 104), Order = i, Parent = cardsRow, Sound = "Equip", OnClick = function()
			myVote = i
			pcall(function()
				Remotes.VoteMap:FireServer(i)
			end)
			refreshVotes()
		end })
		local map = C.text({ Name = "Map", Text = "", Role = "TitleItalic", TextSize = 24, Scaled = true, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 30), ZIndex = 5, Parent = card })
		local mode = C.text({ Name = "Mode", Text = "", Role = "Title", TextSize = 15, Color = Colors.TextDim, Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -28, 0, 20), ZIndex = 5, Parent = card })
		local count = C.text({ Name = "Count", Text = "", Role = "Number", TextSize = 15, Color = Colors.YellowText, Position = UDim2.fromOffset(14, 72), Size = UDim2.new(1, -28, 0, 20), ZIndex = 5, Parent = card })
		voteCards[i] = { Frame = card, Map = map, Mode = mode, Count = count }
	end
	cancelButton = C.button({ Name = "Cancel", Text = "CANCELAR", Icon = "✕", Style = "Ghost", TextSize = 20, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(220, 52), Parent = screen, Sound = "Back", OnClick = function()
		flow.CancelSearch()
	end })
	ReplicatedStorage.AttributeChanged:Connect(function(name)
		if screen.Visible and (string.sub(name, 1, 4) == "Vote" or name == "State" or name == "ModeName") then
			refreshVotes()
		end
	end)
end

-- Teléfono (pantalla baja): panel más arriba para que quepan los votos y CANCELAR debajo
local function applyLayout()
	local phone = C.Breakpoint() == "PHONE"
	-- (el panel mide 230: acaba en su centro + 115. En escritorio, el título de la votación pisaba el
	-- borde amarillo; ahora queda 5 por debajo en los dos tamaños)
	panel.Position = UDim2.new(0.5, 0, phone and 0.28 or 0.42, phone and 0 or -8)
	votesRow.Position = UDim2.new(0.5, 0, phone and 0.28 or 0.42, phone and 120 or 112)
	cancelButton.Size = UDim2.fromOffset(220, phone and 44 or 52)
	cancelButton.Position = UDim2.new(0.5, 0, 1, phone and -16 or -24)
end

function Matchmaking.Show()
	applyLayout()
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.6)
	Transition.Blur(16, 0.25)
	startedAt = os.clock()
	myVote = nil
	screen.Visible = true
	Transition.Pop(panel, 0.9, 0.22)
	Transition.SlideIn(votesRow, Vector2.new(0, 30), 0.3, 0.05)
	refreshVotes()
	if connection then
		connection:Disconnect()
	end
	connection = RunService.RenderStepped:Connect(step)
	step()
end

function Matchmaking.Hide()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	screen.Visible = false
end

local _ = UISound
return Matchmaking
