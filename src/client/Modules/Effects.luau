-- Efectos visuales (solo en el cliente): fogonazo, balas trazadoras, impactos, casquillos y bajas.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

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
	local trail = fxPart({
		Color = color,
		Size = Vector3.new(0.03, 0.03, distance),
		CFrame = direction * CFrame.new(0, 0, -distance / 2),
		Transparency = 0.6,
	})
	TweenService:Create(trail, TweenInfo.new(0.1), { Transparency = 1 }):Play()
	Debris:AddItem(trail, 0.12)

	-- La bala
	local length = math.min(6, distance)
	local travel = math.max(distance - length, 0.01)
	local duration = math.clamp(distance / 900, 0.02, 0.25)
	local bullet = fxPart({
		Color = color,
		Size = Vector3.new(0.12, 0.12, length),
		CFrame = direction * CFrame.new(0, 0, -length / 2),
	})
	TweenService
		:Create(bullet, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = direction * CFrame.new(0, 0, -length / 2 - travel) })
		:Play()
	Debris:AddItem(bullet, duration + 0.02)
end

-- Fogonazo: estrella de luz, llamas y humo
function Effects.MuzzleFlash(attachment, color)
	if not attachment then
		return
	end
	color = color or Color3.fromRGB(255, 200, 90)
	local cf = attachment.WorldCFrame
	local spin = math.random() * math.pi
	for i = 0, 1 do
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
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 4
	light.Parent = core
	Debris:AddItem(core, 0.05)

	local anchor = emitterAnchor(cf.Position, cf.LookVector, 1.2)
	emit(anchor, {
		Texture = TEX.Fire,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 180), color),
		LightEmission = 1,
		Size = seq(0.45, 0),
		Transparency = seq(0, 1),
		Lifetime = NumberRange.new(0.04, 0.08),
		Speed = NumberRange.new(4, 8),
		SpreadAngle = Vector2.new(12, 12),
	}, 5)
	emit(anchor, {
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

-- Impacto: chispas, polvo del color de la superficie y marca de bala
function Effects.Impact(position, normal, hitPart)
	local isCharacter = hitPart ~= nil
		and hitPart.Parent ~= nil
		and (hitPart.Parent:FindFirstChildOfClass("Humanoid") ~= nil or hitPart.Parent:IsA("Accessory"))
	local anchor = emitterAnchor(position + (normal or Vector3.yAxis) * 0.05, normal, 1.5)

	if isCharacter then
		-- Destello de golpe (estilo cartoon, sin sangre)
		emit(anchor, {
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

	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(255, 230, 150)),
		LightEmission = 1,
		Size = seq(0.18, 0),
		Lifetime = NumberRange.new(0.15, 0.35),
		Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(45, 45),
		Acceleration = Vector3.new(0, -40, 0),
	}, 6)
	local dustColor = hitPart and hitPart.Color:Lerp(Color3.new(1, 1, 1), 0.3) or Color3.fromRGB(200, 200, 200)
	emit(anchor, {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(dustColor),
		Size = seq(0.3, 1.4),
		Transparency = seq(0.3, 1),
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(1.5, 3),
		SpreadAngle = Vector2.new(30, 30),
	}, 3)

	local mark = fxPart({
		Color = Color3.fromRGB(25, 25, 28),
		Material = Enum.Material.SmoothPlastic,
		Size = Vector3.new(0.22, 0.22, 0.02),
		Shape = Enum.PartType.Block,
		CFrame = safeLookAt(position, normal or Vector3.yAxis),
		Transparency = 0.15,
	})
	TweenService:Create(mark, TweenInfo.new(5, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
	Debris:AddItem(mark, 5.2)
end

-- Casquillo que sale disparado por la derecha del arma
function Effects.ShellCasing(attachment, cameraCFrame, color)
	if not attachment then
		return
	end
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

return Effects
