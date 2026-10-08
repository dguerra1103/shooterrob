-- COSTA · acabados (Fase 14, pulido visual sin tocar el juego). Todo es decorado: no choca ni para
-- balas.
--
--   * Suelo por zonas: adoquín cálido en la calle mayor y el callejón, piedra arenisca en la plaza de
--     la fuente con un marco de azulejo de barro, barro cocido en la plaza alta (sitio A, cálido),
--     paseo marítimo claro con franja de azulejo azul junto a la barandilla, borde de azulejo azul en
--     el espigón (sitio B, azul) y arena en el patio de las bases.
--   * Buganvillas en las fachadas de las calles (el magenta del pueblo mediterráneo).
--   * Banderines de fiesta sobre la calle mayor y la plaza (por encima de la cabeza).
--   (Las casas encaladas llevan además zócalo pintado azul u ocre: Geometry, opción Plinth.)
local Dressing = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB

local UP = 6
local FLAGS = { RGB(214, 52, 46), RGB(246, 196, 48), RGB(40, 96, 170), RGB(244, 240, 230) }

function Dressing.build(T)
	local F = T.F

	---------------------------------------------------------------------------
	-- Suelo del centro (plaza, plaza alta, espigón)
	---------------------------------------------------------------------------
	F.groundZone(CF(0, 0, 2), 64, 56, "PlazaStone", "PlazaStone")
	F.zoneEdge(CF(0, 0, 8), 36, 36, "TileTerracotta", 1)
	F.zoneEdge(CF(0, 0, 2), 64, 56, "StoneDark", 0.6)
	F.groundZone(CF(0, UP, -97), 92, 34, "UpperPaving", "UpperPaving")
	F.zoneEdge(CF(0, UP, -97), 92, 34, "StoneDark", 0.6)
	F.zoneEdge(CF(0, 0, 98), 78, 38, "TileBlue", 1)

	-- Banderines: cruzan la plaza en diagonal y la calle del puerto (alto, sin tocar el campanario)
	F.bunting(V(-30, 11, -26), V(30, 11, 28), FLAGS)
	F.bunting(V(30, 11, -26), V(-30, 11, 28), FLAGS)
	F.bunting(V(-17, 9.5, 40), V(17, 9.5, 40), FLAGS)

	---------------------------------------------------------------------------
	-- Mitad en espejo: calles, paseo, base, buganvillas y banderines de la calle mayor
	---------------------------------------------------------------------------
	T.mirrored("CoastalDressing", function()
		F.groundZone(CF(-74, 0, -2), 76, 16, "StreetCobble", "StreetCobble")
		F.groundZone(CF(-76, 0, -35), 72, 22, "StreetCobble", "StreetCobble")
		F.groundZone(CF(-95, 0, 68), 110, 32, "Promenade", "Promenade")
		F.groundZone(CF(-95, 0, 83.4), 110, 1.4, "TileBlue", "PromenadeTiles")
		F.groundZone(CF(-131, 0, 0), 37, 88, "BaseSand", "BaseSand")
		-- Buganvillas en las esquinas entre casas (calle mayor, callejón y manzana de la taberna)
		for _, spec in {
			{ CF(-94, 5.5, 5.7), 3.4, 6 }, { CF(-66.4, 6.5, 5.7), 3, 5 },
			{ CF(-95, 6, -45.7) * CFrame.Angles(0, math.pi, 0), 3.4, 6 },
			{ CF(-82, 5.5, -24.3), 3, 5 },
			{ CF(-79, 5, 52.3) * CFrame.Angles(0, math.pi, 0), 3, 5 },
		} do
			F.climber(spec[1], spec[2], spec[3], "Bougainvillea")
		end
		-- Banderines sobre la calle mayor (de fachada a fachada)
		for _, x in { -96, -80, -60 } do
			F.bunting(V(x, 9.5, -9.6), V(x + 4, 9.5, 5.6), FLAGS)
		end
	end)
end

return Dressing
