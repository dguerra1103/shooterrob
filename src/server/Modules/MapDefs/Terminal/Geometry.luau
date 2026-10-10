-- TERMINAL · geometría jugable (blockout). Aeropuerto con el avión en el centro de la plataforma:
--
--   z -130 ┌ OFICINAS ┬──── TERMINAL: vestíbulo abajo, salidas arriba (cristalera) ────┬ OFICINAS ┐
--          │ MUELLE   │   pasarela          PLATAFORMA A (sitio A)          pasarela  │  MUELLE  │
--   z  -82 │ CUBIERTO ├──────────────────────── morro ─────────────────────────────────┤ CUBIERTO │
--   HANGAR │ carretera│                       ╔═ AVIÓN ═╗                             │carretera │ HANGAR
--   (base  │ PLATAFORMA (furgonetas, cisterna, ║ alas   ║  contenedores)      PLATAFORMA │  (base
--   roja)  │          │                       ╚═ cola ══╝                             │  azul)
--   z   78 │ CATERING ├──────────── CARGA: marquesina con el sitio B y el muelle ─────┤ CATERING │
--   z  130 └──────────┴──────────────────────────────────────────────────────────────┴──────────┘
--
-- El avión parte la plataforma en dos (no se pasa por debajo del fuselaje): se cruza por el morro
-- (lado A) o por la cola (lado B). Alturas: suelo 0, salidas de la terminal y pasarelas 10,
-- muelle de carga 4. Simétrico en X = 0.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local L = 10

-- Cristalera: cristal (decorado) y un panel invisible que choca pero no para las balas
local function glazing(T, cf, w, h)
	local G = T.G
	local pane = G.deco("Glazing", V(w, h, 0.2), cf, "Glass")
	pane.Transparency = 0.55
	pane.CastShadow = false
	local stop = T.Kit.block("GlassCollider", V(w, h, 0.4), cf, Color3.new(1, 1, 1), nil, T.Kit.shootThroughFolder())
	stop.Transparency = 1
	stop.CastShadow = false
	G.deco("Mullion", V(0.3, h, 0.35), cf, "TerminalDark")
end

