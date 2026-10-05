-- Posición de los botones táctiles (ContextActionService). Las posiciones del código están pensadas
-- para el teléfono, alrededor del botón de saltar de Roblox. En tablet (pantalla grande) ese botón
-- es más grande y está más arriba y a la izquierda (120 px, a 170 de la derecha y 210 de abajo), así
-- que todo el grupo de abajo a la derecha se corre a la izquierda para no taparlo.
-- En el teléfono hay una disposición propia (PHONE): un racimo ordenado alrededor del botón de saltar,
-- como en los shooters de móvil (disparar grande, apuntar y agacharse a mano del pulgar), sin que
-- ningún botón pise a otro, y los botones de menos uso (marcador, emotes, grafiti) pequeños arriba a
-- la derecha.
local ContextActionService = game:GetService("ContextActionService")

local UI = require(script.Parent.UI)

local TouchLayout = {}

local TABLET_SHIFT_X = -130
local registered = {} -- [acción] = posición de teléfono
local watching = false

-- Teléfono: { posición (esquina de arriba a la izquierda), tamaño }. El salto de Roblox ocupa
-- (1,-95)..(1,-25) de ancho y (1,-90)..(1,-20) de alto.
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

local function isLarge()
	local size = workspace.CurrentCamera.ViewportSize
	return math.min(size.X, size.Y) > 500
end

-- El texto del botón se encoge para caber (si no, «Disparar» salía partido en «Dispar / ar»)
local function styleButton(actionName, size)
	pcall(function()
		local button = ContextActionService:GetButton(actionName)
		if not button then
			return
		end
		if size then
			button.Size = UDim2.fromOffset(size, size)
		end
		local title = button:FindFirstChild("ActionTitle")
		if title and title:IsA("TextLabel") then
			title.TextScaled = true
			title.TextWrapped = false
			if not title:FindFirstChildOfClass("UITextSizeConstraint") then
				local fit = Instance.new("UITextSizeConstraint")
				fit.MaxTextSize = 22
				fit.MinTextSize = 8
				fit.Parent = title
			end
		end
	end)
end

local function apply(actionName, position)
	local size
	local phoneSpot = UI.IsPhone() and PHONE[actionName]
	if phoneSpot then
		position, size = phoneSpot[1], phoneSpot[2]
	elseif isLarge() and position.X.Scale == 1 and position.Y.Scale == 1 then
		position = UDim2.new(1, position.X.Offset + TABLET_SHIFT_X, 1, position.Y.Offset)
	end
	pcall(function()
		ContextActionService:SetPosition(actionName, position)
	end)
	styleButton(actionName, size)
end

-- Igual que ContextActionService:SetPosition, pero se ajusta en tablet y teléfono (y al girar la
-- pantalla, o cuando se sabe por fin su tamaño: al arrancar puede valer 0)
function TouchLayout.Set(actionName, position)
	registered[actionName] = position
	apply(actionName, position)
	if not watching then
		watching = true
		local function mode()
			return (UI.IsPhone() and "phone") or (isLarge() and "large") or "normal"
		end
		local was = mode()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local now = mode()
			if now ~= was then
				was = now
				for name, phonePosition in registered do
					apply(name, phonePosition)
				end
			end
		end)
	end
end

return TouchLayout
