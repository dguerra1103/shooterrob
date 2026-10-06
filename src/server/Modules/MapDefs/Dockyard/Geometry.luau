-- DOCKYARD · geometría jugable (blockout). Terminal de contenedores:
--
--   agua      ~~~~~~~~~~~~~~~~~~~~ buque amarrado (decorado) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--   z -104 ═══ canto del muelle ════════════════════════════════════════════════════════════
--          CONTROL DEL PUERTO  grúa ║      MUELLE (sitio A)      ║ grúa   CONTROL DEL PUERTO
--   z  -60 (azotea 9)        ┌ bloque N ┐  contenedor   ┌ bloque N ┐         (azotea 9)
--  BASE    calle   ───────── │ (2 alto) │ ─── carretilla pórtico ── │          │ ─────── calle  BASE
--  ROJA    interior          └──────────┘    (centro)               └──────────┘          AZUL
--          PUERTA DE         ┌ bloque S ┐                           ┌ bloque S ┐    PUERTA DE
--   z   54 CAMIONES          └──────────┘  ═══ ANDÉN DE CARGA (4) ═══          CAMIONES
--   z  108                         TINGLADO DE TRÁNSITO (interior a 4, sitio B)
--
-- Simétrico en X = 0. Alturas: suelo 0, andén y tinglado 4, azotea del control del puerto 9.
-- Las pilas de contenedores llevan clip encima (no se sube nadie): son paredes de las calles.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local DOCK = 4
local OFFICE = 9
local QUAY = -104
local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0)

