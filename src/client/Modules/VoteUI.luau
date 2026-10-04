-- Votación de mapa + modo durante el descanso. Pulsa V (o el botón) para liberar el ratón y votar.
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local VoteUI = {}

local gui, panel, hint, modal
local cards = {}
local myVote = nil
local open = false

local MODE_ICONS = {
	["Duelo por equipos"] = "⚔",
	["Captura la bandera"] = "🚩",
	["Zona de control"] = "◆",
	["Todos contra todos"] = "💀",
	["Escalada de armas"] = "🔫",
	["Eliminación"] = "☠",
	["Infección"] = "🧟",
	["Calabazas"] = "🎃",
}
-- Una línea para quien no conoce el modo
local MODE_HINTS = {
	["Duelo por equipos"] = "Gana el equipo con más bajas",
	["Captura la bandera"] = "Roba la bandera enemiga",
	["Zona de control"] = "Quédate dentro de la zona",
	["Todos contra todos"] = "Cada uno por su cuenta",
	["Escalada de armas"] = "Cada baja te da otra arma",
	["Eliminación"] = "Una sola vida por ronda",
	["Infección"] = "Sobrevive a los zombis",
	["Calabazas"] = "Recoge las calabazas enemigas",
}

local function setOpen(value)
	open = value
	modal.Visible = value
	ClientState.VoteOpen = value
	ClientState.UpdateMouse()
end

local function refresh()
	local voting = ReplicatedStorage:GetAttribute("State") == "Intermission" and ReplicatedStorage:GetAttribute("Vote1_Map") ~= nil
	-- No tapa el menú ni la pantalla de inicio (sus tarjetas se comerían los clics)
	panel.Visible = voting and not ClientState.MenuOpen and not ClientState.InMainMenu
	ClientState.VotePanelVisible = panel.Visible
	hint.Visible = voting and not open and not ClientState.InMainMenu
	if not voting then
		myVote = nil
		if open then
			setOpen(false)
		end
		return
	end
	for i, card in cards do
		local map = ReplicatedStorage:GetAttribute("Vote" .. i .. "_Map") or "?"
		local mode = ReplicatedStorage:GetAttribute("Vote" .. i .. "_Mode") or "?"
		local count = ReplicatedStorage:GetAttribute("Vote" .. i .. "_Count") or 0
		card.Map.Text = map
		card.Mode.Text = (MODE_ICONS[mode] or "") .. " " .. mode
		card.Hint.Text = MODE_HINTS[mode] or ""
		card.Count.Text = tostring(count) .. (count == 1 and " voto" or " votos")
		card.Stroke.Color = myVote == i and Color3.fromRGB(255, 200, 40) or Color3.fromRGB(90, 100, 140)
		card.Stroke.Thickness = myVote == i and 4 or 2
	end
	local timeLeft = ReplicatedStorage:GetAttribute("TimeLeft") or 0
	panel.Title.Text = "VOTA EL SIGUIENTE MAPA · " .. timeLeft .. "s"
end

function VoteUI.Init()
	gui = UI.new("ScreenGui", {
		Name = "Vote",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 6,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.fromOffset(660, 150),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	UI.label({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 28),
		Text = "VOTA EL SIGUIENTE MAPA",
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 210, 60),
		Parent = panel,
	})
	local row = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i = 1, 3 do
		local card = UI.button({
			LayoutOrder = i,
			Size = UDim2.fromOffset(205, 110),
			Text = "",
			BackgroundColor3 = Color3.fromRGB(28, 32, 52),
			Parent = row,
		}, { UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 150, 200)), Rotation = 90 }) })
		local stroke = UI.stroke(Color3.fromRGB(90, 100, 140), 2, 0)
		stroke.Parent = card
		-- Los nombres largos con icono se encogen para caber en la tarjeta
		local mapLabel = UI.label({ Position = UDim2.fromOffset(6, 8), Size = UDim2.new(1, -12, 0, 30), Text = "", TextScaled = true, Parent = card }, {
			UI.new("UITextSizeConstraint", { MaxTextSize = 24, MinTextSize = 12 }),
		})
		local modeLabel = UI.label({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 24), Text = "", TextSize = 18, TextColor3 = Color3.fromRGB(150, 220, 255), Parent = card })
		local hintLabel = UI.label({
			Position = UDim2.fromOffset(6, 63),
			Size = UDim2.new(1, -12, 0, 16),
			Text = "",
			TextSize = 13,
			TextColor3 = Color3.fromRGB(190, 195, 220),
			Font = UI.FontBody,
			TextStrokeTransparency = 1,
			Parent = card,
		})
		local countLabel = UI.label({ Position = UDim2.fromOffset(0, 82), Size = UDim2.new(1, 0, 0, 22), Text = "", TextSize = 18, TextColor3 = Color3.fromRGB(255, 210, 60), Parent = card })
		card.Activated:Connect(function()
			myVote = i
			Sounds.Play("Click")
			Remotes.VoteMap:FireServer(i)
			refresh()
		end)
		cards[i] = { Map = mapLabel, Mode = modeLabel, Hint = hintLabel, Count = countLabel, Stroke = stroke }
	end
	hint = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -196),
		Size = UDim2.fromOffset(400, 26),
		Text = "Pulsa [V] para votar con el ratón",
		TextSize = 20,
		Visible = false,
		Parent = gui,
	})
	-- Botón Modal: libera el ratón mientras se vota
	modal = UI.new("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Visible = false, Parent = gui })

	ContextActionService:BindAction("Vote", function(_, state)
		if state == Enum.UserInputState.Begin and panel.Visible and not ClientState.InMainMenu then
			setOpen(not open)
			refresh()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.V, Enum.KeyCode.DPadUp)

	ReplicatedStorage.AttributeChanged:Connect(refresh)
	refresh()
end

return VoteUI
