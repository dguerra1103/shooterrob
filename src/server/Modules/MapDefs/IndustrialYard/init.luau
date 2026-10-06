-- INDUSTRIAL YARD (5v5 · Duelo por equipos · Buscar y destruir): planta industrial al atardecer.
-- El sitio A está en la planta de proceso (norte), entre depósitos y bajo la pasarela; el B dentro
-- de la nave de producción (sur), entre máquinas y con la entreplanta encima. En el centro, la sala
-- de calderas con la chimenea (el hito que se ve desde todo el mapa). A los lados, los montones
-- de grava (norte), la caseta de bombas (centro) y el patio de almacenaje (sur).
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "IndustrialYard",
	Name = "Industrial Yard",
	Icon = "🏭",
	Description = "Planta industrial al atardecer · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "IndustrialYard",
	Ambience = "Factory",
	Modes = { "TDM", "SND" },
	RecommendedPlayers = 10,
	Bounds = Vector3.new(300, 70, 240),
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

	T.site(V(0, 0, -82), "A")
	T.site(V(0, 0, 80), "B", { Color = Color3.fromRGB(46, 110, 220) })

	T.zone(V(0, 0, -27), 6, 1)
	T.zone(V(0, 0, 80), 9, 2)
	T.zone(V(-72, 0, 22), 8, 3)
	T.zone(V(0, 0, -82), 9, 4)
	T.zone(V(72, 0, 22), 8, 5)

	T.callout("PLANTA", CF(0, 6, -84), V(100, 12, 52))
	T.callout("PASARELA", CF(0, 11, -106), V(96, 6, 4))
	T.callout("CALDERAS", CF(0, 6, 0), V(24, 12, 24))
	T.callout("NAVE", CF(0, 8, 83), V(90, 16, 52))
	T.callout("ENTREPLANTA", CF(0, 11, 104.5), V(90, 6, 9))
	for _, m in { -1, 1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("GRAVA", at(84, 5, -80), V(50, 10, 60))
		T.callout("BOMBAS", at(72, 4, 0), V(16, 8, 20))
		T.callout("ALMACENAJE", at(84, 5, 80), V(50, 10, 60))
		T.callout("DEPÓSITOS", at(22, 7, -80), V(14, 14, 44))
		T.callout("CALLE", at(112, 5, 0), V(16, 10, 230))
	end

	for _, p in {
		V(-136, 0.5, -34), V(-110, 0.5, -60), V(-110, 0.5, 60), V(-72, 0.5, -6), V(-30, 8.5, -106),
		V(-50, 0.5, -90), V(-60, 0.5, -30), V(-50, 0.5, 30), V(-14, 0.5, -76), V(-8, 0.5, -30),
		V(-16, 0.5, 26), V(-30, 0.5, 86), V(-24, 8.5, 104), V(-80, 0.5, 86), V(-6, 0.5, -9),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	for _, spot in {
		{ V(-30, 8, -106), V(0, 0, -82) }, -- pasarela, al sitio A
		{ V(-24, 8, 104), V(0, 0, 80) }, -- entreplanta, al sitio B
		{ V(-60, 0, -30), V(0, 0, -24) }, -- frente a las calderas
		{ V(-86, 0, 18), V(0, 0, 20) }, -- calle central
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
