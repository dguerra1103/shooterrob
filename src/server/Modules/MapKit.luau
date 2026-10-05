-- Kit de construcción de mapas: piezas reutilizables (contenedores, edificios, palmeras, grúas...),
-- iluminación por mapa y puntos especiales (spawns, bandera, zonas, spawns libres).
local Lighting = game:GetService("Lighting")

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local Kit = {}

Kit.folder = nil -- carpeta del mapa actual (la crea Begin)

-- Rotación de 180° alrededor del centro: la mitad Azul es espejo de la Roja
Kit.MIRROR = CFrame.Angles(0, math.pi, 0)

function Kit.symmetric(fn)
	fn(CFrame.new(), "A")
	fn(Kit.MIRROR, "B")
end

local rad = math.rad
local V = Vector3.new
local RGB = Color3.fromRGB

Kit.C = {
	Metal = RGB(60, 62, 70),
	Yellow = RGB(255, 205, 50),
	White = RGB(245, 245, 250),
	Wood = RGB(176, 124, 70),
	WoodDark = RGB(120, 80, 45),
	Leaf = RGB(80, 180, 80),
	LeafDark = RGB(50, 140, 60),
	Pink = RGB(255, 80, 170),
	Cyan = RGB(0, 220, 255),
	Red = RGB(210, 50, 45),
	Blue = RGB(45, 110, 220),
}
local C = Kit.C

-- Realismo: el plástico liso parece de juguete. Las piezas grandes pasan a materiales PBR reales
-- (yeso pintado si tienen color, hormigón si son oscuras o son suelos); lo pequeño (conos, flores,
-- carteles) se queda como está. Lo usan Kit.block y los mapas con su propia función de piezas.
function Kit.realisticMaterial(size, color, material)
	material = material or Enum.Material.SmoothPlastic
	if material ~= Enum.Material.SmoothPlastic and material ~= Enum.Material.Plastic then
		return material
	end
	local volume = size.X * size.Y * size.Z
	local flatFloor = size.Y <= 0.6 and size.X * size.Z >= 60
	if volume < 30 and not flatFloor then
		return material
	end
	local luminance = color.R * 0.3 + color.G * 0.59 + color.B * 0.11
	if flatFloor or luminance < 0.22 then
		return Enum.Material.Concrete
	end
	return Enum.Material.Plaster
end

-- Estilo Cartoon: los materiales "realistas" pasan a plástico liso y los colores ganan viveza; los
-- grises claros tiran a lavanda (paredes tipo shooter de Roblox). Los detalles de suelo no cambian.
-- (Táctico y Realista usan los materiales de verdad; solo cambia la luz: ver tacticalize y realize)
local function realMaterials()
	return GameConfig.VisualStyle == "Realista" or GameConfig.VisualStyle == "Tactico"
end
Kit.Cartoon = not realMaterials()
Kit.Designed = false -- (mapa hecho ya realista: ver Kit.Begin)
local CARTOON_FLAT = {}
for _, name in {
	"Plaster", "Concrete", "Brick", "Limestone", "Cobblestone", "Slate", "Pavement", "Asphalt", "Granite", "Marble",
	"Sandstone", "Pebble", "CorrodedMetal", "DiamondPlate", "Rock", "Basalt", "Plastic", "Grass", "LeafyGrass",
	"ClayRoofTiles", "CeramicTiles", "Fabric",
} do
	local ok, material = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and material then
		CARTOON_FLAT[material] = true
	end
end
local KEEP_LOOK = {
	ContactShadow = true, OilStain = true, Crack = true, Joint = true, TireMark = true, Puddle = true,
	-- Nata y caramelo blanco de Arena Caramelo (si no, el blanco se volvería lavanda)
	CandyWhite = true, CakeFrosting = true, FrostingDrip = true, GumdropShine = true,
	LollipopStick = true, LollipopSwirl = true, CottonStick = true,
	CastleTop = true, JumpPadRing = true, -- blancos de Caja de Juguetes y de las plataformas de salto
}

-- Tono de los grises en estilo Cartoon (cada mapa puede tener el suyo: Lighting.CartoonNeutral)
Kit.Neutral = { Hue = 0.68, Sat = 0.16 } -- lavanda por defecto

function Kit.vivid(color)
	local h, s, v = color:ToHSV()
	if s < 0.22 then
		local neutral = Kit.Neutral
		if v >= 0.45 then
			-- piedra, yeso, gris claro → pastel del tono del mapa (lavanda por defecto)
			return Color3.fromHSV(neutral.Hue, neutral.Sat, math.min(1, v * 1.02 + 0.05))
		elseif v >= 0.2 then
			-- asfalto, hormigón oscuro → gris con un toque del mismo tono
			return Color3.fromHSV(neutral.Hue, math.min(0.35, neutral.Sat + 0.08), math.min(1, v * 1.12))
		end
		return color -- negros
	end
	return Color3.fromHSV(h, math.clamp(s * 1.45, 0, 0.95), math.clamp(v * 1.1 + 0.04, 0, 1))
end

-- Estilo realista en mapas pensados para Cartoon: los colores muy vivos pasan a pintura de verdad
-- (menos saturados y no tan claros); los grises y los marrones casi no cambian
function Kit.natural(color)
	local h, s, v = color:ToHSV()
	if s < 0.25 then
		return color
	end
	return Color3.fromHSV(h, s * (s > 0.6 and 0.78 or 0.88), v > 0.85 and v * 0.93 or v)
end

function Kit.applyStyle(part)
	if KEEP_LOOK[part.Name] or part.Material == Enum.Material.Neon then
		return
	end
	if not Kit.Cartoon then
		-- (los mapas hechos ya realistas, como Encrucijada, tienen sus colores pensados)
		if not Kit.Designed then
			part.Color = Kit.natural(part.Color)
		end
		return
	end
	if CARTOON_FLAT[part.Material] then
		part.Material = Enum.Material.SmoothPlastic
	end
	-- Textura de cuadrícula (MaterialVariant "Grid" en MaterialService, ver assets/textures/LEEME.md).
	-- Si la variante no existe todavía, Roblox usa el plástico liso normal: no rompe nada.
	if part.Material == Enum.Material.SmoothPlastic then
		part.MaterialVariant = "Grid"
	end
	part.Color = Kit.vivid(part.Color)
end

