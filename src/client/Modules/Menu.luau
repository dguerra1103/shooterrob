-- Menú del pase de batalla, skins y elección de arma principal (tecla B).
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Skins = require(Shared.Skins)
local Weapons = require(Shared.Weapons)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Menu = {}

local gui, panel, content, headerInfo
local tabButtons = {}
local currentTab = "Pase"

local GOLD = Color3.fromRGB(255, 190, 40)
local PANEL_BG = Color3.fromRGB(22, 24, 38)
local CARD_BG = Color3.fromRGB(38, 42, 64)

---------------------------------------------------------------------------
-- Tarjetas de recompensa
---------------------------------------------------------------------------

local function skinSwatch(skinId, parent, size)
	local skin = Skins.Get(skinId)
	local swatch = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = size or UDim2.fromOffset(80, 40),
		BackgroundColor3 = skin.Body,
		Parent = parent,
	}, { UI.corner(6), UI.stroke(Color3.new(0, 0, 0), 2, 0.3) })
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.45),
		Size = UDim2.new(1, 0, 0.22, 0),
		BackgroundColor3 = skin.Accent,
		BorderSizePixel = 0,
		Parent = swatch,
	})
	UI.new("Frame", {
		Position = UDim2.fromScale(0.15, 0.62),
		Size = UDim2.fromScale(0.18, 0.5),
		BackgroundColor3 = skin.Dark,
		BorderSizePixel = 0,
		Parent = swatch,
	})
	return swatch
end

local function rewardCard(reward, unlocked, premium, parent, order)
	local card = UI.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(110, 110),
		BackgroundColor3 = CARD_BG,
		Parent = parent,
	}, { UI.corner(10), UI.stroke(premium and GOLD or Color3.fromRGB(90, 100, 140), 2, 0) })

	if not reward then
		UI.label({ Size = UDim2.fromScale(1, 1), Text = "—", TextSize = 30, TextTransparency = 0.5, Parent = card })
	elseif reward.Type == "Skin" then
		local skin = Skins.Get(reward.Id)
		skinSwatch(reward.Id, card)
		UI.label({
			Position = UDim2.fromOffset(0, 52),
			Size = UDim2.new(1, 0, 0, 22),
			Text = skin.Name,
			TextSize = 17,
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(0, 74),
			Size = UDim2.new(1, 0, 0, 18),
			Text = skin.Rarity,
			TextSize = 14,
			TextColor3 = Skins.RarityColors[skin.Rarity] or Color3.new(1, 1, 1),
			Parent = card,
		})
	else
		UI.label({
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, 0, 0, 40),
			Text = "🪙",
			TextSize = 34,
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(0, 62),
			Size = UDim2.new(1, 0, 0, 24),
			Text = tostring(reward.Amount),
			TextSize = 20,
			TextColor3 = GOLD,
			Parent = card,
		})
	end

	if reward then
		local status = UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 2),
			Size = UDim2.fromOffset(24, 24),
			Text = unlocked and "✔" or "🔒",
			TextSize = 18,
			TextColor3 = unlocked and Color3.fromRGB(90, 230, 110) or Color3.new(1, 1, 1),
			ZIndex = 3,
			Parent = card,
		})
		if not unlocked then
			UI.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.5,
				ZIndex = 2,
				Parent = card,
			}, { UI.corner(10) })
		end
		return card, status
	end
	return card
end

---------------------------------------------------------------------------
-- Páginas
---------------------------------------------------------------------------

