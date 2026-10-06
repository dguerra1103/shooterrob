-- Piezas de puerto (Dockyard): grúa pórtico de muelle (STS), carretilla pórtico (straddle carrier),
-- buque portacontenedores (decorado), bita de amarre, defensa de muelle, camión con remolque y
-- contenedor, puerta enrollable y torre de focos. cf = centro de la base; la "cara" mira a -Z.
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local Port = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local get = Materials.get
local M = Enum.Material

local TIRE = { RGB(32, 32, 34), M.SmoothPlastic }
local DARK_GLASS = { RGB(40, 48, 58), M.Glass }

-- Grúa pórtico de muelle: cuatro patas (chocan: pilares de cobertura) separadas span en X y gauge
-- en Z, pórtico, cabina de maquinaria y pluma que sale sobre el agua (hacia -Z). Hito del mapa
function Port.stsCrane(cf, opts)
	opts = opts or {}
	local span, gauge = opts.Span or 18, opts.Gauge or 22
	local h = opts.Height or 26
	local look = opts.Look or "CraneRed"
	local legs = {}
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			table.insert(legs, G.box("CraneLeg", V(1.8, h, 1.8), cf * CFrame.new(x * span / 2, h / 2, z * gauge / 2), look))
		end
		G.deco("CraneSill", V(1.4, 1.4, gauge + 1.8), cf * CFrame.new(x * span / 2, 13, 0), look)
		G.deco("CraneBogie", V(2.6, 1.2, 4), cf * CFrame.new(x * span / 2, 0.6, -gauge / 2), "SteelDark")
		G.deco("CraneBogie", V(2.6, 1.2, 4), cf * CFrame.new(x * span / 2, 0.6, gauge / 2), "SteelDark")
	end
	for _, z in { -1, 1 } do
		G.deco("CranePortal", V(span + 1.8, 2, 1.8), cf * CFrame.new(0, h - 1, z * gauge / 2), look)
	end
	-- Pluma y contrapluma (decorado, muy por encima del juego)
	local boomLength = opts.Boom or 60
	G.deco("CraneBoom", V(span + 1.8, 2.4, boomLength + gauge), cf * CFrame.new(0, h + 1.2, -boomLength / 2 + 4), look)
	G.deco("CraneMachinery", V(span - 2, 5, 9), cf * CFrame.new(0, h + 4.9, gauge / 2 - 2), "Paint")
	G.deco("CraneApex", V(1.2, 14, 1.2), cf * CFrame.new(-span / 2 + 1, h + 9.4, 0), look)
	G.deco("CraneApex", V(1.2, 14, 1.2), cf * CFrame.new(span / 2 - 1, h + 9.4, 0), look)
	for _, s in { -1, 1 } do
		local a = cf * CFrame.new(s * (span / 2 - 1), h + 16, 0)
		local b = cf * CFrame.new(s * (span / 2 - 1), h + 2.4, -boomLength + 4)
		local mid = (a.Position + b.Position) / 2
		G.deco("CraneStay", V(0.3, 0.3, (a.Position - b.Position).Magnitude), CFrame.lookAt(mid, b.Position), "SteelDark").CastShadow = false
	end
	G.deco("CraneCab", V(4, 3, 4), cf * CFrame.new(0, h - 2.6, -gauge / 2 - 6), DARK_GLASS)
	G.deco("CraneSpreader", V(8, 1, 20), cf * CFrame.new(0, h - 8, -gauge / 2 - 14), "YellowPaint")
	G.deco("CraneCable", V(0.2, 6, 0.2), cf * CFrame.new(0, h - 4.5, -gauge / 2 - 14), "SteelDark")
	return legs
end

-- Carretilla pórtico (straddle carrier): cuatro patas y cabina alta (choca la base de las patas)
function Port.straddleCarrier(cf, look)
	look = look or "YellowPaint"
	local solids = {}
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			table.insert(solids, G.box("CarrierLeg", V(1.2, 13, 1.2), cf * CFrame.new(x * 5, 6.5, z * 6), look))
		end
		G.deco("CarrierBeam", V(1.4, 1.6, 13.4), cf * CFrame.new(x * 5, 12.4, 0), look)
		for _, z in { -6, 6 } do
			Kit.cylinder("Wheel", 1, 2.4, cf * CFrame.new(x * 5, 1.2, z) * CFrame.Angles(0, 0, rad(90)), TIRE[1], TIRE[2], nil, true)
		end
	end
	G.deco("CarrierTop", V(11.4, 1.4, 4), cf * CFrame.new(0, 13.4, 0), look)
	G.deco("CarrierCab", V(3, 3, 3), cf * CFrame.new(-4.4, 15.6, -5), DARK_GLASS)
	return solids
