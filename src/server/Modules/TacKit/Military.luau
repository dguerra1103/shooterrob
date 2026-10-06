-- Piezas militares (Desert Base): barreras HESCO, muros de sacos terreros y de hormigón (T-wall),
-- camión de carga con lona, todoterreno, torre de vigilancia, torre de agua, depósito de
-- combustible, mástil de radio, red de camuflaje, barrera de control y barracón prefabricado.
-- cf = centro de la base; la "cara" mira a -Z.
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local Military = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local get = Materials.get
local M = Enum.Material

local TIRE = { RGB(32, 32, 34), M.SmoothPlastic }
local DARK_GLASS = { RGB(40, 46, 52), M.Glass }

local function wheel(cf, d, w)
	return Kit.cylinder("Wheel", w or 1, d or 2.6, cf * CFrame.Angles(0, 0, rad(90)), TIRE[1], TIRE[2], nil, true)
end

-- Fila de bastiones HESCO a lo largo de X local (count módulos de 3,6; altura h): un bloque que
-- choca y las costuras de malla por encima (cobertura alta o media según h)
function Military.hesco(cf, count, h)
	h = h or 4
	local w = 3.6
	local length = w * count
	local body = G.box("Hesco", V(length, h, w), cf * CFrame.new(0, h / 2, 0), "Hesco")
	for i = 0, count do
		local x = -length / 2 + i * w
		for _, s in { -1, 1 } do
			G.deco("HescoMesh", V(0.15, h + 0.05, 0.15), cf * CFrame.new(x, h / 2, s * (w / 2 + 0.03)), "SteelDark").CastShadow = false
		end
	end
	for _, s in { -1, 1 } do
		G.deco("HescoWire", V(length, 0.12, 0.12), cf * CFrame.new(0, h - 0.4, s * (w / 2 + 0.03)), "SteelDark").CastShadow = false
	end
	G.deco("HescoSand", V(length - 0.3, 0.2, w - 0.3), cf * CFrame.new(0, h + 0.05, 0), "SandDark").CastShadow = false
	return body
end

-- Muro de sacos terreros de a a b (h de alto; cobertura baja a 2,6, media a 4)
function Military.sandbags(a, b, h)
	h = h or 2.6
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local body = G.box("Sandbags", V(2.2, h, length), cf * CFrame.new(0, h / 2, 0), "Sandbag")
	local rows = math.floor(h / 0.65)
	for i = 1, rows - 1 do
		G.deco("SandbagRow", V(2.3, 0.1, length + 0.05), cf * CFrame.new(0, i * h / rows, 0), "SandDark").CastShadow = false
	end
	return body
end

-- Muro de hormigón en T (paneles de 4 studs) de a a b
function Military.tWall(a, b, h)
	h = h or 9
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local body = G.box("TWall", V(1.2, h, length), cf * CFrame.new(0, h / 2, 0), "Concrete")
	G.deco("TWallFoot", V(3.6, 1.2, length), cf * CFrame.new(0, 0.6, 0), "Concrete")
	local n = math.floor(length / 4)
	for i = 1, n - 1 do
		G.deco("TWallJoint", V(1.3, h - 0.2, 0.12), cf * CFrame.new(0, h / 2, -length / 2 + i * length / n), "ConcreteDark").CastShadow = false
	end
	G.deco("TWallStripe", V(1.3, 0.8, length), cf * CFrame.new(0, h - 1.4, 0), "SandDark").CastShadow = false
	return body
end

