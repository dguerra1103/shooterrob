-- MALL RUSH · geometría jugable (blockout). Centro comercial de dos plantas (suelo 0, planta alta 12):
--
--   z -80 ┌─ PASILLO DE SERVICIO ──────────┬──── ZONA DE COMIDA (doble altura) ────┬─ ... ─┐
--         │ BLOX MART      │ pasaje │ tienda│                                       │       │
--   z -36 │ (tienda grande)│        ├ PASILLO NORTE ┬──────── ATRIO ─────────┬─────┤       │
--  APARCA-│ VESTÍBULO ─── GALERÍA ─ PATIO A (sitio A) │ fuente, escaleras,  │ PATIO B │ ... APARCA-
--  MIENTO │ (escalera)     │        ├ PASILLO SUR   ┤ puente arriba       ├─────┤       MIENTO
--  (base  │ PIXEL WEAR     │ tiendas│ tienda│              ENTRADA (vestíbulo)          │  (base
--   roja) │ (tienda grande)├─ pasillo sur B ────────┴──────────────────────────────────┘   azul)
--   z  80 └──────────────────────────────────────────────────────────────────────────────┘
--
-- Como en la referencia, cada sitio está en la mitad de un equipo: el Rojo defiende el A y el Azul
-- el B. Simétrico en X = 0. Planta alta: galería sobre el vestíbulo, anillo sobre los patios y el
-- atrio y un puente que cruza el atrio (escaleras mecánicas desde la fuente).
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local L = 12 -- planta alta
local TOP = 24 -- techo

function Geometry.build(T)
	local G = T.G
	local M = Enum.Material

	-- (relleno sin briznas: con Grass, la hierba 3D atravesaba el suelo del centro comercial)
	T.terrain(M.Pavement, 1200, 1200, CF(0, -1.4, 0))
	G.floor(CF(0, 0, 0), 236, 160, "Floor")
	-- Cúpula sobre el atrio y lucernario de la zona de comida
	T.glassDome(CF(0, TOP + 1, 0), 44, 12)
	for _, x in { -20, 20 } do
		local sky = G.deco("FoodSkylight", V(20, 0.3, 24), CF(x, TOP + 0.6, -58), "Glass")
		sky.Transparency = 0.45
	end
	-- Puertas de cristal de la entrada principal (cerradas: el exterior sur no se juega)
	local doors = G.deco("EntranceGlass", V(24, 9, 0.3), CF(0, 4.5, 80.2), "Glass")
	doors.Transparency = 0.4
	G.box("EntranceStop", V(24, 12, 1), CF(0, 6, 80.5), "Facade").Transparency = 1
	G.wall(CF(0, 9, 80.5), 24, TOP - 9, "Facade")

	T.mirrored("MallHalf", function()
		Geometry.half(T)
	end)
end