end

-- Buque portacontenedores (decorado, fuera del área de juego): casco, superestructura y
-- contenedores en cubierta. cf = centro del casco a la altura del agua; eslora a lo largo de X
function Port.ship(cf, length, colors)
	length = length or 180
	local beam = 30
	G.deco("Hull", V(length, 16, beam), cf * CFrame.new(0, 2, 0), "Hull").CastShadow = false
	G.deco("HullBottom", V(length - 4, 4, beam - 0.4), cf * CFrame.new(0, -7, 0), "Red").CastShadow = false
	G.deco("Bow", V(20, 16, beam * 0.7), cf * CFrame.new(-length / 2 - 6, 2, 0) * CFrame.Angles(0, rad(45), 0), "Hull").CastShadow = false
	G.deco("Deck", V(length, 0.4, beam - 1), cf * CFrame.new(0, 10.2, 0), "SteelDark")
	G.deco("Bridge", V(16, 18, beam - 4), cf * CFrame.new(length / 2 - 14, 19, 0), "Paint").CastShadow = false
	G.deco("BridgeWindows", V(16.2, 2, beam - 3.6), cf * CFrame.new(length / 2 - 14, 25, 0), DARK_GLASS).CastShadow = false
	G.deco("Funnel", V(6, 10, 6), cf * CFrame.new(length / 2 - 8, 33, 0), "Red")
	G.deco("ShipName", V(30, 2.4, 0.2), cf * CFrame.new(-length / 4, 6, beam / 2 + 0.1), "Paint").CastShadow = false
	colors = colors or { "ContainerRed", "ContainerBlue", "ContainerYellow", "ContainerGray" }
	local rows = math.floor((length - 50) / 21)
	for i = 0, rows - 1 do
		local x = -length / 2 + 16 + i * 21
		local layers = 2 + (i % 3)
		for layer = 0, layers - 1 do
			for _, z in { -10, 0, 10 } do
				local c = colors[((i + layer + math.floor(z / 10)) % #colors) + 1]
				G.deco("DeckContainer", V(20, 8.5, 8.2), cf * CFrame.new(x, 10.4 + 4.25 + layer * 8.6, z), c).CastShadow = layer == 0
			end
		end
	end
end

-- Bita de amarre (choca: muy baja) con la amarra hacia el barco
function Port.mooringBollard(cf)
	local post = Kit.cylinder("Bollard", 1.6, 1.4, cf * CFrame.new(0, 0.8, 0), get("SteelDark")[1], get("SteelDark")[2])
	Kit.cylinder("BollardCap", 0.4, 2, cf * CFrame.new(0, 1.7, 0), get("SteelDark")[1], get("SteelDark")[2], nil, true)
	return post
end

-- Defensa de muelle (neumático en el canto; decorado)
function Port.fender(cf)
	Kit.cylinder("Fender", 1.2, 3, cf * CFrame.Angles(rad(90), 0, 0), TIRE[1], TIRE[2], nil, true)
end

-- Camión con remolque y contenedor (cobertura alta). Mira a -Z. Devuelve las piezas que chocan
function Port.containerTruck(cf, look)
	local solids = {}
	table.insert(solids, G.box("TruckCab", V(7, 7, 7), cf * CFrame.new(0, 4.5, -13), "Paint"))
	G.deco("TruckWindscreen", V(6, 2.2, 0.15), cf * CFrame.new(0, 6.2, -16.6), DARK_GLASS).CastShadow = false
	G.deco("TruckChassis", V(6, 1.2, 22), cf * CFrame.new(0, 1.8, 2), "SteelDark")
	table.insert(solids, (Kit.container(cf * CFrame.new(0, 2.4, 2) * CFrame.Angles(0, math.pi / 2, 0), get(look or "ContainerBlue")[1])))
	for _, s in { -1, 1 } do
		for _, z in { -13, 7, 10 } do
			Kit.cylinder("Wheel", 1, 2.8, cf * CFrame.new(s * 3, 1.4, z) * CFrame.Angles(0, 0, rad(90)), TIRE[1], TIRE[2], nil, true)
		end
	end
	return solids
end

-- Puerta enrollable (decorado, sobre la pared) de w x h
function Port.rollerDoor(cf, w, h)
	local door = G.deco("RollerDoor", V(w, h, 0.2), cf * CFrame.new(0, h / 2, 0), "Steel")
	for y = 1, h - 1, 1 do
		G.deco("RollerSlat", V(w, 0.08, 0.25), cf * CFrame.new(0, y, 0), "SteelDark").CastShadow = false
	end
	return door
end

return Port
