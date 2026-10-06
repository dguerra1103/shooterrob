-- ROOFTOP DISTRICT · geometría jugable (blockout). Azoteas de una manzana de ciudad unidas por
-- puentes, con la calle 40 studs más abajo (decorado: no se puede caer, todos los bordes tienen
-- pretil y por encima un clip):
--
--   z -100 ┌ TORRE NO (alta 14) ┐ ─puente─ ┌──── AZOTEA A (4, sitio A) ────┐ ─puente─ ┌ TORRE NE ┐
--          │   (6)              │          │                                │          │  (6)     │
--   z  -50 └────── rampa ───────┘          └──── pasarela norte ────────────┘          └──────────┘
--   BASE ═══ OESTE (0) ═ escalera ═ PLATAFORMA (6) ═ PUENTE DE CRISTAL ═ CENTRO (6) ═ ... ═ BASE
--   ROJA   (tres puentes)                                                 (pantalla)         AZUL
--   z   50 ┌────── puente ──────┐          ┌──── pasarela sur ──────────────┐          ┌──────────┐
--          │ SUROESTE (0, depósito 8)      │ AZOTEA B (0, lucernarios: sitio B)          │ SURESTE  │
--   z  100 └────────────────────┘ ─puente─ └────────────────────────────────┘ ─puente─ └──────────┘
--
-- Simétrico en X = 0. Alturas: azoteas 0, 4 y 6; plataformas altas de las esquinas 14 y 8.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local STREET = -40
local PARAPET = 3.2

-- Manzana con azotea: el edificio entero (desde la calle) y pretiles en los bordes. edges = { N, S,
-- W, E } (N = lado -Z, S = +Z, W = -X, E = +X): false = sin pretil (pegado a otra azotea), o una
-- lista de huecos { desde, hasta } a lo largo del borde (de -X a +X o de -Z a +Z)
local function roof(T, x0, x1, z0, z1, top, look, edges)
	local G = T.G
	local body = G.solid("Building", V(x1 - x0, top - STREET, z1 - z0), CF((x0 + x1) / 2, STREET, (z0 + z1) / 2), look)
	G.deco("RoofSurface", V(x1 - x0 - 0.4, 0.1, z1 - z0 - 0.4), CF((x0 + x1) / 2, top + 0.05, (z0 + z1) / 2), "Roof").CastShadow = false
	-- Bandas de ventanas de las fachadas (decorado; se ven desde los puentes y al asomarse)
	for y = top - 6, STREET + 6, -6 do
		G.deco("FacadeWindows", V(x1 - x0 + 0.2, 1.8, z1 - z0 + 0.2), CF((x0 + x1) / 2, y, (z0 + z1) / 2), { Color3.fromRGB(56, 70, 90), Enum.Material.Glass }).CastShadow = false
	end
	local function edge(a, b, openings)
		if openings == false then
			return
		end
		local dir = (b - a).Unit
		local length = (b - a).Magnitude
		local cuts = {}
		for _, o in openings or {} do
			table.insert(cuts, o)
		end
		table.sort(cuts, function(p, q)
			return p[1] < q[1]
		end)
		local start = 0
		local function piece(t0, t1)
			if t1 - t0 > 0.3 then
				local p0, p1 = a + dir * t0, a + dir * t1
				T.cap(G.parapet(p0, p1, PARAPET, "Parapet", 1))
			end
		end
		local along = math.abs(dir.X) > 0.5 and "X" or "Z"
		for _, c in cuts do
			local t0 = math.abs(c[1] - a[along])
			local t1 = math.abs(c[2] - a[along])
			piece(start, math.min(t0, t1))
			start = math.max(t0, t1)
		end
		piece(start, length)
	end
	local y = top
	local inset = 0.5
	edge(V(x0, y, z0 + inset), V(x1, y, z0 + inset), edges.N)
	edge(V(x0, y, z1 - inset), V(x1, y, z1 - inset), edges.S)
	edge(V(x0 + inset, y, z0), V(x0 + inset, y, z1), edges.W)
	edge(V(x1 - inset, y, z0), V(x1 - inset, y, z1), edges.E)
	return body
end
Geometry.roof = roof

-- Puente abierto entre dos azoteas (a, b = puntos de la superficie en los dos bordes)
local function bridge(T, a, b, width)
	T.G.walkway(a, b, width or 6, { Look = "Deck", EdgeLook = "SteelDark", Cap = true })
end

