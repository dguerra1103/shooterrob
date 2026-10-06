-- TacKit: kit modular de los mapas 5v5 (generación determinista por código, sin modelos de la
-- Toolbox). Junta la geometría (Geometry), los props (Props) y los materiales (Materials) y añade:
--   * Espejo exacto: TacKit.mirrored(fn) construye una mitad del mapa y la copia reflejada en
--     X = 0 (pieza a pieza: escaleras, huecos de puertas y carteles quedan bien). Así los dos equipos
--     tienen exactamente las mismas distancias a todo, y la mitad A y la B del mapa pueden ser
--     distintas (sitio A exterior y cálido, B interior y frío).
--   * Puntos de juego: zona de aparición integrada en el mapa (TacKit.spawnZone), sitios A y B que
--     sirven a los dos equipos (TacKit.site), puntos libres, puestos de bots, zonas y banderas.
-- Convención de los mapas nuevos: el equipo 1 (Rojo) sale en -X y el 2 (Azul) en +X; el sitio A
-- está en -Z y el B en +Z.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Kit = require(script.Parent.MapKit)
local Materials = require(script.Materials)
local Geometry = require(script.Geometry)
local Props = require(script.Props)
local Town = require(script.Town)
local Airport = require(script.Airport)
local Mall = require(script.Mall)
local Rail = require(script.Rail)
local Military = require(script.Military)
local Port = require(script.Port)

local T = {}
for k, v in Geometry do
	T[k] = v
end
for k, v in Props do
	T[k] = v
end
for k, v in Town do
	T[k] = v
end
for k, v in Airport do
	T[k] = v
end
for k, v in Mall do
	T[k] = v
end
for k, v in Rail do
	T[k] = v
end
for k, v in Military do
	T[k] = v
end
for k, v in Port do
	T[k] = v
end
T.Kit = Kit
T.Materials = Materials
T.G = Geometry
T.P = Props
T.Town = Town
T.Airport = Airport
T.Mall = Mall
T.Rail = Rail
T.Military = Military
T.Port = Port

local V = Vector3.new
local RGB = Color3.fromRGB

---------------------------------------------------------------------------
-- Empezar un mapa
---------------------------------------------------------------------------

-- Crea la carpeta del mapa, elige la luz (con sus variantes) y la paleta. def = la tabla del mapa
-- (Name, Lighting, LightingVariants, Palette, Ambience)
function T.begin(def)
	local folder = Kit.Begin(def.Name, { Realistic = true })
	Materials.use(def.Palette or def.Id)
	Kit.applyLighting(Kit.pickLighting(def))
	folder:SetAttribute("Variant", Kit.Variant)
	folder:SetAttribute("Weather", Kit.Weather)
	if def.Ambience then
		folder:SetAttribute("Ambience", def.Ambience) -- (sonido ambiente: ver Ambience en el cliente)
	end
	folder:SetAttribute("Kit", "TacKit")
	return folder
end

-- ¿Es de noche en esta partida? (ventanas encendidas, focos)
function T.isNight()
	return Kit.Variant == "Noche"
end

---------------------------------------------------------------------------
-- Espejo
---------------------------------------------------------------------------

-- Reflejo en el plano X = 0 de una posición y de un CFrame (la rotación R pasa a S·R·S, que para
-- una caja, un cilindro tumbado en X o una cuña es exactamente la pieza reflejada)
function T.mirrorPoint(p)
	return V(-p.X, p.Y, p.Z)
end

function T.mirrorCFrame(cf)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
end

local SWAP_FACE = {
	[Enum.NormalId.Left] = Enum.NormalId.Right,
	[Enum.NormalId.Right] = Enum.NormalId.Left,
}

local function mirrorInstance(inst)
	if inst:IsA("BasePart") then
		inst.CFrame = T.mirrorCFrame(inst.CFrame)
	elseif inst:IsA("SurfaceGui") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") or inst:IsA("Decal") or inst:IsA("Texture") then
		-- (las caras izquierda y derecha se cambian; el texto no sale al revés)
		local face = (inst :: any).Face
		if SWAP_FACE[face] then
			(inst :: any).Face = SWAP_FACE[face]
		end
	elseif inst:IsA("Attachment") then
		local p = inst.Position
		inst.Position = V(-p.X, p.Y, p.Z)
	end
	for _, name in { "Look", "OrbitCenter", "OrbitAxis", "OrbitAnchor" } do
		local value = inst:GetAttribute(name)
		if typeof(value) == "Vector3" then
			inst:SetAttribute(name, T.mirrorPoint(value))
		end
	end
	-- (los giros cambian de sentido en el reflejo)
	for _, name in { "Spin", "Orbit" } do
		local value = inst:GetAttribute(name)
		if type(value) == "number" then
			inst:SetAttribute(name, -value)
		end
	end
