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
local AimAssist = require(script.Parent.AimAssist)
local CombatFX = require(script.Parent.CombatFX)
local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)
local Effects = require(script.Parent.Effects)
local Outfits = require(Shared.Outfits)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WeaponController = {}

-- Teléfono (UI.IsPhone): el arma de cadera se aparta un poco (se decide al arrancar)
local PHONE_HIP = CFrame.new(0.1, -0.12, -0.18) -- (más abajo, a la derecha y más lejos: se ve más pequeña)
local phoneScreen = false

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
local smokeShots = 0 -- disparos de la ráfaga que calientan el cañón (humo al soltar; Effects.BarrelSmoke)
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
-- Animación del arma: inercia con muelle, arma contra la pared, saltos y golpes alternos
local swayVelX, swayVelY = 0, 0
local pendingShot, pendingBurst = nil, false -- disparo que espera a que el arma salga del sprint
local wallAlpha = 0
local airOffset = 0
local meleeSide = 1
local meleeDuration = 0.35
local reloadWasEmpty = false
local reloadDuration = 2 -- lo que dura la recarga en curso (táctica: más corta; Weapons.ReloadDuration)
local wallCheckTime = 0

local collectMovingParts -- (más abajo)
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

local function addArm(model, handPos, shoulderCam, weaponDef, side)
	local shoulder = weaponDef.ViewOffset:PointToObjectSpace(shoulderCam)
	local length = (shoulder - handPos).Magnitude
	local sleeveColor = player.Team and player.TeamColor.Color or Color3.fromRGB(60, 60, 70)
	-- Con traje de operador, los brazos llevan sus colores
	local outfitColors = Outfits.ArmColors(ClientState.Data and ClientState.Data.EquippedOutfit)
	if outfitColors then
		sleeveColor = outfitColors.Sleeve
	end
	-- Mapas realistas sin traje: uniforme de manga larga (verde oliva con un toque del color del
	-- equipo) hasta la muñeca y guantes tácticos, como en los shooters militares
	local map = workspace:FindFirstChild("Map")
	local uniform = not outfitColors and map ~= nil and map:GetAttribute("Realistic") == true
	if uniform then
		sleeveColor = Color3.fromRGB(92, 96, 72):Lerp(player.Team and player.TeamColor.Color or Color3.fromRGB(92, 96, 72), 0.12)
		outfitColors = { Sleeve = sleeveColor, Glove = Color3.fromRGB(38, 38, 36), Cuff = sleeveColor:Lerp(Color3.new(0, 0, 0), 0.3) }
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
	arm:SetAttribute("Side", side)
	arm.Parent = model

	local sleeve = Instance.new("Part")
	sleeve.Name = "Sleeve"
	local sleeveLength = uniform and 0.86 or 0.55 -- (el uniforme cubre también el antebrazo)
	sleeve.Size = Vector3.new(0.46, 0.46, length * sleeveLength)
	sleeve.CFrame = CFrame.lookAt(shoulder:Lerp(handPos, sleeveLength / 2), handPos)
	sleeve.Color = sleeveColor
	sleeve.Material = Enum.Material.Fabric
	sleeve:SetAttribute("Side", side)
	sleeve.Parent = model

	local glove = Instance.new("Part")
	glove.Name = "Glove"
	glove.Size = Vector3.new(0.48, 0.48, 0.55)
	glove.CFrame = CFrame.lookAt(handPos + (shoulder - handPos).Unit * 0.15, handPos)
	glove.Color = outfitColors and outfitColors.Glove or Color3.fromRGB(25, 25, 28)
	glove.Material = Enum.Material.Fabric
	glove:SetAttribute("Side", side)
	glove.Parent = model

	-- Puño blanco de la manga
	local cuff = Instance.new("Part")
	cuff.Name = "Cuff"
	cuff.Size = Vector3.new(0.5, 0.5, 0.12)
	cuff.CFrame = CFrame.lookAt(shoulder:Lerp(handPos, uniform and 0.86 or 0.545), handPos)
	cuff.Color = outfitColors and outfitColors.Cuff or Color3.fromRGB(245, 245, 250)
	cuff.Material = (outfitColors and not zombieSkin and not uniform) and Enum.Material.Neon or Enum.Material.Fabric
	cuff:SetAttribute("Side", side)
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

