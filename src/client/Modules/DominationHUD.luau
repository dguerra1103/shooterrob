-- Dominio: las tres banderas (A, B, C) arriba, debajo del marcador. Cada una con el color de su
-- dueño, una barra con la captura en curso (del color de quien la captura) y "!" si está disputada.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local DominationHUD = {}

local LETTERS = { "A", "B", "C" }
local NEUTRAL = Color3.fromRGB(70, 72, 80)

local gui
local badges = {}

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
	local row = UI.new("Frame", {
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
