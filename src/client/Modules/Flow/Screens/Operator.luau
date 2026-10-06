-- OPERADOR: tu personaje en grande con el traje que estás mirando (en 3D, se gira arrastrando),
-- roles arriba (ASALTO, RECON, PESADO, FRANCOTIRADOR, ESPECIAL), su ficha a la izquierda (rareza,
-- rol, estilo y la clase que le va), las habilidades de operador a la derecha y abajo la tira para
-- elegir. Los trajes son SOLO estética: no cambian vida, daño ni velocidad (se dice en la ficha).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Outfits = require(Shared.Outfits)
local Shop = require(Shared.Shop)
local Skins = require(Shared.Skins)
local Weapons = require(Shared.Weapons)

local Modules = script.Parent.Parent.Parent
local ClientState = require(Modules.ClientState)
local Menu = require(Modules.Menu)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Preview = require(Flow.Preview)

local player = Players.LocalPlayer
local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)

local Operator = {}

-- Roles a partir de la etiqueta "Class" de cada traje
local ROLES = {
	{ Id = "ALL", Text = "TODOS" },
	{ Id = "ASSAULT", Text = "ASALTO", Classes = { ["Clase asalto"] = true }, Style = "Primera línea: entra en los puntos y abre camino al equipo.", Class = "ASALTO" },
	{ Id = "RECON", Text = "RECON", Classes = { ["Clase reconocimiento"] = true, ["Clase infiltración"] = true }, Style = "Información y movilidad: encuentra al enemigo antes de que te encuentre.", Class = "CQB" },
	{ Id = "HEAVY", Text = "PESADO", Classes = { ["Clase pesada"] = true }, Style = "Aguanta posiciones y castiga con fuego sostenido.", Class = "PESADO" },
	{ Id = "SNIPER", Text = "FRANCOTIRADOR", Classes = { ["Clase francotirador"] = true }, Style = "Controla las líneas largas desde lejos y cubre a tu equipo.", Class = "TIRADOR" },
	{ Id = "SPECIAL", Text = "ESPECIAL", Style = "Ediciones de evento y de colección.", Special = true },
}

local flow, screen, preview, tabsRow, strip, infoPanel, abilityPanel, actionButton, actionLabel
local rarityTag, rarityLabel, nameLabel, roleLabel, styleLabel, classButton, classLabel
local tabs = {}
local abilityRows, abilityDescs = {}, {}
local titleLabel
local role = "ALL"
local selected = "Default"
local shownKey

local function roleOf(id)
	local outfit = Outfits.Get(id)
	for _, r in ROLES do
		if r.Classes and r.Classes[outfit.Class] then
			return r
		end
	end
	return ROLES[#ROLES]
end

local function idsFor(roleId)
	local ids = {}
	for id in Outfits.List do
		if roleId == "ALL" or (id ~= "Default" and roleOf(id).Id == roleId) then
			table.insert(ids, id)
		end
	end
	local order = { "Común", "Raro", "Épico", "Legendario", "Mítico" }
	table.sort(ids, function(a, b)
		if (a == "Default") ~= (b == "Default") then
			return a == "Default"
		end
		local ra = table.find(order, Outfits.List[a].Rarity) or 0
		local rb = table.find(order, Outfits.List[b].Rarity) or 0
		if ra ~= rb then
			return ra < rb
		end
		return Outfits.List[a].Name < Outfits.List[b].Name
	end)
	return ids
end

local function rarityColor(rarity)
	return Skins.RarityColors[rarity] or Colors.TextDim
end

-- Índice de la clase que va con el rol (por nombre; si la renombraste, la que más se parece)
local function classFor(r)
	local data = ClientState.Data
	if not r or not r.Class then
		return nil
	end
	local list = data and data.Classes or GameConfig.DefaultClasses
	for i, class in list do
		if class.Name == r.Class then
			return i
		end
	end
	for i, class in GameConfig.DefaultClasses do
		if class.Name == r.Class then
			return i
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- Pintar
---------------------------------------------------------------------------

local function renderPreview()
	local data = ClientState.Data
	local key = selected .. "/" .. tostring(data and data.Primary)
	if key == shownKey then
		return
	end
	shownKey = key
	local model = preview:SetCharacter("me", player)
	if model then
		pcall(Outfits.Remove, model)
		if selected ~= "Default" then
			pcall(Outfits.Apply, model, selected)
		end
		if data then
			preview:SetWeapon("me", data.Primary, Menu.SkinFor and Menu.SkinFor(data, data.Primary) or nil, data.EquippedCharm)
		end
		preview:SetAnimation("me", "OperatorIdle")
	end
end

local function renderStrip()
	local data = ClientState.Data
	for _, child in strip:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i, id in idsFor(role) do
		local outfit = Outfits.Get(id)
		local owned = id == "Default" or (data and data.Outfits and data.Outfits[id] == true)
		local equipped = data and data.EquippedOutfit == id or (id == "Default" and not (data and data.EquippedOutfit))
		local card = C.button({ Name = "O_" .. id, Text = "", Style = "Menu", Size = UDim2.fromOffset(150, 74), Order = i, Parent = strip, OnClick = function()
			Operator.Select(id)
		end })
		C.new("Frame", { Name = "Rarity", BackgroundColor3 = rarityColor(outfit.Rarity), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 4), ZIndex = 5, Parent = card })
		local isSelected = id == selected
		C.text({ Name = "OutfitName", Text = C.upper(outfit.Name), Role = "TitleItalic", TextSize = 17, Color = isSelected and DARK or Colors.White, Scaled = true, Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 22), ZIndex = 5, Parent = card })
		C.text({ Name = "Role", Text = C.upper(id == "Default" and "TU AVATAR" or roleOf(id).Text), Role = "Title", TextSize = 12, Color = isSelected and Color3.fromRGB(60, 46, 6) or Colors.TextDim, Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 16), ZIndex = 5, Parent = card })
		local state = equipped and "✔ EQUIPADO" or (owned and "TUYO" or (outfit.Event and "EVENTO" or "🔒"))
		C.text({ Name = "State", Text = state, Role = "Title", TextSize = 12, Color = equipped and Colors.Green or (isSelected and Color3.fromRGB(60, 46, 6) or Colors.TextFaint), Position = UDim2.fromOffset(10, 48), Size = UDim2.new(1, -20, 0, 16), ZIndex = 5, Parent = card })
		C.setSelected(card, isSelected)
	end
