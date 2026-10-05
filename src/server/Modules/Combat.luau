-- Validación de disparos y daño en el servidor (anti-trampas básico).
-- El cliente calcula el impacto; el servidor comprueba cadencia, munición, distancia y línea de visión.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local Ragdoll = require(script.Parent.Ragdoll)

local Combat = {}

-- Asignado desde Main: function(killer: Player?, victim: Player?, victimName, weaponName, headshot, position: Vector3?)
Combat.OnKill = nil
Combat.OnAssist = nil -- (jugadores que ayudaron, nombre de la víctima, bot víctima, jugador víctima)

-- Quién le ha quitado vida a cada Humanoid y cuándo (para las asistencias)
local ASSIST_WINDOW = 10
local ASSIST_MIN_DAMAGE = 20
local damageLog = setmetatable({}, { __mode = "k" }) -- [humanoid] = { [userId] = { Time, Damage } }

-- Cadencia: "cubo" de disparos por arma. Se rellena a FireRate por segundo y guarda hasta 3, así los
-- disparos legítimos que llegan juntos (lag) no se pierden, pero no se puede disparar más rápido.
local fireBudget = setmetatable({}, { __mode = "k" })
local FIRE_BURST_ALLOWANCE = 3
local reloadTokens = setmetatable({}, { __mode = "k" })
local lastMelee = {}

local function getCharacterFromPart(part)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return model, humanoid
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

-- Bots activos por nombre (los registra Bots): para saber quién hizo una baja
Combat.BotsByName = {}

local function isEnemy(attacker, targetPlayer, targetChar)
	if not targetPlayer then
		-- Bots del mismo equipo no se dañan; muñecos de práctica y bots enemigos sí
		if targetChar and targetChar:GetAttribute("Bot") and ReplicatedStorage:GetAttribute("TeamMode") and attacker.Team then
			return targetChar:GetAttribute("Team") ~= attacker.Team.Name
		end
		return true
	end
	if attacker == targetPlayer then
		return false
	end
	if attacker.Neutral or targetPlayer.Neutral or not attacker.Team then
		return true
	end
	return attacker.Team ~= targetPlayer.Team
end

local function isHeadshot(part, character, position)
	if part.Name == "Head" then
		return true
	end
	return false
end

-- Los accesorios del avatar (sombreros, alas, mochilas) no reciben disparos: ni escudo ni cabeza gigante
local function ignoreAccessories(character)
	local function apply(inst)
		if inst:IsA("BasePart") and inst:FindFirstAncestorOfClass("Accessory") then
			inst.CanQuery = false
		end
	end
	for _, inst in character:GetDescendants() do
		apply(inst)
	end
	character.DescendantAdded:Connect(apply)
end

local function hasLineOfSight(origin, target, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	ignore = table.clone(ignore)
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary) -- muros invisibles del borde del mapa
	end
	params.FilterDescendantsInstances = ignore
	local offset = target - origin
	local distance = offset.Magnitude - 1.5
	if distance <= 0 then
		return true
	end
	return workspace:Raycast(origin, offset.Unit * distance, params) == nil
end

local function damageAtDistance(def, distance)
	if distance <= def.FalloffStart then
		return def.Damage
	end
	if distance >= def.FalloffEnd then
		return def.MinDamage
	end
	local alpha = (distance - def.FalloffStart) / (def.FalloffEnd - def.FalloffStart)
	return def.Damage + (def.MinDamage - def.Damage) * alpha
end

-- Al atacar se pierde cualquier escudo (el de reaparición y el de la pantalla de inicio)
local function removeSpawnShield(character)
	for _, child in character:GetChildren() do
		if child:IsA("ForceField") then
			child:Destroy()
		end
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		player:SetAttribute("InMenu", false)
	end
end

-- Aplica daño y deja la "etiqueta" del atacante. Devuelve daño real y si murió.
local function applyDamage(attacker, humanoid, damage, weaponName, headshot)
	if humanoid.Health <= 0 then
		return 0, false
	end
	humanoid:SetAttribute("LastAttacker", attacker.UserId)
	humanoid:SetAttribute("LastBot", nil)
	humanoid:SetAttribute("LastWeapon", weaponName)
	humanoid:SetAttribute("LastHeadshot", headshot)
	humanoid:SetAttribute("LastHitTime", os.clock())
	local before = humanoid.Health
	humanoid:TakeDamage(damage) -- respeta el ForceField de spawn
	local dealt = before - humanoid.Health
	if dealt > 0 then
		local log = damageLog[humanoid] or {}
		damageLog[humanoid] = log
		local entry = log[attacker.UserId]
		if entry and os.clock() - entry.Time < ASSIST_WINDOW then
			entry.Damage += dealt
		else
			entry = { Damage = dealt }
			log[attacker.UserId] = entry
		end
		entry.Time = os.clock()
	end
	return dealt, humanoid.Health <= 0
