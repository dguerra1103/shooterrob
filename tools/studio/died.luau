local r
for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "Died" and d:IsA("RemoteEvent") then r = d end end
if not r then return "sin remoto Died" end
r:FireClient(game.Players:GetPlayers()[1], "Bot Kira", "Specter9", 100)
return "enviado"