-- Piezas que se mueven por separado en primera persona: cargador, corredera, bomba, cerrojo y
-- los dos brazos. Se guarda dónde está cada una respecto al Handle para moverla desde ahí.
local moving = { Mag = {}, Slide = {}, Pump = {}, Bolt = {}, Left = {}, Right = {} }
local movingDirty = {}
local magCenter, boltCenter = nil, nil

local function movingGroup(part)
	local side = part:GetAttribute("Side")
	if side then
		return side
	end
	local name = part.Name
	if name == "MagTube" or string.sub(name, 1, 10) == "BoltShroud" or string.sub(name, 1, 11) == "BoltRelease" then
		return nil
	end
	local function starts(prefix)
		return string.sub(name, 1, #prefix) == prefix
	end
	if starts("Mag") or starts("Drum") or starts("AmmoBox") or starts("BeltRound") then
		return "Mag"
	elseif starts("Slide") then
		return "Slide"
	elseif starts("Pump") and not starts("Pumpkin") then -- (la Calabazooka no tiene bomba)
		return "Pump"
	elseif starts("BoltHandle") or starts("BoltKnob") then
		return "Bolt"
	end
	return nil
end

local function centerOf(list)
	if #list == 0 then
		return nil
	end
	local sum = Vector3.zero
	for _, entry in list do
		sum += entry.Offset.Position
	end
	return sum / #list
end

collectMovingParts = function(model, weaponDef)
	for key, list in moving do
		table.clear(list)
		movingDirty[key] = false
	end
	local handle = model.PrimaryPart
	if not handle or weaponDef.Type ~= "Gun" then
		-- (las armas cuerpo a cuerpo solo mueven los brazos con el arma entera)
		return
	end
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= handle then
			local group = movingGroup(part)
			if group then
				table.insert(moving[group], { Part = part, Offset = handle.CFrame:ToObjectSpace(part.CFrame) })
			end
		end
	end
	magCenter = centerOf(moving.Mag)
	boltCenter = centerOf(moving.Bolt)
end

-- Coloca un grupo desplazado (offset en el espacio del arma). Sin offset, solo si hace falta
-- devolverlo a su sitio (el arma entera ya se movió con PivotTo).
local function placeGroup(key, handleCF, offset, fade)
	local list = moving[key]
	if #list == 0 then
		return
	end
	if not offset and not movingDirty[key] then
		return
	end
	movingDirty[key] = offset ~= nil
	local cf = offset or CFrame.identity
	for _, entry in list do
		entry.Part.CFrame = handleCF * cf * entry.Offset
		if key == "Mag" then
			entry.Part.LocalTransparencyModifier = offset and fade or 0
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
		addArm(model, weaponDef.RightHand, RIGHT_SHOULDER, weaponDef, "Right")
	end
	if weaponDef.LeftHand then
		addArm(model, weaponDef.LeftHand, LEFT_SHOULDER, weaponDef, "Left")
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
	collectMovingParts(model, weaponDef)
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
	smokeShots = 0
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
	swayX, swayY, swayVelX, swayVelY = 0, 0, 0, 0
	pendingShot, pendingBurst = nil, false
	wallAlpha, airOffset = 0, 0
	updateRayFilter()
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
	elseif ClientState.Crouching then
		spread *= 0.75 -- agachado se apunta mejor
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
	local wasEmpty = localAmmo <= 0
	local token, reloadTime = reloadStart, Weapons.ReloadDuration(def, wasEmpty)
	reloadWasEmpty = wasEmpty
	reloadDuration = reloadTime
	local shotgun = def.Pellets > 1 and #moving.Mag == 0 -- (la escopeta de tambor recarga con cargador)
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
		kickVel += 0.5 -- el gatillo en vacío: un tirón seco
		Sounds.Play("Empty")
		requestReload()
		return
	end
	-- Salida del sprint: el arma tiene que subir antes de disparar (~0,1 s). El disparo no se pierde:
	-- queda pendiente y sale en cuanto el arma está arriba
	if sprintAlpha > 0.35 then
		ClientState.LastShotTime = now -- (deja de correr)
		ClientState.Sprinting = false
		pendingShot = pendingShot or now
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
				ClientState.LastHitModel = model
			end
		end
	end
	Remotes.Fire:FireServer(equippedTool, origin, rays)

	Effects.MuzzleFlash(muzzle)
	if not def.Explosive then
		smokeShots += 1
		Effects.StopBarrelSmoke(muzzle)
	end
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
	if sprintAlpha > 0.35 then -- (salida del sprint: la ráfaga sale cuando el arma esté arriba)
		ClientState.LastShotTime = os.clock()
		ClientState.Sprinting = false
		pendingShot, pendingBurst = pendingShot or os.clock(), true
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
	meleeSide = -meleeSide -- golpes alternos: uno de derecha a izquierda y el siguiente al revés
	meleeDuration = meleeWithKnife and math.clamp(knife.Cooldown * 0.75, 0.32, 0.6) or 0.38
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

-- ¿Hay un enemigo vivo justo en el centro de la mira (al alcance del arma)?
local function enemyInSights()
	local hit = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * math.min(def.Range or 300, 400), rayParams)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or model == character then
		return false
	end
	-- (con la protección de aparición no se le puede herir: no vaciar el cargador en el escudo)
	if model:FindFirstChildOfClass("ForceField") then
		return false
	end
	if not ReplicatedStorage:GetAttribute("TeamMode") then
		return true
	end
	local owner = Players:GetPlayerFromCharacter(model)
	local team = owner and owner.Team and owner.Team.Name or model:GetAttribute("Team")
	return team ~= nil and team ~= "" and player.Team ~= nil and team ~= player.Team.Name
