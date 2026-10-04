-- Ruleta diaria (Shop.Wheel): un giro gratis al día y giros extra con Robux. La ruleta gira y se para
-- en el premio que decide el servidor. Las probabilidades se ven debajo de la ruleta.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Shop = require(Shared.Shop)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Wheel = {}

local SIZE = 340
local gui, panel, rotor, spinButton, buyButton, status, closeButton
local spinning = false
local currentRotation = 0

local function prizes()
	return Shop.Wheel.Prizes
end

-- Texto del botón según los giros disponibles
local function refresh()
	if not gui then
		return
	end
	local data = ClientState.Data
	local free = data and data.WheelFree == true
	local bought = data and data.WheelSpins or 0
	if spinning then
		spinButton.Text = "..."
	elseif free then
		spinButton.Text = "🎁 ¡GIRO GRATIS!"
	elseif bought > 0 then
		spinButton.Text = "🎡 GIRAR (" .. bought .. ")"
	else
		spinButton.Text = "Vuelve mañana"
	end
	spinButton.BackgroundColor3 = (free or bought > 0) and Color3.fromRGB(60, 200, 90) or Color3.fromRGB(70, 70, 82)
	local canBuy = Shop.Wheel.SpinProductId ~= 0 and not (data and data.CratesRestricted)
	buyButton.Visible = canBuy
end

local function build()
	gui = UI.new("ScreenGui", {
		Name = "Wheel",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local shade = UI.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Modal = true,
		Parent = gui,
	})
	_ = shade
	panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 600),
		BackgroundColor3 = Color3.fromRGB(22, 24, 38),
		Parent = gui,
	}, { UI.corner(18), UI.stroke(Color3.fromRGB(255, 200, 60), 3, 0) })
	local scale = UI.new("UIScale", { Parent = panel })
	local function fit()
		local viewport = workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(math.min((viewport.X - 20) / 440, (viewport.Y - 20) / 600), 0.45, 1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()
	UI.label({ Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 36), Text = "🎡 RULETA DIARIA", TextSize = 30, TextColor3 = Color3.fromRGB(255, 210, 60), Parent = panel })
	closeButton = UI.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 36), Text = "✕", TextSize = 22, BackgroundColor3 = Color3.fromRGB(200, 60, 70), Parent = panel })
	closeButton.Activated:Connect(function()
		if not spinning then
			Wheel.Close()
		end
	end)

	-- Ruleta: un círculo (CanvasGroup redondo que recorta) con una porción por premio
	local wheelFrame = UI.new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 66),
		Size = UDim2.fromOffset(SIZE, SIZE),
		BackgroundColor3 = Color3.fromRGB(40, 44, 70),
		Parent = panel,
	}, { UI.corner(SIZE / 2) })
	rotor = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = wheelFrame })
	local list = prizes()
	local step = 360 / #list
	-- Cada porción es un abanico de barras finas que salen del centro (parece una cuña)
	local BARS = 10
	local radius = SIZE / 2 + 2
	for i, prize in list do
		local angle = (i - 1) * step
		for k = 1, BARS do
			local sub = angle - step / 2 + (k - 0.5) * step / BARS
			local rad = math.rad(sub)
			UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.sin(rad) * radius / 2, 0.5, -math.cos(rad) * radius / 2),
				Size = UDim2.fromOffset(math.ceil(2 * radius * math.sin(math.rad(step / BARS / 2))) + 2, radius),
				Rotation = sub,
				BackgroundColor3 = prize.Color,
				BorderSizePixel = 0,
				Parent = rotor,
			})
		end
		-- Separador blanco entre porciones
		local edge = math.rad(angle - step / 2)
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.sin(edge) * radius / 2, 0.5, -math.cos(edge) * radius / 2),
			Size = UDim2.fromOffset(3, radius),
			Rotation = angle - step / 2,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = rotor,
		})
		-- Premio escrito a lo largo del radio
		local rad = math.rad(angle)
		UI.label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.sin(rad) * radius * 0.62, 0.5, -math.cos(rad) * radius * 0.62),
			Size = UDim2.fromOffset(84, 26),
			Rotation = angle, -- (el ganador queda arriba y se lee derecho)
			Text = Shop.WheelPrizeText(prize),
			TextSize = 20,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
			Parent = rotor,
		})
	end
	-- Centro y puntero
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(56, 56),
		BackgroundColor3 = Color3.fromRGB(255, 210, 60),
		ZIndex = 6,
		Parent = wheelFrame,
	}, { UI.corner(28), UI.stroke(Color3.new(1, 1, 1), 3, 0) })
	UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.fromOffset(40, 40),
		Text = "▼",
		TextSize = 40,
		TextColor3 = Color3.fromRGB(255, 70, 90),
		ZIndex = 8,
		Parent = panel,
	})

	-- Probabilidades
	local total = 0
	for _, prize in list do
		total += prize.Weight
	end
	local odds = {}
	for _, prize in list do
		table.insert(odds, Shop.WheelPrizeText(prize) .. " " .. string.format("%g", math.floor(prize.Weight / total * 1000 + 0.5) / 10) .. "%")
	end
	UI.label({
		Position = UDim2.fromOffset(16, 416),
		Size = UDim2.new(1, -32, 0, 40),
		Text = "Probabilidades: " .. table.concat(odds, " · "),
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(180, 185, 210),
		Font = UI.FontBody,
		TextStrokeTransparency = 1,
		Parent = panel,
	})
	status = UI.label({ Position = UDim2.fromOffset(0, 460), Size = UDim2.new(1, 0, 0, 30), Text = "", TextSize = 22, TextColor3 = Color3.fromRGB(255, 220, 90), Parent = panel })

	spinButton = UI.button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 496),
		Size = UDim2.fromOffset(260, 46),
		Text = "",
		TextSize = 24,
		Parent = panel,
	}, { UI.gloss() })
	buyButton = UI.button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 548),
		Size = UDim2.fromOffset(260, 36),
		Text = "+" .. Shop.Wheel.SpinsPerPurchase .. " giros · " .. Shop.Wheel.SpinRobux .. " R$",
		TextSize = 18,
		BackgroundColor3 = Color3.fromRGB(40, 170, 90),
		Parent = panel,
	}, { UI.gloss() })
	buyButton.Activated:Connect(function()
		Sounds.Play("Click")
		pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, Shop.Wheel.SpinProductId)
	end)
	spinButton.Activated:Connect(Wheel.Spin)
	ClientState.DataChanged.Event:Connect(refresh)
