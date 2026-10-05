-- Tu cuerpo en primera persona: al mirar hacia abajo ves tus piernas y tus botas (con lo que lleve el
-- traje o el uniforme en ellas), como en los shooters modernos. Roblox esconde todo el personaje en
-- primera persona; aquí, justo después de la cámara, se vuelven a mostrar la cadera y las piernas. Se
-- esconden otra vez agachado o deslizándote (la cámara baja y las atravesaría), muerto, en el menú y
-- con la cámara lejos (emotes).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ClientState = require(script.Parent.ClientState)

local BodyView = {}

local LOWER_BODY = {
	LowerTorso = true,
	LeftUpperLeg = true,
	LeftLowerLeg = true,
	LeftFoot = true,
	RightUpperLeg = true,
	RightLowerLeg = true,
	RightFoot = true,
}

local player = Players.LocalPlayer
local shown = {} -- piezas a mostrar del personaje actual
local character = nil
local pending = false -- (una sola recogida por fotograma aunque lleguen muchas piezas de golpe)

-- La cadera, las piernas y lo que va pegado a ellas (botas, rodilleras, cinturón del traje)
local function collect(model)
	table.clear(shown)
	if not model then
		return
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and LOWER_BODY[d.Name] then
			table.insert(shown, d)
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("WeldConstraint") or d:IsA("Weld") then
			local a, b = d.Part0, d.Part1
			local onLeg = (a and LOWER_BODY[a.Name] and a:IsDescendantOf(model)) or (b and LOWER_BODY[b.Name] and b:IsDescendantOf(model))
			if onLeg then
				for _, part in { a, b } do
					if part and part:IsA("BasePart") and not LOWER_BODY[part.Name] and not table.find(shown, part) then
						table.insert(shown, part)
					end
				end
			end
		end
	end
end

-- ¿Se ven las piernas ahora? (primera persona, de pie o andando)
function BodyView.Active()
	if not character or ClientState.Dead or ClientState.InMainMenu or ClientState.Emoting then
		return false
	end
	if ClientState.Crouching or ClientState.Sliding then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local camera = workspace.CurrentCamera
	if not humanoid or humanoid.Health <= 0 or not head or not camera then
		return false
	end
	return (camera.CFrame.Position - head.Position).Magnitude < 2
end

function BodyView.Update()
	if not BodyView.Active() then
		return
	end
	for _, part in shown do
		if part.Parent then
			part.LocalTransparencyModifier = 0
		end
	end
end

-- (para las pruebas)
function BodyView.Shown()
	return shown
end

function BodyView.Track(model)
	character = model
	collect(model)
	if model then
		-- Lo que se le pone después (uniforme, traje) también cuenta
		model.DescendantAdded:Connect(function()
			if character == model and not pending then
				pending = true
				task.defer(function()
					pending = false
					if character == model then
						collect(model)
					end
				end)
			end
		end)
	end
end

function BodyView.Init()
	if player.Character then
		BodyView.Track(player.Character)
	end
	player.CharacterAdded:Connect(BodyView.Track)
	-- Justo después de la cámara (que es la que esconde el personaje en primera persona)
	RunService:BindToRenderStep("BodyView", Enum.RenderPriority.Camera.Value + 2, function()
		local ok, err = pcall(BodyView.Update)
		if not ok then
			warn("[BodyView]", err)
		end
	end)
end

return BodyView
