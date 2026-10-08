-- PASE DE BATALLA: la temporada con su reloj real, tu nivel y tu XP, la pista horizontal con la vía
-- GRATIS y la PREMIUM (se desplaza; empieza en tu nivel), la recompensa elegida en grande con
-- RECLAMAR o PREVISUALIZAR, RECLAMAR TODO y las misiones de temporada. Comprar el premium o un nivel
-- solo se ofrece aquí, en un botón, sin ventanas. Lo reclamado entra deslizándose por la derecha.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Catalog = require(Shared.Economy.CosmeticCatalog)
local Products = require(Shared.Economy.Products)
local BattlePassConfig = require(Shared.Economy.BattlePassConfig)

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
local Inspect = require(StoreFolder.Inspect)
local Reveal = require(StoreFolder.Reveal)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)
local GOLD = Color3.fromRGB(255, 200, 60)

local Pass = {}

local flow, rootFrame, screen, titleLabel, seasonLabel, timerLabel, tierLabel, xpBar, xpLabel
local claimAllButton, premiumButton, skipButton, track, trackScroller, detail, missionsPanel, missionsList, missionsToggle
local slideLayer
local cells = {} -- [tier .. track] = { Frame, Tier, Track }
local selected = { Tier = 1, Track = "Free" }
local claiming = false

local function isPhone()
	return C.Breakpoint() == "PHONE"
end

local function cellSize()
	return isPhone() and 72 or 104
end

local function view()
	local data = ClientState.Data
	return data and data.Pass or nil
end

local function season()
	local v = view()
	return v and BattlePassConfig.Get(v.Season) or BattlePassConfig.Current(math.floor(StoreData.Now()))
end

-- Ficha de una recompensa: item del catálogo o monedas
local function rewardInfo(reward)
	if not reward then
		return nil
	end
	if reward.Type == "Coins" then
		return { Coins = reward.Amount, Name = reward.Amount .. " MONEDAS", Rarity = reward.Amount >= 500 and "Épico" or "Raro", Icon = "🪙" }
	elseif reward.Type == "Crate" then
		return { Name = (reward.Amount or 1) .. " CAJA", Rarity = "Raro", Icon = "📦" }
	end
	return Catalog.Item(reward.Type, reward.Id)
end

-- "Claimed" | "Claimable" | "Locked" | "NeedPremium" | "Empty"
local function cellState(tier, trackName)
	local s = season()
	local v = view()
	local reward = s and s.Tiers[tier] and s.Tiers[tier][trackName]
	if not reward then
		return "Empty"
	end
	if not v then
		return "Locked"
	end
	if v[trackName] and v[trackName][tostring(tier)] then
		return "Claimed"
	end
	if trackName == "Premium" and not v.HasPremium then
		return "NeedPremium"
	end
	if tier > (v.Tier or 1) then
		return "Locked"
	end
	return "Claimable"
end

---------------------------------------------------------------------------
-- Recompensas que entran por la derecha
---------------------------------------------------------------------------

local function slideIn(granted)
	for i, reward in granted do
		task.delay((i - 1) * 0.12, function()
			if not slideLayer.Parent then
				return
			end
			local info = reward.Type == "Coins" and { Name = "+" .. reward.Amount .. " MONEDAS", Icon = "🪙", Rarity = "Raro" } or Catalog.Item(reward.Type, reward.Id) or { Name = tostring(reward.Id), Rarity = "Común" }
			local row = C.panel({ Name = "Slide", Size = UDim2.fromOffset(300, 56), Parent = slideLayer }, { Alpha = 0.05, Accent = ItemArt.RarityColor(info.Rarity), StrokeColor = ItemArt.RarityColor(info.Rarity), StrokeAlpha = 0.4 })
			C.text({ Text = info.Icon or "★", TextSize = 26, AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(40, 56), Parent = row })
			C.text({ Text = C.upper(info.Name or ""), Role = "TitleItalic", TextSize = 18, Scaled = true, Position = UDim2.fromOffset(52, 6), Size = UDim2.new(1, -60, 0, 24), Parent = row })
			C.text({ Text = reward.Duplicate and ("YA LO TENÍAS: +" .. (reward.Coins or 0) .. " 🪙") or ("NIVEL " .. tostring(reward.Tier or "") .. " · " .. (reward.Track == "Premium" and "PREMIUM" or "GRATIS")), Role = "Title", TextSize = 12, Color = Colors.TextDim, Position = UDim2.fromOffset(52, 30), Size = UDim2.new(1, -60, 0, 18), Parent = row })
			Transition.SlideIn(row, Vector2.new(320, 0), 0.25)
			UISound.Play("Claim", 1 + i * 0.05)
			task.delay(2.6, function()
				if row.Parent then
					Transition.FadeOut(row, 0.25, true)
					task.delay(0.3, function()
						row:Destroy()
					end)
				end
			end)
		end)
	end
