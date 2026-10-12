local PS = game:GetService("PathfindingService")
local out = {}
local from
for _, d in workspace.Map:GetDescendants() do if d:IsA("SpawnLocation") and d.Position.X < 0 then from = d.Position + Vector3.new(0,3,0) break end end
local solid = RaycastParams.new() solid.RespectCanCollide = true solid.FilterType = Enum.RaycastFilterType.Exclude solid.FilterDescendantsInstances = { workspace.Map:FindFirstChild("Boundary"), workspace.Map:FindFirstChild("Callouts") }
for _, t in { __PTS__ } do
  local target = Vector3.new(t[1], t[2], t[3])
  local line = ("%d,%d,%d:"):format(t[1], t[2], t[3])
  local down = workspace:Raycast(target + Vector3.new(0, 4, 0), Vector3.new(0, -30, 0), solid)
  line ..= down and (" suelo y=%.1f %s"):format(down.Position.Y, down.Instance.Name) or " sin suelo"
  for _, cfg in { {2,5,true}, {1,5,true}, {1,3,true}, {0.5, 2, true} } do
    local path = PS:CreatePath({ AgentRadius = cfg[1], AgentHeight = cfg[2], AgentCanJump = cfg[3], WaypointSpacing = 8 })
    pcall(function() path:ComputeAsync(from, target + Vector3.new(0,3,0)) end)
    line ..= (" r%.1f/h%d=%s"):format(cfg[1], cfg[2], path.Status.Name)
  end
  -- camino inverso y desde el centro
  local path = PS:CreatePath({ AgentRadius = 1, AgentHeight = 5, AgentCanJump = true })
  pcall(function() path:ComputeAsync(target + Vector3.new(0,3,0), from) end)
  line ..= " inverso=" .. path.Status.Name
  local ov = OverlapParams.new() ov.RespectCanCollide = true
  local near = workspace:GetPartBoundsInBox(CFrame.new(target + Vector3.new(0, 3.5, 0)), Vector3.new(3, 5, 3), ov)
  local names = {}
  for _, q in near do if q.CanCollide and q.Transparency < 1 then names[#names+1] = ("%s[%.1f,%.1f,%.1f @ %.1f,%.1f,%.1f]"):format(q.Name, q.Size.X, q.Size.Y, q.Size.Z, q.Position.X, q.Position.Y, q.Position.Z) end end
  line ..= " cerca: " .. table.concat(names, " ", 1, math.min(4, #names))
  out[#out+1] = line
end
return table.concat(out, "\n")
