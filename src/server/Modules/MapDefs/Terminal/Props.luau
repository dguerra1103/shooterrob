-- TERMINAL · props: el avión (hito y gran divisor del centro), cobertura de plataforma (contenedores
-- de carga aérea, trenes de equipaje, cisterna, furgonetas, escalerilla), interior de la terminal
-- (mostradores, asientos, cintas) y el decorado (torre de control, pista, focos, pintura).
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local L = 10
local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0)

function Props.build(T)
	local G = T.G
	local night = T.isNight()

	---------------------------------------------------------------------------
	-- Avión en el centro (morro hacia la terminal); las piezas que chocan se tapan por arriba
	---------------------------------------------------------------------------
	T.cap(T.airliner(CF(0, 0, -6), { Stripe = RGB(40, 92, 190), Length = 84, Diameter = 11, Span = 40, Bottom = 3 }))
	-- Servicio del avión: grupo de energía, cinta cargadora y escalerilla trasera
	for _, s in { -1, 1 } do
		T.gpu(CF(s * 10, 0, -30) * CFrame.Angles(0, rad(s * 20), 0))
		T.beltLoader(CF(s * 9.5, 0, 22) * CFrame.Angles(0, rad(s * 12), 0))
	end

	---------------------------------------------------------------------------
	-- Cobertura en el eje
	---------------------------------------------------------------------------
	-- Plataforma A: escalerilla delante del morro y contenedores a los lados del sitio
	T.airstairs(CF(0, 0, -47))
	for _, s in { -1, 1 } do
		T.uld(CF(s * 12, 0, -72) * CFrame.Angles(0, rad(s * 8), 0), s < 0 and "ContainerBlue" or "ContainerRed")
		T.baggageCart(CF(s * 7, 0, -56), RGB(60, 90, 140))
	end
	-- Detrás de la cola: tren de equipaje a lo largo (corta la línea de un lado a otro)
	T.baggageTrain(CF(0, 0, 46) * CFrame.Angles(0, math.pi, 0), 2)
	-- Carga (sitio B): furgoneta delante del sitio y contenedores apilados
	T.van(CF(0, 0, 86), RGB(40, 92, 190))
	for _, s in { -1, 1 } do
		T.uld(CF(s * 16, 0, 90), "ContainerBlue")
		T.uld(CF(s * 25, 0, 103) * CFrame.Angles(0, rad(90), 0), "ContainerGray")
		T.uld(CF(s * 25, 5.4, 103) * CFrame.Angles(0, rad(90), 0), "ContainerYellow")
		T.crateStack(CF(s * 12, 4, 114), "Wall")
		local tube = G.deco("CanopyLight", V(1.2, 0.3, 30), CF(s * 14, L - 0.3, 98), { RGB(236, 244, 255), M.Neon })
		tube.CastShadow = false
		T.Kit.light(tube, "PointLight", RGB(230, 240, 255), 26, 1)
	end
	-- Terminal (dentro): mostradores de facturación, cintas, asientos y paneles
	for _, s in { -1, 1 } do
		for _, x in { 18, 52 } do
			G.box("CheckIn", V(10, 3.4, 2.4), CF(s * x, 1.7, -100), "TerminalWall")
			G.deco("CheckInStripe", V(10.1, 0.6, 2.5), CF(s * x, 2.6, -100), x == 18 and "Red" or "Blue")
			G.deco("CheckInSign", V(10, 1.4, 0.3), CF(s * x, 8, -103), "Blue")
		end
		G.box("BagBelt", V(16, 1.4, 4), CF(s * 50, 0.7, -120), "TerminalDark")
		for _, x in { 10, 44 } do
			for _, z in { -96, -102 } do
				G.box("SeatRow", V(10, 1.6, 1.6), CF(s * x, L + 0.8, z), "Carpet")
				G.deco("SeatBack", V(10, 1.6, 0.3), CF(s * x, L + 2.4, z + 0.7), "Carpet")
			end
		end
	end
	-- Suelo de baldosa, luces de techo y plantas
	G.deco("HallTiles", V(138, 0.06, 46), CF(0, 0.03, -106), "Tile").CastShadow = false
	T.Kit.floorJoints(CF(0, 0.02, -106), 138, 46, 6, RGB(170, 172, 178))
	for _, x in { -54, -30, -6, 18, 42 } do
		for _, level in { 0, L } do
			local tube = G.deco("CeilingLight", V(14, 0.3, 1.2), CF(x + 6, level + L - 0.25, -106), { RGB(240, 246, 255), M.Neon })
			tube.CastShadow = false
			if x == -30 or x == 18 then
				T.Kit.light(tube, "PointLight", RGB(236, 244, 255), 26, 0.9)
			end
		end
	end
	for _, s in { -1, 1 } do
		T.planter(CF(s * 6, 0, -124), 6, 3)
		T.planter(CF(s * 60, L, -110) * CFrame.Angles(0, rad(90), 0), 6, 3)
	end
	local board = T.sign(CF(0, L + 7, -129.3), "SALIDAS · PUERTAS A1 – A8", 30, 3, RGB(18, 22, 30), RGB(255, 200, 60), { PPS = 16, Glow = true })
	board.CastShadow = false
	T.sign(CF(0, 4, -129.3), "LLEGADAS · RECOGIDA DE EQUIPAJE", 26, 2.2, RGB(18, 22, 30), RGB(240, 240, 240), { PPS = 16, Glow = true })

	T.mirrored("TerminalProps", function()
		Props.half(T)
	end)

	---------------------------------------------------------------------------
	-- Lonas A / B, rótulos
	---------------------------------------------------------------------------
	T.letterBanner(CF(0, L + 5.5, -81.6) * CFrame.Angles(0, math.pi, 0), "A", "Red", 8, 9)
	T.letterBanner(CF(0, 6.4, 77.4), "B", "Blue", 6, 5)
	T.sign(CF(0, 2 * L + 0.2, -73.8) * CFrame.Angles(0, math.pi, 0), "TERMINAL 1", 20, 1.6, RGB(36, 44, 60), RGB(250, 250, 250), { PPS = 18, Glow = true })
	T.sign(CF(-24, L - 0.2, 76.8), "CARGA · CARGO", 14, 1.4, RGB(36, 44, 60), RGB(244, 190, 40), { PPS = 18 })

	---------------------------------------------------------------------------
	-- Suelo: línea de rodaje amarilla, marcas de los puestos, franjas de seguridad
	---------------------------------------------------------------------------
	G.paintLine(V(0, 0, -78), V(0, 0, 76), 0.7)
	for _, s in { -1, 1 } do
		G.paintLine(V(s * 46, 0, -40), V(s * 46, 0, 40), 0.5)
		G.paintLine(V(s * 46, 0, -40), V(s * 112, 0, -40), 0.5)
		G.paintLine(V(s * 46, 0, 40), V(s * 112, 0, 40), 0.5)
		G.paintLine(V(s * 70, 0, -82), V(s * 70, 0, -40), 0.5)
	end
	G.paintLine(V(-46, 0, -80), V(46, 0, -80), 0.5, "Red")
	G.hazardStripes(CF(0, 0, 76), 80, 1.2)

	---------------------------------------------------------------------------
	-- Fondo: torre de control tras la terminal, pista con marcas, hangares lejanos y focos
	---------------------------------------------------------------------------
	T.controlTower(CF(-46, 0, -178), 70)
	G.deco("Runway", V(1400, 0.1, 60), CF(0, 0.05, 230), "Tarmac").CastShadow = false
	for x = -640, 640, 40 do
		G.deco("RunwayDash", V(16, 0.12, 1.2), CF(x, 0.06, 230), "Paint").CastShadow = false
	end
	G.deco("Taxiway", V(1400, 0.08, 24), CF(0, 0.04, 170), "Tarmac").CastShadow = false
	for _, x in { -300, -200, 220, 330 } do
		T.cityBlock(CF(x, 0, -200), 50, 40, 22, RGB(196, 200, 206), { Lit = night, Roof = true })
	end
	for _, spec in { { V(-600, -60, 500), 200 }, { V(500, -70, 560), 220 }, { V(700, -60, -300), 200 } } do
		T.Kit.naturalHill(spec[1], spec[2], M.Rock)
	end
	T.skylineRing(V(0, 0, -480), 260, 200, 340, 9, { RGB(170, 160, 168), RGB(150, 146, 156), RGB(190, 176, 170) }, { Lit = night, MinH = 30, VarH = 50, TowerEvery = 4, TowerExtra = 50, FloorH = 10 })
