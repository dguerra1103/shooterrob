-- Huellas en superficies blandas (nieve, arena, barro, tierra): solo en el cliente, para los
-- personajes cercanos (jugadores y bots). Se desvanecen solas y hay un máximo para no gastar memoria. En calidad Baja
-- no se crean.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ClientState = require(script.Parent.ClientState)

local Footprints = {}

-- Color de la huella según el material que pisa (algo más oscuro que la superficie)
local SOFT = {
	[Enum.Material.Snow] = Color3.fromRGB(184, 194, 214),
	[Enum.Material.Sand] = Color3.fromRGB(140, 120, 88),
	[Enum.Material.Mud] = Color3.fromRGB(58, 44, 30),
	[Enum.Material.Ground] = Color3.fromRGB(80, 66, 46),
}
local STEP_DISTANCE = 2.6 -- studs entre pisadas
local MAX_PRINTS = 70
local LIFETIME = 9
local MAX_DISTANCE = 90 -- solo personajes cerca de la cámara
local CHECK_INTERVAL = 0.08

local folder
local prints = {}
local tracked = {} -- [character] = { Last = Vector3, Left = boolean }

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function removePrint(part)
	local index = table.find(prints, part)
	if index then
		table.remove(prints, index)
	end
	part:Destroy()
end

local function addPrint(cf, color)
	if #prints >= MAX_PRINTS then
		removePrint(prints[1])
	end
	local part = Instance.new("Part")
	part.Name = "Footprint"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = Vector3.new(0.65, 0.04, 1.1)
	part.Transparency = 0.35
	part.CFrame = cf
	part.Parent = folder
	table.insert(prints, part)
	-- Se mantiene un rato y luego se borra poco a poco (como la nieve que cae encima)
	local fade = TweenInfo.new(LIFETIME * 0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, LIFETIME * 0.4)
	TweenService:Create(part, fade, { Transparency = 1 }):Play()
	task.delay(LIFETIME, function()
		if part.Parent then
			removePrint(part)
		end
	end)
end

local function step(character, humanoid, root, state)
	local flat = Vector3.new(1, 0, 1)
	local moved = (root.Position - state.Last) * flat
	if moved.Magnitude < STEP_DISTANCE then
		return
	end
	state.Last = root.Position
	-- El material sale del rayo hacia el suelo (FloorMaterial solo se calcula para tu personaje);
	-- si no hay suelo cerca (saltando) no hay huella
	rayParams.FilterDescendantsInstances = { folder, character }
	local result = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + 1), 0), rayParams)
	local color = result and SOFT[result.Material]
	if not color then
		return
	end
	local normal = result.Normal
	local forward = moved.Unit
	forward = (forward - normal * forward:Dot(normal))
	if forward.Magnitude < 0.01 then
		return
	end
	forward = forward.Unit
	local right = forward:Cross(normal)
	state.Left = not state.Left
	local position = result.Position + normal * 0.02 + right * (state.Left and -0.45 or 0.45)
	addPrint(CFrame.fromMatrix(position, right, normal, -forward), color)
end

function Footprints.Init()
	folder = Instance.new("Folder")
	folder.Name = "Footprints"
	folder.Parent = workspace

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0
		if ClientState.EffectiveQuality == "Baja" then
			return
		end
		local camera = workspace.CurrentCamera
		local seen = {}
		local characters = {}
		for _, player in Players:GetPlayers() do
			if player.Character then
				table.insert(characters, player.Character)
			end
		end
		-- (los bots también dejan huellas)
		local bots = workspace:FindFirstChild("Bots")
		if bots then
			for _, model in bots:GetChildren() do
				table.insert(characters, model)
			end
		end
		for _, character in characters do
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 and camera and (root.Position - camera.CFrame.Position).Magnitude < MAX_DISTANCE then
				seen[character] = true
				local state = tracked[character]
				if not state then
					state = { Last = root.Position, Left = false }
					tracked[character] = state
				end
				step(character, humanoid, root, state)
			end
		end
		for character in tracked do
			if not seen[character] then
				tracked[character] = nil
			end
		end
	end)
end

return Footprints