function Kit.block(name, size, cf, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = Kit.realisticMaterial(size, color, material)
	if part.Material == Enum.Material.Glass then
		part.Reflectance = 0.15 -- los cristales reflejan un poco el cielo
	end
	Kit.applyStyle(part)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or Kit.folder
	return part
end
local block = Kit.block

-- Pieza decorativa: no choca, no bloquea disparos y no hace sombra
function Kit.deco(name, size, cf, color, material, parent)
	local part = block(name, size, cf, color, material, parent)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	-- Realismo con coste medio: solo lo grande (grúas, tejados, barcos, copas) proyecta sombra
	part.CastShadow = size.X * size.Y * size.Z >= 20 and part.Material ~= Enum.Material.Neon and part.Material ~= Enum.Material.Glass
	return part
end
local deco = Kit.deco

-- Cilindro de pie (el eje del cilindro en Roblox es X; lo giramos para que sea vertical)
function Kit.cylinder(name, height, diameter, cf, color, material, parent, decorative)
	local fn = decorative and deco or block
	local part = fn(name, V(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.pi / 2), color, material, parent)
	part.Shape = Enum.PartType.Cylinder
	return part
end
local cylinder = Kit.cylinder

-- Cilindro tumbado a lo largo del eje X local
function Kit.pipe(name, length, diameter, cf, color, material, decorative)
	local fn = decorative and deco or block
	local part = fn(name, V(length, diameter, diameter), cf, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function Kit.ball(name, diameter, cf, color, material, decorative)
	local fn = decorative and deco or block
	local part = fn(name, V(diameter, diameter, diameter), cf, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Texto pegado a una cara de una pieza (carteles, rótulos de neón...)
function Kit.sign(part, face, text, color, strokeColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = strokeColor or Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return gui
end
local sign = Kit.sign

function Kit.light(part, kind, color, range, brightness, face)
	local light = Instance.new(kind or "PointLight")
	light.Color = color
	light.Range = range or 12
	light.Brightness = brightness or 1.5
	if face and (light:IsA("SpotLight") or light:IsA("SurfaceLight")) then
		light.Face = face
	end
	-- Los focos (farolas, lámparas) proyectan sombras reales; el menú Ajustes las apaga en Baja/Media
	if light:IsA("SpotLight") then
		light.Shadows = true
		light:SetAttribute("QualityShadow", true)
	end
	light.Parent = part
	return light
end

-- Rampa inclinada desde "bottom" hasta "top" (posiciones de la superficie)
function Kit.ramp(bottom, top, width, color, material)
	local mid = (bottom + top) / 2
	local length = (top - bottom).Magnitude
	local cf = CFrame.lookAt(mid, top) * CFrame.new(0, -0.5, 0)
	local part = block("Ramp", V(width, 1, length + 1), cf, color or RGB(150, 152, 165), material or Enum.Material.DiamondPlate)
	for _, side in { -1, 1 } do
		deco("RampEdge", V(0.4, 0.1, length + 1), cf * CFrame.new(side * (width / 2 - 0.3), 0.52, 0), C.Yellow, Enum.Material.SmoothPlastic)
	end
	return part
end

-- Escalera de piedra (rampa con escalones decorativos)
function Kit.stairs(bottom, top, width, color, material)
	local part = Kit.ramp(bottom, top, width, color, material or Enum.Material.Concrete)
	local steps = math.max(3, math.floor((top - bottom).Magnitude / 1.6))
	local stepColor = (color or RGB(200, 190, 170)):Lerp(Color3.new(0, 0, 0), 0.12)
	for i = 0, steps - 1 do
		local p = bottom:Lerp(top, (i + 0.5) / steps)
		local dir = (top - bottom)
		local flat = V(dir.X, 0, dir.Z).Unit
		deco("Step", V(width, 0.3, 0.3), CFrame.lookAt(p, p + flat) * CFrame.new(0, 0.05, 0), stepColor, Enum.Material.Concrete)
	end
	return part
end

-- Barandilla entre dos puntos (altura h)
function Kit.railing(a, b, h, color)
	h = h or 3
	color = color or C.Metal
	local length = (b - a).Magnitude
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b)
	deco("Handrail", V(0.25, 0.25, length), cf * CFrame.new(0, h, 0), color, Enum.Material.Metal)
	deco("MidRail", V(0.15, 0.15, length), cf * CFrame.new(0, h * 0.5, 0), color, Enum.Material.Metal)
	local posts = math.max(2, math.floor(length / 4))
	for i = 0, posts do
		local p = a:Lerp(b, i / posts)
		deco("RailPost", V(0.25, h, 0.25), CFrame.new(p + V(0, h / 2, 0)), color, Enum.Material.Metal)
	end
	-- colisión invisible para no caerse (en la carpeta Boundary: las balas y la vista la atraviesan)
	local wall = block("RailCollider", V(0.4, h, length), cf * CFrame.new(0, h / 2, 0), color, nil, Kit.shootThroughFolder())
	wall.Transparency = 1
	wall.CastShadow = false
end

-- Carpeta para lo que choca pero no para las balas ni la vista (barandillas, alambradas): es la de
-- los muros del borde (Map.Boundary), que todos los raycasts del juego excluyen. CanQuery = false
-- no sirve en piezas que colisionan.
function Kit.shootThroughFolder()
	local folder = Kit.folder:FindFirstChild("Boundary")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Boundary"
		folder.Parent = Kit.folder
	end
	return folder
end

---------------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------------

-- Sombra de contacto (oclusión ambiental falsa): dos láminas oscuras semitransparentes algo más
-- grandes que la base, para que lo que está en el suelo parezca apoyado y no flotando. Solo a ras
-- de suelo (encima de otro objeto no hace falta). Material rugoso: el plástico liso brillaba con el
-- cielo y la sombra se veía más clara que el suelo.
function Kit.contactShadow(cf, sizeX, sizeZ, round, parent)
	local pos = cf.Position
	if math.abs(pos.Y) > 0.6 then
		return
	end
	local yaw = cf - pos
	for i, spec in { { 0.45, 0.7 }, { 1.2, 0.86 } } do
		local grow = spec[1] * 2
		local shadow
		if round then
			local d = math.max(sizeX, sizeZ) + grow
			shadow = deco("ContactShadow", V(0.02, d, d), CFrame.new(pos + V(0, 0.012 + i * 0.003, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.new(0, 0, 0), Enum.Material.Concrete, parent)
			shadow.Shape = Enum.PartType.Cylinder
		else
			shadow = deco("ContactShadow", V(sizeX + grow, 0.02, sizeZ + grow), CFrame.new(pos + V(0, 0.012 + i * 0.003, 0)) * yaw, Color3.new(0, 0, 0), Enum.Material.Concrete, parent)
		end
		shadow.Transparency = spec[2]
		shadow.CastShadow = false
	end
end

local CARGO_NAMES = { "HYPER CARGO", "NEXO LINE", "FROST CO.", "TURBO SHIP", "BLAZE LOG.", "VOLT MARINE" }
local cargoIndex = 0

function Kit.container(cf, color, labelText)
	local model = Instance.new("Model")
	model.Name = "Container"
	model.Parent = Kit.folder
	local size = V(20, 8.5, 8)
	local body = block("Body", size, cf * CFrame.new(0, size.Y / 2, 0), color, Enum.Material.CorrodedMetal, model)
	Kit.contactShadow(cf, size.X, size.Z, false, model)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	-- Nervios, techo y marco van pegados al cuerpo: su sombra ya la da el cuerpo (sin sombra propia)
	for i = -4, 4, 2 do
		deco("Rib", V(0.4, 8.2, 8.3), cf * CFrame.new(i * 2.2, 4.25, 0), dark, Enum.Material.Metal, model).CastShadow = false
	end
	block("Roof", V(20.2, 0.3, 8.2), cf * CFrame.new(0, 8.6, 0), dark, Enum.Material.Metal, model).CastShadow = false
	deco("DoorFrame", V(0.3, 8.6, 8.4), cf * CFrame.new(10.1, 4.25, 0), dark, Enum.Material.Metal, model).CastShadow = false
	for _, z in { -2, 2 } do
		deco("LockBar", V(0.3, 7.6, 0.25), cf * CFrame.new(10.3, 4.25, z), RGB(200, 200, 205), Enum.Material.Metal, model)
	end
	deco("DoorSplit", V(0.35, 8, 0.15), cf * CFrame.new(10.3, 4.25, 0), RGB(30, 30, 30), Enum.Material.Metal, model)
	-- Desgaste: chorretones de óxido que bajan desde el techo en los dos laterales largos
	local rust = color:Lerp(RGB(105, 58, 34), 0.6)
	for i, x in { -7.7, 3.3, 5.5 } do
		local side = i % 2 == 0 and 1 or -1
		local length = 2 + ((cargoIndex + i) % 3) * 1.4
		deco("RustStreak", V(0.9, length, 0.06), cf * CFrame.new(x, 8.45 - length / 2, side * 4.04), rust, Enum.Material.CorrodedMetal, model)
	end
	cargoIndex = cargoIndex % #CARGO_NAMES + 1
	local text = labelText or CARGO_NAMES[cargoIndex]
	sign(body, Enum.NormalId.Front, text, Color3.new(1, 1, 1), dark)
	sign(body, Enum.NormalId.Back, text, Color3.new(1, 1, 1), dark)
	return model
end

function Kit.crate(cf, size, color)
	size = size or 4
	local core = block("Crate", V(size, size, size), cf * CFrame.new(0, size / 2, 0), color or C.Wood, Enum.Material.WoodPlanks)
	Kit.contactShadow(cf, size, size)
	for _, y in { 0.12, 0.88 } do
		deco("CrateBand", V(size + 0.15, size * 0.12, size + 0.15), cf * CFrame.new(0, size * y, 0), C.WoodDark, Enum.Material.Wood)
	end
	deco("CrateCross", V(size + 0.1, size * 0.1, size * 1.3), cf * CFrame.new(0, size / 2, 0) * CFrame.Angles(rad(45), 0, 0), C.WoodDark, Enum.Material.Wood)
	return core
end

-- Caja metálica con chevron (estilo industrial)
function Kit.metalCrate(cf, size, color, glow)
	size = size or 5
	local core = block("MetalCrate", V(size, size, size), cf * CFrame.new(0, size / 2, 0), color or RGB(70, 75, 90), Enum.Material.DiamondPlate)
	Kit.contactShadow(cf, size, size)
	deco("CrateRim", V(size + 0.2, 0.3, size + 0.2), cf * CFrame.new(0, size - 0.15, 0), RGB(40, 42, 50), Enum.Material.Metal)
	deco("CrateRimB", V(size + 0.2, 0.3, size + 0.2), cf * CFrame.new(0, 0.15, 0), RGB(40, 42, 50), Enum.Material.Metal)
	if glow then
		deco("CrateGlow", V(size + 0.05, 0.2, size * 0.6), cf * CFrame.new(0, size * 0.5, 0), glow, Enum.Material.Neon)
	end
	return core
end

function Kit.barrel(cf, color)
	cylinder("Barrel", 3, 2, cf * CFrame.new(0, 1.5, 0), color or RGB(40, 90, 180), Enum.Material.Metal)
	Kit.contactShadow(cf, 2, 2, true)
	cylinder("BarrelRing", 0.2, 2.06, cf * CFrame.new(0, 0.8, 0), RGB(40, 40, 45), Enum.Material.Metal, nil, true)
	cylinder("BarrelRing", 0.2, 2.06, cf * CFrame.new(0, 2.2, 0), RGB(40, 40, 45), Enum.Material.Metal, nil, true)
end

function Kit.cone(cf)
	cylinder("ConeBase", 0.2, 1.4, cf * CFrame.new(0, 0.1, 0), RGB(255, 120, 20), Enum.Material.SmoothPlastic, nil, true)
	cylinder("Cone", 1.4, 0.8, cf * CFrame.new(0, 0.8, 0), RGB(255, 120, 20), Enum.Material.SmoothPlastic, nil, true)
	cylinder("ConeStripe", 0.25, 0.85, cf * CFrame.new(0, 0.9, 0), C.White, Enum.Material.SmoothPlastic, nil, true)
end

function Kit.barrier(size, cf)
	local part = block("Barrier", size, cf * CFrame.new(0, size.Y / 2, 0), RGB(225, 225, 230), Enum.Material.Concrete)
	Kit.contactShadow(cf, size.X, size.Z)
	local long = size.X >= size.Z
	local length = long and size.X or size.Z
	local count = math.max(2, math.floor(length / 3))
	for i = 0, count - 1 do
		local offset = -length / 2 + (i + 0.5) * (length / count)
		local color = i % 2 == 0 and RGB(230, 50, 50) or RGB(250, 250, 250)
		local stripeSize = long and V(length / count, 1, size.Z + 0.1) or V(size.X + 0.1, 1, length / count)
		local pos = long and CFrame.new(offset, size.Y - 1.2, 0) or CFrame.new(0, size.Y - 1.2, offset)
		deco("Stripe", stripeSize, cf * pos, color, Enum.Material.SmoothPlastic)
	end
	return part
end

function Kit.streetLamp(cf, color)
	cylinder("Pole", 14, 0.6, cf * CFrame.new(0, 7, 0), C.Metal, Enum.Material.Metal)
	cylinder("Base", 1, 1.2, cf * CFrame.new(0, 0.5, 0), C.Metal, Enum.Material.Metal)
	deco("Arm", V(0.4, 0.4, 4), cf * CFrame.new(0, 13.8, -1.8), C.Metal, Enum.Material.Metal)
	deco("Lamp", V(1.6, 0.5, 2.2), cf * CFrame.new(0, 13.4, -3.6), C.Metal, Enum.Material.Metal)
	local bulb = deco("Bulb", V(1.2, 0.2, 1.8), cf * CFrame.new(0, 13.1, -3.6), color or RGB(255, 240, 200), Enum.Material.Neon)
	Kit.light(bulb, "SpotLight", color or RGB(255, 235, 200), 26, 1.5, Enum.NormalId.Bottom).Angle = 100
end

function Kit.tree(cf)
	block("Planter", V(5, 1.6, 5), cf * CFrame.new(0, 0.8, 0), RGB(200, 200, 208), Enum.Material.Concrete)
	deco("Soil", V(4.4, 0.2, 4.4), cf * CFrame.new(0, 1.65, 0), RGB(90, 60, 40), Enum.Material.Ground)
	cylinder("Trunk", 7, 0.9, cf * CFrame.new(0, 5, 0), RGB(110, 75, 45), Enum.Material.Wood)
	for i, spec in {
		{ V(0, 9.5, 0), 6.5, C.Leaf },
		{ V(1.6, 8.4, 1), 4.5, C.LeafDark },
		{ V(-1.5, 8.8, -1.2), 4.8, C.Leaf },
		{ V(0.3, 11.6, -0.4), 4, C.LeafDark },
	} do
		local leaf = deco("Leaves" .. i, V(spec[2], spec[2], spec[2]), cf * CFrame.new(spec[1]), spec[3], Enum.Material.LeafyGrass)
		leaf.Shape = Enum.PartType.Ball
		leaf.CastShadow = true
	end
end

-- Palmera: tronco inclinado por segmentos y hojas largas
function Kit.palm(cf, height)
	height = height or 14
	local segments = 6
	local lean = rad(8)
	local pos = cf
	for i = 1, segments do
		local seg = height / segments
		local piece = cylinder("PalmTrunk", seg + 0.2, 1.1 - i * 0.07, pos * CFrame.new(0, seg / 2, 0), RGB(140, 105, 70), Enum.Material.Wood, nil, i > 2)
		piece.CanCollide = i <= 2
		deco("TrunkRing", V(0.25, 1.2 - i * 0.07, 1.2 - i * 0.07), pos * CFrame.new(0, seg, 0) * CFrame.Angles(0, 0, math.pi / 2), RGB(110, 80, 50), Enum.Material.Wood).Shape = Enum.PartType.Cylinder
		pos = pos * CFrame.new(0, seg, 0) * CFrame.Angles(lean / segments * 2, 0, 0)
	end
	local top = pos
	for i = 0, 6 do
		local angle = i * math.pi * 2 / 7
		local frond = deco(
			"Frond",
			V(1.6, 0.25, 7),
			top * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.2, -3.2) * CFrame.Angles(rad(-20), 0, 0),
			i % 2 == 0 and RGB(70, 170, 70) or RGB(50, 140, 55),
			Enum.Material.Grass
		)
		frond.CastShadow = true
	end
	Kit.ball("Coconuts", 1.4, top * CFrame.new(0, -0.4, 0), RGB(110, 80, 40), Enum.Material.Wood, true)
end

-- Enredadera colgando de una pared (cara mirando en la dirección `normal`)
function Kit.vines(cf, width, height)
	for i = 0, math.floor(width / 1.5) do
		local h = height * (0.5 + ((i * 37) % 10) / 20)
		deco("Vine", V(1.2, h, 0.3), cf * CFrame.new(-width / 2 + i * 1.5, -h / 2, 0), (i % 2 == 0) and RGB(70, 150, 60) or RGB(90, 175, 70), Enum.Material.LeafyGrass)
	end
end

-- Estandarte de tela con emblema (cuelga de una pared, cara -Z)
function Kit.banner(cf, width, height, color, emblemColor)
	local cloth = deco("Banner", V(width, height, 0.15), cf * CFrame.new(0, -height / 2, 0), color, Enum.Material.Fabric)
	deco("BannerRod", V(width + 1, 0.3, 0.3), cf, C.Metal, Enum.Material.Metal)
	-- Emblema tipo chevron
	for _, s in { -1, 1 } do
		deco("Emblem", V(width * 0.12, height * 0.35, 0.05), cf * CFrame.new(s * width * 0.13, -height * 0.45, -0.1) * CFrame.Angles(0, 0, rad(35 * s)), emblemColor or C.White, Enum.Material.SmoothPlastic)
	end
	deco("BannerTip", V(width * 0.7, width * 0.7, 0.14), cf * CFrame.new(0, -height, 0) * CFrame.Angles(0, 0, rad(45)), color, Enum.Material.Fabric)
	return cloth
end

-- Toldo inclinado
function Kit.awning(cf, width, depth, color)
	for i = 0, math.floor(width / 1.5) - 1 do
		deco("Awning", V(1.5, 0.25, depth), cf * CFrame.new(-width / 2 + 0.75 + i * 1.5, 0, -depth / 2) * CFrame.Angles(rad(-18), 0, 0), i % 2 == 0 and color or C.White, Enum.Material.Fabric)
	end
end

-- Edificio mediterráneo: estuco, cornisa, ventanas, puerta, azotea transitable con murete
function Kit.house(cf, size, color, accent, options)
	options = options or {}
	local model = Instance.new("Model")
	model.Name = "House"
	model.Parent = Kit.folder
	local trim = color:Lerp(Color3.new(0, 0, 0), 0.18)
	block("Walls", size, cf * CFrame.new(0, size.Y / 2, 0), color, Enum.Material.Plaster, model)
	deco("Base", V(size.X + 0.4, 1.4, size.Z + 0.4), cf * CFrame.new(0, 0.7, 0), trim, Enum.Material.Limestone, model)
	Kit.contactShadow(cf, size.X + 0.4, size.Z + 0.4, false, model)
	deco("Cornice", V(size.X + 0.8, 0.8, size.Z + 0.8), cf * CFrame.new(0, size.Y - 0.4, 0), accent or RGB(200, 70, 50), Enum.Material.Plaster, model)
	-- Murete de la azotea (cobertura)
	local h = 2.6
	for _, z in { -1, 1 } do
		block("Parapet", V(size.X, h, 1), cf * CFrame.new(0, size.Y + h / 2, z * (size.Z / 2 - 0.5)), color, Enum.Material.Plaster, model)
	end
	if not options.OpenSides then
		for _, x in { -1, 1 } do
			block("Parapet", V(1, h, size.Z - 2), cf * CFrame.new(x * (size.X / 2 - 0.5), size.Y + h / 2, 0), color, Enum.Material.Plaster, model)
		end
	end
	-- Ventanas con contraventanas
	local floors = math.max(1, math.floor(size.Y / 7))
	for f = 1, floors do
		local y = (f - 0.5) * size.Y / floors + 0.6
		for _, face in { -1, 1 } do
			for i = 1, math.max(1, math.floor(size.X / 9)) do
				local x = -size.X / 2 + (i - 0.5) * size.X / math.max(1, math.floor(size.X / 9))
				local p = cf * CFrame.new(x, y, face * (size.Z / 2 + 0.1))
				deco("Window", V(2.4, 3.2, 0.2), p, RGB(60, 70, 90), Enum.Material.Glass, model) -- opaco (más barato que semitransparente)
				deco("Sill", V(3, 0.3, 0.6), p * CFrame.new(0, -1.75, 0), trim, Enum.Material.Limestone, model)
				for _, s in { -1, 1 } do
					deco("Shutter", V(1.1, 3.2, 0.15), p * CFrame.new(s * 1.85, 0, face * 0.1), accent or RGB(60, 120, 170), Enum.Material.Wood, model)
				end
			end
		end
	end
	-- Puerta con luz
	local doorCf = cf * CFrame.new(options.DoorX or 0, 3.3, -(size.Z / 2 + 0.12))
	deco("Door", V(3.6, 6.6, 0.25), doorCf, RGB(100, 65, 40), Enum.Material.WoodPlanks, model)
	deco("DoorArch", V(4.6, 0.8, 0.4), doorCf * CFrame.new(0, 3.6, 0), trim, Enum.Material.Limestone, model)
	local lamp = deco("DoorLamp", V(0.6, 0.8, 0.6), doorCf * CFrame.new(2.8, 2.5, -0.3), RGB(255, 210, 140), Enum.Material.Neon, model)
	Kit.light(lamp, "PointLight", RGB(255, 200, 120), 12, 1.2)
	if options.Vines then
		Kit.vines(cf * CFrame.new(size.X * 0.25, size.Y - 0.5, -(size.Z / 2 + 0.25)), 6, 8)
	end
	return model
end

-- Grúa pórtico decorativa (para fondos de puerto)
function Kit.crane(cf, height, color)
	color = color or RGB(240, 190, 40)
	height = height or 40
	for _, x in { -6, 6 } do
		for _, z in { -3, 3 } do
			deco("CraneLeg", V(1.2, height, 1.2), cf * CFrame.new(x, height / 2, z), color, Enum.Material.Metal)
		end
	end
	deco("CraneTop", V(14, 2, 8), cf * CFrame.new(0, height, 0), color, Enum.Material.Metal)
	deco("CraneBoom", V(2, 2, 50), cf * CFrame.new(0, height + 2, -14), color, Enum.Material.Metal)
	deco("CraneCab", V(4, 3, 4), cf * CFrame.new(0, height - 2.5, -6), RGB(230, 230, 235), Enum.Material.SmoothPlastic)
	deco("Cable", V(0.2, 12, 0.2), cf * CFrame.new(0, height - 5, -30), RGB(30, 30, 30), Enum.Material.Metal)
	local beacon = Kit.ball("CraneBeacon", 1, cf * CFrame.new(0, height + 3.5, -38), RGB(255, 40, 40), Enum.Material.Neon, true)
	beacon:SetAttribute("Blink", 1)
end

-- Barco de carga decorativo
function Kit.ship(cf, length)
	length = length or 90
	deco("Hull", V(length, 10, 18), cf * CFrame.new(0, 3, 0), RGB(40, 50, 70), Enum.Material.Metal)
	deco("HullStripe", V(length + 0.2, 1.5, 18.2), cf * CFrame.new(0, -1, 0), RGB(200, 40, 40), Enum.Material.Metal)
	deco("Bridge", V(10, 12, 14), cf * CFrame.new(length / 2 - 8, 14, 0), C.White, Enum.Material.SmoothPlastic)
	local colors = { C.Red, C.Blue, RGB(240, 150, 30), RGB(60, 170, 90) }
	local i = 0
	for x = -length / 2 + 8, length / 2 - 18, 9 do
		for row = 0, 1 do
			i += 1
			deco("Cargo", V(8.5, 4, 8), cf * CFrame.new(x, 10 + row * 4, (i % 2 == 0) and -4.2 or 4.2), colors[i % #colors + 1], Enum.Material.CorrodedMetal)
		end
	end
end

-- Faro sobre una isla de roca (fondo)
function Kit.lighthouse(position)
	local terrain = workspace.Terrain
	terrain:FillBall(position + V(0, -6, 0), 26, Enum.Material.Rock)
	terrain:FillBall(position + V(14, -10, 8), 18, Enum.Material.Rock)
	terrain:FillBall(position + V(-10, -2, -6), 14, Enum.Material.Grass)
	local base = position + V(0, 12, 0)
	cylinder("LighthouseTower", 26, 7, CFrame.new(base + V(0, 13, 0)), C.White, Enum.Material.Plaster, nil, true)
	for i = 0, 2 do
		cylinder("LighthouseStripe", 2.5, 7.1, CFrame.new(base + V(0, 6 + i * 8, 0)), C.Red, Enum.Material.Plaster, nil, true)
	end
	cylinder("LighthouseTop", 3, 5, CFrame.new(base + V(0, 27.5, 0)), RGB(255, 245, 200), Enum.Material.Neon, nil, true)
	cylinder("LighthouseRoof", 2, 6, CFrame.new(base + V(0, 30, 0)), C.Red, Enum.Material.Plaster, nil, true)
end

-- Tubería industrial con soportes
function Kit.pipeRun(a, b, diameter, color)
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, rad(90), 0)
	Kit.pipe("Pipe", length, diameter, cf, color or RGB(90, 95, 110), Enum.Material.Metal, true)
	local rings = math.floor(length / 8)
	for i = 1, rings do
		local p = a:Lerp(b, i / (rings + 1))
		Kit.pipe("PipeRing", 0.5, diameter + 0.3, CFrame.lookAt(p, b) * CFrame.Angles(0, rad(90), 0), RGB(50, 52, 60), Enum.Material.Metal, true)
	end
end

-- Canal de lava (daña al tocarla; ver Hazards)
function Kit.lava(size, cf)
	local lava = block("Lava", size, cf, RGB(255, 100, 20), Enum.Material.CrackedLava)
	lava:SetAttribute("Hazard", "Lava")
	local glow = deco("LavaGlow", V(size.X, 0.1, size.Z), cf * CFrame.new(0, size.Y / 2 + 0.05, 0), RGB(255, 140, 30), Enum.Material.Neon)
	glow.Transparency = 0.4
	Kit.light(glow, "SurfaceLight", RGB(255, 120, 30), 16, 1.2, Enum.NormalId.Top)
	return lava
end

-- Cinta transportadora con lingotes
function Kit.conveyor(a, b, width)
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	block("Conveyor", V(width, 1, length), cf, RGB(40, 42, 48), Enum.Material.DiamondPlate)
	for _, s in { -1, 1 } do
		deco("ConveyorSide", V(0.4, 1.2, length), cf * CFrame.new(s * (width / 2 + 0.2), 0.3, 0), RGB(255, 170, 30), Enum.Material.Metal)
	end
	for i = 1, math.floor(length / 4) do
		local bar = deco("GoldBar", V(1.6, 0.6, 2.4), cf * CFrame.new(0, 0.8, -length / 2 + i * 4), RGB(255, 200, 60), Enum.Material.Foil)
		bar.CastShadow = true
	end
end

-- Chimenea industrial con luz roja
function Kit.smokestack(position, height)
	cylinder("Smokestack", height, 6, CFrame.new(position + V(0, height / 2, 0)), RGB(70, 65, 70), Enum.Material.Concrete, nil, true)
	for i = 1, 3 do
		cylinder("StackStripe", 1.2, 6.1, CFrame.new(position + V(0, height * i / 4, 0)), RGB(200, 60, 40), Enum.Material.Concrete, nil, true)
	end
	local light = Kit.ball("StackLight", 1.2, CFrame.new(position + V(0, height + 0.8, 0)), RGB(255, 40, 40), Enum.Material.Neon, true)
	light:SetAttribute("Blink", 1.5)
	-- Humo saliendo de la chimenea
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(RGB(120, 110, 130), RGB(60, 55, 70))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 16) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(5, 8)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Acceleration = V(2, 1, 0)
	smoke.Rate = 4
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = light
end

-- Guirnalda de bombillas entre dos puntos (cuelga un poco por el centro)
function Kit.stringLights(a, b, color)
	local count = math.max(4, math.floor((b - a).Magnitude / 2.5))
	for i = 0, count do
		local t = i / count
		local p = a:Lerp(b, t) - V(0, math.sin(t * math.pi) * 1.5, 0)
		local bulb = Kit.ball("Bulb", 0.45, CFrame.new(p), (i % 3 == 0) and RGB(255, 120, 120) or (color or RGB(255, 220, 140)), Enum.Material.Neon, true)
		bulb.CastShadow = false
	end
	local mid = (a + b) / 2 - V(0, 0.75, 0)
	deco("LightWire", V(0.08, 0.08, (b - a).Magnitude), CFrame.lookAt(mid, b), RGB(30, 30, 30), Enum.Material.SmoothPlastic)
end

-- Maceta con flores
function Kit.flowerPot(cf, flowerColor)
	block("Pot", V(2, 1.6, 2), cf * CFrame.new(0, 0.8, 0), RGB(190, 100, 60), Enum.Material.Plaster)
	Kit.ball("Bush", 2.4, cf * CFrame.new(0, 2.1, 0), RGB(70, 160, 70), Enum.Material.Grass, true)
	for i = 0, 2 do
		Kit.ball("Flower", 0.6, cf * CFrame.new(math.cos(i * 2.1) * 0.8, 2.9, math.sin(i * 2.1) * 0.8), flowerColor or RGB(255, 90, 140), Enum.Material.SmoothPlastic, true)
	end
end

-- Parche de flores (tulipanes de colores con tallo y hoja), decorativo: se atraviesa
local TULIP_COLORS = { RGB(235, 50, 60), RGB(255, 200, 40), RGB(255, 110, 170), RGB(250, 250, 255), RGB(160, 90, 255) }
function Kit.flowers(position, count, seed)
	local rng = Random.new(seed or math.floor(position.X * 17 + position.Z * 29))
	count = count or 3
	for _ = 1, count do
		local offset = V(rng:NextNumber(-1.6, 1.6), 0, rng:NextNumber(-1.6, 1.6))
		local h = rng:NextNumber(0.9, 1.5)
		local base = CFrame.new(position + offset) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 6.28), rng:NextNumber(-0.15, 0.15))
		deco("FlowerStem", V(0.1, h, 0.1), base * CFrame.new(0, h / 2, 0), RGB(60, 160, 60), Enum.Material.SmoothPlastic)
		local color = TULIP_COLORS[rng:NextInteger(1, #TULIP_COLORS)]
		local bloom = deco("FlowerBloom", V(0.34, 0.42, 0.34), base * CFrame.new(0, h + 0.15, 0), color, Enum.Material.SmoothPlastic)
		bloom.CastShadow = false
		for k = 0, 2 do
			deco("FlowerPetal", V(0.18, 0.3, 0.06), base * CFrame.Angles(0, k * 2.09, 0) * CFrame.new(0, h + 0.24, 0.16) * CFrame.Angles(rad(-20), 0, 0), color, Enum.Material.SmoothPlastic)
		end
	end
end

-- Pino cartoon (pisos redondos cada vez más estrechos, verde vivo). far = menos pisos (fondo)
function Kit.cartoonPine(position, scale, far)
	scale = scale or 1
	cylinder("PineTrunk", 4 * scale, 1.2 * scale, CFrame.new(position + V(0, 2 * scale, 0)), RGB(120, 80, 50), Enum.Material.Wood)
	local tiers = far and 3 or 5
	for i = 1, tiers do
		local t = (i - 1) / (tiers - 1)
		local d = (9 - 6.5 * t) * scale
		local y = (3.5 + t * 9) * scale
		local h = (12 / tiers + 0.8) * scale
		local tier = cylinder("PineTier", h, d, CFrame.new(position + V(0, y, 0)), RGB(60, 190, 90):Lerp(RGB(40, 150, 70), (i % 2) * 0.5), Enum.Material.SmoothPlastic, nil, true)
		tier.CastShadow = not far
	end
end

-- Mata de hierba alta (hojas finas inclinadas en abanico)
function Kit.grassTuft(position, scale, seed)
	local rng = Random.new(seed or math.floor(position.X * 23 + position.Z * 7))
	scale = scale or 1
	for i = 0, 3 do
		local h = rng:NextNumber(1.1, 1.9) * scale
		local angle = i * 1.57 + rng:NextNumber(-0.3, 0.3)
		local tilt = rad(rng:NextNumber(12, 30))
		local blade = deco("GrassBlade", V(0.16 * scale, h, 0.05), CFrame.new(position) * CFrame.Angles(0, angle, 0) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, h / 2, 0), RGB(70, 190, 70):Lerp(RGB(40, 140, 50), rng:NextNumber()), Enum.Material.SmoothPlastic)
		blade.CastShadow = false
	end
end

-- Cartel de neón grande con texto
function Kit.neonSign(cf, width, height, text, color, frameColor)
	local board = deco("NeonBoard", V(width, height, 0.6), cf, RGB(20, 20, 30), Enum.Material.SmoothPlastic)
	sign(board, Enum.NormalId.Front, text, color, frameColor or color:Lerp(Color3.new(1, 1, 1), 0.5))
	for _, y in { -1, 1 } do
		deco("NeonFrame", V(width + 0.6, 0.35, 0.7), cf * CFrame.new(0, y * height / 2, 0), frameColor or color, Enum.Material.Neon)
	end
	for _, x in { -1, 1 } do
		deco("NeonFrame", V(0.35, height, 0.7), cf * CFrame.new(x * width / 2, 0, 0), frameColor or color, Enum.Material.Neon)
	end
	Kit.light(board, "SurfaceLight", color, 18, 1.5, Enum.NormalId.Front)
	return board
end

-- Carretilla elevadora decorativa
function Kit.forklift(cf)
	block("ForkBody", V(4, 3, 6), cf * CFrame.new(0, 2, 0), RGB(250, 190, 30), Enum.Material.SmoothPlastic)
	deco("ForkCab", V(3.6, 3, 0.3), cf * CFrame.new(0, 5, 1.5), RGB(40, 40, 45), Enum.Material.Metal)
	deco("ForkRoof", V(4, 0.3, 4), cf * CFrame.new(0, 6.6, 0), RGB(40, 40, 45), Enum.Material.Metal)
	deco("ForkMast", V(3, 6, 0.4), cf * CFrame.new(0, 3.5, -3.2), RGB(40, 40, 45), Enum.Material.Metal)
	for _, x in { -1, 1 } do
		deco("Fork", V(0.4, 0.3, 3), cf * CFrame.new(x * 1, 0.6, -4.8), RGB(40, 40, 45), Enum.Material.Metal)
		for _, z in { -2, 2 } do
			Kit.pipe("Wheel", 0.8, 1.6, cf * CFrame.new(x * 2.1, 0.8, z), RGB(25, 25, 28), Enum.Material.Rubber, true)
		end
	end
end

-- Barca decorativa en el agua
function Kit.boat(cf)
	deco("BoatHull", V(6, 2, 14), cf * CFrame.new(0, 0.5, 0), C.White, Enum.Material.SmoothPlastic)
	deco("BoatStripe", V(6.1, 0.6, 14.1), cf * CFrame.new(0, 0.2, 0), C.Red, Enum.Material.SmoothPlastic)
	deco("BoatCabin", V(4.4, 3, 5), cf * CFrame.new(0, 3, 1), RGB(230, 230, 235), Enum.Material.SmoothPlastic)
	deco("BoatRoof", V(5, 0.4, 6), cf * CFrame.new(0, 4.7, 1), C.Red, Enum.Material.SmoothPlastic)
	deco("BoatWindow", V(4.5, 1, 0.2), cf * CFrame.new(0, 3.3, -1.5), RGB(60, 120, 180), Enum.Material.Glass)
end

---------------------------------------------------------------------------
-- Detalles realistas
---------------------------------------------------------------------------

-- Charco: manchas planas de agua que reflejan el cielo y las luces (formas irregulares)
function Kit.puddle(position, size, seed)
	local rng = Random.new(seed or math.floor(position.X * 7 + position.Z * 13))
	for i = 1, 3 do
		local d = size * (i == 1 and 1 or rng:NextNumber(0.45, 0.75))
		local offset = i == 1 and V(0, 0, 0) or V(rng:NextNumber(-0.4, 0.4) * size, 0, rng:NextNumber(-0.4, 0.4) * size)
		local water = deco("Puddle", V(0.04, d, d), CFrame.new(position + offset + V(0, 0.03 + i * 0.002, 0)) * CFrame.Angles(0, 0, math.pi / 2), RGB(38, 44, 52), Enum.Material.Glass)
		water.Shape = Enum.PartType.Cylinder
		water.Transparency = 0.25
		water.Reflectance = 0.45
	end
end

-- Cono de luz volumétrica bajo una lámpara: discos casi transparentes cada vez más anchos (se ve
-- el haz en el aire, sobre todo con niebla). `top` es la posición de la lámpara.
function Kit.lightCone(top, height, topRadius, bottomRadius, color)
	local segments = 5
	local step = height / segments
	for i = 1, segments do
		local t = (i - 0.5) / segments
		local radius = topRadius + (bottomRadius - topRadius) * t
		local disc = deco("LightCone", V(step, radius * 2, radius * 2), CFrame.new(top - V(0, step * (i - 0.5), 0)) * CFrame.Angles(0, 0, math.pi / 2), color, Enum.Material.Neon)
		disc.Shape = Enum.PartType.Cylinder
		disc.Transparency = 0.93 + 0.01 * i
		disc.CastShadow = false
	end
end

-- Vapor que sale de una rejilla del suelo
function Kit.steamVent(cf, strength)
	strength = strength or 1
	local grate = deco("VentGrate", V(3, 0.1, 3), cf * CFrame.new(0, 0.05, 0), RGB(40, 42, 48), Enum.Material.DiamondPlate)
	for i = -1, 1 do
		deco("VentSlot", V(2.6, 0.12, 0.25), cf * CFrame.new(0, 0.06, i * 0.8), RGB(15, 15, 18), Enum.Material.Metal)
	end
	local steam = Instance.new("ParticleEmitter")
	steam.Name = "Steam"
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Color = ColorSequence.new(RGB(235, 238, 245))
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 6) })
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 1) })
	steam.Lifetime = NumberRange.new(2.5, 4)
	steam.Speed = NumberRange.new(3, 6)
	steam.SpreadAngle = Vector2.new(12, 12)
	steam.Acceleration = V(0, 0.8, 0)
	steam.RotSpeed = NumberRange.new(-20, 20)
	steam.Rotation = NumberRange.new(0, 360)
	steam.Rate = 6 * strength
	steam.LightInfluence = 1
	steam.EmissionDirection = Enum.NormalId.Top
	steam.WindAffectsDrag = true
	steam.Parent = grate
	return grate
