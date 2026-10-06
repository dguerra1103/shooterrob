-- HOME / LOBBY: tu personaje real (copia 3D con tu traje y tu arma) en el centro, el menú a la
-- izquierda con JUGAR como acción dominante, perfil y monedas arriba, misiones diarias, evento y
-- arma destacada a la derecha, modo y rango abajo. Recoge todo lo que tenía la pantalla de inicio
-- (recompensa diaria, ruleta, pack de inicio, grupo, invitar, clasificación, mapa destacado).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SocialService = game:GetService("SocialService")
local GroupService = game:GetService("GroupService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Ranks = require(Shared.Ranks)
local Weapons = require(Shared.Weapons)

local Modules = script.Parent.Parent.Parent
local ClientState = require(Modules.ClientState)
local Menu = require(Modules.Menu)
local Wheel = require(Modules.Wheel)
local WeaponIcon = require(Modules.WeaponIcon)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Preview = require(Flow.Preview)

local player = Players.LocalPlayer
local Colors = Theme.Colors

local Home = {}

local flow, root, screen, preview
local refs: { [string]: any } = {}

local function isPhone()
	return C.Breakpoint() == "PHONE"
end

---------------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------------

local function buildLogo(parent)
	local logo = C.new("Frame", { Name = "Logo", BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(380, 84), Parent = parent })
	local title = tostring(GameConfig.GameTitle or "SHOOTER")
	local first, rest = string.match(title, "^(%S+)%s*(.*)$")
	C.text({
		Text = string.format('%s<font color="%s">%s</font>', C.upper(first or title), "#" .. Colors.Yellow:ToHex(), rest ~= "" and C.upper(rest) or ""),
		Rich = true,
		Role = "TitleItalic",
		TextSize = 54,
		Color = Colors.White,
		Size = UDim2.new(1, 0, 0, 58),
		Stroke = 2,
		Parent = logo,
	})
	local tag = C.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 58), Size = UDim2.new(1, 0, 0, 22), Parent = logo })
	C.new("Frame", { BackgroundColor3 = Colors.Red, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(60, 3), Parent = tag })
	C.text({ Text = "5 V 5", Role = "TitleItalic", TextSize = 20, AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(64, 0), Size = UDim2.fromOffset(60, 22), Parent = tag })
	C.new("Frame", { BackgroundColor3 = Colors.Red, BorderSizePixel = 0, Position = UDim2.fromOffset(128, 10), Size = UDim2.fromOffset(60, 3), Parent = tag })
	return logo
end

local function iconButton(parent, icon, order, onClick)
	local button = C.new("TextButton", {
		Name = "Icon_" .. icon,
		AutoButtonColor = false,
		Text = icon,
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		TextColor3 = Colors.White,
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = Theme.PanelAlpha,
		Size = UDim2.fromOffset(44, 44),
		LayoutOrder = order,
		Parent = parent,
	}, { C.corner(4), C.stroke() })
	C.feel(button)
	button.Activated:Connect(function()
		UISound.Play("Click")
		onClick(button)
	end)
	return button
end

local function buildTopBar(parent)
	local bar = C.new("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 18),
		Size = UDim2.fromOffset(720, 52),
		Parent = parent,
	}, { C.list(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right) })
	-- Perfil: foto, nombre, nivel y XP
	local profile = C.panel({ Name = "Profile", Size = UDim2.fromOffset(260, 52), Order = 1, Parent = bar })
	local thumb = C.new("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = Colors.PanelLight,
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(44, 44),
		Image = "",
		Parent = profile,
	}, { C.corner(3), C.stroke(Colors.Yellow, 1, 0.4) })
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and image then
			thumb.Image = image
		end
	end)
	C.text({ Text = player.DisplayName, Role = "Title", TextSize = 18, Size = UDim2.new(1, -62, 0, 22), Position = UDim2.fromOffset(56, 4), Parent = profile })
	refs.Level = C.text({ Name = "Level", Text = "NIVEL 1", Role = "Number", TextSize = 14, Color = Colors.YellowText, Size = UDim2.new(0, 70, 0, 16), Position = UDim2.fromOffset(56, 28), Parent = profile })
	refs.XP = C.progress({ Size = UDim2.new(1, -136, 0, 6), Position = UDim2.fromOffset(126, 34), Parent = profile })
	-- Monedas (con "+" a la tienda)
	local _, coins = C.currency(bar, "🪙", 2, function()
		Menu.Open("Tienda")
	end)
	refs.Coins = coins
	-- Amigos (invitar), novedades, retos y ajustes
	local friends = iconButton(bar, "👥", 3, function()
		Home.OpenClan()
	end)
	refs.FriendsDot = C.dot(friends, false)
	local news = iconButton(bar, "✉", 4, function()
		local ok, News = pcall(require, Modules.News)
		if ok and News.Open then
			News.Open()
		end
	end)
	refs.NewsDot = C.dot(news, false)
	iconButton(bar, "🔔", 5, function()
		Menu.Open("Retos")
	end)
	iconButton(bar, "⚙", 6, function()
		Menu.Open("Ajustes")
	end)
	return bar
