-- Nombre del enemigo al que apuntas (como en los shooters): normalmente los enemigos no llevan nombre
-- (ver WorldFX), pero si tienes la mira encima de uno, sale su nombre en rojo sobre la cabeza un
-- momento. Un solo cartel reutilizado y un rayo cada 0,1 s.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClientState = require(script.Parent.ClientState)

local EnemyName = {}

local RANGE = 300
local CHECK_INTERVAL = 0.1
local LINGER = 0.4

local player = Players.LocalPlayer
local billboard, label
local lastSeen = 0
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

-- ¿Es un enemigo vivo? Devuelve su nombre
local function enemyName(model)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or model == player.Character then
		return nil
	end
	local owner = Players:GetPlayerFromCharacter(model)
	local teamMode = ReplicatedStorage:GetAttribute("TeamMode") ~= false
	if owner then
		if teamMode and player.Team ~= nil and owner.Team == player.Team then
			return nil
		end
		return owner.DisplayName
	end
	if model:GetAttribute("Bot") then
		local team = model:GetAttribute("Team")
		if teamMode and player.Team ~= nil and team == player.Team.Name then
			return nil
		end
		return model.Name
	end
	return nil
end

local function update()
	local camera = workspace.CurrentCamera
	if not camera or ClientState.InMainMenu then
		billboard.Enabled = false
		return
	end
	local ignore = { camera }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * RANGE, params)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	local name = model and enemyName(model)
	local head = model and model:FindFirstChild("Head")
	if name and head then
		lastSeen = os.clock()
		label.Text = name
		billboard.Adornee = head
		billboard.Enabled = true
	elseif os.clock() - lastSeen > LINGER or not (billboard.Adornee and billboard.Adornee.Parent) then
		billboard.Enabled = false
	end
end

function EnemyName.Init()
	billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyName"
	billboard.ResetOnSpawn = false -- (si no, Roblox lo borraría al aparecer)
	billboard.Size = UDim2.fromOffset(160, 24)
	billboard.StudsOffset = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Enabled = false
	billboard.Parent = player:WaitForChild("PlayerGui")
	label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 70, 60)
	label.TextStrokeTransparency = 0.3
	label.Text = ""
	label.Parent = billboard
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

EnemyName.Update = update
return EnemyName
