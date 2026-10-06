-- INDUSTRIAL YARD · geometría jugable (blockout). Planta industrial al atardecer:
--
--   z -117 ══════════════════ muro ═══ pasarela de la planta (8) ═══ muro ═══════════════════
--          MONTONES DE GRAVA   depósito  ║  PLANTA DE PROCESO (sitio A)  ║  depósito   GRAVA
--   z  -60 (cinta, pala)       depósito  ║   unidad de refrigeración     ║  depósito
--  BASE    calle   CASETA DE BOMBAS ───── SALA DE CALDERAS (chimenea) ───── CASETA DE BOMBAS  BASE
--  ROJA            (interior)              depósito horizontal                (interior)    AZUL
--   z   56 PATIO DE ALMACENAJE  ┌──────────── NAVE DE PRODUCCIÓN (sitio B) ─────────┐ ALMACENAJE
--   z  110                      └────── entreplanta (8) al fondo ───────────────────┘
--
-- Simétrico en X = 0. Alturas: suelo 0; pasarela de la planta y entreplanta de la nave a 8.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local UP = 8

function Geometry.build(T)
	local G = T.G
	local M = Enum.Material
	local door = G.door

	T.terrain(M.Ground, 1400, 1400, CF(0, 0, 0))
	G.floor(CF(0, 0, 0), 304, 244, "Ground", 1)
	G.deco("PlantPad", V(100, 0.1, 56), CF(0, 0.05, -88), "Concrete").CastShadow = false
	G.deco("CentralRoad", V(220, 0.1, 14), CF(0, 0.05, 20), "Asphalt").CastShadow = false
	G.paintLine(V(-110, 0.12, 20), V(110, 0.12, 20), 0.4, "YellowPaint")
	for _, z in { -117, 117 } do
		T.cap(G.box("PerimeterWall", V(304, 8, 1.2), CF(0, 4, z), "ConcreteDark"))
	end

	---------------------------------------------------------------------------
	-- SALA DE CALDERAS (centro): puertas desplazadas, caldera en medio, chimenea
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, 0), 24, 24, 12, "Brick", {
		Front = { door(-5, 4, 7), door(5, 4, 7) },
		Back = { door(-5, 4, 7), door(5, 4, 7) },
		Left = { door(-5, 4, 7), door(5, 4, 7) },
		Right = { door(-5, 4, 7), door(5, 4, 7) },
	}, { Frame = "SteelDark" })
	G.deco("BoilerFloor", V(23, 0.1, 23), CF(0, 0.05, 0), "Concrete").CastShadow = false
	T.Kit.cylinder("Boiler", 9, 14, CF(0, 4.5, 0), Color3.fromRGB(150, 84, 52), M.CorrodedMetal)
	T.Kit.cylinder("BoilerTop", 1, 10, CF(0, 9.5, 0), Color3.fromRGB(64, 66, 70), M.Metal, nil, true)
	T.cap(G.box("BoilerRoof", V(25, 0.8, 25), CF(0, 12.4, 0), "Roof"))
	T.chimney(CF(0, 12.8, 0), 52, 6)
	for _, s in { -1, 1 } do
		G.deco("BoilerWindow", V(16, 2, 0.2), CF(0, 9.6, s * 12.1), "Glass")
	end
	local lamp = G.deco("BoilerLight", V(8, 0.2, 1), CF(0, 11.6, -8), { Color3.fromRGB(255, 220, 170), M.Neon })
	T.Kit.light(lamp, "PointLight", Color3.fromRGB(255, 214, 160), 22, 0.9)

	---------------------------------------------------------------------------
	-- PLANTA DE PROCESO (A): pasarela a 8 por el norte, unidad de refrigeración al sur
	---------------------------------------------------------------------------
	G.floor(CF(0, UP, -106), 96, 4, "Deck", 0.8)
	for x = -40, 40, 16 do
		G.column(CF(x, 0, -106), UP - 0.8, 0.8, "Steel")
	end
	G.railing(V(-48, UP, -107.8), V(48, UP, -107.8), "Yellow", 3.2, { Cap = true })
	G.railing(V(-43.6, UP, -104.2), V(43.6, UP, -104.2), "Yellow", 3.2, { Cap = true })
	T.cap(G.solid("CoolingUnit", V(10, 7, 14), CF(0, 0, -40), "Steel"))
	for _, s in { -1, 1 } do
		G.deco("CoolingFan", V(0.2, 5, 5), CF(s * 5.05, 3.8, -40), "SteelDark")
	end

	---------------------------------------------------------------------------
	-- Transformador (norte de las calderas) y armario de carga (frente a la nave)
	T.cap(G.solid("Transformer", V(6, 6, 7), CF(0, 0, -16.5), "PipeGreen"))
	G.deco("TransformerFins", V(6.2, 3, 7.2), CF(0, 3.5, -16.5), "SteelDark")
	T.cap(G.solid("ChargingCabinet", V(8, 6, 8), CF(0, 0, 50), "Blue"))
	-- Depósito horizontal (centro sur)
	---------------------------------------------------------------------------
	T.cap(T.horizontalTank(CF(0, 0, 36), 16, 6))

	---------------------------------------------------------------------------
	-- NAVE DE PRODUCCIÓN (B): portones al norte, puertas laterales, entreplanta al fondo
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, 83), 92, 54, 16, "Shed", {
		Front = { door(-22, 8, 9), door(22, 8, 9) },
		Back = {},
		Left = { door(-3, 6, 8) },
		Right = { door(-3, 6, 8) },
	}, { Frame = "Orange" })
	G.deco("HallFloor", V(91, 0.1, 53), CF(0, 0.05, 83), "Concrete").CastShadow = false
	T.cap(G.slab(CF(0, 16.5, 83), 92, 54, "Roof", { { -22, -4, 10, 30 }, { 22, -4, 10, 30 } }))
	for _, x in { -22, 22 } do
		local sky = G.deco("HallSkylight", V(10, 0.3, 30), CF(x, 16.8, 79), "Glass")
		sky.Transparency = 0.4
		T.cap(sky)
		local panel = G.deco("HallLight", V(10, 0.2, 2), CF(x, 15.7, 70), { Color3.fromRGB(255, 236, 206), M.Neon })
		panel.CastShadow = false
		T.Kit.light(panel, "PointLight", Color3.fromRGB(255, 232, 200), 30, 1)
	end
	G.floor(CF(0, UP, 104.5), 90, 9, "Deck", 1)
	G.railing(V(-36, UP, 100.2), V(36, UP, 100.2), "Yellow", 3.2, { Cap = true })
	G.deco("CraneRail", V(90, 0.8, 0.8), CF(0, 14.6, 62), "SteelDark")
	G.deco("CraneRail", V(90, 0.8, 0.8), CF(0, 14.6, 98), "SteelDark")
	G.deco("OverheadCrane", V(1.4, 1.6, 36), CF(-10, 13.8, 80), "Orange")

	T.mirrored("IndustrialHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Geometry.half(T)
	local G = T.G
	local door, window = G.door, G.window

	------------------------------------------------------------------
	-- BASE y muro oeste
	------------------------------------------------------------------
	T.spawnHouse({ Back = -150, Front = -122.5, Half = 24, Height = 9, Look = "Building", RoofLook = "Roof", Stripe = "Orange" })
	for _, seg in { { -117, -24 }, { 24, 117 } } do
		T.cap(G.wall(CF(-150.5, 0, (seg[1] + seg[2]) / 2) * CFrame.Angles(0, -math.pi / 2, 0), seg[2] - seg[1], 8, "ConcreteDark"))
	end

	------------------------------------------------------------------
	-- PLANTA (A, mitad): depósitos verticales, rack de tuberías, escalera a la pasarela
	------------------------------------------------------------------
	T.cap(T.fuelTank(CF(-22, 0, -94), 10, 14))
	T.cap(T.fuelTank(CF(-22, 0, -66), 9, 11))
	T.cap(T.pipeRack(V(-40, 0, -100), V(-40, 0, -58), 9, 6))
	G.stairs(V(-46, 0, -92), V(-46, UP, -104), 4, "Steel", { Rails = "Both", Cap = true, Closed = true })
	G.railing(V(-48, UP, -104.2), V(-48, UP, -107.8), "Yellow", 3.2, { Cap = true })

	------------------------------------------------------------------
	-- CASETA DE BOMBAS (centro de cada mitad): se cruza por dentro, puertas desplazadas
	------------------------------------------------------------------
	G.shell(CF(-72, 0, 0), 16, 20, 8, "Building", {
		Front = { window(0, 3.5, 6, 2.5) },
		Back = { window(0, 3.5, 6, 2.5) },
		Left = { door(-5, 4, 7) },
		Right = { door(5, 4, 7) },
	}, { Frame = "Orange" })
	T.cap(G.box("PumpHouseRoof", V(17, 0.6, 21), CF(-72, 8.3, 0), "Roof"))
	G.solid("Pump", V(5, 4, 6), CF(-72, 0, 0), "PipeBlue")
	G.deco("PumpMotor", V(3, 2, 3), CF(-72, 5, 0), "SteelDark")

	------------------------------------------------------------------
	-- NAVE (B, mitad): escalera a la entreplanta
	------------------------------------------------------------------
	G.stairs(V(-40, 0, 88), V(-40, UP, 100), 4, "Steel", { Rails = "Both", Cap = true, Closed = true })
	-- Cierres detrás de la planta y de la nave (no hay paso por detrás)
	T.cap(G.wall(CF(-50.5, 0, -110.5) * CFrame.Angles(0, -math.pi / 2, 0), 13, 8, "ConcreteDark"))
	T.cap(G.wall(CF(-46.5, 0, 113.5) * CFrame.Angles(0, -math.pi / 2, 0), 7, 8, "ConcreteDark"))
	G.railing(V(-45, UP, 100.2), V(-42.2, UP, 100.2), "Yellow", 3.2, { Cap = true })
	G.railing(V(-37.8, UP, 100.2), V(-36, UP, 100.2), "Yellow", 3.2, { Cap = true })
end

return Geometry
