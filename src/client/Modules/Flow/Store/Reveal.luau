-- Escena de compra (1-2 s), solo cuando el SERVIDOR confirma la entrega (PurchaseGranted):
--   COMPRA COMPLETADA → aparece el objeto → brillo → nombre → rareza → EQUIPAR AHORA
-- Al pulsar EQUIPAR AHORA el botón pasa a EQUIPADO ✓ con un pulso y su sonido. Legendario o más:
-- desenfoque, el objeto entra girando y sale el sello LEGENDARIO (sin pasar de 2 s). Packs: los
-- objetos entran uno tras otro y EQUIPAR TODO. Va en su propia capa: se ve también en partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Catalog = require(Shared.Economy.CosmeticCatalog)
local WeaponModels = require(Shared.WeaponModels)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local UISound = require(Flow.UISound)
local ClientState = require(Flow.Parent.ClientState)
local ItemArt = require(script.Parent.ItemArt)
local StoreData = require(script.Parent.StoreData)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)
local player = Players.LocalPlayer

local Reveal = {}
Reveal.OnOpenPass = nil :: (() -> ())? -- (lo pone la pantalla del pase: botón VER PASE)

local gui, root, current
local queue = {}

local function tween(inst, time, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function pop(frame, delay, from)
	local scale = frame:FindFirstChild("RevealScale") or C.new("UIScale", { Name = "RevealScale", Parent = frame })
	scale.Scale = from or 0.5
	frame.Visible = false
	task.delay(delay or 0, function()
		if frame.Parent then
			frame.Visible = true
			tween(scale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end)
end

-- Lo que trae el aviso del servidor, como fichas del catálogo
local function itemsOf(payload)
	local list = {}
	for _, entry in payload.Items or {} do
		local item = Catalog.Item(entry.Kind, entry.Id)
		if item then
			table.insert(list, item)
		end
	end
	return list
end

local function best(items)
	local top
	for _, item in items do
		if not top or Catalog.RarityRank(item.Rarity) > Catalog.RarityRank(top.Rarity) then
			top = item
		end
	end
	return top
end

local function close()
	if current then
		current:Destroy()
		current = nil
	end
	local blur = Lighting:FindFirstChild("RevealBlur")
	if blur then
		tween(blur, 0.2, { Size = 0 }).Completed:Once(function()
			blur:Destroy()
		end)
	end
	ClientState.RevealOpen = false
	if #queue > 0 then
		Reveal.Show(table.remove(queue, 1))
	end
end
Reveal.Close = close

-- Arma girando (escena de legendario)
local function spinningWeapon(parent, skinId)
	local vp, camera = ItemArt.Viewport(parent, { Name = "Spin" })
	local data = ClientState.Data
	local ok, model = pcall(WeaponModels.Build, data and data.Primary or "ARX27", skinId, false, nil, 1)
	if not ok or not model then
		vp:Destroy()
		return nil
	end
	model.Parent = vp
	local cf, size = model:GetBoundingBox()
	local dist = math.max(size.X, size.Y, size.Z) * 1.5
	local start = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not vp.Parent then
			connection:Disconnect()
			return
		end
		local t = os.clock() - start
		-- entra deprisa y se queda girando despacio
		local yaw = t < 0.6 and (1 - (1 - t / 0.6) ^ 3) * math.pi * 2 or math.pi * 2 + (t - 0.6) * 0.6
		local offset = CFrame.Angles(0, yaw - 0.6, 0) * Vector3.new(0, dist * 0.18, -dist)
		camera.CFrame = CFrame.lookAt(cf.Position + offset, cf.Position)
	end)
	return vp
end

function Reveal.Show(payload)
	if type(payload) ~= "table" then
		return
	end
	if current then
		table.insert(queue, payload)
		return
	end
	if not root then
		Reveal.Init()
	end
	ClientState.RevealOpen = true
	local items = itemsOf(payload)
	local bonus = payload.Bonus and Catalog.Item(payload.Bonus.Kind, payload.Bonus.Id)
	-- (el bonus va aparte, no entre lo comprado)
	if bonus then
		for i, item in items do
			if item.Key == bonus.Key then
				table.remove(items, i)
				break
			end
		end
	end
	local top = best(items)
	local legendary = (top and Catalog.IsPremiumRarity(top.Rarity)) or payload.Premium == true
	local phone = C.Breakpoint() == "PHONE"

	local frame = C.new("Frame", { Name = "Reveal", BackgroundColor3 = Colors.Bg, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Active = true, Parent = root })
	current = frame
	tween(frame, 0.15, { BackgroundTransparency = legendary and 0.2 or 0.3 })
	if legendary then
		local blur = Lighting:FindFirstChild("RevealBlur") or C.new("BlurEffect", { Name = "RevealBlur", Size = 0, Parent = Lighting })
		tween(blur, 0.25, { Size = 20 })
	end
	-- Destello de compra
	local flash = C.new("Frame", { Name = "Flash", BackgroundColor3 = legendary and (top and ItemArt.RarityColor(top.Rarity) or Colors.Yellow) or Colors.Yellow, BackgroundTransparency = 0.55, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 9, Parent = frame })
	tween(flash, 0.35, { BackgroundTransparency = 1 })
	UISound.Play(legendary and "Victory" or "Purchase")

	-- Título
	local title = C.text({ Name = "Title", Text = payload.Type == "CoinItem" and "¡COMPRADO!" or "COMPRA COMPLETADA", Role = "TitleItalic", TextSize = phone and 30 or 40, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Stroke = 2, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, phone and 18 or 40), Size = UDim2.new(1, -40, 0, phone and 36 or 48), Parent = frame })
	pop(title, 0, 0.8)
	if payload.Title then
		local sub = C.text({ Name = "Sub", Text = C.upper(payload.Title), Role = "Title", TextSize = 18, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, phone and 54 or 88), Size = UDim2.new(1, -40, 0, 22), Parent = frame })
		pop(sub, 0.1, 0.9)
	end

	-- Objeto(s)
	local center = C.new("Frame", { Name = "Center", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, phone and 0.4 or 0.46), Size = UDim2.fromOffset(phone and 300 or 420, phone and 140 or 250), Parent = frame })
	-- Brillo detrás (color de la rareza), girando despacio
	local glowColor = top and ItemArt.RarityColor(top.Rarity) or Colors.Yellow
	local glow = C.new("Frame", { Name = "Glow", BackgroundColor3 = glowColor, BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.1, 1.1), Rotation = 45, Parent = center }, {
		C.corner(400),
		C.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		C.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	task.delay(0.2, function()
		if glow.Parent then
			tween(glow, 0.3, { BackgroundTransparency = 0.6 })
			tween(glow, 6, { Rotation = 405 }, Enum.EasingStyle.Linear)
		end
	end)
	local single = #items == 1 and items[1] or nil
	local nameText, rarityText
	if single then
		local art
		if legendary and single.Kind == "Skin" then
			art = spinningWeapon(center, single.Id)
		end
		art = art or ItemArt.Thumb(center, single, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.92) })
		if legendary then
			-- entra desde la derecha
			art.Position = UDim2.fromScale(1.4, 0.5)
			art.AnchorPoint = Vector2.new(0.5, 0.5)
			task.delay(0.15, function()
				if art.Parent then
					tween(art, 0.45, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quint)
				end
			end)
		else
			pop(art, 0.2, 0.55)
		end
		nameText = C.upper(single.Name)
		rarityText = C.upper(single.Rarity)
	elseif #items > 1 then
		local row = C.new("Frame", { Name = "Items", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.4, 0.7), Parent = center }, {
			C.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center),
		})
		local cell = phone and 74 or 104
		for i, item in items do
			if i > 6 then
				break
			end
			local thumb = ItemArt.Thumb(row, item, { Size = UDim2.fromOffset(cell, cell), LayoutOrder = i })
			pop(thumb, 0.15 + i * 0.1, 0.4)
		end
		nameText = payload.Title and C.upper(payload.Title) or (#items .. " OBJETOS")
		rarityText = top and C.upper(top.Rarity) or ""
	elseif payload.Pass then
		local badge = C.text({ Text = "🎖️", TextSize = 120, AlignX = Enum.TextXAlignment.Center, Scaled = true, Size = UDim2.fromScale(1, 1), Parent = center })
		pop(badge, 0.2, 0.5)
		nameText = payload.Title or "PASE"
		rarityText = ""
	else
		local coin = C.text({ Text = "🪙", TextSize = 120, AlignX = Enum.TextXAlignment.Center, Scaled = true, Size = UDim2.fromScale(1, 0.8), Parent = center })
		pop(coin, 0.2, 0.5)
		nameText = "+" .. tostring(payload.Coins or 0) .. " MONEDAS"
		rarityText = ""
	end
	local nameLabel = C.text({ Name = "ItemName", Text = nameText or "", Role = "TitleItalic", TextSize = phone and 30 or 44, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Stroke = 2, Scaled = true, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, phone and 0.6 or 0.68, 0), Size = UDim2.new(0.8, 0, 0, phone and 32 or 50), Parent = frame })
	pop(nameLabel, 0.5, 0.85)
	if rarityText ~= "" then
		local stamp = C.new("Frame", { Name = "RarityStamp", BackgroundColor3 = glowColor, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, phone and 0.6 or 0.68, phone and 34 or 56), Size = UDim2.fromOffset(legendary and (phone and 180 or 220) or 150, legendary and (phone and 28 or 34) or 26), Rotation = legendary and -3 or 0, Parent = frame }, { C.corner(3) })
		C.text({ Text = rarityText, Role = "TitleItalic", TextSize = legendary and 24 or 16, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = stamp })
		pop(stamp, 0.7, legendary and 1.8 or 0.6)
		if legendary then
			task.delay(0.7, function()
				UISound.Play("LevelUp", 1.2)
			end)
		end
	end
	-- Extras: monedas devueltas y bonus de primera compra
	local extras = {}
	if (payload.Compensation or 0) > 0 then
		table.insert(extras, "+" .. payload.Compensation .. " 🪙 por lo que ya tenías")
	elseif #items > 0 and (payload.Coins or 0) > 0 then
		table.insert(extras, "+" .. payload.Coins .. " 🪙")
	end
	if bonus then
		table.insert(extras, "🎁 Bonus de primera compra: tarjeta " .. C.upper(bonus.Name))
	end
	if #extras > 0 then
		local extra = C.text({ Name = "Extras", Text = table.concat(extras, "   ·   "), Role = "BodyBold", TextSize = 15, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, phone and 0.6 or 0.68, phone and 66 or 96), Size = UDim2.new(1, -40, 0, 20), Parent = frame })
		pop(extra, 0.8, 0.9)
	end

	-- Botones: EQUIPAR AHORA (o EQUIPAR TODO) y CONTINUAR
	local buttons = C.new("Frame", { Name = "Buttons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, phone and -14 or -36), Size = UDim2.fromOffset(phone and 460 or 560, phone and 48 or 56), Parent = frame }, {
		C.list(12, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center),
	})
	local equippable = {}
	for _, item in items do
		if Catalog.Equippable(item.Kind, item.Id) and item.Kind ~= "Title" then
			table.insert(equippable, item)
		end
	end
	local data = ClientState.Data
	local allEquipped = #equippable > 0
	for _, item in equippable do
		allEquipped = allEquipped and data ~= nil and Catalog.IsEquipped(data, item.Kind, item.Id)
	end
	if payload.Equipped then
		allEquipped = true
	end
	local function equippedLook(button)
		local label = button:FindFirstChild("Label", true)
		if label then
			label.Text = "EQUIPADO ✓"
			label.TextColor3 = Colors.White
		end
		button.BackgroundColor3 = Colors.Green
		local gradient = button:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Enabled = false
		end
	end
	if #equippable > 0 then
		local equip
		equip = C.button({ Name = "Equip", Text = #equippable > 1 and "EQUIPAR TODO" or "EQUIPAR AHORA", Style = "Primary", TextSize = phone and 18 or 22, Size = UDim2.fromOffset(phone and 220 or 270, phone and 48 or 56), Order = 1, Parent = buttons, Sound = "Equip", OnClick = function()
			if equip:GetAttribute("Done") then
				return
			end
			equip:SetAttribute("Done", true)
			for _, item in equippable do
				StoreData.Equip(item.Kind, item.Id)
			end
			equippedLook(equip)
			local scale = equip:FindFirstChild("FeelScale")
			if scale then
				scale.Scale = 1.15
				tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end })
		if allEquipped then
			equip:SetAttribute("Done", true)
			equippedLook(equip)
		end
		pop(equip, 0.9, 0.7)
	end
	if payload.Pass and Reveal.OnOpenPass then
		local see = C.button({ Name = "SeePass", Text = "VER PASE", Icon = "🎖️", Style = "Primary", TextSize = phone and 18 or 22, Size = UDim2.fromOffset(phone and 200 or 240, phone and 48 or 56), Order = 1, Parent = buttons, OnClick = function()
			close()
			if Reveal.OnOpenPass then
				Reveal.OnOpenPass()
			end
		end })
		pop(see, 0.9, 0.7)
	end
	local continue = C.button({ Name = "Continue", Text = "CONTINUAR", Style = "Ghost", TextSize = phone and 16 or 18, Size = UDim2.fromOffset(phone and 170 or 210, phone and 48 or 56), Order = 2, Parent = buttons, Sound = "Back", OnClick = close })
	pop(continue, 0.95, 0.7)
	return frame
end

function Reveal.Init()
	if gui then
		return
	end
	gui = C.new("ScreenGui", { Name = "PurchaseReveal", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 45, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	root = C.root(gui, "RevealRoot")
	Remotes.PurchaseGranted.OnClientEvent:Connect(function(payload)
		Reveal.Show(payload)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if current and not processed and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then
			close()
		end
	end)
end

return Reveal