end

-- Mueve el contenido de las carpetas especiales (Callouts, Boundary) de una mitad a las del mapa
local SPECIAL = { Callouts = true, Boundary = true }
local function mergeSpecial(half, map)
	for _, child in half:GetChildren() do
		if child:IsA("Folder") and SPECIAL[child.Name] then
			local target = map:FindFirstChild(child.Name)
			if not target then
				target = Instance.new("Folder")
				target.Name = child.Name
				target.Parent = map
			end
			for _, item in child:GetChildren() do
				item.Parent = target
			end
			child:Destroy()
		end
	end
end

-- Construye con fn la mitad del equipo 1 (X < 0) y la copia reflejada para el equipo 2. fn no debe
-- tocar el terreno (eso no se copia): para eso, T.terrain fuera del espejo.
function T.mirrored(name, fn)
	local map = Kit.folder
	local half = Instance.new("Folder")
	half.Name = name .. "_Red"
	half.Parent = map
	Kit.folder = half
	local ok, err = pcall(fn)
	Kit.folder = map
	if not ok then
		error(err, 0)
	end
	local copy = half:Clone()
	copy.Name = name .. "_Blue"
	for _, inst in copy:GetDescendants() do
		mirrorInstance(inst)
	end
	copy.Parent = map
	mergeSpecial(half, map)
	mergeSpecial(copy, map)
	return half, copy
end

---------------------------------------------------------------------------
-- Puntos de juego
---------------------------------------------------------------------------

-- Zona de aparición del equipo (1 o 2) integrada en el mapa: suelo con el color del equipo, las
-- SpawnLocations y el nombre «BASE ROJA». cf = centro; -Z local mira hacia el mapa (los jugadores
-- aparecen mirando hacia ahí). opts: Size = Vector2 (X, Z), Points = { Vector3 locales }
function T.spawnZone(teamIndex, cf, opts)
	opts = opts or {}
	local team = GameConfig.Teams[teamIndex]
	local teamColor = team.Color.Color
	local size = opts.Size or Vector2.new(30, 22)
	local floor = Kit.block(team.Name .. "SpawnFloor", V(size.X, 0.3, size.Y), cf * CFrame.new(0, 0.15, 0), opts.Floor or RGB(150, 146, 140), Enum.Material.Concrete)
	floor.CastShadow = false
	-- Marco pintado del color del equipo
	for _, s in { -1, 1 } do
		Kit.deco("SpawnPaint", V(size.X, 0.05, 0.6), cf * CFrame.new(0, 0.32, s * (size.Y / 2 - 0.5)), teamColor, Enum.Material.SmoothPlastic).Color = teamColor
		Kit.deco("SpawnPaint", V(0.6, 0.05, size.Y), cf * CFrame.new(s * (size.X / 2 - 0.5), 0.32, 0), teamColor, Enum.Material.SmoothPlastic).Color = teamColor
	end
	Kit.callout("BASE " .. (string.gsub(string.upper(team.Name), "O$", "A")), cf * CFrame.new(0, 10, 0), V(size.X + 10, 26, size.Y + 10))
	local points = opts.Points or {
		V(-10, 0, 2), V(-5, 0, -3), V(0, 0, 2), V(5, 0, -3), V(10, 0, 2),
	}
	for i, p in points do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = team.Name .. "Spawn" .. i
		spawn.Anchored = true
		spawn.Size = V(5, 0.4, 5)
		spawn.CFrame = cf * CFrame.new(p + V(0, 0.35, 0))
		spawn.TeamColor = team.Color
		spawn.BrickColor = team.Color
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.Transparency = 0.35
		spawn.CastShadow = false
		spawn.Neutral = false
		spawn.AllowTeamChangeOnTouch = false
		spawn.Duration = GameConfig.SpawnProtection
		spawn.Parent = Kit.folder
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
	end
	return floor
