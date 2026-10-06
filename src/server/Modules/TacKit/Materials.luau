-- Biblioteca de materiales de los mapas 5v5: cada "look" es { color, material } y cada mapa tiene
-- su paleta (identidad de color: Construcción = gris + amarillo + rojo...). Las piezas del kit
-- reciben un look (o el nombre de uno de la paleta activa) en vez de color y material sueltos, así
-- cambiar el tono de un mapa es tocar una línea.
local M = Enum.Material
local RGB = Color3.fromRGB

local Materials = {}

-- Comunes a todos los mapas
Materials.Common = {
	Steel = { RGB(118, 122, 128), M.Metal },
	SteelDark = { RGB(64, 66, 72), M.Metal },
	Glass = { RGB(150, 190, 210), M.Glass },
	Asphalt = { RGB(66, 66, 70), M.Asphalt },
	Paint = { RGB(236, 232, 220), M.SmoothPlastic }, -- líneas pintadas en el suelo
	Black = { RGB(30, 30, 34), M.SmoothPlastic },
	Wood = { RGB(176, 128, 80), M.WoodPlanks },
	WoodDark = { RGB(116, 80, 50), M.Wood },
	Fabric = { RGB(200, 60, 50), M.Fabric },
	Leaf = { RGB(70, 132, 62), M.Grass },
}

-- CONSTRUCCIÓN: hormigón claro, amarillo de seguridad y acero rojo
Materials.Construction = {
	Concrete = { RGB(198, 194, 186), M.Concrete },
	ConcreteDark = { RGB(150, 147, 141), M.Concrete },
	ConcreteWarm = { RGB(210, 200, 182), M.Concrete },
	Slab = { RGB(182, 178, 170), M.Concrete },
	Ground = { RGB(166, 160, 150), M.Concrete },
	Dirt = { RGB(138, 116, 90), M.Ground },
	Plywood = { RGB(204, 168, 116), M.WoodPlanks },
	Hoarding = { RGB(72, 82, 96), M.WoodPlanks },
	Yellow = { RGB(244, 188, 30), M.Metal },
	YellowPaint = { RGB(246, 194, 40), M.SmoothPlastic },
	RedSteel = { RGB(156, 40, 32), M.Metal },
	Red = { RGB(196, 46, 38), M.SmoothPlastic },
	Blue = { RGB(40, 92, 190), M.SmoothPlastic },
	ContainerRed = { RGB(172, 46, 38), M.CorrodedMetal },
	ContainerGray = { RGB(112, 116, 120), M.CorrodedMetal },
	ContainerTan = { RGB(150, 126, 94), M.CorrodedMetal },
	Block = { RGB(168, 166, 160), M.Concrete }, -- bloques de hormigón apilados
	Tarp = { RGB(70, 110, 160), M.Fabric },
	-- Edificios de alrededor (ciudad cálida al atardecer)
	BuildingSand = { RGB(214, 196, 164), M.Plaster },
	BuildingRose = { RGB(204, 168, 156), M.Plaster },
	BuildingGray = { RGB(176, 174, 172), M.Concrete },
	BuildingBrick = { RGB(160, 98, 78), M.Brick },
	Corrugated = { RGB(132, 138, 146), M.CorrodedMetal },
}

-- Paleta activa (la elige el mapa al empezar: Materials.use("Construction"))
Materials.Active = Materials.Construction

function Materials.use(name)
	Materials.Active = Materials[name] or Materials.Common
	return Materials.Active
end

-- Look por nombre (de la paleta activa o de las comunes) o un look ya hecho
function Materials.get(look)
	if type(look) == "string" then
		return Materials.Active[look] or Materials.Common[look] or error("[TacKit] look desconocido: " .. look)
	end
	return look
end

-- Un look nuevo con otro color (el mismo material)
function Materials.tint(look, color)
	look = Materials.get(look)
	return { color, look[2] }
end

return Materials