end

local function renderInfo()
	local data = ClientState.Data
	local outfit = Outfits.Get(selected)
	local r = if selected == "Default" then nil else roleOf(selected)
	rarityTag.BackgroundColor3 = rarityColor(outfit.Rarity)
	rarityLabel.Text = C.upper(outfit.Rarity or "")
	nameLabel.Text = C.upper(selected == "Default" and (player.DisplayName or "Tu avatar") or outfit.Name)
	roleLabel.Text = selected == "Default" and "SIN TRAJE · TU AVATAR DE ROBLOX" or (C.upper(r.Text) .. "  ·  " .. C.upper(outfit.Class or ""))
	styleLabel.Text = (r and r.Style or "Juega con tu avatar tal cual.") .. "\nSolo estética: no cambia vida, daño ni velocidad."
	-- Clase que le va
	local classIndex = classFor(r)
	classButton.Visible = classIndex ~= nil
	if classIndex then
		local list = data and data.Classes or GameConfig.DefaultClasses
		local class = list[classIndex]
		local weapon = class and Weapons.Get(class.Primary)
		classLabel.Text = string.format("USAR CLASE %s  ·  %s", tostring(class and class.Name or classIndex), weapon and C.upper(weapon.DisplayName) or "")
		local active = data and data.ActiveClass == classIndex
		classButton.BackgroundTransparency = active and 0.6 or 0.25
		if active then
			classLabel.Text = "✔ CLASE " .. tostring(class and class.Name or classIndex) .. " EN USO"
		end
	end
	-- Acción
	local owned = selected == "Default" or (data and data.Outfits and data.Outfits[selected] == true)
	local equipped = data and data.EquippedOutfit == selected
	local price, onSale = Shop.GetPrice("Outfit", selected)
	local yellow = false
	if equipped then
		actionLabel.Text = "EQUIPADO"
		actionLabel.TextColor3 = Colors.Green
	elseif owned then
		actionLabel.Text = "EQUIPAR"
		yellow = true
	elseif price then
		actionLabel.Text = string.format("%sCOMPRAR  🪙 %d", onSale and "🔥 " or "", price)
		yellow = data ~= nil and (data.Coins or 0) >= price
		actionLabel.TextColor3 = yellow and DARK or Colors.TextDim
	else
		actionLabel.Text = C.upper(outfit.Event or "PASE DE BATALLA")
		actionLabel.TextColor3 = Colors.TextDim
	end
	actionButton.BackgroundColor3 = yellow and Colors.Yellow or Colors.PanelLight
	if yellow then
		actionLabel.TextColor3 = DARK
	end
	local gradient = actionButton:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Enabled = yellow
	end
end

function Operator.Render()
	if not screen then
		return
	end
	for id, button in tabs do
		C.setSelected(button, id == role)
	end
	renderStrip()
	renderInfo()
	renderPreview()
end

---------------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------------

function Operator.Select(id)
	if selected == id then
		return
	end
	selected = id
	Operator.Render()
	Transition.Pop(preview.Viewport, 0.96, 0.2)
end

