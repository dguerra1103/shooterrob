-- Bots: rellenan la partida cuando hay pocos jugadores (GameConfig.Bots). Llevan un arma de verdad
-- (los demás ven trazadoras, fogonazo y sonido como con un jugador), recorren el mapa con
-- PathfindingService, buscan enemigos con línea de visión y fallan más cuanto más lejos disparan.
-- Cuentan para el marcador por equipos y dan algo de XP y monedas, pero no para la clasificación global.
-- Solo durante la ronda; en "Escalada de armas" no hay bots. En Eliminación (NoRespawn) no reaparecen
-- hasta la ronda siguiente (Round llama a Bots.RespawnAll).
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local Combat = require(script.Parent.Combat)
local Loadout = require(script.Parent.Loadout)

local Bots = {}

local CONFIG = GameConfig.Bots
local NAMES = { "Tito", "Luna", "Max", "Kira", "Rocco", "Nova", "Pipo", "Zara", "Dante", "Mia", "Toby", "Vega" }

local folder
local agents = {} -- lista de bots activos
local nameIndex = 0

local function state()
	return ReplicatedStorage:GetAttribute("State")
end

local function noRespawn()
	return ReplicatedStorage:GetAttribute("NoRespawn") == true
end

local function teamMode()
	return ReplicatedStorage:GetAttribute("TeamMode") == true
end

