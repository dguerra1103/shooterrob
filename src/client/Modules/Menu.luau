-- Menú principal del jugador (tecla B): perfil, pase de batalla, retos, armas, skins, trajes, efectos y tienda.
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Skins = require(Shared.Skins)
local Weapons = require(Shared.Weapons)
local Outfits = require(Shared.Outfits)
local Shop = require(Shared.Shop)
local Mastery = require(Shared.Mastery)
local KillEffects = require(Shared.KillEffects)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)
local Ranks = require(Shared.Ranks)
local Charms = require(Shared.Charms)
local Sprays = require(Shared.Sprays)
local Titles = require(Shared.Titles)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)
local WeaponIcon = require(script.Parent.WeaponIcon)
local Effects = require(script.Parent.Effects)
local Settings = require(script.Parent.Settings)

local player = Players.LocalPlayer

local Menu = {}

local gui, panel, content, headerInfo, toast
local tabButtons = {}
local currentTab = "Pase"
local busy = false
local refresh -- reconstruye la pestaña actual (definida más abajo)

local GOLD = Color3.fromRGB(255, 190, 40)
local PANEL_BG = Color3.fromRGB(22, 24, 38)
local CARD_BG = Color3.fromRGB(38, 42, 64)
local GREEN = Color3.fromRGB(60, 170, 90)
local BLUE = Color3.fromRGB(40, 120, 255)
local GREY = Color3.fromRGB(70, 70, 82)

local TABS = { "Perfil", "Pase", "Retos", "Armas", "Skins", "Trajes", "Efectos", "Tienda", "Ajustes" }

local function rarityColor(rarity)
	return Skins.RarityColors[rarity] or Color3.new(1, 1, 1)
end

local function showToast(text, color)
	if not toast then
		return
	end
	toast.Text = text
	toast.TextColor3 = color or Color3.new(1, 1, 1)
	toast.Visible = true
	local token = {}
	toast:SetAttribute("T", tostring(token))
	task.delay(2.5, function()
		if toast:GetAttribute("T") == tostring(token) then
			toast.Visible = false
		end
	end)
end

local function coinsText(n)
	return "🪙 " .. tostring(n)
end

-- Skin con la que se ve un arma (camuflaje de maestría elegido o skin general)
local function skinFor(data, weaponName)
	local camo = data.WeaponCamos and data.WeaponCamos[weaponName]
	if camo and Mastery.HasCamo(data.WeaponKills and data.WeaponKills[weaponName] or 0, camo) then
		return camo
	end
	return data.EquippedSkin
end
Menu.SkinFor = skinFor

-- Barra de progreso sencilla
local function progressBar(parent, position, size, fraction, color)
	local bar = UI.new("Frame", {
		Position = position,
		Size = size,
		BackgroundColor3 = Color3.fromRGB(20, 22, 34),
		Parent = parent,
	}, { UI.corner(6) })
	UI.new("Frame", {
		Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1),
		BackgroundColor3 = color,
		Parent = bar,
	}, { UI.corner(6), UI.gloss() })
	return bar
end

local function scroller(layout)
	return UI.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		Parent = content,
	}, { layout })
end

local function buy(kind, id)
	if busy then
		return
	end
	busy = true
	Sounds.Play("Click")
	local ok, result, message = pcall(function()
		return Remotes.BuyItem:InvokeServer(kind, id)
	end)
	busy = false
	if ok and result then
		Sounds.Play("Kill")
		showToast(message or "¡Comprado!", GOLD)
	else
		showToast(ok and (message or "No se pudo comprar") or "Error de conexión", Color3.fromRGB(255, 90, 90))
	end
end

-- Maniquí R15 sencillo para previsualizar trajes
local function mannequin(outfitId)
	local model = Instance.new("Model")
	local skin = Color3.fromRGB(255, 204, 153)
	local legs = Color3.fromRGB(60, 60, 70)
	local torso = Color3.fromRGB(90, 120, 200)
	local parts = {
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
	}
	for _, spec in parts do
		local p = Instance.new("Part")
		p.Name = spec[1]
		p.Size = spec[2]
		p.CFrame = CFrame.new(spec[3], spec[4], 0)
		p.Color = spec[5]
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
	end
	local face = Instance.new("Part")
	face.Size = Vector3.new(0.6, 0.12, 0.05)
	face.CFrame = CFrame.new(0, 5.35, -0.62)
	face.Color = Color3.fromRGB(25, 25, 25)
	face.Anchored = true
	face.Parent = model
	Outfits.Apply(model, outfitId)
	return model
end

