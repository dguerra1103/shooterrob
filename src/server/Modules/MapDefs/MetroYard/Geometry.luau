-- METRO YARD · geometría jugable (blockout). Estación de metro con su playa de vías:
--
--   z -100 ┌──────────────────── ESTACIÓN (vestíbulo, sitio A; entreplanta a 10) ─────────────────┐
--  PLAZA   │  puerta oeste      torniquetes                                       puerta este      │ PLAZA
--   z  -40 └──── puerta ────────────────── pasarela ──────────────────── puerta ─────────────────┘
--  CALLE  ═ ANDÉN NORTE ═══════════════════════╪═══════════════════════════════ ANDÉN NORTE ═  CALLE
--  BASE   [TÚNEL] zanja (−3): vías 1 y 2, tren  │ pasarela (10) con escaleras al andén central [TÚNEL] BASE
--  ROJA   [ (10) ] ANDÉN CENTRAL (marquesina) ═ núcleo ═ ANDÉN CENTRAL                  [ (10) ] AZUL
--         [TÚNEL] zanja (−3): vías 3 y 4, tren  │                                         [TÚNEL]
--  CALLE  ═ ANDÉN SUR ═════════════════════════╪═══════════════════════════════ ANDÉN SUR ══  CALLE
--   z   44 ┌──── puerta ────────────────── galería ───────────────────── puerta ─────────────────┐
--  PATIO   │                     COCHERAS (taller, sitio B)                                      │ PATIO
--   z  100 └─────────────────────────────────────────────────────────────────────────────────────┘
--
-- Simétrico en X = 0. Alturas: suelo 0, zanjas de las vías −3, y a 10 la entreplanta de la
-- estación, la pasarela, la galería de las cocheras y el techo de los túneles.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local TRENCH = -3
local UP = 10

-- Losa de suelo (de TRENCH a 0) en el rectángulo dado: los lados de las losas son las paredes de
-- las zanjas de las vías
local function plate(G, x0, x1, z0, z1, look)
	return G.box("Ground", V(x1 - x0, -TRENCH + 0.3, z1 - z0), CF((x0 + x1) / 2, (TRENCH - 0.3) / 2, (z0 + z1) / 2), look)
end
Geometry.plate = plate

