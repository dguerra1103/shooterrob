-- Piezas de pueblo (Costa y mapas urbanos): tejado de teja a dos aguas, casa encalada con
-- contraventanas y macetas, arcos, puestos con toldo a rayas, faroles, bolardos, barcas, fuente
-- y sombrillas. Mismas convenciones que Props: cf = centro de la base, la "cara" mira a -Z.
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local Town = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local get = Materials.get
local M = Enum.Material

-- Cuña (WedgePart): la rampa baja hacia -Z y sube hacia +Z (alto en +Z), a lo ancho en X
local function wedge(name, size, cf, look, solid)
	look = get(look)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = look[1]
	w.Material = look[2]
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	if not solid then
		w.CanCollide = false
		w.CanQuery = false
		w.CanTouch = false
	end
	w.CastShadow = size.X * size.Y * size.Z >= 20
	w.Parent = Kit.folder
	return w
end
Town.wedge = wedge

-- Tejado de teja a dos aguas sobre una caja de w (X) x d (Z): cumbrera a lo largo de X. cf = centro
-- de la cara de arriba del muro. pitch = altura de la cumbrera. Aleros que vuelan 0,8.
function Town.gableRoof(cf, w, d, pitch, look)
	look = look or "RoofTile"
	pitch = pitch or d * 0.32
	local eave = 0.8
	local half = d / 2 + eave
	local slope = math.sqrt(half * half + pitch * pitch)
	local angle = math.atan2(pitch, half)
	for _, s in { -1, 1 } do
		local plane = G.deco("RoofTiles", V(w + 2 * eave, 0.5, slope), cf * CFrame.new(0, pitch / 2 - 0.1, s * half / 2) * CFrame.Angles(s * angle, 0, 0), look)
		plane.CastShadow = true
	end
	-- Frontones (triángulos de pared en los extremos), del color de la pared de debajo
	return angle
end

-- Frontón triangular (cierra el hueco bajo el tejado en un extremo): dos cuñas
function Town.gable(cf, d, pitch, look)
	for _, s in { -1, 1 } do
		wedge("Gable", V(0.6, pitch, d / 2), cf * CFrame.new(0, pitch / 2, s * d / 4) * CFrame.Angles(0, s > 0 and math.pi or 0, 0), look)
	end
end

-- Hueco en arco: dos cuñas en las esquinas de arriba de un hueco (decorado; el hueco real es
-- rectangular). cf = centro de la parte de arriba del hueco, en el plano del muro; w = ancho
function Town.archCorners(cf, w, r, look, depth)
	r = r or math.min(1.6, w * 0.3)
	depth = depth or 1.1
	for _, s in { -1, 1 } do
		-- (la cuña rellena la esquina: alta junto a la jamba, baja hacia el centro)
		wedge("ArchCorner", V(depth, r, r), cf * CFrame.new(s * (w / 2 - r / 2), -r / 2, 0) * CFrame.Angles(0, s > 0 and -math.pi / 2 or math.pi / 2, 0) * CFrame.Angles(math.pi, 0, 0), look)
	end
end

