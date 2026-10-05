-- CASTILLO DEL REY: patio medieval de mañana. En el centro, la torre del homenaje con un túnel que
-- la atraviesa de lado a lado y azotea almenada (escalera por fuera en cada lado). A cada lado, una
-- muralla con almenas y tres pasos, con rampa para subir al adarve; torreones redondos, pozo,
-- puestos de mercado con toldos, carros de heno, barriles y árboles. Colinas y pinos de fondo.
-- Simétrico.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)
local Variants = require(script.Parent.Parent.LightingVariants)

local Map = {
	Id = "Castle",
	Name = "Castillo del Rey",
	Icon = "🏰",
	Description = "Mañana · torre central con túnel · murallas con almenas",
}

Map.Lighting = {
	ClockTime = 10.5,
	Brightness = 3,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(120, 120, 130),
	OutdoorAmbient = Color3.fromRGB(170, 170, 180),
	Atmosphere = { Density = 0.25, Offset = 0.2, Color = Color3.fromRGB(205, 225, 255), Decay = Color3.fromRGB(120, 160, 210), Glare = 0, Haze = 0.6 },
	Color = { Saturation = 0.18, Contrast = 0.06, Brightness = 0.02, Tint = Color3.fromRGB(255, 252, 245) },
	Bloom = { Intensity = 0.3, Size = 22, Threshold = 2 },
	Clouds = 0.45,
	SunRays = 0.05,
	ShadowSoftness = 0.3,
	Wind = Vector3.new(4, 0, 2),
	TerrainColors = {
		Grass = Color3.fromRGB(110, 190, 90),
		LeafyGrass = Color3.fromRGB(80, 165, 75),
		Rock = Color3.fromRGB(150, 145, 140),
	},
}
-- A veces sale con otra luz o con mal tiempo (ver LightingVariants)
Map.LightingVariants = { Variants.Sunset(0.25), Variants.Fog(0.25) }

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local GRASS = RGB(120, 195, 95)
local PATH = RGB(205, 190, 160)
local STONE = RGB(185, 180, 172)
local STONE_DARK = RGB(140, 135, 128)
local WOOD = RGB(165, 110, 62)
local WOOD_DARK = RGB(105, 68, 40)
local ROOF_BLUE = RGB(70, 100, 190)
local SMOOTH = Enum.Material.SmoothPlastic
local COBBLE = Enum.Material.Cobblestone

local LENGTH, WIDTH = 200, 130
local KEEP = 8 -- media anchura de la torre central
local KEEP_H = 10 -- altura de su azotea

-- Almenas a lo largo de un borde (de a a b, a la altura y), saltándose los tramos en `skip`
local function battlements(a, b, y, skip, thickness)
	local length = (b - a).Magnitude
	local dir = (b - a).Unit
	local count = math.floor(length / 3)
	for i = 0, count - 1 do
		local p = a + dir * ((i + 0.5) * length / count)
		local blocked = false
		for _, s in skip or {} do
			if (p - s).Magnitude < 3 then
				blocked = true
			end
		end
		if i % 2 == 0 and not blocked then
			Kit.block("Merlon", V(thickness or 2, 2, 2), CFrame.lookAt(V(p.X, y + 1, p.Z), V(p.X, y + 1, p.Z) + dir), STONE, COBBLE)
		end
	end
end

-- Torreón redondo con tejado cónico (cobertura grande)
local function tower(position, diameter, height, roofColor)
	Kit.cylinder("Tower", height, diameter, CFrame.new(position + V(0, height / 2, 0)), STONE, COBBLE)
	Kit.cylinder("TowerRing", 1, diameter + 0.8, CFrame.new(position + V(0, height - 0.5, 0)), STONE_DARK, COBBLE, nil, true)
	-- (el tejado es sólido: si no, alguien podría meterse dentro de un supersalto y disparar sin ser visto)
	for i = 0, 5 do
		local d = (diameter + 1) * (1 - i / 6)
		Kit.cylinder("TowerRoof", 1.4, d, CFrame.new(position + V(0, height + 0.7 + i * 1.4, 0)), roofColor, SMOOTH)
	end
	local flagPole = position + V(0, height + 9.5, 0)
	Kit.cylinder("FlagPole", 4, 0.25, CFrame.new(flagPole), WOOD_DARK, Enum.Material.Wood, nil, true)
	Kit.deco("Pennant", V(2.4, 1.2, 0.1), CFrame.new(flagPole + V(1.2, 1.4, 0)), roofColor, Enum.Material.Fabric)
	for _, a in { 0, 120, 240 } do
		local dir = V(math.sin(rad(a)), 0, math.cos(rad(a)))
		Kit.deco("ArrowSlit", V(0.6, 2.4, 0.3), CFrame.lookAt(position + dir * (diameter / 2 + 0.05) + V(0, height * 0.6, 0), position + dir * 10 + V(0, height * 0.6, 0)), RGB(40, 35, 35), SMOOTH)
	end
end

