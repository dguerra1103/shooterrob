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
local FLOOR_H = 8 -- altura de cada planta
local WALL_T = 1.2 -- grosor de los muros

local PALETTE = {
	Plaster = { RGB(196, 178, 150), RGB(182, 160, 128), RGB(206, 192, 168), RGB(170, 150, 122), RGB(188, 168, 140) },
	Brick = RGB(150, 92, 70),
	Concrete = RGB(150, 146, 138),
	Trim = RGB(120, 106, 88),
	Dark = RGB(60, 56, 52),
	Sand = RGB(190, 168, 128),
	Rust = RGB(120, 70, 45),
}

local block, deco = Kit.block, Kit.deco

---------------------------------------------------------------------------
-- Piezas de construcción
---------------------------------------------------------------------------

-- Muro a lo largo de su eje X local con huecos (puertas y ventanas de verdad: se ve y se dispara a
-- través). cf = centro de la base del muro. openings = { { X = centro, W = ancho, Y0 = abajo, Y1 = arriba } }
local function wall(cf, length, height, color, material, openings)
	openings = openings or {}
	-- Columnas: los huecos con la misma X (ventana de abajo y de arriba) se cortan juntos
	local columns = {}
	for _, o in openings do
		local column
		for _, c in columns do
			if math.abs(c.X - o.X) < 0.01 and math.abs(c.W - o.W) < 0.01 then
				column = c
			end
		end
		if not column then
			column = { X = o.X, W = o.W, Holes = {} }
			table.insert(columns, column)
		end
		table.insert(column.Holes, o)
	end
	table.sort(columns, function(a, b)
		return a.X < b.X
	end)
	local function solid(x0, x1, y0, y1)
		if x1 - x0 > 0.05 and y1 - y0 > 0.05 then
			block("Wall", V(x1 - x0, y1 - y0, WALL_T), cf * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0), color, material)
		end
	end
	local x = -length / 2
	for _, column in columns do
		local x0, x1 = column.X - column.W / 2, column.X + column.W / 2
		solid(x, x0, 0, height)
		table.sort(column.Holes, function(a, b)
			return a.Y0 < b.Y0
		end)
		local y = 0
		for _, o in column.Holes do
			solid(x0, x1, y, o.Y0)
			y = o.Y1
			-- Marco del hueco (dintel y alféizar) para que no parezca un corte en el muro
			deco("Lintel", V(o.W + 0.8, 0.5, WALL_T + 0.3), cf * CFrame.new(o.X, o.Y1 + 0.25, 0), PALETTE.Trim, M.Limestone)
			if o.Y0 > 0.5 then
				deco("Sill", V(o.W + 0.6, 0.35, WALL_T + 0.5), cf * CFrame.new(o.X, o.Y0 - 0.17, 0), PALETTE.Trim, M.Limestone)
			end
		end
		solid(x0, x1, y, height)
		x = x1
	end
	solid(x, length / 2, 0, height)
end

-- Huecos de una fachada: puertas en la planta baja (doors = lista de X) y ventanas cada ~8 studs
-- en cada planta (sin pisar las puertas). windows = false para un muro ciego.
local function facadeOpenings(length, floors, doors, windows)
	local list = {}
	for _, x in doors or {} do
		table.insert(list, { X = x, W = 6, Y0 = 0, Y1 = 7.2 })
	end
	if windows ~= false then
		local count = math.max(1, math.floor(length / 8))
		for f = 0, floors - 1 do
			for i = 1, count do
				local x = -length / 2 + (i - 0.5) * length / count
				local clash = false
				if f == 0 then
					for _, d in doors or {} do
						if math.abs(d - x) < 6 then
							clash = true
						end
					end
				end
				if not clash and math.abs(x) < length / 2 - 2.5 then
					table.insert(list, { X = x, W = 3, Y0 = f * FLOOR_H + 2.8, Y1 = f * FLOOR_H + 6.2 })
				end
			end
		end
	end
	return list
end