end

local function claim(tier, trackName)
	if claiming then
		return
	end
	claiming = true
	local ok, success, result = pcall(function()
		return Remotes.ClaimPass:InvokeServer(tier, trackName)
	end)
	claiming = false
	if ok and success and type(result) == "table" then
		Transition.Flash(Colors.Yellow, 0.18, 0.3)
		slideIn(result)
	else
		UISound.Play("Error")
	end
end

---------------------------------------------------------------------------
-- Pintar
---------------------------------------------------------------------------

local function renderDetail()
	for _, child in detail:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local s = season()
	local entry = s and s.Tiers[selected.Tier]
	local reward = entry and entry[selected.Track]
	local info = rewardInfo(reward)
	local phone = isPhone()
	if not info then
		C.text({ Text = "Nada en este nivel", Role = "Body", TextSize = 14, Color = Colors.TextDim, Position = UDim2.fromOffset(14, 14), Size = UDim2.new(1, -28, 0, 20), Parent = detail })
		return
	end
	-- (en el teléfono, una tira baja: imagen, nombre y botones a la derecha)
	local thumbSize = phone and 50 or 120
	local pad = phone and 7 or 12
	if info.Kind then
		ItemArt.Thumb(detail, info, { Position = UDim2.fromOffset(pad, pad), Size = UDim2.fromOffset(thumbSize, thumbSize) })
	else
		local art = ItemArt.Backdrop(detail, info.Rarity, { Position = UDim2.fromOffset(pad, pad), Size = UDim2.fromOffset(thumbSize, thumbSize) })
		C.text({ Text = info.Icon, TextSize = 50, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromScale(0.15, 0.12), Size = UDim2.fromScale(0.7, 0.7), Parent = art })
	end
	local x = thumbSize + pad * 2
	local textRight = phone and 220 or 12
	C.text({ Text = (selected.Track == "Premium" and "PREMIUM" or "GRATIS") .. "  ·  NIVEL " .. selected.Tier, Role = "Title", TextSize = phone and 11 or 13, Color = selected.Track == "Premium" and GOLD or Colors.TextDim, Position = UDim2.fromOffset(x, pad), Size = UDim2.new(1, -x - textRight, 0, phone and 14 or 18), Parent = detail })
	C.text({ Text = C.upper(info.Name or ""), Role = "TitleItalic", TextSize = phone and 18 or 28, Scaled = true, Position = UDim2.fromOffset(x, phone and 20 or 30), Size = UDim2.new(1, -x - textRight, 0, phone and 22 or 34), Parent = detail })
	C.text({ Text = C.upper(info.Rarity or "") .. (info.Label and ("  ·  " .. info.Label) or ""), Role = "Title", TextSize = phone and 11 or 13, Color = ItemArt.RarityColor(info.Rarity), Scaled = phone, Position = UDim2.fromOffset(x, phone and 42 or 66), Size = UDim2.new(1, -x - textRight, 0, phone and 14 or 18), Parent = detail })
	local state = cellState(selected.Tier, selected.Track)
	local text = ({ Claimable = "RECLAMAR", Claimed = "✓ RECLAMADO", Locked = "LLEGA AL NIVEL " .. selected.Tier, NeedPremium = "ES DEL PASE PREMIUM", Empty = "" })[state]
	local actionPosition = phone and UDim2.new(1, -(pad + 44 + 6 + 160), 0, 12) or UDim2.fromOffset(x, 92)
	local action = C.button({ Name = "Claim", Text = text, Style = state == "Claimable" and "Primary" or "Ghost", TextSize = phone and 13 or 17, Position = actionPosition, Size = UDim2.fromOffset(phone and 160 or 190, phone and 40 or 44), Parent = detail, Sound = "Click", OnClick = function()
		if cellState(selected.Tier, selected.Track) == "Claimable" then
			claim(selected.Tier, selected.Track)
		end
	end })
	local _ = action
	if info.Kind then
		C.button({ Name = "Preview", Text = "", Icon = "👁", Style = "Ghost", TextSize = 18, Position = phone and UDim2.new(1, -(pad + 44), 0, 12) or UDim2.fromOffset(x + 198, 92), Size = UDim2.fromOffset(phone and 44 or 48, phone and 40 or 44), Parent = detail, OnClick = function()
			Inspect.Open(rootFrame, info, {
				OnBuy = function() end,
				OnEquip = function(item)
					StoreData.Equip(item.Kind, item.Id)
					UISound.Play("Equip")
				end,
			})
		end })
	end
