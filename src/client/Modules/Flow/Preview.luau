-- PreviewController: personajes 3D reales (tu avatar, tus compañeros, los rivales y los bots) dentro de
-- un ViewportFrame con WorldModel, para el lobby, la escuadra, la presentación de equipos, el
-- armamento y el operador. Nunca toca los personajes del juego: hace una copia sin scripts del
-- personaje vivo (con su traje y su arma), la congela en una pose de "arma lista" y la ilumina aparte.
-- Uso:
--   local p = Preview.new(parent, { Size = ..., Position = ... })
--   p:SetCharacter("me", player)      -- (o un modelo de bot)
--   p:SetWeapon("me", "ARX27", skin)  -- cambia el arma en las manos
--   p:SetPose("me", "Ready")          -- "Ready" (arma lista) | "Relaxed" (brazos abajo)
--   p:SetAnimation("me", "MenuIdle")  -- animación con nombre (GameConfig.UIAnimations) o su pose
--                                        equivalente si aún no hay animación subida
--   p:SetCameraPreset("Hero")         -- "Hero" | "Squad" | "Lineup" | "Bust"
--   p:SetActive(true/false)           -- anima (respiración) solo mientras se ve
--   p:Clear()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)
local WeaponModels = require(Shared.WeaponModels)
local GameConfig = require(Shared.GameConfig)

local RiflePose = require(script.Parent.Parent.RiflePose)

local Preview = {}
Preview.__index = Preview

-- Dónde se coloca cada hueco de la escena (X a la derecha, mirando a la cámara en -Z → +Z)
Preview.Slots = {
	me = CFrame.new(0, 0, 0),
	s2 = CFrame.new(-3.4, 0, 1.6) * CFrame.Angles(0, math.rad(12), 0),
	s3 = CFrame.new(3.4, 0, 1.6) * CFrame.Angles(0, math.rad(-12), 0),
	s4 = CFrame.new(-6.6, 0, 3.4) * CFrame.Angles(0, math.rad(18), 0),
	s5 = CFrame.new(6.6, 0, 3.4) * CFrame.Angles(0, math.rad(-18), 0),
}
for i = 1, 5 do
	-- (fila de presentación de equipos: cinco en línea)
	Preview.Slots["line" .. i] = CFrame.new((i - 3) * 3.3, 0, math.abs(i - 3) * 0.9)
end

local CAMERAS = {
	Hero = { Pos = Vector3.new(1.2, 3.1, -9.5), Look = Vector3.new(0.4, 2.6, 0), FOV = 34 },
	Bust = { Pos = Vector3.new(0.6, 3.9, -5.2), Look = Vector3.new(0.2, 3.4, 0), FOV = 34 },
	Squad = { Pos = Vector3.new(0, 3.6, -15.5), Look = Vector3.new(0, 2.8, 1.5), FOV = 42 },
	Lineup = { Pos = Vector3.new(0, 3.6, -19), Look = Vector3.new(0, 2.8, 1), FOV = 40 },
}

-- Quita de la copia todo lo que haga algo (scripts, sonidos, interfaces, efectos de partículas)
local function strip(model)
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("BillboardGui") or d:IsA("SurfaceGui")
			or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("ForceField")
			or d:IsA("Light") or d:IsA("IKControl") or d:IsA("Fire") or d:IsA("Smoke") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Anchored = false
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		pcall(function()
			humanoid.EvaluateStateMachine = false
		end)
	end
end

-- Copia de un personaje vivo (jugador o bot). Devuelve nil si no hay personaje
local function cloneCharacter(source)
	local character = source
	if typeof(source) == "Instance" and source:IsA("Player") then
		character = source.Character
	end
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	local archivable = character.Archivable
	character.Archivable = true
	local ok, copy = pcall(function()
		return character:Clone()
	end)
	character.Archivable = archivable
	if not ok or not copy then
		return nil
	end
	-- (solo el arma que lleva en la mano: las de la mochila no están en el personaje)
	strip(copy)
	return copy
end

-- Postura "arma lista" con cinemática inversa de dos huesos calculada aquí (sin IKControl): pone
-- los C0 de hombro, codo y muñeca para que la mano derecha quede en la empuñadura y la izquierda en
-- el guardamanos, con los mismos objetivos que usa RiflePose para los personajes del juego
local function rigAttachment(part, name)
	local a = part and part:FindFirstChild(name)
	return a and a:IsA("Attachment") and a or nil