end

-- Polvo flotando en el aire (se ve a contraluz): una caja invisible que emite motas lentas
function Kit.dustMotes(cf, size, color, rate)
	local volume = deco("DustVolume", size, cf, RGB(255, 255, 255), Enum.Material.SmoothPlastic)
	volume.Transparency = 1
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	dust.Color = ColorSequence.new(color or RGB(255, 245, 220))
	dust.LightEmission = 0.4
	dust.LightInfluence = 0.6
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.12), NumberSequenceKeypoint.new(1, 0) })
	dust.Transparency = NumberSequence.new(0.3)
	dust.Lifetime = NumberRange.new(5, 8)
	dust.Speed = NumberRange.new(0.2, 0.6)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.RotSpeed = NumberRange.new(-30, 30)
	dust.Rate = rate or 12
	dust.WindAffectsDrag = true
	dust.Shape = Enum.ParticleEmitterShape.Box
	dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	dust.Parent = volume
	return volume
end

-- Colina natural de fondo (terreno): una bola grande deformada con bultos, salientes de roca y,
-- si se pide, manchas de otro material por encima (selva, nieve...). Nada de bolas perfectas.
-- `inward` (vector horizontal hacia el centro del mapa) evita que los bultos invadan la zona de juego.
function Kit.naturalHill(center, radius, material, options)
	options = options or {}
	local terrain = workspace.Terrain
	local rng = Random.new(options.Seed or math.floor(center.X * 3 + center.Z * 7))
	local inward = options.Inward
	local function away(offset)
		if inward and offset:Dot(inward) > 0 then
			return offset - inward * (2 * offset:Dot(inward))
		end
		return offset
	end
	-- Dirección sobre la superficie que queda por encima del suelo (y > 3)
	local function surfaceDir(minUp, maxUp)
		local low = math.asin(math.clamp((3 - center.Y) / radius, -1, 1))
		local elevation = math.max(low, minUp) + rng:NextNumber(0, 1) * math.max(0, maxUp - math.max(low, minUp))
		local angle = rng:NextNumber(0, math.pi * 2)
		return V(math.cos(angle) * math.cos(elevation), math.sin(elevation), math.sin(angle) * math.cos(elevation))
	end
	terrain:FillBall(center, radius, material)
	for _ = 1, 4 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(0.35, 0.7) * radius
		local offset = away(V(math.cos(angle) * dist, rng:NextNumber(-0.25, 0.05) * radius, math.sin(angle) * dist))
		terrain:FillBall(center + offset, radius * rng:NextNumber(0.45, 0.65), material)
	end
	-- Salientes de roca en la ladera
	for _ = 1, options.RockCount or 3 do
		local dir = surfaceDir(0.15, 1.1)
		terrain:FillBall(center + dir * radius * 0.94, radius * rng:NextNumber(0.1, 0.18), options.Rock or Enum.Material.Rock)
	end
	-- Manchas en la cima (copas de árboles con LeafyGrass, nieve en una montaña de roca...)
	if options.Top then
		for _ = 1, options.TopCount or 5 do
			local dir = surfaceDir(0.5, 1.4)
			terrain:FillBall(center + dir * radius * 0.92, radius * rng:NextNumber(0.18, 0.3), options.Top)
		end
	end
