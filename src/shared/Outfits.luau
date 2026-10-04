-- Trajes de operador: armadura hecha con piezas que se sueldan al personaje R15.
-- Las piezas se escalan con el tamaño de cada parte del cuerpo, así funcionan con cualquier avatar.
local Outfits = {}

local RGB = Color3.fromRGB

Outfits.List = {
	Default = {
		Name = "Tu avatar",
		Rarity = "Común",
		Class = "Sin traje",
	},
	BlazeRunner = {
		Name = "Blaze Runner",
		Rarity = "Legendario",
		Class = "Clase asalto",
		Body = RGB(28, 26, 28),
		Cloth = RGB(200, 30, 30),
		Glow = RGB(255, 120, 20),
		Plate = RGB(70, 70, 76),
		Pieces = { Vest = true, Pouches = true, Backpack = true, Shoulders = true, Belt = true, Knees = true, Boots = true, Gloves = true, Headset = true, Mask = true, Scarf = true },
	},
	NeonRecon = {
		Name = "Neon Recon",
		Rarity = "Legendario",
		Class = "Clase francotirador",
		Body = RGB(22, 22, 28),
		Cloth = RGB(20, 20, 26),
		Glow = RGB(0, 200, 255),
		Plate = RGB(235, 238, 245),
		Pieces = { Vest = true, Pouches = true, Backpack = true, Belt = true, Knees = true, Boots = true, Gloves = true, Headset = true, Visor = true, Scarf = true },
	},
	VoltBruiser = {
		Name = "Volt Bruiser",
		Rarity = "Mítico",
		Class = "Clase pesada",
		Body = RGB(30, 30, 32),
		Cloth = RGB(40, 40, 44),
		Glow = RGB(255, 200, 30),
		Plate = RGB(225, 225, 230),
		Heavy = true,
		Pieces = { Vest = true, Pouches = true, Backpack = true, Shoulders = true, Belt = true, Knees = true, Boots = true, Gloves = true, Headset = true, Gauntlets = true },
	},
	FrostByte = {
		Name = "Frost Byte",
		Rarity = "Épico",
		Class = "Clase reconocimiento",
		Body = RGB(220, 235, 250),
		Cloth = RGB(150, 200, 240),
		Glow = RGB(120, 230, 255),
		Plate = RGB(255, 255, 255),
		Pieces = { Vest = true, Belt = true, Knees = true, Boots = true, Gloves = true, Visor = true, Scarf = true },
	},
	ToxicRogue = {
		Name = "Toxic Rogue",
		Rarity = "Épico",
		Class = "Clase infiltración",
		Body = RGB(30, 40, 30),
		Cloth = RGB(60, 90, 40),
		Glow = RGB(130, 255, 60),
		Plate = RGB(50, 60, 50),
		Pieces = { Vest = true, Pouches = true, Belt = true, Boots = true, Gloves = true, Mask = true, Headset = true },
	},
	GoldenAce = {
		Name = "Golden Ace",
		Rarity = "Mítico",
		Class = "Edición de lujo",
		Body = RGB(25, 22, 18),
		Cloth = RGB(30, 26, 22),
		Glow = RGB(255, 220, 120),
		Plate = RGB(240, 180, 50),
		PlateMaterial = Enum.Material.Foil,
		Pieces = { Vest = true, Pouches = true, Backpack = true, Shoulders = true, Belt = true, Knees = true, Boots = true, Gloves = true, Visor = true, Gauntlets = true },
	},
	-- Halloween: cabeza de calabaza con cara iluminada y capa
	Calabaza = {
		Name = "Cabeza de Calabaza",
		Rarity = "Legendario",
		Class = "Edición Halloween",
		Body = RGB(25, 20, 30),
		Cloth = RGB(60, 30, 80),
		Glow = RGB(255, 170, 40),
		Plate = RGB(255, 130, 20),
		Pieces = { Pumpkin = true, Cape = true, Belt = true, Boots = true, Gloves = true },
	},
}

function Outfits.Get(id)
	return Outfits.List[id] or Outfits.List.Default
end

-- Colores de los brazos en primera persona (manga, guante y puño)
function Outfits.ArmColors(id)
	local o = Outfits.List[id]
	if not o or not o.Body then
		return nil
	end
	return { Sleeve = o.Cloth, Glove = o.Body, Cuff = o.Glow, Plate = o.Plate }
end

---------------------------------------------------------------------------
-- Construcción sobre el personaje
---------------------------------------------------------------------------

local function newPiece(folder, bodyPart, name, offsetScale, offsetAdd, sizeScale, sizeAdd, color, material, rotation)
	local s = bodyPart.Size
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(s.X * sizeScale.X + sizeAdd.X, s.Y * sizeScale.Y + sizeAdd.Y, s.Z * sizeScale.Z + sizeAdd.Z)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local offset = Vector3.new(s.X * offsetScale.X + offsetAdd.X, s.Y * offsetScale.Y + offsetAdd.Y, s.Z * offsetScale.Z + offsetAdd.Z)
	part.CFrame = bodyPart.CFrame * CFrame.new(offset) * (rotation or CFrame.new())
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bodyPart
	weld.Part1 = part
	weld.Parent = part
	part.Parent = folder
	return part