function Geometry.build(T)
	local G = T.G
	local M = Enum.Material
	local door = G.door

	T.terrain(M.Asphalt, 1200, 1200, CF(0, TRENCH - 0.6, 0))

	---------------------------------------------------------------------------
	-- Suelo: losas a 0 y fondo de las zanjas a −3 (con las vías)
	---------------------------------------------------------------------------
	plate(G, -152, 152, -112, -30, "Concrete")
	plate(G, -152, 152, 30, 112, "Concrete")
	plate(G, -90, 90, -5, 5, "Platform")
	G.floor(CF(0, TRENCH, 0), 180, 60, "Ballast", 1)
	for _, z in { -24, -11, 11, 24 } do
		T.track(V(-90, TRENCH, z), V(90, TRENCH, z))
	end
	-- Bordes de andén: línea amarilla y franja de botones
	for _, z in { -30.4, -5.4, 5.4, 30.4 } do
		G.paintLine(V(-90, 0, z), V(90, 0, z), 0.5, "YellowPaint")
	end

	---------------------------------------------------------------------------
	-- ESTACIÓN (vestíbulo de doble altura con entreplanta al sur; sitio A dentro)
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, -70), 100, 60, 20, "Wall", {
		Front = {},
		Back = { door(-26, 8, 9), door(26, 8, 9), door(0, 6, 7.5, UP) },
		Left = { door(-4, 8, 9) },
		Right = { door(-4, 8, 9) },
	}, { Frame = "WallBlue" })
	G.deco("HallFloor", V(99, 0.1, 59), CF(0, 0.05, -70), "Tile").CastShadow = false
	G.slab(CF(0, UP, -46), 99, 11, "Tile")
	T.cap(G.slab(CF(0, 20.5, -70), 100, 60, "ConcreteDark", { { 0, -6, 60, 10 } }))
	local sky = G.deco("HallSkylight", V(60, 0.3, 10), CF(0, 20.8, -76), "Glass")
	sky.Transparency = 0.4
	T.cap(sky)
	-- Luces del techo del vestíbulo
	for _, x in { -30, 0, 30 } do
		local panel = G.deco("HallLight", V(14, 0.2, 2), CF(x, 19.8, -66), { Color3.fromRGB(240, 246, 255), Enum.Material.Neon })
		panel.CastShadow = false
		T.Kit.light(panel, "PointLight", Color3.fromRGB(236, 242, 255), 34, 1.1)
	end
	-- (cabina central de la línea de torniquetes)
	G.box("GateBooth", V(3, 4, 3), CF(0, 2, -60), "WallBlue")

	---------------------------------------------------------------------------
	-- COCHERAS (taller con dos coches en mantenimiento; sitio B dentro)
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, 72), 100, 56, 16, "Shed", {
		Front = { door(-24, 10, 12), door(24, 10, 12), door(0, 6, 5.5, UP) },
		Back = {},
		Left = { door(-2, 8, 9) },
		Right = { door(-2, 8, 9) },
	}, { Frame = "Orange" })
	for _, x in { -30, 0, 30 } do
		local panel = G.deco("ShedLight", V(12, 0.2, 2), CF(x, 15.7, 70), { Color3.fromRGB(255, 240, 214), Enum.Material.Neon })
		panel.CastShadow = false
		T.Kit.light(panel, "PointLight", Color3.fromRGB(255, 236, 206), 32, 1.1)
	end
	G.deco("ShedFloor", V(99, 0.1, 55), CF(0, 0.05, 72), "ConcreteDark").CastShadow = false
	T.cap(G.slab(CF(0, 16.5, 72), 100, 56, "Shed", { { -24, 2, 12, 36 }, { 24, 2, 12, 36 } }))
	for _, x in { -24, 24 } do
		local roofLight = G.deco("ShedSkylight", V(12, 0.3, 36), CF(x, 16.8, 74), "Glass")
		roofLight.Transparency = 0.4
		T.cap(roofLight)
	end
	G.floor(CF(0, UP, 48), 28, 7.8, "Deck")
	G.railing(V(-14, UP, 51.8), V(14, UP, 51.8), "Yellow", 3.2, { Cap = true })

	---------------------------------------------------------------------------
	-- PASARELA (10) de la estación a las cocheras, cubierta, con escaleras al andén central
	---------------------------------------------------------------------------
	G.floor(CF(0, UP, 2), 6, 84, "Deck", 0.8)
	for _, s in { -1, 1 } do
		for _, seg in { { -40, -2.4 }, { 2.4, 44 } } do
			G.railing(V(s * 2.8, UP, seg[1]), V(s * 2.8, UP, seg[2]), "Yellow", 3.2, { Cap = true })
		end
		local glass = G.deco("BridgeGlass", V(0.2, 6.6, 84), CF(s * 3.05, UP + 3.6, 2), "Glass")
		glass.Transparency = 0.6
		glass.CastShadow = false
		G.stairs(V(s * 17, 0, 0), V(s * 3, UP, 0), 4, "Steel", { Rails = "Both", Cap = true, Closed = true })
	end
	T.cap(G.deco("BridgeRoof", V(7, 0.4, 82), CF(0, UP + 7.2, 2), "SteelDark"))
	-- Faldón opaco a los lados de la pasarela por encima de la barandilla: corta la línea entre
	-- los techos de los dos túneles (de pie no se ven por encima de la playa de vías)
	for _, s in { -1, 1 } do
		G.box("BridgeCladding", V(0.4, 4.2, 79), CF(s * 3.2, UP + 5.3, 2), "WallBlue")
	end
	for _, z in { -30, -18, 18, 30 } do
		G.deco("BridgeFrame", V(6.6, 0.5, 0.5), CF(0, UP + 6.9, z), "Orange")
	end
	-- Bajo la pasarela: núcleos en los andenes norte y sur, el del ascensor en el andén central y
	-- una pila-muro en las zanjas. Con las casetas de relés de cada mitad forman una chicana: se
	-- pasa de un lado al otro, pero no hay línea de vista de túnel a túnel por ninguna zanja
	-- (sin clip encima: la pasarela los cubre de lado a lado)
	G.solid("NorthCore", V(6, UP - 0.8, 10), CF(0, 0, -35), "WallBlue")
	G.solid("SouthCore", V(6, UP - 0.8, 13.5), CF(0, 0, 37.25), "WallBlue")
	G.solid("LiftCore", V(6, UP - 0.8, 10), CF(0, 0, 0), "WallBlue")
	G.solid("BridgePier", V(3.2, UP - 0.8 - TRENCH, 30), CF(0, TRENCH, 0), "Concrete")
	T.relayCabinet(CF(0, TRENCH, -28.6), 9.4)
	T.glassRail(V(-3.2, UP, -51.6), V(3.2, UP, -51.6))
	for _, z in { -35, 37 } do
		for _, s in { -1, 1 } do
			T.sign(CF(s * 3.15, 6.5, z) * CFrame.Angles(0, -s * math.pi / 2, 0), "M", 3, 3, Color3.fromRGB(40, 96, 196), Color3.new(1, 1, 1))
		end
	end

	T.mirrored("MetroHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Geometry.half(T)
	local G = T.G
	local door = G.door

	------------------------------------------------------------------
	-- BASE: cocheras de autobús cerradas (frente ciego, puertas norte y sur con vestíbulo en L)
	------------------------------------------------------------------
	for _, z in { -24, 24 } do
		T.cap(G.wall(CF(-136.25, 0, z), 27.5, 9, "Wall", { door(10.75, 5, 7.4) }))
		T.cap(G.wall(CF(-127.75, 0, z * 0.81), 10.5, 9, "Wall"))
	end
	T.cap(G.wall(CF(-122.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 48.6, 9, "Wall"))
	T.cap(G.wall(CF(-149.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 48.6, 9, "Wall"))
	T.cap(G.floor(CF(-136, 9.6, 0), 28, 49, "SteelDark", 0.6))
	G.deco("BaseStripe", V(0.3, 1.2, 40), CF(-122.1, 6.5, 0), "Orange")

	------------------------------------------------------------------
	-- TÚNEL (x −90 a −60): zanjas y andén central cubiertos; techo transitable a 10
	------------------------------------------------------------------
	for _, z in { -30.5, 30.5 } do
		G.box("TunnelWall", V(30, UP + 0.5, 1), CF(-75, UP / 2 - 0.25, z), "Tunnel")
	end
	-- Muro oeste: puerta al andén central desde la calle
	G.wall(CF(-90.5, TRENCH, 0) * CFrame.Angles(0, -math.pi / 2, 0), 60, UP - TRENCH, "Tunnel", { door(0, 8, 8, -TRENCH) })
	plate(G, -152, -91, -30, 30, "Concrete")
	G.floor(CF(-75, UP, 0), 31, 62, "Tunnel", 1)
	G.deco("PortalFrame", V(1.2, 2, 62), CF(-60.4, UP - 1, 0), "Orange")
	for _, x in { -84, -76, -68 } do
		for _, z in { -4.4, 4.4 } do
			G.column(CF(x, 0, z), UP - 1, 1.2, "Concrete")
		end
	end
	for _, z in { -24, -11, 11, 24 } do
		T.bufferStop(CF(-88.4, TRENCH, z) * CFrame.Angles(0, -math.pi / 2, 0))
	end
	-- Pretiles del techo del túnel (hueco donde llegan las escaleras de la calle)
	T.cap(G.parapet(V(-60.5, UP, -31), V(-60.5, UP, 31), 3.2, "Concrete", 1))
	T.cap(G.parapet(V(-90, UP, -30.5), V(-60, UP, -30.5), 3.2, "Concrete", 1))
	T.cap(G.parapet(V(-90, UP, 30.5), V(-60, UP, 30.5), 3.2, "Concrete", 1))
	for _, seg in { { -31, -24.5 }, { -19.5, 19.5 }, { 24.5, 31 } } do
		T.cap(G.parapet(V(-89.6, UP, seg[1]), V(-89.6, UP, seg[2]), 3.2, "Concrete", 1))
	end
	for _, z in { -22, 22 } do
		G.stairs(V(-104, 0, z), V(-90, UP, z), 5, "Concrete", { Rails = "Both", Cap = true, Closed = true })
	end

	------------------------------------------------------------------
	-- Vallas entre las plazas y los andenes (con puerta)
	------------------------------------------------------------------
	for _, z in { -40.5, 40.5 } do
		T.cap(G.hoarding(V(-90, 0, z), V(-74, 0, z), 3.4, "WallBlue", { Stripe = "Orange" }))
		T.cap(G.hoarding(V(-66, 0, z), V(-50, 0, z), 3.4, "WallBlue", { Stripe = "Orange" }))
	end

	------------------------------------------------------------------
	-- ESTACIÓN (mitad): escalera a la entreplanta, torniquetes, barandilla de cristal
	------------------------------------------------------------------
	G.stairs(V(-44, 0, -68), V(-44, UP, -52), 5, "TileDark", { Rails = "Both", RailLook = "Steel", Cap = true, Closed = true })
	T.glassRail(V(-41.4, UP, -51.6), V(-3.2, UP, -51.6))
	T.glassRail(V(-49.4, UP, -51.6), V(-46.6, UP, -51.6))
	T.cap(T.turnstiles(CF(-19.5, 0, -60), 7))

	-- Taquilla delante de la puerta oeste (desde la puerta no se ve el vestíbulo de lado a lado)
	T.cap(G.solid("TicketOffice", V(3, 7.5, 10), CF(-40, 0, -74), "WallBlue"))
	G.deco("TicketOfficeTop", V(3.2, 0.6, 10.2), CF(-40, 7.2, -74), "Orange").CastShadow = false

	-- Muros de cierre detrás de la estación y de las cocheras (no hay paso por detrás)
	for _, z in { -100, 100 } do
		T.cap(G.wall(CF(-50.5, 0, z + (z < 0 and -6 or 6)) * CFrame.Angles(0, -math.pi / 2, 0), 12, 9, "Concrete"))
	end

	------------------------------------------------------------------
	-- COCHERAS (mitad): escalera de la galería
	------------------------------------------------------------------
	G.stairs(V(-28, 0, 48), V(-14, UP, 48), 4, "Steel", { Rails = "Both", Cap = true, Closed = true })

	------------------------------------------------------------------
	-- Casetas de relés de la chicana central de las zanjas
	------------------------------------------------------------------
	for _, spec in { { -16.4, 8.8 }, { 21, 18 } } do
		T.cap(G.solid("RelayHut", V(3, 9, spec[2]), CF(-7, TRENCH, spec[1]), "ConcreteDark"))
		G.deco("RelayHutStripe", V(3.1, 0.6, spec[2] + 0.1), CF(-7, TRENCH + 8.2, spec[1]), "Orange").CastShadow = false
	end
end

return Geometry
