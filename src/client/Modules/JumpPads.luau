-- Plataformas de salto del mapa (piezas con el atributo JumpPad = velocidad vertical, ver
-- Kit.jumpPad): al pisar una sales disparado hacia arriba y puedes dirigirte en el aire.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local JumpPads = {}

local COOLDOWN = 0.6
local lastLaunch = 0
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

function JumpPads.Init()
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health <= 0 or ClientState.Frozen() then
			return
		end
		if os.clock() - lastLaunch < COOLDOWN then
			return
		end
		params.FilterDescendantsInstances = { character }
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -4, 0), params)
		local power = hit and hit.Instance:GetAttribute("JumpPad")
		if type(power) ~= "number" then
			return
		end
		lastLaunch = os.clock()
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, power, v.Z)
		ClientState.FovKick = 8
		Sounds.Play("Swing")
	end)
end

return JumpPads
