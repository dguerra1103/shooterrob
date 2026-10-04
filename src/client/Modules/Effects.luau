-- Efectos visuales (solo en el cliente): fogonazo, balas trazadoras, impactos, casquillos y bajas.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ClientState = require(script.Parent.ClientState)

local Effects = {}

-- Texturas de partículas incluidas con Roblox
local TEX = {
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
}

local folder = Instance.new("Folder")
folder.Name = "ClientFX"
folder.Parent = workspace

local function fxPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	for key, value in props do
		part[key] = value
	end
	part.Parent = folder
	return part
end

-- lookAt que no falla cuando la dirección es vertical (por ejemplo, impactos en el suelo)
local function safeLookAt(position, direction)
	local up = math.abs(direction.Unit.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis
	return CFrame.lookAt(position, position + direction, up)
end

local function seq(a, b)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

-- Pieza invisible que sirve de emisor; su +Y apunta hacia `direction`
local function emitterAnchor(position, direction, lifetime)
	direction = (direction and direction.Magnitude > 0.01) and direction.Unit or Vector3.yAxis
	local anchor = fxPart({
		Size = Vector3.new(0.1, 0.1, 0.1),
		Transparency = 1,
		CFrame = safeLookAt(position, direction) * CFrame.Angles(-math.pi / 2, 0, 0),
	})
	Debris:AddItem(anchor, lifetime or 2)
	return anchor
end

local function emit(parent, props, count)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.EmissionDirection = Enum.NormalId.Top
	for key, value in props do
		emitter[key] = value
	end
	emitter.Parent = parent
	emitter:Emit(count)
	return emitter
end

-- Reutilización para los efectos de cada disparo: en un tiroteo se creaban decenas de piezas y
-- emisores por segundo (y cada uno avisaba a Settings). Ahora hay un juego de anclas que se van
-- turnando, cada una con sus emisores guardados por tipo; las partículas ya emitidas no se mueven
-- al recolocar el ancla (están en el mundo).
local ANCHOR_POOL = 24
local anchorPool, anchorIndex = {}, 0
local emitterCache = {} -- [ancla] = { [tipo] = ParticleEmitter }

local function pooledAnchor(position, direction)
	direction = (direction and direction.Magnitude > 0.01) and direction.Unit or Vector3.yAxis
	anchorIndex = anchorIndex % ANCHOR_POOL + 1
	local anchor = anchorPool[anchorIndex]
	if not anchor or not anchor.Parent then
		if anchor then
			emitterCache[anchor] = nil
		end
		anchor = fxPart({ Name = "FXAnchor", Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 })
		anchorPool[anchorIndex] = anchor
		emitterCache[anchor] = {}
	end
	anchor.CFrame = safeLookAt(position, direction) * CFrame.Angles(-math.pi / 2, 0, 0)
	return anchor
end

-- Como emit, pero con el emisor guardado en el ancla (se crea la primera vez; el color se actualiza)
local function emitPooled(anchor, key, props, count)
	local cache = emitterCache[anchor]
	if not cache then
		return emit(anchor, props, count)
	end
	local emitter = cache[key]
	if not emitter then
		emitter = emit(anchor, props, 0)
		cache[key] = emitter
	elseif props.Color then
		emitter.Color = props.Color
	end
	emitter:Emit(count)
	return emitter
end

-- Piezas que se reutilizan por turnos (trazadoras y marcas de bala)
local function partRing(size)
	return { Parts = {}, Index = 0, Size = size, Tokens = {} }
end
local function ringPart(ring, props)
	ring.Index = ring.Index % ring.Size + 1
	local part = ring.Parts[ring.Index]
	if not part or not part.Parent then
		part = fxPart(props)
		ring.Parts[ring.Index] = part
	else
		for key, value in props do
			part[key] = value
		end
	end
	local token = (ring.Tokens[ring.Index] or 0) + 1
	ring.Tokens[ring.Index] = token
	return part, ring.Index, token
end
-- Oculta la pieza al acabar, si nadie la ha reutilizado mientras tanto
local function hideLater(ring, index, token, delay)
	task.delay(delay, function()
		local part = ring.Parts[index]
		if ring.Tokens[index] == token and part then
			part.Transparency = 1
		end
	end)
end
-- (las marcas duran 5 s: con 16 disparos por segundo hacen falta unas 80 para que no desaparezcan antes)
local bulletRing, trailRing, markRing, chipRing = partRing(30), partRing(30), partRing(80), partRing(80)

---------------------------------------------------------------------------

-- Bala trazadora que viaja desde el cañón hasta el impacto, con una estela tenue
function Effects.Tracer(from, to, color)
	local distance = (to - from).Magnitude
	if distance < 1 then
		return
	end
	color = color or Color3.fromRGB(255, 230, 120)
	local direction = safeLookAt(from, to - from)

	-- Estela fina que se desvanece
	local trail = ringPart(trailRing, {
		Color = color,
		Size = Vector3.new(0.03, 0.03, distance),
		CFrame = direction * CFrame.new(0, 0, -distance / 2),
		Transparency = 0.6,
	})
	TweenService:Create(trail, TweenInfo.new(0.1), { Transparency = 1 }):Play()

	-- La bala
	local length = math.min(6, distance)
	local travel = math.max(distance - length, 0.01)
	local duration = math.clamp(distance / 900, 0.02, 0.25)
	local bullet, index, token = ringPart(bulletRing, {
		Color = color,
		Size = Vector3.new(0.12, 0.12, length),
		CFrame = direction * CFrame.new(0, 0, -length / 2),
		Transparency = 0,
	})
	TweenService
		:Create(bullet, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = direction * CFrame.new(0, 0, -length / 2 - travel) })
		:Play()
	hideLater(bulletRing, index, token, duration + 0.02)