local function outfitViewport(outfitId, props)
	local viewport = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 185),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1.5, 1),
	})
	for k, v in props do
		viewport[k] = v
	end
	local model = mannequin(outfitId)
	model.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(5, 4.6, -12), Vector3.new(0, 3, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport
end

---------------------------------------------------------------------------
-- Pestaña: Pase de batalla
---------------------------------------------------------------------------

local function rewardCard(reward, unlocked, premium, parent, order)
	local card = UI.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(120, 116),
		BackgroundColor3 = CARD_BG,
		Parent = parent,
	}, { UI.corner(10), UI.stroke(premium and GOLD or Color3.fromRGB(90, 100, 140), 2, 0) })

	if not reward then
		UI.label({ Size = UDim2.fromScale(1, 1), Text = "—", TextSize = 30, TextTransparency = 0.5, Parent = card })
	elseif reward.Type == "Skin" then
		local skin = Skins.Get(reward.Id)
		WeaponIcon.Create(
			ClientState.Data and ClientState.Data.Primary or "ARX27",
			reward.Id,
			{ Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(112, 52), Parent = card },
			"angled",
			112 / 52
		)
		UI.label({ Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 22), Text = skin.Name, TextSize = 17, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 80),
			Size = UDim2.new(1, 0, 0, 18),
			Text = skin.Rarity,
			TextSize = 14,
			TextColor3 = rarityColor(skin.Rarity),
			Parent = card,
		})
	elseif reward.Type == "Outfit" then
		local outfit = Outfits.Get(reward.Id)
		outfitViewport(reward.Id, { Position = UDim2.fromOffset(20, 2), Size = UDim2.fromOffset(80, 70), Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 0, 20), Text = outfit.Name, TextSize = 15, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 94),
			Size = UDim2.new(1, 0, 0, 16),
			Text = outfit.Rarity,
			TextSize = 13,
			TextColor3 = rarityColor(outfit.Rarity),
			Parent = card,
		})
	elseif reward.Type == "KillEffect" then
		local effect = KillEffects.Get(reward.Id)
		UI.label({ Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 44), Text = effect.Icon, TextSize = 38, Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 22), Text = effect.Name, TextSize = 16, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 84),
			Size = UDim2.new(1, 0, 0, 16),
			Text = "Efecto · " .. effect.Rarity,
			TextSize = 13,
			TextColor3 = rarityColor(effect.Rarity),
			Parent = card,
		})
	elseif reward.Type == "Crate" then
		UI.label({ Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 40), Text = "🎁", TextSize = 36, Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 24), Text = "Caja", TextSize = 18, Parent = card })
	else
		UI.label({ Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 40), Text = "🪙", TextSize = 34, Parent = card })
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
		UI.label({
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
	end
	return card
end

local function buildPassPage(data)
	local page = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	local per = data.XPPerLevel or GameConfig.XPPerLevel
	UI.label({
		Size = UDim2.fromOffset(420, 26),
		Text = "Nivel " .. data.Level .. "  ·  " .. data.XP .. " / " .. per .. " XP",
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = page,
	})
	local bar = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.fromOffset(420, 12),
		BackgroundColor3 = Color3.fromRGB(10, 10, 15),
		Parent = page,
	}, { UI.corner(6) })
	UI.new("Frame", {
		Size = UDim2.fromScale(math.clamp(data.XP / per, 0, 1), 1),
		BackgroundColor3 = Color3.fromRGB(80, 170, 255),
		Parent = bar,
	}, { UI.corner(6), UI.gloss() })

	if data.Premium then
		UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 4),
			Size = UDim2.fromOffset(260, 34),
			Text = "👑 PREMIUM ACTIVO",
			TextSize = 22,
			TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = page,
		})
	else
		local buyPass = UI.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 2),
			Size = UDim2.fromOffset(260, 40),
			Text = "👑 Obtener Premium",
			BackgroundColor3 = GOLD,
			TextColor3 = Color3.fromRGB(40, 25, 0),
			Parent = page,
		}, { UI.gloss() })
		buyPass.Activated:Connect(function()
			if GameConfig.PremiumPassId == 0 then
				showToast("Próximamente")
				return
			end
			MarketplaceService:PromptGamePassPurchase(player, GameConfig.PremiumPassId)
		end)
	end

	UI.label({ Position = UDim2.fromOffset(0, 98), Size = UDim2.fromOffset(70, 116), Text = "GRATIS", TextSize = 16, Parent = page })
	UI.label({
		Position = UDim2.fromOffset(0, 222),
		Size = UDim2.fromOffset(70, 116),
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
	-- Solo se dibujan los niveles cercanos al tuyo (cada premio lleva un modelo 3D: con 50 a la vez el
	-- menú iría lento)
	-- (al final del pase la ventana se queda en los últimos niveles: si no, quedaría vacía)
	local first = math.max(1, math.min(data.Level - 2, #GameConfig.BattlePass - 14))
	local last = math.min(#GameConfig.BattlePass, first + 14)
	for tier = first, last do
		local rewards = GameConfig.BattlePass[tier]
		local reached = data.Level >= tier
		local column = UI.new("Frame", {
			LayoutOrder = tier,
			Size = UDim2.fromOffset(120, 280),
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
			Size = UDim2.fromOffset(120, 26),
			Text = "NIVEL " .. tier,
			TextSize = 18,
			TextColor3 = reached and Color3.fromRGB(90, 230, 110) or Color3.fromRGB(180, 180, 190),
			Parent = column,
		})
		rewardCard(rewards.Free, reached, false, column, 1)
		rewardCard(rewards.Premium, reached and data.Premium, true, column, 2)
	end
	if last < #GameConfig.BattlePass then
		UI.label({
			LayoutOrder = last + 1,
			Size = UDim2.fromOffset(120, 280),
			Text = "… y " .. (#GameConfig.BattlePass - last) .. " niveles más\n(hasta el " .. #GameConfig.BattlePass .. ")",
			TextSize = 16,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(190, 195, 220),
			Parent = scroll,
		})
	end
end

---------------------------------------------------------------------------
-- Pestaña: Retos diarios
---------------------------------------------------------------------------

-- Logros: para cada estadística, el siguiente sin reclamar (o nil si ya están todos)
local function nextAchievements(data)
	local list, seen = {}, {}
	for _, achievement in GameConfig.Achievements do
		if not seen[achievement.Stat] and not (data.Achievements or {})[achievement.Id] then
			seen[achievement.Stat] = true
			table.insert(list, achievement)
		end
	end
	return list
end

-- ¿Cuántos logros se pueden reclamar ya? (aviso en la pestaña Perfil)
local function claimableAchievements(data)
	local count = 0
	for _, achievement in GameConfig.Achievements do
		if not (data.Achievements or {})[achievement.Id] and (tonumber(data[achievement.Stat]) or 0) >= achievement.Goal then
			count += 1
		end
	end
	return count
end

-- Perfil: rango, nivel, estadísticas de siempre, arma favorita y colección
local function buildProfilePage(data)
	local scroll = scroller(UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }))
	-- Rango y nivel
	local points = data.RankPoints or 0
	local tier = Ranks.Get(points)
	local fraction, nextTier = Ranks.Progress(points)
	local top = UI.new("Frame", { LayoutOrder = 1, Size = UDim2.new(1, -12, 0, 120), BackgroundColor3 = CARD_BG, Parent = scroll }, {
		UI.corner(12),
		UI.stroke(tier.Color, 2, 0.2),
	})
	UI.label({ Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(100, 100), Text = tier.Icon, TextSize = 72, Parent = top })
	UI.label({
		Position = UDim2.fromOffset(120, 12),
		Size = UDim2.new(1, -140, 0, 34),
		Text = string.upper(tier.Name) .. "   ·   " .. points .. " RP",
		TextSize = 30,
		TextColor3 = tier.Color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})
	progressBar(top, UDim2.fromOffset(120, 54), UDim2.new(1, -140, 0, 16), fraction, tier.Color)
	local nextText = "¡Rango máximo!"
	if nextTier then
		nextText = string.format("Faltan %d RP para %s %s", nextTier.Min - points, nextTier.Icon, nextTier.Name)
	end
	UI.label({
		Position = UDim2.fromOffset(120, 78),
		Size = UDim2.new(1, -140, 0, 26),
		Text = nextText .. "     ·     Nivel " .. data.Level .. (data.VIP and "  👑 VIP" or ""),
		TextSize = 18,
		TextColor3 = Color3.fromRGB(200, 205, 225),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})

	-- Estadísticas
	local kills, deaths = data.TotalKills or 0, data.TotalDeaths or 0
	local matches, wins = data.Matches or 0, data.Wins or 0
	local stats = {
		{ "🎯", "Bajas", tostring(kills) },
		{ "💀", "Muertes", tostring(deaths) },
		{ "⚖", "K/D", string.format("%.2f", kills / math.max(1, deaths)) },
		{ "🏆", "Victorias", tostring(wins) },
		{ "🎮", "Partidas", tostring(matches) },
		{ "📈", "% victorias", matches > 0 and (math.floor(wins / matches * 100 + 0.5) .. "%") or "-" },
		{ "🔥", "Mejor racha", tostring(data.BestStreak or 0) },
		{ "🧠", "A la cabeza", tostring(data.Headshots or 0) },
		{ "🤝", "Asistencias", tostring(data.Assists or 0) },
		(function()
			-- (del evento en marcha; fuera de temporada, genérico)
			local event = GameConfig.CurrentEvent()
			local items = event and event.Items or "evento"
			return { event and event.ItemIcon or "🎉", string.upper(string.sub(items, 1, 1)) .. string.sub(items, 2), tostring(data.EventCandy or 0) }
		end)(),
	}
	local grid = UI.new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, -12, 0, 170), BackgroundTransparency = 1, Parent = scroll }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.2, -10, 0, 80), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, stat in stats do
		local cell = UI.new("Frame", { LayoutOrder = i, BackgroundColor3 = CARD_BG, Parent = grid }, { UI.corner(10) })
		UI.label({ Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 36), Text = stat[1] .. " " .. stat[3], TextSize = 28, Parent = cell })
		UI.label({ Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 22), Text = stat[2], TextSize = 16, TextColor3 = Color3.fromRGB(170, 180, 215), Parent = cell })
	end

	-- Arma favorita (la de más bajas) y colección
	local favorite, favoriteKills = nil, 0
	for name, count in data.WeaponKills or {} do
		local def = Weapons.Get(name)
		if def and not def.Hidden and type(count) == "number" and count > favoriteKills then
			favorite, favoriteKills = name, count
		end
	end
	local bottom = UI.new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, -12, 0, 130), BackgroundTransparency = 1, Parent = scroll })
	local favCard = UI.new("Frame", { Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = CARD_BG, Parent = bottom }, { UI.corner(12) })
	UI.label({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 24), Text = "⭐ ARMA FAVORITA", TextSize = 18, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Parent = favCard })
	if favorite then
		WeaponIcon.Create(favorite, skinFor(data, favorite), { Position = UDim2.fromOffset(10, 34), Size = UDim2.new(0.55, 0, 0, 86), Parent = favCard }, "angled", 2.2)
		UI.label({
			Position = UDim2.new(0.58, 0, 0, 44),
			Size = UDim2.new(0.42, -12, 0, 60),
			Text = Weapons.Get(favorite).DisplayName .. "\n" .. favoriteKills .. " bajas",
			TextSize = 20,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = favCard,
		})
	else
		UI.label({ Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -28, 0, 40), Text = "¡Haz alguna baja para descubrirla!", TextSize = 18, Parent = favCard })
	end
	local function count(owned, list, skip)
		local have, total = 0, 0
		for id, item in list do
			if id ~= "Default" and not (skip and skip(item)) then
				total += 1
				if owned and owned[id] then
					have += 1
				end
			end
		end
		return have, total
	end
	local skinsHave, skinsTotal = count(data.Skins, Skins.List, function(skin)
		return skin.Mastery == true
	end)
	local outfitsHave, outfitsTotal = count(data.Outfits, Outfits.List)
	local effectsHave, effectsTotal = count(data.KillEffects, KillEffects.List)
	local collection = UI.new("Frame", { Position = UDim2.new(0.5, 5, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = CARD_BG, Parent = bottom }, { UI.corner(12) })
	UI.label({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 24), Text = "🎒 COLECCIÓN", TextSize = 18, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Parent = collection })
	for i, row in { { "🎨 Skins", skinsHave, skinsTotal }, { "🦺 Trajes", outfitsHave, outfitsTotal }, { "💥 Efectos", effectsHave, effectsTotal } } do
		local y = 36 + (i - 1) * 30
		UI.label({ Position = UDim2.fromOffset(14, y), Size = UDim2.fromOffset(110, 22), Text = row[1], TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = collection })
		progressBar(collection, UDim2.fromOffset(124, y + 5), UDim2.new(1, -210, 0, 12), row[2] / math.max(1, row[3]), BLUE)
		UI.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, y), Size = UDim2.fromOffset(70, 22), Text = row[2] .. "/" .. row[3], TextSize = 16, TextXAlignment = Enum.TextXAlignment.Right, Parent = collection })
	end

	-- Logros (el siguiente de cada tipo)
	local claimedCount = 0
	for _ in data.Achievements or {} do
		claimedCount += 1
	end
	UI.label({
		LayoutOrder = 4,
		Size = UDim2.new(1, -12, 0, 30),
		Text = "🏅 LOGROS  ·  " .. claimedCount .. "/" .. #GameConfig.Achievements,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GOLD,
		Parent = scroll,
	})
	local pending = nextAchievements(data)
	if #pending == 0 then
		UI.label({ LayoutOrder = 5, Size = UDim2.new(1, -12, 0, 40), Text = "¡Los tienes todos! 👑", TextSize = 20, Parent = scroll })
	end
	for i, achievement in pending do
		local value = tonumber(data[achievement.Stat]) or 0
		local ready = value >= achievement.Goal
		local card = UI.new("Frame", {
			LayoutOrder = 4 + i,
			Size = UDim2.new(1, -12, 0, 58),
			BackgroundColor3 = ready and Color3.fromRGB(40, 80, 50) or CARD_BG,
			Parent = scroll,
		}, { UI.corner(10), UI.stroke(ready and GREEN or Color3.fromRGB(90, 100, 140), 2, 0.2) })
		UI.label({ Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(40, 58), Text = achievement.Icon, TextSize = 28, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(54, 6),
			Size = UDim2.new(1, -250, 0, 24),
			Text = achievement.Text,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		progressBar(card, UDim2.fromOffset(54, 36), UDim2.new(1, -330, 0, 10), math.min(value, achievement.Goal) / achievement.Goal, ready and GREEN or BLUE)
		UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -196, 0, 30),
			Size = UDim2.fromOffset(70, 22),
			Text = math.min(value, achievement.Goal) .. "/" .. achievement.Goal,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = card,
		})
		local button = UI.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(170, 38),
			Text = ready and ("🎁 Reclamar " .. coinsText(achievement.Coins)) or coinsText(achievement.Coins),
			TextSize = 16,
			BackgroundColor3 = ready and GREEN or GREY,
			AutoButtonColor = ready,
			Parent = card,
		}, { UI.gloss() })
		if ready then
			button.Activated:Connect(function()
				if busy then
					return
				end
				busy = true
				local ok, success, result = pcall(function()
					return Remotes.ClaimAchievement:InvokeServer(achievement.Id)
				end)
				busy = false
				if ok and success then
					Sounds.Play("Kill")
					showToast("🏅 ¡Logro conseguido! +" .. tostring(result) .. " 🪙", GREEN)
				else
					showToast(ok and tostring(result) or "No se pudo reclamar", Color3.fromRGB(255, 90, 90))
				end
			end)
		end
	end

	-- Títulos: salen junto a tu nombre en el marcador y el chat
	local equippedTitle = data.EquippedTitle or "Novato"
	if not Titles.Owns(data, equippedTitle, data.VIP == true) then
		equippedTitle = "Novato"
	end
	UI.label({
		LayoutOrder = 40,
		Size = UDim2.new(1, -12, 0, 30),
		Text = "🏷 TÍTULO  ·  " .. Titles.Get(equippedTitle).Name .. "  (sale junto a tu nombre en el marcador y el chat)",
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GOLD,
		Parent = scroll,
	})
	local grid = UI.new("Frame", {
		LayoutOrder = 41,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = scroll,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(196, 62),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, id in Titles.Sorted() do
		local title = Titles.List[id]
		local owned = Titles.Owns(data, id, data.VIP == true)
		local equipped = id == equippedTitle
		local chip = UI.button({
			LayoutOrder = i,
			Text = "",
			BackgroundColor3 = equipped and Color3.fromRGB(60, 55, 25) or CARD_BG,
			AutoButtonColor = not equipped,
			Parent = grid,
		}, { UI.corner(10), UI.stroke(equipped and GOLD or (owned and title.Color or Color3.fromRGB(70, 75, 100)), 2, owned and 0.1 or 0.5) })
		UI.label({
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 0, 26),
			Text = (owned and "" or "🔒 ") .. title.Name,
			TextSize = 19,
			TextColor3 = owned and title.Color or Color3.fromRGB(140, 145, 165),
			TextScaled = true,
			Parent = chip,
		})
		local status
		if equipped then
			status = "✔ Elegido"
		elseif owned then
			status = "Elegir"
		elseif title.Price then
			status = coinsText(Shop.GetPrice("Title", id) or title.Price)
		else
			status = Titles.Requirement(id)
		end
		UI.label({
			Position = UDim2.fromOffset(6, 34),
			Size = UDim2.new(1, -12, 0, 20),
			Text = status,
			TextSize = 15,
			TextColor3 = equipped and GREEN or (title.Price and not owned and GOLD or Color3.fromRGB(190, 195, 220)),
			Parent = chip,
		})
		chip.Activated:Connect(function()
			if equipped then
				return
			end
			if owned then
				Sounds.Play("Click")
				Remotes.EquipTitle:FireServer(id)
			elseif title.Price then
				buy("Title", id)
			else
				showToast("🔒 Para conseguirlo: " .. Titles.Requirement(id), Color3.fromRGB(255, 200, 90))
			end
		end)
	end
end

local function buildChallengesPage(data)
	local info = data.Challenges
	local scroll = scroller(UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }))
	local secondsLeft = 86400 - os.time() % 86400
	UI.label({
		LayoutOrder = 0,
		Size = UDim2.new(1, -12, 0, 30),
		Text = string.format("RETOS DE HOY  ·  nuevos en %dh %02dm", secondsLeft // 3600, (secondsLeft % 3600) // 60),
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GOLD,
		Parent = scroll,
	})
	if not info then
		return
	end
	for i, challenge in info.List do
		local card = UI.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, -12, 0, 96),
			BackgroundColor3 = challenge.Done and Color3.fromRGB(34, 70, 50) or CARD_BG,
			Parent = scroll,
		}, { UI.corner(12), UI.stroke(challenge.Done and GREEN or Color3.fromRGB(90, 100, 140), 2, 0) })
		UI.label({
			Position = UDim2.fromOffset(16, 10),
			Size = UDim2.new(1, -260, 0, 28),
			Text = (challenge.Done and "✅ " or "🎯 ") .. challenge.Text,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		progressBar(card, UDim2.fromOffset(16, 50), UDim2.new(1, -300, 0, 14), challenge.Progress / challenge.Goal, challenge.Done and GREEN or BLUE)
		UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -270, 0, 66),
			Size = UDim2.fromOffset(140, 20),
			Text = challenge.Progress .. " / " .. challenge.Goal,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = card,
		})
		UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0, 12),
			Size = UDim2.fromOffset(230, 26),
			Text = coinsText(challenge.Coins) .. "   +" .. challenge.XP .. " XP",
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = GOLD,
			Parent = card,
		})
		if not challenge.Done and info.RerollsLeft > 0 then
			local reroll = UI.button({
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -16, 1, -10),
				Size = UDim2.fromOffset(150, 32),
				Text = "🔄 Cambiar reto",
				TextSize = 16,
				BackgroundColor3 = Color3.fromRGB(110, 80, 200),
				Parent = card,
			}, { UI.gloss() })
			reroll.Activated:Connect(function()
				if busy then
					return
				end
				busy = true
				Sounds.Play("Click")
				local ok, result = pcall(function()
					return Remotes.RerollChallenge:InvokeServer(i)
				end)
				busy = false
				if not (ok and result) then
					showToast("No se pudo cambiar el reto", Color3.fromRGB(255, 90, 90))
				end
			end)
		end
	end
	local done = 0
	for _, challenge in info.List do
		if challenge.Done then
			done += 1
		end
	end
	local bonus = UI.new("Frame", {
		LayoutOrder = 10,
		Size = UDim2.new(1, -12, 0, 70),
		BackgroundColor3 = info.Bonus and Color3.fromRGB(70, 60, 20) or Color3.fromRGB(50, 40, 70),
		Parent = scroll,
	}, { UI.corner(12), UI.stroke(GOLD, 2, info.Bonus and 0 or 0.5) })
	UI.label({
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0),
		Text = info.Bonus and "🎁 ¡Premio de hoy conseguido! Tienes una caja gratis en la Tienda"
			or ("🎁 Completa los " .. #info.List .. " retos (" .. done .. "/" .. #info.List .. ") y gana " .. info.BonusCrates .. " caja gratis"),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GOLD,
		Parent = bonus,
	})
	-- Retos semanales: más largos y con más premio (sin cambio de reto)
	local weekly = info.Weekly
	if weekly and #weekly.List > 0 then
		local left = math.max(0, (weekly.EndsAt or 0) - os.time())
		UI.label({
			LayoutOrder = 11,
			Size = UDim2.new(1, -12, 0, 34),
			Text = "📅 RETOS DE LA SEMANA  ·  nuevos en " .. (left >= 86400 and string.format("%dd %dh", left // 86400, (left % 86400) // 3600)
				or string.format("%dh %02dm", left // 3600, (left % 3600) // 60)),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(120, 200, 255),
			Parent = scroll,
		})
		local weeklyDone = 0
		for i, challenge in weekly.List do
			if challenge.Done then
				weeklyDone += 1
			end
			local card = UI.new("Frame", {
				LayoutOrder = 11 + i,
				Size = UDim2.new(1, -12, 0, 76),
				BackgroundColor3 = challenge.Done and Color3.fromRGB(34, 70, 50) or Color3.fromRGB(28, 40, 66),
				Parent = scroll,
			}, { UI.corner(12), UI.stroke(challenge.Done and GREEN or Color3.fromRGB(80, 150, 230), 2, 0) })
			UI.label({
				Position = UDim2.fromOffset(16, 8),
				Size = UDim2.new(1, -260, 0, 28),
				Text = (challenge.Done and "✅ " or "📅 ") .. challenge.Text,
				TextSize = 21,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			progressBar(card, UDim2.fromOffset(16, 46), UDim2.new(1, -300, 0, 14), challenge.Progress / challenge.Goal, challenge.Done and GREEN or Color3.fromRGB(80, 150, 230))
			UI.label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -270, 0, 42),
				Size = UDim2.fromOffset(140, 20),
				Text = challenge.Progress .. " / " .. challenge.Goal,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = card,
			})
			UI.label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -16, 0, 10),
				Size = UDim2.fromOffset(230, 26),
				Text = coinsText(challenge.Coins) .. "   +" .. challenge.XP .. " XP",
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = GOLD,
				Parent = card,
			})
		end
		local weeklyBonus = UI.new("Frame", {
			LayoutOrder = 20,
			Size = UDim2.new(1, -12, 0, 56),
			BackgroundColor3 = weekly.Bonus and Color3.fromRGB(70, 60, 20) or Color3.fromRGB(30, 45, 80),
			Parent = scroll,
		}, { UI.corner(12), UI.stroke(Color3.fromRGB(120, 200, 255), 2, weekly.Bonus and 0 or 0.5) })
		UI.label({
			Position = UDim2.fromOffset(16, 0),
			Size = UDim2.new(1, -32, 1, 0),
			Text = weekly.Bonus and "🎁 ¡Premio de la semana conseguido! Tus cajas están en la Tienda"
				or ("🎁 Completa los " .. #weekly.List .. " retos semanales (" .. weeklyDone .. "/" .. #weekly.List .. ") y gana " .. weekly.BonusCrates .. " cajas gratis"),
			TextSize = 19,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(150, 215, 255),
			Parent = weeklyBonus,
		})
	end
	-- Evento de temporada: premios por caramelos (GameConfig.Event) con su vista previa
	local event = GameConfig.CurrentEvent()
	if event and ReplicatedStorage:GetAttribute("EventName") then
		local icon, itemIcon, items = event.Icon or "🎉", event.ItemIcon or "⭐", event.Items or "objetos"
		local candy = data.EventCandy or 0
		local card = UI.new("Frame", {
			LayoutOrder = 30,
			Size = UDim2.new(1, -12, 0, 214),
			BackgroundColor3 = Color3.fromRGB(50, 26, 66),
			Parent = scroll,
		}, { UI.corner(12), UI.stroke(Color3.fromRGB(255, 140, 30), 2, 0.1) })
		UI.label({
			Position = UDim2.fromOffset(16, 8),
			Size = UDim2.new(1, -32, 0, 28),
			Text = icon .. " EVENTO DE " .. string.upper(event.Name) .. "  ·  " .. itemIcon .. " " .. math.min(candy, event.Goal) .. " / " .. event.Goal .. " " .. items,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 170, 60),
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(16, 34),
			Size = UDim2.new(1, -32, 0, 20),
			Text = "Recoge los " .. items .. " que aparecen por el mapa durante las partidas",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(210, 195, 230),
			Font = UI.FontBody,
			TextStrokeTransparency = 1,
			Parent = card,
		})
		progressBar(card, UDim2.fromOffset(16, 60), UDim2.new(1, -32, 0, 12), candy / event.Goal, Color3.fromRGB(255, 140, 30))
		-- Premios: los de por el camino y la skin final
		local prizes = {}
		for _, milestone in event.Milestones or {} do
			if milestone.Count < event.Goal then
				table.insert(prizes, milestone)
			end
		end
		table.insert(prizes, { Count = event.Goal, Skin = event.RewardSkin })
		local width = 1 / #prizes
		for i, prize in prizes do
			local got = candy >= prize.Count
			if prize.Weapon then
				got = (data.OwnedWeapons or {})[prize.Weapon] == true -- (se da al recoger el siguiente caramelo)
			end
			local cell = UI.new("Frame", {
				Position = UDim2.new(width * (i - 1), i == 1 and 16 or 6, 0, 82),
				Size = UDim2.new(width, i == 1 and -22 or -12, 0, 122),
				BackgroundColor3 = got and Color3.fromRGB(40, 80, 50) or CARD_BG,
				Parent = card,
			}, { UI.corner(10), UI.stroke(got and GREEN or Color3.fromRGB(110, 90, 140), 2, 0.2) })
			local preview = { Position = UDim2.fromOffset(4, 2), Size = UDim2.new(1, -8, 0, 78), Parent = cell }
			local title
			if prize.Outfit and Outfits.List[prize.Outfit] then
				outfitViewport(prize.Outfit, preview)
				title = "Traje " .. Outfits.List[prize.Outfit].Name
			elseif prize.Weapon and Weapons.Get(prize.Weapon) then
				WeaponIcon.Create(prize.Weapon, "Default", preview, "angled", 2.2)
				title = Weapons.Get(prize.Weapon).DisplayName
			elseif prize.Skin and Skins.List[prize.Skin] then
				WeaponIcon.Create(data.Primary or "ARX27", prize.Skin, preview, "angled", 2.2)
				title = "Skin " .. Skins.List[prize.Skin].Name
			else
				UI.label({ Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 50), Text = "🪙", TextSize = 44, Parent = cell })
				title = coinsText(prize.Coins or 0)
			end
			UI.label({
				Position = UDim2.new(0, 4, 1, -42),
				Size = UDim2.new(1, -8, 0, 20),
				Text = title,
				TextSize = 15,
				TextScaled = true,
				Parent = cell,
			})
			UI.label({
				Position = UDim2.new(0, 4, 1, -22),
				Size = UDim2.new(1, -8, 0, 18),
				Text = got and "✅ Conseguido" or (itemIcon .. " " .. prize.Count),
				TextSize = 15,
				TextColor3 = got and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 190, 90),
				Parent = cell,
			})
		end
	end
	UI.label({
		LayoutOrder = 31,
		Size = UDim2.new(1, -12, 0, 40),
		Text = "Consejo: cada arma tiene MAESTRÍA. Consigue bajas con ella para ganar camuflajes Carbono, Oro, Diamante y Materia oscura (pestaña Armas).",
		TextSize = 15,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(190, 195, 220),
		Font = UI.FontBody,
		TextStrokeTransparency = 1,
		Parent = scroll,
	})
