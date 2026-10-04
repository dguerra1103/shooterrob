-- Efectos del mundo en el cliente:
--  * Piezas del mapa con atributo Spin (grados/seg) giran y con Bob (studs) flotan
--  * Contorno de color en los compañeros de equipo (visible a través de paredes)
--  * Oculta el nombre de los enemigos
--  * Explosión de partículas cuando alguien es eliminado
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Effects = require(script.Parent.Effects)
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer

local WorldFX = {}

local animated = {} -- [part] = { Base = CFrame, Spin = number, Bob = number, Phase = number }

local function track(inst)
	if not inst:IsA("BasePart") then
		return
	end
	local spin = inst:GetAttribute("Spin")
	local bob = inst:GetAttribute("Bob")
	local blink = inst:GetAttribute("Blink")
	local sweep = inst:GetAttribute("Sweep")
	if spin or bob or blink or sweep then
		animated[inst] = {
			Base = inst.CFrame,
			Spin = spin or 0,
			Bob = bob or 0,
			Blink = blink,
			Sweep = sweep,
			BaseTransparency = inst.Transparency,
			Phase = math.random() * 10,
		}
	end
end

local function animate()
	local t = os.clock()
	for part, info in animated do
		if not part.Parent then
			animated[part] = nil
			continue
		end
		if info.Blink then
			-- Baliza que parpadea
			local on = math.sin((t + info.Phase) * math.pi * 2 / info.Blink) > 0
			part.Transparency = on and info.BaseTransparency or 0.95
		end
		if info.Sweep then
			-- Haz de luz que barre a un lado y a otro desde su base
			local pivot = (info.Base * CFrame.new(0, -part.Size.Y / 2, 0)).Position
			local angle = math.rad(info.Sweep) * math.sin(t * 0.4 + info.Phase)
			part.CFrame = CFrame.new(pivot) * CFrame.Angles(0, angle, 0) * (CFrame.new(pivot):Inverse() * info.Base)
		elseif info.Spin ~= 0 or info.Bob ~= 0 then
			local position = info.Base.Position + Vector3.new(0, math.sin(t * 1.5 + info.Phase) * info.Bob, 0)
			local rotation = info.Base - info.Base.Position
			-- Giro alrededor del eje Y del mundo que pasa por la pieza
			part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(info.Spin * t), 0) * rotation
		end
	end
end

---------------------------------------------------------------------------
-- Jugadores
---------------------------------------------------------------------------

local function teamColorOf(other)
	return other and other.Team and other.TeamColor.Color or Color3.fromRGB(255, 200, 60)
end

-- Compañeros: contorno del color del equipo y nombre visible. Enemigos: sin nombre.
local function applyStyle(character, isTeammate, isSelf, color)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local highlight = character:FindFirstChild("TeamHighlight")
	if isTeammate and not isSelf then
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "TeamHighlight"
			highlight.FillTransparency = 1
			highlight.OutlineTransparency = 0.2
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = character
		end
		highlight.OutlineColor = color
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	else
		if highlight then
			highlight:Destroy()
		end
		if not isSelf then
			-- Sin nombre sobre los enemigos: hay que encontrarlos
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
end

local function styleCharacter(other, character)
	applyStyle(character, player.Team ~= nil and other.Team == player.Team, other == player, teamColorOf(other))
end

-- Bots (carpeta workspace.Bots): el servidor les pone el atributo Team
local function styleBot(model)
	local teamName = model:GetAttribute("Team")
	local team = teamName and teamName ~= "" and Teams:FindFirstChild(teamName)
	local isTeammate = player.Team ~= nil and team == player.Team
	applyStyle(model, isTeammate, false, team and team:IsA("Team") and team.TeamColor.Color or Color3.fromRGB(255, 200, 60))
end

local function onCharacter(other, character)
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
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			styleBot(model)
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
	task.spawn(function()
		local bots = workspace:WaitForChild("Bots", 30)
		if not bots then
			return
		end
		bots.ChildAdded:Connect(function(model)
			model:WaitForChild("Humanoid", 10)
			styleBot(model)
		end)
		for _, model in bots:GetChildren() do
			task.spawn(styleBot, model)
		end
	end)

	-- Efecto de eliminación (lo decide el servidor: el que tenga equipado quien hizo la baja)
	Remotes.KillFX.OnClientEvent:Connect(function(position, effectId, color)
		if typeof(position) == "Vector3" and type(effectId) == "string" then
			Effects.KillEffect(effectId, position, typeof(color) == "Color3" and color or nil)
		end
	end)
end

return WorldFX