-- Pila de contenedores (layers de alto) con clip encima; cf = centro de la base, a lo largo de X
local function stack(T, cf, layers, looks)
	for layer = 0, layers - 1 do
		local look = looks[(layer % #looks) + 1]
		local c = T.container(cf * CF(0, layer * 8.75, 0), look)
		if layer == layers - 1 then
			T.cap(c)
		end
	end
end
Geometry.stack = stack

function Geometry.build(T)
	local G = T.G
	local M = Enum.Material
	local door = G.door

	-- Suelo (hasta el canto del muelle), agua y muro del muelle
	T.terrain(M.Asphalt, 1400, 1400, CF(0, 0, 400))
	workspace.Terrain:FillBlock(CF(0, -9, QUAY - 300), V(1400, 14, 600), M.Water)
	G.floor(CF(0, 0, (QUAY + 122) / 2), 304, 122 - QUAY, "Asphalt", 1)
	G.box("QuayWall", V(304, 10, 2), CF(0, -5, QUAY - 1), "QuayDark")
	G.deco("QuayApron", V(304, 0.1, 44), CF(0, 0.05, QUAY + 22), "Quay").CastShadow = false
	G.deco("QuayEdge", V(304, 0.6, 1.2), CF(0, 0.3, QUAY + 0.6), "YellowPaint")
	T.boundaryWall(V(-152, 0, QUAY - 0.4), V(152, 0, QUAY - 0.4), 60)
	for x = -140, 140, 20 do
		T.fender(CF(x, -2.4, QUAY - 2.2))
	end
	-- Carriles de las grúas
	for _, z in { -101, -79 } do
		G.paintLine(V(-150, 0.1, z), V(150, 0.1, z), 0.6, "SteelDark")
	end

	---------------------------------------------------------------------------
	-- MUELLE (A): contenedor en carga bajo el centro y grúas pórtico (en cada mitad)
	---------------------------------------------------------------------------
	T.cap(T.container(CF(0, 0, -99), "ContainerYellow"))

	---------------------------------------------------------------------------
	-- PLAYA DE CONTENEDORES (centro): contenedor bajo la carretilla pórtico
	---------------------------------------------------------------------------
	stack(T, CF(0, 0, 0) * ALONG_Z, 2, { "ContainerRed", "ContainerBlue" })
	T.cap(T.straddleCarrier(CF(0, 0, 0)))

	---------------------------------------------------------------------------
	-- TINGLADO DE TRÁNSITO (B): interior a la altura del andén de carga
	---------------------------------------------------------------------------
	G.solid("ShedFloor", V(86, DOCK, 44), CF(0, 0, 85), "Concrete")
	G.solid("LoadingDock", V(88, DOCK, 8), CF(0, 0, 58), "ConcreteDark")
	G.deco("DockEdge", V(88, 0.4, 0.6), CF(0, DOCK + 0.02, 54.3), "YellowPaint").CastShadow = false
	for x = -40, 40, 8 do
		G.deco("DockBumper", V(1.4, 1.6, 0.6), CF(x, DOCK - 1.2, 53.7), { Color3.fromRGB(30, 30, 32), M.SmoothPlastic })
	end
	G.shell(CF(0, 0, 85), 88, 46, 16, "Shed", {
		Front = { door(-20, 8, 8, DOCK), door(20, 8, 8, DOCK) },
		Back = {},
		Left = { door(1, 6, 8, DOCK) },
		Right = { door(1, 6, 8, DOCK) },
	}, { Frame = "SteelDark" })
	T.cap(G.slab(CF(0, 16.5, 85), 88, 46, "Roof", { { -20, 0, 10, 30 }, { 20, 0, 10, 30 } }))
	for _, x in { -20, 20 } do
		local sky = G.deco("ShedSkylight", V(10, 0.3, 30), CF(x, 16.8, 85), "Glass")
		sky.Transparency = 0.4
		T.cap(sky)
		local panel = G.deco("ShedLight", V(10, 0.2, 2), CF(x, 15.7, 72), { Color3.fromRGB(255, 240, 214), M.Neon })
		panel.CastShadow = false
		T.Kit.light(panel, "PointLight", Color3.fromRGB(255, 236, 206), 30, 1)
	end
	G.deco("ShedBand", V(88.4, 1.4, 46.4), CF(0, 13.4, 85), "Blue").CastShadow = false

	T.mirrored("DockHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Geometry.half(T)
	local G = T.G
	local door, window = G.door, G.window

	------------------------------------------------------------------
	-- BASE: caseta cerrada y muro trasero
	------------------------------------------------------------------
	T.spawnHouse({ Back = -150, Front = -122.5, Half = 24, Height = 9, Look = "Building", RoofLook = "Roof", Stripe = "Red" })
	for _, seg in { { QUAY, -24 }, { 24, 122 } } do
		T.cap(G.wall(CF(-150.5, 0, (seg[1] + seg[2]) / 2) * CFrame.Angles(0, -math.pi / 2, 0), seg[2] - seg[1], 8, "QuayDark"))
	end

	------------------------------------------------------------------
	-- Grúa pórtico del muelle
	------------------------------------------------------------------
	T.cap(T.stsCrane(CF(-30, 0, -90), { Span = 18, Gauge = 22, Look = "CraneRed" }))

	------------------------------------------------------------------
	-- CONTROL DEL PUERTO: oficina con azotea a 9 (escalera por el este)
	------------------------------------------------------------------
	G.shell(CF(-92, 0, -74), 24, 16, OFFICE, "Building", {
		Front = { window(-6, 3.5, 5, 3), window(6, 3.5, 5, 3) },
		Back = { door(-4, 4, 7) },
		Left = { door(2, 4, 7) },
		Right = { door(-3, 4, 7) },
	}, { Frame = "Blue" })
	G.floor(CF(-92, OFFICE, -74), 24, 16, "Roof", 1)
	G.deco("OfficeFloor", V(23, 0.1, 15), CF(-92, 0.05, -74), "Concrete").CastShadow = false
	-- Pretiles bajos al norte (al muelle), al oeste y al sur (hueco de la escalera); al este, la
	-- caseta de maquinaria con el letrero: desde la azotea no se ve la otra azotea de lado a lado
	T.cap(G.parapet(V(-103.6, OFFICE, -81.6), V(-84, OFFICE, -81.6), 3, "Building", 0.8))
	T.cap(G.parapet(V(-103.6, OFFICE, -81.6), V(-103.6, OFFICE, -66.4), 3, "Building", 0.8))
	T.cap(G.parapet(V(-103.6, OFFICE, -66.4), V(-94.2, OFFICE, -66.4), 3, "Building", 0.8))
	T.cap(G.parapet(V(-89.8, OFFICE, -66.4), V(-84, OFFICE, -66.4), 3, "Building", 0.8))
	T.cap(G.solid("RoofPlant", V(4, 6, 16), CF(-82, OFFICE, -74), "Building"))
	T.sign(CF(-79.9, OFFICE + 3, -74) * CFrame.Angles(0, -math.pi / 2, 0), "PORT CONTROL", 12, 2.2, Color3.fromRGB(40, 96, 190), Color3.new(1, 1, 1))
	G.stairs(V(-92, 0, -54), V(-92, OFFICE, -66.4), 4.2, "Steel", { Rails = "Both", Cap = true, Closed = true })

	------------------------------------------------------------------
	-- PLAYA DE CONTENEDORES: bloques de 2 de alto que forman las calles
	------------------------------------------------------------------
	for _, z in { -48, -40, -32 } do
		for _, x in { -62, -42 } do
			stack(T, CF(x, 0, z), 2, z == -40 and { "ContainerBlue", "ContainerYellow" } or { "ContainerRed", "ContainerGray" })
		end
	end
	for _, z in { 34, 42 } do
		for _, x in { -62, -42 } do
			stack(T, CF(x, 0, z), 2, z == 34 and { "ContainerYellow", "ContainerRed" } or { "ContainerBlue", "ContainerGray" })
		end
	end
	-- Contenedores sueltos (a lo largo de Z) a los lados del centro
	stack(T, CF(-20, 0, -20) * CFrame.Angles(0, math.pi / 2, 0), 1, { "ContainerBlue" })
	stack(T, CF(-20, 0, 20) * CFrame.Angles(0, math.pi / 2, 0), 2, { "ContainerRed", "ContainerYellow" })
	stack(T, CF(-24, 0, -56), 1, { "ContainerGray" })
	stack(T, CF(-50, 0, 50), 1, { "ContainerYellow" })
	stack(T, CF(-14, 0, -70) * CFrame.Angles(0, math.pi / 2, 0), 1, { "ContainerRed" })

	------------------------------------------------------------------
	-- ANDÉN DE CARGA y TINGLADO (mitad): escaleras al andén y a la puerta oeste
	------------------------------------------------------------------
	G.stairs(V(-32, 0, 47), V(-32, DOCK, 54), 5, "ConcreteDark", { Rails = "Both", Cap = true, Closed = true })
	G.stairs(V(-56, 0, 58), V(-44, DOCK, 58), 5, "ConcreteDark", { Rails = "Both", Cap = true, Closed = true })
	G.stairs(V(-56, 0, 86), V(-44, DOCK, 86), 5, "ConcreteDark", { Rails = "Both", Cap = true, Closed = true })
	T.rollerDoor(CF(-20, DOCK + 8, 61.4), 8, 4)
	-- Cierre detrás del tinglado (no hay paso por detrás)
	T.cap(G.wall(CF(-44.5, 0, 115) * CFrame.Angles(0, -math.pi / 2, 0), 14, 8, "QuayDark"))
end

return Geometry
