-- ARMAMENTO: categorías arriba, la lista de armas de la categoría a la izquierda, el arma en grande
-- en el centro (3D, con tu skin, moviéndose despacio), sus estadísticas a la derecha (DAÑO,
-- PRECISIÓN, CADENCIA, MOVILIDAD y CONTROL, barras que se animan al cambiar de arma) y abajo tus
-- 5 clases: eliges la clase que editas y EQUIPAR pone el arma en ella (si es la que usas, se cambia
-- ya en el lobby). Las armas bloqueadas dicen a qué nivel salen o se compran con monedas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Weapons = require(Shared.Weapons)
local Mastery = require(Shared.Mastery)

local Modules = script.Parent.Parent.Parent
local ClientState = require(Modules.ClientState)
local WeaponIcon = require(Modules.WeaponIcon)
local Menu = require(Modules.Menu)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)

local Armory = {}

-- Categorías del juego agrupadas como en un shooter (las de la lista de armas, en castellano)
local CATEGORIES = {
	{ Id = "AR", Text = "FUSILES", Match = { ["Fusil de asalto"] = true, ["Fusil de energía"] = true } },
	{ Id = "SMG", Text = "SUBFUSILES", Match = { Subfusil = true } },
	{ Id = "SG", Text = "ESCOPETAS", Match = { Escopeta = true, ["Escopeta pesada"] = true } },
	{ Id = "MR", Text = "TIRADOR", Match = { ["Fusil de tirador"] = true, Francotirador = true, Ballesta = true } },
	{ Id = "HV", Text = "PESADAS", Match = { ["Ametralladora pesada"] = true, Lanzacohetes = true, Paintball = true } },
	{ Id = "SEC", Text = "SECUNDARIAS", Secondary = true },
}

local flow, screen, tabsRow, listFrame, center, statsPanel, classRow
local nameLabel, categoryLabel, descLabel, iconHolder, actionButton, actionLabel, infoLabel, masteryLabel, masteryBar, useButton
local titleLabel, editLabel
local rowHeight = 44
local stats = {}
local tabs = {}
local classCards = {}
local category = "AR"
local selectedWeapon
local editClass = 1
local iconKey
local swayConnection
local busy = false

---------------------------------------------------------------------------
-- Estadísticas (0..100 comparadas con las demás armas de fuego)
---------------------------------------------------------------------------

local maxes
local function computeMaxes()
	maxes = { Damage = 1, Rate = 1, Recoil = 0.01, Spread = 0.01, WalkMin = 1, WalkMax = 1 }
	for _, def in Weapons.List do
		if def.Type == "Gun" and not def.Explosive and not def.Hidden then
			maxes.Damage = math.max(maxes.Damage, (def.Damage or 0) * (def.Pellets or 1))
			maxes.Rate = math.max(maxes.Rate, def.FireRate or 0)
			maxes.Recoil = math.max(maxes.Recoil, def.Recoil or 0)
			maxes.Spread = math.max(maxes.Spread, (def.Spread or 0) + 2 * (def.AimSpread or 0))
			local walk = def.WalkSpeedMultiplier or 1
			maxes.WalkMin = math.min(maxes.WalkMin, walk)
			maxes.WalkMax = math.max(maxes.WalkMax, walk)
		end
	end
end

function Armory.Stats(def)
	if not maxes then
		computeMaxes()
	end
	local walk = def.WalkSpeedMultiplier or 1
	local walkRange = math.max(0.01, maxes.WalkMax - maxes.WalkMin)
	return {
		-- (raíz: las escopetas, con todos los perdigones, no dejan a los fusiles en nada)
		Damage = 100 * math.sqrt(math.min(1, (def.Damage or 0) * (def.Pellets or 1) / maxes.Damage)),
		Accuracy = 100 * (1 - 0.85 * math.min(1, ((def.Spread or 0) + 2 * (def.AimSpread or 0)) / maxes.Spread)),
		Rate = 100 * math.min(1, (def.FireRate or 0) / maxes.Rate),
		Mobility = 30 + 70 * math.clamp((walk - maxes.WalkMin) / walkRange, 0, 1),
		Control = 100 * (1 - 0.85 * math.min(1, (def.Recoil or 0) / maxes.Recoil)),
	}