end

local function cellArt(holder, info)
	if info.Kind then
		ItemArt.Thumb(holder, info, { Size = UDim2.fromScale(1, 1) })
	else
		local art = ItemArt.Backdrop(holder, info.Rarity, { Size = UDim2.fromScale(1, 1) })
		C.text({ Text = info.Icon, TextSize = 34, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromScale(0.2, 0.1), Size = UDim2.fromScale(0.6, 0.5), Parent = art })
		C.text({ Text = info.Coins and tostring(info.Coins) or info.Name, Role = "Number", TextSize = 18, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Scaled = true, Position = UDim2.fromScale(0.05, 0.64), Size = UDim2.fromScale(0.9, 0.28), Parent = art })
	end
end

local function renderTrack()
	for _, child in track:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(cells)
	local s = season()
	if not s then
		return
	end
	local v = view()
	local cell = cellSize()
	for tier = 1, BattlePassConfig.Tiers do
		local column = C.new("Frame", { Name = "Tier_" .. tier, BackgroundTransparency = 1, Size = UDim2.fromOffset(cell + 8, cell * 2 + 44), LayoutOrder = tier, Parent = track })
		local reached = v and tier <= (v.Tier or 1)
		local number = C.new("Frame", { Name = "Number", BackgroundColor3 = reached and Colors.Yellow or Colors.PanelLight, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 0, 24), Parent = column }, { C.corner(3) })
		C.text({ Text = tostring(tier), Role = "Number", TextSize = 16, Color = reached and DARK or Colors.TextDim, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = number })
		for row, trackName in { "Free", "Premium" } do
			local reward = s.Tiers[tier] and s.Tiers[tier][trackName]
			local info = rewardInfo(reward)
			local holder = C.new("TextButton", { Name = trackName, Text = "", AutoButtonColor = false, BackgroundColor3 = Colors.Panel, BackgroundTransparency = 0.3, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 30 + (row - 1) * (cell + 8)), Size = UDim2.fromOffset(cell, cell), Parent = column }, {
				C.corner(4),
				C.stroke(trackName == "Premium" and GOLD or Colors.Line, trackName == "Premium" and 1.5 or 1, trackName == "Premium" and 0.4 or 0.85),
			})
			if info then
				cellArt(holder, info)
			end
			local state = cellState(tier, trackName)
			if state == "Claimed" then
				local shade = C.new("Frame", { Name = "Shade", BackgroundColor3 = Colors.Black, BackgroundTransparency = 0.45, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = holder }, { C.corner(4) })
				C.text({ Text = "✓", Role = "Title", TextSize = 30, Color = Colors.Green, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = shade })
			elseif state == "Locked" or state == "NeedPremium" then
				local shade = C.new("Frame", { Name = "Shade", BackgroundColor3 = Colors.Black, BackgroundTransparency = state == "Locked" and 0.5 or 0.35, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = holder }, { C.corner(4) })
				C.text({ Text = "🔒", TextSize = 16, AlignX = Enum.TextXAlignment.Right, AlignY = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(-4, 4), Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = shade })
			elseif state == "Claimable" then
				local stroke = holder:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = Colors.Yellow
					stroke.Thickness = 2.5
					stroke.Transparency = 0
				end
				local tag = C.new("Frame", { Name = "ClaimTag", BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.new(1, -10, 0, 16), ZIndex = 4, Parent = holder }, { C.corner(3) })
				C.text({ Text = "RECLAMAR", Role = "Title", TextSize = 13, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = tag })
			end
			if selected.Tier == tier and selected.Track == trackName then
				C.new("UIStroke", { Name = "Selected", Color = Colors.White, Thickness = 3, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = holder })
			end
			C.feel(holder, { Silent = true })
			holder.Activated:Connect(function()
				UISound.Play("Click")
				selected = { Tier = tier, Track = trackName }
				Pass.Render(true)
				if cellState(tier, trackName) == "Claimable" then
					claim(tier, trackName)
				end
			end)
			cells[tier .. trackName] = { Frame = holder, Tier = tier, Track = trackName }
		end
	end