end

-- Fogonazo: estrella de luz, llamas y humo. remote = disparo de otro (más barato: sin luz ni estrella)
function Effects.MuzzleFlash(attachment, color, remote)
	if not attachment then
		return
	end
	color = color or Color3.fromRGB(255, 200, 90)
	local cf = attachment.WorldCFrame
	local spin = math.random() * math.pi
	for i = 0, remote and -1 or 1 do
		local star = fxPart({
			Color = color:Lerp(Color3.new(1, 1, 1), 0.4),
			Size = Vector3.new(0.08, 0.7, 0.3),
			CFrame = cf * CFrame.new(0, 0, -0.2) * CFrame.Angles(0, 0, spin + i * math.pi / 2),
		})
		Debris:AddItem(star, 0.04)
	end
	local core = fxPart({
		Color = Color3.fromRGB(255, 240, 200),
		Size = Vector3.new(0.3, 0.3, 0.3),
		Shape = Enum.PartType.Ball,
		CFrame = cf * CFrame.new(0, 0, -0.15),
	})
	if not remote then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 12
		light.Brightness = 4
		light.Parent = core
	end
	Debris:AddItem(core, 0.05)

	local anchor = pooledAnchor(cf.Position, cf.LookVector)
	emitPooled(anchor, "MuzzleFire", {
		Texture = TEX.Fire,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 180), color),
		LightEmission = 1,
		Size = seq(0.45, 0),
		Transparency = seq(0, 1),
		Lifetime = NumberRange.new(0.04, 0.08),
		Speed = NumberRange.new(4, 8),
		SpreadAngle = Vector2.new(12, 12),
	}, 5)
	emitPooled(anchor, "MuzzleSmoke", {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(Color3.fromRGB(220, 220, 220)),
		Size = seq(0.2, 0.9),
		Transparency = seq(0.6, 1),
		Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(20, 20),
		Acceleration = Vector3.new(0, 1.5, 0),
	}, 2)
end

-- Tipo de superficie según el material: cambia la reacción al impacto (chispas en metal, astillas
-- en madera, polvo y esquirlas en piedra, tierra o nieve que saltan, salpicadura en agua)
local SURFACE = {}
for kind, materials in {
	Metal = { "Metal", "CorrodedMetal", "DiamondPlate", "Foil" },
	Wood = { "Wood", "WoodPlanks" },
	Stone = {
		"Concrete", "Brick", "Cobblestone", "Slate", "Granite", "Marble", "Pebble", "Rock", "Basalt", "Limestone",
		"Pavement", "Asphalt", "Plaster", "Sandstone", "CeramicTiles", "ClayRoofTiles", "CrackedLava",
	},
	Dirt = { "Grass", "LeafyGrass", "Ground", "Mud", "Sand" },
	Snow = { "Snow", "Ice", "Glacier" },
	Water = { "Water" },
	Glass = { "Glass" },
} do
	for _, name in materials do
		local ok, material = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		if ok and material then
			SURFACE[material] = kind
		end
	end
end

local function surfaceColor(hitPart, material)
	if hitPart and hitPart:IsA("Terrain") then
		local ok, color = pcall(function()
			return workspace.Terrain:GetMaterialColor(material)
		end)
		return ok and color or Color3.fromRGB(150, 140, 120)
	end
	return hitPart and hitPart.Color or Color3.fromRGB(200, 200, 200)
end

-- Impacto: reacción según la superficie, polvo del color del material y marca de bala
-- Pintura (arma de paintball): gotas de un color al azar y, en superficies, una mancha plana que se
-- desvanece a los pocos segundos (como mucho MAX_SPLATS a la vez)
local PAINT_COLORS = {
	Color3.fromRGB(255, 60, 140),
	Color3.fromRGB(60, 200, 255),
	Color3.fromRGB(255, 220, 40),
	Color3.fromRGB(120, 230, 60),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 140, 40),
}
local MAX_SPLATS = 40
local splats = {}

