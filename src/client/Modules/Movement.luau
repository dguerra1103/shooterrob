-- Movimiento: correr (Shift) y deslizarse (C).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Movement = {}

local humanoid, rootPart
local sprintHeld = false
local lastSlide = -10
local stopSlide

local function tweenCameraOffset(offset, time)
	if humanoid then
		TweenService:Create(humanoid, TweenInfo.new(time, Enum.EasingStyle.Quad), { CameraOffset = offset }):Play()
	end
end

local function slide()
	if ClientState.Sliding or ClientState.IsBlocked() or not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end
	if os.clock() - lastSlide < GameConfig.SlideCooldown or humanoid.FloorMaterial == Enum.Material.Air then
		return
	end
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = camera.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.01 then
		return
	end
	direction = direction.Unit

	lastSlide = os.clock()
	ClientState.Sliding = true
	Sounds.Play("Slide")

	local attachment = Instance.new("Attachment")
	attachment.Name = "SlideAttachment"
	attachment.Parent = rootPart
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	-- Modo plano: solo empuja en X/Z, la gravedad sigue actuando
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.xAxis
	velocity.SecondaryTangentAxis = Vector3.zAxis
	velocity.MaxForce = 80000
	velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * GameConfig.SlideSpeed
	velocity.Parent = rootPart

	tweenCameraOffset(Vector3.new(0, -1.8, 0), 0.12)

	local start = os.clock()
	local connection
	local stopped = false
	stopSlide = function()
		if stopped then
			return
		end
		stopped = true
		connection:Disconnect()
		velocity:Destroy()
		attachment:Destroy()
		ClientState.Sliding = false
		tweenCameraOffset(Vector3.zero, 0.2)
	end
	connection = RunService.Heartbeat:Connect(function()
		local alpha = (os.clock() - start) / GameConfig.SlideDuration
		local state = humanoid:GetState()
		if alpha >= 1 or humanoid.Health <= 0 or humanoid.Jump or state == Enum.HumanoidStateType.Jumping then
			stopSlide()
			return
		end
		local speed = GameConfig.SlideSpeed + (GameConfig.WalkSpeed - GameConfig.SlideSpeed) * alpha * alpha
		velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * speed
	end)
end

-- Hielo: el Humanoid ignora la fricción del suelo, así que el patinaje se hace con una LinearVelocity
-- (dentro del paso de física, como el deslizamiento): la velocidad cambia despacio hacia donde quieres ir.
local iceVelocity = Vector3.zero
local iceMover: LinearVelocity? = nil

local function stopIce()
	if iceMover then
		local attachment = iceMover.Attachment0
		iceMover:Destroy()
		if attachment then
			attachment:Destroy()
		end
		iceMover = nil
	end
end

local function iceSlide(dt)
	local state = humanoid:GetState()
	local onIce = humanoid.FloorMaterial == Enum.Material.Ice
		and not ClientState.Sliding
		and state ~= Enum.HumanoidStateType.Jumping
		and state ~= Enum.HumanoidStateType.Freefall
	if not onIce then
		stopIce()
		local velocity = rootPart.AssemblyLinearVelocity
		iceVelocity = Vector3.new(velocity.X, 0, velocity.Z)
		return
	end
	if not iceMover or iceMover.Parent ~= rootPart then
		stopIce()
		local attachment = Instance.new("Attachment")
		attachment.Name = "IceAttachment"
		attachment.Parent = rootPart
		local mover = Instance.new("LinearVelocity")
		mover.Name = "IceVelocity"
		mover.Attachment0 = attachment
		mover.RelativeTo = Enum.ActuatorRelativeTo.World
		mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		mover.PrimaryTangentAxis = Vector3.xAxis
		mover.SecondaryTangentAxis = Vector3.zAxis
		mover.MaxForce = 30000
		mover.Parent = rootPart
		iceMover = mover
	end
	local wanted = humanoid.MoveDirection * humanoid.WalkSpeed
	iceVelocity = iceVelocity:Lerp(Vector3.new(wanted.X, 0, wanted.Z), math.min(1, dt * 1.5))
	if iceMover then
		iceMover.PlaneVelocity = Vector2.new(iceVelocity.X, iceVelocity.Z)
	end
end

local function update(dt)
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		ClientState.Sprinting = false
		return
	end
	iceSlide(dt)
	local moving = humanoid.MoveDirection.Magnitude > 0.1
	local recentlyShot = os.clock() - ClientState.LastShotTime < 0.35
	ClientState.Sprinting = sprintHeld
		and moving
		and not ClientState.Aiming
		and not recentlyShot
		and not ClientState.Sliding
		and not ClientState.IsBlocked()

	local speed = GameConfig.WalkSpeed
	if ClientState.Sprinting then
		speed = GameConfig.SprintSpeed
	elseif ClientState.Aiming then
		speed = GameConfig.AimWalkSpeed
	end
	local weaponDef = ClientState.CurrentDef
	if weaponDef and weaponDef.WalkSpeedMultiplier then
		speed *= weaponDef.WalkSpeedMultiplier
	end
	if player:GetAttribute("CarryingFlag") then
		speed *= GameConfig.Flag.CarrierSpeedMultiplier
	end
	humanoid.WalkSpeed = speed
end

local function onCharacter(newCharacter)
	if stopSlide then
		stopSlide()
		stopSlide = nil
	end
	ClientState.Sliding = false
	iceMover = nil -- era del personaje anterior
	humanoid = newCharacter:WaitForChild("Humanoid")
	rootPart = newCharacter:WaitForChild("HumanoidRootPart")
	humanoid.CameraOffset = Vector3.zero
end

function Movement.Init()
	ContextActionService:BindAction("Sprint", function(_, state, input)
		if input.UserInputType == Enum.UserInputType.Touch then
			if state == Enum.UserInputState.Begin then
				sprintHeld = not sprintHeld
			end
		elseif state == Enum.UserInputState.Begin then
			sprintHeld = true
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			sprintHeld = false
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("Sprint", "Correr")
	ContextActionService:SetPosition("Sprint", UDim2.new(1, -260, 1, -160))

	ContextActionService:BindAction("Slide", function(_, state)
		if state == Enum.UserInputState.Begin then
			slide()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonR3)
	ContextActionService:SetTitle("Slide", "Deslizar")
	ContextActionService:SetPosition("Slide", UDim2.new(1, -270, 1, -240))

	-- Si la ventana pierde el foco dejamos de correr
	UserInputService.WindowFocusReleased:Connect(function()
		sprintHeld = false
	end)

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	RunService.Heartbeat:Connect(update)
end

return Movement
