-- Postura realista: los personajes (bots y los demás jugadores) sujetan el arma de fuego con las dos
-- manos, como soldados: la culata al hombro derecho, la mano derecha en la empuñadura y la izquierda en
-- el guardamanos; con pistola, los brazos estirados y las dos manos en la empuñadura. Usa IKControl (la
-- cinemática inversa de Roblox) solo en este cliente: no cambia nada del juego, solo cómo se ven. Con
-- el arma cuerpo a cuerpo, la granada o sin arma, la animación de siempre. Tu propio personaje no (en
-- primera persona no se ve). GameConfig.TwoHandedPose = false lo quita.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Shared.Weapons)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local RiflePose = {}

-- Medidas respecto al pecho (UpperTorso: X a la derecha, Y arriba, -Z hacia delante)
RiflePose.ButtAt = Vector3.new(0.15, 0.45, -0.2) -- dónde apoya la culata (en el pecho, hacia el hombro derecho)
RiflePose.PistolGrip = Vector3.new(0.1, 0.45, -1.5) -- empuñadura de la pistola, brazos estirados
local LEFT_SHOULDER = Vector3.new(-1, 0.56, 0)
-- Lo que llega el brazo (del hombro al agarre de la mano) en un R15 normal; cada personaje usa el suyo
-- (IKControl:GetChainLength)
RiflePose.Reach = 1.85
local POLE_RIGHT = Vector3.new(2.2, -1.6, 0.6) -- el codo derecho, abajo y hacia fuera
local POLE_LEFT = Vector3.new(-1.6, -1.8, -0.4) -- el codo izquierdo, abajo

local player = Players.LocalPlayer
local rigs = {} -- [Model] = { Right, Left, Grip, Hand, Connections }
local rearCache = {} -- [arma] = z de lo más trasero del arma (la culata), en el espacio del arma

-- Lo más trasero del arma (culata), a tamaño completo
local function rearOf(def, name)
	local cached = rearCache[name]
	if cached then
		return cached
	end
	local rear = 0
	for _, spec in def.Parts or {} do
		rear = math.max(rear, spec.CFrame.Position.Z + spec.Size.Z / 2)
	end
	rearCache[name] = rear
	return rear
end

-- Hacia dónde apunta arriba/abajo (atributo AimPitch del personaje, ver AimPitch): los brazos y el
-- arma giran alrededor del pecho
local PITCH_PIVOT = Vector3.new(0, 0.5, 0)
RiflePose.MaxPitch = 0.9 -- (unos 50°: más inclinado el arma se metería en la cabeza)

-- Dónde van la mano derecha (con su giro: el arma mira hacia delante) y la izquierda, respecto al pecho.
-- Devuelve CFrame de la empuñadura y Vector3 de la mano izquierda, o nil si no es un arma de fuego
function RiflePose.Targets(weaponName, scale, pitch, reach)
	local def = weaponName and Weapons.Get(weaponName)
	if not def or def.Type ~= "Gun" or not def.RightHand then
		return nil
	end
	scale = scale or 1
	local right = def.RightHand * scale
	local left = (def.LeftHand or def.RightHand) * scale
	local handle -- dónde queda el origen del arma
	if def.Slot == 2 then
		handle = RiflePose.PistolGrip - right
	else
		-- La culata en el hombro: el arma se coloca para que su parte trasera quede ahí
		local rear = rearOf(def, weaponName) * scale
		handle = RiflePose.ButtAt - Vector3.new(0, 0, rear)
	end
	local grip = CFrame.new(handle + right)
	local hand = handle + left
	-- Si el guardamanos queda demasiado lejos para el brazo izquierdo, la mano se agarra más atrás (en el
	-- brocal del cargador, como hacen muchos tiradores)
	reach = reach or RiflePose.Reach
	local offset = hand - LEFT_SHOULDER
	if offset.Magnitude > reach then
		local side = offset.X * offset.X + offset.Y * offset.Y
		if side < reach * reach then
			hand = Vector3.new(hand.X, hand.Y, LEFT_SHOULDER.Z - math.sqrt(reach * reach - side))
		end
	end
	-- Apuntando arriba o abajo: todo gira alrededor del pecho
	pitch = math.clamp(tonumber(pitch) or 0, -RiflePose.MaxPitch, RiflePose.MaxPitch)
	if math.abs(pitch) > 0.01 then
		local turn = CFrame.new(PITCH_PIVOT) * CFrame.Angles(pitch, 0, 0) * CFrame.new(-PITCH_PIVOT)
		grip = turn * grip
		hand = turn * hand
	end
	return grip, hand
end

local function attachment(parent, name, position)
	local a = parent:FindFirstChild(name)
	if not (a and a:IsA("Attachment")) then
		a = Instance.new("Attachment")
		a.Name = name
		a.Parent = parent
	end
	if typeof(position) == "CFrame" then
		a.CFrame = position
	else
		a.Position = position
	end
	return a
end

local function heldGun(model)
	for _, child in model:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("Weapon") then
			return child
		end
	end
	return nil
end

