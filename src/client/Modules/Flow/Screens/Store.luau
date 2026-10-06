-- TIENDA: DESTACADO (evento, pack de la semana, pack de inicio y tienda diaria con su reloj real),
-- ARMAS, OPERADORES, CHARMS, EFECTOS, POSES, PACKS, PASE y MONEDAS. Cada objeto con su imagen
-- grande, rareza, precio a la vista, PREVISUALIZAR (3D) y COMPRAR. Lo que ya tienes sale como TUYO /
-- EQUIPADO, nunca como nuevo. Sin ventanas que salten, sin relojes falsos, sin azar.
-- Robux: ventana nativa de Roblox. Monedas: confirmación propia. Lo entrega siempre el servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Shop = require(Shared.Shop)
local Catalog = require(Shared.Economy.CosmeticCatalog)
local Products = require(Shared.Economy.Products)
local StoreRotation = require(Shared.Economy.StoreRotation)
local MonetizationConfig = require(Shared.Economy.MonetizationConfig)

local Modules = script.Parent.Parent.Parent
local ClientState = require(Modules.ClientState)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local StoreFolder = Flow.Store
local StoreData = require(StoreFolder.StoreData)
local ItemArt = require(StoreFolder.ItemArt)
local ItemCard = require(StoreFolder.ItemCard)
local Inspect = require(StoreFolder.Inspect)
local Confirm = require(StoreFolder.Confirm)
local Reveal = require(StoreFolder.Reveal)

local player = Players.LocalPlayer
local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)

local Store = {}

local flow, rootFrame, screen, content, tabsRow, coinsLabel, toastLabel, bonusLine, titleLabel
local tabs = {}
local cards = {} -- ItemCard de la pestaña actual (se refrescan sin rehacer)
local refreshers = {} -- otras tarjetas (packs, monedas) que se refrescan
local timers = {} -- { Label, EndsAt, Prefix, Rebuild }
local tab = "FEATURED"
local shownOnce: { [string]: boolean } = {} -- analítica: una vez por visita

local function isPhone()
	return C.Breakpoint() == "PHONE"
end

local function toast(text, color)
	toastLabel.Text = text
	toastLabel.TextColor3 = color or Colors.White
	toastLabel.Visible = true
	local stamp = os.clock()
	toastLabel:SetAttribute("Stamp", stamp)
	task.delay(2.2, function()
		if toastLabel:GetAttribute("Stamp") == stamp then
			toastLabel.Visible = false
		end
	end)
end
Store.Toast = toast

---------------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------------

local function buyRobux(what)
	local ok, reason = StoreData.PromptRobux(what)
	if not ok then
		UISound.Play("Error")
		toast(reason or "No disponible", Colors.TextDim)
	end
end

local function onBuy(item)
	if item.Robux then
		buyRobux({ Type = "Item", Item = item })
		return
	end
	Confirm.Open(rootFrame, item, function()
		local ok, message = StoreData.BuyWithCoins(item)
		if not ok then
			UISound.Play("Error")
			toast(C.upper(tostring(message or "No se pudo comprar")), Colors.Red)
		end
	end, function()
		Store.SelectTab("COINS")
	end)
end

local function onEquip(item)
	StoreData.Equip(item.Kind, item.Id)
	UISound.Play("Equip")
	toast("✓ " .. C.upper(item.Name) .. " EQUIPADO", Colors.Green)
end

local function onPreview(item)
	Inspect.Open(rootFrame, item, { OnBuy = onBuy, OnEquip = onEquip })
end

local callbacks = { OnBuy = onBuy, OnEquip = onEquip, OnPreview = onPreview }

-- Para otras pantallas (la oferta de la pantalla final): previsualizar con COMPRAR y EQUIPAR
function Store.Preview(item, opts)
	Inspect.Open(rootFrame, item, { OnBuy = onBuy, OnEquip = onEquip }, opts)
end
Store.Buy = onBuy
Store.Equip = onEquip