local function paintSplat(anchor, position, normal, isCharacter)
	local color = PAINT_COLORS[math.random(1, #PAINT_COLORS)]
	emitPooled(anchor, "Paint", {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(color),
		LightEmission = 0.2,
		Size = seq(0.4, 0.1),
		Lifetime = NumberRange.new(0.3, 0.55),
		Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(55, 55),
		Acceleration = Vector3.new(0, -60, 0),
	}, isCharacter and 12 or 10)
	if isCharacter then
		return
	end
	normal = (normal and normal.Magnitude > 0.01) and normal.Unit or Vector3.yAxis
	local size = 1.2 + math.random() * 1.2
	-- Cilindro muy fino pegado a la superficie (su eje X apunta en la dirección de la normal)
	local splat = fxPart({
		Name = "PaintSplat",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.04, size, size),
		CFrame = safeLookAt(position + normal * 0.03, normal) * CFrame.Angles(0, math.pi / 2, 0),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
	})
	table.insert(splats, splat)
	if #splats > MAX_SPLATS then
		local oldest = table.remove(splats, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	task.delay(5, function()
		if splat.Parent then
			TweenService:Create(splat, TweenInfo.new(1.5), { Transparency = 1 }):Play()
			task.delay(1.6, function()
				local index = table.find(splats, splat)
				if index then
					table.remove(splats, index)
				end
				splat:Destroy()
			end)
		end
	end)
end

-- style = "Paint" para las armas de paintball (def.ImpactStyle)
function Effects.Impact(position, normal, hitPart, material, style)
	local isCharacter = hitPart ~= nil
		and hitPart.Parent ~= nil
		and (hitPart.Parent:FindFirstChildOfClass("Humanoid") ~= nil or hitPart.Parent:IsA("Accessory"))
	local anchor = pooledAnchor(position + (normal or Vector3.yAxis) * 0.05, normal)
	if style == "Paint" then
		paintSplat(anchor, position, normal, isCharacter)
		return
	end

	if isCharacter then
		-- Destello de golpe (estilo cartoon, sin sangre)
		emitPooled(anchor, "Hit", {
			Texture = TEX.Sparkle,
			Color = ColorSequence.new(Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 220, 120)),
			LightEmission = 1,
			Size = seq(0.5, 0),
			Lifetime = NumberRange.new(0.15, 0.3),
			Speed = NumberRange.new(6, 12),
			SpreadAngle = Vector2.new(60, 60),
			Rotation = NumberRange.new(0, 360),
		}, 8)
		return
	end

	material = material or (hitPart and hitPart.Material) or Enum.Material.Plastic
	local kind = SURFACE[material] or "Plastic"
	local baseColor = surfaceColor(hitPart, material)

	if kind == "Water" then
		-- Salpicadura: gotas hacia arriba que caen y un poco de espuma
		emitPooled(anchor, "WaterDrops", {
			Texture = TEX.Sparkle,
			Color = ColorSequence.new(Color3.fromRGB(220, 240, 255)),
			LightEmission = 0.3,
			Size = seq(0.25, 0.05),
			Lifetime = NumberRange.new(0.4, 0.7),
			Speed = NumberRange.new(10, 18),
			SpreadAngle = Vector2.new(18, 18),
			Acceleration = Vector3.new(0, -50, 0),
		}, 12)
		emitPooled(anchor, "WaterFoam", {
			Texture = TEX.Smoke,
			Color = ColorSequence.new(Color3.fromRGB(240, 248, 255)),
			Size = seq(0.6, 2),
			Transparency = seq(0.4, 1),
			Lifetime = NumberRange.new(0.4, 0.6),
			Speed = NumberRange.new(1, 2),
			SpreadAngle = Vector2.new(70, 70),
		}, 3)
		return
	end

	-- Chispas: muchas en metal, pocas en piedra y cristal, ninguna en materiales blandos
	local sparks = (kind == "Metal" and 12) or ((kind == "Stone" or kind == "Glass" or kind == "Plastic") and 4) or 0
	if sparks > 0 then
		emitPooled(anchor, "Sparks" .. kind, {
			Texture = TEX.Sparkle,
			Color = ColorSequence.new(Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 150, 60)),
			LightEmission = 1,
			Size = seq(kind == "Metal" and 0.22 or 0.16, 0),
			Lifetime = NumberRange.new(0.15, kind == "Metal" and 0.5 or 0.3),
			Speed = NumberRange.new(10, 20),
			SpreadAngle = Vector2.new(50, 50),
			Acceleration = Vector3.new(0, -45, 0),
		}, sparks)
	end

	-- Esquirlas que saltan y caen (astillas de madera, trozos de piedra, terrones, cristal)
	if kind == "Wood" or kind == "Stone" or kind == "Dirt" or kind == "Glass" or kind == "Snow" then
		local chipColor = kind == "Glass" and Color3.fromRGB(220, 240, 255) or baseColor:Lerp(Color3.new(0, 0, 0), kind == "Wood" and 0.25 or 0.1)
		emitPooled(anchor, "Chips" .. kind, {
			Texture = TEX.Smoke,
			Color = ColorSequence.new(chipColor),
			LightInfluence = 1,
			Size = seq(kind == "Snow" and 0.35 or 0.22, 0.12),
			Lifetime = NumberRange.new(0.35, 0.6),
			Speed = NumberRange.new(8, 15),
			SpreadAngle = Vector2.new(40, 40),
			Acceleration = Vector3.new(0, -55, 0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-300, 300),
		}, kind == "Wood" and 6 or 5)
	end

	-- Nube de polvo del color de la superficie (más grande en tierra y nieve)
	local soft = kind == "Dirt" or kind == "Snow"
	local dustColor = baseColor:Lerp(Color3.new(1, 1, 1), kind == "Snow" and 0.5 or 0.3)
	if kind ~= "Metal" and kind ~= "Glass" then
		emitPooled(anchor, soft and "DustSoft" or "Dust", {
			Texture = TEX.Smoke,
			Color = ColorSequence.new(dustColor),
			LightInfluence = 1,
			Size = seq(soft and 0.6 or 0.3, soft and 2.4 or 1.5),
			Transparency = seq(soft and 0.2 or 0.3, 1),
			Lifetime = NumberRange.new(soft and 0.7 or 0.45, soft and 1.1 or 0.8),
			Speed = NumberRange.new(soft and 3 or 1.5, soft and 6 or 3),
			SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(0, soft and -6 or 0.5, 0),
			WindAffectsDrag = true,
		}, soft and 5 or 3)
	end

	-- Marca de bala (no queda en nieve ni en tierra blanda)
	if soft then
		return
	end
	local markColor = (kind == "Metal" and Color3.fromRGB(70, 70, 76))
		or (kind == "Wood" and Color3.fromRGB(45, 30, 20))
		or (kind == "Glass" and Color3.fromRGB(230, 240, 250))
		or Color3.fromRGB(25, 25, 28)
	local mark = ringPart(markRing, {
		Color = markColor,
		Material = kind == "Metal" and Enum.Material.Metal or Enum.Material.SmoothPlastic,
		Size = Vector3.new(0.22, 0.22, 0.03),
		Shape = Enum.PartType.Block,
		CFrame = safeLookAt(position, normal or Vector3.yAxis) * CFrame.Angles(0, 0, math.random() * math.pi),
		Transparency = kind == "Glass" and 0.4 or 0.15,
	})
	if kind == "Stone" then
		-- Desconchón claro alrededor del agujero
		local chip = ringPart(chipRing, {
			Color = baseColor:Lerp(Color3.new(1, 1, 1), 0.25),
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(0.45, 0.45, 0.012),
			CFrame = mark.CFrame * CFrame.new(0, 0, -0.003) * CFrame.Angles(0, 0, 0.6),
			Transparency = 0.35,
		})
		TweenService:Create(chip, TweenInfo.new(5, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
	end
	TweenService:Create(mark, TweenInfo.new(5, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
end

-- Casquillo que sale disparado por la derecha del arma
local liveCasings = 0
local MAX_CASINGS = 8 -- con fuego automático no hace falta simular más a la vez

function Effects.ShellCasing(attachment, cameraCFrame, color)
	if not attachment or liveCasings >= MAX_CASINGS then
		return
	end
	liveCasings += 1
	task.delay(1.5, function()
		liveCasings -= 1
	end)
	local casing = Instance.new("Part")
	casing.Size = Vector3.new(0.06, 0.06, 0.16)
	casing.Color = color or Color3.fromRGB(230, 180, 60)
	casing.Material = Enum.Material.Metal
	casing.Reflectance = 0.2
	casing.CanCollide = true
	casing.CanQuery = false
	casing.CanTouch = false
	casing.CastShadow = false
	casing.Massless = true
	casing.CustomPhysicalProperties = PhysicalProperties.new(0.05, 0.3, 0.6)
	casing.CFrame = attachment.WorldCFrame
	casing.Parent = folder
	local right = cameraCFrame.RightVector
	local up = cameraCFrame.UpVector
	casing.AssemblyLinearVelocity = right * (6 + math.random() * 3) + up * (5 + math.random() * 3)
	casing.AssemblyAngularVelocity = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
	Debris:AddItem(casing, 1.5)
end

-- Explosión del cohete
function Effects.Explosion(position, radius, color)
	radius = radius or 12
	-- Temblor de cámara si la explosión es cercana (más fuerte cuanto más cerca)
	local camera = workspace.CurrentCamera
	if camera then
		local distance = (camera.CFrame.Position - position).Magnitude
		local strength = math.clamp(1 - distance / (radius * 4), 0, 1)
		if strength > 0 then
			ClientState.Shake = math.max(ClientState.Shake or 0, strength)
		end
	end
	color = color or Color3.fromRGB(255, 140, 30)
	local fireball = fxPart({
		Color = Color3.fromRGB(255, 200, 80),
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(position),
		Transparency = 0,
	})
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = radius * 2.5
	light.Brightness = 6
	light.Parent = fireball
	TweenService:Create(fireball, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = Vector3.one * radius * 1.2, Transparency = 1, Color = color }):Play()
	TweenService:Create(light, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(fireball, 0.55)

	-- Onda expansiva en el suelo
	local ring = fxPart({
		Color = color:Lerp(Color3.new(1, 1, 1), 0.4),
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 2, 2),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
		Transparency = 0.2,
	})
	TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = Vector3.new(0.1, radius * 2.4, radius * 2.4), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.45)

	local anchor = emitterAnchor(position, Vector3.yAxis, 3)
	emit(anchor, {
		Texture = TEX.Fire,
		Color = ColorSequence.new(Color3.fromRGB(255, 230, 150), color),
		LightEmission = 1,
		Size = seq(3, 0.5),
		Transparency = seq(0, 1),
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(10, 22),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
	}, 30)
	emit(anchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(Color3.fromRGB(70, 65, 60)),
		Size = seq(2, 7),
		Transparency = seq(0.2, 1),
		Lifetime = NumberRange.new(1.2, 2.2),
		Speed = NumberRange.new(3, 8),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 3, 0),
	}, 14)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 120)),
		LightEmission = 1,
		Size = seq(0.3, 0),
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(25, 45),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -60, 0),
	}, 20)

	-- Columna de humo negro que se queda unos segundos
	local smokeAnchor = emitterAnchor(position + Vector3.new(0, 1, 0), Vector3.yAxis, 6)
	emit(smokeAnchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(Color3.fromRGB(40, 38, 36), Color3.fromRGB(90, 88, 85)),
		Size = seq(3, 10),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.6, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(25, 25),
		Acceleration = Vector3.new(0.5, 2.5, 0),
		RotSpeed = NumberRange.new(-25, 25),
		Rotation = NumberRange.new(0, 360),
	}, 10)

	-- Escombros que salen despedidos
	for _ = 1, 8 do
		local chunk = fxPart({
			Size = Vector3.new(0.3 + math.random() * 0.4, 0.2 + math.random() * 0.3, 0.3 + math.random() * 0.4),
			Color = Color3.fromRGB(70, 66, 62),
			Material = Enum.Material.Slate,
			CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0),
		})
		chunk.Anchored = false
		local dir = Vector3.new(math.random() - 0.5, 0.7 + math.random() * 0.6, math.random() - 0.5).Unit
		chunk.AssemblyLinearVelocity = dir * (25 + math.random() * 20)
		chunk.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 25
		TweenService:Create(chunk, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 1.4), { Transparency = 1 }):Play()
		Debris:AddItem(chunk, 1.9)
	end

	-- Marca de quemado en el suelo (si hay suelo cerca)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	local ground = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -8, 0), params)
	if ground and ground.Instance then
		local scorch = fxPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.05, radius * 0.9, radius * 0.9),
			Color = Color3.fromRGB(22, 20, 18),
			Material = Enum.Material.Slate,
			CFrame = safeLookAt(ground.Position + ground.Normal * 0.04, ground.Normal) * CFrame.Angles(0, math.pi / 2, 0),
			Transparency = 0.25,
		})
		TweenService:Create(scorch, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 6), { Transparency = 1 }):Play()
		Debris:AddItem(scorch, 10.2)
	end