end

local MENU = {
	{ Id = "Armory", Text = "ARMAMENTO", Icon = "🔫" },
	{ Id = "Operator", Text = "OPERADOR", Icon = "🪖" },
	{ Id = "Squad", Text = "ESCUADRA", Icon = "👥" },
	{ Id = "Shop", Text = "TIENDA", Icon = "🛒" },
	{ Id = "Pass", Text = "PASE DE BATALLA", Icon = "⭐" },
	{ Id = "Events", Text = "EVENTOS", Icon = "📅", Desktop = true },
	{ Id = "Clan", Text = "CLAN", Icon = "🛡", Desktop = true },
	{ Id = "Settings", Text = "AJUSTES", Icon = "⚙", Desktop = true },
}

local function onMenu(id)
	if id == "Armory" then
		flow.SetState("Armory")
	elseif id == "Operator" then
		flow.SetState("Operator")
	elseif id == "Squad" then
		flow.SetState("Squad")
	elseif id == "Shop" then
		Menu.Open("Tienda")
	elseif id == "Pass" then
		Menu.Open("Pase")
	elseif id == "Events" then
		Wheel.Open()
	elseif id == "Clan" then
		Home.OpenClan()
	elseif id == "Settings" then
		Menu.Open("Ajustes")
	end
end

local function buildLeft(parent)
	local column = C.new("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 110),
		Size = UDim2.fromOffset(300, 560),
		Parent = parent,
	}, { C.list(8) })
	refs.Play = C.button({
		Name = "Play",
		Text = "JUGAR",
		Icon = "▶",
		Sub = "PARTIDA 5 VS 5",
		Style = "Primary",
		TextSize = 34,
		Size = UDim2.fromOffset(300, 72),
		Order = 0,
		Parent = column,
		OnClick = function()
			flow.Play()
		end,
	})
	refs.Menu = {}
	for i, item in MENU do
		local button = C.button({
			Name = "Menu_" .. item.Id,
			Text = item.Text,
			Icon = item.Icon,
			Style = "Menu",
			TextSize = 20,
			Size = UDim2.fromOffset(300, 46),
			Order = i,
			Parent = column,
			OnClick = function()
				onMenu(item.Id)
			end,
		})
		button:SetAttribute("DesktopOnly", item.Desktop == true)
		refs.Menu[item.Id] = button
	end
	return column
end

local function missionRow(parent, order)
	local row = C.new("Frame", { Name = "Mission", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = order, Parent = parent })
	C.new("Frame", { Name = "Mark", BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, -6), Position = UDim2.fromOffset(0, 3), Parent = row })
	local text = C.text({ Name = "MissionText", Text = "", Role = "BodyBold", TextSize = 14, Size = UDim2.new(1, -120, 0, 20), Position = UDim2.fromOffset(10, 2), Parent = row })
	local count = C.text({ Name = "Count", Text = "", Role = "Number", TextSize = 15, AlignX = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(50, 20), Position = UDim2.new(1, -112, 0, 2), Parent = row })
	local reward = C.new("Frame", { Name = "Reward", BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(56, 26), Parent = row }, { C.corner(3) })
	local rewardText = C.text({ Text = "", Role = "Number", TextSize = 14, Color = Color3.fromRGB(16, 14, 8), AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = reward })
	local bar = C.progress({ Size = UDim2.new(1, -74, 0, 5), Position = UDim2.fromOffset(10, 30), Parent = row })
	return function(challenge)
		row.Visible = challenge ~= nil
		if not challenge then
			return
		end
		text.Text = tostring(challenge.Text or "")
		local progress = math.min(challenge.Progress or 0, challenge.Goal or 1)
		count.Text = string.format("%d/%d", progress, challenge.Goal or 1)
		bar:Set(challenge.Done and 1 or progress / math.max(1, challenge.Goal or 1))
		rewardText.Text = challenge.XP and (tostring(challenge.XP) .. " XP") or (tostring(challenge.Coins or 0) .. " 🪙")
		reward.BackgroundColor3 = challenge.Done and Colors.Green or Colors.Yellow
	end
