-- Efectos propios de cada arma en primera persona (encima de los de Effects, que son los comunes):
--   · Llamarada de boca con el color y la forma de cada arma (fuego, energía, pintura...).
--   · Las luces de neón del arma laten en reposo, destellan con cada disparo, se van poniendo al rojo
--     con el fuego sostenido y, al recargar, se apagan y vuelven a encenderse («recarga» de energía).
--   · Llamas o chispas permanentes en las armas que las piden (Calabazooka, Vortex, Guadaña...).
-- No toca WeaponController: escucha ClientState.WeaponEvent (Equip, Fire, ReloadStart, Melee...) y busca
-- el arma en la cámara. Solo cosmético y solo en tu pantalla. Se recorta con la calidad y en el móvil.
local RunService = game:GetService("RunService")

local ClientState = require(script.Parent.ClientState)
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local WeaponFX = {}

WeaponFX.Enabled = true
WeaponFX.Scale = 1.35 -- tamaño general de las llamaradas (1 = el de la tabla)

local RGB = Color3.fromRGB
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- Flame: llamarada al disparar. Core/Edge = colores (centro y borde), Size = tamaño en studs, Count =
-- lenguas por disparo, Speed, Spread (grados), Life (s), Sparks = chispas por disparo,
-- Kind = "Fire" (por defecto) | "Energy" (anillos y chispas, sin humo) | "Paint" (gotas).
-- Idle: efecto permanente { Kind = "Flame" | "Spark" | "Wisp", Color, Color2, Rate, Size, At = punto }.
-- Hot: color al que tiran las luces con el arma caliente. Back: rebufo por detrás (lanzacohetes).
local ORANGE, YELLOW, WHITE = RGB(255, 140, 40), RGB(255, 225, 120), RGB(255, 255, 255)
WeaponFX.Default = { Flame = { Core = YELLOW, Edge = ORANGE, Size = 0.55, Count = 4, Speed = 20, Spread = 14, Life = 0.07, Sparks = 2 }, Hot = RGB(255, 110, 40) }
WeaponFX.Weapons = {
	ARX27 = { Flame = { Core = YELLOW, Edge = ORANGE, Size = 0.6, Count = 4, Speed = 22, Spread = 12, Life = 0.07, Sparks = 2 } },
	Specter9 = { Flame = { Core = YELLOW, Edge = RGB(255, 100, 30), Size = 0.45, Count = 3, Speed = 24, Spread = 18, Life = 0.055, Sparks = 2 } },
	NovaDrift = { Flame = { Core = RGB(235, 255, 160), Edge = RGB(60, 220, 150), Size = 0.45, Count = 3, Speed = 24, Spread = 16, Life = 0.055, Sparks = 2 }, Hot = RGB(220, 255, 120) },
	HavocPump = { Flame = { Core = YELLOW, Edge = RGB(255, 80, 20), Size = 1.1, Count = 9, Speed = 26, Spread = 34, Life = 0.11, Sparks = 10 } },
	BreachHammer = { Flame = { Core = RGB(255, 240, 150), Edge = RGB(255, 60, 30), Size = 1.0, Count = 8, Speed = 26, Spread = 30, Life = 0.1, Sparks = 8 }, Hot = RGB(255, 60, 30) },
	Signal7 = { Flame = { Core = WHITE, Edge = RGB(120, 220, 255), Size = 0.9, Count = 6, Speed = 46, Spread = 5, Life = 0.1, Sparks = 6 } },
	GhostlineXR = { Flame = { Core = RGB(200, 220, 255), Edge = RGB(80, 124, 255), Size = 0.35, Count = 2, Speed = 16, Spread = 8, Life = 0.08, Sparks = 0 }, Hot = RGB(140, 170, 255) },
	RaptorDMR = { Flame = { Core = RGB(255, 240, 170), Edge = RGB(240, 170, 50), Size = 0.75, Count = 5, Speed = 34, Spread = 8, Life = 0.085, Sparks = 4 } },
	TitanLMG = { Flame = { Core = YELLOW, Edge = RGB(255, 90, 20), Size = 0.85, Count = 5, Speed = 24, Spread = 20, Life = 0.08, Sparks = 4 } },
	VortexBR = {
		Flame = { Kind = "Energy", Core = RGB(235, 215, 255), Edge = RGB(160, 96, 255), Size = 0.8, Count = 4, Speed = 30, Spread = 6, Life = 0.1, Sparks = 6 },
		Idle = { Kind = "Spark", Color = RGB(190, 140, 255), Color2 = RGB(120, 220, 255), Rate = 7, Size = 0.14, At = "Muzzle" },
		Hot = RGB(235, 215, 255),
	},
	NovaLauncher = {
		Flame = { Core = YELLOW, Edge = RGB(255, 90, 10), Size = 1.5, Count = 10, Speed = 20, Spread = 30, Life = 0.16, Sparks = 12 },
		Back = { Core = YELLOW, Edge = RGB(255, 90, 10), Size = 1.6, Count = 10 },
		Idle = { Kind = "Flame", Color = RGB(255, 170, 60), Color2 = RGB(255, 80, 20), Rate = 5, Size = 0.12, At = "Muzzle" },
	},
	Calabazooka = {
		Flame = { Core = RGB(255, 235, 140), Edge = RGB(255, 120, 20), Size = 1.5, Count = 10, Speed = 20, Spread = 32, Life = 0.16, Sparks = 14, SparkColor = RGB(120, 230, 90) },
		Back = { Core = RGB(200, 140, 255), Edge = RGB(150, 70, 220), Size = 1.5, Count = 9 },
		Idle = { Kind = "Flame", Color = RGB(255, 200, 60), Color2 = RGB(255, 110, 20), Rate = 12, Size = 0.2, At = "Muzzle", Flicker = true },
		Hot = RGB(255, 235, 140),
	},
	Viper = { Flame = { Core = YELLOW, Edge = ORANGE, Size = 0.4, Count = 3, Speed = 20, Spread = 14, Life = 0.055, Sparks = 1 } },
	HandCannon = { Flame = { Core = RGB(255, 240, 180), Edge = RGB(255, 150, 40), Size = 1.0, Count = 7, Speed = 24, Spread = 26, Life = 0.1, Sparks = 8 }, Hot = RGB(255, 205, 95) },
	PhantomSidewind = { Flame = { Core = RGB(255, 220, 245), Edge = RGB(235, 60, 150), Size = 0.45, Count = 3, Speed = 22, Spread = 14, Life = 0.055, Sparks = 2 }, Hot = RGB(255, 140, 200) },
	SplatX = { Flame = { Kind = "Paint", Core = RGB(255, 60, 170), Edge = RGB(60, 220, 255), Size = 0.3, Count = 5, Speed = 16, Spread = 24, Life = 0.25, Sparks = 0 }, Hot = RGB(255, 220, 50) },
	Crossbow = { Flame = { Kind = "Energy", Core = RGB(255, 230, 160), Edge = RGB(255, 190, 70), Size = 0.25, Count = 1, Speed = 10, Spread = 4, Life = 0.08, Sparks = 3 } },
	Katana = { Idle = { Kind = "Spark", Color = RGB(120, 230, 255), Color2 = WHITE, Rate = 4, Size = 0.1, At = "Muzzle" }, Slash = RGB(120, 230, 255) },
	Scythe = { Idle = { Kind = "Wisp", Color = RGB(120, 255, 80), Color2 = RGB(40, 160, 60), Rate = 8, Size = 0.28, At = "Muzzle" }, Slash = RGB(120, 255, 80) },
	Knife = { Slash = RGB(120, 230, 255) },
	ToyHammer = { Slash = RGB(255, 220, 80) },
}

