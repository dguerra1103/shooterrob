-- Validación de disparos y daño en el servidor (anti-trampas básico).
-- El cliente calcula el impacto; el servidor comprueba cadencia, munición, distancia y línea de visión.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local Combat = {}

-- Asignado desde Main: function(killer: Player?, victim: Player?, victimName, weaponName, headshot, position: Vector3?)
Combat.OnKill = nil

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
	return dealt, humanoid.Health <= 0
end

-- Daño de un bot (ver Bots): deja su nombre como atacante
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
	humanoid.Died:Connect(function()
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
		if Combat.OnKill then
			Combat.OnKill(killer, victimPlayer, victimName, weaponName, headshot, position, killerBot, victimBot)
		end
	end)
end

local function onFire(player, tool, origin, rays)
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
	task.delay(def.ReloadTime, function()
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

local function findKnife(player)
	for _, container in { player.Character, player:FindFirstChild("Backpack") } do
		if container then
			for _, tool in container:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("Weapon") == Weapons.Melee then
					return tool
				end
			end
		end
	end
	return nil
end

local function onMelee(player, part)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not findKnife(player) then
		return
	end
	local def = Weapons.Get(Weapons.Melee)
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
	local dealt, killed = applyDamage(player, targetHum, def.Damage, Weapons.Melee, false)
	if dealt > 0 then
		Remotes.HitConfirm:FireClient(player, math.floor(dealt + 0.5), false, killed, targetRoot.Position)
	end
end

function Combat.Init()
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
