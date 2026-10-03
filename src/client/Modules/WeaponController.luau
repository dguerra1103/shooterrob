-- Control de armas en primera persona: viewmodel, disparo, recarga, apuntado, cuchillo y cambio de arma.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)
local WeaponModels = require(Shared.WeaponModels)
local Sounds = require(Shared.Sounds)
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local Effects = require(script.Parent.Effects)
local Outfits = require(Shared.Outfits)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WeaponController = {}

-- Hombros del viewmodel (espacio de cámara, fuera de pantalla)
local RIGHT_SHOULDER = Vector3.new(1.1, -1.5, 0.4)
local LEFT_SHOULDER = Vector3.new(-0.7, -1.5, 0.2)

local character, humanoid, rootPart
local equippedTool, def
local viewmodel
local attrConnection

local triggerHeld = false
local aimHeld = false
local lastShot = 0
local localAmmo = 0
local reloadStart = nil
local equipTime = 0
local meleeTime = -10
local meleeWithKnife = false

local recoilKick, recoilRot = 0, 0
local camKick, camYaw = 0, 0
local swayX, swayY = 0, 0
local bobTime = 0
local aimAlpha, sprintAlpha = 0, 0
local viewmodelHidden = false
local pulseParts = {} -- piezas de neón que laten (skins míticas)
local pulseSkin = nil
local strafeRoll = 0
local shakeRoll = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function updateRayFilter()
	local ignore = { camera }
	if character then
		table.insert(ignore, character)
	end
	local fx = workspace:FindFirstChild("ClientFX")
	if fx then
		table.insert(ignore, fx)
	end
	-- Muros y techo invisibles del borde del mapa: las balas los atraviesan
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	rayParams.FilterDescendantsInstances = ignore
end

---------------------------------------------------------------------------
-- Viewmodel
---------------------------------------------------------------------------

local function skinTone()
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	return hand and hand.Color or Color3.fromRGB(255, 204, 153)
end

local function addArm(model, handPos, shoulderCam, weaponDef)
	local shoulder = weaponDef.ViewOffset:PointToObjectSpace(shoulderCam)
	local length = (shoulder - handPos).Magnitude
	local sleeveColor = player.Team and player.TeamColor.Color or Color3.fromRGB(60, 60, 70)
	-- Con traje de operador, los brazos llevan sus colores
	local outfitColors = Outfits.ArmColors(ClientState.Data and ClientState.Data.EquippedOutfit)
	if outfitColors then
		sleeveColor = outfitColors.Sleeve
	end

	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Size = Vector3.new(0.4, 0.4, length)
	arm.CFrame = CFrame.lookAt((handPos + shoulder) / 2, handPos)
	arm.Color = skinTone()
	arm.Material = Enum.Material.SmoothPlastic
	arm.Parent = model

	local sleeve = Instance.new("Part")
	sleeve.Name = "Sleeve"
	sleeve.Size = Vector3.new(0.46, 0.46, length * 0.55)
	sleeve.CFrame = CFrame.lookAt(shoulder:Lerp(handPos, 0.27), handPos)
	sleeve.Color = sleeveColor
	sleeve.Material = Enum.Material.Fabric
	sleeve.Parent = model

	local glove = Instance.new("Part")
	glove.Name = "Glove"
	glove.Size = Vector3.new(0.48, 0.48, 0.55)
	glove.CFrame = CFrame.lookAt(handPos + (shoulder - handPos).Unit * 0.15, handPos)
	glove.Color = outfitColors and outfitColors.Glove or Color3.fromRGB(25, 25, 28)
	glove.Material = Enum.Material.Fabric
	glove.Parent = model

	-- Puño blanco de la manga
	local cuff = Instance.new("Part")
	cuff.Name = "Cuff"
	cuff.Size = Vector3.new(0.5, 0.5, 0.12)
	cuff.CFrame = CFrame.lookAt(shoulder:Lerp(handPos, 0.545), handPos)
	cuff.Color = outfitColors and outfitColors.Cuff or Color3.fromRGB(245, 245, 250)
	cuff.Material = outfitColors and Enum.Material.Neon or Enum.Material.Fabric
	cuff.Parent = model
end