end

---------------------------------------------------------------------------
-- Pestaña: Armas
---------------------------------------------------------------------------

local function buildWeaponsPage(data)
	local scroll = scroller(UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(205, 282),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}))
	local order = 0
	local function weaponCard(weaponName, slotField)
		order += 1
		local def = Weapons.Get(weaponName)
		local unlocked = Weapons.IsUnlocked(weaponName, data)
		local selected = data[slotField] == weaponName
		local card = UI.new("Frame", {
			LayoutOrder = order,
			BackgroundColor3 = CARD_BG,
			Parent = scroll,
		}, { UI.corner(12), UI.stroke(selected and GOLD or Color3.fromRGB(90, 100, 140), 2, 0) })
		UI.label({ Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 24), Text = def.DisplayName, TextSize = 21, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 28),
			Size = UDim2.new(1, 0, 0, 16),
			Text = def.Category .. (slotField == "Secondary" and " · secundaria" or ""),
			TextSize = 14,
			TextColor3 = Color3.fromRGB(170, 180, 215),
			Parent = card,
		})
		WeaponIcon.Create(weaponName, skinFor(data, weaponName), { Position = UDim2.fromOffset(8, 46), Size = UDim2.fromOffset(189, 78), Parent = card }, "angled", 189 / 78)
		local stats
		if def.Type == "Melee" then
			stats = string.format("Daño %d · alcance %s · %.1f golpes/s", def.Damage, tostring(def.Range), 1 / def.Cooldown)
		elseif def.Explosive then
			stats = "Explosivo · radio " .. def.Explosive.Radius
		else
			local damage = def.Pellets > 1 and (def.Damage .. "x" .. def.Pellets) or tostring(def.Damage)
			stats = string.format("Daño %s · %d/s · %d balas", damage, math.floor(def.FireRate + 0.5), def.MagSize)
		end
		UI.label({ Position = UDim2.fromOffset(0, 128), Size = UDim2.new(1, 0, 0, 18), Text = stats, TextSize = 14, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(8, 148),
			Size = UDim2.new(1, -16, 0, 32),
			Text = def.Description or "",
			TextSize = 13,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(190, 195, 220),
			Font = UI.FontBody,
			TextStrokeTransparency = 1,
			Parent = card,
		})
		-- Maestría: bajas con esta arma y camuflajes ganados
		local kills = data.WeaponKills and data.WeaponKills[weaponName] or 0
		local level = Mastery.Level(kills)
		local nextTier = Mastery.Next(kills)
		local current = Mastery.Tiers[level]
		UI.label({
			Position = UDim2.fromOffset(8, 182),
			Size = UDim2.new(1, -16, 0, 16),
			Text = (current and ("🏆 " .. current.Name) or "🏆 Maestría")
				.. (nextTier and ("  ·  " .. kills .. "/" .. nextTier.Kills .. " bajas") or "  ·  ¡COMPLETA!"),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = current and Skins.RarityColors[Skins.Get(current.Camo).Rarity] or Color3.fromRGB(200, 205, 225),
			Parent = card,
		})
		local previous = current and current.Kills or 0
		local fraction = nextTier and (kills - previous) / (nextTier.Kills - previous) or 1
		progressBar(card, UDim2.fromOffset(8, 200), UDim2.new(1, -16, 0, 8), fraction, GOLD)
		if level > 0 then
			local options = { "Default" }
			for i = 1, level do
				table.insert(options, Mastery.Tiers[i].Camo)
			end
			local selected = data.WeaponCamos and data.WeaponCamos[weaponName] or "Default"
			local index = table.find(options, selected) or 1
			local camoButton = UI.button({
				Position = UDim2.fromOffset(10, 212),
				Size = UDim2.new(1, -20, 0, 22),
				Text = "🎨 Camuflaje: " .. (selected == "Default" and "Skin general" or Skins.Get(selected).Name) .. "  ▸",
				TextSize = 13,
				BackgroundColor3 = Color3.fromRGB(70, 60, 120),
				Parent = card,
			})
			camoButton.Activated:Connect(function()
				Sounds.Play("Click")
				Remotes.SetCamo:FireServer(weaponName, options[index % #options + 1])
			end)
		end
		local button = UI.button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0, 36),
			TextSize = 17,
			Parent = card,
		}, { UI.gloss() })
		if selected then
			button.Text = "Equipada"
			button.BackgroundColor3 = GREEN
			button.AutoButtonColor = false
		elseif unlocked then
			button.Text = "Equipar"
			button.BackgroundColor3 = BLUE
			button.Activated:Connect(function()
				Sounds.Play("Click")
				if slotField == "Primary" then
					Remotes.SetPrimary:FireServer(weaponName)
				elseif slotField == "Melee" then
					Remotes.SetMelee:FireServer(weaponName)
				else
					Remotes.SetSecondary:FireServer(weaponName)
				end
			end)
		elseif def.Price then
			button.Text = "🔒 Nv " .. def.UnlockLevel .. "  ·  " .. coinsText(def.Price)
			button.BackgroundColor3 = data.Coins >= def.Price and Color3.fromRGB(230, 140, 20) or GREY
			button.Activated:Connect(function()
				buy("Weapon", weaponName)
			end)
		else
			button.Text = def.EventText or ("🔒 Nivel " .. def.UnlockLevel)
			button.BackgroundColor3 = GREY
			button.AutoButtonColor = false
		end
	end
	for _, name in Weapons.Primaries do
		weaponCard(name, "Primary")
	end
	for _, name in Weapons.Secondaries do
		weaponCard(name, "Secondary")
	end
	for _, name in Weapons.Melees do
		weaponCard(name, "Melee")
	end