end

local STAT_ROWS = {
	{ Key = "Damage", Text = "DAÑO", Icon = "✸" },
	{ Key = "Accuracy", Text = "PRECISIÓN", Icon = "◎" },
	{ Key = "Rate", Text = "CADENCIA", Icon = "≡" },
	{ Key = "Mobility", Text = "MOVILIDAD", Icon = "➤" },
	{ Key = "Control", Text = "CONTROL", Icon = "✥" },
}

---------------------------------------------------------------------------
-- Datos
---------------------------------------------------------------------------

local function categoryOf(id)
	for _, cat in CATEGORIES do
		if cat.Id == id then
			return cat
		end
	end
	return CATEGORIES[1]
end

local function weaponsIn(cat)
	local list = {}
	local source = cat.Secondary and Weapons.Secondaries or Weapons.Primaries
	for _, name in source do
		local def = Weapons.Get(name)
		if def and not def.Hidden and (cat.Secondary or (cat.Match and cat.Match[def.Category])) then
			table.insert(list, name)
		end
	end
	table.sort(list, function(a, b)
		return (Weapons.Get(a).UnlockLevel or 1) < (Weapons.Get(b).UnlockLevel or 1)
	end)
	return list
end

local function categoryFor(name)
	if table.find(Weapons.Secondaries, name) then
		return "SEC"
	end
	local def = Weapons.Get(name)
	for _, cat in CATEGORIES do
		if def and cat.Match and cat.Match[def.Category] then
			return cat.Id
		end
	end
	return "AR"
end

local function classes(data)
	return data and data.Classes or GameConfig.DefaultClasses
end

local function slotField()
	return categoryOf(category).Secondary and "Secondary" or "Primary"
end

---------------------------------------------------------------------------
-- Pintar
---------------------------------------------------------------------------

local function renderClasses()
	local data = ClientState.Data
	local list = classes(data)
	for i, card in classCards do
		local class = list[i] or GameConfig.DefaultClasses[i]
		card.Name.Text = tostring(class.Name or ("CLASE " .. i))
		local primary = Weapons.Get(class.Primary)
		card.Weapon.Text = primary and C.upper(primary.DisplayName) or "—"
		local active = data and data.ActiveClass == i
		card.Active.Visible = active
		C.setSelected(card.Frame, i == editClass)
		local dim = i == editClass and Color3.fromRGB(60, 46, 6) or Colors.TextDim
		card.Head.TextColor3 = dim
		card.Weapon.TextColor3 = dim
	end
	local active = data and data.ActiveClass
	useButton.Visible = active ~= editClass
end

local function renderList()
	local data = ClientState.Data
	for _, child in listFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local equipped = classes(data)[editClass] and classes(data)[editClass][slotField()]
	for i, name in weaponsIn(categoryOf(category)) do
		local def = Weapons.Get(name)
		local unlocked = Weapons.IsUnlocked(name, data)
		local button = C.button({
			Name = "W_" .. name,
			Text = C.upper(def.DisplayName),
			Style = "Menu",
			TextSize = 17,
			Size = UDim2.new(1, 0, 0, rowHeight),
			Order = i,
			Parent = listFrame,
			OnClick = function()
				Armory.SelectWeapon(name)
			end,
		})
		local right = C.text({
			Name = "State",
			Text = name == equipped and "✔" or (unlocked and "" or ("🔒 " .. tostring(def.UnlockLevel))),
			Role = "Number",
			TextSize = 14,
			Color = name == equipped and Colors.Green or Colors.TextFaint,
			AlignX = Enum.TextXAlignment.Right,
			Anchor = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(60, 20),
			ZIndex = 5,
			Parent = button,
		})
		C.setSelected(button, name == selectedWeapon)
		if name == selectedWeapon then
			right.TextColor3 = DARK
		end
	end
