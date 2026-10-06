-- DESERT BASE · geometría jugable (blockout). Base militar vallada en el desierto:
--
--   z -116 ═══════════════════════ muro de hormigón (T-wall) ═══════════════════════════════
--          BARRACONES (oeste)  ┌── PARQUE DE VEHÍCULOS (marquesina, sitio A) ──┐  BARRACONES (este)
--   z  -58 torre ▲             └───────────────────────────────────────────────┘          ▲ torre
--  BASE    control ─ HESCO ─ PATIO DE ARMAS ── torre de agua ── HQ (azotea 9, antena) ── ... BASE
--  ROJA    calle interior                         helipuerto                               AZUL
--   z   56 DEPÓSITO DE         ┌──────────────── ALMACÉN (sitio B) ──────────────┐   DEPÓSITO DE
--          COMBUSTIBLE         │                                                 │   COMBUSTIBLE
--   z  116 ═════════════════════════════════════════════════════════════════════════════════
--
-- Simétrico en X = 0. Alturas: suelo 0, azotea del cuartel general 9, plataforma del depósito de
-- combustible 6 y torres de vigilancia 12.
local Geometry = {}

local V = Vector3.new
local CF = CFrame.new

local HQ_TOP = 9
local TOWER = 12
local GANTRY = 6

