-- Retos del día siempre a la vista (izquierda de la pantalla), con barra de progreso que se llena al
-- jugar y un aviso dorado al completarlos. Se oculta en la pantalla de inicio y al morir.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Sounds = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Sounds"))

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local QuestTracker = {}

local gui, panel
local rows = {} -- [índice] = { Frame, Text, Fill, Count, Check, Done, Progress }

local GREEN = Color3.fromRGB(80, 230, 90)
local GOLD = Color3.fromRGB(255, 205, 60)

local function makeRow(index)
	local frame = UI.new("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	local text = UI.label({
		Size = UDim2.new(1, -40, 0, 20),
		Text = "",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	local count = UI.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(60, 20),
		Text = "",
		TextSize = 15,
		TextColor3 = Color3.fromRGB(210, 215, 230),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})
	local bar = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = Color3.fromRGB(30, 32, 44),
		BackgroundTransparency = 0.2,
		Parent = frame,
	}, { UI.corner(6), UI.stroke(Color3.new(0, 0, 0), 1.5, 0.4) })
	local fill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(70, 170, 255),
		Parent = bar,
	}, { UI.corner(6), UI.gloss() })
	local check = UI.label({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 4, 0, 30),
		Size = UDim2.fromOffset(22, 22),
		Text = "✔",
		TextSize = 20,
		TextColor3 = GREEN,
		Visible = false,
		Parent = frame,
	})
	return { Frame = frame, Text = text, Fill = fill, Count = count, Check = check, Done = nil, Progress = nil }
end

-- Destello dorado cuando se completa un reto
local function celebrate(row)
	Sounds.Play("Flag")
	local flash = UI.new("Frame", {
		Size = UDim2.new(1, 12, 1, 8),
		Position = UDim2.fromOffset(-6, -4),
		BackgroundColor3 = GOLD,
		BackgroundTransparency = 0.35,
		ZIndex = 0,
		Parent = row.Frame,
	}, { UI.corner(8) })
	TweenService:Create(flash, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
	task.delay(1.3, function()
		flash:Destroy()
	end)
end

local function refresh(data)
	local challenges = data and data.Challenges
	local list = challenges and challenges.List or {}
	for i, entry in list do
		local row = rows[i] or makeRow(i)
		rows[i] = row
		row.Frame.Visible = true
		row.Text.Text = entry.Text or ""
		local goal = math.max(1, entry.Goal or 1)
		local progress = math.min(entry.Progress or 0, goal)
		row.Count.Text = entry.Done and "" or (progress .. "/" .. goal)
		row.Check.Visible = entry.Done == true
		row.Text.TextColor3 = entry.Done and GREEN or Color3.new(1, 1, 1)
		local ratio = entry.Done and 1 or progress / goal
		TweenService:Create(row.Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(ratio, 1) }):Play()
		row.Fill.BackgroundColor3 = entry.Done and GREEN or Color3.fromRGB(70, 170, 255)
		-- Solo celebra si lo hemos visto pasar de pendiente a hecho (no al cargar)
		if row.Done == false and entry.Done then
			celebrate(row)
		elseif row.Progress and progress > row.Progress and not entry.Done then
			-- Cada paso del reto se nota: el contador da un salto y la barra destella
			local scale = row.Count:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = row.Count })
			scale.Scale = 1.5
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			row.Fill.BackgroundColor3 = Color3.new(1, 1, 1)
			TweenService:Create(row.Fill, TweenInfo.new(0.4), { BackgroundColor3 = Color3.fromRGB(70, 170, 255) }):Play()
		end
		row.Done = entry.Done == true
		row.Progress = progress
	end
	for i = #list + 1, #rows do
		rows[i].Frame.Visible = false
	end
	panel.Parent.Visible = #list > 0
end

function QuestTracker.Init()
	gui = UI.new("ScreenGui", {
		Name = "QuestTracker",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local holder = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 66, 0.38, 0),
		Size = UDim2.fromOffset(250, 190),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	local scale = UI.new("UIScale", { Parent = holder })
	local function rescale()
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), 0.6, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	UI.label({
		Size = UDim2.new(1, 0, 0, 24),
		Text = "🎯 RETOS DE HOY",
		TextSize = 18,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	panel = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 1, -28),
		BackgroundTransparency = 1,
		Parent = holder,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	ClientState.DataChanged.Event:Connect(refresh)
	refresh(ClientState.Data)
	RunService.Heartbeat:Connect(function()
		gui.Enabled = not ClientState.InMainMenu and not ClientState.Dead and not ClientState.MenuOpen
	end)
end

return QuestTracker
