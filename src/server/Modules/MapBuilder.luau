-- Genera un mapa urbano simétrico (estilo arena) con contenedores, edificios y rampas.
-- Si ya existe workspace.Map (por ejemplo uno que construyas tú en Studio) no genera nada.
-- Tu mapa propio debe tener SpawnLocations con TeamColor = Really red / Really blue.
local Lighting = game:GetService("Lighting")

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local MapBuilder = {}

local LENGTH = 320 -- eje X (de spawn a spawn)
local WIDTH = 220 -- eje Z
local WALL_HEIGHT = 34

local mapFolder

local function block(name, size, cf, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or mapFolder
	return part
end

-- Rampa inclinada desde "bottom" hasta "top" (posiciones de la superficie)
local function ramp(bottom, top, width, color)
	local mid = (bottom + top) / 2
	local length = (top - bottom).Magnitude
	local cf = CFrame.lookAt(mid, top) * CFrame.new(0, -0.5, 0)
	return block("Ramp", Vector3.new(width, 1, length + 1), cf, color, Enum.Material.DiamondPlate)
end

-- Rotación de 180° alrededor del centro: la mitad del equipo Azul es espejo de la del Rojo
local MIRROR = CFrame.Angles(0, math.pi, 0)

local function symmetric(fn)
	fn(CFrame.new(), "A")
	fn(MIRROR, "B")
end

local function container(cf, color)
	local model = Instance.new("Model")
	model.Name = "Container"
	model.Parent = mapFolder
	local size = Vector3.new(20, 8.5, 8)
	block("Body", size, cf * CFrame.new(0, size.Y / 2, 0), color, Enum.Material.CorrodedMetal, model)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	for i = -4, 4 do
		block("Rib", Vector3.new(0.4, 8.2, 8.3), cf * CFrame.new(i * 2.2, 4.25, 0), dark, Enum.Material.Metal, model)
	end
	block("Roof", Vector3.new(20.2, 0.3, 8.2), cf * CFrame.new(0, 8.6, 0), dark, Enum.Material.Metal, model)
	return model
end

local function crate(cf, size)
	size = size or 4
	return block(
		"Crate",
		Vector3.new(size, size, size),
		cf * CFrame.new(0, size / 2, 0),
		Color3.fromRGB(176, 124, 70),
		Enum.Material.WoodPlanks
	)
end

local function building(cf, size, color)
	local model = Instance.new("Model")
	model.Name = "Building"
	model.Parent = mapFolder
	block("Block", size, cf * CFrame.new(0, size.Y / 2, 0), color, Enum.Material.Concrete, model)
	-- franja decorativa y ventanas
	block(
		"Stripe",
		Vector3.new(size.X + 0.2, 1, size.Z + 0.2),
		cf * CFrame.new(0, size.Y - 1.5, 0),
		Color3.fromRGB(255, 196, 0),
		Enum.Material.SmoothPlastic,
		model
	)
	for i = -1, 1 do
		block(
			"Window",
			Vector3.new(size.X * 0.2, size.Y * 0.35, size.Z + 0.3),
			cf * CFrame.new(i * size.X * 0.3, size.Y * 0.45, 0),
			Color3.fromRGB(120, 190, 255),
			Enum.Material.Glass,
			model
		).Transparency = 0.3
	end
	-- murito de cobertura en la azotea
	local h = 3
	local top = size.Y
	block("Rail", Vector3.new(size.X, h, 1), cf * CFrame.new(0, top + h / 2, -size.Z / 2 + 0.5), color, Enum.Material.Concrete, model)
	block("Rail", Vector3.new(size.X, h, 1), cf * CFrame.new(0, top + h / 2, size.Z / 2 - 0.5), color, Enum.Material.Concrete, model)
	return model
end

local function spawnArea(team, cf)
	-- Zona de spawn con techo y muretes
	local base = block(
		"SpawnFloor",
		Vector3.new(30, 0.4, 70),
		cf * CFrame.new(0, 0.2, 0),
		team.Color.Color:Lerp(Color3.new(1, 1, 1), 0.55),
		Enum.Material.SmoothPlastic
	)
	base.Name = team.Name .. "SpawnFloor"
	block("Roof", Vector3.new(30, 1, 70), cf * CFrame.new(0, 16, 0), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)
	for _, z in { -34, 34 } do
		block("Pillar", Vector3.new(2, 16, 2), cf * CFrame.new(14, 8, z), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)
	end
	for _, z in { -24, 0, 24 } do
		block("Cover", Vector3.new(2, 4, 10), cf * CFrame.new(14, 2, z), team.Color.Color, Enum.Material.SmoothPlastic)
	end

	for i, z in { -24, -8, 8, 24 } do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = team.Name .. "Spawn" .. i
		spawn.Anchored = true
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.CFrame = cf * CFrame.new(-4, 0.5, z) * CFrame.Angles(0, -math.pi / 2, 0)
		spawn.TeamColor = team.Color
		spawn.BrickColor = team.Color
		spawn.Material = Enum.Material.Neon
		spawn.Neutral = false
		spawn.AllowTeamChangeOnTouch = false
		spawn.Duration = GameConfig.SpawnProtection
		spawn.Parent = mapFolder
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
	end
end

-- Base de la bandera: el módulo Flags busca piezas "FlagBase" con el atributo Team.
-- En un mapa propio basta con poner una pieza llamada FlagBase con Team = "Rojo" / "Azul".
local function flagBase(team, cf)
	local ring = block(
		"FlagBaseRing",
		Vector3.new(0.3, 13, 13),
		cf * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.pi / 2),
		team.Color.Color,
		Enum.Material.Neon
	)
	ring.Shape = Enum.PartType.Cylinder
	local pad = block(
		"FlagBase",
		Vector3.new(0.4, 11, 11),
		cf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(235, 235, 240),
		Enum.Material.Concrete
	)
	pad.Shape = Enum.PartType.Cylinder
	pad:SetAttribute("Team", team.Name)
	return pad
