-- Mapa "Downtown": ciudad simétrica con calles, tiendas, contenedores y plaza central (de día).
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Kit = require(script.Parent.Parent.MapKit)

local Map = {
	Id = "Downtown",
	Name = "Downtown",
	Icon = "🏙",
	Description = "Ciudad · día · calles y azoteas",
}

local LENGTH = 320 -- eje X (de spawn a spawn)
local WIDTH = 220 -- eje Z
local WALL_HEIGHT = 34

local mapFolder

-- Paleta del mapa (colores pastel y vivos, estilo cartoon)
local C = {
	Asphalt = Color3.fromRGB(70, 74, 86),
	Sidewalk = Color3.fromRGB(214, 214, 222),
	Curb = Color3.fromRGB(240, 240, 245),
	LineWhite = Color3.fromRGB(245, 245, 250),
	LineYellow = Color3.fromRGB(255, 205, 50),
	WallBlue = Color3.fromRGB(150, 98, 78), -- ladrillo (el nombre se mantiene por compatibilidad)
	WallTrim = Color3.fromRGB(240, 244, 250),
	Window = Color3.fromRGB(70, 96, 118), -- cristal oscuro que refleja
	Metal = Color3.fromRGB(60, 62, 70),
	Ramp = Color3.fromRGB(150, 152, 165),
	Pink = Color3.fromRGB(255, 80, 170),
	Cyan = Color3.fromRGB(0, 220, 255),
	Leaf = Color3.fromRGB(90, 190, 90),
	LeafDark = Color3.fromRGB(60, 150, 70),
	Wood = Color3.fromRGB(176, 124, 70),
	WoodDark = Color3.fromRGB(120, 80, 45),
}