-- Camión de carga militar (cabina y caja con lona): cobertura alta. Devuelve las piezas que chocan
function Military.truck(cf, look)
	look = look or "MilGreen"
	local solids = {}
	table.insert(solids, G.box("TruckCab", V(7, 6.4, 6), cf * CFrame.new(0, 4.2, -7.5), look))
	G.deco("TruckWindscreen", V(6, 2, 0.15), cf * CFrame.new(0, 5.8, -10.55), DARK_GLASS).CastShadow = false
	G.deco("TruckBumper", V(7.4, 1, 0.6), cf * CFrame.new(0, 1.8, -10.6), "SteelDark")
	table.insert(solids, G.box("TruckBed", V(7.2, 2, 14), cf * CFrame.new(0, 2.6, 3), "SteelDark"))
	table.insert(solids, G.box("TruckCanvas", V(7, 5.4, 13.4), cf * CFrame.new(0, 6.3, 3), "Canvas"))
	for _, z in { -1.5, 3, 7.5 } do
		G.deco("CanvasRib", V(7.15, 0.3, 0.3), cf * CFrame.new(0, 9.05, z), "MilGreenDark")
	end
	for _, s in { -1, 1 } do
		for _, z in { -7.5, 2, 6.5 } do
			wheel(cf * CFrame.new(s * 3.2, 1.4, z), 2.8, 1.1)
		end
	end
	return solids
end

-- Todoterreno militar (cobertura baja-media)
function Military.jeep(cf, look)
	look = look or "MilGreen"
	local body = G.box("Jeep", V(6, 3, 11), cf * CFrame.new(0, 2.3, 0), look)
	G.deco("JeepCabin", V(5.6, 2, 4.6), cf * CFrame.new(0, 4.8, 0.8), "Canvas")
	G.deco("JeepWindscreen", V(5.4, 1.6, 0.15), cf * CFrame.new(0, 4.6, -1.6), DARK_GLASS).CastShadow = false
	G.deco("JeepSpare", V(0.8, 2.4, 2.4), cf * CFrame.new(0, 2.6, 5.7), TIRE)
	for _, s in { -1, 1 } do
		for _, z in { -3.6, 3.6 } do
			wheel(cf * CFrame.new(s * 3, 1.3, z), 2.6, 1.1)
		end
	end
	return body
end

-- Torre de vigilancia: patas, plataforma a h con sacos terreros (hueco en open = "Front" | "Back"
-- | "Left" | "Right", donde llega la escalera) y tejado sobre postes. Devuelve la plataforma
function Military.watchtower(cf, h, open)
	h = h or 12
	local size = 7
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			G.box("TowerLeg", V(0.8, h, 0.8), cf * CFrame.new(x * (size / 2 - 0.4), h / 2, z * (size / 2 - 0.4)), "WoodDark")
			G.deco("TowerPost", V(0.4, 6.4, 0.4), cf * CFrame.new(x * (size / 2 - 0.2), h + 3.2, z * (size / 2 - 0.2)), "WoodDark")
		end
	end
	for _, s in { -1, 1 } do
		G.deco("TowerBrace", V(0.3, h * 1.1, 0.3), cf * CFrame.new(s * (size / 2 - 0.4), h / 2, 0) * CFrame.Angles(rad(38), 0, 0), "WoodDark")
	end
	local deck = G.box("TowerDeck", V(size, 1.4, size), cf * CFrame.new(0, h - 0.7, 0), "Wood")
	local half = size / 2 - 0.4
	local sides = {
		Front = { V(-half, h, -half), V(half, h, -half) },
		Back = { V(-half, h, half), V(half, h, half) },
		Left = { V(-half, h, -half), V(-half, h, half) },
		Right = { V(half, h, -half), V(half, h, half) },
	}
	local walls = {}
	for name, seg in sides do
		if name ~= open then
			local a, b = cf * seg[1], cf * seg[2]
			table.insert(walls, Military.sandbags(a, b, 1.8))
		end
	end
	local roof = G.box("TowerRoof", V(size + 1.4, 0.5, size + 1.4), cf * CFrame.new(0, h + 6.6, 0), "Canvas")
	G.deco("TowerLamp", V(1, 0.8, 1.4), cf * CFrame.new(0, h + 6, -half), "SteelDark")
	return deck, roof, walls
end

