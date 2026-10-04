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
local Pumpkins = require(script.Parent.Pumpkins)
local Loadout = require(script.Parent.Loadout)
local Zombie = require(script.Parent.Zombie)
local Grenades = require(script.Parent.Grenades)
local SpawnPicker = require(script.Parent.SpawnPicker)
local Domination = require(script.Parent.Domination)
local Outfits = require(Shared.Outfits)
local Shop = require(Shared.Shop)

-- Trajes que pueden llevar los bots (los de la tienda: así se ven en partida)
local BOT_OUTFITS = {}
for id in Shop.OutfitPrices do
	if Outfits.List[id] and not Outfits.List[id].Event then
		table.insert(BOT_OUTFITS, id)
	end
end
table.sort(BOT_OUTFITS)
-- Skins de arma que pueden llevar (las de la tienda)
local BOT_SKINS = {}
for id in Shop.SkinPrices do
	table.insert(BOT_SKINS, id)
end
table.sort(BOT_SKINS)
-- Colgantes de arma que pueden llevar
local Charms = require(Shared.Charms)
local BOT_CHARMS = {}
for id, charm in Charms.List do
	if charm.Price then
		table.insert(BOT_CHARMS, id)
	end
end
table.sort(BOT_CHARMS)

local Bots = {}

local CONFIG = GameConfig.Bots
local NAMES = { "Tito", "Luna", "Max", "Kira", "Rocco", "Nova", "Pipo", "Zara", "Dante", "Mia", "Toby", "Vega", "Bruno", "Sofi", "Leo", "Iris", "Hugo", "Nala", "Thor", "Cleo" }

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
	-- (en la Escalada de armas también: son rivales para subir de arma, aunque ellos no suben)
	if not CONFIG.Enabled or state() ~= "Playing" then
		return 0
	end
	return math.max(0, CONFIG.FillTo - #Players:GetPlayers())
end

-- Equipo con menos miembros (jugadores + bots)
local function pickTeam()
	if not teamMode() then
		return nil
	end
	-- Infección: antes de la infección, superviviente (equipo A); después, zombi (equipo B)
	local infection = ReplicatedStorage:GetAttribute("Infection")
	if infection then
		return Teams:FindFirstChild(ReplicatedStorage:GetAttribute(infection == "On" and "TeamB" or "TeamA") or "")
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
local cachedMap, spawnsByColor, ffaPoints, botSpots = nil, {}, {}, {}
local function refreshPoints()
	local map = workspace:FindFirstChild("Map")
	if map == cachedMap and map ~= nil and map.Parent ~= nil then
		return
	end
	cachedMap, spawnsByColor, ffaPoints, botSpots = map, {}, {}, {}
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
		elseif d:IsA("BasePart") and d.Name == "BotSpot" then
			table.insert(botSpots, { Position = d.Position, Look = d:GetAttribute("Look") })
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
local function makeDescription(team, zombie)
	local description = Instance.new("HumanoidDescription")
	local shirt = team and team.TeamColor.Color or Color3.fromHSV(math.random(), 0.6, 0.85)
	local skin = ({ Color3.fromRGB(255, 205, 160), Color3.fromRGB(200, 150, 110), Color3.fromRGB(140, 95, 65), Color3.fromRGB(255, 220, 190) })[math.random(1, 4)]
	if zombie then
		skin = Zombie.Skin
	end
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
			table.insert(list, { Model = character, Humanoid = humanoid, Head = head, Wanted = (player:GetAttribute("Bounty") or 0) > 0 })
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

-- ¿Se puede pisar ahí? (no agua ni lava). Sin nada debajo cuenta como sí (como antes): solo evita
-- que se tiren al agua del canal o a la lava persiguiendo o esquivando.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
local function safeGround(position)
	local map = workspace:FindFirstChild("Map")
	if not map then
		return true
	end
	groundParams.FilterDescendantsInstances = { map, workspace.Terrain }
	local hit = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -9, 0), groundParams)
	return not hit or (hit.Material ~= Enum.Material.Water and hit.Material ~= Enum.Material.CrackedLava)
end

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

-- Visión: los bots no ven por la espalda. Se fijan en lo que tienen delante (cono de VISION_ANGLE
-- grados), en quien está muy cerca, en quien les acaba de disparar y en con quien ya peleaban.
-- Así flanquear y atacar por detrás funciona, como contra una persona.
local VISION_DOT = math.cos(math.rad(70)) -- 140° en total
local NOTICE_DISTANCE = 14

-- ¿Le ha disparado este objetivo hace poco?
local function hitBy(agent, target)
	local humanoid = agent.Humanoid
	local hitTime = humanoid and humanoid:GetAttribute("LastHitTime")
	if not hitTime or os.clock() - hitTime > 3 then
		return false
	end
	local attackerId = humanoid:GetAttribute("LastAttacker")
	if attackerId then
		local player = Players:GetPlayerFromCharacter(target.Model)
		return player ~= nil and player.UserId == attackerId
	end
	return humanoid:GetAttribute("LastBot") == target.Model.Name
end

local function notices(agent, target)
	if agent.Target == target.Model or target.Distance < NOTICE_DISTANCE then
		return true
	end
	local offset = target.Head.Position - agent.Root.Position
	if offset.Magnitude > 0 and agent.Root.CFrame.LookVector:Dot(offset.Unit) > VISION_DOT then
		return true
	end
	return hitBy(agent, target)
end

