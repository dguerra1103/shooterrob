-- CONSTRUCCIÓN · geometría jugable (blockout): suelos, edificios, escaleras, pasarelas y bordes.
-- Plano (X = de base a base, el Rojo en -X; Z = de sitio a sitio, A en -Z):
--
--   z -130 ┌──────── EDIFICIO A (terraza en la 1ª planta, lona A) ────────┐
--          │ ANDAMIOS │            PLAZA A  (sitio A)             │ ANDAMIOS│
--   z  -70 │──────────┴─────── ESTRUCTURA (forjado en la 1ª) ──────┴─────────│
--          │ CONTENEDORES           │                    │      CONTENEDORES │
--   BASE ──┤ ALMACÉN ─── PATIO ── TORRE (3 alturas + grúa) ── PATIO ─── ALMACÉN ├── BASE
--   ROJA   │ ACOPIO                 │                    │            ACOPIO │  AZUL
--   z   76 │──────── MUELLE ───┬──────── PATIO B ────────┬───── MUELLE ──────│
--          │                   │  EDIFICIO B (sitio B dentro, entreplanta)  │
--   z  130 └────────────────────────────────────────────────────────────────┘
--
-- Alturas: suelo (0), primera (10: torre, ESTRUCTURA, terraza A, entreplanta B y las pasarelas
-- que las unen) y la segunda de la torre (20, posición alta expuesta). Simétrico en X = 0.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local L = 10 -- altura de planta

