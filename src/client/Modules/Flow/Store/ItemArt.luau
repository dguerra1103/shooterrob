-- Imágenes de los cosméticos para la tienda, el pase y la escena de compra: el arma de verdad con su
-- skin (WeaponIcon), un maniquí con el traje, el colgante en 3D, la tarjeta de jugador dibujada, el
-- grafiti y, para lo que no tiene modelo (efectos, poses, intros, títulos), su icono sobre el color
-- de su rareza. Nada de imágenes subidas: todo se dibuja con piezas.
--   ItemArt.Thumb(parent, item, props)        -- miniatura de cualquier objeto (item = Catalog.Item)
--   ItemArt.Card(parent, cardId, props, name) -- tarjeta de jugador (con tu nombre si se pasa)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Outfits = require(Shared.Outfits)
local Charms = require(Shared.Charms)
local Sprays = require(Shared.Sprays)
local Titles = require(Shared.Titles)
local PlayerCards = require(Shared.PlayerCards)
local Catalog = require(Shared.Economy.CosmeticCatalog)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local WeaponIcon = require(Flow.Parent.WeaponIcon)

local Colors = Theme.Colors
local player = Players.LocalPlayer

local ItemArt = {}

function ItemArt.RarityColor(rarity)
	return Catalog.RarityColors[rarity] or Colors.TextDim
end

local function apply(inst, props)
	for key, value in props or {} do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

-- Fondo de una miniatura: degradado oscuro con el color de la rareza abajo
function ItemArt.Backdrop(parent, rarity, props)
	local color = ItemArt.RarityColor(rarity)
	local frame = C.new("Frame", { Name = "Art", BackgroundColor3 = color, BorderSizePixel = 0, ClipsDescendants = true }, {
		C.corner(4),
		C.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(22, 24, 30), color),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.35) }),
		}),
	})
	apply(frame, props)
	frame.Parent = parent
	return frame
end

-- Maniquí sencillo con un traje (miniaturas: no copia tu personaje para cada tarjeta)
function ItemArt.Mannequin(outfitId)
	local model = Instance.new("Model")
	model.Name = "Mannequin"
	local skin = Color3.fromRGB(230, 190, 150)
	local legs = Color3.fromRGB(55, 58, 66)
	local torso = Color3.fromRGB(70, 74, 86)
	for _, spec in {
		{ "Head", Vector3.new(1.2, 1.2, 1.2), 0, 5.2, skin },
		{ "UpperTorso", Vector3.new(2, 1.6, 1), 0, 3.8, torso },
		{ "LowerTorso", Vector3.new(2, 0.4, 1), 0, 2.8, torso },
		{ "LeftUpperArm", Vector3.new(1, 1.2, 1), -1.5, 4.0, skin },
		{ "RightUpperArm", Vector3.new(1, 1.2, 1), 1.5, 4.0, skin },
		{ "LeftLowerArm", Vector3.new(1, 1.1, 1), -1.5, 2.85, skin },
		{ "RightLowerArm", Vector3.new(1, 1.1, 1), 1.5, 2.85, skin },
		{ "LeftHand", Vector3.new(1, 0.3, 1), -1.5, 2.15, skin },
		{ "RightHand", Vector3.new(1, 0.3, 1), 1.5, 2.15, skin },
		{ "LeftUpperLeg", Vector3.new(1, 1.2, 1), -0.5, 2.0, legs },
		{ "RightUpperLeg", Vector3.new(1, 1.2, 1), 0.5, 2.0, legs },
		{ "LeftLowerLeg", Vector3.new(1, 1.1, 1), -0.5, 0.85, legs },
		{ "RightLowerLeg", Vector3.new(1, 1.1, 1), 0.5, 0.85, legs },
		{ "LeftFoot", Vector3.new(1, 0.3, 1), -0.5, 0.15, legs },
		{ "RightFoot", Vector3.new(1, 0.3, 1), 0.5, 0.15, legs },
	} do
		local p = Instance.new("Part")
		p.Name = spec[1]
		p.Size = spec[2]
		p.CFrame = CFrame.new(spec[3], spec[4], 0)
		p.Color = spec[5]
		p.Anchored = true
		p.Parent = model
	end
	if outfitId and outfitId ~= "Default" then
		pcall(Outfits.Apply, model, outfitId)
	end
	return model
end

local function viewport(parent, props)
	local vp = C.new("ViewportFrame", {
		Name = "Viewport",
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 152, 168),
		LightColor = Color3.fromRGB(255, 240, 220),
		LightDirection = Vector3.new(-0.8, -1.2, 0.9),
		Size = UDim2.fromScale(1, 1),
	})
	apply(vp, props)
	vp.Parent = parent
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.Parent = vp
	vp.CurrentCamera = camera
	return vp, camera
end
ItemArt.Viewport = viewport

function ItemArt.Operator(parent, outfitId, props)
	local vp, camera = viewport(parent, props)
	local model = ItemArt.Mannequin(outfitId)
	model.Parent = vp
	camera.CFrame = CFrame.lookAt(Vector3.new(4.5, 4.4, -11), Vector3.new(0, 3, 0))
	return vp
end

function ItemArt.Charm(parent, charmId, props)
	local vp, camera = viewport(parent, props)
	local model = Instance.new("Model")
	for _, piece in Charms.Build(charmId, CFrame.new(0, 0, 0)) do
		piece.Anchored = true
		piece.Parent = model
	end
	model.Parent = vp
	camera.FieldOfView = 24
	camera.CFrame = CFrame.lookAt(Vector3.new(0.35, -0.1, -1.1), Vector3.new(0, -0.18, 0))
	return vp