end

-- Daño de un bot (ver Bots): deja su nombre como atacante
-- Ruido de los disparos: los bots oyen los tiros cercanos (como el punto rojo del minimapa en los
-- shooters de móvil) y van a ver. Las armas con silenciador apenas se oyen.
Combat.Noise = {} -- { Position, Time, Team, Model, Range }
local NOISE_KEEP = 24
function Combat.ReportNoise(position, team, model, weaponName)
	local def = Weapons.Get(weaponName or "")
	local range = (def and def.Suppressed) and 25 or 110
	-- Ventaja "Fantasma": los bots le oyen la mitad de lejos
	local owner = model and Players:GetPlayerFromCharacter(model)
	if owner and owner:GetAttribute("Perk") == 3 then
		range *= 0.5
	end
	table.insert(Combat.Noise, { Position = position, Time = os.clock(), Team = team, Model = model, Range = range })
	if #Combat.Noise > NOISE_KEEP then
		table.remove(Combat.Noise, 1)
	end
end

function Combat.BotDamage(bot, humanoid, damage, weaponName)
	if humanoid.Health <= 0 then
		return 0, false
	end
	humanoid:SetAttribute("LastAttacker", nil)
	humanoid:SetAttribute("LastBot", bot.Name)
	humanoid:SetAttribute("LastWeapon", weaponName)
	humanoid:SetAttribute("LastHeadshot", false)
	humanoid:SetAttribute("LastHitTime", os.clock())
	local before = humanoid.Health
	humanoid:TakeDamage(damage)
	return before - humanoid.Health, humanoid.Health <= 0
end

-- Daño en área (cohetes). Afecta a enemigos y muñecos con línea de visión desde la explosión.
function Combat.Explode(attacker, position, def, weaponName)
	local info = def.Explosive
	local candidates = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(candidates, p.Character)
		end
	end
	for _, folderName in { "Dummies", "Bots" } do
		local npcs = workspace:FindFirstChild(folderName)
		if npcs then
			for _, d in npcs:GetChildren() do
				table.insert(candidates, d)
			end
		end
	end
	local totalDealt, anyKill, hitPosition, best = 0, false, nil, 0
	local attackerChar = attacker.Character
	for _, targetChar in candidates do
		local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
		local root = targetChar:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and targetChar ~= attackerChar then
			local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
			local distance = (root.Position - position).Magnitude
			if distance <= info.Radius and isEnemy(attacker, targetPlayer, targetChar) then
				if hasLineOfSight(position, root.Position, { targetChar, attackerChar }) then
					local alpha = distance / info.Radius
					local damage = info.Damage + (info.MinDamage - info.Damage) * alpha
					local dealt, killed = applyDamage(attacker, humanoid, damage, weaponName, false)
					totalDealt += dealt
					anyKill = anyKill or killed
					if dealt > best then
						best, hitPosition = dealt, root.Position
					end
				end
			end
		end
	end
	if totalDealt > 0 then
		Remotes.HitConfirm:FireClient(attacker, math.floor(totalDealt + 0.5), false, anyKill, hitPosition)
	end
end

