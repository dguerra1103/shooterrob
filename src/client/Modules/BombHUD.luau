-- Buscar y destruir: qué te toca (atacar o defender), la cuenta atrás de la bomba plantada y la
-- barra de plantar / desactivar. Debajo del marcador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)
local HUDZones = require(script.Parent.HUDZones)
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))
local Sounds = require(ReplicatedStorage:WaitForChild("Shared").Sounds)

local player = Players.LocalPlayer

local BombHUD = {}

local gui, label, barBack, bar, barText, droppedMarker
local nextBeep = 0

-- Bomba plantada: la luz parpadea y pita, cada vez más deprisa según se acaba el tiempo
local function beep(timer)
	local bomb = workspace:FindFirstChild("PlantedBomb")
	local light = bomb and bomb:FindFirstChild("BombLight")
	if not light or not light:IsA("BasePart") then
		return
	end
	local now = os.clock()
	if now < nextBeep then
		return
	end
	nextBeep = now + math.clamp(timer / 30, 0.15, 1)
	light.Transparency = 0
	task.delay(0.08, function()
		if light.Parent then
			light.Transparency = 0.7
		end
	end)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.55
	sound.PlaybackSpeed = 1.9
	sound.RollOffMaxDistance = 140
	sound.SoundGroup = Sounds.GetWorldGroup() -- (así también se oye apagado tras una explosión)
	sound.Parent = light
	sound:Play()
	task.delay(1.5, function()
		sound:Destroy()
	end)
end

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
		beep(timer)
		label.Text = UI.HudText(string.format("💣 BOMBA EN %s · %d s%s", site, timer, attacking and " · ¡protégela!" or " · ¡desactívala!"))
		label.TextColor3 = Color3.fromRGB(255, 90, 70)
	elseif attacking then
		-- Quién lleva la bomba (solo el portador puede plantarla)
		local carrier = ReplicatedStorage:GetAttribute("Bomb_Carrier")
		if carrier == player.Name then
			label.Text = UI.HudText("💣 LLEVAS LA BOMBA · plántala en A o B")
		elseif typeof(ReplicatedStorage:GetAttribute("Bomb_Dropped")) == "Vector3" then
			label.Text = UI.HudText("💣 ¡LA BOMBA ESTÁ EN EL SUELO! · recógela")
		elseif carrier then
			local carrierPlayer = Players:FindFirstChild(tostring(carrier))
			local shown = carrierPlayer and carrierPlayer:IsA("Player") and carrierPlayer.DisplayName or tostring(carrier)
			label.Text = UI.HudText("💣 ATACAS · ") .. shown .. " lleva la bomba: cúbrele"
		else
			label.Text = UI.HudText("💣 ATACAS · planta la bomba en A o B")
		end
		label.TextColor3 = Color3.fromRGB(255, 210, 90)
	else
		label.Text = UI.HudText("🛡️ DEFIENDES · protege A y B")
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
	-- Táctil (Fase 16): el estado de la bomba va con el objetivo, bajo el minimapa; el progreso de
	-- plantar o desactivar, bajo la mira (fuera del centro libre). Antes los dos iban fijos arriba y
	-- encima de la mira y en una partida pisaban las medallas y el aviso de baja
	if InputMode.TouchUI() then
		label.Size = UDim2.fromOffset(220, 20)
		barBack.Size = UDim2.fromOffset(200, 18)
		barText.TextSize = 13
		HUDZones.Register("BombStatus", label, "TOP_LEFT", 1, { Gui = gui, Fit = true })
		HUDZones.Register("BombProgress", barBack, "BOTTOM_NOTICE", 0, { Gui = gui })
	end
	task.spawn(function()
		while gui.Parent do
			update()
			task.wait(0.15)
		end
	end)
end

BombHUD.Update = update

return BombHUD
