-- Registro de mapas: construye el mapa elegido y publica su nombre para la interfaz.
-- Si construyes tu propio mapa en Studio dentro de workspace.Map (sin el atributo "Generated"),
-- se usará ese y no habrá rotación de mapas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapBuilder = {}

MapBuilder.Defs = {}
for _, module in script.Parent.MapDefs:GetChildren() do
	local def = require(module)
	MapBuilder.Defs[def.Id] = def
end

-- Orden de rotación (también son las opciones de la votación)
MapBuilder.Order = { "HarborHeights", "ContainerClash", "NeonFoundry", "Downtown" }

MapBuilder.Current = nil

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
	def.Build()
	MapBuilder.Current = def.Id
	ReplicatedStorage:SetAttribute("MapName", def.Name)
	ReplicatedStorage:SetAttribute("MapId", def.Id)
	return def
end

return MapBuilder
