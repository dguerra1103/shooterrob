local process = require("@lune/process")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local Weapons = req(game.ReplicatedStorage.Shared.Weapons)
local Skins = req(game.ReplicatedStorage.Shared.Skins)
local WeaponModels = req(game.ReplicatedStorage.Shared.WeaponModels)
local Shop = req(game.ReplicatedStorage.Shared.Shop)
local n = 0
for w in Weapons.List do
	for s in Skins.List do
		local m = WeaponModels.Build(w, s)
		WeaponModels.ApplySkin(m, "Default", w)
		WeaponModels.ApplySkin(m, s, w)
		n += 1
	end
	local def = Weapons.List[w]
	for _, k in { "AimPoint", "RightHand", "ViewOffset" } do
		if def.Type == "Gun" and def[k] == nil then error(w .. " sin " .. k) end
	end
end
print("combos ok", n)
print("offers", #Shop.GetDailyOffers(20000), Shop.GetPrice("Skin", "Magma", 20000))
-- Sin ID duplicado de piezas por arma
for w, def in Weapons.List do
	local seen = {}
	for _, p in def.Parts do
		if seen[p.Name] then print("DUPLICADO", w, p.Name) end
		seen[p.Name] = true
	end
end
