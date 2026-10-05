-- Posición de los botones táctiles (ContextActionService). Las posiciones del código están pensadas
-- para el teléfono, alrededor del botón de saltar de Roblox. En tablet (pantalla grande) ese botón
-- es más grande y está más arriba y a la izquierda (120 px, a 170 de la derecha y 210 de abajo), así
-- que todo el grupo de abajo a la derecha se corre a la izquierda para no taparlo.
local ContextActionService = game:GetService("ContextActionService")

local TouchLayout = {}

local TABLET_SHIFT_X = -130
local registered = {} -- [acción] = posición de teléfono
local watching = false

local function isLarge()
	local size = workspace.CurrentCamera.ViewportSize
	return math.min(size.X, size.Y) > 500
end

-- El texto del botón se encoge para caber (si no, «Disparar» salía partido en «Dispar / ar»)
local function styleTitle(actionName)
	pcall(function()
		local button = ContextActionService:GetButton(actionName)
		local title = button and button:FindFirstChild("ActionTitle")
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
	if isLarge() and position.X.Scale == 1 and position.Y.Scale == 1 then
		position = UDim2.new(1, position.X.Offset + TABLET_SHIFT_X, 1, position.Y.Offset)
	end
	pcall(function()
		ContextActionService:SetPosition(actionName, position)
	end)
	styleTitle(actionName)
end

-- Igual que ContextActionService:SetPosition, pero se ajusta en tablet (y al girar la pantalla)
function TouchLayout.Set(actionName, position)
	registered[actionName] = position
	apply(actionName, position)
	if not watching then
		watching = true
		local wasLarge = isLarge()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local large = isLarge()
			if large ~= wasLarge then
				wasLarge = large
				for name, phonePosition in registered do
					apply(name, phonePosition)
				end
			end
		end)
	end
end

return TouchLayout