function Operator.SelectRole(id)
	if role == id then
		return
	end
	role = id
	local ids = idsFor(id)
	if not table.find(ids, selected) then
		selected = ids[1] or "Default"
	end
	Operator.Render()
end

local busy = false
local function act()
	local data = ClientState.Data
	if busy or not data then
		return
	end
	local owned = selected == "Default" or (data.Outfits and data.Outfits[selected] == true)
	if data.EquippedOutfit == selected then
		return
	end
	if owned then
		UISound.Play("Equip")
		pcall(function()
			Remotes.EquipOutfit:FireServer(selected)
		end)
		return
	end
	local price = Shop.GetPrice("Outfit", selected)
	if not price then
		UISound.Play("Error")
		return
	end
	busy = true
	local ok, result, message = pcall(function()
		return Remotes.BuyItem:InvokeServer("Outfit", selected)
	end)
	busy = false
	if ok and result then
		UISound.Play("Reward")
		Transition.Flash(Colors.Yellow, 0.25, 0.3)
	else
		UISound.Play("Error")
		actionLabel.Text = C.upper(tostring(ok and (message or "No se pudo comprar") or "Error de conexión"))
	end
end

---------------------------------------------------------------------------
-- Pantalla
---------------------------------------------------------------------------

function Operator.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "Operator", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	-- Personaje (detrás de todo)
	preview = Preview.new(screen, { Name = "OperatorPreview", Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -100), Size = UDim2.new(0, 500, 1, -190), Camera = "Hero" })
	local dragging, lastX = false, 0
	preview.Viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, lastX = true, input.Position.X
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and screen.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			preview:Turn("me", (input.Position.X - lastX) * 0.012)
			lastX = input.Position.X
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	-- Cabecera y roles
	C.button({ Name = "Back", Text = "VOLVER", Icon = "◀", Style = "Ghost", TextSize = 16, Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(130, 40), Parent = screen, Sound = "Back", OnClick = function()
		flow.SetState("Home")
	end })
	titleLabel = C.text({ Text = "OPERADOR", Role = "TitleItalic", TextSize = 46, Position = UDim2.fromOffset(170, 14), Size = UDim2.fromOffset(420, 54), Stroke = 2, Parent = screen })
	tabsRow = C.new("Frame", { Name = "Roles", BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 76), Size = UDim2.new(1, -48, 0, 40), Parent = screen }, {
		C.list(6, Enum.FillDirection.Horizontal),
	})
	for i, r in ROLES do
		tabs[r.Id] = C.button({ Name = "Role_" .. r.Id, Text = r.Text, Style = "Menu", TextSize = 15, Size = UDim2.fromOffset(r.Id == "SNIPER" and 160 or 116, 40), Order = i, Parent = tabsRow, OnClick = function()
			Operator.SelectRole(r.Id)
		end })
	end
	-- Ficha (izquierda)
	infoPanel = C.new("Frame", { Name = "Info", BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 136), Size = UDim2.fromOffset(380, 330), Parent = screen })
	rarityTag = C.new("Frame", { BorderSizePixel = 0, Size = UDim2.fromOffset(120, 24), Parent = infoPanel }, { C.corner(3) })
	rarityLabel = C.text({ Text = "", Role = "Title", TextSize = 14, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = rarityTag })
	nameLabel = C.text({ Text = "", Role = "TitleItalic", TextSize = 56, Scaled = true, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 62), Stroke = 2, Parent = infoPanel })
	roleLabel = C.text({ Text = "", Role = "Title", TextSize = 16, Color = Colors.YellowText, Position = UDim2.fromOffset(2, 94), Size = UDim2.new(1, 0, 0, 20), Parent = infoPanel })
	styleLabel = C.text({ Text = "", Role = "Body", TextSize = 15, Color = Colors.Text, Wrap = true, AlignY = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(2, 124), Size = UDim2.new(1, 0, 0, 64), Parent = infoPanel })
	classButton = C.button({ Name = "UseClass", Text = "", Style = "Ghost", TextSize = 14, Position = UDim2.fromOffset(0, 198), Size = UDim2.new(1, 0, 0, 44), Parent = infoPanel, Sound = "Equip", OnClick = function()
		local index = classFor(roleOf(selected))
		if index then
			pcall(function()
				Remotes.SelectClass:FireServer(index)
			end)
		end
	end })
	classLabel = classButton:FindFirstChild("Label", true)
	-- Habilidades (derecha): las de todos los operadores, con sus teclas y tiempos reales
	abilityPanel = C.panel({ Name = "Abilities", Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 136), Size = UDim2.fromOffset(330, 236), Parent = screen }, {})
	local inner = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = abilityPanel }, { C.padding(12, 14, 12, 14), C.list(8) })
	C.header(inner, "HABILIDADES", "TODOS", 0)
	local abilities = GameConfig.Abilities or {}
	for i, spec in {
		{ "⚡", "IMPULSO", "E", abilities.Dash and abilities.Dash.Cooldown, "Acelerón corto en la dirección en que te mueves" },
		{ "⤒", "SUPERSALTO", "Z", abilities.Jump and abilities.Jump.Cooldown, "Salto alto hacia delante para cambiar de altura" },
		{ "✚", "POCIÓN", "X", abilities.Potion and abilities.Potion.Cooldown, "Recupera " .. tostring(abilities.Potion and abilities.Potion.Heal or 50) .. " de vida en unos segundos" },
	} do
		local row = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = i, Parent = inner })
		table.insert(abilityRows, row)
		-- (cuadrado del alto de la fila: en el teléfono las filas son más bajas)
		local key = C.new("Frame", { BackgroundColor3 = Colors.PanelLight, BorderSizePixel = 0, Size = UDim2.new(0, 44, 1, -6), Parent = row }, {
			C.corner(4),
			C.stroke(Colors.Yellow, 1, 0.5),
			C.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		})
		C.text({ Text = spec[1], Role = "Title", TextSize = 22, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = key })
		C.text({ Text = spec[2] .. "  ·  " .. spec[3], Role = "Title", TextSize = 16, Position = UDim2.fromOffset(54, 2), Size = UDim2.new(1, -110, 0, 20), Parent = row })
		C.text({ Text = spec[4] and (tostring(spec[4]) .. " s") or "", Role = "Number", TextSize = 14, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(50, 20), Parent = row })
		table.insert(abilityDescs, C.text({ Text = spec[5], Role = "Body", TextSize = 12, Color = Colors.TextDim, Wrap = true, Position = UDim2.fromOffset(54, 22), Size = UDim2.new(1, -54, 0, 28), Parent = row }))
	end
	actionButton = C.button({ Name = "Action", Text = "", Style = "Primary", TextSize = 20, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 384), Size = UDim2.fromOffset(330, 54), Parent = screen, Sound = "Click", OnClick = act })
	actionLabel = actionButton:FindFirstChild("Label", true)
	-- Tira de selección (abajo; se desplaza si hay muchos)
	local scroller = C.new("ScrollingFrame", {
		Name = "Strip",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -16),
		Size = UDim2.new(1, -48, 0, 86),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Colors.Yellow,
		Parent = screen,
	})
	strip = C.new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 78), Parent = scroller }, {
		C.list(8, Enum.FillDirection.Horizontal),
	})
	ClientState.DataChanged.Event:Connect(function()
		if screen.Visible then
			shownKey = nil
			Operator.Render()
		end
	end)
	Operator.Screen = screen
