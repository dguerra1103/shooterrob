-- DOCKYARD · props: buque amarrado y grúas lejanas (fondo), bitas y tapas de escotilla en el
-- muelle, camiones con contenedor en la puerta de camiones, interior del tinglado (contenedores
-- frigoríficos, estanterías, palés, carretillas), focos y señalética A/B.
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0)

function Props.build(T)
	local G = T.G

	---------------------------------------------------------------------------
	-- Centro: letras, carteles, buque
	---------------------------------------------------------------------------
	T.letterBanner(CF(0, 9.5, 61.4) * CFrame.Angles(0, math.pi, 0), "B", "Blue", 5, 5.4)
	T.sign(CF(0, 13.5, 61.4) * CFrame.Angles(0, math.pi, 0), "TINGLADO 3 · TRANSIT SHED", 30, 2.6, RGB(40, 96, 190), RGB(255, 255, 255), { PPS = 16 })
	T.cap(G.solid("DockLeveler", V(6, 3, 5), CF(0, 4, 58), "SteelDark"))
	local aSign = T.sign(CF(0, 7, -94.9) * CFrame.Angles(0, math.pi, 0), "A", 3, 3, RGB(200, 54, 42), RGB(255, 255, 255))
	aSign.CastShadow = false
	T.ship(CF(0, -4, -140), 220)
	-- Puerto al fondo: grúas y pilas de contenedores lejanas (decorado)
	for _, x in { -260, -200, 200, 260 } do
		T.stsCrane(CF(x, 0, -150), { Span = 18, Gauge = 22, Look = x < 0 and "CraneBlue" or "CraneRed", Height = 30 })
	end
	local palette = { RGB(150, 156, 164), RGB(120, 132, 150), RGB(184, 186, 190), RGB(100, 110, 128) }
	T.skylineRing(V(0, 0, 60), 260, 30, 330, 14, palette, { Lit = T.isNight(), MinH = 20, VarH = 30, TowerEvery = 5, TowerExtra = 30, FloorH = 6 })

	T.mirrored("DockProps", function()
		Props.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Props.half(T)
	local G = T.G
	local night = T.isNight()

	------------------------------------------------------------------
	-- MUELLE (A): bitas, tapas de escotilla, bobinas
	------------------------------------------------------------------
	for x = -140, -10, 20 do
		T.mooringBollard(CF(x, 0, -102.2))
	end
	T.cap(G.solid("HatchCover", V(8, 5.4, 17), CF(-30, 0, -87.5), "Hull"))
	G.deco("HatchStripe", V(8.1, 0.6, 17.1), CF(-30, 4.6, -87.5), "YellowPaint").CastShadow = false
	T.cableSpool(CF(-46, 0, -66))
	T.cap(T.crateStack(CF(-60, 0, -92), "Wall"))
	T.cap(G.solid("LashingCage", V(6, 3.2, 4), CF(-8, 0, -66), "SteelDark"))

	------------------------------------------------------------------
	-- PUERTA DE CAMIONES (suroeste): camiones con contenedor y casetas
	------------------------------------------------------------------
	T.cap(T.containerTruck(CF(-96, 0, 74), "ContainerBlue"))
	T.cap(T.containerTruck(CF(-80, 0, 98) * CFrame.Angles(0, math.pi, 0), "ContainerRed"))
	T.cap(G.solid("GateBooth", V(4, 7, 4), CF(-108, 0, 50), "Building"))
	G.deco("GateBoothWindow", V(4.1, 1.6, 3), CF(-108, 4.6, 50), { RGB(60, 70, 80), M.Glass }).CastShadow = false
	T.barrierGate(CF(-112, 0, 42), 14)
	G.deco("InnerRoad", V(16, 0.1, 210), CF(-112, 0.05, 10), "ConcreteDark").CastShadow = false

	------------------------------------------------------------------
	-- PLAYA DE CONTENEDORES: barreras y bidones en las calles
	------------------------------------------------------------------
	T.jersey(CF(-84, 0, -6) * ALONG_Z, 8)
	T.jersey(CF(-84, 0, 8) * ALONG_Z, 8)
	T.cap(T.crateStack(CF(-30, 0, 4), "L"))
	T.barrel(CF(-74, 0, 18), "Red")
	T.barrel(CF(-72.4, 0, 19.6), "Blue")
	T.cap(T.crateStack(CF(-90, 0, -40) * CFrame.Angles(0, rad(10), 0), "Wall"))

	------------------------------------------------------------------
	-- TINGLADO (B, mitad): contenedor frigorífico, estanterías, palés, carretilla
	------------------------------------------------------------------
	T.cap(T.container(CF(-28, 4, 96), "ContainerYellow", "REEFER"))
	T.cap(G.solid("Rack", V(3, 8, 14), CF(-34, 4, 80), "SteelDark"))
	for _, y in { 2.6, 5.2 } do
		G.deco("RackShelf", V(3.2, 0.2, 14.2), CF(-34, 4 + y, 80), "Wood").CastShadow = false
	end
	T.cap(G.solid("PalletStack", V(6, 3.4, 6), CF(-14, 4, 76), "Wood"))
	T.cap(G.solid("PalletStack", V(5, 4, 6), CF(-36, 4, 90), "Wood"))
	T.cap(T.crateStack(CF(-16, 4, 92), "L"))
	T.Kit.forklift(CF(-22, 4, 70) * CFrame.Angles(0, rad(90), 0))

	------------------------------------------------------------------
	-- Base y focos
	------------------------------------------------------------------
	local lamp = G.deco("BaseLight", V(14, 0.3, 1.2), CF(-136, 9.1, 0), { RGB(255, 240, 210), M.Neon })
	T.Kit.light(lamp, "PointLight", RGB(255, 236, 200), 20, 0.8)
	T.cap(T.crateStack(CF(-145, 0, -14), "L"))
	for _, p in { V(-118, 0, -60), V(-100, 0, 30), V(-60, 0, 58) } do
		T.floodTower(CF(p), 16, night and RGB(255, 236, 200) or nil)
	end
end

return Props
