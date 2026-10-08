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
local WeaponFeel = require(Shared.WeaponFeel)
local WeaponVisual = require(Shared.WeaponVisual)

local TouchLayout = require(script.Parent.TouchLayout)
local AimAssist = require(script.Parent.AimAssist)
local ScopeSway = require(script.Parent.ScopeSway)
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

-- Hombros, codos y largo de los brazos del viewmodel: WeaponVisual.Arms (espacio de cámara)
local ARMS = WeaponVisual.Arms

local character, humanoid, rootPart
local equippedTool, def
-- Sensación del arma equipada (WeaponFeel: perfil de su tipo + sus ajustes). Retroceso de juego:
-- WeaponFeel.Gameplay (igual para todas; es equilibrio)
local feel = WeaponFeel.Get(nil)
-- Presentación del arma equipada (WeaponVisual: poses, marcas de recarga, reposo, colgante...)
local visual = WeaponVisual.Get(nil)
local GAMEPLAY = WeaponFeel.Gameplay
local EQUIP_READY = 0.25 -- segundos tras sacar el arma hasta poder disparar (igual para todas)
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
-- (la inspección dura visual.Inspect.Duration: 2,6 s en el fusil)
local meleeWithKnife = false

local recoilKick, recoilRot = 0, 0
local camKick, camYaw = 0, 0
-- Retroceso realista: muelles para el golpe del arma (empuja, se pasa un poco y vuelve) y la
-- "deuda" de retroceso: lo que subió la mira en la ráfaga; al dejar de disparar vuelve una parte
local kickVel, rotVel = 0, 0
local recoilSide, sideVel = 0, 0
local sprayCount = 0 -- disparos seguidos de la ráfaga actual
-- Calor del cañón: cada disparo lo calienta (las escopetas y los francotiradores mucho más) y se enfría
-- solo; al dejar de disparar con el cañón caliente sale humo (Effects.BarrelSmoke)
local barrelHeat = 0
local HEAT_SMOKE = 7 -- calor mínimo para que humee
local debtPitch, debtYaw = 0, 0
-- Retroceso de cámara (visual): un muelle que sube la cámara y vuelve del todo. Se aplica como
-- diferencia respecto a lo ya aplicado (la cámara de Roblox conserva el giro), así que no deja la mira
-- desplazada, y al disparar se descuenta: las balas van donde apunta la mira, no donde mira el golpe.
local punchPitch, punchYaw, punchRoll = 0, 0, 0
local punchVelPitch, punchVelYaw, punchVelRoll = 0, 0, 0
local appliedPunchPitch, appliedPunchYaw = 0, 0
local aimToggled = false -- (móvil: apuntar es un interruptor; al cambiar de arma se suelta)
local swayX, swayY = 0, 0
local bobTime = 0
local aimAlpha, sprintAlpha = 0, 0
local viewmodelHidden = false
local pulseParts = {} -- piezas de neón que laten (skins míticas)
local pulseSkin = nil
local strafeRoll = 0
local shakeRoll = 0
-- Golpe al recibir daño: un alabeo corto de la cámara (no mueve la mira) y un tirón del arma
local flinchRoll, flinchHealth = 0, nil
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

-- Suavizado que da lo mismo a 30, 60 o 240 fps (Fase 9). `rate` es el de siempre (el que se usaba con
-- lerp(..., dt × rate)) y a 60 fps da exactamente lo mismo que antes; a otros fps, ya no cambia.
-- (Solo para lo visual: aimAlpha y sprintAlpha deciden cuándo se puede disparar y no se tocan.)
local function damp(current: number, target: number, rate: number, dt: number): number
	local perFrame = math.min(rate / 60, 0.999)
	return current + (target - current) * (1 - (1 - perFrame) ^ (dt * 60))
end
-- Lo mismo para algo que se apaga solo (multiplicar por esto cada fotograma)
local function decay(rate: number, dt: number): number
	return (1 - math.min(rate / 60, 0.999)) ^ (dt * 60)
end

-- Olvida el golpe visual de cámara pendiente (al morir o reaparecer: la cámara ya es otra)
local function resetPunch()
	punchPitch, punchYaw, punchRoll = 0, 0, 0
	punchVelPitch, punchVelYaw, punchVelRoll = 0, 0, 0
	appliedPunchPitch, appliedPunchYaw = 0, 0
end

local function weaponEvent(name, info)
	local weaponName = equippedTool and equippedTool:GetAttribute("Weapon")
	ClientState.WeaponEvent:Fire(name, weaponName, info)
end

-- Corta la inspección en curso al disparar, apuntar, recargar, correr o dar un cuchillazo (con su
-- evento InspectCancel; cambiar de arma ya la quita con Unequip)
local function cancelInspect()
	if inspectTime > 0 and os.clock() - inspectTime < visual.Inspect.Duration then
		weaponEvent("InspectCancel")
	end
	inspectTime = -10
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

-- Colores de los brazos: piel, manga, guante y puño (traje de operador, uniforme en los mapas
-- realistas o garras de zombi)
local function armColors(weaponDef)
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
	return {
		Skin = zombieSkin or skinTone(),
		Sleeve = sleeveColor,
		Glove = outfitColors and outfitColors.Glove or Color3.fromRGB(25, 25, 28),
		Cuff = outfitColors and outfitColors.Cuff or Color3.fromRGB(245, 245, 250),
		CuffNeon = outfitColors ~= nil and not zombieSkin and not uniform,
		LongSleeve = uniform, -- (el uniforme cubre también el antebrazo)
	}
end

-- Brazos procedurales: brazo (manga) y antebrazo con codo, que se recolocan cada fotograma con
-- cinemática inversa (WeaponVisual.SolveArm): el hombro queda fijo respecto a la cámara y la mano
-- sigue al arma, así que en la recarga, la inspección o el sprint el codo se dobla de verdad.
local arms = {} -- [lado] = { Upper, Forearm, Glove, Cuff, UpperLength, LowerLength, Shoulder, Pole, Hand }

local function armPart(model, name, size, color, material, side)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part:SetAttribute("ArmPiece", true)
	part:SetAttribute("Side", side)
	part.Parent = model
	return part
end

local function buildArm(model, weaponDef, side, hand: Vector3, colors)
	local shoulderCam = side == "Right" and ARMS.RightShoulder or ARMS.LeftShoulder
	-- Largo: lo que hay del hombro a la mano en la pose de cadera, algo más (codo un poco doblado)
	local reach = ((visual.ViewOffset or weaponDef.ViewOffset) * hand - shoulderCam).Magnitude * ARMS.Reach
	local upper = reach * ARMS.UpperRatio
	local lower = reach - upper
	local rig = {
		Hand = hand,
		Shoulder = shoulderCam,
		Pole = side == "Right" and ARMS.RightPole or ARMS.LeftPole,
		UpperLength = upper,
		LowerLength = lower,
		Long = colors.LongSleeve,
	}
	rig.Upper = armPart(model, "UpperArm", Vector3.new(0.46, 0.46, upper), colors.Sleeve, Enum.Material.Fabric, side)
	rig.Forearm = armPart(model, "Forearm", Vector3.new(0.4, 0.4, lower), colors.LongSleeve and colors.Sleeve or colors.Skin,
		colors.LongSleeve and Enum.Material.Fabric or Enum.Material.SmoothPlastic, side)
	rig.Glove = armPart(model, "Glove", Vector3.new(0.48, 0.48, 0.55), colors.Glove, Enum.Material.Fabric, side)
	-- Puño: al final de la manga (en el codo con manga corta; en la muñeca con uniforme)
	rig.Cuff = armPart(model, "Cuff", Vector3.new(0.5, 0.5, 0.12), colors.Cuff,
		colors.CuffNeon and Enum.Material.Neon or Enum.Material.Fabric, side)
	arms[side] = rig
