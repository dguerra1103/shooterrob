-- Buscar y destruir: la bomba de cada ronda. Los atacantes la plantan quedándose dentro de un sitio
-- (A o B, en la mitad de los defensores) PLANT_TIME segundos; los defensores la desactivan quedándose
-- junto a ella DEFUSE_TIME segundos antes de que explote (BOMB_TIME). Round decide la ronda con
-- Bomb.Result ("Exploded" / "Defused") y Bomb.Planted.
--
-- Estado para la interfaz (atributos de ReplicatedStorage):
--   Bomb_Attackers / Bomb_Defenders (nombres de equipo), Bomb_A_Position / Bomb_B_Position,
--   Bomb_State ("Idle" | "Planted" | "Exploded" | "Defused"), Bomb_Site (letra), Bomb_Timer (s),
--   Bomb_Action ("Planting" | "Defusing" | ""), Bomb_Progress (0..1),
--   Bomb_Carrier (nombre de quien lleva la bomba), Bomb_Dropped (Vector3 si está en el suelo)
-- Como en los shooters: solo un atacante lleva la bomba y solo él puede plantarla. Si cae, la bomba
-- se queda en el suelo y cualquier atacante la recoge pasando por encima.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local GameConfig = require(Shared.GameConfig)

local PlayerData = require(script.Parent.PlayerData)

local Bomb = {}

local STEP = 0.25

local active = false
local sites = {} -- { Letter, Position, Radius, Visual }
local PICKUP_RADIUS = 5
local carrier -- { Model, Player, Name, LastPosition }
local droppedAt -- Vector3: la bomba está en el suelo
local droppedVisual
local thread
local visuals = {}

Bomb.Result = nil
Bomb.Planted = false
Bomb.Site = nil

local function settings()
	return GameConfig.ModeSettings.SND or {}
end

local function findSites(defenderIndex)
	local list = {}
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "BombSite" and (defenderIndex == nil or d:GetAttribute("Defender") == defenderIndex) then
				table.insert(list, d)
			end
		end
	end
	table.sort(list, function(a, b)
		return (a:GetAttribute("Letter") or "") < (b:GetAttribute("Letter") or "")
	end)
	return list
end

-- ¿Tiene el mapa sitios para los dos equipos?
function Bomb.IsAvailable()
	return #findSites(1) >= 1 and #findSites(2) >= 1
end