end

local function renderWeapon(animate)
	local data = ClientState.Data
	local name = selectedWeapon
	local def = name and Weapons.Get(name)
	if not def then
		return
	end
	nameLabel.Text = C.upper(def.DisplayName)
	categoryLabel.Text = C.upper(def.Category or "")
	descLabel.Text = tostring(def.Description or "")
	-- Arma en 3D (solo se rehace si cambia el arma o la skin)
	local skin = Menu.SkinFor and Menu.SkinFor(data, name) or nil
	local key = name .. "/" .. tostring(skin)
	if key ~= iconKey then
		iconKey = key
		iconHolder:ClearAllChildren()
		pcall(WeaponIcon.Create, name, skin, { Name = "Weapon3D", Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = iconHolder }, "angled", 2.1)
		if animate ~= false then
			Transition.Pop(iconHolder, 0.9, 0.25)
		end
	end
	-- Estadísticas
	local values = Armory.Stats(def)
	for _, row in STAT_ROWS do
		stats[row.Key]:Set(values[row.Key], animate ~= false)
	end
	local damage = (def.Pellets or 1) > 1 and (tostring(def.Damage) .. "×" .. tostring(def.Pellets)) or tostring(def.Damage or 0)
	infoLabel.Text = string.format("Daño %s  ·  %d disparos/s  ·  Cargador %d  ·  Recarga %.1f s", damage, math.floor((def.FireRate or 0) + 0.5), def.MagSize or 0, def.ReloadTime or 0)
	-- Maestría
	local kills = data and data.WeaponKills and data.WeaponKills[name] or 0
	local level = Mastery.Level(kills)
	local nextTier = Mastery.Next(kills)
	local current = Mastery.Tiers[level]
	masteryLabel.Text = (current and ("MAESTRÍA · " .. C.upper(current.Name)) or "MAESTRÍA") .. (nextTier and string.format("   %d/%d bajas", kills, nextTier.Kills) or "   ¡COMPLETA!")
	local previous = current and current.Kills or 0
	masteryBar:Set(nextTier and (kills - previous) / math.max(1, nextTier.Kills - previous) or 1, animate ~= false)
	-- Acción: equipar en la clase, comprar o ver a qué nivel sale
	local unlocked = Weapons.IsUnlocked(name, data)
	local equipped = classes(data)[editClass] and classes(data)[editClass][slotField()] == name
	actionButton.Active = true
	if equipped then
		actionLabel.Text = "EQUIPADA EN CLASE " .. editClass
		actionButton.BackgroundColor3 = Colors.PanelLight
		actionLabel.TextColor3 = Colors.Green
	elseif unlocked then
		actionLabel.Text = "EQUIPAR EN CLASE " .. editClass
		actionButton.BackgroundColor3 = Colors.Yellow
		actionLabel.TextColor3 = DARK
	elseif def.Price then
		actionLabel.Text = string.format("COMPRAR  🪙 %d", def.Price)
		actionButton.BackgroundColor3 = (data and (data.Coins or 0) >= def.Price) and Colors.Yellow or Colors.PanelLight
		actionLabel.TextColor3 = (data and (data.Coins or 0) >= def.Price) and DARK or Colors.TextDim
	else
		actionLabel.Text = def.EventText and C.upper(def.EventText) or ("🔒 NIVEL " .. tostring(def.UnlockLevel))
		actionButton.BackgroundColor3 = Colors.PanelLight
		actionLabel.TextColor3 = Colors.TextDim
	end
	local gradient = actionButton:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Enabled = actionButton.BackgroundColor3 == Colors.Yellow
	end
end

function Armory.Render(animate)
	if not screen then
		return
	end
	for id, button in tabs do
		C.setSelected(button, id == category)
	end
	renderClasses()
	renderList()
	renderWeapon(animate)
end

---------------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------------