end

-- Grupo de rocas de terreno medio enterradas (una grande y dos pequeñas al lado)
function Kit.rockCluster(position, size, material, seed)
	local rng = Random.new(seed or math.floor(position.X * 5 + position.Z * 11))
	material = material or Enum.Material.Rock
	local terrain = workspace.Terrain
	terrain:FillBall(position - V(0, size * 0.35, 0), size, material)
	for _ = 1, 2 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local r = size * rng:NextNumber(0.45, 0.65)
		terrain:FillBall(position + V(math.cos(angle) * size * 0.9, -r * 0.4, math.sin(angle) * size * 0.9), r, material)
	end
end

-- Arbusto: tres bolas de hojas con tonos distintos (decorativo: se atraviesa)
function Kit.bush(position, scale, color)
	scale = scale or 1
	local rng = Random.new(math.floor(position.X * 11 + position.Z * 5))
	local base = color or RGB(58, 112, 46)
	for _ = 1, 3 do
		local d = scale * rng:NextNumber(2.4, 3.6)
		local offset = V(rng:NextNumber(-1, 1) * scale, d * 0.3, rng:NextNumber(-1, 1) * scale)
		local leaf = Kit.ball("Bush", d, CFrame.new(position + offset), base:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)), Enum.Material.LeafyGrass, true)
		leaf.CastShadow = d >= 3
	end
