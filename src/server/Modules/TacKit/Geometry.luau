-- Geometría modular de los mapas 5v5: suelos y forjados (con huecos de escalera), muros con huecos
-- de verdad (puertas y ventanas por las que se ve y se dispara), cascarones de edificio, pilares,
-- vigas, escaleras, barandillas, pasarelas, andamios, vallas de obra y marcas de suelo.
--
-- Convenciones (escala de personaje Roblox: 5 de alto, 2 de ancho):
--   * cf = centro de la BASE de la pieza (lo que apoya en el suelo), salvo que se diga otra cosa.
--   * Plantas cada G.LEVEL (10): planta baja en 0, primera en 10, segunda en 20.
--   * Puertas de 6 de ancho y 8 de alto; pasillos de 8 o más; cobertura baja 3, media 4,5, alta 7+.
--   * look = { color, material } o el nombre de uno de la paleta activa (ver Materials).
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)

local G = {}
G.capHook = function(_part) end -- (TacKit lo cambia por T.cap: tapar por arriba lo que no se pisa)

local V = Vector3.new
local get = Materials.get

G.LEVEL = 10 -- altura entre plantas (forjado de 1 incluido: quedan 9 libres)
G.WALL_T = 1 -- grosor de muro
G.DOOR_W, G.DOOR_H = 6, 8

-- Pieza que choca y para las balas
function G.box(name, size, cf, look)
	look = get(look)
	return Kit.block(name, size, cf, look[1], look[2])
end

-- Pieza decorativa: no choca ni para balas (detalle pequeño)
function G.deco(name, size, cf, look)
	look = get(look)
	return Kit.deco(name, size, cf, look[1], look[2])
end

-- Bloque macizo apoyado en el suelo (cf = centro de la base)
function G.solid(name, size, cf, look)
	return G.box(name, size, cf * CFrame.new(0, size.Y / 2, 0), look)
end

---------------------------------------------------------------------------
-- Suelos y forjados
---------------------------------------------------------------------------

-- Losa con la cara de arriba a la altura de cf (grosor t)
function G.floor(cf, sx, sz, look, t)
	t = t or 1
	return G.box("Floor", V(sx, t, sz), cf * CFrame.new(0, -t / 2, 0), look)
end

-- Forjado con huecos (escaleras, patios de luz): holes = { { X, Z, SX, SZ } } en coordenadas
-- locales. Se parte en rectángulos (rejilla por los bordes de los huecos, unidos por filas).
function G.slab(cf, sx, sz, look, holes, t)
	t = t or 1
	if not holes or #holes == 0 then
		return { G.floor(cf, sx, sz, look, t) }
	end
	local xs, zs = { -sx / 2, sx / 2 }, { -sz / 2, sz / 2 }
	for _, h in holes do
		table.insert(xs, math.clamp(h[1] - h[3] / 2, -sx / 2, sx / 2))
		table.insert(xs, math.clamp(h[1] + h[3] / 2, -sx / 2, sx / 2))
		table.insert(zs, math.clamp(h[2] - h[4] / 2, -sz / 2, sz / 2))
		table.insert(zs, math.clamp(h[2] + h[4] / 2, -sz / 2, sz / 2))
	end
	table.sort(xs)
	table.sort(zs)
	local function inHole(x, z)
		for _, h in holes do
			if math.abs(x - h[1]) < h[3] / 2 and math.abs(z - h[2]) < h[4] / 2 then
				return true
			end
		end
		return false
	end
	local parts = {}
	for j = 1, #zs - 1 do
		local z0, z1 = zs[j], zs[j + 1]
		if z1 - z0 > 0.05 then
			local runStart = nil
			for i = 1, #xs do
				local x0, x1 = xs[i], xs[i + 1]
				local filled = x1 ~= nil and x1 - x0 > 0.001 and not inHole((x0 + x1) / 2, (z0 + z1) / 2)
				local empty = x1 ~= nil and x1 - x0 <= 0.001
				if filled then
					runStart = runStart or x0
				elseif not empty then
					if runStart and x0 - runStart > 0.05 then
						table.insert(parts, G.box("Floor", V(x0 - runStart, t, z1 - z0), cf * CFrame.new((runStart + x0) / 2, -t / 2, (z0 + z1) / 2), look))
					end
					runStart = nil
				end
			end
		end
	end
	return parts
end

---------------------------------------------------------------------------
-- Muros
---------------------------------------------------------------------------

-- Huecos: puerta (x = centro) y ventana (y0 = alféizar)
function G.door(x, w, h, y0)
	return { X = x, W = w or G.DOOR_W, Y0 = y0 or 0, Y1 = (y0 or 0) + (h or G.DOOR_H) }
