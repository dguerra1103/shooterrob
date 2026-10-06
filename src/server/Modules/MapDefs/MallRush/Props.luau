-- MALL RUSH · props: identidad de color (escaparates con rótulos cian, magenta, naranja y morado,
-- banderolas del atrio, puestos de comida), cobertura de interior (quioscos, mesas, jardineras,
-- estanterías, mostradores) y el aparcamiento de cada base. Los rótulos se ponen fuera del espejo
-- para que cada lado tenga sus tiendas.
local Props = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

local L = 12
local TOP = 24

local CYAN, MAGENTA, ORANGE, PURPLE = RGB(0, 186, 214), RGB(226, 40, 140), RGB(250, 140, 30), RGB(130, 70, 200)

function Props.build(T)
	local G = T.G
	local night = T.isNight()

	---------------------------------------------------------------------------
	-- Atrio: fuente, palmeras, jardineras y banderolas (MALL RUSH en el centro)
	---------------------------------------------------------------------------
	T.fountain(CF(0, 0, 0), 10)
	for _, s in { -1, 1 } do
		T.palmPlanter(CF(s * 7, 0, 15), 11)
		T.planter(CF(s * 6, 0, -6) * CFrame.Angles(0, rad(90), 0), 5, 2.6)
	end
	T.hangingBanner(CF(-10, TOP - 1, -21.4), 4.6, 9, CYAN, nil)
	T.hangingBanner(CF(0, TOP - 1, -21.4), 5.4, 9, MAGENTA, "MALL RUSH")
	T.hangingBanner(CF(10, TOP - 1, -21.4), 4.6, 9, ORANGE, nil)
	for _, z in { -12, 12 } do
		local lamp = G.deco("AtriumLight", V(2, 0.4, 2), CF(0, TOP - 0.6, z), { RGB(255, 248, 236), M.Neon })
		T.Kit.light(lamp, "PointLight", RGB(255, 246, 230), 30, 1)
	end

	---------------------------------------------------------------------------
	-- Zona de comida: puestos al fondo, mesas y una palmera en medio
	---------------------------------------------------------------------------
	for i, spec in { { -28, "BITES", ORANGE }, { -10, "SODA", MAGENTA }, { 10, "PIZZA", RGB(214, 50, 40) }, { 28, "NOODLE", CYAN } } do
		T.foodStall(CF(spec[1], 0, -70) * CFrame.Angles(0, math.pi, 0), spec[2], spec[3], 12)
	end
	for _, x in { -30, -18, -6, 6, 18, 30 } do
		for _, z in { -58, -47 } do
			T.tableSet(CF(x, 0, z) * CFrame.Angles(0, rad((x + z) % 30), 0), ({ ORANGE, CYAN, MAGENTA })[((x // 12) % 3) + 1])
		end
	end
	T.palmPlanter(CF(0, 0, -52), 12)
	for _, x in { -20, 20 } do
		local lamp = G.deco("FoodLight", V(14, 0.4, 2), CF(x, TOP - 0.6, -46), { RGB(255, 244, 226), M.Neon })
		T.Kit.light(lamp, "PointLight", RGB(255, 240, 220), 30, 1)
	end

	---------------------------------------------------------------------------
	-- Entrada principal (vestíbulo sur): jardineras, directorio y el rótulo de fuera
	---------------------------------------------------------------------------
	for _, s in { -1, 1 } do
		T.palmPlanter(CF(s * 12, 0, 70), 10)
	end
	T.sign(CF(0, 6, 44) , "DIRECTORIO · PLANTA BAJA Y ALTA", 10, 1.6, RGB(36, 40, 52), RGB(255, 255, 255), { PPS = 18, Back = true })
	G.box("DirectoryStand", V(10, 4.6, 1), CF(0, 2.3, 44), "WallGray")
	local sunrise = T.sign(CF(0, 15, 81.2) * CFrame.Angles(0, math.pi, 0), "♛ SUNRISE MALL", 30, 4, RGB(30, 32, 40), RGB(255, 214, 90), { PPS = 12 })
	sunrise.CastShadow = false

	---------------------------------------------------------------------------
	-- Rótulos, escaparates y lonas de cada lado (fuera del espejo: nombres distintos)
	---------------------------------------------------------------------------
	local names = {
		[-1] = { North = "NEXUS", South = "STYLE", Trend = "TREND", Lobby = "PIXEL", Upper = "GAME ZONE", Big = "BLOX MART", Big2 = "PIXEL WEAR", Facade = "BLOX MART" },
		[1] = { North = "VOLTA", South = "URBAN", Trend = "ARCADE", Lobby = "BEATS", Upper = "SKATE CO.", Big = "MEGA TOYS", Big2 = "SPORT HUB", Facade = "LOADING BAY" },
	}
	for _, s in { -1, 1 } do
		local n = names[s]
		local turnIn = s < 0 and CFrame.Angles(0, -math.pi / 2, 0) or CFrame.Angles(0, math.pi / 2, 0)
		T.storefront(CF(s * 52, 0, -35.6) * CFrame.Angles(0, math.pi, 0), 18, 8, n.North, CYAN, { Depth = 0.7, Shallow = true })
		T.storefront(CF(s * 54, 0, 35.6), 20, 8, n.South, ORANGE, { Depth = 0.7, Shallow = true })
		T.storefront(CF(s * 28, 0, 35.6), 12, 8, n.Trend, MAGENTA, { Depth = 0.7, Shallow = true })
		T.storefront(CF(s * 19.6, 0, 51) * turnIn, 22, 8, n.Lobby, PURPLE, { Depth = 0.7, Shallow = true })
		-- Planta alta
		T.storefront(CF(s * 95, L, -19.6) * CFrame.Angles(0, math.pi, 0), 30, 8, n.Upper, PURPLE, { Depth = 0.7, Shallow = true })
		T.storefront(CF(s * 95, L, 19.6), 30, 8, n.Big2, ORANGE, { Depth = 0.7, Shallow = true })
		T.storefront(CF(s * 52, L, -35.6) * CFrame.Angles(0, math.pi, 0), 18, 8, n.North .. " +", MAGENTA, { Depth = 0.7, Shallow = true })
		T.storefront(CF(s * 54, L, 35.6), 20, 8, n.South .. " +", CYAN, { Depth = 0.7, Shallow = true })
		-- Rótulos de las tiendas grandes (sobre sus escaparates de la galería)
		T.sign(CF(s * 88, 9.4, -19.4) * CFrame.Angles(0, math.pi, 0), n.Big, 10, 1.8, s < 0 and RGB(30, 110, 200) or RGB(214, 50, 40), RGB(255, 255, 255), { PPS = 18 })
		T.sign(CF(s * 106, 9.4, 19.4), n.Big2, 10, 1.8, ORANGE, RGB(255, 255, 255), { PPS = 18 })
		-- Fachada exterior (sobre las puertas del aparcamiento)
		local facade = T.sign(CF(s * 119.2, 16, 0) * turnIn * CFrame.Angles(0, math.pi, 0), n.Facade, 26, 4, s < 0 and RGB(30, 110, 200) or RGB(36, 40, 52), RGB(255, 255, 255), { PPS = 12 })
		facade.CastShadow = false
		-- Lona del sitio colgando sobre el patio y letrero del pasillo de servicio
		local letter = s < 0 and "A" or "B"
		T.hangingBanner(CF(s * 50, TOP - 1, -13.4), 6, 8, s < 0 and RGB(214, 50, 60) or RGB(40, 120, 220), letter)
		T.sign(CF(s * 64.4, 5, -60) * turnIn * CFrame.Angles(0, math.pi, 0), letter .. " →", 3, 1.4, s < 0 and RGB(214, 50, 60) or RGB(40, 120, 220), RGB(255, 255, 255), { PPS = 30 })
	end

	T.mirrored("MallProps", function()
		Props.half(T)
	end)

	-- Fondo: árboles y calles alrededor del centro comercial, ciudad baja
	for x = -140, 140, 28 do
		for _, z in { -96, 96 } do
			T.tree(CF(x + (z > 0 and 10 or 0), 0, z))
		end
	end
	G.deco("Street", V(600, 0.1, 18), CF(0, 0.05, 112), "Parking").CastShadow = false
	G.deco("Street", V(600, 0.1, 18), CF(0, 0.05, -112), "Parking").CastShadow = false
	T.skylineRing(V(0, 0, 0), 230, 0, 355, 12, { RGB(214, 206, 196), RGB(190, 196, 206), RGB(224, 214, 200), RGB(200, 184, 176) }, { Lit = night, MinH = 18, VarH = 30, TowerEvery = 5, TowerExtra = 40, FloorH = 7 })
end

-- Mitad del Rojo (X < 0)
function Props.half(T)
	local G = T.G

	------------------------------------------------------------------
	-- Vestíbulo: mostrador de información delante de las puertas (tapa la vista desde fuera)
	------------------------------------------------------------------
	G.box("InfoDesk", V(3, 3.4, 8), CF(-114, 1.7, 0), "WallGray")
	G.deco("InfoStripe", V(3.1, 0.8, 8.1), CF(-114, 2.6, 0), "Magenta")
	T.planter(CF(-114, 0, -16), 5, 2.6)
	T.planter(CF(-114, 0, 16), 5, 2.6)
	G.box("Bench", V(6, 1.6, 2), CF(-84, 0.8, 14), "WallGray")
	G.box("Bench", V(6, 1.6, 2), CF(-84, 0.8, -14), "WallGray")
	for _, x in { -104, -84 } do
		local lamp = G.deco("HallLight", V(10, 0.4, 2), CF(x, L - 0.6, 0), { RGB(255, 248, 236), M.Neon })
		if x == -84 then
			T.Kit.light(lamp, "PointLight", RGB(255, 246, 230), 26, 0.9)
		end
	end

	------------------------------------------------------------------
	-- Patio (sitio): quioscos que cortan la galería, jardineras y bancos
	------------------------------------------------------------------
	T.kiosk(CF(-50, 0, -10), RGB(0, 186, 214), "CAFÉ")
	T.kiosk(CF(-50, 0, 11), RGB(250, 140, 30), "ZUMOS")
	T.planter(CF(-62, 0, 0) * CFrame.Angles(0, rad(90), 0), 6, 2.6)
	T.planter(CF(-38, 0, -18), 6, 2.6)
	T.planter(CF(-38, 0, 18), 6, 2.6)
	local courtLamp = G.deco("CourtLight", V(2, 0.4, 2), CF(-50, TOP - 0.6, 0), { RGB(255, 248, 236), M.Neon })
	T.Kit.light(courtLamp, "PointLight", RGB(255, 246, 230), 30, 1)

	------------------------------------------------------------------
	-- BLOX MART: estanterías en hileras (cobertura alta con pasillos) y cajas registradoras
	------------------------------------------------------------------
	for _, z in { -34, -46, -58 } do
		for _, seg in { { -114, -96 }, { -92, -78 } } do
			G.box("Shelf", V(seg[2] - seg[1], 6, 2.4), CF((seg[1] + seg[2]) / 2, 3, z), "WallGray")
			G.deco("ShelfGoods", V(seg[2] - seg[1] - 0.4, 4.6, 2.6), CF((seg[1] + seg[2]) / 2, 3.4, z), { z == -46 and RGB(230, 120, 40) or RGB(40, 140, 200), M.SmoothPlastic })
		end
	end
	for _, x in { -112, -104 } do
		G.box("Checkout", V(3, 3, 6), CF(x, 1.5, -25), "Wall")
	end
	local bloxLamp = G.deco("StoreLight", V(30, 0.4, 2), CF(-95, L - 0.6, -46), { RGB(255, 252, 244), M.Neon })
	T.Kit.light(bloxLamp, "PointLight", RGB(255, 250, 240), 30, 0.9)

	------------------------------------------------------------------
	-- PIXEL WEAR: percheros, mesas de exposición y maniquíes
	------------------------------------------------------------------
	for _, spec in { { -108, 32 }, { -92, 32 }, { -108, 48 }, { -84, 50 }, { -100, 62 } } do
		G.box("DisplayTable", V(8, 2.6, 4), CF(spec[1], 1.3, spec[2]), "Wall")
		G.deco("Clothes", V(7, 0.6, 3.4), CF(spec[1], 2.9, spec[2]), { RGB(226, 40, 140), M.Fabric })
	end
	for _, z in { 30, 42, 54, 66 } do
		G.box("ClothesRack", V(1, 5, 7), CF(-78, 2.5, z), "Steel")
	end
	local pixelLamp = G.deco("StoreLight", V(30, 0.4, 2), CF(-95, L - 0.6, 46), { RGB(255, 252, 244), M.Neon })
	T.Kit.light(pixelLamp, "PointLight", RGB(255, 250, 240), 30, 0.9)

	------------------------------------------------------------------
	-- Pasillo de servicio: cajas, carro y luz fría
	------------------------------------------------------------------
	T.crateStack(CF(-96, 0, -76) * CFrame.Angles(0, rad(90), 0), "L")
	T.crateStack(CF(-56, 0, -76) * CFrame.Angles(0, rad(90), 0), "Wall")
	T.crate(CF(-68, 0, -64), 4)
	T.crate(CF(-68.4, 0, -28) * CFrame.Angles(0, rad(10), 0), 3.6)
	local serviceLamp = G.deco("ServiceLight", V(1.2, 0.3, 12), CF(-68, 9.7, -46), { RGB(220, 236, 255), M.Neon })
	T.Kit.light(serviceLamp, "PointLight", RGB(210, 230, 255), 18, 0.7)

	------------------------------------------------------------------
	-- Pasillos sur, zona de la escalera mecánica y jardineras del anillo
	------------------------------------------------------------------
	G.box("Bench", V(6, 1.6, 2), CF(-50, 0.8, 28), "WallGray")
	T.planter(CF(-40, 0, 72), 6, 2.6)
	T.planter(CF(-30, L, -30), 6, 2.6)
	T.planter(CF(-66, L, -30), 6, 2.6)
	T.planter(CF(-30, L, 30), 6, 2.6)

	------------------------------------------------------------------
	-- Exterior: azotea con máquinas y pretil blanco; fachada con paneles de color y cristal
	------------------------------------------------------------------
	for _, spec in { { -100, -60 }, { -84, -40 }, { -100, 40 }, { -76, 64 }, { -56, -60 }, { -40, 50 } } do
		T.hvac(CF(spec[1], TOP + 1, spec[2]) * CFrame.Angles(0, rad(spec[1] % 90), 0))
	end
	G.deco("RoofEdge", V(1.2, 1.4, 162), CF(-118.2, TOP + 1.2, 0), "Wall")
	G.deco("RoofEdge", V(118, 1.4, 1.2), CF(-59, TOP + 1.2, -80.2), "Wall")
	G.deco("RoofEdge", V(118, 1.4, 1.2), CF(-59, TOP + 1.2, 80.2), "Wall")
	for _, spec in { { -40, "Cyan" }, { -24, "Orange" }, { 24, "Magenta" }, { 40, "Cyan" } } do
		G.deco("FacadePanel", V(0.6, TOP - 2, 8), CF(-118.9, (TOP - 2) / 2 + 1, spec[1]), spec[2]).CastShadow = false
	end
	local glass = G.deco("FacadeGlass", V(0.4, 9, 30), CF(-118.9, 15, 0), "Glass")
	glass.Transparency = 0.3

	------------------------------------------------------------------
	-- Aparcamiento (base): camión de reparto, coches, carros de la compra, árboles y farolas
	------------------------------------------------------------------
	-- (camión y furgoneta a lo largo de la fachada: pasillo de 6 entre ellos y las puertas)
	local truck = CF(-127, 0, -6)
	T.cap(G.solid("BoxTruck", V(6, 7, 15), truck * CF(0, 0.8, 2), "Wall"))
	G.solid("TruckCab", V(6, 5.6, 4.6), truck * CF(0, 0.8, -8), "Magenta")
	G.deco("TruckLogo", V(6.1, 3, 8), truck * CF(0, 5, 2), "Cyan")
	for _, z in { -8, 0, 6 } do
		for _, x in { -2.9, 2.9 } do
			T.Kit.pipe("TruckWheel", 0.9, 2.2, truck * CF(x, 1.1, z), RGB(24, 24, 26), M.Rubber, true)
		end
	end
	T.cap(T.van(CF(-127, 0, 14), RGB(226, 40, 140)))
	-- Tótem publicitario entre el camión y la furgoneta
	T.cap(G.box("AdTotem", V(2.6, 9, 4), CF(-127, 4.5, 5.5), "Magenta"))
	T.sign(CF(-125.6, 6, 5.5) * CFrame.Angles(0, -math.pi / 2, 0), "SALE -50%", 3.6, 5, RGB(226, 40, 140), RGB(255, 255, 255), { PPS = 20 })
	T.Kit.car(CF(-142, 0, 40) * CFrame.Angles(0, rad(90), 0), RGB(40, 120, 220))
	T.Kit.car(CF(-142, 0, -42) * CFrame.Angles(0, rad(-90), 0), RGB(240, 240, 244))
	for z = -54, 54, 12 do
		G.paintLine(V(-150, 0, z), V(-138, 0, z), 0.4, "Paint")
	end
	T.lampPost(CF(-122, 0, -30) * CFrame.Angles(0, rad(90), 0))
	T.lampPost(CF(-122, 0, 30) * CFrame.Angles(0, rad(90), 0))
	for i = 0, 2 do
		G.deco("ShoppingCart", V(2, 2.4, 3), CF(-121, 1.2, 30 + i * 1.2), "Steel")
	end
end

return Props