end

local function solveArm(model, side, targetGrip, targetPos, pole)
	local torso = model:FindFirstChild("UpperTorso")
	local upper = model:FindFirstChild(side .. "UpperArm")
	local lower = model:FindFirstChild(side .. "LowerArm")
	local hand = model:FindFirstChild(side .. "Hand")
	if not (torso and upper and lower and hand) then
		return false
	end
	local shoulderJoint = upper:FindFirstChild(side .. "Shoulder")
	local elbowJoint = lower:FindFirstChild(side .. "Elbow")
	local wristJoint = hand:FindFirstChild(side .. "Wrist")
	local aShoulderU = rigAttachment(upper, side .. "ShoulderRigAttachment")
	local aElbowU = rigAttachment(upper, side .. "ElbowRigAttachment")
	local aElbowL = rigAttachment(lower, side .. "ElbowRigAttachment")
	local aWristL = rigAttachment(lower, side .. "WristRigAttachment")
	local aWristH = rigAttachment(hand, side .. "WristRigAttachment")
	local aGrip = rigAttachment(hand, side .. "GripAttachment")
	if not (shoulderJoint and elbowJoint and wristJoint and aShoulderU and aElbowU and aElbowL and aWristL and aWristH) then
		return false
	end
	-- Largos de los huesos
	local upperLen = (aElbowU.Position - aShoulderU.Position).Magnitude
	local gripOffset = aGrip and (aGrip.Position - aWristH.Position) or Vector3.new(0, -0.15, 0)
	local lowerLen = (aWristL.Position - aElbowL.Position).Magnitude + gripOffset.Magnitude * 0.9
	local shoulder = (torso.CFrame * shoulderJoint.C0).Position
	local target = targetGrip and targetGrip.Position or targetPos
	local toTarget = target - shoulder
	local dist = math.clamp(toTarget.Magnitude, 0.05, upperLen + lowerLen - 0.01)
	local dir = toTarget.Unit
	-- Codo: ley del coseno en el plano que forman hombro, objetivo y polo
	local cosA = (upperLen * upperLen + dist * dist - lowerLen * lowerLen) / (2 * upperLen * dist)
	local angle = math.acos(math.clamp(cosA, -1, 1))
	local poleDir = (pole - shoulder)
	poleDir = (poleDir - dir * poleDir:Dot(dir))
	if poleDir.Magnitude < 1e-3 then
		poleDir = Vector3.new(0, -1, 0)
	end
	poleDir = poleDir.Unit
	local elbow = shoulder + (dir * math.cos(angle) + poleDir * math.sin(angle)) * upperLen
	-- Orienta un hueso: su eje "hacia abajo" (-Y del brazo) apunta de un punto al otro
	local function boneCFrame(from, to)
		local down = (to - from).Unit
		local right = down:Cross(poleDir)
		if right.Magnitude < 1e-3 then
			right = Vector3.new(1, 0, 0)
		end
		right = right.Unit
		local back = right:Cross(-down).Unit
		return CFrame.fromMatrix(from, right, -down, back)
	end
	local upperCF = boneCFrame(shoulder, elbow) * CFrame.new(-aShoulderU.Position)
	local wristPos = target - (targetGrip and targetGrip:VectorToWorldSpace(gripOffset) or Vector3.new(0, -0.1, 0))
	local lowerCF = boneCFrame((upperCF * aElbowU.CFrame).Position, wristPos) * CFrame.new(-aElbowL.Position)
	local handCF
	if targetGrip then
		handCF = targetGrip * CFrame.new(-(aGrip and aGrip.Position or Vector3.zero))
	else
		handCF = lowerCF * aWristL.CFrame * aWristH.CFrame:Inverse()
	end
	-- C0 = Part0⁻¹ · Part1 · C1 (con Transform = identidad)
	shoulderJoint.C0 = torso.CFrame:Inverse() * upperCF * shoulderJoint.C1
	elbowJoint.C0 = upperCF:Inverse() * lowerCF * elbowJoint.C1
	wristJoint.C0 = lowerCF:Inverse() * handCF * wristJoint.C1
	return true