-- Detecta la muerte de un Humanoid y avisa a quien corresponda
-- victimBot: el bot (ver Bots) si el que muere es un bot
function Combat.WatchHumanoid(humanoid, victimPlayer, victimName, victimBot)
	Ragdoll.Prepare(humanoid) -- (que Roblox no rompa el cuerpo en piezas al morir)
	humanoid.Died:Connect(function()
		-- El cuerpo cae como un muñeco de trapo, con un empujón alejándose de quien le dio
		-- (mucho más fuerte con explosivos)
		pcall(function()
			local character = humanoid.Parent
			local victimRoot = character and character:FindFirstChild("HumanoidRootPart")
			local push
			local attackerId = humanoid:GetAttribute("LastAttacker")
			local attacker = attackerId and Players:GetPlayerByUserId(attackerId)
			local attackerModel = (attacker and attacker.Character)
				or (humanoid:GetAttribute("LastBot") and Combat.BotsByName[humanoid:GetAttribute("LastBot")] and Combat.BotsByName[humanoid:GetAttribute("LastBot")].Model)
			local attackerRoot = attackerModel and attackerModel:FindFirstChild("HumanoidRootPart")
			if victimRoot and attackerRoot then
				local away = victimRoot.Position - attackerRoot.Position
				away = Vector3.new(away.X, 0, away.Z)
				if away.Magnitude > 0.1 then
					local def = Weapons.Get(humanoid:GetAttribute("LastWeapon") or "")
					local strength = def and def.Explosive and 38 or 9
					push = away.Unit * strength + Vector3.new(0, def and def.Explosive and 22 or 3, 0)
				end
			end
			Ragdoll.Apply(character, push)
		end)
		local killer, killerBot
		local hitTime = humanoid:GetAttribute("LastHitTime")
		local recent = hitTime and os.clock() - hitTime < 10
		local attackerId = humanoid:GetAttribute("LastAttacker")
		if attackerId and recent then
			killer = Players:GetPlayerByUserId(attackerId)
		end
		local botName = humanoid:GetAttribute("LastBot")
		if botName and recent and not killer then
			killerBot = Combat.BotsByName[botName]
		end
		local weaponName = humanoid:GetAttribute("LastWeapon")
		local headshot = humanoid:GetAttribute("LastHeadshot") == true
		local character = humanoid.Parent
		local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head"))
		local position = root and root.Position
		if victimPlayer then
			-- Vida que le quedaba al que te eliminó (se enseña en la pantalla de muerte)
			local killerHumanoid = killer and killer.Character and killer.Character:FindFirstChildOfClass("Humanoid")
				or (killerBot and killerBot.Humanoid)
			local killerHealth = killerHumanoid and math.ceil(math.max(0, killerHumanoid.Health)) or nil
			local killerName = (killer and killer.Name) or (killerBot and killerBot.Name) or nil
			Remotes.Died:FireClient(victimPlayer, killerName, weaponName, killerHealth)
		end
		-- Espectador de Eliminación (entró a mitad de ronda): pantalla de muerte, pero sin baja ni muerte
		-- (el equipo del caído antes de que OnKill lo cambie: en Infección pasa a zombi)
		local victimTeamBefore = (victimPlayer and victimPlayer.Team) or (victimBot and victimBot.Team) or nil
		if Combat.OnKill and not humanoid:GetAttribute("Spectator") then
			Combat.OnKill(killer, victimPlayer, victimName, weaponName, headshot, position, killerBot, victimBot)
		end
		-- Asistencias: quien le quitó bastante vida hace poco y no es quien lo remató
		local log = damageLog[humanoid]
		damageLog[humanoid] = nil
		-- (solo contra jugadores y bots, no muñecos; y no si ahora es del mismo equipo, p. ej. en Infección)
		if log and Combat.OnAssist and (victimPlayer or victimBot) and not humanoid:GetAttribute("Spectator") then
			local victimTeam = victimTeamBefore
			local helpers = {}
			for userId, entry in log do
				local helper = Players:GetPlayerByUserId(userId)
				if helper and helper ~= killer and helper ~= victimPlayer and entry.Damage >= ASSIST_MIN_DAMAGE
					and os.clock() - entry.Time < ASSIST_WINDOW and not (victimTeam and helper.Team == victimTeam) then
					table.insert(helpers, helper)
				end
			end
			if #helpers > 0 then
				Combat.OnAssist(helpers, victimName, victimBot, victimPlayer)
			end
		end
	end)
end

local function frozen()
	return ReplicatedStorage:GetAttribute("Frozen") == true -- cuenta atrás de Eliminación
end

