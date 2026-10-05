-- Efectos del mundo en el cliente:
--  * Piezas del mapa con atributo Spin (grados/seg) giran y con Bob (studs) flotan
--  * Con Orbit (grados/seg) giran alrededor de OrbitCenter sobre el eje OrbitAxis (la noria);
--    con OrbitUpright solo se mueven sin girar (las cabinas siguen derechas), colgando de OrbitAnchor
--  * Contorno de color en los compañeros de equipo (visible a través de paredes)
--  * Oculta el nombre de los enemigos
--  * Explosión de partículas cuando alguien es eliminado
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Effects = require(script.Parent.Effects)
local ClientState = require(script.Parent.ClientState)
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer

local WorldFX = {}

local animated = {} -- [part] = { Base = CFrame, Spin = number, Bob = number, Phase = number }

local function track(inst)
	-- (los efectos sueltos de ClientFX nunca se animan aquí: se descartan lo antes posible)
	if not inst:IsA("BasePart") or (inst.Parent and inst.Parent.Name == "ClientFX") then
		return
	end
	local spin = inst:GetAttribute("Spin")
	local bob = inst:GetAttribute("Bob")
	local blink = inst:GetAttribute("Blink")
	local sweep = inst:GetAttribute("Sweep")
	local orbit = inst:GetAttribute("Orbit")
	if spin or bob or blink or sweep or orbit then
		local center, axis = inst:GetAttribute("OrbitCenter"), inst:GetAttribute("OrbitAxis")
		animated[inst] = {
			Base = inst.CFrame,
			Spin = spin or 0,
			Bob = bob or 0,
			Blink = blink,
			Sweep = sweep,
			Orbit = (orbit and typeof(center) == "Vector3" and typeof(axis) == "Vector3" and axis.Magnitude > 0) and orbit or nil,
			OrbitCenter = center,
			OrbitAxis = typeof(axis) == "Vector3" and axis.Magnitude > 0 and axis.Unit or nil,
			OrbitUpright = inst:GetAttribute("OrbitUpright") == true,
			OrbitAnchor = typeof(inst:GetAttribute("OrbitAnchor")) == "Vector3" and inst:GetAttribute("OrbitAnchor") or nil,
			BaseTransparency = inst.Transparency,
			Phase = math.random() * 10,
		}
	end
end

local frame = 0
local function animate()
	local t = os.clock()
	-- Lo que gira despacio (la noria) se mueve 1 de cada 2 fotogramas (1 de cada 4 en calidad Baja)
	frame += 1
	local orbitNow = frame % (ClientState.EffectiveQuality == "Baja" and 4 or 2) == 0
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
		if info.Orbit then
			if not orbitNow then
				continue
			end
			local turn = CFrame.fromAxisAngle(info.OrbitAxis, math.rad(info.Orbit * t))
			-- (con ancla, la pieza sigue a su punto de enganche sin girar su propio desplazamiento)
			local anchor = info.OrbitAnchor or info.Base.Position
			local position = info.OrbitCenter + turn * (anchor - info.OrbitCenter) + (info.Base.Position - anchor)
			local rotation = info.Base - info.Base.Position
			part.CFrame = CFrame.new(position) * (info.OrbitUpright and rotation or (turn * rotation))
		elseif info.Sweep then
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

local ENEMY_COLOR = Color3.fromRGB(255, 64, 52)

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
	-- Enemigos: un contorno rojo fino que solo se ve donde ya los ves (no atraviesa paredes). Así se
	-- distinguen al momento del fondo, también en mapas oscuros o con ropa del color de las paredes
	local outline = character:FindFirstChild("EnemyOutline")
	local enemy = not isTeammate and not isSelf and GameConfig.EnemyOutline ~= false and humanoid.Health > 0
	if enemy then
		if not outline then
			outline = Instance.new("Highlight")
			outline.Name = "EnemyOutline"
			outline.FillTransparency = 1
			outline.OutlineTransparency = 0.45
			outline.OutlineColor = ENEMY_COLOR
			outline.DepthMode = Enum.HighlightDepthMode.Occluded
			outline.Parent = character
			-- (al caer se quita: un cuerpo ya no es una amenaza)
			humanoid.Died:Connect(function()
				if outline.Parent then
					outline:Destroy()
				end
			end)
		end
	elseif outline then
		outline:Destroy()
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
		local function watchBot(model)
			model:WaitForChild("Humanoid", 10)
			styleBot(model)
			-- (en la Infección un bot cambia de bando al ser infectado)
			model:GetAttributeChangedSignal("Team"):Connect(function()
				styleBot(model)
			end)
		end
		bots.ChildAdded:Connect(watchBot)
		for _, model in bots:GetChildren() do
			task.spawn(watchBot, model)
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
