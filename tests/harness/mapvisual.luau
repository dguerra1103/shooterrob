-- Fase 3 (mapas gold standard): hitos presentes, detalles que no estorban (decorado sin colisión),
-- luz que no esconde enemigos (neblina y bloom limitados en todas las variantes) y presupuesto de
-- piezas (que el pulido visual no dispare el coste de dibujo). Lo VISUAL se valida en Studio; aquí,
-- solo las reglas.
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
local MapBuilder = req(game.ServerScriptService.Server.Modules.MapBuilder)

-- Hitos por mapa (nombres de pieza) y presupuesto de piezas (los de antes de la Fase 3 + ~5 %)
local SPECS = {
	Construction = {
		Landmarks = { CraneChord = "grúa", SafetyNet = "red roja de la torre", SlabEdge = "cantos amarillos de la torre", TowerShaft = "torre" },
		Budget = 6400, -- (la variante de noche añade ventanas encendidas)
	},
	Coastal = {
		Landmarks = { FountainTileBand = "fuente con azulejo", TowerTileBand = "campanario", LighthouseTower = "faro" },
		Budget = 4450,
	},
	MallRush = {
		Landmarks = { FountainFloorRing = "fuente del atrio", DomeGlass = "cúpula", EscalatorStripe = "escalera mecánica", RoofBand = "franja de la cubierta" },
		Budget = 2300,
	},
}
-- Detalles nuevos de la Fase 3: decorado puro (ni chocan ni paran balas)
local DECO = { "FloorInlay", "CeilingLight", "RoofBand", "FountainFloorRing", "FountainFloorInner", "FountainTileBand", "EscalatorStripe", "SafetyNet", "TowerQuoin", "TowerTileBand", "ClockHand", "HazardStripe" }
-- Fase 14 (acabados, TacKit.Finish): zonas de suelo, remates, lonas, trepadoras, banderines y fondo.
-- Tampoco pueden chocar ni parar balas (las rutas y las coberturas no cambian)
for _, name in {
	"GroundZone", "ZoneEdge", "PlazaPavers", "PatioSlab", "PatioBSlab", "BaseGravel", "LaneAsphalt", "Cornice", "CornerPier",
	"Plinth", "MeshBanner", "BannerStripe", "Formwork", "FormworkClamp", "GasHolder", "SkeletonSlab", "SkeletonColumn",
	"PlazaStone", "UpperPaving", "StreetCobble", "Promenade", "PromenadeTiles", "BaseSand", "Bougainvillea", "Bunting", "Wire",
	"AtriumStone", "FoodFloor", "ServiceFloor", "Fascia", "FasciaGlow", "FacadeFin",
} do
	table.insert(DECO, name)
end
-- Hitos y acabados de la Fase 14 que tienen que estar (identidad de cada mapa)
local F14 = {
	Construction = { PlazaPavers = "adoquín de la plaza A", MeshBanner = "lonas de la torre", Cornice = "remates A/B", BaseGravel = "grava de las bases", GasHolder = "fondo industrial", Formwork = "encofrados de la torre" },
	Coastal = { PlazaStone = "plaza de la fuente", UpperPaving = "plaza alta (A)", Bougainvillea = "buganvillas", Bunting = "banderines", Promenade = "paseo" },
	MallRush = { AtriumStone = "suelo del atrio", FoodFloor = "zona de comida", Fascia = "frentes de forjado", FacadeFin = "lamas de fachada" },
}

for name, spec in SPECS do
	MapBuilder.Build(name)
	local map = game.Workspace:FindFirstChild("Map")
	check(map ~= nil, name .. ": construido")
	local found, parts = {}, 0
	local decoProblems = {}
	for _, inst in map:GetDescendants() do
		if inst:IsA("BasePart") then
			parts += 1
			found[inst.Name] = true
			if table.find(DECO, inst.Name) and (inst.CanCollide ~= false or inst.CanQuery ~= false) then
				table.insert(decoProblems, inst.Name)
			end
		end
	end
	for partName, label in spec.Landmarks do
		check(found[partName] == true, name .. ": hito «" .. label .. "»")
	end
	for partName, label in F14[name] or {} do
		check(found[partName] == true, name .. ": acabado de la Fase 14 «" .. label .. "»")
	end
	check(#decoProblems == 0, name .. ": los detalles nuevos no chocan ni paran balas (" .. table.concat(decoProblems, ", ") .. ")")
	check(parts <= spec.Budget, string.format("%s: %d piezas (presupuesto %d)", name, parts, spec.Budget))
	-- Luz: neblina ≤ 0,26 y bloom ≤ 0,5 en la luz por defecto y en cada variante
	local def = MapBuilder.Defs[name]
	local lightings = { def.Lighting }
	for _, variant in def.LightingVariants or {} do
		table.insert(lightings, variant)
	end
	for _, light in lightings do
		local density = light.Atmosphere and light.Atmosphere.Density or 0
		local bloom = light.Bloom and light.Bloom.Intensity or 0
		assert(density <= 0.26 + 1e-6, name .. " " .. tostring(light.Name or "por defecto") .. ": neblina " .. density)
		assert(bloom <= 0.5 + 1e-6, name .. " " .. tostring(light.Name or "por defecto") .. ": bloom " .. bloom)
	end
	check(true, name .. ": neblina ≤ 0,26 y bloom ≤ 0,5 en sus " .. #lightings .. " luces")
end

-- Mall Rush: el rótulo de la entrada dice el nombre del mapa
MapBuilder.Build("MallRush")
local wrongName = false
for _, inst in game.Workspace:FindFirstChild("Map"):GetDescendants() do
	if inst:IsA("TextLabel") and string.find(string.upper(tostring(inst.Text)), "SUNRISE", 1, true) then
		wrongName = true
	end
end
check(not wrongName, "Mall Rush: ningún rótulo dice «SUNRISE MALL»")

-- Coastal es el mapa más luminoso de los tres de día (ambiente exterior)
local function lum(c) return c.R + c.G + c.B end
local coastal = MapBuilder.Defs.Coastal.Lighting
check(lum(coastal.OutdoorAmbient) >= lum(MapBuilder.Defs.Construction.Lighting.OutdoorAmbient) and coastal.Atmosphere.Density <= MapBuilder.Defs.Construction.Lighting.Atmosphere.Density,
	"Costa: más luminosa y con menos neblina que Construcción")

-- DOF: nada borroso en partida por defecto
check(GameConfig.AimDepthOfField == false, "sin desenfoque al apuntar por defecto")
print("MAPAS VISUAL OK")
process.exit(0)
