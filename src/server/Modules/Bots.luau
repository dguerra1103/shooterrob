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
local statsFolder -- ReplicatedStorage.BotStats: una carpeta por bot con Team, Kills, Deaths y Score (marcador)
local agents = {} -- lista de bots activos
local nameIndex = 0

local function state()
	return ReplicatedStorage:GetAttribute("State")
end

local function noRespawn()
	return ReplicatedStorage:GetAttribute("NoRespawn") == true
end

-- Cuenta atrás de Eliminación: todos quietos y sin disparar
local function frozen()
	return ReplicatedStorage:GetAttribute("Frozen") == true
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

-- Puntos del mapa (se guardan hasta que cambia el mapa: recorrer todas las piezas es caro)
local cachedMap, spawnsByColor, ffaPoints = nil, {}, {}
local function refreshPoints()
	local map = workspace:FindFirstChild("Map")
	if map == cachedMap and map ~= nil and map.Parent ~= nil then
		return
	end
	cachedMap, spawnsByColor, ffaPoints = map, {}, {}
	if not map then
		return
	end
	for _, d in map:GetDescendants() do
		if d:IsA("SpawnLocation") then
			local key = d.TeamColor.Name
			spawnsByColor[key] = spawnsByColor[key] or {}
			table.insert(spawnsByColor[key], d.Position)
		elseif d:IsA("BasePart") and d.Name == "FFASpawn" then
			table.insert(ffaPoints, d.Position)
		end
	end
end

local function spawnPoint(team)
	refreshPoints()
	local points = team and spawnsByColor[team.TeamColor.Name] or {}
	if #points == 0 then
		points = ffaPoints
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
	if typeof(zone) == "Vector3" and math.random() < 0.75 then
		return zone + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
	end
	refreshPoints()
	if #ffaPoints == 0 then
		return nil
	end
	return ffaPoints[math.random(1, #ffaPoints)]
end

local function computePath(agent, goal)
	agent.Waypoints = nil
	agent.WaypointIndex = 0
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 6,
		Costs = { CrackedLava = math.huge }, -- nunca por la lava
	})
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
	-- Dificultad según el rango del jugador al que disparan (contra otros bots, normal)
	local targetPlayer = Players:GetPlayerFromCharacter(target.Model)
	local skill = targetPlayer and CONFIG.SkillByRank and CONFIG.SkillByRank[targetPlayer:GetAttribute("Rank") or 1] or 1
	local accuracy = math.min(0.95, CONFIG.Accuracy * skill)
	local chance = math.clamp(accuracy - distance * CONFIG.AccuracyFalloff, 0.06, accuracy)
	local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
	if targetRoot and targetRoot.AssemblyLinearVelocity.Magnitude > 12 then
		chance *= 0.7 -- cuesta más acertar a quien se mueve rápido
	end
	local hit = math.random() < chance
	local endpoint
	if hit then
		endpoint = target.Head.Position + Vector3.new(math.random() - 0.5, -math.random() * 1.5, math.random() - 0.5)
		local damage = (distance > (def.FalloffStart or 100) and def.MinDamage or def.Damage) * CONFIG.DamageScale * skill
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
	if frozen() then
		humanoid:MoveTo(root.Position)
		return
	end
	local now = os.clock()
	local target, distance = findTarget(agent)
	if target then
		if agent.Target ~= target.Model then
			agent.Target = target.Model
			agent.NextShot = math.max(agent.NextShot, now + CONFIG.Reaction)
		end
		-- Mira al objetivo y se mueve un poco de lado mientras dispara (sin girar hacia donde camina)
		humanoid.AutoRotate = false
		local look = Vector3.new(target.Head.Position.X, root.Position.Y, target.Head.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, look)
		end
		if now >= agent.NextStrafe then
			agent.NextStrafe = now + 1.2 + math.random()
			humanoid:MoveTo(root.Position + root.CFrame.RightVector * (math.random() < 0.5 and -6 or 6))
			-- De vez en cuando salta mientras pelea (como un jugador)
			if math.random() < CONFIG.JumpChance then
				humanoid.Jump = true
			end
		end
		if now >= agent.NextShot then
			local def = Weapons.Get(agent.Weapon)
			agent.NextShot = now + 1 / math.min(def and def.FireRate or 6, CONFIG.MaxFireRate) + math.random() * 0.12
			shoot(agent, target, distance)
		end
		return
	end
	agent.Target = nil
	humanoid.AutoRotate = true
	-- Sin enemigos a la vista: seguir el camino o buscar uno nuevo
	local waypoints = agent.Waypoints
	if agent.Computing then
		return
	end
	if not waypoints or agent.WaypointIndex > #waypoints or now > agent.GoalDeadline then
		if now < agent.GoalDeadline and not waypoints then
			return -- sin camino: va en línea recta un rato antes de volver a intentarlo
		end
		local goal = pickGoal(agent)
		agent.GoalDeadline = now + 12
		if goal then
			agent.Computing = true
			task.spawn(function()
				computePath(agent, goal)
				agent.Computing = false
				if not agent.Waypoints and agent.Humanoid then
					agent.Humanoid:MoveTo(goal)
					agent.GoalDeadline = os.clock() + 3
				end
			end)
		else
			agent.GoalDeadline = now + 3
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

