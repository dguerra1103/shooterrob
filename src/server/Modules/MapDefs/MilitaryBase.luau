-- BASE MILITAR: base de entrenamiento en un valle verde, al estilo de los mapas 5 contra 5 de los
-- shooters de móvil. Tres carriles: en el centro, el búnker de mando (dos plantas, se entra por los
-- cuatro lados) con la galería de tiro y los camiones; a un lado el hangar con una avioneta y
-- contenedores; al otro los barracones (dos plantas), las trincheras y la torre de vigilancia.
-- Simétrico por rotación. Siempre en estilo realista.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)
local RealKit = require(script.Parent.Parent.RealKit)

local Map = {
	Id = "MilitaryBase",
	Bomb = true, -- tiene sitios para Buscar y destruir
	Name = "Base Militar",
	Icon = "🪖",
	Description = "Base en el valle · hangar, búnker y trincheras · 5 contra 5",
	Realistic = true,
}

Map.Lighting = {
	ClockTime = 9.6,
	Latitude = 45,
	Brightness = 2.6,
	Exposure = 0,
	Ambient = Color3.fromRGB(70, 76, 80),
	OutdoorAmbient = Color3.fromRGB(135, 145, 150),
	ShadowSoftness = 0.15,
	Atmosphere = { Density = 0.32, Offset = 0.2, Color = Color3.fromRGB(200, 212, 220), Decay = Color3.fromRGB(110, 125, 135), Glare = 0.2, Haze = 1.6 },
	Color = { Saturation = -0.08, Contrast = 0.16, Brightness = 0, Tint = Color3.fromRGB(242, 246, 250) },
	Bloom = { Intensity = 0.4, Size = 24, Threshold = 2.2 },
	Clouds = 0.7,
	CloudColor = Color3.fromRGB(235, 238, 242),
	SunRays = 0.05,
	Wind = Vector3.new(5, 0, -2),
	TerrainColors = { Grass = Color3.fromRGB(88, 112, 62), LeafyGrass = Color3.fromRGB(78, 100, 56), Ground = Color3.fromRGB(110, 96, 74), Rock = Color3.fromRGB(110, 112, 110) },
}

