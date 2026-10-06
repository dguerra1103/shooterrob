-- COSTA · geometría jugable (blockout). Pueblo costero en una isla:
--
--   z -130 ┌──── casas ──── AYUNTAMIENTO (balcón, lona A) ──── casas ────┐  parte alta (y = 6)
--          │                 PLAZA ALTA (sitio A)                        │
--   z  -80 │── casas ─ arco ─┬─ ábside ─┬─ arco ─ casas ──────────────────│
--          │   MIRADOR       │ IGLESIA  │        MIRADOR                │
--   z  -62 ├─escalera─ PLAZUELA (escalinata) │ (escalinata) PLAZUELA ─escalera─┤  muro de contención
--   BASE ──┤ CALLEJÓN  │       campanario       │  CALLEJÓN ├── BASE
--   ROJA   │ CALLE MAYOR ─ ARCO ─ PLAZA (fuente) ─ ARCO ─ CALLE MAYOR │  AZUL
--   (muralla│ PASEO MARÍTIMO   │ calle del puerto │   PASEO MARÍTIMO │ muralla)
--   z   62 │   (mar)          │ LONJA (azotea)    │          (mar)   │
--   z  118 │                  │ ESPIGÓN (sitio B) │                  │
--          └──────────────────┴── muelle de madera ┴─────────────────┘
--
-- Simétrico en X = 0 (cada equipo tiene lo mismo); la mitad A (alta, cálida) y la B (puerto, azul)
-- son distintas. Alturas: calle 0, parte alta 6, balcón del ayuntamiento 14, azotea de la lonja 8.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local UP = 6 -- altura de la parte alta

