-- Novedades (GameConfig.News): en la pantalla de inicio, los jugadores que ya habían jugado ven una
-- vez lo nuevo de la actualización. Se cierra con el botón y el servidor lo apunta (NewsSeen).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local News = {}

local shown = false

local function show()
	shown = true
	local news = GameConfig.ActiveNews()
	local height = 120 + #news.Items * 46
	local gui = UI.new("ScreenGui", {
		Name = "News",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 15,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- (Active: tapa los botones de la pantalla de inicio mientras se lee)
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Active = true, Parent = gui })
	local card = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, height),
		BackgroundColor3 = Color3.fromRGB(26, 20, 40),
		Parent = gui,
	}, { UI.corner(18), UI.stroke(Color3.fromRGB(255, 140, 30), 3, 0) })
	local scale = UI.new("UIScale", { Scale = 0.6, Parent = card })
	local viewport = workspace.CurrentCamera.ViewportSize
	local fit = math.clamp(math.min((viewport.X - 20) / 560, (viewport.Y - 20) / height), 0.45, 1)
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = fit }):Play()
	UI.label({ Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 40), Text = news.Title, TextSize = 30, TextColor3 = Color3.fromRGB(255, 170, 50), Parent = card })
	for i, item in news.Items do
		local row = UI.new("Frame", {
			Position = UDim2.fromOffset(20, 62 + (i - 1) * 46),
			Size = UDim2.new(1, -40, 0, 40),
			BackgroundColor3 = Color3.fromRGB(50, 40, 74),
			BackgroundTransparency = 0.2,
			Parent = card,
		}, { UI.corner(10) })
		UI.label({ Size = UDim2.fromOffset(44, 40), Text = item[1], TextSize = 24, Parent = row })
		UI.label({
			Position = UDim2.fromOffset(48, 0),
			Size = UDim2.new(1, -56, 1, 0),
			Text = item[2],
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = row,
		})
	end
	local button = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(220, 44),
		Text = "¡A JUGAR!",
		TextSize = 24,
		BackgroundColor3 = Color3.fromRGB(255, 130, 30),
		Parent = card,
	}, { UI.gloss() })
	button.Modal = true
	ClientState.NewsOpen = true
	ClientState.UpdateMouse()
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		Remotes.NewsSeen:FireServer()
		gui:Destroy()
		ClientState.NewsOpen = false
		ClientState.UpdateMouse()
	end
	button.Activated:Connect(function()
		Sounds.Play("Click")
		close()
	end)
	-- Si empieza la partida con la tarjeta abierta (por ejemplo con el mando), se cierra sola
	task.spawn(function()
		while not closed do
			if not ClientState.InMainMenu then
				close()
			end
			task.wait(0.3)
		end
	end)
end

function News.Init()
	task.spawn(function()
		while not shown do
			task.wait(1)
			local data = ClientState.Data
			local news = GameConfig.ActiveNews()
			if news and data and ClientState.InMainMenu and data.TutorialDone and (data.NewsSeen or 0) < news.Version then
				task.wait(1) -- que primero se vea la pantalla de inicio
				if ClientState.InMainMenu then
					show()
				end
			elseif data and news and (data.NewsSeen or 0) >= news.Version then
				return
			end
		end
	end)
end

return News