-- Casa encalada maciza (no se entra): cuerpo, zócalo, cornisa, ventanas con contraventanas y
-- macetas en la cara -Z (y +Z si opts.Back), tejado de teja o azotea con pretil. Devuelve el cuerpo.
-- opts: Roof = "Tile" | "Flat", Floors, Shutter (color), Door (bool), Back (bool), Balcony (bool)
function Town.house(cf, w, d, h, look, opts)
	opts = opts or {}
	look = get(look)
	local body = G.box("House", V(w, h, d), cf * CFrame.new(0, h / 2, 0), look)
	local trim = { look[1]:Lerp(Color3.new(0, 0, 0), 0.16), M.Limestone }
	G.deco("HouseBase", V(w + 0.3, 1.2, d + 0.3), cf * CFrame.new(0, 0.6, 0), trim).CastShadow = false
	local shutter = { opts.Shutter or RGB(70, 120, 92), M.WoodPlanks }
	local floors = opts.Floors or math.max(1, math.floor(h / 7))
	local faces = { -1 }
	if opts.Back then
		table.insert(faces, 1)
	end
	for _, side in faces do
		local zf = side * (d / 2 + 0.05)
		local turn = side > 0 and CFrame.Angles(0, math.pi, 0) or CFrame.new()
		local count = math.max(1, math.floor(w / 7))
		for f = 1, floors do
			local y = (f - 1) * (h / floors) + (h / floors) * 0.55
			for i = 1, count do
				local x = -w / 2 + (i - 0.5) * w / count
				local isDoor = f == 1 and opts.Door ~= false and i == math.ceil(count / 2)
				local at = cf * CFrame.new(x, isDoor and 3.5 or y, zf) * turn
				if isDoor then
					G.deco("Door", V(3, 6.4, 0.15), at * CFrame.new(0, -0.3, 0), { RGB(110, 70, 44), M.WoodPlanks })
					G.deco("DoorFrame", V(3.6, 0.5, 0.25), at * CFrame.new(0, 3.1, 0), trim)
				else
					G.deco("Window", V(1.8, 2.4, 0.12), at, { RGB(40, 44, 50), M.Glass })
					for _, s in { -1, 1 } do
						G.deco("Shutter", V(0.9, 2.5, 0.15), at * CFrame.new(s * 1.4, 0, -0.04), shutter)
					end
					if (i + f) % 2 == 0 then
						G.deco("FlowerBox", V(2.2, 0.5, 0.6), at * CFrame.new(0, -1.45, -0.25), { RGB(150, 84, 52), M.Plaster })
						Kit.ball("Geranium", 0.9, at * CFrame.new(-0.5, -1, -0.3), RGB(220, 50, 70), M.SmoothPlastic, true)
						Kit.ball("Geranium", 0.8, at * CFrame.new(0.5, -1, -0.3), RGB(80, 150, 70), M.Grass, true)
					end
				end
			end
		end
	end
	if opts.Roof == "Flat" then
		G.deco("Cornice", V(w + 0.6, 0.6, d + 0.6), cf * CFrame.new(0, h - 0.1, 0), trim).CastShadow = false
		G.deco("Parapet", V(w, 1.2, d), cf * CFrame.new(0, h + 0.6, 0), look).CastShadow = false
	else
		Town.gableRoof(cf * CFrame.new(0, h, 0), w, d, opts.Pitch or math.min(5, d * 0.3), opts.RoofLook)
		for _, s in { -1, 1 } do
			Town.gable(cf * CFrame.new(s * (w / 2 - 0.3), h, 0), d, opts.Pitch or math.min(5, d * 0.3), look)
		end
	end
	if opts.Balcony then
		local bal = cf * CFrame.new(0, h * 0.55 + 0.5, -d / 2 - 1.1)
		G.deco("Balcony", V(math.min(6, w * 0.5), 0.4, 2.2), bal, trim)
		G.deco("BalconyRail", V(math.min(6, w * 0.5), 0.15, 0.15), bal * CFrame.new(0, 2.2, -1), "Iron")
		for k = -2, 2 do
			G.deco("BalconyBar", V(0.12, 2.2, 0.12), bal * CFrame.new(k * math.min(6, w * 0.5) / 5, 1.1, -1), "Iron")
		end
	end
	return body
end

-- Puesto de mercado: mostrador (cobertura baja), postes y toldo a rayas
function Town.stall(cf, color, w)
	w = w or 6
	local counter = G.box("StallCounter", V(w, 3, 2.4), cf * CFrame.new(0, 1.5, 0), { RGB(150, 104, 62), M.WoodPlanks })
	G.deco("StallTop", V(w + 0.3, 0.3, 2.7), cf * CFrame.new(0, 3.1, 0), { RGB(120, 82, 50), M.Wood })
	for _, x in { -w / 2 + 0.2, w / 2 - 0.2 } do
		for _, z in { -1.1, 2.6 } do
			G.deco("StallPost", V(0.25, 6.6, 0.25), cf * CFrame.new(x, 3.3, z), { RGB(110, 76, 46), M.Wood })
		end
	end
	local stripes = math.floor(w / 1.2)
	for i = 0, stripes - 1 do
		G.deco("StallAwning", V(w / stripes, 0.2, 4.6), cf * CFrame.new(-w / 2 + (i + 0.5) * w / stripes, 6.5, 0.7) * CFrame.Angles(rad(-12), 0, 0), { i % 2 == 0 and color or RGB(245, 240, 230), M.Fabric })
	end
	-- Género sobre el mostrador
	for i = -1, 1 do
		Kit.ball("Fruit", 0.7, cf * CFrame.new(i * w * 0.25, 3.6, -0.3), i == 0 and RGB(240, 150, 40) or RGB(200, 50, 40), M.SmoothPlastic, true)
	end
	return counter
end

-- Farol de forja en la pared (cara -Z): luz cálida
function Town.lantern(cf)
	G.deco("LanternArm", V(0.2, 0.2, 1.2), cf * CFrame.new(0, 0.4, -0.6), "Iron")
	G.deco("LanternCage", V(0.9, 1.3, 0.9), cf * CFrame.new(0, -0.3, -1.2), "Iron")
	local glass = G.deco("LanternGlass", V(0.7, 1, 0.7), cf * CFrame.new(0, -0.3, -1.2), { RGB(255, 214, 140), M.Neon })
	Kit.light(glass, "PointLight", RGB(255, 200, 130), 14, 0.9)
end

-- Farola de pie (forja, dos brazos)
function Town.streetLight(cf)
	Kit.cylinder("LampPost", 10, 0.5, cf * CFrame.new(0, 5, 0), RGB(36, 36, 40), M.Metal)
	Kit.cylinder("LampFoot", 0.8, 1.2, cf * CFrame.new(0, 0.4, 0), RGB(36, 36, 40), M.Metal, nil, true)
	local top = cf * CFrame.new(0, 10, 0)
	G.deco("LampTop", V(1.2, 1.6, 1.2), top * CFrame.new(0, 0.4, 0), "Iron")
	local glass = G.deco("LampGlass", V(0.9, 1.2, 0.9), top * CFrame.new(0, 0.4, 0), { RGB(255, 214, 150), M.Neon })
	Kit.light(glass, "PointLight", RGB(255, 205, 140), 18, 1)