end

local function weaponOf(model)
	for _, child in model:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("Weapon") then
			return child
		end
	end
	return nil
end

local function poseReady(model)
	local torso = model:FindFirstChild("UpperTorso")
	local tool = weaponOf(model)
	if not (torso and tool) then
		return false
	end
	local grip, left = RiflePose.Targets(tool:GetAttribute("Weapon"), tool:GetAttribute("WorldScale") or 1, -0.18, RiflePose.Reach)
	if not grip then
		return false
	end
	local worldGrip = torso.CFrame * grip
	local worldLeft = torso.CFrame * left
	local ok1 = solveArm(model, "Right", worldGrip, nil, (torso.CFrame * CFrame.new(2.2, -1.6, 0.6)).Position)
	local ok2 = solveArm(model, "Left", nil, worldLeft, (torso.CFrame * CFrame.new(-1.6, -1.8, -0.4)).Position)
	return ok1 and ok2
end

-- Arma nueva en la mano derecha (como la Tool del juego: mismo agarre y escala)
local function giveWeapon(model, weaponName, skin)
	local old = weaponOf(model)
	if old then
		old:Destroy()
	end
	local hand = model:FindFirstChild("RightHand")
	local def = weaponName and Weapons.Get(weaponName)
	if not hand or not def or def.Type ~= "Gun" then
		return nil
	end
	local scale = GameConfig.WorldWeaponScale or 1
	local ok, weapon = pcall(WeaponModels.Build, weaponName, skin, false, nil, scale)
	if not ok or not weapon then
		return nil
	end
	local tool = Instance.new("Tool")
	tool.Name = "PreviewWeapon"
	tool:SetAttribute("Weapon", weaponName)
	tool:SetAttribute("WorldScale", scale)
	tool.Parent = model
	weapon.Parent = tool
	local handle = weapon.PrimaryPart
	if handle then
		local gripAtt = hand:FindFirstChild("RightGripAttachment")
		local grip = CFrame.new((def.RightHand or Vector3.zero) * scale)
		local weld = Instance.new("Weld")
		weld.Name = "PreviewGrip"
		weld.Part0 = hand
		weld.Part1 = handle
		weld.C0 = gripAtt and gripAtt.CFrame or CFrame.new(0, -0.15, 0)
		weld.C1 = grip
		weld.Parent = hand
	end
	return tool
end

-- Animación con nombre (GameConfig.UIAnimations) en un modelo cualquiera; nil si no hay id configurado
local function playNamed(model, name)
	local id = GameConfig.UIAnimations and GameConfig.UIAnimations[name]
	if type(id) ~= "string" or id == "" then
		return nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local ok, track = pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local loaded = animator:LoadAnimation(animation)
		loaded.Looped = name ~= "WeaponInspect"
		loaded:Play(0.2)
		return loaded
	end)
	return ok and track or nil
end

-- Piezas sueltas para otras escenas (la pantalla final usa las mismas copias, armas y poses)
Preview.Strip = strip
Preview.CloneCharacter = cloneCharacter
Preview.GiveWeapon = giveWeapon
Preview.PoseReady = poseReady
Preview.WeaponOf = weaponOf
Preview.PlayNamed = playNamed

---------------------------------------------------------------------------
-- Escena
---------------------------------------------------------------------------

function Preview.new(parent, props)
	local self = setmetatable({}, Preview)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = props and props.Name or "Preview"
	viewport.BackgroundTransparency = 1
	viewport.Size = props and props.Size or UDim2.fromScale(1, 1)
	viewport.Position = props and props.Position or UDim2.new()
	viewport.AnchorPoint = props and props.Anchor or Vector2.new()
	viewport.ZIndex = props and props.ZIndex or 1
	-- Luz de escenario: ambiente frío y luz principal cálida desde arriba a la derecha (dramática)
	viewport.Ambient = Color3.fromRGB(120, 122, 138)
	viewport.LightColor = Color3.fromRGB(255, 236, 214)
	viewport.LightDirection = Vector3.new(-0.6, -1, 0.7)
	viewport.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	self.Viewport = viewport
	self.World = world
	self.Camera = camera
	self.Rigs = {}
	self.Phase = math.random() * 10
	self:SetCameraPreset(props and props.Camera or "Hero")
	return self
