-- ELECCIÓN RÁPIDA DE CLASE (antes de desplegar): las 5 clases con su arma principal (en 3D, con tu
-- skin), secundaria, letal y ventaja. La que usaste la última vez ya viene marcada: si no tocas
-- nada, entras con ella. Elegir otra la equipa al momento (el servidor cambia las armas durante el
-- despliegue). Una barra marca el tiempo que queda hasta la cuenta atrás.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Weapons = require(Shared.Weapons)

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

local Loadout = {}

local flow, screen, row, timerBar, timerLabel, deployButton
local cards = {}
local shownKeys = {}
local selected
local token = 0
local endsAt, connection
local lateMode = false

local function perkInfo(id)
	for _, perk in GameConfig.Perks do
		if perk.Id == id then
			return perk
		end
	end
	return { Icon = "—", Name = "Sin ventaja" }
end

local function buildCard(i)
	local card = C.button({ Name = "Class" .. i, Text = "", Style = "Menu", Size = UDim2.new(0.2, -10, 1, 0), Order = i, Parent = row, Sound = "Equip", OnClick = function()
		Loadout.Select(i)
	end })
	local z = 5
	local head = C.text({ Name = "Head", Text = "CLASE " .. i, Role = "Title", TextSize = 16, Color = Colors.TextDim, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 20), ZIndex = z, Parent = card })
	local name = C.text({ Name = "ClassName", Text = "", Role = "TitleItalic", TextSize = 26, Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -24, 0, 30), ZIndex = z, Parent = card })
	local icon = C.new("Frame", { Name = "WeaponIcon", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 58), Size = UDim2.new(1, -12, 0, 92), ZIndex = z, Parent = card })
	local primary = C.text({ Name = "Primary", Text = "", Role = "Title", TextSize = 18, Position = UDim2.fromOffset(12, 152), Size = UDim2.new(1, -24, 0, 22), Scaled = true, ZIndex = z, Parent = card })
	local secondary = C.text({ Name = "Secondary", Text = "", Role = "BodyBold", TextSize = 13, Scaled = true, Color = Colors.TextDim, Position = UDim2.fromOffset(12, 176), Size = UDim2.new(1, -24, 0, 18), ZIndex = z, Parent = card })
	local extras = C.text({ Name = "Extras", Text = "", Role = "BodyBold", TextSize = 13, Scaled = true, Color = Colors.TextDim, Position = UDim2.fromOffset(12, 196), Size = UDim2.new(1, -24, 0, 18), ZIndex = z, Parent = card })
	local check = C.new("Frame", { Name = "Check", BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(24, 24), ZIndex = z + 1, Parent = card }, { C.corner(3) })
	C.text({ Text = "✔", Role = "Title", TextSize = 16, Color = Color3.fromRGB(16, 14, 8), AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = z + 2, Parent = check })
	cards[i] = { Frame = card, Head = head, Name = name, Icon = icon, Primary = primary, Secondary = secondary, Extras = extras, Check = check }
end

local function render()
	local data = ClientState.Data
	if not data or not data.Classes then
		return
	end
	selected = selected or data.ActiveClass or 1
	for i, card in cards do
		local class = data.Classes[i] or GameConfig.DefaultClasses[i]
		local def = Weapons.Get(class.Primary)
		local locked = def and not ((def.UnlockLevel or 1) <= (data.Level or 1) or (data.OwnedWeapons and data.OwnedWeapons[class.Primary]))
		card.Name.Text = tostring(class.Name or ("CLASE " .. i))
		card.Primary.Text = def and (C.upper(def.DisplayName) .. (locked and ("  🔒 NV " .. tostring(def.UnlockLevel)) or "")) or ""
		local secondary = Weapons.Get(class.Secondary)
		card.Secondary.Text = "Secundaria: " .. (secondary and secondary.DisplayName or "—")
		local perk = perkInfo(class.Perk)
		card.Extras.Text = "💣 Granada  ·  " .. tostring(perk.Icon) .. " " .. tostring(perk.Name)
		local key = tostring(class.Primary) .. "/" .. tostring(Menu.SkinFor and Menu.SkinFor(data, class.Primary))
		if shownKeys[i] ~= key then
			shownKeys[i] = key
			card.Icon:ClearAllChildren()
			pcall(WeaponIcon.Create, class.Primary, Menu.SkinFor and Menu.SkinFor(data, class.Primary) or nil, { Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = card.Icon }, "angled", 2.2)
		end
		C.setSelected(card.Frame, i == selected)
		card.Check.Visible = i == selected
		card.Head.TextColor3 = i == selected and Color3.fromRGB(60, 46, 6) or Colors.TextDim
		card.Secondary.TextColor3 = i == selected and Color3.fromRGB(60, 46, 6) or Colors.TextDim
		card.Extras.TextColor3 = card.Secondary.TextColor3
	end