function Geometry.build(T)
	local G = T.G
	local M = Enum.Material
	local door = G.door

	T.terrain(M.Sand, 1400, 1400, CF(0, 0, 0))
	G.floor(CF(0, 0, 0), 304, 244, "Sand", 1)
	-- Losas: parque de vehículos, patio de armas y almacén
	G.deco("MotorPoolPad", V(80, 0.12, 50), CF(0, 0.06, -80), "Pad").CastShadow = false
	G.deco("ParadePad", V(120, 0.1, 100), CF(0, 0.05, 0), "Asphalt").CastShadow = false
	for _, x in { -40, -20, 20, 40 } do
		G.paintLine(V(x, 0.1, -46), V(x, 0.1, 46), 0.4, "Paint")
	end
	-- Helipuerto (pintado) entre el cuartel y el almacén
	G.deco("Helipad", V(0.1, 22, 22), CF(0, 0.12, 36) * CFrame.Angles(0, 0, math.pi / 2), "Paint").Shape = Enum.PartType.Cylinder
	G.deco("HelipadInner", V(0.1, 20.4, 20.4), CF(0, 0.13, 36) * CFrame.Angles(0, 0, math.pi / 2), "Asphalt").Shape = Enum.PartType.Cylinder
	for _, spec in { { -2.4, 0, 0.8, 8 }, { 2.4, 0, 0.8, 8 }, { 0, 0, 4, 0.8 } } do
		G.deco("HelipadH", V(spec[3], 0.05, spec[4]), CF(spec[1], 0.16, 36 + spec[2]), "Paint").CastShadow = false
	end

	---------------------------------------------------------------------------
	-- CUARTEL GENERAL (HQ): dos salas, puertas desplazadas, azotea a 9 con antena
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, 0), 28, 32, HQ_TOP, "Building", {
		Front = { door(-8, 4, 7), door(8, 4, 7) },
		Back = { door(-8, 4, 7), door(8, 4, 7) },
		Left = { door(-8, 4, 7), door(8, 4, 7) },
		Right = { door(-8, 4, 7), door(8, 4, 7) },
	}, { Frame = "MilGreenDark" })
	G.wall(CF(0, 0, 0), 26.2, HQ_TOP, "Tan", { door(0, 4, 7) })
	-- Consolas (cortan la línea de puerta a puerta en cada sala)
	for _, z in { -8, 8 } do
		G.solid("Console", V(4, 5.4, 7), CF(0, 0, z), "MilGreenDark")
		G.deco("ConsoleScreen", V(4.1, 1.4, 6), CF(0, 4.2, z), { Color3.fromRGB(80, 200, 120), M.Neon }).CastShadow = false
	end
	G.floor(CF(0, HQ_TOP, 0), 28, 32, "Roof", 1)
	G.deco("HQFloor", V(27, 0.1, 31), CF(0, 0.05, 0), "Concrete").CastShadow = false
	-- Pretil de sacos en la azotea (hueco al oeste y al este donde llegan las escaleras)
	T.cap(T.sandbags(V(-13, HQ_TOP, -15), V(13, HQ_TOP, -15), 2.2))
	T.cap(T.sandbags(V(-13, HQ_TOP, 15), V(13, HQ_TOP, 15), 2.2))
	for _, x in { -13, 13 } do
		T.cap(T.sandbags(V(x, HQ_TOP, -14), V(x, HQ_TOP, -4.6), 2.2))
		T.cap(T.sandbags(V(x, HQ_TOP, 0.6), V(x, HQ_TOP, 14), 2.2))
	end
	T.cap(T.radioMast(CF(0, HQ_TOP, 0), 26))
	T.cap(G.solid("RoofHut", V(6, 4.5, 4), CF(0, HQ_TOP, -8), "Building"))
	T.cap(G.solid("RoofHut", V(6, 4.5, 4), CF(0, HQ_TOP, 8), "Building"))

	---------------------------------------------------------------------------
	-- PARQUE DE VEHÍCULOS (A): marquesina sobre pilares
	---------------------------------------------------------------------------
	T.cap(G.box("MotorPoolRoof", V(76, 0.8, 44), CF(0, 10.4, -80), "Roof"))
	G.deco("MotorPoolFascia", V(76.4, 1.4, 0.4), CF(0, 9.6, -57.8), "MilGreenDark")
	for _, x in { -36, -12, 12, 36 } do
		for _, z in { -100, -60 } do
			G.column(CF(x, 0, z), 10, 1.2, "SteelDark")
		end
	end

	---------------------------------------------------------------------------
	-- ALMACÉN (B): nave con portones al norte, puertas laterales y lucernarios
	---------------------------------------------------------------------------
	G.shell(CF(0, 0, 82), 76, 52, 14, "Tan", {
		Front = { door(-20, 8, 9), door(20, 8, 9) },
		Back = {},
		Left = { door(-2, 8, 9) },
		Right = { door(-2, 8, 9) },
	}, { Frame = "MilGreenDark" })
	G.deco("WarehouseFloor", V(75, 0.1, 51), CF(0, 0.05, 82), "Concrete").CastShadow = false
	T.cap(G.slab(CF(0, 14.5, 82), 76, 52, "Roof", { { -18, 0, 10, 34 }, { 18, 0, 10, 34 } }))
	for _, x in { -18, 18 } do
		local sky = G.deco("WarehouseSkylight", V(10, 0.3, 34), CF(x, 14.8, 82), "Glass")
		sky.Transparency = 0.4
		T.cap(sky)
	end

	---------------------------------------------------------------------------
	-- Torre de agua (centro norte): corta la línea entre las dos torres de vigilancia
	---------------------------------------------------------------------------
	-- Búnker de comunicaciones con la torre de agua encima: corta la línea norte del patio y, con el
	-- depósito, la de torre de vigilancia a torre de vigilancia
	T.cap(G.solid("CommsBunker", V(12, 6, 27), CF(0, 0, -41.5), "Concrete"))
	G.deco("BunkerBand", V(12.2, 0.8, 27.2), CF(0, 5, -41.5), "MilGreenDark").CastShadow = false
	G.deco("BunkerDoor", V(4, 4.6, 0.2), CF(0, 2.3, -27.95), "SteelDark")
	T.cap(T.waterTower(CF(0, 6, -44), 8, 9))
	-- Taller del parque de vehículos (fondo de A): de lado a lado no se ve por detrás de A
	T.cap(G.solid("Workshop", V(4, 7.5, 27.4), CF(0, 0, -102.7), "Building"))
	G.deco("WorkshopBand", V(4.2, 0.8, 27.6), CF(0, 6.6, -102.7), "Red").CastShadow = false
	T.cap(G.solid("Generator", V(8, 5.6, 13), CF(0, 0, -62.5), "MilGreen"))
	-- Helicóptero en el helipuerto (corta la línea sur del patio)
	T.cap(T.helicopter(CF(0, 0, 33)))

	-- Muros perimetrales norte y sur
	for _, z in { -117, 117 } do
		T.cap(T.tWall(V(-150, 0, z), V(150, 0, z), 9))
	end

	T.mirrored("DesertHalf", function()
		Geometry.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Geometry.half(T)
	local G = T.G

	------------------------------------------------------------------
	-- BASE: caseta cerrada (barracón de entrada) y muro trasero
	------------------------------------------------------------------
	T.spawnHouse({ Back = -150, Front = -122.5, Half = 24, Height = 9, Look = "Building", RoofLook = "Roof", Stripe = "Red" })
	for _, seg in { { -117, -24 }, { 24, 117 } } do
		T.cap(T.tWall(V(-149.4, 0, seg[1]), V(-149.4, 0, seg[2]), 9))
	end

	------------------------------------------------------------------
	-- Escalera a la azotea del cuartel general (por el oeste)
	------------------------------------------------------------------
	G.stairs(V(-30, 0, -2), V(-14, HQ_TOP, -2), 4.4, "Concrete", { Rails = "Both", Cap = true, Closed = true })

	------------------------------------------------------------------
	-- BARRACONES (norte): dos barracones que se cruzan por dentro
	------------------------------------------------------------------
	T.barrack(T, CF(-80, 0, -98), 30, 12)
	T.barrack(T, CF(-74, 0, -70), 30, 12, { Awning = false })

	------------------------------------------------------------------
	-- TORRE DE VIGILANCIA (norte, junto al patio): escalera desde el sur
	------------------------------------------------------------------
	local _, roof, walls = T.watchtower(CF(-54, 0, -44), TOWER, "Back")
	T.cap(roof)
	T.cap(walls)
	G.stairs(V(-54, 0, -24.6), V(-54, TOWER, -40.6), 3.6, "Wood", { Rails = "Both", Cap = true, RailLook = "WoodDark" })

	------------------------------------------------------------------
	-- DEPÓSITO DE COMBUSTIBLE (sur): pasarela de carga a 6 con escalera
	------------------------------------------------------------------
	G.floor(CF(-74, GANTRY, 70), 16, 6, "Deck", 1.4)
	for _, x in { -81.5, -66.5 } do
		for _, z in { 67.5, 72.5 } do
			G.column(CF(x, 0, z), GANTRY - 1.4, 0.6, "SteelDark")
		end
	end
	G.railing(V(-82, GANTRY, 72.8), V(-66, GANTRY, 72.8), "Yellow", 3.2, { Cap = true })
	G.railing(V(-82, GANTRY, 67.2), V(-66, GANTRY, 67.2), "Yellow", 3.2, { Cap = true })
	G.railing(V(-81.8, GANTRY, 67.2), V(-81.8, GANTRY, 72.8), "Yellow", 3.2, { Cap = true })
	G.stairs(V(-56, 0, 69), V(-66, GANTRY, 69), 3.6, "Steel", { Rails = "Both", Cap = true })
end

return Geometry
