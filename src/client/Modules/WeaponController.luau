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

local TouchLayout = require(script.Parent.TouchLayout)
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
local inspectTime = -10 -- "Inspeccionar" (V): gira el arma para lucir la skin
local INSPECT_TIME = 2.6
local meleeWithKnife = false

local recoilKick, recoilRot = 0, 0
local camKick, camYaw = 0, 0
-- Retroceso realista: muelles para el golpe del arma (empuja, se pasa un poco y vuelve) y la
-- "deuda" de retroceso: lo que subió la mira en la ráfaga; al dejar de disparar vuelve una parte
local kickVel, rotVel = 0, 0
local recoilSide, sideVel = 0, 0
local sprayCount = 0 -- disparos seguidos de la ráfaga actual
local debtPitch, debtYaw = 0, 0
local RECOVER = 0.65 -- parte del retroceso que la mira recupera sola al soltar
local swayX, swayY = 0, 0
local bobTime = 0
local aimAlpha, sprintAlpha = 0, 0
local viewmodelHidden = false
local pulseParts = {} -- piezas de neón que laten (skins míticas)
local pulseSkin = nil
local strafeRoll = 0
local shakeRoll = 0
local headBobTime = 0 -- balanceo de la cámara al andar (GameConfig.Movement.CameraBob)
local headBobAmount = 0

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
	-- Zombi (garras): brazos verdes y manga rota oscura
	local zombieSkin = weaponDef.ZombieArms
	if zombieSkin then
		sleeveColor = Color3.fromRGB(60, 45, 55)
		outfitColors = { Sleeve = sleeveColor, Glove = zombieSkin, Cuff = sleeveColor }
	end

	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Size = Vector3.new(0.4, 0.4, length)
	arm.CFrame = CFrame.lookAt((handPos + shoulder) / 2, handPos)
	arm.Color = zombieSkin or skinTone()
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
	cuff.Material = (outfitColors and not zombieSkin) and Enum.Material.Neon or Enum.Material.Fabric
	cuff.Parent = model
end

-- Oculta en nuestra pantalla el Tool real (los demás jugadores sí lo ven)
local function hideToolLocally(tool)
	for _, inst in tool:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.LocalTransparencyModifier = 1
		elseif inst:IsA("ParticleEmitter") then
			inst.Enabled = false
		elseif inst:IsA("SurfaceGui") or inst:IsA("BillboardGui") then
			inst.Enabled = false -- los rótulos del arma se verían flotando
		end
	end
end

local charmParts = {} -- { Part, Offset } del colgante del arma en primera persona
local charmRing = nil
local charmSwing, charmVelocity, lastCameraLook = 0, 0, nil

-- El colgante se balancea como un péndulo: lo empuja el giro de la cámara y vuelve solo
-- (igual a cualquier número de fotogramas por segundo)
local function resetCharm()
	charmSwing, charmVelocity, lastCameraLook = 0, 0, nil
end

