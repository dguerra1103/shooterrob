-- PUESTO DEL DESIERTO: aldea de adobe en un cruce de caminos del desierto, 5 contra 5. Identidad:
-- arena cálida con puertas, toldos y detalles turquesa. En el centro el caravasar (dos plantas, se
-- entra por tres lados) que corta la línea de tiro de base a base por la calle mayor. Al norte, los
-- callejones (casas de adobe pegadas, pasos estrechos y una plazuela con el pozo); al sur, la
-- chatarrería (espacio abierto con un tanque, un autobús y coches quemados: cobertura baja y larga
-- distancia). Simétrico por rotación. Siempre en estilo realista (luz propia).
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)
local RealKit = require(script.Parent.Parent.RealKit)

local Map = {
	Id = "DesertOutpost",
	Bomb = true, -- tiene sitios para Buscar y destruir
	Name = "Puesto del Desierto",
	Icon = "🏜️",
	Description = "Aldea de adobe · callejones, caravasar y chatarrería · 5 contra 5",
	Realistic = true,
}

Map.Lighting = {
	ClockTime = 15.6,
	Latitude = 25,
	Brightness = 3,
	Exposure = -0.05,
	Ambient = Color3.fromRGB(112, 98, 86),
	OutdoorAmbient = Color3.fromRGB(184, 164, 144),
	ShadowSoftness = 0.15,
	Atmosphere = { Density = 0.3, Offset = 0.22, Color = Color3.fromRGB(240, 222, 192), Decay = Color3.fromRGB(184, 146, 104), Glare = 0.3, Haze = 1.3 },
	Color = { Saturation = 0.1, Contrast = 0.12, Brightness = 0.01, Tint = Color3.fromRGB(255, 244, 228) },
	Bloom = { Intensity = 0.45, Size = 22, Threshold = 1.9 },
	Clouds = 0.2,
	CloudColor = Color3.fromRGB(255, 246, 232),
	SunRays = 0.06,
	SunSize = 24,
	Wind = Vector3.new(7, 0, 3),
	TerrainColors = {
		Sand = Color3.fromRGB(216, 186, 140),
		Sandstone = Color3.fromRGB(196, 150, 104),
		Ground = Color3.fromRGB(172, 138, 100),
		Rock = Color3.fromRGB(150, 120, 92),
	},
}

