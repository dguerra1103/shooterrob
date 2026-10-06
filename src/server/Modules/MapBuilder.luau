-- Registro de mapas: construye el mapa elegido y publica su nombre para la interfaz.
-- Si construyes tu propio mapa en Studio dentro de workspace.Map (sin el atributo "Generated"),
-- se usará ese y no habrá rotación de mapas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local MapBuilder = {}

MapBuilder.Defs = {}
for _, module in script.Parent.MapDefs:GetChildren() do
	local def = require(module)
	MapBuilder.Defs[def.Id] = def
end

-- Orden de rotación (también son las opciones de la votación)
MapBuilder.Order = { "Construction", "Coastal", "Terminal", "MallRush", "RooftopDistrict" }

MapBuilder.Current = nil

-- ¿Puede salir este mapa ahora? Los de temporada (Season = nombre del evento) solo con su evento
-- en marcha (atributo EventName que pone Event)
function MapBuilder.InSeason(id)
	local def = MapBuilder.Defs[id]
	return def == nil or def.Season == nil or ReplicatedStorage:GetAttribute("EventName") == def.Season
end

-- (la pantalla de inicio dice cuántos mapas hay: los de siempre)
local permanent = 0
for _, id in MapBuilder.Order do
	if MapBuilder.Defs[id] and not MapBuilder.Defs[id].Season then
		permanent += 1
	end
end
ReplicatedStorage:SetAttribute("MapCount", permanent)

-- Mapa destacado del día (GameConfig.FeaturedMap): rota por los de siempre, uno cada día (UTC).
-- Se publica en el atributo FeaturedMap (su nombre) para la votación y el bonus de XP.
function MapBuilder.FeaturedId(day)
	local list = {}
	for _, id in MapBuilder.Order do
		if MapBuilder.Defs[id] and not MapBuilder.Defs[id].Season then
			table.insert(list, id)
		end
	end
	if #list == 0 then
		return nil
	end
	day = day or (os.time() // 86400)
	return list[(day % #list) + 1]
end

function MapBuilder.UpdateFeatured()
	local id = GameConfig.FeaturedMap and MapBuilder.FeaturedId()
	local def = id and MapBuilder.Defs[id]
	ReplicatedStorage:SetAttribute("FeaturedMap", def and def.Name or nil)
end
MapBuilder.UpdateFeatured()

-- ¿Hay un mapa hecho a mano en Studio?
function MapBuilder.IsCustom()
	local map = workspace:FindFirstChild("Map")
	return map ~= nil and not map:GetAttribute("Generated")
end

function MapBuilder.Get(id)
	return MapBuilder.Defs[id]
end

function MapBuilder.Build(id)
	if MapBuilder.IsCustom() then
		ReplicatedStorage:SetAttribute("MapName", "Mapa propio")
		return nil
	end
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	local def = MapBuilder.Defs[id or MapBuilder.Order[1]] or MapBuilder.Defs[MapBuilder.Order[1]]
	MapBuilder.UpdateFeatured() -- (cambia a medianoche: se revisa con cada mapa)
	def.Build()
	-- Gravedad del mapa (la Base Lunar tiene menos: se salta más y las granadas vuelan más)
	workspace.Gravity = def.Gravity or 196.2
	-- Decoración del evento de temporada (calabazas en Halloween)
	local ok, err = pcall(function()
		require(script.Parent.Event).Decorate()
	end)
	if not ok then
		warn("[MapBuilder] decoración del evento:", err)
	end
	MapBuilder.Current = def.Id
	ReplicatedStorage:SetAttribute("MapName", def.Name)
	ReplicatedStorage:SetAttribute("MapId", def.Id)
	return def
end

return MapBuilder