-- Oculta en nuestra pantalla el Tool real (los demás jugadores sí lo ven)
local function hideToolLocally(tool)
	for _, inst in tool:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.LocalTransparencyModifier = 1
		elseif inst:IsA("ParticleEmitter") then
			inst.Enabled = false
		end
	end
end

local function destroyViewmodel()
	if viewmodel then
		viewmodel:Destroy()
		viewmodel = nil
	end
	viewmodelHidden = false
end

local function createViewmodel(tool)
	destroyViewmodel()
	local weaponName = tool:GetAttribute("Weapon")
	local weaponDef = Weapons.Get(weaponName)
	local model = WeaponModels.Build(weaponName, tool:GetAttribute("Skin"))
	if weaponDef.RightHand then
		addArm(model, weaponDef.RightHand, RIGHT_SHOULDER, weaponDef)
	end
	if weaponDef.LeftHand then
		addArm(model, weaponDef.LeftHand, LEFT_SHOULDER, weaponDef)
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
		end
	end
	model.Name = "Viewmodel"
	model.Parent = camera
	viewmodel = model

	-- Skins con "Pulse": los detalles de neón laten
	table.clear(pulseParts)
	pulseSkin = WeaponModels.GetPalette(weaponName, tool:GetAttribute("Skin"))
	if pulseSkin.Pulse then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part:GetAttribute("Role") == "Accent" then
				table.insert(pulseParts, part)
			end
		end
	end
end

local function setViewmodelHidden(hidden)
	if not viewmodel or viewmodelHidden == hidden then
		return
	end
	viewmodelHidden = hidden
	for _, part in viewmodel:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = hidden and 1 or 0
		elseif part:IsA("ParticleEmitter") then
			part.Enabled = not hidden
		end
	end
end

---------------------------------------------------------------------------
-- Equipar
---------------------------------------------------------------------------

local function onUnequipped()
	if attrConnection then
		attrConnection:Disconnect()
		attrConnection = nil
	end
	destroyViewmodel()
	equippedTool, def = nil, nil
	triggerHeld = false
	reloadStart = nil
	ClientState.CurrentTool = nil
	ClientState.CurrentDef = nil
	ClientState.Reloading = false
	ClientState.WeaponChanged:Fire()
end

local function onEquipped(tool)
	if equippedTool then
		onUnequipped()
	end
	local weaponDef = Weapons.Get(tool:GetAttribute("Weapon"))
	if not weaponDef then
		return
	end
	equippedTool, def = tool, weaponDef
	equipTime = os.clock()
	reloadStart = nil
	localAmmo = tool:GetAttribute("Ammo") or 0

	hideToolLocally(tool)
	createViewmodel(tool)

	attrConnection = tool.AttributeChanged:Connect(function(attribute)
		if attribute == "Ammo" then
			local serverAmmo = tool:GetAttribute("Ammo") or 0
			-- Subida = recarga; bajada = confirmación de disparos que ya predijimos
			if serverAmmo > localAmmo then
				localAmmo = serverAmmo
			else
				localAmmo = math.min(localAmmo, serverAmmo)
			end
		elseif attribute == "Skin" then
			createViewmodel(tool)
			hideToolLocally(tool)
		elseif attribute == "Reloading" and not tool:GetAttribute("Reloading") then
			reloadStart = nil
		end
	end)

	ClientState.CurrentTool = tool
	ClientState.CurrentDef = weaponDef
	ClientState.WeaponChanged:Fire()
end

local function getTools()
	local list = {}
	local containers = { player:FindFirstChildOfClass("Backpack"), character }
	for _, container in containers do
		if container then
			for _, tool in container:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("Slot") then
					list[tool:GetAttribute("Slot")] = tool
				end
			end
		end
	end
	return list
end
WeaponController.GetTools = getTools

local function equipSlot(slot)
	if not humanoid or humanoid.Health <= 0 or ClientState.IsBlocked() then
		return
	end
	local tool = getTools()[slot]
	if tool and tool ~= equippedTool then
		humanoid:EquipTool(tool)
	end
end

local function cycleSlot(direction)
	local current = equippedTool and equippedTool:GetAttribute("Slot") or 1
	local tools = getTools()
	for i = 1, 3 do
		local slot = (current - 1 + direction * i) % 3 + 1
		if tools[slot] then
			equipSlot(slot)
			return
		end
	end
end

---------------------------------------------------------------------------
-- Disparo
---------------------------------------------------------------------------