end

-- Cohete que vuela hasta `to` y explota al llegar
function Effects.Rocket(from, to, speed, color, radius)
	local distance = (to - from).Magnitude
	if distance < 0.5 then
		Effects.Explosion(to, radius, color)
		return
	end
	local direction = safeLookAt(from, to - from)
	local rocket = fxPart({
		Color = Color3.fromRGB(230, 230, 235),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(0.35, 0.35, 1.3),
		CFrame = direction,
	})
	local tip = fxPart({
		Color = Color3.fromRGB(220, 40, 40),
		Material = Enum.Material.SmoothPlastic,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.38, 0.38, 0.38),
		CFrame = direction * CFrame.new(0, 0, -0.65),
	})
	local flame = fxPart({
		Color = color or Color3.fromRGB(255, 160, 40),
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.45, 0.45, 0.45),
		CFrame = direction * CFrame.new(0, 0, 0.7),
	})
	local trail = Instance.new("ParticleEmitter")
	trail.Texture = TEX.Smoke
	trail.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
	trail.Size = seq(0.4, 1.6)
	trail.Transparency = seq(0.3, 1)
	trail.Lifetime = NumberRange.new(0.5, 0.9)
	trail.Speed = NumberRange.new(0.5, 1)
	trail.Rate = 80
	trail.Parent = flame
	local duration = distance / speed
	for _, part in { rocket, tip, flame } do
		local offset = direction:ToObjectSpace(part.CFrame)
		local finalCF = direction * CFrame.new(0, 0, -distance) * offset
		TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = finalCF }):Play()
	end
	task.delay(duration, function()
		trail.Enabled = false
		rocket:Destroy()
		tip:Destroy()
		flame.Transparency = 1
		Debris:AddItem(flame, 1)
		Effects.Explosion(to, radius, color)
	end)
