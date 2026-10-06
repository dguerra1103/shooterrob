-- ROOFTOP DISTRICT (5v5 · Duelo por equipos · Buscar y destruir): azoteas de una manzana unidas
-- por puentes, con la calle muy abajo. La azotea A (roja) al norte y la B (lucernarios, azul) al
-- sur; en el centro, la azotea de la pantalla gigante a la que se llega por el puente de cristal.
-- Reconstruido de la hoja de referencia: vista superior (bases a los lados, A arriba, B abajo,
-- flancos por las esquinas con zonas altas), vista general, azotea A, puente central, interior con
-- escaleras y la calle exterior.
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "RooftopDistrict",
	Name = "Rooftop District",
	Icon = "🏙️",
	Description = "Azoteas y puentes · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "RooftopDistrict",
	Ambience = "Wind",
	Modes = { "TDM", "SND" },
	RecommendedPlayers = 10,
	Bounds = Vector3.new(300, 70, 200),
}

Map.Lighting = Lighting.Default
Map.LightingVariants = Lighting.Variants

local V = Vector3.new
local CF = CFrame.new

function Map.Build()
	local folder = T.begin(Map)
	Geometry.build(T)
	Props.build(T)

	local redBase = CFrame.lookAt(V(-136, 0, 0), V(-100, 0, 0))
	local points = { V(-8, 0, 2), V(-4, 0, -3), V(0, 0, 2), V(4, 0, -3), V(8, 0, 2) }
	T.spawnZone(1, redBase, { Size = Vector2.new(24, 16), Points = points })
	T.spawnZone(2, T.mirrorCFrame(redBase), { Size = Vector2.new(24, 16), Points = points })
	T.flagBase(1, CF(-138, 0, -24))
	T.flagBase(2, CF(138, 0, -24))

	T.site(V(0, 4, -78), "A")
	T.site(V(0, 0, 78), "B", { Color = Color3.fromRGB(46, 110, 220) })

	T.zone(V(0, 6, 18), 8, 1)
	T.zone(V(0, 0, 78), 9, 2)
	T.zone(V(-98, 0, -10), 8, 3)
	T.zone(V(0, 4, -78), 9, 4)
	T.zone(V(98, 0, -10), 8, 5)

	T.callout("CENTRO", CF(0, 12, 0), V(80, 14, 60))
	T.callout("PANTALLA", CF(0, 12, 0), V(6, 14, 28))
	T.callout("AZOTEA A", CF(0, 10, -77), V(120, 14, 46))
	T.callout("AZOTEA B", CF(0, 6, 77), V(120, 14, 46))
	T.callout("PASARELA NORTE", CF(0, 9, -42), V(10, 10, 24))
	T.callout("PASARELA SUR", CF(0, 7, 42), V(10, 10, 24))
	for _, m in { -1, 1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("PUENTE DE CRISTAL", at(53, 10, 0), V(26, 10, 10))
		T.callout("PLATAFORMA", at(75, 10, 0), V(18, 10, 28))
		T.callout(m < 0 and "OESTE" or "ESTE", at(87, 6, 0), V(42, 14, 72))
		T.callout("TORRE", at(90, 12, -75), V(36, 14, 50))
		T.callout("ANTENA", at(95, 18, -87), V(14, 10, 14))
		T.callout("DEPÓSITO", at(90, 6, 75), V(36, 14, 50))
	end

	for _, p in {
		V(-140, 0.5, -26), V(-140, 0.5, 26), V(-96, 0.5, -10), V(-80, 0.5, 30), V(-100, 0.5, 30),
		V(-90, 6.5, -70), V(-80, 6.5, -90), V(-96, 0.5, 70), V(-80, 0.5, 92), V(-40, 4.5, -64),
		V(-24, 4.5, -92), V(-40, 0.5, 66), V(-24, 0.5, 96), V(-26, 6.5, -8), V(-30, 6.5, 22),
		V(-76, 6.5, 10),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	for _, spot in {
		{ V(-95, 14, -84), V(-40, 6, -78) }, -- plataforma alta de la torre, a la azotea A
		{ V(-95, 8, 84), V(-40, 4, 78) }, -- depósito, a la azotea B
		{ V(-30, 6, -24), V(0, 6, -50) }, -- centro, a la pasarela norte
		{ V(-74, 6, -10), V(-40, 8, 0) }, -- plataforma, al puente de cristal
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
