-- Pantalla de inicio: título del juego, cámara girando alrededor del mapa y botones.
-- Mientras está abierta el personaje no se mueve y es invulnerable (escudo del servidor).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)
local Menu = require(script.Parent.Menu)
local WeaponIcon = require(script.Parent.WeaponIcon)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MainMenu = {}

local gui, root, infoLabel, showcase
local blur
local orbitAngle = 0
local controls

local ORBIT_CENTER = Vector3.new(0, 8, 0)
local ORBIT_RADIUS = 150
local ORBIT_HEIGHT = 65

local function getControls()
	if controls then
		return controls
	end
	local ok, result = pcall(function()
		local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		return playerModule:GetControls()
	end)
	if ok then
		controls = result
	end
	return controls
end

local function orbit(dt)
	orbitAngle += dt * 0.06
	local position = ORBIT_CENTER + Vector3.new(math.cos(orbitAngle) * ORBIT_RADIUS, ORBIT_HEIGHT, math.sin(orbitAngle) * ORBIT_RADIUS)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(position, ORBIT_CENTER)
	camera.FieldOfView = 60
end

local function bigButton(text, color, order, parent)
	local button = UI.button({
		LayoutOrder = order,
		Size = UDim2.fromOffset(300, 58),
		Text = text,
		TextSize = 28,
		BackgroundColor3 = color,
		Parent = parent,
	}, { UI.stroke(Color3.new(0, 0, 0), 3, 0), UI.gloss() })
	button.TextStrokeTransparency = 0.5
	local scale = UI.new("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	return button
end

local function refreshInfo()
	local data = ClientState.Data
	if infoLabel then
		infoLabel.Text = data and string.format("Nivel %d   ·   🪙 %d   ·   %d bajas", data.Level, data.Coins, data.TotalKills or 0)
			or "Cargando..."
	end
	-- Arma principal con la skin equipada, a la derecha
	if showcase then
		showcase:ClearAllChildren()
		if data then
			WeaponIcon.Create(data.Primary or "Rifle", data.EquippedSkin, { Size = UDim2.fromScale(1, 1), Parent = showcase }, "angled", 1.6)
		end
	end
end

local function play()
	if not ClientState.InMainMenu then
		return
	end
	Sounds.Play("Click")
	Remotes.LeaveMenu:FireServer()
	TweenService:Create(root, TweenInfo.new(0.35), { GroupTransparency = 1 }):Play()
	showcase.Visible = false
	if blur then
		TweenService:Create(blur, TweenInfo.new(0.35), { Size = 0 }):Play()
	end
	task.delay(0.35, function()
		RunService:UnbindFromRenderStep("MainMenuOrbit")
		ClientState.InMainMenu = false
		gui.Enabled = false
		if blur then
			blur:Destroy()
			blur = nil
		end
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
		local ctrl = getControls()
		if ctrl then
			ctrl:Enable()
		end
		if not Menu.IsOpen() then
			UserInputService.MouseIconEnabled = false
		end
	end)
end

function MainMenu.Init()
	gui = UI.new("ScreenGui", {
		Name = "MainMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 4,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	root = UI.new("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	-- Oscurecido a la izquierda para que se lea el texto
	UI.new("Frame", {
		Size = UDim2.fromScale(0.65, 1),
		BackgroundColor3 = Color3.fromRGB(10, 10, 25),
		BorderSizePixel = 0,
		Parent = root,
	}, {
		UI.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(0.6, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	-- Botón invisible "Modal": libera el ratón aunque la cámara sea en primera persona
	UI.new("TextButton", {
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Modal = true,
		Parent = root,
	})

	local left = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 70, 0.5, 0),
		Size = UDim2.fromOffset(560, 520),
		BackgroundTransparency = 1,
		Parent = root,
	})

	-- Título con degradado y borde grueso
	local title = UI.label({
		Size = UDim2.new(1, 0, 0, 110),
		Text = GameConfig.GameTitle,
		TextSize = 96,
		TextScaled = true,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	}, {
		UI.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 170)),
			}),
			Rotation = 90,
		}),
		UI.new("UIStroke", { Thickness = 6, Color = Color3.fromRGB(30, 10, 40) }),
	})
	local titleScale = UI.new("UIScale", { Parent = title })

	UI.label({
		Position = UDim2.fromOffset(4, 112),
		Size = UDim2.new(1, 0, 0, 30),
		Text = "CAPTURA LA BANDERA  ·  DUELO POR EQUIPOS",
		TextSize = 24,
		TextColor3 = Color3.fromRGB(200, 230, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	})

	local buttons = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 175),
		Size = UDim2.fromOffset(300, 220),
		BackgroundTransparency = 1,
		Parent = left,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local playButton = bigButton("▶  JUGAR", Color3.fromRGB(60, 200, 90), 1, buttons)
	playButton.Size = UDim2.fromOffset(300, 70)
	playButton.TextSize = 36
	playButton.Activated:Connect(play)
	bigButton("⭐  PASE DE BATALLA", Color3.fromRGB(255, 130, 30), 2, buttons).Activated:Connect(function()
		Sounds.Play("Click")
		Menu.Open("Pase")
	end)
	bigButton("🔫  ARMAS Y SKINS", Color3.fromRGB(50, 130, 255), 3, buttons).Activated:Connect(function()
		Sounds.Play("Click")
		Menu.Open("Skins")
	end)

	infoLabel = UI.label({
		Position = UDim2.fromOffset(2, 420),
		Size = UDim2.new(1, 0, 0, 26),
		Text = "Cargando...",
		TextSize = 22,
		TextColor3 = Color3.fromRGB(255, 220, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	})
	UI.label({
		Position = UDim2.fromOffset(2, 452),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "Clic izq. disparar · Clic der. apuntar · Shift correr · C deslizar · B pase",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(190, 195, 215),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	})

	-- Escaparate del arma a la derecha (fuera del CanvasGroup para que el 3D se dibuje siempre)
	showcase = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -60, 0.55, 0),
		Size = UDim2.fromOffset(480, 300),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	-- Desenfoque del fondo
	blur = Instance.new("BlurEffect")
	blur.Name = "MainMenuBlur"
	blur.Size = 10
	blur.Parent = Lighting

	ClientState.InMainMenu = true
	UserInputService.MouseIconEnabled = true
	RunService:BindToRenderStep("MainMenuOrbit", Enum.RenderPriority.Camera.Value + 2, orbit)

	-- El título "respira"
	task.spawn(function()
		while ClientState.InMainMenu do
			TweenService:Create(titleScale, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Scale = 1.04 }):Play()
			task.wait(1.2)
			TweenService:Create(titleScale, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
			task.wait(1.2)
		end
	end)

	-- Bloquea el movimiento del personaje mientras tanto
	task.spawn(function()
		local ctrl = getControls()
		if ctrl and ClientState.InMainMenu then
			ctrl:Disable()
		end
	end)

	ClientState.DataChanged.Event:Connect(refreshInfo)
	refreshInfo()

	-- También se puede empezar con Enter / botón A del mando
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not ClientState.InMainMenu or Menu.IsOpen() then
			return
		end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			play()
		end
	end)
end

return MainMenu
