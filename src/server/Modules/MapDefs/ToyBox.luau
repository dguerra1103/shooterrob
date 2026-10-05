-- CAJA DE JUGUETES: eres del tamaño de un juguete dentro del cuarto de un niño. Castillo de bloques
-- en el centro con pasarela elevada, ladrillos de construcción gigantes y cubos con letras como
-- cobertura, tren de juguete, plataformas de ladrillos en los laterales, ceras de colores como
-- pilares y un osito de peluche gigante. Simétrico (rojo contra azul).
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "ToyBox",
	Name = "Caja de Juguetes",
	Icon = "🧸",
	Description = "Cuarto de juegos · castillo de bloques · ladrillos gigantes",
}

Map.Lighting = {
	ClockTime = 15.2,
	Brightness = 3,
	Exposure = 0.06,
	Ambient = Color3.fromRGB(130, 122, 140),
	OutdoorAmbient = Color3.fromRGB(170, 165, 185),
	Atmosphere = { Density = 0.24, Offset = 0.2, Color = Color3.fromRGB(235, 225, 255), Decay = Color3.fromRGB(150, 140, 210), Glare = 0, Haze = 0.5 },
	Color = { Saturation = 0.22, Contrast = 0.06, Brightness = 0.03, Tint = Color3.fromRGB(255, 250, 245) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.45,
	SunRays = 0.04,
	ShadowSoftness = 0.3,
	Wind = Vector3.new(2, 0, 1),
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local WOOD = RGB(222, 168, 110) -- suelo de madera
local WALL = RGB(150, 200, 255) -- paredes azul cielo
local TRIM = RGB(255, 200, 60)
local BRICKS = { RGB(235, 60, 60), RGB(50, 130, 240), RGB(255, 205, 40), RGB(60, 200, 90), RGB(255, 140, 40), RGB(170, 90, 230) }

local LENGTH, WIDTH = 200, 130

local function wall(name, cf, size, color)
	local part = Kit.block(name, size, cf * CFrame.new(0, size.Y / 2, 0), color or WALL, Enum.Material.SmoothPlastic)
	Kit.deco(name .. "Cap", V(size.X + 0.4, 0.7, size.Z + 0.4), cf * CFrame.new(0, size.Y + 0.35, 0), TRIM, Enum.Material.SmoothPlastic)
	return part
end

-- Ladrillo de construcción con tetones (de pie sobre cf). size = ancho x alto x fondo
local function brick(cf, size, color, studs)
	Kit.block("ToyBrick", size, cf * CFrame.new(0, size.Y / 2, 0), color, Enum.Material.SmoothPlastic)
	local nx, nz = studs and studs.X or math.max(1, math.floor(size.X / 3)), studs and studs.Y or math.max(1, math.floor(size.Z / 3))
	for i = 1, nx do
		for j = 1, nz do
			local x = -size.X / 2 + (i - 0.5) * size.X / nx
			local z = -size.Z / 2 + (j - 0.5) * size.Z / nz
			Kit.cylinder("BrickStud", 0.6, math.min(size.X / nx, size.Z / nz) * 0.62, cf * CFrame.new(x, size.Y + 0.3, z), color, Enum.Material.SmoothPlastic, nil, true)
		end
	end
end

-- Cubo de madera con letras de colores en dos caras
local function letterBlock(cf, size, color, letterA, letterB)
	local block = Kit.block("LetterBlock", V(size, size, size), cf * CFrame.new(0, size / 2, 0), color, Enum.Material.SmoothPlastic)
	Kit.sign(block, Enum.NormalId.Front, letterA, Color3.new(1, 1, 1))
	Kit.sign(block, Enum.NormalId.Back, letterB, Color3.new(1, 1, 1))
	Kit.sign(block, Enum.NormalId.Left, letterB, Color3.new(1, 1, 1))
	Kit.sign(block, Enum.NormalId.Right, letterA, Color3.new(1, 1, 1))
	return block
end

-- Cera de colores gigante de pie (pilar): cuerpo, envoltorio de papel y punta
local function crayon(cf, height, color)
	Kit.cylinder("Crayon", height, 3.2, cf * CFrame.new(0, height / 2, 0), color, Enum.Material.SmoothPlastic)
	Kit.cylinder("CrayonWrap", height * 0.55, 3.3, cf * CFrame.new(0, height * 0.42, 0), color:Lerp(Color3.new(1, 1, 1), 0.55), Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("CrayonBand", 0.4, 3.35, cf * CFrame.new(0, height * 0.7, 0), color:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("CrayonTipBase", 1.2, 2.4, cf * CFrame.new(0, height + 0.6, 0), color, Enum.Material.SmoothPlastic, nil, true)
	Kit.ball("CrayonTip", 1.6, cf * CFrame.new(0, height + 1.3, 0), color, Enum.Material.SmoothPlastic, true)
end

-- Tren de juguete (cobertura larga): locomotora y dos vagones con ruedas
local function train(cf, colors)
	local function wheels(at, length)
		for _, x in { -length / 2 + 1, length / 2 - 1 } do
			for _, z in { -1.7, 1.7 } do
				Kit.cylinder("TrainWheel", 0.5, 1.8, at * CFrame.new(x, 0.9, z) * CFrame.Angles(rad(90), 0, 0), RGB(40, 40, 46), Enum.Material.SmoothPlastic, nil, true)
			end
		end
	end
	-- Locomotora
	Kit.block("TrainCab", V(5, 5, 3.4), cf * CFrame.new(-6, 3.3, 0), colors[1], Enum.Material.SmoothPlastic)
	Kit.block("TrainRoof", V(5.6, 0.6, 4), cf * CFrame.new(-6, 6.1, 0), colors[2], Enum.Material.SmoothPlastic)
	Kit.cylinder("TrainBoiler", 5, 3, cf * CFrame.new(-1.5, 2.7, 0) * CFrame.Angles(0, 0, rad(90)), colors[2], Enum.Material.SmoothPlastic)
	Kit.cylinder("TrainChimney", 2, 1.2, cf * CFrame.new(0, 5, 0), RGB(40, 40, 46), Enum.Material.SmoothPlastic, nil, true)
	wheels(cf * CFrame.new(-3.5, 0, 0), 9)
	-- Vagones
	for i, color in { colors[3], colors[4] } do
		local at = cf * CFrame.new(3.5 + i * 7, 0, 0)
		Kit.block("TrainCar", V(6, 2.6, 3.4), at * CFrame.new(0, 2.1, 0), color, Enum.Material.SmoothPlastic)
		Kit.block("TrainCargo", V(2.4, 2.4, 2.4), at * CFrame.new(-1.3, 4.6, 0) * CFrame.Angles(0, rad(12), 0), BRICKS[(i + 2) % #BRICKS + 1], Enum.Material.SmoothPlastic)
		wheels(at, 6)
	end
end

-- Osito de peluche gigante sentado (decoración de fondo)
local function teddy(position, scale, facing)
	local cf = CFrame.new(position) * CFrame.Angles(0, facing, 0)
	local fur, light = RGB(176, 118, 70), RGB(230, 190, 140)
	Kit.ball("TeddyBody", 14 * scale, cf * CFrame.new(0, 7 * scale, 0), fur, Enum.Material.SmoothPlastic, true)
	Kit.ball("TeddyBelly", 9 * scale, cf * CFrame.new(0, 6.5 * scale, -3.4 * scale), light, Enum.Material.SmoothPlastic, true)
	Kit.ball("TeddyHead", 10 * scale, cf * CFrame.new(0, 17 * scale, 0), fur, Enum.Material.SmoothPlastic, true)
	Kit.ball("TeddySnout", 4 * scale, cf * CFrame.new(0, 16 * scale, -4.4 * scale), light, Enum.Material.SmoothPlastic, true)
	Kit.ball("TeddyNose", 1.4 * scale, cf * CFrame.new(0, 16.8 * scale, -6.2 * scale), RGB(40, 30, 30), Enum.Material.SmoothPlastic, true)
	for _, s in { -1, 1 } do
		Kit.ball("TeddyEar", 4 * scale, cf * CFrame.new(s * 4 * scale, 21.5 * scale, 0), fur, Enum.Material.SmoothPlastic, true)
		Kit.ball("TeddyEye", 1.2 * scale, cf * CFrame.new(s * 1.8 * scale, 18.6 * scale, -4.4 * scale), RGB(30, 25, 25), Enum.Material.SmoothPlastic, true)
		Kit.ball("TeddyArm", 5 * scale, cf * CFrame.new(s * 7.5 * scale, 9 * scale, -2 * scale), fur, Enum.Material.SmoothPlastic, true)
		Kit.ball("TeddyFoot", 6 * scale, cf * CFrame.new(s * 4.5 * scale, 2.4 * scale, -6 * scale), fur, Enum.Material.SmoothPlastic, true)
	end
	Kit.block("TeddyBow", V(6 * scale, 2 * scale, 1.4 * scale), cf * CFrame.new(0, 12.5 * scale, -4.5 * scale), RGB(235, 60, 90), Enum.Material.SmoothPlastic)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo de madera con tablas, alfombra redonda en el centro
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), WOOD, Enum.Material.SmoothPlastic)
	for z = -WIDTH / 2, WIDTH / 2, 10 do
		deco("FloorBoardLine", V(LENGTH, 0.05, 0.3), CFrame.new(0, 0.02, z), WOOD:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.SmoothPlastic)
	end
	Kit.cylinder("Rug", 0.2, 64, CFrame.new(0, 0.1, 0), RGB(120, 200, 255), Enum.Material.SmoothPlastic)
	Kit.cylinder("RugRing", 0.22, 52, CFrame.new(0, 0.11, 0), RGB(255, 230, 120), Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("RugCenter", 0.24, 38, CFrame.new(0, 0.12, 0), RGB(255, 150, 190), Enum.Material.SmoothPlastic, nil, true)

	-- Paredes con ceras de colores
	for _, z in { -1, 1 } do
		wall("OuterWall", CFrame.new(0, 0, z * (WIDTH / 2 + 1.5)), V(LENGTH + 6, 20, 3))
		for i, x in { -84, -56, -28, 0, 28, 56, 84 } do
			crayon(CFrame.new(x, 0, z * (WIDTH / 2 - 1)), 18, BRICKS[(i + (z > 0 and 3 or 0)) % #BRICKS + 1])
		end
	end
	for _, x in { -1, 1 } do
		wall("OuterWall", CFrame.new(x * (LENGTH / 2 + 1.5), 0, 0), V(3, 20, WIDTH + 6))
	end

	-- Castillo central de bloques: cuatro torres de cubos y una pasarela en cruz a 8 de altura
	local deckY = 8
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local base = CFrame.new(x * 11, 0, z * 11)
			for level = 0, 2 do
				local color = BRICKS[(level + (x + z) / 2 + 2) % #BRICKS + 1]
				block("CastleBlock", V(6, 4, 6), base * CFrame.new(0, level * 4 + 2, 0) * CFrame.Angles(0, rad(level * 8 * x), 0), color, Enum.Material.SmoothPlastic)
			end
			Kit.cylinder("CastleTop", 2, 4.4, base * CFrame.new(0, 13, 0), RGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, true)
			Kit.ball("CastleTopBall", 2.2, base * CFrame.new(0, 14.4, 0), BRICKS[1], Enum.Material.SmoothPlastic, true)
		end
	end
	block("CastleDeck", V(16, 1, 6), CFrame.new(0, deckY - 0.5, 0), BRICKS[3], Enum.Material.SmoothPlastic)
	block("CastleDeck", V(6, 1, 16), CFrame.new(0, deckY - 0.5, 0), BRICKS[3], Enum.Material.SmoothPlastic)
	for _, s in { -1, 1 } do
		for _, x in { -1, 1 } do
			-- Almenas bajas a los lados del brazo largo (sin cortar el cruce)
			block("Battlement", V(5, 1.6, 0.8), CFrame.new(x * 5.5, deckY + 0.8, s * 2.6), BRICKS[2], Enum.Material.SmoothPlastic)
		end
	end

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and BRICKS[1] or BRICKS[2]
		-- Escalera del castillo (sube por el lado de cada equipo)
		Kit.stairs((m * CFrame.new(-26, 0, 0)).Position, (m * CFrame.new(-8, deckY, 0)).Position, 5, BRICKS[4], Enum.Material.SmoothPlastic)

		-- Plataforma lateral de ladrillos (a 6 de altura) con escalera
		local platY = 6
		brick(m * CFrame.new(-41, 0, -(WIDTH / 2 - 8)), V(22, platY, 12), teamColor, Vector2.new(4, 2))
		Kit.stairs((m * CFrame.new(-62, 0, -(WIDTH / 2 - 8))).Position, (m * CFrame.new(-52, platY, -(WIDTH / 2 - 8))).Position, 5, BRICKS[5], Enum.Material.SmoothPlastic)

		-- Ladrillos gigantes como cobertura
		brick(m * CFrame.new(-36, 0, 18), V(9, 4, 4.5), BRICKS[3])
		brick(m * CFrame.new(-54, 0, -14) * CFrame.Angles(0, rad(90), 0), V(9, 4, 4.5), BRICKS[4])
		brick(m * CFrame.new(-22, 0, -30), V(6, 5, 6), BRICKS[6])
		brick(m * CFrame.new(-70, 0, 40), V(9, 4, 4.5), BRICKS[5])
		brick(m * CFrame.new(-46, 0, 46) * CFrame.Angles(0, rad(25), 0), V(6, 7, 3), BRICKS[1])

		-- Cubos con letras
		letterBlock(m * CFrame.new(-30, 0, -10) * CFrame.Angles(0, rad(15), 0), 5, BRICKS[2], "A", "B")
		letterBlock(m * CFrame.new(-62, 0, 20), 5, BRICKS[4], "C", "D")
		letterBlock(m * CFrame.new(-14, 0, 40), 4.5, BRICKS[5], "E", "F")
		letterBlock(m * CFrame.new(-14, 4.5, 40) * CFrame.Angles(0, rad(30), 0), 3.5, BRICKS[6], "G", "H")

		-- Tren de juguete en la banda lateral (cobertura larga)
		train(m * CFrame.new(-28, 0, 52), { RGB(235, 60, 60), RGB(40, 120, 230), RGB(255, 200, 40), RGB(60, 200, 90) })

		-- Pelota de goma (decoración, se atraviesa)
		local ball = Kit.ball("ToyBall", 5, m * CFrame.new(-80, 2.5, -48), RGB(255, 90, 90), Enum.Material.SmoothPlastic, true)
		ball.CastShadow = true
		Kit.cylinder("ToyBallStripe", 5.1, 1.2, m * CFrame.new(-80, 2.5, -48) * CFrame.Angles(0, 0, rad(90)), RGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, true)
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(255, 240, 210), Roof = WALL }
	Kit.spawnArea(teams[1], CFrame.new(-85, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-85, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-62, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-62, 0, 0))

	-- Fondo: pilas de bloques gigantes, ositos y colinas
	Kit.bounds(LENGTH, WIDTH, 50)
	-- Nombres de las zonas
	Kit.callout("CASTILLO", CFrame.new(0, 8, 0), V(30, 24, 30))
	for _, m in { CFrame.new(), Kit.MIRROR } do
		Kit.callout("LADRILLO GRANDE", m * CFrame.new(-41, 6, -(WIDTH / 2 - 8)), V(26, 18, 16))
	end
	teddy(V(-40, 0, WIDTH / 2 + 30), 1.6, math.pi)
	teddy(V(40, 0, -(WIDTH / 2 + 30)), 1.6, 0)
	local n = 0
	for x = -140, 140, 35 do
		for _, z in { -1, 1 } do
			n += 1
			if math.abs(x - z * -40) > 25 then
				local base = V(x, 0, z * (WIDTH / 2 + 20 + (n % 3) * 8))
				local size = 12 + (n % 3) * 3
				for level = 0, n % 3 do
					deco("BigBlock", V(size, size, size), CFrame.new(base + V((level % 2) * 3, size / 2 + level * size, 0)) * CFrame.Angles(0, rad(level * 17 + n * 9), 0), BRICKS[(n + level) % #BRICKS + 1], Enum.Material.SmoothPlastic)
				end
			end
		end
	end
	for x = -200, 200, 70 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -18, z * 150), 50, Enum.Material.Grass, { Inward = V(0, 0, -z), Top = Enum.Material.LeafyGrass, RockCount = 0 })
		end
	end
	for _, sx in { -1, 1 } do
		for z = -90, 90, 60 do
			Kit.naturalHill(V(sx * 165, -18, z), 50, Enum.Material.Grass, { Inward = V(-sx, 0, 0), Top = Enum.Material.LeafyGrass, RockCount = 0 })
		end
	end

	-- Modos
	for _, p in {
		V(-74, 0.5, 16), V(-74, 0.5, -16), V(-48, 0.5, 2), V(-40, 0.5, 30), V(-44, 0.5, -34),
		V(-22, 0.5, 16), V(-12, 0.5, -20), V(-40, 6.5, -57), V(-1.5, deckY + 0.5, -5), V(-78, 0.5, -36),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, deckY, 0), 5, 1)
	Kit.zone(V(-40, 0, 30), 6, 2)
	Kit.zone(V(40, 0, -30), 6, 3)
	Kit.zone(V(-40, 6, -57), 5, 4)
	Kit.zone(V(40, 6, 57), 5, 5)
	Kit.dustMotes(CFrame.new(0, 8, 0), V(120, 14, 80), Color3.fromRGB(255, 240, 200), 14)
	return folder
end

return Map
