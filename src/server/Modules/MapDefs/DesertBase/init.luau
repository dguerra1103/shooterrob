-- DESERT BASE (5v5 · Duelo por equipos · Buscar y destruir): base militar en el desierto. El sitio
-- A está en el parque de vehículos (marquesina al norte) y el B dentro del almacén (sur). En medio,
-- el patio de armas con el cuartel general (azotea a 9 con antena) y la torre de agua; por los
-- lados, los barracones (norte), las torres de vigilancia y el depósito de combustible (sur).
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "DesertBase",
	Name = "Desert Base",
	Icon = "🏜️",
	Description = "Base militar en el desierto · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "DesertBase",
	Ambience = "Desert",
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

	T.site(V(0, 0, -78), "A")
	T.site(V(0, 0, 80), "B", { Color = Color3.fromRGB(46, 110, 220) })

	T.zone(V(0, 0, -25), 8, 1)
	T.zone(V(0, 0, 80), 9, 2)
	T.zone(V(-76, 0, -6), 8, 3)
	T.zone(V(0, 0, -78), 9, 4)
	T.zone(V(76, 0, -6), 8, 5)

	T.callout("PARQUE DE VEHÍCULOS", CF(0, 6, -80), V(76, 12, 44))
	T.callout("ALMACÉN", CF(0, 7, 82), V(76, 14, 52))
	T.callout("CUARTEL", CF(0, 4, 0), V(28, 9, 32))
	T.callout("AZOTEA DEL CUARTEL", CF(0, 12, 0), V(28, 8, 32))
	T.callout("TORRE DE AGUA", CF(0, 4, -44), V(16, 10, 16))
	T.callout("HELIPUERTO", CF(0, 4, 36), V(24, 10, 24))
	for _, m in { -1, 1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("PATIO", at(60, 4, 4), V(60, 10, 70))
		T.callout("BARRACONES", at(78, 4, -84), V(50, 10, 54))
		T.callout("TORRE", at(54, 14, -44), V(8, 8, 8))
		T.callout("COMBUSTIBLE", at(78, 4, 84), V(50, 10, 60))
		T.callout("CONTROL", at(110, 4, 0), V(20, 10, 90))
	end

	for _, p in {
		V(-136, 0.5, -34), V(-110, 0.5, -60), V(-110, 0.5, 60), V(-80, 0.5, -84), V(-74, 0.5, -70),
		V(-54, 12.5, -44), V(-60, 0.5, 0), V(-40, 0.5, -40), V(-40, 0.5, 40), V(-26, 0.5, -74),
		V(-8, 9.5, -12), V(-24, 0.5, 90), V(-74, 6.5, 70), V(-60, 0.5, 62), V(-20, 0.5, 8),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	for _, spot in {
		{ V(-54, 12, -44), V(0, 0, -70) }, -- torre, al parque de vehículos
		{ V(-10, 9, 10), V(0, 0, 40) }, -- azotea del cuartel, al helipuerto
		{ V(-74, 6, 70), V(-38, 0, 80) }, -- pasarela del combustible, a la puerta del almacén
		{ V(-60, 0, -4), V(0, 0, 0) }, -- patio, al cuartel
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
