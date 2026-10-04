-- PASTEL PLAZA: arena compacta al estilo de los shooters más jugados de Roblox. Paredes lavanda con
-- pilares rosas, naranjas y amarillos, bordes naranjas, suelo de hierba, torre central de dos alturas,
-- casas laterales con azotea, muros en L, plataformas de hierba y pinos de dibujo animado.
-- Hecho para el estilo "Cartoon" y la textura de cuadrícula (ver assets/textures/LEEME.md).
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "PastelPlaza",
	Name = "Pastel Plaza",
	Icon = "🏰",
	Description = "Arena · mediodía · torre central y azoteas",
}

Map.Lighting = {
	ClockTime = 13.8,
	Brightness = 3.2,
	Exposure = 0.05,
	Ambient = Color3.fromRGB(120, 118, 140),
	OutdoorAmbient = Color3.fromRGB(165, 165, 185),
	Atmosphere = { Density = 0.22, Offset = 0.2, Color = Color3.fromRGB(205, 225, 255), Decay = Color3.fromRGB(120, 150, 210), Glare = 0, Haze = 0.4 },
	Color = { Saturation = 0.2, Contrast = 0.06, Brightness = 0.03, Tint = Color3.fromRGB(255, 252, 248) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.55,
	SunRays = 0.04,
	ShadowSoftness = 0.3,
	Wind = Vector3.new(3, 0, 1),
}

local V = Vector3.new
local RGB = Color3.fromRGB

local WALL = RGB(168, 162, 208) -- lavanda
local WALL_DARK = RGB(140, 134, 186)
local TRIM = RGB(255, 165, 50) -- naranja de los bordes
local PILLARS = { RGB(236, 92, 124), RGB(255, 170, 60), RGB(255, 214, 70) }
local GRASS = RGB(96, 206, 98)
local PLAZA = RGB(210, 205, 235)

local LENGTH, WIDTH = 240, 150

-- Muro con borde naranja encima
local function wall(name, cf, size, color)
	local part = Kit.block(name, size, cf * CFrame.new(0, size.Y / 2, 0), color or WALL, Enum.Material.SmoothPlastic)
	Kit.deco(name .. "Cap", V(size.X + 0.4, 0.7, size.Z + 0.4), cf * CFrame.new(0, size.Y + 0.35, 0), TRIM, Enum.Material.SmoothPlastic)
	return part
end

local function pillar(cf, height, color)
	Kit.block("Pillar", V(3.2, height, 3.2), cf * CFrame.new(0, height / 2, 0), color, Enum.Material.SmoothPlastic)
	Kit.deco("PillarCap", V(3.8, 0.8, 3.8), cf * CFrame.new(0, height + 0.4, 0), TRIM, Enum.Material.SmoothPlastic)
end

-- Cobertura baja con borde naranja
local function cover(cf, size)
	wall("Cover", cf, size, WALL_DARK)
end

-- Plataforma de hierba elevada (lados lavanda y tapa verde) con un escalón para subir
local function grassPlatform(cf, size, height, stepSide)
	Kit.block("PlatformBase", V(size.X, height, size.Z), cf * CFrame.new(0, height / 2, 0), WALL, Enum.Material.SmoothPlastic)
	Kit.block("PlatformTop", V(size.X + 0.6, 0.5, size.Z + 0.6), cf * CFrame.new(0, height + 0.1, 0), GRASS, Enum.Material.SmoothPlastic)
	Kit.block("PlatformStep", V(4, height / 2, 6), cf * CFrame.new(stepSide * (size.X / 2 + 2), height / 4, 0), WALL_DARK, Enum.Material.SmoothPlastic)
end

-- Casa con puerta hacia el centro, ventanas, azotea con murete y escalera exterior
local function house(m, cf)
	local w, d, h, t = 22, 16, 11, 1.4
	-- Paredes: la de +X (hacia el centro) con puerta; la de -Z (hacia la calle) con dos ventanas
	wall("HouseWall", cf * CFrame.new(0, 0, d / 2 - t / 2), V(w, h, t))
	wall("HouseWall", cf * CFrame.new(-w / 2 + t / 2, 0, 0), V(t, h, d - 2 * t))
	-- Pared con puerta (hueco de 5 de ancho y 7 de alto)
	local sideLen = (d - 2 * t - 5) / 2
	for _, s in { -1, 1 } do
		Kit.block("HouseWall", V(t, h, sideLen), cf * CFrame.new(w / 2 - t / 2, h / 2, s * (2.5 + sideLen / 2)), WALL, Enum.Material.SmoothPlastic)
	end
	Kit.block("HouseLintel", V(t, h - 7, 5), cf * CFrame.new(w / 2 - t / 2, 7 + (h - 7) / 2, 0), WALL, Enum.Material.SmoothPlastic)
	-- Pared con ventanas (de 4 de ancho, entre y=4 y y=7)
	local front = cf * CFrame.new(0, 0, -d / 2 + t / 2)
	Kit.block("HouseWallLow", V(w, 4, t), front * CFrame.new(0, 2, 0), WALL, Enum.Material.SmoothPlastic)
	Kit.block("HouseWallHigh", V(w, h - 7, t), front * CFrame.new(0, 7 + (h - 7) / 2, 0), WALL, Enum.Material.SmoothPlastic)
	for _, x in { -w / 2 + 2.5, 0, w / 2 - 2.5 } do
		Kit.block("HouseWallMid", V(x == 0 and 5 or 5, 3, t), front * CFrame.new(x, 5.5, 0), WALL, Enum.Material.SmoothPlastic)
	end
	-- Esquinas de color, tejado y murete
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			pillar(cf * CFrame.new(x * (w / 2), 0, z * (d / 2)), h + 0.5, PILLARS[(x + z) % 3 + 1])
		end
	end
	Kit.block("HouseRoof", V(w, 1, d), cf * CFrame.new(0, h + 0.5, 0), WALL_DARK, Enum.Material.SmoothPlastic)
	for _, z in { -1, 1 } do
		wall("RoofParapet", cf * CFrame.new(0, h + 1, z * (d / 2 - 0.4)), V(w - 4, 1.4, 0.8), WALL)
	end
	-- Escalera exterior por el lado de fuera hasta la azotea
	Kit.stairs((cf * CFrame.new(-w / 2 - 3, 0, -d / 2 + 1)).Position, (cf * CFrame.new(-w / 2 - 3, h + 1, d / 2 - 3)).Position, 5, WALL_DARK, Enum.Material.SmoothPlastic)
	Kit.crate(cf * CFrame.new(-4, 0, 3), 4)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo de hierba, plaza central y caminos
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), GRASS, Enum.Material.SmoothPlastic)
	block("Plaza", V(84, 0.2, 64), CFrame.new(0, 0.1, 0), PLAZA, Enum.Material.SmoothPlastic)

	-- Muro perimetral con pilares de colores y borde naranja
	for _, z in { -1, 1 } do
		wall("OuterWall", CFrame.new(0, 0, z * (WIDTH / 2 + 1.5)), V(LENGTH + 6, 22, 3))
		for i, x in { -108, -78, -48, -18, 18, 48, 78, 108 } do
			pillar(CFrame.new(x, 0, z * (WIDTH / 2)), 23, PILLARS[i % 3 + 1])
		end
	end
	for _, x in { -1, 1 } do
		wall("OuterWall", CFrame.new(x * (LENGTH / 2 + 1.5), 0, 0), V(3, 22, WIDTH + 6))
		for i, z in { -55, -20, 20, 55 } do
			pillar(CFrame.new(x * (LENGTH / 2), 0, z), 23, PILLARS[i % 3 + 1])
		end
	end

	-- Torre central: plataforma a 10 de altura sobre cuatro pilares, con muretes
	local deckY = 10
	block("TowerDeck", V(24, 1.2, 24), CFrame.new(0, deckY, 0), WALL_DARK, Enum.Material.SmoothPlastic)
	deco("TowerDeckTrim", V(24.6, 0.5, 24.6), CFrame.new(0, deckY - 0.75, 0), TRIM, Enum.Material.SmoothPlastic)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			pillar(CFrame.new(x * 10.5, 0, z * 10.5), deckY - 0.6, PILLARS[(x + z) % 3 + 1])
		end
	end
	cover(CFrame.new(0, 0, 0), V(8, 3.5, 2))
	Kit.symmetric(function(m)
		-- Muretes de la torre (con hueco donde llega la escalera)
		wall("TowerParapet", m * CFrame.new(0, deckY + 0.6, -11.6), V(24, 1.4, 0.8))
		wall("TowerParapet", m * CFrame.new(-11.6, deckY + 0.6, 3.75), V(0.8, 1.4, 16.5))
		wall("TowerParapet", m * CFrame.new(-11.6, deckY + 0.6, -10.75), V(0.8, 1.4, 2.5))
		Kit.stairs((m * CFrame.new(-28, 0, -7)).Position, (m * CFrame.new(-12.5, deckY + 0.6, -7)).Position, 5, WALL_DARK, Enum.Material.SmoothPlastic)
	end)

	Kit.symmetric(function(m, side)
		-- Camino de baldosas desde la base al centro
		block("Path", V(52, 0.2, 10), m * CFrame.new(-66, 0.1, 0), PLAZA, Enum.Material.SmoothPlastic)

		house(m, m * CFrame.new(-55, 0, 45))

		-- Muro en L y coberturas bajas
		wall("LWall", m * CFrame.new(-62, 0, -25), V(2, 8, 16))
		wall("LWall", m * CFrame.new(-55, 0, -32), V(12, 8, 2))
		cover(m * CFrame.new(-30, 0, -13), V(10, 3.5, 2))
		cover(m * CFrame.new(-48, 0, 8), V(2, 3.5, 10))
		cover(m * CFrame.new(-75, 0, 20), V(8, 3.5, 2))
		cover(m * CFrame.new(-22, 0, -38), V(2, 3.5, 8))
		cover(m * CFrame.new(-86, 0, -52), V(8, 3.5, 2))

		-- Plataformas de hierba elevadas
		grassPlatform(m * CFrame.new(-35, 0, 32), V(14, 0, 14), 3, 1)
		grassPlatform(m * CFrame.new(-78, 0, -40), V(12, 0, 12), 3, 1)

		-- Barriles, cajas y vegetación
		Kit.barrel(m * CFrame.new(-40, 0, -55), side == "A" and RGB(235, 80, 90) or RGB(70, 140, 255))
		Kit.barrel(m * CFrame.new(-42.5, 0, -52.5), RGB(255, 190, 60))
		Kit.crate(m * CFrame.new(-58, 0, 22), 4)
		Kit.crate(m * CFrame.new(-86, 0, 32), 4)
		Kit.crate(m * CFrame.new(-86, 0, 36.5), 3)
		for _, p in { V(-100, 0, 60), V(-15, 0, 64), V(-60, 0, -66) } do
			Kit.bush(m * p, 1.1, RGB(70, 190, 80))
		end
		for i, p in { V(-30, 0, 55), V(-75, 0, -62), V(-10, 0, -34), V(-96, 0, 44), V(-44, 0, 26) } do
			Kit.flowers(m * p, 3, i * 19)
		end
		for i, p in { V(-50, 0, -62), V(-85, 0, 62), V(-25, 0, 20), V(-68, 0, 8) } do
			Kit.grassTuft(m * p, 1.1, i * 3)
		end
		for _, p in { V(-110, 0, 64), V(-62, 0, 66), V(-22, 0, -66) } do
			Kit.cartoonPine(m * p, 1)
		end
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = PLAZA, Roof = WALL_DARK }
	Kit.spawnArea(teams[1], CFrame.new(-105, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-105, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-80, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-80, 0, 0))

	-- Límites y fondo: pinos y colinas verdes detrás de los muros
	Kit.bounds(LENGTH, WIDTH, 50)
	for x = -150, 150, 26 do
		for _, z in { -1, 1 } do
			Kit.cartoonPine(V(x + z * 9, 0, z * (92 + (math.abs(x) % 17))), 1.4 + (math.abs(x) % 3) * 0.15, true)
		end
	end
	for x = -200, 200, 70 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -18, z * 150), 50, Enum.Material.Grass, { Inward = V(0, 0, -z), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end
	for _, sx in { -1, 1 } do
		for z = -100, 100, 70 do
			Kit.naturalHill(V(sx * 190, -18, z), 52, Enum.Material.Grass, { Inward = V(-sx, 0, 0), Top = Enum.Material.LeafyGrass, RockCount = 1 })
		end
	end

	-- Modos
	for _, p in {
		V(-100, 0.5, 50), V(-80, 0.5, -20), V(-60, 0.5, 0), V(-40, 0.5, 20), V(-25, 0.5, -25),
		V(-55, 0.5, 45), V(-35, 3.85, 32), V(-12, 0.5, 50), V(-92, 0.5, -64), V(-3, deckY + 1.1, -5),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, deckY + 0.6, 0), 7, 1)
	Kit.zone(V(-55, 0, 45), 6, 2)
	Kit.zone(V(55, 0, -45), 6, 3)
	Kit.zone(V(-35, 3.35, 32), 6, 4)
	Kit.zone(V(35, 3.35, -32), 6, 5)
	Kit.dustMotes(CFrame.new(0, 8, 0), V(120, 14, 80), Color3.fromRGB(150, 230, 255), 16)
	return folder
end

return Map
