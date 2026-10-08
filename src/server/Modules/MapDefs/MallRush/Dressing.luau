-- MALL RUSH · acabados (Fase 14, pulido visual sin tocar el juego). Todo es decorado: no choca ni
-- para balas.
--
--   * Suelo por zonas: el atrio de granito con marco cian alrededor de la fuente, la zona de comida
--     en azulejo cálido, el pasillo de servicio de hormigón y los patios de los sitios con un marco
--     de su color (A rojo, B azul: se sabe en qué patio se está sin mirar el minimapa).
--   * Frentes de forjado de la planta alta en los huecos del patio y del atrio: frente blanco con una
--     línea de luz de color (naranja en los patios, cian en el atrio). Es lo que más se ve desde
--     abajo y da la energía de centro comercial; solo neón, sin luces nuevas.
--   * Rótulos: «FOOD COURT» en el fondo de la zona de comida y «NIVEL 2» sobre cada escalera
--     mecánica.
--   * Fachadas norte y sur con lamas verticales (la caja blanca deja de ser una caja).
--   * Fondo: vallas publicitarias de marcas ficticias (NOVA, BYTE, FLUX) junto a las calles.
local Dressing = {}

local V = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB

local L = 12
local TOP = 24
local CYAN, ORANGE = RGB(0, 186, 214), RGB(250, 140, 30)

function Dressing.build(T)
	local F = T.F

	---------------------------------------------------------------------------
	-- Suelo del centro: atrio y zona de comida; marco de color de cada sitio (fuera del espejo)
	---------------------------------------------------------------------------
	F.groundZone(CF(0, 0, 0), 44, 44, "AtriumStone", "AtriumStone")
	F.zoneEdge(CF(0, 0, 0), 40, 40, "TileAccent", 0.8)
	F.groundZone(CF(0, 0, -58), 76, 40, "FoodFloor", "FoodFloor")
	F.zoneEdge(CF(0, 0, -58), 76, 40, "Orange", 0.6)
	F.zoneEdge(CF(-50, 0, 0), 24, 32, "Red", 0.9)
	F.zoneEdge(CF(50, 0, 0), 24, 32, "Blue", 0.9)

	-- Rótulo de la zona de comida en el muro del fondo (cara al sur)
	local food = T.sign(CF(0, 17, -79.7) * CFrame.Angles(0, math.pi, 0), "FOOD COURT", 30, 4, ORANGE, RGB(255, 255, 255), { PPS = 12 })
	food.CastShadow = false

	-- Fondo urbano: vallas publicitarias de marcas ficticias junto a las calles (se ven desde los
	-- aparcamientos y en la presentación del mapa; fuera del límite jugable)
	T.billboardScreen(CF(-172, 0, -36) * CFrame.Angles(0, -math.pi / 2, 0), 16, 7, "NOVA", RGB(0, 150, 190))
	T.billboardScreen(CF(172, 0, 36) * CFrame.Angles(0, math.pi / 2, 0), 16, 7, "BYTE", RGB(200, 40, 130))
	T.billboardScreen(CF(40, 0, -126) * CFrame.Angles(0, math.pi, 0), 16, 7, "FLUX", RGB(230, 120, 30))

	T.mirrored("MallDressing", function()
		Dressing.half(T)
	end)
end

-- Mitad del Rojo (X < 0)
function Dressing.half(T)
	local F = T.F

	-- Pasillo de servicio: hormigón
	F.groundZone(CF(-79, 0, -76), 78, 8, "ServiceFloor", "ServiceFloor")

	-- Frentes de forjado (frente blanco y línea de luz debajo) en los bordes de los huecos
	local function fascia(a, b, inward, glow)
		F.band(a, b, L - 1.1, 1.2, 0.3, "Fascia", inward, "Fascia")
		F.band(a, b, L - 1.35, 0.25, 0.4, { glow, Enum.Material.Neon }, inward, "FasciaGlow")
	end
	-- Hueco del patio (x -60..-40, z -14..14)
	fascia(V(-60, 0, -14), V(-60, 0, 14), V(1, 0, 0), ORANGE)
	fascia(V(-40, 0, -14), V(-40, 0, 14), V(-1, 0, 0), ORANGE)
	fascia(V(-60, 0, -14), V(-40, 0, -14), V(0, 0, 1), ORANGE)
	fascia(V(-60, 0, 14), V(-40, 0, 14), V(0, 0, -1), ORANGE)
	-- Hueco del atrio (x -22..0 en esta mitad, z -22..22) y los lados del puente (z -15 y -9)
	fascia(V(-22, 0, -22), V(-22, 0, 22), V(1, 0, 0), CYAN)
	fascia(V(-22, 0, -22), V(0, 0, -22), V(0, 0, 1), CYAN)
	fascia(V(-22, 0, 22), V(0, 0, 22), V(0, 0, -1), CYAN)
	fascia(V(-22, 0, -15), V(0, 0, -15), V(0, 0, -1), CYAN)
	fascia(V(-22, 0, -9), V(0, 0, -9), V(0, 0, 1), CYAN)

	-- «NIVEL 2» colgado bajo el puente, mirando al arranque de la escalera mecánica
	T.sign(CF(-14, 10.1, -8.8) * CFrame.Angles(0, math.pi, 0), "NIVEL 2", 5, 1.3, RGB(36, 40, 52), RGB(255, 255, 255), { PPS = 24, Back = true })

	-- Fachadas norte y sur: lamas verticales gris oscuro cada 12 (no en la entrada principal)
	for x = -112, -16, 12 do
		for _, spec in { { -81, V(0, 0, -1) }, { 81, V(0, 0, 1) } } do
			local fin = T.G.deco("FacadeFin", V(1, TOP - 2, 1.4), CF(x, (TOP - 2) / 2 + 0.4, spec[1] + spec[2].Z * 0.2), "FacadeDark")
			fin.CastShadow = false
		end
	end
end

return Dressing
