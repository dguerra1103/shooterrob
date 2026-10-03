-- CONTAINER CLASH: patio de contenedores al atardecer. Calle central con pila central,
-- pasillos laterales entre contenedores, pasarelas elevadas y almacenes como zonas de salida.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "ContainerClash",
	Name = "Container Clash",
	Description = "Puerto · atardecer · pasillos y pasarelas",
}

Map.Lighting = {
	ClockTime = 17.6,
	Brightness = 2.8,
	Exposure = 0.1,
	Ambient = Color3.fromRGB(110, 80, 75),
	OutdoorAmbient = Color3.fromRGB(175, 125, 105),
	Atmosphere = { Density = 0.33, Offset = 0.15, Color = Color3.fromRGB(255, 190, 140), Decay = Color3.fromRGB(190, 95, 90), Glare = 0.8, Haze = 2 },
	Color = { Saturation = 0.35, Contrast = 0.12, Brightness = 0.02, Tint = Color3.fromRGB(255, 228, 205) },
	Bloom = { Intensity = 1, Size = 28, Threshold = 1.4 },
	Clouds = 0.5,
	CloudColor = Color3.fromRGB(255, 200, 170),
	SunRays = 0.12,
}

local V = Vector3.new
local RGB = Color3.fromRGB
local C = Kit.C

local CONCRETE = RGB(150, 146, 140)
local COLORS = { RGB(210, 60, 45), RGB(45, 110, 210), RGB(240, 150, 30), RGB(60, 160, 90), RGB(130, 135, 145), RGB(230, 230, 235) }

