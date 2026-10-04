-- Buscar y destruir: qué te toca (atacar o defender), la cuenta atrás de la bomba plantada y la
-- barra de plantar / desactivar. Debajo del marcador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local BombHUD = {}

local gui, label, barBack, bar, barText

local function update()
	local attackers = ReplicatedStorage:GetAttribute("Bomb_Attackers")
	gui.Enabled = attackers ~= nil and not ClientState.InMainMenu
	if not gui.Enabled then
		return
	end
	local state = ReplicatedStorage:GetAttribute("Bomb_State")
	local site = ReplicatedStorage:GetAttribute("Bomb_Site") or ""
	local attacking = player.Team ~= nil and player.Team.Name == attackers
	if state == "Planted" then
		local timer = ReplicatedStorage:GetAttribute("Bomb_Timer") or 0
		label.Text = string.format("💣 BOMBA EN %s · %d s%s", site, timer, attacking and " · ¡protégela!" or " · ¡desactívala!")
		label.TextColor3 = Color3.fromRGB(255, 90, 70)
	elseif attacking then
		label.Text = "💣 ATACAS · planta la bomba en A o B"
		label.TextColor3 = Color3.fromRGB(255, 210, 90)
	else
		label.Text = "🛡️ DEFIENDES · protege A y B"
		label.TextColor3 = Color3.fromRGB(140, 200, 255)
	end
	local action = ReplicatedStorage:GetAttribute("Bomb_Action") or ""
	local progress = ReplicatedStorage:GetAttribute("Bomb_Progress") or 0
	barBack.Visible = action ~= "" and progress > 0
	bar.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
	bar.BackgroundColor3 = action == "Planting" and Color3.fromRGB(255, 120, 50) or Color3.fromRGB(80, 170, 255)
	barText.Text = (action == "Planting" and "PLANTANDO EN " .. site or "DESACTIVANDO") .. "..."
end

function BombHUD.Init()
	gui = UI.new("ScreenGui", {
		Name = "BombHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	label = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 118),
		Size = UDim2.fromOffset(460, 30),
		Text = "",
		TextSize = 22,
		Parent = gui,
	})
	barBack = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.fromOffset(260, 22),
		BackgroundColor3 = Color3.fromRGB(20, 22, 28),
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = gui,
	}, { UI.corner(6), UI.stroke(Color3.new(0, 0, 0), 2, 0.2) })
	bar = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = barBack,
	}, { UI.corner(6) })
	barText = UI.label({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextSize = 16,
		ZIndex = 2,
		Parent = barBack,
	})
	task.spawn(function()
		while gui.Parent do
			update()
			task.wait(0.15)
		end
	end)
end

BombHUD.Update = update

return BombHUD
