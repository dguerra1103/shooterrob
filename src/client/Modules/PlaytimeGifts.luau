-- Botón de regalos por tiempo jugado (a la izquierda, debajo de los retos): cuenta atrás hasta el
-- siguiente regalo y, cuando está listo, brilla y se recoge con la tecla H (en partida el ratón está
-- bloqueado) o tocándolo en móvil. Lo valida el servidor (Gifts).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

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
	label.Text = ready and "¡RECOGER! (H)" or ("REGALO EN " .. UI.formatTime(left))
	sub.Text = rewardText(gift)
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
	local ok, result = pcall(function()
		return Remotes.ClaimGift:InvokeServer()
	end)
	claiming = false
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
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	button = UI.button({
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 66, 0.38, 112),
		Size = UDim2.fromOffset(230, 56),
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
			task.wait(0.1)
		end
	end)
end

return PlaytimeGifts