local function swingCharm(dt)
	if not charmRing or not charmRing.Parent then
		return
	end
	dt = math.clamp(dt, 1 / 240, 0.05)
	local look = camera.CFrame.LookVector
	local turnRate = 0
	if lastCameraLook then
		turnRate = lastCameraLook:Cross(look).Y / dt -- giro horizontal (radianes por segundo)
	end
	lastCameraLook = look
	charmVelocity += (-charmSwing * 60 - charmVelocity * 4 + turnRate * 3) * dt
	-- (hacia dentro casi no puede: chocaría con el arma)
	charmSwing = math.clamp(charmSwing + charmVelocity * dt, -0.8, 0.12)
	local pivot = charmRing.CFrame * CFrame.Angles(0, 0, charmSwing)
	for _, entry in charmParts do
		entry.Part.CFrame = pivot * entry.Offset
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
	local model = WeaponModels.Build(weaponName, tool:GetAttribute("Skin"), nil, tool:GetAttribute("Charm"))
	-- Colgante: se guarda dónde está cada pieza respecto a la anilla para balancearlas (renderStep)
	table.clear(charmParts)
	local ring = model:FindFirstChild("CharmRing")
	if ring then
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part ~= ring and string.sub(part.Name, 1, 5) == "Charm" then
				table.insert(charmParts, { Part = part, Offset = ring.CFrame:ToObjectSpace(part.CFrame) })
			end
		end
	end
	charmRing = ring
	resetCharm()
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
	-- Brillo suave del neón del arma sobre las manos (se nota mucho en mapas oscuros)
	local glowPalette = WeaponModels.GetPalette(weaponName, tool:GetAttribute("Skin"))
	-- Solo si el neón brilla de verdad (las armas clásicas sin skin no llevan neón)
	local neonAccent = (glowPalette.AccentMaterial or Enum.Material.Neon) == Enum.Material.Neon
	if model.PrimaryPart and neonAccent then
		local glow = Instance.new("PointLight")
		glow.Name = "NeonGlow"
		glow.Color = glowPalette.Accent
		glow.Range = 4.5
		glow.Brightness = 0.7
		glow.Shadows = false
		glow.Parent = model.PrimaryPart
	end
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
	resetCharm()
	for _, part in viewmodel:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = hidden and 1 or 0
		elseif part:IsA("ParticleEmitter") then
			part.Enabled = not hidden
		elseif part:IsA("SurfaceGui") or part:IsA("PointLight") then
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
	sprayCount, debtPitch, debtYaw = 0, 0, 0 -- (el retroceso de otra arma no se recupera con esta)
	inspectTime = -10
	reloadStart = nil
	localAmmo = tool:GetAttribute("Ammo") or 0
	if weaponDef.Type == "Melee" then
		Sounds.Play("Unsheath")
	else
		Sounds.PlayGun("Equip", nil, weaponDef.Pellets > 1 and 0.85 or 1, 1)
	end

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
	local speed = 0
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity
		speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	end
	-- Cuanto más rápido te mueves, menos preciso (apuntando se nota menos)
	spread *= 1 + math.clamp(speed / 18, 0, 1.5) * (0.6 - aimAlpha * 0.35)
	if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
		spread *= 2
	end
	-- Primer disparo quieto y tras una pausa: casi exacto
	if speed < 2 and os.clock() - lastShot > math.max(0.35, 2.5 / def.FireRate) then
		spread *= 0.45
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
	inspectTime = -10
	Remotes.Reload:FireServer(equippedTool)
	-- Secuencia de la recarga: sacar el cargador, meter el nuevo y (si estaba vacía) montar el arma.
	-- Si la recarga se corta (cambias de arma, cuchillo...) deja de sonar.
	local token, reloadTime, wasEmpty = reloadStart, def.ReloadTime or 2, localAmmo <= 0
	local shotgun = def.Pellets > 1
	local function step(at, name, pitch, volume)
		task.delay(reloadTime * at, function()
			if reloadStart == token then
				Sounds.PlayGun(name, nil, pitch, volume)
			end
		end)
	end
	if shotgun then
		-- Escopetas: cartucho a cartucho
		for index, at in { 0.2, 0.38, 0.56, 0.74 } do
			step(at, "MagIn", 1.25 + index * 0.03, 0.55)
		end
	else
		step(0.12, "MagOut", 1, 1)
		step(0.55, "MagIn", 1, 1)
	end
	if wasEmpty or shotgun then
		step(0.85, "Bolt", shotgun and 0.75 or 1, 1)
	end
end