-- Edificio en el que se entra. cf = centro de la planta baja (suelo en y = 0); sx = ancho (X local),
-- sz = fondo (Z local, el frente mira a -Z). opts:
--   Floors (1 o 2), Color, Material, Doors = { Front = {x...}, Back = {...}, Left = {...}, Right = {...} },
--   Blind = { Left = true, ... } (muro sin ventanas), Ruined (sin tejado y con el muro roto arriba),
--   Sign = texto del rótulo de la fachada, Lamp (luz dentro)
local function building(cf, sx, sz, opts)
	opts = opts or {}
	local floors = opts.Floors or 2
	local height = floors * FLOOR_H + (opts.Ruined and 0 or 1)
	local color = opts.Color or PALETTE.Plaster[1]
	local material = opts.Material or M.Plaster
	local doors = opts.Doors or {}
	local blind = opts.Blind or {}
	local function face(name, wallCf, length)
		wall(wallCf, length, height, color, material, facadeOpenings(length, floors, doors[name], not blind[name]))
	end
	-- Muros: frente (-Z), fondo (+Z), izquierda (-X) y derecha (+X)
	face("Front", cf * CFrame.new(0, 0, -sz / 2 + WALL_T / 2), sx)
	face("Back", cf * CFrame.new(0, 0, sz / 2 - WALL_T / 2) * CFrame.Angles(0, math.pi, 0), sx)
	face("Left", cf * CFrame.new(-sx / 2 + WALL_T / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), sz - 2 * WALL_T)
	face("Right", cf * CFrame.new(sx / 2 - WALL_T / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), sz - 2 * WALL_T)
	-- Zócalo y cornisa
	deco("Plinth", V(sx + 0.4, 1, sz + 0.4), cf * CFrame.new(0, 0.5, 0), PALETTE.Trim, M.Limestone).CanCollide = false
	-- Suelo interior de baldosas
	deco("InteriorFloor", V(sx - 2 * WALL_T, 0.1, sz - 2 * WALL_T), cf * CFrame.new(0, 0.06, 0), RGB(150, 132, 112), M.CeramicTiles)
	local inner = sx - 2 * WALL_T
	local innerZ = sz - 2 * WALL_T
	if floors >= 2 then
		-- Escalera junto al muro izquierdo (franja de 7 studs) y forjado con el hueco de la escalera
		local stripX = -sx / 2 + WALL_T + 3.5
		local run = math.min(innerZ - 6, 16)
		local z0 = -sz / 2 + WALL_T + 1
		Kit.stairs(cf * V(stripX, 0, z0), cf * V(stripX, FLOOR_H, z0 + run), 6, PALETTE.Concrete, M.Concrete)
		block("Slab", V(inner - 7, 1, innerZ), cf * CFrame.new(-sx / 2 + WALL_T + 7 + (inner - 7) / 2, FLOOR_H - 0.5, 0), PALETTE.Concrete, M.Concrete)
		local landing = innerZ - (run + 1)
		if landing > 0.5 then
			block("Landing", V(7, 1, landing), cf * CFrame.new(stripX, FLOOR_H - 0.5, sz / 2 - WALL_T - landing / 2), PALETTE.Concrete, M.Concrete)
		end
		-- Barandilla del hueco de la escalera
		Kit.railing(cf * V(stripX + 3.6, FLOOR_H, z0 + 0.5), cf * V(stripX + 3.6, FLOOR_H, z0 + run - 0.5), 3, PALETTE.Dark)
	end
	if opts.Ruined then
		-- Muro roto: trozos sueltos por arriba y escombros en el suelo
		for i = 1, 6 do
			local px = ((i * 37) % 100) / 100 - 0.5
			deco("Rubble", V(2 + i % 3, 1 + i % 2, 2 + (i + 1) % 3), cf * CFrame.new(px * (sx - 6), 0.6, ((i * 53) % 100 / 100 - 0.5) * (sz - 6)) * CFrame.Angles(i, i * 2, 0), PALETTE.Concrete, M.Concrete).CanCollide = true
		end
	else
		block("Roof", V(sx + 0.6, 1, sz + 0.6), cf * CFrame.new(0, height - 0.5, 0), PALETTE.Concrete, M.Concrete)
		deco("Cornice", V(sx + 1.2, 0.8, sz + 1.2), cf * CFrame.new(0, height - 1.2, 0), PALETTE.Trim, M.Limestone)
		for _, z in { -1, 1 } do
			deco("Parapet", V(sx + 0.6, 1.8, 0.6), cf * CFrame.new(0, height + 0.9, z * (sz / 2)), color, material)
		end
		for _, x in { -1, 1 } do
			deco("Parapet", V(0.6, 1.8, sz + 0.6), cf * CFrame.new(x * (sx / 2), height + 0.9, 0), color, material)
		end
		-- Depósito de agua y antena en la azotea (silueta de ciudad)
		Kit.cylinder("WaterTank", 3, 3, cf * CFrame.new(sx / 4, height + 1.5, sz / 4), RGB(70, 72, 76), M.Metal, nil, true)
	end
	if opts.Sign then
		local plate = deco("ShopSign", V(math.min(sx - 4, 14), 2.2, 0.3), cf * CFrame.new(0, 8.6, -sz / 2 - 0.3), RGB(40, 38, 36), M.Wood)
		Kit.sign(plate, Enum.NormalId.Front, opts.Sign, RGB(235, 225, 200), RGB(20, 20, 20))
		plate.CanCollide = false
	end
	-- Una luz cálida dentro (las plantas bajas se verían negras al entrar desde el sol)
	if opts.Lamp ~= false then
		for f = 0, floors - 1 do
			local bulb = deco("CeilingLamp", V(1.2, 0.3, 1.2), cf * CFrame.new(sx / 6, f * FLOOR_H + FLOOR_H - 1.2, 0), RGB(255, 220, 170), M.Neon)
			Kit.light(bulb, "PointLight", RGB(255, 210, 160), 22, 0.8)
		end
	end