end

-- Coloca un brazo: hombro (mundo), mano (mundo) y polo del codo (mundo)
local function placeArm(rig, shoulder: Vector3, hand: Vector3, pole: Vector3)
	local elbow = WeaponVisual.SolveArm(shoulder, hand, rig.UpperLength, rig.LowerLength, pole)
	rig.Upper.CFrame = CFrame.lookAt((shoulder + elbow) / 2, elbow)
	-- (si la mano no se alcanza, el antebrazo se estira lo que falte: nunca se separa del arma)
	local lower = (hand - elbow).Magnitude
	if math.abs(lower - rig.Forearm.Size.Z) > 0.01 then
		rig.Forearm.Size = Vector3.new(0.4, 0.4, math.max(0.05, lower))
	end
	if lower > 1e-4 then
		rig.Forearm.CFrame = CFrame.lookAt((elbow + hand) / 2, hand)
		local along = (hand - elbow) / lower
		rig.Glove.CFrame = CFrame.lookAt(hand - along * 0.15, hand)
		local cuffAt = rig.Long and hand - along * 0.36 or elbow + along * 0.02
		rig.Cuff.CFrame = CFrame.lookAt(cuffAt, cuffAt + along)
	end
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

-- El colgante se balancea como un péndulo: lo empujan el giro de la cámara, el paso al correr y las
-- acciones (kickCharm) y vuelve solo con un muelle exacto (igual a 30, 60 o 240 fps). Nada de física
-- de verdad: es una pieza que gira sobre su anilla.
local CHARM_STIFFNESS, CHARM_DAMPING = 60, 4

local function resetCharm()
	charmSwing, charmVelocity, lastCameraLook = 0, 0, nil
end

local function swingCharm(dt, sprint, stridePhase)
	if not charmRing or not charmRing.Parent then
		return
	end
	dt = math.clamp(dt, 1 / 240, 0.1)
	local look = camera.CFrame.LookVector
	local turnRate = 0
	if lastCameraLook then
		turnRate = lastCameraLook:Cross(look).Y / dt -- giro horizontal (radianes por segundo)
	end
	lastCameraLook = look
	charmVelocity += (turnRate * 3 + math.cos(stridePhase or 0) * (sprint or 0) * visual.Charm.Sprint * 6) * dt
	charmSwing, charmVelocity = WeaponFeel.StepSpring(charmSwing, charmVelocity, CHARM_STIFFNESS, CHARM_DAMPING, dt)
	-- (hacia dentro casi no puede: chocaría con el arma; en el tope se para)
	if charmSwing < -0.8 or charmSwing > 0.12 then
		charmSwing = math.clamp(charmSwing, -0.8, 0.12)
		charmVelocity = 0
	end
	local pivot = charmRing.CFrame * CFrame.Angles(0, 0, charmSwing)
	for _, entry in charmParts do
		entry.Part.CFrame = pivot * entry.Offset
	end
end

-- Estado de la presentación (WeaponVisual): reposo, gesto de reposo, salto, sprint y acción actual
local lastActivity = 0 -- último momento en que se hizo algo (disparar, apuntar, moverse...)
local idleVariantStart, lastIdleVariant = nil, -math.huge
local jumpY, jumpVel = 0, 0
local wasGrounded = true
local sprintShown = false -- (para los eventos SprintEnter / SprintExit)

local function resetPresentation()
	lastActivity = os.clock()
	idleVariantStart = nil
	jumpY, jumpVel = 0, 0
	sprintShown = false
end

-- Empujón al colgante (con un lado al azar): disparo, recarga, caída, inspección...
local function kickCharm(amount: number)
	if charmRing then
		charmVelocity += (math.random() < 0.5 and -1 or 1) * amount * (0.6 + math.random() * 0.4)
	end
end

-- Piezas que se mueven por separado en primera persona: cargador, corredera, bomba, cerrojo y
-- palanca de carga (WeaponVisual.PieceGroup: por el atributo "Piece" o por el nombre). Se guarda
-- dónde está cada una respecto al Handle para moverla desde ahí. Los brazos van aparte (IK).
local moving = { Mag = {}, Slide = {}, Pump = {}, Bolt = {}, Charge = {} }
local movingDirty = {}
local magCenter, boltCenter, chargeCenter = nil, nil, nil

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
			local group = WeaponVisual.PieceGroup(part.Name, part:GetAttribute("Piece"))
			if group then
				table.insert(moving[group], { Part = part, Offset = handle.CFrame:ToObjectSpace(part.CFrame) })
			end
		end
	end
	magCenter = centerOf(moving.Mag)
	boltCenter = centerOf(moving.Bolt)
	chargeCenter = centerOf(moving.Charge)
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

-- Guardar el arma: el modelo viejo baja de lado unos instantes (Unequip) mientras sube el nuevo; el
-- cambio de arma no espera. Al morir, al cambiar de personaje o con el arma oculta, se quita al momento.
local retiring = nil -- { Model, Start, Time, From (respecto a la cámara), Pose }

local function clearRetiring()
	if retiring then
		retiring.Model:Destroy()
		retiring = nil
	end
end

-- mode: nil = al momento (y también la que estaba bajando), "Animated" = baja de lado, "Replace" = se
-- cambia por otra del mismo arma (skin) sin tocar la que baja
local function destroyViewmodel(mode: string?)
	if mode ~= "Replace" then
		clearRetiring()
	end
	if viewmodel then
		if mode == "Animated" and not viewmodelHidden and viewmodel.Parent then
			retiring = {
				Model = viewmodel,
				Start = os.clock(),
				Time = visual.Unequip.Time,
				From = camera.CFrame:ToObjectSpace(viewmodel:GetPivot()),
				Pose = visual.Unequip,
			}
		else
			viewmodel:Destroy()
		end
		viewmodel = nil
	end
	table.clear(arms)
	table.clear(charmParts)
	charmRing = nil
	table.clear(pulseParts)
	pulseSkin = nil
	viewmodelHidden = false
end
function WeaponController.IsRetiring()
	return retiring ~= nil
end