local function randomInCone(direction, degrees)
	if degrees <= 0 then
		return direction
	end
	local angle = math.rad(degrees) * math.sqrt(math.random())
	local spin = math.random() * math.pi * 2
	return (CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(0, 0, spin) * CFrame.Angles(angle, 0, 0)).LookVector
end

local function currentSpread()
	if not def or def.Type ~= "Gun" then
		return 0
	end
	local spread = lerp(def.Spread, def.AimSpread, aimAlpha)
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity
		if Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 2 then
			spread *= 1.5
		end
	end
	if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
		spread *= 2
	end
	return spread + ClientState.Bloom * (1 - aimAlpha * 0.7)
end

local function requestReload()
	if not equippedTool or not def or def.Type ~= "Gun" or reloadStart then
		return
	end
	local reserve = equippedTool:GetAttribute("Reserve") or 0
	if localAmmo >= def.MagSize or reserve <= 0 then
		return
	end
	reloadStart = os.clock()
	Remotes.Reload:FireServer(equippedTool)
	Sounds.Play("Reload")
end

local function fire()
	local now = os.clock()
	if not equippedTool or not def or def.Type ~= "Gun" or ClientState.IsBlocked() then
		return
	end
	if now - lastShot < 1 / def.FireRate or reloadStart or now - equipTime < 0.25 then
		return
	end
	if localAmmo <= 0 then
		lastShot = now
		Sounds.Play("Empty")
		requestReload()
		return
	end

	lastShot = now
	localAmmo -= 1
	ClientState.LastShotTime = now
	ClientState.Sprinting = false

	updateRayFilter()
	local origin = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	local muzzle = viewmodel and viewmodel.PrimaryPart and viewmodel.PrimaryPart:FindFirstChild("Muzzle")
	local muzzlePos = muzzle and muzzle.WorldPosition or origin
	local tracerColor = WeaponModels.GetPalette(equippedTool:GetAttribute("Weapon"), equippedTool:GetAttribute("Skin")).Accent
	local spread = currentSpread()

	local rays = {}
	if def.Explosive then
		-- Cohete: viaja hasta el impacto y explota
		local direction = randomInCone(look, spread)
		local result = workspace:Raycast(origin, direction * def.Range, rayParams)
		local hitPosition = result and result.Position or origin + direction * def.Range
		table.insert(rays, { Part = result and result.Instance or nil, Position = hitPosition })
		Effects.Rocket(muzzlePos, hitPosition, def.ProjectileSpeed or 200, tracerColor, def.Explosive.Radius)
	end
	for _ = 1, def.Explosive and 0 or def.Pellets do
		local direction = randomInCone(look, spread)
		local result = workspace:Raycast(origin, direction * def.Range, rayParams)
		local hitPosition = result and result.Position or origin + direction * def.Range
		table.insert(rays, { Part = result and result.Instance or nil, Position = hitPosition })
		Effects.Tracer(muzzlePos, hitPosition, tracerColor)
		if result then
			Effects.Impact(result.Position, result.Normal, result.Instance)
		end
	end
	Remotes.Fire:FireServer(equippedTool, origin, rays)

	Effects.MuzzleFlash(muzzle)
	local eject = viewmodel and viewmodel.PrimaryPart and viewmodel.PrimaryPart:FindFirstChild("Eject")
	if not def.Explosive then
		Effects.ShellCasing(eject, camera.CFrame, def.Pellets > 1 and Color3.fromRGB(220, 50, 50) or nil)
	end
	Sounds.PlayShot(equippedTool and equippedTool:GetAttribute("Weapon"), def)
	shakeRoll += (math.random() - 0.5) * math.rad(def.Recoil) * 0.6

	-- Retroceso
	local recoil = math.rad(def.Recoil)
	recoilKick += 0.08 + def.Recoil * 0.03
	recoilRot += recoil * 0.6
	camKick += recoil * (1 - aimAlpha * 0.35)
	camYaw += (math.random() - 0.5) * recoil * 0.5
	ClientState.Bloom = math.min(ClientState.Bloom + def.Recoil * 0.4, 6)
	ClientState.ShotFired:Fire()

	if localAmmo <= 0 then
		task.delay(0.2, requestReload)
	end
end

