-- METRO YARD · props: trenes (la gran cobertura y el hito), marquesina del andén central, mobiliario
-- de estación (torniquetes, máquinas, bancos, paneles), taller de las cocheras, patio de servicio
-- con contenedores, plaza de la estación y la ciudad con un viaducto de metro al fondo.
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local TRENCH = -3
local UP = 10
local ALONG_X = CFrame.Angles(0, math.pi / 2, 0)

-- Autobús articulado de la calle (choca: cobertura alta). Mira a -Z
local function bus(T, cf)
	local G = T.G
	local body = G.box("Bus", V(8, 8.4, 26), cf * CF(0, 4.6, 0), { RGB(230, 232, 236), M.SmoothPlastic })
	for _, s in { -1, 1 } do
		G.deco("BusWindows", V(0.12, 2.6, 23), cf * CF(s * 4.02, 5.8, 0.5), { RGB(34, 42, 54), M.Glass }).CastShadow = false
		G.deco("BusStripe", V(0.12, 0.8, 26), cf * CF(s * 4.02, 3.2, 0), "Orange").CastShadow = false
		for _, z in { -8, 8 } do
			Kit_wheel(T, cf * CF(s * 3.6, 1.2, z))
		end
	end
	G.deco("BusFront", V(7, 3, 0.12), cf * CF(0, 6, -13.06), { RGB(34, 42, 54), M.Glass }).CastShadow = false
	return body
end

function Kit_wheel(T, cf)
	T.Kit.cylinder("Wheel", 1, 2.4, cf * CFrame.Angles(0, 0, rad(90)), RGB(30, 30, 34), M.SmoothPlastic, nil, true)
end

function Props.build(T)
	local G = T.G
	local night = T.isNight()

	---------------------------------------------------------------------------
	-- ESTACIÓN (centro): letrero, kiosco de información, panel de salidas, letra A
	---------------------------------------------------------------------------
	T.sign(CF(0, 15, -39.3) * CFrame.Angles(0, math.pi, 0), "METRO · CENTRAL", 30, 3.2, RGB(40, 96, 196), RGB(255, 255, 255), { PPS = 16 })
	T.letterBanner(CF(0, 9, -99.2), "A", "Red", 6, 6.4)
	T.cap(G.solid("InfoBooth", V(8, 4, 4), CF(0, 0, -94), "WallBlue"))
	T.sign(CF(0, 5.2, -91.9) * CFrame.Angles(0, math.pi, 0), "INFO", 4, 1, RGB(240, 128, 36), RGB(255, 255, 255))
	T.departureBoard(CF(0, 7, -60), "M2 CENTRO  2 min")
	for _, x in { -30, 30 } do
		T.departureBoard(CF(x, UP + 6, -51.6), "M1 PUERTO  4 min")
	end

	---------------------------------------------------------------------------
	-- COCHERAS (centro): letrero, letra B, puente grúa
	---------------------------------------------------------------------------
	T.sign(CF(0, 13.2, 43.4), "COCHERAS · DEPOT", 26, 3, RGB(240, 128, 36), RGB(255, 255, 255), { PPS = 16 })
	T.letterBanner(CF(0, 8, 99.2) * CFrame.Angles(0, math.pi, 0), "B", "Blue", 6, 6.4)
	for _, z in { 60, 90 } do
		G.deco("CraneRail", V(98, 0.8, 0.8), CF(0, 14.4, z), "SteelDark")
	end
	G.deco("CraneBridge", V(1.2, 1.4, 30), CF(-20, 13.4, 75), "Orange")
	G.deco("CraneBridge", V(1.2, 1.4, 30), CF(20, 13.4, 75), "Orange")

	---------------------------------------------------------------------------
	-- Pasarela: carteles de dirección
	---------------------------------------------------------------------------
	T.sign(CF(0, UP + 5.6, -30) , "A ESTACIÓN ↑   B COCHERAS ↓", 5.6, 0.9, RGB(30, 34, 40), RGB(255, 200, 120), { Back = true, PPS = 30 })

	T.mirrored("MetroProps", function()
		Props.half(T)
	end)

	---------------------------------------------------------------------------
	-- Fondo: ciudad y viaducto de metro (decorado)
	---------------------------------------------------------------------------
	local palette = { RGB(170, 172, 176), RGB(120, 136, 160), RGB(196, 194, 188), RGB(150, 96, 76), RGB(98, 108, 124) }
	T.skylineRing(V(0, 0, 0), 230, 0, 355, 10, palette, { Lit = night, MinH = 30, VarH = 40, TowerEvery = 4, TowerExtra = 40, FloorH = 6 })
	for _, z in { -170 } do
		for x = -240, 240, 40 do
			G.deco("ViaductPier", V(4, 20, 4), CF(x, 10, z), "Concrete").CastShadow = false
		end
		G.deco("Viaduct", V(500, 3, 12), CF(0, 21.5, z), "Concrete").CastShadow = false
		for _, x in { -70, -48.5, -27 } do
			local car = G.deco("ViaductCar", V(21, 7.6, 6.4), CF(x, 27, z), "Train")
			car.CastShadow = false
			G.deco("ViaductStripe", V(21, 0.7, 6.5), CF(x, 25.8, z), "Orange").CastShadow = false
		end
	end