end

-- Explosión de partículas cuando alguien es eliminado
function Effects.DeathBurst(position, color)
	color = color or Color3.new(1, 1, 1)
	local anchor = emitterAnchor(position, Vector3.yAxis, 2.5)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(color, Color3.new(1, 1, 1)),
		LightEmission = 1,
		Size = seq(0.9, 0),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(10, 20),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-180, 180),
		Drag = 4,
	}, 24)
	emit(anchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.6)),
		Size = seq(1.5, 4),
		Transparency = seq(0.4, 1),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(180, 180),
	}, 6)
	local flash = fxPart({
		Color = color,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
		Transparency = 0.2,
	})
	TweenService:Create(flash, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = Vector3.new(7, 7, 7), Transparency = 1 }):Play()
	Debris:AddItem(flash, 0.4)
end

---------------------------------------------------------------------------
-- Efectos de eliminación (ver KillEffects.luau)
---------------------------------------------------------------------------

-- Emoji o texto que flota en el mundo (BillboardGui) y se desvanece
local function floatingText(position, text, size, rise, duration, color)
	local anchor = fxPart({ Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1, CFrame = CFrame.new(position) })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(size, size)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = 400
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Parent = gui
	TweenService:Create(anchor, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(position + rise) }):Play()
	TweenService:Create(label, TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, duration * 0.5), { TextTransparency = 1 }):Play()
	Debris:AddItem(anchor, duration + 0.1)
