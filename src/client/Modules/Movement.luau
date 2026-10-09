-- Movimiento: correr (Shift), agacharse (C) y deslizarse (C corriendo), con sensación realista (GameConfig.Movement):
--   * aceleración: se arranca y se pasa a correr poco a poco, y se frena rápido
--   * solo se corre hacia delante, y correr gasta estamina (si se agota, hay que recuperarse)
--   * saltar también gasta un poco; cansado se salta menos
--   * aterrizar desde alto da un golpe de cámara y, si es muy alto, frena un momento
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Sounds = require(Shared.Sounds)

local TouchLayout = require(script.Parent.TouchLayout)
local HUDZones = require(script.Parent.HUDZones)
local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Movement = {}

local humanoid, rootPart
local sprintHeld = false
local MOVE = GameConfig.Movement or {}
local currentSpeed = GameConfig.WalkSpeed
local lastStaminaUse = 0
local fallSpeed = 0 -- la mayor velocidad de caída desde que se despegó del suelo
local slowUntil = 0 -- aterrizaje fuerte: frena hasta entonces
local baseJumpHeight, baseJumpPower
local baseHipHeight -- (agacharse baja la cadera: cámara y cuerpo más bajos, también para los demás)
local staminaBar, staminaFill
local lastSlide = -10
local stopSlide

local function tweenCameraOffset(offset, time)
	if humanoid then
		TweenService:Create(humanoid, TweenInfo.new(time, Enum.EasingStyle.Quad), { CameraOffset = offset }):Play()
	end
end

-- Polvo que levanta el deslizamiento, del color del suelo (nieve, tierra, hormigón...)
local SLIDE_DUST = {
	[Enum.Material.Snow] = Color3.fromRGB(240, 245, 255),
	[Enum.Material.Ice] = Color3.fromRGB(225, 240, 255),
	[Enum.Material.Glacier] = Color3.fromRGB(225, 240, 255),
	[Enum.Material.Grass] = Color3.fromRGB(140, 120, 85),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(140, 120, 85),
	[Enum.Material.Ground] = Color3.fromRGB(150, 125, 90),
	[Enum.Material.Mud] = Color3.fromRGB(110, 85, 60),
	[Enum.Material.Sand] = Color3.fromRGB(205, 185, 140),
}

local function slideDust(floorMaterial)
	if not rootPart or not humanoid or ClientState.EffectiveQuality == "Baja" then
		return nil
	end
	local feet = Instance.new("Attachment")
	feet.Name = "SlideDust"
	feet.Position = Vector3.new(0, -(humanoid.HipHeight + rootPart.Size.Y / 2) + 0.3, 0)
	feet.Parent = rootPart
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(SLIDE_DUST[floorMaterial] or Color3.fromRGB(175, 172, 165))
	dust.LightInfluence = 1
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(0.5, 0.8)
	dust.Speed = NumberRange.new(2, 4)
	dust.SpreadAngle = Vector2.new(50, 50)
	dust.Acceleration = Vector3.new(0, 1, 0)
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-40, 40)
	dust.Rate = 40
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Parent = feet
	return feet
end

local wasFrozen = false

local function slide()
	if ClientState.Sliding or ClientState.Dashing or ClientState.IsBlocked() or ClientState.Frozen() or not humanoid or humanoid.Health <= 0 or not rootPart then
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
	local dust = slideDust(humanoid.FloorMaterial)

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
		if dust then
			-- Deja de emitir y se borra cuando se han disipado las últimas partículas
			local emitter = dust:FindFirstChildOfClass("ParticleEmitter")
			if emitter then
				emitter.Enabled = false
			end
			task.delay(1, function()
				dust:Destroy()
			end)
		end
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
		and not ClientState.Dashing
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

-- Barra de estamina fina debajo de la mira; solo se ve mientras no está llena
local function buildStaminaBar()
	local gui = UI.new("ScreenGui", {
		Name = "Stamina",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Parent = player:WaitForChild("PlayerGui"),
	})
	staminaBar = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 44),
		Size = UDim2.fromOffset(90, 5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 26),
		BackgroundTransparency = 0.35,
		Visible = false,
		Parent = gui,
	}, { UI.corner(3) })
	staminaFill = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(235, 240, 250),
		Parent = staminaBar,
	}, { UI.corner(3) })
	-- (táctil, Fase 16: con los avisos de bajo la mira, fuera del centro libre)
	HUDZones.Register("Stamina", staminaBar, "BOTTOM_NOTICE", 3)
end

local function updateStaminaBar()
	if not staminaBar then
		return
	end
	local stamina = ClientState.Stamina
	staminaBar.Visible = stamina < 0.995 and not ClientState.InMainMenu and not ClientState.Dead
	staminaFill.Size = UDim2.fromScale(math.clamp(stamina, 0, 1), 1)
	staminaFill.BackgroundColor3 = ClientState.Exhausted and Color3.fromRGB(255, 90, 80) or Color3.fromRGB(235, 240, 250)
end

