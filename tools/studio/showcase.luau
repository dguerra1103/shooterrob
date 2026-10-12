-- Escaparate en modo Edit: construye cada arma nueva con su acabado de fábrica y las pone en fila
local RS = game:GetService("ReplicatedStorage")
local old = workspace:FindFirstChild("SR_Showcase") if old then old:Destroy() end
local tmp = RS.Shared:Clone()
tmp.Name = "SharedTmp"
tmp.Parent = game:GetService("ServerStorage")
local Kit = require(tmp.WeaponMeshKit)
local folder = RS:FindFirstChild(Kit.Folder) or Instance.new("Folder")
folder.Name = Kit.Folder
folder.Parent = RS
local out = {}
local show = Instance.new("Folder")
show.Name = "SR_Showcase"
show.Parent = workspace
local WeaponModels
for i, name in Kit.Weapons do
	local prev = folder:FindFirstChild(name) if prev then prev:Destroy() end
	local t0 = os.clock()
	local ok, template = pcall(Kit.BuildTemplate, require(tmp.WeaponMeshes[name]))
	if ok then
		template.Parent = folder
		WeaponModels = WeaponModels or require(tmp.WeaponModels)
		local ok2, model = pcall(WeaponModels.Build, name, nil, false)
		if ok2 then
			local tris, parts = 0, 0
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") then p.Anchored = true parts += 1 if p:IsA("PartOperation") then tris += p.TriangleCount end end
			end
			model:PivotTo(CFrame.new(0, 60 - (i - 1) * 2.4, 0))
			model.Parent = show
			local _, size = model:GetBoundingBox()
			table.insert(out, ("%s: %.0f ms, piezas=%d, sueltas=%s, triángulos=%d, caja=%.2f x %.2f x %.2f, externa=%s"):format(name, (os.clock() - t0) * 1000, parts, tostring(template:GetAttribute("Loose")), tris, size.X, size.Y, size.Z, tostring(model:GetAttribute("External"))))
		else
			table.insert(out, name .. ": Build falla: " .. tostring(model))
		end
	else
		table.insert(out, name .. ": plantilla falla: " .. tostring(template))
	end
end
tmp:Destroy()
folder:Destroy()
return table.concat(out, "\n")