-- Contenedor ligero (pocas piezas) para muros y fondos
local function lite(cf, color, decorative)
	local fn = decorative and Kit.deco or Kit.block
	fn("Container", V(20, 8.5, 8), cf * CFrame.new(0, 4.25, 0), color, Enum.Material.CorrodedMetal)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	for i = -1, 1 do
		Kit.deco("Rib", V(0.5, 8.3, 8.2), cf * CFrame.new(i * 7, 4.25, 0), dark, Enum.Material.Metal)
	end
	Kit.deco("Roof", V(20.2, 0.3, 8.2), cf * CFrame.new(0, 8.6, 0), dark, Enum.Material.Metal)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo con marcas amarillas
	block("Yard", V(340, 2, 240), CFrame.new(0, -1, 0), CONCRETE, Enum.Material.Concrete)
	for _, z in { -30, 30, -90, 90 } do
		deco("LaneLine", V(260, 0.05, 0.8), CFrame.new(0, 0.03, z), C.Yellow, Enum.Material.SmoothPlastic)
	end
	for x = -120, 120, 40 do
		deco("CrossLine", V(0.8, 0.05, 240), CFrame.new(x, 0.03, 0), RGB(200, 190, 120), Enum.Material.SmoothPlastic)
	end
	for i = 1, 14 do
		local x, z = ((i * 53) % 260) - 130, ((i * 71) % 200) - 100
		deco("Stain", V(6 + i % 4, 0.04, 4 + i % 3), CFrame.new(x, 0.025, z) * CFrame.Angles(0, i, 0), RGB(90, 88, 85), Enum.Material.Concrete).Transparency = 0.5
	end

	-- Pila central (dos contenedores a lo largo de Z y uno encima)
	Kit.container(CFrame.new(0, 0, -11) * CFrame.Angles(0, math.rad(90), 0), COLORS[5], "CENTER")
	Kit.container(CFrame.new(0, 0, 11) * CFrame.Angles(0, math.rad(90), 0), COLORS[5], "CENTER")
	Kit.container(CFrame.new(0, 8.9, 0) * CFrame.Angles(0, math.rad(90), 0), C.Yellow, "STACK 01")

	-- Grúa pórtico sobre el centro con un contenedor colgando
	local gantry = RGB(245, 185, 35)
	for _, x in { -22, 22 } do
		for _, z in { -38, 38 } do
			block("GantryLeg", V(2.5, 40, 2.5), CFrame.new(x, 20, z), gantry, Enum.Material.Metal)
		end
		block("GantryBeam", V(2.5, 3, 78), CFrame.new(x, 40, 0), gantry, Enum.Material.Metal)
	end
	block("GantryCross", V(46, 3, 3), CFrame.new(0, 41, -8), gantry, Enum.Material.Metal)
	deco("GantryCable", V(0.3, 9, 0.3), CFrame.new(0, 35, -8), RGB(30, 30, 30), Enum.Material.Metal)
	lite(CFrame.new(0, 22, -8) * CFrame.Angles(0, math.rad(90), 0), RGB(210, 70, 50), true)
	Kit.ball("GantryBeacon", 1, CFrame.new(0, 43, -8), RGB(255, 60, 40), Enum.Material.Neon, true):SetAttribute("Blink", 1)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(210, 50, 45) or RGB(45, 110, 220)

		-- Pasillo lateral: dos filas de contenedores con huecos
		for i, x in { -104, -80, -50, -20 } do
			local c1 = COLORS[(i % #COLORS) + 1]
			local c2 = COLORS[((i + 2) % #COLORS) + 1]
			if i ~= 3 then
				Kit.container(m * CFrame.new(x, 0, -48), c1)
			end
			Kit.container(m * CFrame.new(x + 4, 0, -76), c2)
			if i % 2 == 0 then
				Kit.container(m * CFrame.new(x + 4, 8.9, -76), COLORS[((i + 4) % #COLORS) + 1])
			end
		end
		-- Rampa de cajas para subir a la fila alta del pasillo
		Kit.ramp(m * V(-100, 0, -55), m * V(-100, 8.6, -71.5), 5, RGB(150, 120, 80), Enum.Material.WoodPlanks)

		-- Contenedores y cobertura de la zona media
		Kit.container(m * CFrame.new(-55, 0, 25), COLORS[2])
		Kit.container(m * CFrame.new(-55, 0, 33.4), COLORS[1])
		Kit.container(m * CFrame.new(-30, 0, 55) * CFrame.Angles(0, math.rad(90), 0), COLORS[4])
		Kit.container(m * CFrame.new(-95, 0, 18) * CFrame.Angles(0, math.rad(90), 0), COLORS[3])
		Kit.metalCrate(m * CFrame.new(-25, 0, 22), 4)
		Kit.metalCrate(m * CFrame.new(-21, 0, 22), 4)
		Kit.metalCrate(m * CFrame.new(-23, 4, 22), 3.5)
		Kit.crate(m * CFrame.new(-70, 0, -10), 5)
		Kit.crate(m * CFrame.new(-40, 0, -15))
		Kit.crate(m * CFrame.new(-40, 0, -19.5), 3)
		Kit.crate(m * CFrame.new(-120, 0, 40))
		Kit.barrel(m * CFrame.new(-45, 0, 0), RGB(40, 90, 180))
		Kit.barrel(m * CFrame.new(-43, 0, 2.3), RGB(40, 90, 180))
		Kit.barrel(m * CFrame.new(-100, 0, -30), RGB(200, 60, 40))
		Kit.barrel(m * CFrame.new(-35, 0, 80), RGB(60, 160, 90))
		for _, p in { V(-60, 0, 0), V(-62, 0, 4), V(-15, 0, 40), V(-80, 0, 45) } do
			Kit.cone(m * CFrame.new(p))
		end
		Kit.forklift(m * CFrame.new(-75, 0, 60) * CFrame.Angles(0, math.rad(30), 0))

		-- Pasarela elevada delante del almacén con escaleras
		local walkY = 10
		block("Catwalk", V(8, 1, 100), m * CFrame.new(-118, walkY - 0.5, 0), RGB(80, 82, 92), Enum.Material.DiamondPlate)
		for z = -48, 48, 16 do
			block("CatwalkLeg", V(1, walkY - 1, 1), m * CFrame.new(-115, (walkY - 1) / 2, z), C.Metal, Enum.Material.Metal)
		end
		Kit.railing(m * V(-114.2, walkY, -50), m * V(-114.2, walkY, 50), 3, C.Yellow)
		Kit.stairs(m * V(-118, 0, 72), m * V(-118, walkY, 52), 6, RGB(120, 122, 130))
		Kit.stairs(m * V(-118, 0, -72), m * V(-118, walkY, -52), 6, RGB(120, 122, 130))

		-- Almacén de salida: paredes, número grande y estandartes
		local wallColor = RGB(120, 118, 115)
		block("WarehouseWall", V(32, 22, 2), m * CFrame.new(-145, 11, 37), wallColor, Enum.Material.CorrodedMetal)
		block("WarehouseWall", V(32, 22, 2), m * CFrame.new(-145, 11, -37), wallColor, Enum.Material.CorrodedMetal)
		block("WarehouseRoof", V(34, 1.5, 76), m * CFrame.new(-145, 22.5, 0), RGB(90, 88, 86), Enum.Material.CorrodedMetal)
		local front = block("WarehouseFront", V(2, 6, 76), m * CFrame.new(-129.5, 19.5, 0), wallColor, Enum.Material.CorrodedMetal)
		Kit.sign(front, Enum.NormalId.Right, side == "A" and "02" or "03", RGB(240, 240, 240), RGB(30, 30, 30))
		for _, z in { -30, 30 } do
			Kit.banner(m * CFrame.new(-128.2, 17, z) * CFrame.Angles(0, math.rad(-90), 0), 5, 9, teamColor, C.White)
		end
		for _, z in { -20, 20 } do
			local lamp = deco("WarehouseLamp", V(1.4, 0.6, 3), m * CFrame.new(-128.5, 15.6, z), RGB(255, 220, 160), Enum.Material.Neon)
			Kit.light(lamp, "SpotLight", RGB(255, 210, 150), 30, 2, Enum.NormalId.Bottom).Angle = 110
		end
	end)

	-- Spawns y banderas
	local spawnStyle = { Floor = RGB(110, 108, 106), FloorMaterial = Enum.Material.Concrete, Roof = RGB(90, 88, 86), RoofMaterial = Enum.Material.CorrodedMetal }
	Kit.spawnArea(teams[1], CFrame.new(-145, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-145, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-102, 0, -2))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-102, 0, -2))

	-- Muro perimetral de contenedores (2 alturas) y límites
	Kit.bounds(320, 220, 60)
	for x = -150, 150, 21 do
		for _, z in { -114, 114 } do
			lite(CFrame.new(x, 0, z), COLORS[(math.abs(x) // 21 + (z > 0 and 1 or 0)) % #COLORS + 1])
			lite(CFrame.new(x, 8.9, z), COLORS[(math.abs(x) // 21 + 3) % #COLORS + 1], true)
		end
	end

	-- Fondo: grúas, barcos, más contenedores y el mar al atardecer
	workspace.Terrain:FillBlock(CFrame.new(0, -12, 330), V(1000, 20, 400), Enum.Material.Water)
	block("Quay", V(600, 4, 30), CFrame.new(0, -2, 135), RGB(120, 118, 115), Enum.Material.Concrete)
	for i, x in { -180, -100, -20, 60, 140, 220 } do
		Kit.crane(CFrame.new(x, 0, 140) * CFrame.Angles(0, math.rad(180), 0), 50 + (i % 3) * 6, i % 2 == 0 and RGB(220, 70, 50) or RGB(245, 185, 35))
	end
	Kit.ship(CFrame.new(-60, -2, 190), 140)
	Kit.ship(CFrame.new(160, -2, 260) * CFrame.Angles(0, math.rad(-12), 0), 110)
	for x = -220, 220, 21 do
		for row = 0, 2 do
			lite(CFrame.new(x, row * 8.6, -140 - (x % 3) * 9), COLORS[(math.abs(x) // 21 + row) % #COLORS + 1], true)
		end
	end
	for z = -100, 100, 25 do
		for _, sx in { -1, 1 } do
			lite(CFrame.new(sx * 175, 0, z) * CFrame.Angles(0, math.rad(90), 0), COLORS[(math.abs(z) // 25) % #COLORS + 1], true)
			lite(CFrame.new(sx * 175, 8.6, z) * CFrame.Angles(0, math.rad(90), 0), COLORS[(math.abs(z) // 25 + 2) % #COLORS + 1], true)
		end
	end

	-- Modos
	for _, p in {
		V(-130, 0.5, 50), V(-100, 0.5, -36), V(-70, 0.5, 10), V(-40, 0.5, 40), V(-35, 0.5, -60),
		V(-118, 10.5, 30), V(-118, 10.5, -30), V(-90, 0.5, 90), V(-15, 0.5, -30), V(-60, 0.5, -90),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 0, 30), 10, 1)
	Kit.zone(V(-60, 0, -62), 10, 2)
	Kit.zone(V(60, 0, 62), 10, 3)
	Kit.zone(V(0, 0, -30), 10, 4)
	Kit.zone(V(-75, 0, 10), 10, 5)
	return folder
end

return Map