-- Estamina: correr la gasta; se recupera tras un momento sin correr ni saltar
local function updateStamina(dt)
	local now = os.clock()
	local stamina = ClientState.Stamina
	if ClientState.Sprinting then
		stamina -= dt / (MOVE.StaminaSeconds or 6)
		lastStaminaUse = now
		if stamina <= 0 then
			stamina = 0
			ClientState.Exhausted = true
		end
	elseif now - lastStaminaUse > (MOVE.RegenDelay or 0.8) then
		stamina = math.min(1, stamina + dt / (MOVE.RegenSeconds or 4))
	end
	if ClientState.Exhausted and stamina >= (MOVE.MinToSprint or 0.3) then
		ClientState.Exhausted = false
	end
	ClientState.Stamina = stamina
end

-- Correr solo en el móvil (Ajustes → Controles táctiles → Correr: Auto): con el joystick empujado
-- casi hasta el borde se corre, sin botón. El empuje se lee del ControlModule de Roblox
-- (PlayerModule:GetControls():GetMoveVector(), de 0 a 1); MoveDirection siempre mide 1.
local controls
local controlsRetryAt = 0
local function autoSprint(): boolean
	local settings = ClientState.Settings
	if (settings and settings.AutoSprint or 1) ~= 1 or UserInputService.TouchEnabled ~= true then
		return false
	end
	local okType, lastType = pcall(UserInputService.GetLastInputType, UserInputService)
	if not okType or lastType ~= Enum.UserInputType.Touch then
		return false
	end
	-- (el PlayerModule de Roblox puede no estar aún en el primer fotograma: se reintenta cada segundo)
	if not controls and os.clock() >= controlsRetryAt then
		controlsRetryAt = os.clock() + 1
		controls = false
		local module = player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("PlayerModule")
		if module then
			local ok, playerModule = pcall(require, module)
			if ok and type(playerModule) == "table" and playerModule.GetControls then
				controls = playerModule:GetControls() or false
			end
		end
	end
	if not controls then
		return false
	end
	local ok, vector = pcall(controls.GetMoveVector, controls)
	return ok and typeof(vector) == "Vector3" and vector.Magnitude >= (MOVE.AutoSprintPush or 0.9)
end

local function update(dt)
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		ClientState.Sprinting = false
		updateStaminaBar()
		return
	end
	iceSlide(dt)
	local moveDirection = humanoid.MoveDirection
	local moving = moveDirection.Magnitude > 0.1
	local recentlyShot = os.clock() - ClientState.LastShotTime < 0.35
	-- Solo se corre hacia delante (no de lado ni hacia atrás)
	local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	local flatMove = Vector3.new(moveDirection.X, 0, moveDirection.Z)
	local forward = moving and look.Magnitude > 0.01 and flatMove.Magnitude > 0.01 and flatMove.Unit:Dot(look.Unit) >= (MOVE.SprintAngle or 0.55)
	ClientState.Sprinting = (sprintHeld or autoSprint())
		and moving
		and forward
		and not ClientState.Exhausted
		and not ClientState.Aiming
		and not recentlyShot
		and not ClientState.Sliding
		and not ClientState.IsBlocked()
	-- Correr, deslizarse o estar en el aire te levanta
	if ClientState.Crouching and (ClientState.Sprinting or ClientState.Sliding or humanoid.FloorMaterial == Enum.Material.Air) then
		ClientState.Crouching = false
	end
	if baseHipHeight then
		local target = baseHipHeight - (ClientState.Crouching and (GameConfig.CrouchDrop or 1.3) or 0)
		if math.abs(humanoid.HipHeight - target) > 0.01 then
			humanoid.HipHeight += (target - humanoid.HipHeight) * math.min(1, dt * 12)
		end
	end
	updateStamina(dt)
	updateStaminaBar()

	-- Caída: se apunta la velocidad máxima hasta tocar suelo (el golpe lo da onLanded)
	if humanoid.FloorMaterial == Enum.Material.Air then
		fallSpeed = math.max(fallSpeed, -rootPart.AssemblyLinearVelocity.Y)
	end
	-- Cansado se salta menos
	local jumpScale = ClientState.Exhausted and (MOVE.TiredJump or 0.7) or 1
	if baseJumpHeight then
		humanoid.JumpHeight = baseJumpHeight * jumpScale
		humanoid.JumpPower = baseJumpPower * jumpScale
	end

	local speed = GameConfig.WalkSpeed
	if ClientState.Sprinting then
		speed = GameConfig.SprintSpeed
	elseif ClientState.Crouching then
		speed = GameConfig.CrouchSpeed or 10
	elseif ClientState.Aiming then
		speed = GameConfig.AimWalkSpeed
	end
	local weaponDef = ClientState.CurrentDef
	if weaponDef and weaponDef.WalkSpeedMultiplier then
		speed *= weaponDef.WalkSpeedMultiplier
	end
	-- Ventaja "Ligero"
	local perkId = player:GetAttribute("Perk")
	for _, perk in GameConfig.Perks or {} do
		if perk.Id == perkId and perk.SpeedMultiplier then
			speed *= perk.SpeedMultiplier
		end
	end
	if player:GetAttribute("CarryingFlag") then
		speed *= GameConfig.Flag.CarrierSpeedMultiplier
	end
	if os.clock() < slowUntil then
		speed *= 0.6 -- aterrizaje fuerte
	end
	-- Aceleración: se arranca con parte de la velocidad y se llega a la máxima poco a poco
	if not moving then
		currentSpeed = math.min(currentSpeed, speed * (MOVE.StartFactor or 0.55))
	elseif currentSpeed < speed then
		currentSpeed = math.min(speed, currentSpeed + (MOVE.Acceleration or 30) * dt)
	else
		currentSpeed = math.max(speed, currentSpeed - (MOVE.Deceleration or 70) * dt)
	end
	-- Cuenta atrás de Eliminación: quieto y sin saltar
	local frozen = ClientState.Frozen()
	if frozen then
		currentSpeed = 0
	end
	if frozen ~= wasFrozen then
		wasFrozen = frozen
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not frozen)
	end
	humanoid.WalkSpeed = currentSpeed
