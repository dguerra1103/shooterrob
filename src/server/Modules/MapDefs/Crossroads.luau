-- ENCRUCIJADA: ciudad en guerra al estilo de los mapas 5 contra 5 de los shooters de móvil.
-- Tres carriles de punta a punta: la avenida central (larga, con el monumento en medio que corta
-- la línea de tiro de base a base) y dos carriles laterales (callejón del mercado y obras). Entre
-- carriles, filas de edificios con pasos entre ellos y edificios de dos plantas en los que se
-- puede entrar, con ventanas de verdad para disparar desde arriba. Simétrico por rotación: cada
-- equipo tiene lo mismo a su izquierda y a su derecha. Siempre en estilo realista.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "Crossroads",
	Name = "Encrucijada",
	Icon = "🏚️",
	Description = "Ciudad en guerra · 3 carriles · 5 contra 5",
	Realistic = true,
}

Map.Lighting = {
	ClockTime = 15.2,
	Latitude = 28,
	Brightness = 3.2,
	Exposure = -0.1,
	Ambient = Color3.fromRGB(78, 70, 62),
	OutdoorAmbient = Color3.fromRGB(150, 138, 120),
	ShadowSoftness = 0.08,
	Atmosphere = { Density = 0.38, Offset = 0.12, Color = Color3.fromRGB(222, 196, 160), Decay = Color3.fromRGB(150, 120, 95), Glare = 0.4, Haze = 2.2 },
	Color = { Saturation = -0.05, Contrast = 0.2, Brightness = 0, Tint = Color3.fromRGB(255, 240, 222) },
	Bloom = { Intensity = 0.5, Size = 24, Threshold = 2 },
	Clouds = 0.35,
	CloudColor = Color3.fromRGB(240, 225, 205),
	SunRays = 0.08,
	Wind = Vector3.new(6, 0, 3),
	TerrainColors = { Ground = Color3.fromRGB(128, 108, 82), Sand = Color3.fromRGB(176, 152, 116), Rock = Color3.fromRGB(120, 112, 102) },
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local LENGTH, WIDTH = 410, 270 -- zona jugable (X: de base a base; Z: de lado a lado)

local RealKit = require(script.Parent.Parent.RealKit)
local FLOOR_H = RealKit.FLOOR_H
local PALETTE = RealKit.PALETTE
local building, solidBlock, sandbags, ruinWall = RealKit.building, RealKit.solidBlock, RealKit.sandbags, RealKit.ruinWall
local burntCar, bus, tankWreck, stall = RealKit.burntCar, RealKit.bus, RealKit.tankWreck, RealKit.stall

local block, deco = Kit.block, Kit.deco

---------------------------------------------------------------------------
-- Mapa
---------------------------------------------------------------------------

function Map.Build()
	local folder = Kit.Begin(Map.Name, { Realistic = true })
	Kit.applyLighting(Map.Lighting)
	local teams = GameConfig.Teams

	-- Suelo: tierra en los carriles, asfalto en la avenida y aceras
	Kit.terrainFloor(M.Ground, LENGTH + 240, WIDTH + 240)
	block("Avenue", V(LENGTH + 40, 0.4, 36), CFrame.new(0, 0.2, 0), RGB(64, 64, 66), M.Asphalt)
	for _, z in { -1, 1 } do
		block("Sidewalk", V(LENGTH - 60, 0.7, 5), CFrame.new(0, 0.35, z * 20.5), RGB(150, 144, 134), M.Pavement)
		deco("Curb", V(LENGTH - 60, 0.75, 0.6), CFrame.new(0, 0.37, z * 18.2), RGB(170, 166, 158), M.Concrete)
	end
	for x = -180, 180, 12 do
		if math.abs(x) > 20 then
			deco("LaneDash", V(5, 0.05, 0.5), CFrame.new(x, 0.43, 0), RGB(210, 200, 170), M.Concrete)
		end
	end
	-- Cruce del centro (une la avenida con los dos carriles)
	block("CrossStreet", V(24, 0.4, WIDTH - 20), CFrame.new(0, 0.2, 0), RGB(70, 70, 72), M.Asphalt)

	-- Monumento central: corta la línea de tiro de base a base por la avenida
	Kit.cylinder("FountainBasin", 1.6, 18, CFrame.new(0, 0.8, 0), RGB(170, 160, 145), M.Limestone)
	Kit.cylinder("FountainWater", 0.2, 16, CFrame.new(0, 1.55, 0), RGB(60, 80, 70), M.Glass, nil, true)
	block("MonumentBase", V(7, 4, 7), CFrame.new(0, 3.6, 0), RGB(160, 150, 136), M.Limestone)
	block("MonumentColumn", V(3, 12, 3), CFrame.new(0, 11.6, 0), RGB(176, 166, 150), M.Marble)
	deco("MonumentTop", V(4.2, 1.2, 4.2), CFrame.new(0, 18.2, 0), RGB(150, 140, 125), M.Limestone)
	deco("MonumentStatue", V(1.6, 3.6, 1.2), CFrame.new(0, 20.6, 0) * CFrame.Angles(0, rad(20), 0), RGB(90, 110, 95), M.Metal)
	-- Escombros del monumento (una esquina rota)
	for i = 1, 4 do
		deco("Debris", V(1.5 + i * 0.4, 1, 1.2 + i * 0.3), CFrame.new(5 + i, 2.1, -6 + i * 0.8) * CFrame.Angles(i, i * 0.7, 0), RGB(165, 155, 140), M.Limestone)
	end

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and teams[1].Color.Color or teams[2].Color.Color

		------------------------------------------------------------------
		-- Fila norte (entre la avenida y el callejón del mercado), z 24..46
		------------------------------------------------------------------
		solidBlock(m * CFrame.new(-148, 0, 35), 26, 20, 16, PALETTE.Plaster[2], { Sign = side == "A" and "PANADERÍA" or "FERRETERÍA" })
		-- Hotel: dos plantas, ventanas a la avenida (puesto de tirador) y puertas a los dos lados
		building(m * CFrame.new(-110, 0, 35) * CFrame.Angles(0, 0, 0), 30, 22, {
			Floors = 2,
			Color = PALETTE.Plaster[1],
			Doors = { Front = { -6 }, Back = { 6 } },
			Blind = { Left = true },
			Sign = "HOTEL CENTRAL",
		})
		-- Tienda en ruinas: una planta sin tejado, muros rotos (se pelea dentro)
		building(m * CFrame.new(-66, 0, 34), 24, 18, {
			Floors = 1,
			Color = PALETTE.Plaster[4],
			Ruined = true,
			Doors = { Front = { -4 }, Back = { 5 }, Right = { 0 } },
		})
		-- Puestos del mercado junto al cruce
		stall(m * CFrame.new(-40, 0, 30), RGB(170, 60, 50))
		stall(m * CFrame.new(-30, 0, 40) * CFrame.Angles(0, rad(90), 0), RGB(60, 110, 150))
		sandbags(m * CFrame.new(-20, 0, 27), 8)

		------------------------------------------------------------------
		-- Fila sur (entre la avenida y las obras), z -46..-24
		------------------------------------------------------------------
		solidBlock(m * CFrame.new(-152, 0, -35), 22, 20, 20, PALETTE.Plaster[3], { Sign = side == "A" and "FARMACIA" or "CAFÉ" })
		-- Oficinas: dos plantas, ventanas a la avenida y a las obras
		building(m * CFrame.new(-114, 0, -35) * CFrame.Angles(0, math.pi, 0), 28, 22, {
			Floors = 2,
			Color = PALETTE.Plaster[5],
			Doors = { Front = { 5 }, Back = { -5 } },
			Blind = { Right = true },
			Sign = "OFICINAS",
		})
		solidBlock(m * CFrame.new(-72, 0, -35), 24, 20, 13, PALETTE.Brick, { Material = M.Brick })
		bus(m * CFrame.new(-34, 0, -31) * CFrame.Angles(0, rad(8), 0))

		------------------------------------------------------------------
		-- Avenida (z -18..18)
		------------------------------------------------------------------
		burntCar(m * CFrame.new(-138, 0, -9) * CFrame.Angles(0, rad(25), 0), true)
		Kit.barrier(V(10, 3.6, 1.6), m * CFrame.new(-96, 0, 7))
		sandbags(m * CFrame.new(-70, 0, -8) * CFrame.Angles(0, rad(90), 0), 9)
		burntCar(m * CFrame.new(-48, 0, 9) * CFrame.Angles(0, rad(-15), 0), false)
		Kit.barrier(V(1.6, 3.6, 8), m * CFrame.new(-24, 0, -11))
		for _, p in { V(-120, 0, 14), V(-82, 0, -14), V(-58, 0, 13) } do
			Kit.barrel(m * CFrame.new(p), RGB(80, 84, 70))
		end
		for _, x in { -150, -100, -50 } do
			Kit.streetLamp(m * CFrame.new(x, 0, 19.5) * CFrame.Angles(0, math.pi, 0), RGB(255, 225, 180))
		end

		------------------------------------------------------------------
		-- Carril norte: callejón del mercado (z 50..125)
		------------------------------------------------------------------
		-- Casa con torre: dos plantas, ventanas que miran a lo largo del callejón
		building(m * CFrame.new(-128, 0, 100) * CFrame.Angles(0, -math.pi / 2, 0), 24, 22, {
			Floors = 2,
			Color = PALETTE.Plaster[3],
			Doors = { Front = { 0 }, Back = { 4 } },
		})
		-- Casa en ruinas en mitad del carril
		building(m * CFrame.new(-36, 0, 84), 22, 20, {
			Floors = 1,
			Color = PALETTE.Plaster[2],
			Ruined = true,
			Doors = { Left = { -2 }, Right = { 2 }, Front = { 4 } },
			Lamp = false,
		})
		burntCar(m * CFrame.new(-92, 0, 66) * CFrame.Angles(0, rad(70), 0), false)
		burntCar(m * CFrame.new(-62, 0, 104) * CFrame.Angles(0, rad(-10), 0), true)
		-- Fila exterior del callejón (cierra el carril: es un pasillo, no un descampado)
		solidBlock(m * CFrame.new(-163, 0, 123) * CFrame.Angles(0, math.pi, 0), 24, 22, 15, PALETTE.Plaster[5])
		solidBlock(m * CFrame.new(-90, 0, 124) * CFrame.Angles(0, math.pi, 0), 28, 20, 18, PALETTE.Brick, { Material = M.Brick })
		solidBlock(m * CFrame.new(-21, 0, 124) * CFrame.Angles(0, math.pi, 0), 22, 20, 12, PALETTE.Plaster[1], { Sign = side == "A" and "MERCADO" or "TALLER" })
		ruinWall(m * CFrame.new(-150, 0, 104) * CFrame.Angles(0, rad(90), 0), 18, 6)
		ruinWall(m * CFrame.new(-78, 0, 84), 14, 7)
		ruinWall(m * CFrame.new(-58, 0, 60) * CFrame.Angles(0, rad(90), 0), 10, 5)
		stall(m * CFrame.new(-112, 0, 64), RGB(120, 140, 70))
		stall(m * CFrame.new(-104, 0, 64), RGB(170, 90, 40))
		sandbags(m * CFrame.new(-100, 0, 82) * CFrame.Angles(0, rad(90), 0), 10)
		sandbags(m * CFrame.new(-12, 0, 62), 9)
		Kit.crate(m * CFrame.new(-60, 0, 76), 4.5)
		Kit.crate(m * CFrame.new(-56, 0, 79), 3.5)
		Kit.crate(m * CFrame.new(-58, 4.5, 77), 3)
		stall(m * CFrame.new(-150, 0, 66) * CFrame.Angles(0, rad(90), 0), RGB(150, 120, 60))
		-- Muro bajo de patio con huecos
		for _, seg in { { -168, -150 }, { -140, -118 } } do
			block("CourtWall", V(seg[2] - seg[1], 4, 1.2), m * CFrame.new((seg[1] + seg[2]) / 2, 2, 54), PALETTE.Plaster[4], M.Plaster)
		end

		------------------------------------------------------------------
		-- Carril sur: obras y trincheras (z -125..-50)
		------------------------------------------------------------------
		-- Estructura de hormigón a medio construir: pilares abajo y forjado arriba con rampa
		local obra = m * CFrame.new(-62, 0, -88)
		for _, x in { -12, 0, 12 } do
			for _, z in { -8, 8 } do
				block("Pillar", V(1.8, FLOOR_H, 1.8), obra * CFrame.new(x, FLOOR_H / 2, z), PALETTE.Concrete, M.Concrete)
			end
		end
		block("ObraSlab", V(28, 1, 20), obra * CFrame.new(0, FLOOR_H - 0.5, 0), PALETTE.Concrete, M.Concrete)
		for _, x in { -13.5, 13.5 } do
			block("ObraParapet", V(1, 3, 20), obra * CFrame.new(x, FLOOR_H + 1.5, 0), PALETTE.Concrete, M.Concrete)
		end
		block("ObraParapet", V(28, 3, 1), obra * CFrame.new(0, FLOOR_H + 1.5, 9.5), PALETTE.Concrete, M.Concrete)
		Kit.ramp(obra * V(-6, 0, -26), obra * V(-6, FLOOR_H, -10.5), 6, RGB(130, 110, 80), M.WoodPlanks)
		for i = 1, 5 do
			deco("Rebar", V(0.2, 3, 0.2), obra * CFrame.new(-12 + i * 5, FLOOR_H + 3, 9.5), PALETTE.Rust, M.Metal)
		end
		-- Andamio decorativo y grúa de obra al fondo
		Kit.crane(m * CFrame.new(-60, 0, -152), 46, RGB(225, 170, 40))
		-- Trincheras de sacos y restos
		sandbags(m * CFrame.new(-120, 0, -70), 12)
		sandbags(m * CFrame.new(-100, 0, -108) * CFrame.Angles(0, rad(90), 0), 10)
		sandbags(m * CFrame.new(-24, 0, -64), 10)
		tankWreck(m * CFrame.new(-30, 0, -104) * CFrame.Angles(0, rad(-20), 0))
		for _, p in { V(-146, 0, -96), V(-140, 0, -58), V(-84, 0, -60) } do
			Kit.barrier(V(8, 3.6, 1.6), m * CFrame.new(p))
		end
		for _, p in { V(-90, 0, -70), V(-88, 0, -73), V(-150, 0, -106) } do
			Kit.barrel(m * CFrame.new(p), PALETTE.Rust)
		end
		Kit.metalCrate(m * CFrame.new(-44, 0, -120), 5, RGB(90, 96, 80))
		-- Fila exterior de las obras: almacén y casas (cierra el carril)
		solidBlock(m * CFrame.new(-166, 0, -124), 24, 20, 14, PALETTE.Plaster[2])
		solidBlock(m * CFrame.new(-120, 0, -126), 22, 16, 10, PALETTE.Concrete, { Material = M.Concrete, Windows = false })
		solidBlock(m * CFrame.new(-8, 0, -126), 16, 16, 16, PALETTE.Plaster[3])
		ruinWall(m * CFrame.new(-138, 0, -88) * CFrame.Angles(0, rad(90), 0), 16, 7)
		ruinWall(m * CFrame.new(-92, 0, -96), 12, 6, PALETTE.Brick)
		ruinWall(m * CFrame.new(-36, 0, -78) * CFrame.Angles(0, rad(90), 0), 10, 6)
		-- Valla de obra (chapa) a lo largo del solar
		for i = 0, 3 do
			block("SiteFence", V(9, 6, 0.4), m * CFrame.new(-88 + i * 10, 3, -58), RGB(120, 128, 110), M.CorrodedMetal)
		end

		------------------------------------------------------------------
		-- Borde del mapa: fila de edificios macizos (horizonte de ciudad)
		------------------------------------------------------------------
		for i, x in { -190, -160, -130, -100, -70, -40, -10 } do
			local h = 18 + (i * 7) % 12
			solidBlock(m * CFrame.new(x + 15, 0, 147) * CFrame.Angles(0, math.pi, 0), 30, 20, h, PALETTE.Plaster[(i % #PALETTE.Plaster) + 1], { Windows = i % 2 == 0 })
		end
		for _, z in { -110, -70, 70, 110 } do
			solidBlock(m * CFrame.new(-222, 0, z) * CFrame.Angles(0, math.pi / 2, 0), 40, 16, 22, PALETTE.Plaster[3])
		end

		-- Base: el muro de detrás de la zona de salida
		block("BaseWall", V(2, 14, 90), m * CFrame.new(-206, 7, 0), PALETTE.Concrete, M.Concrete)
		for _, z in { -30, 30 } do
			Kit.banner(m * CFrame.new(-204.8, 9, z) * CFrame.Angles(0, rad(90), 0), 5, 9, teamColor, RGB(240, 240, 240))
		end
	end)

	-- Zonas de salida, banderas y límites
	local spawnStyle = { Floor = RGB(120, 116, 110), FloorMaterial = M.Concrete, Roof = RGB(100, 96, 90), RoofMaterial = M.CorrodedMetal }
	Kit.spawnArea(teams[1], CFrame.new(-190, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-190, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-162, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-162, 0, 0))
	Kit.bounds(LENGTH, WIDTH, 70)

	-- Polvo en el aire y humo a lo lejos (ciudad en guerra)
	Kit.dustMotes(CFrame.new(0, 8, 0), V(360, 14, 220), RGB(230, 205, 165), 35)
	for _, p in { V(-90, 0, 230), V(140, 0, -240), V(260, 0, 120), V(-280, 0, -90) } do
		local plume = deco("SmokePlume", V(4, 4, 4), CFrame.new(p + V(0, 30, 0)), RGB(60, 58, 55), M.Concrete)
		plume.Transparency = 1
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(RGB(80, 74, 68), RGB(40, 38, 36))
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 14), NumberSequenceKeypoint.new(1, 50) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		smoke.Lifetime = NumberRange.new(12, 18)
		smoke.Speed = NumberRange.new(6, 10)
		smoke.SpreadAngle = Vector2.new(10, 10)
		smoke.Rate = 2
		smoke.WindAffectsDrag = true
		smoke.Drag = 0.2
		smoke.EmissionDirection = Enum.NormalId.Top
		smoke.Parent = plume
	end
	-- Colinas secas lejos (fuera del límite)
	for _, spec in { { V(-320, 0, 260), 90 }, { V(340, 0, -250), 100 }, { V(0, 0, -330), 80 }, { V(60, 0, 340), 90 } } do
		Kit.naturalHill(spec[1], spec[2], M.Sand)
	end

	-- Puntos de salida libres (todos contra todos, eliminación...), por todo el mapa
	for _, p in {
		V(-150, 0.5, 8), V(-120, 0.5, -10), V(-80, 0.5, 12), V(-40, 0.5, -6),
		V(-150, 0.5, 80), V(-120, 0.5, 74), V(-60, 0.5, 100), V(-20, 0.5, 112),
		V(-150, 0.5, -80), V(-110, 0.5, -95), V(-62, 0.5, -112), V(-18, 0.5, -80),
		V(-110, FLOOR_H + 0.5, 30), V(-114, FLOOR_H + 0.5, -40),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	-- Puestos de los tiradores (ventanas que dan a la avenida, la torre del callejón y las obras)
	for _, spot in {
		{ V(-110, FLOOR_H, 26.7), V(-110, 4, -20) }, -- hotel, ventanas a la avenida
		{ V(-100, FLOOR_H, 26.7), V(-100, 4, -20) },
		{ V(-114, FLOOR_H, -26.7), V(-114, 4, 20) }, -- oficinas, ventana a la avenida
		{ V(-119.7, FLOOR_H, 108), V(-20, 4, 108) }, -- casa con torre, ventana al callejón
		{ V(-58, FLOOR_H, -86), V(0, 4, -90) }, -- forjado de las obras
	} do
		Kit.botSpot(spot[1], spot[2])
		Kit.botSpot(Kit.MIRROR * spot[1], Kit.MIRROR * spot[2])
	end
	-- Buscar y destruir: cada equipo defiende dos sitios en su mitad (A y B)
	for _, site in { { V(-96, 0, 100), "A" }, { V(-124, 0, -92), "B" } } do
		Kit.bombSite(site[1], site[2], 1)
		Kit.bombSite(Kit.MIRROR * site[1], site[2], 2)
	end
	-- Zonas de control: el monumento, la mitad de cada carril y los dos lados del cruce
	Kit.zone(V(0, 0, 0), 14, 1)
	Kit.zone(V(-36, 0, 84), 11, 2)
	Kit.zone(V(36, 0, -84), 11, 3)
	Kit.zone(V(0, 0, 34), 10, 4)
	Kit.zone(V(0, 0, -34), 10, 5)

	-- Detalles de suelo: grietas, manchas y alcantarillas
	Kit.symmetric(function(m)
		for i, spec in { { V(-120, 0, 4), 9 }, { V(-60, 0, -6), 11 }, { V(-90, 0, 80), 8 }, { V(-40, 0, -90), 10 } } do
			Kit.crack(m * spec[1], spec[2], i * 13)
		end
		for _, p in { V(-130, 0, -6), V(-30, 0, 4), V(-104, 0, 92) } do
			Kit.oilStain(m * p, 3)
		end
		for _, p in { V(-80, 0, 0), V(-140, 0, 10) } do
			Kit.manhole(m * p)
		end
	end)
	return folder
end

return Map