end

---------------------------------------------------------------------------
-- Pestañas: Skins y Trajes
---------------------------------------------------------------------------

local RARITY_ORDER = { "Común", "Raro", "Épico", "Legendario", "Mítico" }

local function sortedIds(list)
	local ids = {}
	for id in list do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		local ra = table.find(RARITY_ORDER, list[a].Rarity) or 0
		local rb = table.find(RARITY_ORDER, list[b].Rarity) or 0
		if ra == rb then
			return list[a].Name < list[b].Name
		end
		return ra < rb
	end)
	return ids
end

local function priceButton(card, kind, id, owned, equipped, onEquip, lockedText)
	local price, onSale = Shop.GetPrice(kind, id)
	local button = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -20, 0, 32),
		TextSize = 16,
		Parent = card,
	}, { UI.gloss() })
	if equipped then
		button.Text = "Equipado"
		button.BackgroundColor3 = GREEN
		button.AutoButtonColor = false
	elseif owned then
		button.Text = "Equipar"
		button.BackgroundColor3 = BLUE
		button.Activated:Connect(onEquip)
	elseif price then
		button.Text = (onSale and "🔥 " or "") .. coinsText(price)
		button.BackgroundColor3 = onSale and Color3.fromRGB(230, 60, 90) or Color3.fromRGB(230, 140, 20)
		button.Activated:Connect(function()
			buy(kind, id)
		end)
	else
		button.Text = lockedText or "🔒 Pase de batalla"
		button.BackgroundColor3 = GREY
		button.AutoButtonColor = false
	end
	if onSale and not owned then
		UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 4),
			Size = UDim2.fromOffset(60, 20),
			Text = "-" .. math.floor(Shop.OfferDiscount * 100) .. "%",
			TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 90, 120),
			ZIndex = 3,
			Parent = card,
		})
	end
end

