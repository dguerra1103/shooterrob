-- Construye los modelos de las armas a partir de las piezas definidas en Weapons.
-- Lo usan el servidor (Tool que ven los demás) y el cliente (viewmodel e iconos 3D).
local Weapons = require(script.Parent.Weapons)
local Skins = require(script.Parent.Skins)

local WeaponModels = {}

-- Texturas de partículas que vienen incluidas con Roblox
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE_TEXTURE = "rbxasset://textures/particles/fire_main.dds"

local function paint(part, role, skin)
	part.Transparency = 0
	part.Reflectance = 0
	if role == "Accent" then
		part.Color = skin.Accent
		part.Material = skin.AccentMaterial
	elseif role == "Accent2" then
		part.Color = skin.Accent2 or skin.Accent
		part.Material = Enum.Material.SmoothPlastic
	elseif role == "Dark" then
		part.Color = skin.Dark
		part.Material = Enum.Material.Metal
	elseif role == "Metal" then
		part.Color = Color3.fromRGB(200, 202, 210)
		part.Material = Enum.Material.Metal
		part.Reflectance = 0.15
	elseif role == "Lens" then
		part.Color = Color3.fromRGB(170, 225, 255)
		part.Material = Enum.Material.Glass
		part.Transparency = 0.55
		part.Reflectance = 0.3
	else
		part.Color = skin.Body
		part.Material = skin.BodyMaterial
	end
end

-- Partículas de la skin (destellos o llamas) alrededor del arma
local function applyEffects(container, skin)
	for _, inst in container:GetDescendants() do
		if inst:IsA("ParticleEmitter") and inst.Name == "SkinFX" then
			inst:Destroy()
		end
	end
	local handle = container:FindFirstChild("Handle")
	if not handle or not skin.Effect then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SkinFX"
	emitter.LockedToPart = true
	emitter.LightEmission = 1
	emitter.SpreadAngle = Vector2.new(180, 180)
	if skin.Effect == "Flame" then
		emitter.Texture = FIRE_TEXTURE
		emitter.Color = ColorSequence.new(skin.Accent, skin.Accent2 or skin.Accent)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.25, 0.45)
		emitter.Speed = NumberRange.new(0.3, 0.8)
		emitter.Acceleration = Vector3.new(0, 2.5, 0)
		emitter.Rate = 14
	else
		emitter.Texture = SPARKLE_TEXTURE
		emitter.Color = ColorSequence.new(skin.Accent, skin.Accent2 or Color3.new(1, 1, 1))
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.16),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Lifetime = NumberRange.new(0.4, 0.8)
		emitter.Speed = NumberRange.new(0.1, 0.4)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-90, 90)
		emitter.Rate = 7
	end
	emitter.Parent = handle
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
	applyEffects(container, skin)
end

-- Devuelve un Model con PrimaryPart = Handle. Las piezas van soldadas al Handle.
-- withEffects = false para no añadir partículas (por ejemplo en iconos).
function WeaponModels.Build(weaponName, skinId, withEffects)
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
		if spec.Shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		elseif spec.Shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		end
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
	-- Punto por donde salen los casquillos (lado derecho del cuerpo)
	local eject = Instance.new("Attachment")
	eject.Name = "Eject"
	eject.Position = Vector3.new(0.2, 0.08, 0)
	eject.Parent = handle

	model.PrimaryPart = handle
	if withEffects ~= false then
		applyEffects(model, skin)
	end
	return model
end

return WeaponModels
