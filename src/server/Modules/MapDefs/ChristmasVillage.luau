-- VILLA NAVIDEÑA (solo sale en la votación durante el evento de Navidad, ver Season): pueblo nevado
-- al anochecer. En el centro, un árbol de Navidad gigante con bolas y estrella, rodeado de regalos
-- enormes (cobertura); a cada lado, casitas con tejado nevado y ventanas encendidas, un mercadillo
-- con toldos de rayas, una pista de patinaje con murete bajo y el trineo de Papá Noel. Nieve cayendo.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "ChristmasVillage",
	Name = "Villa Navideña",
	Icon = "🎄",
	Description = "Navidad · anochecer · árbol gigante, casitas y pista de patinaje",
	Season = "Navidad", -- (solo con el evento de ese nombre en marcha)
}

Map.Lighting = {
	CartoonNeutral = { Hue = 0.6, Sat = 0.12 },
	ClockTime = 18.3,
	Latitude = 50,
	Brightness = 1.8,
	Exposure = 0.15,
	Ambient = Color3.fromRGB(90, 95, 130),
	OutdoorAmbient = Color3.fromRGB(140, 150, 190),
	Atmosphere = { Density = 0.3, Offset = 0.1, Color = Color3.fromRGB(190, 200, 235), Decay = Color3.fromRGB(110, 110, 170), Glare = 0, Haze = 1.2 },
	Color = { Saturation = 0.15, Contrast = 0.1, Brightness = 0.03, Tint = Color3.fromRGB(240, 242, 255) },
	Bloom = { Intensity = 0.8, Size = 24, Threshold = 1.6 },
	Clouds = 0.6,
	CloudColor = Color3.fromRGB(200, 205, 225),
	SunRays = 0.05,
	Wind = Vector3.new(3, 0, 1),
	TerrainColors = {
		Snow = Color3.fromRGB(235, 240, 250),
		Rock = Color3.fromRGB(100, 105, 120),
	},
}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local SNOW = RGB(238, 243, 252)
local WOOD = RGB(150, 95, 60)
local WOOD_DARK = RGB(100, 62, 40)
local RED = RGB(210, 35, 45)
local GREEN = RGB(35, 140, 70)
local GOLD = RGB(255, 205, 60)
local WARM = RGB(255, 210, 120)
local ICE = RGB(175, 220, 245)
local SMOOTH = Enum.Material.SmoothPlastic

local LENGTH, WIDTH = 200, 130

-- Regalo enorme (cobertura): caja con cinta en cruz y lazo
local function present(cf, size, color, ribbon)
	Kit.block("Present", size, cf * CFrame.new(0, size.Y / 2, 0), color, SMOOTH)
	Kit.deco("PresentRibbon", V(size.X + 0.06, size.Y + 0.06, 0.5), cf * CFrame.new(0, size.Y / 2, 0), ribbon, SMOOTH)
	Kit.deco("PresentRibbon", V(0.5, size.Y + 0.06, size.Z + 0.06), cf * CFrame.new(0, size.Y / 2, 0), ribbon, SMOOTH)
	for _, a in { 45, -45 } do
		Kit.deco("PresentBow", V(0.9, 0.5, 0.3), cf * CFrame.new(0, size.Y + 0.25, 0) * CFrame.Angles(0, rad(a), rad(20)), ribbon, SMOOTH)
	end
end

