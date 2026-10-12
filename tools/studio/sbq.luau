local p = game.Players:GetPlayers()[1]
local c = p.Character
local h = c:FindFirstChildOfClass("Humanoid")
local out = {}
local ok, d = pcall(function() return h:GetAppliedDescription() end)
if ok then table.insert(out, ("desc Torso=%d LArm=%d RLeg=%d Head=%d BodyType=%.2f Width=%.2f Height=%.2f"):format(d.Torso, d.LeftArm, d.RightLeg, d.Head, d.BodyTypeScale, d.WidthScale, d.HeightScale)) else table.insert(out, "desc error " .. tostring(d)) end
for _, n in { "UpperTorso", "LeftUpperArm", "LeftLowerArm", "LeftUpperLeg", "LeftLowerLeg", "Head" } do
	local part = c:FindFirstChild(n)
	if part then table.insert(out, ("%s size=%.2f,%.2f,%.2f transp=%.1f mesh=%s"):format(n, part.Size.X, part.Size.Y, part.Size.Z, part.Transparency, tostring(part:IsA("MeshPart") and part.MeshId or "-"))) else table.insert(out, n .. " NO") end
end
local acc = {} for _, a in c:GetChildren() do if a:IsA("Accessory") then table.insert(acc, a.Name .. ":" .. a.AccessoryType.Name) end end
table.insert(out, "accesorios: " .. table.concat(acc, ", "))
return table.concat(out, "\n")
