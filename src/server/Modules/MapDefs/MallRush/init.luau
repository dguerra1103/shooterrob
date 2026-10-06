-- MALL RUSH (5v5 · Duelo por equipos · Buscar y destruir): centro comercial compacto de dos
-- plantas. Atrio central con cúpula, fuente, escaleras mecánicas y puente superior; patios a cada
-- lado con el sitio de cada equipo (como en la referencia: el A junto a la base A y el B junto a
-- la B); zona de comida al norte, entrada principal al sur, pasillo de servicio y tiendas grandes
-- como flancos. Reconstruido de la hoja de referencia (vista superior, vista general, atrio,
-- tiendas laterales, puente superior, pasillo de servicio y zona de comida).
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "MallRush",
	Name = "Mall Rush",
	Icon = "🛍️",
	Description = "Centro comercial · dos plantas · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "MallRush",
	Ambience = "Factory",
	Modes = { "TDM", "SND" },
	RecommendedPlayers = 10,
	Bounds = Vector3.new(300, 40, 180),
}

Map.Lighting = Lighting.Default
Map.LightingVariants = Lighting.Variants

local V = Vector3.new
local CF = CFrame.new
local L = 12

function Map.Build()
	local folder = T.begin(Map)
	Geometry.build(T)
	Props.build(T)

	-- Bases: el aparcamiento de cada lado
	local redBase = CFrame.lookAt(V(-143, 0, 0), V(-100, 0, 0))
	local points = { V(-10, 0, 1), V(-5, 0, -3), V(0, 0, 1), V(5, 0, -3), V(10, 0, 1) }
	T.spawnZone(1, redBase, { Size = Vector2.new(32, 14), Floor = Color3.fromRGB(84, 86, 92), Points = points })
	T.spawnZone(2, T.mirrorCFrame(redBase), { Size = Vector2.new(32, 14), Floor = Color3.fromRGB(84, 86, 92), Points = points })
	T.flagBase(1, CF(-140, 0, 30))
	T.flagBase(2, CF(140, 0, 30))

	-- Sitios: cada equipo defiende el de su mitad (A el Rojo, B el Azul)
	T.site(V(-50, 0, 0), "A", { Defender = 1 })
	T.site(V(50, 0, 0), "B", { Defender = 2, Color = Color3.fromRGB(46, 110, 220) })

	-- Zonas
	T.zone(V(0, 0, -28), 9, 1)
	T.zone(V(-50, 0, 0), 8, 2)
	T.zone(V(0, 0, -58), 9, 3)
	T.zone(V(50, 0, 0), 8, 4)
	T.zone(V(0, 0, 54), 9, 5)

	-- Nombres de zona
	T.callout("ATRIO", CF(0, 6, 0), V(72, 12, 72))
	T.callout("FUENTE", CF(0, 5, 0), V(14, 10, 14))
	T.callout("PUENTE", CF(0, L + 3, -12), V(44, 6, 6))
	T.callout("ANILLO", CF(0, L + 4, 0), V(76, 8, 72))
	T.callout("ZONA DE COMIDA", CF(0, 8, -58), V(80, 16, 44))
	T.callout("ENTRADA", CF(0, 8, 58), V(40, 16, 44))
	for _, m in { -1, 1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout(m < 0 and "PATIO A" or "PATIO B", at(50, 6, 0), V(28, 12, 40))
		T.callout("GALERÍA", at(91, 6, 0), V(54, 12, 40))
		T.callout("PLANTA ALTA", at(78, L + 4, 0), V(84, 8, 72))
		T.callout(m < 0 and "BLOX MART" or "MEGA TOYS", at(95, 6, -46), V(46, 12, 52))
		T.callout(m < 0 and "PIXEL WEAR" or "SPORT HUB", at(95, 6, 46), V(46, 12, 52))
		T.callout("PASILLO DE SERVICIO", at(79, 5, -76), V(78, 10, 8))
		T.callout("PASAJE", at(68, 5, -46), V(8, 10, 52))
		T.callout("PASILLO NORTE", at(50, 5, -28), V(28, 10, 16))
		T.callout("PASILLO SUR", at(54, 5, 28), V(36, 10, 16))
		T.callout("APARCAMIENTO", at(134, 6, 0), V(32, 14, 120))
	end

	-- Puntos libres
	for _, p in {
		V(-140, 0.5, -30), V(-120, 0.5, 30), V(-110, 0.5, -14), V(-88, 0.5, 8), V(-100, 0.5, -64),
		V(-84, 0.5, 60), V(-68, 0.5, -50), V(-60, 0.5, -76), V(-50, 0.5, 28), V(-30, 0.5, -28),
		V(-28, 0.5, 20), V(-34, 0.5, -60), V(-46, 0.5, 72), V(-90, L + 0.5, 0), V(-64, L + 0.5, -28),
		V(-30, L + 0.5, 28), V(-8, 0.5, 58),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	-- Puestos de los bots
	for _, spot in {
		{ V(-64, L, -18), V(-50, 4, 0) }, -- anillo del patio, sobre el sitio
		{ V(-26, L, -28), V(10, 4, -50) }, -- anillo del atrio, sobre la zona de comida
		{ V(-8, L, -12), V(-40, 4, 0) }, -- puente
		{ V(-86, L, -10), V(-60, L + 4, 0) }, -- galería alta
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