end

function ItemArt.Weapon(parent, weaponName, skinId, props)
	local size = props and props.Size
	local aspect = 2
	if typeof(size) == "UDim2" and size.Y.Offset > 0 and size.X.Offset > 0 then
		aspect = size.X.Offset / size.Y.Offset
	end
	local ok, icon = pcall(WeaponIcon.Create, weaponName or "ARX27", skinId, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, "angled", aspect)
	if ok and icon then
		apply(icon, props)
		icon.Parent = parent
		return icon
	end
	return nil
end

-- Tarjeta de jugador: fondo en degradado, borde, emblema y (opcional) tu nombre y nivel
function ItemArt.Card(parent, cardId, props, name, sub)
	local def = PlayerCards.Get(cardId)
	local frame = C.new("Frame", { Name = "PlayerCardArt", BackgroundColor3 = def.Top, BorderSizePixel = 0, ClipsDescendants = true }, {
		C.corner(4),
		C.stroke(def.Border, 2, 0.05),
		C.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(def.Top, def.Bottom) }),
	})
	apply(frame, props)
	frame.Parent = parent
	-- Franjas diagonales muy suaves (textura)
	for i = 0, 3 do
		C.new("Frame", { Name = "Stripe", BackgroundColor3 = def.Border, BackgroundTransparency = 0.88, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.55 + i * 0.12, 0.5), Size = UDim2.new(0, 10, 2, 0), Rotation = 25, Parent = frame })
	end
	C.text({ Name = "Emblem", Text = def.Emblem or "", Role = "Title", TextSize = 34, Color = def.Border, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.4, 0, 0.8, 0), Scaled = true, Parent = frame })
	if name then
		C.text({ Name = "CardName", Text = C.upper(name), Role = "TitleItalic", TextSize = 22, Color = Colors.White, Scaled = true, Stroke = 1, Position = UDim2.new(0, 10, 0.12, 0), Size = UDim2.new(0.72, -10, 0.46, 0), Parent = frame })
		C.text({ Name = "CardSub", Text = sub or "", Role = "Title", TextSize = 13, Color = def.Border, Scaled = true, Position = UDim2.new(0, 10, 0.6, 0), Size = UDim2.new(0.72, -10, 0.3, 0), Parent = frame })
	end
	return frame
end

function ItemArt.Spray(parent, sprayId, props)
	local def = Sprays.List[sprayId] or Sprays.List.Default
	local frame = C.new("Frame", { Name = "SprayArt", BackgroundColor3 = def.Bg or Colors.Panel, BorderSizePixel = 0 }, { C.corner(6) })
	apply(frame, props)
	frame.Parent = parent
	C.text({ Text = def.Icon or "🎨", TextSize = 48, AlignX = Enum.TextXAlignment.Center, Scaled = true, Size = UDim2.fromScale(1, def.Caption and 0.68 or 0.9), Position = UDim2.fromScale(0, 0.05), Parent = frame })
	if def.Caption then
		C.text({ Text = def.Caption, Role = "TitleItalic", TextSize = 22, Color = def.Color or Colors.White, AlignX = Enum.TextXAlignment.Center, Scaled = true, Stroke = 1, Position = UDim2.fromScale(0.05, 0.7), Size = UDim2.fromScale(0.9, 0.26), Parent = frame })
	end
	return frame
end

-- Icono grande sobre la rareza (efectos, poses, intros, títulos)
function ItemArt.Icon(parent, item, props)
	local frame = ItemArt.Backdrop(parent, item.Rarity, props)
	C.text({ Name = "Glyph", Text = item.Icon or "★", TextSize = 64, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromScale(0.2, 0.1), Size = UDim2.fromScale(0.6, 0.62), Parent = frame })
	C.text({ Name = "KindLabel", Text = item.Label or "", Role = "Title", TextSize = 13, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromScale(0.05, 0.76), Size = UDim2.fromScale(0.9, 0.16), Parent = frame })
	return frame
end

-- Miniatura de cualquier objeto
function ItemArt.Thumb(parent, item, props)
	local holder = ItemArt.Backdrop(parent, item.Rarity, props)
	local fill = { Size = UDim2.fromScale(1, 1), Position = UDim2.new(), Parent = holder }
	local kind = item.Kind
	if kind == "Skin" then
		local data = require(Flow.Parent.ClientState).Data
		ItemArt.Weapon(holder, data and data.Primary or "ARX27", item.Id, { Size = UDim2.fromScale(0.94, 0.9), Position = UDim2.fromScale(0.03, 0.05), Parent = holder })
	elseif kind == "Outfit" then
		ItemArt.Operator(holder, item.Id, fill)
	elseif kind == "Charm" then
		ItemArt.Charm(holder, item.Id, fill)
	elseif kind == "Card" then
		ItemArt.Card(holder, item.Id, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.5) }, player and player.DisplayName or "", "NV. 1")
	elseif kind == "Spray" then
		ItemArt.Spray(holder, item.Id, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.86) })
	elseif kind == "Title" then
		local title = Titles.Get(item.Id)
		C.text({ Text = C.upper(title.Name), Role = "TitleItalic", TextSize = 26, Color = title.Color or Colors.White, AlignX = Enum.TextXAlignment.Center, Scaled = true, Stroke = 1, Position = UDim2.fromScale(0.06, 0.3), Size = UDim2.fromScale(0.88, 0.4), Parent = holder })
	else
		holder:Destroy()
		return ItemArt.Icon(parent, item, props)
	end
	return holder
end

return ItemArt