function Armory.SelectCategory(id)
	if category == id then
		return
	end
	category = id
	local data = ClientState.Data
	local class = classes(data)[editClass]
	local list = weaponsIn(categoryOf(id))
	local equipped = class and class[slotField()]
	selectedWeapon = (equipped and table.find(list, equipped)) and equipped or list[1]
	Transition.SlideIn(listFrame, Vector2.new(-24, 0), 0.2)
	Armory.Render(true)
end

function Armory.SelectWeapon(name)
	if selectedWeapon == name then
		return
	end
	selectedWeapon = name
	Armory.Render(true)
end

function Armory.SelectClass(i)
	editClass = i
	local class = classes(ClientState.Data)[i]
	if class then
		local name = class[slotField()]
		if name then
			selectedWeapon = name
		end
	end
	Armory.Render(true)
end

local function act()
	local data = ClientState.Data
	local name = selectedWeapon
	local def = name and Weapons.Get(name)
	if not def or busy then
		return
	end
	local unlocked = Weapons.IsUnlocked(name, data)
	local equipped = classes(data)[editClass] and classes(data)[editClass][slotField()] == name
	if equipped then
		return
	end
	if unlocked then
		UISound.Play("Equip")
		pcall(function()
			Remotes.EditClass:FireServer(editClass, slotField(), name)
		end)
		Transition.Pulse(iconHolder, 1.08, 0.2)
	elseif def.Price then
		busy = true
		local ok, result, message = pcall(function()
			return Remotes.BuyItem:InvokeServer("Weapon", name)
		end)
		busy = false
		if ok and result then
			UISound.Play("Reward")
			Transition.Flash(Colors.Yellow, 0.25, 0.3)
		else
			UISound.Play("Error")
			actionLabel.Text = C.upper(tostring(ok and (message or "No se pudo comprar") or "Error de conexión"))
		end
	else
		UISound.Play("Error")
	end
end

---------------------------------------------------------------------------
-- Pantalla
---------------------------------------------------------------------------

local function buildClassCard(i)
	local card = C.button({ Name = "Class" .. i, Text = "", Style = "Menu", Size = UDim2.new(0.2, -8, 1, 0), Order = i, Parent = classRow, OnClick = function()
		Armory.SelectClass(i)
	end })
	local head = C.text({ Name = "Head", Text = "CLASE " .. i, Role = "Title", TextSize = 13, Color = Colors.TextDim, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 16), ZIndex = 5, Parent = card })
	local name = C.text({ Name = "ClassName", Text = "", Role = "TitleItalic", TextSize = 20, Position = UDim2.fromOffset(12, 21), Size = UDim2.new(1, -24, 0, 24), ZIndex = 5, Parent = card })
	local weapon = C.text({ Name = "Weapon", Text = "", Role = "BodyBold", TextSize = 12, Color = Colors.TextDim, Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 16), ZIndex = 5, Parent = card })
	local active = C.new("Frame", { Name = "Active", BackgroundColor3 = Colors.Green, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(8, 8), ZIndex = 6, Parent = card }, { C.corner(4) })
	classCards[i] = { Frame = card, Head = head, Name = name, Weapon = weapon, Active = active }
end

