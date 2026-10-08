-- CONSTRUCCIÓN · acabados (Fase 14, pulido visual sin tocar el juego). Todo es decorado: no choca
-- ni para balas, así que rutas, coberturas, sitios y líneas de tiro son los de siempre.
--
--   * Suelo por zonas: la plaza A con adoquín cálido, el patio central de hormigón gastado, el patio B
--     de hormigón frío, grava en las bases y asfalto en los dos carriles. El mapa deja de ser una
--     losa gris y cada zona se reconoce por el suelo.
--   * Torre (hito central): lonas de la promotora en las caras de la planta baja que dan a los
--     sitios, zócalo oscuro y encofrado de madera en los pilares de la última planta (obra en curso).
--   * Identidad A / B: el edificio A con remates terracota (cálido, como su lona roja) y el B con
--     remates azul acero (frío, como su lona azul).
--   * Fondo: ciudad industrial (chimeneas, gasómetros y un esqueleto de edificio con su grúa).
--   * Señalética de salida dentro de cada base (sin flechas: vale igual en el espejo).
local Dressing = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB
local rad = math.rad

local L = 10

function Dressing.build(T)
	local F = T.F

	---------------------------------------------------------------------------
	-- Suelo por zonas (centro del mapa; las bases y carriles van en la mitad en espejo)
	---------------------------------------------------------------------------
	F.groundZone(CF(0, 0, -87), 70, 32, "Pavers", "PlazaPavers")
	F.zoneEdge(CF(0, 0, -87), 70, 32, "ConcreteDark", 0.5)
	F.groundZone(CF(0, 0, 0), 120, 76, "ConcreteWorn", "PatioSlab")
	F.groundZone(CF(0, 0, 57), 70, 38, "ConcreteCool", "PatioBSlab")
	F.zoneEdge(CF(0, 0, 57), 70, 38, "ConcreteDark", 0.5)

	---------------------------------------------------------------------------
	-- TORRE: lonas en las caras que miran a los sitios, zócalo y encofrados arriba
	---------------------------------------------------------------------------
	local yellow, ink = RGB(246, 194, 40), RGB(28, 28, 32)
	-- (dos lonas por cara, a los lados de los pilares de la pasarela, que caen en el centro)
	for _, face in { { -16.3, 0 }, { 16.3, math.pi } } do
		for _, spec in { { -9.6, "ROBUILD" }, { 9.6, "TORRE 05" } } do
			local x = face[2] == 0 and spec[1] or -spec[1]
			F.banner(CF(x, 5, face[1]) * CFrame.Angles(0, face[2], 0), 11, 6, spec[2], yellow, ink, { Stripe = ink, TextScale = 0.5 })
		end
	end
	-- (y en las caras que miran a las bases, junto a la puerta: lo primero que se ve al salir)
	for _, s in { -1, 1 } do
		F.banner(CF(s * 16.3, 5, 5) * CFrame.Angles(0, -s * math.pi / 2, 0), 13, 6, "OBRA 05", yellow, ink, { Stripe = ink, TextScale = 0.5 })
	end
	for _, spec in { { V(-16, 0, -16), V(16, 0, -16), V(0, 0, -1) }, { V(-16, 0, 16), V(16, 0, 16), V(0, 0, 1) } } do
		F.band(spec[1], spec[2], 0, 1.2, 0.3, "ConcreteDark", spec[3], "Plinth")
	end
	for _, p in { V(-15.6, 0, -15.6), V(15.6, 0, -15.6), V(-15.6, 0, 15.6), V(15.6, 0, 15.6) } do
		F.formwork(CF(p + V(0, 4 * L + 1, 0)), 2.6, 4.5)
	end

	---------------------------------------------------------------------------
	-- EDIFICIO A (fachada a la plaza en z -108): cornisa y esquinas terracota, zócalo oscuro
	---------------------------------------------------------------------------
	local facadeA, outA = -107.95, V(0, 0, 1)
	F.band(V(-30.4, 0, facadeA), V(30.4, 0, facadeA), 26.4, 1.1, 0.7, "Terracotta", outA, "Cornice")
	F.pilasters(V(-30, 0, facadeA), V(30, 0, facadeA), 60, 0, 27.5, 1.6, 0.6, "Terracotta", outA, nil, "CornerPier")
	for _, seg in { { -29.2, -15.6 }, { -8.4, 8.4 }, { 15.6, 29.2 } } do
		F.band(V(seg[1], 0, facadeA), V(seg[2], 0, facadeA), 0, 1.3, 0.3, "ConcreteDark", outA, "Plinth")
	end

	---------------------------------------------------------------------------
	-- EDIFICIO B (fachada al patio B en z 76): remate azul acero en el borde de la cubierta y
	-- esquinas, zócalo oscuro (sin tapar el portón ni las ventanas)
	---------------------------------------------------------------------------
	local facadeB, outB = 75.95, V(0, 0, -1)
	F.band(V(-36.4, 0, facadeB), V(36.4, 0, facadeB), 21.9, 1.1, 0.7, "SteelBlue", outB, "Cornice")
	F.pilasters(V(-36, 0, facadeB), V(36, 0, facadeB), 72, 0, 23, 1.6, 0.6, "SteelBlue", outB, nil, "CornerPier")
	for _, seg in { { -35.2, -27.4 }, { -20.6, -7.6 }, { 7.6, 20.6 }, { 27.4, 35.2 } } do
		F.band(V(seg[1], 0, facadeB), V(seg[2], 0, facadeB), 0, 1.3, 0.3, "ConcreteDark", outB, "Plinth")
	end

	---------------------------------------------------------------------------
	-- Mitad en espejo: bases (grava y carteles de salida) y carriles de asfalto
	---------------------------------------------------------------------------
	T.mirrored("ConstructionDressing", function()
		F.groundZone(CF(-131, 0, 0), 38, 100, "Gravel", "BaseGravel")
		F.groundZone(CF(-86, 0, -33), 52, 10, "Asphalt", "LaneAsphalt")
		F.groundZone(CF(-86, 0, 31), 52, 10, "Asphalt", "LaneAsphalt")
		-- Carteles en la cara interior de las mamparas de la base (los ven los que salen; nombran el
		-- sitio, no la dirección, así que valen igual en la base reflejada)
		T.sign(CF(-118.6, 6, -24) * CFrame.Angles(0, math.pi / 2, 0), "SALIDA NORTE · A", 9, 1.6, RGB(196, 46, 38), RGB(255, 255, 255), { PPS = 20 })
		T.sign(CF(-118.6, 6, 24) * CFrame.Angles(0, math.pi / 2, 0), "SALIDA SUR · B", 9, 1.6, RGB(40, 92, 190), RGB(255, 255, 255), { PPS = 20 })
	end)

	---------------------------------------------------------------------------
	-- Fondo industrial: chimeneas, gasómetros y un esqueleto de edificio bajo la grúa del sureste
	---------------------------------------------------------------------------
	for _, spec in { { V(318, 0, 120), 82, 9 }, { V(-330, 0, -140), 92, 10 }, { V(140, 0, 330), 74, 8 } } do
		local stack = T.chimney(CF(spec[1]), spec[2], spec[3])
		stack.CastShadow = false
	end
	F.gasHolder(CF(-300, 0, 210), 40, 34, "Steel")
	F.gasHolder(CF(336, 0, -80), 34, 30, { RGB(150, 112, 96), Enum.Material.Metal })
	F.skeleton(CF(196, 0, -284) * CFrame.Angles(0, rad(40), 0), 30, 24, 6, 8, "Concrete")
end

return Dressing
