-- MANSIÓN ENCANTADA (mapa de Halloween): de noche, con luna grande y niebla violeta. Mansión en el
-- centro con planta baja de lado a lado y azotea con almenas (escaleras por fuera), cementerios con
-- lápidas como cobertura, criptas, árboles secos, calabazas, faroles naranjas y un caldero de bruja.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "HauntedManor",
	Name = "Mansión Encantada",
	Icon = "🎃",
	Description = "Halloween · noche · mansión y cementerios",
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.76, Sat = 0.2 }, -- grises violetas
	ClockTime = 0.2,
	Brightness = 1.2,
	Exposure = 0.3,
	Ambient = Color3.fromRGB(60, 45, 85),
	OutdoorAmbient = Color3.fromRGB(85, 70, 120),
	Atmosphere = { Density = 0.38, Offset = 0.1, Color = Color3.fromRGB(110, 80, 150), Decay = Color3.fromRGB(60, 35, 90), Glare = 0, Haze = 2.4 },
	Color = { Saturation = 0.25, Contrast = 0.15, Brightness = 0.04, Tint = Color3.fromRGB(245, 235, 255) },
	Bloom = { Intensity = 0.9, Size = 26, Threshold = 1.4 },
	Clouds = 0.4,
	CloudColor = Color3.fromRGB(90, 70, 120),
	SunRays = 0,
	Stars = 4000,
	MoonSize = 22,
	TerrainColors = {
		Grass = Color3.fromRGB(70, 90, 70),
		LeafyGrass = Color3.fromRGB(60, 80, 65),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local GRASS = RGB(70, 95, 75)
local STONE = RGB(120, 115, 135)
local STONE_DARK = RGB(85, 80, 100)
local WOOD = RGB(90, 60, 45)
local ROOF = RGB(70, 40, 90)
local ORANGE = RGB(255, 140, 40)
local GLOW = RGB(255, 190, 90)

local LENGTH, WIDTH = 190, 130

local function wall(name, cf, size, color)
	local part = Kit.block(name, size, cf * CFrame.new(0, size.Y / 2, 0), color or STONE, Enum.Material.SmoothPlastic)
	Kit.deco(name .. "Cap", V(size.X + 0.4, 0.6, size.Z + 0.4), cf * CFrame.new(0, size.Y + 0.3, 0), STONE_DARK, Enum.Material.SmoothPlastic)
	return part
end

-- Lápida (cobertura baja): losa con parte de arriba redondeada
local function gravestone(cf, w)
	w = w or 2.4
	Kit.block("Gravestone", V(w, 2.6, 0.7), cf * CFrame.new(0, 1.3, 0), STONE, Enum.Material.SmoothPlastic)
	-- Medio disco arriba: cilindro con el eje hacia delante (Z), del mismo grosor que la losa
	local top = Kit.cylinder("GravestoneTop", 0.7, w, cf * CFrame.new(0, 2.6, 0) * CFrame.Angles(rad(90), 0, 0), STONE, Enum.Material.SmoothPlastic)
	top.CastShadow = false
	Kit.deco("GravestoneCross", V(0.2, 0.9, 0.05), cf * CFrame.new(0, 1.7, -0.37), STONE_DARK, Enum.Material.SmoothPlastic)
	Kit.deco("GravestoneCrossBar", V(0.6, 0.18, 0.05), cf * CFrame.new(0, 1.9, -0.37), STONE_DARK, Enum.Material.SmoothPlastic)
end

-- Árbol seco retorcido (decoración, se atraviesa por las ramas)
local function deadTree(position, scale, seed)
	local rng = Random.new(seed)
	local h = 10 * scale
	Kit.cylinder("DeadTrunk", h, 1.2 * scale, CFrame.new(position + V(0, h / 2, 0)) * CFrame.Angles(0, 0, rad(rng:NextNumber(-6, 6))), WOOD, Enum.Material.SmoothPlastic)
	for i = 1, 4 do
		local y = h * (0.45 + i * 0.12)
		local a = rng:NextNumber(0, math.pi * 2)
		local len = rng:NextNumber(3, 5) * scale
		local dir = V(math.cos(a), 0.6, math.sin(a)).Unit
		local mid = position + V(0, y, 0) + dir * len / 2
		Kit.deco("DeadBranch", V(0.45 * scale, 0.45 * scale, len), CFrame.lookAt(mid, mid + dir), WOOD, Enum.Material.SmoothPlastic)
	end
end

-- Farol de hierro con luz naranja
local function lamp(position)
	Kit.cylinder("LampPost", 7, 0.35, CFrame.new(position + V(0, 3.5, 0)), RGB(30, 28, 36), Enum.Material.SmoothPlastic, nil, true)
	local glass = Kit.deco("LampGlow", V(0.9, 1.1, 0.9), CFrame.new(position + V(0, 7.4, 0)), GLOW, Enum.Material.Neon)
	Kit.deco("LampCap", V(1.3, 0.3, 1.3), CFrame.new(position + V(0, 8.1, 0)), RGB(30, 28, 36), Enum.Material.SmoothPlastic)
	Kit.light(glass, "PointLight", ORANGE, 16, 1.2)
end

-- Cripta pequeña (cobertura grande con puerta oscura)
local function crypt(cf)
	Kit.block("Crypt", V(8, 6, 6), cf * CFrame.new(0, 3, 0), STONE_DARK, Enum.Material.SmoothPlastic)
	Kit.block("CryptRoof", V(9, 1, 7), cf * CFrame.new(0, 6.5, 0), ROOF, Enum.Material.SmoothPlastic)
	Kit.deco("CryptDoor", V(2.6, 4, 0.2), cf * CFrame.new(0, 2, -3.05), RGB(20, 15, 25), Enum.Material.SmoothPlastic)
	Kit.deco("CryptCross", V(0.4, 2, 0.4), cf * CFrame.new(0, 8, 0), STONE, Enum.Material.SmoothPlastic)
	Kit.deco("CryptCrossBar", V(1.4, 0.4, 0.4), cf * CFrame.new(0, 8.4, 0), STONE, Enum.Material.SmoothPlastic)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Night") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo de hierba oscura y camino de piedra central
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), GRASS, Enum.Material.SmoothPlastic)
	block("Path", V(LENGTH - 20, 0.2, 12), CFrame.new(0, 0.1, 0), STONE_DARK, Enum.Material.SmoothPlastic)

	-- Muro perimetral con verja
	for _, z in { -1, 1 } do
		wall("OuterWall", CFrame.new(0, 0, z * (WIDTH / 2 + 1.5)), V(LENGTH + 6, 16, 3))
	end
	for _, x in { -1, 1 } do
		wall("OuterWall", CFrame.new(x * (LENGTH / 2 + 1.5), 0, 0), V(3, 16, WIDTH + 6))
	end

	-- Mansión central: planta baja de lado a lado (puertas en ±X), ventanas y azotea con almenas
	local w, d, h, t = 36, 24, 10, 1.6
	for _, z in { -1, 1 } do
		-- Paredes largas con ventanas (tres huecos a media altura)
		block("ManorWallLow", V(w, 3.5, t), CFrame.new(0, 1.75, z * (d / 2 - t / 2)), STONE, Enum.Material.SmoothPlastic)
		block("ManorWallHigh", V(w, h - 6.5, t), CFrame.new(0, 6.5 + (h - 6.5) / 2, z * (d / 2 - t / 2)), STONE, Enum.Material.SmoothPlastic)
		for _, x in { -15.5, -5.5, 5.5, 15.5 } do
			block("ManorWallMid", V(5, 3, t), CFrame.new(x, 5, z * (d / 2 - t / 2)), STONE, Enum.Material.SmoothPlastic)
		end
		for _, x in { -10.5, 0, 10.5 } do
			deco("ManorWindowGlow", V(4.6, 0.3, t + 0.1), CFrame.new(x, 6.4, z * (d / 2 - t / 2)), GLOW, Enum.Material.Neon)
		end
	end
	for _, x in { -1, 1 } do
		-- Paredes cortas con puerta grande en el centro
		local side = (d - 2 * t - 6) / 2
		for _, s in { -1, 1 } do
			block("ManorWallEnd", V(t, h, side), CFrame.new(x * (w / 2 - t / 2), h / 2, s * (3 + side / 2)), STONE, Enum.Material.SmoothPlastic)
		end
		block("ManorLintel", V(t, h - 7, 6), CFrame.new(x * (w / 2 - t / 2), 7 + (h - 7) / 2, 0), STONE, Enum.Material.SmoothPlastic)
		deco("ManorDoorFrame", V(t + 0.2, 0.5, 6.4), CFrame.new(x * (w / 2 - t / 2), 7.2, 0), ORANGE, Enum.Material.SmoothPlastic)
	end
	block("ManorRoof", V(w, 1, d), CFrame.new(0, h + 0.5, 0), ROOF, Enum.Material.SmoothPlastic)
	for _, z in { -1, 1 } do
		for x = -15, 15, 6 do
			block("Battlement", V(3, 1.6, 0.8), CFrame.new(x, h + 1.8, z * (d / 2 - 0.4)), STONE_DARK, Enum.Material.SmoothPlastic)
		end
	end
	-- Torreones con tejado puntiagudo y ventana iluminada en dos esquinas de la azotea (simétricos)
	Kit.symmetric(function(m)
		Kit.cylinder("Turret", 6, 4, m * CFrame.new(-14, h + 4, -8), STONE_DARK, Enum.Material.SmoothPlastic)
		Kit.deco("TurretRoof", V(4.6, 3, 4.6), m * CFrame.new(-14, h + 8.5, -8) * CFrame.Angles(0, rad(45), 0), ROOF, Enum.Material.SmoothPlastic)
		Kit.deco("TurretWindow", V(1, 1.4, 0.2), m * CFrame.new(-14, h + 4.5, -10.05), GLOW, Enum.Material.Neon)
	end)
	-- Lámpara de araña dentro
	local chandelier = deco("Chandelier", V(3, 0.4, 3), CFrame.new(0, h - 1.2, 0), GLOW, Enum.Material.Neon)
	Kit.light(chandelier, "PointLight", ORANGE, 18, 1.2)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(255, 90, 90) or RGB(90, 150, 255)
		-- Escalera exterior a la azotea (pegada a la pared larga)
		Kit.stairs((m * CFrame.new(-w / 2 - 6, 0, -(d / 2 + 3))).Position, (m * CFrame.new(4, h + 1, -(d / 2 + 3))).Position, 5, STONE_DARK, Enum.Material.SmoothPlastic)
		block("StairLanding", V(6, 1, 6), m * CFrame.new(7, h + 0.5, -(d / 2 + 3)), STONE_DARK, Enum.Material.SmoothPlastic)

		-- Cementerio: lápidas en filas
		for row = 0, 2 do
			for col = 0, 3 do
				local x = -40 - col * 6.5 + (row % 2) * 3
				local z = 24 + row * 9
				gravestone(m * CFrame.new(x, 0, z) * CFrame.Angles(0, rad((col * 7 + row * 3) % 12 - 6), 0))
			end
		end
		crypt(m * CFrame.new(-36, 0, -36))
		crypt(m * CFrame.new(-70, 0, 44) * CFrame.Angles(0, rad(90), 0))

		-- Coberturas sueltas: tapias de piedra rotas y ataúdes
		wall("BrokenWall", m * CFrame.new(-30, 0, 10), V(10, 4, 1.5))
		wall("BrokenWall", m * CFrame.new(-52, 0, -14) * CFrame.Angles(0, rad(90), 0), V(9, 3.5, 1.5))
		block("Coffin", V(2.4, 1.6, 6), m * CFrame.new(-20, 0.8, -24) * CFrame.Angles(0, rad(20), 0), WOOD, Enum.Material.SmoothPlastic)
		Kit.deco("CoffinCross", V(0.3, 0.05, 2), m * CFrame.new(-20, 1.62, -24) * CFrame.Angles(0, rad(20), 0), ORANGE, Enum.Material.SmoothPlastic)

		-- Caldero de bruja con líquido verde brillante
		local cauldron = m * CFrame.new(-24, 0, 36)
		Kit.cylinder("Cauldron", 3, 4.2, cauldron * CFrame.new(0, 1.5, 0), RGB(25, 22, 30), Enum.Material.SmoothPlastic)
		local goo = Kit.cylinder("CauldronGoo", 0.3, 3.6, cauldron * CFrame.new(0, 3.05, 0), RGB(120, 255, 90), Enum.Material.Neon, nil, true)
		Kit.light(goo, "PointLight", RGB(120, 255, 90), 14, 1.2)

		-- Árboles secos, faroles y calabazas
		deadTree((m * CFrame.new(-74, 0, -48)).Position, 1.1, 3)
		deadTree((m * CFrame.new(-58, 0, 50)).Position, 1.3, 7)
		deadTree((m * CFrame.new(-12, 0, -46)).Position, 1, 11)
		for _, p in { V(-26, 0, -6), V(-62, 0, 8), V(-40, 0, 52), V(-86, 0, -40) } do
			lamp((m * CFrame.new(p)).Position)
		end
		for i, p in { V(-34, 0, 22), V(-60, 0, -28), V(-16, 0, 16), V(-48, 0, -48) } do
			Kit.pumpkin(m * CFrame.new(p) * CFrame.Angles(0, rad(i * 70), 0), 1 + (i % 2) * 0.3)
		end
		_ = teamColor
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = STONE_DARK, Roof = ROOF }
	Kit.spawnArea(teams[1], CFrame.new(-80, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-80, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-56, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-56, 0, 0))

	-- Fondo: árboles secos y colinas oscuras
	Kit.bounds(LENGTH, WIDTH, 45)
	-- Nombres de las zonas
	Kit.callout("MANSIÓN", CFrame.new(0, 6, 0), V(38, 14, 26))
	Kit.callout("AZOTEA", CFrame.new(0, 16, 0), V(38, 10, 26))
	for _, m in { CFrame.new(), Kit.MIRROR } do
		Kit.callout("CEMENTERIO", m * CFrame.new(-51, 8, 33), V(32, 20, 28))
		Kit.callout("CRIPTA", m * CFrame.new(-36, 6, -36), V(14, 16, 14))
	end
	local n = 0
	for x = -130, 130, 24 do
		for _, z in { -1, 1 } do
			n += 1
			deadTree(V(x + z * 8, 0, z * (WIDTH / 2 + 14 + (n % 3) * 7)), 1.4 + (n % 3) * 0.2, n)
		end
	end
	for x = -180, 180, 70 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -18, z * 125), 48, Enum.Material.Grass, { Inward = V(0, 0, -z), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end
	for _, sx in { -1, 1 } do
		for _, z in { -50, 20 } do
			Kit.naturalHill(V(sx * 150, -18, z), 48, Enum.Material.Grass, { Inward = V(-sx, 0, 0), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end

	-- Modos
	for _, p in {
		V(-66, 0.5, 14), V(-66, 0.5, -14), V(-40, 0.5, 0), V(-30, 0.5, 30), V(-44, 0.5, -30),
		V(-12, 0.5, 0), V(-24, 0.5, -16), V(-6, h + 1.5, 4), V(-56, 0.5, 34), V(-80, 0.5, -46),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, h + 1, 0), 6, 1)
	Kit.zone(V(0, 0.2, 0), 6, 2)
	Kit.zone(V(-40, 0, 32), 6, 3)
	Kit.zone(V(40, 0, -32), 6, 4)
	Kit.zone(V(-28, 0, -36), 5, 5)
	Kit.dustMotes(CFrame.new(0, 8, 0), V(120, 14, 80), Color3.fromRGB(190, 150, 255), 14)
	return folder
end

return Map