end

local function applyLayout()
	local width = flow.Root and flow.Root:GetAttribute("VirtualWidth") or 1280
	local phone = C.Breakpoint() == "PHONE"
	local narrow = phone or width < 1100
	local top = phone and 108 or 136
	titleLabel.TextSize = phone and 34 or 46
	tabsRow.Position = UDim2.fromOffset(24, phone and 58 or 76)
	for id, tab in tabs do
		tab.Size = UDim2.fromOffset(id == "SNIPER" and (phone and 140 or 160) or (phone and 100 or 116), phone and 34 or 40)
	end
	infoPanel.Position = UDim2.fromOffset(24, top)
	infoPanel.Size = UDim2.fromOffset(narrow and 300 or 380, 330)
	-- (teléfono: habilidades sin descripción, en filas bajas, para que quepa el botón encima de la tira)
	for _, row in abilityRows do
		row.Size = UDim2.new(1, 0, 0, phone and 34 or 52)
	end
	for _, desc in abilityDescs do
		desc.Visible = not phone
	end
	abilityPanel.Position = UDim2.new(1, -24, 0, top)
	abilityPanel.Size = UDim2.fromOffset(narrow and 280 or 330, phone and 160 or 236)
	actionButton.Position = UDim2.new(1, -24, 0, top + (phone and 168 or 248))
	actionButton.Size = UDim2.fromOffset(narrow and 280 or 330, phone and 44 or 54)
	preview.Viewport.Size = UDim2.new(0, narrow and 380 or 500, 1, -190)
end

function Operator.Show()
	local data = ClientState.Data
	selected = data and data.EquippedOutfit or "Default"
	role = "ALL"
	shownKey = nil
	applyLayout()
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.55, 0.25)
	Transition.Blur(14, 0.25)
	screen.Visible = true
	Operator.Render()
	preview:SetActive(true)
	Transition.Pop(preview.Viewport, 0.94, 0.3)
	Transition.SlideIn(infoPanel, Vector2.new(-50, 0), 0.3)
	Transition.SlideIn(abilityPanel, Vector2.new(50, 0), 0.3, 0.04)
end

function Operator.Hide()
	preview:SetActive(false)
	screen.Visible = false
end

return Operator
