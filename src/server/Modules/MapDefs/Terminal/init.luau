-- TERMINAL (5v5 · Duelo por equipos · Buscar y destruir): aeropuerto al atardecer. El avión parte la
-- plataforma por la mitad; el sitio A está en la plataforma delante de la terminal (cristalera y
-- pasarelas de embarque encima) y el B bajo la marquesina de carga (furgonetas, contenedores y
-- muelle). Reconstruido de la hoja de referencia: minimapa (bases arriba/abajo, avión en el centro,
-- A junto a la terminal, B en la carga), imagen principal (avión, torre de control, terminal de
-- cristal, contenedores rojos y azules, furgonetas, conos, torres de focos) y paneles (interior de
-- la terminal, zona inferior cubierta, variante nocturna).
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)

local Map = {
	Id = "Terminal",
	Name = "Terminal",
	Icon = "✈️",
	Description = "Aeropuerto · avión en el centro · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "Terminal",
	Ambience = "Base",
	Modes = { "TDM", "SND" },
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

	-- Bases (dentro de los hangares)
	local redBase = CFrame.lookAt(V(-136, 0, 0), V(-100, 0, 0))
	T.spawnZone(1, redBase, { Size = Vector2.new(34, 20) })
	T.spawnZone(2, T.mirrorCFrame(redBase), { Size = Vector2.new(34, 20) })
	T.flagBase(1, CF(-128, 0, 30))
	T.flagBase(2, CF(128, 0, 30))
	local teams = require(game:GetService("ReplicatedStorage").Shared.GameConfig).Teams
	for i, x in { -149.3, 149.3 } do
		for _, z in { -12, 12 } do
			local look = { teams[i].Color.Color, Enum.Material.Fabric }
			T.G.deco("TeamBanner", V(0.3, 10, 6), CF(x, 9, z), look).Color = look[1]
		end
	end

	-- Sitios
	T.site(V(0, 0, -64), "A")
	T.site(V(0, 0, 98), "B", { Color = Color3.fromRGB(46, 110, 220) })

	-- Zonas
	T.zone(V(0, 0, 50), 8, 1)
	T.zone(V(0, 0, 98), 9, 2)
	T.zone(V(-80, 0, 2), 9, 3)
	T.zone(V(0, 0, -64), 9, 4)
	T.zone(V(80, 0, 2), 9, 5)

	-- Nombres de zona
	T.callout("TERMINAL", CF(0, 5, -106), V(140, 10, 48))
	T.callout("SALIDAS", CF(0, 15, -106), V(140, 10, 48))
	T.callout("PLATAFORMA A", CF(0, 6, -62), V(90, 14, 40))
	T.callout("AVIÓN", CF(0, 8, -2), V(80, 20, 70))
	T.callout("MORRO", CF(0, 6, -38), V(24, 14, 12))
	T.callout("COLA", CF(0, 6, 34), V(30, 14, 18))
	T.callout("CARGA", CF(0, 5, 98), V(80, 12, 40))
	T.callout("MUELLE DE CARGA", CF(0, 8, 113), V(62, 8, 10))
	for _, m in { 1, -1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("PASARELA", at(22, 14, -66), V(8, 8, 36))
		T.callout("HANGAR", at(131, 10, 0), V(38, 22, 80))
		T.callout("MUELLE CUBIERTO", at(91, 6, -113), V(42, 12, 34))
		T.callout("CARRETERA", at(91, 6, -68), V(42, 12, 56))
		T.callout("PLATAFORMA", at(76, 6, 0), V(72, 14, 80))
		T.callout("CATERING", at(76, 6, 100), V(72, 14, 50))
		T.callout("ALA", at(24, 6, 6), V(30, 10, 22))
	end

	-- Puntos libres
	for _, p in {
		V(-124, 0.5, -30), V(-124, 0.5, 30), V(-100, 0.5, -60), V(-96, 0.5, -120), V(-70, 0.5, -54),
		V(-60, 0.5, -10), V(-90, 0.5, 6), V(-40, 0.5, 30), V(-56, 0.5, 74), V(-90, 0.5, 90),
		V(-30, 0.5, 104), V(-30, 0.5, -56), V(-40, 0.5, -110), V(-60, L + 0.5, -112), V(-6, L + 0.5, -112),
		V(-12, 4.5, 112), V(-26, 0.5, 46),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	-- Puestos de los bots
	for _, spot in {
		{ V(-12, L, -84), V(-10, 4, -60) }, -- cristalera de salidas, sobre la plataforma A
		{ V(-22, L, -72), V(-40, 4, -40) }, -- pasarela de embarque
		{ V(-16, 4, 112), V(-10, 4, 84) }, -- muelle de carga, al sitio B
		{ V(-100, 0, -40), V(-50, 4, -10) }, -- carretera, a la plataforma
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
