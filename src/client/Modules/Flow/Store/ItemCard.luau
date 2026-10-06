-- Tarjeta de un objeto en la tienda: imagen grande, NUEVO, rareza, nombre, precio a la vista
-- (monedas o Robux, sin letra pequeña) y dos botones: PREVISUALIZAR y COMPRAR. Si ya es tuyo dice
-- TUYO / EQUIPADO y el botón es EQUIPAR (nunca se ofrece otra vez algo que ya tienes).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared").Economy.CosmeticCatalog)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local ItemArt = require(script.Parent.ItemArt)
local StoreData = require(script.Parent.StoreData)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)

local ItemCard = {}

ItemCard.Size = { DESKTOP = Vector2.new(214, 286), PHONE = Vector2.new(168, 232) }

function ItemCard.PriceText(item)
	if item.Robux then
		local entry = StoreData.Robux({ ProductId = item.ProductId, Robux = item.Robux })
		return "R$ " .. tostring(entry)
	elseif item.Coins then
		return "🪙 " .. tostring(item.Coins)
	end
	return ""
end

-- callbacks = { OnPreview(item), OnBuy(item), OnEquip(item) }
function ItemCard.new(parent, item, callbacks, opts)
	opts = opts or {}
	local phone = opts.Phone == true
	local size = phone and ItemCard.Size.PHONE or ItemCard.Size.DESKTOP
	local card = C.panel({ Name = "Item_" .. item.Key, Size = UDim2.fromOffset(size.X, size.Y), Order = opts.Order, Parent = parent }, {
		Alpha = 0.08,
		StrokeColor = ItemArt.RarityColor(item.Rarity),
		StrokeAlpha = 0.55,
	})
	local thumbHeight = math.floor(size.Y * 0.52)
	local thumb = ItemArt.Thumb(card, item, { Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, thumbHeight) })
	-- (tocar la imagen también previsualiza)
	local look = C.new("TextButton", { Name = "PreviewArea", Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, thumbHeight), ZIndex = 4, Parent = card })
	look.Activated:Connect(function()
		callbacks.OnPreview(item)
	end)
	local _ = thumb
	-- Etiquetas
	local tags = C.new("Frame", { Name = "Tags", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 20), ZIndex = 5, Parent = card }, {
		C.list(4, Enum.FillDirection.Horizontal),
	})
	local function tag(text, color, textColor, order)
		local t = C.new("Frame", { Name = "Tag", BackgroundColor3 = color, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), LayoutOrder = order, ZIndex = 5, Parent = tags }, { C.corner(3), C.padding(0, 6, 0, 6) })
		C.text({ Text = text, Role = "Title", TextSize = 12, Color = textColor or Colors.White, AlignX = Enum.TextXAlignment.Center, Size = UDim2.new(0, 0, 1, 0), ZIndex = 6, Parent = t }).AutomaticSize = Enum.AutomaticSize.X
		return t
	end
	if StoreData.IsNew(item) then
		tag("NUEVO", Colors.Red, Colors.White, 1)
	end
	if item.OnSale and item.BaseCoins and item.Coins and item.Coins < item.BaseCoins then
		-- (descuento real: precio de siempre tachado al lado)
		tag("-" .. math.floor((1 - item.Coins / item.BaseCoins) * 100 + 0.5) .. "% HOY", Colors.Yellow, DARK, 2)
	end
	if item.Collection then
		tag(item.Collection, Color3.fromRGB(30, 33, 40), Colors.YellowText, 3)
	end
	-- Rareza (barra y texto) y nombre
	local y = thumbHeight + 10
	C.new("Frame", { Name = "RarityBar", BackgroundColor3 = ItemArt.RarityColor(item.Rarity), BorderSizePixel = 0, Position = UDim2.fromOffset(6, y - 3), Size = UDim2.new(1, -12, 0, 3), ZIndex = 3, Parent = card })
	C.text({ Name = "Rarity", Text = C.upper(item.Rarity) .. "  ·  " .. (item.Label or ""), Role = "Title", TextSize = 12, Color = ItemArt.RarityColor(item.Rarity), Scaled = true, Position = UDim2.fromOffset(10, y + 2), Size = UDim2.new(1, -20, 0, 16), Parent = card })
	C.text({ Name = "ItemName", Text = C.upper(item.Name), Role = "TitleItalic", TextSize = phone and 18 or 21, Color = Colors.White, Scaled = true, Position = UDim2.fromOffset(10, y + 18), Size = UDim2.new(1, -20, 0, phone and 22 or 26), Parent = card })
	-- Precio (siempre visible) con el de siempre tachado si hay descuento
	local priceRow = C.new("Frame", { Name = "PriceRow", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, y + (phone and 42 or 46)), Size = UDim2.new(1, -20, 0, 20), Parent = card })
	local price = C.text({ Name = "Price", Text = ItemCard.PriceText(item), Role = "Number", TextSize = 18, Color = item.Robux and Colors.Green or Colors.YellowText, Size = UDim2.new(0.6, 0, 1, 0), Parent = priceRow })
	if item.OnSale and item.BaseCoins and item.Coins and item.Coins < item.BaseCoins then
		C.text({ Name = "OldPrice", Text = "<s>" .. item.BaseCoins .. "</s>", Rich = true, Role = "Number", TextSize = 14, Color = Colors.TextFaint, AlignX = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.6, 0), Size = UDim2.new(0.4, 0, 1, 0), Parent = priceRow })
	end
	-- Botones
	local buttonY = size.Y - (phone and 46 or 50)
	local preview = C.button({ Name = "Preview", Text = "", Icon = "👁", Style = "Ghost", TextSize = 18, Position = UDim2.fromOffset(8, buttonY), Size = UDim2.fromOffset(phone and 44 or 50, phone and 38 or 42), Parent = card, OnClick = function()
		callbacks.OnPreview(item)
	end })
	local action = C.button({ Name = "Action", Text = "COMPRAR", Style = "Primary", TextSize = phone and 15 or 17, Position = UDim2.fromOffset((phone and 44 or 50) + 14, buttonY), Size = UDim2.new(1, -((phone and 44 or 50) + 22), 0, phone and 38 or 42), Parent = card, Sound = "Click", OnClick = function()
		local state = StoreData.State(item)
		if state == "Buy" then
			callbacks.OnBuy(item)
		elseif state == "Owned" then
			callbacks.OnEquip(item)
		end
	end })
	local actionLabel = action:FindFirstChild("Label", true)
	local api = { Frame = card, Item = item, Action = action, Preview = preview }
	function api.Refresh()
		local state = StoreData.State(item)
		price.Text = (state == "Owned" or state == "Equipped") and "" or ItemCard.PriceText(item)
		local yellow = state == "Buy" or state == "Owned"
		local text = ({
			Buy = "COMPRAR",
			Owned = "EQUIPAR",
			Equipped = "EQUIPADO ✓",
			Soon = "PRÓXIMAMENTE",
			Pass = "PASE DE BATALLA",
			Event = "EVENTO",
			Locked = "NO DISPONIBLE",
		})[state]
		if state == "Owned" and not Catalog.Equippable(item.Kind, item.Id) then
			text, yellow = "TUYO", false
		end
		if StoreData.Pending and StoreData.Pending.Key == item.Key then
			text, yellow = "PROCESANDO…", false
		end
		actionLabel.Text = text
		action.BackgroundColor3 = yellow and Colors.Yellow or Colors.PanelLight
		action.BackgroundTransparency = yellow and 0 or 0.25
		actionLabel.TextColor3 = yellow and DARK or (state == "Equipped" and Colors.Green or Colors.TextDim)
		local gradient = action:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Enabled = yellow
		end
	end
	api.Refresh()
	return api
end

return ItemCard
