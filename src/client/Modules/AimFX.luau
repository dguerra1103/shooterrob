-- Apuntar con realismo: al apuntar con la mira, el fondo se desenfoca un poco más allá de lo que
-- miras (profundidad de campo, enfocada a la distancia del punto de mira) y los bordes de la pantalla
-- se oscurecen suavemente, como al mirar por el arma. Solo en este cliente; con la mira telescópica
-- puesta no hace falta (la tapa el visor) y en calidad Baja no se usa (cuesta en móviles modestos).
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ClientState = require(script.Parent.ClientState)

local AimFX = {}

local MAX_BLUR = 0.22 -- desenfoque del fondo con la mira del todo puesta (0 = nada, 1 = mucho)
local MAX_VIGNETTE = 0.38 -- oscuridad de los bordes

local dof, gui
local edges = {}
local focus = 60
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function buildVignette()
	gui = Instance.new("ScreenGui")
	gui.Name = "AimVignette"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -1 -- (debajo del HUD)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local specs = {
		{ Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 0.3), 90 },
		{ Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.3), -90 },
		{ Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(0.25, 1), 0 },
		{ Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromScale(0.25, 1), 180 },
	}
	for i, spec in specs do
		local frame = Instance.new("Frame")
		frame.Name = "Edge" .. i
		frame.AnchorPoint = spec[1]
		frame.Position = spec[2]
		frame.Size = spec[3]
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 1
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = spec[4]
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.9),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = frame
		frame.Parent = gui
		edges[i] = frame
	end
end

local function ensureDof(camera)
	if dof and dof.Parent == camera then
		return dof
	end
	if dof then
		dof:Destroy()
	end
	dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "AimDepthOfField"
	dof.NearIntensity = 0
	dof.FarIntensity = 0
	dof.FocusDistance = 60
	dof.InFocusRadius = 30
	dof.Enabled = false
	dof.Parent = camera
	return dof
end

function AimFX.Update(dt)
	dt = dt or 1 / 60
	local camera = workspace.CurrentCamera
	if not camera or not gui then
		return
	end
	local alpha = ClientState.AimAlpha or 0
	local def = ClientState.CurrentDef
	-- (con el visor de francotirador puesto lo tapa todo el visor)
	local scoped = def ~= nil and def.Scope == true and alpha > 0.85
	local active = alpha > 0.02 and not scoped and not ClientState.InMainMenu and not ClientState.Dead
	local low = ClientState.EffectiveQuality == "Baja"

	-- Viñeta: bordes algo más oscuros al apuntar
	local edgeTransparency = active and (1 - MAX_VIGNETTE * alpha) or 1
	for _, edge in edges do
		edge.BackgroundTransparency = edgeTransparency
	end

	local effect = ensureDof(camera)
	if not active or low then
		effect.Enabled = false
		return
	end
	-- Enfoque a lo que hay bajo la mira (suave, como el ojo)
	local ignore = { camera }
	local character = Players.LocalPlayer.Character
	if character then
		table.insert(ignore, character)
	end
	params.FilterDescendantsInstances = ignore
	local origin = camera.CFrame.Position
	local hit = workspace:Raycast(origin, camera.CFrame.LookVector * 300, params)
	local target = math.clamp(hit and hit.Distance or 250, 6, 250)
	focus += (target - focus) * math.min(1, dt * 8)
	effect.Enabled = true
	effect.FocusDistance = focus
	effect.InFocusRadius = math.max(10, focus * 0.45)
	effect.FarIntensity = MAX_BLUR * alpha
	effect.NearIntensity = 0
end

function AimFX.Init()
	buildVignette()
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(AimFX.Update, dt)
		if not ok then
			warn("[AimFX]", err)
		end
	end)
end

return AimFX