local function buildSkinsPage(data)
	local scroll = scroller(UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(165, 160),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}))
	local visible = {}
	for id, skin in Skins.List do
		if not skin.Mastery then
			visible[id] = skin
		end
	end
	for i, id in sortedIds(visible) do
		local skin = Skins.List[id]
		local owned = data.Skins[id] == true
		local equipped = data.EquippedSkin == id
		local card = UI.new("Frame", { LayoutOrder = i, BackgroundColor3 = CARD_BG, Parent = scroll }, {
			UI.corner(10),
			UI.stroke(equipped and GOLD or rarityColor(skin.Rarity), 2, equipped and 0 or 0.4),
		})
		WeaponIcon.Create(data.Primary or "ARX27", id, { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(153, 58), Parent = card }, "angled", 153 / 58)
		UI.label({
			Position = UDim2.fromOffset(0, 62),
			Size = UDim2.new(1, 0, 0, 22),
			Text = id == "Default" and "De fábrica" or skin.Name,
			TextSize = 19,
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(0, 84),
			Size = UDim2.new(1, 0, 0, 16),
			Text = skin.Rarity,
			TextSize = 14,
			TextColor3 = rarityColor(skin.Rarity),
			Parent = card,
		})
		priceButton(card, "Skin", id, owned, equipped, function()
			Sounds.Play("Click")
			Remotes.EquipSkin:FireServer(id)
		end, skin.Event and (skin.EventText or "Evento") or nil)
	end

	-- Colgantes para el arma (en la misma rejilla, después de las skins)
	local header = UI.new("Frame", { LayoutOrder = 999, BackgroundColor3 = Color3.fromRGB(60, 50, 90), Parent = scroll }, { UI.corner(10) })
	UI.label({
		Size = UDim2.fromScale(1, 1),
		Text = "🔑 COLGANTES\nCuelgan de tu arma y se balancean\n(se ven al reaparecer)",
		TextSize = 16,
		TextWrapped = true,
		TextColor3 = GOLD,
		Parent = header,
	})
	local charmsOwned = data.Charms or { Default = true }
	for i, id in sortedIds(Charms.List) do
		local charm = Charms.List[id]
		local equipped = (data.EquippedCharm or "Default") == id
		local card = UI.new("Frame", { LayoutOrder = 1000 + i, BackgroundColor3 = CARD_BG, Parent = scroll }, {
			UI.corner(10),
			UI.stroke(equipped and GOLD or rarityColor(charm.Rarity), 2, equipped and 0 or 0.4),
		})
		UI.label({ Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 56), Text = charm.Icon, TextSize = 44, Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 22), Text = charm.Name, TextSize = 18, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 84),
			Size = UDim2.new(1, 0, 0, 16),
			Text = charm.Rarity,
			TextSize = 14,
			TextColor3 = rarityColor(charm.Rarity),
			Parent = card,
		})
		priceButton(card, "Charm", id, charmsOwned[id] == true, equipped, function()
			Sounds.Play("Click")
			Remotes.EquipCharm:FireServer(id)
		end)
	end
end

---------------------------------------------------------------------------
-- Pestaña: Ajustes (calidad gráfica, campo de visión, sensibilidad)
---------------------------------------------------------------------------

local QUALITY_INFO = {
	Auto = "Se elige sola: Baja en móviles, Media en PC",
	Baja = "Máximo rendimiento (móviles): sin sombras ni efectos",
	Media = "Sombras y brillo, menos partículas",
	Alta = "Todo como está diseñado",
	Ultra = "Además desenfoque de distancia y más partículas",
}

local function buildSettingsPage()
	local scroll = scroller(UI.new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }))
	local current = Settings.Get()

	local function section(order, title, height)
		local frame = UI.new("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, -12, 0, height),
			BackgroundColor3 = CARD_BG,
			Parent = scroll,
		}, { UI.corner(12) })
		UI.label({
			Position = UDim2.fromOffset(16, 8),
			Size = UDim2.new(1, -32, 0, 28),
			Text = title,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame,
		})
		return frame
	end

	-- Calidad gráfica
	local quality = section(1, "🎨 Calidad gráfica", 116)
	for i, level in GameConfig.QualityLevels do
		local selected = current.Quality == level
		local button = UI.button({
			Position = UDim2.fromOffset(16 + (i - 1) * 118, 42),
			Size = UDim2.fromOffset(110, 36),
			Text = level,
			TextSize = 18,
			BackgroundColor3 = selected and BLUE or GREY,
			Parent = quality,
		}, { UI.gloss() })
		button.Activated:Connect(function()
			Sounds.Play("Click")
			Settings.Set("Quality", level)
			refresh()
		end)
	end
	UI.label({
		Position = UDim2.fromOffset(16, 84),
		Size = UDim2.new(1, -32, 0, 22),
		Text = QUALITY_INFO[current.Quality] or "",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(190, 195, 220),
		Font = UI.FontBody,
		TextStrokeTransparency = 1,
		Parent = quality,
	})

	-- Deslizadores sencillos con botones − y +
	local function stepper(order, title, key, step, format)
		local frame = section(order, title, 92)
		local valueLabel = UI.label({
			Position = UDim2.fromOffset(80, 44),
			Size = UDim2.fromOffset(120, 36),
			Text = string.format(format, current[key]),
			TextSize = 24,
			TextColor3 = GOLD,
			Parent = frame,
		})
		for _, info in { { "−", -step, 16 }, { "+", step, 206 } } do
			local button = UI.button({
				Position = UDim2.fromOffset(info[3], 44),
				Size = UDim2.fromOffset(56, 36),
				Text = info[1],
				TextSize = 26,
				BackgroundColor3 = BLUE,
				Parent = frame,
			}, { UI.gloss() })
			button.Activated:Connect(function()
				Sounds.Play("Click")
				Settings.Set(key, current[key] + info[2])
				valueLabel.Text = string.format(format, current[key])
			end)
		end
		return frame
	end
	stepper(2, "🔭 Campo de visión (FOV)", "FOV", 5, "%d°")
	stepper(3, "🖱 Sensibilidad", "Sensitivity", 0.1, "%.1f")
	stepper(4, "🎯 Sensibilidad al apuntar", "AimSensitivity", 0.05, "%.2f")

	-- Mira: color (muestras) y tamaño
	local cross = section(5, "➕ Mira", 92)
	for i, color in GameConfig.CrosshairColors do
		local selected = math.floor(current.CrossColor or 1) == i
		local swatch = UI.button({
			Position = UDim2.fromOffset(16 + (i - 1) * 46, 44),
			Size = UDim2.fromOffset(38, 36),
			Text = selected and "✔" or "",
			TextSize = 20,
			TextColor3 = Color3.new(0, 0, 0),
			BackgroundColor3 = color,
			Parent = cross,
		}, { UI.stroke(selected and GOLD or Color3.new(0, 0, 0), selected and 3 or 1, 0) })
		swatch.Activated:Connect(function()
			Sounds.Play("Click")
			Settings.Set("CrossColor", i)
			refresh()
		end)
	end
	local sizeLabel = UI.label({
		Position = UDim2.fromOffset(360, 44),
		Size = UDim2.fromOffset(110, 36),
		Text = "Tamaño " .. string.format("%.1f", current.CrossSize or 1),
		TextSize = 20,
		TextColor3 = GOLD,
		Parent = cross,
	})
	for _, info in { { "−", -0.2, 300 }, { "+", 0.2, 476 } } do
		local button = UI.button({
			Position = UDim2.fromOffset(info[3], 44),
			Size = UDim2.fromOffset(52, 36),
			Text = info[1],
			TextSize = 26,
			BackgroundColor3 = BLUE,
			Parent = cross,
		}, { UI.gloss() })
		button.Activated:Connect(function()
			Sounds.Play("Click")
			Settings.Set("CrossSize", (current.CrossSize or 1) + info[2])
			sizeLabel.Text = "Tamaño " .. string.format("%.1f", current.CrossSize or 1)
		end)
	end
	UI.label({
		LayoutOrder = 6,
		Size = UDim2.new(1, -12, 0, 40),
		Text = "Los ajustes se guardan con tu progreso. La calidad de Roblox (Menú de Roblox → Ajustes → Calidad de gráficos) también influye.",
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(190, 195, 220),
		Font = UI.FontBody,
		TextStrokeTransparency = 1,
		Parent = scroll,
	})
end

-- Muestra un efecto de eliminación delante de la cámara (oculta el menú, y la pantalla de inicio
-- con su desenfoque si está abierta, durante un momento)
local previewing = false
local function previewKillEffect(effectId)
	if previewing then
		return
	end
	previewing = true
	local camera = workspace.CurrentCamera
	local position = camera.CFrame.Position + camera.CFrame.LookVector * 16
	panel.Visible = false
	local mainGui = player.PlayerGui:FindFirstChild("MainMenu")
	local mainWasEnabled = mainGui and mainGui.Enabled
	local blur = game:GetService("Lighting"):FindFirstChild("MainMenuBlur")
	local blurSize = blur and blur.Size
	if mainGui then
		mainGui.Enabled = false
	end
	if blur then
		blur.Size = 0
	end
	Effects.KillEffect(effectId, position, Color3.fromRGB(255, 200, 60))
	task.delay(2.2, function()
		previewing = false
		if mainGui and mainWasEnabled and ClientState.InMainMenu then
			mainGui.Enabled = true
		end
		if blur and blur.Parent and ClientState.InMainMenu then
			blur.Size = blurSize
		end
		if ClientState.MenuOpen then
			panel.Visible = true
		end
	end)
end

local function buildKillEffectsPage(data)
	local scroll = scroller(UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(200, 230),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}))
	local owned = data.KillEffects or { Default = true }
	for i, id in sortedIds(KillEffects.List) do
		local effect = KillEffects.List[id]
		local equipped = (data.EquippedKillEffect or "Default") == id
		local card = UI.new("Frame", { LayoutOrder = i, BackgroundColor3 = CARD_BG, Parent = scroll }, {
			UI.corner(12),
			UI.stroke(equipped and GOLD or rarityColor(effect.Rarity), 2, equipped and 0 or 0.4),
		})
		UI.label({ Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 62), Text = effect.Icon, TextSize = 54, Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 24), Text = effect.Name, TextSize = 20, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 94),
			Size = UDim2.new(1, 0, 0, 16),
			Text = effect.Rarity,
			TextSize = 14,
			TextColor3 = rarityColor(effect.Rarity),
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(8, 112),
			Size = UDim2.new(1, -16, 0, 34),
			Text = effect.Description or "",
			TextSize = 13,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(190, 195, 220),
			Font = UI.FontBody,
			TextStrokeTransparency = 1,
			Parent = card,
		})
		local preview = UI.button({
			Position = UDim2.fromOffset(10, 150),
			Size = UDim2.new(1, -20, 0, 26),
			Text = "👁 Ver efecto",
			TextSize = 15,
			BackgroundColor3 = Color3.fromRGB(70, 60, 120),
			Parent = card,
		})
		preview.Activated:Connect(function()
			Sounds.Play("Click")
			previewKillEffect(id)
		end)
		priceButton(card, "KillEffect", id, owned[id] == true, equipped, function()
			Sounds.Play("Click")
			Remotes.EquipKillEffect:FireServer(id)
		end)
	end

	-- Grafitis (tecla J), en la misma rejilla, después de los efectos
	local header = UI.new("Frame", { LayoutOrder = 999, BackgroundColor3 = Color3.fromRGB(60, 50, 90), Parent = scroll }, { UI.corner(12) })
	UI.label({
		Size = UDim2.fromScale(1, 1),
		Text = "🎨 GRAFITIS\n\nPulsa J (o 🎨 en el móvil) para pintar el tuyo en la pared que tienes delante",
		TextSize = 17,
		TextWrapped = true,
		TextColor3 = GOLD,
		Parent = header,
	}, { UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	local spraysOwned = data.Sprays or { Default = true }
	for i, id in sortedIds(Sprays.List) do
		local sprayDef = Sprays.List[id]
		local equipped = (data.EquippedSpray or "Default") == id
		local card = UI.new("Frame", { LayoutOrder = 1000 + i, BackgroundColor3 = CARD_BG, Parent = scroll }, {
			UI.corner(12),
			UI.stroke(equipped and GOLD or rarityColor(sprayDef.Rarity), 2, equipped and 0 or 0.4),
		})
		local preview = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 10),
			Size = UDim2.fromOffset(110, 110),
			BackgroundTransparency = 1,
			Parent = card,
		})
		Sprays.Draw(id, preview)
		UI.label({ Position = UDim2.fromOffset(0, 126), Size = UDim2.new(1, 0, 0, 24), Text = sprayDef.Name, TextSize = 20, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 150),
			Size = UDim2.new(1, 0, 0, 16),
			Text = sprayDef.Rarity,
			TextSize = 14,
			TextColor3 = rarityColor(sprayDef.Rarity),
			Parent = card,
		})
		priceButton(card, "Spray", id, Sprays.Owns(spraysOwned, id, data.VIP == true), equipped, function()
			Sounds.Play("Click")
			Remotes.EquipSpray:FireServer(id)
		end, sprayDef.VIPOnly and "👑 Solo VIP" or nil)
	end
