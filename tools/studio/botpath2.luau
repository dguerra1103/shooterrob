local PathfindingService = game:GetService("PathfindingService")
local out = {}
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { workspace:FindFirstChild("Bots"), table.unpack((function() local t = {} for _, p in game.Players:GetPlayers() do if p.Character then table.insert(t, p.Character) end end return t end)()) }
local function ground(x, z)
	local r = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -200, 0), params)
	return r
end
local function try(a, b, label)
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
	pcall(function() path:ComputeAsync(a, b) end)
	table.insert(out, ("%s: %s puntos=%d"):format(label, path.Status.Name, path.Status == Enum.PathStatus.Success and #path:GetWaypoints() or 0))
end
for _, spot in { { -124, 14, "base roja" }, { -100, 14, "salida base" }, { -60, 0, "medio rojo" }, { 0, 0, "centro" } } do
	local r = ground(spot[1], spot[2])
	if r then
		table.insert(out, ("%s (%d,%d): techo/suelo desde arriba = %s y=%.1f mat=%s collide=%s size=%s"):format(spot[3], spot[1], spot[2], r.Instance:GetFullName(), r.Position.Y, r.Material.Name, tostring(r.Instance.CanCollide), tostring(r.Instance.Size)))
	else
		table.insert(out, spot[3] .. ": nada")
	end
end
-- suelo real dentro de la base (rayo desde la altura del bot)
local r2 = workspace:Raycast(Vector3.new(-124, 5, 14), Vector3.new(0, -20, 0), params)
table.insert(out, "bajo el bot en la base: " .. tostring(r2 and (r2.Instance:GetFullName() .. (" y=%.1f collide=%s size=%s"):format(r2.Position.Y, tostring(r2.Instance.CanCollide), tostring(r2.Instance.Size)))))
local gy = r2 and r2.Position.Y + 3 or 5
try(Vector3.new(0, gy, 0), Vector3.new(30, gy, 0), "centro -> 30 studs")
try(Vector3.new(-60, gy, 0), Vector3.new(0, gy, 0), "medio rojo -> centro")
try(Vector3.new(-124, gy, 14), Vector3.new(-118, gy, 14), "dentro de la base, 6 studs")
local mods, big = 0, {}
local map = workspace:FindFirstChild("Map")
for _, d in (map and map:GetDescendants() or {}) do
	if d:IsA("PathfindingModifier") then mods += 1 end
	if d:IsA("BasePart") and d.CanCollide and d.Transparency >= 0.95 and d.Size.X * d.Size.Z > 400 then table.insert(big, ("%s %s size=%s pos=%s"):format(d.Name, d.ClassName, tostring(d.Size), tostring(d.Position))) end
end
table.insert(out, "PathfindingModifier=" .. mods .. " piezas invisibles grandes con colisión=" .. #big)
for i = 1, math.min(#big, 8) do table.insert(out, "  " .. big[i]) end
table.insert(out, "partes del mapa=" .. tostring(map and #map:GetDescendants()))
return table.concat(out, "\n")