end

-- Piezas sueltas que salen disparadas con física (confeti, monedas, cristales)
local function debrisBurst(position, count, makePart, speed, lifetime)
	for _ = 1, count do
		local part = makePart()
		part.Anchored = false
		part.CanCollide = false -- no empujan a nadie; desaparecen antes de caer mucho
		part.CFrame = CFrame.new(position + Vector3.new(math.random() - 0.5, math.random() * 0.5, math.random() - 0.5))
			* CFrame.Angles(math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		local dir = Vector3.new(math.random() - 0.5, 0.6 + math.random() * 0.8, math.random() - 0.5).Unit
		part.AssemblyLinearVelocity = dir * speed * (0.6 + math.random() * 0.6)
		part.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, lifetime - 0.4), { Transparency = 1 }):Play()
		Debris:AddItem(part, lifetime)
	end
end

local CONFETTI_COLORS = {
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(255, 210, 40),
	Color3.fromRGB(60, 200, 255),
	Color3.fromRGB(120, 255, 120),
	Color3.fromRGB(200, 100, 255),
	Color3.fromRGB(255, 140, 30),
}

local function flashBall(position, color, size, duration)
	local flash = fxPart({ Color = color, Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(position), Transparency = 0.2 })
	TweenService:Create(flash, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Size = Vector3.one * size, Transparency = 1 }):Play()
	Debris:AddItem(flash, duration + 0.05)
	return flash
end

local KILL_FX = {}

KILL_FX.Confeti = function(position)
	debrisBurst(position, 36, function()
		return fxPart({
			Size = Vector3.new(0.35, 0.05, 0.25),
			Color = CONFETTI_COLORS[math.random(1, #CONFETTI_COLORS)],
			Material = Enum.Material.SmoothPlastic,
		})
	end, 22, 1.6)
	flashBall(position, Color3.fromRGB(255, 230, 120), 5, 0.3)
	floatingText(position + Vector3.new(0, 2, 0), "🎉", 90, Vector3.new(0, 4, 0), 1.4)
end

KILL_FX.Amor = function(position)
	for i = 1, 7 do
		task.delay(i * 0.06, function()
			local offset = Vector3.new((math.random() - 0.5) * 4, math.random() * 1.5, (math.random() - 0.5) * 4)
			floatingText(position + offset, "💖", 50 + math.random(0, 30), Vector3.new(0, 6 + math.random() * 3, 0), 1.6)
		end)
	end
	local anchor = emitterAnchor(position, Vector3.yAxis, 2)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(255, 90, 170), Color3.fromRGB(255, 200, 230)),
		LightEmission = 1,
		Size = seq(0.6, 0),
		Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
	}, 20)
end