-- Versiones de luz (a veces): atardecer naranja y tormenta de arena (aire ocre, sin sol)
Map.LightingVariants = {
	{
		Name = "Atardecer",
		Chance = 0.25,
		ClockTime = 17.9,
		Brightness = 2.2,
		Ambient = Color3.fromRGB(120, 92, 82),
		OutdoorAmbient = Color3.fromRGB(176, 140, 120),
		Atmosphere = { Density = 0.32, Offset = 0.2, Color = Color3.fromRGB(255, 196, 150), Decay = Color3.fromRGB(190, 110, 80), Glare = 0.4, Haze = 1.4 },
		Color = { Saturation = 0.12, Contrast = 0.12, Brightness = 0.02, Tint = Color3.fromRGB(255, 232, 210) },
		CloudColor = Color3.fromRGB(255, 190, 150),
	},
	{
		Name = "Tormenta de arena",
		Chance = 0.2,
		ClockTime = 14,
		Brightness = 1.8,
		Ambient = Color3.fromRGB(130, 110, 90),
		OutdoorAmbient = Color3.fromRGB(190, 166, 136),
		Atmosphere = { Density = 0.42, Offset = 0.05, Color = Color3.fromRGB(226, 190, 140), Decay = Color3.fromRGB(190, 150, 100), Glare = 0, Haze = 2.4 },
		Color = { Saturation = 0.04, Contrast = 0.08, Brightness = 0.03, Tint = Color3.fromRGB(255, 236, 205) },
		Clouds = 0.9,
		CloudColor = Color3.fromRGB(210, 180, 140),
		SunRays = 0,
		Wind = Vector3.new(22, 0, 8),
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

local ADOBE = { RGB(214, 172, 124), RGB(200, 156, 110), RGB(226, 190, 146), RGB(190, 140, 100) }
local TEAL = RGB(36, 150, 150) -- color de identidad del mapa: puertas, toldos y detalles
local TERRACOTTA = RGB(176, 92, 60)
local WOOD = RGB(112, 80, 54)

---------------------------------------------------------------------------
-- Piezas de la aldea
---------------------------------------------------------------------------

-- Casa de adobe maciza (no se entra): ventanas, cornisa y, si tiene cartel, toldo turquesa
local function adobeHouse(cf, sx, sz, height, color, sign)
	solidBlock(cf, sx, sz, height, color, {
		Material = M.Sandstone,
		Sign = sign,
		AwningColor = TEAL,
		Boarded = false,
	})
	-- Identidad del mapa: puerta turquesa en la fachada y una franja turquesa bajo el tejado
	deco("TealDoor", V(3.4, 6.2, 0.3), cf * CFrame.new(sx * 0.28, 3.1, -sz / 2 - 0.1), TEAL, M.WoodPlanks)
	deco("TealBand", V(sx + 0.5, 0.6, sz + 0.5), cf * CFrame.new(0, height - 2.6, 0), TEAL, M.SmoothPlastic)
	-- Vigas de madera asomando por arriba (típico del adobe)
	for i = 1, math.max(2, math.floor(sx / 6)) do
		local x = -sx / 2 + (i - 0.5) * sx / math.max(2, math.floor(sx / 6))
		deco("Beam", V(0.6, 0.6, 1.6), cf * CFrame.new(x, height - 1.6, -sz / 2 - 0.5), WOOD, M.Wood)
	end
end

-- Pozo con tejadillo (punto de referencia de la plazuela; cobertura baja)
local function well(cf)
	Kit.cylinder("WellRim", 3, 7, cf * CFrame.new(0, 1.5, 0), RGB(170, 140, 110), M.Sandstone)
	Kit.cylinder("WellWater", 0.2, 5.6, cf * CFrame.new(0, 2.6, 0), RGB(30, 90, 100), M.Glass, nil, true)
	for _, x in { -3.2, 3.2 } do
		block("WellPost", V(0.6, 7, 0.6), cf * CFrame.new(x, 3.5, 0), WOOD, M.Wood)
	end
	deco("WellRoof", V(8, 0.4, 5), cf * CFrame.new(0, 7.2, 0) * CFrame.Angles(0, 0, rad(4)), TEAL, M.WoodPlanks)
	deco("WellBucket", V(1, 1.1, 1), cf * CFrame.new(0, 4.6, 0), RGB(90, 70, 50), M.Wood)
end

-- Tendedero con ropa de colores entre dos puntos (solo vista)
local function laundry(a, b, y)
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid + V(0, y, 0), b + V(0, y, 0))
	deco("Line", V(0.08, 0.08, length), cf, RGB(40, 40, 40), M.SmoothPlastic)
	local colors = { TEAL, RGB(230, 210, 170), TERRACOTTA, RGB(220, 200, 90), RGB(240, 240, 235) }
	for i = 1, math.floor(length / 3) do
		local z = -length / 2 + i * 3
		deco("Cloth", V(1.6, 2.2, 0.08), cf * CFrame.new(0, -1.1, z) * CFrame.Angles(0, rad(90), 0), colors[(i % #colors) + 1], M.Fabric)
	end
end

-- Tinaja de barro
local function jar(cf, scale)
	scale = scale or 1
	Kit.cylinder("Jar", 2.4 * scale, 1.8 * scale, cf * CFrame.new(0, 1.2 * scale, 0), TERRACOTTA, M.Slate)
	Kit.cylinder("JarNeck", 0.5 * scale, 1 * scale, cf * CFrame.new(0, 2.6 * scale, 0), TERRACOTTA, M.Slate, nil, true)
end

-- Alfombra colgada de una pared o un tendedero (mirando a -Z de cf)
local function rug(cf, color)
	deco("Rug", V(3, 4.4, 0.1), cf, color, M.Fabric)
	deco("RugBand", V(3.02, 0.5, 0.12), cf * CFrame.new(0, 1.4, 0), RGB(240, 220, 170), M.Fabric)
	deco("RugBand", V(3.02, 0.5, 0.12), cf * CFrame.new(0, -1.4, 0), RGB(240, 220, 170), M.Fabric)
end

---------------------------------------------------------------------------
-- Mapa
---------------------------------------------------------------------------

function Map.Build()
	local folder = Kit.Begin(Map.Name, { Realistic = true })
	folder:SetAttribute("Ambience", "Desert") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Kit.pickLighting(Map))
	folder:SetAttribute("Variant", Kit.Variant)
	folder:SetAttribute("Weather", Kit.Weather)
	local teams = GameConfig.Teams

	-- Suelo: arena, la calle mayor de tierra apisonada y el cruce empedrado
	Kit.terrainFloor(M.Sand, LENGTH + 260, WIDTH + 260)
	block("MainStreet", V(LENGTH + 30, 0.4, 36), CFrame.new(0, 0.2, 0), RGB(176, 142, 104), M.Ground)
	block("CrossStreet", V(26, 0.4, WIDTH - 20), CFrame.new(0, 0.21, 0), RGB(190, 164, 128), M.Cobblestone)

	-- Caravasar en el centro: dos plantas, puertas a la calle por los dos lados y por la derecha
	building(CFrame.new(0, 0, 0), 30, 22, {
		Floors = 2,
		Color = ADOBE[1],
		Material = M.Sandstone,
		Doors = { Front = { 7 }, Back = { 7 } }, -- (una puerta para cada equipo; por la izquierda va la escalera)
		Sign = "CARAVASAR",
	})
	-- Cúpula turquesa encima (se ve desde todo el mapa)
	-- (encima del tejado, apoyada en su tambor: no asoma dentro de la planta de arriba)
	block("DomeBase", V(13, 6, 13), CFrame.new(-5, 20, 0), ADOBE[3], M.Sandstone)
	Kit.ball("Dome", 12, CFrame.new(-5, 24, 0), TEAL, M.SmoothPlastic, true)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and teams[1].Color.Color or teams[2].Color.Color

		------------------------------------------------------------------
		-- Calle mayor (z -18..18): carro, sacos, tinajas y palmeras
		------------------------------------------------------------------
		RealKit.burntCar(m * CFrame.new(-120, 0, -7) * CFrame.Angles(0, rad(12), 0), false)
		sandbags(m * CFrame.new(-86, 0, 8), 10)
		sandbags(m * CFrame.new(-50, 0, -9) * CFrame.Angles(0, rad(90), 0), 8)
		block("Cart", V(8, 3, 4.5), m * CFrame.new(-150, 1.8, 10), WOOD, M.WoodPlanks)
		for _, x in { -153, -147 } do
			local wheel = deco("CartWheel", V(3.4, 3.4, 0.5), m * CFrame.new(x, 1.7, 12.6), RGB(80, 60, 40), M.Wood)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CFrame = m * CFrame.new(x, 1.7, 12.6) * CFrame.Angles(0, rad(90), 0)
		end
		for _, p in { V(-104, 0, 14), V(-66, 0, -14), V(-30, 0, 13) } do
			jar(m * CFrame.new(p), 1.1)
		end
		Kit.crate(m * CFrame.new(-138, 0, -14), 4)
		-- Muros altos a los dos lados del caravasar: cortan la línea de tiro de base a base por los
		-- bordes de la calle (el caravasar solo tapa el centro)
		solidBlock(m * CFrame.new(-24, 0, 18), 8, 10, 8, ADOBE[4], { Material = M.Sandstone, Windows = false })
		solidBlock(m * CFrame.new(-24, 0, -18), 8, 10, 8, ADOBE[4], { Material = M.Sandstone, Windows = false })
		Kit.crate(m * CFrame.new(-72, 0, 13), 4)
		for x = -156, -30, 28 do
			Kit.palm(m * CFrame.new(x, 0, 21), 13 + (x % 3))
			Kit.palm(m * CFrame.new(x + 14, 0, -21), 12 + (x % 2))
		end

		------------------------------------------------------------------
		-- Fila norte (z 24..46): la posada (dos plantas, ventanas a la calle) y tiendas
		------------------------------------------------------------------
		adobeHouse(m * CFrame.new(-150, 0, 35), 24, 18, 12, ADOBE[2], side == "A" and "TÉ Y DÁTILES" or "ALFOMBRAS")
		building(m * CFrame.new(-112, 0, 35), 30, 22, {
			Floors = 2,
			Color = ADOBE[3],
			Material = M.Sandstone,
			Doors = { Front = { -6 }, Back = { 6 } },
			Blind = { Left = true },
			Sign = "POSADA",
		})
		building(m * CFrame.new(-68, 0, 34), 24, 18, {
			Floors = 1,
			Color = ADOBE[4],
			Material = M.Sandstone,
			Ruined = true,
			Doors = { Front = { -4 }, Back = { 5 }, Right = { 0 } },
		})
		RealKit.stall(m * CFrame.new(-40, 0, 30), TEAL)
		RealKit.stall(m * CFrame.new(-30, 0, 40) * CFrame.Angles(0, rad(90), 0), TERRACOTTA)
		rug(m * CFrame.new(-150, 4.5, 25.9) * CFrame.Angles(0, math.pi, 0), side == "A" and RGB(160, 40, 50) or RGB(40, 70, 140))

		------------------------------------------------------------------
		-- Fila sur (z -46..-24): telégrafos (dos plantas) y la forja
		------------------------------------------------------------------
		adobeHouse(m * CFrame.new(-152, 0, -35), 22, 20, 12, ADOBE[1], side == "A" and "FORJA" or "ESPECIAS")
		building(m * CFrame.new(-114, 0, -35) * CFrame.Angles(0, math.pi, 0), 28, 22, {
			Floors = 2,
			Color = ADOBE[2],
			Material = M.Sandstone,
			Doors = { Front = { 5 }, Back = { -5 } },
			Blind = { Right = true },
			Sign = "TELÉGRAFOS",
		})
		adobeHouse(m * CFrame.new(-72, 0, -35), 24, 20, 10, ADOBE[3])
		RealKit.stall(m * CFrame.new(-36, 0, -31), RGB(200, 160, 60))

		------------------------------------------------------------------
		-- Carril norte (z 50..125): los callejones y la plazuela del pozo
		------------------------------------------------------------------
		adobeHouse(m * CFrame.new(-160, 0, 68), 18, 14, 10, ADOBE[4])
		adobeHouse(m * CFrame.new(-162, 0, 112), 22, 18, 12, ADOBE[1])
		building(m * CFrame.new(-128, 0, 100) * CFrame.Angles(0, -math.pi / 2, 0), 24, 22, {
			Floors = 2,
			Color = ADOBE[2],
			Material = M.Sandstone,
			Doors = { Front = { 0 }, Back = { 4 } },
			Sign = "CASA DEL JEQUE",
		})
		well(m * CFrame.new(-94, 0, 86))
		adobeHouse(m * CFrame.new(-62, 0, 114), 22, 16, 10, ADOBE[3])
		adobeHouse(m * CFrame.new(-58, 0, 64), 16, 14, 9, ADOBE[1])
		building(m * CFrame.new(-28, 0, 94), 20, 18, {
			Floors = 1,
			Color = ADOBE[4],
			Material = M.Sandstone,
			Ruined = true,
			Doors = { Front = { 0 }, Left = { 0 }, Right = { 2 } },
		})
		RealKit.ruinWall(m * CFrame.new(-110, 0, 64), 12, 5, ADOBE[2])
		sandbags(m * CFrame.new(-80, 0, 104) * CFrame.Angles(0, rad(90), 0), 8)
		laundry(m * V(-151, 0, 75), m * V(-136, 0, 88), 8)
		laundry(m * V(-73, 0, 106), m * V(-66, 0, 72), 7.5)
		for _, p in { V(-104, 0, 74), V(-84, 0, 96), V(-150, 0, 92) } do
			jar(m * CFrame.new(p), 0.9)
		end
		Kit.stringLights(m * V(-110, 8, 70), m * V(-78, 8, 100), RGB(255, 210, 140))

		------------------------------------------------------------------
		-- Carril sur (z -125..-50): la chatarrería (abierta, cobertura baja y alguna alta)
		------------------------------------------------------------------
		RealKit.tankWreck(m * CFrame.new(-104, 0, -92) * CFrame.Angles(0, rad(25), 0))
		RealKit.bus(m * CFrame.new(-60, 0, -70) * CFrame.Angles(0, rad(-12), 0))
		RealKit.burntCar(m * CFrame.new(-146, 0, -72) * CFrame.Angles(0, rad(70), 0), true)
		RealKit.burntCar(m * CFrame.new(-36, 0, -112) * CFrame.Angles(0, rad(-30), 0), false)
		building(m * CFrame.new(-152, 0, -106), 26, 20, {
			Floors = 1,
			Color = ADOBE[3],
			Material = M.Sandstone,
			Doors = { Front = { -6, 6 }, Right = { 0 } },
			Sign = "GARAJE",
		})
		Kit.container(m * CFrame.new(-80, 0, -118), RGB(150, 70, 50), "CARGA")
		sandbags(m * CFrame.new(-120, 0, -60), 12)
		sandbags(m * CFrame.new(-24, 0, -78) * CFrame.Angles(0, rad(90), 0), 10)
		for _, p in { V(-128, 0, -112), V(-78, 0, -96), V(-50, 0, -96), V(-20, 0, -58) } do
			Kit.crate(m * CFrame.new(p), 4.5)
		end
		Kit.crate(m * CFrame.new(-78, 4.5, -96), 3.5)
		for _, p in { V(-90, 0, -66), V(-136, 0, -90), V(-30, 0, -96) } do
			Kit.barrel(m * CFrame.new(p), RGB(150, 70, 50))
		end

		------------------------------------------------------------------
		-- Borde: muralla de adobe, dunas y la base
		------------------------------------------------------------------
		for i = 0, 7 do
			local x = -LENGTH / 2 + 25 + i * 50
			Kit.palm(m * CFrame.new(x, 0, WIDTH / 2 + 10), 15)
		end
		for _, z in { -30, 30 } do
			Kit.banner(m * CFrame.new(-205, 11, z) * CFrame.Angles(0, rad(90), 0), 5, 9, teamColor, RGB(240, 230, 210))
		end
		block("BaseWall", V(2, 12, 90), m * CFrame.new(-206.5, 6, 0), ADOBE[4], M.Sandstone)
	end)

	-- Muralla de la aldea por los lados largos (justo fuera del límite)
	for _, z in { -1, 1 } do
		block("TownWall", V(LENGTH + 10, 10, 3), CFrame.new(0, 5, z * (WIDTH / 2 + 4)), ADOBE[2], M.Sandstone)
		for x = -LENGTH / 2, LENGTH / 2, 10 do
			deco("Crenel", V(3, 2, 3.2), CFrame.new(x, 11, z * (WIDTH / 2 + 4)), ADOBE[2], M.Sandstone)
		end
	end

	-- Zonas de salida, banderas y límites
	local spawnStyle = { Floor = RGB(170, 140, 104), FloorMaterial = M.Sandstone, Roof = RGB(120, 92, 66), RoofMaterial = M.WoodPlanks }
	Kit.spawnArea(teams[1], CFrame.new(-184, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-184, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-160, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-160, 0, 0))
	Kit.bounds(LENGTH, WIDTH, 70)
	-- Nombres de las zonas (los edificios con cartel ya dan el suyo)
	Kit.callout("CALLE MAYOR", CFrame.new(0, 12, 0), V(LENGTH, 36, 40))
	Kit.callout("CRUCE", CFrame.new(0, 12, 0), V(28, 36, WIDTH))
	for _, m in { CFrame.new(), Kit.MIRROR } do
		Kit.callout("CALLEJONES", m * CFrame.new(-96, 14, 88), V(172, 44, 80))
		Kit.callout("PLAZUELA DEL POZO", m * CFrame.new(-94, 10, 86), V(26, 24, 26))
		Kit.callout("CHATARRERÍA", m * CFrame.new(-96, 14, -88), V(172, 44, 80))
		Kit.callout("MERCADO", m * CFrame.new(-35, 10, 35), V(26, 24, 22))
	end

	-- Dunas alrededor y algo de polvo en el aire
	for _, spec in { { V(-330, 0, 245), 110 }, { V(330, 0, -245), 110 }, { V(40, 0, 320), 120 }, { V(-40, 0, -320), 120 }, { V(-365, 0, -130), 95 }, { V(365, 0, 130), 95 } } do
		Kit.naturalHill(spec[1], spec[2], M.Sand)
	end
	Kit.dustMotes(CFrame.new(0, 8, 0), V(LENGTH, 14, WIDTH), RGB(230, 200, 150), Kit.Variant == "Tormenta de arena" and 60 or 18)

	-- Puntos de salida libres
	for _, p in {
		V(-150, 0.5, -2), V(-104, 0.5, 4), V(-74, 0.5, -4), V(-40, 0.5, 4),
		V(-140, 0.5, 86), V(-108, 0.5, 80), V(-80, 0.5, 70), V(-40, 0.5, 70),
		V(-170, 0.5, -90), V(-120, 0.5, -76), V(-70, 0.5, -100), V(-24, 0.5, -96),
		V(-112, 0.5, 35), V(-114, 0.5, -35),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	-- Puestos de los tiradores: ventanas de arriba de la posada, los telégrafos y la casa del jeque
	for _, spot in {
		{ V(-112, FLOOR_H, 26.7), V(-40, 4, 0) },
		{ V(-114, FLOOR_H, -26.7), V(-40, 4, 0) },
		{ V(-119.7, FLOOR_H, 108), V(-60, 4, 90) },
	} do
		Kit.botSpot(spot[1], spot[2])
		Kit.botSpot(Kit.MIRROR * spot[1], Kit.MIRROR * spot[2])
	end
	-- Buscar y destruir: cada equipo defiende dos sitios en su mitad (A: plazuela; B: chatarrería)
	for _, site in { { V(-94, 0, 74), "A" }, { V(-118, 0, -84), "B" } } do
		Kit.bombSite(site[1], site[2], 1)
		Kit.bombSite(Kit.MIRROR * site[1], site[2], 2)
	end
	-- Zonas de control: delante del caravasar, la plazuela, la chatarrería y los lados del cruce
	Kit.zone(V(0, 0, 22), 10, 1)
	Kit.zone(V(-94, 0, 74), 11, 2)
	Kit.zone(V(94, 0, -74), 11, 3)
	Kit.zone(V(0, 0, -22), 10, 4)
	Kit.zone(V(0, 0, 60), 9, 5)
	return folder
end

return Map
