-- JARDÍN SAKURA: arena compacta en un jardín japonés de estilo cartoon. Pagoda central jugable de dos
-- plantas, toriis rojos en las entradas, estanques con nenúfares y puentes de madera, cerezos en flor
-- con pétalos cayendo, linternas de piedra, bambú, casas de té y una montaña nevada de fondo.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)
local Variants = require(script.Parent.Parent.LightingVariants)

local Map = {
	Id = "SakuraGarden",
	Name = "Jardín Sakura",
	Icon = "🌸",
	Description = "Jardín japonés · tarde · pagoda y estanques",
}

Map.Lighting = {
	ClockTime = 16.3,
	Brightness = 3,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(125, 112, 130),
	OutdoorAmbient = Color3.fromRGB(170, 158, 175),
	Atmosphere = { Density = 0.24, Offset = 0.2, Color = Color3.fromRGB(255, 220, 230), Decay = Color3.fromRGB(200, 150, 190), Glare = 0, Haze = 0.6 },
	Color = { Saturation = 0.18, Contrast = 0.06, Brightness = 0.03, Tint = Color3.fromRGB(255, 244, 246) },
	Bloom = { Intensity = 0.35, Size = 24, Threshold = 2 },
	Clouds = 0.5,
	CloudColor = Color3.fromRGB(255, 236, 242),
	SunRays = 0.05,
	ShadowSoftness = 0.3,
	Wind = Vector3.new(4, 0, 1.5),
	TerrainColors = {
		Grass = Color3.fromRGB(110, 190, 90),
		LeafyGrass = Color3.fromRGB(240, 150, 190),
		Snow = Color3.fromRGB(245, 248, 255),
		Rock = Color3.fromRGB(120, 115, 130),
	},
}
-- A veces sale con otra luz o con mal tiempo (ver LightingVariants)
Map.LightingVariants = { Variants.Sunset(0.25), Variants.Fog(0.2) }

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local GRASS = RGB(120, 196, 96)
local STONE = RGB(196, 192, 205)
local STONE_DARK = RGB(150, 146, 160)
local PLASTER = RGB(246, 240, 232)
local WOOD = RGB(150, 98, 60)
local WOOD_DARK = RGB(100, 64, 42)
local TILE = RGB(60, 110, 120) -- tejas verde azulado
local RED = RGB(220, 50, 45)
local PINK = { RGB(255, 170, 205), RGB(250, 140, 185), RGB(255, 182, 212) } -- (saturación > 0,22: el estilo Cartoon no los vuelve lavanda)
local WATER = RGB(70, 170, 210)

local LENGTH, WIDTH = 230, 150

-- Cerezo: tronco inclinado y copa de bolas rosas
local function cherryTree(position, scale, seed)
	local rng = Random.new(seed or 1)
	scale = scale or 1
	local lean = CFrame.Angles(rad(rng:NextNumber(-8, 8)), 0, rad(rng:NextNumber(-8, 8)))
	Kit.cylinder("CherryTrunk", 8 * scale, 1.3 * scale, CFrame.new(position) * lean * CFrame.new(0, 4 * scale, 0), WOOD_DARK, Enum.Material.Wood)
	for i = 1, 4 do
		local offset = V(rng:NextNumber(-2.5, 2.5), 8.5 + rng:NextNumber(-0.5, 2), rng:NextNumber(-2.5, 2.5)) * scale
		local leaf = Kit.ball("Blossom", rng:NextNumber(5, 7.5) * scale, CFrame.new(position + offset), PINK[(i % 3) + 1], Enum.Material.SmoothPlastic, true)
		leaf.CastShadow = true
	end
end

