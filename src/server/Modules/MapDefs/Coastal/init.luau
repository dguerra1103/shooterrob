-- COSTA (5v5 · Duelo por equipos · Buscar y destruir): pueblo costero mediterráneo. Iglesia con
-- campanario y plaza con fuente en el centro; la parte alta (sitio A, ayuntamiento con balcón y
-- lona roja) y el puerto (sitio B en el espigón, lonja con azotea y lona azul). Reconstruido de la
-- hoja de referencia: minimapa (bases arriba/abajo, A a la izquierda, B a la derecha, muelle al
-- sur), imagen principal (plaza, fuente, puestos, escaleras, muelle con bolardos y barcas, faro) y
-- paneles (calle principal, pasarela superior, variante nocturna).
--
-- Archivos: Lighting (luz y variantes), Geometry (blockout jugable), Props (cobertura y decorado),
-- Dressing (acabados de la Fase 14: suelo por zonas, buganvillas, banderines).
local T = require(script.Parent.Parent.TacKit)
local Lighting = require(script.Lighting)
local Geometry = require(script.Geometry)
local Props = require(script.Props)
local Dressing = require(script.Dressing)

local Map = {
	Id = "Coastal",
	Name = "Costa",
	Icon = "⛵",
	Description = "Pueblo costero · plaza y puerto · 5 contra 5",
	Realistic = true,
	Bomb = true,
	Palette = "Coastal",
	Ambience = "Coast",
	Modes = { "TDM", "SND" },
	RecommendedPlayers = 10,
	Bounds = Vector3.new(300, 60, 260),
}

Map.Lighting = Lighting.Default
Map.LightingVariants = Lighting.Variants

local V = Vector3.new
local CF = CFrame.new
local UP = 6

function Map.Build()
	local folder = T.begin(Map)
	Geometry.build(T)
	Props.build(T)
	Dressing.build(T) -- (Fase 14: acabados; solo decorado)

	-- Bases
	local redBase = CFrame.lookAt(V(-134, 0, 0), V(-100, 0, 0))
	T.spawnZone(1, redBase, { Size = Vector2.new(36, 22), Floor = Color3.fromRGB(176, 164, 144) })
	T.spawnZone(2, T.mirrorCFrame(redBase), { Size = Vector2.new(36, 22), Floor = Color3.fromRGB(176, 164, 144) })
	T.flagBase(1, CF(-140, 0, 32))
	T.flagBase(2, CF(140, 0, 32))
	local teams = require(game:GetService("ReplicatedStorage").Shared.GameConfig).Teams
	for i, x in { -148.6, 148.6 } do
		for _, z in { -14, 14 } do
			local look = { teams[i].Color.Color, Enum.Material.Fabric }
			T.G.deco("TeamBanner", V(0.3, 8, 5), CF(x, 6.5, z), look).Color = look[1]
		end
	end

	-- Sitios
	T.site(V(0, UP, -97), "A")
	T.site(V(0, 0, 97), "B", { Color = Color3.fromRGB(46, 110, 220) })

	-- Zonas: centro (sur de la fuente), A, B y una por lado en la calle mayor
	T.zone(V(0, 0, 22), 8, 1)
	T.zone(V(0, 0, 97), 9, 2)
	T.zone(V(-80, 0, -2), 8, 3)
	T.zone(V(0, UP, -97), 9, 4)
	T.zone(V(80, 0, -2), 8, 5)

	-- Nombres de zona
	T.callout("PLAZA", CF(0, 8, 0), V(60, 20, 60))
	T.callout("CAMPANARIO", CF(0, 6, -25), V(12, 14, 12))
	T.callout("IGLESIA", CF(0, 7, -46), V(28, 14, 32))
	T.callout("ÁBSIDE", CF(0, UP + 5, -71), V(28, 10, 18))
	T.callout("PLAZA ALTA", CF(0, UP + 6, -98), V(92, 16, 36))
	T.callout("AYUNTAMIENTO", CF(0, UP + 8, -121), V(60, 16, 18))
	T.callout("BALCÓN", CF(0, UP + 11, -109), V(42, 6, 8))
	T.callout("LONJA", CF(0, 4, 70), V(36, 8, 16))
	T.callout("AZOTEA DE LA LONJA", CF(0, 11, 70), V(46, 6, 18))
	T.callout("ESPIGÓN", CF(0, 6, 98), V(80, 16, 40))
	T.callout("MUELLE", CF(0, 4, 124), V(10, 8, 12))
	T.callout("CALLE DEL PUERTO", CF(0, 6, 46), V(36, 14, 32))
	for _, m in { 1, -1 } do
		local function at(x, y, z)
			return CF(m * x, y, z)
		end
		T.callout("CALLEJÓN", at(76, 8, -35), V(72, 18, 22))
		T.callout("CALLE MAYOR", at(72, 8, -2), V(76, 18, 16))
		T.callout("TABERNA", at(66, 5, -17), V(16, 10, 14))
		T.callout("ARCO", at(33, 5, 2), V(6, 10, 8))
		T.callout("PASEO", at(76, 8, 62), V(72, 18, 46))
		T.callout("MIRADOR", at(47, UP + 6, -71), V(66, 14, 18))
		T.callout("PLAZUELA", at(27, 6, -44), V(26, 14, 36))
		T.callout("ESCALINATA", at(23, 4, -56), V(10, 10, 12))
	end

	-- Puntos libres
	for _, p in {
		V(-124, 0.5, -36), V(-124, 0.5, 36), V(-100, 0.5, -30), V(-70, 0.5, -38), V(-50, 0.5, -30),
		V(-96, 0.5, -4), V(-50, 0.5, -2), V(-20, 0.5, 12), V(-62, 0.5, 20), V(-88, 0.5, 58),
		V(-50, 0.5, 74), V(-28, 0.5, 96), V(-34, 0.5, 64), V(-30, 0.5, -48), V(-60, UP + 0.5, -70),
		V(-30, UP + 0.5, -104), V(-8, UP + 8.5, -110), V(-10, 9, 72), V(-8, 0.5, -36),
	} do
		T.ffa(p)
		T.ffa(T.mirrorPoint(p))
	end
	-- Puestos de los bots
	for _, spot in {
		{ V(-12, UP + 8, -109), V(-20, UP + 4, -85) }, -- balcón del ayuntamiento, sobre la plaza alta
		{ V(-10, 8.5, 74), V(-10, 4, 100) }, -- azotea de la lonja, al espigón
		{ V(-40, UP, -66), V(-20, 4, -10) }, -- mirador, sobre la plaza
		{ V(-34, UP, -104), V(0, UP + 4, -90) }, -- plaza alta, junto al puesto
		{ V(-30, 0, 104), V(0, 4, 90) }, -- espigón, tras la barca
	} do
		T.botSpot(spot[1], spot[2])
		T.botSpot(T.mirrorPoint(spot[1]), T.mirrorPoint(spot[2]))
	end

	T.Kit.bounds(Map.Bounds.X, Map.Bounds.Z, Map.Bounds.Y)
	return folder
end

return Map