function Geometry.build(T)
	local G = T.G
	local M = Enum.Material

	T.terrain(M.Asphalt, 1200, 1200, CF(0, STREET - 0.3, 0))
	G.deco("Street", V(600, 0.2, 600), CF(0, STREET + 0.1, 0), "Street").CastShadow = false

	---------------------------------------------------------------------------
	-- CENTRO (6): azotea con la gran pantalla en medio (corta la vista de lado a lado)
	---------------------------------------------------------------------------
	roof(T, -40, 40, -30, 30, 6, "BuildingBlue", {
		N = { { -4, 4 } }, S = { { -4, 4 } }, W = { { -4, 4 } }, E = { { -4, 4 } },
	})
	-- Pantalla gigante sobre una estructura (choca: es la cobertura alta del centro)
	T.cap(G.box("ScreenFrame", V(2, 14, 26), CF(0, 6 + 7, 0), "SteelDark"))
	for _, s in { -1, 1 } do
		local screen = G.deco("Screen", V(0.3, 11, 23), CF(s * 1.2, 6 + 7.5, 0), "Screen")
		screen.CastShadow = false
		local gui = T.Kit.sign(screen, s < 0 and Enum.NormalId.Left or Enum.NormalId.Right, "ROOFTOP · DISTRICT", Color3.fromRGB(220, 240, 255), Color3.fromRGB(30, 80, 170))
		gui.LightInfluence = 0.2
	end

	---------------------------------------------------------------------------
	-- AZOTEA A (4) y AZOTEA B (0), sitios; pasarelas desde el centro
	---------------------------------------------------------------------------
	roof(T, -60, 60, -100, -54, 4, "Building", {
		N = {}, S = { { -4, 4 } }, W = { { -82, -74 } }, E = { { -82, -74 } },
	})
	roof(T, -60, 60, 54, 100, 0, "BuildingLight", {
		N = { { -4, 4 } }, S = {}, W = { { 74, 82 } }, E = { { 74, 82 } },
	})
	-- Franja de color bajo la azotea: A roja, B azul (se reconocen desde los puentes)
	G.deco("SiteBand", V(120.6, 1.4, 46.6), CF(0, 4 - 2, -77), "Red").CastShadow = false
	G.deco("SiteBand", V(120.6, 1.4, 46.6), CF(0, 0 - 2, 77), "Blue").CastShadow = false
	bridge(T, V(0, 6, -30), V(0, 4, -54), 8)
	bridge(T, V(0, 6, 30), V(0, 0, 54), 8)

	T.mirrored("RooftopHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Geometry.half(T)
	local G = T.G

	------------------------------------------------------------------
	-- BASE (0) y OESTE (0): tres puentes sobre el callejón
	------------------------------------------------------------------
	roof(T, -150, -114, -32, 32, 0, "BuildingBlue", {
		N = {}, S = {}, W = {}, E = { { -26, -20 }, { -3, 3 }, { 20, 26 } },
	})
	for _, z in { -23, 0, 23 } do
		bridge(T, V(-114, 0, z), V(-108, 0, z), 6)
	end
	-- Caseta de la base (marquesina cerrada): frente ciego hacia el mapa, una puerta a cada lado
	-- (norte y sur) que da a un vestíbulo en L; desde las azoteas y los puentes no se ve dentro
	local door = G.door
	for _, z in { -18.5, 18.5 } do
		T.cap(G.wall(CF(-134.75, 0, z), 26.5, 9, "BuildingLight", { door(10.25, 5, 7.4) }))
		T.cap(G.wall(CF(-127.25, 0, z * 0.76), 11.5, 9, "BuildingLight"))
	end
	T.cap(G.wall(CF(-121.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 37.6, 9, "BuildingLight"))
	T.cap(G.floor(CF(-134.5, 9.6, 0), 27.6, 38, "SteelDark", 0.6))
	G.deco("CanopyEdge", V(0.6, 1, 38), CF(-120.9, 9.1, 0), "Red")
	G.deco("CanopyStripe", V(0.3, 1.2, 26), CF(-121.1, 6.5, 0), "Red")
	for _, z in { -18.5, 18.5 } do
		G.deco("DoorSign", V(5, 0.8, 0.2), CF(-124.5, 8, z + (z < 0 and -0.35 or 0.35)), "Red")
	end
	roof(T, -108, -66, -36, 36, 0, "Building", {
		N = { { -93, -87 } }, S = { { -93, -87 } }, W = { { -26, -20 }, { -3, 3 }, { 20, 26 } }, E = {},
	})
	-- Plataforma (6) al este del bloque oeste, con escalera y cuarto de escalera; puente de cristal
	G.solid("Platform", V(18, 6, 28), CF(-75, 0, 0), "BuildingBlue")
	for _, seg in { { V(-84, 6, -14), V(-66, 6, -14) }, { V(-84, 6, 14), V(-66, 6, 14) } } do
		T.cap(G.parapet(seg[1] + V(0, 0, seg[1].Z < 0 and 0.5 or -0.5), seg[2] + V(0, 0, seg[1].Z < 0 and 0.5 or -0.5), PARAPET, "Parapet", 1))
	end
	G.stairs(V(-96, 0, 0), V(-84, 6, 0), 6, "RoofDark", { Rails = "Both", Cap = true })
	-- (borde este de la plataforma: da al vacío; hueco donde llega el puente de cristal)
	T.cap(G.parapet(V(-66.5, 6, -14), V(-66.5, 6, -4), PARAPET, "Parapet", 1))
	T.cap(G.parapet(V(-66.5, 6, 4), V(-66.5, 6, 14), PARAPET, "Parapet", 1))
	-- (cuarto de escalera: tapa la línea del puente de cristal hasta la base)
	T.cap(G.solid("StairHouse", V(8, 8, 12), CF(-76, 6, 0), "BuildingLight"))
	G.deco("StairHouseDoor", V(3, 6.4, 0.2), CF(-76, 6 + 3.2, -6.1), "SteelDark")
	G.deco("StairHouseDoor", V(3, 6.4, 0.2), CF(-76, 6 + 3.2, 6.1), "SteelDark")
	-- Puente de cristal (cubierto) hasta el centro
	G.walkway(V(-66, 6, 0), V(-40, 6, 0), 8, { Look = "Deck", EdgeLook = "SteelDark", Cap = true })
	for _, s in { -1, 1 } do
		local glass = G.deco("BridgeGlass", V(26, 6, 0.2), CF(-53, 6 + 3.6, s * 3.9), "Glass")
		glass.Transparency = 0.55
		glass.CastShadow = false
		for _, x in { -64, -53, -42 } do
			G.deco("BridgeFrame", V(0.4, 7.2, 0.4), CF(x, 6 + 3.6, s * 3.9), "SteelDark")
		end
	end
	T.cap(G.deco("BridgeRoof", V(26, 0.5, 8.6), CF(-53, 6 + 7.4, 0), "Glass"))

	------------------------------------------------------------------
	-- TORRE NO (6, con plataforma alta de 14 y antena) y SUROESTE (0, con depósito en 8)
	------------------------------------------------------------------
	roof(T, -108, -72, -100, -50, 6, "BuildingLight", {
		N = {}, S = { { -93, -87 } }, W = {}, E = { { -82, -74 } },
	})
	G.stairs(V(-90, 0, -36), V(-90, 6, -50), 6, "RoofDark", { Rails = "Both", Cap = true })
	G.solid("HighDeck", V(14, 8, 14), CF(-95, 6, -87), "Building")
	T.cap(G.parapet(V(-102, 14, -93.5), V(-88, 14, -93.5), 2.4, "Parapet", 0.8))
	T.cap(G.parapet(V(-101.5, 14, -94), V(-101.5, 14, -80), 2.4, "Parapet", 0.8))
	G.stairs(V(-76, 6, -84), V(-88, 14, -84), 4, "RoofDark", { Rails = "Both", Cap = true })
	roof(T, -108, -72, 50, 100, 0, "BuildingBrick", {
		N = { { -93, -87 } }, S = {}, W = {}, E = { { 74, 82 } },
	})
	bridge(T, V(-90, 0, 36), V(-90, 0, 50), 6)
	G.solid("TankDeck", V(14, 8, 14), CF(-95, 0, 87), "BuildingLight")
	G.stairs(V(-76, 0, 84), V(-88, 8, 84), 4, "RoofDark", { Rails = "Both", Cap = true })
	T.cap(G.parapet(V(-102, 8, 93.5), V(-88, 8, 93.5), 2.4, "Parapet", 0.8))
	T.cap(G.parapet(V(-101.5, 8, 94), V(-101.5, 8, 80), 2.4, "Parapet", 0.8))
	-- Puentes de las esquinas a los sitios
	bridge(T, V(-72, 6, -78), V(-60, 4, -78), 6)
	bridge(T, V(-72, 0, 78), V(-60, 0, 78), 6)
end

return Geometry