local function makeVisual(site, color)
	local model = Instance.new("Model")
	model.Name = "BombSite_" .. site.Letter
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, site.Radius * 2, site.Radius * 2)
	ring.CFrame = CFrame.new(site.Position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Material = Enum.Material.ForceField
	ring.Color = color
	ring.Transparency = 0.2
	ring.Parent = model
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 1500
	billboard.Parent = ring
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.2
	label.Text = "💣" .. site.Letter
	label.TextColor3 = color
	label.Parent = billboard
	model.Parent = workspace
	table.insert(visuals, model)
	return model
end

-- Vivos de un equipo dentro de un radio: { jugadores } y cuántos (los bots cuentan, sin lista)
local function inside(team, position, radius)
	local players, count = {}, 0
	local function check(root)
		local offset = root.Position - position
		return Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius and math.abs(offset.Y) < 8
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if player.Team == team and humanoid and humanoid.Health > 0 and root and not player:GetAttribute("InMenu") and check(root) then
			table.insert(players, player)
			count += 1
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if model:GetAttribute("Team") == team.Name and humanoid and humanoid.Health > 0 and root and check(root) then
				count += 1
			end
		end
	end
	return players, count
end

local function explode(site)
	local position = site.Position + Vector3.new(0, 1, 0)
	Remotes.ExplosionFX:FireAllClients(position, 26)
	-- La explosión elimina a quien esté muy cerca (sin baja para nadie)
	local victims = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(victims, player.Character)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			table.insert(victims, model)
		end
	end
	for _, model in victims do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and (root.Position - position).Magnitude < 22 then
			humanoid:SetAttribute("LastAttacker", nil)
			humanoid:SetAttribute("LastBot", nil)
			humanoid:TakeDamage(500)
		end
	end
end

local function setAttr(name, value)
	ReplicatedStorage:SetAttribute("Bomb_" .. name, value)
end

-- Miembros vivos de un equipo (jugadores y bots): { Model, Player, Name, Root }
local function aliveMembers(team)
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if player.Team == team and humanoid and humanoid.Health > 0 and root and not player:GetAttribute("InMenu") then
			table.insert(list, { Model = character, Player = player, Name = player.Name, Root = root })
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if model:GetAttribute("Team") == team.Name and humanoid and humanoid.Health > 0 and root then
				table.insert(list, { Model = model, Name = model.Name, Root = root })
			end
		end
	end
	return list
end

-- Raíz del portador si sigue vivo (si murió o reapareció con otro cuerpo, nil)
local function carrierRoot()
	if not carrier then
		return nil
	end
	local model = carrier.Model
	if not model or not model.Parent or (carrier.Player and carrier.Player.Character ~= model) then
		return nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root then
		return root
	end
	return nil
end

local function clearDropped()
	droppedAt = nil
	if droppedVisual then
		droppedVisual:Destroy()
		droppedVisual = nil
	end
	setAttr("Dropped", nil)
end

local function setCarrier(member)
	clearDropped()
	carrier = member and { Model = member.Model, Player = member.Player, Name = member.Name, LastPosition = member.Root.Position } or nil
	setAttr("Carrier", member and member.Name or nil)
	if member and member.Player then
		Remotes.Notify:FireClient(member.Player, "Big", "💣 ¡LLEVAS LA BOMBA! Plántala en A o B")
	end
end

local function dropBomb(position, attackers)
	carrier = nil
	setAttr("Carrier", nil)
	droppedAt = position
	setAttr("Dropped", position)
	local part = Instance.new("Part")
	part.Name = "DroppedBomb"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = Vector3.new(1.4, 0.8, 1)
	part.Color = Color3.fromRGB(60, 60, 55)
	part.Material = Enum.Material.Metal
	part.CFrame = CFrame.new(position - Vector3.new(0, 2.3, 0))
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(36, 36)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 250
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = "💣"
	label.Parent = billboard
	part.Parent = workspace
	droppedVisual = part
	for _, player in Players:GetPlayers() do
		if player.Team == attackers then
			Remotes.Notify:FireClient(player, "Info", "💣 ¡La bomba está en el suelo! Recógela")
		end
	end
end

-- Cada paso sin plantar: quién lleva la bomba (si su portador cae, se queda en el suelo)
local function updateCarrier(attackers)
	if carrier then
		local root = carrierRoot()
		if root then
			carrier.LastPosition = root.Position
			return
		end
		dropBomb(carrier.LastPosition, attackers)
	end
	local members = aliveMembers(attackers)
	if droppedAt then
		for _, member in members do
			if (member.Root.Position - droppedAt).Magnitude <= PICKUP_RADIUS then
				setCarrier(member)
				return
			end
		end
	elseif #members > 0 then
		setCarrier(members[math.random(1, #members)])
	end
end

-- ¿Está el portador dentro del sitio?
local function carrierIn(site)
	local root = carrierRoot()
	if not root then
		return false
	end
	local offset = root.Position - site.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= site.Radius and math.abs(offset.Y) < 8
end

-- Empieza una ronda: attackers plantan en los sitios de la mitad de defenders
function Bomb.Start(attackers, defenders)
	Bomb.Stop()
	local defenderIndex = 1
	for i, cfg in GameConfig.Teams do
		if cfg.Name == defenders.Name then
			defenderIndex = i
		end
	end
	sites = {}
	for _, part in findSites(defenderIndex) do
		local site = { Letter = part:GetAttribute("Letter") or "A", Position = part.Position, Radius = part:GetAttribute("Radius") or 7 }
		site.Visual = makeVisual(site, Color3.fromRGB(255, 200, 60))
		setAttr(site.Letter .. "_Position", site.Position)
		table.insert(sites, site)
	end
	if #sites == 0 then
		return false
	end
	local s = settings()
	local plantTime, defuseTime, bombTime = s.PlantTime or 4, s.DefuseTime or 6, s.BombTime or 35
	Bomb.Result, Bomb.Planted, Bomb.Site = nil, false, nil
	carrier = nil
	clearDropped()
	setAttr("Carrier", nil)
	setAttr("Attackers", attackers.Name)
	setAttr("Defenders", defenders.Name)
	setAttr("State", "Idle")
	setAttr("Action", "")
	setAttr("Progress", 0)
	setAttr("Site", nil)
	setAttr("Timer", nil)
	active = true
	thread = task.spawn(function()
		local progress, site, explodeAt = 0, nil, nil
		while active do
			-- (el progreso con el tiempo de verdad: con el servidor cargado la espera dura más)
			local dt = task.wait(STEP)
			if not Bomb.Planted then
				-- Plantar: el portador de la bomba, vivo dentro de un sitio y sin salir de él
				updateCarrier(attackers)
				local here, players = nil, {}
				if site and carrierIn(site) then
					here = site
				end
				for _, candidate in sites do
					if here then
						break
					end
					if carrierIn(candidate) then
						here = candidate
					end
				end
				if here and carrier and carrier.Player then
					players = { carrier.Player }
				end
				if here and (site == nil or site == here) then
					site = here
					progress += dt / plantTime
					setAttr("Action", "Planting")
					setAttr("Site", site.Letter)
					if progress >= 1 then
						Bomb.Planted, Bomb.Site = true, site.Letter
						carrier = nil
						setAttr("Carrier", nil)
						explodeAt = os.clock() + bombTime
						progress = 0
						setAttr("State", "Planted")
						setAttr("Action", "")
						Remotes.Notify:FireAllClients("Big", "💣 ¡BOMBA PLANTADA EN " .. site.Letter .. "!")
						for _, player in players do
							task.spawn(PlayerData.AddXP, player, 50, "💣 Bomba plantada")
						end
						for _, visual in visuals do
							if visual.Name ~= "BombSite_" .. site.Letter then
								visual:Destroy()
							end
						end
						local ring = site.Visual and site.Visual:FindFirstChild("Ring")
						if ring then
							ring.Color = Color3.fromRGB(255, 50, 40)
						end
					end
				else
					progress, site = 0, nil
					setAttr("Action", "")
					setAttr("Site", nil)
				end
				setAttr("Progress", math.floor(progress * 100 + 0.5) / 100)
			else
				local remaining = explodeAt - os.clock()
				setAttr("Timer", math.max(0, math.ceil(remaining)))
				-- Desactivar: algún defensor vivo junto a la bomba
				local players, count = inside(defenders, site.Position, site.Radius)
				if count > 0 then
					progress += dt / defuseTime
					setAttr("Action", "Defusing")
					if progress >= 1 then
						Bomb.Result = "Defused"
						setAttr("State", "Defused")
						setAttr("Action", "")
						Remotes.Notify:FireAllClients("Big", "✅ ¡BOMBA DESACTIVADA!")
						for _, player in players do
							task.spawn(PlayerData.AddXP, player, 60, "✅ Bomba desactivada")
						end
						active = false
					end
				else
					progress = 0
					setAttr("Action", "")
				end
				setAttr("Progress", math.floor(progress * 100 + 0.5) / 100)
				if active and remaining <= 0 then
					Bomb.Result = "Exploded"
					setAttr("State", "Exploded")
					setAttr("Action", "")
					explode(site)
					Remotes.Notify:FireAllClients("Big", "💥 ¡LA BOMBA HA EXPLOTADO!")
					active = false
				end
			end
		end
	end)
	return true
end

-- Para los bots: los sitios de esta ronda
function Bomb.Sites()
	return sites
end

function Bomb.Stop()
	active = false
	if thread and coroutine.status(thread) ~= "dead" and thread ~= coroutine.running() then
		pcall(task.cancel, thread)
	end
	thread = nil
	for _, visual in visuals do
		visual:Destroy()
	end
	visuals = {}
	sites = {}
	carrier = nil
	clearDropped()
	for _, name in { "Attackers", "Defenders", "A_Position", "B_Position", "State", "Site", "Timer", "Action", "Progress", "Carrier" } do
		setAttr(name, nil)
	end
end

return Bomb
