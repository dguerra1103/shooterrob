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
		part.CanCollide = true -- rebotan en el suelo
		part.Massless = true
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
	end, 22, 2.2)
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
	end, 16, 1.8)
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
	end, 24, 2.4)
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
	-- Partículas que caen hacia el centro
	local anchor = emitterAnchor(position, Vector3.yAxis, 2.5)
	emit(anchor, {
		Texture = TEX.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 80, 200)),
		LightEmission = 1,
		Size = seq(0.7, 0),
		Lifetime = NumberRange.new(0.9, 1.2),
		Speed = NumberRange.new(-14, -10),
		SpreadAngle = Vector2.new(180, 180),
	}, 40)
	task.delay(1.1, function()
		TweenService:Create(hole, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.one * 0.1 }):Play()
		TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.new(0.2, 0.1, 0.1), Transparency = 1 }):Play()
	end)
	Debris:AddItem(hole, 1.6)
	Debris:AddItem(ring, 1.6)
end

-- Dibuja el efecto de eliminación indicado (color = color del equipo de la víctima, para el normal)
function Effects.KillEffect(effectId, position, color)
	local fn = KILL_FX[effectId]
	if fn then
		fn(position)
	else
		Effects.DeathBurst(position, color)
	end
end

return Effects
