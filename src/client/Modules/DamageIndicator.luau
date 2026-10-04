-- Indicador de daño: al recibir un disparo sale una marca roja alrededor de la mira que apunta hacia
-- quien te ha dado (sigue su posición mientras se desvanece). El servidor deja en tu Humanoid quién
-- fue (atributos LastAttacker / LastBot, ver Combat) y LastHitTime cambia con cada impacto.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local DamageIndicator = {}

local RADIUS = 150
local FADE_TIME = 1.4
local MAX_MARKS = 4

local gui, holder
local marks = {} -- { Key, Frame, Source, ShownAt }

local function attackerPosition(source)
	if source.UserId then
		local other = Players:GetPlayerByUserId(source.UserId)
		local root = other and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		return root and root.Position
	end
	local folder = workspace:FindFirstChild("Bots")
	local model = folder and folder:FindFirstChild(source.Bot)
	local root = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
	return root and root.Position
end

local function newMark()
	local frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(110, 16),
		BackgroundColor3 = Color3.fromRGB(255, 40, 40),
		BorderSizePixel = 0,
		Parent = holder,
	}, {
		UI.corner(8),
		UI.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.15),
				NumberSequenceKeypoint.new(0.7, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	-- Punta hacia fuera (hacia el atacante)
	UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(24, 18),
		Text = "▲",
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 60, 60),
		TextStrokeTransparency = 1,
		Parent = frame,
	})
	return frame
end

local function onHit(humanoid)
	local userId = humanoid:GetAttribute("LastAttacker")
	local bot = humanoid:GetAttribute("LastBot")
	if userId == player.UserId then
		return -- (tu propio cohete o granada)
	end
	-- Con escudo (al reaparecer o en la pantalla de inicio) el disparo no hace daño: sin marca
	local character = humanoid.Parent
	if ClientState.Dead or ClientState.InMainMenu or (character and character:FindFirstChildOfClass("ForceField")) then
		return
	end
	local source = userId and { UserId = userId } or (bot and { Bot = bot }) or nil
	if not source then
		return
	end
	local key = userId and ("p" .. userId) or ("b" .. bot)
	for _, mark in marks do
		if mark.Key == key then
			mark.ShownAt = os.clock()
			mark.Source = source
			return
		end
	end
	if #marks >= MAX_MARKS then
		local oldest = table.remove(marks, 1)
		oldest.Frame:Destroy()
	end
	table.insert(marks, { Key = key, Frame = newMark(), Source = source, ShownAt = os.clock() })
end

local function clear()
	for _, mark in marks do
		mark.Frame:Destroy()
	end
	table.clear(marks)
end

local function update()
	if #marks == 0 then
		return
	end
	if ClientState.Dead or ClientState.InMainMenu then
		clear()
		return
	end
	local camera = workspace.CurrentCamera
	local now = os.clock()
	for i = #marks, 1, -1 do
		local mark = marks[i]
		local age = now - mark.ShownAt
		local position = attackerPosition(mark.Source)
		if age > FADE_TIME then
			mark.Frame:Destroy()
			table.remove(marks, i)
		else
			if position then
				mark.LastPosition = position
			end
			local target = mark.LastPosition
			if target then
				local relative = camera.CFrame:PointToObjectSpace(target)
				local angle = math.atan2(relative.X, -relative.Z) -- 0 = delante (arriba en pantalla)
				mark.Frame.Position = UDim2.new(0.5, math.sin(angle) * RADIUS, 0.5, -math.cos(angle) * RADIUS)
				mark.Frame.Rotation = math.deg(angle)
				mark.Frame.Visible = true
			else
				mark.Frame.Visible = false
			end
			-- Se desvanece en el último tramo
			local fade = math.clamp((age - FADE_TIME * 0.45) / (FADE_TIME * 0.55), 0, 1)
			mark.Frame.BackgroundTransparency = fade
			local arrow = mark.Frame:FindFirstChildOfClass("TextLabel")
			if arrow then
				arrow.TextTransparency = fade
			end
		end
	end
end

local function watch(character)
	clear()
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid:GetAttributeChangedSignal("LastHitTime"):Connect(function()
		onHit(humanoid)
	end)
end

function DamageIndicator.Init()
	gui = UI.new("ScreenGui", {
		Name = "DamageIndicator",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 4,
		Parent = player:WaitForChild("PlayerGui"),
	})
	holder = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	player.CharacterAdded:Connect(watch)
	if player.Character then
		task.spawn(watch, player.Character)
	end
	RunService.RenderStepped:Connect(update)
end

return DamageIndicator
