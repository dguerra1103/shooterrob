-- COSTA · props: cobertura con propósito (fuente y puestos en la plaza, barcas varadas y cajas de
-- pescado en el espigón, carros y cajas en el callejón, pozos y carro en la plaza alta) y el
-- decorado que da la personalidad (parras, ropa tendida, faroles, macetas, palmeras, barcas en el
-- agua, el faro en su islote y la ladera con casas).
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local UP = 6

-- Velero fondeado (decorado): casco, mástil y vela triangular
local function sailboat(T, cf, scale)
	scale = scale or 1
	local G = T.G
	G.deco("SailHull", V(4 * scale, 2 * scale, 14 * scale), cf * CF(0, 0.6 * scale, 0), { RGB(240, 240, 236), M.SmoothPlastic })
	G.deco("SailStripe", V(4.1 * scale, 0.5 * scale, 14.1 * scale), cf * CF(0, 1.2 * scale, 0), { RGB(40, 90, 170), M.SmoothPlastic })
	G.deco("SailMast", V(0.3, 14 * scale, 0.3), cf * CF(0, 8 * scale, -1 * scale), "Iron")
	T.wedge("Sail", V(0.15, 12 * scale, 7 * scale), cf * CF(0, 8 * scale, 2.6 * scale), { RGB(250, 248, 240), M.Fabric })
end

-- Ropa tendida entre dos puntos (decorado)
local function laundry(T, a, b)
	local G = T.G
	G.beam(a, b, 0.08, 0.08, "Iron", true)
	local colors = { RGB(220, 70, 60), RGB(250, 250, 245), RGB(70, 130, 200), RGB(240, 200, 70) }
	for i = 1, 4 do
		local p = a:Lerp(b, i / 5) - V(0, 0.9, 0)
		G.deco("Cloth", V(1.4, 1.6, 0.08), CFrame.lookAt(p, p + (b - a)) * CFrame.Angles(0, math.pi / 2, 0), { colors[i], M.Fabric })
	end
end

-- Arco sobre una calle (decorado): puente de casa a casa con parra colgando
local function streetArch(T, x, z0, z1, h, look)
	local G = T.G
	local cf = CF(x, h, (z0 + z1) / 2)
	G.deco("StreetArch", V(3, 2.4, z1 - z0), cf * CF(0, 1.2, 0), look)
	T.archCorners(cf * CFrame.Angles(0, math.pi / 2, 0), z1 - z0, 2, look, 3)
	-- Parra colgando (tiras finas y de largos distintos)
	for k = 0, math.floor((z1 - z0) * 0.6 / 1.2) do
		local len = 1.4 + (k * 37 % 10) / 6
		local z = z0 + (z1 - z0) * 0.2 + k * 1.2
		G.deco("Vine", V(0.5, len, 0.5), CF(x + 1.6, h - len / 2, z), { k % 2 == 0 and RGB(70, 140, 60) or RGB(96, 160, 70), M.LeafyGrass })
	end
end