end

local function renderMissions()
	for _, child in missionsList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local v = view()
	for i, mission in v and v.Missions or {} do
		local row = C.new("Frame", { Name = "Mission_" .. mission.Id, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = i, Parent = missionsList })
		C.text({ Text = (mission.Done and "✓ " or "") .. mission.Text, Role = "BodyBold", TextSize = 13, Color = mission.Done and Colors.Green or Colors.Text, Size = UDim2.new(1, -90, 0, 18), Parent = row })
		C.text({ Text = "+" .. mission.XP .. " XP", Role = "Number", TextSize = 13, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(86, 18), Parent = row })
		local bar = C.progress({ Size = UDim2.new(1, -60, 0, 6), Position = UDim2.fromOffset(0, 24), Color = mission.Done and Colors.Green or Colors.Yellow, Value = mission.Progress / math.max(1, mission.Goal), Parent = row })
		local _ = bar
		C.text({ Text = mission.Progress .. "/" .. mission.Goal, Role = "Number", TextSize = 12, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 19), Size = UDim2.fromOffset(56, 16), Parent = row })
	end
	local note = C.text({ Name = "Note", Text = string.format("Las misiones diarias (+%d) y semanales (+%d) también dan XP del pase.", BattlePassConfig.DailyMissionXP, BattlePassConfig.WeeklyMissionXP), Role = "Body", TextSize = 12, Color = Colors.TextDim, Wrap = true, Size = UDim2.new(1, 0, 0, 30), Order = 99, Parent = missionsList })
	local _ = note
end

local function renderHeader()
	local v = view()
	local s = season()
	seasonLabel.Text = s and (s.Name .. "  ·  " .. s.Title) or "ENTRE TEMPORADAS"
	local tier = v and v.Tier or 1
	tierLabel.Text = "NIVEL " .. tier
	local maxed = tier >= BattlePassConfig.Tiers
	local into = v and (v.XP - BattlePassConfig.XPFor(tier)) or 0
	xpBar:Set(maxed and 1 or into / BattlePassConfig.XPPerTier)
	xpLabel.Text = maxed and "¡PASE COMPLETADO!" or string.format("%d / %d XP", into, BattlePassConfig.XPPerTier)
	local claimable = v and v.Claimable or 0
	local claimLabel = claimAllButton:FindFirstChild("Label", true)
	claimLabel.Text = claimable > 0 and ("RECLAMAR TODO (" .. claimable .. ")") or "NADA POR RECLAMAR"
	claimAllButton.BackgroundColor3 = claimable > 0 and Colors.Yellow or Colors.PanelLight
	claimLabel.TextColor3 = claimable > 0 and DARK or Colors.TextDim
	local gradient = claimAllButton:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Enabled = claimable > 0
	end
	-- Premium: un botón (o la marca de que ya lo tienes)
	local premiumLabel = premiumButton:FindFirstChild("Label", true)
	if v and v.HasPremium then
		premiumLabel.Text = "✓ PREMIUM"
		premiumButton.BackgroundColor3 = Colors.PanelLight
		premiumLabel.TextColor3 = GOLD
	else
		local entry = s and s.Premium
		local pending = StoreData.Pending and s and StoreData.Pending.Key == "Pass:" .. s.Id
		premiumLabel.Text = pending and "PROCESANDO…" or (entry and Products.Enabled(entry) and ("PREMIUM · R$ " .. tostring(StoreData.Robux(entry))) or "PREMIUM · PRÓXIMAMENTE")
		premiumButton.BackgroundColor3 = GOLD
		premiumLabel.TextColor3 = DARK
	end
	-- Un nivel con Robux (pequeño, solo aquí)
	skipButton.Visible = not maxed and s ~= nil and (v and v.Active ~= false)
	local skipLabel = skipButton:FindFirstChild("Label", true)
	skipLabel.Text = Products.Enabled(Products.TierSkip) and ("+1 NIVEL · R$ " .. tostring(StoreData.Robux(Products.TierSkip))) or "+1 NIVEL · PRÓXIMAMENTE"
