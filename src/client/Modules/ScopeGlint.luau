-- Destello de la mira (como en los shooters): un bot tirador enemigo que está quieto y mira hacia
-- ti brilla a lo lejos, así puedes saber desde dónde te apunta. Solo en el cliente; las paredes lo
-- tapan (no es un contorno a través de los muros).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ScopeGlint = {}

local MIN_DISTANCE = 35 -- de cerca no hace falta
local MAX_DISTANCE = 450
local FACING = 0.93 -- coseno del ángulo: tiene que mirar casi hacia la cámara
local CHECK_INTERVAL = 0.1

local player = Players.LocalPlayer
local glints = {} -- [modelo del bot] = BillboardGui

local function isEnemy(model)
	if ReplicatedStorage:GetAttribute("TeamMode") == false then
		return true
	end
	local team = model:GetAttribute("Team")
	return team == nil or player.Team == nil or team ~= player.Team.Name
end

local function makeGlint(head)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ScopeGlint"
	billboard.Size = UDim2.fromOffset(30, 30)
	billboard.StudsOffset = Vector3.new(0.4, 0.1, 0)
	billboard.LightInfluence = 0
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = MAX_DISTANCE
	billboard.Adornee = head
	-- Un punto blanco con un aro y dos rayos en cruz
	local core = Instance.new("Frame")
	core.Name = "Core"
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromScale(0.42, 0.42)
	core.BackgroundColor3 = Color3.fromRGB(255, 255, 235)
	core.BorderSizePixel = 0
	core.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = core
	for _, size in { UDim2.fromScale(1, 0.08), UDim2.fromScale(0.08, 1) } do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = size
		ray.BackgroundColor3 = Color3.fromRGB(255, 250, 210)
		ray.BackgroundTransparency = 0.25
		ray.BorderSizePixel = 0
		ray.Parent = billboard
	end
	billboard.Parent = head
	return billboard
end

local function update()
	local folder = workspace:FindFirstChild("Bots")
	local camera = workspace.CurrentCamera
	local seen = {}
	if folder and camera then
		local cameraPosition = camera.CFrame.Position
		for _, model in folder:GetChildren() do
			if model:GetAttribute("Role") ~= "Tirador" or not isEnemy(model) then
				continue
			end
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			local head = model:FindFirstChild("Head")
			if not (humanoid and root and head and root:IsA("BasePart") and head:IsA("BasePart")) or humanoid.Health <= 0 then
				continue
			end
			local offset = cameraPosition - head.Position
			local distance = offset.Magnitude
			local velocity = root.AssemblyLinearVelocity
			local still = Vector3.new(velocity.X, 0, velocity.Z).Magnitude < 4
			if distance > MIN_DISTANCE and distance < MAX_DISTANCE and still then
				local look = root.CFrame.LookVector
				local flatLook = Vector3.new(look.X, 0, look.Z)
				local flatOffset = Vector3.new(offset.X, 0, offset.Z)
				if flatLook.Magnitude > 0.01 and flatOffset.Magnitude > 0.01 and flatLook.Unit:Dot(flatOffset.Unit) > FACING then
					seen[model] = true
					local glint = glints[model]
					if not glint or glint.Parent ~= head then
						if glint then
							glint:Destroy()
						end
						glint = makeGlint(head)
						glints[model] = glint
					end
					-- (parpadea un poco, como el reflejo del sol en la lente)
					local pulse = 0.5 + 0.5 * math.sin(os.clock() * 9)
					local core = glint:FindFirstChild("Core")
					if core and core:IsA("Frame") then
						core.BackgroundTransparency = 0.05 + 0.3 * pulse
					end
					glint.Size = UDim2.fromOffset(26 + 10 * pulse, 26 + 10 * pulse)
				end
			end
		end
	end
	for model, glint in glints do
		if not seen[model] then
			glint:Destroy()
			glints[model] = nil
		end
	end
end

function ScopeGlint.Init()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0
		update()
	end)
end

ScopeGlint.Update = update
return ScopeGlint