end

function Preview:SetCameraPreset(name)
	local preset = CAMERAS[name] or CAMERAS.Hero
	self.CameraName = name
	self.Camera.FieldOfView = preset.FOV
	self.Camera.CFrame = CFrame.lookAt(preset.Pos, preset.Look)
end

-- Coloca un personaje en un hueco. source = Player o modelo de personaje (bot)
function Preview:SetCharacter(slot, source)
	local old = self.Rigs[slot]
	if old then
		old.Model:Destroy()
		self.Rigs[slot] = nil
	end
	if not source then
		return nil
	end
	local model = cloneCharacter(source)
	if not model then
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	model.Parent = self.World
	-- (de cara a la cámara: la cámara mira hacia +Z, así que el personaje mira hacia -Z)
	local base = (Preview.Slots[slot] or CFrame.new()) * CFrame.Angles(0, math.pi, 0)
	local hip = 3
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		hip = (tonumber(humanoid.HipHeight) or 2) + root.Size.Y / 2
	end
	root.Anchored = true
	root.CFrame = base * CFrame.new(0, hip, 0)
	local rig = { Model = model, Root = root, Base = root.CFrame, Slot = slot }
	self.Rigs[slot] = rig
	self:SetPose(slot, weaponOf(model) and "Ready" or "Relaxed")
	return model
end

function Preview:SetWeapon(slot, weaponName, skin)
	local rig = self.Rigs[slot]
	if not rig then
		return
	end
	giveWeapon(rig.Model, weaponName, skin)
	self:SetPose(slot, "Ready")
end

function Preview:SetPose(slot, pose)
	local rig = self.Rigs[slot]
	if not rig then
		return
	end
	rig.Pose = pose
	if pose == "Ready" then
		pcall(poseReady, rig.Model)
	end
end

-- Animaciones con nombre: si GameConfig.UIAnimations tiene un id para ese nombre se reproduce en
-- bucle (encima de la pose con el arma); si no, se usa la pose por código que le corresponde
Preview.AnimationPoses = {
	MenuIdle = "Ready",
	OperatorIdle = "Ready",
	WeaponInspect = "Ready",
	SquadIdle = "Ready",
	VictoryIdle = "Ready",
	SquadVictoryIdle = "Ready",
	VictoryPose = "Relaxed",
}

function Preview:SetAnimation(slot, name)
	local rig = self.Rigs[slot]
	if not rig then
		return false
	end
	rig.AnimationName = name
	if rig.Track then
		pcall(function()
			rig.Track:Stop(0.2)
		end)
		rig.Track = nil
	end
	local track = playNamed(rig.Model, name)
	if track then
		rig.Track = track
		return true
	end
	local pose = Preview.AnimationPoses[name] or "Ready"
	if pose == "Ready" and not weaponOf(rig.Model) then
		pose = "Relaxed"
	end
	self:SetPose(slot, pose)
	return false
end

-- Animación de reposo (respiración y un vaivén mínimo): solo mientras la vista está activa
function Preview:SetActive(active)
	if active and not self.Connection then
		self.Connection = RunService.RenderStepped:Connect(function()
			if not self.Viewport.Parent or not self.Viewport.Visible then
				return
			end
			local t = os.clock() + self.Phase
			for _, rig in self.Rigs do
				local k = (rig.Slot == "me") and 1 or 0.7
				rig.Root.CFrame = rig.Base * CFrame.new(0, math.sin(t * 1.6) * 0.03 * k, 0) * CFrame.Angles(0, math.sin(t * 0.5) * 0.05 * k, 0)
			end
		end)
	elseif not active and self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

-- Gira al personaje principal (arrastrar en el lobby o el armamento)
function Preview:Turn(slot, radians)
	local rig = self.Rigs[slot]
	if rig then
		rig.Base = rig.Base * CFrame.Angles(0, radians, 0)
	end
end

function Preview:Clear()
	for slot, rig in self.Rigs do
		rig.Model:Destroy()
		self.Rigs[slot] = nil
	end
end

function Preview:Destroy()
	self:SetActive(false)
	self:Clear()
	self.Viewport:Destroy()
end

return Preview