-- ¿Cuántos bots hacen falta ahora mismo?
local function desiredCount()
	if not CONFIG.Enabled or state() ~= "Playing" or ReplicatedStorage:GetAttribute("Mode") == "GUN" then
		return 0
	end
	return math.max(0, CONFIG.FillTo - #Players:GetPlayers())
end

-- Equipo con menos miembros (jugadores + bots)
local function pickTeam()
	if not teamMode() then
		return nil
	end
	local best, bestCount = nil, math.huge
	for _, team in Teams:GetTeams() do
		local count = #team:GetPlayers()
		for _, agent in agents do
			if agent.Team == team then
				count += 1
			end
		end
		if count < bestCount then
			best, bestCount = team, count
		end
	end
	return best
end

local function mapPoints(predicate)
	local points = {}
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and predicate(d) then
				table.insert(points, d.Position)
			end
		end
	end
	return points
end

local function spawnPoint(team)
	local points = {}
	if team then
		points = mapPoints(function(d)
			return d:IsA("SpawnLocation") and d.TeamColor == team.TeamColor
		end)
	end
	if #points == 0 then
		points = mapPoints(function(d)
			return d.Name == "FFASpawn"
		end)
	end
	if #points == 0 then
		return Vector3.new(0, 10, 0)
	end
	return points[math.random(1, #points)] + Vector3.new(0, 4, 0)
end

-- Pinta al bot con los colores de su equipo (o de color aleatorio en todos contra todos)
local function makeDescription(team)
	local description = Instance.new("HumanoidDescription")
	local shirt = team and team.TeamColor.Color or Color3.fromHSV(math.random(), 0.6, 0.85)
	local skin = ({ Color3.fromRGB(255, 205, 160), Color3.fromRGB(200, 150, 110), Color3.fromRGB(140, 95, 65), Color3.fromRGB(255, 220, 190) })[math.random(1, 4)]
	description.HeadColor = skin
	description.LeftArmColor = skin
	description.RightArmColor = skin
	description.TorsoColor = shirt
	description.LeftLegColor = Color3.fromRGB(45, 48, 60)
	description.RightLegColor = Color3.fromRGB(45, 48, 60)
	return description
end

local function isEnemyOf(agent, otherTeam)
	if not teamMode() then
		return true
	end
	return agent.Team ~= otherTeam
end

-- Objetivos posibles: jugadores vivos fuera del menú y sin escudo, y bots enemigos
local function candidates(agent)
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local head = character and character:FindFirstChild("Head")
		if humanoid and head and humanoid.Health > 0 and not player:GetAttribute("InMenu")
			and not character:FindFirstChildOfClass("ForceField") and isEnemyOf(agent, player.Team) then
			table.insert(list, { Model = character, Humanoid = humanoid, Head = head })
		end
	end
	for _, other in agents do
		if other ~= agent and other.Humanoid and other.Humanoid.Health > 0 and isEnemyOf(agent, other.Team) then
			local head = other.Model:FindFirstChild("Head")
			if head then
				table.insert(list, { Model = other.Model, Humanoid = other.Humanoid, Head = head })
			end
		end
	end
	return list
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function canSee(agent, target)
	local head = agent.Model:FindFirstChild("Head")
	if not head then
		return false
	end
	local ignore = { agent.Model }
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	rayParams.FilterDescendantsInstances = ignore
	local direction = target.Head.Position - head.Position
	local hit = workspace:Raycast(head.Position, direction, rayParams)
	return hit == nil or hit.Instance:IsDescendantOf(target.Model)
end

local function findTarget(agent)
	local root = agent.Root
	local best, bestDistance = nil, CONFIG.Range
	for _, target in candidates(agent) do
		local distance = (target.Head.Position - root.Position).Magnitude
		if distance < bestDistance and canSee(agent, target) then
			best, bestDistance = target, distance
		end
	end
	return best, bestDistance
end

-- Camino hasta un punto al azar del mapa (o la zona activa en Zona de control)
local function pickGoal(agent)
	-- En Zona de control, la mitad de las veces van a la zona activa
	local zone = ReplicatedStorage:GetAttribute("ZonePosition")
	if typeof(zone) == "Vector3" and math.random() < 0.5 then
		return zone + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
	end
	local points = mapPoints(function(d)
		return d.Name == "FFASpawn"
	end)
	if #points == 0 then
		return nil
	end
	return points[math.random(1, #points)]
end

local function computePath(agent, goal)
	agent.Waypoints = nil
	agent.WaypointIndex = 0
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
	local ok = pcall(function()
		path:ComputeAsync(agent.Root.Position, goal)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		agent.Waypoints = path:GetWaypoints()
		agent.WaypointIndex = 1
	end
end

local function shoot(agent, target, distance)
	local tool = agent.Tool
	local def = Weapons.Get(agent.Weapon)
	if not tool or not tool.Parent or not def then
		return
	end
	-- Recarga de vez en cuando (pausa breve)
	agent.Shots += 1
	if agent.Shots >= def.MagSize then
		agent.Shots = 0
		agent.NextShot = os.clock() + def.ReloadTime
		return
	end
	local chance = math.clamp(CONFIG.Accuracy - distance * CONFIG.AccuracyFalloff, 0.06, CONFIG.Accuracy)
	local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
	if targetRoot and targetRoot.AssemblyLinearVelocity.Magnitude > 12 then
		chance *= 0.7 -- cuesta más acertar a quien se mueve rápido
	end
	local hit = math.random() < chance
	local endpoint
	if hit then
		endpoint = target.Head.Position + Vector3.new(math.random() - 0.5, -math.random() * 1.5, math.random() - 0.5)
		local damage = (distance > (def.FalloffStart or 100) and def.MinDamage or def.Damage) * CONFIG.DamageScale
		Combat.BotDamage(agent, target.Humanoid, damage, agent.Weapon)
	else
		local miss = Vector3.new(math.random() - 0.5, math.random() - 0.3, math.random() - 0.5).Unit * (2 + math.random() * 3)
		endpoint = target.Head.Position + miss
	end
	Remotes.ShotFX:FireAllClients(tool, { endpoint })
end

local function think(agent)
	local humanoid, root = agent.Humanoid, agent.Root
	if not humanoid or humanoid.Health <= 0 or not root or not root.Parent then
		return
	end
	local now = os.clock()
	local target, distance = findTarget(agent)
	if target then
		if agent.Target ~= target.Model then
			agent.Target = target.Model
			agent.NextShot = math.max(agent.NextShot, now + CONFIG.Reaction)
		end
		-- Mira al objetivo y se mueve un poco de lado mientras dispara
		local look = Vector3.new(target.Head.Position.X, root.Position.Y, target.Head.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, look)
		end
		if now >= agent.NextStrafe then
			agent.NextStrafe = now + 1.2 + math.random()
			humanoid:MoveTo(root.Position + root.CFrame.RightVector * (math.random() < 0.5 and -6 or 6))
		end
		if now >= agent.NextShot then
			local def = Weapons.Get(agent.Weapon)
			agent.NextShot = now + 1 / math.min(def and def.FireRate or 6, CONFIG.MaxFireRate) + math.random() * 0.12
			shoot(agent, target, distance)
		end
		return
	end
	agent.Target = nil
	-- Sin enemigos a la vista: seguir el camino o buscar uno nuevo
	local waypoints = agent.Waypoints
	if not waypoints or agent.WaypointIndex > #waypoints or now > agent.GoalDeadline then
		local goal = pickGoal(agent)
		agent.GoalDeadline = now + 12
		if goal and not agent.Computing then
			agent.Computing = true
			task.spawn(function()
				computePath(agent, goal)
				agent.Computing = false
				if not agent.Waypoints and agent.Humanoid then
					agent.Humanoid:MoveTo(goal)
				end
			end)
		end
		return
	end
	local waypoint = waypoints[agent.WaypointIndex]
	if (Vector3.new(waypoint.Position.X, root.Position.Y, waypoint.Position.Z) - root.Position).Magnitude < 3 then
		agent.WaypointIndex += 1
		return
	end
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		humanoid.Jump = true
	end
	humanoid:MoveTo(waypoint.Position)
end

local spawnAgent

-- Nombre que no lleve ya otro bot activo
local function nextName()
	for _ = 1, #NAMES do
		nameIndex = nameIndex % #NAMES + 1
		local name = "Bot " .. NAMES[nameIndex]
		if not Combat.BotsByName[name] then
			return name
		end
	end
	return "Bot " .. math.random(100, 999)
end

-- Animaciones R15 estándar de Roblox. El script Animate de los personajes es local y no corre en un
-- NPC, así que el servidor las reproduce (se replican a todos).
local ANIMS = {
	Idle = "rbxassetid://507766388",
	Run = "rbxassetid://507767714",
	Jump = "rbxassetid://507765000",
	Fall = "rbxassetid://507767968",
	Hold = "rbxassetid://507768375", -- brazo estirado sujetando el arma
}

local function animate(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local tracks = {}
	for key, id in ANIMS do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if ok and track then
			tracks[key] = track
		end
	end
	local current
	local function play(key, fade)
		local track = tracks[key]
		if track and current ~= track then
			if current then
				current:Stop(fade or 0.2)
			end
			current = track
			track.Looped = key ~= "Jump"
			track:Play(fade or 0.2)
		end
	end
	if tracks.Hold then
		tracks.Hold.Priority = Enum.AnimationPriority.Action
		tracks.Hold.Looped = true
		tracks.Hold:Play()
	end
	play("Idle")
	humanoid.Running:Connect(function(speed)
		play(speed > 0.5 and "Run" or "Idle")
		if tracks.Run then
			tracks.Run:AdjustSpeed(math.max(speed / 16, 0.5))
		end
	end)
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			play("Jump", 0.1)
		elseif new == Enum.HumanoidStateType.Freefall then
			play("Fall", 0.2)
		elseif new == Enum.HumanoidStateType.Landed then
			play("Idle", 0.1)
		end
	end)
end

spawnAgent = function(agent)
	if agent.Spawning then
		return false
	end
	agent.Team = agent.Team or pickTeam()
	agent.Spawning = true
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(makeDescription(agent.Team), Enum.HumanoidRigType.R15)
	end)
	if not ok then
		ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(makeDescription(agent.Team), Enum.HumanoidRigType.R15)
		end)
	end
	agent.Spawning = false
	if not ok or not model then
		warn("[Bots] No se pudo crear el bot:", model)
		return false
	end
	-- Lo quitaron (fin de ronda) mientras se creaba
	if not table.find(agents, agent) or not folder then
		model:Destroy()
		return false
	end
	local localAnimate = model:FindFirstChild("Animate")
	if localAnimate then
		localAnimate:Destroy()
	end
	model.Name = agent.Name
	model:SetAttribute("Bot", true)
	model:SetAttribute("Team", agent.Team and agent.Team.Name or "")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	humanoid.DisplayName = agent.Name
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = CONFIG.WalkSpeed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	model:PivotTo(CFrame.new(spawnPoint(agent.Team)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	agent.Model, agent.Humanoid, agent.Root = model, humanoid, root
	animate(humanoid)
	agent.Weapon = CONFIG.Weapons[math.random(1, #CONFIG.Weapons)]
	agent.Tool = Loadout.MakeTool(agent.Weapon, "Default")
	agent.Tool.Parent = model
	humanoid:EquipTool(agent.Tool)
	agent.Shots, agent.NextShot, agent.NextStrafe, agent.GoalDeadline = 0, 0, 0, 0
	agent.Waypoints, agent.Target = nil, nil

	Combat.WatchHumanoid(humanoid, nil, agent.Name, agent)
	humanoid.Died:Connect(function()
		agent.Humanoid = nil
		task.delay(3, function()
			model:Destroy()
		end)
		task.delay(GameConfig.RespawnTime + 1, function()
			if table.find(agents, agent) and not agent.Humanoid and desiredCount() >= #agents and not noRespawn() then
				spawnAgent(agent)
			end
		end)
	end)
	return true
end

local function removeAgent(agent)
	local index = table.find(agents, agent)
	if index then
		table.remove(agents, index)
	end
	Combat.BotsByName[agent.Name] = nil
	if agent.Model then
		agent.Model:Destroy()
	end
end

-- Ajusta el número de bots. En plena ronda de Eliminación no entran bots nuevos.
local function balance()
	local desired = desiredCount()
	while #agents < desired and not noRespawn() and state() == "Playing" do
		local agent = { Name = nextName() }
		table.insert(agents, agent)
		Combat.BotsByName[agent.Name] = agent
		if not spawnAgent(agent) then
			removeAgent(agent)
			break
		end
		desired = desiredCount()
	end
	if #agents > desired then
		removeAgent(agents[#agents])
	end
end

-- Nueva ronda de Eliminación: los muertos reaparecen y los vivos vuelven a su base con la vida llena
function Bots.RespawnAll()
	for _, agent in table.clone(agents) do
		if agent.Humanoid and agent.Humanoid.Health > 0 and agent.Model then
			agent.Humanoid.Health = agent.Humanoid.MaxHealth
			agent.Model:PivotTo(CFrame.new(spawnPoint(agent.Team)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
			agent.Waypoints, agent.Target, agent.Shots = nil, nil, 0
		elseif not agent.Spawning then
			task.spawn(spawnAgent, agent)
		end
	end
end

-- Al cambiar de modo o de equipos, los bots vuelven a elegir equipo
function Bots.Reset()
	for i = #agents, 1, -1 do
		removeAgent(agents[i])
	end
end

function Bots.Init()
	if not CONFIG.Enabled then
		return
	end
	folder = Instance.new("Folder")
	folder.Name = "Bots"
	folder.Parent = workspace
	ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
		if state() ~= "Playing" then
			Bots.Reset()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(balance)
			if not ok then
				warn("[Bots] balance:", err)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.15)
			for _, agent in table.clone(agents) do
				local ok, err = pcall(think, agent)
				if not ok then
					warn("[Bots] think:", err)
				end
			end
		end
	end)
end

Bots.Agents = agents
return Bots
