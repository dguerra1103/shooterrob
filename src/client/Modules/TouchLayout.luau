-- Botones táctiles del juego. Roblox (ContextActionService) solo crea 7 botones táctiles y los mete
-- en un recuadro del cuarto de abajo a la derecha: en el móvil faltaban la granada, el ataque
-- aéreo, los emotes, el grafiti y el marcador, y los demás salían desordenados. Así que en pantallas
-- táctiles los botones son nuestros: sin límite, con su icono, del tamaño que toca y colocados en la
-- pantalla exactamente donde se dice. Las teclas y el mando siguen con ContextActionService.
--
-- Uso (como ContextActionService): TouchLayout.BindAction(nombre, función, conBotón, teclas...),
-- TouchLayout.SetTitle(nombre, texto) y TouchLayout.Set(nombre, posición). La función recibe
-- (nombre, estado, input) igual que con ContextActionService.
--
-- Posiciones: las del código son las de siempre (pensadas alrededor del botón de saltar de Roblox).
-- En tablet ese botón es más grande y está más arriba y a la izquierda, así que el grupo de abajo a la
-- derecha se corre a la izquierda. En el teléfono hay una disposición propia (PHONE): un racimo
-- ordenado alrededor del botón de saltar, como en los shooters de móvil (disparar grande, apuntar y
-- agacharse a mano del pulgar), sin que ningún botón pise a otro, y los de menos uso (marcador,
-- emotes, grafiti) pequeños arriba a la derecha.
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UI = require(script.Parent.UI)

local TouchLayout = {}

local TABLET_SHIFT_X = -130
local registered = {} -- [acción] = posición pedida por el código
local buttons = {} -- [acción] = { Button, Label, Handler }
local watching = false
local gui

-- Teléfono: { posición en pantalla (esquina de arriba a la izquierda), tamaño }. El salto de Roblox
-- ocupa (1,-95)..(1,-25) de ancho y (1,-90)..(1,-20) de alto.
local BIG, NORMAL, SMALL = 76, 52, 40
local PHONE = {
	Fire = { UDim2.new(1, -180, 1, -176), BIG }, -- (arriba a la izquierda del salto)
	Aim = { UDim2.new(1, -88, 1, -160), NORMAL }, -- (encima del salto)
	Slide = { UDim2.new(1, -168, 1, -84), NORMAL }, -- (a la izquierda del salto)
	Reload = { UDim2.new(1, -244, 1, -150), NORMAL },
	SwapWeapon = { UDim2.new(1, -240, 1, -84), NORMAL },
	Sprint = { UDim2.new(1, -312, 1, -112), NORMAL },
	Melee = { UDim2.new(1, -88, 1, -228), NORMAL },
	Grenade = { UDim2.new(1, -170, 1, -250), NORMAL },
	Airstrike = { UDim2.new(1, -246, 1, -222), NORMAL },
	Scoreboard = { UDim2.new(1, -152, 0, 8), SMALL },
	Emotes = { UDim2.new(1, -106, 0, 8), SMALL },
	Spray = { UDim2.new(1, -60, 0, 8), SMALL },
}
TouchLayout.Phone = PHONE
-- Tablet y pantallas medianas: arriba a la derecha también los de menos uso
local TOP_ROW = {
	Scoreboard = UDim2.new(1, -60, 0, 8),
	Emotes = UDim2.new(1, -112, 0, 8),
	Spray = UDim2.new(1, -164, 0, 8),
}

local function isLarge()
	local size = workspace.CurrentCamera.ViewportSize
	return math.min(size.X, size.Y) > 500
end

local function touchDevice()
	return UserInputService.TouchEnabled
end

local function ensureGui()
	if gui and gui.Parent then
		return gui
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "TouchButtons"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 3
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local function apply(actionName, position)
	local entry = buttons[actionName]
	if not entry then
		return
	end
	local size = NORMAL
	local phoneSpot = UI.IsPhone() and PHONE[actionName]
	if phoneSpot then
		position, size = phoneSpot[1], phoneSpot[2]
	elseif TOP_ROW[actionName] then
		position, size = TOP_ROW[actionName], 46
	elseif isLarge() then
		size = actionName == "Fire" and 90 or 64
		if position.X.Scale == 1 and position.Y.Scale == 1 then
			position = UDim2.new(1, position.X.Offset + TABLET_SHIFT_X, 1, position.Y.Offset)
		end
	elseif actionName == "Fire" then
		size = 64
	end
	entry.Button.Position = position
	entry.Button.Size = UDim2.fromOffset(size, size)
end

-- Botón redondo y translúcido con su icono; mientras se pulsa, más claro
local function createButton(actionName, handler)
	local button = Instance.new("TextButton")
	button.Name = actionName
	button.AutoButtonColor = false
	button.Text = ""
	button.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
	button.BackgroundTransparency = 0.45
	button.Size = UDim2.fromOffset(NORMAL, NORMAL)
	button.Position = UDim2.new(1, -120, 1, -160)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.35
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local label = Instance.new("TextLabel")
	label.Name = "ActionTitle"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.62, 0.62)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Text = ""
	label.Parent = button
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 34
	fit.Parent = label
	-- Pulsar y soltar llaman a la acción como lo haría ContextActionService (con el toque real)
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		button.BackgroundTransparency = 0.15
		task.spawn(handler, actionName, Enum.UserInputState.Begin, input)
		local connection
		connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			local state = input.UserInputState
			if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				connection:Disconnect()
				button.BackgroundTransparency = 0.45
				task.spawn(handler, actionName, state, input)
			end
		end)
	end)
	button.Parent = ensureGui()
	buttons[actionName] = { Button = button, Label = label, Handler = handler }
	-- (que respete enseguida si hay un menú abierto o la pantalla de inicio)
	task.defer(function()
		local ok, ClientState = pcall(require, script.Parent.ClientState)
		if ok and ClientState.UpdateMouse then
			pcall(ClientState.UpdateMouse)
		end
	end)
	if registered[actionName] then
		apply(actionName, registered[actionName])
	end
	return button
end

local function watch()
	if watching then
		return
	end
	watching = true
	local function mode()
		return (UI.IsPhone() and "phone") or (isLarge() and "large") or "normal"
	end
	local was = mode()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local now = mode()
		if now ~= was then
			was = now
			for name, position in registered do
				apply(name, position)
			end
		end
	end)
end

-- Como ContextActionService:BindAction; si conBotón y la pantalla es táctil, el botón es nuestro
function TouchLayout.BindAction(actionName, handler, withButton, ...)
	ContextActionService:BindAction(actionName, handler, false, ...)
	if withButton and touchDevice() then
		if buttons[actionName] then
			buttons[actionName].Button:Destroy()
		end
		createButton(actionName, handler)
		watch()
	end
end

function TouchLayout.UnbindAction(actionName)
	ContextActionService:UnbindAction(actionName)
	local entry = buttons[actionName]
	if entry then
		entry.Button:Destroy()
		buttons[actionName] = nil
	end
end

function TouchLayout.SetTitle(actionName, title)
	local entry = buttons[actionName]
	if entry then
		entry.Label.Text = tostring(title)
	end
end

-- El botón de una acción (nil si no hay: sin pantalla táctil o sin enlazar)
function TouchLayout.GetButton(actionName)
	local entry = buttons[actionName]
	return entry and entry.Button or nil
end

-- Coloca el botón (se ajusta en tablet y teléfono, y al girar la pantalla o cuando se sabe por
-- fin su tamaño: al arrancar puede valer 0)
function TouchLayout.Set(actionName, position)
	registered[actionName] = position
	apply(actionName, position)
	watch()
end

return TouchLayout