---------------------------------------------------------------------------
-- Piezas de la página
---------------------------------------------------------------------------

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function section(text, timerEndsAt, timerPrefix)
	local row = C.new("Frame", { Name = "Section", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = nextOrder(), Parent = content })
	C.text({ Text = text, Role = "TitleItalic", TextSize = 24, Color = Colors.YellowText, Size = UDim2.new(0.6, 0, 1, 0), Parent = row })
	if timerEndsAt then
		local label = C.text({ Name = "Timer", Text = "", Role = "Number", TextSize = 16, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.4, 0), Size = UDim2.new(0.6, 0, 1, 0), Parent = row })
		table.insert(timers, { Label = label, EndsAt = timerEndsAt, Prefix = timerPrefix or "CAMBIA EN " })
	end
	return row
end

-- Cuadrícula con su alto calculado (filas que caben en el ancho de la pantalla)
local function grid(cell)
	local size = cell or (isPhone() and ItemCard.Size.PHONE or ItemCard.Size.DESKTOP)
	local frame = C.new("Frame", { Name = "Grid", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size.Y), LayoutOrder = nextOrder(), Parent = content }, {
		C.new("UIGridLayout", { CellSize = UDim2.fromOffset(size.X, size.Y), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	frame:SetAttribute("CellX", size.X)
	frame:SetAttribute("CellY", size.Y)
	return frame
end

local function fitGrid(frame, count)
	local width = (flow.Root and tonumber(flow.Root:GetAttribute("VirtualWidth")) or 1280) - 48 - 10
	local cellX, cellY = frame:GetAttribute("CellX") or 200, frame:GetAttribute("CellY") or 200
	local perRow = math.max(1, math.floor((width + 12) / (cellX + 12)))
	local rows = math.max(1, math.ceil(count / perRow))
	frame.Size = UDim2.new(1, 0, 0, rows * cellY + (rows - 1) * 12)
end

local function addCards(parent, items)
	fitGrid(parent, #items)
	local keys = {}
	for i, item in items do
		local card = ItemCard.new(parent, item, callbacks, { Phone = isPhone(), Order = i })
		table.insert(cards, card)
		table.insert(keys, item.Key)
	end
	-- (se han visto: la próxima vez ya no son NUEVO)
	StoreData.MarkSeen(keys)
end

-- Tarjeta ancha de un pack (o del pack de inicio): lo que trae, lo que ya tienes, el precio y lo
-- que vale por separado (solo si la cuenta es real)
local function bundleCard(bundle, opts)
	opts = opts or {}
	local phone = isPhone()
	local data = ClientState.Data
	local starter = opts.Starter == true
	local colors = bundle.Colors or { Colors.Yellow, Colors.RedDark }
	local card = C.panel({ Name = "Bundle_" .. tostring(bundle.Id or "Starter"), Size = UDim2.new(1, 0, 0, phone and 196 or 214), Order = nextOrder(), Parent = content }, { Alpha = 0.05, StrokeColor = colors[1], StrokeAlpha = 0.35 })
	C.new("Frame", { Name = "Band", BackgroundColor3 = colors[1], BorderSizePixel = 0, Size = UDim2.new(0, phone and 150 or 210, 1, 0), Parent = card }, {
		C.corner(4),
		C.new("UIGradient", { Rotation = 35, Color = ColorSequence.new(colors[1], colors[2] or colors[1]) }),
	})
	C.text({ Text = bundle.Icon or "📦", TextSize = 54, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromOffset(10, 14), Size = UDim2.fromOffset(phone and 130 or 190, phone and 60 or 76), Parent = card })
	C.text({ Text = C.upper(bundle.Name or "PACK DE INICIO"), Role = "TitleItalic", TextSize = 22, Color = Colors.White, Stroke = 1, Wrap = true, Scaled = true, AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(10, phone and 80 or 96), Size = UDim2.fromOffset(phone and 130 or 190, phone and 50 or 56), Parent = card })
	if opts.Tag then
		C.text({ Text = opts.Tag, Role = "Title", TextSize = 13, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Position = UDim2.new(0, 10, 1, -30), Size = UDim2.fromOffset(phone and 130 or 190, 18), Parent = card })
	end
	-- Lo que trae
	local left = phone and 162 or 226
	local list = Products.BundleItems(bundle)
	local row = C.new("ScrollingFrame", { Name = "Items", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(left, 12), Size = UDim2.new(1, -(left + (phone and 168 or 250)), 0, phone and 112 or 128), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, Parent = card }, {
		C.list(8, Enum.FillDirection.Horizontal),
	})
	local cell = phone and 96 or 112
	local isVIP = StoreData.IsVIP()
	for i, entry in list do
		local item = Catalog.Item(entry.Kind, entry.Id)
		if item then
			local holder = C.new("Frame", { Name = "B_" .. item.Key, BackgroundTransparency = 1, Size = UDim2.fromOffset(cell, cell), LayoutOrder = i, Parent = row })
			ItemArt.Thumb(holder, item, { Size = UDim2.fromScale(1, 1) })
			local owned = data and Catalog.Owns(data, item.Kind, item.Id, isVIP)
			if owned then
				local shade = C.new("Frame", { Name = "Owned", BackgroundColor3 = Colors.Black, BackgroundTransparency = 0.45, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = holder }, { C.corner(4) })
				C.text({ Text = "✓ TUYO", Role = "Title", TextSize = 15, Color = Colors.Green, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = shade })
			end
			local click = C.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = holder })
			click.Activated:Connect(function()
				onPreview(item)
			end)
		end
	end
	if (bundle.Coins or 0) > 0 then
		local holder = C.new("Frame", { Name = "B_Coins", BackgroundTransparency = 1, Size = UDim2.fromOffset(cell, cell), LayoutOrder = 99, Parent = row })
		local art = ItemArt.Backdrop(holder, "Legendario", { Size = UDim2.fromScale(1, 1) })
		C.text({ Text = "🪙", TextSize = 40, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromScale(0.2, 0.08), Size = UDim2.fromScale(0.6, 0.55), Parent = art })
		C.text({ Text = tostring(bundle.Coins), Role = "Number", TextSize = 20, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromScale(0, 0.66), Size = UDim2.fromScale(1, 0.26), Parent = art })
	end
	-- Lo que ya tienes y lo que vale por separado (cuentas reales)
	local status = data and Catalog.BundleStatus(data, bundle, isVIP) or { Owned = 0, Total = #list, Compensation = 0, Missing = list }
	local value = Catalog.BundleValue(bundle)
	local lines = {}
	if value.Complete and value.Robux > 0 and value.Coins == (bundle.Coins or 0) and value.Robux > (bundle.Robux or 0) then
		local saving = math.floor((1 - bundle.Robux / value.Robux) * 100 + 0.5)
		table.insert(lines, string.format("Por separado: <s>R$ %d</s>  ·  <font color=\"#6EE06E\">-%d%%</font>", value.Robux, saving))
	elseif value.Complete and value.Coins > 0 and value.Robux == 0 then
		table.insert(lines, string.format("Lo que trae vale 🪙 %d en la tienda", value.Coins))
	end
	if status.Owned > 0 and status.Owned < status.Total then
		table.insert(lines, string.format("Ya tienes %d de %d: te devolvemos 🪙 %d", status.Owned, status.Total, status.Compensation))
	end
	C.text({ Name = "Value", Text = table.concat(lines, "\n"), Rich = true, Role = "Body", TextSize = 13, Color = Colors.TextDim, Wrap = true, AlignY = Enum.TextYAlignment.Top, Position = UDim2.new(0, left, 1, phone and -64 or -70), Size = UDim2.new(1, -(left + (phone and 168 or 250)), 0, 56), Parent = card })
	-- Precio y botones
	local right = C.new("Frame", { Name = "Buy", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.new(0, phone and 150 or 230, 1, -24), Parent = card })
	local robux = StoreData.Robux({ ProductId = bundle.ProductId, Robux = bundle.Robux })
	C.text({ Name = "Price", Text = "R$ " .. tostring(robux), Role = "Number", TextSize = phone and 26 or 34, Color = Colors.Green, AlignX = Enum.TextXAlignment.Right, Size = UDim2.new(1, 0, 0, phone and 32 or 42), Parent = right })
	local timerLabel
	if opts.EndsAt then
		timerLabel = C.text({ Name = "Timer", Text = "", Role = "Number", TextSize = 13, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Scaled = true, Position = UDim2.fromOffset(0, phone and 32 or 44), Size = UDim2.new(1, 0, 0, 18), Parent = right })
		table.insert(timers, { Label = timerLabel, EndsAt = opts.EndsAt, Prefix = opts.TimerPrefix or "CAMBIA EN " })
	end
	local action = C.button({ Name = "Action", Text = "COMPRAR", Style = "Primary", TextSize = phone and 17 or 20, Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, phone and 44 or 52), Parent = right, Sound = "Click", OnClick = function()
		if status.Owned >= status.Total and status.Total > 0 then
			return
		end
		StoreData.Track(starter and "starter_pack_view" or "bundle_view", { bundle = tostring(bundle.Id or "Starter") })
		buyRobux(starter and { Type = "Starter" } or { Type = "Bundle", Bundle = bundle })
	end })
	local label = action:FindFirstChild("Label", true)
	local function refresh()
		local enabled = Products.Enabled(bundle)
		local text, yellow = "COMPRAR", true
		local data2 = ClientState.Data
		local fresh = data2 and Catalog.BundleStatus(data2, bundle, StoreData.IsVIP()) or status
		local owned = (not starter and data2 and type(data2.Bundles) == "table" and data2.Bundles[bundle.Id]) or (starter and data2 and data2.StarterPack)
		if owned or (fresh.Total > 0 and fresh.Owned >= fresh.Total and (bundle.Coins or 0) == 0) then
			text, yellow = "✓ EN TU COLECCIÓN", false
		elseif not enabled then
			text, yellow = "PRÓXIMAMENTE", false
		elseif StoreData.Pending and (StoreData.Pending.Key == "Bundle:" .. tostring(bundle.Id) or (starter and StoreData.Pending.Key == "Starter")) then
			text, yellow = "PROCESANDO…", false
		end
		label.Text = text
		action.BackgroundColor3 = yellow and Colors.Yellow or Colors.PanelLight
		label.TextColor3 = yellow and DARK or (text:find("COLECCIÓN") and Colors.Green or Colors.TextDim)
		local gradient = action:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Enabled = yellow
		end
	end
	refresh()
	table.insert(refreshers, refresh)
	return card
end

-- Tarjeta pequeña de un producto de Robux (monedas, potenciadores)
local function productCard(parent, spec, order2)
	local phone = isPhone()
	local card = C.panel({ Name = "Product_" .. spec.Name, Size = UDim2.fromOffset(phone and 168 or 200, phone and 176 or 196), Order = order2, Parent = parent }, { Alpha = 0.06, StrokeColor = spec.Color or Colors.Yellow, StrokeAlpha = 0.5 })
	C.text({ Text = spec.Icon, TextSize = 40, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 50), Parent = card })
	C.text({ Text = spec.Title, Role = "TitleItalic", TextSize = 24, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromOffset(8, 62), Size = UDim2.new(1, -16, 0, 28), Parent = card })
	C.text({ Text = spec.Sub or "", Role = "Body", TextSize = 12, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Center, Wrap = true, Position = UDim2.fromOffset(8, 92), Size = UDim2.new(1, -16, 0, 32), Parent = card })
	local action = C.button({ Name = "Action", Text = spec.Button, Style = spec.Enabled and "Primary" or "Ghost", TextSize = 18, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -16, 0, phone and 40 or 44), Parent = card, Sound = "Click", OnClick = function()
		if spec.Enabled and spec.OnClick then
			spec.OnClick()
		end
	end })
	return card, action
