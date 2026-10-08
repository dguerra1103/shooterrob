-- CONSTRUCCIÓN · props: coberturas con propósito (cada una corta una línea de tiro, protege una
-- salida o da dónde plantar) y decorado que da escala e identidad (grúa, estructuras rojas,
-- contenedores, palés de bloques, focos de obra). Lo que afecta al juego va en la mitad en espejo;
-- lo puramente decorativo puede ser asimétrico.
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local L = 10
local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0) -- (contenedores y casetas a lo largo de Z)

function Props.build(T)
	local G = T.G
	local night = T.isNight()

	---------------------------------------------------------------------------
	-- Cobertura en el eje (sirve igual a los dos equipos)
	---------------------------------------------------------------------------
	-- Plaza A: palé entre las dos salidas de la ESTRUCTURA y cajas detrás del sitio
	T.blockPallet(CF(0, 0, -77), 3)
	T.crateStack(CF(0, 0, -100) * CFrame.Angles(0, rad(180), 0), "L")
	-- Atrio B: fila de cajas que corta la vista desde el portón y cajas altas al fondo
	T.crateStack(CF(0, 0, 84), "Wall")
	T.crateStack(CF(0, 0, 106), "Tower")
	-- Entre la torre y la ESTRUCTURA: hormigonera (cobertura en el centro del paso)
	T.cementMixer(CF(0, 0, -30) * CFrame.Angles(0, rad(90), 0))
	-- Patio B, bajo la pasarela: tubos de hormigón
	T.pipeStack(CF(0, 0, 46) * ALONG_Z, 8)
	-- Tejado del ascensor: nada; segunda de la torre: palés como cobertura alta-baja
	T.blockPallet(CF(-8, 2 * L, 8), 2)
	T.blockPallet(CF(8, 2 * L, 8), 2)

	T.mirrored("ConstructionProps", function()
		Props.half(T)
	end)

	---------------------------------------------------------------------------
	-- Hitos: grúa torre sobre la torre, estructuras de acero rojo y lonas A / B
	---------------------------------------------------------------------------
	T.towerCrane(CF(0, 3 * L + 1, 0) * CFrame.Angles(0, rad(-30), 0), 50, { Jib = 60, Counter = 20, Drop = 38 })
	-- Remate de la torre: barandilla amarilla en la cubierta y foco de obra
	for _, p in { { V(-17, 31, -17), V(17, 31, -17) }, { V(-17, 31, 17), V(17, 31, 17) }, { V(-17, 31, -17), V(-17, 31, 17) }, { V(17, 31, -17), V(17, 31, 17) } } do
		G.railing(p[1], p[2], "Yellow", 2.6, { NoToe = true })
	end
	-- Estructura de acero roja sobre el edificio A (a un lado, como en la referencia)
	G.steelFrame(CF(-16, 2 * L + 8, -119), 3, 2, 8, 2, 7, "RedSteel", { Deco = true })
	for _, z in { -127, -111 } do
		G.railing(V(-28, 2 * L + 15, z), V(-4, 2 * L + 15, z), "Yellow", 2.6, { NoToe = true })
	end
	G.floor(CF(-16, 2 * L + 15, -119), 24, 16, "Plywood", 0.4).CanCollide = false
	-- Estructura roja más alta sobre el edificio B
	G.steelFrame(CF(18, 2 * L + 2, 100), 3, 3, 9, 2, 8, "RedSteel", { Deco = true })
	for _, lv in { 8, 16 } do
		G.railing(V(4.5, 2 * L + 2 + lv, 86.5), V(31.5, 2 * L + 2 + lv, 86.5), "Yellow", 2.6, { NoToe = true })
	end
	G.floor(CF(18, 2 * L + 10, 100), 27, 27, "Plywood", 0.4).CanCollide = false
	-- Lonas de los sitios en las fachadas (A roja, B azul) y letras grandes en las estructuras
	T.letterBanner(CF(0, 15, -107.3) * CFrame.Angles(0, math.pi, 0), "A", "Red", 9, 9)
	T.letterBanner(CF(-16, 2 * L + 14, -110.4) * CFrame.Angles(0, math.pi, 0), "A", "Red", 8, 9)
	T.letterBanner(CF(19.7, 16, 75.4), "B", "Blue", 8, 10)
	T.letterBanner(CF(18, 2 * L + 13, 85.9), "B", "Blue", 9, 10)
	-- Rótulos de la obra (la constructora y el número de licencia, sin marcas reales)
	T.sign(CF(0, 2 * L + 4, -107.3) * CFrame.Angles(0, math.pi, 0), "ROBUILD · OBRA 05", 14, 2.2, RGB(240, 186, 30), RGB(30, 30, 34), { PPS = 18 })
	T.sign(CF(0, 2 * L + 0.6, 75.4), "NUEVAS OFICINAS · 2027", 18, 2.4, RGB(36, 44, 60), RGB(244, 190, 40), { PPS = 18 })

	-- Azoteas: máquinas, depósitos, barandilla amarilla y un contenedor rojo en la nave B
	for _, x in { -22, 22 } do
		T.hvac(CF(x, 2 * L + 8, -124))
		T.hvac(CF(x * 0.5, 2 * L + 2, 118) * CFrame.Angles(0, rad(90), 0))
	end
	T.waterTank(CF(10, 2 * L + 8, -122))
	G.railing(V(-30, 2 * L + 8, -108.5), V(30, 2 * L + 8, -108.5), "Yellow", 2.6, { NoToe = true })
	local roofBox = T.container(CF(-20, 2 * L + 2, 116), "ContainerRed")
	for _, part in roofBox:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	T.hvac(CF(-78, 15.8, -8) * CFrame.Angles(0, rad(90), 0))
	T.hvac(CF(78, 15.8, 8) * CFrame.Angles(0, rad(90), 0))

	---------------------------------------------------------------------------
	-- Luz: focos de obra en patios y sitios, tubos fríos en el atrio B y cálidos en el A
	---------------------------------------------------------------------------
	T.floodTower(CF(-26, 0, -60) * CFrame.Angles(0, rad(150), 0), 16)
	T.floodTower(CF(26, 0, 60) * CFrame.Angles(0, rad(-30), 0), 16)
	for _, x in { -14, 14 } do
		local tube = G.deco("CeilingTube", V(0.5, 0.25, 10), CF(x, L - 0.4, -119), { RGB(255, 226, 180), M.Neon })
		T.Kit.light(tube, "PointLight", RGB(255, 214, 160), 16, 0.9)
	end
	for _, x in { -16, 0, 16 } do
		local tube = G.deco("AtriumTube", V(0.5, 0.25, 12), CF(x, 2 * L + 1.4, 112), { RGB(214, 236, 255), M.Neon })
		T.Kit.light(tube, "PointLight", RGB(200, 226, 255), 22, 1.1)
	end
	for _, z in { -8, 8 } do
		local tube = G.deco("TowerTube", V(10, 0.25, 0.5), CF(0, L - 0.4, z * 1.4), { RGB(255, 226, 180), M.Neon })
		T.Kit.light(tube, "PointLight", RGB(255, 214, 160), 14, 0.8)
	end

	---------------------------------------------------------------------------
	-- Suelo: rutas pintadas (amarillo, como el minimapa de la referencia) y franjas de peligro
	---------------------------------------------------------------------------
	for _, seg in {
		{ V(-110, 0, -33), V(-60, 0, -33) }, { V(-60, 0, -33), V(-55, 0, -70) },
		{ V(110, 0, -33), V(60, 0, -33) }, { V(60, 0, -33), V(55, 0, -70) },
		{ V(-110, 0, 33), V(-60, 0, 30) }, { V(110, 0, 33), V(60, 0, 30) },
		{ V(-60, 0, 30), V(-56, 0, 76) }, { V(60, 0, 30), V(56, 0, 76) },
		{ V(-45, 0, -12), V(45, 0, -12) }, { V(-24, 0, -20), V(-24, 0, 36) }, { V(24, 0, -20), V(24, 0, 36) },
	} do
		G.paintLine(seg[1] + V(0, 0, 0), seg[2], 0.6)
	end
	G.hazardStripes(CF(0, 0, 76.5), 14, 1.2)

	---------------------------------------------------------------------------
	-- Fondo: ciudad (bloques sin interior), sierra y otra grúa lejos
	---------------------------------------------------------------------------
	-- (Fase 14: ciudad industrial: hormigón, gris azulado y ladrillo, menos rosas pastel)
	local palette = { RGB(178, 176, 170), RGB(146, 152, 160), RGB(160, 112, 92), RGB(198, 188, 172), RGB(122, 128, 136) }
	-- (tres anillos: la manzana de alrededor baja, la ciudad media y unas pocas torres lejos)
	T.skylineRing(V(0, 0, 0), 205, 0, 355, 10, palette, { Lit = night, MinH = 16, VarH = 18, TowerEvery = 100, FloorH = 6 })
	T.skylineRing(V(0, 0, 0), 270, 4, 356, 12, palette, { Lit = night, MinH = 26, VarH = 34, TowerEvery = 5, TowerExtra = 40, FloorH = 8 })
	T.skylineRing(V(0, 0, 0), 380, 8, 352, 16, palette, { Lit = night, MinH = 40, VarH = 50, TowerEvery = 3, TowerExtra = 80, FloorH = 12 })
	-- Sierra lejana (la neblina la vuelve malva al atardecer)
	for _, spec in { { V(-520, -70, -380), 170 }, { V(120, -80, -640), 200 }, { V(640, -70, 120), 180 }, { V(-580, -80, 300), 190 }, { V(260, -60, 620), 160 } } do
		T.Kit.naturalHill(spec[1], spec[2], M.Rock)
	end
	T.towerCrane(CF(230, 0, -260) * CFrame.Angles(0, rad(40), 0), 90, { Jib = 60, Load = false, Brand = "ROBUILD" })
	T.towerCrane(CF(-280, 0, 220) * CFrame.Angles(0, rad(200), 0), 80, { Jib = 50, Load = false, Brand = "ROBUILD" })
