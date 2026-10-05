-- BAHÍA PIRATA: dos orillas de arena separadas por un canal de agua. En el centro, un galeón
-- atracado: se sube por las pasarelas desde cada orilla, la cubierta tiene cañones y barandillas de
-- cobertura y dos castillos (proa y popa) con escalera. Por los extremos, dos puentes de madera
-- cruzan el canal. En las orillas, almacén con azotea, muelles, palmeras, cofres del tesoro y
-- barriles. Si caes al canal se nada y se sale por la orilla. Simétrico.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)
local Variants = require(script.Parent.Parent.LightingVariants)

local Map = {
	Id = "PirateCove",
	Name = "Bahía Pirata",
	Icon = "🏴‍☠️",
	Description = "Mediodía · galeón en el centro · canal, puentes y muelles",
}

Map.Lighting = {
	ClockTime = 13.8,
	Brightness = 3.2,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(125, 122, 130),
	OutdoorAmbient = Color3.fromRGB(175, 170, 175),
	Atmosphere = { Density = 0.22, Offset = 0.2, Color = Color3.fromRGB(200, 230, 255), Decay = Color3.fromRGB(110, 170, 220), Glare = 0, Haze = 0.5 },
	Color = { Saturation = 0.2, Contrast = 0.06, Brightness = 0.03, Tint = Color3.fromRGB(255, 250, 240) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.4,
	SunRays = 0.05,
	ShadowSoftness = 0.3,
	Wind = Vector3.new(6, 0, 3),
	Water = { Color = Color3.fromRGB(25, 150, 175), Reflectance = 0.6, Transparency = 0.55, WaveSize = 0.15, WaveSpeed = 8 },
	TerrainColors = {
		Sand = Color3.fromRGB(240, 215, 150),
		Rock = Color3.fromRGB(150, 135, 120),
		Grass = Color3.fromRGB(110, 200, 90),
		LeafyGrass = Color3.fromRGB(70, 170, 80),
	},
}
-- A veces sale con otra luz o con mal tiempo (ver LightingVariants)
Map.LightingVariants = { Variants.Sunset(0.25), Variants.Storm(0.25) }

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local SAND = RGB(244, 218, 150)
local WOOD = RGB(165, 110, 62)
local WOOD_DARK = RGB(105, 68, 40)
local HULL = RGB(90, 55, 35)
local HULL_TRIM = RGB(225, 180, 70)
local SAIL = RGB(245, 240, 225)
local IRON = RGB(45, 45, 52)
local SMOOTH = Enum.Material.SmoothPlastic
local PLANKS = Enum.Material.WoodPlanks

local LENGTH, WIDTH = 200, 130
local CHANNEL = 24 -- media anchura del canal (x de -24 a 24)
local DECK = 4 -- altura de la cubierta del galeón

-- Cañón sobre su cureña: la cureña es cobertura baja; el tubo, decorado
local function cannon(cf)
	Kit.block("CannonCarriage", V(2.2, 1.2, 3), cf * CFrame.new(0, 0.6, 0), WOOD_DARK, Enum.Material.Wood)
	for _, x in { -1.15, 1.15 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("CannonWheel", 0.3, 1.1, cf * CFrame.new(x, 0.55, z) * CFrame.Angles(0, 0, rad(90)), WOOD, Enum.Material.Wood, nil, true)
		end
	end
	Kit.cylinder("CannonBarrel", 3.6, 0.9, cf * CFrame.new(0, 1.55, -0.6) * CFrame.Angles(rad(90), 0, 0), IRON, Enum.Material.Metal, nil, true)
	Kit.ball("CannonMuzzle", 1.1, cf * CFrame.new(0, 1.55, -2.4), IRON, Enum.Material.Metal, true)
end

-- Cofre del tesoro con monedas
local function treasure(cf)
	Kit.block("Chest", V(3, 2, 2), cf * CFrame.new(0, 1, 0), WOOD_DARK, PLANKS)
	Kit.deco("ChestLid", V(3.1, 0.6, 2.1), cf * CFrame.new(0, 2.3, 0.2) * CFrame.Angles(rad(-25), 0, 0), WOOD, PLANKS)
	Kit.deco("ChestBand", V(3.15, 2.05, 0.3), cf * CFrame.new(0, 1, 0), HULL_TRIM, Enum.Material.Metal)
	for i = 0, 4 do
		Kit.cylinder("Coin", 0.15, 0.8, cf * CFrame.new(-0.8 + i * 0.4, 2.15 + (i % 2) * 0.12, -0.2) * CFrame.Angles(rad(70), 0, 0), RGB(255, 210, 60), Enum.Material.Neon, nil, true)
	end
end

-- Mástil con dos velas y bandera pirata
local function mast(cf, height)
	Kit.cylinder("Mast", height, 1.1, cf * CFrame.new(0, height / 2, 0), WOOD_DARK, Enum.Material.Wood, nil, true)
	Kit.block("MastBase", V(1.4, 3, 1.4), cf * CFrame.new(0, 1.5, 0), WOOD_DARK, Enum.Material.Wood)
	for i, y in { height * 0.45, height * 0.78 } do
		local w = i == 1 and 12 or 9
		Kit.deco("Yard", V(w + 1, 0.4, 0.4), cf * CFrame.new(0, y + 3.2, 0), WOOD_DARK, Enum.Material.Wood)
		Kit.deco("Sail", V(w, 6, 0.3), cf * CFrame.new(0, y, -0.6) * CFrame.Angles(rad(-6), 0, 0), SAIL, Enum.Material.Fabric)
	end
	local flag = Kit.deco("PirateFlag", V(3.4, 2.2, 0.1), cf * CFrame.new(1.9, height + 0.6, 0), RGB(25, 25, 30), Enum.Material.Fabric)
	Kit.sign(flag, Enum.NormalId.Front, "☠", Color3.new(1, 1, 1))
	Kit.sign(flag, Enum.NormalId.Back, "☠", Color3.new(1, 1, 1))
end

-- Mitad del galeón (la otra mitad sale girada 180°): castillo con escalera, barandilla con huecos
-- para las pasarelas, cañones y mástil
local function shipHalf(m, teamColor)
	-- Castillo (proa o popa) al final de la cubierta
	Kit.block("Castle", V(14, 4, 10), m * CFrame.new(0, DECK + 2, 23), HULL, PLANKS)
	Kit.deco("CastleTrim", V(14.3, 0.4, 10.3), m * CFrame.new(0, DECK + 3.8, 23), HULL_TRIM, SMOOTH)
	for _, x in { -6.6, 6.6 } do
		Kit.block("CastleRail", V(0.6, 1.4, 10), m * CFrame.new(x, DECK + 4.7, 23), WOOD_DARK, Enum.Material.Wood)
	end
	Kit.block("CastleRailEnd", V(14, 1.4, 0.6), m * CFrame.new(0, DECK + 4.7, 27.7), WOOD_DARK, Enum.Material.Wood)
	Kit.stairs(m * V(3.5, DECK, 10.5), m * V(3.5, DECK + 4, 17.9), 3, WOOD, PLANKS)
	-- Farol del castillo
	local lamp = Kit.deco("CastleLantern", V(0.8, 1.2, 0.8), m * CFrame.new(-5.5, DECK + 6.2, 27.2), RGB(255, 200, 110), Enum.Material.Neon)
	Kit.light(lamp, "PointLight", RGB(255, 190, 110), 14, 1)
	-- Barandilla del lado izquierdo (visto desde esta mitad) con huecos en z 0 y z -15 (pasarelas)
	for _, seg in { { -12, -3 }, { 3, 18 } } do
		local len = seg[2] - seg[1]
		Kit.block("DeckRail", V(0.6, 1.4, len), m * CFrame.new(-6.6, DECK + 0.7, (seg[1] + seg[2]) / 2), WOOD_DARK, Enum.Material.Wood)
	end
	-- Pasarelas desde la orilla
	for _, z in { 0, -15 } do
		Kit.ramp(m * V(-CHANNEL - 1, 0, z), m * V(-7, DECK, z), 4, WOOD, PLANKS)
	end
	-- Cañones mirando hacia la borda y un mástil
	-- (los cañones lejos del pie de las escaleras de los castillos)
	cannon(m * CFrame.new(-4.4, DECK, 5.5) * CFrame.Angles(0, rad(90), 0))
	cannon(m * CFrame.new(-4.4, DECK, -5.5) * CFrame.Angles(0, rad(90), 0))
	mast(m * CFrame.new(0, DECK, 12), 22)
	Kit.barrel(m * CFrame.new(2, DECK, -2), RGB(140, 90, 50))
	Kit.crate(m * CFrame.new(2.5, DECK, 1.5), 3, WOOD)
	-- Escudos del equipo en el casco
	for _, z in { -10, 10 } do
		Kit.cylinder("HullShield", 0.3, 2.4, m * CFrame.new(-7.1, DECK - 1.2, z) * CFrame.Angles(0, 0, rad(90)), teamColor, SMOOTH, nil, true)
	end
end

-- Almacén del muelle con escalera trasera a la azotea (murete delante)
local function warehouse(cf, size, color, label)
	Kit.block("Warehouse", size, cf * CFrame.new(0, size.Y / 2, 0), color, PLANKS)
	Kit.contactShadow(cf, size.X + 0.4, size.Z + 0.4, false)
	Kit.block("RoofWall", V(size.X, 2.6, 0.8), cf * CFrame.new(0, size.Y + 1.3, -(size.Z / 2 - 0.4)), color, PLANKS)
	Kit.deco("RoofTrim", V(size.X + 0.6, 0.5, size.Z + 0.6), cf * CFrame.new(0, size.Y - 0.25, 0), WOOD_DARK, SMOOTH)
	Kit.deco("Door", V(4, 6, 0.2), cf * CFrame.new(0, 3, -(size.Z / 2 + 0.1)), WOOD_DARK, PLANKS)
	local board = Kit.deco("Sign", V(size.X * 0.6, 2, 0.3), cf * CFrame.new(0, size.Y - 2, -(size.Z / 2 + 0.15)), RGB(245, 230, 190), SMOOTH)
	Kit.sign(board, Enum.NormalId.Front, label, RGB(110, 50, 30))
	for _, x in { -1, 1 } do
		Kit.deco("Window", V(2.2, 2.2, 0.2), cf * CFrame.new(x * size.X * 0.3, 3.5, -(size.Z / 2 + 0.1)), RGB(60, 70, 90), Enum.Material.Glass)
	end
	Kit.stairs(cf * V(-size.X / 2 + 2.5, 0, size.Z / 2 + 16), cf * V(-size.X / 2 + 2.5, size.Y, size.Z / 2 + 0.2), 4, WOOD, PLANKS)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Coast") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Kit.pickLighting(Map))
	folder:SetAttribute("Variant", Kit.Variant)
	folder:SetAttribute("Weather", Kit.Weather)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Mar alrededor y canal en el centro (el fondo del canal es arena)
	workspace.Terrain:FillBlock(CFrame.new(0, -6, 0), V(900, 10, 700), Enum.Material.Water)
	workspace.Terrain:FillBlock(CFrame.new(0, -12, 0), V(900, 2, 700), Enum.Material.Sand)
	for _, sx in { -1, 1 } do
		local width = LENGTH / 2 + 20 - CHANNEL
		-- (macizas hasta el fondo: no se puede bucear por debajo y salir del mapa)
		block("Sand", V(width, 12, WIDTH + 20), CFrame.new(sx * (CHANNEL + width / 2), -6, 0), SAND, Enum.Material.Sand)
		-- Muelle de tablones a lo largo del canal
		deco("Dock", V(5, 0.3, WIDTH + 10), CFrame.new(sx * (CHANNEL + 2.5), 0.12, 0), WOOD, PLANKS)
		for z = -60, 60, 10 do
			Kit.cylinder("DockPost", 5, 0.8, CFrame.new(sx * (CHANNEL + 0.4), -1.5, z), WOOD_DARK, Enum.Material.Wood, nil, true)
		end
	end
	block("ChannelBed", V(CHANNEL * 2, 1, WIDTH + 20), CFrame.new(0, -5.5, 0), SAND, Enum.Material.Sand)

	-- Galeón: casco y cubierta (las dos mitades iguales giradas)
	block("Hull", V(14, 8, 56), CFrame.new(0, 0, 0), HULL, PLANKS)
	deco("HullTrim", V(14.3, 0.6, 56.3), CFrame.new(0, DECK - 0.6, 0), HULL_TRIM, SMOOTH)
	deco("DeckPlanks", V(13.6, 0.1, 55.6), CFrame.new(0, DECK + 0.05, 0), WOOD, PLANKS)
	for _, sz in { -1, 1 } do
		block("Bow", V(9, 7, 5), CFrame.new(0, 0.5, sz * 30.5), HULL, PLANKS)
		block("BowTip", V(4, 6, 4), CFrame.new(0, 1, sz * 35), HULL, PLANKS)
	end
	Kit.pipe("Bowsprit", 12, 0.6, CFrame.new(0, DECK + 3, -40) * CFrame.Angles(0, rad(90), rad(15)), WOOD_DARK, nil, true)
	mast(CFrame.new(0, DECK, 0), 28)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(235, 70, 70) or RGB(60, 130, 240)
		shipHalf(m, teamColor)

		-- Puente de madera sobre el canal (uno a cada extremo)
		block("Bridge", V(CHANNEL * 2 + 4, 1, 8), m * CFrame.new(0, 0, 52), WOOD, PLANKS)
		for _, z in { 48.3, 55.7 } do
			block("BridgeRail", V(CHANNEL * 2 + 4, 1.4, 0.5), m * CFrame.new(0, 1.2, z), WOOD_DARK, Enum.Material.Wood)
		end

		-- Orilla: almacén con azotea, cofres, barriles, cajas y palmeras
		warehouse(m * CFrame.new(-58, 0, 36), V(18, 9, 14), side == "A" and RGB(200, 120, 90) or RGB(110, 150, 190), "ALMACÉN")
		treasure(m * CFrame.new(-34, 0, 22) * CFrame.Angles(0, rad(20), 0))
		treasure(m * CFrame.new(-70, 0, -40) * CFrame.Angles(0, rad(-30), 0))
		Kit.crate(m * CFrame.new(-36, 0, -10), 4, WOOD)
		Kit.crate(m * CFrame.new(-39, 0, -13), 3.5, WOOD)
		Kit.crate(m * CFrame.new(-36, 4, -10), 2.5, WOOD)
		Kit.barrel(m * CFrame.new(-30, 0, 12), RGB(140, 90, 50))
		Kit.barrel(m * CFrame.new(-32, 0, 14.5), RGB(140, 90, 50))
		Kit.barrel(m * CFrame.new(-48, 0, -26), RGB(120, 80, 45))
		cannon(m * CFrame.new(-44, 0, 8) * CFrame.Angles(0, rad(-90), 0))
		cannon(m * CFrame.new(-44, 0, -36) * CFrame.Angles(0, rad(-90), 0))
		-- Muro bajo de piedra (cobertura) junto al canal
		block("SeaWall", V(2, 2.4, 16), m * CFrame.new(-31, 1.2, -32), RGB(160, 150, 135), Enum.Material.Cobblestone)
		block("SeaWall", V(2, 2.4, 10), m * CFrame.new(-31, 1.2, 34), RGB(160, 150, 135), Enum.Material.Cobblestone)
		for _, p in { V(-78, 0, 50), V(-28, 0, 58), V(-52, 0, -56), V(-80, 0, -52), V(-24, 0, -58) } do
			Kit.palm(m * CFrame.new(p), 13 + (p.Z % 4))
		end
		Kit.banner(m * CFrame.new(-68, 12, 22) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, RGB(255, 210, 80))
		Kit.banner(m * CFrame.new(-68, 12, -22) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, RGB(255, 210, 80))
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(245, 225, 175), Roof = RGB(240, 225, 190), RoofMaterial = PLANKS }
	Kit.spawnArea(teams[1], CFrame.new(-85, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-85, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-62, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-62, 0, 0))

	-- Fondo: barcos y un faro en el mar
	Kit.bounds(LENGTH, WIDTH, 60)
	-- Nombres de las zonas
	Kit.callout("CANAL", CFrame.new(0, 2, 0), V(CHANNEL * 2, 30, WIDTH))
	Kit.callout("GALEÓN", CFrame.new(0, 8, 0), V(16, 30, 76))
	for _, m in { CFrame.new(), Kit.MIRROR } do
		Kit.callout("PUENTE", m * CFrame.new(0, 4, 52), V(CHANNEL * 2 + 6, 16, 10))
		Kit.callout("ALMACÉN", m * CFrame.new(-58, 8, 36), V(22, 24, 18))
	end
	-- Los extremos del canal se cierran también por debajo del agua (los muros empiezan en y = 0)
	local boundary = folder:FindFirstChild("Boundary")
	for _, sz in { -1, 1 } do
		local wall = block("Boundary", V(CHANNEL * 2 + 4, 16, 4), CFrame.new(0, -6, sz * (WIDTH / 2 + 2)), Color3.new(1, 1, 1), nil, boundary)
		wall.Transparency = 1
		wall.CastShadow = false
	end
	Kit.lighthouse(V(-60, 0, -(WIDTH / 2 + 70)))
	for _, p in { { V(80, -1, WIDTH / 2 + 80), 0 }, { V(-150, -1, 30), 90 } } do
		local cf = CFrame.new(p[1]) * CFrame.Angles(0, rad(p[2]), 0)
		deco("FarHull", V(12, 6, 40), cf * CFrame.new(0, 1, 0), HULL, PLANKS)
		deco("FarSail", V(10, 12, 0.4), cf * CFrame.new(0, 12, 0), SAIL, Enum.Material.Fabric)
		deco("FarSail", V(8, 9, 0.4), cf * CFrame.new(0, 11, 12), SAIL, Enum.Material.Fabric)
	end

	-- Modos
	for _, p in {
		V(-76, 0.5, 8), V(-76, 0.5, -16), V(-50, 0.5, 6), V(-40, 0.5, 26), V(-30, 0.5, -46),
		V(-58, 9.5, 36), V(0, DECK + 0.5, -6), V(-3, DECK + 4.5, 23), V(-60, 0.5, -44), V(-38, 0.5, 52),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, DECK, 0), 6, 1)
	Kit.zone(V(-44, 0, -12), 6, 2)
	Kit.zone(V(44, 0, 12), 6, 3)
	Kit.zone(V(-58, 9, 36), 5, 4)
	Kit.zone(V(58, 9, -36), 5, 5)
	return folder
end

return Map