end

-- Bloque macizo (fachada con ventanas pintadas, no se entra): separa carriles y hace de horizonte
local function solidBlock(cf, sx, sz, height, color, opts)
	opts = opts or {}
	block("Block", V(sx, height, sz), cf * CFrame.new(0, height / 2, 0), color, opts.Material or M.Plaster)
	deco("Plinth", V(sx + 0.4, 1.2, sz + 0.4), cf * CFrame.new(0, 0.6, 0), PALETTE.Trim, M.Limestone)
	deco("Cornice", V(sx + 1, 0.8, sz + 1), cf * CFrame.new(0, height - 0.4, 0), PALETTE.Trim, M.Limestone)
	if opts.Windows ~= false then
		local floors = math.max(1, math.floor(height / FLOOR_H))
		for f = 0, floors - 1 do
			for _, side in { -1, 1 } do
				local count = math.max(1, math.floor(sx / 8))
				for i = 1, count do
					local x = -sx / 2 + (i - 0.5) * sx / count
					deco("Window", V(3, 3.4, 0.2), cf * CFrame.new(x, f * FLOOR_H + 4.4, side * (sz / 2 + 0.1)), RGB(40, 44, 50), M.Glass)
				end
			end
		end
	end
	if opts.Sign then
		local plate = deco("ShopSign", V(math.min(sx - 4, 14), 2.2, 0.3), cf * CFrame.new(0, 8.2, -sz / 2 - 0.3), RGB(40, 38, 36), M.Wood)
		Kit.sign(plate, Enum.NormalId.Front, opts.Sign, RGB(235, 225, 200), RGB(20, 20, 20))
	end
	Kit.contactShadow(cf, sx + 0.4, sz + 0.4)
end

-- Muro de sacos terreros (cobertura baja, hasta el pecho)
local function sandbags(cf, length)
	block("Sandbags", V(length, 3.4, 2.4), cf * CFrame.new(0, 1.7, 0), PALETTE.Sand, M.Fabric)
	local count = math.max(2, math.floor(length / 2.2))
	for i = 1, count do
		local x = -length / 2 + (i - 0.5) * length / count
		deco("Sandbag", V(length / count * 0.95, 0.8, 2.2), cf * CFrame.new(x, 3.6, (i % 2) * 0.2 - 0.1) * CFrame.Angles(0, (i % 3 - 1) * 0.08, 0), PALETTE.Sand:Lerp(RGB(120, 100, 70), (i % 3) * 0.12), M.Fabric)
	end
	Kit.contactShadow(cf, length + 0.4, 2.8)
end

-- Muro en ruinas: tramo con el borde de arriba roto (cobertura alta con huecos para asomarse)
local function ruinWall(cf, length, height, color)
	local pieces = math.max(2, math.floor(length / 3))
	for i = 1, pieces do
		local h = height * (0.55 + ((i * 37) % 45) / 100)
		local x = -length / 2 + (i - 0.5) * length / pieces
		block("RuinWall", V(length / pieces + 0.05, h, 1.4), cf * CFrame.new(x, h / 2, 0), color or PALETTE.Plaster[4], M.Plaster)
	end
	for i = 1, 3 do
		deco("Rubble", V(1.2 + i * 0.4, 0.8, 1 + i * 0.3), cf * CFrame.new((i - 2) * length / 3, 0.4, 1.4) * CFrame.Angles(i, i * 1.7, 0), PALETTE.Concrete, M.Concrete)
	end
