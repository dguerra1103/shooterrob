-- Apuntar con realismo: al apuntar con la mira, los bordes de la pantalla se oscurecen suavemente,
-- como al mirar por el arma. Solo en este cliente; con la mira telescópica puesta no hace falta (la
-- tapa el visor).
--
-- Profundidad de campo (DOF): NUNCA en partida por defecto (Fase 3: en combate todo enemigo debe verse
-- nítido, esté a la distancia que esté). El desenfoque al apuntar sigue disponible con
-- GameConfig.AimDepthOfField = true (enfocado a la distancia del punto de mira; no en calidad Baja), y
-- el desenfoque lejano de calidad Ultra (QualityDOF, de Settings) solo se ve en los menús.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientState = require(script.Parent.ClientState)
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local AimFX = {}

-- desenfoque del fondo con la mira del todo puesta (0 = nada, 1 = mucho). Por debajo de 0,22: ahí el
-- desenfoque de Roblox da un salto brusco (y aparecería de golpe en vez de poco a poco)
local MAX_BLUR = 0.2
local MAX_FOCUS = 200 -- (lo máximo que admite FocusDistance)
local MAX_RADIUS = 50 -- (lo máximo que admite InFocusRadius)
local MAX_VIGNETTE = 0.38 -- oscuridad de los bordes

local dof, gui
local edges = {}
local focus = 60
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

-- Distancia a lo que hay bajo la mira. No cuentan las barandillas invisibles del mapa (las balas las
-- atraviesan) ni los cristales: se enfoca a lo que hay detrás
local function focusTarget(camera)
	local ignore = { camera }
	local character = Players.LocalPlayer.Character
	if character then
		table.insert(ignore, character)
	end
	local fx = workspace:FindFirstChild("ClientFX")
	if fx then
		table.insert(ignore, fx)
	end
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * 300
	for _ = 1, 3 do
		params.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(origin, direction, params)
		if not hit then
			return MAX_FOCUS
		end
		if hit.Instance.Transparency < 0.3 then
			return (hit.Position - origin).Magnitude
		end
		table.insert(ignore, hit.Instance)
	end
	return MAX_FOCUS
end

local function buildVignette()
	gui = Instance.new("ScreenGui")
	gui.Name = "AimVignette"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -1 -- (debajo del HUD)
	-- (velo a pantalla completa, sin nada que tocar: también por detrás de la muesca del teléfono)
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
		gui.ClipToDeviceSafeArea = false
	end)
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
		and not ClientState.ReducedFX()
	local low = ClientState.EffectiveQuality == "Baja"

	-- Desenfoque lejano de Ultra: solo en los menús (en partida apagado siempre)
	local quality = Lighting:FindFirstChild("QualityDOF")
	if quality and quality:IsA("DepthOfFieldEffect") then
		local wanted = ClientState.EffectiveQuality == "Ultra" and ClientState.InMainMenu == true
		if quality.Enabled ~= wanted then
			quality.Enabled = wanted
		end
	end

	-- Viñeta: bordes algo más oscuros al apuntar
	local edgeTransparency = active and (1 - MAX_VIGNETTE * alpha) or 1
	for _, edge in edges do
		edge.BackgroundTransparency = edgeTransparency
	end

	local effect = ensureDof(camera)
	if not active or low or not GameConfig.AimDepthOfField then
		effect.Enabled = false
		return
	end
	-- Enfoque a lo que hay bajo la mira (suave, como el ojo)
	local target = math.clamp(focusTarget(camera), 6, MAX_FOCUS)
	focus += (target - focus) * math.min(1, dt * 8)
	effect.Enabled = true
	effect.FocusDistance = math.min(focus, MAX_FOCUS)
	effect.InFocusRadius = math.clamp(focus * 0.45, 10, MAX_RADIUS)
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