-- Ráfaga (Vortex AR-9, Phantom Sidewind): varios disparos seguidos con una pausa entre ráfagas
local bursting = false
local lastBurstEnd = 0
local function startBurst()
	if bursting or not def or not def.Burst then
		return
	end
	if os.clock() - lastBurstEnd < (def.BurstCooldown or 0.3) then
		return
	end
	bursting = true
	local burstDef = def
	task.spawn(function()
		for i = 1, burstDef.Burst do
			if def ~= burstDef or localAmmo <= 0 or reloadStart then
				break
			end
			fire()
			if i < burstDef.Burst then
				task.wait(1 / burstDef.FireRate + 0.01)
			end
		end
		lastBurstEnd = os.clock()
		bursting = false
	end)
end

local function melee()
	local knife = Weapons.Get(Weapons.Melee)
	local now = os.clock()
	if now - meleeTime < knife.Cooldown or ClientState.IsBlocked() or not humanoid or humanoid.Health <= 0 then
		return
	end
	if not getTools()[knife.Slot] then
		return
	end
	meleeTime = now
	meleeWithKnife = def ~= nil and def.Type == "Melee"
	reloadStart = nil
	Sounds.Play("Swing")

	updateRayFilter()
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * knife.Range
	local result = workspace:Spherecast(origin, 1.2, direction, rayParams) or workspace:Raycast(origin, direction, rayParams)
	if result and result.Instance then
		Remotes.Melee:FireServer(result.Instance)
	end
end

---------------------------------------------------------------------------
-- Animación procedural del viewmodel (cada frame)
---------------------------------------------------------------------------