-- Torii: dos pilares rojos, viga superior curvada y viga intermedia
local function torii(cf)
	for _, s in { -1, 1 } do
		Kit.cylinder("ToriiPillar", 13, 1.4, cf * CFrame.new(s * 6, 6.5, 0), RED, Enum.Material.SmoothPlastic)
		Kit.cylinder("ToriiFoot", 1, 1.9, cf * CFrame.new(s * 6, 0.5, 0), RGB(40, 36, 40), Enum.Material.SmoothPlastic, nil, true)
	end
	Kit.deco("ToriiKasagi", V(17, 1.2, 2), cf * CFrame.new(0, 13.6, 0), RGB(40, 36, 40), Enum.Material.SmoothPlastic)
	Kit.deco("ToriiShimaki", V(16, 1, 1.6), cf * CFrame.new(0, 12.6, 0), RED, Enum.Material.SmoothPlastic)
	for _, s in { -1, 1 } do
		Kit.deco("ToriiTip", V(2, 0.8, 2), cf * CFrame.new(s * 8.5, 14.3, 0) * CFrame.Angles(0, 0, rad(s * 12)), RGB(40, 36, 40), Enum.Material.SmoothPlastic)
	end
	Kit.deco("ToriiNuki", V(15, 0.8, 1), cf * CFrame.new(0, 10.4, 0), RED, Enum.Material.SmoothPlastic)
end

-- Linterna de piedra con luz cálida
local function lantern(cf)
	Kit.block("LanternBase", V(1.8, 1, 1.8), cf * CFrame.new(0, 0.5, 0), STONE_DARK, Enum.Material.SmoothPlastic)
	Kit.cylinder("LanternPost", 2.4, 0.8, cf * CFrame.new(0, 2.2, 0), STONE, Enum.Material.SmoothPlastic)
	local box = Kit.block("LanternBox", V(1.5, 1.3, 1.5), cf * CFrame.new(0, 4, 0), STONE, Enum.Material.SmoothPlastic)
	local glow = Kit.deco("LanternGlow", V(1.55, 0.7, 1.55), cf * CFrame.new(0, 4, 0), RGB(255, 210, 140), Enum.Material.Neon)
	Kit.light(glow, "PointLight", RGB(255, 200, 130), 12, 1)
	Kit.deco("LanternRoof", V(2.6, 0.5, 2.6), cf * CFrame.new(0, 4.9, 0) * CFrame.Angles(0, rad(45), 0), STONE_DARK, Enum.Material.SmoothPlastic)
	Kit.ball("LanternTop", 0.6, cf * CFrame.new(0, 5.4, 0), STONE_DARK, Enum.Material.SmoothPlastic, true)
	return box
end

