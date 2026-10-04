-- Habilidades con tiempo de recarga (iconos abajo en el centro, también se tocan en móvil):
--   E  Impulso    : acelerón corto hacia donde te mueves (o hacia donde miras)
--   Z  Supersalto : salto muy alto con un poco de impulso hacia delante
--   X  Poción     : cura con el tiempo (la valida el servidor)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Abilities = {}

local CONFIG = GameConfig.Abilities
local readyAt = { Dash = 0, Jump = 0, Potion = 0 }
local slots = {} -- [nombre] = { Cover, Timer, Frame, WasReady }
local gui

local function getCharacter()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil
end

local function canUse(name)
	return not ClientState.IsBlocked() and not ClientState.Frozen() and os.clock() >= readyAt[name]
end

-- Estela blanca breve detrás del personaje
local function burst(root, color, count, speed)
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Enabled = false
	emitter.Parent = attachment
	emitter:Emit(count)
	task.delay(1, function()
		attachment:Destroy()
	end)
end

local function dash()
	if not canUse("Dash") or ClientState.Sliding then
		return
	end
	local _, humanoid, root = getCharacter()
	if not humanoid or not root then
		return
	end
	local config = CONFIG.Dash
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = camera.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.01 then
		return
	end
	direction = direction.Unit
	readyAt.Dash = os.clock() + config.Cooldown

	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.xAxis
	velocity.SecondaryTangentAxis = Vector3.zAxis
	velocity.MaxForce = 120000
	velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * config.Speed
	velocity.Parent = root
	ClientState.Dashing = true
	task.delay(config.Duration, function()
		ClientState.Dashing = false
		velocity:Destroy()
		attachment:Destroy()
	end)
	ClientState.FovKick = 10
	Sounds.Play("Slide")
	burst(root, Color3.fromRGB(235, 245, 255), 14, 12)
end

local function superJump()
	if not canUse("Jump") then
		return
	end
	local _, humanoid, root = getCharacter()
	if not humanoid or not root or humanoid.FloorMaterial == Enum.Material.Air then
		return
	end
	local config = CONFIG.Jump
	readyAt.Jump = os.clock() + config.Cooldown
	local forward = humanoid.MoveDirection
	if forward.Magnitude < 0.1 then
		forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	end
	if forward.Magnitude > 0.01 then
		forward = forward.Unit
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X + forward.X * config.Forward, config.Power, v.Z + forward.Z * config.Forward)
	ClientState.FovKick = 6
	Sounds.Play("Swing")
	burst(root, Color3.fromRGB(170, 220, 255), 18, 8)
end

local function potion()
	if not canUse("Potion") then
		return
	end
	local _, humanoid = getCharacter()
	if not humanoid or humanoid.Health >= humanoid.MaxHealth then
		return
	end
	readyAt.Potion = os.clock() + CONFIG.Potion.Cooldown
	Sounds.Play("Kill")
	task.spawn(function()
		local ok, used = pcall(function()
			return Remotes.UsePotion:InvokeServer()
		end)
		if not ok or not used then
			readyAt.Potion = os.clock() + 1 -- el servidor no la aceptó: se puede reintentar enseguida
		end
	end)
end

local ACTIONS = {
	{ Name = "Dash", Key = "E", Icon = "💨", Use = dash, Color = Color3.fromRGB(70, 160, 255) },
	{ Name = "Jump", Key = "Z", Icon = "⏫", Use = superJump, Color = Color3.fromRGB(80, 200, 255) },
	{ Name = "Potion", Key = "X", Icon = "🧪", Use = potion, Color = Color3.fromRGB(80, 220, 120) },
}

local function build()
	gui = UI.new("ScreenGui", {
		Name = "Abilities",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local bar = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(3 * 78 + 2 * 12, 92),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 12),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local scale = UI.new("UIScale", { Parent = bar })
	local function rescale()
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), 0.65, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	for i, action in ACTIONS do
		local button = UI.button({
			LayoutOrder = i,
			Size = UDim2.fromOffset(78, 78),
			Text = "",
			BackgroundColor3 = action.Color,
			AutoButtonColor = true,
			Parent = bar,
		}, { UI.stroke(Color3.new(1, 1, 1), 3, 0), UI.gloss() })
		UI.label({ Size = UDim2.fromScale(1, 1), Text = action.Icon, TextSize = 40, Parent = button })
		local cover = UI.new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			ZIndex = 2,
			Parent = button,
		}, { UI.corner(8) })
		local timer = UI.label({ Size = UDim2.fromScale(1, 1), Text = "", TextSize = 30, ZIndex = 3, Parent = button })
		local badge = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 1, 2),
			Size = UDim2.fromOffset(30, 26),
			BackgroundColor3 = Color3.fromRGB(20, 22, 34),
			ZIndex = 4,
			Parent = button,
		}, { UI.corner(6), UI.stroke(Color3.new(1, 1, 1), 2, 0) })
		UI.label({ Size = UDim2.fromScale(1, 1), Text = action.Key, TextSize = 18, ZIndex = 5, Parent = badge })
		button.Activated:Connect(action.Use)
		slots[action.Name] = { Cover = cover, Timer = timer, Frame = button, WasReady = true }
	end
end

local function update()
	gui.Enabled = not ClientState.InMainMenu and not ClientState.Dead and not ClientState.MenuOpen and not ClientState.VotePanelVisible
	local now = os.clock()
	for _, action in ACTIONS do
		local slot = slots[action.Name]
		local left = readyAt[action.Name] - now
		local ready = left <= 0
		local fraction = ready and 0 or math.clamp(left / CONFIG[action.Name].Cooldown, 0, 1)
		slot.Cover.Size = UDim2.fromScale(1, fraction)
		slot.Timer.Text = ready and "" or tostring(math.ceil(left))
		if ready and not slot.WasReady then
			-- Lista otra vez: pequeño salto del icono
			local s = slot.Frame:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = slot.Frame })
			s.Scale = 1.2
			TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		slot.WasReady = ready
	end
end

function Abilities.Init()
	build()
	local keys = {
		Dash = { Enum.KeyCode.E, Enum.KeyCode.DPadLeft },
		Jump = { Enum.KeyCode.Z, Enum.KeyCode.DPadDown },
		Potion = { Enum.KeyCode.X },
	}
	for _, action in ACTIONS do
		ContextActionService:BindAction("Ability" .. action.Name, function(_, state)
			if state == Enum.UserInputState.Begin then
				action.Use()
			end
			return Enum.ContextActionResult.Pass
		end, false, table.unpack(keys[action.Name]))
	end
	-- Al reaparecer, las recargas se mantienen (no se reinician gratis)
	RunService.RenderStepped:Connect(update)
end

return Abilities
