-- Dominio: las tres banderas (A, B, C) arriba, debajo del marcador. Cada una con el color de su
-- dueño, una barra con la captura en curso (del color de quien la captura) y "!" si está disputada.
-- Pantalla táctil (Fase 12): arriba a la izquierda, bajo el minimapa y más pequeñas, para dejar libre
-- el centro (la mira) y lo de arriba en el centro (marcador y avisos de baja).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)
local HUDZones = require(script.Parent.HUDZones)

local player = Players.LocalPlayer

local DominationHUD = {}

local LETTERS = { "A", "B", "C" }
local NEUTRAL = Color3.fromRGB(70, 72, 80)

local gui
local row
local badges = {}
local touchUI = false
local placedAt

-- Táctil: bajo el minimapa; si ahí tocaría los botones de habilidades (pantallas muy bajas), a la
-- derecha del minimapa
local function placeTouch()
	local top = ClientState.MinimapBottom or 156
	local key = top
	local ok, TouchLayout = pcall(require, script.Parent.TouchLayout)
	local dashTop
	if ok then
		local center, size = TouchLayout.Rect("AbilityDash")
		if center and size then
			dashTop = center.Y - size.Y / 2
			key ..= ":" .. math.floor(dashTop)
		end
	end
	if key == placedAt then
		return
	end
	placedAt = key
	local height = 46 * 0.65
	row.AnchorPoint = Vector2.new(0, 0)
	if dashTop and top + 6 + height > dashTop - 6 then
		row.Position = UDim2.fromOffset((ClientState.MinimapLeft or 14) + (ClientState.MinimapSize or 96) + 8, 60)
	else
		row.Position = UDim2.fromOffset(ClientState.MinimapLeft or 14, top + 6)
	end
end

local function teamColor(name)
	local team = name ~= "" and Teams:FindFirstChild(name or "")
	return team and team:IsA("Team") and team.TeamColor.Color or nil
end

local function update()
	local active = ReplicatedStorage:GetAttribute("Dom_A_Position") ~= nil
	gui.Enabled = active and not ClientState.InMainMenu
	if not gui.Enabled then
		return
	end
	if touchUI and not HUDZones.Enabled() then
		placeTouch()
	end
	for _, letter in LETTERS do
		local badge = badges[letter]
		local prefix = "Dom_" .. letter .. "_"
		local owner = ReplicatedStorage:GetAttribute(prefix .. "Owner") or ""
		local capturing = ReplicatedStorage:GetAttribute(prefix .. "Capturing") or ""
		local progress = ReplicatedStorage:GetAttribute(prefix .. "Progress") or 0
		local contested = ReplicatedStorage:GetAttribute(prefix .. "Contested") == true
		badge.Box.BackgroundColor3 = teamColor(owner) or NEUTRAL
		local mine = player.Team and owner == player.Team.Name
		badge.Stroke.Color = mine and Color3.fromRGB(255, 255, 255) or Color3.new(0, 0, 0)
		badge.Bar.Visible = capturing ~= "" and progress > 0
		badge.Bar.Size = UDim2.new(progress, 0, 0, 5)
		badge.Bar.BackgroundColor3 = teamColor(capturing) or Color3.new(1, 1, 1)
		badge.Label.Text = contested and (letter .. "!") or letter
		badge.Label.TextColor3 = contested and Color3.fromRGB(255, 210, 60) or Color3.new(1, 1, 1)
	end
end

function DominationHUD.Init()
	gui = UI.new("ScreenGui", {
		Name = "DominationHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	row = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 118),
		Size = UDim2.fromOffset(3 * 46 + 2 * 8, 46),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
	touchUI = InputMode.TouchUI()
	if touchUI then
		UI.new("UIScale", { Scale = 0.65, Parent = row })
		row:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Left
		-- (Fase 16: su sitio lo da la zona de arriba a la izquierda, bajo el minimapa)
		HUDZones.Register("DomFlags", row, "TOP_LEFT", 1, { Gui = gui })
	end
	for i, letter in LETTERS do
		local stroke = UI.stroke(Color3.new(0, 0, 0), 2, 0)
		local box = UI.new("Frame", {
			Name = letter,
			LayoutOrder = i,
			Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = NEUTRAL,
			Parent = row,
		}, { UI.corner(10), stroke })
		local label = UI.label({
			Size = UDim2.new(1, 0, 1, -4),
			Text = letter,
			TextSize = 28,
			Parent = box,
		})
		local bar = UI.new("Frame", {
			Position = UDim2.new(0, 0, 1, -5),
			Size = UDim2.new(0, 0, 0, 5),
			BorderSizePixel = 0,
			Visible = false,
			Parent = box,
		})
		badges[letter] = { Box = box, Label = label, Bar = bar, Stroke = stroke }
	end
	task.spawn(function()
		while gui.Parent do
			update()
			task.wait(0.15)
		end
	end)
end

DominationHUD.Update = update

return DominationHUD
