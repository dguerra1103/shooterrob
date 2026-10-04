-- Construye los modelos de las armas a partir de las piezas de WeaponDesigns.
-- Lo usan el servidor (Tool que ven los demás) y el cliente (viewmodel e iconos 3D).
--
-- Colores: con la skin "Default" cada arma usa su propia paleta de fábrica (def.Palette);
-- con cualquier otra skin, todas las armas usan los colores de esa skin.
local Weapons = require(script.Parent.Weapons)
local Skins = require(script.Parent.Skins)

local WeaponModels = {}

-- Texturas de partículas que vienen incluidas con Roblox
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE_TEXTURE = "rbxasset://textures/particles/fire_main.dds"

local WHITE = Color3.new(1, 1, 1)

-- Paleta efectiva para un arma y una skin
function WeaponModels.GetPalette(weaponName, skinId)
	local def = Weapons.Get(weaponName)
	if (skinId == nil or skinId == "Default") and def and def.Palette then
		return def.Palette
	end
	return Skins.Get(skinId)
end

-- Camuflaje con imagen: solo si su MaterialVariant existe (si no, se usan los colores de respaldo)
local MaterialService = game:GetService("MaterialService")
local function camoVariant(pal)
	if not pal.Camo then
		return nil
	end
	local name = "Camo" .. pal.Camo
	return MaterialService:FindFirstChild(name) and name or nil
end

-- Skins arcoíris (pal.Rainbow = { Accent = true, ... }): las piezas de esos papeles llevan la etiqueta
-- "RainbowSkin" y el cliente (SkinFX) les va cambiando el color. Las etiquetas se replican.
local rainbowPhase = 0
local function setRainbow(part, role, pal)
	if pal.Rainbow and pal.Rainbow[role or "Body"] then
		rainbowPhase = (rainbowPhase + 0.09) % 1
		part:SetAttribute("RainbowPhase", rainbowPhase)
		part:SetAttribute("RainbowSat", pal.RainbowSat or 1)
		part:SetAttribute("RainbowVal", pal.RainbowVal or 1)
		part:AddTag("RainbowSkin")
	elseif part:HasTag("RainbowSkin") then
		part:RemoveTag("RainbowSkin")
	end
end

local function paint(part, role, pal)
	setRainbow(part, role, pal)
	part.Transparency = 0
	part.Reflectance = 0
	part.MaterialVariant = ""
	if role == "Accent" then
		part.Color = pal.Accent
		part.Material = pal.AccentMaterial or Enum.Material.Neon
	elseif role == "Accent2" then
		part.Color = pal.Accent2 or pal.Accent
		part.Material = pal.Accent2Material or Enum.Material.Neon
	elseif role == "Panel" then
		part.Color = pal.Panel or (pal.Accent2 or pal.Body:Lerp(WHITE, 0.6))
		part.Material = pal.PanelMaterial or Enum.Material.Plastic
	elseif role == "Dark" then
		part.Color = pal.Dark
		part.Material = Enum.Material.Metal
	elseif role == "Metal" then
		part.Color = Color3.fromRGB(200, 202, 210)
		part.Material = Enum.Material.Metal
		part.Reflectance = 0.15
	elseif role == "Rubber" then
		part.Color = pal.Rubber or Color3.fromRGB(28, 28, 32)
		part.Material = Enum.Material.Rubber -- empuñaduras y culatas de goma
	elseif role == "Gold" then
		part.Color = Color3.fromRGB(240, 180, 60)
		part.Material = Enum.Material.Foil
	elseif role == "Shell" then
		part.Color = Color3.fromRGB(200, 30, 35)
		part.Material = Enum.Material.SmoothPlastic
	elseif role == "Core" then
		part.Color = (pal.Accent2 or pal.Accent):Lerp(pal.Accent, 0.5)
		part.Material = Enum.Material.Neon
		part.Transparency = 0.15
	elseif role == "Reticle" then
		-- Punto rojo de las miras: siempre brilla
		part.Color = Color3.fromRGB(255, 40, 40)
		part.Material = Enum.Material.Neon
	elseif role == "Lens" then
		part.Color = pal.Lens or pal.Accent:Lerp(WHITE, 0.35)
		part.Material = Enum.Material.Glass
		part.Transparency = 0.45
		part.Reflectance = 0.3
	else
		part.Color = pal.Body
		-- Polímero con textura fina (el plástico liso parecía de juguete)
		part.Material = pal.BodyMaterial or Enum.Material.Plastic
	end
	-- Cuerpo y paneles con la imagen del camuflaje (el color blanco no la tiñe)
	if role == "Body" or role == "Panel" or role == nil then
		local variant = camoVariant(pal)
		if variant then
			part.Material = Enum.Material.Plastic
			part.MaterialVariant = variant
			part.Color = role == "Panel" and Color3.fromRGB(205, 205, 205) or WHITE
		end
	end
