local PathfindingService = game:GetService("PathfindingService")
local out = {}
for _, c in { { 2, 5 }, { 1.5, 5 }, { 1, 5 }, { 2, 4 }, { 2, 3 }, { 1, 3 } } do
	local path = PathfindingService:CreatePath({ AgentRadius = c[1], AgentHeight = c[2], AgentCanJump = true, WaypointSpacing = 6 })
	pcall(function() path:ComputeAsync(Vector3.new(-140, 5, 0), Vector3.new(-60, 5, 0)) end)
	table.insert(out, ("centro de la base -> medio, radio %.1f alto %d: %s"):format(c[1], c[2], path.Status.Name))
end
local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5 })
pcall(function() path:ComputeAsync(Vector3.new(-140, 5, 0), Vector3.new(-130, 5, 6)) end)
table.insert(out, "dentro de la base, 12 studs: " .. path.Status.Name)
local f = workspace.Map:FindFirstChild("DesertHalf_Red")
local names = {}
for _, p in f:GetChildren() do if p:IsA("BasePart") then local k = p.Name .. (" %.0fx%.0fx%.0f"):format(p.Size.X, p.Size.Y, p.Size.Z) names[k] = (names[k] or 0) + 1 end end
local list = {} for k, v in names do table.insert(list, k .. " ×" .. v) end
table.sort(list)
table.insert(out, table.concat(list, " | "))
return table.concat(out, "\n")
