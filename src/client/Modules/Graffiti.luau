-- Grafitis (tecla J, o el botón 🎨 en móvil): pinta tu grafiti equipado en la pared o el suelo que
-- tienes delante. El servidor (Graffiti) comprueba el punto y lo pinta para todos.
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Sprays = require(Shared.Sprays)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer

local Graffiti = {}

local lastSpray = -math.huge
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function spray()
	if ClientState.IsBlocked() then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if os.clock() - lastSpray < Sprays.Cooldown then
		return
	end
	local camera = workspace.CurrentCamera
	local ignore = { character }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	rayParams.FilterDescendantsInstances = ignore
	local origin = camera.CFrame.Position
	local hit = workspace:Raycast(origin, camera.CFrame.LookVector * (Sprays.Range + 4), rayParams)
	local head = character:FindFirstChild("Head")
	if not hit or not head or (hit.Position - head.Position).Magnitude > Sprays.Range then
		return
	end
	lastSpray = os.clock()
	Remotes.Spray:FireServer(hit.Position)
	Sounds.Play("Slide", nil, 1.6, 0.5) -- "pssst" del bote
end

function Graffiti.Init()
	ContextActionService:BindAction("Spray", function(_, state)
		if state == Enum.UserInputState.Begin then
			spray()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.J)
	ContextActionService:SetTitle("Spray", "🎨")
	ContextActionService:SetPosition("Spray", UDim2.new(1, -200, 1, -360))
end

return Graffiti