end

function G.window(x, y0, w, h)
	return { X = x, W = w or 4, Y0 = y0 or 3.5, Y1 = (y0 or 3.5) + (h or 3.5) }
end

-- Muro a lo largo de su X local con huecos de verdad. cf = centro de la base; openings = lista de
-- G.door / G.window (X local). opts: T (grosor), Frame (look del marco de los huecos)
function G.wall(cf, length, height, look, openings, opts)
	opts = opts or {}
	local t = opts.T or G.WALL_T
	openings = openings or {}
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
	local parts = {}
	local function piece(x0, x1, y0, y1)
		if x1 - x0 > 0.05 and y1 - y0 > 0.05 then
			table.insert(parts, G.box("Wall", V(x1 - x0, y1 - y0, t), cf * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0), look))
		end
	end
	local x = -length / 2
	for _, column in columns do
		local x0, x1 = column.X - column.W / 2, column.X + column.W / 2
		piece(x, x0, 0, height)
		table.sort(column.Holes, function(a, b)
			return a.Y0 < b.Y0
		end)
		local y = 0
		for _, o in column.Holes do
			piece(x0, x1, y, o.Y0)
			y = math.min(o.Y1, height)
			if opts.Frame then
				-- Marco: dintel y jambas finas (no chocan)
				G.deco("Frame", V(o.W + 0.6, 0.4, t + 0.2), cf * CFrame.new(o.X, math.min(o.Y1, height) - 0.2, 0), opts.Frame)
				for _, s in { -1, 1 } do
					G.deco("Frame", V(0.3, o.Y1 - o.Y0, t + 0.2), cf * CFrame.new(o.X + s * (o.W / 2 + 0.15), (o.Y0 + o.Y1) / 2, 0), opts.Frame)
				end
				if o.Y0 > 0.5 then
					G.deco("Sill", V(o.W + 0.6, 0.3, t + 0.4), cf * CFrame.new(o.X, o.Y0 - 0.15, 0), opts.Frame)
				end
			end
		end
		piece(x0, x1, y, height)
		x = x1
	end
	piece(x, length / 2, 0, height)
	return parts
end

-- Cascarón de edificio: cuatro muros de altura height con huecos por cara. sides = { Front, Back,
-- Left, Right } (listas de huecos; Front/Back con X del edificio, Left/Right con Z del edificio).
-- Front es la cara -Z local. Las medidas son exteriores. opts: T, Frame, Skip = { Left = true }
function G.shell(cf, sx, sz, height, look, sides, opts)
	opts = opts or {}
	sides = sides or {}
	local t = opts.T or G.WALL_T
	local skip = opts.Skip or {}
	if not skip.Front then
		G.wall(cf * CFrame.new(0, 0, -sz / 2 + t / 2), sx, height, look, sides.Front, opts)
	end
	if not skip.Back then
		G.wall(cf * CFrame.new(0, 0, sz / 2 - t / 2), sx, height, look, sides.Back, opts)
	end
	-- (los laterales van entre el frontal y el trasero; su X local = Z del edificio)
	local function side(list, x)
		local shifted = {}
		for _, o in list or {} do
			table.insert(shifted, { X = o.X, W = o.W, Y0 = o.Y0, Y1 = o.Y1 })
		end
		G.wall(cf * CFrame.new(x, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), sz - 2 * t, height, look, shifted, opts)
	end
	if not skip.Left then
		side(sides.Left, -sx / 2 + t / 2)
	end
	if not skip.Right then
		side(sides.Right, sx / 2 - t / 2)
	end
end

-- Pretil (muro bajo de azotea o de terraza) entre dos puntos de la base
function G.parapet(a, b, h, look, t)
	t = t or 0.8
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	return G.box("Parapet", V(t, h, length + t), CFrame.lookAt(mid, b) * CFrame.new(0, h / 2, 0), look)
end

---------------------------------------------------------------------------
-- Estructura
---------------------------------------------------------------------------

-- Pilar (cf = centro de la base)
function G.column(cf, h, w, look, name)
	w = w or 1.6
	return G.box(name or "Column", V(w, h, w), cf * CFrame.new(0, h / 2, 0), look)
end

-- Viga entre dos puntos (centros de los extremos). deco = sin colisión
function G.beam(a, b, w, h, look, deco)
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	if math.abs((b - a).Unit.Y) > 0.99 then
		cf = CFrame.new(mid) * CFrame.Angles(math.pi / 2, 0, 0)
	end
	local fn = deco and G.deco or G.box
	return fn("Beam", V(w, h, length), cf, look)