end

-- Al tocar suelo tras una caída: golpe de cámara, sonido y, si fue muy alta, frena un momento
local function onLanded()
	local speed = fallSpeed
	fallSpeed = 0
	local hard = MOVE.HardLanding or 38
	if speed < hard then
		return
	end
	local k = math.clamp((speed - hard) / 40, 0, 1)
	ClientState.LandKick = math.max(ClientState.LandKick or 0, 0.35 + 0.65 * k)
	Sounds.Play("Land", nil, 1 - 0.15 * k, 0.5 + 0.5 * k)
	if speed >= (MOVE.HeavyLanding or 62) then
		slowUntil = os.clock() + 0.35
	end
end

local function onCharacter(newCharacter)
	if stopSlide then
		stopSlide()
		stopSlide = nil
	end
	ClientState.Sliding = false
	iceMover = nil -- era del personaje anterior
	humanoid = newCharacter:WaitForChild("Humanoid")
	wasFrozen = false -- el humanoide nuevo empieza con el salto activado (después de cambiarlo)
	rootPart = newCharacter:WaitForChild("HumanoidRootPart")
	humanoid.CameraOffset = Vector3.zero
	baseJumpHeight, baseJumpPower = humanoid.JumpHeight, humanoid.JumpPower
	baseHipHeight = humanoid.HipHeight
	ClientState.Crouching = false
	currentSpeed = GameConfig.WalkSpeed * (MOVE.StartFactor or 0.55)
	fallSpeed = 0
	slowUntil = 0
	ClientState.Stamina = 1
	ClientState.Exhausted = false
	local character = newCharacter
	humanoid.StateChanged:Connect(function(_, new)
		if player.Character ~= character then
			return
		end
		if new == Enum.HumanoidStateType.Landed then
			onLanded()
		elseif new == Enum.HumanoidStateType.Jumping then
			-- Saltar gasta un poco de estamina
			ClientState.Stamina = math.max(0, ClientState.Stamina - (MOVE.JumpCost or 0.12))
			lastStaminaUse = os.clock()
		end
	end)
end

function Movement.Init()
	buildStaminaBar()
	TouchLayout.BindAction("Sprint", function(_, state, input)
		if input and input.UserInputType == Enum.UserInputType.Touch then
			if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
				sprintHeld = not sprintHeld
			end
		elseif state == Enum.UserInputState.Begin then
			sprintHeld = true
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			sprintHeld = false
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)

	-- C: corriendo te deslizas; si no, te agachas o te levantas (como en los shooters de móvil)
	TouchLayout.BindAction("Slide", function(_, state)
		if state == Enum.UserInputState.Begin then
			local running = ClientState.Sprinting or currentSpeed > GameConfig.WalkSpeed + 1
			if running then
				ClientState.Crouching = false
				slide()
			elseif not ClientState.Sliding and not ClientState.IsBlocked() and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
				ClientState.Crouching = not ClientState.Crouching
			end
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonR3)

	-- Saltar (táctil, Fase 15): el botón es nuestro (va en el grupo de combate con su jerarquía; el de
	-- Roblox se esconde en TouchLayout) y hace EXACTAMENTE lo que hace el de Roblox: mientras el dedo
	-- está encima, Humanoid.Jump = true en cada fotograma, justo después del ControlModule de Roblox
	-- (que lo pone a false si nadie salta). Misma altura, mismo coste de estamina, mismo autosalto.
	local jumpHeld = false
	if TouchLayout.BindButton("Jump", function(_, state)
		if state == Enum.UserInputState.Begin then
			jumpHeld = not ClientState.IsBlocked()
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			jumpHeld = false
		end
		return Enum.ContextActionResult.Pass
	end) then
		RunService:BindToRenderStep("TouchJump", Enum.RenderPriority.Input.Value + 1, function()
			if jumpHeld and humanoid and humanoid.Health > 0 then
				humanoid.Jump = true
			end
		end)
	end
	Movement.TouchJumpHeld = function()
		return jumpHeld
	end

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