function Armory.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "Armory", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	-- Cabecera
	C.button({ Name = "Back", Text = "VOLVER", Icon = "◀", Style = "Ghost", TextSize = 16, Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(130, 40), Parent = screen, Sound = "Back", OnClick = function()
		flow.SetState("Home")
	end })
	titleLabel = C.text({ Text = "ARMAMENTO", Role = "TitleItalic", TextSize = 46, Position = UDim2.fromOffset(170, 14), Size = UDim2.fromOffset(420, 54), Stroke = 2, Parent = screen })
	tabsRow = C.new("Frame", { Name = "Tabs", BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 76), Size = UDim2.new(1, -48, 0, 40), Parent = screen }, {
		C.list(6, Enum.FillDirection.Horizontal),
	})
	for i, cat in CATEGORIES do
		tabs[cat.Id] = C.button({ Name = "Tab_" .. cat.Id, Text = cat.Text, Style = "Menu", TextSize = 15, Size = UDim2.fromOffset(cat.Id == "SEC" and 150 or 124, 40), Order = i, Parent = tabsRow, OnClick = function()
			Armory.SelectCategory(cat.Id)
		end })
	end
	-- Lista de armas (izquierda)
	listFrame = C.new("Frame", { Name = "List", BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 128), Size = UDim2.new(0, 250, 1, -262), Parent = screen }, { C.list(6) })
	-- Arma en grande (centro)
	center = C.new("Frame", { Name = "Center", BackgroundTransparency = 1, Position = UDim2.fromOffset(290, 120), Size = UDim2.new(1, -290 - 380, 1, -250), Parent = screen })
	categoryLabel = C.text({ Text = "", Role = "Title", TextSize = 16, Color = Colors.YellowText, Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 20), Parent = center })
	nameLabel = C.text({ Text = "", Role = "TitleItalic", TextSize = 48, Position = UDim2.fromOffset(6, 22), Size = UDim2.new(1, -12, 0, 54), Scaled = true, Stroke = 2, Parent = center })
	-- Suelo de luz detrás del arma (sin imágenes: un degradado)
	C.new("Frame", { Name = "Glow", BackgroundColor3 = Colors.Yellow, BackgroundTransparency = 0.88, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.new(0.9, 0, 0.5, 0), Parent = center }, {
		C.corner(200),
		C.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	iconHolder = C.new("Frame", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.new(1, 0, 0.62, 0), ZIndex = 3, Parent = center })
	descLabel = C.text({ Text = "", Role = "Body", TextSize = 14, Color = Colors.TextDim, Wrap = true, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(0.9, 0, 0, 36), Parent = center })
	-- Estadísticas (derecha)
	statsPanel = C.panel({ Name = "Stats", Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 128), Size = UDim2.fromOffset(350, 300), Parent = screen }, {})
	local inner = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = statsPanel }, { C.padding(12, 14, 12, 14), C.list(6) })
	C.header(inner, "ESTADÍSTICAS", "", 0)
	for i, row in STAT_ROWS do
		stats[row.Key] = C.statRow(inner, row.Text, row.Icon, i)
	end
	infoLabel = C.text({ Text = "", Role = "BodyBold", TextSize = 12, Color = Colors.TextDim, Wrap = true, Size = UDim2.new(1, 0, 0, 30), Order = 10, Parent = inner })
	masteryLabel = C.text({ Text = "", Role = "Title", TextSize = 14, Color = Colors.YellowText, Size = UDim2.new(1, 0, 0, 18), Order = 11, Parent = inner })
	masteryBar = C.progress({ Size = UDim2.new(1, 0, 0, 5), Order = 12, Parent = inner })
	actionButton = C.button({ Name = "Action", Text = "", Style = "Primary", TextSize = 20, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 440), Size = UDim2.fromOffset(350, 54), Parent = screen, Sound = "Click", OnClick = act })
	actionLabel = actionButton:FindFirstChild("Label", true)
	-- Clases (abajo)
	editLabel = C.text({ Text = "CLASE QUE EDITAS", Role = "Title", TextSize = 13, Color = Colors.TextDim, Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -100), Size = UDim2.fromOffset(300, 16), Parent = screen })
	classRow = C.new("Frame", { Name = "Classes", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -24), Size = UDim2.new(1, -48 - 220, 0, 70), Parent = screen }, {
		C.list(8, Enum.FillDirection.Horizontal),
	})
	for i = 1, GameConfig.ClassCount or 5 do
		buildClassCard(i)
	end
	useButton = C.button({ Name = "UseClass", Text = "USAR ESTA CLASE", Style = "Ghost", TextSize = 15, Anchor = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(208, 70), Parent = screen, Sound = "Equip", OnClick = function()
		pcall(function()
			Remotes.SelectClass:FireServer(editClass)
		end)
	end })
	ClientState.DataChanged.Event:Connect(function()
		if screen.Visible then
			Armory.Render(false)
		end
	end)
	Armory.Screen = screen