end

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(110, 110, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	Lighting.GlobalShadows = true

	local function ensure(className)
		local inst = Lighting:FindFirstChildOfClass(className)
		if not inst then
			inst = Instance.new(className)
			inst.Parent = Lighting
		end
		return inst
	end
	local atmosphere = ensure("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Haze = 1
	atmosphere.Color = Color3.fromRGB(200, 225, 255)
	local cc = ensure("ColorCorrectionEffect")
	cc.Saturation = 0.2
	cc.Contrast = 0.08
	local bloom = ensure("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 20
	bloom.Threshold = 1.4
	ensure("Sky")
end

function MapBuilder.Build()
	setupLighting()
	if workspace:FindFirstChild("Map") then
		return workspace.Map
	end

	-- Quita el Baseplate por defecto de las plantillas
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	-- Suelo
	block("Floor", Vector3.new(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), Color3.fromRGB(196, 200, 210), Enum.Material.Concrete)
	-- Carriles de color
	for _, z in { -70, 0, 70 } do
		block("Lane", Vector3.new(LENGTH - 60, 0.05, 3), CFrame.new(0, 0.03, z), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic)
	end

	-- Muros exteriores
	local wallColor = Color3.fromRGB(163, 196, 230)
	block("Wall", Vector3.new(LENGTH, WALL_HEIGHT, 4), CFrame.new(0, WALL_HEIGHT / 2, WIDTH / 2 + 2), wallColor, Enum.Material.Concrete)
	block("Wall", Vector3.new(LENGTH, WALL_HEIGHT, 4), CFrame.new(0, WALL_HEIGHT / 2, -WIDTH / 2 - 2), wallColor, Enum.Material.Concrete)
	block("Wall", Vector3.new(4, WALL_HEIGHT, WIDTH), CFrame.new(LENGTH / 2 + 2, WALL_HEIGHT / 2, 0), wallColor, Enum.Material.Concrete)
	block("Wall", Vector3.new(4, WALL_HEIGHT, WIDTH), CFrame.new(-LENGTH / 2 - 2, WALL_HEIGHT / 2, 0), wallColor, Enum.Material.Concrete)
	-- Techo invisible para que nadie salga del mapa
	local ceiling = block("Ceiling", Vector3.new(LENGTH, 1, WIDTH), CFrame.new(0, WALL_HEIGHT + 12, 0), Color3.new(1, 1, 1))
	ceiling.Transparency = 1
	ceiling.CanQuery = false

	-- Spawns
	local teams = GameConfig.Teams
	spawnArea(teams[1], CFrame.new(-LENGTH / 2 + 15, 0, 0))
	spawnArea(teams[2], MIRROR * CFrame.new(-LENGTH / 2 + 15, 0, 0))
	flagBase(teams[1], CFrame.new(-118, 0, 12))
	flagBase(teams[2], MIRROR * CFrame.new(-118, 0, 12))

	-- Mitad simétrica del mapa
	symmetric(function(m)
		-- Contenedores
		container(m * CFrame.new(-95, 0, -62), Color3.fromRGB(220, 60, 50))
		container(m * CFrame.new(-95, 0, -62 + 8.4), Color3.fromRGB(40, 120, 220))
		container(m * CFrame.new(-95, 8.9, -58), Color3.fromRGB(240, 150, 30))
		container(m * CFrame.new(-60, 0, 10) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(60, 170, 90))
		container(m * CFrame.new(-35, 0, -85), Color3.fromRGB(240, 150, 30))
		container(m * CFrame.new(-120, 0, 75), Color3.fromRGB(40, 120, 220))

		-- Edificio con azotea accesible por rampa
		building(m * CFrame.new(-75, 0, 68), Vector3.new(26, 12, 22), Color3.fromRGB(245, 245, 250))
		ramp(
			(m * CFrame.new(-38, 0, 74)).Position,
			(m * CFrame.new(-62, 12, 74)).Position,
			7,
			Color3.fromRGB(150, 150, 160)
		)

		-- Pasarela elevada sobre los contenedores
		block("Catwalk", Vector3.new(30, 1, 6), m * CFrame.new(-95, 17.9, -45), Color3.fromRGB(90, 90, 100), Enum.Material.DiamondPlate)
		ramp(
			(m * CFrame.new(-120, 0, -5)).Position,
			(m * CFrame.new(-110, 17.4, -45)).Position,
			6,
			Color3.fromRGB(150, 150, 160)
		)

		-- Cajas de cobertura
		crate(m * CFrame.new(-110, 0, 20))
		crate(m * CFrame.new(-110, 0, 25))
		crate(m * CFrame.new(-110, 4, 22.5))
		crate(m * CFrame.new(-45, 0, 45), 5)
		crate(m * CFrame.new(-80, 0, -20))
		crate(m * CFrame.new(-25, 0, -40), 5)
		crate(m * CFrame.new(-25, 0, -35))

		-- Muros bajos de cobertura
		block("LowWall", Vector3.new(2, 4.5, 16), m * CFrame.new(-40, 2.25, -15), Color3.fromRGB(250, 210, 80), Enum.Material.Concrete)
		block("LowWall", Vector3.new(14, 4.5, 2), m * CFrame.new(-18, 2.25, 40), Color3.fromRGB(250, 210, 80), Enum.Material.Concrete)

		-- Rampa a la plataforma central
		ramp((m * CFrame.new(-34, 0, 0)).Position, (m * CFrame.new(-12, 7, 0)).Position, 8, Color3.fromRGB(150, 150, 160))
	end)

	-- Plataforma central
	block("CenterPlatform", Vector3.new(24, 1, 24), CFrame.new(0, 6.5, 0), Color3.fromRGB(80, 80, 95), Enum.Material.DiamondPlate)
	for _, x in { -10, 10 } do
		for _, z in { -10, 10 } do
			block("Pillar", Vector3.new(2, 6, 2), CFrame.new(x, 3, z), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
		end
	end
	block("CenterCover", Vector3.new(2, 4, 10), CFrame.new(0, 9, 7), Color3.fromRGB(255, 80, 160), Enum.Material.SmoothPlastic)
	block("CenterCover", Vector3.new(2, 4, 10), CFrame.new(0, 9, -7), Color3.fromRGB(255, 80, 160), Enum.Material.SmoothPlastic)

	-- Rascacielos de fondo (decoración fuera de los muros)
	local rng = Random.new(42)
	local skyline = Instance.new("Folder")
	skyline.Name = "Skyline"
	skyline.Parent = mapFolder
	local palette = {
		Color3.fromRGB(120, 170, 230),
		Color3.fromRGB(90, 140, 210),
		Color3.fromRGB(200, 220, 245),
		Color3.fromRGB(70, 110, 180),
	}
	for x = -220, 220, 36 do
		for _, side in { -1, 1 } do
			local h = rng:NextNumber(60, 160)
			local w = rng:NextNumber(24, 34)
			local z = side * (WIDTH / 2 + 40 + rng:NextNumber(0, 30))
			local tower = block(
				"Tower",
				Vector3.new(w, h, w),
				CFrame.new(x, h / 2, z),
				palette[rng:NextInteger(1, #palette)],
				Enum.Material.Glass,
				skyline
			)
			tower.CanCollide = false
			tower.CanQuery = false
			tower.CastShadow = false
			for y = 10, h - 10, 14 do
				local strip = block(
					"Window",
					Vector3.new(w + 0.4, 1, w + 0.4),
					CFrame.new(x, y, z),
					Color3.fromRGB(255, 255, 255),
					Enum.Material.SmoothPlastic,
					skyline
				)
				strip.CanCollide = false
				strip.CanQuery = false
			end
		end
	end
	for _, x in { -1, 1 } do
		for z = -140, 140, 40 do
			local h = rng:NextNumber(50, 130)
			local tower = block(
				"Tower",
				Vector3.new(30, h, 30),
				CFrame.new(x * (LENGTH / 2 + 50), h / 2, z),
				palette[rng:NextInteger(1, #palette)],
				Enum.Material.Glass,
				skyline
			)
			tower.CanCollide = false
			tower.CanQuery = false
			tower.CastShadow = false
		end
	end

	return mapFolder
end

return MapBuilder