---------------------------------------------------------------------------
-- Estado del arma en mano
---------------------------------------------------------------------------

local camera = workspace.CurrentCamera
local model -- el Viewmodel enlazado
local style = WeaponFX.Default
local neon = {} -- { Part, Base }
local light, lightBase
local flameEmitter, sparkEmitter, backEmitter, idleLight
local flash, heat = 0, 0
local reloadStart, reloadDuration = nil, 0
local breath = 0

local function factor()
	if not WeaponFX.Enabled then
		return 0
	end
	local quality = ClientState.EffectiveQuality
	local f = quality == "Baja" and 0.45 or (quality == "Media" and 0.8 or 1)
	if InputMode.TouchUI() then
		f *= 0.7
	end
	return f
end

local function colors(a, b, c)
	return ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.35, b), ColorSequenceKeypoint.new(1, c or b) })
end

local function sizes(from, mid, to)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(0.3, mid), NumberSequenceKeypoint.new(1, to) })
end

local function fade(from)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(0.6, math.min(1, from + 0.3)), NumberSequenceKeypoint.new(1, 1) })
end

local function emitter(parent, name, props)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Rate = 0
	e.LightEmission = 1
	e.LightInfluence = 0
	e.LockedToPart = true
	e.EmissionDirection = Enum.NormalId.Front
	for key, value in props do
		e[key] = value
	end
	e.Parent = parent
	return e
end

local function clear()
	for _, entry in neon do
		if entry.Part.Parent then
			entry.Part.Color = entry.Base
		end
	end
	table.clear(neon)
	if light and light.Parent and lightBase then
		light.Brightness = lightBase
	end
	model, light, lightBase = nil, nil, nil
	flameEmitter, sparkEmitter, backEmitter, idleLight = nil, nil, nil, nil
	flash, heat, reloadStart = 0, 0, nil
end