local function renderStep(dt)
	if not character or not humanoid then
		return
	end

	-- Disparo automático
	if triggerHeld and def and def.Type == "Gun" and def.Automatic then
		fire()
	end

	ClientState.Bloom = math.max(0, ClientState.Bloom - dt * 8)
	ClientState.Spread = currentSpread()

	-- Recarga: tiempo límite por si el servidor la rechazó
	if reloadStart and def and os.clock() - reloadStart > def.ReloadTime + 1 then
		reloadStart = nil
	end
	ClientState.Reloading = reloadStart ~= nil
	ClientState.ReloadProgress = (reloadStart and def) and math.clamp((os.clock() - reloadStart) / def.ReloadTime, 0, 1)
		or 0
	ClientState.Ammo = localAmmo

	-- Apuntar
	local canAim = def ~= nil and def.Type == "Gun" and aimHeld and not reloadStart and not ClientState.IsBlocked()
	ClientState.Aiming = canAim
	aimAlpha = lerp(aimAlpha, canAim and 1 or 0, math.min(1, dt * 14))
	if aimAlpha < 0.001 then
		aimAlpha = 0
	end
	ClientState.AimAlpha = aimAlpha
	sprintAlpha = lerp(sprintAlpha, (ClientState.Sprinting and not reloadStart) and 1 or 0, math.min(1, dt * 10))

	-- Retroceso de cámara
	local applyPitch = camKick * math.min(1, dt * 22)
	local applyYaw = camYaw * math.min(1, dt * 22)
	camKick -= applyPitch
	camYaw -= applyYaw
	if applyPitch ~= 0 or applyYaw ~= 0 then
		camera.CFrame = camera.CFrame * CFrame.Angles(applyPitch, applyYaw, 0)
	end

	-- Inclinación de cámara al moverse de lado y pequeña sacudida al disparar.
	-- El módulo de cámara recalcula el giro cada frame, así que esto no se acumula.
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity
		local side = velocity:Dot(camera.CFrame.RightVector)
		strafeRoll = lerp(strafeRoll, math.clamp(-side / 26, -1, 1) * math.rad(1.6), math.min(1, dt * 8))
	end
	shakeRoll = lerp(shakeRoll, 0, math.min(1, dt * 18))
	camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, strafeRoll + shakeRoll)

	-- Latido de las skins míticas
	if #pulseParts > 0 and pulseSkin then
		local t = (math.sin(os.clock() * 3) + 1) / 2
		local color = pulseSkin.Accent:Lerp(pulseSkin.Accent2 or Color3.new(1, 1, 1), t)
		for _, part in pulseParts do
			part.Color = color
		end
	end

	-- Campo de visión (el del menú Ajustes) y sensibilidad: al apuntar baja en proporción al zoom
	local settings = ClientState.Settings or GameConfig.DefaultSettings
	local baseFov = settings.FOV or GameConfig.FieldOfView
	local targetFov = baseFov
	local aimScale = 1
	if def and def.AimFOV then
		targetFov = lerp(baseFov, math.min(def.AimFOV, baseFov), aimAlpha)
		aimScale = lerp(1, (settings.AimSensitivity or 0.8) * math.min(1, def.AimFOV / baseFov) ^ 0.5, aimAlpha)
	end
	camera.FieldOfView = targetFov + sprintAlpha * 6
	UserInputService.MouseDeltaSensitivity = (settings.Sensitivity or 1) * aimScale

	if not viewmodel or not def then
		return
	end

	local now = os.clock()

	-- Balanceo al caminar
	local speed = 0
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity
		speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	end
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded and not ClientState.Sliding then
		bobTime += dt * math.min(speed, 30) * 0.45
	end
	local bobAmount = math.clamp(speed / 18, 0, 1.5) * (1 - aimAlpha * 0.9)
	if not grounded or ClientState.Sliding then
		bobAmount = 0
	end
	local bob = CFrame.new(math.cos(bobTime) * 0.05 * bobAmount, -math.abs(math.sin(bobTime)) * 0.06 * bobAmount, 0)

	-- Inercia al mover el ratón
	local delta = UserInputService:GetMouseDelta()
	swayX = lerp(swayX, math.clamp(-delta.X * 0.004, -0.12, 0.12), math.min(1, dt * 10))
	swayY = lerp(swayY, math.clamp(-delta.Y * 0.004, -0.12, 0.12), math.min(1, dt * 10))
	local swayScale = 1 - aimAlpha * 0.75
	local sway = CFrame.Angles(swayY * swayScale, swayX * swayScale, swayX * 0.6 * swayScale)

	-- Retroceso del arma
	recoilKick = lerp(recoilKick, 0, math.min(1, dt * 16))
	recoilRot = lerp(recoilRot, 0, math.min(1, dt * 14))
	local recoilCF = CFrame.new(0, 0, recoilKick) * CFrame.Angles(recoilRot, 0, 0)

	-- Cadera -> mira
	local base = def.ViewOffset
	if def.AimPoint then
		local a = def.AimPoint
		local aimCF = CFrame.new(-a.X, -a.Y, -def.AimDistance - a.Z)
		base = def.ViewOffset:Lerp(aimCF, aimAlpha)
	end

	-- Correr
	local s = sprintAlpha
	local sprintCF = CFrame.new(-0.25 * s, -0.2 * s, 0.1 * s) * CFrame.Angles(math.rad(-12) * s, math.rad(35) * s, math.rad(18) * s)

	-- Recarga
	local reloadCF = CFrame.new()
	if reloadStart then
		local r = math.sin(ClientState.ReloadProgress * math.pi)
		reloadCF = CFrame.new(0, -0.35 * r, 0) * CFrame.Angles(math.rad(-20) * r, 0, math.rad(35) * r)
	end

	-- Sacar arma
	local e = 1 - math.clamp((now - equipTime) / 0.3, 0, 1)
	local equipCF = CFrame.new(0, -0.8 * e * e, 0) * CFrame.Angles(math.rad(-40) * e, 0, 0)

	-- Cuchillazo / golpe rápido
	local meleeCF = CFrame.new()
	local m = (now - meleeTime) / 0.35
	if m < 1 then
		local k = math.sin(m * math.pi)
		if meleeWithKnife then
			meleeCF = CFrame.new(-0.6 * k, 0.2 * k, -0.6 * k)
				* CFrame.Angles(math.rad(-20) * k, math.rad(70) * k, math.rad(-30) * k)
		else
			meleeCF = CFrame.new(-0.3 * k, 0, -0.5 * k) * CFrame.Angles(0, math.rad(30) * k, math.rad(20) * k)
		end
	end

	viewmodel:PivotTo(camera.CFrame * bob * sway * base * sprintCF * reloadCF * equipCF * meleeCF * recoilCF)

	-- Mira telescópica: ocultar el arma
	-- (y también en la pantalla de inicio, donde la cámara está lejos)
	setViewmodelHidden((def.Scope == true and aimAlpha > 0.85) or ClientState.InMainMenu)