end

function Wheel.Spin()
	if spinning then
		return
	end
	local data = ClientState.Data
	if not data or not (data.WheelFree or (data.WheelSpins or 0) > 0) then
		status.Text = "Vuelve mañana para otro giro gratis"
		return
	end
	spinning = true
	status.Text = ""
	refresh()
	Sounds.Play("Click")
	local ok, success, index = pcall(function()
		return Remotes.SpinWheel:InvokeServer()
	end)
	if not (ok and success and type(index) == "number") then
		spinning = false
		status.Text = (ok and type(index) == "string") and index or "No se pudo girar"
		refresh()
		return
	end
	-- Para con el premio arriba (bajo el puntero), tras unas vueltas
	local step = 360 / #prizes()
	local target = -((index - 1) * step) + (math.random() - 0.5) * step * 0.6
	local base = currentRotation - currentRotation % 360
	local final = base + 360 * 5 + target
	currentRotation = final
	local tween = TweenService:Create(rotor, TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = final })
	tween:Play()
	-- Clic de la ruleta al pasar las porciones
	task.spawn(function()
		local last = math.floor(rotor.Rotation / step)
		while tween.PlaybackState == Enum.PlaybackState.Playing do
			local now = math.floor(rotor.Rotation / step)
			if now ~= last then
				last = now
				Sounds.Play("Click", nil, 1.4, 0.6)
			end
			task.wait()
		end
	end)
	tween.Completed:Wait()
	local prize = prizes()[index]
	Sounds.Play(prize.Jackpot and "Flag" or "Kill")
	status.Text = (prize.Jackpot and "💥 ¡PREMIO GORDO! " or "¡Has ganado ") .. Shop.WheelPrizeText(prize) .. (prize.Jackpot and "" or "!")
	spinning = false
	refresh()
end

function Wheel.Open()
	if not gui then
		build()
	end
	gui.Enabled = true
	ClientState.WheelOpen = true
	ClientState.UpdateMouse()
	status.Text = ""
	refresh()
end

function Wheel.Close()
	if gui then
		gui.Enabled = false
	end
	ClientState.WheelOpen = false
	ClientState.UpdateMouse()
end

function Wheel.Init()
	-- (se construye la primera vez que se abre)
end

return Wheel