end

---------------------------------------------------------------------------
-- Pestañas
---------------------------------------------------------------------------

local function renderFeatured()
	local now = StoreData.Now()
	local event = StoreRotation.ActiveEvent(now)
	if event then
		section("⚠ " .. event.Name, event.EndsAt, "TERMINA EN ")
		local bundle = StoreRotation.BundleById(event.Bundle)
		if bundle then
			bundleCard(bundle, { Tag = "EVENTO", EndsAt = event.EndsAt, TimerPrefix = "TERMINA EN " })
		end
		local items = {}
		for _, key in event.Items do
			local kind, id = Catalog.ParseKey(key)
			local item = kind and Catalog.Item(kind, id, StoreData.Day())
			if item then
				table.insert(items, item)
			end
		end
		addCards(grid(), items)
	end
	local featured = StoreRotation.FeaturedBundle(now)
	if featured and not (event and featured.Id == event.Bundle) then
		section("★ PACK DE LA SEMANA", StoreRotation.WeekEndsAt(now))
		bundleCard(featured, { Tag = "DESTACADO" })
	end
	if StoreData.StarterVisible() then
		section("🎁 PACK DE INICIO · SOLO PARA NUEVOS")
		bundleCard(Shop.StarterPack, { Starter = true, Tag = "UNA SOLA VEZ" })
		if not shownOnce.Starter then
			shownOnce.Starter = true
			StoreData.Track("starter_pack_view", { level = ClientState.Data and ClientState.Data.Level or 1 })
			StoreData.MarkSeen({ "Starter" })
		end
	end
	section("TIENDA DIARIA", StoreRotation.DayEndsAt(now), "NUEVA EN ")
	addCards(grid(), StoreData.Daily())