local function buildPassPage(data)
	local page = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })

	-- Progreso
	local per = data.XPPerLevel or GameConfig.XPPerLevel
	UI.label({
		Size = UDim2.fromOffset(400, 26),
		Text = "Nivel " .. data.Level .. "  ·  " .. data.XP .. " / " .. per .. " XP",
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = page,
	})
	local bar = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.fromOffset(400, 12),
		BackgroundColor3 = Color3.fromRGB(10, 10, 15),
		Parent = page,
	}, { UI.corner(6) })
	UI.new("Frame", {
		Size = UDim2.fromScale(math.clamp(data.XP / per, 0, 1), 1),
		BackgroundColor3 = Color3.fromRGB(80, 170, 255),
		Parent = bar,
	}, { UI.corner(6) })

	-- Premium
	if data.Premium then
		UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 4),
			Size = UDim2.fromOffset(240, 34),
			Text = "👑 PREMIUM ACTIVO",
			TextSize = 22,
			TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = page,
		})
	else
		local buy = UI.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 2),
			Size = UDim2.fromOffset(240, 40),
			Text = "👑 Obtener Premium",
			BackgroundColor3 = GOLD,
			TextColor3 = Color3.fromRGB(40, 25, 0),
			Parent = page,
		})
		buy.Activated:Connect(function()
			if GameConfig.PremiumPassId == 0 then
				buy.Text = "Configura PremiumPassId"
				return
			end
			MarketplaceService:PromptGamePassPurchase(player, GameConfig.PremiumPassId)
		end)
	end

	-- Filas de etiquetas
	UI.label({
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.fromOffset(70, 110),
		Text = "GRATIS",
		TextSize = 16,
		Parent = page,
	})
	UI.label({
		Position = UDim2.fromOffset(0, 210),
		Size = UDim2.fromOffset(70, 110),
		Text = "PREMIUM",
		TextSize = 16,
		TextColor3 = GOLD,
		Parent = page,
	})

	local scroll = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(74, 56),
		Size = UDim2.new(1, -74, 1, -56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		Parent = page,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	for tier, rewards in GameConfig.BattlePass do
		local reached = data.Level >= tier
		local column = UI.new("Frame", {
			LayoutOrder = tier,
			Size = UDim2.fromOffset(110, 270),
			BackgroundTransparency = 1,
			Parent = scroll,
		}, {
			UI.new("UIListLayout", {
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		UI.label({
			LayoutOrder = 0,
			Size = UDim2.fromOffset(110, 26),
			Text = "NIVEL " .. tier,
			TextSize = 18,
			TextColor3 = reached and Color3.fromRGB(90, 230, 110) or Color3.fromRGB(180, 180, 190),
			Parent = column,
		})
		rewardCard(rewards.Free, reached, false, column, 1)
		rewardCard(rewards.Premium, reached and data.Premium, true, column, 2)
	end
end

local function buildSkinsPage(data)
	local scroll = UI.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		Parent = content,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(165, 150),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local order = { "Común", "Raro", "Épico", "Legendario", "Mítico" }
	local ids = {}
	for id in Skins.List do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		local ra = table.find(order, Skins.List[a].Rarity) or 0
		local rb = table.find(order, Skins.List[b].Rarity) or 0
		if ra == rb then
			return Skins.List[a].Name < Skins.List[b].Name
		end
		return ra < rb
	end)

	for i, id in ids do
		local skin = Skins.List[id]
		local owned = data.Skins[id] == true
		local equipped = data.EquippedSkin == id
		local card = UI.new("Frame", {
			LayoutOrder = i,
			BackgroundColor3 = CARD_BG,
			Parent = scroll,
		}, {
			UI.corner(10),
			UI.stroke(equipped and GOLD or (Skins.RarityColors[skin.Rarity] or Color3.new(1, 1, 1)), 2, equipped and 0 or 0.4),
		})
		skinSwatch(id, card, UDim2.fromOffset(120, 46))
		UI.label({
			Position = UDim2.fromOffset(0, 58),
			Size = UDim2.new(1, 0, 0, 22),
			Text = skin.Name,
			TextSize = 19,
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(0, 80),
			Size = UDim2.new(1, 0, 0, 16),
			Text = skin.Rarity,
			TextSize = 14,
			TextColor3 = Skins.RarityColors[skin.Rarity] or Color3.new(1, 1, 1),
			Parent = card,
		})
		local button = UI.button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0, 30),
			TextSize = 16,
			Text = equipped and "Equipada" or (owned and "Equipar" or "🔒 Pase de batalla"),
			BackgroundColor3 = equipped and Color3.fromRGB(60, 160, 80)
				or (owned and Color3.fromRGB(40, 120, 255) or Color3.fromRGB(70, 70, 80)),
			AutoButtonColor = owned and not equipped,
			Parent = card,
		})
		if owned and not equipped then
			button.Activated:Connect(function()
				Sounds.Play("Click")
				Remotes.EquipSkin:FireServer(id)
			end)
		end
	end
end

local function buildWeaponsPage(data)
	local holder = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = content,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, weaponName in Weapons.Primaries do
		local def = Weapons.Get(weaponName)
		local selected = data.Primary == weaponName
		local card = UI.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.fromOffset(220, 300),
			BackgroundColor3 = CARD_BG,
			Parent = holder,
		}, { UI.corner(12), UI.stroke(selected and GOLD or Color3.fromRGB(90, 100, 140), 2, 0) })
		UI.label({
			Position = UDim2.fromOffset(0, 12),
			Size = UDim2.new(1, 0, 0, 30),
			Text = def.DisplayName,
			TextSize = 26,
			Parent = card,
		})
		local stats = {
			{ "Daño", def.Pellets > 1 and (def.Damage .. " x" .. def.Pellets) or tostring(def.Damage) },
			{ "Cadencia", string.format("%.1f/s", def.FireRate) },
			{ "Cargador", tostring(def.MagSize) },
			{ "Recarga", string.format("%.1fs", def.ReloadTime) },
			{ "Alcance", tostring(def.Range) },
		}
		for j, stat in stats do
			UI.label({
				Position = UDim2.fromOffset(18, 52 + (j - 1) * 30),
				Size = UDim2.new(1, -36, 0, 26),
				Text = stat[1],
				TextSize = 18,
				TextColor3 = Color3.fromRGB(180, 185, 210),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			UI.label({
				Position = UDim2.fromOffset(18, 52 + (j - 1) * 30),
				Size = UDim2.new(1, -36, 0, 26),
				Text = stat[2],
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = card,
			})
		end
		local button = UI.button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14),
			Size = UDim2.new(1, -30, 0, 40),
			Text = selected and "Elegida" or "Elegir",
			BackgroundColor3 = selected and Color3.fromRGB(60, 160, 80) or Color3.fromRGB(40, 120, 255),
			Parent = card,
		})
		if not selected then
			button.Activated:Connect(function()
				Sounds.Play("Click")
				Remotes.SetPrimary:FireServer(weaponName)
			end)
		end
	end
	UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "Secundaria: " .. Weapons.Get(Weapons.Secondary).DisplayName .. "  ·  Cuerpo a cuerpo: " .. Weapons.Get(
			Weapons.Melee
		).DisplayName,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(180, 185, 210),
		Parent = holder.Parent,
	})
