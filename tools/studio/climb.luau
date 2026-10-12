-- ¿Suben los bots? Muestra durante 70 s la altura de cada bot
local folder = workspace:FindFirstChild("Bots")
local top = {}
local stuck = {}
local last = {}
for i = 1, 70 do
	for _, m in folder and folder:GetChildren() or {} do
		local root = m:FindFirstChild("HumanoidRootPart")
		local hum = m:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			top[m.Name] = math.max(top[m.Name] or -99, root.Position.Y)
			if last[m.Name] and (last[m.Name] - root.Position).Magnitude < 0.3 then stuck[m.Name] = (stuck[m.Name] or 0) + 1 else stuck[m.Name] = 0 end
			last[m.Name] = root.Position
		end
	end
	task.wait(1)
end
local s, high, higher = {}, 0, 0
for name, y in top do
	s[#s + 1] = string.format("%s=%.0f", string.gsub(name, "Bot ", ""), y)
	if y > __A__ then high += 1 end
	if y > __B__ then higher += 1 end
end
local still = 0
for _, n in stuck do if n >= 12 then still += 1 end end
return tostring(game.ReplicatedStorage:GetAttribute("MapId")) .. ": altura máxima por bot: " .. table.concat(s, " ") .. " · por encima de __A__: " .. high .. " · por encima de __B__: " .. higher .. " · parados 12 s o más al final: " .. still