end

function Loadout.Select(i)
	if selected == i then
		return
	end
	selected = i
	pcall(function()
		Remotes.SelectClass:FireServer(i)
	end)
	-- El arma de la clase elegida da un saltito
	local card = cards[i]
	if card then
		Transition.Pulse(card.Icon, 1.15, 0.25)
	end
	render()
end

local function step()
	if flow.State ~= "Loadout" then
		return
	end
	local remaining, total
	if lateMode then
		remaining = endsAt - os.clock()
		total = flow.Times.LateLoadout
	else
		local countdownIn = flow.CountdownIn()
		remaining = countdownIn or 0
		total = math.max(1, (GameConfig.Deploy.LineupTime or 7) - flow.Times.TeamIntro)
	end
	timerBar:Set(math.clamp(remaining / total, 0, 1), false)
	timerLabel.Text = string.format("%d", math.max(0, math.ceil(remaining)))
	if remaining <= 0 then
		flow.Advance("Loadout")
	end
end

function Loadout.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "Loadout", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	C.text({ Text = "ELIGE TU CLASE", Role = "TitleItalic", TextSize = 52, Position = UDim2.fromOffset(40, 40), Size = UDim2.fromOffset(700, 60), Stroke = 2, Parent = screen })
	C.text({ Text = "La última que usaste ya está marcada · si no eliges, entras con ella", Role = "BodyBold", TextSize = 15, Color = Colors.TextDim, Position = UDim2.fromOffset(44, 100), Size = UDim2.fromOffset(700, 20), Parent = screen })
	timerLabel = C.text({ Text = "", Role = "Number", TextSize = 56, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -40, 0, 36), Size = UDim2.fromOffset(120, 64), Parent = screen })
	timerBar = C.progress({ Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 130), Size = UDim2.new(1, -80, 0, 4), Parent = screen })
	row = C.new("Frame", { Name = "Classes", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.52, 0), Size = UDim2.new(1, -80, 0, 226), Parent = screen }, {
		C.list(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center),
	})
	for i = 1, GameConfig.ClassCount or 5 do
		buildCard(i)
	end
	deployButton = C.button({ Name = "Deploy", Text = "DESPLEGAR", Icon = "▶", Style = "Primary", TextSize = 30, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -32), Size = UDim2.fromOffset(320, 64), Parent = screen, OnClick = function()
		if lateMode then
			flow.Advance("Loadout")
		else
			-- (en el despliegue de todos, la cuenta atrás la marca el servidor: aquí solo confirmas)
			local label = deployButton:FindFirstChild("Label", true)
			if label then
				label.Text = "¡LISTO!"
			end
		end
	end })
	ClientState.DataChanged.Event:Connect(function()
		if screen.Visible then
			local data = ClientState.Data
			if data and data.ActiveClass then
				selected = data.ActiveClass
			end
			render()
		end
	end)
end

function Loadout.Show(ctx)
	token += 1
	lateMode = ctx.Late == true and ReplicatedStorage:GetAttribute("Deploy") == nil
	endsAt = os.clock() + flow.Times.LateLoadout
	flow.SetBackdrop(0.72, 0.2)
	Transition.Blur(14, 0.2)
	local data = ClientState.Data
	selected = data and data.ActiveClass or 1
	screen.Visible = true
	local label = deployButton:FindFirstChild("Label", true)
	if label then
		label.Text = "DESPLEGAR"
	end
	render()
	for i, card in cards do
		-- (están en una lista horizontal: entran creciendo, una tras otra)
		Transition.Pop(card.Frame, 0.85, 0.22, (i - 1) * 0.04)
	end
	if connection then
		connection:Disconnect()
	end
	connection = RunService.RenderStepped:Connect(step)
end

function Loadout.Hide()
	token += 1
	if connection then
		connection:Disconnect()
		connection = nil
	end
	screen.Visible = false
end

local _ = UISound
local __ = Players
return Loadout