end

-- Mitad del Rojo (X < 0)
function Props.half(T)
	local G = T.G

	------------------------------------------------------------------
	-- HANGAR (base): contenedores delante del portón central, banco de trabajo y un tractor
	------------------------------------------------------------------
	T.uld(CF(-104, 0, -3) * ALONG_Z, "ContainerGray")
	T.uld(CF(-104, 0, 3) * ALONG_Z, "ContainerGray")
	G.box("Workbench", V(3, 3, 10), CF(-147, 1.5, -30), "TerminalDark")
	T.tug(CF(-142, 0, 30) * CFrame.Angles(0, rad(90), 0))
	T.sign(CF(-112.2, 15.5, 0) * CFrame.Angles(0, -math.pi / 2, 0), "HANGAR 2", 12, 2.4, RGB(36, 44, 60), RGB(250, 250, 250), { PPS = 16 })
	for _, z in { -24, 0, 24 } do
		local lamp = G.deco("HangarLamp", V(4, 0.4, 4), CF(-131, 21.2, z), { RGB(255, 240, 210), M.Neon })
		T.Kit.light(lamp, "PointLight", RGB(255, 236, 200), 26, 1)
	end

	------------------------------------------------------------------
	-- CARRETERA DE SERVICIO (norte): furgoneta, barreras, contenedor y conos
	------------------------------------------------------------------
	T.van(CF(-88, 0, -62) * CFrame.Angles(0, rad(90), 0), RGB(220, 120, 30))
	T.jersey(CF(-100, 0, -84) * ALONG_Z, 8)
	T.container(CF(-82, 0, -46), "ContainerRed")
	T.cones(V(-74, 0, -76), V(-74, 0, -66), 4)
	-- Muelle cubierto (dentro): furgoneta, contenedores y persianas
	T.van(CF(-102, 0, -114), RGB(40, 92, 190))
	T.uld(CF(-84, 0, -122), "ContainerRed")
	T.uld(CF(-78, 0, -106) * CFrame.Angles(0, rad(20), 0), "ContainerBlue")
	T.crateStack(CF(-92, 0, -104), "L")
	for _, x in { -104, -91, -78 } do
		G.deco("RollerDoor", V(9, 7, 0.3), CF(x, 3.5, -129.8), "TerminalPanel")
	end
	local dockLamp = G.deco("DockLamp", V(16, 0.3, 0.6), CF(-91, L - 0.3, -113), { RGB(220, 236, 255), M.Neon })
	T.Kit.light(dockLamp, "PointLight", RGB(210, 230, 255), 22, 1)

	------------------------------------------------------------------
	-- PLATAFORMA A (mitad oeste): tren de equipaje y contenedor
	------------------------------------------------------------------
	T.baggageTrain(CF(-56, 0, -70) * CFrame.Angles(0, rad(-90), 0), 2)
	T.uld(CF(-36, 0, -46), "ContainerYellow")

	------------------------------------------------------------------
	-- PLATAFORMA (centro oeste): cisterna, contenedores, carros y focos
	------------------------------------------------------------------
	T.fuelTruck(CF(-58, 0, 10))
	T.uld(CF(-80, 0, -24), "ContainerBlue")
	T.uld(CF(-80, 5.4, -24) * CFrame.Angles(0, rad(6), 0), "ContainerGray")
	T.baggageCart(CF(-84, 0, 20) * CFrame.Angles(0, rad(90), 0), RGB(150, 60, 50))
	T.baggageCart(CF(-34, 0, -24) * CFrame.Angles(0, rad(10), 0), RGB(60, 90, 140))
	T.cones(V(-46, 0, -14), V(-46, 0, 14), 5)
	-- Deflectores de chorro delante del hangar (cortan la vista larga de la plataforma)
	T.blastFence(CF(-90, 0, -14) * CFrame.Angles(0, rad(90), 0), 14)
	T.blastFence(CF(-90, 0, 18) * CFrame.Angles(0, rad(90), 0), 10)
	T.baggageTrain(CF(-70, 0, 26) * CFrame.Angles(0, rad(-90), 0), 1)
	T.gpu(CF(-66, 0, -8))
	T.uld(CF(-50, 0, -32), "ContainerGray")
	T.apronLight(CF(-100, 0, -36) * CFrame.Angles(0, rad(-120), 0), 24)
	T.apronLight(CF(-100, 0, 36) * CFrame.Angles(0, rad(-60), 0), 24)

	------------------------------------------------------------------
	-- Sur: catering, contenedores y la valla del borde
	------------------------------------------------------------------
	T.van(CF(-52, 0, 62) * CFrame.Angles(0, rad(-10), 0), RGB(200, 60, 50))
	T.uld(CF(-76, 0, 96), "ContainerRed")
	T.uld(CF(-62, 0, 110) * CFrame.Angles(0, rad(30), 0), "ContainerBlue")
	T.container(CF(-92, 0, 106), "ContainerTan")
	T.cones(V(-66, 0, 84), V(-56, 0, 84), 4)
	T.sign(CF(-81, 9.5, 79.8) * CFrame.Angles(0, math.pi, 0), "CATERING", 10, 1.6, RGB(36, 44, 60), RGB(250, 250, 250), { PPS = 18 })
end

return Props
