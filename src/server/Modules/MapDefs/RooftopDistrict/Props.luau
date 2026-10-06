-- ROOFTOP DISTRICT · props: máquinas de aire, depósitos, antenas, placas solares, lucernarios y
-- pantallas (cobertura e identidad de azotea), la azotea A en rojo y la B en azul, y la ciudad.
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local STREET = -40

function Props.build(T)
	local G = T.G
	local night = T.isNight()
	local RED, BLUE = RGB(200, 52, 48), RGB(40, 104, 210)

	---------------------------------------------------------------------------
	-- AZOTEA A (4): cuarto de escalera con toldo rojo, máquinas rojas y cajas junto al sitio
	---------------------------------------------------------------------------
	T.cap(G.solid("StairHouseA", V(12, 8, 8), CF(0, 4, -94), "BuildingLight"))
	T.Kit.awning(CF(0, 4 + 6.4, -89.9), 12, 3, RED)
	T.letterBanner(CF(0, 4 + 4.2, -89.8), "A", "Red", 5, 5.4)
	for _, s in { -1, 1 } do
		T.hvac(CF(s * 12, 4, -70) * CFrame.Angles(0, rad(90), 0), { RED, M.Metal })
		T.hvac(CF(s * 30, 4, -88), { RGB(196, 198, 200), M.Metal })
		T.cap(T.crateStack(CF(s * 22, 4, -64) * CFrame.Angles(0, rad(s * 15), 0), "L"))
		T.planter(CF(s * 44, 4, -66) * CFrame.Angles(0, rad(90), 0), 6, 3)
		T.dish(CF(s * 50, 4, -94))
	end
	T.blockPallet(CF(0, 4, -66), 2)

	---------------------------------------------------------------------------
	-- AZOTEA B (0): lucernarios (cobertura baja), depósito y máquinas azules
	---------------------------------------------------------------------------
	for _, s in { -1, 1 } do
		T.skylight(CF(s * 14, 0, 72), 8)
		T.skylight(CF(s * 14, 0, 88), 8)
		T.hvac(CF(s * 34, 0, 66), { BLUE, M.Metal })
		T.solarRow(CF(s * 40 - 4, 0, 92), 2)
		T.crateStack(CF(s * 28, 0, 82) * CFrame.Angles(0, rad(s * -10), 0), "Wall")
	end
	T.cap(G.solid("StairHouseB", V(12, 8, 8), CF(0, 0, 95), "BuildingLight"))
	T.letterBanner(CF(0, 4.6, 90.8), "B", "Blue", 5, 5.4)
	T.waterTank(CF(0, 8, 95))

	---------------------------------------------------------------------------
	-- CENTRO (6): máquinas a los lados de la pantalla
	---------------------------------------------------------------------------
	for _, s in { -1, 1 } do
		for _, z in { -18, 18 } do
			T.hvac(CF(s * 18, 6, z) * CFrame.Angles(0, rad(90), 0))
		end
		T.planter(CF(s * 32, 6, 0) * CFrame.Angles(0, rad(90), 0), 6, 3)
	end

	T.mirrored("RooftopProps", function()
		Props.half(T)
	end)

	---------------------------------------------------------------------------
	-- Calle de abajo, ciudad alrededor y grúa lejana
	---------------------------------------------------------------------------
	for _, z in { -46, 46 } do
		G.paintLine(V(-300, STREET + 0.2, z), V(300, STREET + 0.2, z), 0.5, "Paint")
	end
	T.van(CF(-20, STREET + 0.2, -42) * CFrame.Angles(0, rad(90), 0), RGB(214, 50, 40))
	T.Kit.car(CF(30, STREET + 0.2, 44) * CFrame.Angles(0, rad(-90), 0), RGB(40, 104, 210))
	local palette = { RGB(160, 168, 180), RGB(96, 122, 160), RGB(196, 198, 204), RGB(84, 92, 106), RGB(150, 88, 72), RGB(120, 140, 170) }
	T.skylineRing(V(0, STREET, 0), 200, 0, 355, 9, palette, { Lit = night, MinH = 60, VarH = 40, TowerEvery = 4, TowerExtra = 60, FloorH = 7 })
	T.skylineRing(V(0, STREET, 0), 300, 4, 356, 12, palette, { Lit = night, MinH = 80, VarH = 60, TowerEvery = 3, TowerExtra = 80, FloorH = 10 })
	T.towerCrane(CF(-150, STREET, -220) * CFrame.Angles(0, rad(150), 0), 120, { Jib = 60, Load = false })
end

-- Mitad del Rojo (X < 0)
function Props.half(T)
	local G = T.G
	local RED = RGB(200, 52, 48)

	-- Base: cajas y jardineras bajo la marquesina
	T.cap(T.crateStack(CF(-146, 0, -26), "L"))
	T.planter(CF(-120, 0, -30), 6, 3)
	T.planter(CF(-120, 0, 30), 6, 3)
	local lamp = G.deco("CanopyLight", V(16, 0.3, 1.2), CF(-135, 9.2, 0), { RGB(240, 246, 255), M.Neon })
	T.Kit.light(lamp, "PointLight", RGB(236, 244, 255), 20, 0.8)

	-- Bloque oeste: máquinas, placas solares, parabólica, cajas (cobertura de paso)
	T.hvac(CF(-100, 0, -20))
	T.hvac(CF(-100, 0, 22) * CFrame.Angles(0, rad(90), 0))
	T.solarRow(CF(-104, 0, -30), 3)
	T.dish(CF(-70, 0, 30))
	T.cap(T.crateStack(CF(-80, 0, -26) * CFrame.Angles(0, rad(12), 0), "L"))
	T.crateStack(CF(-86, 0, 26), "Wall")
	T.planter(CF(-104, 0, 8) * CFrame.Angles(0, rad(90), 0), 6, 3)

	-- Torre NO: antena en la plataforma alta, depósito, pantalla mirando al norte del mapa
	T.cap(T.antennaTower(CF(-97, 14, -90), 22))
	T.waterTank(CF(-80, 6, -96))
	T.hvac(CF(-100, 6, -60))
	T.cap(T.crateStack(CF(-80, 6, -62), "L"))
	T.cap(T.billboardScreen(CF(-90, 6, -98) * CFrame.Angles(0, math.pi, 0), 14, 7, "NEXT DROP 07.25", RGB(30, 80, 170)))

	-- Suroeste: depósito sobre su plataforma, máquinas, pantalla roja
	T.waterTank(CF(-95, 8, 87))
	T.hvac(CF(-100, 0, 60))
	T.cap(T.crateStack(CF(-80, 0, 64) * CFrame.Angles(0, rad(-20), 0), "L"))
	T.solarRow(CF(-106, 0, 70), 2)
	T.cap(T.billboardScreen(CF(-90, 0, 98), 14, 7, "CITY LIGHTS", RED))

	-- Pantallas en las fachadas (se ven desde los puentes)
	local facade = G.deco("FacadeScreen", V(0.3, 14, 20), CF(-71.7, -10, -78), "Screen")
	T.Kit.sign(facade, Enum.NormalId.Right, "ROOFTOP", RGB(230, 244, 255), RGB(30, 80, 170)).LightInfluence = 0.2
	local facade2 = G.deco("FacadeScreen", V(0.3, 12, 18), CF(-65.7, -14, 0), "Red")
	T.Kit.sign(facade2, Enum.NormalId.Right, "DISTRICT", RGB(255, 236, 230), RED).LightInfluence = 0.2
end

return Props