end

-- Coche quemado con humo
local function burntCar(cf, smoke)
	local model = Kit.car(cf, RGB(52, 46, 42))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Material == M.Glass then
			part.Transparency = 1 -- sin cristales
		elseif part:IsA("BasePart") and part.Name == "CarBody" then
			part.Material = M.CorrodedMetal
			part.Reflectance = 0
		end
	end
	-- (que tape de verdad: la cabina de cristal no choca)
	local cover = block("CarCover", V(9, 3.6, 4.2), cf * CFrame.new(0, 1.8, 0), RGB(52, 46, 42), M.CorrodedMetal)
	cover.Transparency = 1
	cover.CastShadow = false
	if smoke then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Color = ColorSequence.new(RGB(70, 66, 62), RGB(40, 38, 36))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 12) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(4, 7)
		emitter.Speed = NumberRange.new(3, 6)
		emitter.SpreadAngle = Vector2.new(15, 15)
		emitter.Rate = 3
		emitter.WindAffectsDrag = true
		emitter.Drag = 0.5
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Parent = cover
	end
	return model
end

-- Autobús volcado de lado / atravesado (cobertura grande)
local function bus(cf)
	local body = block("Bus", V(26, 8, 7), cf * CFrame.new(0, 4.2, 0), RGB(190, 150, 60), M.CorrodedMetal)
	deco("BusStripe", V(26.1, 1, 7.1), cf * CFrame.new(0, 3.2, 0), RGB(150, 60, 40), M.CorrodedMetal)
	for i = -2, 2 do
		deco("BusWindow", V(3.6, 2.4, 7.1), cf * CFrame.new(i * 4.6, 6, 0), RGB(30, 30, 32), M.Glass)
	end
	for _, x in { -8.5, 8.5 } do
		for _, z in { -3.4, 3.4 } do
			local wheel = deco("Wheel", V(2.6, 2.6, 0.9), cf * CFrame.new(x, 1.1, z) * CFrame.Angles(0, math.pi / 2, 0), RGB(24, 24, 26), M.Rubber)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	Kit.contactShadow(cf, 26, 7)
	return body
end

-- Tanque destruido (cobertura y silueta)
local function tankWreck(cf)
	block("TankHull", V(14, 3.6, 7.5), cf * CFrame.new(0, 2.6, 0), RGB(78, 82, 64), M.CorrodedMetal)
	for _, z in { -3.6, 3.6 } do
		block("TankTrack", V(15, 2.4, 1.6), cf * CFrame.new(0, 1.2, z), RGB(40, 40, 38), M.Metal)
	end
	block("TankTurret", V(6.5, 2.4, 5.5), cf * CFrame.new(1, 5.6, 0) * CFrame.Angles(0, rad(25), 0), RGB(72, 76, 60), M.CorrodedMetal)
	deco("TankGun", V(9, 0.7, 0.7), cf * CFrame.new(-4, 5.8, -2.2) * CFrame.Angles(0, rad(25), rad(-6)), RGB(60, 62, 52), M.Metal)
	Kit.contactShadow(cf, 15, 8)
end

-- Puesto de mercado con toldo (cobertura media)
local function stall(cf, color)
	block("StallCounter", V(6, 3.2, 2.5), cf * CFrame.new(0, 1.6, 0), RGB(130, 96, 62), M.WoodPlanks)
	for _, x in { -2.8, 2.8 } do
		deco("StallPole", V(0.3, 7, 0.3), cf * CFrame.new(x, 3.5, 1.2), RGB(90, 70, 50), M.Wood)
	end
	deco("StallAwning", V(7, 0.2, 4), cf * CFrame.new(0, 7, 0.4) * CFrame.Angles(rad(-10), 0, 0), color, M.Fabric)
	for i = 1, 3 do
		deco("Goods", V(1.4, 0.8, 1.2), cf * CFrame.new(-2.5 + i * 1.6, 3.6, -0.3), ({ RGB(200, 80, 50), RGB(220, 170, 60), RGB(90, 140, 60) })[i], M.Fabric)
	end
end

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