-- Grupo de bambú (decorativo, se atraviesa)
local function bamboo(position, seed)
	local rng = Random.new(seed or 2)
	for i = 1, 5 do
		local h = rng:NextNumber(9, 15)
		local offset = V(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		local stalk = Kit.cylinder("Bamboo", h, 0.45, CFrame.new(position + offset + V(0, h / 2, 0)), RGB(120, 190, 80):Lerp(RGB(90, 160, 60), i / 5), Enum.Material.SmoothPlastic, nil, true)
		stalk.CastShadow = false
		Kit.deco("BambooLeaf", V(0.1, 0.5, 2.2), CFrame.new(position + offset + V(0, h - 0.5, 0)) * CFrame.Angles(rad(30), i, 0), RGB(100, 180, 70), Enum.Material.SmoothPlastic)
	end
end

-- Estanque con borde de piedras, nenúfares y peces
local function pond(position, radius, seed)
	local rng = Random.new(seed or 3)
	local water = Kit.cylinder("Pond", 0.3, radius * 2, CFrame.new(position + V(0, 0.08, 0)), WATER, Enum.Material.SmoothPlastic, nil, true)
	water.Reflectance = 0.25
	local rim = Kit.cylinder("PondRim", 0.2, radius * 2 + 2, CFrame.new(position + V(0, 0.05, 0)), STONE_DARK, Enum.Material.SmoothPlastic, nil, true)
	rim.CastShadow = false
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local s = rng:NextNumber(1.2, 2.2)
		Kit.block("PondStone", V(s, s * 0.6, s), CFrame.new(position + V(math.cos(a) * (radius + 0.8), s * 0.25, math.sin(a) * (radius + 0.8))) * CFrame.Angles(0, a, 0), STONE, Enum.Material.SmoothPlastic)
	end
	for _ = 1, 4 do
		local p = position + V(rng:NextNumber(-0.6, 0.6) * radius, 0.26, rng:NextNumber(-0.6, 0.6) * radius)
		Kit.cylinder("LilyPad", 0.06, rng:NextNumber(1.4, 2.2), CFrame.new(p), RGB(90, 180, 80), Enum.Material.SmoothPlastic, nil, true)
		if rng:NextNumber() < 0.5 then
			Kit.ball("LilyFlower", 0.5, CFrame.new(p + V(0, 0.2, 0)), RGB(255, 190, 220), Enum.Material.SmoothPlastic, true)
		end
	end
	for _ = 1, 3 do
		local p = position + V(rng:NextNumber(-0.5, 0.5) * radius, 0.25, rng:NextNumber(-0.5, 0.5) * radius)
		local fish = Kit.deco("Koi", V(0.5, 0.1, 1.4), CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng:NextNumber() < 0.5 and RGB(255, 130, 40) or RGB(255, 245, 240), Enum.Material.SmoothPlastic)
		fish.CastShadow = false
	end
end

-- Casa de té: paredes de madera y papel, tejado de tejas, dos puertas
local function teaHouse(cf)
	local w, d, h = 18, 14, 9
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.block("TeaPost", V(1.2, h, 1.2), cf * CFrame.new(x * w / 2, h / 2, z * d / 2), WOOD_DARK, Enum.Material.Wood)
		end
	end
	-- Paredes largas (con puerta en el centro de la que mira al centro del mapa)
	for _, z in { -1, 1 } do
		local face = cf * CFrame.new(0, 0, z * d / 2)
		for _, x in { -1, 1 } do
			Kit.block("TeaWall", V(w / 2 - 2.5, h, 0.6), face * CFrame.new(x * (w / 4 + 1.25), h / 2, 0), PLASTER, Enum.Material.SmoothPlastic)
			Kit.deco("TeaBeam", V(w / 2 - 2.5, 0.4, 0.7), face * CFrame.new(x * (w / 4 + 1.25), 3.5, 0), WOOD, Enum.Material.Wood)
		end
		Kit.block("TeaLintel", V(5, h - 6.5, 0.6), face * CFrame.new(0, 6.5 + (h - 6.5) / 2, 0), PLASTER, Enum.Material.SmoothPlastic)
	end
	for _, x in { -1, 1 } do
		Kit.block("TeaWall", V(0.6, h, d), cf * CFrame.new(x * w / 2, h / 2, 0), PLASTER, Enum.Material.SmoothPlastic)
		for _, z in { -3, 3 } do
			Kit.deco("PaperWindow", V(0.7, 2.6, 3), cf * CFrame.new(x * w / 2, 5, z), RGB(255, 250, 230), Enum.Material.SmoothPlastic)
		end
	end
	Kit.block("TeaFloor", V(w, 0.6, d), cf * CFrame.new(0, 0.3, 0), WOOD, Enum.Material.WoodPlanks)
	-- Tejado de dos aguas en voladizo
	for _, s in { -1, 1 } do
		Kit.deco("TeaRoof", V(w + 4, 0.8, d / 2 + 3), cf * CFrame.new(0, h + 1.6, s * (d / 4 + 0.6)) * CFrame.Angles(rad(s * 22), 0, 0), TILE, Enum.Material.SmoothPlastic)
	end
	Kit.deco("TeaRidge", V(w + 4.4, 0.8, 1.2), cf * CFrame.new(0, h + 3.2, 0), RGB(40, 70, 80), Enum.Material.SmoothPlastic)
	Kit.block("TeaCeiling", V(w, 0.6, d), cf * CFrame.new(0, h + 0.3, 0), WOOD, Enum.Material.Wood)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Breeze") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Kit.pickLighting(Map))
	folder:SetAttribute("Variant", Kit.Variant)
	folder:SetAttribute("Weather", Kit.Weather)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), GRASS, Enum.Material.SmoothPlastic)
	block("CenterGravel", V(60, 0.2, 60), CFrame.new(0, 0.1, 0), RGB(226, 222, 214), Enum.Material.SmoothPlastic)

	-- Muro de jardín blanco con tejadillo de tejas
	for _, z in { -1, 1 } do
		block("GardenWall", V(LENGTH + 4, 14, 2.5), CFrame.new(0, 7, z * (WIDTH / 2 + 1.25)), PLASTER, Enum.Material.SmoothPlastic)
		deco("GardenWallTile", V(LENGTH + 8, 1, 4.5), CFrame.new(0, 14.5, z * (WIDTH / 2 + 1.25)), TILE, Enum.Material.SmoothPlastic)
		deco("GardenWallBase", V(LENGTH + 4.4, 2.5, 2.9), CFrame.new(0, 1.25, z * (WIDTH / 2 + 1.25)), STONE_DARK, Enum.Material.SmoothPlastic)
	end
	for _, x in { -1, 1 } do
		block("GardenWall", V(2.5, 14, WIDTH + 4), CFrame.new(x * (LENGTH / 2 + 1.25), 7, 0), PLASTER, Enum.Material.SmoothPlastic)
		deco("GardenWallTile", V(4.5, 1, WIDTH + 8), CFrame.new(x * (LENGTH / 2 + 1.25), 14.5, 0), TILE, Enum.Material.SmoothPlastic)
	end

	-- Pagoda central: planta baja abierta con columnas rojas y núcleo; segunda planta a 10 de altura
	block("PagodaBase", V(26, 1.4, 26), CFrame.new(0, 0.7, 0), STONE, Enum.Material.SmoothPlastic)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("PagodaColumn", 9, 1.6, CFrame.new(x * 10, 5.9, z * 10), RED, Enum.Material.SmoothPlastic)
		end
	end
	block("PagodaCore", V(6, 9, 6), CFrame.new(0, 5.9, 0), PLASTER, Enum.Material.SmoothPlastic)
	block("PagodaDeck", V(24, 1, 24), CFrame.new(0, 10.9, 0), WOOD, Enum.Material.WoodPlanks)
	deco("PagodaRoof1", V(32, 0.8, 32), CFrame.new(0, 10.1, 0), TILE, Enum.Material.SmoothPlastic)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("PagodaColumn2", 8, 1.2, CFrame.new(x * 9, 15.4, z * 9), RED, Enum.Material.SmoothPlastic)
		end
	end
	block("PagodaRoof2", V(24, 1, 24), CFrame.new(0, 19.9, 0), TILE, Enum.Material.SmoothPlastic)
	deco("PagodaRoof2Top", V(14, 2, 14), CFrame.new(0, 21.4, 0), TILE, Enum.Material.SmoothPlastic)
	Kit.cylinder("PagodaSpire", 6, 0.6, CFrame.new(0, 25, 0), RGB(230, 180, 60), Enum.Material.SmoothPlastic, nil, true)
	for i = 1, 3 do
		Kit.cylinder("SpireRing", 0.3, 1.6 - i * 0.3, CFrame.new(0, 22.6 + i * 1.2, 0), RGB(230, 180, 60), Enum.Material.SmoothPlastic, nil, true)
	end
	Kit.symmetric(function(m)
		-- Barandilla de la segunda planta (con hueco para la escalera) y escalera
		Kit.railing((m * CFrame.new(-11.5, 11.4, 11.5)).Position, (m * CFrame.new(11.5, 11.4, 11.5)).Position, 2.6, RED)
		Kit.railing((m * CFrame.new(-11.5, 11.4, -11.5)).Position, (m * CFrame.new(-11.5, 11.4, 1.5)).Position, 2.6, RED)
		Kit.railing((m * CFrame.new(-11.5, 11.4, 7.5)).Position, (m * CFrame.new(-11.5, 11.4, 11.5)).Position, 2.6, RED)
		Kit.stairs((m * CFrame.new(-28, 0, 4.5)).Position, (m * CFrame.new(-12.5, 11.4, 4.5)).Position, 5, WOOD, Enum.Material.WoodPlanks)
		lantern(m * CFrame.new(-15, 0, -15))
	end)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(235, 70, 80) or RGB(70, 140, 255)
		-- Camino de piedra desde la base
		block("StonePath", V(46, 0.2, 8), m * CFrame.new(-66, 0.1, 0), STONE, Enum.Material.SmoothPlastic)
		for i = 0, 5 do
			deco("SteppingStone", V(3, 0.25, 3), m * CFrame.new(-40 + i * 4.5, 0.15, -20 - (i % 2) * 2) * CFrame.Angles(0, i, 0), STONE, Enum.Material.SmoothPlastic)
		end
		torii(m * CFrame.new(-80, 0, 0) * CFrame.Angles(0, rad(90), 0))

		-- Estanque con puente de madera
		pond(m * V(-45, 0, 38), 11, side == "A" and 5 or 6)
		block("Bridge", V(4, 0.6, 26), m * CFrame.new(-45, 0.9, 38), WOOD, Enum.Material.WoodPlanks)
		for _, x in { -2.2, 2.2 } do
			Kit.railing((m * CFrame.new(-45 + x, 1.2, 26)).Position, (m * CFrame.new(-45 + x, 1.2, 50)).Position, 1.8, RED)
		end

		-- Casa de té y coberturas de piedra con tejadillo
		teaHouse(m * CFrame.new(-62, 0, -42))
		for _, spec in { { V(-28, 0, -12), V(10, 3.5, 2) }, { V(-50, 0, 10), V(2, 3.5, 10) }, { V(-75, 0, 28), V(8, 3.5, 2) }, { V(-24, 0, 30), V(2, 3.5, 8) }, { V(-90, 0, -55), V(8, 3.5, 2) } } do
			local p, size = spec[1], spec[2]
			block("StoneWall", size, m * CFrame.new(p + V(0, size.Y / 2, 0)), STONE_DARK, Enum.Material.SmoothPlastic)
			deco("StoneWallTile", V(size.X + 0.8, 0.5, size.Z + 0.8), m * CFrame.new(p + V(0, size.Y + 0.25, 0)), TILE, Enum.Material.SmoothPlastic)
		end
		Kit.crate(m * CFrame.new(-36, 0, -40), 4)
		Kit.crate(m * CFrame.new(-36, 0, -35.5), 3)
		Kit.barrel(m * CFrame.new(-84, 0, 40), teamColor)

		-- Vegetación: cerezos, bambú, flores y linternas
		for i, p in { V(-100, 0, 58), V(-28, 0, 62), V(-70, 0, 62), V(-98, 0, -62), V(-20, 0, -62) } do
			cherryTree(m * p, 1 + (i % 2) * 0.2, i + (side == "A" and 0 or 10))
		end
		bamboo(m * V(-108, 0, 30), side == "A" and 8 or 9)
		bamboo(m * V(-30, 0, -50), side == "A" and 10 or 11)
		for i, p in { V(-56, 0, 22), V(-30, 0, 46), V(-80, 0, -30), V(-12, 0, -44) } do
			Kit.flowers(m * p, 3, i * 7 + (side == "A" and 0 or 50))
		end
		lantern(m * CFrame.new(-72, 0, 8))
		lantern(m * CFrame.new(-72, 0, -8))
		lantern(m * CFrame.new(-56, 0, 50))
	end)

	-- Pétalos de cerezo cayendo sobre todo el jardín
	local sky = deco("FallingPetals", V(LENGTH, 1, WIDTH), CFrame.new(0, 34, 0), RGB(255, 190, 220), Enum.Material.SmoothPlastic)
	sky.Transparency = 1
	sky.CastShadow = false
	local petals = Instance.new("ParticleEmitter")
	petals.Name = "Petals"
	petals.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	petals.Color = ColorSequence.new(RGB(255, 180, 210), RGB(255, 230, 240))
	petals.Size = NumberSequence.new(0.3)
	petals.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.9, 0.1), NumberSequenceKeypoint.new(1, 1) })
	petals.Lifetime = NumberRange.new(10, 13)
	petals.Speed = NumberRange.new(2.5, 3.5)
	petals.SpreadAngle = Vector2.new(25, 25)
	petals.RotSpeed = NumberRange.new(-120, 120)
	petals.Acceleration = V(0.4, 0, 0.1)
	petals.Rate = 28
	petals.WindAffectsDrag = true
	petals.EmissionDirection = Enum.NormalId.Bottom
	petals.Parent = sky

	-- Bases y banderas
	local spawnStyle = { Floor = STONE, Roof = TILE }
	Kit.spawnArea(teams[1], CFrame.new(-100, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-100, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-70, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-70, 0, 0))

	-- Límites y fondo: cerezos fuera del muro, colinas en flor y montaña nevada
	Kit.bounds(LENGTH, WIDTH, 50)
	-- Nombres de las zonas
	Kit.callout("PAGODA", CFrame.new(0, 10, 0), V(28, 24, 28))
	for _, m in { CFrame.new(), Kit.MIRROR } do
		Kit.callout("ESTANQUE", m * CFrame.new(-45, 6, 38), V(26, 16, 28))
		Kit.callout("CASA DE TÉ", m * CFrame.new(-62, 8, -42), V(24, 20, 20))
		Kit.callout("TORII", m * CFrame.new(-80, 8, 0), V(10, 20, 20))
	end
	for x = -140, 140, 28 do
		for _, z in { -1, 1 } do
			local position = V(x + z * 10, 0, z * (90 + (math.abs(x) % 13)))
			Kit.cylinder("CherryTrunk", 7, 1.4, CFrame.new(position + V(0, 3.5, 0)), WOOD_DARK, Enum.Material.Wood)
			local crown = Kit.ball("Blossom", 9, CFrame.new(position + V(0, 9, 0)), PINK[(math.abs(x) // 28) % 3 + 1], Enum.Material.SmoothPlastic, true)
			crown.CastShadow = false
		end
	end
	for x = -200, 200, 70 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -18, z * 150), 50, Enum.Material.Grass, { Inward = V(0, 0, -z), Top = Enum.Material.LeafyGrass, TopCount = 6, RockCount = 1 })
		end
	end
	Kit.naturalHill(V(260, -40, 120), 95, Enum.Material.Rock, { Inward = V(-1, 0, 0), Top = Enum.Material.Snow, TopCount = 6, Rock = Enum.Material.Slate })
	for _, sx in { -1, 1 } do
		for z = -100, 100, 70 do
			Kit.naturalHill(V(sx * 185, -18, z), 50, Enum.Material.Grass, { Inward = V(-sx, 0, 0), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end

	-- Modos
	for _, p in {
		V(-98, 0.5, 50), V(-80, 0.5, -20), V(-58, 0.5, 0), V(-38, 0.5, 18), V(-26, 0.5, -26),
		V(-62, 1.1, -42), V(-45, 1.7, 30), V(-12, 0.5, 52), V(-92, 0.5, -64), V(-4, 11.9, -6),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 11.4, 0), 7, 1)
	Kit.zone(V(-62, 0.6, -42), 6, 2)
	Kit.zone(V(62, 0.6, 42), 6, 3)
	Kit.zone(V(-45, 1.2, 38), 6, 4)
	Kit.zone(V(45, 1.2, -38), 6, 5)
	return folder
end

return Map
