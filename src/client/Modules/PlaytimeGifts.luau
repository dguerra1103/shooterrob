-- Botón de regalos por tiempo jugado (a la izquierda, debajo de los retos): cuenta atrás hasta el
-- siguiente regalo y, cuando está listo, brilla y se recoge con la tecla H (en partida el ratón está
-- bloqueado) o tocándolo en móvil. Lo valida el servidor (Gifts).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local PlaytimeGifts = {}

local READY = Color3.fromRGB(255, 190, 40)
local WAITING = Color3.fromRGB(45, 50, 80)

local gui, button, icon, label, sub, scale
local claiming = false
local message, messageUntil = nil, 0 -- aviso breve si el servidor no deja recogerlo
local compact = false -- móvil: solo el icono y el tiempo (arriba a la izquierda)

local function rewardText(gift)
	local parts = {}
	if gift.Coins then
		table.insert(parts, gift.Coins .. " 🪙")
	end
	if gift.XP then
		table.insert(parts, gift.XP .. " XP")
	end
	if gift.Revives then
		table.insert(parts, gift.Revives .. " 💖")
	end
	return table.concat(parts, " + ")
end

-- Siguiente regalo y segundos que faltan (nil si ya se recogieron todos)
local function nextGift()
	local start = player:GetAttribute("GiftStart")
	local index = (player:GetAttribute("GiftsClaimed") or 0) + 1
	local gift = GameConfig.PlaytimeGifts[index]
	if not start or not gift then
		return nil
	end
	return gift, math.max(0, start + gift.Minutes * 60 - workspace:GetServerTimeNow())
end

local function update()
	local gift, left = nextGift()
	gui.Enabled = gift ~= nil and not ClientState.InMainMenu and not ClientState.Dead
	if not gift then
		return
	end
	local ready = left <= 0
	button.BackgroundColor3 = ready and READY or WAITING
	if compact then
		label.Text = ready and "¡YA!" or UI.formatTime(left)
	else
		label.Text = ready and "¡RECOGER! (H)" or ("REGALO EN " .. UI.formatTime(left))
	end
	sub.Text = (message and os.clock() < messageUntil) and message or rewardText(gift)
	-- Late cuando está listo
	scale.Scale = ready and (1 + math.sin(os.clock() * 6) * 0.05) or 1
	icon.Rotation = ready and math.sin(os.clock() * 10) * 12 or 0
end

local function claim()
	local gift, left = nextGift()
	if claiming or not gift or left > 0 then
		return
	end
	claiming = true
	Sounds.Play("Click")
	local ok, result, reason = pcall(function()
		return Remotes.ClaimGift:InvokeServer()
	end)
	claiming = false
	if not (ok and result) then
		message, messageUntil = (ok and type(reason) == "string") and reason or "Inténtalo otra vez", os.clock() + 2
	end
	if ok and result then
		Sounds.Play("Flag")
		-- Pequeño salto del botón al recogerlo
		scale.Scale = 1.25
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

function PlaytimeGifts.Init()
	gui = UI.new("ScreenGui", {
		Name = "PlaytimeGifts",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- En móvil: botón pequeño arriba a la izquierda (abajo está el joystick y los retos ocupan el centro)
	compact = InputMode.TouchUI()
	UI.WaitViewport()
	-- (teléfono: a la derecha del minimapa, pequeño; tablet: debajo del botón de la tienda)
	local phone = UI.IsPhone()
	button = UI.button({
		AnchorPoint = Vector2.new(0, 0),
		-- (táctil: a la derecha del minimapa, que mide 96 en el teléfono y 160 en la tablet)
		Position = compact and UDim2.fromOffset(14 + (phone and 96 or 160) + 6, UI.TopbarBottom())
			or UDim2.new(0, 66, 0.38, 112),
		Size = phone and UDim2.fromOffset(44, 54) or (compact and UDim2.fromOffset(52, 64) or UDim2.fromOffset(230, 56)),
		Text = "",
		BackgroundColor3 = WAITING,
		BackgroundTransparency = 0.1,
		Parent = gui,
	}, { UI.stroke(Color3.new(1, 1, 1), 2, 0.3) })
	scale = UI.new("UIScale", { Parent = button })
	icon = UI.label({
		Position = UDim2.fromOffset(4, 0),
		Size = UDim2.fromOffset(50, 56),
		Text = "🎁",
		TextSize = 34,
		Parent = button,
	})
	label = UI.label({
		Position = UDim2.fromOffset(56, 6),
		Size = UDim2.new(1, -62, 0, 24),
		Text = "",
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = button,
	})
	sub = UI.label({
		Position = UDim2.fromOffset(56, 30),
		Size = UDim2.new(1, -62, 0, 20),
		Text = "",
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 235, 170),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = button,
	})
	if compact then
		-- Icono arriba y el tiempo debajo, sin la línea del premio
		local small = phone
		icon.Position, icon.Size, icon.TextSize = UDim2.fromOffset(0, 2), UDim2.new(1, 0, 0, small and 30 or 38), small and 24 or 30
		label.Position, label.Size = UDim2.fromOffset(0, small and 32 or 40), UDim2.new(1, 0, 0, small and 18 or 20)
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextSize = small and 12 or 15
		sub.Visible = false
	end
	button.Activated:Connect(claim)
	ContextActionService:BindAction("ClaimGift", function(_, state)
		if state == Enum.UserInputState.Begin and gui.Enabled and not ClientState.IsBlocked() then
			claim()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.H)
	task.spawn(function()
		while true do
			update()
			-- Rápido solo cuando late (regalo listo y a la vista)
			local gift, left = nextGift()
			task.wait((gui.Enabled and gift and left <= 0) and 0.1 or 0.25)
		end
	end)
end

return PlaytimeGifts