end

local function buildRight(parent)
	local column = C.new("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 84),
		Size = UDim2.fromOffset(350, 520),
		Parent = parent,
	}, { C.list(10) })
	-- Recompensa diaria (solo cuando está disponible)
	refs.Daily = C.button({
		Name = "Daily",
		Text = "RECOMPENSA DIARIA",
		Icon = "🎁",
		Sub = "TOCA PARA RECOGER",
		Style = "Primary",
		TextSize = 22,
		Size = UDim2.new(1, 0, 0, 56),
		Order = 0,
		Parent = column,
		Sound = "Reward",
		OnClick = function()
			if Menu.ClaimDaily() then
				refs.Daily.Visible = false
				Transition.Flash(Colors.Yellow, 0.25, 0.3)
			end
		end,
	})
	refs.Daily.Visible = false
	-- Avisos cortos: pack de inicio, ruleta gratis, XP doble, primera victoria del día
	local chips = C.new("Frame", { Name = "Chips", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 0, Parent = column }, {
		C.list(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right),
	})
	local function chip(name, text, color, order, onClick)
		local button = C.button({ Name = name, Text = text, Style = "Ghost", TextSize = 13, Size = UDim2.fromOffset(0, 30), Order = order, Parent = chips, OnClick = onClick })
		button.AutomaticSize = Enum.AutomaticSize.X
		button.BackgroundColor3 = color
		button.BackgroundTransparency = 0.15
		local label = button:FindFirstChild("Label", true)
		if label then
			label.AutomaticSize = Enum.AutomaticSize.X
			label.TextColor3 = color == Colors.Yellow and Color3.fromRGB(16, 14, 8) or Colors.White
		end
		C.padding(0, 10, 0, 10).Parent = button
		return button
	end
	refs.ChipStarter = chip("Starter", "🎁 PACK DE INICIO", Colors.Yellow, 1, function()
		Menu.Open("Tienda")
	end)
	refs.ChipWheel = chip("Wheel", "🎡 RULETA GRATIS", Colors.RedDark, 2, function()
		Wheel.Open()
	end)
	refs.ChipBoost = chip("Boost", "⚡ XP DOBLE", Colors.Blue, 3, function() end)
	refs.ChipFirstWin = chip("FirstWin", "🏆 1.ª VICTORIA +" .. tostring(GameConfig.FirstWinOfDay and GameConfig.FirstWinOfDay.Coins or 0) .. " 🪙", Colors.PanelLight, 4, function()
		flow.Play()
	end)
	refs.Chips = chips
	-- Misiones diarias
	local missions = C.panel({ Name = "Missions", Size = UDim2.new(1, 0, 0, 190), Order = 1, Parent = column })
	local inner = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = missions }, { C.padding(10, 12, 10, 12), C.list(6) })
	refs.MissionsHeader = C.header(inner, "MISIONES DIARIAS", "0/3", 0)
	refs.Missions = {}
	for i = 1, 3 do
		refs.Missions[i] = missionRow(inner, i)
	end
	-- Evento activo o mapa destacado (rojo: eventos)
	local event = C.button({ Name = "Event", Text = "", Style = "Ghost", Size = UDim2.new(1, 0, 0, 92), Order = 2, Parent = column, OnClick = function()
		Menu.Open("Retos")
	end })
	event.BackgroundColor3 = Colors.RedDark
	event.BackgroundTransparency = 0.15
	refs.EventTag = C.text({ Text = "EVENTO ACTIVO", Role = "Title", TextSize = 15, Color = Colors.White, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 20), ZIndex = 5, Parent = event })
	refs.EventName = C.text({ Text = "", Role = "TitleItalic", TextSize = 30, Color = Colors.White, Scaled = true, Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 34), ZIndex = 5, Parent = event })
	refs.EventSub = C.text({ Text = "", Role = "BodyBold", TextSize = 13, Color = Color3.fromRGB(255, 210, 200), Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 0, 20), ZIndex = 5, Parent = event })
	refs.Event = event
	-- Arma destacada (la siguiente que se desbloquea o una de la tienda)
	local promo = C.button({ Name = "Promo", Text = "", Style = "Ghost", Size = UDim2.new(1, 0, 0, 110), Order = 3, Parent = column, OnClick = function()
		flow.SetState("Armory")
	end })
	promo.BackgroundColor3 = Color3.fromRGB(20, 40, 90)
	promo.BackgroundTransparency = 0.1
	local tag = C.new("Frame", { BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(110, 22), ZIndex = 5, Parent = promo }, { C.corner(3) })
	C.text({ Text = "NUEVA ARMA", Role = "Title", TextSize = 14, Color = Color3.fromRGB(16, 14, 8), AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = tag })
	refs.PromoName = C.text({ Text = "", Role = "TitleItalic", TextSize = 28, Scaled = true, Position = UDim2.fromOffset(12, 30), Size = UDim2.new(0.55, 0, 0, 32), ZIndex = 5, Parent = promo })
	refs.PromoSub = C.text({ Text = "", Role = "BodyBold", TextSize = 13, Color = Colors.TextDim, Position = UDim2.fromOffset(12, 66), Size = UDim2.new(0.55, 0, 0, 34), Wrap = true, ZIndex = 5, Parent = promo })
	refs.PromoIcon = C.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.48, 0, 1, -10), ZIndex = 5, Parent = promo })
	refs.Promo = promo
	return column
