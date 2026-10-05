-- NEON FOUNDRY: fundición de noche. Horno central con metal fundido, canales de lava (hacen daño),
-- puentes metálicos, cintas con lingotes, pasarelas y rótulos de neón.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "NeonFoundry",
	Name = "Neon Foundry",
	Icon = "🔥",
	Description = "Industrial · noche · lava y neón",
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.75, Sat = 0.18 }, -- tono de los grises en estilo Cartoon
	ClockTime = 0.3,
	Brightness = 1,
	Exposure = 0.2,
	Ambient = Color3.fromRGB(35, 30, 50),
	OutdoorAmbient = Color3.fromRGB(55, 50, 80),
	Atmosphere = { Density = 0.4, Offset = 0.1, Color = Color3.fromRGB(90, 70, 130), Decay = Color3.fromRGB(50, 30, 80), Glare = 0, Haze = 2.8 },
	Color = { Saturation = 0.2, Contrast = 0.2, Brightness = 0.02, Tint = Color3.fromRGB(240, 232, 255) },
	Bloom = { Intensity = 1, Size = 28, Threshold = 1.3 },
	Clouds = 0.35,
	CloudColor = Color3.fromRGB(80, 60, 110),
	SunRays = 0,
	Stars = 5000, -- cielo nocturno estrellado
	MoonSize = 16,
}

local V = Vector3.new
local RGB = Color3.fromRGB
local C = Kit.C