-- Puesto de mercado: mostrador (cobertura baja), postes y toldo de rayas
local function stall(cf, color)
	Kit.block("Counter", V(6, 2.4, 2), cf * CFrame.new(0, 1.2, 0), WOOD, Enum.Material.WoodPlanks)
	for _, x in { -2.8, 2.8 } do
		Kit.deco("StallPost", V(0.4, 5, 0.4), cf * CFrame.new(x, 2.5, 1.5), WOOD_DARK, Enum.Material.Wood)
	end
	for i = 0, 3 do
		Kit.deco("Awning", V(1.55, 0.2, 3.6), cf * CFrame.new(-2.3 + i * 1.55, 5, 0.6) * CFrame.Angles(rad(-15), 0, 0), i % 2 == 0 and color or RGB(250, 245, 235), Enum.Material.Fabric)
	end
	for i = 0, 2 do
		Kit.ball("Fruit", 0.7, cf * CFrame.new(-1.5 + i * 1.5, 2.75, 0), i == 1 and RGB(255, 170, 40) or RGB(220, 50, 50), SMOOTH, true)
	end
end

local function well(cf)
	Kit.cylinder("Well", 2.4, 5, cf * CFrame.new(0, 1.2, 0), STONE, COBBLE)
	Kit.cylinder("WellWater", 0.1, 4, cf * CFrame.new(0, 2.45, 0), RGB(70, 140, 200), SMOOTH, nil, true)
	for _, x in { -2.2, 2.2 } do
		Kit.deco("WellPost", V(0.4, 4, 0.4), cf * CFrame.new(x, 4, 0), WOOD_DARK, Enum.Material.Wood)
	end
	Kit.deco("WellRoof", V(5.6, 0.3, 3.4), cf * CFrame.new(0, 6.1, 0), RGB(170, 60, 50), SMOOTH)
end