end

local function renderBundles()
	local now = StoreData.Now()
	section("PACKS")
	for _, bundle in Shop.Bundles do
		local inDates = (bundle.StartsAt == nil or now >= bundle.StartsAt) and (bundle.EndsAt == nil or now < bundle.EndsAt)
		if inDates then
			bundleCard(bundle, { EndsAt = bundle.EndsAt, TimerPrefix = "A LA VENTA " })
		end
	end
	if not shownOnce.Bundles then
		shownOnce.Bundles = true
		StoreData.Track("bundle_view", { tab = "BUNDLES" })
	end
end

local function renderCoins()
	local data = ClientState.Data
	section("MONEDAS")
	local productCell = isPhone() and Vector2.new(168, 176) or Vector2.new(200, 196)
	local packs = grid(productCell)
	fitGrid(packs, #Shop.CoinPacks)
	for i, pack in Shop.CoinPacks do
		productCard(packs, {
			Name = pack.Name,
			Icon = string.rep("🪙", math.min(i, 3)),
			Title = tostring(pack.Coins),
			Sub = C.upper(pack.Name) .. (pack.Tag and ("  ·  " .. pack.Tag .. " monedas por Robux") or ""),
			Button = Products.Enabled(pack) and ("R$ " .. tostring(StoreData.Robux(pack))) or "PRÓXIMAMENTE",
			Enabled = Products.Enabled(pack),
			OnClick = function()
				buyRobux({ Type = "Coins", Def = pack })
			end,
		}, i)
	end
	section("POTENCIADORES  ·  solo XP y monedas, el tiempo corre jugando")
	local boosts = grid(productCell)
	fitGrid(boosts, #Shop.Boosters)
	for i, booster in Shop.Boosters do
		local left = data and tonumber(data[booster.Field]) or 0
		productCard(boosts, {
			Name = booster.Id,
			Icon = booster.Icon,
			Title = booster.Name,
			Sub = booster.Minutes .. " min de juego" .. (left > 0 and ("  ·  te quedan " .. math.ceil(left / 60) .. " min") or ""),
			Button = Products.Enabled(booster) and ("R$ " .. tostring(StoreData.Robux(booster))) or "PRÓXIMAMENTE",
			Enabled = Products.Enabled(booster),
			Color = Colors.Blue,
			OnClick = function()
				buyRobux({ Type = "Booster", Def = booster })
			end,
		}, i)
	end
	section("VIP")
	local vipRow = grid(productCell)
	fitGrid(vipRow, 2)
	local vip = data and data.VIP
	productCard(vipRow, {
		Name = "VIP",
		Icon = "👑",
		Title = "VIP",
		Sub = "x2 XP y monedas · nombre dorado · grafiti exclusivo · +" .. (MonetizationConfig.Rules.VIPDailyCoins or 0) .. " 🪙 al día",
		Button = vip and "✓ YA ERES VIP" or (Shop.VIPPassId ~= 0 and ("R$ " .. tostring(StoreData.Robux({ ProductId = Shop.VIPPassId, Robux = Shop.VIPRobux }, Enum.InfoType.GamePass))) or "PRÓXIMAMENTE"),
		Enabled = not vip and Shop.VIPPassId ~= 0,
		OnClick = function()
			buyRobux({ Type = "VIP" })
		end,
	}, 1)
	local premium = GameConfig.RobloxPremium
	if premium then
		local isPremium = player:GetAttribute("RobloxPremium") == true
		productCard(vipRow, {
			Name = "RobloxPremium",
			Icon = utf8.char(0xE001),
			Title = "PREMIUM",
			Sub = "+" .. math.floor((premium.Multiplier - 1) * 100 + 0.5) .. "% monedas y XP con Roblox Premium",
			Button = isPremium and "✓ ACTIVO" or "HAZTE PREMIUM",
			Enabled = not isPremium,
			OnClick = function()
				pcall(function()
					game:GetService("MarketplaceService"):PromptPremiumPurchase(player)
				end)
			end,
		}, 2)
	end
end

local function renderCategory(category)
	section(category.Text)
	addCards(grid(), Catalog.StoreItems(category.Kinds, StoreData.Day()))
end

local function render()
	for _, child in content:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(cards)
	table.clear(refreshers)
	table.clear(timers)
	order = 0
	content.CanvasPosition = Vector2.zero
	if tab == "FEATURED" then
		renderFeatured()
	elseif tab == "BUNDLES" then
		renderBundles()
	elseif tab == "COINS" then
		renderCoins()
	else
		for _, category in Catalog.Categories do
			if category.Id == tab and category.Kinds then
				renderCategory(category)
			end
		end
	end
	Store.UpdateTimers()
end

-- Relojes: cuentan hasta la hora de cambio de verdad; al llegar, la tienda se rehace (cambio real)
function Store.UpdateTimers()
	local now = StoreData.Now()
	local expired = false
	for _, timer in timers do
		local left = timer.EndsAt - now
		if left <= 0 then
			expired = true
		end
		timer.Label.Text = timer.Prefix .. StoreData.FormatTime(left)
	end
	if expired and screen.Visible then
		render()
	end
end

local function refreshTabs()
	local data = ClientState.Data
	for id, button in tabs do
		C.setSelected(button, id == tab)
		local dot = false
		for _, category in Catalog.Categories do
			if category.Id == id and category.Kinds and data then
				for _, item in Catalog.StoreItems(category.Kinds) do
					if Catalog.IsNew(data, item.Kind, item.Id) and not Catalog.Owns(data, item.Kind, item.Id, StoreData.IsVIP()) then
						dot = true
						break
					end
				end
			end
		end
		if id == "PASS" then
			dot = data ~= nil and data.Pass ~= nil and (data.Pass.Claimable or 0) > 0
		end
		C.dot(button, dot)
	end
end

function Store.SelectTab(id)
	if id == "PASS" then
		flow.SetState("Pass")
		return
	end
	tab = id
	refreshTabs()
	render()
	StoreData.Track("store_open", { tab = id })
	Transition.SlideIn(content, Vector2.new(0, 16), 0.18)
end

function Store.Refresh()
	local data = ClientState.Data
	coinsLabel.Text = data and tostring(data.Coins or 0) or "—"
	bonusLine.Visible = data ~= nil and not data.FirstPurchase and MonetizationConfig.FirstPurchaseBonus ~= nil
	for _, card in cards do
		card.Refresh()
	end
	for _, refresh in refreshers do
		refresh()
	end
	refreshTabs()
end

---------------------------------------------------------------------------
-- Pantalla
---------------------------------------------------------------------------

local function applyLayout()
	local phone = isPhone()
	titleLabel.TextSize = phone and 34 or 46
	tabsRow.Position = UDim2.fromOffset(24, phone and 58 or 76)
	tabsRow.Size = UDim2.new(1, -48, 0, phone and 38 or 42)
	for _, button in tabs do
		button.Size = UDim2.fromOffset(phone and 104 or 128, phone and 38 or 42)
	end
	local top = phone and 104 or 128
	content.Position = UDim2.fromOffset(24, top)
	content.Size = UDim2.new(1, -48, 1, -(top + (phone and 30 or 40)))
end

function Store.Build(flowController, root)
	flow = flowController
	rootFrame = root
	StoreData.Init()
	Reveal.Init()
	screen = C.new("Frame", { Name = "Store", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	C.button({ Name = "Back", Text = "VOLVER", Icon = "◀", Style = "Ghost", TextSize = 16, Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(130, 40), Parent = screen, Sound = "Back", OnClick = function()
		flow.SetState("Home")
	end })
	titleLabel = C.text({ Text = "TIENDA", Role = "TitleItalic", TextSize = 46, Position = UDim2.fromOffset(170, 14), Size = UDim2.fromOffset(300, 54), Stroke = 2, Parent = screen })
	-- Monedas (con + que lleva a MONEDAS); los Robux los enseña Roblox en su ventana
	local currencyRow = C.new("Frame", { Name = "Currency", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 22), Size = UDim2.fromOffset(160, 40), Parent = screen })
	local _, amount = C.currency(currencyRow, "🪙", 1, function()
		Store.SelectTab("COINS")
	end)
	coinsLabel = amount
	-- Pestañas
	tabsRow = C.new("ScrollingFrame", { Name = "Tabs", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(24, 76), Size = UDim2.new(1, -48, 0, 42), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0, Parent = screen }, {
		C.list(6, Enum.FillDirection.Horizontal),
	})
	for i, category in Catalog.Categories do
		tabs[category.Id] = C.button({ Name = "Tab_" .. category.Id, Text = category.Text, Style = "Menu", TextSize = 15, Size = UDim2.fromOffset(128, 42), Order = i, Parent = tabsRow, OnClick = function()
			Store.SelectTab(category.Id)
		end })
	end
	-- Contenido
	content = C.new("ScrollingFrame", {
		Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(24, 128),
		Size = UDim2.new(1, -48, 1, -168),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Colors.Yellow,
		Parent = screen,
	}, { C.list(10), C.padding(4, 6, 12, 2) })
	-- Una línea (sin ventana) con el bonus de la primera compra
	bonusLine = C.text({ Name = "FirstPurchase", Text = "🎁 " .. (MonetizationConfig.FirstPurchaseBonus and MonetizationConfig.FirstPurchaseBonus.Text or ""), Role = "Body", TextSize = 13, Color = Colors.TextDim, Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -8), Size = UDim2.new(1, -48, 0, 20), Parent = screen })
	toastLabel = C.text({ Name = "Toast", Text = "", Role = "TitleItalic", TextSize = 20, AlignX = Enum.TextXAlignment.Center, Stroke = 2, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -34), Size = UDim2.new(1, -40, 0, 28), Visible = false, ZIndex = 10, Parent = screen })
	ClientState.DataChanged.Event:Connect(function()
		if screen.Visible then
			Store.Refresh()
		end
	end)
	StoreData.Changed.Event:Connect(function(state)
		if screen.Visible then
			Store.Refresh()
			if state == "Cancelled" then
				toast("COMPRA CANCELADA", Colors.TextDim)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if screen.Visible then
				Store.UpdateTimers()
			end
		end
	end)
	-- Lo que antes abría la tienda o el pase del menú (botones de otros sitios): en el lobby, aquí
	pcall(function()
		local Menu = require(Modules.Menu)
		Menu.Redirect = function(tabName)
			if (tabName == "Tienda" or tabName == "Pase") and flow.Lobby[flow.State] then
				flow.SetState(tabName == "Tienda" and "Store" or "Pass")
				return true
			end
			return false
		end
	end)
	Store.Screen = screen
end

-- ctx.Tab: pestaña con la que abrir (p. ej. "COINS" desde el + de las monedas, "FEATURED" desde EVENTOS)
function Store.Show(ctx)
	ctx = ctx or {}
	table.clear(shownOnce)
	tab = ctx.Tab or "FEATURED"
	applyLayout()
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.62, 0.25)
	Transition.Blur(16, 0.25)
	screen.Visible = true
	Store.Refresh()
	render()
	StoreData.Track("store_open", { tab = tab })
	Transition.SlideIn(content, Vector2.new(0, 24), 0.3)
end

function Store.Hide()
	Inspect.Close()
	Confirm.Close()
	screen.Visible = false
end

return Store
