-- Piezas de aeropuerto (Terminal): avión de pasajeros estilizado, carros de equipaje con tractor,
-- furgoneta de servicio, contenedor de carga aérea (ULD), camión cisterna, escalerilla, torre de
-- focos de plataforma y torre de control (decorado). cf = centro de la base, "cara" hacia -Z.
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local Airport = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local get = Materials.get
local M = Enum.Material

local WHITE = { RGB(240, 242, 246), M.SmoothPlastic }
local GRAY = { RGB(178, 184, 192), M.Metal }

-- Cilindro tumbado a lo largo de Z local (eje del fuselaje)
local function tube(name, length, d, cf, look, solid)
	look = get(look)
	local part = Kit.pipe(name, length, d, cf * CFrame.Angles(0, rad(90), 0), look[1], look[2], not solid)
	return part
end

-- Avión de pasajeros: el morro mira a -Z. Fuselaje (choca: es la gran cobertura del centro), alas
-- y motores (los motores chocan: cobertura baja-media), deriva con la franja azul. Devuelve las
-- piezas que chocan (para taparlas por arriba).
function Airport.airliner(cf, opts)
	opts = opts or {}
	local length = opts.Length or 64
	local d = opts.Diameter or 9
	local stripe = opts.Stripe or RGB(40, 92, 190)
	local bottom = opts.Bottom or 2.6
	local cy = bottom + d / 2
	local solids = {}
	-- Fuselaje (dos tramos: el central recto y la cola que se estrecha)
	table.insert(solids, tube("Fuselage", length * 0.72, d, cf * CFrame.new(0, cy, -length * 0.08), WHITE, true))
	for i, spec in { { 0.82, 0.62 }, { 0.62, 0.42 } } do
		local seg = length * 0.1
		tube("FuselageTail", seg, d * spec[1], cf * CFrame.new(0, cy + d * (1 - spec[1]) * 0.35 * i, length * 0.28 + (i - 0.5) * seg), WHITE)
	end
	-- Morro: media esfera y cabina
	local nose = Kit.ball("Nose", d, cf * CFrame.new(0, cy, -length * 0.44), WHITE[1], WHITE[2], false)
	table.insert(solids, nose)
	G.deco("Cockpit", V(d * 0.62, d * 0.16, 2.2), cf * CFrame.new(0, cy + d * 0.18, -length * 0.44 - d * 0.3) * CFrame.Angles(rad(-25), 0, 0), { RGB(30, 40, 52), M.Glass })
	-- Franja de ventanillas y franja azul inferior
	for _, s in { -1, 1 } do
		G.deco("Windows", V(0.2, 0.7, length * 0.6), cf * CFrame.new(s * (d / 2 - 0.05), cy + d * 0.12, -length * 0.08), { RGB(36, 44, 56), M.Glass }).CastShadow = false
		G.deco("Cheatline", V(0.2, 0.5, length * 0.68), cf * CFrame.new(s * (d / 2 - 0.1), cy - d * 0.12, -length * 0.08), { stripe, M.SmoothPlastic }).CastShadow = false
		G.deco("PlaneDoor", V(0.25, 4.2, 2.4), cf * CFrame.new(s * (d / 2), cy + 0.6, -length * 0.36), GRAY).CastShadow = false
	end
	-- Alas (barridas hacia atrás) con winglets; motores colgados
	for _, s in { -1, 1 } do
		local root = cf * CFrame.new(s * d * 0.45, bottom + d * 0.22, length * 0.02)
		local span = opts.Span or 34
		local wing = G.deco("Wing", V(span, 0.9, 9), root * CFrame.new(s * span / 2, 0, 3) * CFrame.Angles(0, s * rad(-22), 0) * CFrame.Angles(0, 0, s * rad(5)), WHITE)
		wing.CastShadow = true
		G.deco("Winglet", V(0.5, 4, 3), root * CFrame.new(s * (span - 1), 2.4, 3 + span * 0.4) * CFrame.Angles(0, s * rad(-22), 0), { stripe, M.SmoothPlastic })
		local engine = tube("Engine", 8, 4.6, cf * CFrame.new(s * (d * 0.45 + 10), bottom + 0.2 + 2.3 - 0.4, -length * 0.02), GRAY, true)
		table.insert(solids, engine)
		tube("EngineIntake", 0.6, 4.2, cf * CFrame.new(s * (d * 0.45 + 10), bottom + 2.1, -length * 0.02 - 4.2), { RGB(40, 42, 48), M.Metal })
		G.deco("Pylon", V(0.8, 2.4, 5), cf * CFrame.new(s * (d * 0.45 + 10), bottom + 4.8, length * 0.0), GRAY)
		-- Estabilizador horizontal de cola
		G.deco("Stabilizer", V(13, 0.6, 5), cf * CFrame.new(s * 7.5, cy + 1.6, length * 0.4) * CFrame.Angles(0, s * rad(-25), 0), WHITE)
	end
	-- Deriva (con el color de la compañía)
	G.deco("Fin", V(0.8, 13, 9), cf * CFrame.new(0, cy + d * 0.4 + 6, length * 0.42) * CFrame.Angles(rad(-28), 0, 0), { stripe, M.SmoothPlastic })
	-- Tren de aterrizaje
	G.deco("NoseGear", V(0.6, bottom + 0.4, 0.6), cf * CFrame.new(0, (bottom + 0.4) / 2, -length * 0.36), "SteelDark")
	tube("NoseWheel", 0.8, 1.6, cf * CFrame.new(0, 0.8, -length * 0.36) * CFrame.Angles(0, rad(90), 0), { RGB(24, 24, 26), M.Rubber })
	for _, s in { -1, 1 } do
		G.deco("MainGear", V(0.8, bottom + 1, 0.8), cf * CFrame.new(s * 4, (bottom + 1) / 2, length * 0.06), "SteelDark")
		for _, z in { -0.9, 0.9 } do
			Kit.pipe("MainWheel", 1, 2.2, cf * CFrame.new(s * 4, 1.1, length * 0.06 + z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	-- Balizas
	for _, p in { V(-38, bottom + 3, 6), V(38, bottom + 3, 6) } do
		local light = Kit.ball("NavLight", 0.6, cf * CFrame.new(p), p.X < 0 and RGB(255, 40, 40) or RGB(40, 255, 90), M.Neon, true)
		light:SetAttribute("Blink", 1)
	end
	return solids
end

-- Carro de equipaje (cobertura baja-media) con maletas y lona
function Airport.baggageCart(cf, tarp)
	local body = G.box("BagCart", V(4.4, 1, 7), cf * CFrame.new(0, 1.2, 0), "SteelDark")
	G.box("BagLoad", V(4, 2.6, 6.4), cf * CFrame.new(0, 3, 0), { tarp or RGB(60, 90, 140), M.Fabric })
	for _, x in { -2, 2 } do
		for _, z in { -2.6, 2.6 } do
			Kit.pipe("CartWheel", 0.5, 1.2, cf * CFrame.new(x, 0.6, z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	G.deco("CartBar", V(0.3, 0.3, 2), cf * CFrame.new(0, 1, -4.4), "SteelDark")
	return body
end

-- Tractor de remolque (amarillo)
function Airport.tug(cf)
	local body = G.box("Tug", V(4.6, 2.6, 6), cf * CFrame.new(0, 1.7, 0), { RGB(232, 180, 30), M.Metal })
	G.deco("TugSeat", V(3, 2.2, 2), cf * CFrame.new(0, 4, 1.2), "SteelDark")
	G.deco("TugRoof", V(4.2, 0.3, 3.2), cf * CFrame.new(0, 5.4, 1), "SteelDark")
	for _, x in { -2.3, 2.3 } do
		for _, z in { -2, 2 } do
			Kit.pipe("TugWheel", 0.8, 1.8, cf * CFrame.new(x, 0.9, z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	local beacon = Kit.ball("TugBeacon", 0.5, cf * CFrame.new(0, 5.8, 1), RGB(255, 160, 30), M.Neon, true)
	beacon:SetAttribute("Blink", 1)
	return body
end

-- Tren de carros detrás de un tractor (count carros)
function Airport.baggageTrain(cf, count)
	Airport.tug(cf)
	for i = 1, count do
		Airport.baggageCart(cf * CFrame.new(0, 0, 4 + i * 8.2), i % 2 == 0 and RGB(150, 60, 50) or RGB(60, 90, 140))
	end
end

-- Furgoneta de servicio (blanca, cobertura alta)
function Airport.van(cf, stripe)
	local body = G.box("Van", V(5.4, 5.4, 11), cf * CFrame.new(0, 3.3, 0.5), WHITE)
	G.box("VanCab", V(5.4, 3.6, 3), cf * CFrame.new(0, 2.4, -6.4), WHITE)
	G.deco("VanGlass", V(5, 1.6, 0.2), cf * CFrame.new(0, 4.6, -5.1), { RGB(40, 50, 62), M.Glass })
	G.deco("VanStripe", V(5.5, 0.6, 11.1), cf * CFrame.new(0, 2.6, 0.5), { stripe or RGB(220, 120, 30), M.SmoothPlastic })
	for _, x in { -2.5, 2.5 } do
		for _, z in { -5.4, 3.6 } do
			Kit.pipe("VanWheel", 0.8, 2, cf * CFrame.new(x, 1, z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	Kit.contactShadow(cf, 5.8, 14)
	return body
end

-- Contenedor de carga aérea (ULD): forma con el chaflán arriba (cobertura alta)
function Airport.uld(cf, look)
	look = get(look or "ContainerBlue")
	local body = G.box("ULD", V(6, 5.4, 5), cf * CFrame.new(0, 2.9, 0), look)
	G.deco("ULDBase", V(6.2, 0.4, 5.2), cf * CFrame.new(0, 0.2, 0), "SteelDark")
	G.deco("ULDDoor", V(5, 4, 0.1), cf * CFrame.new(0, 3, -2.55), { RGB(40, 44, 50), M.Fabric })
	G.deco("ULDRib", V(0.25, 5.4, 5.1), cf * CFrame.new(-1.5, 2.9, 0), { look[1]:Lerp(Color3.new(0, 0, 0), 0.3), M.Metal })
	G.deco("ULDRib", V(0.25, 5.4, 5.1), cf * CFrame.new(1.5, 2.9, 0), { look[1]:Lerp(Color3.new(0, 0, 0), 0.3), M.Metal })
	return body
end

-- Camión cisterna de combustible (cobertura alta y larga)
function Airport.fuelTruck(cf)
	G.box("FuelCab", V(5.2, 5, 4.4), cf * CFrame.new(0, 3, -7.6), WHITE)
	G.deco("FuelGlass", V(4.8, 1.6, 0.2), cf * CFrame.new(0, 4.4, -9.85), { RGB(40, 50, 62), M.Glass })
	local tank = tube("FuelTank", 12, 5, cf * CFrame.new(0, 4, 1.4), { RGB(226, 228, 232), M.Metal }, true)
	G.box("FuelChassis", V(4.6, 1.2, 17), cf * CFrame.new(0, 1.4, -1), "SteelDark")
	G.deco("FuelStripe", V(5.1, 0.8, 12.1), cf * CFrame.new(0, 3, 1.4), { RGB(214, 60, 40), M.SmoothPlastic })
	for _, x in { -2.3, 2.3 } do
		for _, z in { -7.5, 3, 6.4 } do
			Kit.pipe("FuelWheel", 0.9, 2.2, cf * CFrame.new(x, 1.1, z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	return tank
end

-- Torre de focos de plataforma (alta, luz cálida hacia -Z y abajo)
function Airport.apronLight(cf, h)
	h = h or 24
	G.column(cf, h, 1, "SteelDark", "ApronMast")
	G.deco("ApronHead", V(6, 1.4, 1.2), cf * CFrame.new(0, h + 0.7, -0.4), "SteelDark")
	for _, x in { -2, 0, 2 } do
		local lamp = G.deco("ApronLamp", V(1.6, 1, 0.3), cf * CFrame.new(x, h + 0.6, -1.1) * CFrame.Angles(rad(-30), 0, 0), { RGB(255, 236, 200), M.Neon })
		if x == 0 then
			Kit.light(lamp, "SpotLight", RGB(255, 228, 190), 60, 2, Enum.NormalId.Front).Angle = 90
		end
	end
end

-- Deflector de chorro: pantalla de rejilla inclinada sobre un murete (cobertura alta, cara -Z)
function Airport.blastFence(cf, length)
	length = length or 16
	local base = G.box("BlastBase", V(length, 3, 1.4), cf * CFrame.new(0, 1.5, 0), "Concrete")
	local panel = G.box("BlastPanel", V(length, 6, 0.5), cf * CFrame.new(0, 5.6, 1.2) * CFrame.Angles(rad(-22), 0, 0), { RGB(190, 196, 204), M.DiamondPlate })
	panel.CastShadow = true
	for x = -length / 2 + 1, length / 2 - 1, 4 do
		G.deco("BlastStrut", V(0.4, 7, 0.4), cf * CFrame.new(x, 4, 2.4) * CFrame.Angles(rad(30), 0, 0), "SteelDark")
	end
	return base
end

-- Grupo de energía de tierra (caja amarilla con ruedas: cobertura baja)
function Airport.gpu(cf)
	local body = G.box("GPU", V(3.4, 3, 5), cf * CFrame.new(0, 2, 0), { RGB(230, 180, 40), M.Metal })
	for _, x in { -1.6, 1.6 } do
		for _, z in { -1.8, 1.8 } do
			Kit.pipe("GPUWheel", 0.5, 1, cf * CFrame.new(x, 0.5, z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	G.deco("GPUCable", V(0.3, 0.3, 6), cf * CFrame.new(0, 0.3, -5.5), "Black")
	return body
end

-- Cinta cargadora de equipaje (camión bajo con cinta inclinada)
function Airport.beltLoader(cf)
	local body = G.box("BeltLoader", V(4, 2.2, 10), cf * CFrame.new(0, 1.6, 0), { RGB(230, 180, 40), M.Metal })
	G.deco("Belt", V(2.6, 0.5, 13), cf * CFrame.new(0, 4.4, -2) * CFrame.Angles(rad(18), 0, 0), "SteelDark")
	for _, x in { -2, 2 } do
		for _, z in { -3.5, 3.5 } do
			Kit.pipe("LoaderWheel", 0.6, 1.4, cf * CFrame.new(x, 0.7, z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	return body
end

-- Torre de control (decorado alto, fuera del área de juego): fuste, cabina octogonal de cristal
function Airport.controlTower(cf, h)
	h = h or 70
	Kit.cylinder("TowerShaft", h, 9, cf * CFrame.new(0, h / 2, 0), RGB(206, 208, 212), M.Concrete, nil, true)
	Kit.cylinder("TowerBand", 2, 11, cf * CFrame.new(0, h * 0.4, 0), RGB(150, 154, 160), M.Concrete, nil, true)
	Kit.cylinder("CabFloor", 2, 20, cf * CFrame.new(0, h + 1, 0), RGB(120, 124, 130), M.Concrete, nil, true)
	local cab = Kit.cylinder("CabGlass", 7, 19, cf * CFrame.new(0, h + 5.5, 0), RGB(70, 110, 140), M.Glass, nil, true)
	cab.Transparency = 0.15
	Kit.cylinder("CabRoof", 1.6, 21, cf * CFrame.new(0, h + 9.8, 0), RGB(80, 84, 90), M.Metal, nil, true)
	Kit.cylinder("Antenna", 8, 0.6, cf * CFrame.new(0, h + 14.6, 0), RGB(200, 60, 50), M.Metal, nil, true)
	local beacon = Kit.ball("TowerBeacon", 1, cf * CFrame.new(0, h + 19, 0), RGB(255, 40, 30), M.Neon, true)
	beacon:SetAttribute("Blink", 1)
	G.deco("TowerBalcony", V(24, 0.6, 24), cf * CFrame.new(0, h - 0.4, 0) * CFrame.Angles(0, rad(22.5), 0), "SteelDark")
end

-- Escalerilla de embarque (decorado con cuerpo que choca: cobertura)
function Airport.airstairs(cf)
	local body = G.box("StairTruck", V(4.6, 2, 9), cf * CFrame.new(0, 1.6, 0), WHITE)
	G.deco("StairFlight", V(3.6, 0.6, 11), cf * CFrame.new(0, 5, -0.5) * CFrame.Angles(rad(30), 0, 0), GRAY)
	for _, s in { -1, 1 } do
		G.deco("StairRail", V(0.2, 0.2, 11), cf * CFrame.new(s * 1.8, 6.6, -0.5) * CFrame.Angles(rad(30), 0, 0), "SteelDark")
	end
	return body
end

return Airport