local spawnAgent, safeSpawn

-- Estadísticas del bot para el marcador (Tab) de los clientes
local function statsOf(agent)
	if not statsFolder or not table.find(agents, agent) then
		return nil
	end
	local entry = statsFolder:FindFirstChild(agent.Name)
	if not entry then
		entry = Instance.new("Folder")
		entry.Name = agent.Name
		entry:SetAttribute("Kills", 0)
		entry:SetAttribute("Deaths", 0)
		entry:SetAttribute("Score", 0)
		entry.Parent = statsFolder
	end
	entry:SetAttribute("Team", agent.Team and agent.Team.Name or "")
	return entry
end

-- Suma a una estadística del bot (Kills, Deaths o Score); lo llama Round al registrar bajas
function Bots.AddStat(agent, field, amount)
	local entry = agent and statsOf(agent)
	if entry then
		entry:SetAttribute(field, (entry:GetAttribute(field) or 0) + amount)
	end
end


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
	statsOf(agent)
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
				safeSpawn(agent)
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
	if statsFolder then
		local entry = statsFolder:FindFirstChild(agent.Name)
		if entry then
			entry:Destroy()
		end
	end
	Combat.BotsByName[agent.Name] = nil
	if agent.Model then
		agent.Model:Destroy()
	end
end

-- Crea el bot sin que un error deje un hueco fantasma: si falla, el bot se quita de la lista
safeSpawn = function(agent)
	if agent.Spawning then
		return true -- ya se está creando
	end
	local ok, spawned = pcall(spawnAgent, agent)
	if not ok then
		warn("[Bots] spawn:", spawned)
		agent.Spawning = false
	end
	if not (ok and spawned) then
		if agent.Model and agent.Model.Parent and not agent.Humanoid then
			agent.Model:Destroy()
		end
		removeAgent(agent)
		return false
	end
	return true
end

-- Bot a quitar: del equipo con más miembros (jugadores + bots) para no desequilibrar
local function botToRemove()
	if not teamMode() then
		return agents[#agents]
	end
	local best, bestCount = nil, -1
	for _, team in Teams:GetTeams() do
		local count = #team:GetPlayers()
		local candidate
		for _, agent in agents do
			if agent.Team == team then
				count += 1
				candidate = agent
			end
		end
		if candidate and count > bestCount then
			best, bestCount = candidate, count
		end
	end
	return best or agents[#agents]
end

-- Ajusta el número de bots. En plena ronda de Eliminación no entran bots nuevos.
local function balance()
	local desired = desiredCount()
	while #agents < desired and not noRespawn() and state() == "Playing" do
		local agent = { Name = nextName() }
		table.insert(agents, agent)
		Combat.BotsByName[agent.Name] = agent
		if not safeSpawn(agent) then
			break
		end
		desired = desiredCount()
	end
	if #agents > desired then
		if not noRespawn() then
			removeAgent(botToRemove())
		else
			-- En plena ronda de Eliminación solo se quita un bot ya eliminado (no se le quita un luchador
			-- a un equipo a mitad de ronda); el resto se ajusta en la preparación de la siguiente
			for i = #agents, 1, -1 do
				if not agents[i].Humanoid and not agents[i].Spawning then
					removeAgent(agents[i])
					break
				end
			end
		end
	end
end

-- Nueva ronda de Eliminación: los muertos reaparecen y los vivos vuelven a su base con la vida llena
function Bots.RespawnAll()
	for _, agent in table.clone(agents) do
		if agent.Humanoid and agent.Humanoid.Health > 0 and agent.Model then
			agent.Humanoid.Health = agent.Humanoid.MaxHealth
			agent.Model:PivotTo(CFrame.new(spawnPoint(agent.Team)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
			agent.Waypoints, agent.Target, agent.Shots, agent.GoalDeadline = nil, nil, 0, 0
		elseif not agent.Spawning then
			task.spawn(safeSpawn, agent)
		end
	end
end

-- Fin de la preparación de Eliminación: reaparece cualquier bot que siga muerto
function Bots.RespawnDead()
	for _, agent in table.clone(agents) do
		if not agent.Humanoid and not agent.Spawning then
			task.spawn(safeSpawn, agent)
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
	statsFolder = Instance.new("Folder")
	statsFolder.Name = "BotStats"
	statsFolder.Parent = ReplicatedStorage
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
