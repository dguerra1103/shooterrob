local PathfindingService = game:GetService("PathfindingService")
local out = {}
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local ex = { workspace:FindFirstChild("Bots") }
for _, p in game.Players:GetPlayers() do if p.Character then table.insert(ex, p.Character) end end
params.FilterDescendantsInstances = ex
local o = Vector3.new(-124, 5, 14)
for name, dir in { arriba = Vector3.new(0, 30, 0), abajo = Vector3.new(0, -30, 0), ["+X"] = Vector3.new(60, 0, 0), ["-X"] = Vector3.new(-60, 0, 0), ["+Z"] = Vector3.new(0, 0, 60), ["-Z"] = Vector3.new(0, 0, -60) } do
	local r = workspace:Raycast(o, dir, params)
	table.insert(out, ("%s: %s"):format(name, r and (("%s a %.1f (size %.0f,%.0f,%.0f collide=%s transp=%.1f)"):format(r.Instance:GetFullName(), (r.Position - o).Magnitude, r.Instance.Size.X, r.Instance.Size.Y, r.Instance.Size.Z, tostring(r.Instance.CanCollide), r.Instance.Transparency)) or "nada"))
end
local function try(h, a, b, label)
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = h, AgentCanJump = true, WaypointSpacing = 6 })
	pcall(function() path:ComputeAsync(a, b) end)
	table.insert(out, ("%s (alto %s): %s"):format(label, tostring(h), path.Status.Name))
end
for _, h in { 5, 4, 3, 2 } do try(h, o, o + Vector3.new(5, 0, 0), "base, 5 studs") end
try(5, Vector3.new(-100, 5, 14), Vector3.new(-60, 5, 0), "delante de la base -> medio")
try(5, Vector3.new(-112, 5, 14), Vector3.new(-60, 5, 0), "x=-112 -> medio")
-- piezas que tocan la caja del bot
local parts = workspace:GetPartBoundsInBox(CFrame.new(o), Vector3.new(4, 6, 4))
local n = 0
for _, p in parts do
	if not p:IsDescendantOf(workspace.Bots) and p.CanCollide then n += 1; if n <= 6 then table.insert(out, ("  toca al bot: %s size=%.0f,%.0f,%.0f transp=%.1f"):format(p:GetFullName(), p.Size.X, p.Size.Y, p.Size.Z, p.Transparency)) end end
end
table.insert(out, "piezas con colisión dentro de la caja del bot: " .. n)
return table.concat(out, "\n")
