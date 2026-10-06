-- DESERT BASE · props: camiones y todoterrenos (A), estanterías y carretilla (B), barreras HESCO y
-- sacos terreros (cobertura del patio), depósitos de combustible, control de acceso, palmeras,
-- focos y montañas de arenisca alrededor.
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local ALONG_X = CFrame.Angles(0, math.pi / 2, 0)

function Props.build(T)
	local G = T.G

	---------------------------------------------------------------------------
	-- Centro: mástil con bandera, letras A y B, contenedor del almacén
	---------------------------------------------------------------------------
	G.box("FlagBase", V(3, 1, 3), CF(0, 0.5, -21), "Concrete")
	G.deco("FlagPole", V(0.4, 18, 0.4), CF(0, 9.5, -21), "Steel")
	G.deco("Flag", V(0.15, 3, 5), CF(0, 16.5, -18.4), "Red").CastShadow = false
	T.letterBanner(CF(0, 8.4, -57.6) * CFrame.Angles(0, math.pi, 0), "A", "Red", 5, 5.4)
	T.letterBanner(CF(0, 9, 55.6), "B", "Blue", 5, 5.4)
	T.cap(T.container(CF(0, 0, 102) * ALONG_X, "ContainerGreen", "ARMORY"))
	T.sign(CF(0, 12, 55.4), "ALMACÉN · DEPOT 7", 22, 2.6, RGB(92, 104, 68), RGB(240, 232, 210), { PPS = 16 })
	T.sign(CF(0, 7.4, -15.6), "MANDO · HQ", 10, 1.6, RGB(92, 104, 68), RGB(240, 232, 210))
	T.sign(CF(0, 7.4, 15.6) * CFrame.Angles(0, math.pi, 0), "MANDO · HQ", 10, 1.6, RGB(92, 104, 68), RGB(240, 232, 210))

	T.mirrored("DesertProps", function()
		Props.half(T)
	end)

	---------------------------------------------------------------------------
	-- Fondo: montañas de arenisca y dunas
	---------------------------------------------------------------------------
	for _, spec in {
		{ V(-120, -40, -330), 120 }, { V(140, -50, -360), 140 }, { V(380, -50, -120), 130 },
		{ V(400, -60, 180), 150 }, { V(80, -50, 360), 130 }, { V(-260, -50, 330), 140 },
		{ V(-420, -60, 60), 150 }, { V(-360, -50, -220), 120 },
	} do
		T.Kit.naturalHill(spec[1], spec[2], M.Sandstone, { Top = M.Sand, TopCount = 3 })
	end
	for _, spec in { { V(-220, -6, -170), 26 }, { V(230, -6, 160), 30 }, { V(200, -6, -190), 24 }, { V(-210, -6, 190), 28 } } do
		workspace.Terrain:FillBall(spec[1], spec[2], M.Sand)
	end
end