end

-- Responsive: en pantallas estrechas la lista y las estadísticas se estrechan; en el teléfono
-- (pantalla baja) todo se compacta y se quitan los detalles (datos en texto y maestría)
local function applyLayout()
	local width = flow.Root and flow.Root:GetAttribute("VirtualWidth") or 1280
	local phone = C.Breakpoint() == "PHONE"
	local narrow = phone or width < 1100
	local listW = phone and 190 or (narrow and 200 or 250)
	local statsW = phone and 280 or (narrow and 300 or 350)
	local top = phone and 100 or 128
	rowHeight = phone and 36 or 44
	titleLabel.TextSize = phone and 34 or 46
	titleLabel.Position = UDim2.fromOffset(170, phone and 8 or 14)
	tabsRow.Position = UDim2.fromOffset(24, phone and 56 or 76)
	for id, tab in tabs do
		tab.Size = UDim2.fromOffset(id == "SEC" and (phone and 120 or 150) or (phone and 104 or 124), phone and 34 or 40)
	end
	listFrame.Position = UDim2.fromOffset(24, top)
	listFrame.Size = UDim2.new(0, listW, 1, -(top + 130))
	statsPanel.Position = UDim2.new(1, -24, 0, top)
	statsPanel.Size = UDim2.fromOffset(statsW, phone and 214 or 300)
	infoLabel.Visible = not phone
	masteryLabel.Visible = not phone
	masteryBar.Frame.Visible = not phone
	actionButton.Position = UDim2.new(1, -24, 0, top + (phone and 222 or 312))
	actionButton.Size = UDim2.fromOffset(statsW, phone and 44 or 54)
	classRow.Size = UDim2.new(1, -48 - (phone and 200 or 220), 0, phone and 58 or 70)
	classRow.Position = UDim2.new(0, 24, 1, phone and -12 or -24)
	editLabel.Position = UDim2.new(0, 24, 1, phone and -74 or -100)
	useButton.Size = UDim2.fromOffset(phone and 190 or 208, phone and 58 or 70)
	useButton.Position = UDim2.new(1, -24, 1, phone and -12 or -24)
	local left = listW + 40
	local right = statsW + 34
	center.Position = UDim2.fromOffset(left, top - 8)
	center.Size = UDim2.new(1, -left - right, 1, -(top + 130))
end

function Armory.Show()
	local data = ClientState.Data
	editClass = data and data.ActiveClass or 1
	local class = classes(data)[editClass]
	selectedWeapon = class and class.Primary or Weapons.Primaries[1]
	category = categoryFor(selectedWeapon)
	iconKey = nil
	applyLayout()
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.62, 0.25)
	Transition.Blur(14, 0.25)
	screen.Visible = true
	Armory.Render(true)
	Transition.SlideIn(listFrame, Vector2.new(-50, 0), 0.3)
	Transition.SlideIn(statsPanel, Vector2.new(50, 0), 0.3, 0.04)
	-- El arma se mueve despacio (solo mientras se ve esta pantalla)
	if swayConnection then
		swayConnection:Disconnect()
	end
	local base, pivot
	swayConnection = RunService.RenderStepped:Connect(function()
		local viewport = iconHolder:FindFirstChild("Weapon3D")
		local camera = viewport and viewport.CurrentCamera
		local model = viewport and viewport:FindFirstChildWhichIsA("Model")
		if not camera or not model then
			return
		end
		if camera:GetAttribute("Base") == nil then
			local ok, cf = pcall(model.GetPivot, model)
			if not ok then
				return
			end
			camera:SetAttribute("Base", true)
			pivot = cf
			base = cf:ToObjectSpace(camera.CFrame)
		end
		if pivot and base then
			camera.CFrame = pivot * CFrame.Angles(0, math.sin(os.clock() * 0.6) * 0.22, 0) * base
		end
	end)
end

function Armory.Hide()
	if swayConnection then
		swayConnection:Disconnect()
		swayConnection = nil
	end
	screen.Visible = false
end

return Armory