-- Un fotograma de la salida del arma vieja
local function stepRetiring()
	if not retiring then
		return
	end
	local t = (os.clock() - retiring.Start) / retiring.Time
	if t >= 1 or not retiring.Model.Parent or ClientState.InMainMenu or ClientState.Emoting or ClientState.KillcamActive then
		clearRetiring()
		return
	end
	local k = t * t -- (acelera al bajar)
	retiring.Model:PivotTo(camera.CFrame * retiring.From * WeaponVisual.PoseCFrame(retiring.Pose, k))
end

-- Skin con la que se dibuja el arma en primera persona (el modo QA de Studio puede enseñar otra solo
-- en esta pantalla, sin dársela a nadie: ClientState.QASkinPreview)
local function viewSkin(tool)
	return ClientState.QASkinPreview or tool:GetAttribute("Skin")
end

-- Puntos del arma en primera persona: centro de la mira y agarre de las manos. Si el modelo trae
-- Attachments con esos nombres (un modelo externo), mandan ellos; si no, los de Weapons.
local points = { AimPoint = nil :: Vector3?, LeftHand = nil :: Vector3?, RightHand = nil :: Vector3? }
local POINT_NAMES = { "AimPoint", "LeftHand", "RightHand" } -- (una tabla con valores nil no tiene claves)

local function readPoints(model, weaponDef)
	local handle = model.PrimaryPart
	for _, key in POINT_NAMES do
		local attachment = handle and handle:FindFirstChild(key)
		points[key] = (attachment and attachment:IsA("Attachment") and model:GetAttribute("External")) and attachment.Position
			or weaponDef[key]
	end
end

local function createViewmodel(tool)
	destroyViewmodel("Replace")
	local weaponName = tool:GetAttribute("Weapon")
	local weaponDef = Weapons.Get(weaponName)
	local model = WeaponModels.Build(weaponName, viewSkin(tool), nil, tool:GetAttribute("Charm"))
	readPoints(model, weaponDef)
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
	local colors = armColors(weaponDef)
	if points.RightHand then
		buildArm(model, weaponDef, "Right", points.RightHand, colors)
	end
	if points.LeftHand then
		buildArm(model, weaponDef, "Left", points.LeftHand, colors)
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
	local glowPalette = WeaponModels.GetPalette(weaponName, viewSkin(tool))
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
	pulseSkin = WeaponModels.GetPalette(weaponName, viewSkin(tool))
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
			-- (el humo del cañón no se vuelve a encender al mostrar el arma: lo enciende el calor)
			part.Enabled = not hidden and part.Name ~= "BarrelSmoke"
		elseif part:IsA("SurfaceGui") or part:IsA("PointLight") then
			part.Enabled = not hidden
		end
	end
end

---------------------------------------------------------------------------
-- Equipar
---------------------------------------------------------------------------

-- animated = el arma baja de lado (cambio de arma); sin él, desaparece al momento (muerte, personaje nuevo)
local function onUnequipped(animated: boolean?)
	if attrConnection then
		attrConnection:Disconnect()
		attrConnection = nil
	end
	if reloadStart and equippedTool then
		weaponEvent("ReloadCancel")
	end
	if equippedTool then
		weaponEvent("Unequip", { Animated = animated == true })
		if animated and def and def.Type == "Gun" then
			-- (hueco de audio propio; sin él, en silencio como antes)
			Sounds.PlayWeapon(equippedTool:GetAttribute("Weapon"), "Unequip", nil)
		end
	end
	destroyViewmodel(animated and "Animated" or nil)
	inspectTime = -10
	equippedTool, def = nil, nil
	barrelHeat = 0
	triggerHeld = false
	reloadStart = nil
	ClientState.CurrentTool = nil
	ClientState.CurrentDef = nil
	ClientState.Reloading = false
	ClientState.WeaponChanged:Fire()
end

local function onEquipped(tool)
	if equippedTool then
		onUnequipped(true)
	end
	local weaponDef = Weapons.Get(tool:GetAttribute("Weapon"))
	if not weaponDef then
		return
	end
	equippedTool, def = tool, weaponDef
	feel = WeaponFeel.Get(tostring(tool:GetAttribute("Weapon")), weaponDef)
	visual = WeaponVisual.Get(tostring(tool:GetAttribute("Weapon")), weaponDef)
	equipTime = os.clock()
	resetPresentation()
	if aimToggled then
		aimHeld, aimToggled = false, false
	end
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
		Sounds.PlayWeapon(tool:GetAttribute("Weapon"), "Equip", "Equip", nil, weaponDef.Pellets > 1 and 0.85 or 1, 1)
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
	weaponEvent("Equip")
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
	cancelInspect()
	Remotes.Reload:FireServer(equippedTool)
	-- Secuencia de la recarga: sacar el cargador, meter el nuevo y (si estaba vacía) montar el arma.
	-- Si la recarga se corta (cambias de arma, cuchillo...) deja de sonar.
	local wasEmpty = localAmmo <= 0
	local token, reloadTime = reloadStart, Weapons.ReloadDuration(def, wasEmpty)
	reloadWasEmpty = wasEmpty
	reloadDuration = reloadTime
	local shotgun = def.Pellets > 1 and #moving.Mag == 0 -- (la escopeta de tambor recarga con cargador)
	local weaponName = equippedTool:GetAttribute("Weapon")
	-- (la munición la pone el servidor al acabar: aquí solo se presenta la recarga)
	Sounds.PlayWeapon(weaponName, "Reload", nil)
	weaponEvent("ReloadStart", { Empty = wasEmpty, Duration = reloadTime })
	-- Marcas de la recarga (WeaponVisual): en cada una, su evento, su sonido y un meneo del colgante,
	-- todo a la vez. Si la recarga se corta (cambias de arma, cuchillo...), lo que falte no suena.
	local shells = 0
	for _, marker in WeaponVisual.ReloadMarkers(visual, wasEmpty or shotgun, shotgun) do
		local name = marker.Name
		if name == "ShellIn" then
			shells += 1
		end
		local shellIndex = shells
		task.delay(reloadTime * marker.At, function()
			if reloadStart ~= token then
				return
			end
			weaponEvent(name, name == "ShellIn" and { Index = shellIndex } or nil)
			if name == "MagOut" or name == "MagIn" then
				Sounds.PlayWeapon(weaponName, name, name, nil, 1, 1)
				kickCharm(visual.Charm.Reload)
			elseif name == "ShellIn" then
				-- (cartucho: el hueco MagIn, más agudo y más flojo)
				Sounds.PlayWeapon(weaponName, "MagIn", "MagIn", nil, 1.25 + shellIndex * 0.03, 0.55, 1 + shellIndex * 0.025)
				kickCharm(visual.Charm.Reload * 0.4)
			elseif name == "Bolt" then
				Sounds.PlayWeapon(weaponName, "Bolt", "Bolt", nil, shotgun and 0.75 or 1, 1)
				kickCharm(visual.Charm.Reload * 0.7)
			end
		end)
	end
end