end

-- Bolardo de amarre con neumático colgado en el borde del muelle (decorado: la barandilla del
-- muelle ya impide caer)
function Town.bollard(cf)
	Kit.cylinder("Bollard", 1.4, 1.1, cf * CFrame.new(0, 0.7, 0), RGB(40, 42, 46), M.Metal)
	Kit.cylinder("BollardCap", 0.3, 1.5, cf * CFrame.new(0, 1.45, 0), RGB(40, 42, 46), M.Metal, nil, true)
end

function Town.tire(cf)
	local tire = Kit.pipe("Tire", 0.7, 2.6, cf * CFrame.Angles(0, rad(90), 0), RGB(28, 28, 30), M.Rubber, true)
	return tire
end

-- Barca de remos (decorado, flota en el agua)
function Town.rowboat(cf, color)
	color = color or RGB(236, 236, 230)
	G.deco("BoatHull", V(3.6, 1.6, 9), cf * CFrame.new(0, 0.3, 0), { color, M.WoodPlanks })
	G.deco("BoatGunwale", V(3.8, 0.3, 9.2), cf * CFrame.new(0, 1.1, 0), { RGB(160, 50, 40), M.Wood })
	wedge("BoatBow", V(3.6, 1.6, 2.4), cf * CFrame.new(0, 0.3, -5.7) * CFrame.Angles(0, math.pi, 0), { color, M.WoodPlanks })
	for _, z in { -1.6, 1.8 } do
		G.deco("BoatSeat", V(3.4, 0.25, 0.8), cf * CFrame.new(0, 0.8, z), { RGB(150, 110, 70), M.Wood })
	end
end

-- Fuente de plaza: pilón (cobertura baja), agua y columna con figura (cobertura alta en el centro)
function Town.fountain(cf, d)
	d = d or 12
	local basin = Kit.cylinder("FountainBasin", 2.4, d, cf * CFrame.new(0, 1.2, 0), RGB(206, 196, 178), M.Limestone)
	Kit.cylinder("FountainRim", 0.4, d + 0.6, cf * CFrame.new(0, 2.5, 0), RGB(226, 216, 198), M.Limestone, nil, true)
	local water = Kit.cylinder("FountainWater", 0.2, d - 1.2, cf * CFrame.new(0, 2.1, 0), RGB(70, 150, 190), M.Glass, nil, true)
	water.Transparency = 0.25
	Kit.cylinder("FountainPedestal", 5, 3, cf * CFrame.new(0, 4.5, 0), RGB(210, 200, 182), M.Limestone)
	Kit.cylinder("FountainBowl", 0.8, 5.4, cf * CFrame.new(0, 7.2, 0), RGB(214, 204, 186), M.Limestone, nil, true)
	G.deco("FountainFigure", V(1.4, 3.4, 1.2), cf * CFrame.new(0, 9.3, 0), { RGB(196, 188, 170), M.Marble })
	Kit.ball("FountainHead", 1.1, cf * CFrame.new(0, 11.4, 0), RGB(196, 188, 170), M.Marble, true)
	local drops = Instance.new("ParticleEmitter")
	drops.Name = "FountainSpray"
	drops.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	drops.Color = ColorSequence.new(RGB(220, 240, 255))
	drops.Size = NumberSequence.new(0.25, 0.1)
	drops.Transparency = NumberSequence.new(0.3, 1)
	drops.Lifetime = NumberRange.new(0.6, 0.9)
	drops.Rate = 30
	drops.Speed = NumberRange.new(5, 7)
	drops.SpreadAngle = Vector2.new(25, 25)
	drops.Acceleration = V(0, -30, 0)
	drops.Parent = water
	return basin
end

-- Mesa de terraza con sombrilla (cobertura muy baja)
function Town.cafeTable(cf, color)
	Kit.cylinder("CafeTable", 0.2, 2.4, cf * CFrame.new(0, 2.6, 0), RGB(236, 232, 224), M.Metal, nil, true)
	G.box("CafeLeg", V(0.4, 2.6, 0.4), cf * CFrame.new(0, 1.3, 0), "Iron")
	G.deco("Parasol", V(0.2, 5, 0.2), cf * CFrame.new(0, 5, 0), "Iron")
	Kit.cylinder("ParasolTop", 0.3, 6, cf * CFrame.new(0, 7.4, 0), color or RGB(200, 60, 50), M.Fabric, nil, true)
	for _, a in { 0, 120, 240 } do
		local seat = cf * CFrame.Angles(0, rad(a), 0) * CFrame.new(0, 0, -2.2)
		G.deco("CafeChair", V(1.2, 0.25, 1.2), seat * CFrame.new(0, 1.6, 0), "Iron")
		G.deco("CafeChairBack", V(1.2, 1.4, 0.15), seat * CFrame.new(0, 2.3, -0.55), "Iron")
	end
end

return Town
