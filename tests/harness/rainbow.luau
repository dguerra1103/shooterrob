local process = require("@lune/process")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local WeaponModels = req(game.ReplicatedStorage.Shared.WeaponModels)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local function tagged(m)
	local n = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("RainbowSkin") then
			n += 1
			assert(d:GetAttribute("RainbowSat") and d:GetAttribute("RainbowPhase"), "atributos")
		end
	end
	return n
end
for _, w in { "ARX27", "HavocPump", "Viper", "NovaLauncher" } do
	local m = WeaponModels.Build(w, "Arcoiris")
	check(tagged(m) > 0, w .. " Arcoíris: piezas animadas " .. tagged(m))
	local p = WeaponModels.Build(w, "Prisma")
	check(tagged(p) > 0, w .. " Prisma: piezas animadas " .. tagged(p))
	WeaponModels.ApplySkin(p, "Default", w)
	check(tagged(p) == 0, w .. " al cambiar de skin se quita la animación")
end
print("ARCOIRIS OK")
process.exit(0)