local function fire()
	local now = os.clock()
	if not equippedTool or not def or def.Type ~= "Gun" or ClientState.IsBlocked() or ClientState.Frozen() then
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

	if now - lastShot > math.max(0.3, 2.2 / def.FireRate) then
		sprayCount = 0 -- ráfaga nueva
	end
	sprayCount += 1
	local spread = currentSpread() -- (antes de apuntar este disparo: el primero va más preciso)
	lastShot = now
	localAmmo -= 1
	ClientState.LastShotTime = now
	inspectTime = -10
	ClientState.Sprinting = false

	updateRayFilter()
	local origin = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	local muzzle = viewmodel and viewmodel.PrimaryPart and viewmodel.PrimaryPart:FindFirstChild("Muzzle")
	local muzzlePos = muzzle and muzzle.WorldPosition or origin
	local tracerColor = WeaponModels.GetPalette(equippedTool:GetAttribute("Weapon"), equippedTool:GetAttribute("Skin")).Accent

	local rays = {}
	if def.Explosive then
		-- Cohete: viaja hasta el impacto y explota
		local direction = randomInCone(look, spread)
		local result = workspace:Raycast(origin, direction * def.Range, rayParams)
		local hitPosition = result and result.Position or origin + direction * def.Range
		table.insert(rays, { Part = result and result.Instance or nil, Position = hitPosition })
		Effects.Rocket(muzzlePos, hitPosition, def.ProjectileSpeed or 200, tracerColor, def.Explosive.Radius, def.ProjectileStyle)
	end
	for pellet = 1, def.Explosive and 0 or def.Pellets do
		local direction = randomInCone(look, spread)
		local result = workspace:Raycast(origin, direction * def.Range, rayParams)
		local hitPosition = result and result.Position or origin + direction * def.Range
		table.insert(rays, { Part = result and result.Instance or nil, Position = hitPosition })
		-- (escopetas: basta con dibujar unos pocos perdigones; el daño cuenta todos)
		if pellet <= 3 then
			Effects.Tracer(muzzlePos, hitPosition, tracerColor)
		end
		if result then
			if pellet <= 4 then
				Effects.Impact(result.Position, result.Normal, result.Instance, result.Material, def.ImpactStyle)
			end
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model and model:FindFirstChildOfClass("Humanoid") then
				ClientState.LastHitPosition = result.Position
				ClientState.LastHitTime = os.clock()
			end
		end
	end
	Remotes.Fire:FireServer(equippedTool, origin, rays)

	Effects.MuzzleFlash(muzzle)
	local eject = viewmodel and viewmodel.PrimaryPart and viewmodel.PrimaryPart:FindFirstChild("Eject")
	if not def.Explosive then
		Effects.ShellCasing(eject, camera.CFrame, def.Pellets > 1 and Color3.fromRGB(220, 50, 50) or nil)
	end
	local weaponName = equippedTool:GetAttribute("Weapon") or ""
	Sounds.PlayShot(weaponName, def)
	shakeRoll += (math.random() - 0.5) * math.rad(def.Recoil) * 0.6
	-- Mecánica del arma: cerrojo de los francotiradores y corredera de las escopetas
	if not def.Explosive and def.FireRate <= 1.6 and localAmmo > 0 then
		local shotDef = def
		task.delay(0.28, function()
			if def == shotDef then
				Sounds.PlayGun("Bolt", nil, shotDef.Pellets > 1 and 0.7 or 1.05, 0.8)
			end
		end)
	end
	-- Quedan pocas balas: un "tic" más agudo cuanto menos quede (avisa sin mirar el HUD)
	if def.MagSize >= 4 and localAmmo > 0 and localAmmo <= math.ceil(def.MagSize * 0.25) then
		Sounds.Play("LowAmmo", nil, 1 + (1 - localAmmo / (def.MagSize * 0.25)) * 0.3, 1)
	end

	-- Retroceso. La mira sube más en los primeros disparos de la ráfaga y luego se estabiliza;
	-- el lado sigue un patrón propio de cada arma (se puede aprender a controlar) con algo de azar.
	local recoil = math.rad(def.Recoil)
	local ads = 1 - aimAlpha * 0.35
	local climb = recoil * (0.75 + 0.5 * math.min(sprayCount, 6) / 6) * ads
	local seed = #weaponName * 1.7
	local drift = math.sin(sprayCount * 0.55 + seed) * 0.45 + (math.random() - 0.5) * 0.25
	local yaw = recoil * drift * (sprayCount > 3 and 1 or 0.4) * ads
	camKick += climb
	camYaw += yaw
	debtPitch += climb
	debtYaw += yaw
	-- Golpe del arma en la mano (muelles): hacia atrás, hacia arriba y un poco de lado
	local hip = 1 - aimAlpha * 0.5
	kickVel += (1.6 + def.Recoil * 0.55) * hip
	rotVel += recoil * 10 * hip
	sideVel += (math.random() - 0.5) * recoil * 9
	-- Las armas potentes sacuden la cámara y abren un poco el campo de visión
	if def.Recoil >= 3 then
		ClientState.Shake = math.max(ClientState.Shake or 0, def.Recoil * 0.05)
		ClientState.FovKick = (ClientState.FovKick or 0) + def.Recoil * 0.22
	end
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
	-- El arma cuerpo a cuerpo que lleves (cuchillo, martillo o katana) está en la ranura 3
	local meleeTool = getTools()[3]
	local knife = meleeTool and Weapons.Get(meleeTool:GetAttribute("Weapon"))
	if not knife or knife.Type ~= "Melee" then
		return
	end
	local now = os.clock()
	if now - meleeTime < knife.Cooldown or ClientState.IsBlocked() or ClientState.Frozen() or not humanoid or humanoid.Health <= 0 then
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

	local firing = os.clock() - lastShot < 0.15
	ClientState.Bloom = math.max(0, ClientState.Bloom - dt * (firing and 5 or 14))
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
	if canAim then
		inspectTime = -10
	end
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
	-- Recuperación: al dejar de disparar, la mira baja sola parte de lo que subió. Si mientras
	-- disparabas ya tirabas del ratón hacia abajo, eso cuenta y no baja de más.
	local mouseDown = UserInputService:GetMouseDelta().Y
	if mouseDown > 0 and debtPitch > 0 then
		debtPitch = math.max(0, debtPitch - mouseDown * 0.0025)
	end
	if os.clock() - lastShot > 0.12 and math.abs(camKick) < 0.002 and (debtPitch > 0.0005 or math.abs(debtYaw) > 0.0005) then
		local r = math.min(1, dt * 7)
		local backPitch, backYaw = debtPitch * r, debtYaw * r
		debtPitch -= backPitch
		debtYaw -= backYaw
		camera.CFrame = camera.CFrame * CFrame.Angles(-backPitch * RECOVER, -backYaw * RECOVER, 0)
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
	-- Temblor por explosiones cercanas (se apaga solo en ~0,6 s)
	local shake = ClientState.Shake or 0
	if shake > 0.01 then
		local t = os.clock() * 40
		camera.CFrame = camera.CFrame
			* CFrame.Angles(math.noise(t, 1) * shake * 0.05, math.noise(t, 2) * shake * 0.05, math.noise(t, 3) * shake * 0.03)
		ClientState.Shake = math.max(0, shake - dt * 1.6)
	end
	-- Balanceo de cabeza al andar y correr, y golpe al aterrizar desde alto. Solo se mueve la
	-- posición y el alabeo (no hacia dónde se mira), así que no desvía la puntería ni se acumula.
	local moveConfig = GameConfig.Movement
	if rootPart and humanoid and moveConfig then
		local v = rootPart.AssemblyLinearVelocity
		local flatSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
		local onGround = humanoid.FloorMaterial ~= Enum.Material.Air and not ClientState.Sliding
		if onGround then
			headBobTime += dt * math.min(flatSpeed, 32) * 0.42
		end
		headBobAmount = lerp(headBobAmount, onGround and math.clamp(flatSpeed / 18, 0, 1.6) or 0, math.min(1, dt * 8))
		local amount = headBobAmount * (moveConfig.CameraBob or 1) * (1 - aimAlpha * 0.85)
		if amount > 0.001 and not ClientState.InMainMenu then
			local y = -math.abs(math.sin(headBobTime)) * 0.08 * amount
			local roll = math.sin(headBobTime) * math.rad(0.4) * amount
			camera.CFrame = camera.CFrame * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, roll)
		end
	end
	local land = ClientState.LandKick or 0
	if land > 0.01 then
		camera.CFrame = camera.CFrame * CFrame.new(0, -0.55 * land, 0) * CFrame.Angles(0, 0, math.rad(1.2) * land)
		ClientState.LandKick = land * math.max(0, 1 - dt * 7)
	else
		ClientState.LandKick = 0
	end

	-- Latido de las skins míticas
	if #pulseParts > 0 and pulseSkin then
		local t = (math.sin(os.clock() * 3) + 1) / 2
		local color = pulseSkin.Accent:Lerp(pulseSkin.Accent2 or Color3.new(1, 1, 1), t)
		for _, part in pulseParts do
			part.Color = color
		end
		local glow = viewmodel and viewmodel.PrimaryPart and viewmodel.PrimaryPart:FindFirstChild("NeonGlow")
		if glow and glow:IsA("PointLight") then
			glow.Color = color
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
	local kick = ClientState.FovKick or 0
	if kick > 0.01 then
		ClientState.FovKick = kick * math.max(0, 1 - dt * 5)
	else
		ClientState.FovKick = 0
	end
	camera.FieldOfView = targetFov + sprintAlpha * 6 + kick
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
	-- (muelles amortiguados: el arma va hacia atrás, se pasa un poquito al volver y se asienta)
	local sdt = math.min(dt, 1 / 30)
	kickVel += (-260 * recoilKick - 24 * kickVel) * sdt
	recoilKick += kickVel * sdt
	rotVel += (-220 * recoilRot - 20 * rotVel) * sdt
	recoilRot += rotVel * sdt
	sideVel += (-180 * recoilSide - 18 * sideVel) * sdt
	recoilSide += sideVel * sdt
	local recoilCF = CFrame.new(recoilSide * 0.4, 0, recoilKick) * CFrame.Angles(recoilRot, recoilSide * 0.6, recoilSide * 1.5)

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

	-- Inspeccionar: sube el arma, la gira para ver un costado y luego el otro, y vuelve
	local inspectCF = CFrame.new()
	local it = (now - inspectTime) / INSPECT_TIME
	if it < 1 then
		local function smooth(x)
			x = math.clamp(x, 0, 1)
			return x * x * (3 - 2 * x)
		end
		local envelope = smooth(math.min(it / 0.18, (1 - it) / 0.18))
		local turn = smooth((it - 0.18) / 0.64)
		local yaw = math.rad(70 + (-45 - 70) * turn)
		local roll = math.rad(-25 + 35 * turn)
		inspectCF = CFrame.new(-0.35 * envelope, 0.18 * envelope, 0.25 * envelope)
			* CFrame.Angles(math.rad(12) * envelope, yaw * envelope, roll * envelope)
	end

	-- Mira telescópica: ocultar el arma
	-- (y también en la pantalla de inicio, donde la cámara está lejos)
	local hide = (def.Scope == true and aimAlpha > 0.85) or ClientState.InMainMenu or ClientState.Emoting
	setViewmodelHidden(hide)
	if not hide then -- oculta no hace falta moverla cada fotograma
		viewmodel:PivotTo(camera.CFrame * bob * sway * base * sprintCF * reloadCF * equipCF * meleeCF * inspectCF * recoilCF)
		swingCharm(dt)
	end
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
	TouchLayout.Set("Fire", UDim2.new(1, -110, 1, -160))

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
	TouchLayout.Set("Aim", UDim2.new(1, -190, 1, -110))

	ContextActionService:BindAction("Reload", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			requestReload()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle("Reload", "R")
	TouchLayout.Set("Reload", UDim2.new(1, -200, 1, -190))

	ContextActionService:BindAction("Melee", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			melee()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("Melee", "F")
	TouchLayout.Set("Melee", UDim2.new(1, -120, 1, -240))

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

	-- Cambiar de arma: tecla Q (siguiente) y botón táctil en móvil (no hay barra de inventario)
	ContextActionService:BindAction("Inspect", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() and not ClientState.VotePanelVisible and def and not reloadStart and not ClientState.Aiming then
			if os.clock() - inspectTime > INSPECT_TIME then
				inspectTime = os.clock()
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.V, Enum.KeyCode.DPadUp)

	ContextActionService:BindAction("SwapWeapon", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			cycleSlot(1)
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.Q)
	ContextActionService:SetTitle("SwapWeapon", "⇄")
	TouchLayout.Set("SwapWeapon", UDim2.new(1, -280, 1, -100))

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

local characterConnections = {}

local function onCharacter(newCharacter)
	-- Las conexiones del personaje anterior se cortan (si no, el personaje viejo queda en memoria)
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	onUnequipped()
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	rootPart = newCharacter:WaitForChild("HumanoidRootPart")
	aimHeld = false
	camKick, camYaw = 0, 0
	debtPitch, debtYaw = 0, 0
	recoilKick, recoilRot, recoilSide = 0, 0, 0
	kickVel, rotVel, sideVel = 0, 0, 0
	sprayCount = 0
	updateRayFilter()

	table.insert(characterConnections, newCharacter.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("Weapon") then
			onEquipped(child)
		end
	end))
	table.insert(characterConnections, newCharacter.ChildRemoved:Connect(function(child)
		if child == equippedTool then
			onUnequipped()
		end
	end))
	local existing = newCharacter:FindFirstChildOfClass("Tool")
	if existing and existing:GetAttribute("Weapon") then
		onEquipped(existing)
	end

	table.insert(characterConnections, humanoid.Died:Connect(function()
		onUnequipped()
		triggerHeld = false
	end))
end

-- Efectos de los disparos de otros jugadores (y bots). Para no dar tirones en móviles: de lejos o
-- con calidad Baja solo la trazadora, y como mucho un sonido por arma cada 0,1 s.
local FAR_SHOT = 120
local lastRemoteSound = setmetatable({}, { __mode = "k" }) -- [tool] = os.clock()
local lastWhiz = 0

local function isTeammateTool(tool)
	local owner = tool.Parent and Players:GetPlayerFromCharacter(tool.Parent)
	if owner == player then
		return true
	end
	-- (los bots guardan el nombre de su equipo en el atributo "Team" del modelo)
	local team = tool.Parent and tool.Parent:GetAttribute("Team")
	if owner then
		team = owner.Team and owner.Team.Name
	end
	return team ~= nil and team ~= "" and player.Team ~= nil and team == player.Team.Name
end

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
	local cheap = ClientState.EffectiveQuality == "Baja" or (muzzle.WorldPosition - camera.CFrame.Position).Magnitude > FAR_SHOT
	for index, position in endpoints do
		if typeof(position) == "Vector3" and index <= 3 then
			if weaponDef and weaponDef.Explosive then
				Effects.Rocket(muzzle.WorldPosition, position, weaponDef.ProjectileSpeed or 200, color, weaponDef.Explosive.Radius, weaponDef.ProjectileStyle)
			else
				Effects.Tracer(muzzle.WorldPosition, position, color)
				-- Paintball: también se ven las manchas de los disparos de los demás (si no es caro)
				if weaponDef and weaponDef.ImpactStyle and not cheap then
					local direction = position - muzzle.WorldPosition
					if direction.Magnitude > 1 then
						local hit = workspace:Raycast(position - direction.Unit * 1.5, direction.Unit * 3, rayParams)
						if hit then
							Effects.Impact(hit.Position, hit.Normal, hit.Instance, hit.Material, weaponDef.ImpactStyle)
						end
					end
				end
			end
		end
	end
	if not cheap then
		Effects.MuzzleFlash(muzzle, nil, true)
	end
	local now = os.clock()
	if now - (lastRemoteSound[tool] or 0) >= 0.1 then
		lastRemoteSound[tool] = now
		Sounds.PlayShot(tool:GetAttribute("Weapon"), weaponDef, handle, camera.CFrame.Position)
	end
	-- Bala que te pasa rozando: "fiuu" (solo si no te ha dado de lleno y no es de tu equipo)
	if weaponDef and not weaponDef.Explosive and now - lastWhiz > 0.15 and not isTeammateTool(tool) then
		local listener = camera.CFrame.Position
		local from = muzzle.WorldPosition
		for _, position in endpoints do
			if typeof(position) == "Vector3" then
				local segment = position - from
				local length = segment.Magnitude
				if length > 1 then
					local along = math.clamp((listener - from):Dot(segment / length), 0, length)
					local closest = from + segment / length * along
					local gap = (listener - closest).Magnitude
					-- (lejos del final: si acaba justo en ti, es que te ha dado)
					if gap < 7 and gap > 1.5 and length - along > 4 then
						lastWhiz = now
						local sound = Sounds.Play("Whiz", nil, 0.9 + math.random() * 0.25, 1.2 - gap / 7)
						if sound then
							sound.TimePosition = 0.05
						end
						break
					end
				end
			end
		end
	end
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
