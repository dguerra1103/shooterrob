-- Comprueba que la línea de mira (desde AimPoint hacia -Z) no atraviesa piezas opacas,
-- que el cañón (Muzzle) está delante de todo y que las manos tocan alguna pieza.
local Vector3 = require("@lune/roblox").Vector3
local process = require("@lune/process")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local Weapons = req(game.ReplicatedStorage.Shared.Weapons)

local IGNORE = { Lens = true, Accent = false }
local function inside(part, point, pad)
	local lp = part.CFrame:PointToObjectSpace(point)
	local h = part.Size / 2
	return math.abs(lp.X) <= h.X + pad and math.abs(lp.Y) <= h.Y + pad and math.abs(lp.Z) <= h.Z + pad
end
for name, def in Weapons.List do
	if def.Type ~= "Gun" then continue end
	local blocked = {}
	for z = def.AimPoint.Z, def.AimPoint.Z - 6, -0.05 do
		local pt = Vector3.new(0, def.AimPoint.Y, z)
		for _, p in def.Parts do
			if p.Role ~= "Lens" and not (p.Size.Magnitude < 0.06) and not p.Name:find("Dot") and not p.Name:find("Reticle") and not p.Name:find("Bead") then
				if inside(p, pt, -0.005) and not blocked[p.Name] then
					blocked[p.Name] = string.format("%.2f", z)
				end
			end
		end
	end
	local list = {}
	for n, z in blocked do table.insert(list, n .. "@" .. z) end
	-- manos
	local function touches(v)
		for _, p in def.Parts do if inside(p, v, 0.12) then return true end end
		return false
	end
	local minZ = math.huge
	for _, p in def.Parts do
		local front = p.CFrame.Position.Z - math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2
		minZ = math.min(minZ, front)
	end
	print(string.format("%-16s mira:%s  manoD:%s manoI:%s  muzzleZ %.2f frente %.2f", name,
		#list == 0 and "libre" or table.concat(list, ","), tostring(touches(def.RightHand)), tostring(def.LeftHand == nil or touches(def.LeftHand)), def.Muzzle.Z, minZ))
end
