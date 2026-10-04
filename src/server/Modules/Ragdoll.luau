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
	local motors = {}
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then
			table.insert(motors, d)
		end
	end
	if #motors == 0 then
		return false
	end
	character:SetAttribute("Ragdolled", true)
	for _, motor in motors do
		local a0 = Instance.new("Attachment")
		a0.Name = "RagdollA0"
		a0.CFrame = motor.C0
		a0.Parent = motor.Part0
		local a1 = Instance.new("Attachment")
		a1.Name = "RagdollA1"
		a1.CFrame = motor.C1
		a1.Parent = motor.Part1
		local socket = Instance.new("BallSocketConstraint")
		socket.Name = "RagdollSocket"
		socket.Attachment0 = a0
		socket.Attachment1 = a1
		local limit = LIMITS[motor.Name] or { 45, 15 }
		socket.LimitsEnabled = true
		socket.UpperAngle = limit[1]
		socket.TwistLimitsEnabled = true
		socket.TwistLowerAngle = -limit[2]
		socket.TwistUpperAngle = limit[2]
		socket.Parent = motor.Part1
		motor.Enabled = false
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
	return true
end

return Ragdoll
