-- PLAYA TIKI: isla tropical de estilo cartoon rodeada de mar. Torre de socorrista jugable en el centro,
-- chozas tiki con techo de paja, palmeras, sombrillas y toallas, tablas de surf, laguna turquesa,
-- antorchas tiki, sacos de arena y un muelle con barcas.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "TikiBeach",
	Name = "Playa Tiki",
	Icon = "🏝",
	Description = "Isla tropical · mediodía · torre y chozas",
}

Map.Lighting = {
	ClockTime = 14.4,
	Brightness = 3.3,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(125, 122, 130),
	OutdoorAmbient = Color3.fromRGB(175, 170, 175),
	Atmosphere = { Density = 0.22, Offset = 0.2, Color = Color3.fromRGB(200, 230, 255), Decay = Color3.fromRGB(110, 170, 220), Glare = 0, Haze = 0.5 },
	Color = { Saturation = 0.2, Contrast = 0.06, Brightness = 0.03, Tint = Color3.fromRGB(255, 250, 240) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.45,
	SunRays = 0.05,
	ShadowSoftness = 0.3,
	Wind = Vector3.new(5, 0, 2),
	Water = { Color = Color3.fromRGB(30, 170, 190), Reflectance = 0.7, Transparency = 0.5, WaveSize = 0.18, WaveSpeed = 9 },
	TerrainColors = {
		Sand = Color3.fromRGB(240, 215, 150),
		Rock = Color3.fromRGB(150, 135, 120),
		Grass = Color3.fromRGB(110, 200, 90),
		LeafyGrass = Color3.fromRGB(70, 170, 80),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local SAND = RGB(244, 218, 150)
local WOOD = RGB(170, 115, 65)
local WOOD_DARK = RGB(120, 78, 45)
local THATCH = RGB(222, 182, 98)
local LAGOON = RGB(60, 210, 220)
local STRIPES = { RGB(255, 80, 90), RGB(60, 150, 255), RGB(255, 200, 50), RGB(80, 210, 120) }

local LENGTH, WIDTH = 230, 150

-- Techo de paja a cuatro aguas (cuatro faldones inclinados y una punta)
local function thatchRoof(cf, w, d)
	for _, s in { -1, 1 } do
		Kit.deco("Thatch", V(w + 3, 0.8, d / 2 + 2.5), cf * CFrame.new(0, 0, s * (d / 4 + 0.4)) * CFrame.Angles(rad(s * 28), 0, 0), THATCH, Enum.Material.SmoothPlastic)
		Kit.deco("ThatchSide", V(w / 2 + 1, 0.8, d + 1), cf * CFrame.new(s * (w / 4 + 0.6), -0.4, 0) * CFrame.Angles(0, 0, rad(-s * 28)), THATCH:Lerp(RGB(180, 140, 70), 0.3), Enum.Material.SmoothPlastic)
	end
	Kit.deco("ThatchTop", V(2.4, 1.6, d * 0.4), cf * CFrame.new(0, d / 4 + 0.6, 0), THATCH:Lerp(RGB(150, 110, 50), 0.3), Enum.Material.SmoothPlastic)
end

-- Antorcha tiki con fuego
local function tikiTorch(cf)
	Kit.cylinder("TikiPole", 6, 0.5, cf * CFrame.new(0, 3, 0), WOOD_DARK, Enum.Material.Wood)
	local cup = Kit.cylinder("TikiCup", 1, 1, cf * CFrame.new(0, 6.3, 0), RGB(90, 60, 40), Enum.Material.Wood, nil, true)
	local fire = Instance.new("Fire")
	fire.Size = 2.5
	fire.Heat = 5
	fire.Color = RGB(255, 140, 40)
	fire.SecondaryColor = RGB(255, 220, 80)
	fire.Parent = cup
	Kit.light(cup, "PointLight", RGB(255, 170, 80), 14, 1.2)
end

-- Sombrilla de rayas con toalla
local function umbrella(cf, colorA, colorB)
	Kit.cylinder("UmbrellaPole", 7, 0.25, cf * CFrame.new(0, 3.5, 0), RGB(240, 240, 240), Enum.Material.SmoothPlastic, nil, true)
	for i = 0, 7 do
		Kit.deco("UmbrellaCloth", V(2.6, 0.2, 4.4), cf * CFrame.Angles(0, i * math.pi / 4, 0) * CFrame.new(0, 6.5, -2) * CFrame.Angles(rad(-18), 0, 0), i % 2 == 0 and colorA or colorB, Enum.Material.SmoothPlastic)
	end
	Kit.deco("Towel", V(3, 0.08, 6), cf * CFrame.new(2.5, 0.05, 1) * CFrame.Angles(0, rad(15), 0), colorB, Enum.Material.SmoothPlastic)
	Kit.deco("TowelStripe", V(3.02, 0.09, 0.8), cf * CFrame.new(2.5, 0.05, 1) * CFrame.Angles(0, rad(15), 0), colorA, Enum.Material.SmoothPlastic)
end

-- Tabla de surf clavada en la arena
local function surfboard(cf, color)
	Kit.deco("Surfboard", V(1.8, 6.5, 0.3), cf * CFrame.new(0, 3, 0) * CFrame.Angles(rad(8), 0, 0), color, Enum.Material.SmoothPlastic)
	Kit.deco("SurfStripe", V(0.4, 6.4, 0.32), cf * CFrame.new(0, 3, 0) * CFrame.Angles(rad(8), 0, 0), RGB(255, 255, 255), Enum.Material.SmoothPlastic)
end

-- Choza tiki: suelo elevado de madera, paredes de bambú con puerta y ventana, techo de paja
local function hut(cf)
	local w, d, h = 16, 12, 7
	Kit.block("HutFloor", V(w + 2, 1, d + 2), cf * CFrame.new(0, 0.5, 0), WOOD, Enum.Material.WoodPlanks)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("HutPost", h + 1, 0.9, cf * CFrame.new(x * w / 2, 1 + h / 2, z * d / 2), WOOD_DARK, Enum.Material.Wood)
		end
	end
	-- Pared trasera completa, laterales con ventana y frontal con puerta (mira a +X)
	Kit.block("HutWall", V(0.6, h, d), cf * CFrame.new(-w / 2, 1 + h / 2, 0), RGB(200, 170, 100), Enum.Material.SmoothPlastic)
	for _, z in { -1, 1 } do
		local face = cf * CFrame.new(0, 0, z * d / 2)
		Kit.block("HutWallLow", V(w, 3, 0.6), face * CFrame.new(0, 2.5, 0), RGB(200, 170, 100), Enum.Material.SmoothPlastic)
		Kit.block("HutWallHigh", V(w, 1.5, 0.6), face * CFrame.new(0, 1 + h - 0.75, 0), RGB(200, 170, 100), Enum.Material.SmoothPlastic)
		for _, x in { -1, 1 } do
			Kit.block("HutWallSide", V(4, h - 4.5, 0.6), face * CFrame.new(x * (w / 2 - 2), 4 + (h - 4.5) / 2, 0), RGB(200, 170, 100), Enum.Material.SmoothPlastic)
		end
	end
	for _, z in { -1, 1 } do
		Kit.block("HutDoorSide", V(0.6, h, (d - 5) / 2), cf * CFrame.new(w / 2, 1 + h / 2, z * (2.5 + (d - 5) / 4)), RGB(200, 170, 100), Enum.Material.SmoothPlastic)
	end
	Kit.block("HutLintel", V(0.6, 1.5, 5), cf * CFrame.new(w / 2, 1 + h - 0.75, 0), RGB(200, 170, 100), Enum.Material.SmoothPlastic)
	Kit.block("HutCeiling", V(w, 0.5, d), cf * CFrame.new(0, 1 + h + 0.25, 0), WOOD, Enum.Material.Wood)
	thatchRoof(cf * CFrame.new(0, 1 + h + 1.6, 0), w, d)
	Kit.block("HutStep", V(3, 0.5, 5), cf * CFrame.new(w / 2 + 2, 0.25, 0), WOOD, Enum.Material.WoodPlanks)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Coast") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Isla de arena y mar alrededor
	block("Sand", V(LENGTH + 20, 2, WIDTH + 20), CFrame.new(0, -1, 0), SAND, Enum.Material.Sand)
	workspace.Terrain:FillBlock(CFrame.new(0, -6, 0), V(900, 10, 700), Enum.Material.Water)
	workspace.Terrain:FillBlock(CFrame.new(0, -12, 0), V(900, 2, 700), Enum.Material.Sand)
	-- Orilla mojada alrededor de la isla
	for _, z in { -1, 1 } do
		deco("WetSand", V(LENGTH + 24, 0.1, 6), CFrame.new(0, 0.02, z * (WIDTH / 2 + 8)), RGB(215, 185, 120), Enum.Material.SmoothPlastic)
	end

	-- Laguna central y torre de socorrista
	local lagoon = Kit.cylinder("Lagoon", 0.3, 34, CFrame.new(0, 0.12, 0), LAGOON, Enum.Material.SmoothPlastic, nil, true)
	lagoon.Reflectance = 0.25
	Kit.cylinder("LagoonRim", 0.2, 37, CFrame.new(0, 0.08, 0), RGB(230, 200, 140), Enum.Material.SmoothPlastic, nil, true)
	local deckY = 9
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("TowerStilt", deckY, 1.4, CFrame.new(x * 8, deckY / 2, z * 8), WOOD_DARK, Enum.Material.Wood)
		end
	end
	block("TowerDeck", V(20, 1, 20), CFrame.new(0, deckY + 0.5, 0), WOOD, Enum.Material.WoodPlanks)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("TowerRoofPost", 7, 0.7, CFrame.new(x * 8.5, deckY + 4.5, z * 8.5), WOOD_DARK, Enum.Material.Wood, nil, true)
		end
	end
	block("TowerRoof", V(22, 0.6, 22), CFrame.new(0, deckY + 8.2, 0), WOOD, Enum.Material.Wood)
	thatchRoof(CFrame.new(0, deckY + 9.2, 0), 20, 20)
	local flag = deco("LifeguardFlag", V(0.2, 3, 4), CFrame.new(0, deckY + 15, 2), RGB(255, 60, 60), Enum.Material.Fabric)
	flag.CastShadow = false
	Kit.cylinder("FlagPole", 6, 0.25, CFrame.new(0, deckY + 13.5, 0), RGB(240, 240, 240), Enum.Material.SmoothPlastic, nil, true)
	Kit.symmetric(function(m)
		Kit.railing((m * CFrame.new(-10, deckY + 1, 10)).Position, (m * CFrame.new(10, deckY + 1, 10)).Position, 2.4, RGB(255, 255, 255))
		Kit.railing((m * CFrame.new(-10, deckY + 1, -10)).Position, (m * CFrame.new(-10, deckY + 1, 1)).Position, 2.4, RGB(255, 255, 255))
		Kit.railing((m * CFrame.new(-10, deckY + 1, 7)).Position, (m * CFrame.new(-10, deckY + 1, 10)).Position, 2.4, RGB(255, 255, 255))
		Kit.stairs((m * CFrame.new(-25, 0, 4)).Position, (m * CFrame.new(-10.5, deckY + 1, 4)).Position, 5, WOOD, Enum.Material.WoodPlanks)
	end)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(255, 80, 90) or RGB(60, 150, 255)
		-- Pasarela de madera desde la base
		block("Boardwalk", V(44, 0.4, 7), m * CFrame.new(-64, 0.2, 0), WOOD, Enum.Material.WoodPlanks)
		for i = 0, 9 do
			deco("BoardGap", V(0.15, 0.42, 7.05), m * CFrame.new(-84 + i * 4.4, 0.2, 0), WOOD_DARK, Enum.Material.Wood)
		end

		hut(m * CFrame.new(-55, 0, 42))
		hut(m * CFrame.new(-55, 0, -42) * CFrame.Angles(0, 0, 0))

		-- Sacos de arena (cobertura baja) y cajas
		for _, spec in { { V(-30, 0, -10), 0 }, { V(-45, 0, 12), 90 }, { V(-80, 0, 26), 0 }, { V(-26, 0, 30), 90 }, { V(-88, 0, -50), 0 } } do
			local cf = m * CFrame.new(spec[1]) * CFrame.Angles(0, rad(spec[2]), 0)
			for row = 0, 1 do
				for i = -1, 1 do
					block("Sandbag", V(3.2, 1.6, 2), cf * CFrame.new(i * 3 + row * 1.5 - 0.75, 0.8 + row * 1.5, 0), RGB(200, 180, 130), Enum.Material.SmoothPlastic)
				end
			end
		end
		Kit.crate(m * CFrame.new(-38, 0, -30), 4)
		Kit.crate(m * CFrame.new(-34, 0, -30), 3)
		Kit.barrel(m * CFrame.new(-82, 0, 44), teamColor)

		-- Playa: palmeras, sombrillas, tablas de surf, pelotas y antorchas
		for i, p in { V(-100, 0, 58), V(-70, 0, 64), V(-20, 0, 62), V(-100, 0, -58), V(-25, 0, -64), V(-62, 0, 20) } do
			Kit.palm(m * CFrame.new(p) * CFrame.Angles(0, i * 1.3, 0), 13 + (i % 3) * 2)
		end
		umbrella(m * CFrame.new(-34, 0, 52), STRIPES[1], STRIPES[3])
		umbrella(m * CFrame.new(-82, 0, -64), STRIPES[2], STRIPES[4])
		surfboard(m * CFrame.new(-44, 0, 60) * CFrame.Angles(0, rad(10), 0), STRIPES[2])
		surfboard(m * CFrame.new(-47, 0, 60) * CFrame.Angles(0, rad(-12), 0), STRIPES[1])
		Kit.ball("BeachBall", 2, m * CFrame.new(-30, 1, 44), STRIPES[(side == "A" and 3 or 4)], Enum.Material.SmoothPlastic, true)
		for _, p in { V(-74, 0, 7), V(-74, 0, -7), V(-14, 0, 22), V(-40, 0, 26) } do
			tikiTorch(m * CFrame.new(p))
		end
		Kit.rockCluster(m * V(-112, 0, -30), 4, Enum.Material.Rock)
		Kit.rockCluster(m * V(-10, 0, 70), 4, Enum.Material.Rock)

		-- Muelle con barca en el mar
		block("Pier", V(8, 0.6, 26), m * CFrame.new(-60, 0.3, -WIDTH / 2 - 14), WOOD, Enum.Material.WoodPlanks)
		for _, z in { -24, -16, -8 } do
			for _, x in { -3.5, 3.5 } do
				Kit.cylinder("PierPost", 6, 0.7, m * CFrame.new(-60 + x, -2.5, -WIDTH / 2 + z), WOOD_DARK, Enum.Material.Wood, nil, true)
			end
		end
		Kit.boat(m * CFrame.new(-48, -1.2, -WIDTH / 2 - 22) * CFrame.Angles(0, rad(15), 0))
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(250, 230, 175), Roof = THATCH }
	Kit.spawnArea(teams[1], CFrame.new(-100, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-100, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-72, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-72, 0, 0))

	-- Límites invisibles (la isla acaba en el agua) e islas lejanas
	Kit.bounds(LENGTH, WIDTH, 50)
	for i, spec in { { V(-260, 0, -220), 40 }, { V(240, 0, 240), 55 }, { V(330, 0, -60), 35 }, { V(-320, 0, 160), 45 } } do
		Kit.naturalHill(spec[1] + V(0, -spec[2] * 0.55, 0), spec[2], Enum.Material.Sand, { Top = Enum.Material.LeafyGrass, TopCount = 5, RockCount = 2, Seed = i * 7 })
	end

	-- Modos
	for _, p in {
		V(-98, 0.5, 50), V(-80, 0.5, -20), V(-58, 0.5, 6), V(-38, 0.5, 18), V(-26, 0.5, -24),
		V(-55, 1.5, 42), V(-55, 1.5, -42), V(-12, 0.5, 50), V(-94, 0.5, -64), V(-3, deckY + 1.5, -5),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, deckY + 1, 0), 7, 1)
	Kit.zone(V(-55, 1, 42), 6, 2)
	Kit.zone(V(55, 1, -42), 6, 3)
	Kit.zone(V(-30, 0, 0), 8, 4)
	Kit.zone(V(30, 0, 0), 8, 5)
	return folder
end

return Map
