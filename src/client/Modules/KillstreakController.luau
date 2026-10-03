-- Recompensas por racha en el cliente:
--  * Radar: resalta en rojo a los enemigos a través de las paredes mientras dure (RadarUntil)
--  * Ataque aéreo: tecla T (cruceta derecha en mando) lanza el ataque al punto al que apuntas
--  * Marcas rojas en el suelo antes de que caigan las bombas
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local KillstreakController = {}

local strikeWidget, strikeLabel, radarLabel

local function radarActive()
	return workspace:GetServerTimeNow() < (player:GetAttribute("RadarUntil") or 0)
end

local function isEnemy(other)
	if other == player then
		return false
	end
	if ReplicatedStorage:GetAttribute("TeamMode") ~= false and player.Team ~= nil and other.Team == player.Team then
		return false
	end
	return true
end

-- Pone o quita el contorno rojo del radar en los enemigos
local function updateRadar()
	local active = radarActive()
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if character then
			local highlight = character:FindFirstChild("RadarHighlight")
			if active and isEnemy(other) then
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "RadarHighlight"
					highlight.FillColor = Color3.fromRGB(255, 40, 40)
					highlight.FillTransparency = 0.55
					highlight.OutlineColor = Color3.fromRGB(255, 120, 120)
					highlight.OutlineTransparency = 0
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.Parent = character
				end
			elseif highlight then
				highlight:Destroy()
			end
		end
	end
	local left = (player:GetAttribute("RadarUntil") or 0) - workspace:GetServerTimeNow()
	radarLabel.Visible = active and not ClientState.InMainMenu
	radarLabel.Text = "📡 RADAR " .. math.max(0, math.ceil(left)) .. "s"
end

local function updateWidget()
	local charges = player:GetAttribute("Airstrikes") or 0
	strikeWidget.Visible = charges > 0 and not ClientState.InMainMenu
	strikeLabel.Text = "✈ T" .. (charges > 1 and (" ×" .. charges) or "")
end

-- Punto al que apunta la cámara (o lejos al frente si apunta al cielo)
local function aimPoint()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { camera }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	local fx = workspace:FindFirstChild("ClientFX")
	if fx then
		table.insert(ignore, fx)
	end
	params.FilterDescendantsInstances = ignore
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * 500
	local result = workspace:Raycast(origin, direction, params)
	return result and result.Position or origin + camera.CFrame.LookVector * 150
end

local function callAirstrike()
	if ClientState.IsBlocked() or (player:GetAttribute("Airstrikes") or 0) <= 0 then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	Remotes.CallAirstrike:FireServer(aimPoint())
	Sounds.Play("Flag", nil, 1.3, 1)
end

-- Columna roja y anillo donde va a caer cada bomba
local function markPoints(points, delay)
	local folder = workspace:FindFirstChild("ClientFX") or workspace
	for _, point in points do
		if typeof(point) == "Vector3" then
			local beam = Instance.new("Part")
			beam.Anchored = true
			beam.CanCollide = false
			beam.CanQuery = false
			beam.CanTouch = false
			beam.CastShadow = false
			beam.Material = Enum.Material.Neon
			beam.Color = Color3.fromRGB(255, 40, 40)
			beam.Transparency = 0.5
			beam.Size = Vector3.new(0.8, 70, 0.8)
			beam.CFrame = CFrame.new(point + Vector3.new(0, 35, 0))
			beam.Parent = folder
			local ring = Instance.new("Part")
			ring.Anchored = true
			ring.CanCollide = false
			ring.CanQuery = false
			ring.CanTouch = false
			ring.CastShadow = false
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(255, 60, 40)
			ring.Shape = Enum.PartType.Cylinder
			ring.Transparency = 0.3
			ring.Size = Vector3.new(0.2, 2, 2)
			ring.CFrame = CFrame.new(point) * CFrame.Angles(0, 0, math.pi / 2)
			ring.Parent = folder
			TweenService:Create(ring, TweenInfo.new(delay, Enum.EasingStyle.Linear), { Size = Vector3.new(0.2, 22, 22), Transparency = 0.8 }):Play()
			TweenService:Create(beam, TweenInfo.new(delay, Enum.EasingStyle.Linear), { Size = Vector3.new(2.2, 70, 2.2) }):Play()
			Debris:AddItem(beam, delay + 0.2)
			Debris:AddItem(ring, delay + 0.2)
		end
	end
	Sounds.Play("Flag", nil, 0.6, 1.2)
end

function KillstreakController.Init()
	local gui = UI.new("ScreenGui", {
		Name = "Killstreaks",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Parent = player:WaitForChild("PlayerGui"),
	})
	strikeWidget = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -116, 1, -150),
		Size = UDim2.fromOffset(84, 34),
		BackgroundColor3 = Color3.fromRGB(150, 30, 30),
		Visible = false,
		Parent = gui,
	}, { UI.corner(10), UI.stroke(Color3.fromRGB(255, 200, 60), 2, 0), UI.gloss() })
	strikeLabel = UI.label({ Size = UDim2.fromScale(1, 1), Text = "✈ T", TextSize = 20, Parent = strikeWidget })
	radarLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 92),
		Size = UDim2.fromOffset(220, 28),
		Text = "",
		TextSize = 22,
		TextColor3 = Color3.fromRGB(255, 110, 110),
		Visible = false,
		Parent = gui,
	})

	ContextActionService:BindAction("Airstrike", function(_, state)
		if state == Enum.UserInputState.Begin then
			callAirstrike()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.T, Enum.KeyCode.DPadRight)
	ContextActionService:SetTitle("Airstrike", "✈")
	ContextActionService:SetPosition("Airstrike", UDim2.new(1, -280, 1, -310))

	Remotes.AirstrikeMark.OnClientEvent:Connect(function(points, delay)
		if type(points) == "table" then
			markPoints(points, type(delay) == "number" and delay or 1.5)
		end
	end)

	task.spawn(function()
		while true do
			updateRadar()
			updateWidget()
			task.wait(0.25)
		end
	end)
end

return KillstreakController
