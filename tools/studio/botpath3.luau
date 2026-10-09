local PathfindingService = game:GetService("PathfindingService")
local out = {}
local function try(h, a, b, label, extra)
	local cfg = { AgentRadius = 2, AgentHeight = h, AgentCanJump = true, WaypointSpacing = 6 }
	for k, v in extra or {} do cfg[k] = v end
	local path = PathfindingService:CreatePath(cfg)
	pcall(function() path:ComputeAsync(a, b) end)
	table.insert(out, ("%s (alto %s): %s"):format(label, tostring(h), path.Status.Name))
end
for _, h in { 5, 3, 2 } do try(h, Vector3.new(-60, 5, 0), Vector3.new(-30, 5, 0), "medio rojo -> 30 studs") end
try(5, Vector3.new(-60, 2.5, 0), Vector3.new(-30, 2.5, 0), "igual, a ras de suelo")
local map = workspace:FindFirstChild("Map")
local low = {}
for _, d in map:GetDescendants() do
	if d:IsA("BasePart") and d.CanCollide and d.Transparency >= 0.95 then
		local bottom = d.Position.Y - d.Size.Y / 2
		if bottom < 8 and d.Size.X * d.Size.Z > 100 then table.insert(low, ("%s size=%.0f,%.0f,%.0f pos=%.0f,%.0f,%.0f fondo=%.1f"):format(d.Name, d.Size.X, d.Size.Y, d.Size.Z, d.Position.X, d.Position.Y, d.Position.Z, bottom)) end
	end
end
table.insert(out, "invisibles con colisión y fondo < 8: " .. #low)
for i = 1, math.min(#low, 10) do table.insert(out, "  " .. low[i]) end
-- ¿hay Terrain de verdad bajo el mapa? ¿y agua?
local region = Region3.new(Vector3.new(-64, -4, -4), Vector3.new(-56, 4, 4)):ExpandToGrid(4)
local mats, occ = workspace.Terrain:ReadVoxels(region, 4)
local seen = {}
for x = 1, mats.Size.X do for y = 1, mats.Size.Y do for z = 1, mats.Size.Z do seen[mats[x][y][z].Name] = (seen[mats[x][y][z].Name] or 0) + 1 end end end
local s = {} for k, v in seen do table.insert(s, k .. "=" .. v) end
table.insert(out, "vóxeles bajo (-60,0): " .. table.concat(s, " "))
table.insert(out, "otro mapa cargado antes? atributos Map: Realistic=" .. tostring(map:GetAttribute("Realistic")) .. " Terrain=" .. tostring(map:GetAttribute("Terrain")))
return table.concat(out, "\n")
