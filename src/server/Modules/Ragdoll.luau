-- Muñeco de trapo al morir (como en los shooters): en vez de romperse en piezas, las articulaciones
-- pasan a ser rótulas sueltas con límites y el cuerpo cae de forma natural. Sirve para jugadores y
-- bots (R15). Prepare antes de morir (para que Roblox no rompa las uniones) y Apply al morir.
local Ragdoll = {}

-- Límites de giro de cada articulación (grados): cuello y cintura poco, hombros y caderas más
local LIMITS = {
	Neck = { 35, 20 },
	Waist = { 25, 15 },
	Root = { 20, 10 },
	LeftShoulder = { 80, 40 },
	RightShoulder = { 80, 40 },
	LeftElbow = { 70, 10 },
	RightElbow = { 70, 10 },
	LeftWrist = { 30, 10 },
	RightWrist = { 30, 10 },
	LeftHip = { 60, 25 },
	RightHip = { 60, 25 },
	LeftKnee = { 70, 8 },
	RightKnee = { 70, 8 },
	LeftAnkle = { 25, 8 },
	RightAnkle = { 25, 8 },
}

Ragdoll.SettleTime = 2.5

function Ragdoll.Prepare(humanoid)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.BreakJointsOnDeath = false
	end
end

-- push (opcional): empujón inicial del cuerpo (p. ej. alejándose de una explosión)
function Ragdoll.Apply(character, push)
	if not character or character:GetAttribute("Ragdolled") then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	-- Uniones del personaje: Motor6D en los de siempre; en los personajes con las uniones nuevas de
	-- Roblox son AnimationConstraint (entre dos Attachment), y casi todas traen ya su rótula
	-- (BallSocketConstraint) preparada para cuando se apagan
	local motors = {}
	local sockets = {} -- [Attachment] = rótula que ya trae el personaje
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then
			table.insert(motors, { Joint = d, Part0 = d.Part0, Part1 = d.Part1, C0 = d.C0, C1 = d.C1 })
		elseif d:IsA("AnimationConstraint") and d.Attachment0 and d.Attachment1 then
			local part0, part1 = d.Attachment0.Parent, d.Attachment1.Parent
			if part0 and part1 and part0:IsA("BasePart") and part1:IsA("BasePart") then
				table.insert(motors, {
					Joint = d, Part0 = part0, Part1 = part1,
					C0 = d.Attachment0.CFrame, C1 = d.Attachment1.CFrame, Attachment0 = d.Attachment0,
				})
			end
		elseif d:IsA("BallSocketConstraint") then
			if d.Attachment0 then
				sockets[d.Attachment0] = d
			end
			if d.Attachment1 then
				sockets[d.Attachment1] = d
			end
		end
	end
	if #motors == 0 then
		return false
	end
	character:SetAttribute("Ragdolled", true)
	-- (el cuerpo de un jugador lo mueve su propio cliente: el servidor se lo queda para que el
	-- empujón y la caída se vean igual para todos)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			pcall(part.SetNetworkOwner, part, nil)
		end
	end
	-- El eje X de la rótula va a lo largo del hueso (en R15 los miembros van en Y): así UpperAngle
	-- limita cuánto se dobla y los límites de giro, cuánto rota sobre sí mismo
	local alongBone = CFrame.Angles(0, 0, math.pi / 2)
	for _, motor in motors do
		local own = motor.Attachment0 and sockets[motor.Attachment0]
		if own then
			-- (unión nueva con su rótula ya puesta: basta con apagar la unión)
			local apart = Instance.new("NoCollisionConstraint")
			apart.Part0 = motor.Part0
			apart.Part1 = motor.Part1
			apart.Parent = motor.Part1
			own.Enabled = true
			motor.Joint.Enabled = false
			continue
		end
		local a0 = Instance.new("Attachment")
		a0.Name = "RagdollA0"
		a0.CFrame = motor.C0 * alongBone
		a0.Parent = motor.Part0
		local a1 = Instance.new("Attachment")
		a1.Name = "RagdollA1"
		a1.CFrame = motor.C1 * alongBone
		a1.Parent = motor.Part1
		-- Las piezas unidas se solapan en la articulación: que no choquen entre sí (temblarían)
		local noCollide = Instance.new("NoCollisionConstraint")
		noCollide.Part0 = motor.Part0
		noCollide.Part1 = motor.Part1
		noCollide.Parent = motor.Part1
		local socket = Instance.new("BallSocketConstraint")
		socket.Name = "RagdollSocket"
		socket.Attachment0 = a0
		socket.Attachment1 = a1
		local limit = LIMITS[motor.Joint.Name] or { 45, 15 }
		socket.LimitsEnabled = true
		socket.UpperAngle = limit[1]
		socket.TwistLimitsEnabled = true
		socket.TwistLowerAngle = -limit[2]
		socket.TwistUpperAngle = limit[2]
		socket.Parent = motor.Part1
		motor.Joint.Enabled = false
	end
	-- Las piezas del cuerpo chocan con el suelo (si no, atravesarían el suelo); la raíz no
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") then
			part.CanCollide = part ~= root
			if part == root then
				part.Massless = true
			end
		end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") and typeof(push) == "Vector3" then
		torso.AssemblyLinearVelocity += push
	end
	-- Cuando ya ha caído, se queda quieto y sin colisión: no estorba en puertas ni escaleras (en
	-- Eliminación y Buscar y destruir el cuerpo dura toda la ronda) y no gasta física
	task.delay(Ragdoll.SettleTime, function()
		if not character.Parent then
			return
		end
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end
	end)
	return true
end

return Ragdoll