local function block(name, size, cf, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = Kit.realisticMaterial(size, color, material)
	if part.Material == Enum.Material.Glass then
		part.Reflectance = 0.15
	end
	Kit.applyStyle(part)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or mapFolder
	return part
end

-- Pieza decorativa: no choca, no bloquea disparos y no hace sombra
local function deco(name, size, cf, color, material, parent)
	local part = block(name, size, cf, color, material, parent)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = size.X * size.Y * size.Z >= 20 and part.Material ~= Enum.Material.Neon and part.Material ~= Enum.Material.Glass
	return part
end

-- Cilindro de pie (en Roblox el eje del cilindro es X, lo giramos para que sea vertical)
local function cylinder(name, height, diameter, cf, color, material, parent, decorative)
	local fn = decorative and deco or block
	local part = fn(
		name,
		Vector3.new(height, diameter, diameter),
		cf * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material,
		parent
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Texto pegado a una cara de una pieza (carteles, rótulos de neón...)
local function sign(part, face, text, color, strokeColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = strokeColor or Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return gui
end

-- Rampa inclinada desde "bottom" hasta "top" (posiciones de la superficie)
local function ramp(bottom, top, width, color)
	local mid = (bottom + top) / 2
	local length = (top - bottom).Magnitude
	local cf = CFrame.lookAt(mid, top) * CFrame.new(0, -0.5, 0)
	local part = block("Ramp", Vector3.new(width, 1, length + 1), cf, color, Enum.Material.DiamondPlate)
	-- Franjas amarillas de los bordes
	for _, side in { -1, 1 } do
		deco(
			"RampEdge",
			Vector3.new(0.4, 0.1, length + 1),
			cf * CFrame.new(side * (width / 2 - 0.3), 0.52, 0),
			C.LineYellow,
			Enum.Material.SmoothPlastic
		)
	end
	return part
end

-- Rotación de 180° alrededor del centro: la mitad del equipo Azul es espejo de la del Rojo
local MIRROR = CFrame.Angles(0, math.pi, 0)

local function symmetric(fn)
	fn(CFrame.new(), "A")
	fn(MIRROR, "B")
end

---------------------------------------------------------------------------
-- Piezas del mapa
---------------------------------------------------------------------------

local CARGO_NAMES = { "HYPER CARGO", "NEXO LINE", "FROST CO.", "TURBO SHIP" }
local cargoIndex = 0

local function container(cf, color)
	local model = Instance.new("Model")
	model.Name = "Container"
	model.Parent = mapFolder
	local size = Vector3.new(20, 8.5, 8)
	local body = block("Body", size, cf * CFrame.new(0, size.Y / 2, 0), color, Enum.Material.CorrodedMetal, model)
	Kit.contactShadow(cf, size.X, size.Z, false, model)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	for i = -4, 4, 2 do
		deco("Rib", Vector3.new(0.4, 8.2, 8.3), cf * CFrame.new(i * 2.2, 4.25, 0), dark, Enum.Material.Metal, model)
	end
	block("Roof", Vector3.new(20.2, 0.3, 8.2), cf * CFrame.new(0, 8.6, 0), dark, Enum.Material.Metal, model)
	-- Marco y puertas en un extremo
	deco("DoorFrame", Vector3.new(0.3, 8.6, 8.4), cf * CFrame.new(10.1, 4.25, 0), dark, Enum.Material.Metal, model)
	for _, z in { -2, 2 } do
		deco("LockBar", Vector3.new(0.3, 7.6, 0.25), cf * CFrame.new(10.3, 4.25, z), Color3.fromRGB(200, 200, 205), Enum.Material.Metal, model)
	end
	deco("DoorSplit", Vector3.new(0.35, 8, 0.15), cf * CFrame.new(10.3, 4.25, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal, model)
	-- Desgaste: chorretones de óxido bajando desde el techo
	local rust = color:Lerp(Color3.fromRGB(105, 58, 34), 0.6)
	for i, x in { -7.7, 3.3, 5.5 } do
		local side = i % 2 == 0 and 1 or -1
		local length = 2 + ((cargoIndex + i) % 3) * 1.4
		deco("RustStreak", Vector3.new(0.9, length, 0.06), cf * CFrame.new(x, 8.45 - length / 2, side * 4.04), rust, Enum.Material.CorrodedMetal, model)
	end
	-- Rótulo de la naviera en los dos lados largos
	cargoIndex = cargoIndex % #CARGO_NAMES + 1
	local text = CARGO_NAMES[cargoIndex]
	sign(body, Enum.NormalId.Front, text, Color3.new(1, 1, 1), dark)
	sign(body, Enum.NormalId.Back, text, Color3.new(1, 1, 1), dark)
	return model
end

local function crate(cf, size)
	size = size or 4
	local core = block(
		"Crate",
		Vector3.new(size, size, size),
		cf * CFrame.new(0, size / 2, 0),
		C.Wood,
		Enum.Material.WoodPlanks
	)
	Kit.contactShadow(cf, size, size)
	-- Bandas de refuerzo
	for _, y in { 0.12, 0.88 } do
		deco(
			"CrateBand",
			Vector3.new(size + 0.15, size * 0.12, size + 0.15),
			cf * CFrame.new(0, size * y, 0),
			C.WoodDark,
			Enum.Material.Wood
		)
	end
	return core
end

-- Barrera tipo "jersey" de hormigón con franjas rojas y blancas
local function barrier(size, cf)
	local part = block("Barrier", size, cf * CFrame.new(0, size.Y / 2, 0), Color3.fromRGB(225, 225, 230), Enum.Material.Concrete)
	Kit.contactShadow(cf, size.X, size.Z)
	local long = size.X >= size.Z
	local length = long and size.X or size.Z
	local count = math.max(2, math.floor(length / 3))
	for i = 0, count - 1 do
		local offset = -length / 2 + (i + 0.5) * (length / count)
		local color = i % 2 == 0 and Color3.fromRGB(230, 50, 50) or Color3.fromRGB(250, 250, 250)
		local stripeSize = long and Vector3.new(length / count, 1, size.Z + 0.1) or Vector3.new(size.X + 0.1, 1, length / count)
		local pos = long and CFrame.new(offset, size.Y - 1.2, 0) or CFrame.new(0, size.Y - 1.2, offset)
		deco("Stripe", stripeSize, cf * pos, color, Enum.Material.SmoothPlastic)
	end
	return part
end

local function streetLamp(cf)
	local model = Instance.new("Model")
	model.Name = "StreetLamp"
	model.Parent = mapFolder
	cylinder("Pole", 14, 0.6, cf * CFrame.new(0, 7, 0), C.Metal, Enum.Material.Metal, model)
	cylinder("Base", 1, 1.2, cf * CFrame.new(0, 0.5, 0), C.Metal, Enum.Material.Metal, model)
	deco("Arm", Vector3.new(0.4, 0.4, 4), cf * CFrame.new(0, 13.8, -1.8), C.Metal, Enum.Material.Metal, model)
	local head = deco("Lamp", Vector3.new(1.6, 0.5, 2.2), cf * CFrame.new(0, 13.4, -3.6), C.Metal, Enum.Material.Metal, model)
	local bulb = deco("Bulb", Vector3.new(1.2, 0.2, 1.8), cf * CFrame.new(0, 13.1, -3.6), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, model)
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Range = 26
	light.Angle = 100
	light.Brightness = 1.5
	light.Color = Color3.fromRGB(255, 235, 200)
	light.Shadows = true
	light:SetAttribute("QualityShadow", true)
	light.Parent = bulb
	return head
end

local function tree(cf)
	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = mapFolder
	block("Planter", Vector3.new(5, 1.6, 5), cf * CFrame.new(0, 0.8, 0), Color3.fromRGB(200, 200, 208), Enum.Material.Concrete, model)
	deco("Soil", Vector3.new(4.4, 0.2, 4.4), cf * CFrame.new(0, 1.65, 0), Color3.fromRGB(90, 60, 40), Enum.Material.Ground, model)
	cylinder("Trunk", 7, 0.9, cf * CFrame.new(0, 5, 0), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, model)
	for i, spec in {
		{ Vector3.new(0, 9.5, 0), 6.5, C.Leaf },
		{ Vector3.new(1.6, 8.4, 1), 4.5, C.LeafDark },
		{ Vector3.new(-1.5, 8.8, -1.2), 4.8, C.Leaf },
		{ Vector3.new(0.3, 11.6, -0.4), 4, C.LeafDark },
	} do
		local leaf = deco("Leaves" .. i, Vector3.new(spec[2], spec[2], spec[2]), cf * CFrame.new(spec[1]), spec[3], Enum.Material.Grass, model)
		leaf.Shape = Enum.PartType.Ball
		leaf.CastShadow = true
	end
end

local function bollard(cf)
	cylinder("Bollard", 2.4, 0.8, cf * CFrame.new(0, 1.2, 0), C.LineYellow, Enum.Material.SmoothPlastic)
	cylinder("BollardBand", 0.4, 0.85, cf * CFrame.new(0, 1.9, 0), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic, nil, true)
end

local SHOP_SIGNS = {
	{ "ARCADE", Color3.fromRGB(255, 80, 200) },
	{ "PIZZA", Color3.fromRGB(255, 170, 30) },
	{ "GYM", Color3.fromRGB(0, 220, 255) },
	{ "TACOS", Color3.fromRGB(120, 255, 90) },
}
local signIndex = 0

local brickToggle = false

local function building(cf, size, color)
	local model = Instance.new("Model")
	model.Name = "Building"
	model.Parent = mapFolder
	local trim = color:Lerp(Color3.new(0, 0, 0), 0.15)
	-- La mitad de los edificios son de ladrillo visto (más realista que todo hormigón)
	brickToggle = not brickToggle
	local wallMaterial = brickToggle and Enum.Material.Brick or Enum.Material.Concrete
	block("Block", size, cf * CFrame.new(0, size.Y / 2, 0), color, wallMaterial, model)
	-- Zócalo y cornisa
	deco("Base", Vector3.new(size.X + 0.4, 1.2, size.Z + 0.4), cf * CFrame.new(0, 0.6, 0), trim, Enum.Material.Concrete, model)
	deco("Cornice", Vector3.new(size.X + 0.6, 0.8, size.Z + 0.6), cf * CFrame.new(0, size.Y - 0.4, 0), C.WallTrim, Enum.Material.Concrete, model)
	deco("Stripe", Vector3.new(size.X + 0.3, 0.6, size.Z + 0.3), cf * CFrame.new(0, size.Y - 1.6, 0), C.WallTrim:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Concrete, model)

	-- Ventanas en las cuatro fachadas: una fila por planta, con marco y alféizar
	local floors = math.max(1, math.floor((size.Y - 3) / 7))
	local function windowsOnFace(axis, sign_, count, span, skip)
		for row = 1, floors do
			local y = 4.2 + (row - 1) * 7
			for i = 1, count do
				if i == skip and row == 1 then
					continue
				end
				local t = (i - 0.5) / count - 0.5
				local pos, glassSize, frameSize, sillSize, sillOffset
				if axis == "Z" then
					pos = CFrame.new(t * span, y, sign_ * (size.Z / 2 + 0.1))
					glassSize = Vector3.new(2.6, 3.6, 0.2)
					frameSize = Vector3.new(3.2, 4.2, 0.15)
					sillSize = Vector3.new(3.6, 0.3, 0.6)
					sillOffset = CFrame.new(0, -2.2, sign_ * 0.25)
				else
					pos = CFrame.new(sign_ * (size.X / 2 + 0.1), y, t * span)
					glassSize = Vector3.new(0.2, 3.6, 2.6)
					frameSize = Vector3.new(0.15, 4.2, 3.2)
					sillSize = Vector3.new(0.6, 0.3, 3.6)
					sillOffset = CFrame.new(sign_ * 0.25, -2.2, 0)
				end
				deco("WindowFrame", frameSize, cf * pos, C.WallTrim, Enum.Material.Concrete, model)
				deco("WindowSill", sillSize, cf * pos * sillOffset, C.WallTrim, Enum.Material.Concrete, model)
				local glass = deco("Window", glassSize, cf * pos, C.Window, Enum.Material.Glass, model)
				glass.Transparency = 0 -- opaco: delante de la pared no se nota y no cuesta ordenar transparencias
				glass.Reflectance = 0.25
			end
		end
	end
	windowsOnFace("Z", -1, 4, size.X - 6, 1) -- sin la primera: ahí va la puerta
	windowsOnFace("Z", 1, 4, size.X - 6)
	windowsOnFace("X", -1, 3, size.Z - 6)
	windowsOnFace("X", 1, 3, size.Z - 6)

	-- Puerta y toldo en la fachada que mira al centro del mapa (-Z)
	local front = -size.Z / 2
	local doorX = -0.375 * (size.X - 6)
	deco("Door", Vector3.new(4, 6.5, 0.3), cf * CFrame.new(doorX, 3.25, front - 0.1), Color3.fromRGB(50, 55, 70), Enum.Material.SmoothPlastic, model)
	signIndex = signIndex % #SHOP_SIGNS + 1
	local shop = SHOP_SIGNS[signIndex]
	for i = 0, 4 do
		deco(
			"Awning",
			Vector3.new(1.2, 0.3, 3),
			cf * CFrame.new(doorX - 2.4 + i * 1.2, 7.6, front - 1.5) * CFrame.Angles(math.rad(-15), 0, 0),
			i % 2 == 0 and shop[2] or Color3.new(1, 1, 1),
			Enum.Material.Fabric,
			model
		)
	end
	-- Rótulo de neón
	local signPart = deco("ShopSign", Vector3.new(10, 2.6, 0.4), cf * CFrame.new(size.X / 5, size.Y - 2.5, front - 0.3), Color3.fromRGB(25, 25, 35), Enum.Material.SmoothPlastic, model)
	sign(signPart, Enum.NormalId.Front, shop[1], shop[2], Color3.fromRGB(255, 255, 255))
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Front
	glow.Color = shop[2]
	glow.Range = 10
	glow.Brightness = 1.5
	glow.Parent = signPart

	-- Murito de cobertura en la azotea (sólido)
	local h = 3
	local top = size.Y
	block("Rail", Vector3.new(size.X, h, 1), cf * CFrame.new(0, top + h / 2, -size.Z / 2 + 0.5), color, Enum.Material.Concrete, model)
	block("Rail", Vector3.new(size.X, h, 1), cf * CFrame.new(0, top + h / 2, size.Z / 2 - 0.5), color, Enum.Material.Concrete, model)

	-- Aires acondicionados y antena en la azotea
	for _, x in { -size.X / 4, -size.X / 4 + 4.5 } do
		block("ACUnit", Vector3.new(3.5, 2.4, 3), cf * CFrame.new(x, top + 1.2, 4), Color3.fromRGB(200, 205, 210), Enum.Material.Metal, model)
		local fan = cylinder("Fan", 0.2, 2.2, cf * CFrame.new(x, top + 2.45, 4), Color3.fromRGB(70, 70, 75), Enum.Material.Metal, model, true)
		fan:SetAttribute("Spin", 360)
	end
	cylinder("Antenna", 7, 0.25, cf * CFrame.new(size.X / 2 - 3, top + 3.5, size.Z / 2 - 3), C.Metal, Enum.Material.Metal, model, true)
	local beacon = deco("Beacon", Vector3.new(0.6, 0.6, 0.6), cf * CFrame.new(size.X / 2 - 3, top + 7.2, size.Z / 2 - 3), Color3.fromRGB(255, 40, 40), Enum.Material.Neon, model)
	beacon.Shape = Enum.PartType.Ball
	return model
end

local function spawnArea(team, cf)
	local teamColor = team.Color.Color
	local light = teamColor:Lerp(Color3.new(1, 1, 1), 0.55)
	local floor = block("SpawnFloor", Vector3.new(30, 0.4, 70), cf * CFrame.new(0, 0.2, 0), light, Enum.Material.SmoothPlastic)
	floor.Name = team.Name .. "SpawnFloor"
	-- Rejilla del suelo
	for z = -30, 30, 10 do
		deco("FloorLine", Vector3.new(30, 0.05, 0.3), cf * CFrame.new(0, 0.42, z), teamColor, Enum.Material.SmoothPlastic)
	end

	local roof = block("Roof", Vector3.new(30, 1, 70), cf * CFrame.new(0, 16, 0), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)
	deco("RoofTrim", Vector3.new(0.6, 0.5, 70.2), cf * CFrame.new(15, 15.4, 0), teamColor, Enum.Material.Neon)
	-- Cartel del equipo encima de la entrada
	local banner = block("TeamBanner", Vector3.new(0.6, 4, 28), cf * CFrame.new(15.2, 18.6, 0), teamColor, Enum.Material.SmoothPlastic)
	sign(banner, Enum.NormalId.Right, "EQUIPO " .. string.upper(team.Name), Color3.new(1, 1, 1))
	sign(banner, Enum.NormalId.Left, "EQUIPO " .. string.upper(team.Name), Color3.new(1, 1, 1))
	roof.Name = team.Name .. "SpawnRoof"
	roof.CanCollide = false -- (no se puede pisar: nadie acampa encima de la base enemiga)

	for _, z in { -34, 34 } do
		block("Pillar", Vector3.new(2, 16, 2), cf * CFrame.new(14, 8, z), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)
		deco("PillarStripe", Vector3.new(2.1, 1, 2.1), cf * CFrame.new(14, 12, z), teamColor, Enum.Material.Neon)
	end
	for _, z in { -24, 0, 24 } do
		block("Cover", Vector3.new(2, 4, 10), cf * CFrame.new(14, 2, z), teamColor, Enum.Material.SmoothPlastic)
		deco("CoverTop", Vector3.new(2.1, 0.3, 10.1), cf * CFrame.new(14, 4.05, z), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
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

	-- Luz de equipo bajo el techo
	local lamp = deco("SpawnLight", Vector3.new(20, 0.2, 60), cf * CFrame.new(0, 15.4, 0), teamColor:Lerp(Color3.new(1, 1, 1), 0.7), Enum.Material.Neon)
	local surfaceLight = Instance.new("SurfaceLight")
	surfaceLight.Face = Enum.NormalId.Bottom
	surfaceLight.Range = 16
	surfaceLight.Brightness = 0.8
	surfaceLight.Color = teamColor:Lerp(Color3.new(1, 1, 1), 0.5)
	surfaceLight.Parent = lamp
end

-- Base de la bandera: el módulo Flags busca piezas "FlagBase" con el atributo Team.
-- En un mapa propio basta con poner una pieza llamada FlagBase con Team = "Rojo" / "Azul".
local function flagBase(team, cf)
	local teamColor = team.Color.Color
	local ring = deco("FlagBaseRing", Vector3.new(0.3, 13, 13), cf * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.pi / 2), teamColor, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	local pad = block("FlagBase", Vector3.new(0.4, 11, 11), cf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)
	pad.Shape = Enum.PartType.Cylinder
	pad:SetAttribute("Team", team.Name)
	local inner = deco("FlagBaseInner", Vector3.new(0.45, 4, 4), cf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), teamColor, Enum.Material.Neon)
	inner.Shape = Enum.PartType.Cylinder
	-- Pilones luminosos alrededor
	for i = 0, 3 do
		local angle = i * math.pi / 2 + math.pi / 4
		local offset = CFrame.new(math.cos(angle) * 7.5, 0, math.sin(angle) * 7.5)
		cylinder("Pylon", 2, 0.7, cf * offset * CFrame.new(0, 1, 0), Color3.fromRGB(230, 230, 235), Enum.Material.SmoothPlastic, nil, true)
		local top = deco("PylonLight", Vector3.new(0.8, 0.8, 0.8), cf * offset * CFrame.new(0, 2.3, 0), teamColor, Enum.Material.Neon)
		top.Shape = Enum.PartType.Ball
	end
	local glow = Instance.new("PointLight")
	glow.Color = teamColor
	glow.Range = 16
	glow.Brightness = 1.5
	glow.Parent = inner
	return pad
end

-- Fachada con ventanas sobre la cara interior de un muro exterior.
-- `inward` = signo (+1/-1) de la dirección hacia el centro del mapa.
local function facade(center, length, alongX, inward)
	local rows = { 13, 22 }
	for _, y in rows do
		for t = -length / 2 + 8, length / 2 - 8, 12 do
			local pos = alongX and Vector3.new(t, y, center.Z + inward * 0.3) or Vector3.new(center.X + inward * 0.3, y, t)
			local frameSize = alongX and Vector3.new(5, 5, 0.3) or Vector3.new(0.3, 5, 5)
			local glassSize = alongX and Vector3.new(4.2, 4.2, 0.35) or Vector3.new(0.35, 4.2, 4.2)
			deco("FacadeFrame", frameSize, CFrame.new(pos), C.WallTrim, Enum.Material.Concrete)
			local glass = deco("FacadeWindow", glassSize, CFrame.new(pos), C.Window, Enum.Material.Glass)
			glass.Transparency = 0
			glass.Reflectance = 0.25
		end
	end
	-- Cornisa y franja inferior
	local trimSize = alongX and Vector3.new(length, 1.2, 1.2) or Vector3.new(1.2, 1.2, length)
	deco("WallCornice", trimSize, CFrame.new(center + Vector3.new(0, WALL_HEIGHT / 2 + 0.3, 0)), C.WallTrim, Enum.Material.Concrete)
	local baseSize = alongX and Vector3.new(length, 3, 0.6) or Vector3.new(0.6, 3, length)
	local basePos = alongX and Vector3.new(center.X, 1.5, center.Z + inward * 0.3) or Vector3.new(center.X + inward * 0.3, 1.5, center.Z)
	deco("WallBase", baseSize, CFrame.new(basePos), Color3.fromRGB(110, 108, 104), Enum.Material.Concrete)
end

---------------------------------------------------------------------------

Map.Lighting = {
	CartoonNeutral = { Hue = 0.6, Sat = 0.17 }, -- tono de los grises en estilo Cartoon
	ClockTime = 16.4,
	Brightness = 3,
	Exposure = 0,
	Ambient = Color3.fromRGB(60, 62, 72),
	OutdoorAmbient = Color3.fromRGB(125, 128, 140),
	Atmosphere = { Density = 0.3, Offset = 0.2, Color = Color3.fromRGB(200, 215, 235), Decay = Color3.fromRGB(110, 130, 160), Glare = 0.4, Haze = 1.6 },
	Color = { Saturation = 0.1, Contrast = 0.16, Brightness = 0, Tint = Color3.fromRGB(255, 246, 235) },
	Bloom = { Intensity = 0.7, Size = 24, Threshold = 1.6 },
	SunRays = 0.08,
}

function Map.Build()
	mapFolder = Kit.Begin(Map.Name)
	Kit.applyLighting(Map.Lighting)

	-- Suelo: asfalto, aceras y plaza central
	block("Floor", Vector3.new(LENGTH + 40, 2, WIDTH + 40), CFrame.new(0, -1, 0), C.Asphalt, Enum.Material.Asphalt)
	for _, side in { -1, 1 } do
		block("Sidewalk", Vector3.new(LENGTH, 0.4, 16), CFrame.new(0, 0.2, side * (WIDTH / 2 - 8)), C.Sidewalk, Enum.Material.Pavement)
		deco("Curb", Vector3.new(LENGTH, 0.45, 0.8), CFrame.new(0, 0.22, side * (WIDTH / 2 - 16.4)), C.Curb, Enum.Material.Concrete)
		-- Línea discontinua del carril
		for x = -125, 125, 10 do
			deco("LaneDash", Vector3.new(5, 0.05, 0.6), CFrame.new(x, 0.03, side * 50), C.LineWhite, Enum.Material.SmoothPlastic)
		end
		-- Pasos de cebra
		for _, x in { -40, 40 } do
			for i = 0, 6 do
				deco("Zebra", Vector3.new(8, 0.05, 1.4), CFrame.new(x, 0.035, side * (40 + i * 3)), C.LineWhite, Enum.Material.SmoothPlastic)
			end
		end
		-- Línea amarilla de borde
		deco("EdgeLine", Vector3.new(LENGTH - 60, 0.05, 0.5), CFrame.new(0, 0.03, side * (WIDTH / 2 - 19)), C.LineYellow, Enum.Material.SmoothPlastic)
	end
	-- Plaza central con baldosas de colores
	local tileColors = { Color3.fromRGB(235, 230, 220), Color3.fromRGB(255, 190, 200) }
	for ix = -5, 4 do
		for iz = -5, 4 do
			deco(
				"PlazaTile",
				Vector3.new(5.9, 0.06, 5.9),
				CFrame.new(ix * 6 + 3, 0.03, iz * 6 + 3),
				tileColors[(ix + iz) % 2 + 1],
				Enum.Material.Pavement
			)
		end
	end

	-- Muros exteriores con fachadas
	block("Wall", Vector3.new(LENGTH, WALL_HEIGHT, 4), CFrame.new(0, WALL_HEIGHT / 2, WIDTH / 2 + 2), C.WallBlue, Enum.Material.Brick)
	block("Wall", Vector3.new(LENGTH, WALL_HEIGHT, 4), CFrame.new(0, WALL_HEIGHT / 2, -WIDTH / 2 - 2), C.WallBlue, Enum.Material.Brick)
	block("Wall", Vector3.new(4, WALL_HEIGHT, WIDTH), CFrame.new(LENGTH / 2 + 2, WALL_HEIGHT / 2, 0), C.WallBlue, Enum.Material.Brick)
	block("Wall", Vector3.new(4, WALL_HEIGHT, WIDTH), CFrame.new(-LENGTH / 2 - 2, WALL_HEIGHT / 2, 0), C.WallBlue, Enum.Material.Brick)
	facade(Vector3.new(0, WALL_HEIGHT / 2, WIDTH / 2), LENGTH, true, -1)
	facade(Vector3.new(0, WALL_HEIGHT / 2, -WIDTH / 2), LENGTH, true, 1)
	facade(Vector3.new(LENGTH / 2, WALL_HEIGHT / 2, 0), WIDTH, false, -1)
	facade(Vector3.new(-LENGTH / 2, WALL_HEIGHT / 2, 0), WIDTH, false, 1)

	-- Techo invisible para que nadie salga del mapa
	local ceiling = block("Ceiling", Vector3.new(LENGTH, 1, WIDTH), CFrame.new(0, WALL_HEIGHT + 12, 0), Color3.new(1, 1, 1))
	ceiling.Transparency = 1
	ceiling.CastShadow = false
	-- Los disparos ignoran la carpeta Boundary
	local boundary = Instance.new("Folder")
	boundary.Name = "Boundary"
	boundary.Parent = ceiling.Parent
	ceiling.Parent = boundary

	-- Carteles gigantes con el nombre del juego sobre los muros largos
	for _, side in { -1, 1 } do
		local board = deco(
			"Billboard",
			Vector3.new(70, 14, 1),
			CFrame.new(0, WALL_HEIGHT + 9, side * (WIDTH / 2 + 3)) * (side > 0 and CFrame.new() or MIRROR),
			Color3.fromRGB(20, 20, 35),
			Enum.Material.SmoothPlastic
		)
		sign(board, Enum.NormalId.Front, GameConfig.GameTitle, Color3.fromRGB(255, 200, 40), Color3.fromRGB(120, 20, 80))
		deco("BillboardFrame", Vector3.new(72, 1, 1.2), board.CFrame * CFrame.new(0, 7.4, 0), C.Pink, Enum.Material.Neon)
		deco("BillboardFrame", Vector3.new(72, 1, 1.2), board.CFrame * CFrame.new(0, -7.4, 0), C.Pink, Enum.Material.Neon)
		for _, x in { -25, 25 } do
			deco("BillboardLeg", Vector3.new(1, 10, 1), board.CFrame * CFrame.new(x, -12, 0.5), C.Metal, Enum.Material.Metal)
		end
	end

	-- Spawns y banderas
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
		ramp((m * CFrame.new(-38, 0, 74)).Position, (m * CFrame.new(-62, 12, 74)).Position, 7, C.Ramp)

		-- Pasarela elevada sobre los contenedores, con barandillas
		local catwalk = block("Catwalk", Vector3.new(30, 1, 6), m * CFrame.new(-95, 17.9, -45), Color3.fromRGB(90, 90, 100), Enum.Material.DiamondPlate)
		for _, z in { -2.8, 2.8 } do
			deco("Handrail", Vector3.new(30, 0.25, 0.25), catwalk.CFrame * CFrame.new(0, 3, z), C.LineYellow, Enum.Material.Metal)
			for x = -14, 14, 4 do
				deco("RailPost", Vector3.new(0.25, 2.5, 0.25), catwalk.CFrame * CFrame.new(x, 1.75, z), C.Metal, Enum.Material.Metal)
			end
		end
		for _, x in { -82, -108 } do
			block("CatwalkLeg", Vector3.new(1, 17.4, 1), m * CFrame.new(x, 8.7, -42.6), C.Metal, Enum.Material.Metal)
		end
		ramp((m * CFrame.new(-120, 0, -5)).Position, (m * CFrame.new(-110, 17.4, -45)).Position, 6, C.Ramp)

		-- Cajas de cobertura
		crate(m * CFrame.new(-110, 0, 20))
		crate(m * CFrame.new(-110, 0, 25))
		crate(m * CFrame.new(-110, 4, 22.5))
		crate(m * CFrame.new(-45, 0, 45), 5)
		crate(m * CFrame.new(-80, 0, -20))
		crate(m * CFrame.new(-25, 0, -40), 5)
		crate(m * CFrame.new(-25, 0, -35))

		-- Barreras de cobertura
		barrier(Vector3.new(2, 4.5, 16), m * CFrame.new(-40, 0, -15))
		barrier(Vector3.new(14, 4.5, 2), m * CFrame.new(-18, 0, 40))

		-- Rampa a la plataforma central
		ramp((m * CFrame.new(-34, 0, 0)).Position, (m * CFrame.new(-12, 7, 0)).Position, 8, C.Ramp)

		-- Farolas y árboles en las dos aceras (la otra mitad sale del espejo)
		for _, x in { -130, -90, -50, -10 } do
			streetLamp(m * CFrame.new(x, 0.4, -(WIDTH / 2 - 4)) * MIRROR) -- brazo hacia el centro
			streetLamp(m * CFrame.new(x, 0.4, WIDTH / 2 - 4))
		end
		for _, x in { -110, -70, -30 } do
			tree(m * CFrame.new(x, 0.4, -(WIDTH / 2 - 7)))
			tree(m * CFrame.new(x, 0.4, WIDTH / 2 - 7))
		end

		-- Bolardos en las esquinas de la plaza
		for _, z in { -28, 28 } do
			bollard(m * CFrame.new(-30, 0, z))
			bollard(m * CFrame.new(-26, 0, z))
		end
	end)

	-- Plataforma central
	local platform = block("CenterPlatform", Vector3.new(24, 1, 24), CFrame.new(0, 6.5, 0), Color3.fromRGB(80, 80, 95), Enum.Material.DiamondPlate)
	for _, x in { -10, 10 } do
		for _, z in { -10, 10 } do
			block("Pillar", Vector3.new(2, 6, 2), CFrame.new(x, 3, z), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
		end
	end
	-- Bordes de neón
	for _, z in { -12, 12 } do
		deco("PlatformEdge", Vector3.new(24.2, 0.3, 0.3), platform.CFrame * CFrame.new(0, -0.45, z), C.Pink, Enum.Material.Neon)
	end
	for _, x in { -12, 12 } do
		deco("PlatformEdge", Vector3.new(0.3, 0.3, 24.2), platform.CFrame * CFrame.new(x, -0.45, 0), C.Pink, Enum.Material.Neon)
	end
	block("CenterCover", Vector3.new(2, 4, 10), CFrame.new(0, 9, 7), C.Pink, Enum.Material.SmoothPlastic)
	block("CenterCover", Vector3.new(2, 4, 10), CFrame.new(0, 9, -7), C.Pink, Enum.Material.SmoothPlastic)
	-- Holograma giratorio sobre el centro (gira en el cliente)
	local holo = deco("Hologram", Vector3.new(0.3, 9, 9), CFrame.new(0, 22, 0) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(math.rad(70), 0, 0), C.Cyan, Enum.Material.ForceField)
	holo.Shape = Enum.PartType.Cylinder
	holo:SetAttribute("Spin", 45)
	local holoCore = deco("HologramCore", Vector3.new(2.5, 2.5, 2.5), CFrame.new(0, 22, 0), C.Pink, Enum.Material.Neon)
	holoCore.Shape = Enum.PartType.Ball
	holoCore:SetAttribute("Bob", 1.2)
	local holoLight = Instance.new("PointLight")
	holoLight.Color = C.Pink
	holoLight.Range = 20
	holoLight.Brightness = 2
	holoLight.Parent = holoCore

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
		Color3.fromRGB(240, 240, 250),
		Color3.fromRGB(255, 200, 210),
	}
	local neonTops = { C.Pink, C.Cyan, C.LineYellow, Color3.fromRGB(140, 255, 120) }

	-- near = fila cercana (con franjas); las lejanas van lisas: casi no se distinguen y ahorran cientos de piezas
	local function tower(position, w, d, h, near)
		local color = palette[rng:NextInteger(1, #palette)]
		local glassy = rng:NextNumber() < 0.6
		local body = deco("Tower", Vector3.new(w, h, d), CFrame.new(position + Vector3.new(0, h / 2, 0)), color, glassy and Enum.Material.Glass or Enum.Material.Concrete, skyline)
		body.Reflectance = glassy and 0.15 or 0
		-- Franjas horizontales (solo en la fila cercana, cada tres pisos, sin sombra)
		if near then
			for y = 12, h - 6, 24 do
				local stripe = deco("Floor", Vector3.new(w + 0.3, 0.8, d + 0.3), CFrame.new(position + Vector3.new(0, y, 0)), C.WallTrim, Enum.Material.SmoothPlastic, skyline)
				stripe.CastShadow = false
			end
		end
		-- Remate superior
		local capH = rng:NextNumber(2, 6)
		deco("Cap", Vector3.new(w * 0.7, capH, d * 0.7), CFrame.new(position + Vector3.new(0, h + capH / 2, 0)), C.WallTrim, Enum.Material.Concrete, skyline)
		if rng:NextNumber() < 0.5 then
			deco("NeonTop", Vector3.new(w + 0.6, 1, d + 0.6), CFrame.new(position + Vector3.new(0, h - 0.5, 0)), neonTops[rng:NextInteger(1, #neonTops)], Enum.Material.Neon, skyline)
		end
		if rng:NextNumber() < 0.4 then
			local antennaH = rng:NextNumber(8, 16)
			deco("Antenna", Vector3.new(0.6, antennaH, 0.6), CFrame.new(position + Vector3.new(0, h + capH + antennaH / 2, 0)), C.Metal, Enum.Material.Metal, skyline)
			local light = deco("AntennaLight", Vector3.new(1, 1, 1), CFrame.new(position + Vector3.new(0, h + capH + antennaH, 0)), Color3.fromRGB(255, 40, 40), Enum.Material.Neon, skyline)
			light.Shape = Enum.PartType.Ball
		end
	end

	for x = -230, 230, 38 do
		for _, side in { -1, 1 } do
			local w = rng:NextNumber(24, 34)
			tower(Vector3.new(x + rng:NextNumber(-6, 6), 0, side * (WIDTH / 2 + 42 + rng:NextNumber(0, 30))), w, w, rng:NextNumber(60, 160), true)
			-- Segunda fila más lejana y alta
			local w2 = rng:NextNumber(28, 40)
			tower(Vector3.new(x + 19, 0, side * (WIDTH / 2 + 110 + rng:NextNumber(0, 40))), w2, w2, rng:NextNumber(110, 240))
		end
	end
	for _, side in { -1, 1 } do
		for z = -140, 140, 40 do
			tower(Vector3.new(side * (LENGTH / 2 + 50), 0, z + rng:NextNumber(-5, 5)), 30, 30, rng:NextNumber(50, 130), true)
			tower(Vector3.new(side * (LENGTH / 2 + 120), 0, z + 20), 36, 36, rng:NextNumber(100, 220))
		end
	end

	-- Puntos para "Todos contra todos" y zonas de control
	for _, p in {
		Vector3.new(-120, 0.5, -80), Vector3.new(-60, 0.5, 40), Vector3.new(-20, 0.5, -60), Vector3.new(-90, 0.5, 0),
		Vector3.new(-40, 0.5, 85), Vector3.new(0, 7.5, 0), Vector3.new(-130, 0.5, 40), Vector3.new(-75, 12.5, 68),
	} do
		Kit.ffaSpawn(p)
		Kit.ffaSpawn(Vector3.new(-p.X, p.Y, -p.Z))
	end
	Kit.zone(Vector3.new(0, 7, 0), 12, 1)
	Kit.zone(Vector3.new(-75, 12.4, 68), 10, 2)
	Kit.zone(Vector3.new(75, 12.4, -68), 10, 3)
	Kit.zone(Vector3.new(-60, 0, -40), 12, 4)
	Kit.zone(Vector3.new(60, 0, 40), 12, 5)

	-- Realismo: charcos en el asfalto, alcantarillas con vapor y polvo en la plaza
	for _, p in { Vector3.new(-116, 0, -76), Vector3.new(-56, 0, 44), Vector3.new(-86, 0, 4), Vector3.new(-16, 0, -56), Vector3.new(-126, 0, 44) } do
		Kit.puddle(p, 4.5)
		Kit.puddle(Vector3.new(-p.X, p.Y, -p.Z), 4.5)
	end
	for _, p in { Vector3.new(-110, 0.05, -30), Vector3.new(-50, 0.05, 70) } do
		Kit.steamVent(CFrame.new(p), 0.8)
		Kit.steamVent(CFrame.new(-p.X, p.Y, -p.Z), 0.8)
	end
	Kit.dustMotes(CFrame.new(0, 6, 0), Vector3.new(60, 10, 60), Color3.fromRGB(255, 240, 210), 14)

	-- Realismo: losas de acera, alcantarillas, desagües junto al bordillo, grietas, aceite y rodadas
	for _, side in { -1, 1 } do
		Kit.floorJoints(CFrame.new(0, 0.4, side * (WIDTH / 2 - 8)), LENGTH, 16, 6, Color3.fromRGB(118, 116, 112))
	end
	symmetric(function(m)
		for _, p in { Vector3.new(-100, 0, 46), Vector3.new(-20, 0, -48), Vector3.new(-128, 0, -10) } do
			Kit.manhole(m * p)
		end
		for _, p in { Vector3.new(-80, 0, 92.4), Vector3.new(-20, 0, -92.4), Vector3.new(-130, 0, 92.4) } do
			Kit.drain(m * CFrame.new(p))
		end
		for i, spec in { { Vector3.new(-70, 0, 30), 9 }, { Vector3.new(-130, 0, -55), 8 }, { Vector3.new(-30, 0, 58), 10 }, { Vector3.new(-90, 0, -20), 7 } } do
			Kit.crack(m * spec[1], spec[2], i * 23)
		end
		for _, p in { Vector3.new(-108, 0, 54), Vector3.new(-62, 0, -50), Vector3.new(-25, 0, 30) } do
			Kit.oilStain(m * p, 2.6)
		end
		Kit.tireMarks(m * CFrame.new(-58, 0, 52) * CFrame.Angles(0, math.rad(80), 0), 26, -0.5)
		-- Coches aparcados junto al bordillo (también sirven de cobertura)
		Kit.car(m * CFrame.new(-110, 0, 91), Color3.fromRGB(175, 30, 35))
		Kit.car(m * CFrame.new(-70, 0, 91) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(225, 225, 228))
		Kit.car(m * CFrame.new(-58, 0, -91), Color3.fromRGB(30, 60, 120))
	end)

	return mapFolder
end

return Map
