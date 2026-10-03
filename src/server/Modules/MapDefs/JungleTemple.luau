-- JUNGLE TEMPLE: ruinas en la selva. Pirámide escalonada en el centro con un santuario y una gema
-- que gira, rodeada por un foso de agua; salones de columnas en ruinas, plataformas de piedra con
-- enredaderas, cabezas de piedra gigantes, antorchas, árboles enormes y cascadas al fondo.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "JungleTemple",
	Name = "Jungle Temple",
	Description = "Selva · mediodía · pirámide y cascadas",
}

Map.Lighting = {
	ClockTime = 13.2,
	Brightness = 2.8,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(95, 110, 80),
	OutdoorAmbient = Color3.fromRGB(140, 160, 120),
	Atmosphere = { Density = 0.36, Offset = 0.2, Color = Color3.fromRGB(195, 220, 185), Decay = Color3.fromRGB(110, 140, 100), Glare = 0.3, Haze = 2 },
	Color = { Saturation = 0.3, Contrast = 0.12, Brightness = 0.02, Tint = Color3.fromRGB(255, 252, 235) },
	Bloom = { Intensity = 0.8, Size = 24, Threshold = 1.6 },
	Clouds = 0.6,
	SunRays = 0.18,
	Water = { Color = Color3.fromRGB(40, 115, 95), Reflectance = 0.6, Transparency = 0.55, WaveSize = 0.05, WaveSpeed = 6 },
	TerrainColors = {
		Grass = Color3.fromRGB(88, 140, 58),
		LeafyGrass = Color3.fromRGB(70, 125, 50),
		Mud = Color3.fromRGB(105, 80, 52),
		Ground = Color3.fromRGB(110, 92, 62),
		Rock = Color3.fromRGB(120, 116, 100),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local STONE = RGB(150, 145, 125)
local STONE_DARK = RGB(110, 108, 92)
local MOSS = RGB(95, 130, 70)
local JADE = RGB(40, 255, 140)
local GRASS = RGB(85, 135, 60)

-- Árbol de la selva: tronco alto y copa de varias bolas de hojas
local function jungleTree(position, scale)
	scale = scale or 1
	Kit.cylinder("JungleTrunk", 16 * scale, 2.2 * scale, CFrame.new(position + V(0, 8 * scale, 0)), RGB(100, 75, 50), Enum.Material.Wood)
	for i, spec in { { V(0, 17, 0), 12 }, { V(4, 15.5, 2), 9 }, { V(-4, 16, -2.5), 9.5 }, { V(1, 20, -1), 8 } } do
		local leaf = Kit.ball("Canopy" .. i, spec[2] * scale, CFrame.new(position + spec[1] * scale), i % 2 == 0 and RGB(45, 120, 50) or RGB(60, 145, 55), Enum.Material.Grass, true)
		leaf.CastShadow = true
	end
	for i = 0, 3 do
		local angle = i * math.pi / 2 + 0.4
		Kit.deco("Root", V(1, 1.4, 4.5) * scale, CFrame.new(position + V(math.cos(angle) * 2.2, 0.5, math.sin(angle) * 2.2) * scale) * CFrame.Angles(0, -angle + math.pi / 2, rad(-15)), RGB(90, 68, 45), Enum.Material.Wood)
	end
end

-- Helecho (decoración del suelo)
local function fern(position)
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		Kit.deco("Fern", V(0.8, 0.15, 3.5), CFrame.new(position) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.6, -1.5) * CFrame.Angles(rad(25), 0, 0), RGB(70, 155, 60), Enum.Material.Grass)
	end
end

-- Antorcha con fuego de verdad
local function torch(cf)
	Kit.cylinder("TorchPost", 5, 0.7, cf * CFrame.new(0, 2.5, 0), RGB(95, 70, 45), Enum.Material.Wood)
	local bowl = Kit.cylinder("TorchBowl", 0.8, 1.6, cf * CFrame.new(0, 5.2, 0), STONE_DARK, Enum.Material.Slate, nil, true)
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 6
	fire.Color = RGB(255, 140, 40)
	fire.SecondaryColor = RGB(255, 220, 80)
	fire.Parent = bowl
	Kit.light(bowl, "PointLight", RGB(255, 160, 70), 18, 1.6)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo de terreno con hierba 3D animada y caminos de barro (sin hierba)
	Kit.terrainFloor(Enum.Material.Grass, 340, 240)
	for _, z in { -60, 60 } do
		Kit.terrainPatch(CFrame.new(0, 0, z), V(260, 4, 8), Enum.Material.Mud)
	end
	Kit.terrainPatch(CFrame.new(0, 0, 0), V(260, 4, 8), Enum.Material.Mud)
	-- Tierra bajo las bases, salones y plataformas (para que la hierba no atraviese los suelos)
	for _, cf in { CFrame.new(-145, 0, 0), Kit.MIRROR * CFrame.new(-145, 0, 0) } do
		Kit.terrainPatch(cf, V(36, 4, 76), Enum.Material.Ground)
	end
	for _, cf in { CFrame.new(-112, 0, 10), Kit.MIRROR * CFrame.new(-112, 0, 10) } do
		Kit.terrainPatch(cf, V(20, 4, 20), Enum.Material.Ground)
	end

	-- Foso de agua alrededor de la pirámide (poco profundo) y puentes de piedra
	workspace.Terrain:FillCylinder(CFrame.new(0, 0.6, 0), 1.2, 31, Enum.Material.Water)
	for _, angle in { 0, 90 } do
		block("MoatBridge", V(66, 0.8, 7), CFrame.new(0, 0.4, 0) * CFrame.Angles(0, rad(angle), 0), STONE, Enum.Material.Cobblestone)
	end

	-- Pirámide escalonada con escaleras en dos lados
	for i, size in { 30, 24, 18, 12 } do
		local y = 1.5 + (i - 1) * 3
		block("PyramidTier", V(size, 3, size), CFrame.new(0, y, 0), i % 2 == 0 and STONE or STONE_DARK, Enum.Material.Slate)
		deco("PyramidMoss", V(size + 0.1, 0.4, size + 0.1), CFrame.new(0, y + 1.3, 0), MOSS, Enum.Material.LeafyGrass)
	end
	-- Santuario en la cima con la gema
	for _, x in { -4.5, 4.5 } do
		for _, z in { -4.5, 4.5 } do
			block("ShrineColumn", V(1.6, 7, 1.6), CFrame.new(x, 15.5, z), STONE, Enum.Material.Slate)
		end
	end
	block("ShrineRoof", V(12, 1.2, 12), CFrame.new(0, 19.6, 0), STONE_DARK, Enum.Material.Slate)
	block("ShrineRoofTop", V(7, 1.2, 7), CFrame.new(0, 20.8, 0), STONE, Enum.Material.Slate)
	local gem = deco("JadeGem", V(1.8, 2.6, 1.8), CFrame.new(0, 16, 0) * CFrame.Angles(0, 0, rad(45)), JADE, Enum.Material.Neon)
	gem:SetAttribute("Spin", 60)
	gem:SetAttribute("Bob", 0.4)
	Kit.light(gem, "PointLight", JADE, 22, 2.5)
	block("GemAltar", V(3, 1.6, 3), CFrame.new(0, 12.8, 0), STONE_DARK, Enum.Material.Slate)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(255, 60, 80) or RGB(60, 140, 255)

		-- Escalinata de la pirámide (desde el puente)
		Kit.stairs(m * V(-27, 0.8, 0), m * V(-6, 12, 0), 6, STONE, Enum.Material.Cobblestone)

		-- Salón de columnas en ruinas
		local hall = m * CFrame.new(-78, 0, -55)
		Kit.terrainPatch(hall, V(32, 4, 24), Enum.Material.Ground)
		block("HallFloor", V(28, 1, 20), hall * CFrame.new(0, 0.5, 0), STONE, Enum.Material.Cobblestone)
		for i, x in { -12, -4, 4, 12 } do
			for _, z in { -8, 8 } do
				local broken = (i + (z > 0 and 1 or 0)) % 3 == 0
				local h = broken and 6 or 12
				Kit.cylinder("HallColumn", h, 2.4, hall * CFrame.new(x, 1 + h / 2, z), STONE, Enum.Material.Slate)
				deco("ColumnMoss", V(2.6, 1, 2.6), hall * CFrame.new(x, 1.5, z), MOSS, Enum.Material.LeafyGrass)
			end
		end
		block("HallRoof", V(16, 1.6, 20), hall * CFrame.new(-6, 13.8, 0), STONE_DARK, Enum.Material.Slate)
		Kit.vines(hall * CFrame.new(-6, 13, -10.2), 14, 6)
		Kit.vines(hall * CFrame.new(-6, 13, 10.2), 14, 6)
		block("Rubble", V(5, 2.5, 4), hall * CFrame.new(8, 2.25, 2) * CFrame.Angles(0, rad(20), rad(8)), STONE_DARK, Enum.Material.Slate)
		block("Rubble", V(3, 2, 3), hall * CFrame.new(5, 2, -3) * CFrame.Angles(0, rad(-35), 0), STONE, Enum.Material.Slate)
		torch(hall * CFrame.new(16, 0, -11))
		torch(hall * CFrame.new(16, 0, 11))

		-- Plataforma de piedra elevada (puesto de tirador) con parapetos y enredaderas
		local plat = m * CFrame.new(-70, 0, 50)
		block("Platform", V(20, 10, 16), plat * CFrame.new(0, 5, 0), STONE_DARK, Enum.Material.Slate)
		deco("PlatformMoss", V(20.2, 0.4, 16.2), plat * CFrame.new(0, 9.9, 0), MOSS, Enum.Material.LeafyGrass)
		block("Parapet", V(20, 1.4, 1), plat * CFrame.new(0, 10.7, -7.5), STONE, Enum.Material.Slate)
		block("Parapet", V(20, 1.4, 1), plat * CFrame.new(0, 10.7, 7.5), STONE, Enum.Material.Slate)
		block("Parapet", V(1, 1.4, 14), plat * CFrame.new(-9.5, 10.7, 0), STONE, Enum.Material.Slate)
		block("Parapet", V(1, 1.4, 4), plat * CFrame.new(9.5, 10.7, -5), STONE, Enum.Material.Slate)
		Kit.stairs(m * V(-48, 0, 53), m * V(-60.2, 10, 53), 5, STONE, Enum.Material.Cobblestone)
		Kit.vines(plat * CFrame.new(0, 10, -8.2), 18, 7)
		Kit.vines(plat * CFrame.new(0, 10, 8.2) * CFrame.Angles(0, math.pi, 0), 18, 7)
		local glyph = deco("Glyph", V(0.3, 3, 3), plat * CFrame.new(10.05, 5, -3), teamColor, Enum.Material.Neon)
		glyph.Transparency = 0.2
		torch(plat * CFrame.new(12, 0, -10))

		-- Cabeza de piedra gigante mirando al centro (cobertura)
		local head = m * CFrame.new(-38, 0, -12)
		block("StoneHead", V(8, 9, 8), head * CFrame.new(0, 4.5, 0), RGB(125, 130, 112), Enum.Material.Slate)
		block("StoneHelmet", V(8.6, 2, 8.6), head * CFrame.new(0, 9.5, 0), STONE_DARK, Enum.Material.Slate)
		for _, z in { -1.8, 1.8 } do
			deco("StoneEye", V(0.3, 1, 1.6), head * CFrame.new(4.05, 6, z), JADE, Enum.Material.Neon)
		end
		deco("StoneNose", V(1, 2, 1.4), head * CFrame.new(4.4, 4.6, 0), RGB(115, 120, 102), Enum.Material.Slate)
		deco("StoneMouth", V(0.3, 0.8, 3.6), head * CFrame.new(4.05, 2.6, 0), RGB(60, 60, 52), Enum.Material.Slate)

		-- Muros en ruinas como cobertura
		block("RuinWall", V(2, 5, 12), m * CFrame.new(-28, 2.5, 32), STONE, Enum.Material.Cobblestone)
		block("RuinWall", V(12, 4, 2), m * CFrame.new(-55, 2, 15), STONE, Enum.Material.Cobblestone)
		block("RuinWall", V(2, 6, 14), m * CFrame.new(-100, 3, -22), STONE, Enum.Material.Cobblestone)
		block("RuinWall", V(10, 3, 2), m * CFrame.new(-22, 1.5, -40), STONE_DARK, Enum.Material.Cobblestone)
		for _, p in { V(-28, 5.2, 28), V(-100, 6.2, -18) } do
			deco("WallMoss", V(2.2, 0.5, 5), m * CFrame.new(p), MOSS, Enum.Material.LeafyGrass)
		end
		torch(m * CFrame.new(-45, 0, -30))
		torch(m * CFrame.new(-95, 0, 25))

		-- Árboles y vegetación
		for i, p in { V(-120, 0, 72), V(-98, 0, 96), V(-58, 0, 94), V(-30, 0, -84), V(-112, 0, -82), V(-135, 0, -58), V(-24, 0, 88) } do
			jungleTree(m * p, 0.9 + (i % 3) * 0.15)
		end
		for _, p in { V(-35, 0, 45), V(-88, 0, 10), V(-60, 0, -10), V(-15, 0, -70), V(-120, 0, 30) } do
			fern(m * p)
		end
		Kit.palm(m * CFrame.new(-50, 0, 80), 15)
		Kit.palm(m * CFrame.new(-128, 0, -95), 13)

		-- Cascada al fondo con poza
		local fall = m * CFrame.new(-20, 0, -108)
		local water = deco("Waterfall", V(16, 46, 1), fall * CFrame.new(0, 23, 0), RGB(150, 210, 240), Enum.Material.Glass)
		water.Transparency = 0.35
		local foam = deco("WaterfallFoam", V(18, 1.5, 6), fall * CFrame.new(0, 0.8, 3), RGB(240, 250, 255), Enum.Material.SmoothPlastic)
		foam.Transparency = 0.4
		local mist = Instance.new("ParticleEmitter")
		mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
		mist.Color = ColorSequence.new(Color3.new(1, 1, 1))
		mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8) })
		mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		mist.Lifetime = NumberRange.new(2, 3)
		mist.Speed = NumberRange.new(2, 5)
		mist.SpreadAngle = Vector2.new(50, 50)
		mist.Rate = 12
		mist.EmissionDirection = Enum.NormalId.Top
		mist.Parent = foam
		workspace.Terrain:FillBlock(fall * CFrame.new(0, 0.5, 7), V(26, 1, 10), Enum.Material.Water)
		-- Acantilado de roca con hierba por encima (de donde cae el agua)
		for i, x in { -30, -16, 0, 16, 30 } do
			local h = 18 + (i % 2) * 6
			workspace.Terrain:FillBall((fall * CFrame.new(x, h, -22)).Position, 20, Enum.Material.Rock)
			workspace.Terrain:FillBall((fall * CFrame.new(x * 0.9, h + 16, -26)).Position, 15, Enum.Material.Grass)
		end
	end)

	-- Hojas que caen lentamente sobre el mapa
	local sky = deco("FallingLeaves", V(320, 1, 220), CFrame.new(0, 45, 0), GRASS, Enum.Material.SmoothPlastic)
	sky.Transparency = 1
	local leaves = Instance.new("ParticleEmitter")
	leaves.Name = "Leaves"
	leaves.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	leaves.Color = ColorSequence.new(RGB(150, 210, 90), RGB(230, 210, 90))
	leaves.Size = NumberSequence.new(0.35)
	leaves.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.9, 0.2), NumberSequenceKeypoint.new(1, 1) })
	leaves.Lifetime = NumberRange.new(12, 15)
	leaves.Speed = NumberRange.new(2.5, 4)
	leaves.SpreadAngle = Vector2.new(25, 25)
	leaves.RotSpeed = NumberRange.new(-90, 90)
	leaves.Acceleration = V(0.8, 0, 0.4)
	leaves.Rate = 20
	leaves.EmissionDirection = Enum.NormalId.Bottom
	leaves.Parent = sky

	-- Spawns y banderas
	local spawnStyle = { Floor = RGB(160, 150, 125), FloorMaterial = Enum.Material.Cobblestone, Roof = RGB(120, 95, 65), RoofMaterial = Enum.Material.WoodPlanks }
	Kit.spawnArea(teams[1], CFrame.new(-145, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-145, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-112, 0, 10))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-112, 0, 10))

	-- Límites, colinas y selva de fondo
	Kit.bounds(320, 220, 60)
	for x = -240, 240, 60 do
		for _, z in { -1, 1 } do
			workspace.Terrain:FillBall(V(x - z * 20, -22, z * (170 + (math.abs(x) % 40))), 55 + (math.abs(x) % 3) * 10, Enum.Material.Grass)
		end
	end
	for z = -150, 150, 60 do
		for _, sx in { -1, 1 } do
			workspace.Terrain:FillBall(V(sx * 225, -20, z), 58, Enum.Material.Grass)
		end
	end
	for x = -150, 150, 24 do
		for _, z in { -1, 1 } do
			if math.abs(x - z * 20) > 14 then -- deja ver las cascadas
				jungleTree(V(x, 0, z * (124 + (math.abs(x) % 11))), 1.2)
			end
		end
	end

	-- Modos
	for _, p in {
		V(-130, 0.5, 45), V(-100, 0.5, -5), V(-70, 10.5, 50), V(-78, 1.5, -55), V(-45, 0.5, 8),
		V(-20, 0.5, -55), V(-110, 0.5, 80), V(-60, 0.5, -25), V(-12, 0.5, 55), V(-125, 0.5, -90),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 12, 0), 6, 1)
	Kit.zone(V(-78, 1, -55), 9, 2)
	Kit.zone(V(78, 1, 55), 9, 3)
	Kit.zone(V(-45, 0, 32), 9, 4)
	Kit.zone(V(45, 0, -32), 9, 5)
	return folder
end

return Map