end

local function buildBottom(parent)
	local row = C.new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -18),
		Size = UDim2.new(1, -48, 0, 76),
		Parent = parent,
	})
	-- Modo (lleva a JUGAR) y rango (abre la clasificación)
	local mode = C.button({ Name = "ModeCard", Text = "", Style = "Ghost", Size = UDim2.fromOffset(270, 76), Parent = row, OnClick = function()
		flow.Play()
	end })
	C.text({ Text = "MULTIJUGADOR 5V5", Role = "TitleItalic", TextSize = 22, Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 26), ZIndex = 5, Parent = mode })
	refs.ModeSub = C.text({ Text = "Combate táctico en equipo", Role = "BodyBold", TextSize = 13, Color = Colors.TextDim, Position = UDim2.fromOffset(14, 42), Size = UDim2.new(1, -28, 0, 20), ZIndex = 5, Parent = mode })
	refs.ModeCard = mode
	local ranked = C.button({ Name = "RankCard", Text = "", Style = "Ghost", Position = UDim2.fromOffset(282, 0), Size = UDim2.fromOffset(280, 76), Parent = row, OnClick = function()
		Home.OpenLeaderboard()
	end })
	refs.RankTitle = C.text({ Text = "", Role = "TitleItalic", TextSize = 22, Rich = true, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 26), ZIndex = 5, Parent = ranked })
	refs.RankBar = C.progress({ Size = UDim2.new(1, -28, 0, 6), Position = UDim2.fromOffset(14, 40), ZIndex = 5, Parent = ranked })
	refs.RankNext = C.text({ Text = "", Role = "BodyBold", TextSize = 12, Color = Colors.TextDim, Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -28, 0, 18), ZIndex = 5, Parent = ranked })
	refs.RankCard = ranked
	-- Accesos rápidos a la derecha
	local quick = C.new("Frame", { Name = "Quick", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 14), Size = UDim2.fromOffset(600, 56), Parent = row }, {
		C.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right),
	})
	for i, spec in {
		{ "INVENTARIO", "🎒", function() Menu.Open("Skins") end },
		{ "ARMAS", "🔫", function() flow.SetState("Armory") end },
		{ "RACHAS", "✈", function() Home.OpenStreaks() end },
		{ "PERSONALIZAR", "👕", function() flow.SetState("Operator") end },
	} do
		C.button({ Name = "Quick_" .. spec[1], Text = spec[1], Icon = spec[2], Style = "Ghost", TextSize = 15, Size = UDim2.fromOffset(140, 50), Order = i, Parent = quick, OnClick = spec[3] })
	end
	refs.Quick = quick
	return row