function Geometry.build(T)
	local G = T.G
	local door, window = G.door, G.window
	local M = Enum.Material

	-- (césped segado: LeafyGrass no saca briznas 3D; con Grass medían 2 studs, tapaban la vista a ras
	-- de suelo y son muchos triángulos para un móvil)
	T.terrain(M.LeafyGrass, 1400, 1400, CF(0, -0.3, 0))
	G.floor(CF(0, 0, 0), 300, 260, "Apron")

	---------------------------------------------------------------------------
	-- TERMINAL (140 x 48): vestíbulo con mostradores abajo; salidas arriba con cristalera a la
	-- plataforma; dos pasarelas de embarque bajan a la plataforma A
	---------------------------------------------------------------------------
	local t = CF(0, 0, -106) * CFrame.Angles(0, math.pi, 0) -- (la cara mira a la plataforma, +Z)
	local front0 = { door(-12, 8, 8), door(12, 8, 8), door(-40), door(40) }
	for _, x in { -56, -26, 26, 56 } do
		table.insert(front0, window(x, 2.5, 10, 5))
	end
	G.shell(t, 140, 48, L, "TerminalWall", { Front = front0, Left = { door(0, 8, 8) }, Right = { door(0, 8, 8) } }, { Frame = "TerminalDark" })
	local front1 = { door(-22, 6, 8), door(22, 6, 8) }
	local windows1 = { -60, -48, -36, -10, 0, 10, 36, 48, 60 }
	for _, x in windows1 do
		table.insert(front1, window(x, 2.5, 8, 6))
	end
	G.shell(t * CF(0, L, 0), 140, 48, L, "TerminalWall", {
		Front = front1,
		Left = { window(0, 3, 10, 4) },
		Right = { window(0, 3, 10, 4) },
	}, { Frame = "TerminalDark" })
	-- Cristales de los huecos de la fachada (las ventanas de la planta baja y las de arriba)
	for _, x in { -56, -26, 26, 56 } do
		glazing(T, CF(x, 5, -82.5), 10, 5)
	end
	for _, x in windows1 do
		glazing(T, CF(x, L + 5.5, -82.5), 8, 6)
	end
	G.slab(CF(0, L, -106), 138, 46, "Tile", { { -30, 4.5, 5.4, 10 }, { 30, 4.5, 5.4, 10 } })
	for _, s in { -1, 1 } do
		G.stairs(V(s * 30, 0, -90), V(s * 30, L, -106), 5, "TerminalPanel", { Rails = "Both" })
		G.railing(V(s * 27.2, L, -96.4), V(s * 32.8, L, -96.4))
		-- Pilares del vestíbulo (dos alturas)
		for _, x in { 14, 46 } do
			G.column(CF(s * x, 0, -112), 2 * L, 1.8, "TerminalWall")
		end
	end
	T.cap(G.floor(CF(0, 2 * L + 0.8, -106), 142, 50, "TerminalPanel", 0.8))
	-- Marquesina sobre la fachada y rótulo
	G.deco("Canopy", V(142, 0.8, 8), CF(0, 2 * L + 0.6, -78), "TerminalPanel")
	G.deco("CanopyFascia", V(142, 1.6, 0.6), CF(0, 2 * L, -74.2), "TerminalDark")

	-- Pasarelas de embarque: de la puerta de la primera a una escalera que baja a la plataforma
	for _, s in { -1, 1 } do
		G.walkway(V(s * 22, L, -82), V(s * 22, L, -64), 6, { Look = "TerminalPanel", EdgeLook = "TerminalDark", Supports = 9 })
		G.deco("BridgeRoof", V(6.6, 0.5, 18.4), CF(s * 22, L + 7.6, -73), "TerminalPanel")
		for _, side in { -1, 1 } do
			G.deco("BridgeGlass", V(0.2, 3.6, 18), CF(s * 22 + side * 3.1, L + 5.2, -73), "Glass").Transparency = 0.5
			G.deco("BridgeFrame", V(0.3, 7.6, 0.3), CF(s * 22 + side * 3.1, L + 3.8, -64.2), "TerminalDark")
		end
		G.stairs(V(s * 22, 0, -48), V(s * 22, L, -64), 5, "TerminalPanel", { Rails = "Both" })
	end

	---------------------------------------------------------------------------
	-- CARGA (sitio B): marquesina de 80 x 40 sobre columnas, muro del fondo y muelle de carga
	---------------------------------------------------------------------------
	T.cap(G.floor(CF(0, L + 0.8, 98), 82, 42, "TerminalPanel", 0.8))
	G.deco("CargoFascia", V(82, 2, 0.6), CF(0, L - 0.2, 77.2), "TerminalDark")
	for _, x in { -40, -20, 20, 40 } do
		G.column(CF(x, 0, 78), L, 1.4, "TerminalDark")
	end
	for _, x in { -40, 40 } do
		G.column(CF(x, 0, 98), L, 1.4, "TerminalDark")
	end
	G.wall(CF(0, 0, 118.5), 82, L, "HangarWall")
	for _, s in { -1, 1 } do
		G.wall(CF(s * 40.5, 0, 108.5) * CFrame.Angles(0, -math.pi / 2, 0), 21, L, "HangarWall")
		-- Rampa del muelle
		G.stairs(V(s * 37.5, 0, 113), V(s * 30.5, 4, 113), 6, "Concrete", {})
	end
	G.box("CargoDock", V(61, 4, 10), CF(0, 2, 113), "Concrete")
	G.railing(V(-22, 4, 108.2), V(-30, 4, 108.2))
	G.railing(V(22, 4, 108.2), V(30, 4, 108.2))

	T.mirrored("TerminalHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0): hangar (base), muelle cubierto, catering y bordes
function Geometry.half(T)
	local G = T.G
	local door = G.door

	------------------------------------------------------------------
	-- HANGAR (base): tres portones; mamparas para que las salidas laterales queden en L
	------------------------------------------------------------------
	local hg = CF(-131, 0, 0)
	G.shell(hg, 38, 80, 22, "HangarWall", {
		Right = { door(-29, 10, 12), door(0, 10, 12), door(29, 10, 12) },
	}, { Frame = "TerminalDark" })
	T.cap(G.floor(hg * CF(0, 22.6, 0), 39, 81, "HangarWall", 0.6))
	T.gableRoof(hg * CF(0, 22.6, 0) * CFrame.Angles(0, math.pi / 2, 0), 80, 38, 5, "HangarWall")
	T.gable(hg * CF(0, 22.6, -39.7) * CFrame.Angles(0, math.pi / 2, 0), 38, 5, "HangarWall")
	T.gable(hg * CF(0, 22.6, 39.7) * CFrame.Angles(0, math.pi / 2, 0), 38, 5, "HangarWall")
	for _, z in { -17, 17 } do
		T.cap(G.wall(CF(-118, 0, z + (z < 0 and -10.5 or 10.5)) * CFrame.Angles(0, -math.pi / 2, 0), 21, 10, "HangarWall"))
	end
	-- (y frente al portón central: se sale rodeándola por los pasillos de las laterales)
	T.cap(G.wall(CF(-120, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), 18, 10, "HangarWall"))

	------------------------------------------------------------------
	-- MUELLE CUBIERTO (norte, junto a la terminal): techo sobre pilares, muro con persianas
	------------------------------------------------------------------
	T.cap(G.floor(CF(-91, L + 0.8, -113), 42, 34, "TerminalPanel", 0.8))
	for _, x in { -110, -91, -72 } do
		G.column(CF(x, 0, -97), L, 1.2, "TerminalDark")
	end
	G.wall(CF(-91, 0, -130.5), 42, L, "HangarWall")
	G.wall(CF(-112.5, 0, -113) * CFrame.Angles(0, -math.pi / 2, 0), 34, L, "HangarWall")

	------------------------------------------------------------------
	-- Bordes: oficinas y taller (macizos), catering, vallas
	------------------------------------------------------------------
	T.cap(T.facadeBlock(CF(-131, 0, -85), 38, 90, 16, "TerminalWall", { Lit = T.isNight(), Windows = Color3.fromRGB(70, 110, 150) }))
	T.cap(T.facadeBlock(CF(-131, 0, 85), 38, 90, 14, "TerminalPanel", { Lit = T.isNight(), Windows = Color3.fromRGB(70, 110, 150) }))
	T.cap(T.facadeBlock(CF(-81, 0, 68), 38, 24, 12, "TerminalWall", { Lit = T.isNight(), Windows = Color3.fromRGB(70, 110, 150), Roof = false }))
	G.meshFence(V(-112, 0, 126), V(-41, 0, 126), 8)
	G.meshFence(V(-112, 0, -40), V(-112, 0, -96), 8)
end

return Geometry