end

-- Tronco caído con musgo por encima y los cortes claros (sirve de cobertura baja)
function Kit.log(cf, length, diameter)
	local y = diameter * 0.42
	Kit.pipe("Log", length, diameter, cf * CFrame.new(0, y, 0), RGB(92, 70, 50), Enum.Material.Wood)
	Kit.deco("LogMoss", V(length * 0.7, 0.2, diameter * 0.5), cf * CFrame.new(length * 0.05, y + diameter * 0.42, 0), RGB(78, 118, 52), Enum.Material.LeafyGrass)
	for _, side in { -1, 1 } do
		Kit.pipe("LogEnd", 0.1, diameter * 0.9, cf * CFrame.new(side * length / 2, y, 0), RGB(168, 132, 92), Enum.Material.Wood, true)
	end
end

-- Coche aparcado (sedán): carrocería de pintura brillante, cabina de cristal, ruedas de goma con
-- tapacubos, faros y pilotos. La carrocería y la cabina son cobertura; el resto es decorativo.
-- Largo en el eje X local (el morro mira a -X). options.Snow = true le pone nieve encima.
function Kit.car(cf, color, options)
	options = options or {}
	local model = Instance.new("Model")
	model.Name = "Car"
	model.Parent = Kit.folder
	local function paint(part)
		part.Material = Enum.Material.SmoothPlastic -- pintura lisa con brillo (no yeso)
		part.MaterialVariant = "" -- sin cuadrícula: es pintura de coche
		part.Reflectance = 0.12
		return part
	end
	paint(block("CarBody", V(9, 1.5, 4.2), cf * CFrame.new(0, 1.25, 0), color, nil, model))
	paint(block("CarHood", V(2.6, 0.35, 4.1), cf * CFrame.new(-3.1, 2.15, 0), color, nil, model))
	paint(block("CarTrunk", V(1.6, 0.35, 4.1), cf * CFrame.new(3.6, 2.15, 0), color, nil, model))
	local cabin = block("CarCabin", V(4.6, 1.35, 3.8), cf * CFrame.new(0.2, 2.65, 0), RGB(28, 34, 44), Enum.Material.Glass, model)
	cabin.Reflectance = 0.35
	cabin.Transparency = 0.15
	paint(deco("CarRoof", V(3.4, 0.22, 3.86), cf * CFrame.new(0.3, 3.42, 0), color, nil, model))
	-- Parabrisas y luna trasera inclinados (cuñas de cristal)
	for _, spec in { { -2.6, 1, math.pi / 2 }, { 2.9, 0.8, -math.pi / 2 } } do
		local glass = Instance.new("WedgePart")
		glass.Name = "CarWindshield"
		glass.Anchored = true
		glass.CanCollide = false
		glass.CanQuery = false
		glass.CanTouch = false
		glass.CastShadow = false
		glass.Size = V(3.8, 1.35, spec[2])
		glass.CFrame = cf * CFrame.new(spec[1], 2.65, 0) * CFrame.Angles(0, spec[3], 0)
		glass.Color = RGB(28, 34, 44)
		glass.Material = Enum.Material.Glass
		glass.Reflectance = 0.35
		glass.Transparency = 0.15
		glass.Parent = model
	end
	for _, x in { -2.15, 2.5 } do
		paint(deco("CarPillar", V(0.3, 1.35, 3.86), cf * CFrame.new(x, 2.65, 0), color, nil, model))
	end
	-- Ruedas y tapacubos
	for _, x in { -2.9, 2.9 } do
		for _, z in { -1.85, 1.85 } do
			local wheel = deco("Wheel", V(1.75, 1.75, 0.7), cf * CFrame.new(x, 0.875, z) * CFrame.Angles(0, math.pi / 2, 0), RGB(24, 24, 26), Enum.Material.Rubber, model)
			wheel.Shape = Enum.PartType.Cylinder
			local hub = deco("Hubcap", V(0.08, 0.95, 0.95), cf * CFrame.new(x, 0.875, z + (z > 0 and 0.36 or -0.36)) * CFrame.Angles(0, math.pi / 2, 0), RGB(190, 192, 198), Enum.Material.Metal, model)
			hub.Shape = Enum.PartType.Cylinder
		end
	end
	-- Parachoques, faros y pilotos
	for _, x in { -4.6, 4.6 } do
		deco("Bumper", V(0.3, 0.5, 4.3), cf * CFrame.new(x, 0.85, 0), RGB(35, 35, 38), Enum.Material.Plastic, model)
	end
	for _, z in { -1.5, 1.5 } do
		deco("Headlight", V(0.12, 0.35, 0.8), cf * CFrame.new(-4.52, 1.55, z), RGB(250, 248, 235), Enum.Material.Neon, model)
		deco("Taillight", V(0.12, 0.3, 0.7), cf * CFrame.new(4.52, 1.6, z), RGB(200, 25, 25), Enum.Material.Neon, model)
	end
	deco("Plate", V(0.08, 0.35, 1.1), cf * CFrame.new(4.62, 1.05, 0), RGB(235, 235, 225), Enum.Material.SmoothPlastic, model)
	if options.Snow then
		local snow = RGB(240, 245, 252)
		deco("CarSnow", V(3.2, 0.35, 3.6), cf * CFrame.new(0.3, 3.7, 0), snow, Enum.Material.Snow, model)
		deco("CarSnow", V(2.3, 0.25, 3.8), cf * CFrame.new(-3.2, 2.45, 0), snow, Enum.Material.Snow, model)
		deco("CarSnow", V(1.4, 0.25, 3.8), cf * CFrame.new(3.6, 2.45, 0), snow, Enum.Material.Snow, model)
	end
	Kit.contactShadow(cf, 9, 4.2, false, model)
	return model
end

-- Tapa de alcantarilla de hierro fundido
function Kit.manhole(position)
	Kit.cylinder("ManholeRim", 0.05, 3.5, CFrame.new(position + V(0, 0.025, 0)), RGB(72, 70, 66), Enum.Material.Metal, nil, true)
	Kit.cylinder("Manhole", 0.07, 3, CFrame.new(position + V(0, 0.035, 0)), RGB(46, 44, 42), Enum.Material.DiamondPlate, nil, true)
end

-- Rejilla de desagüe junto a un bordillo
function Kit.drain(cf)
	Kit.deco("DrainFrame", V(3.2, 0.06, 1.6), cf * CFrame.new(0, 0.03, 0), RGB(60, 58, 55), Enum.Material.Metal)
	for i = -3, 3 do
		Kit.deco("DrainSlot", V(0.18, 0.07, 1.2), cf * CFrame.new(i * 0.4, 0.036, 0), RGB(14, 14, 16), Enum.Material.Metal)
	end
end

-- Mancha de aceite: discos oscuros semitransparentes con un brillo leve
function Kit.oilStain(position, size, seed)
	local rng = Random.new(seed or math.floor(position.X * 13 + position.Z * 3))
	for i = 1, 3 do
		local d = size * (i == 1 and 1 or rng:NextNumber(0.4, 0.7))
		local offset = i == 1 and V(0, 0, 0) or V(rng:NextNumber(-0.35, 0.35) * size, 0, rng:NextNumber(-0.35, 0.35) * size)
		local stain = Kit.cylinder("OilStain", 0.02, d, CFrame.new(position + offset + V(0, 0.012 + i * 0.002, 0)), RGB(18, 18, 20), Enum.Material.SmoothPlastic, nil, true)
		stain.Transparency = 0.55 + i * 0.08
		stain.Reflectance = 0.08
	end
end

