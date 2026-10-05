-- PUEBLO VAQUERO: calle mayor del Oeste a pleno sol. En el centro, el depósito de agua sobre patas
-- (cobertura entre las patas) con el abrevadero; a cada lado de la calle, edificios de madera con
-- fachada falsa: el saloon y el banco tienen escalera por detrás para subir a la azotea (la fachada
-- hace de parapeto hacia la calle). Por detrás, callejones de flanqueo con vallas, carros, balas de
-- heno y cactus. De fondo, mesetas rojas y un tren de vapor. Simétrico.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "WildWest",
	Name = "Pueblo Vaquero",
	Icon = "🤠",
	Description = "Oeste · calle mayor · saloon, banco y depósito de agua",
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.08, Sat = 0.14 }, -- grises cálidos de desierto
	ClockTime = 15.2,
	Latitude = 25,
	Brightness = 3.2,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(135, 120, 110),
	OutdoorAmbient = Color3.fromRGB(190, 170, 150),
	Atmosphere = { Density = 0.25, Offset = 0.15, Color = Color3.fromRGB(255, 220, 180), Decay = Color3.fromRGB(220, 150, 100), Glare = 0.1, Haze = 1 },
	Color = { Saturation = 0.22, Contrast = 0.07, Brightness = 0.03, Tint = Color3.fromRGB(255, 245, 230) },
	Bloom = { Intensity = 0.3, Size = 22, Threshold = 2 },
	Clouds = 0.2,
	SunRays = 0.06,
	ShadowSoftness = 0.25,
	Wind = Vector3.new(6, 0, 2),
	TerrainColors = {
		Sand = Color3.fromRGB(230, 190, 130),
		Sandstone = Color3.fromRGB(200, 110, 70),
		Rock = Color3.fromRGB(170, 100, 70),
		Ground = Color3.fromRGB(200, 150, 100),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local DIRT = RGB(222, 180, 125) -- tierra de la calle
local DIRT_DARK = RGB(200, 155, 105)
local WOOD = RGB(176, 120, 70)
local WOOD_DARK = RGB(120, 78, 45)
local WOOD_RED = RGB(190, 75, 55)
local WOOD_TEAL = RGB(80, 160, 165)
local WOOD_CREAM = RGB(240, 220, 175)
local WOOD_MUSTARD = RGB(225, 175, 70)
local CACTUS = RGB(90, 170, 80)
local HAY = RGB(240, 200, 90)
local SMOOTH = Enum.Material.SmoothPlastic
local PLANKS = Enum.Material.WoodPlanks

local LENGTH, WIDTH = 200, 130

-- Edificio de madera con fachada falsa (la fachada sobresale por encima del tejado: parapeto hacia la
-- calle), porche con tejadillo y postes, ventanas y letrero. La puerta mira hacia -Z del cf.
local function westernBuilding(cf, size, color, signText, options)
	options = options or {}
	local trim = color:Lerp(Color3.new(1, 1, 1), 0.45)
	Kit.block("Walls", size, cf * CFrame.new(0, size.Y / 2, 0), color, PLANKS)
	Kit.contactShadow(cf, size.X + 0.4, size.Z + 0.4, false)
	-- Fachada falsa (parapeto de la azotea hacia la calle)
	local frontH = 3 -- (a la altura del pecho: se dispara por encima agachándose detrás)
	local front = Kit.block("FalseFront", V(size.X + 0.6, frontH, 1), cf * CFrame.new(0, size.Y + frontH / 2, -(size.Z / 2 - 0.5)), color, PLANKS)
	Kit.deco("FrontCap", V(size.X + 1.2, 0.6, 1.4), cf * CFrame.new(0, size.Y + frontH + 0.3, -(size.Z / 2 - 0.5)), trim, SMOOTH)
	-- Letrero grande en la fachada
	local board = Kit.deco("SignBoard", V(size.X * 0.7, 2.6, 0.3), cf * CFrame.new(0, size.Y + 1.6, -(size.Z / 2 + 0.1)), WOOD_CREAM, SMOOTH)
	Kit.sign(board, Enum.NormalId.Front, signText, RGB(120, 50, 30), RGB(255, 240, 210))
	Kit.sign(board, Enum.NormalId.Back, signText, RGB(120, 50, 30), RGB(255, 240, 210))
	-- Porche: tablado, tejadillo y postes
	local porchDepth = 4
	Kit.deco("Porch", V(size.X, 0.6, porchDepth), cf * CFrame.new(0, 0.3, -(size.Z / 2 + porchDepth / 2)), WOOD_DARK, PLANKS)
	Kit.deco("PorchRoof", V(size.X + 0.4, 0.4, porchDepth + 0.6), cf * CFrame.new(0, 7.2, -(size.Z / 2 + porchDepth / 2)) * CFrame.Angles(rad(-8), 0, 0), trim, PLANKS)
	for i = 0, 3 do
		local x = -size.X / 2 + 0.6 + i * (size.X - 1.2) / 3
		Kit.block("PorchPost", V(0.6, 7, 0.6), cf * CFrame.new(x, 3.5, -(size.Z / 2 + porchDepth - 0.4)), WOOD_DARK, Enum.Material.Wood)
	end
	-- Puerta batiente y ventanas
	local doorCf = cf * CFrame.new(options.DoorX or 0, 3, -(size.Z / 2 + 0.12))
	for _, s in { -1, 1 } do
		Kit.deco("SwingDoor", V(1.6, 3, 0.2), doorCf * CFrame.new(s * 0.85, 0.2, 0), WOOD_DARK, Enum.Material.Wood)
	end
	Kit.deco("DoorDark", V(3.6, 6, 0.1), doorCf * CFrame.new(0, 0, 0.05), RGB(40, 28, 20), SMOOTH)
	local windows = math.max(1, math.floor(size.X / 7))
	for i = 1, windows do
		local x = -size.X / 2 + (i - 0.5) * size.X / windows
		if math.abs(x - (options.DoorX or 0)) > 3 then
			Kit.deco("Window", V(2.4, 2.8, 0.2), cf * CFrame.new(x, 3.6, -(size.Z / 2 + 0.1)), RGB(60, 70, 90), Enum.Material.Glass)
			Kit.deco("WindowFrame", V(2.9, 0.35, 0.3), cf * CFrame.new(x, 2.1, -(size.Z / 2 + 0.15)), trim, SMOOTH)
		end
		if size.Y > 9 then
			-- Ventanas del piso de arriba
			Kit.deco("Window", V(2.2, 2.6, 0.2), cf * CFrame.new(x, size.Y - 3, -(size.Z / 2 + 0.1)), RGB(60, 70, 90), Enum.Material.Glass)
		end
	end
	-- Rayas de las tablas (más relieve)
	for y = 1.5, size.Y - 1, 2.5 do
		Kit.deco("PlankLine", V(size.X + 0.05, 0.12, size.Z + 0.05), cf * CFrame.new(0, y, 0), color:Lerp(Color3.new(0, 0, 0), 0.2), SMOOTH)
	end
	-- Escalera por detrás hasta la azotea
	if options.RoofStairs then
		local x = options.StairsX or 0
		Kit.stairs(cf * V(x, 0, size.Z / 2 + 17), cf * V(x, size.Y, size.Z / 2 + 0.2), 4, WOOD, PLANKS)
	end
	return front
end

-- Depósito de agua sobre cuatro patas (las patas son cobertura; el tanque, decorado)
local function waterTower(cf)
	local legH = 14
	for _, x in { -4, 4 } do
		for _, z in { -4, 4 } do
			Kit.block("TowerLeg", V(1.2, legH, 1.2), cf * CFrame.new(x, legH / 2, z), WOOD_DARK, Enum.Material.Wood)
		end
	end
	for _, z in { -4, 4 } do
		Kit.deco("TowerBrace", V(11.5, 0.5, 0.4), cf * CFrame.new(0, legH * 0.55, z) * CFrame.Angles(0, 0, rad(40)), WOOD_DARK, Enum.Material.Wood)
	end
	Kit.deco("TowerDeck", V(11, 0.6, 11), cf * CFrame.new(0, legH + 0.3, 0), WOOD, PLANKS)
	Kit.cylinder("Tank", 8, 10, cf * CFrame.new(0, legH + 4.6, 0), RGB(150, 100, 60), Enum.Material.WoodPlanks, nil, true)
	for _, y in { 2, 5, 8 } do
		Kit.cylinder("TankBand", 0.3, 10.15, cf * CFrame.new(0, legH + 0.6 + y, 0), RGB(70, 70, 75), Enum.Material.Metal, nil, true)
	end
	for i = 0, 5 do
		Kit.deco("TankRoof", V(6.5, 0.4, 3.2), cf * CFrame.new(0, legH + 9.4, 0) * CFrame.Angles(0, rad(i * 60), 0) * CFrame.new(0, 0, -1.4) * CFrame.Angles(rad(28), 0, 0), WOOD_RED, SMOOTH)
	end
	-- Abrevadero debajo (cobertura baja)
	Kit.block("Trough", V(7, 1.8, 2.2), cf * CFrame.new(0, 0.9, 0), WOOD, Enum.Material.Wood)
	Kit.deco("TroughWater", V(6.4, 0.1, 1.6), cf * CFrame.new(0, 1.75, 0), RGB(90, 170, 210), SMOOTH)
end

-- Carro cubierto (cobertura grande)
local function wagon(cf, canvasColor)
	Kit.block("WagonBed", V(5, 2.2, 10), cf * CFrame.new(0, 2.4, 0), WOOD, PLANKS)
	for _, z in { -3.4, 3.4 } do
		for _, x in { -2.9, 2.9 } do
			local wheel = cf * CFrame.new(x, 1.7, z) * CFrame.Angles(0, 0, rad(90))
			Kit.cylinder("WagonWheel", 0.4, 3.4, wheel, WOOD_DARK, Enum.Material.Wood, nil, true)
			Kit.cylinder("WagonHub", 0.6, 0.8, wheel, RGB(60, 60, 65), Enum.Material.Metal, nil, true)
		end
	end
	-- Lona en arcos
	for i = -2, 2 do
		local a = rad(i * 30)
		Kit.deco("WagonCanvas", V(2.2, 0.3, 9), cf * CFrame.new(0, 3.5, 0) * CFrame.new(math.sin(a) * 2.9, math.cos(a) * 2.9, 0) * CFrame.Angles(0, 0, -a), canvasColor, Enum.Material.Fabric)
	end
	Kit.block("WagonCanvasBlock", V(4.6, 2.6, 8.6), cf * CFrame.new(0, 4.8, 0), canvasColor, Enum.Material.Fabric)
	Kit.deco("WagonTongue", V(0.4, 0.4, 5), cf * CFrame.new(0, 1.6, -7.2), WOOD_DARK, Enum.Material.Wood)
	Kit.contactShadow(cf, 6, 10.5)
end

local function hayBale(cf)
	Kit.block("HayBale", V(4, 2.4, 2.6), cf * CFrame.new(0, 1.2, 0), HAY, Enum.Material.Grass)
	for _, x in { -1, 1 } do
		Kit.deco("HayBand", V(0.15, 2.45, 2.65), cf * CFrame.new(x, 1.2, 0), RGB(150, 110, 60), SMOOTH)
	end
end

-- Cactus saguaro de dibujo: tronco y dos brazos
local function cactus(position, scale)
	scale = scale or 1
	local base = CFrame.new(position)
	Kit.cylinder("Cactus", 8 * scale, 1.8 * scale, base * CFrame.new(0, 4 * scale, 0), CACTUS, SMOOTH)
	Kit.ball("CactusTop", 1.8 * scale, base * CFrame.new(0, 8 * scale, 0), CACTUS, SMOOTH, true)
	for _, s in { -1, 1 } do
		local h = (s > 0 and 3.5 or 4.6) * scale
		Kit.cylinder("CactusArm", 1.6 * scale, 1.2 * scale, base * CFrame.new(s * 1.4 * scale, h, 0) * CFrame.Angles(0, 0, rad(90)), CACTUS, SMOOTH, nil, true)
		Kit.cylinder("CactusArm", 2.6 * scale, 1.2 * scale, base * CFrame.new(s * 2.1 * scale, h + 1.3 * scale, 0), CACTUS, SMOOTH, nil, true)
		Kit.ball("CactusArmTop", 1.2 * scale, base * CFrame.new(s * 2.1 * scale, h + 2.6 * scale, 0), CACTUS, SMOOTH, true)
	end
end

-- Valla de madera entre dos puntos (cobertura baja)
local function fence(a, b)
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	for _, y in { 1.1, 2.2 } do
		Kit.deco("FenceRail", V(0.3, 0.4, length), cf * CFrame.new(0, y, 0), WOOD, Enum.Material.Wood)
	end
	Kit.block("FenceBlock", V(0.4, 2.6, length), cf * CFrame.new(0, 1.3, 0), WOOD, Enum.Material.Wood).Transparency = 1
	for i = 0, math.floor(length / 4) do
		Kit.deco("FencePost", V(0.5, 2.8, 0.5), cf * CFrame.new(0, 1.4, -length / 2 + i * length / math.floor(length / 4)), WOOD_DARK, Enum.Material.Wood)
	end
end

-- Tren de vapor de fondo sobre sus vías
local function train(cf)
	for x = -120, 120, 4 do
		Kit.deco("Sleeper", V(1, 0.3, 6), cf * CFrame.new(x, 0.15, 0), WOOD_DARK, Enum.Material.Wood)
	end
	for _, z in { -2, 2 } do
		Kit.deco("Rail", V(244, 0.3, 0.3), cf * CFrame.new(0, 0.45, z), RGB(90, 90, 95), Enum.Material.Metal)
	end
	local loco = cf * CFrame.new(-20, 0, 0)
	Kit.deco("LocoBody", V(14, 5, 5), loco * CFrame.new(0, 4, 0), RGB(40, 40, 48), SMOOTH)
	Kit.cylinder("LocoBoiler", 9, 4.6, loco * CFrame.new(-3, 4.6, 0) * CFrame.Angles(0, 0, rad(90)), RGB(30, 30, 36), SMOOTH, nil, true)
	Kit.deco("LocoCab", V(5, 5, 5.4), loco * CFrame.new(5, 7.5, 0), WOOD_RED, SMOOTH)
	Kit.deco("LocoCabRoof", V(6, 0.5, 6.2), loco * CFrame.new(5, 10.2, 0), RGB(30, 30, 36), SMOOTH)
	Kit.cylinder("Smokestack", 4, 1.6, loco * CFrame.new(-6, 9, 0), RGB(30, 30, 36), SMOOTH, nil, true)
	Kit.cylinder("SmokestackTop", 1, 2.6, loco * CFrame.new(-6, 11.2, 0), RGB(30, 30, 36), SMOOTH, nil, true)
	Kit.deco("Cowcatcher", V(2, 2, 5), loco * CFrame.new(-8, 1.6, 0) * CFrame.Angles(0, 0, rad(30)), WOOD_RED, SMOOTH)
	for _, x in { -5, -1, 3 } do
		for _, z in { -2.6, 2.6 } do
			Kit.cylinder("LocoWheel", 0.4, 2.6, loco * CFrame.new(x, 1.4, z) * CFrame.Angles(rad(90), 0, 0), WOOD_RED, SMOOTH, nil, true)
		end
	end
	local smoke = Kit.deco("SmokePuff", V(1, 1, 1), loco * CFrame.new(-6, 12, 0), RGB(255, 255, 255), SMOOTH)
	smoke.Transparency = 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(RGB(240, 240, 240))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(3, 5)
	emitter.Rate = 3
	emitter.Speed = NumberRange.new(4, 6)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Parent = smoke
	-- Vagones
	local wagonColors = { WOOD_RED, WOOD_TEAL, WOOD_MUSTARD }
	for i, color in wagonColors do
		local car = cf * CFrame.new(-20 + i * 13, 0, 0)
		Kit.deco("TrainCar", V(11, 5, 5), car * CFrame.new(0, 4.5, 0), color, PLANKS)
		Kit.deco("TrainCarRoof", V(11.6, 0.5, 5.6), car * CFrame.new(0, 7.2, 0), WOOD_DARK, SMOOTH)
		for _, x in { -3.5, 3.5 } do
			for _, z in { -2.6, 2.6 } do
				Kit.cylinder("CarWheel", 0.4, 2, car * CFrame.new(x, 1.2, z) * CFrame.Angles(rad(90), 0, 0), RGB(40, 40, 45), SMOOTH, nil, true)
			end
		end
	end
end

-- Meseta roja de fondo (tierra)
local function mesa(position, radius, height)
	local terrain = workspace.Terrain
	terrain:FillCylinder(CFrame.new(position + V(0, height / 2, 0)), height, radius, Enum.Material.Sandstone)
	terrain:FillCylinder(CFrame.new(position + V(0, height + 1, 0)), 2, radius * 0.92, Enum.Material.Sandstone)
	terrain:FillCylinder(CFrame.new(position + V(0, 2, 0)), 4, radius * 1.25, Enum.Material.Sand)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Desert") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo: tierra, calle mayor más clara y huellas de carro
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), DIRT_DARK, SMOOTH)
	deco("MainStreet", V(LENGTH, 0.1, 30), CFrame.new(0, 0.05, 0), DIRT, SMOOTH)
	for _, z in { -5, 5 } do
		deco("WheelRut", V(LENGTH - 20, 0.06, 0.8), CFrame.new(0, 0.12, z), DIRT_DARK, SMOOTH)
	end

	waterTower(CFrame.new(0, 0, 0))

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(235, 70, 70) or RGB(60, 130, 240)
		-- Fila norte: almacén y saloon (escalera a la azotea)
		westernBuilding(m * CFrame.new(-61, 0, 33), V(12, 8, 12), WOOD_TEAL, "ALMACÉN")
		westernBuilding(m * CFrame.new(-36, 0, 33), V(20, 11, 14), WOOD_RED, "SALOON", { RoofStairs = true, StairsX = -5 })
		-- Fila sur: banco (escalera a la azotea) y oficina del sheriff, mirando a la calle
		westernBuilding(m * CFrame.new(-58, 0, -33) * CFrame.Angles(0, math.pi, 0), V(16, 12, 14), WOOD_CREAM, "BANCO", { RoofStairs = true, StairsX = 3 })
		westernBuilding(m * CFrame.new(-31, 0, -33) * CFrame.Angles(0, math.pi, 0), V(14, 8, 12), WOOD_MUSTARD, "SHERIFF")

		-- Cobertura en la calle
		wagon(m * CFrame.new(-16, 0, -9) * CFrame.Angles(0, rad(75), 0), RGB(245, 240, 225))
		hayBale(m * CFrame.new(-48, 0, 9))
		hayBale(m * CFrame.new(-50, 0, 11.5) * CFrame.Angles(0, rad(30), 0))
		hayBale(m * CFrame.new(-26, 0, 12) * CFrame.Angles(0, rad(-15), 0))
		Kit.barrel(m * CFrame.new(-28, 0, 22), WOOD)
		Kit.barrel(m * CFrame.new(-30.5, 0, 22.5), WOOD_DARK)
		block("Trough", V(6, 1.8, 2), m * CFrame.new(-44, 0.9, -19), WOOD, Enum.Material.Wood)
		Kit.crate(m * CFrame.new(-66, 0, -14), 4, WOOD)
		Kit.crate(m * CFrame.new(-63, 0, -17), 3, WOOD)
		Kit.crate(m * CFrame.new(-8, 0, 20), 3.5, WOOD)

		-- Callejones de atrás: vallas, carro de heno, cactus y barriles
		fence(m * V(-70, 0, 52), m * V(-48, 0, 52))
		fence(m * V(-22, 0, -52), m * V(-6, 0, -52))
		hayBale(m * CFrame.new(-14, 0, 48) * CFrame.Angles(0, rad(10), 0))
		Kit.barrel(m * CFrame.new(-50, 0, -50), WOOD_RED)
		Kit.crate(m * CFrame.new(-12, 0, -46), 4, WOOD)
		cactus(m * V(-76, 0, 58), 1)
		cactus(m * V(-20, 0, 60), 0.8)
		cactus(m * V(-74, 0, -56), 0.9)

		-- Farol y carteles de "SE BUSCA" en los postes
		local poster = deco("WantedPoster", V(1.6, 2.2, 0.1), m * CFrame.new(-39.1, 4, 22.05), RGB(240, 225, 180), SMOOTH)
		Kit.sign(poster, Enum.NormalId.Front, "SE BUSCA", RGB(110, 40, 30))
		Kit.banner(m * CFrame.new(-68, 12, 22) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, RGB(255, 210, 80))
		Kit.banner(m * CFrame.new(-68, 12, -22) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, RGB(255, 210, 80))
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(240, 215, 170), Roof = WOOD_CREAM, RoofMaterial = PLANKS }
	Kit.spawnArea(teams[1], CFrame.new(-85, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-85, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-62, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-62, 0, 0))

	-- Fondo: tren de vapor, mesetas y cactus
	Kit.bounds(LENGTH, WIDTH, 60)
	block("TrackGround", V(LENGTH + 80, 2, 16), CFrame.new(0, -1, WIDTH / 2 + 24), DIRT_DARK, SMOOTH)
	block("BackGround", V(LENGTH + 80, 2, 20), CFrame.new(0, -1, -(WIDTH / 2 + 26)), DIRT_DARK, SMOOTH)
	train(CFrame.new(0, 0, WIDTH / 2 + 24))
	local rng = Random.new(41)
	for x = -120, 120, 26 do
		cactus(V(x + rng:NextNumber(-8, 8), 0, -(WIDTH / 2 + 18 + rng:NextNumber(0, 10))), rng:NextNumber(0.8, 1.3))
	end
	for _, sx in { -1, 1 } do
		for z = -60, 60, 40 do
			cactus(V(sx * (LENGTH / 2 + 16 + rng:NextNumber(0, 8)), 0, z + rng:NextNumber(-8, 8)), rng:NextNumber(0.9, 1.3))
		end
	end
	mesa(V(-60, 0, -(WIDTH / 2 + 70)), 34, 40)
	mesa(V(70, 0, -(WIDTH / 2 + 80)), 42, 52)
	mesa(V(-150, 0, 40), 30, 34)
	mesa(V(150, 0, -30), 34, 44)
	mesa(V(20, 0, WIDTH / 2 + 90), 40, 46)

	-- Modos
	for _, p in {
		V(-76, 0.5, 8), V(-76, 0.5, -16), V(-52, 0.5, 4), V(-40, 0.5, 18), V(-20, 0.5, 44),
		V(-60, 0.5, 46), V(-14, 0.5, -36), V(-36, 11.5, 34), V(-8, 0.5, 10), V(-44, 0.5, -48),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 0, 0), 7, 1)
	Kit.zone(V(-44, 0, -12), 6, 2)
	Kit.zone(V(44, 0, 12), 6, 3)
	Kit.zone(V(-36, 11, 33), 5, 4)
	Kit.zone(V(36, 11, -33), 5, 5)
	Kit.dustMotes(CFrame.new(0, 5, 0), V(150, 8, 90), Color3.fromRGB(240, 200, 150), 10)
	return folder
end

return Map