KILL_FX.Fuego = function(position)
	local anchor = emitterAnchor(position - Vector3.new(0, 2.5, 0), Vector3.yAxis, 2.2)
	emit(anchor, {
		Texture = TEX.Fire,
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 60, 0)),
		LightEmission = 1,
		Size = seq(3, 0.5),
		Transparency = seq(0, 1),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(14, 24),
		SpreadAngle = Vector2.new(12, 12),
		Acceleration = Vector3.new(0, 10, 0),
	}, 40)
	emit(anchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(Color3.fromRGB(60, 50, 50)),
		Size = seq(2, 6),
		Transparency = seq(0.3, 1),
		Lifetime = NumberRange.new(1.2, 1.8),
		Speed = NumberRange.new(8, 14),
		SpreadAngle = Vector2.new(20, 20),
	}, 10)
	flashBall(position, Color3.fromRGB(255, 120, 20), 8, 0.35)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 30)
	light.Range = 24
	light.Brightness = 4
	light.Parent = anchor
	TweenService:Create(light, TweenInfo.new(1.2), { Brightness = 0 }):Play()
end

KILL_FX.Hielo = function(position)
	debrisBurst(position, 14, function()
		return fxPart({
			Size = Vector3.new(0.4, 1.2 + math.random(), 0.4),
			Color = Color3.fromRGB(170, 230, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
			Reflectance = 0.3,
		})
	end, 16, 1.4)
	local anchor = emitterAnchor(position, Vector3.yAxis, 2)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 220, 255)),
		LightEmission = 1,
		Size = seq(0.8, 0),
		Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -6, 0),
		Drag = 2,
	}, 30)
	flashBall(position, Color3.fromRGB(150, 230, 255), 7, 0.4)
	floatingText(position + Vector3.new(0, 2, 0), "❄️", 80, Vector3.new(0, 3, 0), 1.3)
end

KILL_FX.Fantasma = function(position)
	floatingText(position, "👻", 110, Vector3.new(0, 14, 0), 2.2)
	local anchor = emitterAnchor(position, Vector3.yAxis, 2.5)
	emit(anchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(Color3.fromRGB(230, 235, 255)),
		Size = seq(1.5, 5),
		Transparency = seq(0.3, 1),
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(3, 7),
		SpreadAngle = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, 4, 0),
	}, 14)
end

KILL_FX.Calavera = function(position)
	floatingText(position + Vector3.new(0, 1, 0), "💀", 150, Vector3.new(0, 5, 0), 1.8)
	local anchor = emitterAnchor(position, Vector3.yAxis, 2.5)
	emit(anchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(Color3.fromRGB(200, 20, 30), Color3.fromRGB(40, 0, 0)),
		Size = seq(2, 7),
		Transparency = seq(0.2, 1),
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(4, 9),
		SpreadAngle = Vector2.new(180, 180),
	}, 18)
	flashBall(position, Color3.fromRGB(255, 30, 40), 8, 0.35)
end

KILL_FX.Rayo = function(position)
	-- Zigzag de neón desde el cielo
	local top = position + Vector3.new((math.random() - 0.5) * 6, 60, (math.random() - 0.5) * 6)
	local points = { top }
	for i = 1, 7 do
		local p = top:Lerp(position, i / 8) + Vector3.new((math.random() - 0.5) * 5, 0, (math.random() - 0.5) * 5)
		table.insert(points, p)
	end
	table.insert(points, position)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local seg = fxPart({
			Size = Vector3.new(0.5, 0.5, (b - a).Magnitude),
			CFrame = safeLookAt((a + b) / 2, b - a),
			Color = Color3.fromRGB(190, 230, 255),
		})
		TweenService:Create(seg, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.1), { Transparency = 1, Size = Vector3.new(0.1, 0.1, seg.Size.Z) }):Play()
		Debris:AddItem(seg, 0.7)
	end
	local flash = flashBall(position, Color3.fromRGB(200, 240, 255), 12, 0.45)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(180, 220, 255)
	light.Range = 40
	light.Brightness = 8
	light.Parent = flash
	local anchor = emitterAnchor(position, Vector3.yAxis, 2)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(80, 180, 255)),
		LightEmission = 1,
		Size = seq(1, 0),
		Lifetime = NumberRange.new(0.3, 0.7),
		Speed = NumberRange.new(20, 35),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 5,
	}, 30)
end

KILL_FX.Monedas = function(position)
	debrisBurst(position, 22, function()
		local coin = fxPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.15, 0.8, 0.8),
			Color = Color3.fromRGB(255, 200, 50),
			Material = Enum.Material.Foil,
		})
		return coin
	end, 24, 1.6)
	floatingText(position + Vector3.new(0, 2, 0), "+🪙", 80, Vector3.new(0, 4, 0), 1.4, Color3.fromRGB(255, 220, 80))
	local anchor = emitterAnchor(position, Vector3.yAxis, 2)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 180, 30)),
		LightEmission = 1,
		Size = seq(0.8, 0),
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(10, 18),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
	}, 24)
end

