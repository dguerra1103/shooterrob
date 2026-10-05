-- BASE LUNAR: base espacial de dibujos animados en la Luna, de noche con la Tierra enorme en el
-- cielo. En el centro, un cohete en su plataforma de lanzamiento con una pasarela a media altura;
-- cúpulas de los módulos, paneles solares, un rover, cajas de carga y cráteres. Plataformas con
-- propulsores (plataformas de salto) a los lados. Simétrico (rojo contra azul).
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "MoonBase",
	Name = "Base Lunar",
	Icon = "🚀",
	Description = "Espacio · cohete central · cúpulas y cráteres · gravedad lunar",
	Gravity = 120, -- (la normal es 196.2): saltos más altos y lentos
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.62, Sat = 0.1 }, -- grises lunares algo azulados
	ClockTime = 23.5,
	Brightness = 1.6,
	Exposure = 0.35,
	Ambient = Color3.fromRGB(80, 85, 115),
	OutdoorAmbient = Color3.fromRGB(120, 125, 160),
	Atmosphere = { Density = 0.12, Offset = 0, Color = Color3.fromRGB(70, 80, 130), Decay = Color3.fromRGB(30, 30, 70), Glare = 0, Haze = 0 },
	Color = { Saturation = 0.25, Contrast = 0.12, Brightness = 0.04, Tint = Color3.fromRGB(240, 245, 255) },
	Bloom = { Intensity = 0.8, Size = 24, Threshold = 1.5 },
	Clouds = 0,
	SunRays = 0,
	Stars = 6000,
	MoonSize = 0.1, -- (estamos en la Luna: la que se ve es la Tierra)
	ShadowSoftness = 0.15,
	Wind = Vector3.new(0, 0, 0),
	TerrainColors = {
		Rock = Color3.fromRGB(150, 150, 165),
		Basalt = Color3.fromRGB(120, 120, 135),
		Slate = Color3.fromRGB(135, 135, 150),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local MOON = RGB(185, 185, 198) -- suelo lunar
local MOON_DARK = RGB(150, 150, 165)
local HULL = RGB(240, 242, 248) -- blanco de las naves y módulos
local TRIM = RGB(255, 170, 40)
local GLOW = RGB(90, 220, 255)
local PANEL = RGB(40, 70, 160)

local LENGTH, WIDTH = 200, 130

-- Cráter: anillo de borde y fondo un poco más oscuro (decoración plana, se puede pisar)
local function crater(position, size)
	Kit.cylinder("CraterRim", 0.5, size, CFrame.new(position + V(0, 0.15, 0)), MOON:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("Crater", 0.55, size * 0.8, CFrame.new(position + V(0, 0.18, 0)), MOON_DARK, Enum.Material.SmoothPlastic, nil, true)
end

-- Cúpula de un módulo habitable (media esfera sólida) con anillo, puerta y ventanas iluminadas
local function dome(cf, size, accent)
	Kit.ball("Dome", size, cf, HULL, Enum.Material.SmoothPlastic)
	Kit.cylinder("DomeRing", 1.2, size + 0.8, cf * CFrame.new(0, 0.6, 0), accent, Enum.Material.SmoothPlastic, nil, true)
	Kit.block("DomeDoor", V(4, 6, 2.5), cf * CFrame.new(0, 3, -size / 2 + 1), RGB(70, 75, 95), Enum.Material.SmoothPlastic)
	Kit.deco("DomeDoorGlow", V(4.4, 0.4, 2.7), cf * CFrame.new(0, 6.2, -size / 2 + 1), GLOW, Enum.Material.Neon)
	for _, angle in { -50, 50, 140, 220 } do
		local window = cf * CFrame.Angles(0, rad(angle), 0) * CFrame.new(0, size * 0.22, -size * 0.43) * CFrame.Angles(rad(-25), 0, 0)
		Kit.deco("DomeWindow", V(2.2, 1.4, 0.3), window, GLOW, Enum.Material.Neon)
	end
end

-- Panel solar inclinado sobre un poste (cobertura baja)
local function solarPanel(cf)
	Kit.block("SolarPost", V(0.8, 3, 0.8), cf * CFrame.new(0, 1.5, 0), RGB(160, 165, 180), Enum.Material.SmoothPlastic)
	local panel = cf * CFrame.new(0, 3.4, 0) * CFrame.Angles(rad(30), 0, 0)
	Kit.block("SolarPanel", V(9, 0.4, 5), panel, PANEL, Enum.Material.SmoothPlastic)
	for i = -1, 1 do
		Kit.deco("SolarCellLine", V(0.12, 0.42, 5), panel * CFrame.new(i * 3, 0, 0), RGB(200, 210, 230), Enum.Material.SmoothPlastic)
	end
	Kit.deco("SolarCellLine", V(9, 0.42, 0.12), panel, RGB(200, 210, 230), Enum.Material.SmoothPlastic)
end

-- Rover lunar (cobertura): carrocería, cabina, seis ruedas y antena
local function rover(cf, color)
	Kit.block("RoverBody", V(10, 2.2, 5.5), cf * CFrame.new(0, 2.4, 0), HULL, Enum.Material.SmoothPlastic)
	Kit.block("RoverCab", V(4, 2.4, 4.6), cf * CFrame.new(-2.5, 4.7, 0), color, Enum.Material.SmoothPlastic)
	Kit.deco("RoverWindow", V(0.3, 1.4, 3.6), cf * CFrame.new(-4.55, 4.9, 0), GLOW, Enum.Material.Neon)
	for _, x in { -3.6, 0, 3.6 } do
		for _, z in { -1, 1 } do
			Kit.cylinder("RoverWheel", 1, 2.6, cf * CFrame.new(x, 1.3, z * 3.1) * CFrame.Angles(rad(90), 0, 0), RGB(50, 52, 62), Enum.Material.SmoothPlastic, nil, true)
		end
	end
	Kit.cylinder("RoverAntenna", 3, 0.2, cf * CFrame.new(3, 5, 1.5), RGB(200, 200, 210), Enum.Material.SmoothPlastic, nil, true)
	Kit.ball("RoverAntennaTip", 0.6, cf * CFrame.new(3, 6.6, 1.5), TRIM, Enum.Material.Neon, true)
end

-- Antena parabólica (decoración de fondo)
local function dish(cf, scale)
	Kit.cylinder("DishPost", 8 * scale, 1.2 * scale, cf * CFrame.new(0, 4 * scale, 0), RGB(170, 175, 190), Enum.Material.SmoothPlastic, nil, true)
	local head = cf * CFrame.new(0, 8.5 * scale, 0) * CFrame.Angles(rad(-35), 0, 0)
	Kit.cylinder("Dish", 0.8 * scale, 9 * scale, head * CFrame.Angles(rad(90), 0, 0), HULL, Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("DishFeed", 3 * scale, 0.3 * scale, head * CFrame.new(0, 0, -1.6 * scale) * CFrame.Angles(rad(90), 0, 0), RGB(170, 175, 190), Enum.Material.SmoothPlastic, nil, true)
	Kit.ball("DishLight", 0.8 * scale, head * CFrame.new(0, 0, -3.2 * scale), RGB(255, 80, 80), Enum.Material.Neon, true)
end

-- Cohete en el centro (decoración salvo la plataforma): cuerpo blanco con franjas, alerones y punta
local function rocket(base)
	local height = 34
	Kit.cylinder("RocketBody", height, 7, base * CFrame.new(0, height / 2 + 2, 0), HULL, Enum.Material.SmoothPlastic, nil, true)
	for _, y in { 8, 20, 30 } do
		Kit.cylinder("RocketStripe", 1.4, 7.15, base * CFrame.new(0, y, 0), RGB(230, 60, 60), Enum.Material.SmoothPlastic, nil, true)
	end
	Kit.cylinder("RocketWindowRing", 0.3, 3, base * CFrame.new(0, 25, -3.45) * CFrame.Angles(rad(90), 0, 0), TRIM, Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("RocketWindow", 0.35, 2.3, base * CFrame.new(0, 25, -3.5) * CFrame.Angles(rad(90), 0, 0), GLOW, Enum.Material.Neon, nil, true)
	Kit.cylinder("RocketNoseBase", 4, 6, base * CFrame.new(0, height + 4, 0), RGB(230, 60, 60), Enum.Material.SmoothPlastic, nil, true)
	Kit.ball("RocketNose", 5.4, base * CFrame.new(0, height + 6.6, 0), RGB(230, 60, 60), Enum.Material.SmoothPlastic, true)
	for i = 0, 3 do
		local fin = base * CFrame.Angles(0, rad(45 + i * 90), 0) * CFrame.new(0, 5, -4.6)
		Kit.deco("RocketFin", V(0.8, 8, 4), fin * CFrame.Angles(rad(-12), 0, 0), RGB(230, 60, 60), Enum.Material.SmoothPlastic)
	end
	Kit.cylinder("RocketEngine", 2, 5, base * CFrame.new(0, 1.6, 0), RGB(80, 85, 100), Enum.Material.SmoothPlastic, nil, true)
end

-- La Tierra en el cielo: esfera azul con continentes verdes
local function earth(position, size)
	Kit.ball("Earth", size, CFrame.new(position), RGB(60, 130, 230), Enum.Material.SmoothPlastic, true)
	local rng = Random.new(7)
	for _ = 1, 9 do
		local dir = V(rng:NextNumber(-1, 1), rng:NextNumber(-0.6, 1), rng:NextNumber(0.2, 1)).Unit
		local patch = rng:NextNumber(0.22, 0.38) * size
		Kit.ball("EarthLand", patch, CFrame.new(position + dir * (size / 2 - patch * 0.42)), RGB(90, 190, 90), Enum.Material.SmoothPlastic, true)
	end

end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo lunar con cráteres
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), MOON, Enum.Material.SmoothPlastic)
	for _, c in { { V(-30, 0, 34), 12 }, { V(-60, 0, -20), 9 }, { V(-14, 0, -46), 10 }, { V(-78, 0, 50), 8 } } do
		crater(c[1], c[2])
		crater(Kit.MIRROR * c[1], c[2])
	end
	crater(V(0, 0, 50), 7)
	crater(V(0, 0, -50), 7)

	-- Plataforma de lanzamiento: base octogonal alta (cobertura) y pasarela alrededor del cohete
	local deckY = 8
	Kit.cylinder("LaunchPad", 2, 26, CFrame.new(0, 1, 0), RGB(120, 125, 145), Enum.Material.SmoothPlastic)
	Kit.cylinder("LaunchPadStripe", 2.05, 22, CFrame.new(0, 1.02, 0), TRIM, Enum.Material.SmoothPlastic, nil, true)
	rocket(CFrame.new(0, 2, 0))
	-- Pasarela (gantry) en forma de anillo cuadrado con barandillas
	for _, s in { -1, 1 } do
		block("Gantry", V(22, 1, 5), CFrame.new(0, deckY - 0.5, s * 8.5), RGB(150, 155, 175), Enum.Material.Metal)
		block("Gantry", V(5, 1, 12), CFrame.new(s * 8.5, deckY - 0.5, 0), RGB(150, 155, 175), Enum.Material.Metal)
		deco("GantryGlow", V(22, 0.2, 0.3), CFrame.new(0, deckY + 0.05, s * 10.9), GLOW, Enum.Material.Neon)
		for _, x in { -10, 10 } do
			block("GantryPillar", V(1.2, deckY - 1, 1.2), CFrame.new(x, (deckY - 1) / 2, s * 10), RGB(120, 125, 145), Enum.Material.Metal)
		end
		Kit.railing(V(-11, deckY, s * 11), V(11, deckY, s * 11), 2.5, RGB(220, 220, 230))
	end

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(235, 70, 70) or RGB(60, 130, 240)
		-- Rampa a la pasarela
		Kit.stairs((m * CFrame.new(-30, 0, 0)).Position, (m * CFrame.new(-11, deckY, 0)).Position, 5, RGB(150, 155, 175), Enum.Material.Metal)

		-- Cúpulas de los módulos (cobertura grande)
		dome(m * CFrame.new(-50, 0, 32) * CFrame.Angles(0, rad(200), 0), 18, teamColor)
		dome(m * CFrame.new(-34, 0, -38) * CFrame.Angles(0, rad(-20), 0), 14, teamColor)

		-- Plataforma elevada con propulsor (plataforma de salto) para subir
		local platY = 9
		block("LandingPlatform", V(18, 1.2, 12), m * CFrame.new(-60, platY - 0.6, -(WIDTH / 2 - 10)), RGB(170, 175, 195), Enum.Material.Metal)
		deco("LandingGlow", V(18.4, 0.3, 0.3), m * CFrame.new(-60, platY, -(WIDTH / 2 - 16.2)), teamColor, Enum.Material.Neon)
		for _, x in { -67, -53 } do
			for _, z in { -(WIDTH / 2 - 5), -(WIDTH / 2 - 15) } do
				block("LandingLeg", V(1.2, platY - 1.2, 1.2), m * CFrame.new(x, (platY - 1.2) / 2, z), RGB(120, 125, 145), Enum.Material.Metal)
			end
		end
		Kit.jumpPad((m * CFrame.new(-60, 0, -(WIDTH / 2 - 26))).Position, 72, teamColor)

		-- Paneles solares (cobertura baja)
		solarPanel(m * CFrame.new(-22, 0, 22) * CFrame.Angles(0, rad(90), 0))
		solarPanel(m * CFrame.new(-22, 0, 34) * CFrame.Angles(0, rad(90), 0))
		solarPanel(m * CFrame.new(-74, 0, -6) * CFrame.Angles(0, rad(15), 0))

		-- Rover y cajas de carga
		rover(m * CFrame.new(-42, 0, 4) * CFrame.Angles(0, rad(-10), 0), teamColor)
		Kit.metalCrate(m * CFrame.new(-16, 0, -18), 5, HULL, GLOW)
		Kit.metalCrate(m * CFrame.new(-20, 0, -24), 4, TRIM, GLOW)
		Kit.metalCrate(m * CFrame.new(-66, 0, 22), 5, HULL, teamColor)
		Kit.metalCrate(m * CFrame.new(-28, 0, 52), 4, HULL, GLOW)
		Kit.metalCrate(m * CFrame.new(-23, 0, 53), 4, TRIM, GLOW)

		-- Rocas lunares (cobertura natural de terreno)
		Kit.rockCluster((m * CFrame.new(-48, 0, -52)).Position, 3.5, Enum.Material.Basalt)
		Kit.rockCluster((m * CFrame.new(-10, 0, 28)).Position, 3, Enum.Material.Basalt)
		Kit.rockCluster((m * CFrame.new(-82, 0, -44)).Position, 3, Enum.Material.Basalt)

		-- Bandera de su "país" plantada (decoración)
		Kit.cylinder("FlagPole", 9, 0.3, m * CFrame.new(-80, 4.5, 30), RGB(220, 220, 230), Enum.Material.SmoothPlastic, nil, true)
		deco("PlantedFlag", V(0.2, 3, 5), m * CFrame.new(-80, 7.4, 32.6), teamColor, Enum.Material.SmoothPlastic)

		-- Muro bajo del módulo de aterrizaje (protege la salida de la base)
		block("BaseWall", V(2, 4, 16), m * CFrame.new(-72, 2, 18), HULL, Enum.Material.SmoothPlastic)
		deco("BaseWallGlow", V(2.2, 0.3, 16.2), m * CFrame.new(-72, 4.1, 18), teamColor, Enum.Material.Neon)
		block("BaseWall", V(2, 4, 16), m * CFrame.new(-72, 2, -26), HULL, Enum.Material.SmoothPlastic)
		deco("BaseWallGlow", V(2.2, 0.3, 16.2), m * CFrame.new(-72, 4.1, -26), teamColor, Enum.Material.Neon)
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(225, 228, 238), Roof = HULL }
	Kit.spawnArea(teams[1], CFrame.new(-85, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-85, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-62, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-62, 0, 0))

	-- Fondo: colinas de roca lunar, antenas y la Tierra
	Kit.bounds(LENGTH, WIDTH, 60)
	-- Nombres de las zonas
	Kit.callout("COHETE", CFrame.new(0, 10, 0), V(28, 30, 28))
	for _, m in { CFrame.new(), Kit.MIRROR } do
		Kit.callout("CÚPULA GRANDE", m * CFrame.new(-50, 8, 32), V(22, 20, 22))
		Kit.callout("CÚPULA PEQUEÑA", m * CFrame.new(-34, 8, -38), V(18, 18, 18))
		Kit.callout("ATERRIZAJE", m * CFrame.new(-60, 8, -(WIDTH / 2 - 10)), V(22, 20, 16))
	end
	for x = -200, 200, 60 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -16, z * 140), 42, Enum.Material.Rock, { Inward = V(0, 0, -z), Top = Enum.Material.Basalt, RockCount = 2 })
		end
	end
	for _, sx in { -1, 1 } do
		for z = -80, 80, 55 do
			Kit.naturalHill(V(sx * 160, -16, z), 42, Enum.Material.Rock, { Inward = V(-sx, 0, 0), Top = Enum.Material.Basalt, RockCount = 2 })
		end
	end
	dish(CFrame.new(-30, 0, WIDTH / 2 + 22) * CFrame.Angles(0, rad(160), 0), 1.4)
	dish(CFrame.new(30, 0, -(WIDTH / 2 + 22)) * CFrame.Angles(0, rad(-20), 0), 1.4)
	earth(V(-60, 150, -380), 110)

	-- Modos
	for _, p in {
		V(-76, 0.5, 8), V(-76, 0.5, -16), V(-50, 0.5, 10), V(-40, 0.5, -20), V(-24, 0.5, 40),
		V(-16, 0.5, -34), V(-30, 0.5, 18), V(-60, 9.5, -(WIDTH / 2 - 10)), V(-6, deckY + 0.5, 8), V(-84, 0.5, 44),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, deckY, 8.5), 4, 1)
	Kit.zone(V(-40, 0, -14), 6, 2)
	Kit.zone(V(40, 0, 14), 6, 3)
	Kit.zone(V(-60, 9, -(WIDTH / 2 - 10)), 5, 4)
	Kit.zone(V(60, 9, WIDTH / 2 - 10), 5, 5)
	Kit.dustMotes(CFrame.new(0, 6, 0), V(140, 10, 90), Color3.fromRGB(200, 220, 255), 10)
	return folder
end

return Map