local function onFire(player, tool, origin, rays)
	if frozen() then
		return
	end
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") or typeof(origin) ~= "Vector3" or type(rays) ~= "table" then
		return
	end
	local character = player.Character
	if not character or tool.Parent ~= character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not head then
		return
	end
	local weaponName = tool:GetAttribute("Weapon")
	local def = Weapons.Get(weaponName)
	if not def or def.Type ~= "Gun" or tool:GetAttribute("Reloading") then
		return
	end
	local ammo = tool:GetAttribute("Ammo") or 0
	if ammo <= 0 then
		return
	end
	local now = os.clock()
	-- Armas lentas (escopetas, francotiradores) no acumulan: 1 disparo; las rápidas hasta 3
	local cap = math.clamp(def.FireRate * 0.2, 1, FIRE_BURST_ALLOWANCE)
	local budget = fireBudget[tool]
	if not budget then
		budget = { Time = now, Shots = cap }
		fireBudget[tool] = budget
	end
	budget.Shots = math.min(cap, budget.Shots + (now - budget.Time) * def.FireRate * 1.15)
	budget.Time = now
	if budget.Shots < 1 then
		return
	end
	-- El origen del disparo tiene que estar cerca de la cabeza y SIN pared en medio
	if (head.Position - origin).Magnitude > 12 or not hasLineOfSight(head.Position, origin, { character }) then
		return
	end
	budget.Shots -= 1
	tool:SetAttribute("Ammo", ammo - 1)
	removeSpawnShield(character)
	Combat.ReportNoise(head.Position, player.Team, character, weaponName)

	if def.Explosive then
		local ray = rays[1]
		if type(ray) ~= "table" or typeof(ray.Position) ~= "Vector3" then
			return
		end
		local position = ray.Position
		if (position - origin).Magnitude > def.Range + 5 then
			return
		end
		-- El cohete no puede atravesar paredes hasta el punto de impacto
		local back = (origin - position).Unit * 1.5
		if not hasLineOfSight(origin, position + back, { character }) then
			return
		end
		Combat.Explode(player, position + back * 0.5, def, tool:GetAttribute("Weapon"))
		for _, other in Players:GetPlayers() do
			if other ~= player then
				Remotes.ShotFX:FireClient(other, tool, { position })
			end
		end
		return
	end

	local endpoints = {}
	local perTarget = {}
	for i = 1, math.min(#rays, def.Pellets) do
		local ray = rays[i]
		if type(ray) == "table" and typeof(ray.Position) == "Vector3" then
			local position = ray.Position
			local distance = (position - origin).Magnitude
			if distance <= def.Range + 5 then
				table.insert(endpoints, position)
				local part = ray.Part
				if typeof(part) == "Instance" and part:IsA("BasePart") and part:IsDescendantOf(workspace) then
					local targetChar, targetHum = getCharacterFromPart(part)
					if targetChar and targetChar ~= character and targetHum.Health > 0 then
						local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
						local closeEnough = (part.Position - position).Magnitude <= part.Size.Magnitude / 2 + 8
						if
							isEnemy(player, targetPlayer, targetChar)
							and closeEnough
							and hasLineOfSight(origin, position, { character, targetChar })
						then
							local headshot = isHeadshot(part, targetChar, position)
							local damage = damageAtDistance(def, distance)
								* (headshot and def.HeadshotMultiplier or 1)
							local entry = perTarget[targetHum]
							if not entry then
								entry = { Damage = 0, Headshot = false }
								perTarget[targetHum] = entry
							end
							entry.Damage += damage
							entry.Position = position
							entry.Headshot = entry.Headshot or headshot
						end
					end
				end
			end
		end
	end

	-- hitPosition: dónde se hizo más daño (el cliente pone ahí el número de daño)
	local totalDealt, anyHeadshot, anyKill, hitPosition, best = 0, false, false, nil, 0
	for targetHum, entry in perTarget do
		local dealt, killed = applyDamage(player, targetHum, entry.Damage, weaponName, entry.Headshot)
		if dealt > 0 then
			totalDealt += dealt
			anyHeadshot = anyHeadshot or entry.Headshot
			anyKill = anyKill or killed
			if dealt > best then
				best, hitPosition = dealt, entry.Position
			end
		end
	end
	if totalDealt > 0 then
		Remotes.HitConfirm:FireClient(player, math.floor(totalDealt + 0.5), anyHeadshot, anyKill, hitPosition)
	end

	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.ShotFX:FireClient(other, tool, endpoints)
		end
	end
end

local function onReload(player, tool)
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return
	end
	local character = player.Character
	if not character or tool.Parent ~= character then
		return
	end
	local def = Weapons.Get(tool:GetAttribute("Weapon"))
	if not def or def.Type ~= "Gun" or tool:GetAttribute("Reloading") then
		return
	end
	local ammo = tool:GetAttribute("Ammo") or 0
	local reserve = tool:GetAttribute("Reserve") or 0
	if ammo >= def.MagSize or reserve <= 0 then
		return
	end
	tool:SetAttribute("Reloading", true)
	local token = {}
	reloadTokens[tool] = token
	-- (con balas aún en el cargador, recarga táctica: más rápida)
	task.delay(Weapons.ReloadDuration(def, ammo <= 0), function()
		if reloadTokens[tool] ~= token then
			return
		end
		reloadTokens[tool] = nil
		-- Si cambió de arma la recarga ya se canceló (Reloading = false)
		if not tool:GetAttribute("Reloading") or tool.Parent ~= player.Character then
			tool:SetAttribute("Reloading", false)
			return
		end
		local currentAmmo = tool:GetAttribute("Ammo") or 0
		local currentReserve = tool:GetAttribute("Reserve") or 0
		local take = math.min(def.MagSize - currentAmmo, currentReserve)
		tool:SetAttribute("Ammo", currentAmmo + take)
		tool:SetAttribute("Reserve", currentReserve - take)
		tool:SetAttribute("Reloading", false)
	end)
end

-- Arma cuerpo a cuerpo que lleva el jugador (cuchillo, martillo o katana): su nombre
local function findMelee(player)
	for _, container in { player.Character, player:FindFirstChild("Backpack") } do
		if container then
			for _, tool in container:GetChildren() do
				local name = tool:IsA("Tool") and tool:GetAttribute("Weapon")
				local def = name and Weapons.Get(name)
				if def and def.Type == "Melee" then
					return name
				end
			end
		end
	end
	return nil
end

local function onMelee(player, part)
	if frozen() then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local meleeName = findMelee(player)
	if not humanoid or humanoid.Health <= 0 or not root or not meleeName then
		return
	end
	local def = Weapons.Get(meleeName)
	local now = os.clock()
	if now - (lastMelee[player] or 0) < def.Cooldown * 0.8 then
		return
	end
	lastMelee[player] = now
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then
		return
	end
	local targetChar, targetHum = getCharacterFromPart(part)
	if not targetChar or targetChar == character or targetHum.Health <= 0 then
		return
	end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or part
	if (targetRoot.Position - root.Position).Magnitude > def.Range + 4 then
		return
	end
	if not isEnemy(player, Players:GetPlayerFromCharacter(targetChar), targetChar) then
		return
	end
	-- Nada de cuchillazos a través de paredes
	if not hasLineOfSight(root.Position, targetRoot.Position, { character, targetChar }) then
		return
	end
	removeSpawnShield(character)
	local dealt, killed = applyDamage(player, targetHum, def.Damage, meleeName, false)
	if dealt > 0 then
		Remotes.HitConfirm:FireClient(player, math.floor(dealt + 0.5), false, killed, targetRoot.Position)
	end
end

-- Hacia dónde mira cada jugador arriba/abajo (radianes): se guarda en su personaje (atributo AimPitch,
-- se replica) para que los demás le vean apuntar con el arma inclinada (RiflePose). Como mucho unas
-- 10 veces por segundo y redondeado (cambios pequeños no se mandan)
local lastPitch = setmetatable({}, { __mode = "k" }) -- [player] = os.clock()
local function onAimPitch(player, pitch)
	if type(pitch) ~= "number" or pitch ~= pitch then
		return
	end
	local now = os.clock()
	if now - (lastPitch[player] or 0) < 0.08 then
		return
	end
	lastPitch[player] = now
	local character = player.Character
	if character then
		character:SetAttribute("AimPitch", math.floor(math.clamp(pitch, -1.3, 1.3) * 20 + 0.5) / 20)
	end
end

-- Linterna del arma (de noche): los demás la ven si la llevas encendida
local lastFlashlight = setmetatable({}, { __mode = "k" }) -- [player] = os.clock()
local function onFlashlight(player, on)
	if type(on) ~= "boolean" then
		return
	end
	local now = os.clock()
	if now - (lastFlashlight[player] or 0) < 0.2 then
		return
	end
	lastFlashlight[player] = now
	if player.Character then
		player.Character:SetAttribute("Flashlight", on)
	end
end

function Combat.Init()
	Remotes.AimPitch.OnServerEvent:Connect(onAimPitch)
	Remotes.Flashlight.OnServerEvent:Connect(onFlashlight)
	Remotes.Fire.OnServerEvent:Connect(onFire)
	Remotes.Reload.OnServerEvent:Connect(onReload)
	Remotes.Melee.OnServerEvent:Connect(onMelee)

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			ignoreAccessories(character)
			local humanoid = character:WaitForChild("Humanoid")
			Combat.WatchHumanoid(humanoid, player, player.Name)
		end)
		if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
			ignoreAccessories(player.Character)
			Combat.WatchHumanoid(player.Character:FindFirstChildOfClass("Humanoid"), player, player.Name)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastMelee[player] = nil
	end)
end

return Combat
