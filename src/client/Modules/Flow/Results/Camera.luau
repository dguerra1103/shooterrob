-- ResultsCameraController: cámara de la pantalla final. Tres planos y movimiento muy lento:
--   "Wide"  plano general del equipo (entra un poco más lejos y se acerca despacio)
--   "MVP"   se acerca al MVP sin perder al resto
--   "Drift" deriva lateral lentísima (lo que queda mientras se mira la pantalla)
-- Profundidad de campo ligera (los personajes nítidos, el fondo un poco borroso) solo mientras dura;
-- es una instancia propia que se borra al salir: la iluminación del juego no se toca.
local Lighting = game:GetService("Lighting")

local Camera = {}

local targets
local preset = "Wide"
local presetAt = 0
local fromCF
local dof
local FOV = 46

local function shot(name, t)
	local center, mvp, forward = targets.Center, targets.MVP, targets.Forward
	local right = forward:Cross(Vector3.yAxis).Unit
	if name == "Wide" then
		-- (de 17 a 14,5 studs en los primeros segundos)
		local d = 14.5 + 2.5 * math.exp(-t * 0.9)
		return CFrame.lookAt(center + forward * d + Vector3.new(0, 1.6, 0), center + Vector3.new(0, 0.2, 0))
	elseif name == "MVP" then
		local d = 11 + 1.5 * math.exp(-t * 0.8)
		return CFrame.lookAt(mvp + forward * d + Vector3.new(0, 1.0, 0) + right * 0.4, mvp - Vector3.new(0, 0.5, 0))
	end
	-- Drift: muy despacio de un lado a otro
	local sway = math.sin(t * 0.12) * 1.6
	return CFrame.lookAt(center + forward * 13 + right * sway + Vector3.new(0, 1.4, 0), center + Vector3.new(0, 0.3, 0))
end

function Camera.Start(stageTargets, camera)
	targets = stageTargets
	fromCF = camera and camera.CFrame or nil
	preset = "Wide"
	presetAt = os.clock()
	if not dof or not dof.Parent then
		dof = Instance.new("DepthOfFieldEffect")
		dof.Name = "ResultsDepth"
		dof.FarIntensity = 0.22
		dof.NearIntensity = 0
		dof.FocusDistance = 14
		dof.InFocusRadius = 9
		dof.Parent = Lighting
	end
end

function Camera.SetPreset(name)
	if not targets or name == preset then
		return
	end
	-- (el plano nuevo arranca desde donde está la cámara: sin cortes)
	fromCF = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or fromCF
	preset = name
	presetAt = os.clock()
end

-- Lo llama el FlowController en cada fotograma (modo de cámara "Scripted") mientras se ve
function Camera.Step(camera)
	if not targets then
		return
	end
	local t = os.clock() - presetAt
	local goal = shot(preset, t)
	-- Mezcla suave desde el plano anterior (1,2 s)
	local a = math.clamp(t / 1.2, 0, 1)
	a = 1 - (1 - a) ^ 3
	camera.CFrame = fromCF and fromCF:Lerp(goal, a) or goal
	camera.FieldOfView = FOV
	if dof then
		dof.FocusDistance = (camera.CFrame.Position - (preset == "MVP" and targets.MVP or targets.Center)).Magnitude
	end
end

function Camera.Stop()
	targets = nil
	if dof then
		dof:Destroy()
		dof = nil
	end
end

return Camera
