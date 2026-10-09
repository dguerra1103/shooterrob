local PathfindingService = game:GetService("PathfindingService")
local rs = game.ReplicatedStorage
local out = { ("Map=%s Mode=%s State=%s Frozen=%s TimeLeft=%s"):format(tostring(rs:GetAttribute("MapId")), tostring(rs:GetAttribute("Mode")), tostring(rs:GetAttribute("State")), tostring(rs:GetAttribute("Frozen")), tostring(rs:GetAttribute("TimeLeft"))) }
local bots = {}
for _, m in workspace:GetDescendants() do
	if m:IsA("Model") and m:GetAttribute("Bot") and m:FindFirstChild("HumanoidRootPart") then table.insert(bots, m) end
end
local start = {}
for _, b in bots do start[b] = b.HumanoidRootPart.Position end
local b = bots[1]
if b then
	local from = b.HumanoidRootPart.Position
	for _, goal in { Vector3.new(0, from.Y, 0), Vector3.new(-from.X, from.Y, from.Z), from + Vector3.new(from.X > 0 and -30 or 30, 0, 0) } do
		for _, radius in { 2, 1.5, 1 } do
			local path = PathfindingService:CreatePath({ AgentRadius = radius, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
			local ok, err = pcall(function() path:ComputeAsync(from, goal) end)
			table.insert(out, ("de (%.0f,%.0f,%.0f) a (%.0f,%.0f,%.0f) radio %.1f -> %s %s puntos=%d"):format(from.X, from.Y, from.Z, goal.X, goal.Y, goal.Z, radius, tostring(ok), path.Status.Name, ok and #path:GetWaypoints() or 0))
		end
	end
	-- ¿qué hay bajo y alrededor del bot?
	local ray = workspace:Raycast(from, Vector3.new(0, -12, 0))
	table.insert(out, "suelo bajo el bot: " .. tostring(ray and (ray.Instance:GetFullName() .. " mat=" .. ray.Material.Name .. " canCollide=" .. tostring(ray.Instance.CanCollide))))
end
task.wait(5)
local moved = 0
for _, m in bots do if m.Parent and m:FindFirstChild("HumanoidRootPart") and (m.HumanoidRootPart.Position - start[m]).Magnitude > 2 then moved += 1 end end
table.insert(out, ("bots=%d se movieron en 5 s=%d"):format(#bots, moved))
return table.concat(out, "\n")