local function attach(viewmodel, weaponName)
	clear()
	model = viewmodel
	style = WeaponFX.Weapons[weaponName] or WeaponFX.Default
	local handle = viewmodel.PrimaryPart
	if not handle then
		return
	end
	for _, part in viewmodel:GetDescendants() do
		-- (las skins con «Pulse» ya animan su neón en WeaponController: esas luces no se tocan)
		if not ClientState.ViewmodelPulse and part:IsA("BasePart") and part.Material == Enum.Material.Neon then
			local role = part:GetAttribute("Role")
			if role == "Accent" or role == "Accent2" or role == "Core" then
				table.insert(neon, { Part = part, Base = part.Color })
			end
		end
	end
	light = handle:FindFirstChild("NeonGlow")
	lightBase = light and light.Brightness or nil

	local muzzle = handle:FindFirstChild("Muzzle")
	local flame = style.Flame
	if muzzle and flame then
		local kind = flame.Kind or "Fire"
		local size = flame.Size * WeaponFX.Scale
		flameEmitter = emitter(muzzle, "FXFlame", {
			Texture = kind == "Paint" and SMOKE or FIRE,
			Color = colors(WHITE, flame.Core, flame.Edge),
			Size = kind == "Energy" and sizes(size * 0.3, size, size * 0.15) or sizes(size * 0.55, size, size * 0.2),
			Transparency = fade(kind == "Paint" and 0.15 or 0.05),
			Lifetime = NumberRange.new(flame.Life * 0.7, flame.Life * 1.3),
			Speed = NumberRange.new(flame.Speed * 0.6, flame.Speed * 1.2),
			SpreadAngle = Vector2.new(flame.Spread, flame.Spread),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-260, 260),
			Drag = 7,
			LightEmission = kind == "Paint" and 0.3 or 1,
			ZOffset = 0.4,
		})
		if (flame.Sparks or 0) > 0 then
			sparkEmitter = emitter(muzzle, "FXSparks", {
				Texture = SPARK,
				Color = colors(WHITE, flame.SparkColor or flame.Core, flame.SparkColor or flame.Edge),
				Size = sizes(0.09, 0.07, 0),
				Transparency = fade(0),
				Lifetime = NumberRange.new(0.12, 0.3),
				Speed = NumberRange.new(flame.Speed * 0.8, flame.Speed * 1.8),
				SpreadAngle = Vector2.new(flame.Spread * 1.6 + 8, flame.Spread * 1.6 + 8),
				Acceleration = Vector3.new(0, -26, 0),
				Drag = 3,
				LockedToPart = false,
			})
		end
	end
	-- Rebufo (lanzacohetes): desde la cola del arma, hacia atrás
	if style.Back and muzzle then
		local back = Instance.new("Attachment")
		back.Name = "FXBack"
		local _, size = viewmodel:GetBoundingBox()
		back.Position = Vector3.new(muzzle.Position.X, muzzle.Position.Y, muzzle.Position.Z + size.Z * 0.98)
		back.Parent = handle
		backEmitter = emitter(back, "FXBackblast", {
			Texture = FIRE,
			Color = colors(WHITE, style.Back.Core, style.Back.Edge),
			Size = sizes(style.Back.Size * 0.4, style.Back.Size, style.Back.Size * 0.5),
			Transparency = fade(0.1),
			Lifetime = NumberRange.new(0.12, 0.26),
			Speed = NumberRange.new(14, 30),
			SpreadAngle = Vector2.new(24, 24),
			Rotation = NumberRange.new(0, 360),
			EmissionDirection = Enum.NormalId.Back,
			Drag = 5,
			LockedToPart = false,
		})
	end
	-- Efecto permanente
	local idle = style.Idle
	local at = idle and handle:FindFirstChild(idle.At or "Muzzle")
	if idle and at and factor() > 0 then
		local wisp = idle.Kind == "Wisp"
		local spark = idle.Kind == "Spark"
		emitter(at, "FXIdle", {
			Texture = spark and SPARK or (wisp and SMOKE or FIRE),
			Color = colors(WHITE, idle.Color, idle.Color2 or idle.Color),
			Size = sizes(idle.Size * 0.5, idle.Size, 0),
			Transparency = fade(wisp and 0.45 or 0.1),
			Lifetime = wisp and NumberRange.new(0.5, 0.9) or NumberRange.new(0.18, 0.4),
			Speed = spark and NumberRange.new(0.5, 2.5) or NumberRange.new(0.6, 1.6),
			SpreadAngle = spark and Vector2.new(180, 180) or Vector2.new(18, 18),
			EmissionDirection = spark and Enum.NormalId.Front or Enum.NormalId.Top,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-120, 120),
			Acceleration = spark and Vector3.zero or Vector3.new(0, 1.5, 0),
			LightEmission = wisp and 0.7 or 1,
			Rate = idle.Rate * factor(),
			LockedToPart = spark,
		})
		if idle.Flicker then
			idleLight = Instance.new("PointLight")
			idleLight.Name = "FXIdleLight"
			idleLight.Color = idle.Color
			idleLight.Range = 5
			idleLight.Brightness = 0.6
			idleLight.Shadows = false
			idleLight.Parent = at
		end
	end