-- Grieta en el suelo: segmentos finos en zigzag
function Kit.crack(position, length, seed)
	local rng = Random.new(seed or math.floor(position.X * 7 + position.Z * 17))
	local heading = rng:NextNumber(0, math.pi * 2)
	local point = position
	local segments = math.max(3, math.floor(length / 2.5))
	for i = 1, segments do
		heading += rng:NextNumber(-0.7, 0.7)
		local seg = length / segments
		local dir = V(math.cos(heading), 0, math.sin(heading))
		local width = 0.16 * (1 - i / (segments + 1)) + 0.05
		Kit.deco("Crack", V(seg + 0.1, 0.03, width), CFrame.lookAt(point + dir * (seg / 2) + V(0, 0.015, 0), point + dir * seg + V(0, 0.015, 0)) * CFrame.Angles(0, math.pi / 2, 0), RGB(28, 28, 30), Enum.Material.SmoothPlastic)
		point += dir * seg
	end
end

-- Juntas de dilatación de una losa de hormigón o asfalto: líneas oscuras cada `spacing` studs
function Kit.floorJoints(cf, length, width, spacing, color)
	color = color or RGB(40, 40, 42)
	for x = -length / 2 + spacing, length / 2 - spacing / 2, spacing do
		Kit.deco("Joint", V(0.15, 0.03, width), cf * CFrame.new(x, 0.015, 0), color, Enum.Material.SmoothPlastic)
	end
	for z = -width / 2 + spacing, width / 2 - spacing / 2, spacing do
		Kit.deco("Joint", V(length, 0.03, 0.15), cf * CFrame.new(0, 0.015, z), color, Enum.Material.SmoothPlastic)
	end
end

-- Marcas de neumático: dos franjas oscuras paralelas que hacen una curva suave
function Kit.tireMarks(cf, length, bend)
	bend = bend or 0.3
	local segments = 6
	local seg = length / segments
	local pose = cf
	for _ = 1, segments do
		pose = pose * CFrame.Angles(0, bend / segments, 0)
		for _, side in { -1.1, 1.1 } do
			local mark = Kit.deco("TireMark", V(0.7, 0.02, seg + 0.05), pose * CFrame.new(side, 0.011, -seg / 2), RGB(20, 20, 22), Enum.Material.SmoothPlastic)
			mark.Transparency = 0.6
		end
		pose = pose * CFrame.new(0, 0, -seg)
	end
end

---------------------------------------------------------------------------
-- Puntos especiales del modo de juego
---------------------------------------------------------------------------

-- Zona de reaparición del equipo con techo, muretes y SpawnLocations
function Kit.spawnArea(team, cf, style)
	style = style or {}
	local teamColor = team.Color.Color
	local light = teamColor:Lerp(Color3.new(1, 1, 1), 0.55)
	local floorColor = style.Floor or light
	-- (los colores del equipo se quedan puros, también en el estilo realista: así casan con los neones
	-- y las zonas de aparición y se reconoce de un vistazo de qué equipo es la base)
	local floor = block(team.Name .. "SpawnFloor", V(30, 0.4, 70), cf * CFrame.new(0, 0.2, 0), floorColor, style.FloorMaterial or Enum.Material.SmoothPlastic)
	floor.Color = floorColor
	for z = -30, 30, 10 do
		deco("FloorLine", V(30, 0.05, 0.3), cf * CFrame.new(0, 0.42, z), teamColor, Enum.Material.SmoothPlastic).Color = teamColor
	end
	local roofColor = style.Roof or RGB(235, 235, 240)
	local roof = block(team.Name .. "SpawnRoof", V(30, 1, 70), cf * CFrame.new(0, 16, 0), roofColor, style.RoofMaterial or Enum.Material.Concrete)
	-- (no se puede pisar: con el supersalto alguien podría subirse a acampar encima de la base enemiga;
	-- las balas sí lo siguen chocando)
	roof.CanCollide = false
	deco("RoofTrim", V(0.6, 0.5, 70.2), cf * CFrame.new(15, 15.4, 0), teamColor, Enum.Material.Neon)
	local banner = block("TeamBanner", V(0.6, 4, 28), cf * CFrame.new(15.2, 18.6, 0), teamColor, Enum.Material.SmoothPlastic)
	banner.Color = teamColor
	sign(banner, Enum.NormalId.Right, "EQUIPO " .. string.upper(team.Name), Color3.new(1, 1, 1))
	sign(banner, Enum.NormalId.Left, "EQUIPO " .. string.upper(team.Name), Color3.new(1, 1, 1))
	for _, z in { -34, 34 } do
		block("Pillar", V(2, 16, 2), cf * CFrame.new(14, 8, z), roofColor, Enum.Material.Concrete)
		deco("PillarStripe", V(2.1, 1, 2.1), cf * CFrame.new(14, 12, z), teamColor, Enum.Material.Neon)
	end
	for _, z in { -24, 0, 24 } do
		block("Cover", V(2, 4, 10), cf * CFrame.new(14, 2, z), teamColor, Enum.Material.SmoothPlastic).Color = teamColor
		deco("CoverTop", V(2.1, 0.3, 10.1), cf * CFrame.new(14, 4.05, z), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	end
	for i, z in { -24, -8, 8, 24 } do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = team.Name .. "Spawn" .. i
		spawn.Anchored = true
		spawn.Size = V(6, 1, 6)
		spawn.CFrame = cf * CFrame.new(-4, 0.5, z) * CFrame.Angles(0, -math.pi / 2, 0)
		spawn.TeamColor = team.Color
		spawn.BrickColor = team.Color
		spawn.Material = Enum.Material.Neon
		spawn.Neutral = false
		spawn.AllowTeamChangeOnTouch = false
		spawn.Duration = GameConfig.SpawnProtection
		spawn.Parent = Kit.folder
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
	end
	local lamp = deco("SpawnLight", V(20, 0.2, 60), cf * CFrame.new(0, 15.4, 0), teamColor:Lerp(Color3.new(1, 1, 1), 0.7), Enum.Material.Neon)
	Kit.light(lamp, "SurfaceLight", teamColor:Lerp(Color3.new(1, 1, 1), 0.5), 16, 0.8, Enum.NormalId.Bottom)
end

-- Base de la bandera (Captura la bandera). Flags busca piezas "FlagBase" con el atributo Team.
function Kit.flagBase(team, cf)
	local teamColor = team.Color.Color
	local ring = deco("FlagBaseRing", V(0.3, 13, 13), cf * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.pi / 2), teamColor, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	local pad = block("FlagBase", V(0.4, 11, 11), cf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), RGB(235, 235, 240), Enum.Material.Concrete)
	pad.Shape = Enum.PartType.Cylinder
	pad:SetAttribute("Team", team.Name)
	local inner = deco("FlagBaseInner", V(0.45, 4, 4), cf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), teamColor, Enum.Material.Neon)
	inner.Shape = Enum.PartType.Cylinder
	for i = 0, 3 do
		local angle = i * math.pi / 2 + math.pi / 4
		local offset = CFrame.new(math.cos(angle) * 7.5, 0, math.sin(angle) * 7.5)
		cylinder("Pylon", 2, 0.7, cf * offset * CFrame.new(0, 1, 0), RGB(230, 230, 235), Enum.Material.SmoothPlastic, nil, true)
		Kit.ball("PylonLight", 0.8, cf * offset * CFrame.new(0, 2.3, 0), teamColor, Enum.Material.Neon, true)
	end
	Kit.light(inner, "PointLight", teamColor, 16, 1.5)
	return pad
end

-- Calabaza de Halloween con cara iluminada (decoración del evento; se atraviesa)
function Kit.pumpkin(cf, scale)
	scale = scale or 1
	-- Esferas achatadas: una Ball de Roblox siempre es redonda, así que se usa una malla de esfera
	local function squashed(part)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
	local body = deco("Pumpkin", V(3 * scale, 2.4 * scale, 3 * scale), cf * CFrame.new(0, 1.2 * scale, 0), RGB(255, 130, 20), Enum.Material.SmoothPlastic)
	squashed(body)
	for _, a in { 0, 60, 120 } do
		local rib = deco("PumpkinRib", V(0.6 * scale, 2.3 * scale, 3.06 * scale), cf * CFrame.new(0, 1.2 * scale, 0) * CFrame.Angles(0, rad(a), 0), RGB(230, 100, 10), Enum.Material.SmoothPlastic)
		squashed(rib)
	end
	Kit.cylinder("PumpkinStem", 0.6 * scale, 0.35 * scale, cf * CFrame.new(0, 2.5 * scale, 0), RGB(80, 120, 40), Enum.Material.SmoothPlastic, nil, true)
	-- Ojos y boca brillantes (hacia -Z del cf)
	for _, s in { -1, 1 } do
		deco("PumpkinEye", V(0.45 * scale, 0.4 * scale, 0.2 * scale), cf * CFrame.new(s * 0.5 * scale, 1.5 * scale, -1.42 * scale) * CFrame.Angles(0, 0, rad(s * 20)), RGB(255, 220, 90), Enum.Material.Neon)
	end
	local mouth = deco("PumpkinMouth", V(1.1 * scale, 0.25 * scale, 0.2 * scale), cf * CFrame.new(0, 0.85 * scale, -1.45 * scale), RGB(255, 220, 90), Enum.Material.Neon)
	Kit.light(mouth, "PointLight", RGB(255, 160, 60), 8 * scale, 0.8)
	return body
end