end

-- Partículas de la skin (destellos o llamas) alrededor del arma
local function applyEffects(container, pal)
	for _, inst in container:GetDescendants() do
		if inst:IsA("ParticleEmitter") and inst.Name == "SkinFX" then
			inst:Destroy()
		end
	end
	local handle = container:FindFirstChild("Handle")
	if not handle or not pal.Effect then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SkinFX"
	emitter.LockedToPart = true
	emitter.LightEmission = 1
	emitter.SpreadAngle = Vector2.new(180, 180)
	if pal.Effect == "Flame" then
		emitter.Texture = FIRE_TEXTURE
		emitter.Color = ColorSequence.new(pal.Accent, pal.Accent2 or pal.Accent)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.25, 0.45)
		emitter.Speed = NumberRange.new(0.3, 0.8)
		emitter.Acceleration = Vector3.new(0, 2.5, 0)
		emitter.Rate = 14
	else
		emitter.Texture = SPARKLE_TEXTURE
		emitter.Color = ColorSequence.new(pal.Accent, pal.Accent2 or WHITE)
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

-- Texto (nombre del arma) en los dos costados de una pieza
local function addLabel(part, text, pal)
	for _, face in { Enum.NormalId.Right, Enum.NormalId.Left } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Label"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 300
		gui.LightInfluence = 0.3
		gui.Parent = part
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Text = text
		label.TextColor3 = Color3.fromRGB(240, 240, 245)
		label.TextStrokeTransparency = 0.6
		label.Parent = gui
	end
end

-- Pinta todas las piezas de un arma (Model o Tool) con la skin indicada.
function WeaponModels.ApplySkin(container, skinId, weaponName)
	weaponName = weaponName or container:GetAttribute("Weapon") or container.Name
	local pal = WeaponModels.GetPalette(weaponName, skinId)
	for _, part in container:GetDescendants() do
		if part:IsA("BasePart") then
			local role = part:GetAttribute("Role")
			if role then
				paint(part, role, pal)
			end
		end
	end
	applyEffects(container, pal)
end

-- Devuelve un Model con PrimaryPart = Handle. Las piezas van soldadas al Handle.
-- withEffects = false para no añadir partículas (por ejemplo en iconos).
function WeaponModels.Build(weaponName, skinId, withEffects)
	local def = Weapons.Get(weaponName)
	assert(def, "Arma desconocida: " .. tostring(weaponName))
	local pal = WeaponModels.GetPalette(weaponName, skinId)

	local model = Instance.new("Model")
	model.Name = weaponName

	local handle
	local created = {}
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
		paint(part, spec.Role, pal)
		if spec.Text then
			addLabel(part, spec.Text, pal)
		end
		if spec.Name == "Handle" then
			handle = part
		end
		part.Parent = model
		table.insert(created, { Part = part, Spec = spec })
	end

	-- Coloca y suelda cada pieza al Handle (que está en el origen del diseño)
	for _, entry in created do
		entry.Part.CFrame = entry.Spec.CFrame
		if entry.Part ~= handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = entry.Part
			weld.Parent = entry.Part
		end
	end
	local function attach(name, position)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = position
		a.Parent = handle
		return a
	end
	if def.Muzzle then
		attach("Muzzle", def.Muzzle)
	end
	if def.AimPoint then
		attach("AimPoint", def.AimPoint)
	end
	attach("Eject", def.Eject or Vector3.new(0.22, 0.08, 0))

	model:SetAttribute("Weapon", weaponName)
	model.PrimaryPart = handle
	if withEffects ~= false then
		applyEffects(model, pal)
	end
	return model
end

return WeaponModels
