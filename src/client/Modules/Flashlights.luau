-- Linternas de noche (mapas nocturnos y versiones de noche): el arma de fuego lleva una linterna, como
-- en los shooters militares. La tuya (tecla L para apagarla o encenderla) sale de donde va el arma y
-- proyecta sombras; las de los demás (jugadores con la suya encendida y bots) se ven desde lejos...
-- y también delatan dónde está cada uno. Solo en este cliente: tu elección se manda al servidor
-- (atributo Flashlight del personaje) para que los demás vean la tuya.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)
local ClientState = require(script.Parent.ClientState)

local Flashlights = {}

Flashlights.On = true -- tu linterna (de noche)
Flashlights.MaxRemote = 6 -- linternas de los demás encendidas a la vez (las más cercanas)
Flashlights.RemoteRange = 160
local COLOR = Color3.fromRGB(255, 244, 226)
local OFFSET = CFrame.new(0.45, -0.45, -1.2) -- (de donde va el arma)

local player = Players.LocalPlayer
local holder, light
local remoteLights = setmetatable({}, { __mode = "k" }) -- [Tool] = SpotLight
local remoteClock = 0

-- ¿Es de noche? (antes del amanecer o después del anochecer)
function Flashlights.IsNight()
	local t = Lighting.ClockTime
	return t < 6.3 or t > 18.2
end

local function ensureLocal()
	if holder and holder.Parent then
		return
	end
	holder = Instance.new("Part")
	holder.Name = "MyFlashlight"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 50
	light.Range = 48
	light.Brightness = 1.8
	light.Color = COLOR
	light.Enabled = false
	light.Parent = holder
	holder.Parent = workspace.CurrentCamera
end

local function holdsGun(model)
	local tool = model and model:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("Weapon") then
		return tool
	end
	return nil
end

-- Linternas de los demás: las más cercanas con el arma en la mano (y la linterna encendida)
local function updateRemote(active)
	local camera = workspace.CurrentCamera
	local wanted = {}
	if active and camera and ClientState.EffectiveQuality ~= "Baja" then
		local list = {}
		local function consider(model, on)
			local tool = holdsGun(model)
			local handle = tool and tool:FindFirstChild("Handle")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			if on and handle and handle:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local distance = (handle.Position - camera.CFrame.Position).Magnitude
				if distance <= Flashlights.RemoteRange then
					table.insert(list, { Tool = tool, Handle = handle, Distance = distance })
				end
			end
		end
		for _, p in Players:GetPlayers() do
			if p ~= player and p.Character then
				consider(p.Character, p.Character:GetAttribute("Flashlight") ~= false)
			end
		end
		local bots = workspace:FindFirstChild("Bots")
		if bots then
			for _, model in bots:GetChildren() do
				consider(model, not model:GetAttribute("Zombie"))
			end
		end
		table.sort(list, function(a, b)
			return a.Distance < b.Distance
		end)
		for i = 1, math.min(#list, Flashlights.MaxRemote) do
			wanted[list[i].Tool] = list[i].Handle
		end
	end
	for tool, handle in wanted do
		local spot = remoteLights[tool]
		if not spot or not spot.Parent then
			spot = Instance.new("SpotLight")
			spot.Name = "Flashlight"
			spot.Face = Enum.NormalId.Front
			spot.Angle = 45
			spot.Range = 40
			spot.Brightness = 1.5
			spot.Color = COLOR
			spot.Shadows = false
			spot.Parent = handle
			remoteLights[tool] = spot
		end
		spot.Enabled = true
	end
	for tool, spot in remoteLights do
		if not wanted[tool] and spot.Parent then
			spot.Enabled = false
		end
	end
end

function Flashlights.Update(dt)
	local camera = workspace.CurrentCamera
	local active = Flashlights.IsNight() and not ClientState.InMainMenu
	-- La tuya
	ensureLocal()
	local def = ClientState.CurrentDef
	local mine = active and Flashlights.On and def ~= nil and def.Type == "Gun"
		and not ClientState.Dead and not ClientState.KillcamActive and camera ~= nil
	light.Enabled = mine
	if mine and camera then
		holder.CFrame = camera.CFrame * OFFSET
		light.Shadows = ClientState.EffectiveQuality ~= "Baja"
	end
	-- Las de los demás (unas 4 veces por segundo)
	remoteClock += dt or 0
	if remoteClock >= 0.25 then
		remoteClock = 0
		updateRemote(active)
	end
end

-- Encender o apagar la tuya (y avisar al servidor: los demás ven si la llevas encendida)
function Flashlights.Toggle()
	Flashlights.On = not Flashlights.On
	Remotes.Flashlight:FireServer(Flashlights.On)
	return Flashlights.On
end

function Flashlights.Init()
	RunService:BindToRenderStep("Flashlight", Enum.RenderPriority.Camera.Value + 3, function(dt)
		local ok, err = pcall(Flashlights.Update, dt)
		if not ok then
			warn("[Flashlights]", err)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.L or ClientState.InMainMenu then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		Flashlights.Toggle()
	end)
	-- (personaje nuevo: el servidor vuelve a saber cómo la llevas)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		Remotes.Flashlight:FireServer(Flashlights.On)
	end)
end

return Flashlights