end

-- Mitad del Rojo (X < 0)
function Props.half(T)
	local G = T.G
	local night = T.isNight()

	------------------------------------------------------------------
	-- Trenes: dos coches en la vía 1 (norte), uno en la 3 y otro aparcado en el túnel (vía 4);
	-- carro de mantenimiento en la vía 2
	------------------------------------------------------------------
	T.cap(T.train(CF(-31, TRENCH, -24) * ALONG_X, 2, 20, { Label = "M2 · CENTRO" }))
	T.cap(T.metroCar(CF(-28, TRENCH, 11) * ALONG_X, 20, { Cab = "Both", Label = "M1 · PUERTO", Stripe = "Blue" }))
	T.cap(T.metroCar(CF(-76, TRENCH, 24) * ALONG_X, 20, { Cab = "Both", Label = "FUERA DE SERVICIO" }))
	T.cap(T.trolley(CF(-48, TRENCH, -11) * ALONG_X))
	for _, x in { -28, -56 } do
		for _, z in { -17.5, 17.5 } do
			T.gantry(CF(x, TRENCH, z) * ALONG_X, 25, 11)
		end
	end

	------------------------------------------------------------------
	-- Andén central: marquesina, bancos, máquina de bebidas, panel
	------------------------------------------------------------------
	for _, x in { -54, -42, -30, -22 } do
		G.column(CF(x, 0, 0), 8.2, 0.8, "Steel")
	end
	T.cap(G.box("PlatformCanopy", V(38, 0.5, 11), CF(-38, 8.45, 0), "SteelDark"))
	G.deco("CanopyEdge", V(38, 0.6, 0.3), CF(-38, 8.1, -5.6), "Orange").CastShadow = false
	G.deco("CanopyEdge", V(38, 0.6, 0.3), CF(-38, 8.1, 5.6), "Orange").CastShadow = false
	local strip = G.deco("CanopyLight", V(30, 0.2, 0.8), CF(-38, 8.1, 0), { RGB(236, 244, 255), M.Neon })
	strip.CastShadow = false
	T.Kit.light(strip, "PointLight", RGB(236, 244, 255), 22, night and 1.2 or 0.5)
	T.bench(CF(-26, 0, 3.4))
	T.bench(CF(-46, 0, -3.4) * CFrame.Angles(0, math.pi, 0))
	T.vending(CF(-36, 0, 3.6) * CFrame.Angles(0, math.pi, 0))
	T.departureBoard(CF(-38, 6, 0) * ALONG_X, "M2 CENTRO  2 min")
	-- Andén dentro del túnel: luces y bancos
	for _, z in { -17, 17 } do
		local lamp = G.deco("TunnelLamp", V(10, 0.3, 0.8), CF(-75, UP - 1.2, z), { RGB(255, 226, 170), M.Neon })
		lamp.CastShadow = false
		T.Kit.light(lamp, "PointLight", RGB(255, 220, 160), 24, night and 1.4 or 0.9)
	end
	T.bench(CF(-80, 0, 3.4))

	------------------------------------------------------------------
	-- Andenes norte y sur
	------------------------------------------------------------------
	T.cap(G.solid("NewsKiosk", V(7, 6, 6), CF(-30, 0, -37), "Orange"))
	T.sign(CF(-30, 6.8, -33.9) * CFrame.Angles(0, math.pi, 0), "PRENSA", 5, 1, RGB(40, 96, 196), RGB(255, 255, 255))
	T.vending(CF(-52, 0, -31.4) * CFrame.Angles(0, math.pi, 0), RGB(40, 96, 196))
	T.bench(CF(-14, 0, -31.4))
	T.ticketMachine(CF(-70, 0, -38.8) * CFrame.Angles(0, math.pi, 0))
	T.ticketMachine(CF(-66.6, 0, -38.8) * CFrame.Angles(0, math.pi, 0))
	-- Andén sur (delante de las cocheras): palés, carro y vallas
	T.cap(T.crateStack(CF(-30, 0, 38) * CFrame.Angles(0, rad(8), 0), "Wall"))
	T.jersey(CF(-52, 0, 33) * ALONG_X, 6)
	T.cableSpool(CF(-14, 0, 34))
	T.workLight(CF(-62, 0, 41))

	------------------------------------------------------------------
	-- ESTACIÓN (mitad): pilares, máquinas de billetes, bancos, jardinera
	------------------------------------------------------------------
	for _, z in { -66, -88 } do
		G.column(CF(-16, 0, z), 20, 2.2, "Wall", "HallColumn")
		G.deco("ColumnBand", V(2.4, 1, 2.4), CF(-16, 8, z), "WallBlue")
	end
	for _, z in { -84, -88.4, -92.8 } do
		T.ticketMachine(CF(-48, 0, z) * CFrame.Angles(0, -math.pi / 2, 0))
	end
	T.vending(CF(-32, 0, -97.6))
	T.bench(CF(-11.5, 0, -84) * CFrame.Angles(0, rad(90), 0))
	T.cap(T.planter(CF(-30, 0, -74), 8, 3))
	T.ticketMachine(CF(-10, 0, -70))
	T.ticketMachine(CF(-7.4, 0, -70))
	T.departureBoard(CF(-26, 7, -60), "M1 PUERTO  4 min")
	-- Toldo sobre la puerta oeste
	T.cap(G.box("EntranceCanopy", V(5, 0.5, 14), CF(-52.6, 10.2, -74), "Orange"))

	------------------------------------------------------------------
	-- COCHERAS (mitad): coche en mantenimiento, banco de trabajo, estanterías
	------------------------------------------------------------------
	T.track(V(-49, 0, 84), V(-6, 0, 84), { Step = 4 })
	T.cap(T.metroCar(CF(-30, 0.4, 84) * ALONG_X, 20, { Cab = "Front", Label = "TALLER" }))
	for _, x in { -36, -24 } do
		G.deco("Jack", V(1.6, 1, 1.6), CF(x, 0.5, 80), "YellowPaint")
	end
	T.cap(G.solid("WorkBench", V(8, 3.4, 2.6), CF(-26, 0, 72), "SteelDark"))
	T.cap(T.crateStack(CF(-12, 0, 66) * CFrame.Angles(0, rad(-12), 0), "L"))
	T.cableSpool(CF(-11, 0, 84))
	for _, x in { -40, -24 } do
		T.cap(G.solid("PartsRack", V(12, 8, 2.6), CF(x, 0, 97.6), "Orange"))
	end
	T.trolley(CF(-44, 0, 64))

	------------------------------------------------------------------
	-- BASE (cochera de autobuses): interior y calle
	------------------------------------------------------------------
	local lamp = G.deco("BaseLight", V(16, 0.3, 1.2), CF(-136, 9.2, 0), { RGB(240, 246, 255), M.Neon })
	T.Kit.light(lamp, "PointLight", RGB(236, 244, 255), 20, 0.8)
	T.cap(T.crateStack(CF(-146, 0, -14), "L"))
	T.cap(bus(T, CF(-110, 0, 64)))
	T.Kit.car(CF(-112, 0, -58), RGB(240, 200, 40))
	T.Kit.car(CF(-98, 0, 92) * CFrame.Angles(0, math.pi, 0), RGB(200, 60, 50))
	for _, z in { -96, -40, 40, 96 } do
		T.streetLight(CF(-121, 0, z))
	end
	for _, z in { -60, 0, 60 } do
		G.paintLine(V(-105, 0.02, z - 12), V(-105, 0.02, z + 12), 0.5, "YellowPaint")
	end
	G.deco("Sidewalk", V(4, 0.3, 220), CF(-122, 0.15, 0), "Sidewalk").CastShadow = false
	G.deco("Street", V(28, 0.1, 220), CF(-105, 0.05, 0), "Asphalt").CastShadow = false
	G.deco("PlazaPaving", V(38, 0.1, 58), CF(-69, 0.05, -71), "Tile").CastShadow = false

	------------------------------------------------------------------
	-- PLAZA DE LA ESTACIÓN (norte)
	------------------------------------------------------------------
	T.metroTotem(CF(-58, 0, -88))
	T.cap(T.planter(CF(-80, 0, -64), 8, 3))
	T.cap(T.planter(CF(-70, 0, -92) * ALONG_X, 8, 3))
	T.tree(CF(-80, 0, -64))
	T.tree(CF(-70, 0, -92))
	T.cap(T.kiosk(CF(-96, 0, -80), RGB(240, 128, 36), "CAFÉ"))
	for _, x in { -64, -88 } do
		T.bollard(CF(x, 0, -44))
	end

	------------------------------------------------------------------
	-- PATIO DE SERVICIO (sur): contenedores, traviesas, focos
	------------------------------------------------------------------
	T.cap(T.container(CF(-82, 0, 70) * ALONG_X, "ContainerBlue", "METRO"))
	T.cap(T.container(CF(-66, 0, 92), "ContainerGray"))
	T.cap(T.portacabin(CF(-104, 0, 100), "Wall"))
	T.beamStack(CF(-96, 0, 56), 12, "Sleeper")
	T.pipeStack(CF(-70, 0, 52) * ALONG_X, 12)
	T.floodTower(CF(-118, 0, 108), 16)
	T.cap(T.crateStack(CF(-60, 0, 80), "Wall"))
end

return Props