function Geometry.half(T)
	local G = T.G
	local door, window = G.door, G.window

	------------------------------------------------------------------
	-- Fachadas (oeste con 4 puertas; norte y sur) y aparcamiento
	------------------------------------------------------------------
	T.cap(G.wall(CF(-118.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 162, TOP, "Facade", {
		door(-76, 6, 8), door(-9, 6, 8), door(9, 6, 8), door(68, 6, 8),
	}, { Frame = "FacadeDark" }))
	T.cap(G.wall(CF(-59.5, 0, -80.5), 119, TOP, "Facade"))
	T.cap(G.wall(CF(-65.5, 0, 80.5), 107, TOP, "Facade"))
	G.floor(CF(-134, 0, 0), 32, 120, "Parking", 1)
	-- Marquesina del aparcamiento (la base): paredes a los lados y techo; delante, aparcados, el
	-- camión y la furgoneta (ver Props) tapan las puertas del centro comercial
	for _, z in { -24.5, 24.5 } do
		T.cap(G.wall(CF(-141, 0, z), 22, 8, "FacadeDark"))
		G.column(CF(-130.4, 0, z), 8.6, 1, "Steel")
	end
	T.cap(G.floor(CF(-141, 9, 0), 23, 50, "FacadeDark", 0.8))
	-- (tubos de luz bajo la marquesina: la base no se queda a oscuras)
	for _, z in { -14, 14 } do
		local tube = G.deco("CarportLight", V(14, 0.2, 0.8), CF(-141, 8.1, z), { Color3.fromRGB(255, 246, 230), Enum.Material.Neon })
		tube.CastShadow = false
		T.Kit.light(tube, "SurfaceLight", Color3.fromRGB(255, 240, 220), 18, 1.2, Enum.NormalId.Bottom)
	end
	G.deco("CarportStripe", V(0.4, 1, 50), CF(-129.8, 8.4, 0), "Magenta")
	G.box("ParkingCurb", V(32, 0.8, 1), CF(-134, 0.4, -60.5), "Concrete")
	G.box("ParkingCurb", V(32, 0.8, 1), CF(-134, 0.4, 60.5), "Concrete")
	T.cap(G.hoarding(V(-150, 0, -61), V(-150, 0, 61), 10, "FacadeDark", { Stripe = "Magenta" }))
	T.cap(G.hoarding(V(-150, 0, -61), V(-119, 0, -61), 6, "FacadeDark", { Stripe = "Magenta" }))
	T.cap(G.hoarding(V(-150, 0, 61), V(-119, 0, 61), 6, "FacadeDark", { Stripe = "Magenta" }))

	------------------------------------------------------------------
	-- Tiendas grandes con interior: BLOX MART (norte) y PIXEL WEAR (sur)
	------------------------------------------------------------------
	G.wall(CF(-95, 0, -72), 46, L, "WallGray")
	G.wall(CF(-72, 0, -46) * CFrame.Angles(0, -math.pi / 2, 0), 52, L, "WallGray", { door(6) })
	G.wall(CF(-95, 0, -20), 46, L, "Wall", { door(-13, 8, 8), window(7, 1, 10, 7) })
	G.box("BloxUpper", V(46, L, 52), CF(-95, L + L / 2, -46), "Wall")
	G.wall(CF(-95, 0, 20), 46, L, "Wall", { door(5, 8, 8), window(-11, 1, 10, 7) })
	G.wall(CF(-72, 0, 46) * CFrame.Angles(0, -math.pi / 2, 0), 52, L, "WallGray", { door(-18), door(24) })
	G.box("PixelUpper", V(46, L, 52), CF(-95, L + L / 2, 46), "Wall")

	------------------------------------------------------------------
	-- Pasillo de servicio (norte), pasaje al patio y pasillo sur B: techos bajos (10)
	------------------------------------------------------------------
	G.box("ServiceUpper", V(78, 14, 8), CF(-79, 17, -76), "Service")
	G.box("PassageUpper", V(8, 14, 36), CF(-68, 17, -54), "Service")
	T.cap(G.wall(CF(-40, 0, -76) * CFrame.Angles(0, -math.pi / 2, 0), 8, 10, "Service", { door(0) }))
	G.box("SouthCorridorUpper", V(52, 14, 14), CF(-46, 17, 73), "Wall")

	------------------------------------------------------------------
	-- Bloques de tiendas macizos (dos plantas)
	------------------------------------------------------------------
	G.solid("ShopN2", V(24, TOP, 36), CF(-52, 0, -54), "Wall")
	G.solid("ShopS2", V(36, TOP, 30), CF(-54, 0, 51), "Wall")
	G.solid("ShopS4", V(16, TOP, 30), CF(-28, 0, 51), "Wall")

	------------------------------------------------------------------
	-- Planta alta: galería (con la escalera del vestíbulo), anillo del patio y del atrio, puente
	------------------------------------------------------------------
	G.slab(CF(-94.5, L, 0), 45, 40, "Floor", { { -5.5, -3, 4.8, 11 } })
	G.stairs(V(-100, 0, 12), V(-100, L, -8), 4.4, "WallGray", { Rails = "Both", RailLook = "Steel" })
	-- Vestíbulo-esclusa: pared interior con las puertas desplazadas respecto a las de la fachada
	-- (desde dentro no se ve el aparcamiento de la base)
	T.cap(G.wall(CF(-110, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 40, L, "Wall", { door(-15, 6, 8), door(15, 6, 8) }, { Frame = "FacadeDark" }))
	G.slab(CF(-54, L, 0), 36, 72, "Floor", { { 4, 0, 20, 28 } })
	G.slab(CF(-18, L, 0), 36, 72, "Floor", { { 7, 0, 22, 44 } })
	G.floor(CF(-11, L, -12), 22, 6, "Floor")
	-- Barandillas de cristal: hueco del patio, hueco del atrio, puente y bordes sobre la comida y
	-- la entrada (los bordes con tiendas tienen la pared de la tienda)
	T.glassRail(V(-60, L, -14), V(-60, L, 14))
	T.glassRail(V(-40, L, -14), V(-40, L, 14))
	T.glassRail(V(-60, L, -14), V(-40, L, -14))
	T.glassRail(V(-60, L, 14), V(-40, L, 14))
	T.glassRail(V(-22, L, -22), V(-22, L, -15.2))
	T.glassRail(V(-22, L, -8.8), V(-22, L, 22))
	T.glassRail(V(-22, L, -22), V(0, L, -22))
	T.glassRail(V(-22, L, 22), V(-16.6, L, 22))
	T.glassRail(V(-11.4, L, 22), V(0, L, 22))
	T.glassRail(V(-22, L, -15), V(0, L, -15))
	T.glassRail(V(-22, L, -9), V(0, L, -9))
	T.glassRail(V(-40, L, -36), V(0, L, -36))
	T.glassRail(V(-20, L, 36), V(0, L, 36))
	T.glassRail(V(-97.8, L, 2.6), V(-102.2, L, 2.6))
	-- Falsos techos blancos bajo la planta alta (el interior se ve claro)
	for _, spec in { { -94.5, 0, 44, 39 }, { -54, -28, 35, 15 }, { -54, 28, 35, 15 }, { -66, 0, 11, 26 }, { -29, 0, 13, 71 }, { -11, -29, 21, 13 }, { -11, 29, 21, 13 } } do
		local panel = G.deco("CeilingPanel", V(spec[3], 0.15, spec[4]), CF(spec[1], L - 1.1, spec[2]), "Ceiling")
		panel.CastShadow = false
	end
	-- Escalera mecánica del atrio (sube hacia el sur, hasta el anillo)
	T.escalator(V(-14, 0, 0), V(-14, L, 22), 4.4)

	------------------------------------------------------------------
	-- Techo (con huecos: patio, atrio y lucernario de la comida)
	------------------------------------------------------------------
	T.cap(G.slab(CF(-59, TOP + 0.5, 0), 118, 160, "RoofTop", {
		{ 9, 0, 20, 28 },
		{ 48, 0, 22, 44 },
		{ 39, -58, 20, 24 },
	}))
	local sky = G.deco("CourtSkylight", V(20, 0.3, 28), CF(-50, TOP + 0.6, 0), "Glass")
	sky.Transparency = 0.45
	T.cap(sky)
end

return Geometry