local function update(model)
	local rig = rigs[model]
	if not rig then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local tool = heldGun(model)
	local grip, hand
	if tool and humanoid and humanoid.Health > 0 then
		grip, hand = RiflePose.Targets(tool:GetAttribute("Weapon"), tool:GetAttribute("WorldScale") or 1, model:GetAttribute("AimPitch"), rig.Reach)
	end
	if grip and hand then
		rig.Grip.CFrame = grip
		rig.Hand.Position = hand
		rig.Right.Enabled = true
		rig.Left.Enabled = true
	else
		rig.Right.Enabled = false
		rig.Left.Enabled = false
	end
end

local function release(model)
	local rig = rigs[model]
	if not rig then
		return
	end
	rigs[model] = nil
	for _, connection in rig.Connections do
		connection:Disconnect()
	end
	for _, instance in { rig.Right, rig.Left, rig.Grip, rig.Hand, rig.PoleRight, rig.PoleLeft } do
		if instance then
			instance:Destroy()
		end
	end
end

function RiflePose.Setup(model)
	if GameConfig.TwoHandedPose == false or rigs[model] or (player and model == player.Character) then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local torso = model:FindFirstChild("UpperTorso")
	local rightArm, leftArm = model:FindFirstChild("RightUpperArm"), model:FindFirstChild("LeftUpperArm")
	local rightHand, leftHand = model:FindFirstChild("RightHand"), model:FindFirstChild("LeftHand")
	-- (solo personajes R15 con sus manos)
	if not (humanoid and torso and rightArm and leftArm and rightHand and leftHand) then
		return
	end
	local rightGrip = rightHand:FindFirstChild("RightGripAttachment")
	if not rightGrip then
		return
	end
	local leftGrip = leftHand:FindFirstChild("LeftGripAttachment") or leftHand
	local grip = attachment(torso, "PoseGrip", CFrame.new())
	local hand = attachment(torso, "PoseLeftHand", Vector3.zero)
	local poleRight = attachment(torso, "PoseElbowR", POLE_RIGHT)
	local poleLeft = attachment(torso, "PoseElbowL", POLE_LEFT)

	local right = Instance.new("IKControl")
	right.Name = "PoseRightArm"
	right.Type = Enum.IKControlType.Transform
	right.ChainRoot = rightArm
	right.EndEffector = rightGrip
	right.Target = grip
	right.Pole = poleRight
	right.SmoothTime = 0.08
	right.Weight = 1
	right.Enabled = false
	right.Parent = humanoid

	local left = Instance.new("IKControl")
	left.Name = "PoseLeftArm"
	left.Type = Enum.IKControlType.Position
	left.ChainRoot = leftArm
	left.EndEffector = leftGrip
	left.Target = hand
	left.Pole = poleLeft
	left.SmoothTime = 0.08
	left.Weight = 1
	left.Enabled = false
	left.Parent = humanoid

	-- (lo que llega de verdad el brazo izquierdo de este personaje; si no se puede medir, lo normal)
	local okLength, chain = pcall(function()
		return left:GetChainLength()
	end)
	local reach = (okLength and type(chain) == "number" and chain > 1 and chain < 4) and chain * 0.97 or RiflePose.Reach
	local rig = {
		Reach = reach,
		Right = right,
		Left = left,
		Grip = grip,
		Hand = hand,
		PoleRight = poleRight,
		PoleLeft = poleLeft,
		Connections = {},
	}
	rigs[model] = rig
	table.insert(rig.Connections, model.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			update(model)
		end
	end))
	table.insert(rig.Connections, model.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			update(model)
		end
	end))
	-- (apunta arriba o abajo: el arma se inclina)
	table.insert(rig.Connections, model:GetAttributeChangedSignal("AimPitch"):Connect(function()
		update(model)
	end))
	-- Al morir, el cuerpo cae suelto (Ragdoll): nada de sujetar el arma
	table.insert(rig.Connections, humanoid.Died:Connect(function()
		release(model)
	end))
	table.insert(rig.Connections, model.AncestryChanged:Connect(function()
		if not model.Parent then
			release(model)
		end
	end))
	update(model)
end

-- (para las pruebas)
function RiflePose.Rig(model)
	return rigs[model]
end

local function watchPlayer(other)
	if other == player then
		return
	end
	other.CharacterAdded:Connect(function(character)
		-- (las piezas del personaje llegan un poco después)
		character:WaitForChild("UpperTorso", 10)
		character:WaitForChild("RightHand", 10)
		character:WaitForChild("LeftHand", 10)
		RiflePose.Setup(character)
	end)
	if other.Character then
		task.spawn(RiflePose.Setup, other.Character)
	end
end

function RiflePose.Init()
	if GameConfig.TwoHandedPose == false then
		return
	end
	for _, other in Players:GetPlayers() do
		watchPlayer(other)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	local function watchBots(folder)
		for _, model in folder:GetChildren() do
			if model:IsA("Model") then
				task.spawn(RiflePose.Setup, model)
			end
		end
		folder.ChildAdded:Connect(function(model)
			if model:IsA("Model") then
				task.wait(0.2) -- (el bot se monta entero antes de entrar en la carpeta, pero por si acaso)
				RiflePose.Setup(model)
			end
		end)
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		watchBots(bots)
	end
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Bots" and child:IsA("Folder") then
			watchBots(child)
		end
	end)
end

return RiflePose