end

local function buildOutfitsPage(data)
	local scroll = scroller(UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(200, 250),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}))
	for i, id in sortedIds(Outfits.List) do
		local outfit = Outfits.List[id]
		local owned = data.Outfits[id] == true
		local equipped = data.EquippedOutfit == id
		local card = UI.new("Frame", { LayoutOrder = i, BackgroundColor3 = CARD_BG, Parent = scroll }, {
			UI.corner(12),
			UI.stroke(equipped and GOLD or rarityColor(outfit.Rarity), 2, equipped and 0 or 0.4),
		})
		if id ~= "Default" then
			outfitViewport(id, { Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(180, 140), Parent = card })
		else
			UI.label({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 60), Text = "🙂", TextSize = 54, Parent = card })
		end
		UI.label({ Position = UDim2.fromOffset(0, 146), Size = UDim2.new(1, 0, 0, 24), Text = outfit.Name, TextSize = 20, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 170),
			Size = UDim2.new(1, 0, 0, 18),
			Text = outfit.Class .. " · " .. outfit.Rarity,
			TextSize = 14,
			TextColor3 = rarityColor(outfit.Rarity),
			Parent = card,
		})
		priceButton(card, "Outfit", id, owned, equipped, function()
			Sounds.Play("Click")
			Remotes.EquipOutfit:FireServer(id)
		end, outfit.Event)
	end
end

---------------------------------------------------------------------------
-- Pestaña: Tienda (diaria, ofertas, cajas, Robux, VIP)
---------------------------------------------------------------------------

local function itemName(kind, id)
	if kind == "Outfit" then
		return Outfits.Get(id).Name, Outfits.Get(id).Rarity
	elseif kind == "KillEffect" then
		return KillEffects.Get(id).Name, KillEffects.Get(id).Rarity
	end
	return Skins.Get(id).Name, Skins.Get(id).Rarity
end

-- Animación de apertura de caja: una tira de premios que gira y se para en el tuyo
local crateOverlay = nil -- animación de caja en curso (el menú no se puede cerrar hasta acabar)

local function crateAnimation(result)
	local overlay = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		Active = true, -- los clics no atraviesan (no se compra otra caja sin querer)
		ZIndex = 20,
		Parent = gui,
	})
	crateOverlay = overlay
	UI.new("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Parent = overlay })
	local window = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(760, 170),
		BackgroundColor3 = Color3.fromRGB(15, 16, 26),
		ClipsDescendants = true,
		ZIndex = 21,
		Parent = overlay,
	}, { UI.corner(12), UI.stroke(GOLD, 3, 0) })
	local reel = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 15),
		Size = UDim2.fromOffset(40 * 150, 140),
		BackgroundTransparency = 1,
		ZIndex = 22,
		Parent = window,
	}, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	-- Rellenamos con objetos aleatorios y el premio en la posición 32
	local pool = {}
	for id, skin in Skins.List do
		if id ~= "Default" and not skin.Mastery and not skin.Event then
			table.insert(pool, { "Skin", id })
		end
	end
	for id, outfit in Outfits.List do
		if id ~= "Default" and not outfit.Event then
			table.insert(pool, { "Outfit", id })
		end
	end
	local PRIZE_INDEX = 32
	for i = 1, 38 do
		local kind, id
		if i == PRIZE_INDEX then
			kind, id = result.Kind, result.Id
		else
			local pick = pool[math.random(1, #pool)]
			kind, id = pick[1], pick[2]
		end
		local name, rarity = itemName(kind, id)
		local card = UI.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.fromOffset(140, 140),
			BackgroundColor3 = rarityColor(rarity):Lerp(Color3.new(0, 0, 0), 0.55),
			ZIndex = 23,
			Parent = reel,
		}, { UI.corner(10), UI.stroke(rarityColor(rarity), 3, 0) })
		UI.label({
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 0, 50),
			Text = kind == "Outfit" and "🧥" or "🔫",
			TextSize = 40,
			ZIndex = 24,
			Parent = card,
		})
		UI.label({ Position = UDim2.fromOffset(4, 90), Size = UDim2.new(1, -8, 0, 22), Text = name, TextScaled = true, ZIndex = 24, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 112),
			Size = UDim2.new(1, 0, 0, 18),
			Text = rarity,
			TextSize = 14,
			TextColor3 = rarityColor(rarity),
			ZIndex = 24,
			Parent = card,
		})
	end
	-- Marcador central
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = GOLD,
		BorderSizePixel = 0,
		ZIndex = 30,
		Parent = window,
	})
	local cardStep = 150
	local target = -((PRIZE_INDEX - 1) * cardStep + 70 - 380) + math.random(-50, 50)
	local spin = TweenService:Create(reel, TweenInfo.new(4.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(target, 15) })
	spin:Play()
	-- "tic" mientras gira
	task.spawn(function()
		local last = 0
		while spin.PlaybackState == Enum.PlaybackState.Playing do
			local index = math.floor(-reel.Position.X.Offset / cardStep)
			if index ~= last then
				last = index
				Sounds.Play("Click")
			end
			task.wait()
		end
	end)
	spin.Completed:Wait()
	local name, rarity = itemName(result.Kind, result.Id)
	Sounds.Play("Kill")
	local title = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.45, 100),
		Size = UDim2.fromOffset(700, 50),
		Text = result.Duplicate and ("Repetido: " .. name .. "  ·  +" .. result.Refund .. " monedas") or ("¡" .. name .. "! (" .. rarity .. ")"),
		TextSize = 34,
		TextColor3 = rarityColor(rarity),
		TextStrokeTransparency = 0,
		ZIndex = 25,
		Parent = overlay,
	})
	local scale = UI.new("UIScale", { Scale = 1.6, Parent = title })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local close = UI.button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.45, 160),
		Size = UDim2.fromOffset(220, 46),
		Text = "¡Genial!",
		BackgroundColor3 = GREEN,
		ZIndex = 25,
		Parent = overlay,
	}, { UI.gloss() })
	close.Activated:Connect(function()
		overlay:Destroy()
		crateOverlay = nil
		busy = false
	end)
end

local function openCrate(crateId, useFree)
	if busy then
		return
	end
	busy = true
	local ok, success, result = pcall(function()
		return Remotes.OpenCrate:InvokeServer(crateId, useFree)
	end)
	if ok and success and type(result) == "table" then
		-- busy sigue activo hasta cerrar la animación (no se puede abrir otra mientras gira)
		crateAnimation(result)
	else
		busy = false
		showToast(ok and tostring(result) or "Error de conexión", Color3.fromRGB(255, 90, 90))
	end
end