end

---------------------------------------------------------------------------
-- Ventanas encima (clasificación, clan, rachas)
---------------------------------------------------------------------------

local overlay
local function openOverlay(title, height)
	if overlay then
		overlay:Destroy()
	end
	overlay = C.new("Frame", { Name = "Overlay", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = screen })
	local blocker = C.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = overlay })
	blocker.Activated:Connect(function()
		overlay:Destroy()
		overlay = nil
	end)
	local panel = C.panel({ Name = "Window", Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, height or 360), ZIndex = 41, Parent = overlay }, { Alpha = 0.05, StrokeColor = Colors.Yellow, StrokeAlpha = 0.5 })
	C.text({ Text = title, Role = "TitleItalic", TextSize = 28, Color = Colors.White, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -70, 0, 34), ZIndex = 42, Parent = panel })
	local close = C.button({ Name = "Close", Text = "✕", Style = "Ghost", TextSize = 18, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 36), ZIndex = 43, Parent = panel, Sound = "Back", OnClick = function()
		if overlay then
			overlay:Destroy()
			overlay = nil
		end
	end })
	close.ZIndex = 43
	Transition.Pop(panel, 0.92, 0.18)
	local body = C.new("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 52), Size = UDim2.new(1, -32, 1, -64), ZIndex = 42, Parent = panel })
	return body
end

function Home.OpenLeaderboard()
	local body = openOverlay("CLASIFICACIÓN", 420)
	local tabs = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ZIndex = 42, Parent = body }, { C.list(6, Enum.FillDirection.Horizontal) })
	local list = C.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -42), ZIndex = 42, Parent = body }, { C.list(3) })
	local board = "Kills"
	local buttons = {}
	local function render()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for id, button in buttons do
			C.setSelected(button, id == board)
		end
		local raw = ReplicatedStorage:GetAttribute("Leaderboard_" .. board)
		local ok, rows = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if type(raw) ~= "string" or not ok or type(rows) ~= "table" or #rows == 0 then
			C.text({ Text = "Aún no hay datos. ¡Sé el primero!", Role = "BodyBold", TextSize = 16, Color = Colors.TextDim, ZIndex = 43, Parent = list })
			return
		end
		for i, row in rows do
			if i > 10 then
				break
			end
			local me = row.UserId == player.UserId
			local line = C.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 27), BackgroundColor3 = me and Colors.Yellow or Colors.PanelLight, BackgroundTransparency = me and 0.75 or 0.5, BorderSizePixel = 0, ZIndex = 42, Parent = list }, { C.corner(3) })
			C.text({ Text = "#" .. tostring(row.Rank or i), Role = "Number", TextSize = 16, Color = i <= 3 and Colors.YellowText or Colors.TextDim, Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(40, 27), ZIndex = 43, Parent = line })
			C.text({ Text = tostring(row.Name or "?"), Role = "BodyBold", TextSize = 15, Color = me and Colors.YellowText or Colors.White, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -140, 1, 0), ZIndex = 43, Parent = line })
			C.text({ Text = board == "Rank" and (Ranks.Get(tonumber(row.Value) or 0).Icon .. " " .. tostring(row.Value or 0)) or tostring(row.Value or 0), Role = "Number", TextSize = 16, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(84, 27), ZIndex = 43, Parent = line })
		end
	end
	for i, info in { { "Kills", "BAJAS" }, { "Wins", "VICTORIAS" }, { "Rank", "RANGO" } } do
		buttons[info[1]] = C.button({ Text = info[2], Style = "Menu", TextSize = 15, Size = UDim2.fromOffset(120, 32), Order = i, ZIndex = 43, Parent = tabs, OnClick = function()
			board = info[1]
			render()
		end })
	end
	render()
end