-- Versiones de luz (a veces): niebla de primera hora (se ve menos de lejos)
Map.LightingVariants = {
	{
		Name = "Niebla",
		Chance = 0.3,
		ClockTime = 7.4,
		Brightness = 1.9,
		Ambient = Color3.fromRGB(80, 86, 92),
		OutdoorAmbient = Color3.fromRGB(140, 148, 156),
		Atmosphere = { Density = 0.48, Offset = 0.05, Color = Color3.fromRGB(205, 212, 218), Decay = Color3.fromRGB(150, 160, 170), Glare = 0, Haze = 3 },
		Color = { Saturation = -0.15, Contrast = 0.1, Brightness = 0.02, Tint = Color3.fromRGB(235, 242, 250) },
		Clouds = 0.85,
		SunRays = 0.02,
	},
	{
		Name = "Tormenta",
		Chance = 0.3,
		Weather = "Rain",
		ClockTime = 16,
		Brightness = 1.2,
		Exposure = -0.05,
		Ambient = Color3.fromRGB(60, 64, 70),
		OutdoorAmbient = Color3.fromRGB(100, 106, 115),
		Atmosphere = { Density = 0.42, Offset = 0.08, Color = Color3.fromRGB(150, 155, 165), Decay = Color3.fromRGB(90, 95, 105), Glare = 0, Haze = 2.6 },
		Color = { Saturation = -0.25, Contrast = 0.12, Brightness = 0, Tint = Color3.fromRGB(225, 232, 240) },
		Bloom = { Intensity = 0.3, Size = 20, Threshold = 2.4 },
		Clouds = 1,
		CloudColor = Color3.fromRGB(120, 124, 130),
		SunRays = 0,
		Wind = Vector3.new(14, 0, -6),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local LENGTH, WIDTH = 400, 260
local FLOOR_H = RealKit.FLOOR_H
local building, solidBlock, sandbags = RealKit.building, RealKit.solidBlock, RealKit.sandbags
local block, deco = Kit.block, Kit.deco

local OLIVE = RGB(92, 98, 70)
local OLIVE_DARK = RGB(64, 68, 50)
local CONCRETE = RGB(150, 148, 142)

---------------------------------------------------------------------------
-- Piezas de la base
---------------------------------------------------------------------------

-- Muro en T de hormigón (cobertura alta)
local function tWall(cf)
	block("TWall", V(6, 7, 1.2), cf * CFrame.new(0, 3.5, 0), CONCRETE, M.Concrete)
	deco("TWallFoot", V(6, 1, 3.4), cf * CFrame.new(0, 0.5, 0), CONCRETE:Lerp(RGB(0, 0, 0), 0.08), M.Concrete).CanCollide = true
	deco("TWallStripe", V(6.05, 0.5, 1.25), cf * CFrame.new(0, 6, 0), RGB(230, 190, 40), M.Concrete)
	Kit.contactShadow(cf, 6.2, 3.6)
end

-- Fila de muros en T entre dos puntos (con hueco cada pocos)
local function tWallRow(a, b, gapEvery)
	local direction = b - a
	local count = math.floor(direction.Magnitude / 6.2)
	local cf = CFrame.lookAt(a, b) * CFrame.Angles(0, math.pi / 2, 0)
	for i = 0, count - 1 do
		if not gapEvery or (i + 1) % gapEvery ~= 0 then
			tWall(CFrame.new(a + direction.Unit * (i * 6.2 + 3.1)) * (cf - cf.Position))
		end
	end
end

-- Alambrada: postes y malla; se ve y se dispara a través, pero no se pasa
local function fence(a, b, height)
	height = height or 7
	local direction = b - a
	local length = direction.Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	local mesh = deco("Fence", V(0.15, height, length), cf * CFrame.new(0, height / 2, 0), RGB(150, 155, 160), M.DiamondPlate)
	mesh.Transparency = 0.75
	mesh.CastShadow = false
	-- Lo que choca va aparte, donde las balas y la vista no lo ven (se dispara a través)
	local collider = block("FenceCollider", V(0.4, height, length), cf * CFrame.new(0, height / 2, 0), RGB(150, 155, 160), nil, Kit.shootThroughFolder())
	collider.Transparency = 1
	collider.CastShadow = false
	local posts = math.max(1, math.floor(length / 8))
	for i = 0, posts do
		local p = a:Lerp(b, i / posts)
		deco("FencePost", V(0.35, height + 0.6, 0.35), CFrame.new(p + V(0, (height + 0.6) / 2, 0)), RGB(90, 92, 96), M.Metal)
	end
	deco("BarbedWire", V(0.3, 0.3, length), cf * CFrame.new(0, height + 0.5, 0), RGB(70, 70, 72), M.Metal)
end

-- Camión militar con lona (cobertura grande)
local function truck(cf)
	block("TruckCab", V(6.5, 6.5, 7.5), cf * CFrame.new(-8, 3.6, 0), OLIVE, M.Metal)
	deco("TruckWindshield", V(0.2, 2.2, 6.4), cf * CFrame.new(-11.3, 5.2, 0), RGB(30, 34, 38), M.Glass)
	block("TruckBed", V(13, 2, 7.5), cf * CFrame.new(2, 2.4, 0), OLIVE_DARK, M.Metal)
	block("TruckCanvas", V(12.5, 6, 7.3), cf * CFrame.new(2.2, 6.4, 0), RGB(84, 88, 62), M.Fabric)
	for _, x in { -8, 0.5, 5.5 } do
		for _, z in { -3.6, 3.6 } do
			local wheel = deco("Wheel", V(3, 3, 1.2), cf * CFrame.new(x, 1.5, z) * CFrame.Angles(0, math.pi / 2, 0), RGB(28, 28, 30), M.Rubber)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	Kit.contactShadow(cf * CFrame.new(-1.5, 0, 0), 20, 8)
end

-- Avioneta (dentro del hangar)
local function plane(cf)
	local body = RGB(176, 180, 176)
	Kit.pipe("Fuselage", 22, 4, cf * CFrame.new(0, 4, 0), body, M.Metal)
	block("Wing", V(6, 0.5, 30), cf * CFrame.new(-1, 4.6, 0), body, M.Metal)
	block("TailWing", V(3, 0.4, 10), cf * CFrame.new(9.5, 5, 0), body, M.Metal)
	block("TailFin", V(3, 4.5, 0.4), cf * CFrame.new(10, 7.2, 0), RGB(150, 60, 50), M.Metal)
	deco("Cockpit", V(4, 1.6, 2.6), cf * CFrame.new(-5, 6.3, 0), RGB(40, 48, 58), M.Glass)
	deco("Propeller", V(0.3, 6, 0.6), cf * CFrame.new(-11.2, 4, 0), RGB(40, 40, 42), M.Metal)
	for _, z in { -3, 3 } do
		deco("Gear", V(0.5, 2, 0.5), cf * CFrame.new(-2, 1, z), RGB(50, 50, 52), M.Metal)
		local wheel = deco("GearWheel", V(1.4, 1.4, 0.6), cf * CFrame.new(-2, 0.7, z) * CFrame.Angles(0, math.pi / 2, 0), RGB(28, 28, 30), M.Rubber)
		wheel.Shape = Enum.PartType.Cylinder
	end
end

-- Hangar: nave alta con los dos extremos abiertos (se cruza de punta a punta)
local function hangar(cf, sx, sz, height)
	local wallColor = RGB(126, 132, 120)
	for _, z in { -1, 1 } do
		block("HangarWall", V(sx, height, 1.2), cf * CFrame.new(0, height / 2, z * (sz / 2 - 0.6)), wallColor, M.CorrodedMetal)
		-- Ventanales altos (decoración)
		for i = -2, 2 do
			deco("HangarWindow", V(5, 2.4, 0.2), cf * CFrame.new(i * sx / 5, height - 3, z * (sz / 2 + 0.05)), RGB(40, 46, 52), M.Glass)
		end
	end
	-- Fachadas de los extremos con el portón abierto (dintel por encima)
	for _, x in { -1, 1 } do
		block("HangarLintel", V(1.2, 5, sz), cf * CFrame.new(x * (sx / 2 - 0.6), height - 2.5, 0), wallColor, M.CorrodedMetal)
		for _, z in { -1, 1 } do
			block("HangarJamb", V(1.2, height - 5, 4), cf * CFrame.new(x * (sx / 2 - 0.6), (height - 5) / 2, z * (sz / 2 - 2)), wallColor, M.CorrodedMetal)
		end
	end
	block("HangarRoof", V(sx + 2, 1, sz + 2), cf * CFrame.new(0, height + 0.5, 0), RGB(96, 100, 92), M.CorrodedMetal)
	for i = -2, 2 do
		deco("RoofRib", V(0.6, 0.6, sz + 2), cf * CFrame.new(i * sx / 5, height + 1.2, 0), RGB(80, 84, 78), M.Metal)
	end
	deco("HangarFloor", V(sx - 2, 0.1, sz - 2), cf * CFrame.new(0, 0.06, 0), RGB(118, 118, 116), M.Concrete)
	for i = -1, 1, 2 do
		local lamp = deco("HangarLamp", V(2, 0.4, 2), cf * CFrame.new(i * sx / 4, height - 0.6, 0), RGB(255, 240, 210), M.Neon)
		Kit.light(lamp, "PointLight", RGB(255, 236, 200), 30, 1.1)
	end
end

-- Torre de vigilancia: patas, escalera y plataforma con parapeto (puesto de tirador)
local function watchtower(cf, height)
	local wood = RGB(110, 86, 60)
	for _, x in { -3.5, 3.5 } do
		for _, z in { -3.5, 3.5 } do
			block("TowerLeg", V(1, height, 1), cf * CFrame.new(x, height / 2, z), wood, M.Wood)
		end
	end
	block("TowerFloor", V(9, 1, 9), cf * CFrame.new(0, height - 0.5, 0), wood, M.WoodPlanks)
	for _, side in { { 0, 4.3, 9, 0.6 }, { 0, -4.3, 9, 0.6 }, { 4.3, 0, 0.6, 9 } } do
		block("TowerWall", V(side[3], 2.6, side[4]), cf * CFrame.new(side[1], height + 1.3, side[2]), wood, M.WoodPlanks)
	end
	deco("TowerRoof", V(10.5, 0.6, 10.5), cf * CFrame.new(0, height + 6, 0), OLIVE_DARK, M.CorrodedMetal)
	for _, x in { -4.6, 4.6 } do
		for _, z in { -4.6, 4.6 } do
			deco("RoofPost", V(0.4, 6, 0.4), cf * CFrame.new(x, height + 3, z), wood, M.Wood)
		end
	end
	-- Escalera por el lado abierto (-X)
	Kit.stairs(cf * V(-4.5 - height * 1.5, 0, 0), cf * V(-4.5, height, 0), 4, wood, M.WoodPlanks)
	local lamp = deco("TowerSpot", V(1, 1, 1), cf * CFrame.new(3.6, height + 4.8, 3.6), RGB(255, 240, 200), M.Neon)
	Kit.light(lamp, "SpotLight", RGB(255, 236, 200), 40, 1.2, Enum.NormalId.Bottom)
end

-- Tienda de campaña militar: dos faldones inclinados y la lona de detrás (cobertura que tapa la vista)
local function tent(cf, length, width)
	local canvas = RGB(98, 102, 74)
	local h = width * 0.55
	for _, side in { -1, 1 } do
		local slope = math.sqrt((width / 2) ^ 2 + h ^ 2)
		local angle = math.atan2(h, width / 2)
		block("TentRoof", V(length, 0.3, slope), cf * CFrame.new(0, h / 2, side * width / 4) * CFrame.Angles(side * angle, 0, 0), canvas, M.Fabric)
	end
	block("TentBack", V(0.3, h * 0.8, width * 0.6), cf * CFrame.new(length / 2 - 0.2, h * 0.4, 0), canvas:Lerp(RGB(0, 0, 0), 0.1), M.Fabric)
	deco("TentRidge", V(length + 0.6, 0.35, 0.35), cf * CFrame.new(0, h + 0.05, 0), RGB(70, 60, 44), M.Wood)
end

-- Red de camuflaje sobre postes (sombra y vista, no para las balas)
local function camoNet(cf, sx, sz, height)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("NetPole", height, 0.35, cf * CFrame.new(x * (sx / 2 - 0.5), height / 2, z * (sz / 2 - 0.5)), RGB(80, 66, 48), M.Wood, nil, true)
		end
	end
	local net = deco("CamoNet", V(sx, 0.2, sz), cf * CFrame.new(0, height, 0), RGB(78, 88, 58), M.Fabric)
	net.CastShadow = true
	-- Manchas del camuflaje
	for i, spot in { { -0.25, -0.2, RGB(58, 66, 42) }, { 0.2, 0.15, RGB(104, 96, 66) }, { -0.05, 0.3, RGB(50, 58, 38) } } do
		deco("CamoSpot", V(sx * 0.35, 0.22, sz * 0.3), cf * CFrame.new(spot[1] * sx, height + 0.02, spot[2] * sz) * CFrame.Angles(0, i, 0), spot[3], M.Fabric)
	end
end

-- Torre de focos (de noche no se encienden: solo silueta)
local function floodlight(cf)
	local metal = RGB(96, 98, 100)
	Kit.cylinder("FloodPole", 18, 0.6, cf * CFrame.new(0, 9, 0), metal, M.Metal, nil, true)
	deco("FloodBar", V(5, 0.4, 0.4), cf * CFrame.new(0, 17.6, 0), metal, M.Metal)
	for _, x in { -1.8, 0, 1.8 } do
		deco("FloodLamp", V(1.3, 1.1, 0.8), cf * CFrame.new(x, 18.4, 0.3) * CFrame.Angles(rad(-20), 0, 0), RGB(60, 62, 64), M.Metal)
		deco("FloodGlass", V(1, 0.8, 0.1), cf * CFrame.new(x, 18.4, 0.75) * CFrame.Angles(rad(-20), 0, 0), RGB(230, 230, 210), M.Glass)
	end
end

-- Diana de la galería de tiro
local function target(cf)
	deco("TargetPost", V(0.3, 3, 0.3), cf * CFrame.new(0, 1.5, 0), RGB(100, 80, 60), M.Wood)
	local board = deco("TargetBoard", V(2.4, 3, 0.2), cf * CFrame.new(0, 4.2, 0), RGB(235, 230, 215), M.Wood)
	board.CastShadow = false
	for i, d in { 2, 1.3, 0.6 } do
		local ring = deco("TargetRing", V(0.05, d, d), cf * CFrame.new(0, 4.4, -0.12) * CFrame.Angles(0, math.pi / 2, 0), i % 2 == 1 and RGB(200, 40, 40) or RGB(240, 240, 235), M.SmoothPlastic)
		ring.Shape = Enum.PartType.Cylinder
	end
end

---------------------------------------------------------------------------
-- Mapa
---------------------------------------------------------------------------

function Map.Build()
	local folder = Kit.Begin(Map.Name, { Realistic = true })
	folder:SetAttribute("Ambience", "Base") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Kit.pickLighting(Map))
	folder:SetAttribute("Variant", Kit.Variant)
	folder:SetAttribute("Weather", Kit.Weather)
	local teams = GameConfig.Teams

	-- Suelo: hierba con caminos de hormigón y tierra
	Kit.terrainFloor(M.Grass, LENGTH + 260, WIDTH + 260)
	block("MainRoad", V(LENGTH + 30, 0.4, 22), CFrame.new(0, 0.2, 0), RGB(108, 108, 106), M.Concrete)
	block("CrossRoad", V(20, 0.4, WIDTH - 30), CFrame.new(0, 0.2, 0), RGB(108, 108, 106), M.Concrete)
	for _, z in { -1, 1 } do
		deco("RoadLine", V(LENGTH - 40, 0.05, 0.5), CFrame.new(0, 0.43, z * 10), RGB(220, 200, 90), M.Concrete)
	end

	-- Búnker de mando en el centro: dos plantas y puertas a los cuatro lados
	building(CFrame.new(0, 0, 0), 30, 26, {
		Floors = 2,
		Color = CONCRETE,
		Material = M.Concrete,
		Doors = { Front = { 6 }, Back = { -6 }, Right = { 0 } }, -- (por la izquierda va la escalera)
		Sign = "MANDO",
	})
	Kit.cylinder("Antenna", 16, 0.5, CFrame.new(10, 25, 8), RGB(70, 72, 76), M.Metal, nil, true)
	deco("Dish", V(0.6, 5, 5), CFrame.new(-8, 19.5, -6) * CFrame.Angles(0, rad(30), rad(-25)), RGB(220, 222, 225), M.Metal).Shape = Enum.PartType.Cylinder

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and teams[1].Color.Color or teams[2].Color.Color

		------------------------------------------------------------------
		-- Carril central (z -20..20): galería de tiro, camiones y muros en T
		------------------------------------------------------------------
		truck(m * CFrame.new(-120, 0, -12) * CFrame.Angles(0, rad(10), 0))
		truck(m * CFrame.new(-52, 0, 13) * CFrame.Angles(0, rad(-170), 0))
		tWallRow(m * V(-95, 0, -6), m * V(-95, 0, 12), nil)
		tWallRow(m * V(-34, 0, -14), m * V(-34, 0, 2), nil)
		sandbags(m * CFrame.new(-75, 0, -2) * CFrame.Angles(0, rad(90), 0), 8)
		-- Galería de tiro: puestos con muro bajo y dianas al fondo
		for i = 0, 3 do
			local z = 35 + i * 3.4
			block("RangeBooth", V(1.2, 3.6, 3), m * CFrame.new(-150, 1.8, z), RGB(120, 110, 96), M.WoodPlanks)
			target(m * CFrame.new(-125, 0, z) * CFrame.Angles(0, rad(90), 0))
		end
		for _, p in { V(-140, 0, 8), V(-108, 0, 15), V(-66, 0, -16) } do
			Kit.crate(m * CFrame.new(p), 4)
		end
		Kit.crate(m * CFrame.new(-66, 4, -16), 3)
		for _, p in { V(-128, 0, 16), V(-85, 0, -15) } do
			Kit.barrel(m * CFrame.new(p), OLIVE)
		end

		------------------------------------------------------------------
		-- Separación norte (z 24..44): alambrada con huecos y casetas
		------------------------------------------------------------------
		fence(m * V(-170, 0, 30), m * V(-132, 0, 30))
		fence(m * V(-118, 0, 30), m * V(-80, 0, 30))
		solidBlock(m * CFrame.new(-66, 0, 36), 18, 12, 9, RGB(140, 136, 120), { Material = M.Concrete, Sign = side == "A" and "ARMERÍA" or "COMBUSTIBLE", Awning = false })
		tWallRow(m * V(-48, 0, 28), m * V(-24, 0, 28), 3)

		------------------------------------------------------------------
		-- Separación sur (z -44..-24): almacén y contenedores
		------------------------------------------------------------------
		solidBlock(m * CFrame.new(-150, 0, -36), 26, 16, 12, RGB(126, 130, 118), { Material = M.CorrodedMetal, Windows = false })
		Kit.container(m * CFrame.new(-110, 0, -32), OLIVE)
		Kit.container(m * CFrame.new(-110, 8.6, -32), RGB(120, 70, 50))
		Kit.container(m * CFrame.new(-80, 0, -36) * CFrame.Angles(0, rad(90), 0), RGB(70, 90, 110))
		fence(m * V(-60, 0, -30), m * V(-24, 0, -30))

		------------------------------------------------------------------
		-- Carril norte (z 50..125): hangar con avioneta y contenedores
		------------------------------------------------------------------
		local hangarCf = m * CFrame.new(-92, 0, 88)
		hangar(hangarCf, 54, 40, 16)
		plane(hangarCf * CFrame.new(4, 0, 2) * CFrame.Angles(0, rad(8), 0))
		Kit.crate(hangarCf * CFrame.new(-18, 0, -12), 4)
		Kit.crate(hangarCf * CFrame.new(-18, 0, -8), 4)
		Kit.metalCrate(hangarCf * CFrame.new(18, 0, 14), 5, OLIVE_DARK)
		Kit.container(m * CFrame.new(-150, 0, 70) * CFrame.Angles(0, rad(90), 0), RGB(150, 120, 60))
		Kit.container(m * CFrame.new(-34, 0, 64), RGB(110, 60, 50))
		Kit.container(m * CFrame.new(-28, 0, 112) * CFrame.Angles(0, rad(15), 0), OLIVE)
		sandbags(m * CFrame.new(-50, 0, 92) * CFrame.Angles(0, rad(90), 0), 10)
		sandbags(m * CFrame.new(-12, 0, 82), 8)
		truck(m * CFrame.new(-150, 0, 108) * CFrame.Angles(0, rad(-80), 0))

		------------------------------------------------------------------
		-- Carril sur (z -125..-50): barracones, trincheras y torre
		------------------------------------------------------------------
		building(m * CFrame.new(-112, 0, -84) * CFrame.Angles(0, math.pi, 0), 30, 24, {
			Floors = 2,
			Color = RGB(150, 138, 112),
			Doors = { Front = { -6 }, Back = { 6 }, Right = { 0 } },
			Blind = { Left = true },
			Sign = "BARRACONES",
		})
		watchtower(m * CFrame.new(-40, 0, -100), 14)
		-- Trincheras: líneas de sacos en zigzag
		sandbags(m * CFrame.new(-70, 0, -64), 14)
		sandbags(m * CFrame.new(-60, 0, -74) * CFrame.Angles(0, rad(60), 0), 10)
		sandbags(m * CFrame.new(-150, 0, -64), 12)
		sandbags(m * CFrame.new(-18, 0, -66) * CFrame.Angles(0, rad(90), 0), 10)
		Kit.log(m * CFrame.new(-80, 0, -110) * CFrame.Angles(0, rad(20), 0), 10, 2.2)
		for _, p in { V(-150, 0, -100), V(-72, 0, -118) } do
			Kit.metalCrate(m * CFrame.new(p), 5, OLIVE_DARK)
		end

		------------------------------------------------------------------
		-- Perímetro: muro con alambre, garitas y bosque detrás
		------------------------------------------------------------------
		for _, z in { -1, 1 } do
			block("PerimeterWall", V(LENGTH / 2 + 10, 9, 1.5), m * CFrame.new(-LENGTH / 4, 4.5, z * (WIDTH / 2 + 2)), CONCRETE, M.Concrete)
			deco("PerimeterWire", V(LENGTH / 2 + 10, 0.4, 0.4), m * CFrame.new(-LENGTH / 4, 9.6, z * (WIDTH / 2 + 2)), RGB(70, 70, 72), M.Metal)
		end
		block("PerimeterWall", V(1.5, 9, WIDTH + 6), m * CFrame.new(-LENGTH / 2 - 8, 4.5, 0), CONCRETE, M.Concrete)
		for _, z in { -90, 90 } do
			Kit.cartoonPine(m * V(-LENGTH / 2 - 30, 0, z), 1.6, true)
		end
		for i = 0, 8 do
			local x = -LENGTH / 2 + i * 24
			for _, z in { -1, 1 } do
				Kit.cartoonPine(m * V(x + z * 6, 0, z * (WIDTH / 2 + 24 + (i % 3) * 8)), 1.5 + (i % 2) * 0.4, true)
			end
		end

		------------------------------------------------------------------
		-- Ambiente: caminos de tierra, tiendas, red de camuflaje, focos y postes de la luz
		------------------------------------------------------------------
		Kit.terrainPatch(m * CFrame.new(-95, 0, 62), V(150, 1, 7), M.Ground)
		Kit.terrainPatch(m * CFrame.new(-90, 0, -56), V(150, 1, 7), M.Ground)
		Kit.terrainPatch(m * CFrame.new(-65, 0, -70), V(26, 1, 16), M.Mud)
		Kit.terrainPatch(m * CFrame.new(-150, 0, -64), V(18, 1, 10), M.Mud)
		tent(m * CFrame.new(-176, 0, -90) * CFrame.Angles(0, rad(90), 0), 11, 8)
		tent(m * CFrame.new(-176, 0, -108) * CFrame.Angles(0, rad(90), 0), 11, 8)
		camoNet(m * CFrame.new(-150, 0, 108) * CFrame.Angles(0, rad(10), 0), 16, 12, 9)
		for _, p in { V(-178, 0, 48), V(-178, 0, -48) } do
			floodlight(m * CFrame.new(p) * CFrame.Angles(0, rad(p.Z > 0 and -90 or 90), 0))
		end
		RealKit.utilityLine(m * CFrame.new(0, 0, 22.5), -175, -23, 38)
		-- Helipuerto junto al hangar (solo dibujo en el suelo) y manga de viento
		local pad = Kit.cylinder("Helipad", 0.06, 14, m * CFrame.new(-112, 0.04, 121), RGB(70, 72, 70), M.Concrete, nil, true)
		pad.CastShadow = false
		local ring = Kit.cylinder("HelipadRing", 0.07, 12.4, m * CFrame.new(-112, 0.05, 121), RGB(225, 200, 60), M.SmoothPlastic, nil, true)
		ring.CastShadow = false
		local inner = Kit.cylinder("HelipadInner", 0.08, 11.4, m * CFrame.new(-112, 0.06, 121), RGB(70, 72, 70), M.Concrete, nil, true)
		inner.CastShadow = false
		local letter = deco("HelipadH", V(7, 0.05, 7), m * CFrame.new(-112, 0.1, 121), RGB(255, 255, 255), M.SmoothPlastic)
		letter.Transparency = 1
		local gui = Kit.sign(letter, Enum.NormalId.Top, "H", RGB(235, 235, 230), RGB(235, 235, 230))
		gui.LightInfluence = 1
		Kit.cylinder("WindsockPole", 9, 0.3, m * CFrame.new(-100, 4.5, 127), RGB(200, 200, 200), M.Metal, nil, true)
		for i = 0, 3 do
			deco("Windsock", V(0.9 - i * 0.12, 0.9 - i * 0.12, 1.1), m * CFrame.new(-100, 8.6 - i * 0.12, 127.7 + i * 1.05) * CFrame.Angles(rad(-6 * i), 0, 0), i % 2 == 0 and RGB(240, 110, 30) or RGB(240, 240, 235), M.Fabric)
		end

		-- Base: el muro de detrás de la zona de salida, con sus banderas
		for _, z in { -30, 30 } do
			Kit.banner(m * CFrame.new(-206.5, 6, z) * CFrame.Angles(0, rad(90), 0), 5, 9, teamColor, RGB(240, 240, 240))
		end
	end)

	-- Pájaros dando vueltas sobre el valle (los mueve el cliente: atributos Orbit de WorldFX);
	-- con tormenta no vuelan
	if Kit.Weather ~= "Rain" then
		for i, spec in { { 70, 48, 14 }, { 110, 58, -11 }, { 90, 52, 9 }, { 140, 64, -7 } } do
			local radius, height, speed = spec[1], spec[2], spec[3]
			local angle = i * 1.7
			local body = CFrame.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
				* CFrame.Angles(0, -angle + (speed > 0 and 0 or math.pi), 0)
			for _, side in { -1, 1 } do
				local wing = deco("BirdWing", V(1.6, 0.08, 0.45), body * CFrame.new(side * 0.75, 0, 0) * CFrame.Angles(0, 0, rad(side * 22)), RGB(40, 38, 36), M.SmoothPlastic)
				wing.CastShadow = false
				wing:SetAttribute("Orbit", speed)
				wing:SetAttribute("OrbitCenter", V(0, height, 0))
				wing:SetAttribute("OrbitAxis", V(0, 1, 0))
			end
		end
	end

	-- Con tormenta: hormigón mojado (brilla un poco) y charcos por los caminos
	if Kit.Weather == "Rain" then
		for _, part in folder:GetDescendants() do
			if part:IsA("BasePart") and (part.Name == "MainRoad" or part.Name == "CrossRoad") then
				part.Color = part.Color:Lerp(RGB(0, 0, 0), 0.25)
				part.Reflectance = 0.12
			end
		end
		for i, p in { V(-150, 0, 4), V(-96, 0, -5), V(-60, 0, 7), V(-20, 0, -4), V(4, 0, 60), V(-4, 0, -70), V(-110, 0, 62), V(-80, 0, -56) } do
			for _, q in { p, Kit.MIRROR * p } do
				local onRoad = math.abs(q.Z) < 11 or math.abs(q.X) < 10
				local puddle = Kit.cylinder("Puddle", 0.04, 3 + (i % 3) * 1.5, CFrame.new(q + V(0, onRoad and 0.43 or 0.03, 0)), RGB(62, 66, 72), M.SmoothPlastic, nil, true)
				puddle.Reflectance = 0.35
				puddle.CastShadow = false
			end
		end
	end

	-- Zonas de salida, banderas y límites
	local spawnStyle = { Floor = RGB(118, 118, 114), FloorMaterial = M.Concrete, Roof = OLIVE_DARK, RoofMaterial = M.CorrodedMetal }
	Kit.spawnArea(teams[1], CFrame.new(-184, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-184, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-160, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-160, 0, 0))
	Kit.bounds(LENGTH, WIDTH, 70)

	-- Pinos de verde oscuro natural (el pino del kit es de colores de dibujo animado)
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "PineTier" then
			part.Color = RGB(46, 72, 44):Lerp(RGB(34, 56, 36), (math.floor(part.Position.Y) % 2) * 0.6)
			part.Material = M.LeafyGrass
		end
	end

	-- Montañas alrededor del valle
	for _, spec in { { V(-330, 0, 240), 110 }, { V(330, 0, -240), 110 }, { V(60, 0, 330), 120 }, { V(-60, 0, -330), 120 }, { V(-360, 0, -150), 90 }, { V(360, 0, 150), 90 } } do
		Kit.naturalHill(spec[1], spec[2], M.Grass)
	end

	-- Puntos de salida libres
	for _, p in {
		V(-150, 0.5, -6), V(-115, 0.5, 6), V(-80, 0.5, 8), V(-45, 0.5, -6),
		V(-160, 0.5, 90), V(-118, 0.5, 92), V(-70, 0.5, 80), V(-20, 0.5, 100),
		V(-160, 0.5, -85), V(-90, 0.5, -96), V(-56, 0.5, -112), V(-20, 0.5, -90),
		V(-2, FLOOR_H + 0.5, 4), V(-112, FLOOR_H + 0.5, -82),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	-- Puestos de los tiradores (torre de vigilancia, barracones y búnker de arriba)
	for _, spot in {
		{ V(-40, 14, -100), V(40, 4, -80) }, -- torre de vigilancia
		{ V(-112, FLOOR_H, -74.7), V(-112, 4, -20) }, -- barracones, ventana de arriba
		{ V(0, FLOOR_H, -10.3), V(0, 4, -60) }, -- búnker, ventana de arriba
	} do
		Kit.botSpot(spot[1], spot[2])
		Kit.botSpot(Kit.MIRROR * spot[1], Kit.MIRROR * spot[2])
	end
	-- Buscar y destruir: cada equipo defiende dos sitios en su mitad (A y B)
	for _, site in { { V(-108, 0, 100), "A" }, { V(-135, 0, -110), "B" } } do
		Kit.bombSite(site[1], site[2], 1)
		Kit.bombSite(Kit.MIRROR * site[1], site[2], 2)
	end
	-- Zonas de control: delante del búnker, los dos carriles y los dos lados del centro
	Kit.zone(V(0, 0, 20), 10, 1)
	Kit.zone(V(-92, 0, 88), 12, 2)
	Kit.zone(V(92, 0, -88), 12, 3)
	Kit.zone(V(0, 0, -20), 10, 4)
	Kit.zone(V(0, 0, 0), 9, 5)
	return folder
end

return Map