end

-- Perfil de acero en I (ala arriba y abajo y alma): para estructuras metálicas vistas
function G.ibeam(a, b, depth, look, deco)
	depth = depth or 1.2
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local dir = (b - a).Unit
	local cf
	if math.abs(dir.Y) > 0.99 then
		cf = CFrame.new(mid) * CFrame.Angles(math.pi / 2, 0, 0)
	else
		cf = CFrame.lookAt(mid, b)
	end
	local fn = deco and G.deco or G.box
	local web = fn("SteelWeb", V(0.25, depth, length), cf, look)
	G.deco("SteelFlange", V(depth * 0.8, 0.22, length), cf * CFrame.new(0, depth / 2 - 0.11, 0), look)
	G.deco("SteelFlange", V(depth * 0.8, 0.22, length), cf * CFrame.new(0, -depth / 2 + 0.11, 0), look)
	return web
end

-- Pórtico de acero: pilares en I en las esquinas de una rejilla y vigas por arriba en cada nivel
-- (estructura sin terminar). cf = centro de la base; nx, nz = vanos; bay = luz de cada vano
function G.steelFrame(cf, nx, nz, bay, levels, levelH, look, opts)
	opts = opts or {}
	local sx, sz = nx * bay, nz * bay
	for i = 0, nx do
		for j = 0, nz do
			local p = cf * V(-sx / 2 + i * bay, 0, -sz / 2 + j * bay)
			G.ibeam(p, p + V(0, levels * levelH, 0), 1.2, look, opts.Deco)
		end
	end
	for l = 1, levels do
		local y = l * levelH - 0.6
		for j = 0, nz do
			G.ibeam(cf * V(-sx / 2, y, -sz / 2 + j * bay), cf * V(sx / 2, y, -sz / 2 + j * bay), 1.2, look, true)
		end
		for i = 0, nx do
			G.ibeam(cf * V(-sx / 2 + i * bay, y, -sz / 2), cf * V(-sx / 2 + i * bay, y, sz / 2), 1.2, look, true)
		end
	end
end

---------------------------------------------------------------------------
-- Escaleras, barandillas y pasarelas
---------------------------------------------------------------------------

-- Barandilla entre dos puntos del suelo (altura h): postes, pasamanos, barra media y rodapié. Choca
-- pero no para las balas ni la vista (va en Map.Boundary, como las de Kit.railing)
function G.railing(a, b, look, h, opts)
	opts = opts or {}
	h = h or 3.2
	look = get(look or "Yellow")
	local length = (b - a).Magnitude
	if length < 0.5 then
		return
	end
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b)
	G.deco("Handrail", V(0.3, 0.3, length), cf * CFrame.new(0, h, 0), look)
	G.deco("MidRail", V(0.2, 0.2, length), cf * CFrame.new(0, h * 0.5, 0), look)
	if not opts.NoToe then
		G.deco("ToeBoard", V(0.12, 0.45, length), cf * CFrame.new(0, 0.25, 0), look)
	end
	local posts = math.max(1, math.floor(length / 3.5 + 0.5))
	for i = 0, posts do
		local p = a:Lerp(b, i / posts)
		G.deco("RailPost", V(0.3, h, 0.3), CFrame.new(p + V(0, h / 2, 0)), look)
	end
	local collider = Kit.block("RailCollider", V(0.5, h + 0.6, length), cf * CFrame.new(0, (h + 0.6) / 2, 0), look[1], nil, Kit.shootThroughFolder())
	collider.Transparency = 1
	collider.CastShadow = false
	if opts.Cap then
		-- (borde de un vacío: nadie salta por encima, ni con el supersalto)
		G.capHook(collider)
	end
	return collider
end