-- Muñeco de nieve (decoración del evento de Navidad): tres bolas, ojos de carbón, nariz de
-- zanahoria, bufanda y sombrero de copa
function Kit.snowman(cf, scale)
	scale = scale or 1
	local snow = RGB(245, 248, 255)
	Kit.ball("SnowmanBase", 3.2 * scale, cf * CFrame.new(0, 1.5 * scale, 0), snow, Enum.Material.SmoothPlastic, true)
	Kit.ball("SnowmanBody", 2.4 * scale, cf * CFrame.new(0, 3.4 * scale, 0), snow, Enum.Material.SmoothPlastic, true)
	local headCf = cf * CFrame.new(0, 4.95 * scale, 0)
	Kit.ball("SnowmanHead", 1.7 * scale, headCf, snow, Enum.Material.SmoothPlastic, true)
	for _, s in { -1, 1 } do
		Kit.ball("SnowmanEye", 0.22 * scale, headCf * CFrame.new(s * 0.3 * scale, 0.2 * scale, -0.75 * scale), RGB(25, 25, 30), Enum.Material.SmoothPlastic, true)
	end
	deco("SnowmanNose", V(0.18 * scale, 0.18 * scale, 0.7 * scale), headCf * CFrame.new(0, 0, -1.05 * scale), RGB(255, 130, 30), Enum.Material.SmoothPlastic)
	for i = 1, 3 do
		Kit.ball("SnowmanButton", 0.22 * scale, cf * CFrame.new(0, (2.8 + i * 0.4) * scale, -1.12 * scale), RGB(25, 25, 30), Enum.Material.SmoothPlastic, true)
	end
	Kit.cylinder("SnowmanScarf", 0.35 * scale, 1.75 * scale, cf * CFrame.new(0, 4.25 * scale, 0), RGB(220, 40, 50), Enum.Material.Fabric, nil, true)
	deco("SnowmanScarfTail", V(0.35 * scale, 1 * scale, 0.12 * scale), cf * CFrame.new(0.45 * scale, 3.8 * scale, -0.8 * scale), RGB(220, 40, 50), Enum.Material.Fabric)
	Kit.cylinder("SnowmanHatBrim", 0.12 * scale, 1.9 * scale, headCf * CFrame.new(0, 0.75 * scale, 0), RGB(25, 25, 30), Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("SnowmanHat", 1 * scale, 1.15 * scale, headCf * CFrame.new(0, 1.3 * scale, 0), RGB(25, 25, 30), Enum.Material.SmoothPlastic, nil, true)
	Kit.cylinder("SnowmanHatBand", 0.2 * scale, 1.18 * scale, headCf * CFrame.new(0, 0.95 * scale, 0), RGB(220, 40, 50), Enum.Material.SmoothPlastic, nil, true)
end

-- Plataforma de salto: al pisarla te lanza hacia arriba (el cliente lo hace, ver JumpPads).
-- power = velocidad vertical (75 ≈ 14 studs de altura). Para subir a cornisas y a lo alto.
function Kit.jumpPad(position, power, color)
	color = color or RGB(80, 230, 255)
	local ring = Kit.cylinder("JumpPadRing", 0.4, 7.6, CFrame.new(position + V(0, 0.2, 0)), RGB(250, 250, 255), Enum.Material.SmoothPlastic)
	ring:SetAttribute("JumpPad", power or 75) -- también lanza si pisas el borde
	local pad = Kit.cylinder("JumpPad", 0.5, 6, CFrame.new(position + V(0, 0.3, 0)), color, Enum.Material.Neon)
	pad:SetAttribute("JumpPad", power or 75)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "JumpPadSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(color)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(0.6, 0)
	sparks.Lifetime = NumberRange.new(0.6, 1)
	sparks.Rate = 8
	sparks.Speed = NumberRange.new(8, 12)
	sparks.SpreadAngle = Vector2.new(12, 12)
	sparks.EmissionDirection = Enum.NormalId.Right -- el eje X del cilindro es el vertical: suben
	sparks.Parent = pad
	return pad
end

-- Punto de aparición para "Todos contra todos" y "Escalada" (invisible)
function Kit.ffaSpawn(position)
	local p = deco("FFASpawn", V(2, 1, 2), CFrame.new(position + V(0, 0.5, 0)), C.White, Enum.Material.SmoothPlastic)
	p.Transparency = 1
	return p
end

-- Puesto de vigilancia para los bots tiradores (ventana, azotea, torre): se apostan ahí mirando
-- hacia look. No es un punto de aparición.
function Kit.botSpot(position, look)
	local p = deco("BotSpot", V(1, 1, 1), CFrame.new(position + V(0, 0.5, 0)), C.White, Enum.Material.SmoothPlastic)
	p.Transparency = 1
	p:SetAttribute("Look", look)
	return p
end

-- Sitio de la bomba (Buscar y destruir): letra "A" o "B" y qué equipo lo defiende (1 o 2, el de
-- GameConfig.Teams). Cada equipo defiende los dos sitios de su mitad.
function Kit.bombSite(position, letter, defender)
	local p = deco("BombSite", V(1, 1, 1), CFrame.new(position + V(0, 0.5, 0)), C.White, Enum.Material.SmoothPlastic)
	p.Transparency = 1
	p:SetAttribute("Letter", letter)
	p:SetAttribute("Defender", defender)
	p:SetAttribute("Radius", 7)
	-- La letra pintada en el suelo, como en los mapas de los shooters (se ve en todos los modos)
	local floorY = position.Y
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Kit.folder, workspace.Terrain }
	local hit = workspace:Raycast(position + V(0, 2, 0), V(0, -5, 0), params)
	if hit then
		floorY = hit.Position.Y
	end
	local paint = deco("SiteLetter", V(7, 0.05, 7), CFrame.new(position.X, floorY + 0.04, position.Z), C.White, Enum.Material.SmoothPlastic)
	paint.Transparency = 1
	paint.CastShadow = false
	local gui = sign(paint, Enum.NormalId.Top, letter, Color3.fromRGB(205, 58, 40), Color3.fromRGB(205, 58, 40))
	gui.LightInfluence = 1
	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Font = Enum.Font.GothamBlack
		label.TextTransparency = 0.12
		label.TextStrokeTransparency = 1
	end
	return p
end

-- Zona de control (modo "Zona"). order = orden de rotación.
function Kit.zone(position, radius, order)
	local z = deco("HardpointZone", V(0.3, radius * 2, radius * 2), CFrame.new(position + V(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2), C.White, Enum.Material.SmoothPlastic)
	z.Shape = Enum.PartType.Cylinder
	z.Transparency = 1
	z:SetAttribute("Order", order)
	z:SetAttribute("Radius", radius)
	return z
end

-- Muros exteriores invisibles (y techo) para que nadie se salga
-- Muros y techo invisibles. Van en la carpeta Map.Boundary, que los disparos ignoran
-- (CanQuery = false no sirve en piezas que colisionan, así que se excluyen en cada raycast).
function Kit.bounds(length, width, height)
	local folder = Kit.folder:FindFirstChild("Boundary") or Instance.new("Folder")
	folder.Name = "Boundary"
	folder.Parent = Kit.folder
	local function wall(size, cf)
		local w = block("Boundary", size, cf, Color3.new(1, 1, 1), nil, folder)
		w.Transparency = 1
		w.CastShadow = false
	end
	wall(V(length, height, 4), CFrame.new(0, height / 2, width / 2 + 2))
	wall(V(length, height, 4), CFrame.new(0, height / 2, -width / 2 - 2))
	wall(V(4, height, width), CFrame.new(length / 2 + 2, height / 2, 0))
	wall(V(4, height, width), CFrame.new(-length / 2 - 2, height / 2, 0))
	wall(V(length, 1, width), CFrame.new(0, height, 0))
end

---------------------------------------------------------------------------
-- Iluminación por mapa
---------------------------------------------------------------------------

-- Colores por defecto de los materiales del terreno (se restauran al cambiar de mapa)
local TERRAIN_DEFAULTS = {
	Grass = RGB(106, 127, 63),
	LeafyGrass = RGB(115, 132, 74),
	Mud = RGB(58, 46, 36),
	Ground = RGB(102, 92, 59),
	Snow = RGB(195, 199, 218),
	Glacier = RGB(101, 176, 234),
	Rock = RGB(102, 108, 111),
	Sand = RGB(143, 126, 95),
	Sandstone = RGB(137, 90, 71),
	Slate = RGB(63, 127, 107),
	Pavement = RGB(148, 148, 140),
}

-- Hierba y hojas más vivas en estilo Cartoon
local CARTOON_TERRAIN = {
	Grass = RGB(80, 175, 70),
	LeafyGrass = RGB(66, 150, 58),
	Ground = RGB(150, 120, 80),
}

local function ensure(className, parent)
	parent = parent or Lighting
	local inst = parent:FindFirstChildOfClass(className)
	if not inst then
		inst = Instance.new(className)
		inst.Parent = parent
	end
	return inst
end

-- Estilo Cartoon: luz más suave y clara (sombras rellenas), menos neblina, sin deslumbramiento y
-- más saturación; el ambiente de cada mapa (hora, color del cielo) se mantiene
local function cartoonize(preset)
	local p = table.clone(preset)
	local clock = p.ClockTime or 14
	local night = clock < 6 or clock > 18.6
	p.Ambient = (p.Ambient or RGB(60, 62, 72)):Lerp(night and RGB(70, 70, 105) or RGB(125, 125, 145), 0.55)
	p.OutdoorAmbient = (p.OutdoorAmbient or RGB(125, 128, 140)):Lerp(night and RGB(90, 90, 135) or RGB(170, 170, 190), 0.55)
	p.ShadowSoftness = 0.3
	if not night then
		p.Brightness = math.max(p.Brightness or 3, 3)
	end
	local a = table.clone(p.Atmosphere or {})
	a.Density = math.min(a.Density or 0.3, 0.26)
	a.Haze = math.min(a.Haze or 1.4, 0.6)
	a.Glare = 0
	p.Atmosphere = a
	local c = table.clone(p.Color or {})
	c.Saturation = (c.Saturation or 0.1) + 0.12
	c.Contrast = 0.06
	c.Brightness = (c.Brightness or 0.02) + 0.02
	p.Color = c
	local b = table.clone(p.Bloom or {})
	b.Intensity = math.min(b.Intensity or 0.8, 0.45)
	p.Bloom = b
	p.Clouds = math.max(p.Clouds or 0.55, 0.6)
	p.SunRays = math.min(p.SunRays or 0.06, 0.05)
	local terrain = {}
	for name, color in TERRAIN_DEFAULTS do
		terrain[name] = Kit.vivid((p.TerrainColors and p.TerrainColors[name]) or CARTOON_TERRAIN[name] or color)
	end
	p.TerrainColors = terrain
	return p
end

-- Estilo realista en mapas pensados para Cartoon: luz más contrastada (sombras más oscuras y nítidas),
-- color natural (menos tono pastel en el ambiente y la neblina), neblina y brillo del sol de verdad,
-- y hierba y tierra de colores naturales. Se respeta el carácter de cada mapa: la hora, las sombras
-- azuladas de la nieve, el aire limpio de la Luna, los pétalos rosas, la nieve blanca y el brillo de
-- los neones de noche (que además se aclara un poco para que se vea bien en el móvil).
local function neutralize(color, amount)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s * (1 - amount), v)
end

-- Que el color tenga al menos este brillo (el canal más alto), sin cambiar su tono
local function atLeast(color, minimum)
	local top = math.max(color.R, color.G, color.B) * 255
	if top >= minimum or top <= 0 then
		return color
	end
	local k = minimum / top
	return Color3.new(math.min(1, color.R * k), math.min(1, color.G * k), math.min(1, color.B * k))
end

local SNOWY = { Snow = true, Ice = true, Glacier = true }

local function realize(preset)
	local p = table.clone(preset)
	local clock = p.ClockTime or 14
	-- (el atardecer y el anochecer cuentan como noche: sin brillo del sol forzado)
	local night = clock < 6.2 or clock > 17.8
	p.Ambient = neutralize(p.Ambient or RGB(60, 62, 72), 0.35)
		:Lerp(night and RGB(44, 46, 60) or RGB(70, 72, 82), night and 0.25 or 0.3)
	p.OutdoorAmbient = neutralize(p.OutdoorAmbient or RGB(125, 128, 140), 0.35)
		:Lerp(night and RGB(70, 74, 98) or RGB(120, 122, 132), night and 0.25 or 0.3)
	if night then
		p.Ambient = atLeast(p.Ambient, 50)
		p.OutdoorAmbient = atLeast(p.OutdoorAmbient, 80)
	end
	p.ShadowSoftness = math.min(p.ShadowSoftness or 0.12, 0.15)
	local a = table.clone(p.Atmosphere or {})
	-- (si el mapa pide un aire muy limpio, como la Luna, se respeta)
	local thin = (a.Density or 0.3) < 0.2
	if not thin then
		a.Density = math.max(a.Density or 0.3, 0.3)
		a.Haze = math.max(a.Haze or 1.4, 1.2)
	end
	-- (de noche, sin aire o con el cielo cubierto —tormenta, niebla— no hay brillo de sol)
	local overcast = (p.Clouds or 0) >= 0.85
	a.Glare = (night or thin or overcast) and (a.Glare or 0) or math.max(a.Glare or 0.3, 0.25)
	if a.Color then
		a.Color = neutralize(a.Color, 0.4)
	end
	if a.Decay then
		a.Decay = neutralize(a.Decay, 0.4)
	end
	p.Atmosphere = a
	local c = table.clone(p.Color or {})
	c.Saturation = math.min(c.Saturation or 0.05, night and 0.12 or 0.05)
	c.Contrast = math.max(c.Contrast or 0.12, 0.12)
	c.Brightness = math.min(c.Brightness or 0, 0.02)
	if c.Tint then
		c.Tint = neutralize(c.Tint, 0.5)
	end
	p.Color = c
	-- Brillo: de día contenido (el sol no deslumbra como en un dibujo); de noche se deja que los
	-- neones brillen
	local b = table.clone(p.Bloom or {})
	b.Intensity = math.min(b.Intensity or 0.6, night and 0.9 or 0.6)
	b.Threshold = math.max(b.Threshold or 1.6, night and 1.35 or 1.6)
	p.Bloom = b
	-- Terreno: los verdes muy vivos van hacia el tono natural; lo demás pensado a propósito (pétalos,
	-- arena, roca) solo se apaga un poco, y la nieve y el hielo se quedan como están
	local terrain = {}
	for name, color in TERRAIN_DEFAULTS do
		local custom = p.TerrainColors and p.TerrainColors[name]
		if not custom then
			terrain[name] = color
		elseif SNOWY[name] then
			terrain[name] = custom
		else
			local h, sat = custom:ToHSV()
			if sat > 0.25 and h > 0.12 and h < 0.45 then
				terrain[name] = neutralize(custom, 0.3):Lerp(color, 0.35)
			else
				terrain[name] = Kit.natural(custom)
			end
		end
	end
	p.TerrainColors = terrain
	return p