-- El enemigo visible más cercano: se ordenan por distancia y solo se lanzan rayos hasta encontrar
-- uno a la vista (antes se comprobaban todos)
local function findTarget(agent)
	local root = agent.Root
	local inRange = {}
	for _, target in candidates(agent) do
		local distance = (target.Head.Position - root.Position).Magnitude
		if distance < CONFIG.Range then
			target.Distance = distance
			table.insert(inRange, target)
		end
	end
	-- (el buscado, "SE BUSCA", atrae a los bots: cuenta como si estuviera más cerca)
	table.sort(inRange, function(x, y)
		return x.Distance * (x.Wanted and 0.6 or 1) < y.Distance * (y.Wanted and 0.6 or 1)
	end)
	for _, target in inRange do
		if notices(agent, target) and canSee(agent, target) then
			return target, target.Distance
		end
	end
	return nil, CONFIG.Range
end

-- Le han disparado y no ve a nadie: se gira hacia el disparo y va a ver qué pasa
local function checkAlert(agent, now)
	local humanoid, root = agent.Humanoid, agent.Root
	local hitTime = humanoid:GetAttribute("LastHitTime")
	if not hitTime or hitTime == agent.LastAlert or now - hitTime > 2 then
		return
	end
	agent.LastAlert = hitTime
	local source
	local attackerId = humanoid:GetAttribute("LastAttacker")
	if attackerId then
		local attacker = Players:GetPlayerByUserId(attackerId)
		source = attacker and attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	else
		local other = Combat.BotsByName[humanoid:GetAttribute("LastBot") or ""]
		source = other and other.Root
	end
	if source and source.Parent then
		local look = Vector3.new(source.Position.X, root.Position.Y, source.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, look)
		end
		agent.AlertPosition = source.Position
		agent.AlertTime = now
		agent.GoalDeadline = 0 -- (busca camino nuevo ya)
		agent.Waypoints = nil
		humanoid:MoveTo(root.Position) -- (se para a mirar)
	end
end

-- Captura la bandera: si lleva la bandera, a casa; si no, a devolver la suya caída, a perseguir a
-- quien se la lleva o a por la enemiga (ver Flags: FlagPos_/FlagHome_/FlagState_)
local function flagGoal(agent)
	if ReplicatedStorage:GetAttribute("Mode") ~= "CTF" or not agent.Team then
		return nil
	end
	local own = agent.Team.Name
	local enemy
	for _, team in Teams:GetTeams() do
		if team ~= agent.Team then
			enemy = team.Name
		end
	end
	if agent.CarryingFlag then
		return ReplicatedStorage:GetAttribute("FlagHome_" .. own)
	end
	local ownState = ReplicatedStorage:GetAttribute("FlagState_" .. own)
	if (ownState == "Dropped" or ownState == "Carried") and math.random() < 0.6 then
		return ReplicatedStorage:GetAttribute("FlagPos_" .. own)
	end
	if enemy and math.random() < 0.65 then
		return ReplicatedStorage:GetAttribute("FlagPos_" .. enemy)
	end
	return nil
end

local laneGoal, bestIntel, chooseRole -- (más abajo)

-- Adónde ir: objetivo del modo, alerta, pista del equipo o su carril
local function pickGoal(agent)
	agent.SpotLook = nil -- (solo vale si el objetivo nuevo es un puesto de vigilancia)
	local flagTarget = flagGoal(agent)
	if typeof(flagTarget) == "Vector3" then
		return flagTarget, true
	end
	-- Le dispararon desde donde no veía: va hacia allí
	if agent.AlertPosition then
		local alert, fresh = agent.AlertPosition, os.clock() - (agent.AlertTime or 0) < 5
		agent.AlertPosition = nil
		if fresh then
			return alert, true
		end
	end
	-- Calabazas: casi siempre van a por la calabaza más cercana que haya
	if ReplicatedStorage:GetAttribute("Mode") == "CAL" and agent.Root and math.random() < 0.8 then
		local pumpkin = Pumpkins.Nearest(agent.Root.Position)
		if pumpkin then
			return pumpkin, true
		end
	end
	-- Dominio: defienden su bandera si se la están quitando; si no, a por las que no son suyas (casi
	-- siempre la más cercana; los agresivos, a veces la del fondo). El tirador a veces guarda su línea.
	if ReplicatedStorage:GetAttribute("Mode") == "DOM" and agent.Root and agent.Team then
		local flags = Domination.Points()
		local defend, targets = nil, {}
		for _, flag in flags do
			if flag.Owner == agent.Team and flag.Capturing and flag.Capturing ~= agent.Team then
				defend = flag
			elseif flag.Owner ~= agent.Team then
				table.insert(targets, flag)
			end
		end
		local chosen
		if defend and math.random() < 0.7 then
			chosen = defend
		elseif #targets > 0 and not (agent.Role == "Tirador" and math.random() < 0.5) then
			table.sort(targets, function(x, y)
				return (x.Position - agent.Root.Position).Magnitude < (y.Position - agent.Root.Position).Magnitude
			end)
			local aggressive = agent.Role == "Subfusil" or agent.Role == "Escopeta"
			chosen = (aggressive and math.random() < 0.35) and targets[#targets] or targets[1]
		end
		if chosen then
			local spread = chosen.Radius * 0.5
			return chosen.Position + Vector3.new((math.random() - 0.5) * spread, 0, (math.random() - 0.5) * spread), true
		end
	end
	-- En Zona de control, la mitad de las veces van a la zona activa
	local zone = ReplicatedStorage:GetAttribute("ZonePosition")
	if typeof(zone) == "Vector3" and math.random() < 0.75 then
		return zone + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
	end
	-- Pista del equipo: va a donde se ha visto u oído al enemigo (los agresivos casi siempre)
	local clue = bestIntel(agent, 10, 150)
	local chase = ({ Subfusil = 0.85, Escopeta = 0.85, Asalto = 0.55, Ametralladora = 0.35, Tirador = 0 })[agent.Role or "Asalto"] or 0.5
	if clue and math.random() < chase then
		return clue.Position + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)), true
	end
	-- Si no, patrulla su carril hasta donde le toca según su rol
	return laneGoal(agent)
