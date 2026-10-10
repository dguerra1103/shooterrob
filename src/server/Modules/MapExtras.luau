-- Coberturas y decoración añadidas a los mapas después de construirlos (lo llama MapBuilder.Build,
-- antes del detalle de suelo y del repaso). Tapan los huecos que salieron al medir las coberturas
-- (tools/studio/cover.js: zonas del suelo sin nada tras lo que cubrirse a menos de 24 studs) y dan
-- algo de vida a las esquinas vacías.
--
-- Todo se coloca por parejas reflejadas en X (los dos equipos, lo mismo) y solo si el sitio está
-- libre: si un mapa cambia y algo cae encima de otra cosa, esa pieza no se pone y sale un aviso.
local MapExtras = {}

MapExtras.Enabled = true

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

-- por mapa: function(T, put). put(x, z, yaw, radius, fn): fn(cf) en (x, z) y en su reflejo
MapExtras.Maps = {}

function MapExtras.Maps.MetroYard(T, put)
	-- Plaza y calle del oeste: jardineras con árbol, bancos, un coche aparcado y una valla de obra
	put(-128, -70, 0, 4, function(cf) T.planter(cf, 6, 3) end)
	put(-128, -92, 0, 4, function(cf) T.planter(cf, 6, 3) end)
	put(-140, -60, 0, 3, function(cf) T.tree(cf) end)
	put(-140, -98, 0, 3, function(cf) T.tree(cf) end)
	put(-118, -82, 90, 7, function(cf) T.Kit.car(cf, RGB(196, 60, 48)) end)
	put(-134, -81, 90, 3.5, function(cf) T.bench(cf) end)
	put(-141, 60, 90, 4, function(cf) T.planter(cf, 6, 3) end)
	put(-141, 92, 90, 4, function(cf) T.planter(cf, 6, 3) end)
	put(-140, 76, 15, 5, function(cf) T.crateStack(cf, "L") end)
	put(-84, -103, 90, 5, function(cf) T.jersey(cf, 8) end)
	put(-138, -76, 0, 7, function(cf) T.Kit.car(cf, RGB(60, 110, 190)) end)
	put(-135, -54, 90, 5, function(cf) T.jersey(cf, 8) end)
	put(-116, -100, 10, 3.5, function(cf) T.blockPallet(cf, 3) end)
	put(-143, -102, 0, 3, function(cf) T.tree(cf) end)
end

function MapExtras.Maps.Dockyard(T, put)
	-- Canto del muelle: carga suelta entre las grúas
	put(-124, -110, 0, 7, function(cf) T.crateStack(cf, "Wall") end)
	put(-110, -108, 10, 3.5, function(cf) T.blockPallet(cf, 3) end)
	put(-96, -112, 0, 3.5, function(cf) T.crateStack(cf, "Tower") end)
	put(-84, -109, -20, 5, function(cf) T.crateStack(cf, "L") end)
	put(-90, -106, 0, 1.6, function(cf) T.barrel(cf) end)
	put(-102, -113, 0, 1.6, function(cf) T.barrel(cf, { RGB(196, 56, 44), Enum.Material.Metal }) end)
	put(-116, 106, 30, 5, function(cf) T.crateStack(cf, "L") end)
	put(-110, 110, 0, 1.6, function(cf) T.barrel(cf) end)
	put(-57, -2, 0, 5, function(cf) T.jersey(cf, 8) end)
end

function MapExtras.Maps.Terminal(T, put)
	-- Plataforma: equipos de tierra junto al avión
	put(-10, -9, 25, 4, function(cf) T.gpu(cf) end)
	put(-30, 41, 0, 4.5, function(cf) T.uld(cf, "ContainerBlue") end)
	put(-30, 2, 90, 4.5, function(cf) T.uld(cf, "ContainerRed") end)
	put(-24, 36, 0, 1.2, function(cf) T.cone(cf) end)
	put(-24, 46, 0, 1.2, function(cf) T.cone(cf) end)
end

function MapExtras.Maps.DesertBase(T, put)
	put(-81, -36, 90, 5, function(cf) T.hesco(cf, 2, 4) end)
	put(-120, 72, 0, 5, function(cf) T.jersey(cf, 8) end)
	put(-120, -54, 0, 5, function(cf) T.jersey(cf, 8) end)
end

function MapExtras.Apply(def, T)
	local build = MapExtras.Enabled and def and MapExtras.Maps[def.Id]
	local map = workspace:FindFirstChild("Map")
	if not build or not map then
		return 0
	end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = { map:FindFirstChild("Boundary"), map:FindFirstChild("Callouts") }
	ray.RespectCanCollide = true
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = { map }
	overlap.RespectCanCollide = true
	local folder = Instance.new("Folder")
	folder.Name = "Extras"
	folder.Parent = map
	local previous = T.Kit.folder
	T.Kit.folder = folder
	local placed, skipped = 0, {}

	local function free(x, z, radius)
		local hit = workspace:Raycast(V(x, 12, z), V(0, -16, 0), ray)
		if not hit or math.abs(hit.Position.Y) > 0.6 or hit.Normal.Y < 0.99 then
			return nil
		end
		for _, part in workspace:GetPartBoundsInBox(CFrame.new(x, hit.Position.Y + 2.4, z), V(radius * 2, 4, radius * 2), overlap) do
			if part.CanCollide and not part:IsDescendantOf(folder) and not (map:FindFirstChild("Boundary") and part:IsDescendantOf(map.Boundary)) then
				return nil
			end
		end
		return hit.Position.Y
	end

	local function put(x, z, yaw, radius, fn)
		-- (los dos lados o ninguno: el mapa sigue siendo simétrico)
		local y = free(x, z, radius)
		local yMirror = free(-x, z, radius)
		if not y or not yMirror then
			table.insert(skipped, ("(%d, %d)"):format(x, z))
			return
		end
		local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, rad(yaw), 0)
		fn(cf)
		fn(T.mirrorCFrame(cf))
		placed += 2
	end

	local ok, err = pcall(build, T, put)
	T.Kit.folder = previous
	if not ok then
		warn("[MapExtras]", err)
	end
	if #skipped > 0 then
		warn(("[MapExtras] %s: sitio ocupado, no se ha puesto en %s"):format(def.Id, table.concat(skipped, " ")))
	end
	map:SetAttribute("Extras", placed)
	map:SetAttribute("ExtrasSkipped", #skipped)
	return placed
end

return MapExtras