end

---------------------------------------------------------------------------

local function refresh()
	if not content then
		return
	end
	for _, child in content:GetChildren() do
		child:Destroy()
	end
	local data = ClientState.Data
	if headerInfo then
		headerInfo.Text = data and ("Nivel " .. data.Level .. "   🪙 " .. data.Coins) or "Cargando..."
	end
	for name, button in tabButtons do
		button.BackgroundColor3 = name == currentTab and Color3.fromRGB(40, 120, 255) or CARD_BG
	end
	if not data then
		UI.label({ Size = UDim2.fromScale(1, 1), Text = "Cargando datos...", TextSize = 24, Parent = content })
		return
	end
	if currentTab == "Pase" then
		buildPassPage(data)
	elseif currentTab == "Skins" then
		buildSkinsPage(data)
	else
		buildWeaponsPage(data)
	end
end

local function setOpen(open)
	ClientState.MenuOpen = open
	panel.Visible = open
	UserInputService.MouseIconEnabled = open
	if open then
		refresh()
	end
end

function Menu.Toggle()
	setOpen(not panel.Visible)
end

function Menu.Init()
	gui = UI.new("ScreenGui", {
		Name = "Menu",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- Botón superior (útil en móvil)
	local open = UI.button({
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(210, 38),
		Text = "⭐ PASE DE BATALLA",
		BackgroundColor3 = Color3.fromRGB(255, 120, 30),
		TextSize = 18,
		Parent = gui,
	}, { UI.stroke(Color3.new(0, 0, 0), 2, 0.3) })
	open.Activated:Connect(Menu.Toggle)

	panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(800, 480),
		BackgroundColor3 = PANEL_BG,
		Visible = false,
		Parent = gui,
	}, { UI.corner(16), UI.stroke(Color3.fromRGB(255, 140, 40), 3, 0), UI.padding(16) })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(800, 480) }).Parent = panel

	-- Un botón "Modal" libera el ratón en primera persona mientras el menú está abierto
	UI.new("TextButton", {
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Modal = true,
		Parent = panel,
	})

	UI.label({
		Size = UDim2.fromOffset(400, 36),
		Text = "🎃 PASE DE BATALLA",
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 160, 50),
		Parent = panel,
	})
	headerInfo = UI.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.fromOffset(300, 36),
		Text = "",
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	local close = UI.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(36, 36),
		Text = "✕",
		BackgroundColor3 = Color3.fromRGB(220, 60, 60),
		Parent = panel,
	})
	close.Activated:Connect(function()
		setOpen(false)
	end)

	local tabs = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, name in { "Pase", "Skins", "Armas" } do
		local button = UI.button({
			LayoutOrder = i,
			Size = UDim2.fromOffset(130, 36),
			Text = name,
			BackgroundColor3 = CARD_BG,
			Parent = tabs,
		})
		button.Activated:Connect(function()
			currentTab = name
			Sounds.Play("Click")
			refresh()
		end)
		tabButtons[name] = button
	end

	content = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 94),
		Size = UDim2.new(1, 0, 1, -94),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	ContextActionService:BindAction("Menu", function(_, state)
		if state == Enum.UserInputState.Begin then
			Menu.Toggle()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.B, Enum.KeyCode.ButtonSelect)

	ClientState.DataChanged.Event:Connect(function()
		if panel.Visible then
			refresh()
		end
	end)
end

return Menu
