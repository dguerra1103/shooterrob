-- ¿Asoma el terreno por los suelos? Por cada punto de una rejilla: altura del terreno y la del suelo
-- (pieza plana visible) que lo cubre. Si el terreno queda a menos de 0,15 por debajo (o por encima),
-- se ve a través o parpadea.
local map = workspace.Map
local floors = {}
for _, d in map:GetDescendants() do
	if d:IsA("BasePart") and d.Transparency < 0.5 and d.Name ~= "ContactShadow" then
		local cf, s = d.CFrame, d.Size
		if math.abs(cf.UpVector.Y) > 0.9999 and s.X * s.Z >= 36 then
			local top = cf.Position.Y + s.Y / 2
			if top > -0.6 and top < 0.8 then
				local rx, rz = cf.RightVector, cf.LookVector
				local hx = (math.abs(rx.X) * s.X + math.abs(rz.X) * s.Z) / 2
				local hz = (math.abs(rx.Z) * s.X + math.abs(rz.Z) * s.Z) / 2
				table.insert(floors, { x0 = cf.X - hx, x1 = cf.X + hx, z0 = cf.Z - hz, z1 = cf.Z + hz, top = top, name = d.Name })
			end
		end
	end
end
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { workspace.Terrain }
local bad, covered, byFloor, tmin, tmax = 0, 0, {}, 99, -99
for x = -147, 147, 6 do
	for z = -117, 117, 6 do
		local r = workspace:Raycast(Vector3.new(x, 12, z), Vector3.new(0, -16, 0), rp)
		if r and r.Material ~= Enum.Material.Water then
			local best
			for _, f in floors do
				if x > f.x0 and x < f.x1 and z > f.z0 and z < f.z1 and (not best or f.top > best.top) then best = f end
			end
			if best then
				covered += 1
				tmin, tmax = math.min(tmin, r.Position.Y), math.max(tmax, r.Position.Y)
				if r.Position.Y > best.top - 0.15 then
					bad += 1
					byFloor[best.name] = (byFloor[best.name] or 0) + 1
				end
			end
		end
	end
end
local s = {}
for k, v in byFloor do s[#s + 1] = k .. "x" .. v end
table.sort(s)
return string.format("%s: terreno bajo suelos entre %.2f y %.2f · puntos cubiertos %d · asoma en %d · %s", tostring(map:GetAttribute("MapName")), tmin, tmax, covered, bad, table.concat(s, " "))