KILL_FX.AgujeroNegro = function(position)
	local hole = fxPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.5, 0.5, 0.5),
		CFrame = CFrame.new(position),
		Color = Color3.fromRGB(5, 0, 10),
		Material = Enum.Material.SmoothPlastic,
	})
	local ring = fxPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 1, 1),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(170, 60, 255),
	})
	TweenService:Create(hole, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Size = Vector3.one * 6 }):Play()
	TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Size = Vector3.new(0.2, 11, 11) }):Play()
	-- Partículas que nacen en una esfera grande y caen hacia el centro
	local anchor = fxPart({ Size = Vector3.new(12, 12, 12), Transparency = 1, CFrame = CFrame.new(position) })
	Debris:AddItem(anchor, 2.5)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 80, 200)),
		LightEmission = 1,
		Size = seq(0.7, 0),
		Lifetime = NumberRange.new(0.5, 0.6),
		Speed = NumberRange.new(10, 12),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
	}, 50)
	task.delay(1.1, function()
		TweenService:Create(hole, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.one * 0.1 }):Play()
		TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.new(0.2, 0.1, 0.1), Transparency = 1 }):Play()
	end)
	Debris:AddItem(hole, 1.6)
	Debris:AddItem(ring, 1.6)
end

-- Dibuja el efecto de eliminación indicado (color = color del equipo de la víctima, para el normal)
-- Pintura: bolas de pintura de colores que saltan y manchas en el suelo alrededor
KILL_FX.Pintura = function(position)
	debrisBurst(position, 18, function()
		local ball = fxPart({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.6, 0.6, 0.6),
			Color = PAINT_COLORS[math.random(1, #PAINT_COLORS)],
			Material = Enum.Material.SmoothPlastic,
		})
		return ball
	end, 20, 1.4)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	for i = 1, 6 do
		local angle = i / 6 * math.pi * 2
		local origin = position + Vector3.new(math.cos(angle) * 2.5, 1, math.sin(angle) * 2.5)
		local hit = workspace:Raycast(origin, Vector3.new(0, -8, 0), params)
		if hit and not hit.Instance.Parent:FindFirstChildOfClass("Humanoid") then
			local anchor = emitterAnchor(hit.Position, hit.Normal, 1)
			paintSplat(anchor, hit.Position, hit.Normal, false)
		end
	end
	floatingText(position + Vector3.new(0, 2, 0), "🎨", 80, Vector3.new(0, 4, 0), 1.3)
end

-- Arcoíris: un arco de bolas de colores que sale del enemigo y se desvanece
KILL_FX.Arcoiris = function(position)
	for i = 0, 13 do
		task.delay(i * 0.035, function()
			local t = i / 13
			local offset = Vector3.new((t - 0.5) * 9, math.sin(t * math.pi) * 6 + 1, 0)
			local ball = fxPart({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.1, 1.1, 1.1),
				Color = Color3.fromHSV(t * 0.85, 0.8, 1),
				CFrame = CFrame.new(position + offset),
			})
			TweenService:Create(ball, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2) }):Play()
			Debris:AddItem(ball, 1.3)
		end)
	end
	flashBall(position, Color3.fromRGB(255, 255, 255), 5, 0.3)
	floatingText(position + Vector3.new(0, 3, 0), "🌈", 90, Vector3.new(0, 3, 0), 1.5)
end

-- Murciélagos: salen volando hacia arriba en todas direcciones, con humo morado
KILL_FX.Murcielagos = function(position)
	for i = 1, 9 do
		task.delay(i * 0.04, function()
			local angle = math.random() * math.pi * 2
			local velocity = Vector3.new(math.cos(angle) * (4 + math.random() * 4), 6 + math.random() * 5, math.sin(angle) * (4 + math.random() * 4))
			floatingText(position + Vector3.new(0, 1, 0), "🦇", 40 + math.random(0, 25), velocity, 1.4)
		end)
	end
	local anchor = emitterAnchor(position, Vector3.yAxis, 2.5)
	emit(anchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(Color3.fromRGB(140, 60, 200), Color3.fromRGB(40, 20, 60)),
		Size = seq(1.5, 4),
		Transparency = seq(0.3, 1),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 2, 0),
	}, 12)
	flashBall(position, Color3.fromRGB(170, 80, 255), 4, 0.25)
end

-- Calabazas: calabacitas naranjas que saltan y una gran 🎃 que sube
KILL_FX.Calabazas = function(position)
	debrisBurst(position, 10, function()
		return fxPart({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.9, 0.75, 0.9),
			Color = Color3.fromRGB(255, 130, 20),
			Material = Enum.Material.SmoothPlastic,
		})
	end, 18, 1.5)
	flashBall(position, Color3.fromRGB(255, 160, 40), 5, 0.3)
	floatingText(position + Vector3.new(0, 2, 0), "🎃", 110, Vector3.new(0, 3.5, 0), 1.6)
	task.delay(0.25, function()
		floatingText(position + Vector3.new(1.5, 3, 0), "😈", 60, Vector3.new(0, 2.5, 0), 1.2)
	end)
end

function Effects.KillEffect(effectId, position, color)
	local fn = KILL_FX[effectId]
	if fn then
		fn(position)
	else
		Effects.DeathBurst(position, color)
	end
end

return Effects
