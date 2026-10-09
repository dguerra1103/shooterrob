-- Tarjeta de controles para jugadores nuevos: la primera vez que entran en partida ven los controles
-- básicos (adaptados a PC o a móvil). Se cierra con el botón o a los 20 s y no vuelve a salir
-- (el servidor guarda TutorialDone).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Tutorial = {}

local PC_TIPS = {
	{ "🖱", "Clic izquierdo dispara · clic derecho apunta" },
	{ "⌨", "WASD te mueve · Shift corre · C te agacha (corriendo, te desliza)" },
	{ "⚡", "E impulso · Z supersalto · X poción" },
	{ "🔪", "1 2 3 o rueda: cambiar arma · R recargar · F golpe · G granada" },
	{ "🛒", "B abre la tienda, el pase y los retos" },
	{ "📋", "Tab marcador · H regalo 🎁 · J grafiti 🎨" },
}
local TOUCH_TIPS = {
	{ "🕹", "Joystick a la izquierda para moverte" },
	{ "🔫", "Disparar: el botón grande de la derecha · Apuntar a su izquierda" },
	{ "⚡", "Encima del joystick: impulso, supersalto, poción y granada" },
	{ "⬆", "Saltar y agacharte junto a Disparar · Recargar debajo de Apuntar" },
	{ "🔄", "Abajo, la tarjeta del arma: tócala para cambiar de arma" },
	{ "⚙", "Arriba a la derecha: menú y tienda, marcador, emotes y grafiti" },
}

local shown = false

local function show()
	if shown then
		return
	end
	shown = true
	-- Mientras se lee: ratón libre y visible, sin disparar
	ClientState.TutorialOpen = true
	ClientState.UpdateMouse()
	local touch = InputMode.TouchUI()
	local gui = UI.new("ScreenGui", {
		Name = "Tutorial",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 7, -- (por encima de la tienda)
		Parent = player:WaitForChild("PlayerGui"),
	})
	local card = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(520, 400),
		BackgroundColor3 = Color3.fromRGB(20, 22, 36),
		BackgroundTransparency = 0.08,
		Parent = gui,
	}, { UI.corner(18), UI.stroke(Color3.fromRGB(255, 205, 60), 3, 0) })
	local scale = UI.new("UIScale", { Scale = 0.6, Parent = card })
	local viewport = workspace.CurrentCamera.ViewportSize
	local fit = math.clamp(math.min((viewport.X - 20) / 520, (viewport.Y - 20) / 400), 0.45, 1)
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = fit }):Play()
	UI.label({
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "¡BIENVENIDO A LA PELEA!",
		TextSize = 32,
		TextColor3 = Color3.fromRGB(255, 210, 60),
		Parent = card,
	})
	for i, tip in touch and TOUCH_TIPS or PC_TIPS do
		local row = UI.new("Frame", {
			Position = UDim2.fromOffset(24, 60 + (i - 1) * 46),
			Size = UDim2.new(1, -48, 0, 40),
			BackgroundColor3 = Color3.fromRGB(40, 44, 70),
			BackgroundTransparency = 0.2,
			Parent = card,
		}, { UI.corner(10) })
		UI.label({ Size = UDim2.fromOffset(44, 40), Text = tip[1], TextSize = 24, Parent = row })
		UI.label({
			Position = UDim2.fromOffset(48, 0),
			Size = UDim2.new(1, -56, 1, 0),
			Text = tip[2],
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = row,
		})
	end
	local button = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(220, 46),
		Text = "¡A JUGAR!",
		TextSize = 24,
		BackgroundColor3 = Color3.fromRGB(70, 200, 90),
		Parent = card,
	}, { UI.gloss() })
	-- El botón Modal libera el ratón mientras se lee (en primera persona está bloqueado)
	button.Modal = true
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		ClientState.TutorialOpen = false
		ClientState.UpdateMouse()
		Sounds.Play("Click")
		Remotes.TutorialDone:FireServer()
		TweenService:Create(scale, TweenInfo.new(0.2), { Scale = 0 }):Play()
		task.delay(0.25, function()
			gui:Destroy()
		end)
	end
	button.Activated:Connect(close)
	task.delay(20, close)
	-- Se quita si mueres o vuelves a la pantalla de inicio
	task.spawn(function()
		while not closed do
			if ClientState.Dead or ClientState.InMainMenu then
				close()
			end
			task.wait(0.2)
		end
	end)
end

function Tutorial.Init()
	task.spawn(function()
		-- Cuando sale de la pantalla de inicio por primera vez y sus datos dicen que es nuevo
		while not shown do
			task.wait(0.5)
			local data = ClientState.Data
			if data and data.TutorialDone == false and not ClientState.InMainMenu and not ClientState.Dead then
				task.wait(1.5) -- que primero vea el mapa
				if not ClientState.InMainMenu and not ClientState.Dead then
					show()
				end
			elseif data and data.TutorialDone then
				return
			end
		end
	end)
end

return Tutorial
