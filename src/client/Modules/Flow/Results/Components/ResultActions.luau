-- Acciones de abajo: VER MARCADOR (secundaria), ⌂ VOLVER AL LOBBY (grafito) y ▶ JUGAR DE NUEVO
-- (amarillo, la dominante). Como el servidor ya te mete en la siguiente partida, JUGAR DE NUEVO te
-- lleva a buscarla al momento (con la votación del mapa) y, si no tocas nada, se hace solo al acabar
-- la pantalla final: "SIGUIENTE PARTIDA EN 8 s", con CANCELAR para quedarte mirando.
local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Icons = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Icons"))
local Transition = require(Flow.Transition)

local Colors = Theme.Colors

local ResultActions = {}

-- callbacks = { OnScoreboard, OnLobby, OnPlay, OnCancelAuto }
function ResultActions.new(parent, callbacks)
	local root = C.new("Frame", { Name = "ResultActions", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64), Parent = parent })
	local board = C.button({ Name = "Scoreboard", Text = "VER MARCADOR", Icon = Icons.Clipboard, Style = "Ghost", TextSize = 18, Position = UDim2.fromOffset(0, 8), Size = UDim2.fromOffset(230, 52), Parent = root, OnClick = function()
		callbacks.OnScoreboard()
	end })
	local play = C.button({ Name = "PlayAgain", Text = "JUGAR DE NUEVO", Icon = "▶", Sub = "", Style = "Primary", TextSize = 28, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(340, 64), Parent = root, OnClick = function()
		callbacks.OnPlay()
	end })
	local lobby = C.button({ Name = "Lobby", Text = "VOLVER AL LOBBY", Icon = Icons.Home, Style = "Ghost", TextSize = 17, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -352, 0, 8), Size = UDim2.fromOffset(240, 52), Parent = root, Sound = "Back", OnClick = function()
		callbacks.OnLobby()
	end })
	lobby.BackgroundColor3 = Colors.Panel
	local cancel = C.button({ Name = "CancelAuto", Text = "CANCELAR", Icon = "✕", Style = "Ghost", TextSize = 14, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -352, 0, 8), Size = UDim2.fromOffset(120, 52), Parent = root, Sound = "Back", OnClick = function()
		callbacks.OnCancelAuto()
	end })
	local sub = play:FindFirstChild("Sub", true)
	local compact = false
	local api = { Frame = root, Play = play, Lobby = lobby, Board = board, Cancel = cancel }
	-- Cuenta atrás hasta la siguiente partida (nil: sin automático)
	function api.SetCountdown(seconds)
		if sub then
			local left = seconds and math.max(0, math.ceil(seconds))
			sub.Text = left and string.format(compact and "SIGUIENTE EN %d s" or "SIGUIENTE PARTIDA EN %d s", left) or "BUSCAR LA SIGUIENTE PARTIDA"
		end
		cancel.Visible = seconds ~= nil
		-- (sin CANCELAR, VOLVER AL LOBBY se arrima a JUGAR DE NUEVO)
		lobby.Position = UDim2.new(1, cancel.Visible and (compact and -352 or -484) or (compact and -262 or -352), 0, compact and 6 or 8)
	end
	function api.Show()
		root.Visible = true
		Transition.SlideIn(root, Vector2.new(0, 40), 0.3)
		Transition.Pulse(play, 1.08, 0.3)
	end
	function api.Layout(phone)
		board.Size = UDim2.fromOffset(phone and 150 or 230, phone and 44 or 52)
		lobby.Size = UDim2.fromOffset(phone and 170 or 240, phone and 44 or 52)
		play.Size = UDim2.fromOffset(phone and 250 or 340, phone and 56 or 64)
		compact = phone
		cancel.Size = UDim2.fromOffset(phone and 84 or 120, phone and 44 or 52)
		cancel.Position = UDim2.new(1, phone and -262 or -352, 0, phone and 6 or 8)
		lobby.Position = UDim2.new(1, cancel.Visible and (phone and -352 or -484) or (phone and -262 or -352), 0, phone and 6 or 8)
		local cancelLabel = cancel:FindFirstChild("Label", true)
		if cancelLabel then
			cancelLabel.Text = phone and "" or "CANCELAR" -- (en el teléfono basta la ✕)
		end
		root.Size = UDim2.new(1, 0, 0, phone and 56 or 64)
		local label = board:FindFirstChild("Label", true)
		if label then
			label.Text = phone and "MARCADOR" or "VER MARCADOR"
		end
	end
	return api
end

return ResultActions
