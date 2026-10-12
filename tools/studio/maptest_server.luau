local rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local map = workspace:FindFirstChild("Map")
local out = {}
local maps = 0
for _, c in workspace:GetChildren() do if c.Name == "Map" then maps += 1 end end
out[#out+1] = ("MAPA=%s MODO=%s ESTADO=%s · carpetas Map=%d · piezas=%d"):format(tostring(rs:GetAttribute("MapId")), tostring(rs:GetAttribute("Mode")), tostring(rs:GetAttribute("State")), maps, map and #map:GetDescendants() or 0)
if map then
  out[#out+1] = ("repaso: %s · malla lista a los %s s · avisos %s"):format(tostring(map:GetAttribute("MapCheck")), tostring(map:GetAttribute("NavReady")), tostring(map:GetAttribute("MapCheckIssues")))
  local text = map:GetAttribute("MapCheckText")
  if text and text ~= "" then out[#out+1] = "  " .. string.gsub(text, "\n", "\n  ") end
end
-- Lo que hay en workspace fuera del mapa
local extra = {}
for _, c in workspace:GetChildren() do
  if c ~= map and not c:IsA("Terrain") and not c:IsA("Camera") and not Players:GetPlayerFromCharacter(c) then
    extra[#extra+1] = c.Name .. "(" .. c.ClassName .. "," .. #c:GetDescendants() .. ")"
  end
end
out[#out+1] = "workspace: " .. table.concat(extra, " ")
-- Bots: se mueven, no están bajo el suelo ni dentro de una pieza
local ov = OverlapParams.new() ov.RespectCanCollide = true ov.FilterType = Enum.RaycastFilterType.Exclude
local bots = {}
local folder = workspace:FindFirstChild("Bots")
for _, m in folder and folder:GetChildren() or {} do
  local root = m:FindFirstChild("HumanoidRootPart")
  if root then bots[m] = root.Position end
end
task.wait(6)
local total, moved, fallen, inside, where = 0, 0, 0, 0, {}
for m, p in bots do
  total += 1
  local root = m.Parent and m:FindFirstChild("HumanoidRootPart")
  if root then
    local q = root.Position
    if (q - p).Magnitude > 2 then moved += 1 end
    if q.Y < -15 then fallen += 1 end
    ov.FilterDescendantsInstances = { m, folder }
    for _, hit in workspace:GetPartBoundsInBox(CFrame.new(q), Vector3.new(0.6, 1.2, 0.6), ov) do
      if hit.CanCollide and hit:IsDescendantOf(map) then inside += 1 where[#where+1] = ("%s en (%.0f,%.0f,%.0f)"):format(hit.Name, q.X, q.Y, q.Z) break end
    end
  else
    moved += 1 -- (murió y reapareció: estaba en combate)
  end
end
out[#out+1] = ("bots=%d · movidos en 6 s=%d · caídos=%d · dentro de una pieza=%d %s"):format(total, moved, fallen, inside, table.concat(where, "; ", 1, math.min(3, #where)))
for _, plr in Players:GetPlayers() do
  local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  out[#out+1] = ("jugador %s equipo=%s pos=%s"):format(plr.Name, tostring(plr.Team), root and ("(%.0f,%.0f,%.0f)"):format(root.Position.X, root.Position.Y, root.Position.Z) or "sin personaje")
end
local score = {}
for _, t in game:GetService("Teams"):GetChildren() do score[#score+1] = t.Name .. "=" .. tostring(t:GetAttribute("Score")) end
out[#out+1] = "marcador: " .. table.concat(score, " ") .. " · tiempo=" .. tostring(rs:GetAttribute("TimeLeft"))
return table.concat(out, "\n")
