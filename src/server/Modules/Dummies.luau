-- Muñecos de práctica para probar las armas en Studio (desactívalos en GameConfig.TrainingDummies).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Combat = require(script.Parent.Combat)

local Dummies = {}

local SPOTS = {
	Vector3.new(-20, 4, -60),
	Vector3.new(20, 4, 60),
	Vector3.new(-50, 4, 30),
	Vector3.new(50, 4, -30),
	Vector3.new(0, 11, 0),
}

local folder

-- Un punto libre del mapa actual (puntos FFASpawn) o uno de los fijos si no hay
local function randomSpot(fallback)
	local map = workspace:FindFirstChild("Map")
	local points = {}
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "FFASpawn" then
				table.insert(points, d.Position + Vector3.new(0, 3, 0))
			end
		end
	end
	if #points > 0 then
		return points[math.random(1, #points)]
	end
	return fallback
end

local function spawnDummy(position)
	position = randomSpot(position)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = Color3.fromRGB(255, 200, 80)
	description.TorsoColor = Color3.fromRGB(80, 80, 90)
	description.LeftArmColor = Color3.fromRGB(255, 200, 80)
	description.RightArmColor = Color3.fromRGB(255, 200, 80)
	description.LeftLegColor = Color3.fromRGB(60, 60, 70)
	description.RightLegColor = Color3.fromRGB(60, 60, 70)

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)
	end
	if not ok then
		warn("[Dummies] No se pudo crear el muñeco:", model)
		return
	end
	model.Name = "Muñeco"
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = "Muñeco"
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	model.Parent = folder

	Combat.WatchHumanoid(humanoid, nil, "Muñeco")
	humanoid.Died:Connect(function()
		task.wait(4)
		model:Destroy()
		spawnDummy(position)
	end)
end

function Dummies.Init()
	if not GameConfig.TrainingDummies then
		return
	end
	folder = Instance.new("Folder")
	folder.Name = "Dummies"
	folder.Parent = workspace
	for _, position in SPOTS do
		spawnDummy(position)
	end
end

return Dummies