end

---------------------------------------------------------------------------
-- Eventos del arma
---------------------------------------------------------------------------

local function onFire()
	local f = factor()
	if not model or f <= 0 then
		return
	end
	flash = 1
	heat = math.min(1, heat + 0.07)
	local flame = style.Flame
	if flameEmitter and flame then
		flameEmitter:Emit(math.max(1, math.floor(flame.Count * f + 0.5)))
		if flame.Kind == "Paint" then
			-- (cada disparo, una mezcla distinta de los dos colores)
			local mix = math.random()
			flameEmitter.Color = colors(WHITE, flame.Core:Lerp(flame.Edge, mix), flame.Core:Lerp(flame.Edge, 1 - mix))
		end
	end
	if sparkEmitter and flame then
		sparkEmitter:Emit(math.floor((flame.Sparks or 0) * f + 0.5))
	end
	if backEmitter and style.Back then
		backEmitter:Emit(math.max(1, math.floor(style.Back.Count * f + 0.5)))
	end
end

local function onMelee()
	local f = factor()
	if not model or f <= 0 or not style.Slash then
		return
	end
	flash = 1
	local handle = model.PrimaryPart
	local tip = handle and handle:FindFirstChild("Muzzle")
	if not tip then
		return
	end
	local slash = tip:FindFirstChild("FXSlash")
	if not slash then
		slash = emitter(tip, "FXSlash", {
			Texture = SPARK,
			Color = colors(WHITE, style.Slash, style.Slash),
			Size = sizes(0.16, 0.12, 0),
			Transparency = fade(0),
			Lifetime = NumberRange.new(0.15, 0.35),
			Speed = NumberRange.new(1, 5),
			SpreadAngle = Vector2.new(180, 180),
			LockedToPart = false,
		})
	end
	slash:Emit(math.max(2, math.floor(10 * f)))
end

local function step(dt)
	if not model then
		return
	end
	if not model.Parent then
		clear()
		return
	end
	flash = math.max(0, flash - dt * 7)
	heat = math.max(0, heat - dt * 0.28)
	breath += dt
	-- Recarga: las luces caen, se quedan casi apagadas y vuelven a subir al final, con un destello
	local power = 1
	if reloadStart then
		local t = (os.clock() - reloadStart) / math.max(0.1, reloadDuration)
		if t >= 1 then
			reloadStart = nil
			flash = 1
		elseif t < 0.2 then
			power = 1 - t / 0.2 * 0.85
		elseif t < 0.7 then
			power = 0.15
		else
			power = 0.15 + (t - 0.7) / 0.3 * 0.85
		end
	end
	local pulse = 0.82 + 0.18 * math.sin(breath * 2.4)
	local hot = style.Hot or WeaponFX.Default.Hot
	for _, entry in neon do
		local color = entry.Base:Lerp(hot, heat * 0.55)
		color = color:Lerp(Color3.new(1, 1, 1), flash * 0.65)
		local level = power * pulse
		entry.Part.Color = Color3.new(color.R * level, color.G * level, color.B * level)
	end
	if light and lightBase then
		light.Brightness = lightBase * power * pulse + flash * 1.6 + heat * 0.5
	end
	if idleLight then
		idleLight.Brightness = 0.45 + 0.25 * math.noise(breath * 9, 3.1) + flash * 1.5
	end
end

function WeaponFX.Init()
	ClientState.WeaponEvent.Event:Connect(function(name, weaponName, info)
		if name == "Equip" then
			-- (el arma se crea justo antes de este aviso; por si acaso, se busca también un momento después)
			local function bind()
				local viewmodel = camera:FindFirstChild("Viewmodel")
				if viewmodel and viewmodel ~= model then
					attach(viewmodel, tostring(weaponName))
				end
			end
			bind()
			task.delay(0.05, bind)
		elseif name == "Unequip" then
			clear()
		elseif name == "Fire" then
			if not model or not model.Parent then
				local viewmodel = camera:FindFirstChild("Viewmodel")
				if viewmodel then
					attach(viewmodel, tostring(weaponName))
				end
			end
			onFire()
		elseif name == "ReloadStart" then
			reloadStart = os.clock()
			reloadDuration = type(info) == "table" and tonumber(info.Duration) or 1.5
		elseif name == "ReloadCancel" then
			reloadStart = nil
		elseif name == "Melee" then
			onMelee()
		end
	end)
	RunService.RenderStepped:Connect(step)
end

return WeaponFX