-- Árbol de Navidad gigante (decoración) con bolas, guirnalda y estrella
local function christmasTree(cf)
	Kit.cylinder("TreeTrunk", 4, 3, cf * CFrame.new(0, 2, 0), WOOD_DARK, Enum.Material.Wood, nil, true)
	local tiers = 6
	for i = 1, tiers do
		local t = (i - 1) / (tiers - 1)
		local d = 22 - 17 * t
		local y = 5 + t * 22
		Kit.cylinder("TreeTier", 5, d, cf * CFrame.new(0, y, 0), GREEN:Lerp(RGB(25, 110, 55), (i % 2) * 0.5), SMOOTH, nil, true)
		Kit.cylinder("TreeSnow", 0.4, d * 0.7, cf * CFrame.new(0, y + 2.6, 0), SNOW, Enum.Material.Snow, nil, true)
		-- Bolas alrededor de cada piso
		local count = math.max(4, math.floor(d * 0.7))
		for k = 0, count - 1 do
			local a = k / count * math.pi * 2 + i
			local colors = { RED, GOLD, RGB(80, 160, 255), RGB(255, 120, 200) }
			Kit.ball("Ornament", 0.9, cf * CFrame.new(math.cos(a) * d / 2, y - 1.6, math.sin(a) * d / 2), colors[(k + i) % #colors + 1], Enum.Material.Neon, true).CastShadow = false
		end
	end
	-- Estrella (dos rombos cruzados que brillan)
	for _, a in { 0, 45 } do
		local star = Kit.deco("TreeStar", V(3, 3, 0.6), cf * CFrame.new(0, 31.5, 0) * CFrame.Angles(0, 0, rad(a)), GOLD, Enum.Material.Neon)
		Kit.light(star, "PointLight", GOLD, 30, 1.5)
	end
end

-- Casita con tejado a dos aguas nevado, chimenea, puerta y ventanas encendidas (paredes = cobertura)
local function cottage(cf, color)
	local w, h, d = 14, 8, 10
	Kit.block("CottageWalls", V(w, h, d), cf * CFrame.new(0, h / 2, 0), color, Enum.Material.Plaster)
	Kit.deco("CottageBase", V(w + 0.4, 1, d + 0.4), cf * CFrame.new(0, 0.5, 0), WOOD_DARK, Enum.Material.Wood)
	for _, s in { -1, 1 } do
		local slope = cf * CFrame.new(0, h + 2.2, s * d / 4) * CFrame.Angles(rad(s * 32), 0, 0)
		Kit.deco("CottageRoof", V(w + 1.6, 0.7, d * 0.62), slope, RED:Lerp(WOOD_DARK, 0.3), SMOOTH)
		Kit.deco("CottageRoofSnow", V(w + 1.7, 0.4, d * 0.6), slope * CFrame.new(0, 0.5, 0), SNOW, Enum.Material.Snow)
	end
	Kit.deco("CottageGable", V(w - 0.2, 3.6, d - 4), cf * CFrame.new(0, h + 1.6, 0), color, Enum.Material.Plaster)
	Kit.deco("Chimney", V(1.8, 5, 1.8), cf * CFrame.new(w / 2 - 3, h + 2.8, d / 4), RGB(150, 70, 55), Enum.Material.Brick)
	Kit.deco("ChimneySnow", V(2, 0.4, 2), cf * CFrame.new(w / 2 - 3, h + 5.4, d / 4), SNOW, Enum.Material.Snow)
	Kit.deco("CottageDoor", V(2.6, 4.4, 0.3), cf * CFrame.new(0, 2.2, -d / 2 - 0.1), WOOD_DARK, Enum.Material.Wood)
	Kit.deco("Wreath", V(1.4, 1.4, 0.3), cf * CFrame.new(0, 3.6, -d / 2 - 0.3) * CFrame.Angles(0, 0, rad(45)), GREEN, SMOOTH)
	for _, x in { -4.2, 4.2 } do
		local window = Kit.deco("CottageWindow", V(2.4, 2.2, 0.2), cf * CFrame.new(x, 4.4, -d / 2 - 0.08), WARM, Enum.Material.Neon)
		window.CastShadow = false
		Kit.deco("WindowFrame", V(2.8, 0.3, 0.3), cf * CFrame.new(x, 3.2, -d / 2 - 0.15), WOOD_DARK, Enum.Material.Wood)
	end
	Kit.stringLights((cf * CFrame.new(-w / 2, h + 0.3, -d / 2 - 0.4)).Position, (cf * CFrame.new(w / 2, h + 0.3, -d / 2 - 0.4)).Position, WARM)
end

-- Puesto del mercadillo navideño (mostrador de cobertura y toldo de rayas rojas)
local function marketStall(cf, text)
	Kit.block("StallCounter", V(8, 3, 1.6), cf * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.Wood)
	Kit.block("StallBack", V(8, 6.5, 0.5), cf * CFrame.new(0, 3.25, 4.5), WOOD_DARK, Enum.Material.Wood)
	for _, x in { -3.8, 3.8 } do
		Kit.cylinder("StallPost", 7, 0.4, cf * CFrame.new(x, 3.5, -0.6), WOOD_DARK, Enum.Material.Wood, nil, true)
	end
	Kit.deco("StallRoof", V(8.6, 0.4, 6), cf * CFrame.new(0, 7, 2), RED, SMOOTH)
	Kit.deco("StallRoofSnow", V(8.7, 0.3, 6), cf * CFrame.new(0, 7.3, 2), SNOW, Enum.Material.Snow)
	Kit.awning(cf * CFrame.new(0, 6.8, -0.6), 8, 2.4, RED)
	for i = 0, 4 do
		local colors = { RED, GOLD, GREEN, RGB(80, 160, 255), RGB(255, 120, 200) }
		Kit.block("StallGift", V(0.9, 0.8, 0.9), cf * CFrame.new(-2.8 + i * 1.4, 3.4, 0), colors[i + 1], SMOOTH)
	end
	Kit.neonSign(cf * CFrame.new(0, 8.4, 2), 6.5, 1.4, text, WARM, RED)
end

-- Trineo de Papá Noel (cobertura) con su saco de regalos
local function sleigh(cf)
	Kit.block("SleighBody", V(4.6, 2.4, 8), cf * CFrame.new(0, 2.2, 0), RED, SMOOTH)
	Kit.deco("SleighTrim", V(4.7, 0.4, 8.1), cf * CFrame.new(0, 3.3, 0), GOLD, Enum.Material.Neon)
	Kit.block("SleighSeatBack", V(4.6, 2.2, 1), cf * CFrame.new(0, 4.4, 3.4), RED, SMOOTH)
	for _, x in { -2.1, 2.1 } do
		Kit.deco("SleighRunner", V(0.4, 0.4, 10), cf * CFrame.new(x, 0.4, -0.6), GOLD, Enum.Material.Metal)
		Kit.deco("SleighRunnerCurl", V(0.4, 1.6, 0.4), cf * CFrame.new(x, 1.1, -5.6), GOLD, Enum.Material.Metal)
	end
	Kit.ball("SleighSack", 3.6, cf * CFrame.new(0, 4.4, 1), RGB(150, 110, 70), Enum.Material.Fabric, true)
	present(cf * CFrame.new(-0.8, 3.4, -1.8), V(1.4, 1.2, 1.4), GREEN, GOLD)
	present(cf * CFrame.new(1, 3.4, -2.4), V(1.2, 1, 1.2), RGB(80, 160, 255), RED)
end

-- Bastón de caramelo gigante (farola)
local function candyCane(cf)
	for i = 0, 8 do
		Kit.cylinder("CaneStripe", 1, 0.7, cf * CFrame.new(0, 0.5 + i, 0), i % 2 == 0 and RED or RGB(250, 250, 250), SMOOTH, nil, true)
	end
	Kit.deco("CaneHook", V(2.2, 0.7, 0.7), cf * CFrame.new(0.8, 9.1, 0), RED, SMOOTH)
	Kit.deco("CaneHookEnd", V(0.7, 1.4, 0.7), cf * CFrame.new(1.6, 8.5, 0), RGB(250, 250, 250), SMOOTH)
	local lamp = Kit.ball("CaneLamp", 0.9, cf * CFrame.new(1.6, 7.6, 0), WARM, Enum.Material.Neon, true)
	Kit.light(lamp, "PointLight", WARM, 16, 1)
	return (cf * CFrame.new(1.6, 8, 0)).Position
end

-- Pista de patinaje: hielo con murete bajo de madera (huecos para entrar)
local function iceRink(cf)
	local sx, sz = 26, 16
	Kit.deco("Rink", V(sx, 0.2, sz), cf * CFrame.new(0, 0.1, 0), ICE, Enum.Material.Ice)
	for _, z in { -1, 1 } do
		for _, x in { -1, 1 } do
			Kit.block("RinkWall", V(sx / 2 - 2.5, 2.4, 0.8), cf * CFrame.new(x * (sx / 4 + 1.25), 1.2, z * sz / 2), WOOD, Enum.Material.Wood)
		end
	end
	for _, x in { -1, 1 } do
		Kit.block("RinkWall", V(0.8, 2.4, sz), cf * CFrame.new(x * sx / 2, 1.2, 0), WOOD, Enum.Material.Wood)
	end
	Kit.snowman(cf * CFrame.new(5, 0.2, 3), 0.8)
end

function Map.Build()
	local folder = Kit.Begin(Map.Name)
	folder:SetAttribute("Ambience", "Snow") -- (sonido ambiente: ver Ambience en el cliente)
	Kit.applyLighting(Map.Lighting)
	local block, deco = Kit.block, Kit.deco
	local teams = GameConfig.Teams

	block("Floor", V(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), SNOW, Enum.Material.Snow)
	-- Caminos pisados en la nieve
	deco("Path", V(LENGTH, 0.06, 10), CFrame.new(0, 0.03, 0), RGB(215, 222, 235), Enum.Material.Snow)
	deco("Path", V(10, 0.06, WIDTH), CFrame.new(0, 0.03, 0), RGB(215, 222, 235), Enum.Material.Snow)

	-- Centro: árbol gigante en una plaza elevada con regalos alrededor
	Kit.cylinder("TreePlaza", 1, 30, CFrame.new(0, 0.5, 0), RGB(200, 205, 220), Enum.Material.Cobblestone)
	christmasTree(CFrame.new(0, 1, 0))
	for i, spot in { { 9, 6, RED, GOLD }, { -8, 8, GREEN, RED }, { -9, -6, RGB(80, 160, 255), GOLD }, { 8, -8, GOLD, RED } } do
		local size = (i % 2 == 0) and V(4, 3.5, 4) or V(3.4, 3, 3.4)
		present(CFrame.new(spot[1], 1, spot[2]) * CFrame.Angles(0, rad(i * 25), 0), size, spot[3], spot[4])
	end

	Kit.symmetric(function(m, side)
		local teamColor = side == "A" and RGB(235, 70, 70) or RGB(60, 130, 240)
		-- Casitas
		cottage(m * CFrame.new(-55, 0, 46), RGB(240, 225, 200))
		cottage(m * CFrame.new(-34, 0, 48) * CFrame.Angles(0, rad(-8), 0), RGB(200, 225, 240))
		cottage(m * CFrame.new(-70, 0, -46) * CFrame.Angles(0, rad(180), 0), RGB(245, 210, 210))
		-- Mercadillo
		marketStall(m * CFrame.new(-22, 0, -40) * CFrame.Angles(0, rad(180), 0), "TURRÓN")
		marketStall(m * CFrame.new(-40, 0, -40) * CFrame.Angles(0, rad(180), 0), "REGALOS")
		-- Pista de patinaje y trineo
		iceRink(m * CFrame.new(-30, 0, 20))
		sleigh(m * CFrame.new(-58, 0, -14) * CFrame.Angles(0, rad(20), 0))
		-- Regalos y muñecos de nieve sueltos (cobertura media)
		present(m * CFrame.new(-46, 0, 8), V(4, 3.2, 4), teamColor, GOLD)
		present(m * CFrame.new(-49, 0, 12), V(3, 2.6, 3), GREEN, RED)
		present(m * CFrame.new(-18, 0, -14), V(3.6, 3, 3.6), RED, GOLD)
		Kit.snowman(m * CFrame.new(-14, 0, 30), 1.1)
		Kit.snowman(m * CFrame.new(-60, 0, 26), 1)
		-- Farolas de bastón de caramelo con guirnaldas
		local a = candyCane(m * CFrame.new(-20, 0, 32))
		local b = candyCane(m * CFrame.new(-48, 0, 32))
		local c = candyCane(m * CFrame.new(-20, 0, -28))
		local d = candyCane(m * CFrame.new(-48, 0, -28))
		Kit.stringLights(a, b, WARM)
		Kit.stringLights(c, d, RGB(255, 120, 120))
		Kit.banner(m * CFrame.new(-68, 12, 30) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, GOLD)
		Kit.banner(m * CFrame.new(-68, 12, -30) * CFrame.Angles(0, rad(90), 0), 4, 6, teamColor, GOLD)
	end)

	-- Bases y banderas
	local spawnStyle = { Floor = RGB(235, 235, 245), Roof = RGB(230, 236, 248) }
	Kit.spawnArea(teams[1], CFrame.new(-85, 0, 0), spawnStyle)
	Kit.spawnArea(teams[2], Kit.MIRROR * CFrame.new(-85, 0, 0), spawnStyle)
	Kit.flagBase(teams[1], CFrame.new(-62, 0, 0))
	Kit.flagBase(teams[2], Kit.MIRROR * CFrame.new(-62, 0, 0))

	-- Fondo: pinos y colinas nevadas
	Kit.bounds(LENGTH, WIDTH, 60)
	-- Nombres de las zonas
	Kit.callout("ÁRBOL GIGANTE", CFrame.new(0, 10, 0), V(32, 30, 32))
	for _, m in { CFrame.new(), Kit.MIRROR } do
		Kit.callout("CASITAS", m * CFrame.new(-48, 8, 47), V(40, 20, 18))
		Kit.callout("MERCADILLO", m * CFrame.new(-31, 8, -40), V(28, 18, 14))
		Kit.callout("PISTA DE HIELO", m * CFrame.new(-30, 6, 20), V(28, 14, 18))
	end
	local rng = Random.new(12)
	for x = -130, 130, 20 do
		for _, z in { -1, 1 } do
			Kit.cartoonPine(V(x + rng:NextNumber(-5, 5), 0, z * (WIDTH / 2 + 30 + rng:NextNumber(0, 18))), 1.7, true)
		end
	end
	for _, sx in { -1, 1 } do
		for z = -60, 60, 30 do
			Kit.cartoonPine(V(sx * (LENGTH / 2 + 14 + rng:NextNumber(0, 10)), 0, z + rng:NextNumber(-6, 6)), 1.6, true)
		end
		for z = -80, 80, 55 do
			Kit.naturalHill(V(sx * 165, -16, z), 42, Enum.Material.Snow, { Inward = V(-sx, 0, 0), Top = Enum.Material.Snow, RockCount = 1 })
		end
	end
	for x = -200, 200, 60 do
		for _, z in { -1, 1 } do
			Kit.naturalHill(V(x, -16, z * 160), 42, Enum.Material.Snow, { Inward = V(0, 0, -z), Top = Enum.Material.Snow, RockCount = 1 })
		end
	end

	-- Nieve cayendo
	local sky = deco("Snowfall", V(LENGTH + 40, 1, WIDTH + 40), CFrame.new(0, 56, 0), SNOW, SMOOTH)
	sky.Transparency = 1
	sky.CastShadow = false
	local snow = Instance.new("ParticleEmitter")
	snow.Name = "Snow"
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.LightEmission = 0.3
	snow.Size = NumberSequence.new(0.25)
	snow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.85, 0.2), NumberSequenceKeypoint.new(1, 1) })
	snow.Lifetime = NumberRange.new(7, 9)
	snow.Speed = NumberRange.new(5, 8)
	snow.SpreadAngle = Vector2.new(15, 15)
	snow.WindAffectsDrag = true
	snow.RotSpeed = NumberRange.new(-60, 60)
	snow.Rate = 110
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Parent = sky

	-- Modos
	for _, p in {
		V(-76, 0.5, 8), V(-76, 0.5, -16), V(-50, 0.5, 2), V(-42, 0.5, 24), V(-30, 0.5, 20),
		V(-24, 0.5, -24), V(-12, 1.5, -12), V(-40, 0.5, -52), V(-62, 0.5, 30), V(-16, 0.5, 44),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Kit.MIRROR * p)
	end
	Kit.zone(V(0, 1, 13), 5, 1)
	Kit.zone(V(-30, 0, 20), 6, 2)
	Kit.zone(V(30, 0, -20), 6, 3)
	Kit.zone(V(-31, 0, -46), 5, 4)
	Kit.zone(V(31, 0, 46), 5, 5)
	return folder
end

return Map
