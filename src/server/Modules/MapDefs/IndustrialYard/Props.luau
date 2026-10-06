-- INDUSTRIAL YARD · props: máquinas y palés de la nave (B), bombas y válvulas de la planta (A),
-- montones de grava con cinta y pala cargadora, patio de almacenaje con contenedores, focos y la
-- zona industrial alrededor (naves y torres de refrigeración al fondo).
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0)

function Props.build(T)
	local night = T.isNight()

	---------------------------------------------------------------------------
	-- Centro: letras, carteles
	---------------------------------------------------------------------------
	T.letterBanner(CF(0, 10, 55.4) * CFrame.Angles(0, math.pi, 0), "B", "Blue", 5, 5.4)
	T.sign(CF(0, 13.6, 55.4) * CFrame.Angles(0, math.pi, 0), "NAVE 2 · PRODUCCIÓN", 26, 2.6, RGB(226, 120, 36), RGB(255, 255, 255), { PPS = 16 })
	T.letterBanner(CF(0, 4.4, -104) * CFrame.Angles(0, math.pi, 0), "A", "Red", 5, 5.4)
	T.sign(CF(0, 7.6, -12.4) * CFrame.Angles(0, math.pi, 0), "CALDERAS", 10, 1.6, RGB(64, 66, 70), RGB(255, 200, 120))
	T.sign(CF(0, 7.6, 12.4), "CALDERAS", 10, 1.6, RGB(64, 66, 70), RGB(255, 200, 120))

	T.mirrored("IndustrialProps", function()
		Props.half(T)
	end)

	---------------------------------------------------------------------------
	-- Fondo: naves industriales y torres de refrigeración
	---------------------------------------------------------------------------
	local palette = { RGB(150, 140, 128), RGB(120, 112, 104), RGB(170, 164, 152), RGB(132, 96, 78), RGB(100, 104, 110) }
	T.skylineRing(V(0, 0, 0), 240, 0, 355, 12, palette, { Lit = night, MinH = 14, VarH = 18, TowerEvery = 6, TowerExtra = 20, FloorH = 6 })
	for _, spec in { { V(-190, 0, -260), 46 }, { V(-120, 0, -290), 40 }, { V(260, 0, 200), 44 } } do
		local tower = T.Kit.cylinder("CoolingTower", 60, spec[2], CF(spec[1] + V(0, 30, 0)), RGB(186, 182, 172), M.Concrete, nil, true)
		tower.CastShadow = false
		T.Kit.cylinder("CoolingTowerRim", 3, spec[2] * 0.82, CF(spec[1] + V(0, 61.5, 0)), RGB(150, 146, 138), M.Concrete, nil, true).CastShadow = false
	end
	for _, x in { -230, 230 } do
		T.chimney(CF(x, 0, -200), 70, 7)
	end
end

-- Mitad del Rojo (X < 0)
function Props.half(T)
	local G = T.G
	local night = T.isNight()

	------------------------------------------------------------------
	-- PLANTA (A): bombas, válvulas, depósito pequeño
	------------------------------------------------------------------
	T.cap(G.solid("PumpSkid", V(6, 3.6, 4), CF(-10, 0, -98), "PipeBlue"))
	T.cap(G.solid("ValveManifold", V(3, 5.4, 8), CF(-34, 0, -80), "PipeGreen"))
	-- Filtros verticales a los lados de A (cortan la línea de lado a lado por la planta)
	for _, z in { -88, -73 } do
		T.cap(T.fuelTank(CF(-12, 0, z), 4, 7))
	end
	T.cap(T.horizontalTank(CF(-12, 0, -64), 10, 5))
	T.cap(T.horizontalTank(CF(-30, 0, -52), 12, 5))
	T.barrel(CF(-30, 0, -70), "Orange")
	T.barrel(CF(-31.6, 0, -71.6), "Rust")
	T.cap(T.crateStack(CF(-56, 0, -76) * CFrame.Angles(0, rad(12), 0), "Wall"))

	------------------------------------------------------------------
	-- GRAVA (noroeste): montones, cinta y pala cargadora
	------------------------------------------------------------------
	T.heap(CF(-86, 0, -98), 22, 12, 8)
	T.heap(CF(-80, 0, -58) * ALONG_Z, 16, 10, 6, "Rust")
	T.conveyor(V(-62, 1, -98), V(-80, 10, -98), 3)
	T.cap(T.wheelLoader(CF(-104, 0, -74) * CFrame.Angles(0, rad(20), 0)))

	------------------------------------------------------------------
	-- Centro de cada mitad: contenedores y barreras
	------------------------------------------------------------------
	T.cap(T.container(CF(-34, 0, -30) * ALONG_Z, "ContainerRed"))
	T.cap(T.container(CF(-38, 0, 22.4) * ALONG_Z, "ContainerBlue"))
	T.jersey(CF(-50, 0, -20) * ALONG_Z, 8)
	T.cap(T.crateStack(CF(-28, 0, 10) * CFrame.Angles(0, rad(-8), 0), "L"))
	T.cap(T.horizontalTank(CF(-96, 0, -24), 12, 5))

	------------------------------------------------------------------
	-- ALMACENAJE (suroeste): contenedores, palés, contenedor de escombros, carretilla
	------------------------------------------------------------------
	T.cap(T.container(CF(-96, 0, 70) * ALONG_Z, "ContainerYellow"))
	T.cap(T.container(CF(-96, 8.75, 70) * ALONG_Z, "ContainerGray"))
	T.cap(T.container(CF(-72, 0, 98), "ContainerRed"))
	T.cap(G.solid("PalletStack", V(6, 3.6, 6), CF(-62, 0, 64), "Wood"))
	T.cap(G.solid("PalletStack", V(6, 5.4, 6), CF(-80, 0, 48), "Wood"))
	T.skip(CF(-112, 0, 96))
	T.Kit.forklift(CF(-68, 0, 80) * CFrame.Angles(0, rad(-60), 0))

	------------------------------------------------------------------
	-- NAVE (B, mitad): máquinas, palés, cinta
	------------------------------------------------------------------
	T.cap(T.machine(CF(-30, 0, 76), 6, 8, 7))
	T.cap(T.machine(CF(-14, 0, 92), 5, 5, 6))
	T.cap(T.machine(CF(-37, 0, 84), 5, 6, 6.4))
	T.cap(G.solid("PalletStack", V(5, 4, 6), CF(-38, 0, 64), "Wood"))
	T.cap(T.crateStack(CF(-12, 0, 66), "L"))
	G.box("ConveyorTable", V(14, 2.6, 3), CF(-28, 1.3, 98), "SteelDark")

	------------------------------------------------------------------
	-- Base y focos
	------------------------------------------------------------------
	local lamp = G.deco("BaseLight", V(14, 0.3, 1.2), CF(-136, 9.1, 0), { RGB(255, 240, 210), M.Neon })
	T.Kit.light(lamp, "PointLight", RGB(255, 236, 200), 20, 0.8)
	T.cap(T.crateStack(CF(-145, 0, -14), "L"))
	G.deco("InnerRoad", V(16, 0.1, 230), CF(-112, 0.05, 0), "Asphalt").CastShadow = false
	for _, p in { V(-118, 0, -50), V(-118, 0, 50), V(-56, 0, 0) } do
		T.floodTower(CF(p), 16, night and RGB(255, 226, 180) or nil)
	end
end

return Props