-- Torre de agua: cuatro patas (chocan) y depósito arriba (h = altura de la base del depósito)
function Military.waterTower(cf, h, d)
	h = h or 12
	d = d or 9
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			G.box("WaterTowerLeg", V(1, h, 1), cf * CFrame.new(x * d * 0.32, h / 2, z * d * 0.32), "SteelDark")
		end
	end
	for _, y in { h * 0.35, h * 0.7 } do
		G.deco("WaterTowerRing", V(d * 0.66, 0.3, 0.3), cf * CFrame.new(0, y, d * 0.32), "SteelDark")
		G.deco("WaterTowerRing", V(d * 0.66, 0.3, 0.3), cf * CFrame.new(0, y, -d * 0.32), "SteelDark")
	end
	local tank = Kit.cylinder("WaterTank", 8, d, cf * CFrame.new(0, h + 4, 0), get("Tank")[1], get("Tank")[2])
	Kit.cylinder("WaterTankRoof", 1.2, d * 0.8, cf * CFrame.new(0, h + 8.6, 0), get("SteelDark")[1], get("SteelDark")[2], nil, true)
	G.deco("WaterTankBand", V(d + 0.1, 1, 0.2), cf * CFrame.new(0, h + 5, -d / 2), "Red").CastShadow = false
	return tank
end

-- Depósito de combustible vertical (d de diámetro, h de alto): cobertura alta y ancha
function Military.fuelTank(cf, d, h)
	d = d or 12
	h = h or 10
	local tank = Kit.cylinder("FuelTank", h, d, cf * CFrame.new(0, h / 2, 0), get("Tank")[1], get("Tank")[2])
	Kit.cylinder("FuelTankTop", 0.6, d * 0.9, cf * CFrame.new(0, h + 0.3, 0), get("Concrete")[1], get("Concrete")[2], nil, true)
	for _, y in { h * 0.3, h * 0.7 } do
		Kit.cylinder("FuelTankBand", 0.4, d + 0.12, cf * CFrame.new(0, y, 0), get("SteelDark")[1], get("SteelDark")[2], nil, true)
	end
	G.deco("FuelTankLadder", V(0.8, h, 0.3), cf * CFrame.new(0, h / 2, -d / 2 - 0.2), "SteelDark")
	G.deco("FuelTankSign", V(3, 1.4, 0.2), cf * CFrame.new(2.4, h * 0.5, -d / 2 + 0.3) * CFrame.Angles(0, rad(-22), 0), "Red").CastShadow = false
	return tank
end

-- Mástil de radio (decorado salvo la base): hito visible desde todo el mapa
function Military.radioMast(cf, h)
	h = h or 26
	local base = G.box("MastBase", V(2.4, 1.6, 2.4), cf * CFrame.new(0, 0.8, 0), "SteelDark")
	G.deco("Mast", V(0.6, h, 0.6), cf * CFrame.new(0, h / 2, 0), "Steel")
	for y = 4, h - 2, 4 do
		G.deco("MastRung", V(1.6, 0.15, 0.15), cf * CFrame.new(0, y, 0), "Steel").CastShadow = false
	end
	for _, y in { h * 0.55, h * 0.8 } do
		G.deco("MastDish", V(1.6, 1.6, 0.4), cf * CFrame.new(0.6, y, -0.6) * CFrame.Angles(0, rad(30), 0), "Concrete")
	end
	local tip = G.deco("MastLight", V(0.6, 0.6, 0.6), cf * CFrame.new(0, h + 0.3, 0), { RGB(255, 60, 40), M.Neon })
	tip.CastShadow = false
	return base
end

-- Red de camuflaje sobre postes (decorado: no choca)
function Military.campNet(cf, w, d, h)
	h = h or 7
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			G.deco("NetPole", V(0.3, h, 0.3), cf * CFrame.new(x * w / 2, h / 2, z * d / 2), "WoodDark")
		end
	end
	local net = G.deco("CamoNet", V(w + 1, 0.2, d + 1), cf * CFrame.new(0, h, 0), "MilGreen")
	net.Transparency = 0.15
	for i, x in { -0.3, 0.15, 0.35 } do
		G.deco("CamoPatch", V(w * 0.3, 0.25, d * 0.4), cf * CFrame.new(x * w, h + 0.05, (i - 2) * d * 0.25), i == 2 and "Canvas" or "MilGreenDark").CastShadow = false
	end
	return net
end

