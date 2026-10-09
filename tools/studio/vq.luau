local lp = game.Players.LocalPlayer
local vf = lp.PlayerGui.MainMenu.FlowRoot.Home:FindFirstChild("HeroPreview")
local rig
for _, m in vf:GetDescendants() do if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then rig = m end end
if not rig then return "sin rig" end
local out = {}
for _, n in { "UpperTorso", "LeftUpperArm", "RightLowerArm", "LeftUpperLeg", "RightLowerLeg", "Head" } do
	local p = rig:FindFirstChild(n)
	if p then table.insert(out, ("%s %s size=%.2f,%.2f,%.2f pos=%.1f,%.1f,%.1f tr=%.1f ltm=%.1f color=%d,%d,%d mesh=%s"):format(n, p.ClassName, p.Size.X, p.Size.Y, p.Size.Z, p.Position.X, p.Position.Y, p.Position.Z, p.Transparency, p.LocalTransparencyModifier, p.Color.R*255, p.Color.G*255, p.Color.B*255, tostring(p:IsA("MeshPart") and string.sub(p.MeshId, -12) or "-"))) else table.insert(out, n .. " NO ESTÁ") end
end
local real = lp.Character
local rp = real and real:FindFirstChild("LeftUpperLeg")
table.insert(out, "real LeftUpperLeg: " .. (rp and ("size=%.2f,%.2f,%.2f tr=%.1f ltm=%.1f mesh=%s"):format(rp.Size.X, rp.Size.Y, rp.Size.Z, rp.Transparency, rp.LocalTransparencyModifier, string.sub(rp.MeshId, -12)) or "no"))
local n = 0 for _, d in rig:GetDescendants() do if d:IsA("WrapTarget") or d:IsA("WrapLayer") then n += 1 end end
table.insert(out, "wraps en la copia=" .. n)
return table.concat(out, "\n")
