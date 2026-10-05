-- FROST STATION: base de investigación polar. Lago helado resbaladizo en el centro bajo la torre
-- del radar, hangares con techo naranja, laboratorios sobre pilotes, montículos de nieve como
-- cobertura, montañas nevadas de fondo y nieve cayendo.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)
local Variants = require(script.Parent.Parent.LightingVariants)

local Map = {
	Id = "FrostStation",
	Name = "Frost Station",
	Icon = "❄",
	Description = "Polar · tarde · lago helado y nieve",
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.57, Sat = 0.16 }, -- tono de los grises en estilo Cartoon
	ClockTime = 15.6,
	Latitude = 70, -- sol bajo: sombras largas y azules sobre la nieve
	Brightness = 2.4,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(75, 85, 105),
	OutdoorAmbient = Color3.fromRGB(130, 145, 170),
	Atmosphere = { Density = 0.4, Offset = 0.15, Color = Color3.fromRGB(210, 225, 245), Decay = Color3.fromRGB(140, 160, 205), Glare = 0.45, Haze = 2.2 },
	Color = { Saturation = 0.05, Contrast = 0.15, Brightness = 0.02, Tint = Color3.fromRGB(235, 243, 255) },
	Bloom = { Intensity = 0.5, Size = 24, Threshold = 2 },
	Clouds = 0.8,
	CloudColor = Color3.fromRGB(228, 234, 245),
	SunRays = 0.12,
	Wind = Vector3.new(8, 0, 3), -- viento polar: la nieve cae en diagonal y las nubes corren
	TerrainColors = {
		Snow = Color3.fromRGB(232, 238, 248),
		Glacier = Color3.fromRGB(150, 200, 235),
		Rock = Color3.fromRGB(95, 105, 120),
	},
}
-- A veces sale con otra luz o con mal tiempo (ver LightingVariants)
Map.LightingVariants = { Variants.Blizzard(0.3) }

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local C = Kit.C

local SNOW = RGB(236, 242, 250)
local ICE = RGB(165, 215, 245)
local RED = RGB(215, 70, 50)
local ORANGE = RGB(255, 140, 40)
local WALL = RGB(196, 202, 212)
local DARK = RGB(60, 66, 78)

-- Pino nevado: tronco y siete pisos redondos de ramas, cada vez más estrechos y muy juntos para
-- que la silueta sea un cono; nieve sobre pisos alternos y verdes algo distintos
-- `far` = pino de fondo: cuatro pisos más altos en vez de siete (la silueta lejana es la misma)
local function pine(position, scale, far)
	scale = scale or 1
	local cylinder = Kit.cylinder
	cylinder("PineTrunk", 5 * scale, 1.1 * scale, CFrame.new(position + V(0, 2.5 * scale, 0)), RGB(88, 62, 44), Enum.Material.Wood)
	local tiers = far and 4 or 7
	local step = 6 / (tiers - 1)
	for i = 1, tiers do
		local d = (10 - (i - 1) * 8.1 / (tiers - 1)) * scale
		local y = (3 + (i - 1) * 1.65 * step) * scale
		local green = RGB(34, 74, 52):Lerp(RGB(50, 98, 66), (i % 2) * 0.6)
		local height = (1.65 * step + 0.55) * scale -- los pisos se solapan un poco, sin huecos
		local branches = cylinder("PineTier", height, d, CFrame.new(position + V(0, y, 0)), green, Enum.Material.LeafyGrass, nil, true)
		branches.CastShadow = not far
		if far or i % 2 == 1 then
			cylinder("PineSnow", 0.4 * scale, d * 0.78, CFrame.new(position + V(0, y + height / 2, 0)), SNOW, Enum.Material.Snow, nil, true)
		end
	end
	cylinder("PineTip", 1.8 * scale, 0.9 * scale, CFrame.new(position + V(0, 14.2 * scale, 0)), RGB(40, 84, 58), Enum.Material.LeafyGrass, nil, true)
end

