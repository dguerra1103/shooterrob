-- Efectos del mundo en el cliente:
--  * Piezas del mapa con atributo Spin (grados/seg) giran y con Bob (studs) flotan
--  * Contorno de color en los compañeros de equipo (visible a través de paredes)
--  * Oculta el nombre de los enemigos
--  * Explosión de partículas cuando alguien es eliminado
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer

local WorldFX = {}

local animated = {} -- [part] = { Base = CFrame, Spin = number, Bob = number, Phase = number }

local function track(inst)
	if not inst:IsA("BasePart") then
		return
	end
	local spin = inst:GetAttribute("Spin")
	local bob = inst:GetAttribute("Bob")
	if spin or bob then
		animated[inst] = { Base = inst.CFrame, Spin = spin or 0, Bob = bob or 0, Phase = math.random() * 10 }
	end
end

local function animate()
	local t = os.clock()
	for part, info in animated do
		if not part.Parent then
			animated[part] = nil
			continue
		end
		local position = info.Base.Position + Vector3.new(0, math.sin(t * 1.5 + info.Phase) * info.Bob, 0)
		local rotation = info.Base - info.Base.Position
		-- Giro alrededor del eje Y del mundo que pasa por la pieza
		part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(info.Spin * t), 0) * rotation
	end
end

---------------------------------------------------------------------------
-- Jugadores
---------------------------------------------------------------------------

local function teamColorOf(other)
	return other and other.Team and other.TeamColor.Color or Color3.fromRGB(255, 200, 60)
end

local function styleCharacter(other, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local isTeammate = player.Team ~= nil and other.Team == player.Team
	local highlight = character:FindFirstChild("TeamHighlight")
	if isTeammate and other ~= player then
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "TeamHighlight"
			highlight.FillTransparency = 1
			highlight.OutlineTransparency = 0.2
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = character
		end
		highlight.OutlineColor = teamColorOf(other)
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	else
		if highlight then
			highlight:Destroy()
		end
		if other ~= player then
			-- Sin nombre sobre los enemigos: hay que encontrarlos
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
end

local function watchDeath(character, color)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
		if root then
			Effects.DeathBurst(root.Position, typeof(color) == "function" and color() or color)
		end
	end)
end

local function onCharacter(other, character)
	task.spawn(watchDeath, character, function()
		return teamColorOf(other)
	end)
	character:WaitForChild("Humanoid", 10)
	styleCharacter(other, character)
end

local function onPlayer(other)
	other.CharacterAdded:Connect(function(character)
		onCharacter(other, character)
	end)
	if other.Character then
		task.spawn(onCharacter, other, other.Character)
	end
	other:GetPropertyChangedSignal("Team"):Connect(function()
		if other.Character then
			styleCharacter(other, other.Character)
		end
	end)
end

local function restyleAll()
	for _, other in Players:GetPlayers() do
		if other.Character then
			styleCharacter(other, other.Character)
		end
	end
end

function WorldFX.Init()
	-- Animaciones del mapa
	for _, inst in workspace:GetDescendants() do
		track(inst)
	end
	workspace.DescendantAdded:Connect(track)
	RunService.RenderStepped:Connect(animate)

	-- Jugadores
	for _, other in Players:GetPlayers() do
		onPlayer(other)
	end
	Players.PlayerAdded:Connect(onPlayer)
	player:GetPropertyChangedSignal("Team"):Connect(restyleAll)

	-- Muñecos de práctica
	local function watchDummies(folder)
		for _, dummy in folder:GetChildren() do
			task.spawn(watchDeath, dummy, Color3.fromRGB(255, 200, 60))
		end
		folder.ChildAdded:Connect(function(dummy)
			task.spawn(watchDeath, dummy, Color3.fromRGB(255, 200, 60))
		end)
	end
	local dummies = workspace:FindFirstChild("Dummies")
	if dummies then
		watchDummies(dummies)
	end
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Dummies" then
			watchDummies(child)
		end
	end)
end

return WorldFX