end

---------------------------------------------------------------------------
-- Entrada
---------------------------------------------------------------------------

local function bindActions()
	ContextActionService:BindAction("Fire", function(_, state)
		if ClientState.IsBlocked() then
			triggerHeld = false
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
			triggerHeld = true
			if def and def.Type == "Melee" then
				melee()
			elseif def and def.Burst then
				startBurst()
			else
				fire()
			end
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			triggerHeld = false
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
	ContextActionService:SetTitle("Fire", "Disparar")
	ContextActionService:SetPosition("Fire", UDim2.new(1, -110, 1, -160))

	ContextActionService:BindAction("Aim", function(_, state, input)
		if ClientState.IsBlocked() then
			aimHeld = false
			return Enum.ContextActionResult.Pass
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			if state == Enum.UserInputState.Begin then
				aimHeld = not aimHeld -- en móvil es un interruptor
			end
		elseif state == Enum.UserInputState.Begin then
			aimHeld = true
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			aimHeld = false
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)
	ContextActionService:SetTitle("Aim", "Apuntar")
	ContextActionService:SetPosition("Aim", UDim2.new(1, -190, 1, -110))

	ContextActionService:BindAction("Reload", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			requestReload()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle("Reload", "R")
	ContextActionService:SetPosition("Reload", UDim2.new(1, -200, 1, -190))

	ContextActionService:BindAction("Melee", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			melee()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("Melee", "F")
	ContextActionService:SetPosition("Melee", UDim2.new(1, -120, 1, -240))

	ContextActionService:BindAction("Slots", function(_, state, input)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if input.KeyCode == Enum.KeyCode.One then
			equipSlot(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			equipSlot(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			equipSlot(3)
		elseif input.KeyCode == Enum.KeyCode.ButtonY then
			cycleSlot(1)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.ButtonY)

	UserInputService.InputChanged:Connect(function(input, processed)
		if processed or ClientState.IsBlocked() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			cycleSlot(input.Position.Z > 0 and -1 or 1)
		end
	end)
end

---------------------------------------------------------------------------
-- Personaje
---------------------------------------------------------------------------

local function onCharacter(newCharacter)
	onUnequipped()
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	rootPart = newCharacter:WaitForChild("HumanoidRootPart")
	aimHeld = false
	camKick, camYaw = 0, 0
	updateRayFilter()

	newCharacter.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("Weapon") then
			onEquipped(child)
		end
	end)
	newCharacter.ChildRemoved:Connect(function(child)
		if child == equippedTool then
			onUnequipped()
		end
	end)
	local existing = newCharacter:FindFirstChildOfClass("Tool")
	if existing and existing:GetAttribute("Weapon") then
		onEquipped(existing)
	end

	humanoid.Died:Connect(function()
		onUnequipped()
		triggerHeld = false
	end)
end

-- Efectos de los disparos de otros jugadores
local function onShotFX(tool, endpoints)
	if typeof(tool) ~= "Instance" or not tool.Parent or type(endpoints) ~= "table" then
		return
	end
	local handle = tool:FindFirstChild("Handle")
	local muzzle = handle and handle:FindFirstChild("Muzzle")
	if not muzzle then
		return
	end
	local color = WeaponModels.GetPalette(tool:GetAttribute("Weapon"), tool:GetAttribute("Skin")).Accent
	local weaponDef = Weapons.Get(tool:GetAttribute("Weapon"))
	for _, position in endpoints do
		if typeof(position) == "Vector3" then
			if weaponDef and weaponDef.Explosive then
				Effects.Rocket(muzzle.WorldPosition, position, weaponDef.ProjectileSpeed or 200, color, weaponDef.Explosive.Radius)
			else
				Effects.Tracer(muzzle.WorldPosition, position, color)
			end
		end
	end
	Effects.MuzzleFlash(muzzle)
	Sounds.PlayShot(tool:GetAttribute("Weapon"), weaponDef, handle)
end

function WeaponController.Init()
	UserInputService.MouseIconEnabled = false
	bindActions()
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	Remotes.ShotFX.OnClientEvent:Connect(onShotFX)
	RunService:BindToRenderStep("WeaponViewmodel", Enum.RenderPriority.Camera.Value + 1, renderStep)
end

return WeaponController
