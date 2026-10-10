-- Detalle de suelo repartido por el mapa (lo llama MapBuilder.Build antes del repaso de MapCheck):
-- manchas de aceite, grietas, rodadas, charcos y tapas de alcantarilla en las zonas abiertas, para que
-- los patios y las calles no sean un plano liso. Es solo decorado: piezas finas que no chocan, no
-- paran balas ni hacen sombra. El reparto es fijo por mapa (misma semilla: los dos equipos ven lo
-- mismo en todas las partidas) y simétrico en X, como los mapas.
--
-- MapCheck coloca después cada pieza sobre el suelo que de verdad tiene debajo y separa las que se
-- pisan, así que aquí basta con dejarlas a ras del punto encontrado.
local MapDress = {}

MapDress.Enabled = true

-- Cuántos de cada cosa POR MITAD del mapa (se reflejan en la otra). Sin entrada = sin detalle
MapDress.Profiles = {
	Dockyard = { Stains = 6, Cracks = 4, Tires = 3, Puddles = 3 },
	IndustrialYard = { Stains = 7, Cracks = 5, Tires = 3, Puddles = 3 },
	MetroYard = { Stains = 3, Cracks = 4, Puddles = 2, Manholes = 2 },
	Terminal = { Stains = 4, Cracks = 3, Tires = 4 },
	DesertBase = { Stains = 4, Cracks = 4, Tires = 3 },
	Construction = { Stains = 3, Cracks = 3, Puddles = 3 },
	RooftopDistrict = { Stains = 2, Cracks = 3, Puddles = 4, MaxY = 7 },
	Coastal = { Cracks = 3, Puddles = 2 },
}

local V = Vector3.new

local function near(points, position, distance)
	for _, p in points do
		if (V(p.X, 0, p.Z) - V(position.X, 0, position.Z)).Magnitude < distance then
			return true
		end
	end
	return false
end

function MapDress.Apply(def, Kit)
	local profile = MapDress.Enabled and def and MapDress.Profiles[def.Id]
	local map = workspace:FindFirstChild("Map")
	if not profile or not map or not def.Bounds then
		return 0
	end
	-- Sitios donde no se pone nada: bases, objetivos y puntos de aparición
	local keepOut, spawns = {}, {}
	for _, d in map:GetDescendants() do
		if d:IsA("SpawnLocation") then
			table.insert(spawns, d.Position)
		elseif d:IsA("BasePart") and (d.Name == "BombSite" or d.Name == "FlagBase" or d.Name == "HardpointZone" or d.Name == "FFASpawn") then
			table.insert(keepOut, d.Position)
		end
	end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = { map:FindFirstChild("Boundary"), map:FindFirstChild("Callouts") }
	ray.RespectCanCollide = true
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { map:FindFirstChild("Boundary"), map:FindFirstChild("Callouts") }
	overlap.RespectCanCollide = true

	local seed = 0
	for i = 1, #def.Id do
		seed = (seed * 31 + string.byte(def.Id, i)) % 100000
	end
	local rng = Random.new(seed)
	local halfX, halfZ = def.Bounds.X / 2 - 8, def.Bounds.Z / 2 - 8
	local top = def.Bounds.Y - 3
	local maxY = profile.MaxY or 0.6
	local used = {}

	-- Un sitio a cielo abierto, llano y despejado, en la mitad X < 0; radius = lo que ocupa
	local function spot(radius)
		for _ = 1, 40 do
			local x, z = -rng:NextNumber(6, halfX), rng:NextNumber(-halfZ, halfZ)
			local hit = workspace:Raycast(V(x, top, z), V(0, -(top + 6), 0), ray)
			if hit and hit.Position.Y > -0.6 and hit.Position.Y < maxY and hit.Normal.Y > 0.99 and hit.Material ~= Enum.Material.Water then
				local position = hit.Position
				local free = #workspace:GetPartBoundsInBox(CFrame.new(position + V(0, 2.2, 0)), V(radius * 2, 3.6, radius * 2), overlap) == 0
				if free and not near(spawns, position, 16) and not near(keepOut, position, 9) and not near(used, position, radius + 5) then
					table.insert(used, position)
					return position
				end
			end
		end
		return nil
	end

	local folder = Instance.new("Folder")
	folder.Name = "Dressing"
	folder.Parent = map
	local previous = Kit.folder
	Kit.folder = folder
	local placed = 0
	local function each(count, radius, fn)
		for _ = 1, count or 0 do
			local position = spot(radius)
			if position then
				for _, side in { 1, -1 } do
					fn(V(position.X * side, position.Y, position.Z), side)
					placed += 1
				end
			end
		end
	end
	local ok, err = pcall(function()
		each(profile.Tires, 9, function(position, side)
			local yaw = rng:NextNumber(0, math.pi * 2)
			Kit.tireMarks(CFrame.new(position) * CFrame.Angles(0, side > 0 and yaw or -yaw, 0), rng:NextNumber(12, 18), rng:NextNumber(-0.5, 0.5) * side)
		end)
		each(profile.Manholes, 2.5, function(position)
			Kit.manhole(position)
		end)
		each(profile.Puddles, 3.5, function(position)
			Kit.puddle(position, rng:NextNumber(2.4, 4.2), math.floor(math.abs(position.X) * 7 + position.Z * 13))
		end)
		each(profile.Stains, 2.5, function(position)
			Kit.oilStain(position, rng:NextNumber(1.8, 3.2), math.floor(math.abs(position.X) * 13 + position.Z * 3))
		end)
		each(profile.Cracks, 4, function(position)
			Kit.crack(position, rng:NextNumber(5, 9), math.floor(math.abs(position.X) * 7 + position.Z * 17))
		end)
	end)
	Kit.folder = previous
	if not ok then
		warn("[MapDress]", err)
	end
	map:SetAttribute("Dressing", placed)
	return placed
end

return MapDress