function Geometry.build(T)
	local G = T.G
	local door, window = G.door, G.window

	---------------------------------------------------------------------------
	-- Suelo
	---------------------------------------------------------------------------
	T.terrain(Enum.Material.Concrete, 1100, 1100, CF(0, -0.3, 0))
	G.floor(CF(0, 0, 0), 300, 260, "Ground", 1)

	---------------------------------------------------------------------------
	-- TORRE central (32 x 32): planta baja de paso (puertas este/oeste), primera con las pasarelas
	-- norte y sur, segunda abierta con barandillas y el remate de hormigón con la grúa encima.
	-- El hueco del ascensor (8 x 8) corta las líneas de tiro de lado a lado.
	---------------------------------------------------------------------------
	local tower = CF(0, 0, 0)
	G.solid("TowerShaft", V(8, 31, 8), tower, "ConcreteDark")
	-- Planta baja: muros con puertas al este y al oeste
	G.shell(tower, 32, 32, L, "Concrete", {
		Left = { door(-9) },
		Right = { door(-9) },
	}, { Frame = "ConcreteDark" })
	-- Primera: puertas a las pasarelas (norte y sur) y ventanales sobre el patio (este y oeste)
	G.shell(tower * CF(0, L, 0), 32, 32, L, "Concrete", {
		Front = { door(0, 6, 8) },
		Back = { door(0, 6, 8) },
		Left = { window(-7, 3, 6, 4), window(7, 3, 6, 4) },
		Right = { window(-7, 3, 6, 4), window(7, 3, 6, 4) },
	}, { Frame = "ConcreteDark" })
	-- Forjados: primera (hueco sobre las escaleras de subida), segunda (huecos de las de arriba) y
	-- cubierta
	G.slab(tower * CF(0, L, 0), 30, 30, "Slab", {
		{ -13, -1, 4, 10 }, { 13, -1, 4, 10 },
	})
	G.slab(tower * CF(0, 2 * L, 0), 32, 32, "Slab", {
		{ -5.2, -12, 8.4, 4.2 }, { 5.2, -12, 8.4, 4.2 },
	})
	T.cap(G.floor(tower * CF(0, 3 * L + 1, 0), 34, 34, "Concrete", 1))
	-- Escaleras: de la baja a la primera por los laterales; de la primera a la segunda, dos tramos
	-- por el lado norte que suben hacia el centro
	for _, s in { -1, 1 } do
		G.stairs(V(s * 13, 0, 10), V(s * 13, L, -6), 4, "Concrete", { Rails = s < 0 and "Right" or "Left" })
		G.stairs(V(s * 15, L, -12), V(s * 1.2, 2 * L, -12), 4, "Concrete", {})
	end
	-- Segunda: abierta, pilares en las esquinas y en el centro de cada cara y barandilla
	for _, p in { V(-15.2, 0, -15.2), V(15.2, 0, -15.2), V(-15.2, 0, 15.2), V(15.2, 0, 15.2), V(0, 0, 15.2), V(-15.2, 0, 0), V(15.2, 0, 0) } do
		G.column(tower * CF(p + V(0, 2 * L, 0)), L + 1, 1.6, "Concrete")
	end
	G.column(tower * CF(-6, 2 * L, -15.2), L + 1, 1.6, "Concrete")
	G.column(tower * CF(6, 2 * L, -15.2), L + 1, 1.6, "Concrete")
	local y2 = 2 * L
	G.railing(V(-15.6, y2, -15.6), V(15.6, y2, -15.6))
	G.railing(V(-15.6, y2, 15.6), V(15.6, y2, 15.6))
	G.railing(V(-15.6, y2, -15.6), V(-15.6, y2, 15.6))
	G.railing(V(15.6, y2, -15.6), V(15.6, y2, 15.6))
	-- Obra vista: pilares en las esquinas, cantos de forjado y dos plantas más sin terminar encima
	-- (pilares, forjado y barandilla, decorado) para la silueta alta de la referencia
	for _, p in { V(-15.6, 0, -15.6), V(15.6, 0, -15.6), V(-15.6, 0, 15.6), V(15.6, 0, 15.6) } do
		G.box("TowerPier", V(2.4, 3 * L + 1, 2.4), CF(p + V(0, (3 * L + 1) / 2, 0)), "Concrete")
		for _, y in { 3 * L + 1, 4 * L + 1 } do
			G.deco("UpperColumn", V(1.6, L, 1.6), CF(p + V(0, y + L / 2, 0)), "Concrete")
		end
	end
	for _, y in { L, 2 * L } do
		G.deco("SlabEdge", V(33.2, 0.9, 33.2), CF(0, y - 0.45, 0), "Slab").CastShadow = false
	end
	G.deco("UpperSlab", V(33, 0.8, 33), CF(0, 4 * L + 0.6, 0), "Slab")
	G.deco("UpperSlab", V(20, 0.8, 33), CF(-6.5, 5 * L + 0.6, 0), "Slab")
	for _, y in { 4 * L + 1, 5 * L + 1 } do
		G.deco("UpperRail", V(33, 0.3, 0.3), CF(0, y + 3, -16.4), "Yellow")
		G.deco("UpperRail", V(33, 0.3, 0.3), CF(0, y + 3, 16.4), "Yellow")
	end
	T.hoist(CF(-19, 0, 8), 4 * L + 4)
	-- Barandillas de los huecos de la primera (para no caer por el hueco de la escalera)
	for _, s in { -1, 1 } do
		G.railing(V(s * 11, L, -6), V(s * 11, L, 4))
		G.railing(V(s * 1.2, 2 * L, -10), V(s * 9.4, 2 * L, -10))
	end

	---------------------------------------------------------------------------
	-- ESTRUCTURA (36 x 32, entre la torre y la plaza A): obra de hormigón sin terminar. Abajo,
	-- paso con pilares y núcleo de escalera macizo; arriba, el forjado que une las pasarelas.
	---------------------------------------------------------------------------
	local est = CF(0, 0, -54)
	T.cap(G.solid("EstCore", V(6, 18, 10), est * CF(0, 0, -7), "ConcreteDark"))
	G.shell(est, 36, 32, L - 1, "Concrete", {
		Front = { door(-9, 6, 8), door(9, 6, 8) }, -- (cara sur, a la plaza)
		Back = { door(-9, 6, 8), door(9, 6, 8) }, -- (cara norte, al patio)
		Left = { door(-8, 6, 8) },
		Right = { door(-8, 6, 8) },
	}, { Frame = "ConcreteDark" })
	G.slab(est * CF(0, L, 0), 36, 32, "Slab", {
		{ -15, 2, 4.2, 12 }, { 15, 2, 4.2, 12 },
	})
	for _, s in { -1, 1 } do
		G.stairs(V(s * 15, 0, -42), V(s * 15, L, -58), 4, "Concrete", { Rails = s < 0 and "Right" or "Left" })
	end
	-- Pilares que siguen hacia arriba (obra a medias) y barandilla del forjado
	for _, x in { -17.4, -6, 6, 17.4 } do
		for _, z in { -69.4, -54, -38.6 } do
			T.cap(G.column(CF(x, L, z), 8, 1.4, "Concrete"))
			for i = 0, 2 do
				G.deco("Rebar", V(0.18, 2.4, 0.18), CF(x - 0.4 + i * 0.4, L + 9.1, z), { Color3.fromRGB(120, 66, 42), Enum.Material.CorrodedMetal })
			end
		end
	end
	for _, s in { -1, 1 } do
		G.railing(V(s * 18, L, -38.4), V(s * 3.2, L, -38.4))
		G.railing(V(s * 18, L, -69.6), V(s * 3.2, L, -69.6))
		G.railing(V(s * 17.6, L, -69.6), V(s * 17.6, L, -38.4))
		-- (borde del hueco de la escalera)
		G.railing(V(s * 12.8, L, -46), V(s * 12.8, L, -58))
		G.railing(V(s * 12.8, L, -45.8), V(s * 17.4, L, -45.8))
	end

	---------------------------------------------------------------------------
	-- Pasarelas de la primera: torre ↔ ESTRUCTURA ↔ terraza A y torre ↔ edificio B
	---------------------------------------------------------------------------
	G.walkway(V(0, L, -16), V(0, L, -38), 6, { Supports = 11 })
	G.walkway(V(0, L, -70), V(0, L, -102), 6, { Supports = 11 })
	G.walkway(V(0, L, 16), V(0, L, 76), 6, { Supports = 15 })

	---------------------------------------------------------------------------
	-- EDIFICIO A (60 x 22, al fondo de la plaza): oficinas abajo, primera con puertas a la terraza
	-- y una planta más (cerrada) arriba. Terraza de 6 de fondo a lo largo de la fachada.
	---------------------------------------------------------------------------
	local a = CF(0, 0, -119) * CFrame.Angles(0, math.pi, 0) -- (la "cara" mira a la plaza, +Z)
	G.shell(a, 60, 22, L, "ConcreteWarm", {
		Front = { door(-12), door(12), window(-22, 3.5, 4, 3.5), window(22, 3.5, 4, 3.5) },
	}, { Frame = "ConcreteDark" })
	G.shell(a * CF(0, L, 0), 60, 22, L, "ConcreteWarm", {
		Front = { door(-12, 6, 8), door(12, 6, 8), window(-22, 3, 4, 4), window(22, 3, 4, 4) },
	}, { Frame = "ConcreteDark" })
	G.shell(a * CF(0, 2 * L, 0), 60, 22, 7, "ConcreteWarm", {
		Front = { window(-22, 2, 4, 3), window(-12, 2, 4, 3), window(12, 2, 4, 3), window(22, 2, 4, 3) },
	}, { Frame = "ConcreteDark" })
	G.slab(CF(0, L, -119), 58, 20, "Slab", { { -25, 5, 4.4, 10 }, { 25, 5, 4.4, 10 } })
	G.floor(CF(0, 2 * L, -119), 58, 20, "Slab")
	T.cap(G.floor(CF(0, 2 * L + 7.5, -119), 61, 23, "ConcreteDark", 1))
	for _, s in { -1, 1 } do
		-- (sube hacia la fachada; arriba se sale de lado a la primera)
		G.stairs(V(s * 25, 0, -125), V(s * 25, L, -110), 4, "Concrete", { Rails = s > 0 and "Right" or "Left" })
		G.railing(V(s * 22.8, L, -119), V(s * 22.8, L, -111.2))
	end
	-- Terraza (primera) delante de la fachada, más ancha que el edificio: llegan las escaleras de
	-- los lados y la pasarela de la ESTRUCTURA
	G.floor(CF(0, L, -105), 72, 6, "Slab", 0.8)
	for _, s in { -1, 1 } do
		G.railing(V(s * 36, L, -101.8), V(s * 3.2, L, -101.8))
		G.deco("TerraceBeam", V(1, 1, 6), CF(s * 34, L - 1.3, -105), "ConcreteDark")
		G.column(CF(s * 34, 0, -102.6), L - 0.8, 1.2, "ConcreteDark", "TerraceColumn")
	end

	---------------------------------------------------------------------------
	-- EDIFICIO B (72 x 48): sitio B dentro, en un atrio de dos alturas; entreplanta en U alrededor
	-- (lados y fondo) y pasillo delantero donde llega la pasarela de la torre.
	---------------------------------------------------------------------------
	local b = CF(0, 0, 100)
	G.shell(b, 72, 48, L, "Concrete", {
		Front = { door(0, 14, 8), window(-24, 3.5, 6, 3.5), window(24, 3.5, 6, 3.5) },
		Back = { window(-20, 4, 6, 3), window(20, 4, 6, 3) },
		Left = { door(16) },
		Right = { door(16) },
	}, { Frame = "ConcreteDark" })
	G.shell(b * CF(0, L, 0), 72, 48, 12, "Concrete", {
		Front = { door(0, 6, 8), window(-12, 3, 5, 4), window(12, 3, 5, 4), window(-27, 3, 5, 4), window(27, 3, 5, 4) },
		Back = { window(-20, 3, 6, 4), window(0, 3, 6, 4), window(20, 3, 6, 4) },
		Left = { door(4, 6, 8), window(-12, 3, 4, 4) },
		Right = { door(4, 6, 8), window(-12, 3, 4, 4) },
	}, { Frame = "ConcreteDark" })
	-- Entreplanta (primera): lados, fondo y pasillo delantero; el atrio queda abierto
	for _, s in { -1, 1 } do
		G.floor(CF(s * 29.5, L, 100), 11, 46, "Slab")
		G.railing(V(s * 24, L, 81), V(s * 24, L, 108))
		G.stairs(V(s * 18, 0, 91), V(s * 18, L, 107.6), 4, "Concrete", { Rails = "Both" })
		G.railing(V(s * 20.2, L, 108), V(s * 24, L, 108))
	end
	G.railing(V(-24, L, 81), V(24, L, 81))
	G.railing(V(-15.8, L, 108), V(15.8, L, 108)) -- (entre las dos escaleras)
	G.floor(CF(0, L, 116), 48, 16, "Slab")
	G.floor(CF(0, L, 79), 48, 4, "Slab")
	-- Cubierta con lucernario sobre el atrio
	T.cap(G.slab(CF(0, 2 * L + 2, 100), 72, 48, "ConcreteDark", { { 0, -4, 40, 22 } }))
	for i = -2, 2 do
		local pane = G.deco("Skylight", V(7.6, 0.3, 21.6), CF(i * 8, 2 * L + 1.7, 96), "Glass")
		pane.Transparency = 0.55
		G.deco("SkylightBar", V(0.4, 0.5, 22), CF(i * 8 + 4, 2 * L + 1.8, 96), "SteelDark")
	end
	-- Pilares del atrio
	for _, x in { -12, 12 } do
		for _, z in { 88, 112 } do
			G.column(CF(x, 0, z), L, 1.4, "ConcreteDark")
		end
	end

	---------------------------------------------------------------------------
	-- Una mitad (la del Rojo) que se copia en espejo para el Azul
	---------------------------------------------------------------------------
	T.mirrored("ConstructionHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0): base, almacén, carriles, andamios, muelle y bordes
function Geometry.half(T)
	local G = T.G
	local door, window = G.door, G.window
	-- (vallas, tapias y bloques del borde no se pisan: se tapan por arriba)
	local function hoarding(a, b, h)
		return T.cap(G.hoarding(a, b, h))
	end

	------------------------------------------------------------------
	-- BASE: recinto de obra con casetas; tres salidas (norte, centro en zigzag y sur)
	------------------------------------------------------------------
	hoarding(V(-150, 0, -50), V(-150, 0, 50), 14)
	hoarding(V(-150, 0, -50), V(-95, 0, -50), 12)
	hoarding(V(-150, 0, 50), V(-95, 0, 50), 12)
	-- Frente de la base (x = -112): huecos en z ±(26..40) y en el centro (z ±4)
	hoarding(V(-112, 0, -26), V(-112, 0, -4), 10)
	hoarding(V(-112, 0, 4), V(-112, 0, 26), 10)
	hoarding(V(-112, 0, -50), V(-112, 0, -40), 10)
	hoarding(V(-112, 0, 40), V(-112, 0, 50), 10)

	------------------------------------------------------------------
	-- ALMACÉN (35 x 40): nave de paso entre la base y el patio, sin subir al tejado
	------------------------------------------------------------------
	local wh = CF(-77.5, 0, 0)
	G.shell(wh, 35, 40, 15, "Corrugated", {
		Front = { door(7.5) }, -- (cara norte, al carril A: X del edificio)
		Back = { door(-6.5) }, -- (cara sur, al acopio)
		Left = { door(-10), door(10) }, -- (oeste, a la base)
		Right = { door(8, 8, 9), door(-16) }, -- (este, al patio)
	}, { Frame = "Concrete" })
	T.cap(G.floor(wh * CF(0, 15.8, 0), 36, 41, "Hoarding", 0.8))
	G.deco("RoofEdge", V(36.2, 0.6, 41.2), wh * CF(0, 15.1, 0), "SteelDark")

	------------------------------------------------------------------
	-- Bordes de los carriles y de las plazas
	------------------------------------------------------------------
	-- Pared oeste de la plaza A (con la entrada principal en z -100..-88) y cierre norte
	T.cap(G.wall(CF(-35, 0, -104) * CFrame.Angles(0, -math.pi / 2, 0), 8, 8, "Concrete"))
	T.cap(G.wall(CF(-35, 0, -79) * CFrame.Angles(0, -math.pi / 2, 0), 18, 8, "Concrete"))
	T.cap(G.wall(CF(-26.5, 0, -70), 17, 8, "Concrete"))
	-- Túnel de andamios (ANDAMIOS): de los contenedores a la entrada de la plaza A
	hoarding(V(-70, 0, -70), V(-62, 0, -70), 10)
	T.cap(G.box("TunnelRoof", V(15, 0.6, 28), CF(-55, 8.3, -86), "Plywood"))
	for _, z in { -72, -79, -86, -93, -100 } do
		for _, x in { -62.2, -47.8 } do
			G.column(CF(x, 0, z), 8, 0.5, "Yellow", "TunnelPole")
		end
		G.deco("TunnelBeam", V(15, 0.5, 0.5), CF(-55, 7.8, z), "Yellow")
	end
	-- Escalera de la plaza A a la terraza (sube hacia el este pegada al edificio A)
	G.stairs(V(-52, 0, -105), V(-36, L, -105), 5, "Concrete", { Rails = "Right" })
	-- Pared entre el acopio y el patio B (con un paso en z 50..58)
	hoarding(V(-35, 0, 38), V(-35, 0, 50), 8)
	hoarding(V(-35, 0, 58), V(-35, 0, 76), 8)

	------------------------------------------------------------------
	-- MUELLE (lado oeste del edificio B): escalera exterior a la entreplanta
	------------------------------------------------------------------
	G.stairs(V(-39, 0, 84), V(-39, L, 100), 4, "Concrete", { Rails = "Right" })
	G.floor(CF(-39, L, 104.5), 4.4, 9, "Slab", 0.8)
	G.railing(V(-41.2, L, 100), V(-41.2, L, 109))
	G.railing(V(-41.2, L, 109), V(-36.4, L, 109))
	G.beam(V(-41, 0, 108.6), V(-41, L - 0.8, 108.6), 0.7, 0.7, "SteelDark")
	hoarding(V(-75, 0, 120), V(-36, 0, 120), 10)

	------------------------------------------------------------------
	-- Edificios del borde (macizos): cierran el mapa en forma de cruz
	------------------------------------------------------------------
	-- Bloques de borde: tramos de ~26 con alturas y colores distintos (manzana de ciudad)
	local looks = { "BuildingSand", "BuildingGray", "BuildingRose", "ConcreteWarm", "BuildingBrick" }
	local count = 0
	local function filler(x0, x1, z0, z1, h)
		local alongX = (x1 - x0) >= (z1 - z0)
		local length = alongX and (x1 - x0) or (z1 - z0)
		local pieces = math.max(1, math.floor(length / 26 + 0.5))
		for k = 0, pieces - 1 do
			count += 1
			local a0 = (alongX and x0 or z0) + k * length / pieces
			local a1 = a0 + length / pieces
			local cx = alongX and (a0 + a1) / 2 or (x0 + x1) / 2
			local cz = alongX and (z0 + z1) / 2 or (a0 + a1) / 2
			local sx = alongX and (a1 - a0) or (x1 - x0)
			local sz = alongX and (z1 - z0) or (a1 - a0)
			local height = h + ((count * 7) % 5 - 2) * 2.5
			T.cap(T.facadeBlock(CF(cx, 0, cz), sx, sz, height, looks[(count % #looks) + 1], { Lit = T.isNight(), Roof = count % 2 == 0 }))
		end
	end
	filler(-162, -150.3, -50, 50, 24)
	filler(-150.3, -95, -140, -50.3, 22)
	filler(-150.3, -95, 50.3, 140, 26)
	filler(-95, -70, -140, -70, 18)
	filler(-70, -30, -140, -108.5, 14)
	filler(-95, -75, 76, 140, 20)
	filler(-75, -36, 120.3, 140, 12)
	filler(-36, 0, 124.5, 140, 13)
	filler(-30, 0, -140, -130.2, 17)
end

return Geometry