-- Clan: invitar amigos (+monedas para los dos) y el grupo del juego (premio una vez)
function Home.OpenClan()
	local body = openOverlay("CLAN Y AMIGOS", 300)
	C.text({ Text = string.format("👥 Amigos en este servidor: %d  ·  +10%% XP y monedas por amigo", player:GetAttribute("FriendsHere") or 0), Role = "BodyBold", TextSize = 14, Color = Colors.TextDim, Wrap = true, Size = UDim2.new(1, 0, 0, 36), ZIndex = 43, Parent = body })
	local referral = (GameConfig.Referral and GameConfig.Referral.InviterCoins) or 0
	local invite
	invite = C.button({ Text = "INVITAR AMIGOS  +" .. referral .. " 🪙", Icon = "✉", Style = "Primary", TextSize = 20, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 52), ZIndex = 43, Parent = body, OnClick = function()
		local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if ok and canInvite then
			pcall(function()
				local options = Instance.new("ExperienceInviteOptions")
				options.LaunchData = "ref:" .. player.UserId
				options.PromptMessage = "¡Juega conmigo a " .. tostring(GameConfig.GameTitle) .. " y nos llevamos monedas los dos!"
				SocialService:PromptGameInvite(player, options)
			end)
		else
			UISound.Play("Error")
		end
	end })
	if GameConfig.Group and GameConfig.Group.Id ~= 0 then
		local label = "ÚNETE AL GRUPO  +" .. GameConfig.Group.Coins .. " 🪙"
		local groupButton
		groupButton = C.button({ Text = label, Icon = "⭐", Style = "Ghost", TextSize = 18, Position = UDim2.fromOffset(0, 108), Size = UDim2.new(1, 0, 0, 48), ZIndex = 43, Parent = body, OnClick = function()
			local function claim()
				local ok, success, result = pcall(function()
					return Remotes.ClaimGroup:InvokeServer()
				end)
				return ok and success, result
			end
			local done, result = claim()
			if not done and result == "NotMember" then
				local prompted = pcall(function()
					(GroupService :: any):PromptJoinAsync(GameConfig.Group.Id)
				end)
				if prompted then
					task.wait(3.2)
					done, result = claim()
				end
			end
			local labelNode = groupButton:FindFirstChild("Label", true)
			if labelNode then
				labelNode.Text = done and ("¡+" .. tostring(result) .. " 🪙! GRACIAS") or tostring(result == "NotMember" and "ÚNETE EN LA PÁGINA DEL JUEGO" or (result or "NO SE PUDO"))
			end
			UISound.Play(done and "Reward" or "Error")
		end })
		groupButton.Visible = not (ClientState.Data and ClientState.Data.GroupReward)
	end
	local _ = invite
end

-- Rachas de puntos (fijas en este juego): qué dan y con cuántas bajas
function Home.OpenStreaks()
	local body = openOverlay("RACHAS DE PUNTOS", 300)
	for i, spec in { { "📡", "RADAR", "3 bajas seguidas: ves a todos los enemigos en el minimapa unos segundos" }, { "✈", "ATAQUE AÉREO", "5 bajas seguidas: marca un punto del mapa y llega un bombardeo" } } do
		local row = C.panel({ Size = UDim2.new(1, 0, 0, 88), Position = UDim2.fromOffset(0, (i - 1) * 98), ZIndex = 42, Parent = body }, { Accent = Colors.Red })
		C.text({ Text = spec[1], TextSize = 34, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(64, 88), ZIndex = 43, Parent = row })
		C.text({ Text = spec[2], Role = "TitleItalic", TextSize = 22, Position = UDim2.fromOffset(70, 10), Size = UDim2.new(1, -80, 0, 26), ZIndex = 43, Parent = row })
		C.text({ Text = spec[3], Role = "BodyBold", TextSize = 13, Color = Colors.TextDim, Wrap = true, Position = UDim2.fromOffset(70, 40), Size = UDim2.new(1, -80, 0, 40), ZIndex = 43, Parent = row })
	end
end

---------------------------------------------------------------------------
-- Datos
---------------------------------------------------------------------------

local shownPromo, shownPreviewKey

