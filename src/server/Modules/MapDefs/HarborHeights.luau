-- HARBOR HEIGHTS: pueblo costero vertical. Canal con agua en el centro (pasarelas por debajo
-- de los puentes), torre de control en el puente central, azoteas en cada lado y el mar de fondo.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "HarborHeights",
	Name = "Harbor Heights",
	Icon = "⚓",
	Description = "Costa · día · canal, puentes y azoteas",
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.08, Sat = 0.3 }, -- tono de los grises en estilo Cartoon
	ClockTime = 14.2,
	Brightness = 3.2,
	Exposure = 0,
	Ambient = Color3.fromRGB(60, 62, 72),
	OutdoorAmbient = Color3.fromRGB(125, 128, 140),
	Atmosphere = { Density = 0.3, Offset = 0.25, Color = Color3.fromRGB(199, 215, 235), Decay = Color3.fromRGB(106, 130, 160), Glare = 0.5, Haze = 1.6 },
	Color = { Saturation = 0.12, Contrast = 0.16, Brightness = 0.01, Tint = Color3.fromRGB(255, 250, 242) },
	Clouds = 0.6,
	SunRays = 0.06,
	-- Agua de puerto: verde azulada, con reflejos y oleaje suave
	Water = { Color = Color3.fromRGB(20, 110, 135), Reflectance = 0.8, Transparency = 0.45, WaveSize = 0.12, WaveSpeed = 8 },
	Latitude = 38,
	Bloom = { Intensity = 0.5, Size = 24, Threshold = 2 },
}

local V = Vector3.new
local RGB = Color3.fromRGB
local C = Kit.C

