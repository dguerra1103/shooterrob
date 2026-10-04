-- Buscar y destruir: qué te toca (atacar o defender), la cuenta atrás de la bomba plantada y la
-- barra de plantar / desactivar. Debajo del marcador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local BombHUD = {}

local gui, label, barBack, bar, barText, droppedMarker

local function update()
	local attackers = ReplicatedStorage:GetAttribute("Bomb_Attackers")
	gui.Enabled = attackers ~= nil and not ClientState.InMainMenu
	if not gui.Enabled then
		droppedMarker.Parent = nil
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
		-- Quién lleva la bomba (solo el portador puede plantarla)
		local carrier = ReplicatedStorage:GetAttribute("Bomb_Carrier")
		if carrier == player.Name then
			label.Text = "💣 LLEVAS LA BOMBA · plántala en A o B"
		elseif typeof(ReplicatedStorage:GetAttribute("Bomb_Dropped")) == "Vector3" then
			label.Text = "💣 ¡LA BOMBA ESTÁ EN EL SUELO! · recógela"
		elseif carrier then
			local carrierPlayer = Players:FindFirstChild(tostring(carrier))
			local shown = carrierPlayer and carrierPlayer:IsA("Player") and carrierPlayer.DisplayName or tostring(carrier)
			label.Text = "💣 ATACAS · " .. shown .. " lleva la bomba: cúbrele"
		else
			label.Text = "💣 ATACAS · planta la bomba en A o B"
		end
		label.TextColor3 = Color3.fromRGB(255, 210, 90)
	else
		label.Text = "🛡️ DEFIENDES · protege A y B"
		label.TextColor3 = Color3.fromRGB(140, 200, 255)
	end
	-- Marca de la bomba en el suelo, solo para los atacantes (los defensores no la ven a través de las paredes)
	local dropped = ReplicatedStorage:GetAttribute("Bomb_Dropped")
	if attacking and state ~= "Planted" and typeof(dropped) == "Vector3" then
		droppedMarker.Position = dropped - Vector3.new(0, 2.5, 0)
		droppedMarker.Parent = workspace
	else
		droppedMarker.Parent = nil
	end
	local action = ReplicatedStorage:GetAttribute("Bomb_Action") or ""
	local progress = ReplicatedStorage:GetAttribute("Bomb_Progress") or 0
	barBack.Visible = action ~= "" and progress > 0
	bar.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
	bar.BackgroundColor3 = action == "Planting" and Color3.fromRGB(255, 120, 50) or Color3.fromRGB(80, 170, 255)
	barText.Text = (action == "Planting" and "PLANTANDO EN " .. site or "DESACTIVANDO") .. "..."
end

function BombHUD.Init()
	-- Marca de la bomba en el suelo (pieza invisible con el icono encima, solo en este cliente)
	droppedMarker = Instance.new("Part")
	droppedMarker.Name = "DroppedBombMarker"
	droppedMarker.Anchored = true
	droppedMarker.CanCollide = false
	droppedMarker.CanQuery = false
	droppedMarker.CanTouch = false
	droppedMarker.Transparency = 1
	droppedMarker.Size = Vector3.new(0.2, 0.2, 0.2)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(36, 36)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 400
	billboard.Parent = droppedMarker
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.TextScaled = true
	icon.Text = "💣"
	icon.Parent = billboard
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
		TextScaled = true, -- (con nombres largos se encoge)
		Parent = gui,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = 22 }) })
	barBack = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.5, -30), -- (encima de la mira: debajo salen las medallas en el móvil)
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