local function sectionTitle(parent, text, order)
	return UI.label({
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, 30),
		Text = text,
		TextSize = 24,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
end

-- Fila de tarjetas: si no caben (pantallas estrechas) pasan a la línea siguiente
local function row(parent, order, height)
	return UI.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, height),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function buildShopPage(data)
	local scroll = scroller(UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }))

	-- Pack de inicio (solo jugadores nuevos, una vez)
	local starter = Shop.StarterPack
	if data.StarterPackAvailable then
		local card = UI.new("Frame", {
			LayoutOrder = 0,
			Size = UDim2.new(1, -10, 0, 130),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Parent = scroll,
		}, {
			UI.corner(14),
			UI.stroke(GOLD, 3, 0),
			UI.new("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 90, 40), Color3.fromRGB(150, 40, 200)),
				Rotation = 0,
			}),
		})
		UI.label({
			Position = UDim2.fromOffset(18, 8),
			Size = UDim2.new(1, -280, 0, 36),
			Text = "🔥 PACK DE INICIO  ·  solo una vez",
			TextSize = 28,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(18, 48),
			Size = UDim2.new(1, -280, 0, 72),
			Text = string.format(
				"🪙 %d monedas  ·  👕 Traje %s  ·  🎨 Skin %s  ·  %s Efecto %s\n¡Vale más de 4 veces su precio!",
				starter.Coins,
				Outfits.Get(starter.Outfit).Name,
				Skins.Get(starter.Skin).Name,
				KillEffects.Get(starter.KillEffect).Icon,
				KillEffects.Get(starter.KillEffect).Name
			),
			TextSize = 18,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = card,
		})
		local buyStarter = UI.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -18, 0.5, 0),
			Size = UDim2.fromOffset(230, 60),
			Text = starter.ProductId ~= 0 and ("R$ " .. starter.Robux .. "  ¡COMPRAR!") or "Próximamente",
			TextSize = 24,
			BackgroundColor3 = starter.ProductId ~= 0 and GREEN or GREY,
			Parent = card,
		}, { UI.gloss() })
		buyStarter.Activated:Connect(function()
			if not buyStarter.Active then
				return
			end
			if starter.ProductId ~= 0 then
				Sounds.Play("Click")
				-- Un solo intento hasta que llegue la respuesta del servidor (la página se rehace)
				buyStarter.Active = false
				buyStarter.AutoButtonColor = false
				buyStarter.Text = "Procesando..."
				MarketplaceService:PromptProductPurchase(player, starter.ProductId)
			else
				showToast("Próximamente")
			end
		end)
	end

	-- Pack de Halloween (compra única, hasta que acaba el evento)
	local bundle = Shop.HalloweenBundle
	if data.HalloweenBundleAvailable and os.time() < bundle.EndsAt then
		local daysLeft = math.max(0, math.ceil((bundle.EndsAt - os.time()) / 86400))
		local card = UI.new("Frame", {
			LayoutOrder = -1,
			Size = UDim2.new(1, -10, 0, 130),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Parent = scroll,
		}, {
			UI.corner(14),
			UI.stroke(Color3.fromRGB(255, 150, 30), 3, 0),
			UI.new("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 120, 20), Color3.fromRGB(90, 30, 140)),
				Rotation = 0,
			}),
		})
		UI.label({
			Position = UDim2.fromOffset(18, 8),
			Size = UDim2.new(1, -280, 0, 36),
			Text = "🎃 PACK DE HALLOWEEN  ·  " .. (daysLeft <= 1 and "¡ÚLTIMO DÍA!" or ("quedan " .. daysLeft .. " días")),
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(18, 48),
			Size = UDim2.new(1, -280, 0, 72),
			Text = string.format(
				"🪙 %d monedas  ·  %s Efecto %s  ·  %s Colgante %s  ·  🎨 Grafiti %s\n¡Todo vale %d monedas! Solo se puede comprar una vez.",
				bundle.Coins,
				KillEffects.Get(bundle.KillEffect).Icon,
				KillEffects.Get(bundle.KillEffect).Name,
				Charms.Get(bundle.Charm).Icon,
				Charms.Get(bundle.Charm).Name,
				Sprays.Get(bundle.Spray).Name,
				bundle.Value
			),
			TextSize = 18,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = card,
		})
		local buyBundle = UI.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -18, 0.5, 0),
			Size = UDim2.fromOffset(230, 60),
			Text = "R$ " .. bundle.Robux .. "  ¡COMPRAR!",
			TextSize = 24,
			BackgroundColor3 = GREEN,
			Parent = card,
		}, { UI.gloss() })
		buyBundle.Activated:Connect(function()
			if not buyBundle.Active then
				return
			end
			Sounds.Play("Click")
			buyBundle.Active = false
			buyBundle.AutoButtonColor = false
			buyBundle.Text = "Procesando..."
			MarketplaceService:PromptProductPurchase(player, bundle.ProductId)
			-- (si la compra no llega a entregarse, el botón vuelve a funcionar)
			task.delay(20, function()
				if buyBundle.Parent and buyBundle.Text == "Procesando..." then
					buyBundle.Active = true
					buyBundle.AutoButtonColor = true
					buyBundle.Text = "R$ " .. bundle.Robux .. "  ¡COMPRAR!"
				end
			end)
		end)
	end

	-- Recompensa diaria
	local daily = UI.new("Frame", {
		LayoutOrder = 1,
		Size = UDim2.new(1, -10, 0, 70),
		BackgroundColor3 = Color3.fromRGB(40, 60, 40),
		Parent = scroll,
	}, { UI.corner(12), UI.stroke(Color3.fromRGB(90, 230, 110), 2, 0) })
	local streak = data.DailyStreak or 0
	local nextDay = data.DailyAvailable and ((streak % #Shop.DailyRewards) + 1) or streak
	UI.label({
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -260, 1, 0),
		Text = "🎁 Recompensa diaria · Día " .. tostring(nextDay) .. "/" .. #Shop.DailyRewards .. "  (día 7: caja gratis)",
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = daily,
	})
	local claim = UI.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(220, 46),
		Text = data.DailyAvailable and "¡Reclamar!" or "Vuelve mañana",
		BackgroundColor3 = data.DailyAvailable and GREEN or GREY,
		Parent = daily,
	}, { UI.gloss() })
	claim.Activated:Connect(function()
		Menu.ClaimDaily()
	end)

	-- Ofertas del día
	sectionTitle(scroll, "🔥 Ofertas de hoy (-" .. math.floor(Shop.OfferDiscount * 100) .. "%)", 2)
	local offers = row(scroll, 3, 190)
	for i, offer in Shop.GetDailyOffers(data.Day) do
		local name, rarity = itemName(offer.Kind, offer.Id)
		local owned
		if offer.Kind == "Skin" then
			owned = data.Skins[offer.Id] == true
		elseif offer.Kind == "KillEffect" then
			owned = data.KillEffects ~= nil and data.KillEffects[offer.Id] == true
		else
			owned = data.Outfits[offer.Id] == true
		end
		local card = UI.new("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(200, 190), BackgroundColor3 = CARD_BG, Parent = offers }, {
			UI.corner(12),
			UI.stroke(rarityColor(rarity), 2, 0),
		})
		if offer.Kind == "Skin" then
			WeaponIcon.Create(data.Primary or "ARX27", offer.Id, { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(184, 80), Parent = card }, "angled", 184 / 80)
		elseif offer.Kind == "KillEffect" then
			local icon = UI.button({
				Position = UDim2.fromOffset(50, 6),
				Size = UDim2.fromOffset(100, 80),
				Text = KillEffects.Get(offer.Id).Icon,
				TextSize = 56,
				BackgroundTransparency = 1,
				Parent = card,
			})
			icon.Activated:Connect(function()
				previewKillEffect(offer.Id)
			end)
		else
			outfitViewport(offer.Id, { Position = UDim2.fromOffset(50, 2), Size = UDim2.fromOffset(100, 90), Parent = card })
		end
		UI.label({ Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 24), Text = name, TextSize = 19, Parent = card })
		UI.label({
			Position = UDim2.fromOffset(0, 116),
			Size = UDim2.new(1, 0, 0, 18),
			Text = (offer.Kind == "Outfit" and "Traje · " or offer.Kind == "KillEffect" and "Efecto · " or "Skin · ") .. rarity,
			TextSize = 14,
			TextColor3 = rarityColor(rarity),
			Parent = card,
		})
		priceButton(card, offer.Kind, offer.Id, owned, false, function()
			Sounds.Play("Click")
			if offer.Kind == "Skin" then
				Remotes.EquipSkin:FireServer(offer.Id)
			elseif offer.Kind == "KillEffect" then
				Remotes.EquipKillEffect:FireServer(offer.Id)
			else
				Remotes.EquipOutfit:FireServer(offer.Id)
			end
		end)
	end

	-- Cajas
	sectionTitle(scroll, "🎁 Cajas", 4)
	local crates = row(scroll, 5, 150)
	for crateId, crate in Shop.Crates do
		local card = UI.new("Frame", { Size = UDim2.fromOffset(480, 150), BackgroundColor3 = Color3.fromRGB(50, 30, 80), Parent = crates }, {
			UI.corner(12),
			UI.stroke(Color3.fromRGB(190, 80, 255), 2, 0),
			UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 100, 255)), Rotation = 30 }),
		})
		UI.label({
			Position = UDim2.fromOffset(16, 8),
			Size = UDim2.fromOffset(300, 30),
			Text = "🎁 " .. crate.Name,
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		local oddsText = {}
		for _, entry in crate.Odds do
			table.insert(oddsText, entry.Rarity .. " " .. entry.Weight .. "%")
		end
		UI.label({
			Position = UDim2.fromOffset(16, 40),
			Size = UDim2.fromOffset(450, 36),
			Text = "Probabilidades: "
				.. table.concat(oddsText, " · ")
				.. "\nSkins y trajes. Si repites, recuperas el "
				.. math.floor(crate.DuplicateRefund * 100)
				.. "%.",
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.FontBody,
			TextStrokeTransparency = 1,
			Parent = card,
		})
		local buyCrate = UI.button({
			Position = UDim2.fromOffset(16, 90),
			Size = UDim2.fromOffset(210, 46),
			Text = data.CratesRestricted and "No disponible" or ("Abrir · " .. coinsText(crate.Price)),
			BackgroundColor3 = data.CratesRestricted and GREY or Color3.fromRGB(230, 140, 20),
			Parent = card,
		}, { UI.gloss() })
		buyCrate.Activated:Connect(function()
			if not data.CratesRestricted then
				openCrate(crateId, false)
			end
		end)
		local free = UI.button({
			Position = UDim2.fromOffset(240, 90),
			Size = UDim2.fromOffset(220, 46),
			Text = "Gratis (" .. tostring(data.FreeCrates or 0) .. ")",
			BackgroundColor3 = (data.FreeCrates or 0) > 0 and GREEN or GREY,
			Parent = card,
		}, { UI.gloss() })
		free.Activated:Connect(function()
			if (data.FreeCrates or 0) > 0 then
				openCrate(crateId, true)
			end
		end)
	end

	-- Monedas con Robux
	sectionTitle(scroll, "🪙 Monedas", 6)
	local packs = row(scroll, 7, 170)
	for i, pack in Shop.CoinPacks do
		local card = UI.new("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(200, 170), BackgroundColor3 = Color3.fromRGB(60, 50, 20), Parent = packs }, {
			UI.corner(12),
			UI.stroke(GOLD, 2, 0),
			UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 160, 60)), Rotation = 90 }),
		})
		UI.label({ Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 44), Text = string.rep("🪙", math.min(i + 1, 4)), TextSize = 30, Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 30), Text = tostring(pack.Coins), TextSize = 30, TextColor3 = GOLD, Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 20), Text = pack.Name, TextSize = 16, Parent = card })
		if pack.Tag then
			UI.label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 4),
				Size = UDim2.fromOffset(120, 18),
				Text = pack.Tag,
				TextSize = 13,
				TextColor3 = Color3.fromRGB(120, 255, 140),
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = card,
			})
		end
		local buyPack = UI.button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0, 40),
			Text = pack.ProductId ~= 0 and ("R$ " .. pack.Robux) or "Próximamente",
			BackgroundColor3 = pack.ProductId ~= 0 and GREEN or GREY,
			Parent = card,
		}, { UI.gloss() })
		buyPack.Activated:Connect(function()
			if pack.ProductId ~= 0 then
				MarketplaceService:PromptProductPurchase(player, pack.ProductId)
			end
		end)
	end

	-- Revivir instantáneo con Robux (vuelves a la acción justo donde caíste)
	local PINK_REVIVE = Color3.fromRGB(255, 70, 200)
	sectionTitle(scroll, "💖 Revivir instantáneo", 8)
	local revives = row(scroll, 9, 150)
	for i, pack in Shop.RevivePacks do
		local card = UI.new("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(200, 150), BackgroundColor3 = Color3.fromRGB(70, 20, 60), Parent = revives }, {
			UI.corner(12),
			UI.stroke(PINK_REVIVE, 2, 0),
			UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 80, 170)), Rotation = 90 }),
		})
		UI.label({ Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 40), Text = string.rep("💖", i + 1), TextSize = 28, Parent = card })
		UI.label({ Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 30), Text = "x" .. pack.Revives, TextSize = 30, TextColor3 = Color3.fromRGB(255, 200, 240), Parent = card })
		if pack.Tag then
			UI.label({ Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 0, 18), Text = pack.Tag, TextSize = 13, TextColor3 = Color3.fromRGB(120, 255, 140), Parent = card })
		end
		local buyRevive = UI.button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0, 40),
			Text = pack.ProductId ~= 0 and ("R$ " .. pack.Robux) or "Próximamente",
			BackgroundColor3 = pack.ProductId ~= 0 and GREEN or GREY,
			Parent = card,
		}, { UI.gloss() })
		buyRevive.Activated:Connect(function()
			if pack.ProductId ~= 0 then
				MarketplaceService:PromptProductPurchase(player, pack.ProductId)
			end
		end)
	end

	-- VIP
	local vip = UI.new("Frame", {
		LayoutOrder = 10,
		Size = UDim2.new(1, -10, 0, 90),
		BackgroundColor3 = Color3.fromRGB(70, 50, 10),
		Parent = scroll,
	}, {
		UI.corner(12),
		UI.stroke(GOLD, 3, 0),
		UI.new("UIGradient", { Color = ColorSequence.new(GOLD, Color3.fromRGB(120, 60, 200)), Rotation = 0 }),
	})
	UI.label({
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.new(1, -280, 0, 34),
		Text = "👑 VIP",
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = vip,
	})
	UI.label({
		Position = UDim2.fromOffset(16, 42),
		Size = UDim2.new(1, -280, 0, 40),
		Text = "x2 XP · x2 monedas · caja gratis cada día · grafiti 👑 exclusivo",
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = vip,
	})
	local vipText = "Próximamente"
	if data.VIP then
		vipText = "✔ Ya eres VIP"
	elseif Shop.VIPPassId ~= 0 then
		vipText = "Hazte VIP · R$ " .. Shop.VIPRobux
	end
	local vipButton = UI.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(240, 52),
		Text = vipText,
		BackgroundColor3 = data.VIP and GREEN or (Shop.VIPPassId ~= 0 and GOLD or GREY),
		TextColor3 = Color3.fromRGB(30, 20, 0),
		Parent = vip,
	}, { UI.gloss() })
	vipButton.Activated:Connect(function()
		if not data.VIP and Shop.VIPPassId ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, Shop.VIPPassId)
		end
	end)