local STONE = RGB(168, 158, 140) -- adoquín envejecido (antes casi blanco: deslumbraba)
local STONE_DARK = RGB(132, 122, 104)
local PLASTER = RGB(236, 226, 205)
local CANAL_HALF = 12 -- el canal va de x = -12 a x = 12
local LEDGE_Y = -7.5 -- altura de las pasarelas del canal
local WATER_Y = -8.5

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	---------------------------------------------------------------------------
	-- Suelo, canal y agua
	---------------------------------------------------------------------------
	Kit.symmetric(function(m)
		block("Ground", V(150, 2, 220), m * CFrame.new(-(CANAL_HALF + 75), -1, 0), STONE, Enum.Material.Cobblestone)
		-- Muro del canal y pasarela inferior
		block("CanalWall", V(2, 14, 220), m * CFrame.new(-(CANAL_HALF - 1), -7, 0), STONE_DARK, Enum.Material.Limestone)
		block("CanalLedge", V(4, 1, 220), m * CFrame.new(-(CANAL_HALF - 4), LEDGE_Y - 0.5, 0), STONE, Enum.Material.Cobblestone)
		deco("LedgeEdge", V(0.4, 0.3, 220), m * CFrame.new(-(CANAL_HALF - 6.2), LEDGE_Y + 0.05, 0), C.Yellow, Enum.Material.SmoothPlastic)
		-- Farolillos del canal
		for z = -90, 90, 30 do
			local lamp = deco("CanalLamp", V(0.8, 1, 0.8), m * CFrame.new(-(CANAL_HALF - 2.4), LEDGE_Y + 4, z), RGB(255, 210, 140), Enum.Material.Neon)
			Kit.light(lamp, "PointLight", RGB(255, 200, 130), 14, 1.4)
		end
		-- Escaleras de bajada al canal
		for _, z in { 30, -75 } do
			Kit.stairs(m * V(-(CANAL_HALF - 3), 0, z), m * V(-(CANAL_HALF - 3), LEDGE_Y, z + 15), 3.6, STONE)
		end
		-- Realismo: algas en la línea del agua, mancha de humedad en el muro y bolardos de amarre
		deco("WaterlineAlgae", V(0.06, 0.7, 220), m * CFrame.new(-(CANAL_HALF - 6) + 0.03, WATER_Y + 0.15, 0), RGB(48, 66, 44), Enum.Material.Slate)
		deco("WetStain", V(0.06, 1.2, 220), m * CFrame.new(-(CANAL_HALF - 1) + 1.03, LEDGE_Y + 0.6, 0), STONE_DARK:Lerp(RGB(40, 50, 40), 0.35), Enum.Material.Limestone)
		for z = -100, 100, 20 do
			local nearBridge = math.abs(z) < 12 or math.abs(math.abs(z) - 80) < 8
			local nearStairs = (z >= 26 and z <= 50) or (z >= -79 and z <= -56)
			if not nearBridge and not nearStairs then
				Kit.cylinder("Bollard", 1.4, 1, m * CFrame.new(-(CANAL_HALF - 1), 0.7, z), RGB(40, 42, 46), Enum.Material.Metal, nil, true)
				Kit.ball("BollardCap", 1.3, m * CFrame.new(-(CANAL_HALF - 1), 1.45, z), RGB(40, 42, 46), Enum.Material.Metal, true)
			end
		end
		Kit.manhole(m * V(-75, 0, -30))
		Kit.manhole(m * V(-115, 0, 50))
	end)
	block("CanalFloor", V(16, 1, 220), CFrame.new(0, -14, 0), RGB(60, 70, 60), Enum.Material.Mud)
	workspace.Terrain:FillBlock(CFrame.new(0, (WATER_Y - 14) / 2, 0), V(16, WATER_Y + 14, 222), Enum.Material.Water)
	-- Barca amarrada en el canal
	Kit.boat(CFrame.new(-1, WATER_Y, -40))

	---------------------------------------------------------------------------
	-- Puentes
	---------------------------------------------------------------------------
	local function bridge(z, width)
		block("Bridge", V(CANAL_HALF * 2 + 4, 1.5, width), CFrame.new(0, -0.75, z), STONE, Enum.Material.Cobblestone)
		-- Arco de piedra decorativo bajo el puente
		for _, x in { -6, 0, 6 } do
			deco("Arch", V(4, 1.2, width + 0.2), CFrame.new(x, -2.1 + math.abs(x) * 0.05, z), STONE_DARK, Enum.Material.Limestone)
		end
		for _, side in { -1, 1 } do
			Kit.railing(V(-(CANAL_HALF + 2), 0, z + side * (width / 2 - 0.3)), V(CANAL_HALF + 2, 0, z + side * (width / 2 - 0.3)), 3, RGB(90, 70, 50))
		end
	end
	bridge(0, 18)
	bridge(80, 9)
	bridge(-80, 9)

	---------------------------------------------------------------------------
	-- Torre de control (centro, sobre el puente)
	---------------------------------------------------------------------------
	local towerColor = RGB(200, 185, 160)
	for _, x in { -7, 7 } do
		for _, z in { -7, 7 } do
			block("TowerLeg", V(2.4, 24, 2.4), CFrame.new(x, 12, z), towerColor, Enum.Material.Limestone)
		end
	end
	-- Primer piso (con hueco para la escalera de mano)
	block("TowerFloor1", V(17, 1, 7), CFrame.new(0, 10.5, -5), STONE, Enum.Material.WoodPlanks)
	block("TowerFloor1", V(17, 1, 7), CFrame.new(0, 10.5, 5), STONE, Enum.Material.WoodPlanks)
	block("TowerFloor1", V(6, 1, 3), CFrame.new(-5.5, 10.5, 0), STONE, Enum.Material.WoodPlanks)
	block("TowerFloor1", V(6, 1, 3), CFrame.new(5.5, 10.5, 0), STONE, Enum.Material.WoodPlanks)
	-- Azotea de la torre (con hueco en el centro para la escalera de mano)
	for _, s in { -1, 1 } do
		block("TowerParapet", V(17, 2.6, 1), CFrame.new(0, 24.3, s * 8), towerColor, Enum.Material.Limestone)
		block("TowerParapet", V(1, 2.6, 15), CFrame.new(s * 8, 24.3, 0), towerColor, Enum.Material.Limestone)
		Kit.railing(V(-8.5, 11, s * 8.3), V(8.5, 11, s * 8.3), 3, RGB(90, 70, 50))
	end
	-- Escalera de mano (TrussPart: se puede trepar) del primer piso a la azotea
	local truss = Instance.new("TrussPart")
	truss.Name = "TowerLadder"
	truss.Anchored = true
	truss.Size = V(2, 12, 2)
	truss.CFrame = CFrame.new(0, 16.5, 0)
	truss.Color = RGB(110, 85, 60)
	truss.Parent = folder
	block("TowerTop", V(17, 1, 7.5), CFrame.new(0, 22.5, -4.75), towerColor, Enum.Material.Limestone)
	block("TowerTop", V(17, 1, 7.5), CFrame.new(0, 22.5, 4.75), towerColor, Enum.Material.Limestone)
	block("TowerTop", V(7, 1, 2), CFrame.new(-5, 22.5, 0), towerColor, Enum.Material.Limestone)
	block("TowerTop", V(7, 1, 2), CFrame.new(5, 22.5, 0), towerColor, Enum.Material.Limestone)
	-- Antena y radar
	Kit.cylinder("TowerMast", 10, 0.5, CFrame.new(5, 28, 5), C.Metal, Enum.Material.Metal, nil, true)
	local dish = deco("RadarDish", V(0.4, 4, 4), CFrame.new(-5, 27, -5) * CFrame.Angles(0, math.rad(35), math.rad(70)), RGB(230, 230, 235), Enum.Material.Metal)
	dish.Shape = Enum.PartType.Cylinder
	dish:SetAttribute("Spin", 30)
	Kit.ball("TowerBeacon", 1, CFrame.new(5, 33.5, 5), RGB(255, 40, 40), Enum.Material.Neon, true):SetAttribute("Blink", 1.2)
	-- Estandartes de la torre (neutros)
	for _, s in { -1, 1 } do
		Kit.banner(CFrame.new(0, 21, s * 8.7) * (s > 0 and CFrame.Angles(0, math.pi, 0) or CFrame.new()), 6, 8, RGB(240, 190, 40), C.White)
	end

	---------------------------------------------------------------------------
	-- Mitad simétrica: A (rojo) y B (azul)
	---------------------------------------------------------------------------
	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(200, 45, 40) or RGB(45, 100, 210)

		-- Rampa a la torre desde la orilla
		Kit.stairs(m * V(-32, 0, -3.5), m * V(-8.5, 11, -3.5), 4, STONE)

		-- Casas con azoteas (A1 con escalera exterior; A2 alta, comunicada con A1 por una pasarela)
		Kit.house(m * CFrame.new(-60, 0, 55), V(24, 10, 18), RGB(255, 222, 165), teamColor, { Vines = true, OpenSides = true })
		Kit.stairs(m * V(-45.5, 0, 68), m * V(-45.5, 10, 50), 4, STONE)
		Kit.house(m * CFrame.new(-100, 0, 72), V(20, 15, 16), RGB(255, 196, 180), teamColor, { Vines = true, OpenSides = true })
		Kit.ramp(m * V(-72, 10, 60), m * V(-90, 15, 68), 4, RGB(120, 90, 60), Enum.Material.WoodPlanks)
		Kit.house(m * CFrame.new(-78, 0, -58), V(22, 10, 20), RGB(200, 226, 240), teamColor, { DoorX = -4, OpenSides = true })
		Kit.stairs(m * V(-64.5, 0, -45), m * V(-64.5, 10, -61), 4, STONE)
		Kit.house(m * CFrame.new(-128, 0, -78), V(18, 12, 16), RGB(240, 235, 215), teamColor)

		-- Macetas en las azoteas y guirnaldas sobre el mercado
		Kit.flowerPot(m * CFrame.new(-68, 10, 50), RGB(255, 80, 120))
		Kit.flowerPot(m * CFrame.new(-52, 10, 60), RGB(255, 200, 60))
		Kit.flowerPot(m * CFrame.new(-104, 15, 76), RGB(255, 120, 200))
		Kit.flowerPot(m * CFrame.new(-84, 10, -54), RGB(120, 160, 255))
		-- Flores al pie de las casas y hierba alta en los rincones
		for i, p in { V(-50, 0, 44), V(-88, 0, 62), V(-70, 0, -46), V(-122, 0, -88), V(-140, 0, 72) } do
			Kit.flowers(m * p, 3, i * 11)
		end
		for i, p in { V(-30, 0, 60), V(-125, 0, -60), V(-148, 0, 96), V(-60, 0, -98) } do
			Kit.grassTuft(m * p, 1, i * 5)
		end
		Kit.stringLights(m * V(-44, 9, 12), m * V(-30, 9, 36))
		Kit.stringLights(m * V(-30, 9, 12), m * V(-44, 9, 36))

		-- Estandartes del equipo en las fachadas que miran al centro
		Kit.banner(m * CFrame.new(-55, 9.5, 45.6), 5, 7, teamColor, C.White)
		Kit.banner(m * CFrame.new(-82, 9.5, -47.4), 5, 7, teamColor, C.White)

		-- Mercado con toldos
		for i, z in { 18, 30 } do
			block("Stall", V(8, 3, 5), m * CFrame.new(-38, 1.5, z), RGB(150, 110, 70), Enum.Material.WoodPlanks)
			for _, x in { -3.7, 3.7 } do
				deco("StallPost", V(0.4, 6, 0.4), m * CFrame.new(-38 + x, 3, z - 2.2), RGB(110, 80, 50), Enum.Material.Wood)
			end
			Kit.awning(m * CFrame.new(-38, 6.2, z + 2), 9, 6, i == 1 and teamColor or RGB(240, 160, 40))
			Kit.crate(m * CFrame.new(-33, 0, z + 1), 2.5)
		end

		-- Contenedores y cajas de cobertura
		Kit.container(m * CFrame.new(-32, 0, -32) * CFrame.Angles(0, math.rad(90), 0), side == "A" and C.Red or C.Blue)
		Kit.container(m * CFrame.new(-112, 0, 22), side == "A" and C.Blue or C.Red)
		Kit.crate(m * CFrame.new(-25, 0, 8))
		Kit.crate(m * CFrame.new(-25, 0, 12.5))
		Kit.crate(m * CFrame.new(-25, 4, 10), 3.5)
		Kit.crate(m * CFrame.new(-55, 0, -20), 5)
		Kit.crate(m * CFrame.new(-90, 0, 40))
		Kit.crate(m * CFrame.new(-90, 0, 35), 3)
		Kit.crate(m * CFrame.new(-140, 0, 60), 4)
		Kit.barrel(m * CFrame.new(-50, 0, 10), RGB(40, 90, 180))
		Kit.barrel(m * CFrame.new(-48, 0, 12.5), RGB(180, 50, 40))
		Kit.barrel(m * CFrame.new(-100, 0, -30), RGB(40, 90, 180))
		-- Muros bajos de piedra
		block("StoneWall", V(2, 4, 14), m * CFrame.new(-45, 2, -8), STONE_DARK, Enum.Material.Cobblestone)
		block("StoneWall", V(12, 4, 2), m * CFrame.new(-95, 2, 0), STONE_DARK, Enum.Material.Cobblestone)
		block("StoneWall", V(2, 3, 18), m * CFrame.new(-120, 1.5, -40), STONE_DARK, Enum.Material.Cobblestone)

		-- Palmeras y farolas
		for _, p in { V(-20, 0, 45), V(-20, 0, -55), V(-70, 0, 20), V(-130, 0, 95), V(-55, 0, -95), V(-110, 0, -10) } do
			Kit.palm(m * CFrame.new(p) * CFrame.Angles(0, (p.X + p.Z) % 6, 0), 13 + (math.abs(p.Z) % 4))
		end
		for _, p in { V(-18, 0, 20), V(-18, 0, -30), V(-60, 0, 90), V(-90, 0, -95) } do
			Kit.streetLamp(m * CFrame.new(p) * CFrame.Angles(0, math.rad(90), 0), RGB(255, 225, 170))
		end
	end)

	---------------------------------------------------------------------------
	-- Spawns, banderas, bordes
	---------------------------------------------------------------------------
	local spawnStyle = { Floor = RGB(230, 215, 185), FloorMaterial = Enum.Material.CeramicTiles, Roof = RGB(200, 90, 60), RoofMaterial = Enum.Material.ClayRoofTiles }
	Kit.spawnArea(teams[1], CFrame.new(-145, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-145, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-118, 0, 12))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-118, 0, 12))
	Kit.bounds(320, 220, 60)

	-- Malecón con barandilla hacia el mar (lado +Z) y fachadas al otro lado (lado -Z)
	block("SeaWall", V(320, 3, 3), CFrame.new(0, 1.5, 111.5), STONE_DARK, Enum.Material.Limestone)
	Kit.railing(V(-160, 3, 111.5), V(160, 3, 111.5), 2.5, RGB(240, 240, 245))
	for x = -150, 150, 30 do
		local h = 18 + (math.abs(x) % 4) * 4
		block("BackHouse", V(28, h, 10), CFrame.new(x, h / 2, -116), (x / 30) % 2 == 0 and PLASTER or RGB(240, 210, 180), Enum.Material.Plaster)
		deco("BackRoof", V(29, 1.5, 11), CFrame.new(x, h + 0.75, -116), RGB(200, 90, 60), Enum.Material.ClayRoofTiles)
		for wx = -9, 9, 6 do
			deco("BackWindow", V(2.4, 3, 0.2), CFrame.new(x + wx, h * 0.6, -110.9), RGB(60, 70, 90), Enum.Material.Glass)
		end
	end
	for z = -90, 90, 30 do
		for _, sx in { -1, 1 } do
			block("SideHouse", V(10, 22, 28), CFrame.new(sx * 167, 11, z), PLASTER, Enum.Material.Plaster)
			deco("SideRoof", V(11, 1.5, 29), CFrame.new(sx * 167, 22.75, z), RGB(200, 90, 60), Enum.Material.ClayRoofTiles)
		end
	end

	-- Mar, isla del faro y barco (fondo)
	workspace.Terrain:FillBlock(CFrame.new(0, -12, 322), V(900, 20, 420), Enum.Material.Water)
	Kit.lighthouse(V(120, 0, 300))
	Kit.ship(CFrame.new(-140, -2, 250) * CFrame.Angles(0, math.rad(10), 0), 110)
	Kit.crane(CFrame.new(-60, 0, 150), 42)
	Kit.crane(CFrame.new(40, 0, 160) * CFrame.Angles(0, math.rad(20), 0), 38)

	---------------------------------------------------------------------------
	-- Modos: puntos libres y zonas
	---------------------------------------------------------------------------
	for _, p in {
		V(-130, 0.5, 45), V(-90, 0.5, -15), V(-50, 0.5, 30), V(-40, 0.5, -70), V(-100, 15.5, 72),
		V(-60, 10.5, 55), V(-10, LEDGE_Y + 0.5, 60), V(-70, 0.5, 90), V(-150, 0.5, -60), V(-25, 0.5, -10),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 0, 0), 9, 1)
	Kit.zone(V(-60, 10, 55), 10, 2)
	Kit.zone(V(60, 10, -55), 10, 3)
	Kit.zone(V(-40, 0, -45), 12, 4)
	Kit.zone(V(40, 0, 45), 12, 5)
	-- Realismo: polvo y polen flotando a contraluz sobre el mercado y el puente
	Kit.dustMotes(CFrame.new(0, 7, 0), Vector3.new(120, 12, 60), Color3.fromRGB(255, 245, 215), 16)
	return folder
end

return Map
