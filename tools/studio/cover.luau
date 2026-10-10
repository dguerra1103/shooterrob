-- Análisis de coberturas del mapa actual: puntos del suelo jugable desde los que no hay nada tras lo
-- que cubrirse a menos de LIMIT studs, agrupados en zonas (lado X <= 0).
local map = workspace.Map
local B = __BOUNDS__
local LIMIT = 24
local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.FilterDescendantsInstances = { map:FindFirstChild("Boundary"), map:FindFirstChild("Callouts") }
ray.RespectCanCollide = true
local pts, total = {}, 0
for x = -B.X / 2 + 6, 0, 6 do
	for z = -B.Z / 2 + 6, B.Z / 2 - 6, 6 do
		local hit = workspace:Raycast(Vector3.new(x, B.Y - 3, z), Vector3.new(0, -(B.Y + 4), 0), ray)
		if hit and hit.Position.Y > -1 and hit.Position.Y < __MAXY__ and hit.Normal.Y > 0.95 and hit.Material ~= Enum.Material.Water then
			total += 1
			local p = hit.Position + Vector3.new(0, 2.6, 0)
			local nearest = 999
			for i = 0, 15 do
				local a = i * math.pi / 8
				local r = workspace:Raycast(p, Vector3.new(math.cos(a), 0, math.sin(a)) * 60, ray)
				if r then nearest = math.min(nearest, r.Distance) end
			end
			if nearest > LIMIT then table.insert(pts, { p = hit.Position, d = nearest }) end
		end
	end
end
-- Agrupa (vecinos a 6 studs)
local groups = {}
local seen = {}
for i, a in pts do
	if not seen[i] then
		local g, queue = { a }, { i }
		seen[i] = true
		while #queue > 0 do
			local k = table.remove(queue)
			for j, b in pts do
				if not seen[j] and (pts[k].p - b.p).Magnitude < 8.6 then seen[j] = true table.insert(g, b) table.insert(queue, j) end
			end
		end
		table.insert(groups, g)
	end
end
table.sort(groups, function(a, b) return #a > #b end)
local out = { ("%s: %d puntos de suelo, %d expuestos (%.0f %%), %d zonas"):format(tostring(map:GetAttribute("MapName")), total, #pts, #pts / math.max(total, 1) * 100, #groups) }
for i = 1, math.min(8, #groups) do
	local g = groups[i]
	local c, far = Vector3.zero, 0
	local x0, x1, z0, z1 = 999, -999, 999, -999
	for _, e in g do c += e.p far = math.max(far, e.d) x0 = math.min(x0, e.p.X) x1 = math.max(x1, e.p.X) z0 = math.min(z0, e.p.Z) z1 = math.max(z1, e.p.Z) end
	c /= #g
	table.insert(out, ("  zona %d: %d puntos, centro (%.0f, %.1f, %.0f), x %d..%d z %d..%d, hasta %.0f studs sin cobertura"):format(i, #g, c.X, c.Y, c.Z, x0, x1, z0, z1, far))
end
return table.concat(out, "\n")