local function nextWeapon(data)
	local best
	for _, name in Weapons.Primaries do
		local def = Weapons.Get(name)
		if def and not def.Hidden and (def.UnlockLevel or 1) > (data.Level or 1) and (def.UnlockLevel or 1) < 900 then
			if not best or def.UnlockLevel < Weapons.Get(best).UnlockLevel then
				best = name
			end
		end
	end
	return best
end

function Home.Refresh()
	local data = ClientState.Data
	if not screen or not data then
		return
	end
	refs.Level.Text = "NIVEL " .. tostring(data.Level or 1)
	refs.XP:Set((data.XP or 0) / math.max(1, data.XPPerLevel or 1000))
	refs.Coins.Text = tostring(data.Coins or 0)
	refs.Daily.Visible = data.DailyAvailable == true
	refs.ChipStarter.Visible = data.StarterPackAvailable == true
	refs.ChipWheel.Visible = data.WheelFree == true
	refs.ChipBoost.Visible = (ReplicatedStorage:GetAttribute("XPBoost") or 1) > 1
	refs.ChipFirstWin.Visible = GameConfig.FirstWinOfDay ~= nil and data.FirstWinAvailable == true
	refs.Chips.Visible = refs.ChipStarter.Visible or refs.ChipWheel.Visible or refs.ChipBoost.Visible or refs.ChipFirstWin.Visible
	refs.NewsDot.Visible = (data.NewsSeen or 0) < ((GameConfig.ActiveNews and GameConfig.ActiveNews().Version) or 0)
	refs.FriendsDot.Visible = (player:GetAttribute("FriendsHere") or 0) > 0
	-- Misiones
	local list = data.Challenges and data.Challenges.List or {}
	local done = 0
	for i = 1, 3 do
		refs.Missions[i](list[i])
		if list[i] and list[i].Done then
			done += 1
		end
	end
	local right = refs.MissionsHeader:FindFirstChild("Right")
	if right then
		right.Text = done .. "/" .. math.max(#list, 3)
	end
	-- Evento o mapa destacado
	local event = GameConfig.CurrentEvent and GameConfig.CurrentEvent()
	local featured = ReplicatedStorage:GetAttribute("FeaturedMap")
	if event then
		refs.EventTag.Text = "EVENTO ACTIVO"
		refs.EventName.Text = C.upper((event.Icon or "") .. " " .. tostring(event.Name))
		local left = (event.EndsAt or 0) - os.time()
		refs.EventSub.Text = left > 0 and string.format("Termina en %dd %dh · premios en Retos", left // 86400, (left % 86400) // 3600) or "Premios en Retos"
		refs.Event.Visible = true
	elseif featured and GameConfig.FeaturedMap then
		refs.EventTag.Text = "MAPA DESTACADO DE HOY"
		refs.EventName.Text = C.upper(tostring(featured))
		refs.EventSub.Text = "+" .. math.floor((GameConfig.FeaturedMap.XPBonus - 1) * 100 + 0.5) .. "% XP jugando en él"
		refs.Event.Visible = true
	else
		refs.Event.Visible = false
	end
	-- Arma destacada
	local promo = nextWeapon(data)
	if promo ~= shownPromo then
		shownPromo = promo
		refs.PromoIcon:ClearAllChildren()
		if promo then
			local def = Weapons.Get(promo)
			refs.PromoName.Text = C.upper(def.DisplayName)
			refs.PromoSub.Text = C.upper(def.Category or "") .. " · SE DESBLOQUEA AL NIVEL " .. tostring(def.UnlockLevel)
			pcall(WeaponIcon.Create, promo, nil, { Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = refs.PromoIcon }, "angled", 1.6)
		end
		refs.Promo.Visible = promo ~= nil
	end
	-- Rango
	local points = data.RankPoints or 0
	local tier = Ranks.Get(points)
	local fraction, nextTier = Ranks.Progress(points)
	refs.RankTitle.Text = string.format('%s <font color="#%s">%s</font>  ·  %d RP', tier.Icon, tier.Color:ToHex(), C.upper(tier.Name), points)
	refs.RankBar:Set(fraction)
	refs.RankBar.Fill.BackgroundColor3 = tier.Color
	refs.RankNext.Text = nextTier and string.format("Faltan %d RP para %s", nextTier.Min - points, nextTier.Name) or "¡Rango máximo!"
	-- Personaje: se rehace si cambia el arma o el traje
	local key = tostring(data.Primary) .. "/" .. tostring(data.EquippedOutfit) .. "/" .. tostring(data.EquippedSkin)
	if preview and key ~= shownPreviewKey and flow.State == "Home" then
		shownPreviewKey = key
		Home.RefreshPreview()
	end
end

function Home.RefreshPreview()
	if not preview then
		return
	end
	local model = preview:SetCharacter("me", player)
	local data = ClientState.Data
	if model and data then
		-- (el arma de la clase activa, con su skin, aunque en el mundo lleve otra en la mano)
		preview:SetWeapon("me", data.Primary, Menu.SkinFor and Menu.SkinFor(data, data.Primary) or nil)
	end
end

local function applyLayout()
	local phone = isPhone()
	for _, button in refs.Menu do
		button.Visible = not (phone and button:GetAttribute("DesktopOnly"))
		button.Size = UDim2.fromOffset(phone and 250 or 300, phone and 40 or 46)
	end
	refs.Play.Size = UDim2.fromOffset(phone and 250 or 300, phone and 62 or 72)
	refs.Quick.Visible = not phone
	refs.ModeCard.Visible = not phone
	refs.RankCard.Position = phone and UDim2.fromOffset(0, 0) or UDim2.fromOffset(282, 0)
	refs.Right.Size = UDim2.fromOffset(phone and 300 or 350, 520)
	refs.Promo.Visible = refs.Promo.Visible and not phone
end

---------------------------------------------------------------------------
-- Pantalla
---------------------------------------------------------------------------

function Home.Build(flowController, rootFrame)
	flow, root = flowController, rootFrame
	-- (Frame y no CanvasGroup: Roblox no dibuja los ViewportFrame dentro de un CanvasGroup)
	screen = C.new("Frame", { Name = "Home", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	-- Personaje en el centro
	preview = Preview.new(screen, { Name = "HeroPreview", Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 560, 1, -10), Camera = "Hero" })
	-- Arrastrar sobre el personaje lo gira
	local dragging, lastX = false, 0
	preview.Viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, lastX = true, input.Position.X
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			preview:Turn("me", (input.Position.X - lastX) * 0.012)
			lastX = input.Position.X
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	buildLogo(screen)
	buildTopBar(screen)
	refs.Left = buildLeft(screen)
	refs.Right = buildRight(screen)
	refs.Bottom = buildBottom(screen)
	applyLayout()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
	end
	ClientState.DataChanged.Event:Connect(Home.Refresh)
	player:GetAttributeChangedSignal("FriendsHere"):Connect(Home.Refresh)
	ReplicatedStorage:GetAttributeChangedSignal("FeaturedMap"):Connect(Home.Refresh)
	ReplicatedStorage:GetAttributeChangedSignal("XPBoost"):Connect(Home.Refresh)
	-- Enter / botón A: JUGAR
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or flow.State ~= "Home" or Menu.IsOpen() or ClientState.WheelOpen or ClientState.NewsOpen or overlay then
			return
		end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			flow.Play()
		end
	end)
	Home.Screen = screen
	Home.Refs = refs
end

function Home.Show(_, previous)
	pcall(function()
		Remotes.SetReady:FireServer(false)
	end)
	flow.SetCamera("Orbit")
	flow.SetBackdrop(0.35)
	Transition.Blur(12, 0.3)
	screen.Visible = true
	Transition.Pop(preview.Viewport, 0.94, previous == "Boot" and 0.45 or 0.25)
	-- Entrada: columnas que deslizan desde los lados (rápido)
	Transition.SlideIn(refs.Left, Vector2.new(-60, 0), 0.35)
	Transition.SlideIn(refs.Right, Vector2.new(60, 0), 0.35, 0.05)
	shownPreviewKey = nil
	Home.Refresh()
	preview:SetActive(true)
	C.setSelected(refs.Play, false)
end

function Home.Hide()
	preview:SetActive(false)
	if overlay then
		overlay:Destroy()
		overlay = nil
	end
	screen.Visible = false
end

return Home
