-- Construye los modelos de las armas a partir de las piezas definidas en Weapons.
-- Lo usan el servidor (Tool que ven los demás) y el cliente (viewmodel en primera persona).
local Weapons = require(script.Parent.Weapons)
local Skins = require(script.Parent.Skins)

local WeaponModels = {}

local function paint(part, role, skin)
	if role == "Accent" then
		part.Color = skin.Accent
		part.Material = skin.AccentMaterial
	elseif role == "Dark" then
		part.Color = skin.Dark
		part.Material = Enum.Material.Metal
	else
		part.Color = skin.Body
		part.Material = skin.BodyMaterial
	end
end

-- Pinta todas las piezas de un arma (Model o Tool) con la skin indicada.
function WeaponModels.ApplySkin(container, skinId)
	local skin = Skins.Get(skinId)
	for _, part in container:GetDescendants() do
		if part:IsA("BasePart") then
			local role = part:GetAttribute("Role")
			if role then
				paint(part, role, skin)
			end
		end
	end
end

-- Devuelve un Model con PrimaryPart = Handle. Las piezas van soldadas al Handle.
function WeaponModels.Build(weaponName, skinId)
	local def = Weapons.Get(weaponName)
	assert(def, "Arma desconocida: " .. tostring(weaponName))
	local skin = Skins.Get(skinId)

	local model = Instance.new("Model")
	model.Name = weaponName

	local handle
	for _, spec in def.Parts do
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = spec.Size
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CastShadow = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part:SetAttribute("Role", spec.Role)
		paint(part, spec.Role, skin)
		if spec.Name == "Handle" then
			handle = part
			part.CFrame = CFrame.new()
		end
		part.Parent = model
	end

	-- Coloca y suelda cada pieza al Handle
	for _, spec in def.Parts do
		if spec.Name ~= "Handle" then
			local part = model:FindFirstChild(spec.Name)
			part.CFrame = handle.CFrame * spec.CFrame
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
		end
	end

	if def.Muzzle then
		local muzzle = Instance.new("Attachment")
		muzzle.Name = "Muzzle"
		muzzle.Position = def.Muzzle
		muzzle.Parent = handle
	end
	if def.AimPoint then
		local aim = Instance.new("Attachment")
		aim.Name = "AimPoint"
		aim.Position = def.AimPoint
		aim.Parent = handle
	end

	model.PrimaryPart = handle
	return model
end

return WeaponModels