end

-- Mitad del Rojo (X < 0): se copia en espejo para el Azul
function Props.half(T)
	local G = T.G

	------------------------------------------------------------------
	-- BASE: escudo de contenedores delante de la salida central, casetas y focos
	------------------------------------------------------------------
	T.container(CF(-103, 0, 0) * ALONG_Z, "ContainerGray", "ROBUILD · 05")
	T.cap(T.container(CF(-103, 8.8, 0.6) * CFrame.Angles(0, math.pi / 2 + rad(3), 0), "ContainerRed"))
	T.portacabin(CF(-136, 0, -40) * CFrame.Angles(0, math.pi, 0), nil, { Sign = "OFICINA DE OBRA" })
	T.cap(T.portacabin(CF(-136, 9.3, -40.4) * CFrame.Angles(0, math.pi + rad(1.5), 0), nil, {}))
	T.cap(T.portacabin(CF(-136, 0, 40), nil, { Sign = "VESTUARIOS" }))
	T.workLight(CF(-146, 0, -24) * CFrame.Angles(0, rad(-110), 0))
	T.workLight(CF(-146, 0, 24) * CFrame.Angles(0, rad(-70), 0))
	T.cones(V(-109, 0, -38), V(-109, 0, -28), 3)
	T.cones(V(-109, 0, 28), V(-109, 0, 38), 3)

	------------------------------------------------------------------
	-- CONTENEDORES (carril A): muro de contenedores que tapa la salida norte de la base, uno
	-- tumbado en medio (dos caminos) y otro que separa el carril del paso a la ESTRUCTURA
	------------------------------------------------------------------
	T.container(CF(-88, 0, -40) * ALONG_Z, "ContainerRed")
	T.cap(T.container(CF(-88, 8.8, -41) * CFrame.Angles(0, math.pi / 2 - rad(2), 0), "ContainerGray"))
	T.container(CF(-70, 0, -57), "ContainerRed")
	T.container(CF(-44, 0, -58) * ALONG_Z, "ContainerTan")
	T.crateStack(CF(-78, 0, -28) * CFrame.Angles(0, rad(8), 0), "L")
	T.crateStack(CF(-58, 0, -30) * CFrame.Angles(0, rad(90), 0), "Wall")
	T.blockPallet(CF(-76, 0, -66), 3)
	T.blockPallet(CF(-71.4, 0, -66), 2)
	T.barrel(CF(-92, 0, -66))
	T.barrel(CF(-90, 0, -67.5), { RGB(200, 60, 40), M.Metal })
	T.skip(CF(-62, 0, -44) * CFrame.Angles(0, rad(90), 0))
	T.sackPallet(CF(-80, 0, -24))
	T.cableSpool(CF(-92, 0, -24) * CFrame.Angles(0, rad(20), 0))
	-- Suelo del carril: asfalto de acceso con rodadas y manchas
	G.deco("AccessRoad", V(30, 0.05, 12), CF(-80, 0.03, -63), "Asphalt").CastShadow = false
	T.Kit.tireMarks(CF(-94, 0, -62) * CFrame.Angles(0, rad(-90), 0), 26, 0.2)
	T.Kit.oilStain(V(-74, 0, -45), 3)

	------------------------------------------------------------------
	-- ALMACÉN (fuera): chapa ondulada sobre zócalo de hormigón, portón con cajón de persiana y
	-- franjas de peligro, rótulo y apliques sobre las puertas
	------------------------------------------------------------------
	local function ribbedFace(a, b, outward, openings)
		local length = (b - a).Magnitude
		local dir = (b - a).Unit
		G.deco("Plinth", V(0.3, 2.4, length), CFrame.lookAt((a + b) / 2, b) * CF(0, 1.2, 0) + outward * 0.15, "ConcreteDark").CastShadow = false
		for d = 1.2, length - 1.2, 2.4 do
			local blocked = false
			for _, o in openings do
				if d > o[1] - 0.5 and d < o[2] + 0.5 then
					blocked = true
				end
			end
			if not blocked then
				local p = a + dir * d + outward * 0.2
				G.deco("WallRib", V(0.35, 12.6, 0.35), CF(p + V(0, 2.4 + 6.3, 0)), "SteelDark").CastShadow = false
			end
		end
	end
	ribbedFace(V(-95, 0, -20), V(-60, 0, -20), V(0, 0, -1), { { 22, 28 } })
	ribbedFace(V(-95, 0, 20), V(-60, 0, 20), V(0, 0, 1), { { 8, 14 } })
	ribbedFace(V(-95, 0, -20), V(-95, 0, 20), V(-1, 0, 0), { { 7, 13 }, { 27, 33 } })
	ribbedFace(V(-60, 0, -20), V(-60, 0, 20), V(1, 0, 0), { { 1, 7 }, { 24, 32 } })
	-- Portón (lado del patio): cajón de la persiana, persiana a medio subir y franjas en las jambas
	G.deco("ShutterBox", V(1.4, 1.6, 9.4), CF(-59.4, 9.8, 8), "SteelDark")
	G.deco("Shutter", V(0.25, 1.4, 8), CF(-59.6, 8.3, 8), "Corrugated")
	for _, z in { 3.6, 12.4 } do
		for k = 0, 3 do
			G.deco("JambStripe", V(0.5, 1, 0.9), CF(-59.6, 0.5 + k * 2, z), k % 2 == 0 and "YellowPaint" or "Black").CastShadow = false
		end
	end
	T.sign(CF(-59.6, 12.2, 8) * CFrame.Angles(0, -math.pi / 2, 0), "ALMACÉN · NAVE 2", 10, 1.6, RGB(36, 44, 60), RGB(244, 190, 40), { PPS = 18 })
	T.wallLamp(CF(-59.5, 7.6, -16) * CFrame.Angles(0, -math.pi / 2, 0))
	T.wallLamp(CF(-70, 8.6, -20.5))
	T.wallLamp(CF(-95.5, 8.6, 10) * CFrame.Angles(0, math.pi / 2, 0))
	T.wallLamp(CF(-95.5, 8.6, -10) * CFrame.Angles(0, math.pi / 2, 0))

	------------------------------------------------------------------
	-- ALMACÉN (dentro): cajas y palés que rompen la vista de puerta a puerta, carretilla y luz
	------------------------------------------------------------------
	T.crateStack(CF(-86, 0, -2), "Tower")
	T.crateStack(CF(-72, 0, -6) * CFrame.Angles(0, rad(90), 0), "L")
	T.blockPallet(CF(-80, 0, 12), 3)
	T.blockPallet(CF(-75.6, 0, 12), 2)
	T.Kit.forklift(CF(-68, 0, 14) * CFrame.Angles(0, rad(200), 0))
	G.scaffold(CF(-88, 0, -17), 8, 4, 2, 5, {})
	for _, z in { -10, 10 } do
		local tube = G.deco("WarehouseTube", V(12, 0.25, 0.5), CF(-77.5, 14.4, z), { RGB(255, 230, 190), M.Neon })
		T.Kit.light(tube, "PointLight", RGB(255, 220, 170), 18, 0.9)
	end

	------------------------------------------------------------------
	-- PATIO central: barrera junto al portón del almacén, palés y cajas (cobertura de paso)
	------------------------------------------------------------------
	T.jersey(CF(-46, 0, 2), 8)
	T.blockPallet(CF(-30, 0, -24), 3)
	T.blockPallet(CF(-25.6, 0, -24.4), 2)
	T.crateStack(CF(-32, 0, 14) * CFrame.Angles(0, rad(-10), 0), "L")
	T.rebarBundle(CF(-48, 0, 26) * CFrame.Angles(0, rad(80), 0), 10)
	T.cementMixer(CF(-52, 0, -24) * CFrame.Angles(0, rad(30), 0))
	T.cones(V(-20, 0, -18), V(-20, 0, -14), 2)
	T.sackPallet(CF(-38, 0, -30) * CFrame.Angles(0, rad(15), 0))
	T.cableSpool(CF(-24, 0, 24) * CFrame.Angles(0, rad(70), 0), 3.4)
	T.Kit.floorJoints(CF(-38, 0, 0), 44, 76, 8, RGB(132, 128, 120))
	T.Kit.crack(V(-36, 0, -6), 9, 4)
	T.Kit.oilStain(V(-50, 0, 12), 2.6)

	------------------------------------------------------------------
	-- PASILLO A y ESTRUCTURA: palés abajo, cajas y palés arriba (cobertura en la primera)
	------------------------------------------------------------------
	T.blockPallet(CF(-26, 0, -52), 3)
	T.crateStack(CF(-8, 0, -50) * CFrame.Angles(0, rad(90), 0), "L")
	T.blockPallet(CF(-10, L, -46), 2)
	T.crateStack(CF(-11, L, -62) * CFrame.Angles(0, rad(90), 0), "Wall")
	T.blockPallet(CF(-14, L, -40.5), 2)
	for _, z in { -46, -62 } do
		G.column(CF(-6, 0, z), L - 1, 1.4, "Concrete")
	end

	------------------------------------------------------------------
	-- ANDAMIOS: andamio en la fachada del bloque, cajas a la salida del túnel
	------------------------------------------------------------------
	G.scaffold(CF(-67, 0, -86) * ALONG_Z, 28, 4, 3, 5, {})
	T.cap(G.solid("Shed", V(13, 9, 18), CF(-41.5, 0, -79), "Plywood"))
	G.deco("ShedRoof", V(14, 0.5, 19), CF(-41.5, 9.2, -79), "SteelDark")
	T.blockPallet(CF(-66, 0, -104), 3)
	T.crate(CF(-42, 0, -96) * CFrame.Angles(0, rad(15), 0), 4)
	T.workLight(CF(-62, 0, -104) * CFrame.Angles(0, rad(-45), 0))

	------------------------------------------------------------------
	-- PLAZA A: contenedor rojo a cada lado del sitio (tres caminos) y palés junto a las paredes
	------------------------------------------------------------------
	T.container(CF(-16, 0, -86) * ALONG_Z, "ContainerRed")
	T.blockPallet(CF(-28, 0, -78), 3)
	T.crateStack(CF(-29, 0, -97), "Tower")
	T.barrel(CF(-33, 0, -84))
	T.cones(V(-24, 0, -100), V(-20, 0, -100), 2)
	T.Kit.floorJoints(CF(-17.5, 0, -88), 35, 36, 6, RGB(150, 144, 134))
	T.sackPallet(CF(-30, 0, -90) * CFrame.Angles(0, rad(-10), 0))
	T.wallLamp(CF(-12, 7.6, -107.5) * CFrame.Angles(0, math.pi, 0))

	------------------------------------------------------------------
	-- ACOPIO (carril B): palés de bloques en hileras, vigas, tubos, ferralla y silo
	------------------------------------------------------------------
	for i, p in { V(-74, 0, 40), V(-69.4, 0, 40), V(-74, 0, 44.6), V(-78.6, 0, 40) } do
		T.blockPallet(CF(p), i == 1 and 3 or 2)
	end
	T.beamStack(CF(-62, 0, 56) * ALONG_Z, 14)
	T.pipeStack(CF(-84, 0, 60), 8)
	T.rebarBundle(CF(-50, 0, 46), 10)
	T.rebarBundle(CF(-48.6, 0, 46.4), 9)
	T.crateStack(CF(-70, 0, 70) * CFrame.Angles(0, rad(-5), 0), "L")
	T.blockPallet(CF(-46, 0, 66), 3)
	T.skip(CF(-86, 0, 44))
	T.sackPallet(CF(-56, 0, 32))
	T.sackPallet(CF(-51.4, 0, 32.4) * CFrame.Angles(0, rad(8), 0))
	T.cableSpool(CF(-66, 0, 38))
	-- Suelo de tierra del acopio (el material se descarga aquí)
	G.deco("DirtPatch", V(40, 0.06, 34), CF(-72, 0.03, 56), "Dirt").CastShadow = false
	T.Kit.tireMarks(CF(-92, 0, 50) * CFrame.Angles(0, rad(-80), 0), 30, 0.3)
	-- Silo de cemento (decorado alto en la esquina)
	local siloShape = G.solid("SiloShape", V(7, 24, 7), CF(-90, 0, 70), "Steel")
	T.cap(siloShape)
	siloShape:Destroy()
	T.Kit.cylinder("Silo", 22, 7, CF(-90, 13, 70), RGB(220, 220, 216), M.Metal)
	T.Kit.cylinder("SiloLegs", 2, 7.2, CF(-90, 1, 70), RGB(90, 92, 98), M.Metal, nil, true)
	G.deco("SiloCone", V(4, 2, 4), CF(-90, 1.4, 70), "SteelDark")

	------------------------------------------------------------------
	-- MUELLE (oeste del B): camión de obra aparcado (cobertura alta) y cajas
	------------------------------------------------------------------
	G.solid("TruckBed", V(6, 4, 14), CF(-58, 0, 100), { RGB(220, 160, 30), M.Metal })
	G.solid("TruckCab", V(6, 6, 5), CF(-58, 0, 89.5), { RGB(220, 160, 30), M.Metal })
	G.deco("TruckGlass", V(5, 2, 0.2), CF(-58, 4.6, 86.9), { RGB(50, 64, 76), M.Glass })
	for _, z in { 90, 98, 104 } do
		for _, x in { -61.2, -54.8 } do
			T.Kit.pipe("TruckWheel", 0.9, 2.4, CF(x, 1.2, z), RGB(28, 28, 30), M.SmoothPlastic, true)
		end
	end
	T.crateStack(CF(-48, 0, 112), "L")
	T.blockPallet(CF(-66, 0, 114), 3)

	------------------------------------------------------------------
	-- EDIFICIO B (dentro, mitad oeste): palés bajo la entreplanta, cajas junto al sitio
	------------------------------------------------------------------
	T.crateStack(CF(-10, 0, 98) * CFrame.Angles(0, rad(90), 0), "L")
	T.blockPallet(CF(-29, 0, 92), 3)
	T.blockPallet(CF(-29, 0, 84), 2)
	T.crateStack(CF(-30, 0, 104), "Tower")
	T.blockPallet(CF(-30, L, 92), 2)
	T.crateStack(CF(-12, L, 116), "Wall")

	------------------------------------------------------------------
	-- PATIO B: carretilla y palés
	------------------------------------------------------------------
	T.Kit.forklift(CF(-22, 0, 60) * CFrame.Angles(0, rad(30), 0))
	T.blockPallet(CF(-28, 0, 44), 3)
	T.crateStack(CF(-14, 0, 68) * CFrame.Angles(0, rad(10), 0), "Wall")
	T.Kit.floorJoints(CF(-17.5, 0, 57), 35, 38, 8, RGB(140, 134, 126))
	T.skip(CF(-30, 0, 70) * CFrame.Angles(0, rad(90), 0))
	T.wallLamp(CF(-10, 7.6, 75.5))
end

return Props