end
Kit.realize = realize

-- Estilo Táctico (estilizado): materiales de verdad pero luz limpia y legible, como los shooters de
-- Roblox modernos. Color un poco vivo (cada mapa conserva su tinte), contraste moderado, sombras
-- limpias sin zonas negras, neblina que da profundidad sin tapar a nadie y un brillo contenido (solo
-- brillan las luces y los neones, no las paredes al sol). Lo importante es ver al enemigo.
-- designed: mapa ya pensado con su luz (Kit.Begin con Realistic): solo se le ponen los límites de
-- legibilidad (ni muy oscuro, ni mucha niebla, ni mucho brillo)
local function tacticalize(preset, designed)
	local p = table.clone(preset)
	local clock = p.ClockTime or 14
	local night = clock < 6.2 or clock > 17.8
	if designed then
		p.Ambient = atLeast(p.Ambient or RGB(60, 62, 72), night and 55 or 66)
		p.OutdoorAmbient = atLeast(p.OutdoorAmbient or RGB(125, 128, 140), night and 85 or 112)
	else
		p.Ambient = neutralize(p.Ambient or RGB(60, 62, 72), 0.15)
			:Lerp(night and RGB(54, 58, 78) or RGB(82, 84, 96), 0.25)
		p.OutdoorAmbient = neutralize(p.OutdoorAmbient or RGB(125, 128, 140), 0.15)
			:Lerp(night and RGB(78, 84, 112) or RGB(138, 140, 152), 0.25)
		p.Ambient = atLeast(p.Ambient, night and 55 or 70)
		p.OutdoorAmbient = atLeast(p.OutdoorAmbient, night and 88 or 120)
		p.ShadowSoftness = 0.2
	end
	local a = table.clone(p.Atmosphere or {})
	local thin = (a.Density or 0.3) < 0.2
	if not thin then
		local maxDensity = designed and 0.38 or 0.34
		a.Density = math.clamp(a.Density or 0.3, designed and 0.2 or 0.24, maxDensity)
		a.Haze = math.clamp(a.Haze or 1.4, 0.4, designed and 1.4 or 1.1)
	end
	local overcast = (p.Clouds or 0) >= 0.85
	if not designed then
		a.Glare = (night or thin or overcast) and math.min(a.Glare or 0, 0.1) or 0.15
		if a.Color then
			a.Color = neutralize(a.Color, 0.2)
		end
		if a.Decay then
			a.Decay = neutralize(a.Decay, 0.2)
		end
	else
		a.Glare = math.min(a.Glare or 0.3, 0.3)
	end
	p.Atmosphere = a
	local c = table.clone(p.Color or {})
	if designed then
		c.Saturation = math.max(c.Saturation or 0.05, 0.06)
		c.Contrast = math.min(c.Contrast or 0.12, 0.16)
	else
		c.Saturation = math.clamp(c.Saturation or 0.1, 0.08, night and 0.14 or 0.16)
		c.Contrast = math.clamp(c.Contrast or 0.12, 0.08, 0.13)
		c.Brightness = math.clamp(c.Brightness or 0.02, 0, 0.03)
		if c.Tint then
			c.Tint = neutralize(c.Tint, 0.3) -- (el tinte del mapa se nota, pero sin teñirlo todo)
		end
	end
	p.Color = c
	local b = table.clone(p.Bloom or {})
	b.Intensity = math.min(b.Intensity or 0.6, night and 0.75 or 0.5)
	b.Threshold = math.max(b.Threshold or 1.8, night and 1.4 or 1.8)
	b.Size = math.min(b.Size or 22, 24)
	p.Bloom = b
	p.SunRays = math.min(p.SunRays or 0.05, 0.05)
	if not designed then
		-- Terreno: los colores del mapa se respetan; solo los verdes chillones bajan un poco
		local terrain = {}
		for name, color in TERRAIN_DEFAULTS do
			local custom = p.TerrainColors and p.TerrainColors[name]
			if not custom or SNOWY[name] then
				terrain[name] = custom or color
			else
				local h, sat = custom:ToHSV()
				terrain[name] = (sat > 0.5 and h > 0.12 and h < 0.45) and neutralize(custom, 0.18) or custom
			end
		end
		p.TerrainColors = terrain
	end
	return p
end
Kit.tacticalize = tacticalize

-- Luz de esta partida: a veces sale otra hora del día del mapa (como las versiones de los mapas en
-- los shooters de móvil). map.LightingVariants = { { Name = "Atardecer", Chance = 0.3, ...cambios } }.
-- Deja el nombre de la variante en Kit.Variant (y el mapa lo guarda en su atributo Variant).
function Kit.pickLighting(map)
	Kit.Variant, Kit.Weather = nil, nil
	for _, variant in map.LightingVariants or {} do
		if math.random() < (variant.Chance or 0.3) then
			local preset = table.clone(map.Lighting)
			for key, value in variant do
				if key ~= "Name" and key ~= "Chance" and key ~= "Weather" then
					preset[key] = value
				end
			end
			Kit.Variant = variant.Name
			Kit.Weather = variant.Weather -- ("Rain": lluvia y truenos en el cliente, ver Ambience)
			return preset
		end
	end
	return map.Lighting
end

-- preset: tabla con ClockTime, Brightness, Ambient, OutdoorAmbient, Atmosphere{...}, Color{...}, Bloom{...}, Clouds
function Kit.applyLighting(preset)
	-- Tono de los grises de este mapa (se usa al crear las piezas, que van después)
	local neutral = preset.CartoonNeutral
	Kit.Neutral = type(neutral) == "table" and { Hue = neutral.Hue or 0.68, Sat = neutral.Sat or 0.16 } or { Hue = 0.68, Sat = 0.16 }
	if Kit.Cartoon then
		preset = cartoonize(preset)
	elseif GameConfig.VisualStyle == "Tactico" then
		preset = tacticalize(preset, Kit.Designed)
	elseif not Kit.Designed then
		preset = realize(preset)
	end
	Lighting.ClockTime = preset.ClockTime or 14
	Lighting.GeographicLatitude = preset.Latitude or 35
	Lighting.Brightness = preset.Brightness or 3
	Lighting.ExposureCompensation = preset.Exposure or 0
	Lighting.Ambient = preset.Ambient or RGB(60, 62, 72)
	Lighting.OutdoorAmbient = preset.OutdoorAmbient or RGB(125, 128, 140)
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = preset.ShadowSoftness or 0.12 -- sombras de sol nítidas pero no duras
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = Kit.Cartoon and 0.5 or 1 -- en Cartoon, menos brillo de plástico
	-- Viento: mueve la hierba del terreno, las nubes y las partículas con WindAffectsDrag
	workspace.GlobalWind = preset.Wind or V(4, 0, 2)

	local a = preset.Atmosphere or {}
	local atmosphere = ensure("Atmosphere")
	atmosphere.Density = a.Density or 0.3
	atmosphere.Offset = a.Offset or 0.25
	atmosphere.Color = a.Color or RGB(199, 220, 255)
	atmosphere.Decay = a.Decay or RGB(106, 120, 150)
	atmosphere.Glare = a.Glare or 0.3
	atmosphere.Haze = a.Haze or 1.4

	local c = preset.Color or {}
	local cc = ensure("ColorCorrectionEffect")
	cc.Saturation = c.Saturation or 0.1
	cc.Contrast = c.Contrast or 0.15
	cc.Brightness = c.Brightness or 0.02
	cc.TintColor = c.Tint or RGB(255, 250, 245)

	local b = preset.Bloom or {}
	local bloom = ensure("BloomEffect")
	bloom.Intensity = b.Intensity or 0.8
	bloom.Size = b.Size or 24
	bloom.Threshold = b.Threshold or 2

	local rays = ensure("SunRaysEffect")
	rays.Intensity = preset.SunRays or 0.06
	rays.Spread = 0.6

	local sky = ensure("Sky")
	sky.StarCount = preset.Stars or 3000
	sky.SunAngularSize = preset.SunSize or 21
	sky.MoonAngularSize = preset.MoonSize or 11
	sky.CelestialBodiesShown = true

	local clouds = ensure("Clouds", workspace.Terrain)
	clouds.Cover = preset.Clouds or 0.55
	clouds.Density = Kit.Cartoon and 0.72 or 0.6 -- nubes más esponjosas en Cartoon
	clouds.Color = preset.CloudColor or RGB(255, 255, 255)

	-- Agua del terreno: color, reflejo, transparencia y olas de cada mapa
	local w = preset.Water or {}
	local terrain = workspace.Terrain
	terrain.WaterColor = w.Color or RGB(12, 84, 92)
	terrain.WaterReflectance = w.Reflectance or 1
	terrain.WaterTransparency = w.Transparency or 0.3
	terrain.WaterWaveSize = w.WaveSize or 0.15
	terrain.WaterWaveSpeed = w.WaveSpeed or 10

	-- Colores de los materiales del terreno (hierba, nieve, roca...) según el mapa
	for name, color in TERRAIN_DEFAULTS do
		local custom = preset.TerrainColors and preset.TerrainColors[name]
		pcall(function()
			terrain:SetMaterialColor(Enum.Material[name], custom or color)
		end)
	end
end

-- Suelo de terreno (en vez de una pieza): con Grass sale hierba 3D animada (Terrain.Decoration,
-- activada en default.project.json). La superficie queda exactamente en y = 0.
function Kit.terrainFloor(material, length, width)
	workspace.Terrain:FillBlock(CFrame.new(0, -2, 0), V(length, 4, width), material)
end

-- Cambia el material del terreno del suelo en una zona (caminos de barro, suelo bajo edificios...)
function Kit.terrainPatch(cf, size, material)
	workspace.Terrain:FillBlock(cf * CFrame.new(0, -2, 0), V(size.X, 4, size.Z), material)
end

-- Empieza un mapa nuevo: borra el anterior (y el agua/roca de Terrain). options.Realistic: este
-- mapa usa materiales y luz realistas aunque el juego esté en estilo Cartoon (mapas tipo CoD)
function Kit.Begin(name, options)
	Kit.Cartoon = not realMaterials() and not (options and options.Realistic)
	-- (mapa hecho ya realista: su luz y sus colores se respetan tal cual)
	Kit.Designed = options ~= nil and options.Realistic == true
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	workspace.Terrain:Clear()
	local folder = Instance.new("Folder")
	folder.Name = "Map"
	folder:SetAttribute("Generated", true)
	folder:SetAttribute("MapName", name)
	folder:SetAttribute("Realistic", Kit.Cartoon == false or nil)
	folder.Parent = workspace
	Kit.folder = folder
	return folder
end

return Kit
