-- Poses de victoria e intros de MVP (Shared/Poses) sobre una copia de personaje (pantalla final,
-- vista previa de la tienda). Las poses se hacen por código con la misma cinemática inversa que la
-- pose de "arma lista" del lobby (Preview), así no hace falta subir animaciones; las intros de MVP son
-- piezas propias (sin partículas, para que también se vean dentro de un ViewportFrame) que se borran
-- solas. Solo estética.
--   PoseRig.Apply(model, poseId)                    -- pone la pose (con o sin arma)
--   local stop = PoseRig.PlayIntro(parent, model, introId)   -- intro de MVP (≈1 s)
local TweenService = game:GetService("TweenService")

local Preview = require(script.Parent.Parent.Preview)

local PoseRig = {}

local function hideWeapon(model)
	local tool = Preview.WeaponOf(model)
	if tool then
		tool:Destroy()
	end
end

local function torsoPoint(model, offset)
	local torso = model:FindFirstChild("UpperTorso")
	return torso and (torso.CFrame * offset).Position or nil
end

local RIGHT_POLE = CFrame.new(2.2, -1.6, 0.6)
local LEFT_POLE = CFrame.new(-1.6, -1.8, -0.4)

local function arm(model, side, offset, pole)
	local target = torsoPoint(model, offset)
	local torso = model:FindFirstChild("UpperTorso")
	if target and torso then
		pcall(Preview.SolveArm, model, side, nil, target, (torso.CFrame * pole).Position)
	end
end

-- Cada pose: qué hace con el arma y con los brazos (el personaje mira a su -Z)
PoseRig.Poses = {
	Ready = function(model)
		pcall(Preview.PoseReady, model)
	end,
	Bajada = function(model)
		if not Preview.WeaponOf(model) or not pcall(Preview.PoseReady, model, math.rad(-55)) then
			arm(model, "Right", CFrame.new(0.9, -1.4, -0.3), RIGHT_POLE)
		end
	end,
	AlCielo = function(model)
		if not Preview.WeaponOf(model) or not pcall(Preview.PoseReady, model, math.rad(70)) then
			arm(model, "Right", CFrame.new(0.8, 1.8, -0.2), RIGHT_POLE)
		end
	end,
	Saludo = function(model)
		hideWeapon(model)
		arm(model, "Right", CFrame.new(0.32, 1.25, -0.42), CFrame.new(2.4, 0.6, 0.2))
	end,
	Brazos = function(model)
		hideWeapon(model)
		arm(model, "Right", CFrame.new(-0.42, -0.2, -0.62), RIGHT_POLE)
		arm(model, "Left", CFrame.new(0.42, -0.05, -0.66), LEFT_POLE)
	end,
	Senala = function(model)
		hideWeapon(model)
		arm(model, "Right", CFrame.new(0.55, 0.55, -2.3), CFrame.new(2.2, -0.6, 0.2))
	end,
}

function PoseRig.Apply(model, poseId)
	local pose = PoseRig.Poses[poseId or "Ready"] or PoseRig.Poses.Ready
	local ok = pcall(pose, model)
	return ok
end

---------------------------------------------------------------------------
-- Intros de MVP
---------------------------------------------------------------------------

local function spark(parent, position, color, size)
	local p = Instance.new("Part")
	p.Name = "IntroFX"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Shape = Enum.PartType.Ball
	p.Color = color
	p.Size = Vector3.one * (size or 0.25)
	p.Position = position
	p.Parent = parent
	return p
end

local function fadeAway(part, time, props)
	props = props or {}
	props.Transparency = 1
	local t = TweenService:Create(part, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	task.delay(time + 0.05, function()
		part:Destroy()
	end)
end

local INTROS = {}

-- Destello dorado: chispas que salen hacia fuera desde el pecho
INTROS.Destello = function(parent, model, root)
	local center = root.Position + Vector3.new(0, 1.2, 0)
	for i = 1, 14 do
		local angle = i / 14 * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0.4 + (i % 3) * 0.25, math.sin(angle))
		local p = spark(parent, center, Color3.fromRGB(255, 214, 90), 0.22)
		fadeAway(p, 0.7, { Position = center + dir * 3, Size = Vector3.one * 0.05 })
	end
end

-- Media vuelta: el MVP gira sobre sí mismo y vuelve a mirar a la cámara
INTROS.Giro = function(parent, model, root)
	local base = root.CFrame
	model:SetAttribute("IntroSpinning", true) -- (la escena no le mueve mientras gira)
	task.spawn(function()
		local start = os.clock()
		while model.Parent and os.clock() - start < 0.6 do
			local a = (os.clock() - start) / 0.6
			a = 1 - (1 - a) ^ 3
			root.CFrame = base * CFrame.Angles(0, a * math.pi * 2, 0)
			task.wait()
		end
		if model.Parent then
			root.CFrame = base
		end
		model:SetAttribute("IntroSpinning", nil)
	end)
	INTROS.Destello(parent, model, root)
end

-- Lluvia de ascuas: chispas naranjas que suben alrededor
INTROS.Ascuas = function(parent, _, root)
	local feet = root.Position - Vector3.new(0, 2.6, 0)
	for i = 1, 22 do
		task.delay(i * 0.04, function()
			if not parent.Parent then
				return
			end
			local offset = Vector3.new(math.cos(i * 2.4) * 1.6, 0, math.sin(i * 2.4) * 1.6)
			local p = spark(parent, feet + offset, i % 2 == 0 and Color3.fromRGB(255, 120, 30) or Color3.fromRGB(255, 200, 70), 0.16)
			fadeAway(p, 0.9, { Position = feet + offset + Vector3.new(0, 4 + (i % 4), 0) })
		end)
	end
end

-- Columna de luz: un haz cae sobre el MVP y se cierra
INTROS.Columna = function(parent, _, root)
	local beam = Instance.new("Part")
	beam.Name = "IntroFX"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Shape = Enum.PartType.Cylinder
	beam.Color = Color3.fromRGB(255, 236, 160)
	beam.Transparency = 0.25
	beam.Size = Vector3.new(30, 3.2, 3.2)
	beam.CFrame = CFrame.new(root.Position + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Parent = parent
	fadeAway(beam, 1, { Size = Vector3.new(30, 0.2, 0.2) })
	INTROS.Destello(parent, nil, root)
end

function PoseRig.PlayIntro(parent, model, introId)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not root or not parent then
		return
	end
	local intro = INTROS[introId or "Destello"] or INTROS.Destello
	pcall(intro, parent, model, root)
end

return PoseRig