-- Escalera recta: bottom y top son puntos de la superficie (centro de la escalera). Cuerpo de
-- hormigón (la rampa sobre la que se camina, también para los bots) y peldaños vistos encima.
-- opts: Rails = "Both" | "Left" | "Right", RailLook, StepLook, Closed (rellena por debajo)
function G.stairs(bottom, top, width, look, opts)
	opts = opts or {}
	look = get(look)
	local flatDir = V(top.X - bottom.X, 0, top.Z - bottom.Z)
	local run = flatDir.Magnitude
	local rise = top.Y - bottom.Y
	local mid = (bottom + top) / 2
	local slopeLength = (top - bottom).Magnitude
	local cf = CFrame.lookAt(mid, top)
	-- Rampa (se camina por su cara de arriba, a ras de la línea bottom-top)
	local body = G.box("StairBody", V(width, 1, slopeLength + 0.6), cf * CFrame.new(0, -0.5, 0), look)
	local steps = math.max(3, math.floor(rise / 0.75 + 0.5))
	local stepRun, stepRise = run / steps, rise / steps
	local face = CFrame.lookAt(bottom, bottom + flatDir)
	local stepLook = opts.StepLook and get(opts.StepLook) or { look[1]:Lerp(Color3.new(1, 1, 1), 0.08), look[2] }
	for i = 0, steps - 1 do
		-- (cada peldaño asoma por encima de la rampa: su arista delantera toca la línea)
		local y = (i + 1) * stepRise
		local z = (i + 0.5) * stepRun
		local p = face * CFrame.new(0, y - stepRise / 2 - 0.05, -z)
		G.deco("Step", V(width, stepRise + 0.1, stepRun + 0.02), p, stepLook)
		if i % 2 == 0 then
			G.deco("StepNosing", V(width, 0.08, 0.25), face * CFrame.new(0, y + 0.01, -(i * stepRun) - 0.12), opts.NosingLook or "YellowPaint")
		end
	end
	if opts.Closed then
		-- Relleno de debajo (escalera maciza contra un muro): bloque en cuña con piezas escalonadas
		local slices = 4
		for i = 1, slices do
			local h = rise * (i - 0.5) / slices
			local z0 = run * (i - 1) / slices
			G.box("StairFill", V(width, h, run / slices), face * CFrame.new(0, h / 2 - 0.02, -(z0 + run / slices / 2)), look)
		end
	end
	local rails = opts.Rails
	if rails then
		local right = face.RightVector * (width / 2 - 0.2)
		local ext = flatDir.Unit * 0.4
		if rails == "Both" or rails == "Left" then
			G.railing(bottom - right - ext, top - right + ext, opts.RailLook, 3.2, { NoToe = true, Cap = opts.Cap })
		end
		if rails == "Both" or rails == "Right" then
			G.railing(bottom + right - ext, top + right + ext, opts.RailLook, 3.2, { NoToe = true, Cap = opts.Cap })
		end
	end
	return body
end

-- Pasarela recta entre a y b (puntos de la superficie, a la misma altura): tablero, perfiles a los
-- lados y barandillas. opts: Rails = { Left = bool, Right = bool } (por defecto las dos), Look,
-- Supports = separación de los pilares hasta el suelo (y = 0), Roof = look de la cubierta
function G.walkway(a, b, width, opts)
	opts = opts or {}
	local look = opts.Look or "Plywood"
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local deck = G.box("Walkway", V(width, 0.8, length), cf * CFrame.new(0, -0.4, 0), look)
	local edge = opts.EdgeLook or "Steel"
	for _, s in { -1, 1 } do
		G.deco("WalkwayEdge", V(0.4, 1, length), cf * CFrame.new(s * (width / 2 - 0.1), -0.6, 0), edge)
	end
	local rails = opts.Rails or { Left = true, Right = true }
	for side, s in { Left = -1, Right = 1 } do
		if rails[side] then
			local offset = cf.RightVector * s * (width / 2 - 0.25)
			G.railing(a + offset, b + offset, opts.RailLook, 3.2, { Cap = opts.Cap })
		end
	end
	if opts.Supports and a.Y > 2 then
		local count = math.max(1, math.floor(length / opts.Supports))
		for i = 0, count do
			local p = a:Lerp(b, i / count)
			for _, s in { -1, 1 } do
				local foot = p + cf.RightVector * s * (width / 2 - 0.4)
				G.beam(V(foot.X, 0, foot.Z), V(foot.X, p.Y - 0.8, foot.Z), 0.7, 0.7, edge)
			end
		end
	end
	return deck
end

---------------------------------------------------------------------------
-- Obra: andamios y vallas
---------------------------------------------------------------------------