end

local function computePath(agent, goal)
	agent.Waypoints = nil
	agent.WaypointIndex = 0
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 6,
		Costs = { CrackedLava = math.huge, Water = math.huge }, -- nunca por la lava ni por el agua
	})
	local ok = pcall(function()
		path:ComputeAsync(agent.Root.Position, goal)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		agent.Waypoints = path:GetWaypoints()
		agent.WaypointIndex = 1
	end
end

---------------------------------------------------------------------------
-- Comportamiento "de jugador": roles, carriles, información del equipo, oído y coberturas
---------------------------------------------------------------------------

-- Lo que sabe cada equipo de dónde está el enemigo (lo que ve u oye cualquier compañero).
-- En todos contra todos cada bot tiene lo suyo.
local intel = {} -- [clave] = { { Position, Time } }
local INTEL_TIME = 12

local function intelKey(agent)
	return (teamMode() and agent.Team) and agent.Team.Name or agent.Name
end

local function reportEnemy(agent, position)
	local key = intelKey(agent)
	local list = intel[key]
	if not list then
		list = {}
		intel[key] = list
	end
	local now = os.clock()
	for _, entry in list do
		if (entry.Position - position).Magnitude < 18 then
			entry.Position, entry.Time = position, now
			return
		end
	end
	table.insert(list, { Position = position, Time = now })
	if #list > 8 then
		table.remove(list, 1)
	end
end

-- La pista más reciente (y cercana) que tiene su equipo
bestIntel = function(agent, maxAge, maxDistance)
	local list = intel[intelKey(agent)]
	if not list or not agent.Root then
		return nil
	end
	local now = os.clock()
	local best, bestScore = nil, math.huge
	for _, entry in list do
		local age = now - entry.Time
		local distance = (entry.Position - agent.Root.Position).Magnitude
		if age < maxAge and distance < maxDistance then
			local score = distance + age * 12
			if score < bestScore then
				best, bestScore = entry, score
			end
		end
	end
	return best
end

-- Oído: disparos recientes de enemigos a su alcance
local function hear(agent, now)
	local noise = Combat.Noise
	for i = #noise, 1, -1 do
		local n = noise[i]
		if now - n.Time > 1.2 then
			break -- (van en orden: los más nuevos al final)
		end
		local enemy = n.Model ~= agent.Model and (not teamMode() or n.Team ~= agent.Team)
		if enemy and n.Model and n.Model.Parent then
			local distance = (n.Position - agent.Root.Position).Magnitude
			if distance < n.Range * (CONFIG.Hearing or 1) then
				reportEnemy(agent, n.Position)
				return n.Position
			end
		end
	end
	return nil
end

-- Eje del mapa: de la base propia a la enemiga (para repartir carriles y saber hacia dónde avanzar)
local function mapAxis(agent)
	refreshPoints()
	local own, enemy
	if teamMode() and agent.Team then
		for _, team in Teams:GetTeams() do
			local points = spawnsByColor[team.TeamColor.Name]
			if points and #points > 0 then
				local sum = Vector3.zero
				for _, p in points do
					sum += p
				end
				if team == agent.Team then
					own = sum / #points
				else
					enemy = sum / #points
				end
			end
		end
	end
	if not own or not enemy or (enemy - own).Magnitude < 20 then
		return nil
	end
	return own, enemy
end

-- Punto de patrulla según su rol y su carril: los de subfusil y escopeta se meten hasta el fondo,
-- los de fusil por la mitad y el tirador se queda en su mitad, a ser posible en alto (ventanas).
local ROLE_DEPTH = {
	Asalto = { 0.3, 0.75 },
	Subfusil = { 0.45, 0.98 },
	Escopeta = { 0.45, 0.98 },
	Ametralladora = { 0.25, 0.6 },
	Tirador = { 0.12, 0.5 },
}

laneGoal = function(agent)
	refreshPoints()
	if #ffaPoints == 0 then
		return nil
	end
	local own, enemy = mapAxis(agent)
	if not own then
		return ffaPoints[math.random(1, #ffaPoints)]
	end
	local axis = Vector3.new(enemy.X - own.X, 0, enemy.Z - own.Z)
	local length = axis.Magnitude
	axis = axis.Unit
	local side = Vector3.new(-axis.Z, 0, axis.X)
	local middle = (own + enemy) / 2
	local maxSide = 1
	for _, p in ffaPoints do
		maxSide = math.max(maxSide, math.abs((p - middle):Dot(side)))
	end
	-- El tirador va a un puesto de vigilancia de su mitad (ventana, torre...) si el mapa los tiene
	if agent.Role == "Tirador" and #botSpots > 0 then
		local mine = {}
		for _, spot in botSpots do
			if (spot.Position - own):Dot(axis) / length < 0.55 then
				table.insert(mine, spot)
			end
		end
		if #mine > 0 then
			local spot = mine[math.random(1, #mine)]
			agent.SpotLook = typeof(spot.Look) == "Vector3" and spot.Look or nil
			return spot.Position
		end
	end
	local depth = ROLE_DEPTH[agent.Role or "Asalto"] or ROLE_DEPTH.Asalto
	local anyLane = math.random() < 0.2
	local good, high = {}, {}
	for _, p in ffaPoints do
		local progress = (p - own):Dot(axis) / length
		local lateral = (p - middle):Dot(side) / maxSide
		local lane = lateral < -0.33 and -1 or (lateral > 0.33 and 1 or 0)
		if progress >= depth[1] and progress <= depth[2] and (anyLane or lane == agent.Lane) then
			table.insert(good, p)
			if p.Y > own.Y + 4 then
				table.insert(high, p)
			end
		end
	end
	if agent.Role == "Tirador" and #high > 0 then
		return high[math.random(1, #high)]
	end
	if #good == 0 then
		return ffaPoints[math.random(1, #ffaPoints)]
	end
	return good[math.random(1, #good)]
end

-- Hacia dónde mira mientras espera en un sitio: hacia el lado enemigo (o la pista más reciente)
local function watchPoint(agent)
	local clue = bestIntel(agent, INTEL_TIME, 200)
	if clue then
		return clue.Position
	end
	local own, enemy = mapAxis(agent)
	if own then
		return agent.Root.Position + Vector3.new(enemy.X - own.X, 0, enemy.Z - own.Z).Unit * 50
	end
	return agent.Root.Position + agent.Root.CFrame.LookVector * 50
end

-- Cobertura: un punto cercano desde el que el enemigo no le ve (para retirarse con poca vida)
local function findCover(agent, target)
	local root = agent.Root
	local enemyHead = target.Head.Position
	local away = Vector3.new(root.Position.X - enemyHead.X, 0, root.Position.Z - enemyHead.Z)
	away = away.Magnitude > 0.1 and away.Unit or root.CFrame.LookVector * -1
	local ignore = { agent.Model, target.Model }
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	rayParams.FilterDescendantsInstances = ignore
	local best
	for _, angle in { 70, -70, 110, -110, 40, -40, 150, -150 } do
		local direction = CFrame.Angles(0, math.rad(angle), 0) * away
		for _, distance in { 9, 15 } do
			local point = root.Position + direction * distance
			-- Que se pueda llegar en línea recta y que desde el enemigo no se vea
			local path = workspace:Raycast(root.Position, direction * distance, rayParams)
			if not path and safeGround(point) then
				local seen = workspace:Raycast(enemyHead, (point + Vector3.new(0, 1.5, 0)) - enemyHead, rayParams)
				if seen then
					best = point
					break
				end
			end
		end
		if best then
			break
		end
	end
	return best
end

-- Daño de un arma a una distancia (cae entre FalloffStart y FalloffEnd)
local function damageAt(def, distance)
	local start, finish = def.FalloffStart or 100, def.FalloffEnd or 300
	if distance <= start then
		return def.Damage
	end
	local alpha = math.clamp((distance - start) / math.max(1, finish - start), 0, 1)
	return def.Damage + ((def.MinDamage or def.Damage) - def.Damage) * alpha
end

-- Recarga (los demás ven el arma recargando: atributo Reloading del Tool)
local function startReload(agent, def, now)
	local tool = agent.Tool
	agent.Mag = def.MagSize
	agent.ReloadUntil = now + def.ReloadTime * (1.05 + math.random() * 0.2)
	if tool then
		tool:SetAttribute("Reloading", true)
		task.delay(agent.ReloadUntil - now, function()
			if tool.Parent then
				tool:SetAttribute("Reloading", false)
			end
		end)
	end
end

local function shoot(agent, target, distance, now)
	local tool = agent.Tool
	local def = Weapons.Get(agent.Weapon)
	if not tool or not tool.Parent or not def then
		return
	end
	-- Cargador de verdad: al vaciarlo recarga (y mientras tanto no dispara)
	if agent.Mag <= 0 then
		startReload(agent, def, now)
		return
	end
	agent.Mag -= 1
	-- Dificultad según el rango del jugador al que disparan (contra otros bots, normal)
	local targetPlayer = Players:GetPlayerFromCharacter(target.Model)
	local rankSkill = targetPlayer and CONFIG.SkillByRank and CONFIG.SkillByRank[targetPlayer:GetAttribute("Rank") or 1] or 1
	local skill = rankSkill * (agent.Skill or 1)
	-- La puntería se asienta: los primeros tiros sobre un objetivo nuevo fallan más
	local settle = math.clamp((now - (agent.AimStart or now)) / 0.9 + 0.35, 0.35, 1)
	local accuracy = math.min(0.95, CONFIG.Accuracy * skill) * settle
	-- (los fusiles de precisión apenas pierden puntería de lejos; las escopetas, mucha)
	local falloff = CONFIG.AccuracyFalloff * math.clamp((def.Spread or 1.6) / 1.6, 0.25, 3)
	local chance = math.clamp(accuracy - distance * falloff, 0.04, accuracy)
	if agent.Root.AssemblyLinearVelocity.Magnitude > 8 then
		chance *= 0.8 -- disparar andando
	end
	local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
	if targetRoot and targetRoot.AssemblyLinearVelocity.Magnitude > 12 then
		chance *= 0.7 -- cuesta más acertar a quien se mueve rápido
	end
	local pellets = math.max(1, def.Pellets or 1)
	local hits = 0
	for _ = 1, pellets do
		if math.random() < chance then
			hits += 1
		end
	end
	local endpoints = {}
	if hits > 0 then
		local headshot = math.random() < 0.12 * skill
		local damage = damageAt(def, distance) * hits * CONFIG.DamageScale * rankSkill
		if headshot then
			damage *= def.HeadshotMultiplier or 1.5
			table.insert(endpoints, target.Head.Position)
		else
			table.insert(endpoints, target.Head.Position + Vector3.new(math.random() - 0.5, -0.8 - math.random() * 1.2, math.random() - 0.5))
		end
		Combat.BotDamage(agent, target.Humanoid, damage, agent.Weapon)
	end
	while #endpoints < math.min(3, pellets) or #endpoints == 0 do
		local miss = Vector3.new(math.random() - 0.5, math.random() - 0.3, math.random() - 0.5).Unit * (2 + math.random() * 3)
		table.insert(endpoints, target.Head.Position + miss)
	end
	Remotes.ShotFX:FireAllClients(tool, endpoints)
	local head = agent.Model:FindFirstChild("Head")
	if head then
		Combat.ReportNoise(head.Position, agent.Team, agent.Model, agent.Weapon)
	end
end

-- Granada al último sitio donde vio al enemigo (si se ha escondido detrás de algo)
local function throwGrenade(agent, position)
	local head = agent.Model:FindFirstChild("Head")
	if not head then
		return false
	end
	local grenadeDef = Weapons.Grenade
	return Grenades.BotThrow(agent.Model, head.Position + agent.Root.CFrame.LookVector * 2, position, function(blast)
		local info = grenadeDef.Explosive
		local ignore = { agent.Model }
		local map = workspace:FindFirstChild("Map")
		local boundary = map and map:FindFirstChild("Boundary")
		if boundary then
			table.insert(ignore, boundary)
		end
		for _, target in candidates(agent) do
			local root = target.Model:FindFirstChild("HumanoidRootPart")
			local distance = root and (root.Position - blast).Magnitude
			if distance and distance <= info.Radius then
				rayParams.FilterDescendantsInstances = ignore
				local hit = workspace:Raycast(blast, root.Position - blast, rayParams)
				if not hit or hit.Instance:IsDescendantOf(target.Model) then
					local damage = info.Damage + (info.MinDamage - info.Damage) * (distance / info.Radius)
					Combat.BotDamage(agent, target.Humanoid, damage * CONFIG.DamageScale, "Grenade")
				end
			end
		end
	end)
end

-- Zombi (Infección): persigue al superviviente más cercano (aunque no lo vea, con el buscador de
-- caminos) y le araña cuando lo tiene al alcance
local function zombieThink(agent, humanoid, root, now)
	local def = Weapons.Get("Claws")
	local best, bestDistance = nil, math.huge
	for _, target in candidates(agent) do
		local distance = (target.Head.Position - root.Position).Magnitude
		if distance < bestDistance then
			best, bestDistance = target, distance
		end
	end
	if not best then
		humanoid:MoveTo(root.Position)
		return
	end
	local targetRoot = best.Model:FindFirstChild("HumanoidRootPart") or best.Head
	if bestDistance <= def.Range + 1 and math.abs(targetRoot.Position.Y - root.Position.Y) < 4 and canSee(agent, best) then
		humanoid:MoveTo(targetRoot.Position)
		if now >= agent.NextShot then
			agent.NextShot = now + def.Cooldown + math.random() * 0.3
			local targetPlayer = Players:GetPlayerFromCharacter(best.Model)
			local skill = targetPlayer and CONFIG.SkillByRank and CONFIG.SkillByRank[targetPlayer:GetAttribute("Rank") or 1] or 1
			Combat.BotDamage(agent, best.Humanoid, def.Damage * CONFIG.DamageScale * 1.4 * skill, "Claws")
		end
		return
	end
	-- Cerca y a la vista: directo; si no, por el camino (se recalcula cada poco)
	if bestDistance < 30 and canSee(agent, best) then
		local flat = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
		if flat.Magnitude < 0.1 or safeGround(root.Position + flat.Unit * 4) then
			agent.Waypoints = nil
			humanoid:MoveTo(targetRoot.Position)
			return
		end
		-- (hay agua o lava en medio: por el camino)
	end
	if not agent.Computing and (not agent.Waypoints or now > agent.GoalDeadline or agent.WaypointIndex > #agent.Waypoints) then
		agent.Computing = true
		agent.GoalDeadline = now + 2.5
		local goal = targetRoot.Position
		task.spawn(function()
			computePath(agent, goal)
			agent.Computing = false
			if not agent.Waypoints and agent.Humanoid then
				agent.Humanoid:MoveTo(goal)
			end
		end)
		return
	end
	local waypoints = agent.Waypoints
	if waypoints and waypoints[agent.WaypointIndex] then
		local waypoint = waypoints[agent.WaypointIndex]
		if (Vector3.new(waypoint.Position.X, root.Position.Y, waypoint.Position.Z) - root.Position).Magnitude < 3 then
			agent.WaypointIndex += 1
		else
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(waypoint.Position)
		end
	end
end

local function lookAt(root, position)
	local look = Vector3.new(position.X, root.Position.Y, position.Z)
	if (look - root.Position).Magnitude > 0.5 then
		root.CFrame = CFrame.lookAt(root.Position, look)
	end
end

-- Pelea con un enemigo a la vista: se mueve según su rol, se cubre si le queda poca vida y dispara
-- en ráfagas (a quemarropa, a todo lo que da el arma)
local function fight(agent, humanoid, root, target, distance, now)
	if agent.Target ~= target.Model then
		agent.Target = target.Model
		agent.AimStart = now + (agent.Reaction or CONFIG.Reaction)
		agent.NextShot = math.max(agent.NextShot, agent.AimStart)
		agent.BurstLeft = 0
	end
	agent.LastSeenPosition, agent.LastSeenTime = target.Head.Position, now
	agent.HoldUntil = 0
	reportEnemy(agent, target.Head.Position)
	humanoid.WalkSpeed = CONFIG.WalkSpeed
	humanoid.AutoRotate = false
	lookAt(root, target.Head.Position)

	-- Con poca vida se retira a cubierto (la vida se recupera sola) y luego vuelve
	if humanoid.Health < humanoid.MaxHealth * 0.35 and agent.Role ~= "Escopeta" and now > (agent.NextRetreat or 0) then
		agent.NextRetreat = now + 9
		local cover = findCover(agent, target)
		if cover then
			agent.RetreatUntil = now + 2.2
			humanoid.WalkSpeed = CONFIG.SprintSpeed or CONFIG.WalkSpeed
			humanoid.AutoRotate = true
			humanoid:MoveTo(cover)
			return
		end
	end

	-- Movimiento: cada rol pelea a su manera
	if now >= agent.NextStrafe then
		local role = agent.Role
		local dest
		if role == "Tirador" then
			-- Quieto para apuntar; de vez en cuando un paso al lado
			agent.NextStrafe = now + 2.5 + math.random() * 2
			if math.random() < 0.35 then
				dest = root.Position + root.CFrame.RightVector * (math.random() < 0.5 and -4 or 4)
			else
				dest = root.Position
			end
		else
			agent.NextStrafe = now + 0.45 + math.random() * 0.7
			local strafe = (math.random() < 0.5 and -1 or 1) * (role == "Ametralladora" and 3 or 6)
			dest = root.Position + root.CFrame.RightVector * strafe
			-- Los de corta distancia se echan encima; todos se acercan si está muy lejos
			local close = (role == "Subfusil" and 18) or (role == "Escopeta" and 9) or 75
			if distance > close then
				dest += root.CFrame.LookVector * math.min(10, distance - close)
			end
		end
		if not safeGround(dest) then
			dest = root.Position - (dest - root.Position) -- (al otro lado, si no hay agua)
		end
		if safeGround(dest) then
			humanoid:MoveTo(dest)
		end
		if math.random() < CONFIG.JumpChance and role ~= "Tirador" then
			humanoid.Jump = true
		end
	end

	-- Disparo: ráfagas controladas de lejos con armas automáticas, a todo trapo de cerca
	if now < (agent.ReloadUntil or 0) then
		return
	end
	local def = Weapons.Get(agent.Weapon)
	local interval = 1 / math.min(def and def.FireRate or 6, CONFIG.MaxFireRate)
	local shots = 0
	while now >= agent.NextShot and shots < 2 do
		shots += 1
		if def and def.Automatic and distance > 35 then
			if agent.BurstLeft <= 0 then
				agent.BurstLeft = math.random(3, 6)
				agent.NextShot = now + 0.22 + math.random() * 0.3
				break
			end
			agent.BurstLeft -= 1
		end
		shoot(agent, target, distance, now)
		agent.NextShot = math.max(agent.NextShot + interval, now - interval) + math.random() * 0.04
		if now < (agent.ReloadUntil or 0) then
			break
		end
	end
end

-- Atascado contra algo: salta y, si sigue, busca otro camino
local function checkStuck(agent, humanoid, root, now)
	local moved = agent.StuckPosition and (root.Position - agent.StuckPosition).Magnitude or math.huge
	if moved > 1.5 then
		agent.StuckPosition, agent.StuckTime = root.Position, now
		return
	end
	local stuck = now - (agent.StuckTime or now)
	if stuck > 1.4 then
		humanoid.Jump = true
	end
	if stuck > 3 then
		agent.Waypoints, agent.GoalDeadline = nil, 0
		agent.StuckPosition, agent.StuckTime = root.Position, now
	end
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
	if agent.Zombie then
		zombieThink(agent, humanoid, root, now)
		return
	end
	local target, distance = findTarget(agent)
	local heard = hear(agent, now)
	if not target then
		checkAlert(agent, now)
	end
	-- Con la bandera a cuestas no se para a pelear: dispara mientras sigue su camino a casa
	if target and agent.CarryingFlag then
		if agent.Target ~= target.Model then
			agent.Target = target.Model
			agent.AimStart = now + (agent.Reaction or CONFIG.Reaction)
			agent.NextShot = math.max(agent.NextShot, agent.AimStart)
		end
		reportEnemy(agent, target.Head.Position)
		if now >= agent.NextShot and now >= (agent.ReloadUntil or 0) then
			local def = Weapons.Get(agent.Weapon)
			agent.NextShot = now + 1 / math.min(def and def.FireRate or 6, CONFIG.MaxFireRate) + math.random() * 0.12
			shoot(agent, target, distance, now)
		end
		target = nil
	end
	-- Retirándose a cubierto: sigue hasta llegar (sin pararse a pelear)
	if now < (agent.RetreatUntil or 0) and not agent.CarryingFlag then
		return
	end
	if target then
		fight(agent, humanoid, root, target, distance, now)
		return
	end
	-- (el portador de la bandera conserva su objetivo: si no, el retraso de reacción no acabaría nunca)
	if not agent.CarryingFlag then
		agent.Target = nil
	end
	humanoid.AutoRotate = true

	-- Recarga táctica cuando no hay nadie delante
	local def = Weapons.Get(agent.Weapon)
	if def and agent.Mag < def.MagSize * 0.4 and now >= (agent.ReloadUntil or 0) then
		startReload(agent, def, now)
	end

	-- Acaba de perder de vista al enemigo: granada si se ha escondido cerca; si no, mira hacia allí
	-- un momento (pre-apuntar) antes de ir a buscarle
	local lostFor = agent.LastSeenTime and now - agent.LastSeenTime or math.huge
	if lostFor < 3 and agent.LastSeenPosition then
		local away = (agent.LastSeenPosition - root.Position).Magnitude
		if lostFor > 0.6 and away > 14 and away < 48 and now >= (agent.NextGrenade or 0) and math.random() < 0.3 then
			agent.NextGrenade = now + (CONFIG.GrenadeCooldown or 18) * (0.8 + math.random() * 0.4)
			lookAt(root, agent.LastSeenPosition)
			throwGrenade(agent, agent.LastSeenPosition)
		end
		if agent.Role ~= "Subfusil" and agent.Role ~= "Escopeta" and lostFor < 1.5 then
			humanoid.AutoRotate = false
			lookAt(root, agent.LastSeenPosition)
			humanoid:MoveTo(root.Position)
			return
		end
		if not agent.ChasedSeen then
			agent.ChasedSeen = true
			agent.AlertPosition, agent.AlertTime = agent.LastSeenPosition, now
			agent.Waypoints, agent.GoalDeadline, agent.HoldUntil = nil, 0, 0
		end
	else
		agent.ChasedSeen = false
	end
	-- Ha oído disparos cerca: deja lo que esté haciendo y va (el tirador solo se gira)
	if heard and not agent.CarryingFlag and now > (agent.NextHeard or 0) then
		agent.NextHeard = now + 4
		if agent.Role == "Tirador" and (agent.HoldUntil or 0) > now then
			agent.HoldLook = heard
		elseif (heard - root.Position).Magnitude > 12 then
			agent.AlertPosition, agent.AlertTime = heard, now
			agent.Waypoints, agent.GoalDeadline, agent.HoldUntil = nil, 0, 0
		end
	end

	-- Esperando en un sitio (el tirador vigila su línea; los demás echan un vistazo)
	if (agent.HoldUntil or 0) > now then
		humanoid:MoveTo(root.Position)
		humanoid.AutoRotate = false
		local look = agent.HoldLook or watchPoint(agent)
		local scan = math.sin(now * 0.7 + (agent.Seed or 0)) * math.rad(agent.Role == "Tirador" and 25 or 50)
		local direction = Vector3.new(look.X - root.Position.X, 0, look.Z - root.Position.Z)
		if direction.Magnitude > 0.5 then
			lookAt(root, root.Position + CFrame.Angles(0, scan, 0) * direction.Unit * 10)
		end
		return
	end

	-- Sin enemigos a la vista: seguir el camino o buscar uno nuevo
	local waypoints = agent.Waypoints
	if agent.Computing then
		return
	end
	if not waypoints or agent.WaypointIndex > #waypoints or now > agent.GoalDeadline then
		if now < agent.GoalDeadline and not waypoints then
			return -- sin camino: va en línea recta un rato antes de volver a intentarlo
		end
		-- Ha llegado: se para un momento a mirar (el tirador se aposta un buen rato)
		if waypoints and agent.WaypointIndex > #waypoints and not agent.Arrived then
			agent.Arrived = true
			-- (en un puesto de vigilancia, mira hacia donde manda el puesto)
			agent.HoldLook = (agent.SpotLook and agent.GoalPosition and (agent.GoalPosition - root.Position).Magnitude < 6) and agent.SpotLook or nil
			agent.HoldUntil = now + (agent.Role == "Tirador" and (12 + math.random() * 14) or (0.6 + math.random() * 1.6))
			-- (en una bandera de Dominio que no es suya, se queda a capturarla)
			if ReplicatedStorage:GetAttribute("Mode") == "DOM" then
				for _, flag in Domination.Points() do
					local offset = flag.Position - root.Position
					if flag.Owner ~= agent.Team and Vector3.new(offset.X, 0, offset.Z).Magnitude <= flag.Radius then
						agent.HoldUntil = now + 3
					end
				end
			end
			return
		end
		agent.Arrived = false
		local goal, objective = pickGoal(agent)
		-- (las banderas se mueven: el camino hacia ellas se recalcula antes)
		agent.GoalDeadline = now + (objective and 5 or 14)
		agent.GoalPosition = goal
		agent.Urgent = objective
		if goal then
			agent.Computing = true
			task.spawn(function()
				computePath(agent, goal)
				agent.Computing = false
				-- (si mientras tanto le dispararon, no se pisa la alerta: el siguiente turno va hacia allí)
				if not agent.Waypoints and agent.Humanoid and not agent.AlertPosition then
					agent.Humanoid:MoveTo(goal)
					agent.GoalDeadline = os.clock() + 3
				end
			end)
		else
			agent.GoalDeadline = now + 3
		end
		return
	end
	-- De camino: corre si no espera encontrarse a nadie; anda (y atento) cerca de donde hay enemigos
	local clue = bestIntel(agent, 6, 45)
	humanoid.WalkSpeed = (clue or agent.Role == "Tirador" and agent.Urgent) and CONFIG.WalkSpeed or (CONFIG.SprintSpeed or CONFIG.WalkSpeed)
	checkStuck(agent, humanoid, root, now)
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

-- Rol del bot (GameConfig.Bots.Roles): al azar según su peso, sin pasar del máximo por equipo, y el
-- carril con menos compañeros. Cada bot tiene además su puntería y sus reflejos.
chooseRole = function(agent)
	local roles = CONFIG.Roles
	agent.Skill = 0.85 + math.random() * 0.3
	agent.Reaction = CONFIG.Reaction * (0.75 + math.random() * 0.5) / agent.Skill
	agent.Seed = math.random() * 10
	local laneCount = { [-1] = 0, [0] = 0, [1] = 0 }
	local roleCount = {}
	for _, other in agents do
		if other ~= agent and other.Team == agent.Team then
			if other.Lane then
				laneCount[other.Lane] += 1
			end
			if other.Role then
				roleCount[other.Role] = (roleCount[other.Role] or 0) + 1
			end
		end
	end
	local lane, fewest = 0, math.huge
	for _, l in { 0, -1, 1 } do
		if laneCount[l] < fewest then
			lane, fewest = l, laneCount[l]
		end
	end
	agent.Lane = lane
	if not roles or #roles == 0 then
		agent.Role = "Asalto"
		return
	end
	local pool, total = {}, 0
	for _, role in roles do
		if not role.Max or (roleCount[role.Name] or 0) < role.Max then
			table.insert(pool, role)
			total += role.Weight or 1
		end
	end
	local pick = math.random() * total
	local chosen = pool[1] or roles[1]
	for _, role in pool do
		pick -= role.Weight or 1
		if pick <= 0 then
			chosen = role
			break
		end
	end
	agent.Role = chosen.Name
	local options = {}
	for _, name in chosen.Weapons do
		if Weapons.Get(name) then
			table.insert(options, name)
		end
	end
	agent.RoleWeapon = #options > 0 and options[math.random(1, #options)] or nil
end

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
	if ReplicatedStorage:GetAttribute("Infection") == "On" and agent.Team and agent.Team.Name == ReplicatedStorage:GetAttribute("TeamB") then
		agent.Zombie = true
	end
	agent.Spawning = true
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(makeDescription(agent.Team, agent.Zombie), Enum.HumanoidRigType.R15)
	end)
	if not ok then
		ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(makeDescription(agent.Team, agent.Zombie), Enum.HumanoidRigType.R15)
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
	-- Primera vez en la base; al reaparecer, en el punto más seguro (como los jugadores: SpawnPicker)
	local spawnAt = spawnPoint(agent.Team)
	if agent.HasSpawned and SpawnPicker.Enabled() then
		local picked = SpawnPicker.Pick(agent.Team, nil)
		if picked then
			spawnAt = picked + Vector3.new(0, 4, 0)
		end
	end
	agent.HasSpawned = true
	model:PivotTo(CFrame.new(spawnAt) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	agent.Model, agent.Humanoid, agent.Root = model, humanoid, root
	statsOf(agent)
	animate(humanoid)
	if agent.Zombie then
		agent.Weapon = "Claws"
	else
		-- Rol y arma (los conserva al reaparecer), carril, puntería y reflejos propios
		if not agent.Role then
			chooseRole(agent)
		end
		agent.Weapon = agent.RoleWeapon or CONFIG.Weapons[math.random(1, #CONFIG.Weapons)]
	end
	-- Traje de operador al azar (cada bot conserva el suyo al reaparecer)
	if agent.Outfit == nil then
		agent.Outfit = (#BOT_OUTFITS > 0 and math.random() < (CONFIG.OutfitChance or 0)) and BOT_OUTFITS[math.random(1, #BOT_OUTFITS)] or false
	end
	-- En los mapas realistas (tipo shooter militar) van de soldado, con el color de su equipo
	local map = workspace:FindFirstChild("Map")
	local soldier = map ~= nil and map:GetAttribute("Realistic") == true and not agent.Zombie
	if soldier then
		pcall(Outfits.Apply, model, Outfits.Soldier(agent.Team and agent.Team.TeamColor.Color))
	elseif agent.Outfit and not agent.Zombie then
		pcall(Outfits.Apply, model, agent.Outfit)
	end
	if agent.Zombie then
		local claws = Weapons.Get("Claws")
		Zombie.Apply(model, GameConfig.ModeSettings.INF.ZombieHealth)
		humanoid.WalkSpeed = CONFIG.WalkSpeed * (claws.WalkSpeedMultiplier or 1)
	end
	if agent.Skin == nil then
		agent.Skin = (#BOT_SKINS > 0 and math.random() < 0.5) and BOT_SKINS[math.random(1, #BOT_SKINS)] or "Default"
	end
	if agent.Charm == nil then
		agent.Charm = (#BOT_CHARMS > 0 and math.random() < 0.3) and BOT_CHARMS[math.random(1, #BOT_CHARMS)] or false
	end
	agent.Tool = Loadout.MakeTool(agent.Weapon, (agent.Zombie or soldier) and "Default" or agent.Skin, (not soldier and agent.Charm) or nil)
	agent.Tool.Parent = model
	humanoid:EquipTool(agent.Tool)
	agent.Shots, agent.NextShot, agent.NextStrafe, agent.GoalDeadline = 0, 0, 0, 0
	agent.AlertPosition, agent.AlertTime = nil, nil
	agent.Waypoints, agent.Target = nil, nil
	local weaponDef = Weapons.Get(agent.Weapon)
	agent.Mag = weaponDef and weaponDef.MagSize or 30
	agent.ReloadUntil, agent.BurstLeft, agent.RetreatUntil, agent.HoldUntil = 0, 0, 0, 0
	agent.LastSeenPosition, agent.LastSeenTime, agent.Arrived = nil, nil, false
	agent.NextGrenade = os.clock() + 8 + math.random() * 10
	agent.StuckPosition, agent.StuckTime = nil, nil
	humanoid.WalkSpeed = agent.Zombie and humanoid.WalkSpeed or (CONFIG.SprintSpeed or CONFIG.WalkSpeed)

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
			agent.AlertPosition, agent.AlertTime = nil, nil
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

-- Infección: el bot pasa a ser zombi (si está vivo, reaparece ya como zombi; si no, al reaparecer)
function Bots.Infect(agent, zombieTeam)
	if agent.Zombie then
		return
	end
	agent.Team = zombieTeam
	agent.Zombie = true
	local entry = statsOf(agent)
	if entry then
		entry:SetAttribute("Team", zombieTeam.Name)
	end
	if agent.Humanoid and agent.Humanoid.Health > 0 and agent.Model then
		-- Paciente cero: se cambia el cuerpo por uno de zombi (sin contar como muerte)
		local model = agent.Model
		agent.Humanoid = nil
		model:Destroy()
		task.spawn(safeSpawn, agent)
	end
end

-- Al cambiar de modo o de equipos, los bots vuelven a elegir equipo
function Bots.Reset()
	for i = #agents, 1, -1 do
		removeAgent(agents[i])
	end
	table.clear(intel) -- (lo que sabían del enemigo era de la ronda anterior)
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
