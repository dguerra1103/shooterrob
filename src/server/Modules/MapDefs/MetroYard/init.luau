-- METRO YARD (5v5 · Duelo por equipos · Buscar y destruir): estación de metro con su playa de vías.
-- El sitio A está en el vestíbulo de la estación (norte) y el B en las cocheras (sur, el taller).
-- En medio, las vías van en dos zanjas a −3 con trenes aparcados (cobertura alta y divisoria) y un
-- andén central con marquesina; por encima cruza la pasarela (10) de la estación a las cocheras.
-- Cada equipo sale de una cochera de autobuses junto a la calle, con el túnel de las vías delante
-- (por dentro: interior; por arriba: posición alta sobre la playa de vías).
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "MetroYard",
	Name = "Metro Yard",
	Icon = "🚇",
	Description = "Estación, vías y cocheras · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "MetroYard",
	Ambience = "Breeze",
	Modes = { "TDM", "SND" },
	RecommendedPlayers = 10,
	Bounds = Vector3.new(300, 70, 220),
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
	T.flagBase(1, CF(-138, 0, -34))
	T.flagBase(2, CF(138, 0, -34))

	T.site(V(0, 0, -78), "A")
	T.site(V(0, 0, 74), "B", { Color = Color3.fromRGB(46, 110, 220) })

	T.zone(V(0, 10, -22), 7, 1)
	T.zone(V(0, 0, 74), 9, 2)
	T.zone(V(-74, 0, 0), 8, 3)
	T.zone(V(0, 0, -78), 9, 4)
	T.zone(V(74, 0, 0), 8, 5)

	T.callout("ESTACIÓN", CF(0, 10, -70), V(98, 20, 58))
	T.callout("ENTREPLANTA", CF(0, 14, -46), V(98, 8, 11))
	T.callout("TORNIQUETES", CF(0, 3, -60), V(80, 6, 6))
	T.callout("COCHERAS", CF(0, 8, 72), V(98, 16, 54))
	T.callout("GALERÍA", CF(0, 14, 48), V(28, 8, 8))
	T.callout("PASARELA", CF(0, 14, 2), V(6, 8, 84))
	T.callout("ANDÉN CENTRAL", CF(0, 4, 0), V(120, 8, 10))
	T.callout("ANDÉN NORTE", CF(0, 4, -35), V(180, 8, 10))
	T.callout("ANDÉN SUR", CF(0, 4, 37), V(180, 8, 14))
	T.callout("VÍAS NORTE", CF(0, 1, -17.5), V(120, 8, 25))
	T.callout("VÍAS SUR", CF(0, 1, 17.5), V(120, 8, 25))
	for _, m in { -1, 1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("TÚNEL", at(75, 3, 0), V(30, 12, 60))
		T.callout("TECHO DEL TÚNEL", at(75, 13, 0), V(30, 8, 62))
		T.callout("CALLE", at(105, 4, 0), V(30, 10, 220))
		T.callout("PLAZA", at(85, 4, -72), V(70, 10, 60))
		T.callout("PATIO", at(85, 4, 76), V(70, 10, 64))
	end

	for _, p in {
		V(-140, 0.5, -32), V(-105, 0.5, -40), V(-100, 0.5, 40), V(-72, 0.5, 0), V(-75, 10.5, -10),
		V(-40, 0.5, -35), V(-40, 0.5, 35), V(-30, -2.5, -15), V(-30, -2.5, 20), V(-30, 0.5, -80),
		V(-36, 10.5, -46), V(-30, 0.5, 60), V(-90, 0.5, -60), V(-80, 0.5, 86), V(-48, 0.5, 2.5),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	for _, spot in {
		{ V(-64, 10, -20), V(0, 0, -35) }, -- techo del túnel, al andén norte
		{ V(-36, 10, -46), V(0, 0, -78) }, -- entreplanta, al sitio A
		{ V(-10, 10, 48), V(0, 0, 74) }, -- galería de las cocheras, al sitio B
		{ V(-74, 0, 0), V(0, 0, 0) }, -- boca del túnel, a la playa de vías
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