end

function Pass.UpdateTimer()
	local s = season()
	if not s then
		timerLabel.Text = ""
		return
	end
	local left = s.EndsAt - StoreData.Now()
	timerLabel.Text = left > 0 and ("TERMINA EN " .. StoreData.FormatTime(left)) or "TEMPORADA TERMINADA"
end

-- keepScroll: no mover la pista (al tocar una casilla)
function Pass.Render(keepScroll)
	if not screen then
		return
	end
	renderHeader()
	renderTrack()
	renderDetail()
	renderMissions()
	Pass.UpdateTimer()
	if not keepScroll then
		-- (la pista empieza en tu nivel)
		local v = view()
		local tier = v and v.Tier or 1
		local cell = cellSize()
		task.defer(function()
			trackScroller.CanvasPosition = Vector2.new(math.max(0, (tier - 2) * (cell + 8 + 6)), 0)
		end)
	end
end

---------------------------------------------------------------------------
-- Pantalla
---------------------------------------------------------------------------

local progressRow

local function applyLayout()
	local phone = isPhone()
	local cell = cellSize()
	titleLabel.TextSize = phone and 32 or 46
	titleLabel.Position = UDim2.fromOffset(phone and 166 or 170, phone and 6 or 10)
	seasonLabel.Position = UDim2.fromOffset(phone and 168 or 172, phone and 44 or 60)
	seasonLabel.TextSize = phone and 13 or 16
	timerLabel.Position = UDim2.fromOffset(phone and 168 or 172, phone and 60 or 80)
	-- Premium y +1 nivel arriba a la derecha (en el teléfono, en una fila)
	premiumButton.Position = UDim2.new(1, phone and -16 or -24, 0, phone and 10 or 18)
	premiumButton.Size = UDim2.fromOffset(phone and 210 or 280, phone and 38 or 48)
	skipButton.Position = phone and UDim2.new(1, -234, 0, 10) or UDim2.new(1, -24, 0, 72)
	skipButton.Size = UDim2.fromOffset(phone and 150 or 200, phone and 38 or 34)
	-- Progreso
	progressRow.Position = UDim2.fromOffset(phone and 16 or 24, phone and 80 or 108)
	progressRow.Size = UDim2.new(1, phone and -32 or -48, 0, phone and 34 or 44)
	tierLabel.TextSize = phone and 22 or 30
	tierLabel.Size = UDim2.fromOffset(phone and 96 or 150, phone and 34 or 40)
	claimAllButton.Size = UDim2.fromOffset(phone and 170 or 280, phone and 32 or 42)
	missionsToggle.Visible = phone
	missionsToggle.Parent = phone and progressRow or screen
	missionsToggle.AnchorPoint = Vector2.new(1, 0.5)
	missionsToggle.Position = UDim2.new(1, -178, 0.5, 0)
	missionsToggle.Size = UDim2.fromOffset(112, 32)
	local barRight = phone and (170 + 120 + 70) or 300
	xpBar.Frame.Position = UDim2.new(0, phone and 100 or 156, 0.5, 0)
	xpBar.Frame.Size = UDim2.new(1, -((phone and 100 or 156) + barRight + 10), 0, phone and 8 or 10)
	xpLabel.Position = UDim2.new(1, -(barRight - (phone and 64 or 0)), 0.5, 0)
	xpLabel.Size = UDim2.fromOffset(phone and 64 or 150, 18)
	xpLabel.TextSize = phone and 11 or 14
	-- Pista
	local trackTop = phone and 120 or 160
	local left = phone and 76 or 110
	trackScroller.Position = UDim2.fromOffset(left, trackTop)
	trackScroller.Size = UDim2.new(1, -(left + (phone and 16 or 24)), 0, cell * 2 + 46)
	local free, premium = screen:FindFirstChild("FreeLabel"), screen:FindFirstChild("PremiumLabel")
	free.Position = UDim2.fromOffset(phone and 12 or 24, trackTop + 30)
	free.Size = UDim2.fromOffset(phone and 58 or 80, cell)
	premium.Position = UDim2.fromOffset(phone and 12 or 24, trackTop + 30 + cell + 8)
	premium.Size = UDim2.fromOffset(phone and 58 or 80, cell)
	-- Recompensa elegida y misiones
	local below = trackTop + cell * 2 + (phone and 50 or 66)
	detail.Position = UDim2.fromOffset(phone and 16 or 24, below)
	detail.Size = UDim2.new(phone and 1 or 0.5, phone and -32 or -36, 0, phone and 64 or 146)
	missionsPanel.Visible = not phone
	missionsPanel.Position = phone and UDim2.fromOffset(16, 56) or UDim2.new(0.5, 12, 0, below)
	missionsPanel.Size = phone and UDim2.new(1, -32, 1, -66) or UDim2.new(0.5, -36, 1, -(below + 18))
	slideLayer.Position = UDim2.new(1, phone and -16 or -24, 0, trackTop)