end

local function renderStep(dt)
	if not character or not humanoid then
		return
	end

	-- Disparo automático
	if triggerHeld and def and def.Type == "Gun" and def.Automatic then
		fire()
	end
	-- Disparo automático (modo sencillo de los shooters de móvil): con la mira sobre un enemigo,
	-- el arma dispara sola. Ajustes: 2 = solo en pantallas táctiles (por defecto), 1 = siempre, 0 = no
	local autoMode = math.floor(((ClientState.Settings or GameConfig.DefaultSettings).AutoFire or 2) + 0.5)
	-- (el rayo solo cuando el arma ya puede disparar: no cada fotograma de la cadencia)
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if autoMode ~= 0 and (autoMode == 1 or touchOnly) and def and def.Type == "Gun"
		and not reloadStart and not bursting and os.clock() - lastShot >= 1 / def.FireRate
		and not ClientState.IsBlocked() and not ClientState.InMainMenu and enemyInSights() then
		if def.Burst then
			startBurst()
		else
			fire()
		end
	end
	-- Disparo pendiente de la salida del sprint (si se tarda demasiado, se descarta)
	if pendingShot then
		if os.clock() - pendingShot > 0.5 or not def or def.Type ~= "Gun" then
			pendingShot, pendingBurst = nil, false
		elseif sprintAlpha <= 0.35 then
			local burst = pendingBurst
			pendingShot, pendingBurst = nil, false
			if burst then
				startBurst()
			elseif not (triggerHeld and def.Automatic) then -- (el automático ya dispara solo)
				fire()
			end
		end
	end

	local firing = os.clock() - lastShot < 0.15
	ClientState.Bloom = math.max(0, ClientState.Bloom - dt * (firing and 5 or 14))
	ClientState.Spread = currentSpread()

	-- Recarga: tiempo límite por si el servidor la rechazó
	if reloadStart and def and os.clock() - reloadStart > reloadDuration + 1 then
		reloadStart = nil
	end
	ClientState.Reloading = reloadStart ~= nil
	ClientState.ReloadProgress = (reloadStart and def) and math.clamp((os.clock() - reloadStart) / reloadDuration, 0, 1)
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
	-- Asistencia de apuntado (dedo o mando): la mira se va hacia el enemigo cercano
	AimAssist.Update(dt)
	-- Tras una ráfaga larga (o varios tiros de escopeta/francotirador), sale humo del cañón
	if smokeShots > 0 and os.clock() - lastShot > 0.3 then
		local heavy = def ~= nil and (def.Pellets > 1 or def.Damage >= 60)
		local shots = heavy and smokeShots * 4 or smokeShots
		if shots >= 7 and viewmodel and viewmodel.PrimaryPart then
			Effects.BarrelSmoke(viewmodel.PrimaryPart:FindFirstChild("Muzzle"), math.min(1, shots / 24))
		end
		smokeShots = 0
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
	local function smooth(x)
		x = math.clamp(x, 0, 1)
		return x * x * (3 - 2 * x)
	end
	local function window(x, a, b) -- 0 -> 1 entre a y b
		return smooth((x - a) / (b - a))
	end
	local function pulse(x, center, width) -- 0 -> 1 -> 0 alrededor de center
		return smooth(1 - math.abs(x - center) / width)
	end

	-- Balanceo al caminar (al correr, más amplio y con giro: el "ocho" de los shooters)
	local speed, verticalSpeed = 0, 0
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity
		speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		verticalSpeed = velocity.Y
	end
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded and not ClientState.Sliding then
		bobTime += dt * math.min(speed, 30) * 0.45
	end
	local bobAmount = math.clamp(speed / 18, 0, 1.5) * (1 - aimAlpha * 0.9)
	if not grounded or ClientState.Sliding then
		bobAmount = 0
	end
	local s = sprintAlpha
	local bob = CFrame.new(
		math.cos(bobTime) * (0.05 + 0.05 * s) * bobAmount,
		-math.abs(math.sin(bobTime)) * (0.06 + 0.04 * s) * bobAmount,
		0
	) * CFrame.Angles(0, 0, math.cos(bobTime) * math.rad(3.5) * s * bobAmount)

	-- Respiración: el arma nunca está del todo quieta (apuntando, casi nada)
	local breathScale = (1 - aimAlpha * 0.8) * (1 - math.min(1, bobAmount))
	local breath = CFrame.new(math.sin(now * 0.8) * 0.01 * breathScale, math.sin(now * 1.6) * 0.014 * breathScale, 0)
		* CFrame.Angles(math.sin(now * 1.6 + 0.6) * math.rad(0.5) * breathScale, 0, 0)

	-- Inercia al mover el ratón: muelle (se retrasa, se pasa un poco y vuelve). Las armas
	-- pesadas (las que te hacen ir más lento) van más perezosas.
	local delta = UserInputService:GetMouseDelta()
	local weight = math.clamp(def.WalkSpeedMultiplier or 1, 0.8, 1.15)
	local stiffness, damping = 160 * weight * weight, 16 * weight
	local sdt = math.min(dt, 1 / 30)
	local targetX = math.clamp(-delta.X * 0.004, -0.12, 0.12)
	local targetY = math.clamp(-delta.Y * 0.004, -0.12, 0.12)
	swayVelX += ((targetX - swayX) * stiffness - swayVelX * damping) * sdt
	swayVelY += ((targetY - swayY) * stiffness - swayVelY * damping) * sdt
	swayX += swayVelX * sdt
	swayY += swayVelY * sdt
	local swayScale = 1 - aimAlpha * 0.75
	local sway = CFrame.Angles(swayY * swayScale, swayX * swayScale, swayX * 0.6 * swayScale)

	-- Moverse: al ir de lado el arma se inclina; al saltar se queda atrás y al caer se hunde
	local strafeTilt = CFrame.Angles(0, 0, strafeRoll * 2.5 * (1 - aimAlpha * 0.8))
	airOffset = lerp(airOffset, grounded and 0 or math.clamp(-verticalSpeed * 0.005, -0.12, 0.12), math.min(1, dt * 10))
	local land = ClientState.LandKick or 0
	local airCF = CFrame.new(0, airOffset - 0.2 * land, 0) * CFrame.Angles(airOffset * 0.8 - math.rad(7) * land, 0, 0)

	-- Retroceso del arma
	-- (muelles amortiguados: el arma va hacia atrás, se pasa un poquito al volver y se asienta)
	kickVel += (-260 * recoilKick - 24 * kickVel) * sdt
	recoilKick += kickVel * sdt
	rotVel += (-220 * recoilRot - 20 * rotVel) * sdt
	recoilRot += rotVel * sdt
	sideVel += (-180 * recoilSide - 18 * sideVel) * sdt
	recoilSide += sideVel * sdt
	local recoilCF = CFrame.new(recoilSide * 0.4, 0, recoilKick) * CFrame.Angles(recoilRot, recoilSide * 0.6, recoilSide * 1.5)

	-- Cadera -> mira
	-- (en el teléfono, el arma de cadera algo más abajo, a la derecha y lejos: en una pantalla
	-- pequeña tapaba media pantalla y los botones táctiles)
	local hipOffset = phoneScreen and PHONE_HIP * def.ViewOffset or def.ViewOffset
	local base = hipOffset
	if def.AimPoint then
		local a = def.AimPoint
		local aimCF = CFrame.new(-a.X, -a.Y, -def.AimDistance - a.Z)
		base = hipOffset:Lerp(aimCF, aimAlpha)
	end

	-- Correr
	local sprintCF = CFrame.new(-0.25 * s, -0.2 * s, 0.1 * s) * CFrame.Angles(math.rad(-12) * s, math.rad(35) * s, math.rad(18) * s)

	-- Pegado a una pared: el arma se recoge y apunta hacia arriba en vez de atravesarla
	if now - wallCheckTime > 1 then
		wallCheckTime = now
		updateRayFilter()
	end
	local wallTarget = 0
	if def.Type == "Gun" and not ClientState.InMainMenu then
		local hit = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 3.4, rayParams)
		local part = hit and hit.Instance
		local solid = part and part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.9
		if solid and not (part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")) then
			wallTarget = math.clamp(1 - (hit.Distance - 1.1) / 2.3, 0, 1) * (1 - aimAlpha * 0.6)
		end
	end
	wallAlpha = lerp(wallAlpha, wallTarget, math.min(1, dt * 10))
	local w = wallAlpha
	local wallCF = CFrame.new(-0.1 * w, -0.1 * w, 0.55 * w) * CFrame.Angles(math.rad(32) * w, math.rad(-12) * w, math.rad(-14) * w)

	-- Recarga. Con cargador: lo sueltas, la mano trae otro, lo encaja (golpe) y, si estaba
	-- vacía, se monta. Escopetas: cartucho a cartucho y bombeo al final. Va al ritmo de los sonidos.
	local reloadCF = CFrame.new()
	local magOffset, magFade, leftOffset, rightOffset = nil, 0, nil, nil
	local slideBack, pumpBack, boltBack = 0, 0, 0
	local p = reloadStart and ClientState.ReloadProgress or -1
	local shotgun = (def.Pellets or 1) > 1 and #moving.Mag == 0
	if p >= 0 then
		local tilt = window(p, 0, 0.12) * (1 - window(p, 0.86, 1))
		local seat = pulse(p, 0.57, 0.05)
		local function aroundMag(rotation) -- (gira sobre su propio centro)
			return CFrame.new(magCenter) * rotation * CFrame.new(-magCenter)
		end
		if magCenter and not shotgun then
			-- Cargador fuera (cae acelerando y desaparece) y el nuevo sube desde abajo
			if p < 0.3 then
				local out = window(p, 0.1, 0.26)
				magOffset = CFrame.new(0, -1.8 * out * out, 0.12 * out) * aroundMag(CFrame.Angles(math.rad(-15) * out, 0, 0))
				magFade = out
			else
				local into = window(p, 0.34, 0.55)
				magOffset = CFrame.new(0, -0.9 * (1 - into), 0.15 * (1 - into)) * aroundMag(CFrame.Angles(math.rad(-10) * (1 - into), 0, 0))
				magFade = 1 - window(p, 0.3, 0.38)
			end
			-- La mano izquierda baja a por el cargador nuevo, lo sube hasta su sitio y vuelve
			local hand = def.LeftHand or magCenter
			local grab = window(p, 0.14, 0.28) * (1 - window(p, 0.58, 0.72))
			local bottom = magCenter + Vector3.new(0, -0.35, 0.05) - hand
			local follow = p < 0.3 and Vector3.new(0, -0.9 * window(p, 0.16, 0.3), 0.15 * window(p, 0.16, 0.3))
				or magOffset.Position
			leftOffset = CFrame.new((bottom + follow) * grab)
			reloadCF = CFrame.new(-0.08 * tilt, -0.1 * tilt + 0.05 * seat, 0.05 * tilt)
				* CFrame.Angles(math.rad(8) * tilt + math.rad(4) * seat, math.rad(-10) * tilt, math.rad(28) * tilt)
		elseif shotgun then
			-- Cartuchos: la mano va de la cartuchera a la ventana de carga cuatro veces
			local active = window(p, 0.08, 0.16) * (1 - window(p, 0.78, 0.84))
			local push = 0
			for _, at in { 0.2, 0.38, 0.56, 0.74 } do
				push = math.max(push, pulse(p, at, 0.07))
			end
			local port = Vector3.new(0, -0.32, -0.15) - (def.LeftHand or Vector3.new(0, -0.3, -1))
			if active > 0.001 then
				leftOffset = CFrame.new((port + Vector3.new(0.1, -0.55, 0.25) * (1 - push)) * active)
			end
			reloadCF = CFrame.new(-0.05 * tilt, -0.08 * tilt + 0.03 * push * active, 0)
				* CFrame.Angles(math.rad(12) * tilt, math.rad(-8) * tilt, math.rad(-32) * tilt)
			pumpBack = pulse(p, 0.91, 0.06)
		else
			-- Lanzacohetes, ballesta, revólver...: la mano baja, trae la munición y la mete
			local fetch = pulse(p, 0.38, 0.22)
			leftOffset = CFrame.new(0.1 * fetch, -0.8 * fetch, 0.2 * fetch)
			reloadCF = CFrame.new(0, -0.3 * tilt + 0.04 * seat, 0) * CFrame.Angles(math.rad(-18) * tilt, 0, math.rad(30) * tilt)
		end
		-- Montar el arma (si estaba vacía): tirón seco hacia atrás
		if reloadWasEmpty and not shotgun then
			local charge = pulse(p, 0.88, 0.05)
			reloadCF *= CFrame.new(0, 0, 0.06 * charge) * CFrame.Angles(math.rad(-3) * charge, 0, math.rad(-6) * charge)
			slideBack = p < 0.86 and 1 or 0
		end
	elseif def.Type == "Gun" then
		local t = now - lastShot
		-- Corredera de las pistolas: atrás y adelante en cada disparo; abierta si te quedas sin balas
		slideBack = localAmmo <= 0 and 1 or (t < 0.03 and t / 0.03 or math.max(0, 1 - (t - 0.03) / 0.07))
		local manual = def.FireRate <= 1.6 and not def.Explosive and localAmmo > 0
		if manual and t < 0.7 then
			local cycle = (t - 0.14) / 0.36
			if cycle > 0 and cycle < 1 then
				local motion = math.sin(cycle * math.pi)
				if def.Pellets > 1 then
					-- Bombeo de la escopeta (con la mano izquierda en el guardamanos)
					pumpBack = motion
					reloadCF = CFrame.Angles(math.rad(-3) * motion, 0, math.rad(-4) * motion)
				elseif boltCenter then
					-- Cerrojo: la mano derecha va a la manilla, la abre, tira y la cierra
					boltBack = motion
					local reach = smooth(math.min(cycle / 0.2, (1 - cycle) / 0.2))
					rightOffset = CFrame.new((boltCenter - (def.RightHand or boltCenter) + Vector3.new(0.05, 0, 0.1)) * reach + Vector3.new(0, 0, 0.3 * motion))
					reloadCF = CFrame.new(0, -0.04 * reach, 0) * CFrame.Angles(0, 0, math.rad(-14) * reach)
				end
			end
		end
	end

	-- Sacar arma: sube desde abajo girando y se asienta con un pequeño rebote
	local e = math.clamp((now - equipTime) / 0.4, 0, 1)
	local c1, c3 = 1.70158, 2.70158
	local raise = 1 + c3 * (e - 1) ^ 3 + c1 * (e - 1) ^ 2 -- (sale un poco de más y vuelve)
	local down = 1 - raise
	local equipCF = CFrame.new(0.15 * down, -0.9 * down, 0.1 * down) * CFrame.Angles(math.rad(-50) * down, math.rad(15) * down, math.rad(-25) * down)

	-- Cuerpo a cuerpo: golpe rápido (el impacto es al instante) y vuelta más lenta, alternando lado
	local meleeCF = CFrame.new()
	local m = (now - meleeTime) / meleeDuration
	if m < 1 then
		local k = m < 0.3 and 1 - (1 - m / 0.3) ^ 3 or 1 - smooth((m - 0.3) / 0.7)
		local side = meleeSide
		if meleeWithKnife then
			meleeCF = CFrame.new(-0.6 * k * side, 0.15 * k, -0.6 * k)
				* CFrame.Angles(math.rad(-20) * k, math.rad(70) * k * side, math.rad(-35) * k * side)
		else
			-- Culatazo con el arma de fuego
			meleeCF = CFrame.new(-0.3 * k, 0.05 * k, -0.55 * k) * CFrame.Angles(math.rad(10) * k, math.rad(30) * k, math.rad(25) * k)
		end
	end

	-- Inspeccionar: sube el arma, la gira para ver un costado y luego el otro, y vuelve
	local inspectCF = CFrame.new()
	local it = (now - inspectTime) / INSPECT_TIME
	if it < 1 then
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
		viewmodel:PivotTo(
			camera.CFrame * bob * breath * sway * airCF * strafeTilt * base * sprintCF * wallCF * reloadCF * equipCF * meleeCF * inspectCF * recoilCF
		)
		-- Piezas móviles (después de colocar el arma entera)
		local handle = viewmodel.PrimaryPart
		if handle then
			local handleCF = handle.CFrame
			placeGroup("Mag", handleCF, magOffset, magFade)
			placeGroup("Slide", handleCF, slideBack > 0.001 and CFrame.new(0, 0, 0.16 * slideBack) or nil)
			local pumpCF = pumpBack > 0.001 and CFrame.new(0, 0, 0.36 * pumpBack) or nil
			placeGroup("Pump", handleCF, pumpCF)
			placeGroup("Bolt", handleCF, boltBack > 0.001 and CFrame.new(0, 0.04 * boltBack, 0.3 * boltBack) or nil)
			-- La mano izquierda acompaña a la bomba de la escopeta
			if pumpCF and not leftOffset then
				leftOffset = pumpCF
			end
			placeGroup("Left", handleCF, leftOffset)
			placeGroup("Right", handleCF, rightOffset)
		end
		swingCharm(dt)
	end
end

---------------------------------------------------------------------------
-- Entrada
---------------------------------------------------------------------------

local function bindActions()
	TouchLayout.BindAction("Fire", function(_, state)
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
	TouchLayout.SetTitle("Fire", "🔫") -- (iconos: con palabras no cabían en el botón)
	TouchLayout.Set("Fire", UDim2.new(1, -110, 1, -160))

	TouchLayout.BindAction("Aim", function(_, state, input)
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
	TouchLayout.SetTitle("Aim", "🎯")
	TouchLayout.Set("Aim", UDim2.new(1, -190, 1, -110))

	TouchLayout.BindAction("Reload", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			requestReload()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
	TouchLayout.SetTitle("Reload", "🔄")
	TouchLayout.Set("Reload", UDim2.new(1, -200, 1, -190))

	TouchLayout.BindAction("Melee", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			melee()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
	TouchLayout.SetTitle("Melee", "🔪")
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

	TouchLayout.BindAction("SwapWeapon", function(_, state)
		if state == Enum.UserInputState.Begin and not ClientState.IsBlocked() then
			cycleSlot(1)
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.Q)
	TouchLayout.SetTitle("SwapWeapon", "⇄")
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
						-- (supresión: un instante de desenfoque, más cuanto más cerca pasa)
						CombatFX.Suppress(1 - gap / 7)
						break
					end
				end
			end
		end
	end
end

function WeaponController.Init()
	UserInputService.MouseIconEnabled = false
	-- (teléfono o no: se mira cuando se sabe el tamaño de pantalla y al girarla)
	task.spawn(function()
		UI.WaitViewport()
		phoneScreen = UI.IsPhone()
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			phoneScreen = UI.IsPhone()
		end)
	end)
	bindActions()
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	Remotes.ShotFX.OnClientEvent:Connect(onShotFX)
	RunService:BindToRenderStep("WeaponViewmodel", Enum.RenderPriority.Camera.Value + 1, renderStep)
end

return WeaponController
