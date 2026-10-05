-- FERIA: parque de atracciones al atardecer. En el centro, un tiovivo con caballitos (se puede subir
-- a la plataforma y los caballos cubren); a cada lado, una fila de casetas de juegos con toldos de
-- rayas, los coches de choque (muro bajo), la casa de la risa con azotea por escaleras y el martillo
-- de fuerza. De fondo, la noria gigante, la montaña rusa y la carpa del circo. Simétrico.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "Carnival",
	Name = "Feria",
	Icon = "🎡",
	Description = "Atardecer · tiovivo central · casetas, coches de choque y noria",
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.07, Sat = 0.12 }, -- grises cálidos de atardecer
	ClockTime = 17.6,
	Latitude = 20,
	Brightness = 2.6,
	Exposure = 0.1,
	Ambient = Color3.fromRGB(130, 105, 120),
	OutdoorAmbient = Color3.fromRGB(185, 150, 160),
	Atmosphere = { Density = 0.22, Offset = 0.15, Color = Color3.fromRGB(255, 200, 170), Decay = Color3.fromRGB(200, 110, 140), Glare = 0.2, Haze = 0.8 },
	Color = { Saturation = 0.25, Contrast = 0.08, Brightness = 0.02, Tint = Color3.fromRGB(255, 240, 230) },
	Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.6 },
	Clouds = 0.35,
	SunRays = 0.08,
	ShadowSoftness = 0.25,
	Wind = Vector3.new(3, 0, 1),
	TerrainColors = {
		Grass = Color3.fromRGB(120, 200, 100),
		LeafyGrass = Color3.fromRGB(100, 180, 90),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local PATH = RGB(235, 210, 170) -- paseo de arena
local GRASS = RGB(120, 200, 100)
local CREAM = RGB(255, 245, 225)
local GOLD = RGB(255, 200, 60)
local RED = RGB(230, 60, 70)
local TEAL = RGB(40, 190, 200)
local PURPLE = RGB(150, 90, 220)
local PINK = RGB(255, 120, 180)
local NEON_BULB = RGB(255, 230, 150)
local SMOOTH = Enum.Material.SmoothPlastic

local LENGTH, WIDTH = 200, 130

-- Cono de rayas (tejado de carpa o tiovivo): cilindros apilados cada vez más estrechos
local function stripedCone(cf, diameter, height, colorA, colorB, steps)
	steps = steps or 6
	for i = 0, steps - 1 do
		local d = diameter * (1 - i / steps) + 1
		Kit.cylinder("ConeRoof", height / steps, d, cf * CFrame.new(0, (i + 0.5) * height / steps, 0), i % 2 == 0 and colorA or colorB, SMOOTH, nil, true)
	end
	Kit.cylinder("ConeTopPole", 2.5, 0.3, cf * CFrame.new(0, height + 1.2, 0), GOLD, SMOOTH, nil, true)
	Kit.ball("ConeTop", 1.2, cf * CFrame.new(0, height + 2.6, 0), GOLD, Enum.Material.Neon, true)
end

-- Tiovivo: plataforma baja transitable, columna central, caballitos (cobertura) y tejado
local function carousel(cf)
	Kit.cylinder("CarouselBase", 1, 30, cf * CFrame.new(0, 0.5, 0), CREAM, SMOOTH)
	Kit.cylinder("CarouselRim", 1.05, 30.6, cf * CFrame.new(0, 0.45, 0), RED, SMOOTH, nil, true)
	Kit.cylinder("CarouselColumn", 10, 5, cf * CFrame.new(0, 6, 0), GOLD, SMOOTH)
	Kit.cylinder("CarouselColumnBand", 1.2, 5.3, cf * CFrame.new(0, 4, 0), PINK, SMOOTH, nil, true)
	local colors = { CREAM, PINK, TEAL, PURPLE }
	for i = 0, 7 do
		local spot = cf * CFrame.Angles(0, rad(i * 45 + 22.5), 0) * CFrame.new(0, 1, -10.5)
		Kit.cylinder("CarouselPole", 10, 0.35, spot * CFrame.new(0, 5, 0), GOLD, Enum.Material.Metal, nil, true)
		local horseColor = colors[i % 4 + 1]
		local y = (i % 2 == 0) and 3.2 or 4.2 -- unos arriba y otros abajo, como si subieran y bajaran
		local horse = spot * CFrame.new(0, y, 0) * CFrame.Angles(0, rad(90), 0)
		Kit.block("HorseBody", V(3.4, 1.5, 1.2), horse, horseColor, SMOOTH)
		Kit.deco("HorseNeck", V(0.9, 1.6, 0.9), horse * CFrame.new(-1.6, 1, 0) * CFrame.Angles(0, 0, rad(-20)), horseColor, SMOOTH)
		Kit.deco("HorseHead", V(1.6, 0.8, 0.8), horse * CFrame.new(-2.2, 1.8, 0), horseColor, SMOOTH)
		Kit.deco("HorseMane", V(0.3, 1.4, 0.3), horse * CFrame.new(-1.3, 1.3, 0) * CFrame.Angles(0, 0, rad(-20)), GOLD, SMOOTH)
		Kit.deco("HorseSaddle", V(1.2, 0.3, 1.3), horse * CFrame.new(0.2, 0.85, 0), RED, SMOOTH)
		for _, lx in { -1.2, 1.2 } do
			Kit.deco("HorseLeg", V(0.35, 1.4, 0.35), horse * CFrame.new(lx, -1.3, 0) * CFrame.Angles(0, 0, rad(lx * 12)), horseColor, SMOOTH)
		end
		Kit.deco("HorseTail", V(0.3, 1.2, 0.3), horse * CFrame.new(1.8, 0.1, 0) * CFrame.Angles(0, 0, rad(-30)), GOLD, SMOOTH)
	end
	-- Tejado con borde festoneado y bombillas
	Kit.cylinder("CarouselCanopy", 1.2, 32, cf * CFrame.new(0, 11.6, 0), RED, SMOOTH, nil, true)
	for i = 0, 23 do
		local edge = cf * CFrame.Angles(0, rad(i * 15), 0) * CFrame.new(0, 10.6, -15.6)
		Kit.deco("CanopyScallop", V(3.6, 1.1, 0.3), edge, i % 2 == 0 and CREAM or GOLD, SMOOTH)
		Kit.ball("CanopyBulb", 0.5, edge * CFrame.new(0, -0.8, -0.2), NEON_BULB, Enum.Material.Neon, true).CastShadow = false
	end
	stripedCone(cf * CFrame.new(0, 12.2, 0), 31, 6, RED, CREAM, 6)
end

-- Caseta de juegos: mostrador (cobertura), paredes, toldo de rayas, premios y letrero
local function booth(cf, color, text)
	Kit.block("BoothCounter", V(8, 3.2, 1.6), cf * CFrame.new(0, 1.6, 0), CREAM, SMOOTH)
	Kit.deco("BoothCounterStripe", V(8.05, 0.8, 1.65), cf * CFrame.new(0, 2.2, 0), color, SMOOTH)
	Kit.block("BoothBack", V(8, 7, 0.6), cf * CFrame.new(0, 3.5, 5), color:Lerp(CREAM, 0.35), SMOOTH)
	for _, x in { -3.7, 3.7 } do
		Kit.block("BoothSide", V(0.6, 7, 5.4), cf * CFrame.new(x, 3.5, 2.5), CREAM, SMOOTH)
		Kit.cylinder("BoothPost", 7.6, 0.5, cf * CFrame.new(x, 3.8, -0.6), GOLD, SMOOTH, nil, true)
	end
	Kit.deco("BoothRoof", V(8.6, 0.5, 6.6), cf * CFrame.new(0, 7.3, 2.4), color, SMOOTH)
	Kit.awning(cf * CFrame.new(0, 7.2, -0.6), 8, 2.6, color)
	-- Premios: peluches (bolas) y globos en las estanterías
	local prizeColors = { PINK, TEAL, GOLD, PURPLE, RED }
	for i = 0, 4 do
		local p = cf * CFrame.new(-2.8 + i * 1.4, 4.2, 4.4)
		Kit.ball("PrizeBody", 1.1, p, prizeColors[i + 1], SMOOTH, true)
		Kit.ball("PrizeHead", 0.8, p * CFrame.new(0, 0.85, 0), prizeColors[i + 1], SMOOTH, true)
		Kit.ball("PrizeShelfToy", 0.7, cf * CFrame.new(-2.8 + i * 1.4, 6.2, 4.4), prizeColors[(i + 2) % 5 + 1], SMOOTH, true)
	end
	Kit.deco("BoothShelf", V(7, 0.3, 0.8), cf * CFrame.new(0, 3.5, 4.4), RGB(150, 100, 60), Enum.Material.Wood)
	Kit.deco("BoothShelf", V(7, 0.3, 0.8), cf * CFrame.new(0, 5.6, 4.4), RGB(150, 100, 60), Enum.Material.Wood)
	Kit.neonSign(cf * CFrame.new(0, 8.6, 2), 7, 1.6, text, color:Lerp(Color3.new(1, 1, 1), 0.3), GOLD)
end

-- Coches de choque: pista con muro bajo (cobertura) y cochecitos con su poste
local function bumperCars(cf, colorA, colorB)
	local sx, sz = 24, 16
	Kit.deco("BumperFloor", V(sx, 0.2, sz), cf * CFrame.new(0, 0.1, 0), RGB(70, 70, 90), SMOOTH)
	for _, z in { -1, 1 } do
		-- (con un hueco en medio de los lados largos para entrar)
		for _, x in { -1, 1 } do
			Kit.block("BumperWall", V(sx / 2 - 2.5, 2.6, 1), cf * CFrame.new(x * (sx / 4 + 1.25), 1.3, z * sz / 2), colorA, SMOOTH)
			Kit.deco("BumperWallTop", V(sx / 2 - 2.5, 0.4, 1.1), cf * CFrame.new(x * (sx / 4 + 1.25), 2.7, z * sz / 2), GOLD, SMOOTH)
		end
	end
	for _, x in { -1, 1 } do
		Kit.block("BumperWall", V(1, 2.6, sz), cf * CFrame.new(x * sx / 2, 1.3, 0), colorA, SMOOTH)
		Kit.deco("BumperWallTop", V(1.1, 0.4, sz), cf * CFrame.new(x * sx / 2, 2.7, 0), GOLD, SMOOTH)
	end
	local cars = { { -6, -3, 20, colorB }, { 4, 3, -35, GOLD }, { 7, -4, 70, TEAL }, { -3, 4, 160, PINK } }
	for _, c in cars do
		local car = cf * CFrame.new(c[1], 0, c[2]) * CFrame.Angles(0, rad(c[3]), 0)
		Kit.block("BumperCar", V(2.6, 1.4, 3.6), car * CFrame.new(0, 0.9, 0), c[4], SMOOTH)
		Kit.deco("BumperRubber", V(2.9, 0.5, 3.9), car * CFrame.new(0, 0.4, 0), RGB(40, 40, 45), SMOOTH)
		Kit.deco("BumperSeat", V(1.8, 1, 0.6), car * CFrame.new(0, 1.9, 0.9), RGB(40, 40, 45), SMOOTH)
		Kit.cylinder("BumperPole", 5, 0.2, car * CFrame.new(0, 4, 1.5), RGB(180, 180, 190), Enum.Material.Metal, nil, true)
	end
end

-- Casa de la risa: bloque con cara de payaso (mirando al centro del mapa, +Z local), azotea transitable (murete) y escaleras
local function funhouse(cf, color)
	local h = 9
	Kit.block("Funhouse", V(16, h, 12), cf * CFrame.new(0, h / 2, 0), color, SMOOTH)
	Kit.deco("FunhouseRoofEdge", V(16.4, 0.5, 12.4), cf * CFrame.new(0, h + 0.25, 0), GOLD, SMOOTH)
	Kit.deco("FunhouseMouth", V(5, 3.6, 0.3), cf * CFrame.new(0, 1.8, 6.05), RGB(40, 20, 30), SMOOTH)
	Kit.deco("FunhouseLip", V(6, 0.6, 0.35), cf * CFrame.new(0, 3.8, 6.1), RED, SMOOTH)
	for _, x in { -3.6, 3.6 } do
		Kit.ball("FunhouseEye", 3, cf * CFrame.new(x, 6.2, 5.6), Color3.new(1, 1, 1), SMOOTH, true)
		Kit.ball("FunhousePupil", 1.4, cf * CFrame.new(x * 0.9, 6, 7), RGB(30, 30, 40), SMOOTH, true)
	end
	Kit.ball("FunhouseNose", 2, cf * CFrame.new(0, 4.8, 6.4), RED, SMOOTH, true)
	-- Murete de la azotea (con hueco donde llega la escalera)
	Kit.block("FunhouseParapet", V(16, 1.6, 0.6), cf * CFrame.new(0, h + 0.8, -5.7), color:Lerp(CREAM, 0.3), SMOOTH)
	Kit.block("FunhouseParapet", V(16, 1.6, 0.6), cf * CFrame.new(0, h + 0.8, 5.7), color:Lerp(CREAM, 0.3), SMOOTH)
	Kit.block("FunhouseParapet", V(0.6, 1.6, 12), cf * CFrame.new(-7.7, h + 0.8, 0), color:Lerp(CREAM, 0.3), SMOOTH)
	Kit.stairs((cf * CFrame.new(26, 0, 0)).Position, (cf * CFrame.new(8, h, 0)).Position, 5, CREAM, SMOOTH)
	return h
end

-- Martillo de fuerza: torre con escala de luces y campana
local function strengthTester(cf)
	Kit.block("TesterBase", V(3, 1.2, 3), cf * CFrame.new(0, 0.6, 0), RED, SMOOTH)
	Kit.deco("TesterTower", V(1.4, 14, 0.8), cf * CFrame.new(0, 8, 0), CREAM, SMOOTH)
	for i = 0, 6 do
		local color = RGB(80, 220, 90):Lerp(RGB(255, 60, 60), i / 6)
		Kit.deco("TesterLight", V(1, 1.2, 0.3), cf * CFrame.new(0, 2.4 + i * 1.8, -0.5), color, Enum.Material.Neon)
	end
	Kit.ball("TesterBell", 2, cf * CFrame.new(0, 15.6, 0), GOLD, Enum.Material.Metal, true)
	Kit.deco("TesterPad", V(2, 0.3, 2), cf * CFrame.new(0, 0.15, -2.4), RGB(60, 60, 70), SMOOTH)
end

-- Carrito de globos
local function balloonCart(cf)
	Kit.block("BalloonCart", V(4, 2.4, 2.4), cf * CFrame.new(0, 1.6, 0), CREAM, SMOOTH)
	for _, x in { -1.4, 1.4 } do
		Kit.cylinder("CartWheel", 0.4, 1.4, cf * CFrame.new(x, 0.7, -1.3) * CFrame.Angles(rad(90), 0, 0), RGB(60, 60, 70), SMOOTH, nil, true)
	end
	local colors = { RED, TEAL, GOLD, PINK, PURPLE, RGB(90, 200, 90) }
	local rng = Random.new(5)
	for i = 1, 9 do
		local top = cf * CFrame.new(rng:NextNumber(-1.8, 1.8), 8 + rng:NextNumber(-1, 1.5), rng:NextNumber(-1.2, 1.2))
		Kit.ball("Balloon", 1.5, top, colors[(i - 1) % #colors + 1], SMOOTH, true)
		local mid = (top.Position + (cf * CFrame.new(0, 3, 0)).Position) / 2
		Kit.deco("BalloonString", V(0.06, 0.06, (top.Position - (cf * CFrame.new(0, 3, 0)).Position).Magnitude), CFrame.lookAt(mid, top.Position), Color3.new(1, 1, 1), SMOOTH)
	end
end

-- Puesto de palomitas
local function popcornStand(cf)
	Kit.block("PopcornCart", V(3.4, 3, 2.4), cf * CFrame.new(0, 1.5, 0), RED, SMOOTH)
	Kit.deco("PopcornGlass", V(3, 2.4, 2), cf * CFrame.new(0, 4.2, 0), RGB(255, 240, 200), Enum.Material.Glass).Transparency = 0.4
	Kit.deco("Popcorn", V(2.8, 1, 1.8), cf * CFrame.new(0, 3.5, 0), RGB(255, 245, 210), SMOOTH)
	Kit.deco("PopcornRoof", V(3.8, 0.5, 2.8), cf * CFrame.new(0, 5.7, 0), CREAM, SMOOTH)
	Kit.deco("PopcornSign", V(3.6, 0.8, 0.2), cf * CFrame.new(0, 6.3, -1.2), GOLD, SMOOTH)
end

-- Farola de feria con bombillas (y de donde cuelgan las guirnaldas)
local function lampPost(cf)
	Kit.cylinder("FairLamp", 9, 0.5, cf * CFrame.new(0, 4.5, 0), RGB(60, 50, 70), Enum.Material.Metal, nil, true)
	Kit.ball("FairLampGlobe", 1.4, cf * CFrame.new(0, 9.4, 0), NEON_BULB, Enum.Material.Neon, true)
	return (cf * CFrame.new(0, 9, 0)).Position
end

-- Noria gigante de fondo (en el plano XY local, mirando hacia el mapa)
local function ferrisWheel(cf, radius)
	local hub = cf * CFrame.new(0, radius + 5, 0)
	-- La rueda gira despacio en el cliente (WorldFX: Orbit); las cabinas siguen derechas
	local axis = hub.LookVector
	local function spin(part, anchor)
		part:SetAttribute("Orbit", 7)
		part:SetAttribute("OrbitCenter", hub.Position)
		part:SetAttribute("OrbitAxis", axis)
		if anchor then
			part:SetAttribute("OrbitUpright", true)
			part:SetAttribute("OrbitAnchor", anchor)
		end
		return part
	end
	for _, z in { -3.5, 3.5 } do
		for _, s in { -1, 1 } do
			local foot = (cf * CFrame.new(s * radius * 0.6, 0, z * 1.6)).Position
			local top = (hub * CFrame.new(0, 0, z)).Position
			Kit.deco("WheelLeg", V(1.2, 1.2, (top - foot).Magnitude), CFrame.lookAt((foot + top) / 2, top), CREAM, SMOOTH)
		end
	end
	Kit.cylinder("WheelHub", 8, 3, hub * CFrame.Angles(rad(90), 0, 0), GOLD, SMOOTH, nil, true)
	local segments = 28
	local segLength = 2 * math.pi * radius / segments + 0.4
	for i = 0, segments - 1 do
		local around = hub * CFrame.Angles(0, 0, i / segments * 2 * math.pi)
		for _, z in { -1.6, 1.6 } do
			spin(Kit.deco("WheelRim", V(segLength, 0.7, 0.7), around * CFrame.new(0, radius, z), i % 2 == 0 and RED or CREAM, SMOOTH))
		end
		if i % 2 == 0 then
			spin(Kit.deco("WheelSpoke", V(0.35, radius, 0.35), around * CFrame.new(0, radius / 2, 0), CREAM, SMOOTH))
			spin(Kit.ball("WheelBulb", 0.7, around * CFrame.new(0, radius + 0.6, 0), NEON_BULB, Enum.Material.Neon, true)).CastShadow = false
		end
		if i % 4 == 0 then
			-- Cabina colgando (siempre derecha)
			local p = (around * CFrame.new(0, radius, 0)).Position
			local cabinColors = { TEAL, PINK, GOLD, PURPLE, RGB(90, 200, 90), RED, RGB(60, 140, 240) }
			local color = cabinColors[(i / 4) % #cabinColors + 1]
			local base = CFrame.new(p) * (cf - cf.Position)
			spin(Kit.deco("WheelCabin", V(4, 2.6, 3.4), base * CFrame.new(0, -2.6, 0), color, SMOOTH), p)
			spin(Kit.deco("WheelCabinRoof", V(4.4, 0.5, 3.8), base * CFrame.new(0, -1.1, 0), CREAM, SMOOTH), p)
			spin(Kit.deco("WheelCabinBar", V(0.3, 1, 0.3), base * CFrame.new(0, -0.5, 0), CREAM, SMOOTH), p)
		end
	end
end

-- Montaña rusa de fondo: vía ondulada sobre pilares, con un vagón
local function rollerCoaster(fromX, toX, z)
	local function height(x)
		return 14 + 9 * math.sin(x / 16) + 4 * math.sin(x / 7)
	end
	local stepX = 6
	local last
	local count = 0
	for x = fromX, toX, stepX do
		local p = V(x, height(x), z)
		if last then
			local mid = (last + p) / 2
			local look = CFrame.lookAt(mid, p)
			local length = (p - last).Magnitude + 0.3
			for _, side in { -1, 1 } do
				Kit.deco("CoasterRail", V(0.4, 0.4, length), look * CFrame.new(side * 1.1, 0, 0), RED, Enum.Material.Metal)
			end
			Kit.deco("CoasterTie", V(2.8, 0.25, 0.6), look * CFrame.new(0, -0.2, 0), RGB(90, 80, 90), SMOOTH)
		end
		count += 1
		if count % 2 == 0 then
			Kit.cylinder("CoasterPillar", p.Y, 0.8, CFrame.new(x, p.Y / 2, z), CREAM, SMOOTH, nil, true)
		end
		last = p
	end
	-- Vagón en una bajada
	local x = fromX + (toX - fromX) * 0.35
	local a, b = V(x, height(x), z), V(x + 3, height(x + 3), z)
	local car = CFrame.lookAt(a, b) * CFrame.new(0, 1.1, 0)
	Kit.deco("CoasterCar", V(2.6, 1.6, 4.6), car, GOLD, SMOOTH)
	Kit.deco("CoasterCarFront", V(2.7, 1.2, 0.5), car * CFrame.new(0, 0.3, -2.3), RED, SMOOTH)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Breeze") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo: césped con paseos de arena (cruz central y anillo alrededor del tiovivo)
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), GRASS, Enum.Material.SmoothPlastic)
	deco("Path", V(LENGTH, 0.1, 14), CFrame.new(0, 0.05, 0), PATH, SMOOTH)
	deco("Path", V(14, 0.1, WIDTH), CFrame.new(0, 0.05, 0), PATH, SMOOTH)
	Kit.cylinder("PathRing", 0.1, 44, CFrame.new(0, 0.06, 0), PATH, SMOOTH, nil, true)
	for _, z in { -1, 1 } do
		deco("Path", V(LENGTH - 30, 0.1, 10), CFrame.new(0, 0.05, z * 38), PATH, SMOOTH)
	end

	carousel(CFrame.new(0, 0, 0))

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(235, 70, 70) or RGB(60, 130, 240)
		-- Casetas de juegos mirando al centro
		booth(m * CFrame.new(-60, 0, 50), RED, "TIRO AL PATO")
		booth(m * CFrame.new(-48, 0, 50), TEAL, "ARO")
		booth(m * CFrame.new(-36, 0, 50), PURPLE, "PREMIOS")
		strengthTester(m * CFrame.new(-22, 0, 52))

		-- Coches de choque (muro bajo) y casa de la risa con azotea
		bumperCars(m * CFrame.new(-30, 0, -28), teamColor, GOLD)
		funhouse(m * CFrame.new(-70, 0, -48), side == "A" and PINK or TEAL)

		-- Cobertura media: cajas, barriles, carrito de globos y palomitas
		balloonCart(m * CFrame.new(-30, 0, 14) * CFrame.Angles(0, rad(20), 0))
		popcornStand(m * CFrame.new(-12, 0, -13) * CFrame.Angles(0, rad(-30), 0))
		Kit.crate(m * CFrame.new(-48, 0, 14), 4, RGB(200, 150, 90))
		Kit.crate(m * CFrame.new(-51, 0, 18), 3.5, RGB(200, 150, 90))
		Kit.crate(m * CFrame.new(-46, 0, -12), 4, RGB(200, 150, 90))
		Kit.barrel(m * CFrame.new(-22, 0, 28), RED)
		Kit.barrel(m * CFrame.new(-24, 0, 30.5), TEAL)
		Kit.barrel(m * CFrame.new(-56, 0, -18), GOLD)
		Kit.crate(m * CFrame.new(-12, 0, 44), 4, RGB(200, 150, 90))

		-- Farolas con guirnaldas de bombillas a lo largo de los paseos
		local a = lampPost(m * CFrame.new(-20, 0, 32))
		local b = lampPost(m * CFrame.new(-52, 0, 32))
		local c = lampPost(m * CFrame.new(-20, 0, -44))
		local d = lampPost(m * CFrame.new(-52, 0, -44))
		Kit.stringLights(a, b, RGB(255, 220, 140))
		Kit.stringLights(c, d, RGB(255, 220, 140))
		Kit.stringLights(a, V(0, 20, 0), RGB(255, 160, 200))

		-- Taquilla junto a la base
		block("TicketBooth", V(5, 5, 5), m * CFrame.new(-78, 2.5, 44), teamColor:Lerp(CREAM, 0.4), SMOOTH)
		deco("TicketWindow", V(3, 1.8, 0.3), m * CFrame.new(-78, 3, 41.4), RGB(255, 240, 200), Enum.Material.Neon)
		stripedCone(m * CFrame.new(-78, 5, 44), 6.5, 3, teamColor, CREAM, 3)

		-- Banderines del equipo
		Kit.banner(m * CFrame.new(-68, 12, 30) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, GOLD)
		Kit.banner(m * CFrame.new(-68, 12, -30) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, GOLD)
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(255, 235, 210), Roof = CREAM }
	Kit.spawnArea(teams[1], CFrame.new(-85, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-85, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-62, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-62, 0, 0))

	-- Fondo: noria, montaña rusa, carpa del circo, pinos y colinas
	Kit.bounds(LENGTH, WIDTH, 60)
	ferrisWheel(CFrame.new(-10, 0, WIDTH / 2 + 26) * CFrame.Angles(0, rad(180), 0), 26)
	rollerCoaster(-110, 110, -(WIDTH / 2 + 24))
	stripedCone(CFrame.new(70, 0, WIDTH / 2 + 34), 34, 22, RED, CREAM, 8)
	stripedCone(CFrame.new(-75, 0, -(WIDTH / 2 + 40)), 26, 16, PURPLE, CREAM, 6)
	local rng = Random.new(31)
	for x = -130, 130, 22 do
		for _, z in { -1, 1 } do
			Kit.cartoonPine(V(x + rng:NextNumber(-6, 6), 0, z * (WIDTH / 2 + 52 + rng:NextNumber(0, 12))), 1.6, true)
		end
	end
	for _, sx in { -1, 1 } do
		for z = -60, 60, 30 do
			Kit.cartoonPine(V(sx * (LENGTH / 2 + 14 + rng:NextNumber(0, 8)), 0, z + rng:NextNumber(-6, 6)), 1.5, true)
		end
		for z = -80, 80, 55 do
			Kit.naturalHill(V(sx * 165, -16, z), 42, Enum.Material.Grass, { Inward = V(-sx, 0, 0), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end
	for x = -200, 200, 60 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -16, z * 160), 42, Enum.Material.Grass, { Inward = V(0, 0, -z), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end

	-- Modos
	for _, p in {
		V(-76, 0.5, 8), V(-76, 0.5, -16), V(-54, 0.5, 6), V(-40, 0.5, 22), V(-26, 0.5, 40),
		V(-30, 0.5, -28), V(-14, 0.5, -36), V(-70, 9.5, -48), V(-8, 1.5, 12), V(-40, 0.5, -56),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 1, 0), 6, 1)
	Kit.zone(V(-30, 0, -28), 6, 2)
	Kit.zone(V(30, 0, 28), 6, 3)
	Kit.zone(V(-70, 9, -48), 5, 4)
	Kit.zone(V(70, 9, 48), 5, 5)
	Kit.dustMotes(CFrame.new(0, 6, 0), V(140, 10, 90), Color3.fromRGB(255, 220, 180), 8)
	return folder
end

return Map
