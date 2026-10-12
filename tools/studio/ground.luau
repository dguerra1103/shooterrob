local PathfindingService = game:GetService("PathfindingService")
local rs = game.ReplicatedStorage
local out = { ("Map=%s State=%s"):format(tostring(rs:GetAttribute("MapId")), tostring(rs:GetAttribute("State"))) }
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }
for _, s in { { -100, 14 }, { -60, 0 }, { 40, 30 } } do
	local r = workspace:Raycast(Vector3.new(s[1], 40, s[2]), Vector3.new(0, -80, 0), params)
	table.insert(out, ("terreno en (%d,%d): y=%s"):format(s[1], s[2], r and ("%.2f"):format(r.Position.Y) or "nada"))
end
for _, c in { { 2, 5 }, { 1, 5 } } do
	local path = PathfindingService:CreatePath({ AgentRadius = c[1], AgentHeight = c[2], AgentCanJump = true, WaypointSpacing = 6 })
	pcall(function() path:ComputeAsync(Vector3.new(-140, 3, 0), Vector3.new(-60, 3, 0)) end)
	table.insert(out, ("centro de la base -> medio, radio %.1f alto %d: %s"):format(c[1], c[2], path.Status.Name))
end
local pos = {}
for _, m in workspace:GetDescendants() do if m:IsA("Model") and m:GetAttribute("Bot") and m:FindFirstChild("HumanoidRootPart") then pos[m] = m.HumanoidRootPart.Position end end
task.wait(5)
local moved, total, inBase = 0, 0, 0
for m, p in pos do total += 1
	if m.Parent and m:FindFirstChild("HumanoidRootPart") then
		local q = m.HumanoidRootPart.Position
		if (q - p).Magnitude > 2 then moved += 1 end
		if math.abs(q.X) > 122 and math.abs(q.Z) < 25 then inBase += 1 end
	end
end
table.insert(out, ("bots=%d movidos en 5 s=%d, aún dentro de una base=%d"):format(total, moved, inBase))
return table.concat(out, "\n")
