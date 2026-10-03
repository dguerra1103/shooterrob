-- Iconos 3D de armas: dibuja el modelo real (con su skin) dentro de un ViewportFrame.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponModels = require(Shared.WeaponModels)

local WeaponIcon = {}

local FOV = 20

-- view: "side" (de perfil, cañón a la derecha) o "angled" (tres cuartos)
-- aspect: ancho / alto del ViewportFrame
function WeaponIcon.Create(weaponName, skinId, props, view, aspect)
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(170, 170, 185)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1.5, -0.6)
	for key, value in props or {} do
		viewport[key] = value
	end

	local model = WeaponModels.Build(weaponName, skinId, false)
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local boxCFrame, size = model:GetBoundingBox()
	local center = boxCFrame.Position
	aspect = aspect or 2.5
	local tanHalf = math.tan(math.rad(FOV / 2))

	local direction
	if view == "angled" then
		direction = Vector3.new(1, 0.35, 0.45).Unit
	else
		direction = Vector3.new(1, 0.05, 0).Unit
	end
	-- Distancia para que quepa: el largo del arma (Z) en horizontal y el alto (Y) en vertical
	local fitVertical = (size.Y / 2) / tanHalf
	local fitHorizontal = (size.Z / 2) / (tanHalf * aspect)
	local margin = view == "angled" and 1.35 or 1.12
	local distance = math.max(fitVertical, fitHorizontal) * margin + size.X / 2
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
	return viewport
end

return WeaponIcon