-- Mitad del Rojo (X < 0)
function Props.half(T)
	local G = T.G
	local night = T.isNight()

	------------------------------------------------------------------
	-- PARQUE DE VEHÍCULOS (A)
	------------------------------------------------------------------
	T.cap(T.truck(CF(-24, 0, -86)))
	T.cap(T.jeep(CF(-14, 0, -67) * ALONG_X))
	for i, p in { V(-10, 0, -96), V(-12.6, 0, -96.4), V(-11, 0, -93.6) } do
		T.barrel(CF(p) * CFrame.Angles(0, rad(i * 30), 0), "MilGreen")
	end
	T.cap(T.crateStack(CF(-33, 0, -66), "L"))
	T.cap(T.hesco(CF(-24, 0, -54), 2, 3.4))
	T.cap(T.sandbags(V(-8, 0, -104), V(-18, 0, -104), 2.6))

	------------------------------------------------------------------
	-- PATIO DE ARMAS (centro de cada mitad)
	------------------------------------------------------------------
	T.cap(T.hesco(CF(-76, 0, 10) * ALONG_X, 3, 4))
	T.cap(T.hesco(CF(-58, 0, -16), 3, 4))
	T.cap(T.container(CF(-64, 0, 28) * ALONG_X, "ContainerTan", "SUPPLY"))
	T.cap(T.jeep(CF(-92, 0, -8)))
	-- Barreras escalonadas: cada franja del patio queda cortada en algún punto (ver longlines)
	T.cap(T.hesco(CF(-40, 0, 20.4) * ALONG_X, 3, 5.4))
	T.cap(T.hesco(CF(-30, 0, -22.5) * ALONG_X, 3, 5.4))
	T.cap(T.hesco(CF(-34, 0, -72) * ALONG_X, 2, 5.4))
	T.cap(T.tWall(V(-46, 0, 42.5), V(-46, 0, 56), 6))
	T.cap(T.sandbags(V(-50, 0, -50), V(-50, 0, -40), 2.6))
	for _, z in { -22, 22 } do
		T.palm(CF(-20, 0, z), 15)
	end
	T.cap(T.crateStack(CF(-34, 0, -30) * CFrame.Angles(0, rad(10), 0), "Wall"))

	------------------------------------------------------------------
	-- CONTROL DE ACCESO (calle interior) y entrada de la base
	------------------------------------------------------------------
	T.barrierGate(CF(-112, 0, -36), 14)
	T.barrierGate(CF(-112, 0, 36), 14)
	T.cap(G.solid("GuardBooth", V(4, 7, 4), CF(-102, 0, -40), "Building"))
	G.deco("GuardWindow", V(4.1, 1.6, 3), CF(-102, 4.6, -40), { RGB(60, 70, 80), M.Glass }).CastShadow = false
	T.cap(G.solid("GuardBooth", V(4, 7, 4), CF(-102, 0, 40), "Building"))
	G.deco("GuardWindow", V(4.1, 1.6, 3), CF(-102, 4.6, 40), { RGB(60, 70, 80), M.Glass }).CastShadow = false
	G.deco("InnerRoad", V(16, 0.1, 230), CF(-112, 0.05, 0), "Asphalt").CastShadow = false
	for _, z in { -30, 30 } do
		T.palm(CF(-119, 0, z), 14)
	end
	local lamp = G.deco("BaseLight", V(14, 0.3, 1.2), CF(-136, 9.1, 0), { RGB(255, 240, 210), M.Neon })
	T.Kit.light(lamp, "PointLight", RGB(255, 236, 200), 20, 0.8)
	T.cap(T.crateStack(CF(-145, 0, -14), "L"))

	------------------------------------------------------------------
	-- BARRACONES (norte)
	------------------------------------------------------------------
	T.cap(T.truck(CF(-104, 0, -82)))
	T.campNet(CF(-104, 0, -82), 10, 24, 9)
	T.cap(T.crateStack(CF(-62, 0, -88) * CFrame.Angles(0, rad(-12), 0), "Wall"))
	T.cap(T.sandbags(V(-96, 0, -56), V(-86, 0, -56), 2.6))
	T.barrel(CF(-58, 0, -100), "Red")
	T.barrel(CF(-56, 0, -102), "MilGreen")

	------------------------------------------------------------------
	-- DEPÓSITO DE COMBUSTIBLE (sur)
	------------------------------------------------------------------
	T.cap(T.fuelTank(CF(-94, 0, 98), 12, 10))
	T.cap(T.fuelTank(CF(-72, 0, 102), 10, 9))
	T.cap(T.container(CF(-56, 0, 92), "ContainerGreen", "FUEL · 07"))
	T.cap(T.hesco(CF(-94, 0, 84), 3, 3.4))
	T.fuelTruck(CF(-90, 0, 60) * ALONG_X)
	T.cap(T.crateStack(CF(-64, 0, 52), "Wall"))

	------------------------------------------------------------------
	-- ALMACÉN (B, mitad): estanterías, carretilla, palés
	------------------------------------------------------------------
	T.cap(G.solid("Rack", V(3, 8, 10), CF(-30, 0, 80), "MilGreenDark"))
	for _, y in { 2.6, 5.2 } do
		G.deco("RackShelf", V(3.2, 0.2, 10.2), CF(-30, y, 80), "Wood").CastShadow = false
	end
	T.cap(T.crateStack(CF(-20, 0, 66) * CFrame.Angles(0, rad(-8), 0), "L"))
	T.Kit.forklift(CF(-14, 0, 96) * CFrame.Angles(0, math.pi, 0))
	T.cap(G.solid("PalletStack", V(6, 3.4, 6), CF(-12, 0, 74), "Wood"))
	T.cap(G.solid("Rack", V(14, 8, 3), CF(-26, 0, 103), "MilGreenDark"))
	for _, x in { -18 } do
		local panel = G.deco("WarehouseLight", V(10, 0.2, 2), CF(x, 13.6, 70), { RGB(255, 240, 214), M.Neon })
		panel.CastShadow = false
		T.Kit.light(panel, "PointLight", RGB(255, 236, 206), 30, 1)
	end

	------------------------------------------------------------------
	-- Focos (de noche iluminan el patio)
	------------------------------------------------------------------
	for _, p in { V(-100, 0, -48), V(-50, 0, 50), V(-120, 0, 100) } do
		T.floodTower(CF(p), 14, night and RGB(255, 236, 200) or nil)
	end
end

return Props