-- Andamio de tubos: cf = centro de la base, sx de largo (X), sz de fondo, levels plantas de levelH.
-- opts.Walkable: las plataformas chocan (si no, es decorado). opts.Look: color de los tubos
function G.scaffold(cf, sx, sz, levels, levelH, opts)
	opts = opts or {}
	local tube = opts.Look or "Yellow"
	local bays = math.max(1, math.floor(sx / 6 + 0.5))
	local bay = sx / bays
	local h = levels * levelH
	for i = 0, bays do
		for _, z in { -sz / 2, sz / 2 } do
			G.deco("ScaffoldPole", V(0.35, h + 1.2, 0.35), cf * CFrame.new(-sx / 2 + i * bay, (h + 1.2) / 2, z), tube)
		end
	end
	for l = 1, levels do
		local y = l * levelH
		for _, z in { -sz / 2, sz / 2 } do
			G.deco("ScaffoldLedger", V(sx, 0.25, 0.25), cf * CFrame.new(0, y - 0.1, z), tube)
			G.deco("ScaffoldGuard", V(sx, 0.2, 0.2), cf * CFrame.new(0, y + 1.6, z), tube)
		end
		local plank = opts.Walkable and G.box or G.deco
		plank("ScaffoldDeck", V(sx, 0.3, sz), cf * CFrame.new(0, y - 0.35, 0), opts.DeckLook or "Plywood")
		-- Diagonales en la cara delantera (una por vano y planta, alternando)
		for i = 0, bays - 1 do
			local x0 = -sx / 2 + i * bay
			local up = (i + l) % 2 == 0
			local p0 = cf * V(x0, y - levelH, -sz / 2)
			local p1 = cf * V(x0 + bay, y, -sz / 2)
			if not up then
				p0, p1 = cf * V(x0, y, -sz / 2), cf * V(x0 + bay, y - levelH, -sz / 2)
			end
			G.beam(p0, p1, 0.2, 0.2, tube, true)
		end
	end
end

-- Valla de obra (paneles de madera pintados con postes): muro opaco de altura h
function G.hoarding(a, b, h, look, opts)
	opts = opts or {}
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local panel = G.box("Hoarding", V(0.5, h, length), cf * CFrame.new(0, h / 2, 0), look or "Hoarding")
	local posts = math.max(1, math.floor(length / 8 + 0.5))
	for i = 0, posts do
		local p = a:Lerp(b, i / posts)
		G.deco("HoardingPost", V(0.6, h + 0.4, 0.6), CFrame.lookAt(p, p + (b - a)) * CFrame.new(0, (h + 0.4) / 2, 0), opts.PostLook or "SteelDark")
	end
	-- Franja de color arriba (identidad de la obra)
	G.deco("HoardingStripe", V(0.56, 0.8, length), cf * CFrame.new(0, h - 0.6, 0), opts.Stripe or "YellowPaint")
	return panel
end

-- Valla de malla: se ve y se dispara a través, pero no se pasa
function G.meshFence(a, b, h, look)
	look = get(look or "Steel")
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local mesh = G.deco("FenceMesh", V(0.1, h - 0.4, length), cf * CFrame.new(0, h / 2 + 0.2, 0), { look[1], Enum.Material.DiamondPlate })
	mesh.Transparency = 0.55
	G.deco("FenceTop", V(0.2, 0.2, length), cf * CFrame.new(0, h, 0), look)
	local posts = math.max(1, math.floor(length / 6 + 0.5))
	for i = 0, posts do
		local p = a:Lerp(b, i / posts)
		G.deco("FencePost", V(0.3, h, 0.3), CFrame.new(p + V(0, h / 2, 0)), look)
	end
	local collider = Kit.block("FenceCollider", V(0.5, h, length), cf * CFrame.new(0, h / 2, 0), look[1], nil, Kit.shootThroughFolder())
	collider.Transparency = 1
	collider.CastShadow = false
end

---------------------------------------------------------------------------
-- Suelo: pintura, bordillos y juntas
---------------------------------------------------------------------------

-- Línea pintada en el suelo entre dos puntos (y = superficie)
function G.paintLine(a, b, width, look)
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local line = G.deco("PaintLine", V(width or 0.5, 0.04, length), CFrame.lookAt(mid, b) * CFrame.new(0, 0.02, 0), look or "YellowPaint")
	line.CastShadow = false
	return line
end

-- Franjas de peligro (amarillo/negro) en un rectángulo del suelo (cf = centro, a ras de suelo)
function G.hazardStripes(cf, sx, sz)
	local count = math.max(2, math.floor(sx / 1.2))
	G.deco("HazardBase", V(sx, 0.04, sz), cf * CFrame.new(0, 0.02, 0), "Black").CastShadow = false
	for i = 0, count - 1, 2 do
		local x = -sx / 2 + (i + 0.5) * sx / count
		G.deco("HazardStripe", V(sx / count, 0.05, sz), cf * CFrame.new(x, 0.03, 0), "YellowPaint").CastShadow = false
	end
end

-- Bordillo (choca: se pasa por encima andando)
function G.curb(a, b, look)
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	return G.box("Curb", V(0.8, 0.6, length), CFrame.lookAt(mid, b) * CFrame.new(0, 0.3, 0), look or "ConcreteDark")
end

return G