local function hayCart(cf)
	Kit.block("CartBed", V(4, 1.6, 7), cf * CFrame.new(0, 1.8, 0), WOOD, Enum.Material.WoodPlanks)
	Kit.block("CartHay", V(3.6, 1.8, 6.4), cf * CFrame.new(0, 3.5, 0), RGB(240, 205, 95), Enum.Material.Grass)
	for _, z in { -2.4, 2.4 } do
		for _, x in { -2.2, 2.2 } do
			Kit.cylinder("CartWheel", 0.35, 2.4, cf * CFrame.new(x, 1.2, z) * CFrame.Angles(0, 0, rad(90)), WOOD_DARK, Enum.Material.Wood, nil, true)
		end
	end
	Kit.contactShadow(cf, 4.5, 7.5)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Breeze") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Kit.pickLighting(Map))
	folder:SetAttribute("Variant", Kit.Variant)
	folder:SetAttribute("Weather", Kit.Weather)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo: césped con caminos de tierra en cruz
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), GRASS, SMOOTH)
	deco("Path", V(LENGTH, 0.1, 12), CFrame.new(0, 0.05, 0), PATH, SMOOTH)
	deco("Path", V(12, 0.1, WIDTH), CFrame.new(0, 0.05, 0), PATH, SMOOTH)

	-- Torre del homenaje: dos mitades a los lados del túnel (a lo largo de x) y el techo del túnel
	for _, sz in { -1, 1 } do
		block("Keep", V(KEEP * 2, KEEP_H, KEEP - 3), CFrame.new(0, KEEP_H / 2, sz * (KEEP + 3) / 2), STONE, COBBLE)
	end
	block("KeepTop", V(KEEP * 2, KEEP_H - 6, 6), CFrame.new(0, 6 + (KEEP_H - 6) / 2, 0), STONE, COBBLE)
	deco("KeepTrim", V(KEEP * 2 + 0.6, 0.6, KEEP * 2 + 0.6), CFrame.new(0, KEEP_H - 0.3, 0), STONE_DARK, COBBLE)
	for _, sx in { -1, 1 } do
		deco("TunnelArch", V(0.6, 1, 7), CFrame.new(sx * (KEEP + 0.1), 6.3, 0), STONE_DARK, COBBLE)
		local torch = deco("Torch", V(0.5, 1.2, 0.5), CFrame.new(sx * (KEEP + 0.4), 5, 4.2), RGB(255, 170, 60), Enum.Material.Neon)
		Kit.light(torch, "PointLight", RGB(255, 170, 80), 12, 1)
	end
	-- Estandarte real en lo alto
	Kit.cylinder("KeepPole", 8, 0.35, CFrame.new(0, KEEP_H + 4, 0), WOOD_DARK, Enum.Material.Wood, nil, true)
	local banner = deco("RoyalBanner", V(4, 2.6, 0.12), CFrame.new(2, KEEP_H + 6.6, 0), RGB(150, 40, 160), Enum.Material.Fabric)
	Kit.sign(banner, Enum.NormalId.Front, "👑", RGB(255, 215, 70))
	Kit.sign(banner, Enum.NormalId.Back, "👑", RGB(255, 215, 70))

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(235, 70, 70) or RGB(60, 130, 240)

		-- Escalera exterior a la azotea de la torre y almenas de su lado
		Kit.stairs(m * V(-KEEP - 15.8, 0, 6), m * V(-KEEP - 0.2, KEEP_H, 6), 3, STONE, COBBLE)
		battlements(m * V(-KEEP + 0.9, 0, -KEEP + 0.9), m * V(-KEEP + 0.9, 0, KEEP - 0.9), KEEP_H, { m * V(-KEEP + 0.9, 0, 6) })
		battlements(m * V(-KEEP + 0.9, 0, KEEP - 0.9), m * V(KEEP - 0.9, 0, KEEP - 0.9), KEEP_H, { m * V(-5.3, 0, KEEP - 0.9) })

		-- Muralla con tres pasos y rampa al adarve
		local wallX = -48
		-- (los tramos de los extremos llegan al límite del mapa: solo se cruza por los tres pasos)
		for _, seg in { { -65, -30 }, { -18, -6 }, { 6, 18 }, { 30, 65 } } do
			local len = seg[2] - seg[1]
			local cz = (seg[1] + seg[2]) / 2
			-- (4 de ancho: las almenas van por el lado del centro y queda un adarve para andar)
			block("CastleWall", V(4, 7, len), m * CFrame.new(wallX, 3.5, cz), STONE, COBBLE)
			battlements(m * V(wallX + 1.4, 0, seg[1] + 0.5), m * V(wallX + 1.4, 0, seg[2] - 0.5), 7, nil, 1.2)
			Kit.banner(m * CFrame.new(wallX + 2.2, 4.6, cz) * CFrame.Angles(0, rad(-90), 0), 2.5, 3.5, teamColor, RGB(255, 215, 70))
		end
		Kit.stairs(m * V(wallX - 14, 0, 12), m * V(wallX - 2, 7, 12), 3, STONE, COBBLE)
		Kit.stairs(m * V(wallX - 14, 0, -40), m * V(wallX - 2, 7, -40), 3, STONE, COBBLE)
		-- Torreones en las esquinas de la muralla
		tower(m * V(wallX, 0, 56), 9, 14, side == "A" and RGB(200, 60, 60) or ROOF_BLUE)
		tower(m * V(wallX, 0, -56), 9, 14, side == "A" and RGB(200, 60, 60) or ROOF_BLUE)

		-- Patio: mercado, pozo, carros de heno, barriles, cajas y árboles
		stall(m * CFrame.new(-30, 0, 24) * CFrame.Angles(0, rad(180), 0), teamColor)
		stall(m * CFrame.new(-22, 0, 30) * CFrame.Angles(0, rad(150), 0), RGB(80, 170, 90))
		well(m * CFrame.new(-28, 0, -24))
		hayCart(m * CFrame.new(-16, 0, -14) * CFrame.Angles(0, rad(70), 0))
		hayCart(m * CFrame.new(-38, 0, 8) * CFrame.Angles(0, rad(10), 0))
		Kit.barrel(m * CFrame.new(-12, 0, 18), WOOD)
		Kit.barrel(m * CFrame.new(-14.3, 0, 19.5), WOOD_DARK)
		Kit.crate(m * CFrame.new(-36, 0, -42), 4, WOOD)
		Kit.crate(m * CFrame.new(-31.5, 0, -46), 3.5, WOOD)
		Kit.crate(m * CFrame.new(-62, 0, 24), 4, WOOD)
		Kit.crate(m * CFrame.new(-64, 0, -26), 4, WOOD)
		Kit.tree(m * CFrame.new(-20, 0, -48))
		Kit.tree(m * CFrame.new(-8, 0, 50))
		Kit.tree(m * CFrame.new(-66, 0, 52))
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(235, 225, 205), Roof = STONE, RoofMaterial = COBBLE }
	Kit.spawnArea(teams[1], CFrame.new(-85, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-85, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-62, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-62, 0, 0))

	-- Fondo: colinas y pinos
	Kit.bounds(LENGTH, WIDTH, 60)
	local rng = Random.new(53)
	for x = -130, 130, 22 do
		for _, z in { -1, 1 } do
			Kit.cartoonPine(V(x + rng:NextNumber(-6, 6), 0, z * (WIDTH / 2 + 50 + rng:NextNumber(0, 12))), 1.6, true)
		end
	end
	for x = -200, 200, 60 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -16, z * 160), 42, Enum.Material.Grass, { Inward = V(0, 0, -z), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end
	for _, sx in { -1, 1 } do
		for z = -80, 80, 55 do
			Kit.naturalHill(V(sx * 165, -16, z), 42, Enum.Material.Grass, { Inward = V(-sx, 0, 0), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end

	-- Modos
	for _, p in {
		V(-76, 0.5, 8), V(-76, 0.5, -16), V(-56, 0.5, 2), V(-40, 0.5, 30), V(-26, 0.5, -36),
		V(-49, 7.5, 15), V(-4, KEEP_H + 0.5, -4), V(-20, 0.5, 0), V(-60, 0.5, -44), V(-38, 0.5, 50),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, KEEP_H, 0), 6, 1)
	Kit.zone(V(-28, 0, -10), 6, 2)
	Kit.zone(V(28, 0, 10), 6, 3)
	Kit.zone(V(0, 0, -36), 6, 4)
	Kit.zone(V(0, 0, 36), 6, 5)
	return folder
end

return Map
