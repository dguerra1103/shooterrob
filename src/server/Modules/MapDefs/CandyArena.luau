-- ARENA CARAMELO: arena pequeña y simétrica para duelos rápidos (pensada para Eliminación, pero vale
-- para todos los modos). Tarta de dos pisos en el centro, gominolas y tabletas de chocolate como
-- cobertura, rosquillas, cornisas laterales, pilares de bastón de caramelo y piruletas gigantes de fondo.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "CandyArena",
	Name = "Arena Caramelo",
	Icon = "🍬",
	Description = "Arena pequeña · duelos rápidos · tarta central",
}

Map.Lighting = {
	ClockTime = 14.2,
	Brightness = 3.2,
	Exposure = 0.08,
	Ambient = Color3.fromRGB(135, 120, 140),
	OutdoorAmbient = Color3.fromRGB(175, 165, 190),
	Atmosphere = { Density = 0.2, Offset = 0.2, Color = Color3.fromRGB(255, 225, 245), Decay = Color3.fromRGB(190, 140, 210), Glare = 0, Haze = 0.5 },
	Color = { Saturation = 0.22, Contrast = 0.06, Brightness = 0.03, Tint = Color3.fromRGB(255, 250, 252) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.5,
	SunRays = 0.04,
	ShadowSoftness = 0.3,
	Wind = Vector3.new(2, 0, 1),
	TerrainColors = {
		Grass = Color3.fromRGB(150, 220, 120),
		LeafyGrass = Color3.fromRGB(120, 200, 110),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local MINT = RGB(140, 225, 195) -- paredes
local MINT_DARK = RGB(100, 195, 165)
local PINK = RGB(255, 120, 175) -- bordes y tarta
local FLOOR = RGB(255, 205, 160) -- galleta
local CHOCOLATE = RGB(120, 70, 45)
local CREAM = RGB(255, 245, 235) -- nata (no se vuelve lavanda: ver KEEP_LOOK en MapKit)
local GUMDROPS = { RGB(255, 90, 110), RGB(90, 200, 255), RGB(255, 200, 60), RGB(140, 230, 90), RGB(200, 120, 255) }

local LENGTH, WIDTH = 180, 110

-- Muro de menta con borde rosa
local function wall(name, cf, size, color)
	local part = Kit.block(name, size, cf * CFrame.new(0, size.Y / 2, 0), color or MINT, Enum.Material.SmoothPlastic)
	Kit.deco(name .. "Cap", V(size.X + 0.4, 0.7, size.Z + 0.4), cf * CFrame.new(0, size.Y + 0.35, 0), PINK, Enum.Material.SmoothPlastic)
	return part
end

-- Pilar de bastón de caramelo (blanco con franjas rojas)
local function candyCane(cf, height)
	Kit.cylinder("CandyWhite", height, 3.4, cf * CFrame.new(0, height / 2, 0), CREAM, Enum.Material.SmoothPlastic)
	for y = 2.5, height - 1, 4 do
		Kit.cylinder("CandyRed", 1.3, 3.6, cf * CFrame.new(0, y, 0) * CFrame.Angles(rad(18), 0, 0), RGB(240, 50, 70), Enum.Material.SmoothPlastic, nil, true)
	end
	Kit.ball("CandyTop", 3.8, cf * CFrame.new(0, height, 0), RGB(240, 50, 70), Enum.Material.SmoothPlastic, true)
end

-- Gominola (media bola con azúcar): cobertura baja redondeada
local function gumdrop(position, size, color)
	Kit.ball("Gumdrop", size, CFrame.new(position), color, Enum.Material.SmoothPlastic)
	Kit.ball("GumdropShine", size * 0.22, CFrame.new(position + V(-size * 0.18, size * 0.36, -size * 0.12)), CREAM, Enum.Material.SmoothPlastic, true)
end

-- Tableta de chocolate de pie (cobertura) con onzas marcadas
local function chocolateBar(cf, length)
	Kit.block("ChocolateBar", V(length, 3.6, 1.8), cf * CFrame.new(0, 1.8, 0), CHOCOLATE, Enum.Material.SmoothPlastic)
	for x = -length / 2 + length / 4, length / 2 - 0.1, length / 4 do
		Kit.deco("ChocolateGroove", V(0.25, 3.62, 1.84), cf * CFrame.new(x, 1.8, 0), CHOCOLATE:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.SmoothPlastic)
	end
	Kit.deco("ChocolateWrap", V(length * 0.4, 3.7, 1.9), cf * CFrame.new(length * 0.3, 1.8, 0), RGB(230, 60, 90), Enum.Material.SmoothPlastic)
end

-- Rosquilla de pie hecha con bolas en anillo (cobertura con hueco para asomarse)
local function donut(cf, color)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		Kit.ball("Donut", 2.6, cf * CFrame.new(math.cos(a) * 2.8, 3.1 + math.sin(a) * 2.8, 0), color, Enum.Material.SmoothPlastic)
	end
end

-- Magdalena gigante (cobertura): cápsula de papel con rayas y bola de nata
local function cupcake(cf, color)
	Kit.cylinder("CupcakeBase", 3.4, 5.5, cf * CFrame.new(0, 1.7, 0), color, Enum.Material.SmoothPlastic)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		Kit.deco("CupcakeFold", V(0.4, 3.42, 0.6), cf * CFrame.new(math.cos(a) * 2.7, 1.7, math.sin(a) * 2.7) * CFrame.Angles(0, -a, 0), color:Lerp(Color3.new(1, 1, 1), 0.35), Enum.Material.SmoothPlastic)
	end
	Kit.ball("CupcakeCream", 5.6, cf * CFrame.new(0, 4, 0), RGB(255, 170, 210), Enum.Material.SmoothPlastic)
	Kit.ball("CupcakeCherry", 1.4, cf * CFrame.new(0, 7, 0), RGB(230, 30, 60), Enum.Material.SmoothPlastic, true)
end

-- Muro de barquillo (alto: corta las líneas de tiro largas)
local function waferWall(cf, length)
	Kit.block("Wafer", V(length, 8, 1.6), cf * CFrame.new(0, 4, 0), RGB(235, 180, 100), Enum.Material.SmoothPlastic)
	for y = 1.6, 7, 1.6 do
		Kit.deco("WaferLine", V(length + 0.05, 0.25, 1.65), cf * CFrame.new(0, y, 0), RGB(200, 140, 70), Enum.Material.SmoothPlastic)
	end
	Kit.deco("WaferCream", V(length + 0.1, 0.5, 1.7), cf * CFrame.new(0, 8.1, 0), RGB(255, 150, 200), Enum.Material.SmoothPlastic)
end

-- Pila de caramelos cuadrados de colores (cobertura alta para asomarse)
local function candyStack(cf)
	Kit.block("CandyBlock", V(4, 4, 4), cf * CFrame.new(0, 2, 0), GUMDROPS[1], Enum.Material.SmoothPlastic)
	Kit.block("CandyBlock", V(4, 4, 4), cf * CFrame.new(4.2, 2, 0.4) * CFrame.Angles(0, rad(12), 0), GUMDROPS[2], Enum.Material.SmoothPlastic)
	Kit.block("CandyBlock", V(4, 4, 4), cf * CFrame.new(1.8, 6, 0.2) * CFrame.Angles(0, rad(-8), 0), GUMDROPS[3], Enum.Material.SmoothPlastic)
end

-- Piruleta (palo + caramelo redondo); far = de fondo, más grande y sin colisión
local function lollipop(position, height, diameter, color, far)
	Kit.cylinder("LollipopStick", height, diameter * 0.08, CFrame.new(position + V(0, height / 2, 0)), CREAM, Enum.Material.SmoothPlastic, nil, far)
	-- Disco de cara a la arena (eje a lo largo de Z)
	local candy = Kit.cylinder("Lollipop", diameter * 0.18, diameter, CFrame.new(position + V(0, height + diameter * 0.4, 0)) * CFrame.Angles(rad(90), 0, 0), color, Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("LollipopSwirl", diameter * 0.19, diameter * 0.55, candy.CFrame * CFrame.Angles(0, 0, -rad(90)), CREAM, Enum.Material.SmoothPlastic, nil, true)
end

-- Árbol de algodón de azúcar (de fondo)
local function cottonCandy(position, scale, color)
	Kit.cylinder("CottonStick", 8 * scale, 0.7 * scale, CFrame.new(position + V(0, 4 * scale, 0)), CREAM, Enum.Material.SmoothPlastic, nil, true)
	Kit.ball("CottonCandy", 9 * scale, CFrame.new(position + V(0, 10 * scale, 0)), color, Enum.Material.SmoothPlastic, true)
	Kit.ball("CottonCandy", 6 * scale, CFrame.new(position + V(2 * scale, 13.5 * scale, 1 * scale)), color:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.SmoothPlastic, true)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	-- Suelo de galleta con círculo central rosa
	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), FLOOR, Enum.Material.SmoothPlastic)
	Kit.cylinder("Plaza", 0.2, 56, CFrame.new(0, 0.1, 0), RGB(255, 180, 205), Enum.Material.SmoothPlastic)
	Kit.cylinder("PlazaRing", 0.22, 58, CFrame.new(0, 0.09, 0), PINK, Enum.Material.SmoothPlastic, nil, true)

	-- Muro perimetral de menta con bastones de caramelo
	for _, z in { -1, 1 } do
		wall("OuterWall", CFrame.new(0, 0, z * (WIDTH / 2 + 1.5)), V(LENGTH + 6, 18, 3))
		for x = -75, 75, 30 do
			-- (sin pilar donde están las cornisas laterales)
			if not (math.abs(x) < 60 and math.sign(x) == z) then
				candyCane(CFrame.new(x, 0, z * (WIDTH / 2 - 0.5)), 19)
			end
		end
	end
	for _, x in { -1, 1 } do
		wall("OuterWall", CFrame.new(x * (LENGTH / 2 + 1.5), 0, 0), V(3, 18, WIDTH + 6))
		for _, z in { -40, 40 } do
			candyCane(CFrame.new(x * (LENGTH / 2 - 0.5), 0, z), 19)
		end
	end

	-- Tarta central de dos pisos (se sube por escaleras): piso 1 a 4 de altura, piso 2 a 8
	Kit.cylinder("CakeTier", 4, 28, CFrame.new(0, 2, 0), PINK, Enum.Material.SmoothPlastic)
	Kit.cylinder("CakeFrosting", 0.5, 28.8, CFrame.new(0, 4.05, 0), CREAM, Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("CakeTier", 4, 14, CFrame.new(0, 6, 0), CHOCOLATE, Enum.Material.SmoothPlastic)
	Kit.cylinder("CakeFrosting", 0.5, 14.6, CFrame.new(0, 8.05, 0), CREAM, Enum.Material.SmoothPlastic, nil, true)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		Kit.ball("FrostingDrip", 1.6, CFrame.new(math.cos(a) * 14.1, 3.6, math.sin(a) * 14.1), CREAM, Enum.Material.SmoothPlastic, true)
	end
	-- Vela con llama en el centro de la tarta (decorativa)
	Kit.cylinder("Candle", 3, 0.8, CFrame.new(0, 9.6, 0), RGB(120, 200, 255), Enum.Material.SmoothPlastic, nil, true)
	local flame = Kit.ball("CandleFlame", 0.9, CFrame.new(0, 11.4, 0), RGB(255, 200, 80), Enum.Material.Neon, true)
	Kit.light(flame, "PointLight", RGB(255, 190, 110), 14, 1.2)

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(255, 90, 110) or RGB(90, 160, 255)
		-- Escaleras de la tarta: al piso 1 desde el lado del equipo y al piso 2 de lado
		Kit.stairs((m * CFrame.new(-24, 0, 0)).Position, (m * CFrame.new(-13.6, 4, 0)).Position, 6, PINK:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.SmoothPlastic)
		Kit.stairs((m * CFrame.new(0, 4, -13)).Position, (m * CFrame.new(0, 8, -6.8)).Position, 4, CHOCOLATE:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.SmoothPlastic)

		-- Cornisa lateral (piso a 7) con escalera y barandilla
		local ledgeY = 7
		block("Ledge", V(34, 1, 7), m * CFrame.new(-28, ledgeY - 0.5, -(WIDTH / 2 - 3.5)), MINT_DARK, Enum.Material.SmoothPlastic)
		deco("LedgeTrim", V(34.4, 0.5, 0.4), m * CFrame.new(-28, ledgeY - 0.75, -(WIDTH / 2 - 7.2)), PINK, Enum.Material.SmoothPlastic)
		for _, x in { -42, -14 } do
			Kit.cylinder("LedgeLeg", ledgeY - 1, 1.6, m * CFrame.new(x, (ledgeY - 1) / 2, -(WIDTH / 2 - 6)), CREAM, Enum.Material.SmoothPlastic)
		end
		Kit.stairs((m * CFrame.new(-60, 0, -(WIDTH / 2 - 3.5))).Position, (m * CFrame.new(-45, ledgeY, -(WIDTH / 2 - 3.5))).Position, 5, MINT_DARK, Enum.Material.SmoothPlastic)
		Kit.railing((m * CFrame.new(-44, ledgeY, -(WIDTH / 2 - 7))).Position, (m * CFrame.new(-12, ledgeY, -(WIDTH / 2 - 7))).Position, 2.4, PINK)

		-- Coberturas: tabletas de chocolate, gominolas y rosquillas
		chocolateBar(m * CFrame.new(-38, 0, 14), 10)
		chocolateBar(m * CFrame.new(-30, 0, -24) * CFrame.Angles(0, rad(90), 0), 8)
		chocolateBar(m * CFrame.new(-56, 0, 34), 9)
		gumdrop((m * CFrame.new(-46, 0, -10)).Position, 7, GUMDROPS[1])
		gumdrop((m * CFrame.new(-20, 0, 30)).Position, 6, GUMDROPS[2])
		gumdrop((m * CFrame.new(-64, 0, -44)).Position, 6.5, GUMDROPS[3])
		gumdrop((m * CFrame.new(-10, 0, -40)).Position, 5.5, GUMDROPS[4])
		gumdrop((m * CFrame.new(-70, 0, 42)).Position, 6, GUMDROPS[5])
		donut(m * CFrame.new(-50, 0, 22) * CFrame.Angles(0, rad(90), 0), side == "A" and RGB(255, 150, 190) or RGB(150, 200, 255))
		donut(m * CFrame.new(-24, 0, 44), RGB(255, 200, 120))
		cupcake(m * CFrame.new(-12, 0, 22), GUMDROPS[5])
		cupcake(m * CFrame.new(-42, 0, -42), GUMDROPS[2])
		waferWall(m * CFrame.new(-6, 0, 34), 14)
		waferWall(m * CFrame.new(-54, 0, -16) * CFrame.Angles(0, rad(90), 0), 10)
		candyStack(m * CFrame.new(-36, 0, -6) * CFrame.Angles(0, rad(20), 0))
		candyStack(m * CFrame.new(-52, 0, 46))
		-- Plataformas de salto: a la tarta y a la cornisa
		Kit.jumpPad((m * CFrame.new(-17, 0, -8)).Position, 75)
		Kit.jumpPad((m * CFrame.new(-28, 0, -40)).Position, 75, RGB(255, 120, 200))

		-- Piruletas medianas (solo decoración, se atraviesan) y caramelos en el suelo
		lollipop((m * CFrame.new(-80, 0, -46)).Position, 7, 5, teamColor, true)
		lollipop((m * CFrame.new(-36, 0, 48)).Position, 6, 4.5, GUMDROPS[3], true)
		for i, p in { V(-28, 0.3, 6), V(-60, 0.3, -6), V(-44, 0.3, 40), V(-14, 0.3, -18) } do
			Kit.ball("Sprinkle", 0.7, m * CFrame.new(p), GUMDROPS[i % #GUMDROPS + 1], Enum.Material.SmoothPlastic, true)
		end
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(255, 225, 235), Roof = MINT_DARK }
	Kit.spawnArea(teams[1], CFrame.new(-75, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-75, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-52, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-52, 0, 0))

	-- Fondo: piruletas gigantes, árboles de algodón de azúcar y colinas
	Kit.bounds(LENGTH, WIDTH, 45)
	local farColors = { RGB(255, 120, 180), RGB(120, 200, 255), RGB(255, 210, 90), RGB(170, 120, 255), RGB(120, 230, 160) }
	local n = 0
	for x = -130, 130, 26 do
		for _, z in { -1, 1 } do
			n += 1
			local color = farColors[n % #farColors + 1]
			if n % 3 == 0 then
				lollipop(V(x + z * 7, 0, z * (WIDTH / 2 + 22 + (n % 4) * 6)), 24 + (n % 3) * 6, 14, color, true)
			else
				cottonCandy(V(x + z * 7, 0, z * (WIDTH / 2 + 16 + (n % 5) * 5)), 1.2 + (n % 3) * 0.2, color)
			end
		end
	end
	for _, sx in { -1, 1 } do
		for z = -60, 60, 40 do
			cottonCandy(V(sx * (LENGTH / 2 + 20 + (math.abs(z) % 3) * 6), 0, z), 1.4, farColors[(z // 40) % #farColors + 1])
		end
	end
	for x = -180, 180, 70 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -18, z * 125), 46, Enum.Material.Grass, { Inward = V(0, 0, -z), Top = Enum.Material.LeafyGrass, RockCount = 0 })
		end
	end
	for _, sx in { -1, 1 } do
		for _, z in { -50, 20 } do
			Kit.naturalHill(V(sx * 150, -18, z), 48, Enum.Material.Grass, { Inward = V(-sx, 0, 0), Top = Enum.Material.LeafyGrass, RockCount = 0 })
		end
	end

	-- Modos
	for _, p in {
		V(-66, 0.5, 14), V(-66, 0.5, -14), V(-44, 0.5, 0), V(-34, 0.5, 34), V(-36, 0.5, -36),
		V(-20, 0.5, 16), V(-16, 0.5, -26), V(-28, 7.5, -51.5), V(-6, 4.5, -9), V(-70, 0.5, -46),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 8.3, 0), 6, 1)
	Kit.zone(V(-34, 0, 30), 6, 2)
	Kit.zone(V(34, 0, -30), 6, 3)
	Kit.zone(V(-28, 7, -51.5), 5, 4)
	Kit.zone(V(28, 7, 51.5), 5, 5)
	Kit.dustMotes(CFrame.new(0, 8, 0), V(100, 14, 70), Color3.fromRGB(255, 200, 235), 14)
	return folder
end

return Map
