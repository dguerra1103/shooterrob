local process = require("@lune/process")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local WeaponModels = req(game.ReplicatedStorage.Shared.WeaponModels)
local function count(m, v)
	local n = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.MaterialVariant == v then n += 1 end
	end
	return n
end
local m = WeaponModels.Build("ARX27", "CamoBosque")
print("sin variante:", count(m, "CamoBosque"))
local mv = mock.new("MaterialVariant"); mv.Name = "CamoBosque"; mv.Parent = game:GetService("MaterialService")
m = WeaponModels.Build("ARX27", "CamoBosque")
print("con variante:", count(m, "CamoBosque"))
WeaponModels.ApplySkin(m, "Default", "ARX27")
print("tras volver a Default:", count(m, "CamoBosque"))
