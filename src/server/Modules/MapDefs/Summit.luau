-- CUMBRE: estación de montaña nevada al atardecer, al estilo de los mapas 5 contra 5 de los
-- shooters de móvil. En el centro el refugio (dos plantas, se entra por los cuatro lados). Por el
-- carril central la carretera con la quitanieves y rocas; a un lado la estación del teleférico,
-- en alto, con su cabina (puesto de tirador); al otro el laboratorio, la cúpula del radar y los
-- depósitos de combustible. Simétrico por rotación. Siempre en estilo realista.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)
local RealKit = require(script.Parent.Parent.RealKit)

local Map = {
	Id = "Summit",
	Name = "Cumbre",
	Icon = "🏔️",
	Description = "Estación de montaña nevada · teleférico y laboratorio · 5 contra 5",
	Realistic = true,
}

Map.Lighting = {
	ClockTime = 17.3,
	Latitude = 50,
	Brightness = 2.4,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(80, 86, 104),
	OutdoorAmbient = Color3.fromRGB(150, 158, 182),
	ShadowSoftness = 0.12,
	Atmosphere = { Density = 0.36, Offset = 0.18, Color = Color3.fromRGB(210, 196, 214), Decay = Color3.fromRGB(120, 112, 150), Glare = 0.6, Haze = 1.8 },
	Color = { Saturation = -0.04, Contrast = 0.15, Brightness = 0.02, Tint = Color3.fromRGB(240, 238, 255) },
	Bloom = { Intensity = 0.55, Size = 26, Threshold = 1.9 },
	Clouds = 0.45,
	CloudColor = Color3.fromRGB(255, 220, 210),
	SunRays = 0.1,
	SunSize = 26,
	Wind = Vector3.new(10, 0, 4),
	TerrainColors = { Snow = Color3.fromRGB(232, 236, 246), Rock = Color3.fromRGB(96, 98, 108), Glacier = Color3.fromRGB(170, 205, 235) },
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local LENGTH, WIDTH = 400, 260
local FLOOR_H = RealKit.FLOOR_H
local building, solidBlock, sandbags = RealKit.building, RealKit.solidBlock, RealKit.sandbags
local block, deco = Kit.block, Kit.deco

local SNOW = RGB(236, 240, 248)
local STONE = RGB(110, 112, 120)
local WOOD = RGB(116, 84, 58)

---------------------------------------------------------------------------
-- Piezas de la montaña
---------------------------------------------------------------------------

-- Capa de nieve encima de una pieza
local function snowCap(part)
	local s = part.Size
	local cap = deco("SnowCap", V(s.X + 0.3, 0.35, s.Z + 0.3), part.CFrame * CFrame.new(0, s.Y / 2 + 0.17, 0), SNOW, M.Snow)
	cap.CastShadow = false
	return cap
end

-- Muro de piedra con nieve encima (cobertura)
local function stoneWall(cf, length, height)
	local wall = block("StoneWall", V(length, height, 2), cf * CFrame.new(0, height / 2, 0), STONE, M.Slate)
	snowCap(wall)
	Kit.contactShadow(cf, length + 0.4, 2.4)
	return wall
end

-- Pino nevado (verde oscuro con nieve en las ramas)
local function snowyPine(position, scale)
	Kit.cartoonPine(position, scale, true)
end

-- Quitanieves (cobertura grande en la carretera)
local function snowplow(cf)
	local orange = RGB(220, 120, 30)
	block("PlowCab", V(6, 6.5, 7), cf * CFrame.new(-6, 3.8, 0), orange, M.Metal)
	deco("PlowWindow", V(0.2, 2.2, 6), cf * CFrame.new(-9.1, 5.4, 0), RGB(30, 34, 40), M.Glass)
	block("PlowBody", V(12, 4, 7), cf * CFrame.new(3, 2.8, 0), orange, M.Metal)
	block("PlowBlade", V(1, 3, 10), cf * CFrame.new(-11, 1.5, 0) * CFrame.Angles(0, rad(-12), 0), RGB(200, 200, 205), M.Metal)
	for _, x in { -6, 2, 6 } do
		for _, z in { -3.4, 3.4 } do
			local wheel = deco("Wheel", V(3, 3, 1.2), cf * CFrame.new(x, 1.5, z) * CFrame.Angles(0, math.pi / 2, 0), RGB(28, 28, 30), M.Rubber)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	local light = deco("PlowBeacon", V(1, 0.6, 1), cf * CFrame.new(-6, 7.4, 0), RGB(255, 170, 40), M.Neon)
	Kit.light(light, "PointLight", RGB(255, 170, 40), 14, 1.2)
	Kit.contactShadow(cf * CFrame.new(-2, 0, 0), 22, 8)
end

-- Depósito de combustible (cilindro tumbado sobre patas)
local function fuelTank(cf)
	Kit.pipe("FuelTank", 14, 6, cf * CFrame.new(0, 4.5, 0), RGB(200, 202, 206), M.Metal)
	for _, x in { -5, 5 } do
		block("TankLeg", V(1, 2, 5), cf * CFrame.new(x, 1, 0), RGB(80, 80, 86), M.Metal)
	end
	deco("TankStripe", V(1, 6.1, 6.1), cf * CFrame.new(0, 4.5, 0), RGB(200, 60, 40), M.Metal).Shape = Enum.PartType.Cylinder
	deco("TankSnow", V(12, 0.4, 3), cf * CFrame.new(0, 7.6, 0), SNOW, M.Snow)
end

-- Estación del teleférico: plataforma en alto con rampa, barandilla, cabina y torre del cable
local function cableStation(cf)
	local height = 9
	block("StationDeck", V(26, 1, 18), cf * CFrame.new(0, height - 0.5, 0), RGB(130, 132, 138), M.Concrete)
	for _, x in { -11, 11 } do
		for _, z in { -7, 7 } do
			block("StationPillar", V(1.6, height - 1, 1.6), cf * CFrame.new(x, (height - 1) / 2, z), RGB(120, 122, 128), M.Concrete)
		end
	end
	snowCap(block("StationRoof", V(28, 1, 20), cf * CFrame.new(0, height + 8, 0), RGB(90, 92, 100), M.CorrodedMetal))
	for _, x in { -12.5, 12.5 } do
		deco("RoofPost", V(0.8, 7, 0.8), cf * CFrame.new(x, height + 4, 8.5), RGB(70, 72, 78), M.Metal)
		deco("RoofPost", V(0.8, 7, 0.8), cf * CFrame.new(x, height + 4, -8.5), RGB(70, 72, 78), M.Metal)
	end
	-- Parapeto delantero (cobertura) y barandillas
	block("StationParapet", V(26, 2.6, 0.8), cf * CFrame.new(0, height + 1.3, -8.6), RGB(140, 142, 148), M.Concrete)
	Kit.railing(cf * V(-13, height, 8.6), cf * V(13, height, 8.6), 3, RGB(60, 62, 66))
	-- Cabina colgada del cable (se puede usar como cobertura arriba)
	local cabin = block("CableCabin", V(8, 6, 5), cf * CFrame.new(4, height + 3, 2), RGB(200, 40, 40), M.Metal)
	deco("CabinWindows", V(8.1, 2, 5.1), cf * CFrame.new(4, height + 4.4, 2), RGB(40, 48, 58), M.Glass)
	snowCap(cabin)
	deco("Cable", V(0.25, 0.25, 200), cf * CFrame.new(4, height + 7.8, 2) * CFrame.Angles(rad(-8), rad(90), 0) * CFrame.new(0, 0, -100), RGB(40, 40, 42), M.Metal)
	-- Rampa por detrás
	Kit.ramp(cf * V(-6, 0, 26), cf * V(-6, height, 9.5), 6, RGB(120, 100, 76), M.WoodPlanks)
end

-- Cúpula del radar
local function radarDome(cf)
	block("RadarBase", V(10, 6, 10), cf * CFrame.new(0, 3, 0), RGB(150, 152, 158), M.Concrete)
	Kit.ball("RadarDome", 11, cf * CFrame.new(0, 8, 0), RGB(240, 242, 246), M.SmoothPlastic)
	local beacon = Kit.ball("RadarBeacon", 0.8, cf * CFrame.new(0, 13.6, 0), RGB(255, 50, 40), M.Neon, true)
	beacon:SetAttribute("Blink", 1.2)
end

---------------------------------------------------------------------------
-- Mapa
---------------------------------------------------------------------------

function Map.Build()
	local folder = Kit.Begin(Map.Name, { Realistic = true })
	Kit.applyLighting(Map.Lighting)
	local teams = GameConfig.Teams

	-- Suelo nevado con la carretera despejada
	Kit.terrainFloor(M.Snow, LENGTH + 260, WIDTH + 260)
	block("Road", V(LENGTH + 30, 0.4, 20), CFrame.new(0, 0.2, 0), RGB(84, 86, 92), M.Asphalt)
	for _, z in { -1, 1 } do
		deco("RoadSnowBank", V(LENGTH - 40, 1.2, 3), CFrame.new(0, 0.6, z * 11.5), SNOW, M.Snow)
	end
	block("CrossPath", V(18, 0.3, WIDTH - 40), CFrame.new(0, 0.15, 0), RGB(170, 172, 180), M.Pavement)

	-- Refugio en el centro: dos plantas, puertas a los cuatro lados
	building(CFrame.new(0, 0, 0), 32, 24, {
		Floors = 2,
		Color = RGB(150, 112, 80),
		Material = M.WoodPlanks,
		Doors = { Front = { 7 }, Back = { -7 }, Left = { 0 }, Right = { 0 } },
		Sign = "REFUGIO",
	})
	Kit.cylinder("Chimney", 6, 2.4, CFrame.new(-10, 19, 6), STONE, M.Slate, nil, true)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and teams[1].Color.Color or teams[2].Color.Color

		------------------------------------------------------------------
		-- Carretera central (z -20..20)
		------------------------------------------------------------------
		snowplow(m * CFrame.new(-118, 0, -6) * CFrame.Angles(0, rad(15), 0))
		stoneWall(m * CFrame.new(-90, 0, 8), 12, 4)
		stoneWall(m * CFrame.new(-62, 0, -10) * CFrame.Angles(0, rad(90), 0), 9, 4)
		sandbags(m * CFrame.new(-36, 0, 6), 9)
		for _, p in { V(-140, 0, 14), V(-76, 0, 15), V(-48, 0, -15) } do
			Kit.crate(m * CFrame.new(p), 4)
		end
		Kit.rockCluster(m * V(-100, 0, -16), 4)
		Kit.rockCluster(m * V(-28, 0, 16), 3.5)

		------------------------------------------------------------------
		-- Separaciones: muros de piedra con huecos, cabañas y depósitos
		------------------------------------------------------------------
		for _, seg in { { -168, -140 }, { -126, -96 }, { -82, -54 } } do
			stoneWall(m * CFrame.new((seg[1] + seg[2]) / 2, 0, 30), seg[2] - seg[1], 5)
		end
		solidBlock(m * CFrame.new(-40, 0, 36), 18, 12, 8, WOOD, { Material = M.WoodPlanks, Sign = side == "A" and "ALQUILER DE ESQUÍS" or "TAQUILLA" })
		fuelTank(m * CFrame.new(-150, 0, -36))
		fuelTank(m * CFrame.new(-120, 0, -38))
		stoneWall(m * CFrame.new(-86, 0, -30), 26, 5)
		stoneWall(m * CFrame.new(-44, 0, -30), 20, 5)

		------------------------------------------------------------------
		-- Carril norte (z 50..125): estación del teleférico
		------------------------------------------------------------------
		cableStation(m * CFrame.new(-100, 0, 88))
		stoneWall(m * CFrame.new(-150, 0, 70) * CFrame.Angles(0, rad(90), 0), 18, 5)
		stoneWall(m * CFrame.new(-48, 0, 100), 16, 4)
		sandbags(m * CFrame.new(-22, 0, 74) * CFrame.Angles(0, rad(90), 0), 10)
		Kit.metalCrate(m * CFrame.new(-60, 0, 66), 5, RGB(90, 96, 110))
		Kit.metalCrate(m * CFrame.new(-60, 5, 66), 4, RGB(90, 96, 110))
		solidBlock(m * CFrame.new(-70, 0, 114), 16, 12, 7, WOOD, { Material = M.WoodPlanks })
		Kit.rockCluster(m * V(-128, 0, 116), 6)
		Kit.rockCluster(m * V(-30, 0, 118), 5)

		------------------------------------------------------------------
		-- Carril sur (z -125..-50): laboratorio, radar y trincheras
		------------------------------------------------------------------
		building(m * CFrame.new(-104, 0, -86) * CFrame.Angles(0, math.pi, 0), 36, 22, {
			Floors = 1,
			Color = RGB(196, 200, 206),
			Material = M.Concrete,
			Doors = { Front = { -10, 10 }, Back = { 0 }, Right = { 0 } },
			Sign = "LABORATORIO",
		})
		radarDome(m * CFrame.new(-50, 0, -104))
		sandbags(m * CFrame.new(-66, 0, -62), 12)
		sandbags(m * CFrame.new(-150, 0, -66), 10)
		sandbags(m * CFrame.new(-20, 0, -72) * CFrame.Angles(0, rad(90), 0), 10)
		solidBlock(m * CFrame.new(-84, 0, -120), 14, 10, 6, WOOD, { Material = M.WoodPlanks, Windows = false })
		Kit.rockCluster(m * V(-150, 0, -112), 6)

		------------------------------------------------------------------
		-- Bosque y montañas alrededor; banderas de la base
		------------------------------------------------------------------
		for i = 0, 8 do
			local x = -LENGTH / 2 + i * 24
			for _, z in { -1, 1 } do
				snowyPine(m * V(x + z * 6, 0, z * (WIDTH / 2 + 12 + (i % 3) * 8)), 1.5 + (i % 2) * 0.4)
			end
		end
		for _, z in { -100, -40, 40, 100 } do
			snowyPine(m * V(-LENGTH / 2 - 14, 0, z), 1.7)
		end
		for _, z in { -30, 30 } do
			Kit.banner(m * CFrame.new(-205, 6, z) * CFrame.Angles(0, rad(90), 0), 5, 9, teamColor, RGB(240, 240, 240))
		end
		block("BaseWall", V(2, 12, 90), m * CFrame.new(-206.5, 6, 0), STONE, M.Slate)
	end)

	-- Pinos nevados: verde oscuro y nieve
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "PineTier" then
			local high = math.floor(part.Position.Y) % 3 == 0
			part.Color = high and RGB(220, 226, 236) or RGB(40, 64, 46)
			part.Material = high and M.Snow or M.LeafyGrass
		end
	end

	-- Zonas de salida, banderas y límites
	local spawnStyle = { Floor = RGB(120, 122, 128), FloorMaterial = M.Concrete, Roof = RGB(90, 92, 100), RoofMaterial = M.CorrodedMetal }
	Kit.spawnArea(teams[1], CFrame.new(-184, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-184, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-160, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-160, 0, 0))
	Kit.bounds(LENGTH, WIDTH, 70)

	-- Montañas nevadas alrededor y nieve cayendo
	for _, spec in { { V(-320, 0, 230), 120 }, { V(320, 0, -230), 120 }, { V(40, 0, 320), 130 }, { V(-40, 0, -320), 130 }, { V(-350, 0, -140), 100 }, { V(350, 0, 140), 100 } } do
		Kit.naturalHill(spec[1], spec[2], M.Snow)
	end
	local snow = deco("SnowEmitter", V(LENGTH, 1, WIDTH), CFrame.new(0, 60, 0), SNOW, M.SmoothPlastic)
	snow.Transparency = 1
	local flakes = Instance.new("ParticleEmitter")
	flakes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	flakes.Color = ColorSequence.new(Color3.new(1, 1, 1))
	flakes.Size = NumberSequence.new(0.25)
	flakes.Transparency = NumberSequence.new(0.2)
	flakes.Lifetime = NumberRange.new(10, 14)
	flakes.Speed = NumberRange.new(4, 7)
	flakes.SpreadAngle = Vector2.new(20, 20)
	flakes.Rate = 120
	flakes.EmissionDirection = Enum.NormalId.Bottom
	flakes.WindAffectsDrag = true
	flakes.Drag = 0.4
	flakes.Parent = snow

	-- Puntos de salida libres
	for _, p in {
		V(-150, 0.5, -6), V(-110, 0.5, 8), V(-74, 0.5, -6), V(-44, 0.5, 14),
		V(-160, 0.5, 90), V(-128, 0.5, 64), V(-70, 0.5, 90), V(-24, 0.5, 100),
		V(-160, 0.5, -90), V(-104, 0.5, -112), V(-70, 0.5, -84), V(-24, 0.5, -100),
		V(-108, 9.5, 92), V(-104, 0.5, -86),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	-- Puestos de los tiradores: la estación del teleférico y la planta de arriba del refugio
	for _, spot in {
		{ V(-96, 9, 82), V(-20, 4, 70) },
		{ V(6, FLOOR_H, -8), V(-60, 4, -30) },
	} do
		Kit.botSpot(spot[1], spot[2])
		Kit.botSpot(Kit.MIRROR * spot[1], Kit.MIRROR * spot[2])
	end
	-- Zonas de control
	Kit.zone(V(0, 0, 20), 10, 1)
	Kit.zone(V(-100, 0, 88), 12, 2)
	Kit.zone(V(100, 0, -88), 12, 3)
	Kit.zone(V(0, 0, -20), 10, 4)
	Kit.zone(V(0, 0, 0), 9, 5)
	return folder
end

return Map