end

local V = Vector3.new
local Z = Vector3.zero

-- Quita el traje actual del personaje
function Outfits.Remove(character)
	local old = character:FindFirstChild("Outfit")
	if old then
		old:Destroy()
	end
end

-- Pone el traje `id` en el personaje (R15). Devuelve true si se aplicó.
function Outfits.Apply(character, id)
	Outfits.Remove(character)
	local o = Outfits.List[id]
	if not o or not o.Pieces then
		return false
	end
	local function get(name)
		return character:FindFirstChild(name)
	end
	local upper, lower, head = get("UpperTorso"), get("LowerTorso"), get("Head")
	if not upper or not lower or not head then
		return false -- solo R15
	end

	-- La ropa clásica taparía los colores del traje
	for _, child in character:GetChildren() do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			child:Destroy()
		end
	end
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors.TorsoColor3 = o.Cloth
		bodyColors.LeftLegColor3 = o.Body
		bodyColors.RightLegColor3 = o.Body
	end
	for _, name in { "UpperTorso", "LowerTorso" } do
		get(name).Color = o.Cloth
	end
	for _, name in { "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg" } do
		local p = get(name)
		if p then
			p.Color = o.Body
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = "Outfit"
	folder:SetAttribute("Id", id)
	folder.Parent = character

	local P = o.Pieces
	local plateMat = o.PlateMaterial or Enum.Material.SmoothPlastic
	local glow = Enum.Material.Neon
	local heavy = o.Heavy and 1.15 or 1

	-- Chaleco (cubre el torso) con placa delantera
	if P.Vest then
		newPiece(folder, upper, "Vest", V(0, -0.02, 0), Z, V(1.06 * heavy, 0.86, 1.18 * heavy), Z, o.Body)
		newPiece(folder, upper, "ChestPlate", V(0, 0.12, -0.6 * heavy), Z, V(0.7, 0.4, 0.12), Z, o.Plate, plateMat)
		newPiece(folder, upper, "ChestGlow", V(0, 0.12, -0.67 * heavy), Z, V(0.4, 0.05, 0.05), Z, o.Glow, glow)
	end
	if P.Pouches then
		for i, x in { -0.3, 0, 0.3 } do
			newPiece(folder, upper, "Pouch" .. i, V(x, -0.25, -0.66 * heavy), Z, V(0.24, 0.32, 0.18), Z, o.Body:Lerp(Color3.new(0, 0, 0), 0.25))
			newPiece(folder, upper, "PouchGlow" .. i, V(x, -0.25, -0.76 * heavy), Z, V(0.04, 0.2, 0.02), Z, o.Glow, glow)
		end
	end
	if P.Backpack then
		newPiece(folder, upper, "Backpack", V(0, -0.05, 0.85 * heavy), Z, V(0.72, 0.78, 0.55), Z, o.Body)
		newPiece(folder, upper, "BackpackPlate", V(0, 0.05, 1.13 * heavy), Z, V(0.42, 0.38, 0.05), Z, o.Plate, plateMat)
		newPiece(folder, upper, "BackpackEmblem", V(0, 0.05, 1.17 * heavy), Z, V(0.14, 0.14, 0.03), Z, o.Glow, glow, CFrame.Angles(0, 0, math.rad(45)))
	end
	-- Cinturón
	if P.Belt then
		newPiece(folder, lower, "Belt", V(0, 0.32, 0), Z, V(1.08, 0.3, 1.12), Z, o.Body:Lerp(Color3.new(0, 0, 0), 0.3))
		newPiece(folder, lower, "Buckle", V(0, 0.32, -0.58), Z, V(0.22, 0.22, 0.06), Z, o.Glow, glow)
	end

	-- Brazos y piernas (izquierda y derecha)
	for _, side in { "Left", "Right" } do
		local upperArm, lowerArm, hand = get(side .. "UpperArm"), get(side .. "LowerArm"), get(side .. "Hand")
		local upperLeg, lowerLeg, foot = get(side .. "UpperLeg"), get(side .. "LowerLeg"), get(side .. "Foot")
		local sx = side == "Left" and -1 or 1
		if P.Shoulders and upperArm then
			newPiece(folder, upperArm, "Shoulder", V(0.05 * sx, 0.3, 0), Z, V(1.35 * heavy, 0.42, 1.3 * heavy), Z, o.Plate, plateMat)
			newPiece(folder, upperArm, "ShoulderGlow", V(0.05 * sx, 0.3, -0.66 * heavy), Z, V(0.8, 0.07, 0.03), Z, o.Glow, glow)
		end
		if P.Gauntlets and lowerArm then
			newPiece(folder, lowerArm, "Gauntlet", V(0, -0.05, 0), Z, V(1.3, 0.7, 1.3), Z, o.Plate, plateMat)
			newPiece(folder, lowerArm, "GauntletGlow", V(0, -0.05, -0.66), Z, V(0.5, 0.08, 0.03), Z, o.Glow, glow)
		end
		if P.Gloves and hand then
			newPiece(folder, hand, "Glove", Z, Z, V(1.15, 1.1, 1.15), Z, o.Body)
		end
		if P.Knees and lowerLeg then
			newPiece(folder, lowerLeg, "KneePad", V(0, 0.32, -0.55), Z, V(0.95, 0.32, 0.3), Z, o.Plate, plateMat)
			newPiece(folder, lowerLeg, "KneeGlow", V(0, 0.32, -0.72), Z, V(0.3, 0.1, 0.02), Z, o.Glow, glow)
		end
		if P.Boots and foot then
			newPiece(folder, foot, "Boot", V(0, 0.08, 0), Z, V(1.14, 1.15, 1.12), Z, o.Body)
			newPiece(folder, foot, "Sole", V(0, -0.42, 0), Z, V(1.17, 0.32, 1.15), Z, Color3.fromRGB(245, 245, 248))
			newPiece(folder, foot, "BootGlow", V(0, -0.2, 0), Z, V(1.18, 0.1, 1.16), Z, o.Glow, glow)
		end
		_ = upperLeg
	end

	-- Cabeza
	if P.Headset then
		for _, sx in { -1, 1 } do
			newPiece(folder, head, "EarCup", V(0.55 * sx, 0, 0), Z, V(0.18, 0.45, 0.45), Z, o.Body)
			newPiece(folder, head, "EarGlow", V(0.65 * sx, 0, 0), Z, V(0.03, 0.25, 0.25), Z, o.Glow, glow)
		end
		newPiece(folder, head, "Headband", V(0, 0.55, 0), Z, V(1.15, 0.1, 0.18), Z, o.Body)
		newPiece(folder, head, "Mic", V(-0.42, -0.25, -0.35), Z, V(0.06, 0.06, 0.45), Z, o.Body, nil, CFrame.Angles(0, math.rad(-30), 0))
	end
	if P.Visor then
		local visor = newPiece(folder, head, "Visor", V(0, 0.1, -0.52), Z, V(0.98, 0.24, 0.08), Z, o.Glow, glow)
		visor.Transparency = 0.15
		newPiece(folder, head, "VisorFrame", V(0, 0.1, -0.5), Z, V(1.04, 0.3, 0.06), Z, o.Body)
	end
	if P.Mask then
		newPiece(folder, head, "Mask", V(0, -0.22, -0.5), Z, V(0.92, 0.36, 0.1), Z, o.Body)
		for i, x in { -0.18, 0, 0.18 } do
			newPiece(folder, head, "MaskGlow" .. i, V(x, -0.2, -0.56), Z, V(0.08, 0.05, 0.02), Z, o.Glow, glow)
		end
	end
	if P.Pumpkin then
		-- Calabaza que envuelve la cabeza (malla de esfera: una Ball no se puede achatar)
		local pumpkin = newPiece(folder, head, "PumpkinHead", V(0, 0.05, 0), Z, V(1.55, 1.35, 1.55), Z, o.Plate)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = pumpkin
		newPiece(folder, head, "PumpkinStem", V(0, 0.75, 0), Z, V(0.14, 0.3, 0.14), Z, RGB(80, 120, 40))
		for _, sx in { -1, 1 } do
			newPiece(folder, head, "PumpkinEye", V(0.24 * sx, 0.15, -0.74), Z, V(0.2, 0.18, 0.06), Z, o.Glow, glow, CFrame.Angles(0, 0, math.rad(20 * sx)))
		end
		newPiece(folder, head, "PumpkinMouth", V(0, -0.2, -0.74), Z, V(0.55, 0.12, 0.06), Z, o.Glow, glow)
	end
	if P.Cape then
		newPiece(folder, upper, "Cape", V(0, -0.35, 0.62), Z, V(1.1, 1.7, 0.06), Z, o.Cloth, Enum.Material.Fabric, CFrame.Angles(math.rad(8), 0, 0))
		newPiece(folder, upper, "CapeCollar", V(0, 0.48, 0.45), Z, V(1.0, 0.18, 0.25), Z, RGB(150, 30, 40), Enum.Material.Fabric)
	end
	if P.Scarf then
		local scarfColor = o.Cloth == o.Body and o.Glow or o.Cloth
		newPiece(folder, upper, "ScarfRing", V(0, 0.46, 0), Z, V(0.78, 0.2, 1.28), Z, scarfColor, Enum.Material.Fabric)
		newPiece(folder, upper, "ScarfTail", V(0.25, 0.25, 0.75), Z, V(0.18, 0.08, 1.1), Z, scarfColor, Enum.Material.Fabric, CFrame.Angles(math.rad(-25), math.rad(20), 0))
	end
	return true
end

return Outfits