end

---------------------------------------------------------------------------

local lastBuiltTab = nil

function refresh()
	if not content then
		return
	end
	-- Si se reconstruye la misma pestaña, se mantiene la posición del scroll
	local keepScroll = nil
	if lastBuiltTab == currentTab then
		local old = content:FindFirstChildOfClass("ScrollingFrame")
		keepScroll = old and old.CanvasPosition
	end
	lastBuiltTab = currentTab
	for _, child in content:GetChildren() do
		child:Destroy()
	end
	local data = ClientState.Data
	if headerInfo then
		headerInfo.Text = data and ("Nivel " .. data.Level .. "   " .. coinsText(data.Coins) .. (data.VIP and "   👑" or "")) or "Cargando..."
	end
	for name, button in tabButtons do
		button.BackgroundColor3 = name == currentTab and BLUE or CARD_BG
	end
	-- Aviso en Perfil si hay logros por reclamar
	if tabButtons.Perfil and data then
		local claimable = claimableAchievements(data)
		tabButtons.Perfil.Text = claimable > 0 and ("Perfil 🔴" .. claimable) or "Perfil"
	end
	if not data then
		UI.label({ Size = UDim2.fromScale(1, 1), Text = "Cargando datos...", TextSize = 24, Parent = content })
		return
	end
	if currentTab == "Perfil" then
		buildProfilePage(data)
	elseif currentTab == "Pase" then
		buildPassPage(data)
	elseif currentTab == "Retos" then
		buildChallengesPage(data)
	elseif currentTab == "Armas" then
		buildWeaponsPage(data)
	elseif currentTab == "Skins" then
		buildSkinsPage(data)
	elseif currentTab == "Trajes" then
		buildOutfitsPage(data)
	elseif currentTab == "Efectos" then
		buildKillEffectsPage(data)
	elseif currentTab == "Ajustes" then
		buildSettingsPage()
	else
		buildShopPage(data)
	end
	if keepScroll then
		local scroll = content:FindFirstChildOfClass("ScrollingFrame")
		if scroll then
			task.defer(function()
				scroll.CanvasPosition = keepScroll
			end)
		end
	end
end

local menuModal -- botón Modal a nivel de pantalla: libera el ratón aunque el panel esté oculto

local function setOpen(open)
	if not open and crateOverlay then
		return -- no se cierra a mitad de abrir una caja
	end
	ClientState.MenuOpen = open
	if not open then
		ClientState.MenuClosedAt = os.clock()
	end
	panel.Visible = open
	if menuModal then
		menuModal.Visible = open
	end
	ClientState.UpdateMouse()
	if open then
		refresh()
	end
end

function Menu.Toggle()
	-- Durante la vista previa de un efecto el panel está oculto pero el menú sigue abierto
	setOpen(not ClientState.MenuOpen)
end

-- Abre el menú directamente en una pestaña
function Menu.Open(tab)
	if tab then
		currentTab = tab
	end
	setOpen(true)
end

function Menu.Close()
	if ClientState.MenuOpen then
		setOpen(false)
	end
end

function Menu.IsOpen()
	return panel ~= nil and ClientState.MenuOpen
end

-- Recoge la recompensa diaria (también se usa desde la pantalla de inicio)
function Menu.ClaimDaily()
	if busy then
		return false
	end
	busy = true
	local ok, success, result = pcall(function()
		return Remotes.ClaimDaily:InvokeServer()
	end)
	busy = false
	if ok and success and type(result) == "table" then
		Sounds.Play("Kill")
		showToast("Día " .. result.Streak .. ": +" .. result.Coins .. " monedas" .. (result.Crate and " y una caja gratis 🎁" or ""), GOLD)
		return true
	end
	showToast("Ya la has recogido hoy. ¡Vuelve mañana!")
	return false
end

function Menu.Init()
	gui = UI.new("ScreenGui", {
		Name = "Menu",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- Botón superior (útil en móvil)
	local open = UI.button({
		Position = UDim2.fromOffset(16, 58),
		Size = UDim2.fromOffset(210, 38),
		Text = "⭐ PASE · TIENDA",
		BackgroundColor3 = Color3.fromRGB(255, 120, 30),
		TextSize = 18,
		Parent = gui,
	}, { UI.stroke(Color3.new(0, 0, 0), 2, 0.3), UI.gloss() })
	open.Activated:Connect(Menu.Toggle)

	panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.new(0.92, 0, 0.84, 0),
		BackgroundColor3 = PANEL_BG,
		Active = true, -- los clics y toques no atraviesan el panel
		Visible = false,
		Parent = gui,
	}, {
		UI.corner(16),
		UI.stroke(Color3.fromRGB(255, 140, 40), 3, 0),
		UI.padding(16),
		UI.new("UISizeConstraint", { MaxSize = Vector2.new(1100, 640) }),
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 120, 200)),
			Rotation = 120,
		}),
	})

	-- Botón "Modal": libera el ratón en primera persona mientras el menú está abierto
	menuModal = UI.new("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Visible = false, Parent = gui })

	-- En pantallas pequeñas (móviles) todo el panel se escala para que quepa entero
	local panelScale = UI.new("UIScale", { Parent = panel })
	local function rescalePanel()
		local viewport = workspace.CurrentCamera.ViewportSize
		local s = math.clamp(math.min(viewport.X / 1150, viewport.Y / 700), 0.5, 1)
		panelScale.Scale = s
		panel.Size = UDim2.fromScale(math.min(0.92 / s, 1 / s), math.min(0.84 / s, 0.95 / s))
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescalePanel)
	rescalePanel()

	UI.label({
		Size = UDim2.fromOffset(400, 36),
		Text = "⚡ " .. GameConfig.GameTitle,
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 170, 50),
		Parent = panel,
	})
	headerInfo = UI.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.fromOffset(360, 36),
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

	-- Barra de pestañas con desplazamiento horizontal (en pantallas estrechas no caben todas)
	local tabs = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 3,
		Parent = panel,
	}, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, name in TABS do
		local button = UI.button({
			LayoutOrder = i,
			Size = UDim2.fromOffset(name == "Ajustes" and 52 or 112, 38),
			Text = name == "Tienda" and "🛒 Tienda" or name == "Retos" and "🎯 Retos" or name == "Efectos" and "💥 Efectos" or name == "Ajustes" and "⚙" or name,
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
		Position = UDim2.fromOffset(0, 96),
		Size = UDim2.new(1, 0, 1, -96),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	toast = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.fromOffset(700, 36),
		Text = "",
		TextSize = 24,
		TextStrokeTransparency = 0,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	})

	ContextActionService:BindAction("Menu", function(_, state)
		-- Muerto, la B es "Revivir instantáneo" (pantalla de muerte); solo sirve para cerrar la tienda
		if state == Enum.UserInputState.Begin and (not ClientState.Dead or ClientState.MenuOpen) then
			Menu.Toggle()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.B, Enum.KeyCode.ButtonSelect)

	-- Si se cancela la compra del pack de inicio, el botón vuelve a estar disponible
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
		local single = productId == Shop.StarterPack.ProductId or productId == Shop.HalloweenBundle.ProductId
		if userId == player.UserId and single and not purchased and ClientState.MenuOpen then
			refresh()
		end
	end)

	-- Una baja puede mandar varias actualizaciones seguidas: se agrupan en una sola reconstrucción
	local refreshQueued = false
	ClientState.DataChanged.Event:Connect(function()
		if not panel.Visible or refreshQueued then
			return
		end
		refreshQueued = true
		task.delay(0.4, function()
			refreshQueued = false
			if panel.Visible then
				refresh()
			end
		end)
	end)
end

return Menu
