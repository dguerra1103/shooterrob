-- DOCKYARD (5v5 · Duelo por equipos · Buscar y destruir): terminal de contenedores. El sitio A
-- está en el muelle, junto al buque y entre las grúas pórtico; el B dentro del tinglado de
-- tránsito, a la altura del andén de carga. En medio, la playa de contenedores: bloques de dos de
-- alto en rojo, azul y amarillo que forman calles (no un laberinto) y la carretilla pórtico en el
-- centro. A los lados, el control del puerto (azotea a 9) y la puerta de camiones.
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "Dockyard",
	Name = "Dockyard",
	Icon = "⚓",
	Description = "Muelle, contenedores y tinglado · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "Dockyard",
	Ambience = "Coast",
	Modes = { "TDM", "SND" },
	RecommendedPlayers = 10,
	Bounds = Vector3.new(300, 70, 244),
}

Map.Lighting = Lighting.Default
Map.LightingVariants = Lighting.Variants

local V = Vector3.new
local CF = CFrame.new

function Map.Build()
	local folder = T.begin(Map)
	Geometry.build(T)
	Props.build(T)

	local redBase = CFrame.lookAt(V(-140, 0, 0), V(-100, 0, 0))
	local points = { V(-8, 0, 2), V(-4, 0, -3), V(0, 0, 2), V(4, 0, -3), V(8, 0, 2) }
	T.spawnZone(1, redBase, { Size = Vector2.new(24, 14), Points = points })
	T.spawnZone(2, T.mirrorCFrame(redBase), { Size = Vector2.new(24, 14), Points = points })
	T.flagBase(1, CF(-136, 0, -34))
	T.flagBase(2, CF(136, 0, -34))

	T.site(V(0, 0, -84), "A")
	T.site(V(0, 4, 84), "B", { Color = Color3.fromRGB(46, 110, 220) })

	T.zone(V(0, 0, -24), 8, 1)
	T.zone(V(0, 4, 84), 9, 2)
	T.zone(V(-86, 0, 18), 8, 3)
	T.zone(V(0, 0, -84), 9, 4)
	T.zone(V(86, 0, 18), 8, 5)

	T.callout("MUELLE", CF(0, 5, -82), V(300, 10, 44))
	T.callout("TINGLADO", CF(0, 10, 85), V(86, 14, 44))
	T.callout("ANDÉN DE CARGA", CF(0, 7, 58), V(88, 6, 8))
	T.callout("CARRETILLA", CF(0, 6, 0), V(14, 12, 22))
	T.callout("PLAYA DE CONTENEDORES", CF(0, 6, -4), V(150, 12, 96))
	for _, m in { -1, 1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("CONTROL DEL PUERTO", at(92, 5, -74), V(24, 9, 16))
		T.callout("AZOTEA DEL CONTROL", at(92, 12, -74), V(24, 6, 16))
		T.callout("GRÚA", at(30, 6, -90), V(20, 12, 24))
		T.callout("PUERTA DE CAMIONES", at(96, 5, 80), V(46, 10, 60))
		T.callout("CALLE", at(112, 5, 0), V(16, 10, 210))
	end

	for _, p in {
		V(-136, 0.5, -34), V(-110, 0.5, -70), V(-110, 0.5, 70), V(-92, 0.5, -74), V(-92, 9.5, -72),
		V(-60, 0.5, -76), V(-52, 0.5, -20), V(-52, 0.5, 20), V(-30, 0.5, -60), V(-8, 0.5, -40),
		V(-8, 0.5, 30), V(-30, 4.5, 58), V(-24, 4.5, 84), V(-66, 0.5, 96), V(-86, 0.5, 0),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	for _, spot in {
		{ V(-96, 9, -79), V(-40, 0, -100) }, -- azotea del control, al muelle
		{ V(-36, 4, 57), V(0, 0, 30) }, -- andén de carga, a la playa de contenedores
		{ V(-34, 0, -64), V(0, 0, -84) }, -- borde del muelle, al sitio A
		{ V(-86, 0, 0), V(0, 0, 0) }, -- calle, a la carretilla pórtico
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