end

-- Sitio de la bomba que sirve a los dos equipos (el que defienda en cada ronda): letra pintada en
-- el suelo, nombre de zona «SITIO A» y un BombSite por equipo en el mismo sitio.
-- position = centro a ras de suelo
function T.site(position, letter, opts)
	opts = opts or {}
	local radius = opts.Radius or 7
	-- (opts.Defender: el sitio es solo de ese equipo, en su mitad del mapa; si no, lo defiende el
	-- equipo que defienda en cada ronda y los atacantes esperan unos segundos: ver Round)
	if not opts.Defender then
		Kit.folder:SetAttribute("SharedSites", true)
	end
	for defender = 1, 2 do
		if opts.Defender and defender ~= opts.Defender then
			continue
		end
		local p = Kit.deco("BombSite", V(1, 1, 1), CFrame.new(position + V(0, 0.5, 0)), Kit.C.White, Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p:SetAttribute("Letter", letter)
		p:SetAttribute("Defender", defender)
		p:SetAttribute("Radius", radius)
	end
	local box = Kit.callout("SITIO " .. letter, CFrame.new(position + V(0, 6, 0)), opts.Callout or V(radius * 2 + 14, 18, radius * 2 + 14))
	box:SetAttribute("Site", true) -- (el cliente solo lo nombra en Buscar y destruir)
	-- Letra pintada en el suelo y círculo de la zona de plantado
	local paint = Kit.deco("SiteLetter", V(7, 0.05, 7), CFrame.new(position + V(0, 0.05, 0)) * (opts.Turn or CFrame.new()), Kit.C.White, Enum.Material.SmoothPlastic)
	paint.Transparency = 1
	paint.CastShadow = false
	local color = opts.Color or RGB(205, 58, 40)
	local gui = Kit.sign(paint, Enum.NormalId.Top, letter, color, color)
	gui.LightInfluence = 1
	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.TextTransparency = 0.1
		label.TextStrokeTransparency = 1
	end
	for i = 0, 11, 2 do
		local a = math.rad(i * 30)
		local mark = Kit.deco("SiteRing", V(0.6, 0.05, radius * 0.5), CFrame.new(position + V(math.cos(a) * radius, 0.04, math.sin(a) * radius)) * CFrame.Angles(0, -a, 0), color, Enum.Material.SmoothPlastic)
		mark.Color = color
		mark.CastShadow = false
	end
	return box
end

-- Caseta de base cerrada para el equipo 1 (en -X; la del 2 sale con T.mirrored): frente ciego hacia
-- el mapa en x = Front, fondo en x = Back, laterales en z = ±Half con una puerta junto al frente y
-- un muro interior (vestíbulo en L) detrás de cada puerta. Así no se ve la base desde fuera.
-- opts: Back, Front, Half, Height, Look, RoofLook, Stripe
function T.spawnHouse(opts)
	local G = Geometry
	local back, front = opts.Back or -150, opts.Front or -122.5
	local half, h = opts.Half or 24, opts.Height or 9
	local look = opts.Look or "Building"
	local length = front - back
	for _, z in { -half, half } do
		T.cap(G.wall(CFrame.new((back + front) / 2, 0, z), length, h, look, { G.door(length / 2 - 3, 5, 7.4) }))
		T.cap(G.wall(CFrame.new(front - 5.25, 0, z * (half - 4.56) / half), 10.5, h, look))
	end
	T.cap(G.wall(CFrame.new(front, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), half * 2 + 0.6, h, look))
	T.cap(G.wall(CFrame.new(back + 0.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), half * 2 + 0.6, h, look))
	T.cap(G.floor(CFrame.new((back + front) / 2, h + 0.6, 0), length + 0.5, half * 2 + 1, opts.RoofLook or "SteelDark", 0.6))
	if opts.Stripe then
		G.deco("BaseStripe", V(0.3, 1.2, half * 2 - 8), CFrame.new(front + 0.4, h - 2.5, 0), opts.Stripe)
	end
end

T.ffa = Kit.ffaSpawn
T.botSpot = Kit.botSpot
T.zone = Kit.zone
T.callout = Kit.callout
T.flagBase = function(teamIndex, cf)
	return Kit.flagBase(GameConfig.Teams[teamIndex], cf)
end

-- Muro invisible de borde entre dos puntos (dentro de Map.Boundary: no para balas ni la vista)
function T.boundaryWall(a, b, h)
	h = h or 60
	local folder = Kit.shootThroughFolder()
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local wall = Kit.block("Boundary", V(2, h, length), CFrame.lookAt(V(mid.X, h / 2, mid.Z), V(b.X, h / 2, b.Z)), Color3.new(1, 1, 1), nil, folder)
	wall.Transparency = 1
	wall.CastShadow = false
	return wall
end

-- Tejado o remate que no se debe pisar (el supersalto llega a ~17 studs): un volumen invisible
-- encima, del tamaño de la pieza y hasta el techo del mapa. Va en Map.Boundary (no para balas ni
-- la vista), así que solo lo nota quien intenta subirse. part = la pieza (o lista de piezas)
T.CEILING = 60
-- Pieza inclinada (barandilla de escalera o de rampa): el clip va en tramos verticales de 2 studs,
-- cada uno desde lo más alto de la pieza en ese tramo (un clip girado se tumbaría sobre la escalera)
local function capTilted(part, cf, size)
	local axes = { cf.RightVector * size.X, cf.UpVector * size.Y, cf.LookVector * size.Z }
	local long, best = 1, -1
	for i, a in axes do
		local hl = V(a.X, 0, a.Z).Magnitude
		if hl > best then
			long, best = i, hl
		end
	end
	local d = axes[long]
	local length = V(d.X, 0, d.Z).Magnitude
	if length < 0.5 then
		return nil
	end
	local dir = V(d.X, 0, d.Z) / length
	local perp = V(-dir.Z, 0, dir.X)
	local width, extra = 0, 0
	for i, a in axes do
		if i ~= long then
			width += math.abs(a:Dot(perp))
			extra += math.abs(a.Y) / 2
		end
	end
	local slope = d.Y / length
	local center = cf.Position
	local n = math.max(1, math.ceil(length / 2))
	local first
	for i = 0, n - 1 do
		local s0 = -length / 2 + length * i / n
		local s1 = -length / 2 + length * (i + 1) / n
		local top = center.Y + math.max(slope * s0, slope * s1) + extra
		if top < T.CEILING - 1 then
			local h = T.CEILING - top
			local mid = center + dir * ((s0 + s1) / 2)
			local flat = CFrame.lookAt(V(mid.X, top + h / 2, mid.Z), V(mid.X, top + h / 2, mid.Z) + dir)
			local clip = Kit.block("PlayerClip", V(width + 0.4, h, (s1 - s0) + 0.05), flat, Color3.new(1, 1, 1), nil, Kit.shootThroughFolder())
			clip.Transparency = 1
			clip.CastShadow = false
			first = first or clip
		end
	end
	return first
end

function T.cap(part)
	if typeof(part) == "table" then
		for _, p in part do
			T.cap(p)
		end
		return
	end
	if not part then
		return
	end
	if part:IsA("Model") then
		-- (contenedor: se tapa su cuerpo)
		return T.cap(part:FindFirstChild("Body"))
	end
	local cf, size = part.CFrame, part.Size
	if math.abs(cf.UpVector.Y) < 0.995 then
		return capTilted(part, cf, size)
	end
	-- Altura de la cara de arriba (piezas giradas solo en Y)
	local top = cf.Position.Y + math.abs(cf.UpVector.Y) * size.Y / 2
	if top >= T.CEILING - 1 then
		return
	end
	local h = T.CEILING - top
	local flat = CFrame.new(cf.Position.X, top + h / 2, cf.Position.Z) * (cf - cf.Position)
	local clip = Kit.block("PlayerClip", V(size.X + 0.4, h, size.Z + 0.4), flat, Color3.new(1, 1, 1), nil, Kit.shootThroughFolder())
	clip.Transparency = 1
	clip.CastShadow = false
	return clip
end

Mall.capHook = T.cap
Geometry.capHook = T.cap

-- Terreno: relleno bajo el mapa (para que nada flote) y colinas de fondo
function T.terrain(material, sx, sz, cf)
	workspace.Terrain:FillBlock((cf or CFrame.new()) * CFrame.new(0, -3, 0), V(sx, 6, sz), material)
end

return T