local function fire()
	local now = os.clock()
	if not equippedTool or not def or def.Type ~= "Gun" or ClientState.IsBlocked() or ClientState.Frozen() then
		return
	end
	if now - lastShot < 1 / def.FireRate or reloadStart or now - equipTime < EQUIP_READY then
		return
	end
	if localAmmo <= 0 then
		lastShot = now
		kickVel += 0.5 -- el gatillo en vacío: un tirón seco
		Sounds.PlayWeapon(equippedTool:GetAttribute("Weapon"), "Empty", "Empty")
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
	cancelInspect()
	ClientState.Sprinting = false

	updateRayFilter()
	local origin = camera.CFrame.Position
	-- (sin el golpe visual de cámara: la bala va adonde apunta la mira)
	local look = (camera.CFrame * CFrame.Angles(-appliedPunchPitch, -appliedPunchYaw, 0)).LookVector
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
	-- (modo QA de Studio: dibujar el disparo; nil fuera del modo QA)
	if ClientState.QAShotHook then
		pcall(ClientState.QAShotHook, origin, rays)
	end
	Remotes.Fire:FireServer(equippedTool, origin, rays)

	-- Todo a la vez en el mismo fotograma: fogonazo + luz, sonido, casquillo y retroceso (abajo)
	Effects.MuzzleFlash(muzzle, nil, false, feel.Flash)
	if not def.Explosive and feel.Heat.PerShot > 0 then
		barrelHeat = math.min(30, barrelHeat + feel.Heat.PerShot)
		Effects.StopBarrelSmoke(muzzle)
	end
	local eject = viewmodel and viewmodel.PrimaryPart and viewmodel.PrimaryPart:FindFirstChild("Eject")
	if not def.Explosive and feel.Shells.Enabled then
		-- (el casquillo sale con la velocidad del jugador: corriendo no se queda atrás ni te da en la cara)
		Effects.ShellCasing(eject, camera.CFrame, feel.Shells.Color, rootPart and rootPart.AssemblyLinearVelocity or nil)
	end
	kickCharm(visual.Charm.Fire)
	lastActivity = now
	local weaponName = equippedTool:GetAttribute("Weapon") or ""
	Sounds.PlayShot(weaponName, def)
	shakeRoll += (math.random() - 0.5) * math.rad(def.Recoil) * 0.6
	-- Mecánica del arma: cerrojo de los francotiradores y corredera de las escopetas
	if not def.Explosive and def.FireRate <= 1.6 and localAmmo > 0 then
		local shotDef = def
		task.delay(0.28, function()
			if def == shotDef then
				Sounds.PlayWeapon(weaponName, "Bolt", "Bolt", nil, shotDef.Pellets > 1 and 0.7 or 1.05, 0.8)
			end
		end)
	end
	-- Quedan pocas balas: un "tic" más agudo cuanto menos quede (avisa sin mirar el HUD)
	if def.MagSize >= 4 and localAmmo > 0 and localAmmo <= math.ceil(def.MagSize * 0.25) then
		Sounds.Play("LowAmmo", nil, 1 + (1 - localAmmo / (def.MagSize * 0.25)) * 0.3, 1)
	end

	-- 1) Retroceso de JUEGO (precisión real; igual que antes de la Fase 2). La mira sube más en los
	-- primeros disparos de la ráfaga y luego se estabiliza; el lado sigue un patrón propio de cada arma
	-- (se puede aprender a controlar) con algo de azar.
	local recoil = math.rad(def.Recoil)
	local ads = 1 - aimAlpha * GAMEPLAY.AimReduction
	local climb = recoil * (GAMEPLAY.ClimbBase + GAMEPLAY.ClimbGrowth * math.min(sprayCount, GAMEPLAY.ClimbShots) / GAMEPLAY.ClimbShots) * ads
	local seed = #weaponName * 1.7
	local drift = math.sin(sprayCount * 0.55 + seed) * GAMEPLAY.Drift + (math.random() - 0.5) * GAMEPLAY.DriftNoise
	local yaw = recoil * drift * (sprayCount > GAMEPLAY.DriftDelay and 1 or 0.4) * ads
	camKick += climb
	camYaw += yaw
	debtPitch += climb
	debtYaw += yaw
	ClientState.Bloom = math.min(ClientState.Bloom + def.Recoil * GAMEPLAY.BloomPerRecoil, GAMEPLAY.BloomMax)

	-- 2) Retroceso del ARMA en la mano (muelles): hacia atrás, hacia arriba y un poco de lado
	local view = feel.View
	local hip = 1 - aimAlpha * (1 - view.AimScale)
	kickVel += (1.6 + def.Recoil * 0.55) * hip * view.Back
	rotVel += recoil * 10 * hip * view.Rise
	sideVel += (math.random() - 0.5) * recoil * 9 * view.Side

	-- 3) Retroceso de CÁMARA (visual, se recupera del todo): golpe hacia arriba, un poco de lado y alabeo
	local cam = feel.Camera
	local camScale = (1 - aimAlpha * (1 - cam.AimScale)) * (ClientState.ReducedFX() and 0.3 or 1)
	local impulse = cam.Impulse * camScale -- (pico = los grados del perfil)
	punchVelPitch += math.rad(cam.Punch) * impulse
	punchVelYaw += (math.random() - 0.5) * 2 * math.rad(cam.PunchSide) * impulse
	punchVelRoll += (math.random() < 0.5 and -1 or 1) * math.rad(cam.PunchRoll) * impulse
	-- Las armas potentes (perfil con temblor) sacuden la cámara y abren un poco el campo de visión
	if cam.Shake > 0 then
		ClientState.Shake = math.max(ClientState.Shake or 0, def.Recoil * cam.Shake)
	end
	if cam.FovKick > 0 then
		ClientState.FovKick = (ClientState.FovKick or 0) + def.Recoil * cam.FovKick
	end
	ClientState.ShotFired:Fire()
	weaponEvent("Fire", { ADS = aimAlpha > 0.5 })

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
	cancelInspect()
	meleeWithKnife = def ~= nil and def.Type == "Melee"
	meleeSide = -meleeSide -- golpes alternos: uno de derecha a izquierda y el siguiente al revés
	meleeDuration = meleeWithKnife and math.clamp(knife.Cooldown * 0.75, 0.32, 0.6) or 0.38
	if reloadStart then
		weaponEvent("ReloadCancel")
	end
	reloadStart = nil
	lastActivity = now
	-- (hueco de audio propio del arma que golpea; si no tiene, el «fium» de siempre)
	local swingWeapon = meleeWithKnife and meleeTool:GetAttribute("Weapon") or (equippedTool and equippedTool:GetAttribute("Weapon"))
	if Sounds.WeaponSoundName(swingWeapon, "Melee", nil) then
		Sounds.PlayWeapon(swingWeapon, "Melee", nil)
	else
		Sounds.Play("MeleeSwing")
	end
	weaponEvent("Melee", { Knife = meleeWithKnife })
	-- Momento del golpe en la animación (el impacto real ya se decidió al pulsar)
	local token = meleeTime
	task.delay(meleeDuration * visual.Melee.HitAt, function()
		if meleeTime == token and equippedTool then
			weaponEvent("MeleeHit")
			kickCharm(visual.Charm.Fire * 2)
		end
	end)

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
		cancelInspect()
	end
	-- (cada tipo de arma apunta a su ritmo: subfusiles y pistolas antes, ametralladora más despacio)
	aimAlpha = lerp(aimAlpha, canAim and 1 or 0, math.min(1, dt * feel.Aim.Speed))
	if aimAlpha < 0.001 then
		aimAlpha = 0
	end
	ClientState.AimAlpha = aimAlpha
	sprintAlpha = lerp(sprintAlpha, (ClientState.Sprinting and not reloadStart) and 1 or 0, math.min(1, dt * feel.Sprint.Speed))
	-- Correr cancela la inspección
	if sprintAlpha > 0.5 then
		cancelInspect()
	end

	-- Muerto (o en la killcam) la cámara ya no es tuya: nada de retroceso, balanceo ni temblores
	if not ClientState.Dead and humanoid.Health > 0 then
		-- Retroceso de cámara
		local applyPitch = camKick * math.min(1, dt * GAMEPLAY.ApplySpeed)
		local applyYaw = camYaw * math.min(1, dt * GAMEPLAY.ApplySpeed)
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
			local r = math.min(1, dt * GAMEPLAY.RecoverSpeed)
			local backPitch, backYaw = debtPitch * r, debtYaw * r
			debtPitch -= backPitch
			debtYaw -= backYaw
			camera.CFrame = camera.CFrame * CFrame.Angles(-backPitch * GAMEPLAY.Recover, -backYaw * GAMEPLAY.Recover, 0)
		end
		-- Golpe visual de cámara (muelle). Solo se aplica lo que cambió desde el fotograma anterior: al
		-- volver el muelle a 0 la cámara queda exactamente donde estaba
		do
			local cam = feel.Camera
			local step = WeaponFeel.StepSpring
			punchPitch, punchVelPitch = step(punchPitch, punchVelPitch, cam.Stiffness, cam.Damping, dt)
			punchYaw, punchVelYaw = step(punchYaw, punchVelYaw, cam.Stiffness, cam.Damping, dt)
			punchRoll, punchVelRoll = step(punchRoll, punchVelRoll, cam.Stiffness, cam.Damping, dt)
			if math.abs(punchPitch) + math.abs(punchYaw) + math.abs(punchVelPitch) + math.abs(punchVelYaw) < 1e-5 then
				punchPitch, punchYaw, punchVelPitch, punchVelYaw = 0, 0, 0, 0
			end
			local deltaPitch, deltaYaw = punchPitch - appliedPunchPitch, punchYaw - appliedPunchYaw
			if deltaPitch ~= 0 or deltaYaw ~= 0 then
				camera.CFrame = camera.CFrame * CFrame.Angles(deltaPitch, deltaYaw, 0)
				appliedPunchPitch, appliedPunchYaw = punchPitch, punchYaw
			end
		end
		-- Asistencia de apuntado (dedo o mando): la mira se va hacia el enemigo cercano. Lo que ya
		-- corrigió hacia abajo (o al lado contrario del retroceso) no se recupera otra vez al soltar
		local _, assistPitch, assistYaw = AimAssist.Update(dt)
		if assistPitch < 0 and debtPitch > 0 then
			debtPitch = math.max(0, debtPitch + assistPitch)
		end
		if assistYaw * debtYaw < 0 then
			debtYaw = math.sign(debtYaw) * math.max(0, math.abs(debtYaw) - math.abs(assistYaw))
		end
		-- Visor de francotirador: el pulso mueve un poco la mira (Mayús: aguantar la respiración)
		local swayPitch, swayYaw = ScopeSway.Update(dt, def ~= nil and def.Scope == true and aimAlpha > 0.85)
		if swayPitch ~= 0 or swayYaw ~= 0 then
			camera.CFrame = camera.CFrame * CFrame.Angles(swayPitch, swayYaw, 0)
		end
		-- Tras una ráfaga larga (o varios tiros seguidos de escopeta/francotirador), sale humo del cañón
		if barrelHeat > 0 and os.clock() - lastShot > 0.3 then
			if barrelHeat >= HEAT_SMOKE and viewmodel and viewmodel.PrimaryPart and not viewmodelHidden then
				Effects.BarrelSmoke(viewmodel.PrimaryPart:FindFirstChild("Muzzle"), math.min(1, barrelHeat / 24))
				barrelHeat = 0
			else
				-- (se enfría poco a poco: así los tiros lentos del francotirador también calientan)
				barrelHeat = math.max(0, barrelHeat - dt * 1.5)
			end
		end

		-- Inclinación de cámara al moverse de lado y pequeña sacudida al disparar.
		-- El módulo de cámara recalcula el giro cada frame, así que esto no se acumula.
		if rootPart then
			local velocity = rootPart.AssemblyLinearVelocity
			local side = velocity:Dot(camera.CFrame.RightVector)
			strafeRoll = damp(strafeRoll, math.clamp(-side / 26, -1, 1) * math.rad(1.6), 8, dt)
		end
		shakeRoll = damp(shakeRoll, 0, 18, dt)
		-- Daño recibido: alabeo hacia un lado según cuánto (como mucho ~1,5°) y un tirón del arma
		if humanoid then
			local health = humanoid.Health
			if flinchHealth and health < flinchHealth - 1 and health > 0 then
				local hurt = math.min(flinchHealth - health, 40)
				flinchRoll += (math.random() < 0.5 and -1 or 1) * math.rad(hurt * 0.035)
				sideVel += (math.random() - 0.5) * hurt * 0.08
			end
			flinchHealth = health
		end
		flinchRoll = damp(flinchRoll, 0, 12, dt)
		-- (competitivo: apuntando tiembla mucho menos, y con «Efectos de pantalla: Reducidos» casi nada)
		local calm = (ClientState.ReducedFX() and 0.3 or 1) * (1 - 0.6 * aimAlpha)
		-- (el alabeo no se acumula: la cámara de Roblox lo recalcula cada fotograma)
		camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, (strafeRoll + shakeRoll + flinchRoll) * calm + punchRoll)
		-- Temblor por explosiones cercanas (se apaga solo en ~0,6 s)
		local shake = ClientState.Shake or 0
		if shake > 0.01 then
			local t = os.clock() * 40
			local amount = shake * calm
			camera.CFrame = camera.CFrame
				* CFrame.Angles(math.noise(t, 1) * amount * 0.05, math.noise(t, 2) * amount * 0.05, math.noise(t, 3) * amount * 0.03)
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
			headBobAmount = damp(headBobAmount, onGround and math.clamp(flatSpeed / 18, 0, 1.6) or 0, 8, dt)
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
			ClientState.LandKick = land * decay(7, dt)
		else
			ClientState.LandKick = 0
		end
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
		ClientState.FovKick = kick * decay(5, dt)
	else
		ClientState.FovKick = 0
	end
	camera.FieldOfView = targetFov + sprintAlpha * feel.Sprint.Fov + kick
	UserInputService.MouseDeltaSensitivity = (settings.Sensitivity or 1) * aimScale

	-- La salida del arma anterior (Unequip) sigue aunque ya no haya arma
	stepRetiring()
	if not viewmodel or not def then
		ClientState.WeaponAction = "None"
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
	local rad = math.rad

	---------------------------------------------------------------------
	-- 1) CUERPO: balanceo al andar, respiración, salto y caída
	---------------------------------------------------------------------
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
	local bobAmount = math.clamp(speed / 18, 0, 1.5) * (1 - aimAlpha * (1 - feel.Aim.Bob))
	if not grounded or ClientState.Sliding then
		bobAmount = 0
	end
	local s = sprintAlpha
	-- (las armas pesadas se balancean menos: llevan más peso que inercia)
	local bobScale = lerp(feel.Bob.Walk, feel.Bob.Sprint, s)
	local bob = CFrame.new(
		math.cos(bobTime) * (0.05 + 0.05 * s) * bobAmount * bobScale,
		-math.abs(math.sin(bobTime)) * (0.06 + 0.04 * s) * bobAmount * bobScale,
		0
	) * CFrame.Angles(0, 0, math.cos(bobTime) * rad(3.5) * s * bobAmount * bobScale)

	-- Respiración: el arma nunca está del todo quieta (apuntando, casi nada; la mira no se mueve de
	-- forma apreciable)
	local breathScale = (1 - aimAlpha * 0.8) * (1 - math.min(1, bobAmount)) * visual.Idle.Breath
	local breath = CFrame.new(math.sin(now * 0.8) * 0.01 * breathScale, math.sin(now * 1.6) * 0.014 * breathScale, 0)
		* CFrame.Angles(math.sin(now * 1.6 + 0.6) * rad(0.5) * breathScale, 0, 0)

	-- Salto y caída: al despegar, el arma se queda un instante atrás (muelle); en el aire se queda
	-- detrás según la velocidad; al aterrizar se hunde (más cuanto más alta la caída: LandKick)
	if wasGrounded and not grounded and verticalSpeed > 4 then
		jumpVel -= visual.Jump.Kick
		lastActivity = now
	elseif grounded and not wasGrounded then
		kickCharm(visual.Charm.Land * math.max(0.3, ClientState.LandKick or 0))
		lastActivity = now
	end
	wasGrounded = grounded
	jumpY, jumpVel = WeaponFeel.StepSpring(jumpY, jumpVel, visual.Jump.Stiffness, visual.Jump.Damping, dt)
	airOffset = damp(airOffset, grounded and 0 or math.clamp(-verticalSpeed * 0.005, -0.12, 0.12), 10, dt)
	local land = ClientState.LandKick or 0
	local airCF = CFrame.new(0, airOffset - 0.2 * land + jumpY * 0.08, 0)
		* CFrame.Angles(airOffset * 0.8 - rad(7) * land + jumpY * rad(4), 0, 0)

	-- Inercia al mover el ratón: muelle exacto (se retrasa, se pasa un poco y vuelve; igual a cualquier
	-- fps). Las armas pesadas (las que te hacen ir más lento) van más perezosas.
	local delta = UserInputService:GetMouseDelta()
	local weight = math.clamp(def.WalkSpeedMultiplier or 1, 0.8, 1.15)
	local stiffness, damping = 160 * weight * weight, 16 * weight
	local swayGain = 0.004 * feel.Sway.Amount
	local targetX = math.clamp(-delta.X * swayGain, -0.12, 0.12)
	local targetY = math.clamp(-delta.Y * swayGain, -0.12, 0.12)
	local offX, offY
	offX, swayVelX = WeaponFeel.StepSpring(swayX - targetX, swayVelX, stiffness, damping, dt)
	offY, swayVelY = WeaponFeel.StepSpring(swayY - targetY, swayVelY, stiffness, damping, dt)
	swayX, swayY = targetX + offX, targetY + offY
	local swayScale = 1 - aimAlpha * (1 - feel.Aim.Sway) -- (apuntando casi no se mueve: no estorba al apuntar)
	local sway = CFrame.Angles(swayY * swayScale, swayX * swayScale, swayX * 0.6 * swayScale)

	-- Moverse de lado: el arma se inclina
	local strafeTilt = CFrame.Angles(0, 0, strafeRoll * 2.5 * (1 - aimAlpha * 0.8))

	---------------------------------------------------------------------
	-- 2) RETROCESO DEL ARMA (muelles exactos; se aplica el último, encima de todo)
	---------------------------------------------------------------------
	local view = feel.View
	recoilKick, kickVel = WeaponFeel.StepSpring(recoilKick, kickVel, view.Stiffness, view.Damping, dt)
	recoilRot, rotVel = WeaponFeel.StepSpring(recoilRot, rotVel, view.RotStiffness, view.RotDamping, dt)
	recoilSide, sideVel = WeaponFeel.StepSpring(recoilSide, sideVel, view.SideStiffness, view.SideDamping, dt)
	local recoilCF = CFrame.new(recoilSide * 0.4, 0, recoilKick) * CFrame.Angles(recoilRot, recoilSide * 0.6, recoilSide * 1.5)

	---------------------------------------------------------------------
	-- 3) POSE BASE: cadera -> mira (ADS)
	---------------------------------------------------------------------
	-- (en el teléfono, el arma de cadera algo más abajo, a la derecha y lejos: en una pantalla
	-- pequeña tapaba media pantalla y los botones táctiles)
	-- (un modelo nuevo puede traer su propia pose: WeaponVisual.Weapons[arma].ViewOffset / AimDistance)
	local hip = visual.ViewOffset or def.ViewOffset
	local hipOffset = phoneScreen and PHONE_HIP * hip or hip
	local base = hipOffset
	if points.AimPoint then
		-- (el AimPoint del arma queda en el centro exacto de la pantalla)
		local a = points.AimPoint
		local aimCF = CFrame.new(-a.X, -a.Y, -(visual.AimDistance or def.AimDistance) - a.Z)
		base = hipOffset:Lerp(aimCF, aimAlpha)
	end

	---------------------------------------------------------------------
	-- 4) LOCOMOCIÓN: sprint y pared
	---------------------------------------------------------------------
	local sprintCF = WeaponVisual.PoseCFrame(visual.Sprint, s)
	local sprinting = s > 0.5
	if sprinting ~= sprintShown then
		sprintShown = sprinting
		weaponEvent(sprinting and "SprintEnter" or "SprintExit")
	end

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
	wallAlpha = damp(wallAlpha, wallTarget, 10, dt)
	local w = wallAlpha
	local wallCF = CFrame.new(-0.1 * w, -0.1 * w, 0.55 * w) * CFrame.Angles(rad(32) * w, rad(-12) * w, rad(-14) * w)

	---------------------------------------------------------------------
	-- 5) ACCIONES: recarga, sacar, cuchillo, inspección y gesto de reposo
	---------------------------------------------------------------------
	-- Recarga (al ritmo de las marcas de WeaponVisual y de la duración REAL de la recarga). Con
	-- cargador: lo sueltas, la mano trae otro, lo encaja (golpe) y, si estaba vacía, monta el arma
	-- (palanca de carga si el modelo la tiene). Escopetas: cartucho a cartucho y bombeo al final.
	local reloadCF = CFrame.new()
	local magOffset, magFade = nil, 0
	local leftHandOffset, rightHandOffset = nil, nil -- desplazamiento de cada mano (espacio del arma)
	local slideBack, pumpBack, boltBack, chargeBack = 0, 0, 0, 0
	local p = reloadStart and ClientState.ReloadProgress or -1
	local shotgun = (def.Pellets or 1) > 1 and #moving.Mag == 0
	if p >= 0 then
		local timeline = reloadWasEmpty and visual.Reload.Empty or visual.Reload.Tactical
		local mOut, mIn = timeline.MagOut or 0.12, timeline.MagIn or 0.55
		local mBolt = visual.Reload.Empty.Bolt or 0.85
		local tilt = window(p, 0, 0.12) * (1 - window(p, 0.86, 1))
		local seat = pulse(p, mIn + 0.02, 0.05)
		local function aroundMag(rotation) -- (gira sobre su propio centro)
			return CFrame.new(magCenter) * rotation * CFrame.new(-magCenter)
		end
		if magCenter and not shotgun then
			-- Cargador fuera (cae acelerando y desaparece) y el nuevo sube desde abajo
			if p < mOut + 0.18 then
				local out = window(p, mOut - 0.02, mOut + 0.14)
				magOffset = CFrame.new(0, -1.8 * out * out, 0.12 * out) * aroundMag(CFrame.Angles(rad(-15) * out, 0, 0))
				magFade = out
			else
				local into = window(p, mIn - 0.21, mIn)
				magOffset = CFrame.new(0, -0.9 * (1 - into), 0.15 * (1 - into)) * aroundMag(CFrame.Angles(rad(-10) * (1 - into), 0, 0))
				magFade = 1 - window(p, mOut + 0.18, mOut + 0.26)
			end
			-- La mano izquierda baja a por el cargador nuevo, lo sube hasta su sitio y vuelve
			local hand = points.LeftHand or magCenter
			local grab = window(p, mOut + 0.02, mOut + 0.16) * (1 - window(p, mIn + 0.03, mIn + 0.17))
			local bottom = magCenter + Vector3.new(0, -0.35, 0.05) - hand
			local follow = p < mOut + 0.18 and Vector3.new(0, -0.9 * window(p, mOut + 0.04, mOut + 0.18), 0.15 * window(p, mOut + 0.04, mOut + 0.18))
				or magOffset.Position
			local handMove = (bottom + follow) * grab
			-- Vacía, con palanca de carga (fusil): la mano sube a la palanca, tira de ella y vuelve
			if reloadWasEmpty and chargeCenter then
				local reach = window(p, mBolt - 0.1, mBolt - 0.03) * (1 - window(p, mBolt + 0.06, mBolt + 0.13))
				chargeBack = pulse(p, mBolt + 0.01, 0.045)
				local toCharge = chargeCenter + Vector3.new(-0.08, 0.05, 0.05) - hand
				handMove += (toCharge + Vector3.new(0, 0, visual.Reload.ChargePull * chargeBack)) * reach
			end
			leftHandOffset = CFrame.new(handMove)
			local tiltPose = visual.Reload.Tilt
			local o = tiltPose.Offset * tilt + Vector3.new(0, 0.05 * seat, 0)
			local ang = tiltPose.Angles * tilt + Vector3.new(4 * seat, 0, 0)
			reloadCF = CFrame.new(o) * CFrame.Angles(rad(ang.X), rad(ang.Y), rad(ang.Z))
		elseif shotgun then
			-- Cartuchos: la mano va de la cartuchera a la ventana de carga una vez por cartucho
			local shells = visual.Reload.Shells
			local active = window(p, shells[1] - 0.12, shells[1] - 0.04) * (1 - window(p, shells[#shells] + 0.04, shells[#shells] + 0.1))
			local push = 0
			for _, at in shells do
				push = math.max(push, pulse(p, at, 0.07))
			end
			local port = Vector3.new(0, -0.32, -0.15) - (points.LeftHand or Vector3.new(0, -0.3, -1))
			if active > 0.001 then
				leftHandOffset = CFrame.new((port + Vector3.new(0.1, -0.55, 0.25) * (1 - push)) * active)
			end
			reloadCF = CFrame.new(-0.05 * tilt, -0.08 * tilt + 0.03 * push * active, 0)
				* CFrame.Angles(rad(12) * tilt, rad(-8) * tilt, rad(-32) * tilt)
			pumpBack = pulse(p, visual.Reload.ShellPump + 0.06, 0.06)
		else
			-- Lanzacohetes, ballesta, revólver...: la mano baja, trae la munición y la mete
			local fetch = pulse(p, 0.38, 0.22)
			leftHandOffset = CFrame.new(0.1 * fetch, -0.8 * fetch, 0.2 * fetch)
			reloadCF = CFrame.new(0, -0.3 * tilt + 0.04 * seat, 0) * CFrame.Angles(rad(-18) * tilt, 0, rad(30) * tilt)
		end
		-- Montar el arma (si estaba vacía): tirón seco hacia atrás
		if reloadWasEmpty and not shotgun then
			local charge = pulse(p, mBolt + 0.03, 0.05)
			reloadCF *= CFrame.new(0, 0, 0.06 * charge) * CFrame.Angles(rad(-3) * charge, 0, rad(-6) * charge)
			slideBack = p < mBolt + 0.01 and 1 or 0
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
					reloadCF = CFrame.Angles(rad(-3) * motion, 0, rad(-4) * motion)
				elseif boltCenter then
					-- Cerrojo: la mano derecha va a la manilla, la abre, tira y la cierra
					boltBack = motion
					local reach = smooth(math.min(cycle / 0.2, (1 - cycle) / 0.2))
					rightHandOffset = CFrame.new((boltCenter - (points.RightHand or boltCenter) + Vector3.new(0.05, 0, 0.1)) * reach + Vector3.new(0, 0, 0.3 * motion))
					reloadCF = CFrame.new(0, -0.04 * reach, 0) * CFrame.Angles(0, 0, rad(-14) * reach)
				end
			end
		end
	end

	-- Sacar arma: sube desde abajo girando y se asienta con un pequeño rebote (no cambia cuándo se
	-- puede disparar: eso es EQUIP_READY)
	local e = math.clamp((now - equipTime) / feel.Equip.Time, 0, 1)
	local c1, c3 = 1.70158, 2.70158
	local raise = 1 + c3 * (e - 1) ^ 3 + c1 * (e - 1) ^ 2 -- (sale un poco de más y vuelve)
	local equipCF = WeaponVisual.PoseCFrame(visual.Equip, 1 - raise)

	-- Cuerpo a cuerpo: golpe rápido (el impacto es al instante) y vuelta más lenta, alternando lado
	local meleeCF = CFrame.new()
	local m = (now - meleeTime) / meleeDuration
	if m < 1 then
		local k = m < 0.3 and 1 - (1 - m / 0.3) ^ 3 or 1 - smooth((m - 0.3) / 0.7)
		local side = meleeSide
		if meleeWithKnife then
			meleeCF = CFrame.new(-0.6 * k * side, 0.15 * k, -0.6 * k)
				* CFrame.Angles(rad(-20) * k, rad(70) * k * side, rad(-35) * k * side)
		else
			-- Culatazo con el arma de fuego
			meleeCF = CFrame.new(-0.3 * k, 0.05 * k, -0.55 * k) * CFrame.Angles(rad(10) * k, rad(30) * k, rad(25) * k)
		end
	end

	-- Inspeccionar: claves de WeaponVisual (costado con skin y colgante, de cerca, el otro costado y remate)
	local inspectCF = CFrame.new()
	local it = (now - inspectTime) / visual.Inspect.Duration
	if it < 1 then
		local pos, ang = WeaponVisual.InspectPose(visual, it)
		inspectCF = CFrame.new(pos) * CFrame.Angles(rad(ang.X), rad(ang.Y), rad(ang.Z))
	end

	-- Acción que manda ahora (WeaponVisual.ActionPriority) y gesto de reposo: tras un rato sin hacer
	-- nada, la mano izquierda suelta el guardamanos y lo vuelve a agarrar. Cualquier acción (moverse,
	-- mirar, apuntar, disparar...) lo corta al momento.
	local busy = speed > 1.5 or delta.Magnitude > 3 or aimAlpha > 0.05 or s > 0.05 or reloadStart ~= nil
		or it < 1 or m < 1 or triggerHeld or now - lastShot < 0.3 or not grounded
	local action = WeaponVisual.ResolveAction({
		Melee = m < 1,
		Reload = reloadStart ~= nil,
		Equip = e < 1,
		Inspect = it < 1,
		Sprint = s > 0.5,
		IdleVariant = idleVariantStart ~= nil,
	})
	local idle = visual.Idle
	if busy then
		lastActivity = now
		idleVariantStart = nil
	elseif not idleVariantStart and action == "Idle" and def.Type == "Gun"
		and now - lastActivity > idle.VariantAfter and now - lastIdleVariant > idle.VariantCooldown then
		idleVariantStart, lastIdleVariant = now, now
		weaponEvent("IdleVariant")
		kickCharm(visual.Charm.Idle)
	end
	local idleCF = CFrame.new()
	local vt = idleVariantStart and (now - idleVariantStart) / idle.VariantDuration or 1
	if vt >= 1 then
		idleVariantStart = nil
	else
		local envelope = smooth(math.min(vt / 0.25, (1 - vt) / 0.3))
		local grip = pulse(vt, 0.5, 0.3)
		idleCF = CFrame.new(0, -0.03 * envelope, 0) * CFrame.Angles(rad(2) * envelope, 0, rad(idle.VariantRoll) * envelope)
		if not leftHandOffset then
			leftHandOffset = CFrame.new(idle.VariantHand * grip)
		end
	end
	ClientState.WeaponAction = (action == "Idle" and aimAlpha > 0.5) and "ADS" or action

	---------------------------------------------------------------------
	-- Colocar todo
	---------------------------------------------------------------------
	-- Mira telescópica: ocultar el arma
	-- (y también en la pantalla de inicio, donde la cámara está lejos)
	local hide = (def.Scope == true and aimAlpha > 0.85) or ClientState.InMainMenu or ClientState.Emoting or ClientState.KillcamActive
	setViewmodelHidden(hide)
	if hide then
		clearRetiring()
	else -- oculta no hace falta moverla cada fotograma
		viewmodel:PivotTo(
			camera.CFrame * bob * breath * sway * airCF * strafeTilt * base * sprintCF * wallCF * reloadCF * equipCF * meleeCF * inspectCF * idleCF * recoilCF
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
			placeGroup("Charge", handleCF, chargeBack > 0.001 and CFrame.new(0, 0, visual.Reload.ChargePull * chargeBack) or nil)
			-- La mano izquierda acompaña a la bomba de la escopeta
			if pumpCF and not leftHandOffset then
				leftHandOffset = pumpCF
			end
			-- Brazos: hombros pegados al cuerpo (cámara con su balanceo) y manos en el arma (IK)
			local body = camera.CFrame * bob * breath * airCF
			for side, rig in arms do
				local offset = side == "Left" and leftHandOffset or rightHandOffset
				local hand = (offset and handleCF * offset or handleCF) * rig.Hand
				placeArm(rig, body * rig.Shoulder, hand, body:VectorToWorldSpace(rig.Pole))
			end
		end
		swingCharm(dt, s, bobTime)
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
				aimToggled = aimHeld
			end
		elseif state == Enum.UserInputState.Begin then
			aimHeld, aimToggled = true, false
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
			if os.clock() - inspectTime > visual.Inspect.Duration then
				inspectTime = os.clock()
				lastActivity = inspectTime
				weaponEvent("Inspect")
				Sounds.PlayWeapon(equippedTool and equippedTool:GetAttribute("Weapon"), "Inspect", nil)
				-- Momento de enseñar el colgante de cerca
				local token = inspectTime
				task.delay(visual.Inspect.Duration * visual.Inspect.Moment, function()
					if inspectTime == token and equippedTool then
						weaponEvent("InspectMoment")
						kickCharm(visual.Charm.Inspect)
					end
				end)
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
	aimHeld, aimToggled = false, false
	aimAlpha, sprintAlpha = 0, 0
	resetPunch()
	camKick, camYaw = 0, 0
	debtPitch, debtYaw = 0, 0
	recoilKick, recoilRot, recoilSide = 0, 0, 0
	kickVel, rotVel, sideVel = 0, 0, 0
	flinchRoll, flinchHealth = 0, nil
	sprayCount = 0
	-- (un temblor o un golpe de aterrizaje pendientes de antes de morir no siguen en la vida nueva)
	ClientState.Shake = 0
	ClientState.LandKick = 0
	updateRayFilter()

	table.insert(characterConnections, newCharacter.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("Weapon") then
			onEquipped(child)
		end
	end))
	table.insert(characterConnections, newCharacter.ChildRemoved:Connect(function(child)
		if child == equippedTool then
			onUnequipped(true)
		end
	end))
	local existing = newCharacter:FindFirstChildOfClass("Tool")
	if existing and existing:GetAttribute("Weapon") then
		onEquipped(existing)
	end

	table.insert(characterConnections, humanoid.Died:Connect(function()
		onUnequipped()
		triggerHeld = false
		-- (lo pendiente de retroceso y temblores no se aplica a la cámara de la muerte)
		camKick, camYaw = 0, 0
		debtPitch, debtYaw = 0, 0
		resetPunch()
		ClientState.Shake = 0
		ClientState.LandKick = 0
		ClientState.FovKick = 0
		ScopeSway.Reset()
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
		Effects.MuzzleFlash(muzzle, nil, true, WeaponFeel.Get(tostring(tool:GetAttribute("Weapon")), weaponDef).Flash)
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
