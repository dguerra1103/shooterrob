-- CONSTRUCCIÓN (5v5 · Duelo por equipos · Buscar y destruir): obra en construcción vertical, con
-- la torre de hormigón y la grúa en el centro, el edificio A (lona roja, terraza) y el edificio B
-- (lona azul, sitio interior, estructura roja encima). Reconstruido de la hoja de referencia del
-- mapa: distribución del minimapa, volúmenes y colores de la imagen principal y detalles de los
-- paneles (vista desde A/B, zona central, interior, pasarela superior, variante nocturna).
--
-- Archivos: Lighting (luz y variantes), Geometry (blockout jugable), Props (cobertura y decorado).
-- Tamaño jugable: 300 x 260 en cruz; de base a sitio ~7 s corriendo, de base a base ~13 s.
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "Construction",
	Name = "Construcción",
	Icon = "🏗️",
	Description = "Obra vertical · torre central · 5 contra 5",
	Realistic = true, -- (5v5 táctico: sale siempre en la votación con TDM, Dominio o Buscar y destruir)
	Bomb = true, -- tiene sitios A y B
	Palette = "Construction",
	Ambience = "Base",
	Modes = { "TDM", "SND" }, -- (pensado para estos; funciona con todos)
	RecommendedPlayers = 10,
	Bounds = Vector3.new(300, 60, 260),
}

Map.Lighting = Lighting.Default
Map.LightingVariants = Lighting.Variants

local V = Vector3.new
local CF = CFrame.new
local L = 10

function Map.Build()
	local folder = T.begin(Map)
	Geometry.build(T)
	Props.build(T)

	---------------------------------------------------------------------------
	-- Puntos de juego
	---------------------------------------------------------------------------
	-- Bases: el Rojo en -X mirando al centro; el Azul, su reflejo
	local redBase = CFrame.lookAt(V(-131, 0, 0), V(-100, 0, 0))
	T.spawnZone(1, redBase, { Size = Vector2.new(36, 22) })
	T.spawnZone(2, T.mirrorCFrame(redBase), { Size = Vector2.new(36, 22) })
	T.flagBase(1, CF(-143, 0, 0))
	T.flagBase(2, CF(143, 0, 0))
	-- Lonas del equipo en el muro del fondo de cada base
	local teams = require(game:GetService("ReplicatedStorage").Shared.GameConfig).Teams
	for i, x in { -149.4, 149.4 } do
		for _, z in { -18, 18 } do
			local look = { teams[i].Color.Color, Enum.Material.Fabric }
			T.G.deco("TeamBanner", V(0.3, 9, 6), CF(x, 7, z), look).Color = look[1]
		end
	end

	-- Sitios de la bomba (sirven a los dos equipos): A en la plaza, B en el atrio
	T.site(V(0, 0, -88), "A")
	T.site(V(0, 0, 96), "B", { Color = Color3.fromRGB(46, 110, 220) })

	-- Zonas (Dominio: la más cercana a cada base y la del centro; Zona de control: en orden)
	T.zone(V(0, 0, -27), 9, 1)
	T.zone(V(0, 0, 96), 9, 2)
	T.zone(V(-78, 0, -8), 9, 3)
	T.zone(V(0, 0, -88), 9, 4)
	T.zone(V(78, 0, -8), 9, 5)

	-- Nombres de zona (los callouts que se dicen en partida)
	T.callout("TORRE", CF(0, 15, 0), V(34, 32, 34))
	T.callout("SEGUNDA DE LA TORRE", CF(0, 25, 0), V(34, 10, 34))
	T.callout("ESTRUCTURA", CF(0, 5, -54), V(36, 10, 32))
	T.callout("FORJADO", CF(0, 15, -54), V(38, 10, 34))
	T.callout("PASARELA", CF(0, 13, -27), V(8, 6, 22))
	T.callout("PASARELA", CF(0, 13, -86), V(8, 6, 32))
	T.callout("PASARELA B", CF(0, 13, 46), V(8, 6, 60))
	T.callout("PLAZA A", CF(0, 6, -88), V(70, 16, 38))
	T.callout("TERRAZA A", CF(0, 14, -105), V(76, 8, 8))
	T.callout("OFICINAS A", CF(0, 10, -119), V(60, 20, 22))
	T.callout("NAVE B", CF(0, 5, 100), V(72, 10, 48))
	T.callout("ENTREPLANTA B", CF(0, 15, 100), V(72, 10, 48))
	T.callout("PATIO B", CF(0, 8, 57), V(70, 20, 38))
	T.callout("PATIO", CF(0, 8, 0), V(120, 20, 76))
	for _, m in { 1, -1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("ALMACÉN", at(77.5, 8, 0), V(35, 16, 40))
		T.callout("CONTENEDORES", at(68, 10, -45), V(55, 24, 50))
		T.callout("ANDAMIOS", at(53, 8, -89), V(36, 18, 38))
		T.callout("ACOPIO", at(66, 10, 48), V(60, 24, 56))
		T.callout("MUELLE", at(56, 10, 98), V(40, 24, 44))
		T.callout("PASILLO A", at(26.5, 8, -54), V(17, 18, 32))
	end

	-- Puntos libres (todos contra todos, reapariciones dinámicas): repartidos y a cubierto
	for _, p in {
		V(-120, 0.5, -34), V(-120, 0.5, 34), V(-90, 0.5, -60), V(-82, 0.5, -10), V(-70, 0.5, 26),
		V(-66, 0.5, -36), V(-74, 0.5, 58), V(-55, 0.5, -84), V(-56, 0.5, 110), V(-40, 0.5, 12),
		V(-26, 0.5, -64), V(-24, 0.5, -90), V(-28, 0.5, 112), V(-30, 0.5, 56), V(-6, L + 0.5, -66.5),
		V(-30, L + 0.5, 116), V(-8, L + 0.5, -7),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	-- Puestos de los bots tiradores (miran hacia donde llega el enemigo)
	for _, spot in {
		{ V(-20, L, -105), V(-20, 4, -75) }, -- terraza A, sobre la plaza
		{ V(-14.5, L, -67.5), V(-30, 4, -30) }, -- forjado de la ESTRUCTURA
		{ V(-14, L, -8), V(-60, 4, -8) }, -- ventanal de la primera de la torre, al patio
		{ V(-30, L, 98), V(-30, 4, 60) }, -- entreplanta B, lado oeste
		{ V(-10, 2 * L, 12), V(-40, 4, 40) }, -- segunda de la torre
		{ V(-100, 0, -33), V(-60, 4, -40) }, -- salida norte de la base
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	-- Muros y techo invisibles del borde
	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
