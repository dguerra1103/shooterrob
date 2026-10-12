local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end
if not r then return "sin remoto QA" end
r:FireServer("NextMatch", { Map = "DesertBase", Mode = "TDM", Now = true })
return "pedido DesertBase TDM"