-- Barrera de control (dos postes y brazo a rayas, decorado) de ancho w a lo largo de X local
function Military.barrierGate(cf, w)
	w = w or 10
	local post = G.box("GatePost", V(1, 3.4, 1), cf * CFrame.new(-w / 2, 1.7, 0), "Concrete")
	G.deco("GatePost", V(1, 3.4, 1), cf * CFrame.new(w / 2, 1.7, 0), "Concrete")
	for i = 0, 4 do
		G.deco("GateArm", V(w / 5, 0.4, 0.4), cf * CFrame.new(-w / 2 + (i + 0.5) * w / 5, 3.2, 0), i % 2 == 0 and "Red" or "Paint").CastShadow = false
	end
	return post
end

-- Barracón prefabricado (cf = centro de la base, largo a lo largo de X): cascarón con puertas en
-- los extremos (se cruza por dentro) y una lateral, techo plano con clip, toldo y aire acondicionado
function Military.barrack(T, cf, length, depth, opts)
	opts = opts or {}
	length, depth = length or 30, depth or 12
	local h = 8
	local door, window = G.door, G.window
	G.shell(cf, length, depth, h, opts.Look or "Building", {
		Front = opts.Front or { window(-length / 4, 3.5, 4, 2.5), window(length / 4, 3.5, 4, 2.5) },
		Back = opts.Back or { door(-length / 4, 4, 7), window(length / 4, 3.5, 4, 2.5) },
		Left = { door(0, 4, 7) },
		Right = { door(0, 4, 7) },
	}, { Frame = "MilGreenDark" })
	T.cap(G.box("BarrackRoof", V(length + 1, 0.6, depth + 1), cf * CFrame.new(0, h + 0.3, 0), "Roof"))
	G.deco("BarrackFloor", V(length - 1, 0.1, depth - 1), cf * CFrame.new(0, 0.05, 0), "Wood").CastShadow = false
	G.deco("BarrackAC", V(3, 2, 2), cf * CFrame.new(length / 4, h + 1.6, 0), "Concrete")
	if opts.Awning ~= false then
		Kit.awning(cf * CFrame.new(-length / 4, 7.2, depth / 2 + 0.2) * CFrame.Angles(0, math.pi, 0), 8, 3, get("Canvas")[1])
	end
end

-- Helicóptero de transporte posado (cobertura alta y hito). El morro mira a -Z. Devuelve las
-- piezas que chocan
function Military.helicopter(cf, look)
	look = look or "MilGreen"
	local solids = {}
	table.insert(solids, G.box("HeliBody", V(7, 7, 18), cf * CFrame.new(0, 4.6, 0), look))
	G.deco("HeliNose", V(6, 4.6, 3), cf * CFrame.new(0, 4.4, -10.4) * CFrame.Angles(rad(-12), 0, 0), look)
	G.deco("HeliCockpit", V(5.6, 2.4, 0.2), cf * CFrame.new(0, 6.4, -11.4) * CFrame.Angles(rad(-30), 0, 0), DARK_GLASS).CastShadow = false
	table.insert(solids, G.box("HeliTail", V(2, 2.2, 14), cf * CFrame.new(0, 6.6, 15.8), look))
	G.deco("HeliFin", V(0.5, 5, 3), cf * CFrame.new(0, 9, 22.2), look)
	G.deco("HeliTailRotor", V(0.2, 4.4, 0.6), cf * CFrame.new(0.5, 9.6, 22.4), "SteelDark")
	G.deco("HeliMast", V(1, 1.4, 1), cf * CFrame.new(0, 8.8, 0), "SteelDark")
	for _, a in { 20, 110 } do
		G.deco("HeliBlade", V(1.1, 0.2, 34), cf * CFrame.new(0, 9.6, 0) * CFrame.Angles(0, rad(a), 0), "SteelDark")
	end
	for _, s in { -1, 1 } do
		G.deco("HeliSkid", V(0.5, 0.5, 16), cf * CFrame.new(s * 3.6, 0.25, -1), "SteelDark")
		G.deco("HeliWindow", V(0.15, 1.6, 9), cf * CFrame.new(s * 3.52, 5.8, -1), DARK_GLASS).CastShadow = false
		G.deco("HeliDoor", V(0.2, 4.6, 4), cf * CFrame.new(s * 3.55, 3.8, 3), "MilGreenDark")
	end
	return solids
end

return Military
