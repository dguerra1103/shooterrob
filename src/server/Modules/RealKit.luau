-- Kit de construcción "realista" para los mapas tipo shooter militar (Encrucijada, Base Militar...):
-- edificios en los que se entra (con escalera, plantas y ventanas de verdad), bloques macizos de
-- fachada, sacos terreros, muros en ruinas, coches quemados, autobús, tanque y puestos de mercado.
local Kit = require(script.Parent.MapKit)

local RealKit = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

RealKit.FLOOR_H = 8 -- altura de cada planta
local FLOOR_H = RealKit.FLOOR_H
RealKit.WALL_T = 1.2 -- grosor de los muros
local WALL_T = RealKit.WALL_T

RealKit.PALETTE = {
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
function RealKit.wall(cf, length, height, color, material, openings)
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
			deco("Lintel", V(o.W + 0.8, 0.5, WALL_T + 0.3), cf * CFrame.new(o.X, o.Y1 + 0.25, 0), RealKit.PALETTE.Trim, M.Limestone)
			if o.Y0 > 0.5 then
				deco("Sill", V(o.W + 0.6, 0.35, WALL_T + 0.5), cf * CFrame.new(o.X, o.Y0 - 0.17, 0), RealKit.PALETTE.Trim, M.Limestone)
			end
		end
		solid(x0, x1, y, height)
		x = x1
	end
	solid(x, length / 2, 0, height)
end

-- Huecos de una fachada: puertas en la planta baja (doors = lista de X) y ventanas cada ~8 studs
-- en cada planta (sin pisar las puertas). windows = false para un muro ciego.
function RealKit.facadeOpenings(length, floors, doors, windows)
	local list = {}
	for _, x in doors or {} do
		table.insert(list, { X = x, W = 6, Y0 = 0, Y1 = 7.2 })
	end
	if windows ~= false then
		local count = math.max(1, math.floor(length / 8))
		for f = 0, floors - 1 do
			for i = 1, count do
				local x = -length / 2 + (i - 0.5) * length / count
				-- (ni al lado de una puerta ni encima: el muro de sobre la puerta taparía la ventana)
				local clash = false
				for _, d in doors or {} do
					if math.abs(d - x) < (f == 0 and 6 or 4.6) then
						clash = true
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

-- Número "al azar" pero fijo para cada sitio (el mapa sale igual siempre)
local function hash(cf, i)
	local p = cf.Position
	return (math.floor(math.abs(p.X * 7.13 + p.Z * 3.71 + i * 17.3)) % 97) / 97
end

-- Detalles de fachada que no chocan (sin tocar la jugabilidad): banda de piedra entre plantas,
-- bajante en una esquina, aparatos de aire bajo algunas ventanas de arriba y trastos en la azotea.
-- windowXs = posiciones X de las ventanas de la fachada delantera/trasera (de facadeOpenings)
local function facadeDetails(cf, sx, sz, height, floors, roofed, windowXs)
	local trim = RealKit.PALETTE.Trim
	for f = 1, floors - 1 do
		local y = f * FLOOR_H - 0.6
		for _, z in { -1, 1 } do
			deco("Band", V(sx + 0.5, 0.45, 0.5), cf * CFrame.new(0, y, z * (sz / 2 + 0.05)), trim, M.Limestone)
		end
		for _, x in { -1, 1 } do
			deco("Band", V(0.5, 0.45, sz + 0.5), cf * CFrame.new(x * (sx / 2 + 0.05), y, 0), trim, M.Limestone)
		end
	end
	-- Bajante de la azotea (esquina delantera derecha)
	Kit.cylinder("Downpipe", height, 0.45, cf * CFrame.new(sx / 2 - 0.7, height / 2, -sz / 2 - 0.35), RGB(88, 84, 78), M.Metal, nil, true)
	-- Aparatos de aire bajo algunas ventanas de la planta de arriba (delante y detrás)
	if floors >= 2 and windowXs then
		for i, x in windowXs do
			for side = -1, 1, 2 do
				if hash(cf, i * 3 + side) < 0.32 then
					local y = (floors - 1) * FLOOR_H + 1.6
					local unit = cf * CFrame.new(x, y, side * (sz / 2 + 0.75))
					deco("ACUnit", V(2.2, 1.5, 1.2), unit, RGB(196, 196, 190), M.Metal)
					deco("ACGrille", V(1.4, 1.1, 0.1), unit * CFrame.new(0, 0, side * 0.62), RGB(70, 72, 74), M.DiamondPlate)
				end
			end
		end
	end
	if roofed then
		-- Azotea: máquina del aire, chimenea de ventilación y antena
		deco("RoofAC", V(3.2, 1.8, 2.6), cf * CFrame.new(-sx / 4, height + 0.9, -sz / 5), RGB(170, 170, 166), M.Metal)
		Kit.cylinder("RoofVent", 2.4, 0.9, cf * CFrame.new(sx / 5, height + 1.2, -sz / 4), RGB(110, 108, 104), M.Metal, nil, true)
		if hash(cf, 7) < 0.6 then
			Kit.cylinder("Antenna", 7, 0.25, cf * CFrame.new(-sx / 2 + 1.5, height + 3.5, sz / 2 - 1.5), RGB(60, 60, 62), M.Metal, nil, true)
			deco("AntennaBar", V(3, 0.2, 0.2), cf * CFrame.new(-sx / 2 + 1.5, height + 5.8, sz / 2 - 1.5), RGB(60, 60, 62), M.Metal)
		end
	end
end

-- Edificio en el que se entra. cf = centro de la planta baja (suelo en y = 0); sx = ancho (X local),
-- sz = fondo (Z local, el frente mira a -Z). opts:
--   Floors (1 o 2), Color, Material, Doors = { Front = {x...}, Back = {...}, Left = {...}, Right = {...} },
--   Blind = { Left = true, ... } (muro sin ventanas), Ruined (sin tejado y con el muro roto arriba),
--   Sign = texto del rótulo de la fachada, Lamp (luz dentro)
function RealKit.building(cf, sx, sz, opts)
	opts = opts or {}
	local floors = opts.Floors or 2
	local height = floors * FLOOR_H + (opts.Ruined and 0 or 1)
	local color = opts.Color or RealKit.PALETTE.Plaster[1]
	local material = opts.Material or M.Plaster
	local doors = opts.Doors or {}
	local blind = opts.Blind or {}
	local function face(name, wallCf, length)
		RealKit.wall(wallCf, length, height, color, material, RealKit.facadeOpenings(length, floors, doors[name], not blind[name]))
	end
	-- Muros: frente (-Z), fondo (+Z), izquierda (-X) y derecha (+X)
	face("Front", cf * CFrame.new(0, 0, -sz / 2 + WALL_T / 2), sx)
	face("Back", cf * CFrame.new(0, 0, sz / 2 - WALL_T / 2) * CFrame.Angles(0, math.pi, 0), sx)
	face("Left", cf * CFrame.new(-sx / 2 + WALL_T / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), sz - 2 * WALL_T)
	face("Right", cf * CFrame.new(sx / 2 - WALL_T / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), sz - 2 * WALL_T)
	-- Zócalo y cornisa
	deco("Plinth", V(sx + 0.4, 1, sz + 0.4), cf * CFrame.new(0, 0.5, 0), RealKit.PALETTE.Trim, M.Limestone).CanCollide = false
	-- Suelo interior de baldosas
	deco("InteriorFloor", V(sx - 2 * WALL_T, 0.1, sz - 2 * WALL_T), cf * CFrame.new(0, 0.06, 0), RGB(150, 132, 112), M.CeramicTiles)
	-- (un edificio con cartel en el que se entra da nombre a su zona: «estoy en el HOTEL CENTRAL»)
	if type(opts.Sign) == "string" and opts.Sign ~= "" then
		Kit.callout(opts.Sign, cf * CFrame.new(0, height / 2, 0), V(sx, height + 2, sz))
	end
	local inner = sx - 2 * WALL_T
	local innerZ = sz - 2 * WALL_T
	if floors >= 2 then
		-- Escalera junto al muro izquierdo (franja de 7 studs) y forjado con el hueco de la escalera
		local stripX = -sx / 2 + WALL_T + 3.5
		local run = math.min(innerZ - 6, 16)
		local z0 = -sz / 2 + WALL_T + 1
		Kit.stairs(cf * V(stripX, 0, z0), cf * V(stripX, FLOOR_H, z0 + run), 6, RealKit.PALETTE.Concrete, M.Concrete)
		block("Slab", V(inner - 7, 1, innerZ), cf * CFrame.new(-sx / 2 + WALL_T + 7 + (inner - 7) / 2, FLOOR_H - 0.5, 0), RealKit.PALETTE.Concrete, M.Concrete)
		local landing = innerZ - (run + 1)
		if landing > 0.5 then
			block("Landing", V(7, 1, landing), cf * CFrame.new(stripX, FLOOR_H - 0.5, sz / 2 - WALL_T - landing / 2), RealKit.PALETTE.Concrete, M.Concrete)
		end
		-- Barandilla del hueco de la escalera
		Kit.railing(cf * V(stripX + 3.6, FLOOR_H, z0 + 0.5), cf * V(stripX + 3.6, FLOOR_H, z0 + run - 0.5), 3, RealKit.PALETTE.Dark)
	end
	if opts.Ruined then
		-- Muro roto: trozos sueltos por arriba y escombros en el suelo
		for i = 1, 6 do
			local px = ((i * 37) % 100) / 100 - 0.5
			deco("Rubble", V(2 + i % 3, 1 + i % 2, 2 + (i + 1) % 3), cf * CFrame.new(px * (sx - 6), 0.6, ((i * 53) % 100 / 100 - 0.5) * (sz - 6)) * CFrame.Angles(i, i * 2, 0), RealKit.PALETTE.Concrete, M.Concrete).CanCollide = true
		end
	else
		block("Roof", V(sx + 0.6, 1, sz + 0.6), cf * CFrame.new(0, height - 0.5, 0), RealKit.PALETTE.Concrete, M.Concrete)
		deco("Cornice", V(sx + 1.2, 0.8, sz + 1.2), cf * CFrame.new(0, height - 1.2, 0), RealKit.PALETTE.Trim, M.Limestone)
		for _, z in { -1, 1 } do
			deco("Parapet", V(sx + 0.6, 1.8, 0.6), cf * CFrame.new(0, height + 0.9, z * (sz / 2)), color, material)
		end
		for _, x in { -1, 1 } do
			deco("Parapet", V(0.6, 1.8, sz + 0.6), cf * CFrame.new(x * (sx / 2), height + 0.9, 0), color, material)
		end
		-- Depósito de agua y antena en la azotea (silueta de ciudad)
		Kit.cylinder("WaterTank", 3, 3, cf * CFrame.new(sx / 4, height + 1.5, sz / 4), RGB(70, 72, 76), M.Metal, nil, true)
	end
	-- Ventanas de la fachada (para colocar los aparatos de aire debajo)
	local windowXs = {}
	if not blind.Front then
		for _, o in RealKit.facadeOpenings(sx, floors, doors.Front, true) do
			if o.Y0 > (floors - 1) * FLOOR_H then
				table.insert(windowXs, o.X)
			end
		end
	end
	facadeDetails(cf, sx, sz, height, floors, not opts.Ruined, windowXs)
	if opts.Sign then
		local plate = deco("ShopSign", V(math.min(sx - 4, 14), 2.2, 0.3), cf * CFrame.new(0, 8.6, -sz / 2 - 0.3), RGB(40, 38, 36), M.Wood)
		Kit.sign(plate, Enum.NormalId.Front, opts.Sign, RGB(235, 225, 200), RGB(20, 20, 20))
		plate.CanCollide = false
	end
	-- Muebles (cobertura dentro): mesa al fondo y estantería delante, contra el muro derecho, y cajas
	-- arriba (en el lado derecho: la escalera va por el izquierdo y la puerta lateral está en el centro)
	if not opts.Empty then
		-- (nada delante de una puerta del muro derecho: su hueco va en z = -offset, 6 de ancho)
		local function clearOfDoors(z, halfDepth)
			for _, d in doors.Right or {} do
				if math.abs(-d - z) < 3 + halfDepth + 0.5 then
					return false
				end
			end
			return true
		end
		local tableZ = sz / 4 + 0.8
		if clearOfDoors(tableZ, 2.2) then
			local tableCf = cf * CFrame.new(sx / 2 - WALL_T - 2, 0, tableZ)
			block("Table", V(2.6, 0.3, 4.4), tableCf * CFrame.new(0, 3, 0), RGB(110, 80, 56), M.WoodPlanks)
			block("TableBase", V(2.2, 2.85, 0.4), tableCf * CFrame.new(0, 1.45, 0), RGB(90, 64, 44), M.Wood) -- (se esconde detrás)
			-- Sillas junto a la mesa (una volcada)
			for i, dz in { -1.2, 1.3 } do
				local chair = tableCf * CFrame.new(-2.2, 0, dz) * (i == 2 and CFrame.Angles(0, 0, rad(80)) * CFrame.new(0.9, -0.6, 0) or CFrame.new())
				deco("ChairSeat", V(1.4, 0.2, 1.4), chair * CFrame.new(0, 1.8, 0), RGB(96, 70, 48), M.Wood)
				deco("ChairBack", V(0.2, 1.8, 1.4), chair * CFrame.new(-0.6, 2.8, 0), RGB(96, 70, 48), M.Wood)
				for _, leg in { V(-0.55, 0, -0.55), V(0.55, 0, -0.55), V(-0.55, 0, 0.55), V(0.55, 0, 0.55) } do
					deco("ChairLeg", V(0.18, 1.7, 0.18), chair * CFrame.new(leg + V(0, 0.85, 0)), RGB(80, 58, 40), M.Wood)
				end
			end
		end
		-- Alfombra en el centro y papeles por el suelo
		deco("Rug", V(math.min(sx / 3, 8), 0.05, math.min(sz / 3, 6)), cf * CFrame.new(sx / 8, 0.14, 0), RGB(120, 52, 44), M.Fabric)
		for i = 1, 4 do
			deco("FloorPaper", V(0.9, 0.04, 0.7), cf * CFrame.new(sx / 8 + (i - 2.5) * 1.6, 0.18, (i % 2 - 0.5) * 3) * CFrame.Angles(0, i * 0.9, 0), RGB(225, 220, 205), M.SmoothPlastic)
		end
		if clearOfDoors(-sz / 4, 2) then
			block("Shelf", V(1.2, 5, 4), cf * CFrame.new(sx / 2 - WALL_T - 0.6, 2.5, -sz / 4), RGB(96, 90, 82), M.Metal)
		end
		if floors >= 2 then
			local crateCf = cf * CFrame.new(sx / 2 - WALL_T - 2, FLOOR_H, -sz / 4)
			Kit.crate(crateCf, 2.5)
			Kit.crate(crateCf * CFrame.new(0, 0, 2.8), 2.5)
			-- Cama arriba, en la esquina del fondo a la derecha (cobertura baja)
			local bedCf = cf * CFrame.new(sx / 2 - WALL_T - 1.8, FLOOR_H, sz / 2 - WALL_T - 3.4)
			block("BedFrame", V(3.2, 1, 6.2), bedCf * CFrame.new(0, 0.5, 0), RGB(70, 60, 52), M.Wood)
			deco("Mattress", V(3, 0.5, 5.8), bedCf * CFrame.new(0, 1.25, 0), RGB(170, 168, 150), M.Fabric)
			deco("Blanket", V(3.1, 0.12, 3.4), bedCf * CFrame.new(0, 1.55, -1.1) * CFrame.Angles(0, 0, rad(3)), RGB(70, 84, 64), M.Fabric)
			deco("Pillow", V(2, 0.4, 1), bedCf * CFrame.new(0, 1.7, 2.2), RGB(225, 222, 210), M.Fabric)
		end
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
function RealKit.solidBlock(cf, sx, sz, height, color, opts)
	opts = opts or {}
	block("Block", V(sx, height, sz), cf * CFrame.new(0, height / 2, 0), color, opts.Material or M.Plaster)
	deco("Plinth", V(sx + 0.4, 1.2, sz + 0.4), cf * CFrame.new(0, 0.6, 0), RealKit.PALETTE.Trim, M.Limestone)
	deco("Cornice", V(sx + 1, 0.8, sz + 1), cf * CFrame.new(0, height - 0.4, 0), RealKit.PALETTE.Trim, M.Limestone)
	if opts.Windows ~= false then
		local floors = math.max(1, math.floor(height / FLOOR_H))
		for f = 0, floors - 1 do
			for _, side in { -1, 1 } do
				local count = math.max(1, math.floor(sx / 8))
				for i = 1, count do
					local x = -sx / 2 + (i - 0.5) * sx / count
					local windowCf = cf * CFrame.new(x, f * FLOOR_H + 4.4, side * (sz / 2 + 0.1))
					deco("Window", V(3, 3.4, 0.2), windowCf, RGB(40, 44, 50), M.Glass)
					-- Algunas ventanas tapiadas con tablones (ciudad en guerra)
					if opts.Boarded ~= false and hash(windowCf, f * 7 + i) < 0.22 then
						for b, angle in { 0.35, -0.3 } do
							deco("Board", V(3.6, 0.5, 0.12), windowCf * CFrame.new(0, (b - 1.5) * 0.6, side * 0.12) * CFrame.Angles(0, 0, angle), RGB(120 - b * 12, 92 - b * 8, 62), M.WoodPlanks)
						end
					end
				end
			end
		end
	end
	local floorsHigh = math.max(1, math.floor(height / FLOOR_H))
	local windowXs = {}
	if opts.Windows ~= false then
		local count = math.max(1, math.floor(sx / 8))
		for i = 1, count do
			table.insert(windowXs, -sx / 2 + (i - 0.5) * sx / count)
		end
	end
	facadeDetails(cf, sx, sz, height, floorsHigh, true, windowXs)
	if opts.Sign then
		if opts.Awning ~= false then
			RealKit.awning(cf * CFrame.new(0, 6.6, -sz / 2), math.min(sx - 4, 14), opts.AwningColor)
		end
		local plate = deco("ShopSign", V(math.min(sx - 4, 14), 2.2, 0.3), cf * CFrame.new(0, 8.2, -sz / 2 - 0.3), RGB(40, 38, 36), M.Wood)
		Kit.sign(plate, Enum.NormalId.Front, opts.Sign, RGB(235, 225, 200), RGB(20, 20, 20))
	end
	Kit.contactShadow(cf, sx + 0.4, sz + 0.4)
end

---------------------------------------------------------------------------
-- Detalles de calle (no chocan: solo vista)
---------------------------------------------------------------------------

-- Postes de la luz en fila a lo largo del eje X local de cf (desde x0 hasta x1, cada `step`) con
-- dos cables entre poste y poste
function RealKit.utilityLine(cf, x0, x1, step)
	local wood, wire = RGB(92, 74, 56), RGB(30, 30, 32)
	local last
	for x = x0, x1, step do
		local base = cf * CFrame.new(x, 0, 0)
		Kit.cylinder("UtilityPole", 15, 0.7, base * CFrame.new(0, 7.5, 0), wood, M.Wood, nil, true)
		deco("Crossarm", V(0.4, 0.4, 4), base * CFrame.new(0, 13.8, 0), wood, M.Wood)
		deco("Transformer", V(1.2, 1.8, 1.2), base * CFrame.new(0.7, 11.8, 0), RGB(110, 112, 110), M.Metal)
		if last then
			for _, z in { -1.6, 1.6 } do
				deco("Wire", V(x - last, 0.1, 0.1), cf * CFrame.new((x + last) / 2, 13.2, z), wire, M.SmoothPlastic)
			end
		end
		last = x
	end
end

-- Parche de asfalto (más oscuro) con un bache y grietas
function RealKit.roadPatch(cf, sx, sz)
	deco("RoadPatch", V(sx, 0.06, sz), cf * CFrame.new(0, 0.42, 0), RGB(48, 48, 50), M.Asphalt)
	deco("Pothole", V(sx * 0.35, 0.07, sz * 0.4), cf * CFrame.new(sx * 0.15, 0.44, -sz * 0.1) * CFrame.Angles(0, 0.6, 0), RGB(36, 34, 33), M.Slate)
	for i = 1, 2 do
		deco("Crack", V(sx * 0.6, 0.07, 0.18), cf * CFrame.new(-sx * 0.1, 0.44, (i - 1.5) * sz * 0.4) * CFrame.Angles(0, (i - 1.5) * 0.7, 0), RGB(30, 30, 30), M.Asphalt)
	end
end

-- Basura junto a una pared: bolsas, cajas de cartón y papeles
function RealKit.trashPile(cf)
	for i, offset in { V(0, 0, 0), V(1.3, 0, 0.5), V(0.5, 0, -1.1) } do
		local size = 1.2 + (i % 2) * 0.3
		Kit.ball("TrashBag", size, cf * CFrame.new(offset + V(0, size / 2 - 0.1, 0)), i == 2 and RGB(40, 60, 40) or RGB(28, 28, 30), M.Plastic, true)
	end
	deco("Cardboard", V(1.6, 1.1, 1.3), cf * CFrame.new(-1.4, 0.55, 0.4) * CFrame.Angles(0, 0.4, 0), RGB(160, 124, 82), M.Cardboard)
	deco("Cardboard", V(1.2, 0.8, 1), cf * CFrame.new(-1.2, 1.5, 0.3) * CFrame.Angles(0, -0.3, 0.1), RGB(150, 116, 76), M.Cardboard)
	for i = 1, 3 do
		deco("Paper", V(0.8, 0.03, 0.6), cf * CFrame.new(-2 + i * 1.4, 0.45, 1.6 + (i % 2)) * CFrame.Angles(0, i, 0), RGB(220, 214, 200), M.SmoothPlastic)
	end
end

-- Semáforo (apagado por la guerra) en la esquina: poste, brazo y caja de luces
function RealKit.trafficLight(cf)
	local metal = RGB(56, 58, 60)
	Kit.cylinder("SignalPole", 11, 0.5, cf * CFrame.new(0, 5.5, 0), metal, M.Metal, nil, true)
	deco("SignalArm", V(0.35, 0.35, 6), cf * CFrame.new(0, 10.6, 3), metal, M.Metal)
	local box = deco("SignalBox", V(1.2, 3.2, 1.1), cf * CFrame.new(0, 9.4, 5.6), RGB(40, 42, 40), M.Metal)
	for i, color in { RGB(90, 30, 28), RGB(90, 80, 30), RGB(30, 80, 40) } do
		deco("SignalLamp", V(0.75, 0.75, 0.1), box.CFrame * CFrame.new(-0.62, 1.05 - (i - 1) * 1.05, 0) * CFrame.Angles(0, math.pi / 2, 0), color, M.Glass)
	end
end

-- Toldo de tienda a rayas sobre la fachada (cf = centro del borde de arriba, pegado al muro)
local AWNING_COLORS = { RGB(150, 46, 40), RGB(40, 90, 120), RGB(60, 110, 60), RGB(170, 120, 40) }
function RealKit.awning(cf, width, color)
	color = color or AWNING_COLORS[math.floor(hash(cf, 3) * #AWNING_COLORS) + 1]
	local depth = 3
	local stripes = math.max(3, math.floor(width / 1.6))
	for i = 1, stripes do
		local x = -width / 2 + (i - 0.5) * width / stripes
		deco("Awning", V(width / stripes, 0.12, depth), cf * CFrame.new(x, -0.6, -depth / 2) * CFrame.Angles(rad(-22), 0, 0), i % 2 == 0 and RGB(226, 218, 200) or color, M.Fabric)
	end
	deco("AwningValance", V(width, 0.5, 0.08), cf * CFrame.new(0, -1.5, -depth + 0.15), color, M.Fabric)
end

-- Cartel de papel pegado en una pared (cf = sobre la cara del muro, mirando hacia fuera por -Z)
local POSTER_COLORS = { RGB(200, 70, 50), RGB(220, 200, 150), RGB(60, 90, 140), RGB(230, 225, 210) }
function RealKit.poster(cf, i)
	local color = POSTER_COLORS[(i % #POSTER_COLORS) + 1]
	local paper = deco("Poster", V(1.7, 2.3, 0.04), cf * CFrame.Angles(0, 0, rad((i % 3 - 1) * 4)), color, M.SmoothPlastic)
	deco("PosterBand", V(1.5, 0.35, 0.05), paper.CFrame * CFrame.new(0, 0.6, 0), color:Lerp(RGB(20, 20, 20), 0.6), M.SmoothPlastic)
	deco("PosterBand", V(1.2, 0.18, 0.05), paper.CFrame * CFrame.new(0, -0.3, 0), color:Lerp(RGB(20, 20, 20), 0.45), M.SmoothPlastic)
end

-- Pintada en una pared (cf igual que poster): texto con aerosol
function RealKit.graffiti(cf, text, color, width)
	local plate = deco("Graffiti", V(width or 8, 2.6, 0.04), cf, RGB(255, 255, 255), M.SmoothPlastic)
	plate.Transparency = 1
	local gui = Kit.sign(plate, Enum.NormalId.Front, text, color, color)
	gui.LightInfluence = 1
	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Font = Enum.Font.PermanentMarker
		label.TextStrokeTransparency = 1
		label.TextTransparency = 0.12
	end
end

-- Muro de sacos terreros (cobertura baja, hasta el pecho)
function RealKit.sandbags(cf, length)
	block("Sandbags", V(length, 3.4, 2.4), cf * CFrame.new(0, 1.7, 0), RealKit.PALETTE.Sand, M.Fabric)
	local count = math.max(2, math.floor(length / 2.2))
	for i = 1, count do
		local x = -length / 2 + (i - 0.5) * length / count
		deco("Sandbag", V(length / count * 0.95, 0.8, 2.2), cf * CFrame.new(x, 3.6, (i % 2) * 0.2 - 0.1) * CFrame.Angles(0, (i % 3 - 1) * 0.08, 0), RealKit.PALETTE.Sand:Lerp(RGB(120, 100, 70), (i % 3) * 0.12), M.Fabric)
	end
	Kit.contactShadow(cf, length + 0.4, 2.8)
end

-- Muro en ruinas: tramo con el borde de arriba roto (cobertura alta con huecos para asomarse)
function RealKit.ruinWall(cf, length, height, color)
	local pieces = math.max(2, math.floor(length / 3))
	for i = 1, pieces do
		local h = height * (0.55 + ((i * 37) % 45) / 100)
		local x = -length / 2 + (i - 0.5) * length / pieces
		block("RuinWall", V(length / pieces + 0.05, h, 1.4), cf * CFrame.new(x, h / 2, 0), color or RealKit.PALETTE.Plaster[4], M.Plaster)
	end
	for i = 1, 3 do
		deco("Rubble", V(1.2 + i * 0.4, 0.8, 1 + i * 0.3), cf * CFrame.new((i - 2) * length / 3, 0.4, 1.4) * CFrame.Angles(i, i * 1.7, 0), RealKit.PALETTE.Concrete, M.Concrete)
	end
end

-- Coche quemado con humo
function RealKit.burntCar(cf, smoke)
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
function RealKit.bus(cf)
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
function RealKit.tankWreck(cf)
	block("TankHull", V(14, 3.6, 7.5), cf * CFrame.new(0, 2.6, 0), RGB(78, 82, 64), M.CorrodedMetal)
	for _, z in { -3.6, 3.6 } do
		block("TankTrack", V(15, 2.4, 1.6), cf * CFrame.new(0, 1.2, z), RGB(40, 40, 38), M.Metal)
	end
	block("TankTurret", V(6.5, 2.4, 5.5), cf * CFrame.new(1, 5.6, 0) * CFrame.Angles(0, rad(25), 0), RGB(72, 76, 60), M.CorrodedMetal)
	deco("TankGun", V(9, 0.7, 0.7), cf * CFrame.new(-4, 5.8, -2.2) * CFrame.Angles(0, rad(25), rad(-6)), RGB(60, 62, 52), M.Metal)
	Kit.contactShadow(cf, 15, 8)
end

-- Puesto de mercado con toldo (cobertura media)
function RealKit.stall(cf, color)
	block("StallCounter", V(6, 3.2, 2.5), cf * CFrame.new(0, 1.6, 0), RGB(130, 96, 62), M.WoodPlanks)
	for _, x in { -2.8, 2.8 } do
		deco("StallPole", V(0.3, 7, 0.3), cf * CFrame.new(x, 3.5, 1.2), RGB(90, 70, 50), M.Wood)
	end
	deco("StallAwning", V(7, 0.2, 4), cf * CFrame.new(0, 7, 0.4) * CFrame.Angles(rad(-10), 0, 0), color, M.Fabric)
	for i = 1, 3 do
		deco("Goods", V(1.4, 0.8, 1.2), cf * CFrame.new(-2.5 + i * 1.6, 3.6, -0.3), ({ RGB(200, 80, 50), RGB(220, 170, 60), RGB(90, 140, 60) })[i], M.Fabric)
	end
end

return RealKit