end

-- Al entrar: la primera recompensa por reclamar, o la de tu nivel
local function defaultSelection()
	local v = view()
	local tier = v and v.Tier or 1
	for t = 1, tier do
		for _, trackName in { "Free", "Premium" } do
			if cellState(t, trackName) == "Claimable" then
				return { Tier = t, Track = trackName }
			end
		end
	end
	for t = tier, BattlePassConfig.Tiers do
		if cellState(t, "Free") ~= "Empty" then
			return { Tier = t, Track = "Free" }
		elseif cellState(t, "Premium") ~= "Empty" then
			return { Tier = t, Track = "Premium" }
		end
	end
	return { Tier = tier, Track = "Free" }
end

function Pass.Build(flowController, root)
	flow = flowController
	rootFrame = root
	StoreData.Init()
	Reveal.Init()
	Reveal.OnOpenPass = function()
		if flow.Lobby[flow.State] then
			flow.SetState("Pass")
		end
	end
	screen = C.new("Frame", { Name = "Pass", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	C.button({ Name = "Back", Text = "VOLVER", Icon = "◀", Style = "Ghost", TextSize = 16, Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(130, 40), Parent = screen, Sound = "Back", OnClick = function()
		flow.SetState("Home")
	end })
	titleLabel = C.text({ Text = "PASE DE BATALLA", Role = "TitleItalic", TextSize = 46, Position = UDim2.fromOffset(170, 10), Size = UDim2.fromOffset(460, 54), Stroke = 2, Parent = screen })
	seasonLabel = C.text({ Text = "", Role = "Title", TextSize = 16, Color = Colors.YellowText, Position = UDim2.fromOffset(172, 60), Size = UDim2.fromOffset(420, 20), Parent = screen })
	timerLabel = C.text({ Name = "Timer", Text = "", Role = "Number", TextSize = 14, Color = Colors.TextDim, Position = UDim2.fromOffset(172, 80), Size = UDim2.fromOffset(300, 18), Parent = screen })
	-- Derecha arriba: premium y +1 nivel
	premiumButton = C.button({ Name = "Premium", Text = "PREMIUM", Icon = "🎖️", Style = "Primary", TextSize = 18, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 18), Size = UDim2.fromOffset(280, 48), Parent = screen, Sound = "Click", OnClick = function()
		local v = view()
		local s = season()
		if s and not (v and v.HasPremium) then
			local ok, reason = StoreData.PromptRobux({ Type = "PassPremium", Season = s.Id })
			if not ok then
				UISound.Play("Error")
				local label = premiumButton:FindFirstChild("Label", true)
				label.Text = reason
			end
		end
	end })
	skipButton = C.button({ Name = "TierSkip", Text = "+1 NIVEL", Style = "Ghost", TextSize = 14, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 72), Size = UDim2.fromOffset(200, 34), Parent = screen, OnClick = function()
		local ok = StoreData.PromptRobux({ Type = "TierSkip" })
		if not ok then
			UISound.Play("Error")
		end
	end })
	-- Progreso
	local progress = C.new("Frame", { Name = "Progress", BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 108), Size = UDim2.new(1, -48, 0, 44), Parent = screen })
	progressRow = progress
	tierLabel = C.text({ Name = "Tier", Text = "NIVEL 1", Role = "TitleItalic", TextSize = 30, Color = Colors.White, Size = UDim2.fromOffset(150, 40), Parent = progress })
	xpBar = C.progress({ Size = UDim2.new(1, -470, 0, 10), Position = UDim2.new(0, 156, 0.5, 0), Anchor = Vector2.new(0, 0.5), Parent = progress })
	xpLabel = C.text({ Name = "XP", Text = "", Role = "Number", TextSize = 14, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -300, 0.5, 0), Size = UDim2.fromOffset(150, 18), Parent = progress })
	claimAllButton = C.button({ Name = "ClaimAll", Text = "RECLAMAR TODO", Style = "Primary", TextSize = 17, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(280, 42), Parent = progress, Sound = "Click", OnClick = function()
		local v = view()
		if v and (v.Claimable or 0) > 0 then
			claim("All")
		end
	end })
	-- Pista
	C.text({ Name = "FreeLabel", Text = "GRATIS", Role = "TitleItalic", TextSize = 18, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Scaled = true, Parent = screen })
	C.text({ Name = "PremiumLabel", Text = "PREMIUM", Role = "TitleItalic", TextSize = 18, Color = GOLD, AlignX = Enum.TextXAlignment.Center, Scaled = true, Parent = screen })
	trackScroller = C.new("ScrollingFrame", { Name = "Track", BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 4, ScrollBarImageColor3 = Colors.Yellow, Parent = screen })
	track = C.new("Frame", { Name = "Columns", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = trackScroller }, {
		C.list(6, Enum.FillDirection.Horizontal),
	})
	-- Recompensa elegida
	detail = C.panel({ Name = "Detail", Parent = screen }, { Alpha = 0.12 })
	-- Misiones de temporada
	missionsPanel = C.panel({ Name = "Missions", ZIndex = 5, Parent = screen }, { Alpha = 0.06 })
	local missionsInner = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = missionsPanel }, { C.padding(10, 14, 10, 14) })
	C.header(missionsInner, "MISIONES DE TEMPORADA", nil, 0)
	missionsList = C.new("ScrollingFrame", { Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -30), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, Parent = missionsInner }, { C.list(6) })
	missionsToggle = C.button({ Name = "MissionsToggle", Text = "MISIONES", Icon = "🎯", Style = "Ghost", TextSize = 14, Anchor = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -10), Size = UDim2.fromOffset(150, 40), ZIndex = 6, Parent = screen, OnClick = function()
		missionsPanel.Visible = not missionsPanel.Visible
		missionsPanel.ZIndex = 9
		local label = missionsToggle:FindFirstChild("Label", true)
		label.Text = missionsPanel.Visible and "CERRAR" or "MISIONES"
	end })
	slideLayer = C.new("Frame", { Name = "Slides", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 160), Size = UDim2.fromOffset(300, 400), ZIndex = 8, Parent = screen }, {
		C.list(6),
	})
	ClientState.DataChanged.Event:Connect(function()
		if screen.Visible then
			Pass.Render(true)
		end
	end)
	StoreData.Changed.Event:Connect(function()
		if screen.Visible then
			renderHeader()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if screen.Visible then
				Pass.UpdateTimer()
			end
		end
	end)
	Pass.Screen = screen
end

function Pass.Show()
	local v = view()
	selected = defaultSelection()
	applyLayout()
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.62, 0.25)
	Transition.Blur(16, 0.25)
	screen.Visible = true
	Pass.Render(false)
	StoreData.Track("battlepass_open", { tier = v and v.Tier or 1 })
	Transition.SlideIn(trackScroller, Vector2.new(60, 0), 0.3)
end

function Pass.Hide()
	Inspect.Close()
	screen.Visible = false
end

return Pass