-- Montículo de nieve (terreno) que sirve de cobertura
local function snowMound(position, radius)
	workspace.Terrain:FillBall(position, radius, Enum.Material.Snow)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Snow") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Kit.pickLighting(Map))
	folder:SetAttribute("Variant", Kit.Variant)
	folder:SetAttribute("Weather", Kit.Weather)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo nevado con huellas de vehículos
	block("Floor", V(340, 2, 240), CFrame.new(0, -1, 0), SNOW, Enum.Material.Snow)
	for _, z in { -62, 62 } do
		for _, dz in { -2.5, 2.5 } do
			deco("Tracks", V(200, 0.05, 1.2), CFrame.new(0, 0.03, z + dz), RGB(205, 215, 230), Enum.Material.Snow)
		end
	end

	-- Lago helado en el centro: ¡resbala!
	local lake = Kit.cylinder("FrozenLake", 0.3, 54, CFrame.new(0, 0.15, 0), ICE, Enum.Material.Ice)
	lake.CustomPhysicalProperties = PhysicalProperties.new(0.9, 0.02, 0.05, 100, 1)
	lake.Reflectance = 0.22 -- hielo pulido: refleja el cielo
	Kit.cylinder("LakeRim", 0.2, 57, CFrame.new(0, 0.1, 0), RGB(215, 228, 242), Enum.Material.Glacier, nil, true)
	for i = 1, 6 do
		local angle = i * math.pi / 3
		deco("IceCrack", V(0.15, 0.05, 10 + i), CFrame.new(math.cos(angle) * 14, 0.31, math.sin(angle) * 14) * CFrame.Angles(0, angle + 0.6, 0), RGB(235, 248, 255), Enum.Material.Neon).Transparency = 0.5
	end

	-- Torre del radar: plataforma elevada con cúpula y antena giratoria
	block("TowerDeck", V(24, 1.2, 24), CFrame.new(0, 9, 0), DARK, Enum.Material.DiamondPlate)
	deco("TowerDeckEdge", V(24.4, 0.4, 24.4), CFrame.new(0, 8.3, 0), ORANGE, Enum.Material.Neon)
	for _, x in { -10, 10 } do
		for _, z in { -10, 10 } do
			block("TowerLeg", V(2, 8.4, 2), CFrame.new(x, 4.2, z), RGB(80, 86, 98), Enum.Material.Metal)
		end
	end
	local dome = Kit.ball("RadarDome", 8, CFrame.new(0, 13.4, 0), RGB(245, 247, 252), Enum.Material.SmoothPlastic)
	dome.CastShadow = true
	Kit.cylinder("DomeBase", 1.4, 9, CFrame.new(0, 10.3, 0), RGB(200, 205, 215), Enum.Material.Metal)
	Kit.cylinder("RadarMast", 5, 0.8, CFrame.new(0, 19.6, 0), RGB(90, 95, 105), Enum.Material.Metal, nil, true)
	local dish = deco("RadarDish", V(0.5, 7, 7), CFrame.new(0, 22.5, 0) * CFrame.Angles(0, 0, rad(-20)), RGB(235, 238, 245), Enum.Material.Metal)
	dish.Shape = Enum.PartType.Cylinder
	dish:SetAttribute("Spin", 45)
	local beacon = Kit.ball("RadarBeacon", 1, CFrame.new(0, 26.4, 0), RGB(255, 40, 40), Enum.Material.Neon, true)
	beacon:SetAttribute("Blink", 1.2)
	Kit.light(beacon, "PointLight", RGB(255, 60, 60), 18, 2)
	local deckLight = deco("TowerLight", V(18, 0.2, 18), CFrame.new(0, 8.35, 0), RGB(255, 230, 190), Enum.Material.Neon)
	Kit.light(deckLight, "SurfaceLight", RGB(255, 220, 170), 14, 1, Enum.NormalId.Bottom)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(255, 60, 80) or RGB(60, 140, 255)

		-- Escaleras de la torre y barandillas (con hueco donde llegan)
		Kit.stairs(m * V(-31, 0, -6), m * V(-12.5, 9.6, -6), 6, RGB(120, 125, 138), Enum.Material.DiamondPlate)
		Kit.railing(m * V(-12, 9.6, 12), m * V(12, 9.6, 12), 3, ORANGE)
		Kit.railing(m * V(-12, 9.6, -12), m * V(-12, 9.6, -9.5), 3, ORANGE)
		Kit.railing(m * V(-12, 9.6, -2.5), m * V(-12, 9.6, 12), 3, ORANGE)

		-- Hangar: lo atraviesa el carril norte, con techo naranja
		local hz = -62
		block("HangarBack", V(44, 14, 2), m * CFrame.new(-70, 7, hz - 15), WALL, Enum.Material.CorrodedMetal)
		block("HangarFrontA", V(16, 14, 2), m * CFrame.new(-84, 7, hz + 15), WALL, Enum.Material.CorrodedMetal)
		block("HangarFrontB", V(16, 14, 2), m * CFrame.new(-56, 7, hz + 15), WALL, Enum.Material.CorrodedMetal)
		block("HangarLintel", V(12, 4, 2), m * CFrame.new(-70, 12, hz + 15), WALL, Enum.Material.CorrodedMetal)
		block("HangarRoof", V(46, 1.5, 34), m * CFrame.new(-70, 14.75, hz), RED, Enum.Material.Metal)
		deco("HangarRoofSnow", V(44, 0.4, 30), m * CFrame.new(-70, 15.7, hz), SNOW, Enum.Material.Snow)
		for _, x in { -91, -49 } do
			deco("HangarStripe", V(2.2, 1, 34.2), m * CFrame.new(x, 13.6, hz), C.Yellow, Enum.Material.SmoothPlastic)
		end
		Kit.neonSign(m * CFrame.new(-70, 12, hz + 16.4) * CFrame.Angles(0, math.pi, 0), 10, 3, side == "A" and "HANGAR A" or "HANGAR B", teamColor, C.White)
		for _, x in { -82, -70, -58 } do
			local lamp = deco("HangarLamp", V(3, 0.3, 3), m * CFrame.new(x, 13.8, hz), RGB(255, 235, 200), Enum.Material.Neon)
			Kit.lightCone((m * CFrame.new(x, 13.6, hz)).Position, 12, 1.4, 5.5, RGB(255, 230, 190))
			Kit.light(lamp, "SpotLight", RGB(255, 225, 180), 22, 1.6, Enum.NormalId.Bottom).Angle = 110
		end
		-- Moto de nieve (snowcat) y cajas dentro del hangar
		block("SnowcatBody", V(8, 3.5, 5), m * CFrame.new(-64, 2.6, hz - 5), ORANGE, Enum.Material.SmoothPlastic)
		local cab = block("SnowcatCab", V(4, 3, 4.6), m * CFrame.new(-65.5, 5.8, hz - 5), RGB(120, 170, 220), Enum.Material.Glass)
		cab.Transparency = 0.3
		for _, dz in { -2.8, 2.8 } do
			block("SnowcatTrack", V(9, 1.6, 1.3), m * CFrame.new(-64, 0.8, hz - 5 + dz), RGB(30, 30, 34), Enum.Material.Rubber)
		end
		Kit.metalCrate(m * CFrame.new(-84, 0, hz - 8), 5, RGB(90, 96, 110), teamColor)
		Kit.metalCrate(m * CFrame.new(-84, 0, hz - 2.8), 5, RGB(90, 96, 110), teamColor)
		Kit.metalCrate(m * CFrame.new(-84, 5, hz - 5.4), 4, RGB(90, 96, 110), ORANGE)
		Kit.metalCrate(m * CFrame.new(-54, 0, hz + 8), 4, RGB(90, 96, 110), C.Cyan)

		-- Laboratorio sobre pilotes con terraza (puesto de tirador)
		local lab = m * CFrame.new(-72, 0, 45)
		block("LabDeck", V(26, 1, 20), lab * CFrame.new(0, 8, 0), DARK, Enum.Material.DiamondPlate)
		for _, x in { -12, 12 } do
			for _, z in { -9, 9 } do
				block("LabPile", V(1.5, 7.5, 1.5), lab * CFrame.new(x, 3.75, z), RGB(80, 86, 98), Enum.Material.Metal)
			end
		end
		block("LabCabin", V(16, 8, 10), lab * CFrame.new(-2, 12.5, 0), RED, Enum.Material.SmoothPlastic)
		block("LabRoof", V(17, 0.8, 11), lab * CFrame.new(-2, 16.9, 0), SNOW, Enum.Material.Snow)
		for _, z in { -5.1, 5.1 } do
			for _, x in { -7, -2, 3 } do
				local win = deco("LabWindow", V(3, 2.2, 0.2), lab * CFrame.new(x, 13.5, z), RGB(255, 225, 150), Enum.Material.Neon)
				win.Transparency = 0.2
			end
		end
		deco("LabStripe", V(16.2, 0.6, 10.2), lab * CFrame.new(-2, 9.2, 0), C.White, Enum.Material.SmoothPlastic)
		Kit.stairs(m * V(-46, 0, 50), m * V(-59.5, 8.5, 50), 5, RGB(120, 125, 138), Enum.Material.DiamondPlate)
		Kit.railing(lab * V(-13, 8.5, -10), lab * V(13, 8.5, -10), 3, teamColor)
		Kit.railing(lab * V(-13, 8.5, 10), lab * V(13, 8.5, 10), 3, teamColor)
		Kit.railing(lab * V(-13, 8.5, -10), lab * V(-13, 8.5, 10), 3, teamColor)
		Kit.railing(lab * V(13, 8.5, -10), lab * V(13, 8.5, 2.5), 3, teamColor)
		local dishPole = Kit.cylinder("LabAntenna", 6, 0.5, lab * CFrame.new(4, 20, 0), RGB(150, 155, 165), Enum.Material.Metal, nil, true)
		local labBeacon = Kit.ball("LabBeacon", 0.7, lab * CFrame.new(4, 23.3, 0), teamColor, Enum.Material.Neon, true)
		labBeacon:SetAttribute("Blink", 0.9)
		dishPole.CastShadow = true

		-- Depósitos de combustible
		for _, z in { -60, -76 } do
			Kit.cylinder("FuelTank", 10, 7, m * CFrame.new(-120, 5, z), RGB(240, 242, 246), Enum.Material.Metal)
			Kit.cylinder("FuelBand", 1.2, 7.3, m * CFrame.new(-120, 7, z), RED, Enum.Material.SmoothPlastic, nil, true)
			Kit.cylinder("FuelCap", 0.8, 5, m * CFrame.new(-120, 10.4, z), SNOW, Enum.Material.Snow, nil, true)
		end
		Kit.pipeRun(m * V(-116, 2, -68), m * V(-93, 2, -68), 1.2, RGB(150, 155, 165))

		-- Contenedores de suministros y cobertura
		Kit.container(m * CFrame.new(-36, 0, 74), RED, "POLAR-1")
		Kit.container(m * CFrame.new(-98, 0, -28) * CFrame.Angles(0, rad(90), 0), RGB(45, 110, 200), "SUMINISTROS")
		Kit.barrier(V(2, 4, 14), m * CFrame.new(-24, 0, -30))
		Kit.barrier(V(14, 4, 2), m * CFrame.new(-50, 0, -30))
		Kit.barrier(V(2, 4, 12), m * CFrame.new(-34, 0, 18))
		Kit.metalCrate(m * CFrame.new(-60, 0, 2), 5, RGB(90, 96, 110), ORANGE)
		Kit.metalCrate(m * CFrame.new(-60, 0, 7.2), 5, RGB(90, 96, 110), ORANGE)
		Kit.metalCrate(m * CFrame.new(-92, 0, 62), 5, RGB(90, 96, 110), teamColor)

		-- Montículos de nieve (terreno)
		-- Montículos de unos 4,5 studs de alto: tapan a un jugador agachado o deslizándose
		snowMound(m * V(-42, -1.5, 26), 6)
		snowMound(m * V(-28, -2.5, -48), 7)
		snowMound(m * V(-108, -1.5, -2), 6)
		snowMound(m * V(-115, -1.5, 46), 5.5)
		snowMound(m * V(-20, -2.5, 82), 7)

		-- Coches aparcados cubiertos de nieve
		Kit.car(m * CFrame.new(-130, 0, -62) * CFrame.Angles(0, rad(8), 0), RGB(40, 70, 110), { Snow = true })
		Kit.car(m * CFrame.new(-80, 0, 88) * CFrame.Angles(0, rad(175), 0), RGB(150, 40, 35), { Snow = true })

		-- Rocas que asoman entre la nieve
		Kit.rockCluster(m * V(-150, 0, -70), 4, Enum.Material.Rock)
		Kit.rockCluster(m * V(-75, 0, 104), 4.5, Enum.Material.Slate)
		Kit.rockCluster(m * V(-135, 0, -104), 4, Enum.Material.Rock)
		Kit.rockCluster(m * V(-40, 0, -104), 5, Enum.Material.Slate)

		-- Antena de comunicaciones con baliza
		local mast = m * CFrame.new(-128, 0, 88)
		Kit.cylinder("CommsMast", 32, 1, mast * CFrame.new(0, 16, 0), RGB(200, 70, 55), Enum.Material.Metal)
		for i = 1, 4 do
			deco("CommsBar", V(5, 0.3, 0.3), mast * CFrame.new(0, i * 7, 0) * CFrame.Angles(0, rad(i * 45), 0), RGB(230, 230, 235), Enum.Material.Metal)
		end
		local top = Kit.ball("CommsBeacon", 1.2, mast * CFrame.new(0, 32.6, 0), RGB(255, 40, 40), Enum.Material.Neon, true)
		top:SetAttribute("Blink", 1.5)

		-- Farolas naranjas
		for _, p in { V(-92, 0, 22), V(-40, 0, -42), V(-24, 0, 44), V(-110, 0, -40) } do
			Kit.streetLamp(m * CFrame.new(p) * CFrame.Angles(0, rad(90), 0), RGB(255, 190, 110))
		end

		-- Pinos en los bordes
		for _, p in { V(-140, 0, 96), V(-100, 0, 100), V(-60, 0, 98), V(-150, 0, -96), V(-88, 0, -98), V(-18, 0, -100) } do
			pine(m * p, 1 + (math.abs(p.X) % 3) * 0.15)
		end
	end)

	-- Nieve cayendo sobre todo el mapa
	local sky = deco("Snowfall", V(330, 1, 230), CFrame.new(0, 56, 0), SNOW, Enum.Material.SmoothPlastic)
	sky.Transparency = 1
	sky.CastShadow = false
	local snow = Instance.new("ParticleEmitter")
	snow.Name = "Snow"
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.LightEmission = 0.3
	snow.Size = NumberSequence.new(0.22)
	snow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.85, 0.2), NumberSequenceKeypoint.new(1, 1) })
	snow.Lifetime = NumberRange.new(7, 9)
	snow.Speed = NumberRange.new(6, 9)
	snow.SpreadAngle = Vector2.new(15, 15)
	snow.Acceleration = V(0.4, 0, 0.2)
	snow.WindAffectsDrag = true
	snow.RotSpeed = NumberRange.new(-60, 60)
	snow.Rate = 140
	-- (con ventisca: mucha más nieve, más rápida y de lado)
	if Kit.Weather == "Snowstorm" then
		snow.Rate = 420
		snow.Speed = NumberRange.new(12, 18)
		snow.Lifetime = NumberRange.new(4, 6)
		snow.Acceleration = V(6, 0, 2.5)
	end
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Parent = sky

	-- Spawns y banderas
	local spawnStyle = { Floor = RGB(205, 215, 230), FloorMaterial = Enum.Material.Concrete, Roof = RED, RoofMaterial = Enum.Material.Metal }
	Kit.spawnArea(teams[1], CFrame.new(-145, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-145, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-112, 0, 10))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-112, 0, 10))

	-- Límites y montañas nevadas de fondo
	Kit.bounds(320, 220, 60)
	for x = -240, 240, 60 do
		for _, z in { -1, 1 } do
			-- Laderas nevadas irregulares con roca a la vista y, detrás, picos de roca con nieve en la cima
			Kit.naturalHill(V(x + z * 15, -18, z * (175 + (math.abs(x) % 50))), 55 + (math.abs(x) % 4) * 8, Enum.Material.Snow, {
				Inward = V(0, 0, -z),
				RockCount = 4,
			})
			Kit.naturalHill(V(x + 25, -30, z * 230), 60, Enum.Material.Rock, {
				Inward = V(0, 0, -z),
				Rock = Enum.Material.Slate,
				Top = Enum.Material.Snow,
				TopCount = 4,
			})
		end
	end
	for z = -150, 150, 60 do
		for _, sx in { -1, 1 } do
			Kit.naturalHill(V(sx * 230, -20, z), 60, Enum.Material.Snow, { Inward = V(-sx, 0, 0), RockCount = 3 })
		end
	end
	-- Pinos fuera del mapa (bosque de fondo)
	for x = -150, 150, 22 do
		for _, z in { -1, 1 } do
			pine(V(x + (z * 7), 0, z * (122 + (math.abs(x) % 13))), 1.3, true)
		end
	end

	-- Modos
	for _, p in {
		V(-130, 0.5, 45), V(-100, 0.5, -10), V(-62.5, 8.6, 45), V(-70, 0.5, -62), V(-45, 0.5, 8),
		V(-20, 0.5, -60), V(-110, 0.5, 80), V(-60, 0.5, -15), V(-12, 0.5, 52), V(-125, 0.5, -90),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 9.6, 0), 10, 1)
	Kit.zone(V(-70, 0, -62), 9, 2)
	Kit.zone(V(70, 0, 62), 9, 3)
	Kit.zone(V(-45, 0, 0), 9, 4)
	Kit.zone(V(45, 0, 0), 9, 5)
	-- Realismo: carámbanos en los tejados y ventisca rasante (nieve que arrastra el viento por el suelo)
	local function icicles(a, b, top, count, seed)
		local rng = Random.new(seed)
		for i = 0, count do
			local p = a:Lerp(b, i / count) + Vector3.new(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.2, 0.2))
			local length = rng:NextNumber(0.8, 2.6)
			Kit.deco("Icicle", Vector3.new(0.35, length, 0.35), CFrame.new(p.X, top - length / 2, p.Z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), Color3.fromRGB(205, 235, 255), Enum.Material.Ice)
			Kit.deco("IcicleTip", Vector3.new(0.18, length * 0.5, 0.18), CFrame.new(p.X, top - length - length * 0.2, p.Z), Color3.fromRGB(220, 242, 255), Enum.Material.Ice)
		end
	end
	Kit.symmetric(function(m, side)
		local seed = side == "A" and 11 or 29
		-- Borde del tejado del hangar (mirando al centro) y del laboratorio
		local a, b = m * Vector3.new(-92, 0, -45.2), m * Vector3.new(-48, 0, -45.2)
		icicles(a, b, 14, 22, seed)
		local c, d = m * Vector3.new(-82, 0, 50.6), m * Vector3.new(-66, 0, 50.6)
		icicles(c, d, 16.5, 8, seed + 1)
	end)
	local drift = Kit.deco("SnowDrift", Vector3.new(300, 2, 200), CFrame.new(0, 1.2, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	drift.Transparency = 1
	local blow = Instance.new("ParticleEmitter")
	blow.Name = "Spindrift"
	blow.Texture = "rbxasset://textures/particles/smoke_main.dds"
	blow.Color = ColorSequence.new(Color3.fromRGB(245, 248, 255))
	blow.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	blow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.82), NumberSequenceKeypoint.new(1, 1) })
	blow.Lifetime = NumberRange.new(3, 5)
	blow.Speed = NumberRange.new(10, 16)
	blow.SpreadAngle = Vector2.new(10, 4)
	blow.EmissionDirection = Enum.NormalId.Right
	blow.Shape = Enum.ParticleEmitterShape.Box
	blow.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	blow.Rate = Kit.Weather == "Snowstorm" and 45 or 18
	blow.Parent = drift
	return folder
end

return Map