function Props.build(T)
	local G = T.G
	local night = T.isNight()

	---------------------------------------------------------------------------
	-- Cobertura en el eje (sirve igual a los dos equipos)
	---------------------------------------------------------------------------
	T.fountain(CF(0, 0, 8), 12, RGB(40, 96, 170))
	-- Plaza alta: carro con cajas delante del ayuntamiento (cobertura del sitio A)
	G.solid("Cart", V(4, 2.4, 7), CF(0, UP + 0.6, -104), "Crate")
	for _, x in { -2.2, 2.2 } do
		T.Kit.pipe("CartWheel", 0.4, 2.6, CF(x, UP + 1.3, -104), RGB(90, 64, 40), M.Wood, true)
	end
	T.crate(CF(0.4, UP + 3, -105) * CFrame.Angles(0, rad(12), 0), 3)
	-- Espigón: cajas de pescado que cortan el paseo de punta a punta y el sitio B
	T.crateStack(CF(0, 0, 83) * CFrame.Angles(0, rad(90), 0), "Wall")
	T.crateStack(CF(0, 0, 112), "L")
	-- Lonja (dentro): mostradores de pescado (cobertura baja)
	for _, x in { -6, 6 } do
		G.box("FishCounter", V(4, 3, 8), CF(x, 1.5, 70), "Stone")
		G.deco("FishIce", V(3.6, 0.3, 7.6), CF(x, 3.1, 70), { RGB(220, 236, 244), M.Ice })
	end
	-- Bancos de la iglesia (cobertura baja) a los dos lados del pasillo central
	for _, z in { -34, -38, -42 } do
		for _, s in { -1, 1 } do
			G.box("Pew", V(8, 2.4, 1.4), CF(s * 8.5, 1.2, z), "Deck")
			G.deco("PewBack", V(8, 1.6, 0.3), CF(s * 8.5, 3.2, z + 0.6), "Deck")
		end
	end

	T.mirrored("CoastalProps", function()
		Props.half(T)
	end)

	---------------------------------------------------------------------------
	-- Lonas de los sitios y rótulos
	---------------------------------------------------------------------------
	T.letterBanner(CF(0, UP + 12, -111.4) * CFrame.Angles(0, math.pi, 0), "A", "Red", 7, 8)
	T.letterBanner(CF(0, 6, 61.3), "B", "Blue", 7, 6)
	T.letterBanner(CF(0, 4.6, 78.7) * CFrame.Angles(0, math.pi, 0), "B", "Blue", 5, 4.4)
	T.sign(CF(0, UP + 15, -111.6) * CFrame.Angles(0, math.pi, 0), "AYUNTAMIENTO", 16, 1.6, RGB(236, 226, 206), RGB(120, 60, 40), { PPS = 18 })
	T.sign(CF(0, 7.6, 61.2), "LONJA", 9, 1.4, RGB(236, 226, 206), RGB(40, 70, 120), { PPS = 18 })

	---------------------------------------------------------------------------
	-- Luz: faroles en las fachadas, farolas en la plaza y el paseo
	---------------------------------------------------------------------------
	for _, x in { -20, 20 } do
		T.streetLight(CF(x, 0, 24))
		T.streetLight(CF(x, 0, -14))
	end
	T.lantern(CF(-6, UP + 6.5, -111.6) * CFrame.Angles(0, math.pi, 0))
	T.lantern(CF(6, UP + 6.5, -111.6) * CFrame.Angles(0, math.pi, 0))
	T.lantern(CF(-9, 5.5, 61.2))
	T.lantern(CF(9, 5.5, 61.2))

	---------------------------------------------------------------------------
	-- Fondo: ladera con casas al norte, el faro en su islote, islas, veleros y sierra
	---------------------------------------------------------------------------
	local houseColors = { RGB(238, 232, 220), RGB(226, 204, 164), RGB(204, 112, 80), RGB(216, 168, 96), RGB(222, 176, 160) }
	-- (la isla sube por detrás del pueblo y la sierra queda lejos, azulada por la neblina)
	for _, spec in { { V(0, -40, -300), 90 }, { V(-170, -40, -280), 80 }, { V(170, -40, -290), 84 }, { V(-420, -60, -380), 150 }, { V(380, -70, -420), 160 } } do
		T.Kit.naturalHill(spec[1], spec[2], M.Rock, { Top = M.Grass, TopCount = 4 })
	end
	local i = 0
	for x = -230, 230, 22 do
		for _, zBase in { -150, -172, -194 } do
			i += 1
			local z = zBase + (i * 7) % 9
			local terrace = (zBase + 150) * -0.45 + 6
			local w, d, h = 14 + (i * 5) % 6, 12 + (i * 3) % 5, 9 + (i * 7) % 8
			local color = houseColors[(i % #houseColors) + 1]
			local body = G.deco("HillHouse", V(w, h, d), CF(x + (i % 3) * 3, terrace + h / 2, z), { color, M.Plaster })
			body.CastShadow = false
			local roof = G.deco("HillRoof", V(w + 1, 1, d + 1), CF(x + (i % 3) * 3, terrace + h + 0.4, z), i % 3 == 0 and { color:Lerp(Color3.new(0, 0, 0), 0.15), M.Plaster } or "RoofTile")
			roof.CastShadow = false
			if night and i % 2 == 0 then
				G.deco("HillWindow", V(2, 1.6, 0.1), CF(x + (i % 3) * 3, terrace + h * 0.55, z + d / 2 + 0.05), { RGB(230, 180, 110), M.Neon }).CastShadow = false
			end
		end
	end
	-- (Fase 3: el faro, más cerca y más alto: hito visible desde el paseo y el espigón)
	T.Kit.lighthouse(V(120, 0, 230), 1.3)
	T.Kit.naturalHill(V(-200, -40, 420), 90, M.Rock, { Top = M.Grass })
	T.Kit.naturalHill(V(300, -50, 260), 80, M.Rock)
	T.Kit.naturalHill(V(-420, -60, 120), 110, M.Rock, { Top = M.Grass })
	T.Kit.naturalHill(V(440, -60, -40), 120, M.Rock, { Top = M.Grass })
	sailboat(T, CF(-60, -3, 230) * CFrame.Angles(0, rad(30), 0), 1.4)
	sailboat(T, CF(80, -3, 190) * CFrame.Angles(0, rad(-60), 0), 1.1)
	sailboat(T, CF(230, -3, 120) * CFrame.Angles(0, rad(10), 0), 1.2)
	-- (de noche el faro alumbra)
	if night then
		local beam = G.deco("LighthouseGlow", V(2, 2, 2), CF(120, 48, 230), { RGB(255, 240, 200), M.Neon })
		T.Kit.light(beam, "PointLight", RGB(255, 236, 190), 60, 2)
	end
end

-- Mitad del Rojo (X < 0): se copia en espejo para el Azul
function Props.half(T)
	local G = T.G

	------------------------------------------------------------------
	-- BASE: naranjos, bancos, farol
	------------------------------------------------------------------
	T.tree(CF(-144, 0, -36))
	T.tree(CF(-144, 0, 36))
	T.lantern(CF(-113.2, 7, -20) * CFrame.Angles(0, math.pi / 2, 0))
	T.lantern(CF(-113.2, 7, 20) * CFrame.Angles(0, math.pi / 2, 0))

	------------------------------------------------------------------
	-- CALLEJÓN: carro, cajas, barriles, macetas, arcos con parra y ropa tendida
	------------------------------------------------------------------
	G.solid("Cart", V(4, 2.4, 7), CF(-92, 0.6, -36) * CFrame.Angles(0, rad(80), 0), "Crate")
	T.crate(CF(-90.5, 3, -36) * CFrame.Angles(0, rad(20), 0), 3)
	T.crateStack(CF(-56, 0, -40) * CFrame.Angles(0, rad(-8), 0), "L")
	T.barrel(CF(-82, 0, -27), { RGB(120, 84, 52), M.Wood })
	T.barrel(CF(-80.4, 0, -28.2), { RGB(120, 84, 52), M.Wood })
	T.Kit.flowerPot(CF(-104, 0, -44.5), RGB(230, 60, 90))
	T.Kit.flowerPot(CF(-62, 0, -44.5), RGB(250, 200, 70))
	T.Kit.flowerPot(CF(-48, 0, -25.5), RGB(230, 60, 90))
	streetArch(T, -96, -46, -24, 9, "Sand")
	streetArch(T, -46, -46, -24, 9.5, "Ochre")
	laundry(T, V(-84, 10, -46.2), V(-84, 9.6, -24.2))
	laundry(T, V(-60, 10.5, -46.2), V(-60, 10, -24.2))
	T.lantern(CF(-100, 7, -45.6) * CFrame.Angles(0, math.pi, 0))
	T.lantern(CF(-70, 7, -24.4))

	------------------------------------------------------------------
	-- Suelo: adoquín en el callejón y la calle mayor, juntas de losa en la plaza y el espigón
	------------------------------------------------------------------
	G.deco("Cobbles", V(72, 0.05, 22), CF(-76, 0.03, -35), "Cobble").CastShadow = false
	G.deco("Cobbles", V(76, 0.05, 16), CF(-74, 0.03, -2), "Cobble").CastShadow = false
	T.Kit.floorJoints(CF(-15, 0, 0), 30, 60, 5, RGB(176, 164, 144))
	T.Kit.floorJoints(CF(-20, 0, 98), 40, 40, 4, RGB(132, 126, 116))

	------------------------------------------------------------------
	-- CALLE MAYOR: terrazas, puesto y toldos
	------------------------------------------------------------------
	T.cafeTable(CF(-84, 0, -5), RGB(200, 60, 50))
	T.cafeTable(CF(-76, 0, 2), RGB(60, 110, 170))
	T.stall(CF(-98, 0, 3) * CFrame.Angles(0, rad(180), 0), RGB(200, 60, 50), 6)
	T.Kit.awning(CF(-90, 8, 5.6) * CFrame.Angles(0, math.pi, 0), 9, 3, RGB(200, 60, 50))
	T.Kit.awning(CF(-48, 8, 5.6) * CFrame.Angles(0, math.pi, 0), 9, 3, RGB(40, 120, 90))
	T.Kit.flowerPot(CF(-62, 0, -8.5), RGB(230, 60, 90))
	T.lantern(CF(-70, 7, 5.6) * CFrame.Angles(0, math.pi, 0))

	------------------------------------------------------------------
	-- PLAZA: puestos con toldo a rayas, mesas de café, palmeras y bancos
	------------------------------------------------------------------
	T.stall(CF(-16, 0, -6) * CFrame.Angles(0, rad(-90), 0), RGB(200, 60, 50), 6)
	T.stall(CF(-18, 0, 20) * CFrame.Angles(0, rad(-90), 0), RGB(40, 110, 180), 6)
	T.cafeTable(CF(-24, 0, 6), RGB(240, 200, 70))
	T.palm(CF(-26, 0, -24), 15)
	T.palm(CF(-26, 0, 27), 13)
	G.box("Bench", V(5, 1.4, 1.6), CF(-10, 0.7, 26), "Deck")
	-- Plazuela: olivo en su alcorque y un banco
	T.planter(CF(-34, 0, -38) * CFrame.Angles(0, rad(90), 0), 6, 3)
	G.box("Bench", V(1.6, 1.4, 5), CF(-38, 0.7, -52), "Deck")

	------------------------------------------------------------------
	-- PASEO MARÍTIMO: palmeras, bancos, quiosco, redes y barcas
	------------------------------------------------------------------
	for x = -104, -48, 14 do
		T.palm(CF(x, 0, 80), 13 + (x % 3))
		G.box("Bench", V(5, 1.4, 1.6), CF(x + 7, 0.7, 82), "Deck")
		T.bollard(CF(x + 3, 0, 84))
		T.tire(CF(x + 3, -1.2, 85.4))
	end
	T.cap(G.solid("Kiosk", V(5, 7, 5), CF(-78, 0, 64), "Shutter"))
	G.deco("KioskRoof", V(6.4, 0.6, 6.4), CF(-78, 7.3, 64), "RoofTile")
	T.crateStack(CF(-60, 0, 70) * CFrame.Angles(0, rad(15), 0), "L")
	G.deco("Nets", V(4, 0.8, 3), CF(-94, 0.4, 66), { RGB(70, 90, 70), M.Fabric })
	T.barrel(CF(-90, 0, 70), { RGB(40, 90, 160), M.Metal })
	T.rowboat(CF(-90, -2.6, 100) * CFrame.Angles(0, rad(20), 0), RGB(240, 240, 236))
	T.rowboat(CF(-68, -2.6, 104) * CFrame.Angles(0, rad(-30), 0), RGB(70, 130, 190))
	T.Kit.boat(CF(-80, -3.4, 116) * CFrame.Angles(0, rad(80), 0))
	T.streetLight(CF(-96, 0, 83))
	T.streetLight(CF(-62, 0, 83))

	------------------------------------------------------------------
	-- ESPIGÓN (mitad oeste): barca varada sobre calzos (cobertura alta), cajas, redes, bolardos
	------------------------------------------------------------------
	local boat = CF(-22, 0, 104) * CFrame.Angles(0, rad(8), 0)
	T.cap(G.solid("DryBoat", V(5, 4.6, 13), boat * CF(0, 0.8, 0), "Deck"))
	G.deco("DryBoatStripe", V(5.1, 0.6, 13.1), boat * CF(0, 4.6, 0), "Red")
	for _, z in { -4, 4 } do
		G.deco("BoatChock", V(4, 0.8, 1), boat * CF(0, 0.4, z), "WoodDark")
	end
	T.crateStack(CF(-12, 0, 112) * CFrame.Angles(0, rad(5), 0), "Tower")
	T.crate(CF(-30, 0, 92) * CFrame.Angles(0, rad(25), 0), 4)
	T.barrel(CF(-34, 0, 100), { RGB(40, 90, 160), M.Metal })
	G.deco("Nets", V(5, 0.7, 3), CF(-30, 0.35, 114), { RGB(80, 100, 70), M.Fabric })
	for z = 90, 114, 8 do
		T.bollard(CF(-38.6, 0, z))
		T.tire(CF(-41, -1.2, z) * CFrame.Angles(0, rad(90), 0))
	end
	T.bollard(CF(-20, 0, 116.4))

	------------------------------------------------------------------
	-- Entre la plaza y el puerto
	------------------------------------------------------------------
	T.crateStack(CF(-25, 0, 70) * CFrame.Angles(0, rad(90), 0), "L")
	T.barrel(CF(-36, 0, 56), { RGB(120, 84, 52), M.Wood })
	T.Kit.flowerPot(CF(-31, 0, 40), RGB(230, 60, 90))

	------------------------------------------------------------------
	-- PARTE ALTA: macetas y bancos del mirador, pozo y puesto en la plaza alta, ropa tendida
	------------------------------------------------------------------
	G.box("Bench", V(5, 1.4, 1.6), CF(-52, UP + 0.7, -64.6), "Deck")
	T.Kit.flowerPot(CF(-38, UP, -65), RGB(230, 60, 90))
	T.Kit.flowerPot(CF(-62, UP, -78), RGB(250, 200, 70))
	T.palm(CF(-40, UP, -76), 12)
	-- Pozo (cobertura baja y redonda)
	T.Kit.cylinder("Well", 2.6, 5, CF(-18, UP + 1.3, -100), RGB(186, 174, 152), M.Limestone)
	for _, s in { -1, 1 } do
		G.deco("WellPost", V(0.4, 5, 0.4), CF(-18 + s * 2, UP + 4, -100), "WoodDark")
	end
	G.deco("WellBeam", V(4.6, 0.4, 0.4), CF(-18, UP + 6.4, -100), "WoodDark")
	T.stall(CF(-38, UP, -100) * CFrame.Angles(0, rad(90), 0), RGB(240, 200, 70), 6)
	T.crateStack(CF(-28, UP, -94) * CFrame.Angles(0, rad(30), 0), "L")
	T.planter(CF(-36, UP, -110), 6, 3)
	laundry(T, V(-46.2, UP + 9, -100), V(-46.2, UP + 9, -92))
end

return Props