function Geometry.build(T)
	local G = T.G
	local door, window = G.door, G.window
	local M = Enum.Material

	---------------------------------------------------------------------------
	-- Terreno: mar alrededor, la isla y la ladera del norte
	---------------------------------------------------------------------------
	workspace.Terrain:FillBlock(CF(0, -11, 0), V(1600, 16, 1600), M.Water)
	T.terrain(M.Rock, 340, 250, CF(0, -0.3, -40))
	T.terrain(M.Rock, 84, 36, CF(0, -0.3, 102))
	T.terrain(M.Sand, 60, 20, CF(-95, -2.6, 96))
	T.terrain(M.Sand, 60, 20, CF(95, -2.6, 96))

	---------------------------------------------------------------------------
	-- Suelos: pueblo bajo (0), parte alta (6, con su muro de contención), espigón y muelle
	---------------------------------------------------------------------------
	G.floor(CF(0, 0, 11.5), 300, 147, "Paving")
	G.box("UpperTown", V(300, 7, 73), CF(0, 2.5, -98.5), "Stone")
	G.floor(CF(0, 0, 98), 80, 40, "Quay")
	G.floor(CF(0, 0.3, 124), 10, 12, "Deck", 0.6)
	-- Paramento del muelle hasta el agua
	G.deco("Seawall", V(82, 4, 1), CF(0, -2, 118.5), "StoneDark")
	for _, s in { -1, 1 } do
		G.deco("Seawall", V(1, 4, 40), CF(s * 40.5, -2, 98), "StoneDark")
		G.deco("Seawall", V(110, 4, 1), CF(s * 95, -2, 85.5), "StoneDark")
		G.deco("PierPost", V(0.8, 5, 0.8), CF(s * 4.6, -2, 129.6), "Deck")
	end

	---------------------------------------------------------------------------
	-- IGLESIA (eje): nave en la calle, ábside en la parte alta y escalera dentro que las une.
	-- Campanario delante, con paso por su base. Corta las líneas de un lado a otro de la plaza.
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, -46), 28, 32, 14, "Whitewash", {
		Front = { door(0, 6, 8, UP) }, -- (cara norte, z -62: al ábside, en la parte alta)
		Back = { door(0, 6, 9) }, -- (cara sur, z -30: la puerta principal, tras el campanario)
		Left = { door(2, 6, 8) },
		Right = { door(2, 6, 8) },
	}, { Frame = "Stone" })
	G.stairs(V(0, 0, -47), V(0, UP, -59), 6, "Stone", { Rails = "Both", RailLook = "Iron" })
	G.floor(CF(0, UP, -60.5), 8, 3, "Stone")
	T.gableRoof(CF(0, 14, -46) * CFrame.Angles(0, math.pi / 2, 0), 32, 28, 6, "RoofTile")
	T.gable(CF(0, 14, -30.3) * CFrame.Angles(0, math.pi / 2, 0), 28, 6, "Whitewash")
	T.gable(CF(0, 14, -61.7) * CFrame.Angles(0, math.pi / 2, 0), 28, 6, "Whitewash")
	-- Techo de madera de la nave (el tejado de teja es decorado)
	T.cap(G.floor(CF(0, 14.6, -46), 28, 32, "Deck", 0.6))
	-- Ábside en la parte alta
	G.shell(CF(0, UP, -71), 28, 18, 9, "Whitewash", {
		Front = { door(0, 6, 8) }, -- (cara norte, z -80: a la plaza alta)
		Left = { door(-1) },
		Right = { door(-1) },
	}, { Frame = "Stone", Skip = { Back = true } })
	T.cap(G.floor(CF(0, UP + 9.6, -71), 30, 20, "RoofTile", 0.6))
	-- Campanario (base con paso de 5 y techo; arriba, campanas detrás de arcos: decorado)
	G.shell(CF(0, 0, -25), 10, 10, 9, "Sand", {
		Front = { door(0, 5, 7.5) },
		Back = { door(0, 5, 7.5) },
	}, { Frame = "Stone" })
	G.floor(CF(0, 9, -25), 10, 10, "Stone")
	local tower = G.box("BellTower", V(10, 26, 10), CF(0, 9 + 13, -25), "Sand")
	T.cap(tower)
	for _, face in { { V(0, 0, -5.1), 0 }, { V(0, 0, 5.1), math.pi }, { V(-5.1, 0, 0), math.pi / 2 }, { V(5.1, 0, 0), -math.pi / 2 } } do
		local at = CF(V(0, 29, -25) + face[1]) * CFrame.Angles(0, face[2], 0)
		G.deco("Belfry", V(4, 5, 0.3), at, { Color3.fromRGB(40, 36, 34), M.SmoothPlastic })
		T.archCorners(at * CF(0, 2.5, -0.1), 4, 1.4, "Sand", 0.5)
		G.deco("BelfrySill", V(5, 0.4, 0.8), at * CF(0, -2.6, 0), "Stone")
	end
	G.deco("TowerCornice", V(11, 0.8, 11), CF(0, 35.2, -25), "Stone")
	T.gableRoof(CF(0, 35.6, -25), 10, 10, 4, "RoofTile")
	T.gableRoof(CF(0, 35.6, -25) * CFrame.Angles(0, math.pi / 2, 0), 10, 10, 4, "RoofTile")
	local bell = T.Kit.ball("Bell", 2.6, CF(0, 29, -25), Color3.fromRGB(170, 130, 60), M.Metal, true)
	bell.CastShadow = false
	local clock = T.Kit.cylinder("TowerClock", 0.4, 4, CF(0, 20, -19.8) * CFrame.Angles(math.pi / 2, 0, 0), Color3.fromRGB(240, 236, 224), M.SmoothPlastic, nil, true)
	clock.CastShadow = false

	---------------------------------------------------------------------------
	-- AYUNTAMIENTO (sitio A, parte alta): dos plantas, balcón con la lona A
	---------------------------------------------------------------------------
	local a = CF(0, UP, -121) * CFrame.Angles(0, math.pi, 0)
	G.shell(a, 60, 18, 8, "Terracotta", {
		Front = { door(-10, 6, 7), door(10, 6, 7), window(-22, 3, 4, 3.5), window(22, 3, 4, 3.5) },
	}, { Frame = "Stone" })
	G.shell(a * CF(0, 8, 0), 60, 18, 8, "Terracotta", {
		Front = { door(-10, 5, 7), door(10, 5, 7), window(-22, 2.5, 4, 3.5), window(22, 2.5, 4, 3.5) },
	}, { Frame = "Stone" })
	G.slab(CF(0, UP + 8, -121), 58, 16, "Stone", { { -25, -2, 4.4, 12 }, { 25, -2, 4.4, 12 } })
	T.cap(G.floor(CF(0, UP + 16.6, -121), 61, 19, "Stone", 0.6))
	G.deco("TownHallCornice", V(61, 0.8, 19), CF(0, UP + 16, -121), "Stone")
	for _, s in { -1, 1 } do
		G.stairs(V(s * 25, UP, -127), V(s * 25, UP + 8, -115), 4, "Stone", { Rails = s > 0 and "Right" or "Left", RailLook = "Iron" })
		G.railing(V(s * 22.8, UP + 8, -122), V(s * 22.8, UP + 8, -115.2), "Iron")
	end
	-- Balcón corrido delante de la primera planta
	G.floor(CF(0, UP + 8, -109), 40, 6, "Stone", 1)
	G.railing(V(-20, UP + 8, -106.3), V(20, UP + 8, -106.3), "Iron")
	for _, s in { -1, 1 } do
		G.railing(V(s * 19.8, UP + 8, -112), V(s * 19.8, UP + 8, -106.3), "Iron")
		G.beam(V(s * 18, 0, -106.8) + V(0, UP, 0), V(s * 18, UP + 7.4, -106.8), 0.8, 0.8, "Stone")
	end

	---------------------------------------------------------------------------
	-- LONJA (puerto, sur de la plaza): soportales de paso y azotea con dos escaleras
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, 70), 36, 16, 8, "Stone", {
		Front = { door(-12, 6, 6.5), door(0, 6, 6.5), door(12, 6, 6.5) },
		Back = { door(-12, 6, 6.5), door(0, 6, 6.5), door(12, 6, 6.5) },
	}, { Frame = "StoneDark" })
	for _, z in { 62, 78 } do
		for _, x in { -12, 0, 12 } do
			T.archCorners(CF(x, 6.5, z) * (z > 70 and CFrame.Angles(0, math.pi, 0) or CFrame.new()), 6, 1.6, "Stone")
		end
	end
	G.floor(CF(0, 8.5, 70), 36, 16, "Paving", 1)
	G.deco("LonjaCeiling", V(34, 0.3, 14), CF(0, 7.35, 70), "Deck")
	for _, s in { -1, 1 } do
		G.stairs(V(s * 20.5, 0, 77), V(s * 20.5, 8.5, 64), 4, "Stone", { Rails = s > 0 and "Right" or "Left", RailLook = "Iron" })
		G.floor(CF(s * 20.2, 8.5, 62.5), 4.6, 3, "Stone", 0.5)
		-- Pretil de la azotea (cobertura baja con hueco donde llega la escalera)
		G.box("LonjaParapet", V(0.8, 2.6, 13), CF(s * 17.6, 8.5 + 1.3, 71.5), "Stone")
		G.railing(V(s * 22.6, 8.5, 61), V(s * 22.6, 8.5, 64), "Iron")
		G.railing(V(s * 18.4, 8.5, 61.2), V(s * 22.6, 8.5, 61.2), "Iron")
	end
	G.box("LonjaParapet", V(36, 2.6, 0.8), CF(0, 8.5 + 1.3, 77.6), "Stone")
	G.box("LonjaParapet", V(28, 2.6, 0.8), CF(0, 8.5 + 1.3, 62.4), "Stone")

	T.mirrored("CoastalHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Geometry.half(T)
	local G = T.G
	local door = G.door

	local looks = { "Whitewash", "Sand", "Terracotta", "Ochre", "Rose", "Whitewash", "Sand" }
	local shutters = { Color3.fromRGB(70, 120, 92), Color3.fromRGB(56, 100, 160), Color3.fromRGB(150, 60, 50) }
	local count = 0
	-- Manzana de casas macizas: tramos de ~14 con alturas, colores y tejados distintos
	local function row(x0, x1, z0, z1, h, opts)
		opts = opts or {}
		local alongX = (x1 - x0) >= (z1 - z0)
		local length = alongX and (x1 - x0) or (z1 - z0)
		local pieces = math.max(1, math.floor(length / (opts.Piece or 14) + 0.5))
		for k = 0, pieces - 1 do
			count += 1
			local a0 = (alongX and x0 or z0) + k * length / pieces
			local a1 = a0 + length / pieces
			local cx = alongX and (a0 + a1) / 2 or (x0 + x1) / 2
			local cz = alongX and (z0 + z1) / 2 or (a0 + a1) / 2
			local w = alongX and (a1 - a0) or (x1 - x0)
			local d = alongX and (z1 - z0) or (a1 - a0)
			local height = h + ((count * 5) % 3) * 2
			-- (la cara con ventanas mira a la calle: opts.Face = dirección de la calle)
			local face = opts.Face or V(0, 0, 1)
			local yaw = math.atan2(-face.X, -face.Z)
			local turned = math.abs(face.X) > 0.5
			local cf = CF(cx, opts.Y or 0, cz) * CFrame.Angles(0, yaw, 0)
			T.cap(T.house(cf, turned and d or w, turned and w or d, height, looks[(count % #looks) + 1], {
				Roof = (count % 3 == 0) and "Flat" or "Tile",
				Shutter = shutters[(count % #shutters) + 1],
				Back = opts.Back,
				Balcony = count % 4 == 1,
				Door = opts.Door,
			}))
		end
	end

	------------------------------------------------------------------
	-- BASE: patio tras la muralla, tres puertas (norte, centro, sur)
	------------------------------------------------------------------
	local wallH = 10
	T.cap(G.wall(CF(-112, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 90, wallH, "StoneDark", {
		door(-34, 8, 8), door(-7, 6, 8), door(37, 10, 8),
	}, { T = 2, Frame = "Stone" }))
	T.cap(G.wall(CF(-150, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 90, 12, "StoneDark", {}, { T = 2 }))
	-- Almenas de la muralla y arcos de las puertas
	for z = -44, 44, 4 do
		if not ((z > -39 and z < -29) or (z > -11 and z < -3) or (z > 31 and z < 43)) then
			G.deco("Merlon", V(2.2, 1.6, 2), CF(-112, wallH + 0.8, z), "StoneDark")
		end
	end
	for _, gate in { { -34, 8 }, { -7, 6 }, { 37, 10 } } do
		T.archCorners(CF(-111, 8, gate[1]) * CFrame.Angles(0, -math.pi / 2, 0), gate[2], 1.6, "StoneDark", 2.2)
	end
	-- Mamparas: las salidas norte y sur quedan en L; la central, tras un crucero de piedra
	T.cap(G.wall(CF(-119, 0, -28) * CFrame.Angles(0, -math.pi / 2, 0), 16, 8, "Stone"))
	T.cap(G.wall(CF(-119, 0, 29) * CFrame.Angles(0, -math.pi / 2, 0), 18, 8, "Stone"))
	T.cap(G.solid("StoneCross", V(3, 6, 10), CF(-117.5, 0, -4), "Stone"))
	G.deco("CrossShaft", V(0.8, 5, 0.8), CF(-117.5, 8.5, -4), "Stone")
	G.deco("CrossArm", V(0.8, 0.8, 3), CF(-117.5, 10, -4), "Stone")
	-- Casas a los lados de la base
	row(-150, -112, -62, -46, 12, { Face = V(0, 0, 1) })
	row(-150, -112, 46, 90, 12, { Face = V(0, 0, -1) })

	------------------------------------------------------------------
	-- CALLEJÓN (norte): casas a los dos lados, escalera a la parte alta y arcos con parra
	------------------------------------------------------------------
	row(-112, -78, -62, -46, 12, { Face = V(0, 0, 1) })
	row(-66, -40, -62, -46, 12, { Face = V(0, 0, 1) })
	G.stairs(V(-72, 0, -50), V(-72, UP, -62), 6, "Stone", { Rails = "Both", RailLook = "Iron" })
	for _, x in { -77.4, -66.6 } do
		G.solid("StairWall", V(1.2, UP + 1, 12), CF(x, 0, -56), "StoneDark")
	end
	-- Manzana entre el callejón y la calle mayor, con la TABERNA (se cruza de una calle a otra)
	row(-110, -74, -24, -10, 11, { Face = V(0, 0, -1), Back = true })
	row(-58, -30, -24, -10, 12, { Face = V(0, 0, -1), Back = true })
	G.shell(CF(-66, 0, -17), 16, 14, 9, "Ochre", {
		Front = { door(-3) },
		Back = { door(3) },
	}, { Frame = "Stone" })
	T.cap(G.floor(CF(-66, 9.5, -17), 17, 15, "RoofTile", 0.5))
	T.gableRoof(CF(-66, 9.8, -17), 16, 14, 3.5, "RoofTile")

	------------------------------------------------------------------
	-- CALLE MAYOR (centro) y el ARCO que da a la plaza (desplazado de la puerta de la base)
	------------------------------------------------------------------
	row(-108, -66, 6, 32, 12, { Face = V(0, 0, -1), Back = true })
	row(-58, -36, 6, 30, 12, { Face = V(0, 0, -1) })
	-- Arco de la villa: casa sobre un paso de 8 (z -2..6)
	T.cap(G.wall(CF(-33, 0, -2) * CFrame.Angles(0, -math.pi / 2, 0), 16, 13, "Rose", { door(4, 8, 8) }, { T = 6, Frame = "Stone" }))
	T.archCorners(CF(-36.1, 8, 2) * CFrame.Angles(0, -math.pi / 2, 0), 8, 2, "Stone", 0.4)
	T.gableRoof(CF(-33, 13, -2) * CFrame.Angles(0, math.pi / 2, 0), 16, 6, 2.5, "RoofTile")
	T.cap(G.solid("ArchPier", V(6, 12, 8), CF(-33, 0, 14), "Rose"))

	------------------------------------------------------------------
	-- PASEO MARÍTIMO (sur): casas frente al mar, barandilla del muelle
	------------------------------------------------------------------
	row(-100, -58, 40, 52, 11, { Face = V(0, 0, 1) })
	row(-30, -18, 30, 60, 11, { Face = V(1, 0, 0) })
	G.railing(V(-150, 0, 84.6), V(-40, 0, 84.6), "Iron")
	G.railing(V(-40.4, 0, 84.6), V(-40.4, 0, 117.6), "Iron")
	G.railing(V(-40.4, 0, 117.6), V(-5, 0, 117.6), "Iron")
	G.railing(V(-5, 0.6, 118), V(-5, 0.6, 129.6), "Iron")
	G.railing(V(-5, 0.6, 129.6), V(0, 0.6, 129.6), "Iron")
	-- Cierre del paseo junto a la base (baluarte)
	T.cap(G.wall(CF(-112, 0, 66) * CFrame.Angles(0, -math.pi / 2, 0), 38, 8, "StoneDark", {}, { T = 2 }))

	------------------------------------------------------------------
	-- PARTE ALTA: casas, mirador sobre el muro de contención, escalinata y arcos a la plaza alta
	------------------------------------------------------------------
	row(-112, -80, -130, -62, 12, { Face = V(1, 0, 0), Y = UP })
	row(-80, -46, -130, -90, 12, { Face = V(0, 0, 1), Y = UP })
	-- Fila entre el mirador y la plaza alta, con un arco de paso (x -30..-24)
	row(-46, -30, -90, -80, 10, { Face = V(0, 0, 1), Y = UP, Back = true })
	row(-24, -14, -90, -80, 10, { Face = V(0, 0, 1), Y = UP, Back = true })
	G.deco("ArchBridge", V(6, 2.2, 10), CF(-27, UP + 8.6, -85), "Ochre")
	T.archCorners(CF(-27, UP + 7.5, -80.2), 6, 1.5, "Ochre", 0.6)
	-- Escalinata de la plazuela a la parte alta
	G.stairs(V(-23, 0, -50), V(-23, UP, -62), 9, "Stone", { Rails = "Both", RailLook = "Iron" })
	-- Balaustrada del mirador (cobertura baja) salvo donde llegan las escaleras
	for _, seg in { { -80, -75.6 }, { -68.4, -27.8 }, { -18.2, -14 } } do
		G.box("Balustrade", V(seg[2] - seg[1], 3, 0.8), CF((seg[1] + seg[2]) / 2, UP + 1.5, -62.6), "Stone")
	end
	-- Pequeño bloque en la esquina de la plaza alta
	row(-46, -30, -130, -112, 13, { Face = V(1, 0, 0), Y = UP })
end

return Geometry