local FLOOR = RGB(58, 60, 72)
local WALL = RGB(70, 72, 84)
local ORANGE = RGB(255, 130, 30)
local LAVA_X = 32 -- canales de lava en x = ±32

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Factory") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo de placas con líneas de neón
	-- Hormigón húmedo (con los charcos refleja el neón)
	block("Floor", V(340, 2, 240), CFrame.new(0, -1, 0), FLOOR, Enum.Material.Concrete)
	for _, z in { -45, 45 } do
		deco("FloorNeon", V(250, 0.06, 0.5), CFrame.new(0, 0.04, z), C.Cyan, Enum.Material.Neon)
	end
	for _, x in { -95, 95 } do
		deco("FloorNeon", V(0.5, 0.06, 200), CFrame.new(x, 0.04, 0), C.Pink, Enum.Material.Neon)
	end

	-- Horno central con metal fundido cayendo a una piscina de lava
	Kit.cylinder("Furnace", 34, 20, CFrame.new(0, 17, 0), RGB(75, 70, 80), Enum.Material.CorrodedMetal)
	for i, y in { 8, 18, 28 } do
		Kit.cylinder("FurnaceBand", 1.4, 20.6, CFrame.new(0, y, 0), i == 2 and ORANGE or RGB(45, 45, 52), i == 2 and Enum.Material.Neon or Enum.Material.Metal, nil, true)
	end
	local emblemPlate = deco("FurnaceEmblem", V(8, 8, 0.5), CFrame.new(0, 22, -10.3), RGB(40, 40, 48), Enum.Material.Metal)
	Kit.sign(emblemPlate, Enum.NormalId.Front, "⚡", ORANGE)
	local emblemBack = deco("FurnaceEmblem", V(8, 8, 0.5), CFrame.new(0, 22, 10.3), RGB(40, 40, 48), Enum.Material.Metal)
	Kit.sign(emblemBack, Enum.NormalId.Back, "⚡", ORANGE)
	for _, s in { -1, 1 } do
		local pour = deco("MoltenPour", V(3, 14, 1.2), CFrame.new(0, 7, s * 10.6), RGB(255, 150, 40), Enum.Material.Neon)
		Kit.light(pour, "PointLight", ORANGE, 30, 3)
		-- Chispas del metal fundido
		local sparks = Instance.new("ParticleEmitter")
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(RGB(255, 230, 150), ORANGE)
		sparks.LightEmission = 1
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		sparks.Lifetime = NumberRange.new(0.6, 1.2)
		sparks.Speed = NumberRange.new(8, 16)
		sparks.SpreadAngle = Vector2.new(70, 70)
		sparks.Acceleration = V(0, -35, 0)
		sparks.Rate = 25
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Parent = pour
		Kit.lava(V(12, 1, 6), CFrame.new(0, -0.3, s * 14))
		Kit.railing(V(-7, 0, s * 17.5), V(7, 0, s * 17.5), 3, ORANGE)
	end
	Kit.cylinder("FurnaceCap", 3, 14, CFrame.new(0, 35.5, 0), RGB(50, 50, 58), Enum.Material.Metal, nil, true)
	Kit.smokestack(V(0, 37, 0), 18)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(255, 60, 80) or RGB(60, 140, 255)

		-- Canal de lava a lo largo de Z con tres puentes
		Kit.lava(V(10, 1, 210), m * CFrame.new(-LAVA_X, -0.4, 0))
		for _, bz in { -70, 5, 70 } do
			block("LavaBridge", V(14, 1, 10), m * CFrame.new(-LAVA_X, 0.5, bz), RGB(80, 82, 95), Enum.Material.DiamondPlate)
			for _, s in { -1, 1 } do
				Kit.railing(m * V(-LAVA_X - 7, 1, bz + s * 4.8), m * V(-LAVA_X + 7, 1, bz + s * 4.8), 2.5, ORANGE)
			end
		end

		-- Plataforma elevada con cinta transportadora
		block("ConveyorDeck", V(14, 8, 46), m * CFrame.new(-62, 4, -60), WALL, Enum.Material.CorrodedMetal)
		deco("DeckNeon", V(14.2, 0.4, 46.2), m * CFrame.new(-62, 7.9, -60), teamColor, Enum.Material.Neon)
		Kit.conveyor(m * V(-62, 8.5, -80), m * V(-62, 8.5, -40), 5)
		Kit.stairs(m * V(-62, 0, -100), m * V(-62, 8, -83), 6, RGB(90, 92, 105))
		Kit.stairs(m * V(-43, 0, -45), m * V(-55.5, 8, -45), 5, RGB(90, 92, 105))
		Kit.railing(m * V(-69, 8, -83), m * V(-69, 8, -37), 3, C.Yellow)

		-- Edificio del rótulo de neón (lado del equipo, con pasarela)
		block("Factory", V(30, 22, 26), m * CFrame.new(-95, 11, 75), WALL, Enum.Material.CorrodedMetal)
		deco("FactoryTrim", V(30.4, 1, 26.4), m * CFrame.new(-95, 21.8, 75), RGB(40, 40, 50), Enum.Material.Metal)
		for i, x in { -104, -95, -86 } do
			local win = deco("FactoryWindow", V(5, 4, 0.3), m * CFrame.new(x, 8, 61.9), i == 2 and ORANGE or RGB(255, 190, 80), Enum.Material.Neon)
			win.Transparency = 0.25
		end
		Kit.neonSign(m * CFrame.new(-95, 16, 61.6), 22, 6, side == "A" and "NEON FOUNDRY" or "FOUNDRY 02", side == "A" and C.Cyan or C.Pink, side == "A" and C.Pink or C.Cyan)
		block("FactoryWalk", V(8, 1, 40), m * CFrame.new(-76, 9.5, 75), RGB(80, 82, 95), Enum.Material.DiamondPlate)
		Kit.railing(m * V(-72.2, 10, 56), m * V(-72.2, 10, 94), 3, C.Cyan)
		Kit.stairs(m * V(-76, 0, 38), m * V(-76, 10, 55), 6, RGB(90, 92, 105))

		-- Cajas metálicas con brillo, tuberías y cobertura
		Kit.metalCrate(m * CFrame.new(-50, 0, 10), 5, RGB(70, 75, 90), teamColor)
		Kit.metalCrate(m * CFrame.new(-50, 0, 15.2), 5, RGB(70, 75, 90), teamColor)
		Kit.metalCrate(m * CFrame.new(-50, 5, 12.6), 4, RGB(70, 75, 90), C.Cyan)
		Kit.metalCrate(m * CFrame.new(-18, 0, 35), 5, RGB(80, 70, 70), ORANGE)
		Kit.metalCrate(m * CFrame.new(-18, 0, -35), 5, RGB(80, 70, 70), ORANGE)
		Kit.metalCrate(m * CFrame.new(-80, 0, 15), 6, RGB(70, 75, 90), C.Pink)
		Kit.metalCrate(m * CFrame.new(-110, 0, -40), 5, RGB(70, 75, 90), teamColor)
		Kit.metalCrate(m * CFrame.new(-110, 0, -34.8), 5, RGB(70, 75, 90), teamColor)
		Kit.container(m * CFrame.new(-82, 0, -15) * CFrame.Angles(0, math.rad(90), 0), RGB(140, 40, 60), "FOUNDRY")
		Kit.barrier(V(2, 4, 14), m * CFrame.new(-20, 0, 0))
		Kit.barrier(V(14, 4, 2), m * CFrame.new(-60, 0, 40))
		Kit.pipeRun(m * V(-140, 14, -96), m * V(-20, 14, -96), 2.4, RGB(110, 100, 120))
		Kit.pipeRun(m * V(-140, 18, -100), m * V(-40, 18, -100), 1.6, RGB(160, 80, 60))
		for _, x in { -130, -100, -70, -40 } do
			block("PipeSupport", V(1.2, 18, 1.2), m * CFrame.new(x, 9, -98), RGB(45, 45, 55), Enum.Material.Metal)
		end

		-- Grúa con caja colgando (decoración)
		deco("CraneArm", V(2, 2, 40), m * CFrame.new(-45, 34, 30), C.Yellow, Enum.Material.Metal)
		deco("CraneMast", V(2, 34, 2), m * CFrame.new(-45, 17, 50), C.Yellow, Enum.Material.Metal)
		deco("CraneCable", V(0.3, 10, 0.3), m * CFrame.new(-45, 28, 14), RGB(20, 20, 20), Enum.Material.Metal)
		Kit.metalCrate(m * CFrame.new(-45, 19, 14), 5, RGB(90, 90, 100), C.Yellow)

		-- Focos que barren el cielo
		local beam = deco("SkyBeam", V(1.5, 120, 1.5), m * CFrame.new(-120, 60, 100) * CFrame.Angles(math.rad(-15), 0, math.rad(12)), side == "A" and C.Cyan or C.Pink, Enum.Material.Neon)
		beam.Transparency = 0.75
		beam:SetAttribute("Sweep", 18)
	end)

	-- Pórticos de neón sobre los carriles con lámparas colgantes
	for _, z in { -45, 45 } do
		block("NeonGantry", V(2, 2, 2), CFrame.new(-60, 1, z), RGB(45, 45, 55), Enum.Material.Metal)
		block("NeonGantry", V(2, 2, 2), CFrame.new(60, 1, z), RGB(45, 45, 55), Enum.Material.Metal)
		deco("GantryPostA", V(1.4, 24, 1.4), CFrame.new(-60, 12, z), RGB(50, 50, 60), Enum.Material.Metal)
		deco("GantryPostB", V(1.4, 24, 1.4), CFrame.new(60, 12, z), RGB(50, 50, 60), Enum.Material.Metal)
		deco("GantryBeam", V(122, 1.6, 1.6), CFrame.new(0, 24, z), RGB(50, 50, 60), Enum.Material.Metal)
		deco("GantryNeon", V(122, 0.4, 1.7), CFrame.new(0, 23, z), z < 0 and C.Pink or C.Cyan, Enum.Material.Neon)
		for x = -45, 45, 30 do
			deco("LampCable", V(0.15, 6, 0.15), CFrame.new(x, 20, z), RGB(20, 20, 20), Enum.Material.Metal)
			local lamp = deco("HangingLamp", V(2.4, 0.8, 2.4), CFrame.new(x, 16.6, z), RGB(255, 210, 150), Enum.Material.Neon)
			Kit.lightCone(V(x, 16.2, z), 15, 1.2, 6, RGB(255, 205, 140))
			Kit.light(lamp, "SpotLight", RGB(255, 200, 140), 28, 2, Enum.NormalId.Bottom).Angle = 100
		end
	end

	-- Spawns y banderas
	local spawnStyle = { Floor = RGB(50, 52, 62), FloorMaterial = Enum.Material.DiamondPlate, Roof = RGB(45, 46, 56), RoofMaterial = Enum.Material.Metal }
	Kit.spawnArea(teams[1], CFrame.new(-145, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-145, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-112, 0, 10))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-112, 0, 10))

	-- Límites: muros de fábrica alrededor y chimeneas de fondo
	Kit.bounds(320, 220, 60)
	for x = -150, 150, 30 do
		for _, z in { -1, 1 } do
			local h = 26 + (math.abs(x) % 3) * 6
			block("BackFactory", V(30, h, 12), CFrame.new(x, h / 2, z * 117), WALL:Lerp(Color3.new(0, 0, 0), (math.abs(x) % 2) * 0.15), Enum.Material.CorrodedMetal)
			local stripe = deco("BackStripe", V(30.2, 0.6, 0.3), CFrame.new(x, h - 3, z * 110.9), (x / 30) % 2 == 0 and C.Cyan or C.Pink, Enum.Material.Neon)
			stripe.Transparency = 0.1
			deco("BackVertical", V(0.6, h - 6, 0.3), CFrame.new(x + 14, (h - 6) / 2, z * 110.9), (x / 30) % 2 == 0 and C.Pink or C.Cyan, Enum.Material.Neon)
			local window = deco("BackWindow", V(10, 4, 0.3), CFrame.new(x - 5, h * 0.45, z * 110.9), RGB(255, 180, 80), Enum.Material.Neon)
			window.Transparency = 0.35
		end
	end
	for z = -90, 90, 30 do
		for _, sx in { -1, 1 } do
			block("SideFactory", V(12, 30, 30), CFrame.new(sx * 168, 15, z), WALL, Enum.Material.CorrodedMetal)
		end
	end
	for i, p in { V(-120, 0, 160), V(-40, 0, 190), V(60, 0, 170), V(150, 0, 200), V(-160, 0, -170), V(20, 0, -190), V(130, 0, -160) } do
		Kit.smokestack(p, 50 + (i % 3) * 15)
	end

	-- Modos
	for _, p in {
		V(-130, 0.5, 45), V(-100, 0.5, -15), V(-60, 8.5, -60), V(-76, 10.5, 75), V(-45, 0.5, 30),
		V(-20, 0.5, -60), V(-110, 0.5, 85), V(-60, 0.5, 20), V(-15, 0.5, 60), V(-125, 0.5, -80),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 0, 25), 9, 1)
	Kit.zone(V(-62, 8, -60), 9, 2)
	Kit.zone(V(62, 8, 60), 9, 3)
	Kit.zone(V(0, 0, -25), 9, 4)
	Kit.zone(V(-50, 0, 25), 10, 5)
	-- Realismo: suelo mojado con charcos que reflejan el neón, vapor y brasas en el aire
	for _, p in { Vector3.new(-56, 0, 24), Vector3.new(-40, 0, 34), Vector3.new(-11, 0, 64), Vector3.new(-16, 0, -56), Vector3.new(-121, 0, -76), Vector3.new(-126, 0, 49) } do
		Kit.puddle(p, 5.5)
		Kit.puddle(Kit.MIRROR * p, 5.5)
	end
	for _, p in { Vector3.new(-26, 0, -66), Vector3.new(-105, 0, -20), Vector3.new(-90, 0, 40) } do
		Kit.steamVent(CFrame.new(p), 1.4)
		Kit.steamVent(Kit.MIRROR * CFrame.new(p), 1.4)
	end
	Kit.dustMotes(CFrame.new(0, 12, 0), Vector3.new(70, 22, 70), Color3.fromRGB(255, 150, 60), 25)
	-- Losas de hormigón industrial con juntas, grietas y manchas de aceite de la maquinaria
	Kit.floorJoints(CFrame.new(), 300, 210, 12, Color3.fromRGB(38, 38, 42))
	Kit.symmetric(function(m)
		for i, spec in { { Vector3.new(-84, 0, -8), 9 }, { Vector3.new(-35, 0, -30), 8 }, { Vector3.new(-115, 0, 66), 10 } } do
			Kit.crack(m * spec[1], spec[2], i * 31)
		end
		for _, p in { Vector3.new(-66, 0, -34), Vector3.new(-100, 0, 30), Vector3.new(-30, 0, 80) } do
			Kit.oilStain(m * p, 3.2)
		end
		Kit.manhole(m * Vector3.new(-48, 0, -12))
	end)
	return folder
end

return Map
