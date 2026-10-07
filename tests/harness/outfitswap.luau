-- Cambiar de traje devuelve los colores del avatar (cabeza, brazos, torso)
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local mock = require("./mock")
local V, CF, C3 = roblox.Vector3.new, roblox.CFrame.new, roblox.Color3.fromRGB
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Outfits = req(game.ReplicatedStorage.Shared.Outfits)
local skin, shirt = C3(255, 204, 153), C3(90, 120, 200)
local char = mock.new("Model")
for _, r in { { "Head", skin }, { "UpperTorso", shirt }, { "LowerTorso", shirt }, { "LeftUpperArm", skin }, { "RightUpperArm", skin }, { "LeftLowerArm", skin }, { "RightLowerArm", skin } } do
	local p = mock.new("Part"); p.Name = r[1]; p.Size = V(1, 1, 1); p.CFrame = CF(0, 3, 0); p.Color = r[2]; p.Parent = char
end
local bc = mock.new("BodyColors"); bc.HeadColor3 = skin; bc.LeftArmColor3 = skin; bc.RightArmColor3 = skin; bc.TorsoColor3 = shirt; bc.Parent = char
local function same(a, b) return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.01 end
check(Outfits.Apply(char, "Vampiro"), "vampiro puesto")
check(not same(char.Head.Color, skin) and not same(char.LeftUpperArm.Color, skin), "cabeza pálida y mangas")
check(Outfits.Apply(char, "BlazeRunner"), "cambio a Blaze Runner")
check(same(char.Head.Color, skin) and same(char.LeftUpperArm.Color, skin) and same(bc.HeadColor3, skin), "vuelven la cara y los brazos del avatar")
Outfits.Remove(char)
check(same(char.UpperTorso.Color, shirt) and same(bc.TorsoColor3, shirt), "sin traje: el torso vuelve a su color")
print("CAMBIO DE TRAJE OK")
process.exit(0)
