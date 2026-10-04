-- Evento de temporada (GameConfig.Event, ahora Halloween): durante las rondas van apareciendo
-- caramelos por el mapa (en los puntos de aparición libres). Al tocar uno: monedas y +1 al contador
-- del evento (se guarda); hay premios por el camino (Milestones) y al llegar a Goal se gana la
-- skin exclusiva. También pone calabazas en los
-- mapas (Event.Decorate lo llama MapBuilder). Los bots no recogen caramelos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Skins = require(Shared.Skins)
local Outfits = require(Shared.Outfits)

local PlayerData = require(script.Parent.PlayerData)
local Kit = require(script.Parent.MapKit)

local Event = {}

local CONFIG = GameConfig.Event
local CANDY_COLORS = {
	Color3.fromRGB(255, 130, 20),
	Color3.fromRGB(170, 80, 255),
	Color3.fromRGB(120, 230, 60),
	Color3.fromRGB(255, 70, 120),
}

local folder
local candies = {}
local lastPickup = {} -- [player] = os.clock() (límite de recogida)
local LIFETIME = 60 -- segundos que dura un caramelo sin recoger
local PICKUP_RANGE = 9 -- distancia máxima real al caramelo (contra trampas de "toque" a distancia)

local function enabled()
	return CONFIG and CONFIG.Enabled and (CONFIG.EndsAt == nil or os.time() < CONFIG.EndsAt)
end

-- Puntos libres del mapa actual (FFASpawn); se guardan mientras no cambie el mapa
local cachedMap, cachedPoints = nil, {}
local function spawnPoints()
	local map = workspace:FindFirstChild("Map")
	if map ~= cachedMap then
		cachedMap, cachedPoints = map, {}
		if map then
			for _, d in map:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "FFASpawn" then
					table.insert(cachedPoints, d.Position)
				end
			end
		end
	end
	return cachedPoints
end

local function clear()
	for _, candy in candies do
		candy:Destroy()
	end
	table.clear(candies)
end

local function collect(player, candy)
	if not candy.Parent or candy:GetAttribute("Taken") then
		return
	end
	-- Comprobaciones del servidor: de verdad cerca y no demasiado seguido
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - candy.Position).Magnitude > PICKUP_RANGE then
		return
	end
	if os.clock() - (lastPickup[player] or 0) < 0.25 then
		return
	end
	lastPickup[player] = os.clock()
	candy:SetAttribute("Taken", true)
	local index = table.find(candies, candy)
	if index then
		table.remove(candies, index)
	end
	candy:Destroy()
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	if type(data.EventProgress) ~= "table" or data.EventProgress.Id ~= CONFIG.Id then
		data.EventProgress = { Id = CONFIG.Id, Count = 0 }
	end
	if type(data.EventProgress.Claimed) ~= "table" then
		-- Premios por el camino ya dados ("m25" = true). Los que ya se pasaron antes de existir esta
		-- lista se dieron al llegar justo a su número: se marcan como dados para no pagarlos dos veces
		local claimed = {}
		for _, milestone in CONFIG.Milestones or {} do
			if data.EventProgress.Count >= milestone.Count then
				claimed["m" .. milestone.Count] = true
			end
		end
		data.EventProgress.Claimed = claimed
	end
	data.EventProgress.Count += 1
	local count = data.EventProgress.Count
	PlayerData.MarkDirty(player)
	local coins = PlayerData.AddCoins(player, CONFIG.CandyCoins) -- (envía los datos al cliente, contador incluido)
	Remotes.Notify:FireClient(player, "XP", "🍬 Caramelo  +" .. coins .. " 🪙  (" .. math.min(count, CONFIG.Goal) .. "/" .. CONFIG.Goal .. ")")
	-- Premios por el camino (también los que quedaron atrás si el premio se añadió con el evento empezado)
	local claimed = data.EventProgress.Claimed
	for _, milestone in CONFIG.Milestones or {} do
		local key = "m" .. milestone.Count
		if count >= milestone.Count and milestone.Count < CONFIG.Goal and not claimed[key] then
			claimed[key] = true
			if milestone.Outfit and PlayerData.GiveOutfit(player, milestone.Outfit) then
				local outfit = Outfits.Get(milestone.Outfit)
				Remotes.Notify:FireClient(player, "Challenge", "🎃 ¡" .. milestone.Count .. " caramelos! Traje " .. outfit.Name .. " desbloqueado")
			else
				local amount = milestone.Coins or milestone.Compensate or 0
				if amount > 0 then
					PlayerData.AddCoins(player, amount, false) -- premio fijo (no lo dobla el VIP)
					Remotes.Notify:FireClient(player, "Challenge", "🎃 ¡" .. milestone.Count .. " caramelos! +" .. amount .. " 🪙")
				end
			end
		end
	end
	if count >= CONFIG.Goal and PlayerData.GiveSkin(player, CONFIG.RewardSkin) then
		local skin = Skins.Get(CONFIG.RewardSkin)
		Remotes.Notify:FireClient(player, "Challenge", "🎃 ¡Skin " .. skin.Name .. " desbloqueada!")
	end
end

-- Raycast solo contra el mapa (ni jugadores ni bots)
local mapParams = RaycastParams.new()
mapParams.FilterType = Enum.RaycastFilterType.Include

local function groundAt(position, up, down)
	local map = workspace:FindFirstChild("Map")
	if not map then
		return nil
	end
	mapParams.FilterDescendantsInstances = { map, workspace.Terrain }
	local hit = workspace:Raycast(position + Vector3.new(0, up, 0), Vector3.new(0, -(up + down), 0), mapParams)
	return hit and hit.Instance.CanCollide and hit.Position or nil
end

local function spawnCandy()
	local points = spawnPoints()
	if #points == 0 then
		return
	end
	local base = points[math.random(1, #points)]
	-- Cerca del punto, sobre el suelo y sin meterse en paredes (si no, en el propio punto)
	local position = base + Vector3.new(0, 2.2, 0)
	for _ = 1, 4 do
		local candidate = base + Vector3.new(math.random(-40, 40) / 10, 0, math.random(-40, 40) / 10)
		local floor = groundAt(candidate, 2, 4)
		if floor and math.abs(floor.Y - base.Y) < 1.5 then
			local mapFolder = workspace:FindFirstChild("Map")
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Include
			overlap.FilterDescendantsInstances = { mapFolder }
			local blocking = false
			for _, part in workspace:GetPartBoundsInRadius(floor + Vector3.new(0, 2.2, 0), 0.9, overlap) do
				if part.CanCollide then
					blocking = true
					break
				end
			end
			if not blocking then
				position = floor + Vector3.new(0, 2.2, 0)
				break
			end
		end
	end
	local candy = Instance.new("Part")
	candy.Name = "Candy"
	candy.Shape = Enum.PartType.Ball
	candy.Size = Vector3.new(1.6, 1.6, 1.6)
	candy.Color = CANDY_COLORS[math.random(1, #CANDY_COLORS)]
	candy.Material = Enum.Material.SmoothPlastic
	candy.Anchored = true
	candy.CanCollide = false
	candy.CanQuery = false
	candy.CanTouch = true
	candy.CastShadow = false
	candy.CFrame = CFrame.new(position)
	candy:SetAttribute("Bob", 0.5) -- flota (lo anima WorldFX en el cliente)
	local light = Instance.new("PointLight")
	light.Color = candy.Color
	light.Range = 8
	light.Brightness = 1
	light.Parent = candy
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(candy.Color)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.4, 0)
	sparkle.Lifetime = NumberRange.new(0.5, 0.8)
	sparkle.Rate = 5
	sparkle.Speed = NumberRange.new(1, 2)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Parent = candy
	candy.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if player and humanoid and humanoid.Health > 0 and not player:GetAttribute("InMenu") then
			collect(player, candy)
		end
	end)
	candy.Parent = folder
	table.insert(candies, candy)
	-- Si nadie lo coge, desaparece (y deja sitio a otro)
	task.delay(LIFETIME, function()
		if candy.Parent then
			local index = table.find(candies, candy)
			if index then
				table.remove(candies, index)
			end
			candy:Destroy()
		end
	end)
end

-- Calabazas junto a algunos puntos libres del mapa (determinista: siempre en los mismos sitios)
function Event.Decorate()
	if not enabled() or not CONFIG.Pumpkins then
		return
	end
	local points = spawnPoints()
	local rng = Random.new(#points * 7 + 3)
	for i, point in points do
		if i % 3 == 1 then
			local offset = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
			if offset.Magnitude < 0.1 then
				offset = Vector3.xAxis
			end
			-- Sobre el suelo que haya debajo (si el punto está en una plataforma, que no flote en el aire)
			local ground = groundAt(point + offset.Unit * 5, 3, 4)
			if ground then
				Kit.pumpkin(CFrame.new(ground) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), rng:NextNumber(0.8, 1.3))
			end
		end
	end
end

function Event.Init()
	if not enabled() then
		return
	end
	folder = Instance.new("Folder")
	folder.Name = "EventCandies"
	folder.Parent = workspace
	ReplicatedStorage:SetAttribute("EventName", CONFIG.Name)
	ReplicatedStorage:SetAttribute("EventGoal", CONFIG.Goal)
	Players.PlayerRemoving:Connect(function(player)
		lastPickup[player] = nil
	end)
	ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
		if ReplicatedStorage:GetAttribute("State") ~= "Playing" then
			clear()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(CONFIG.SpawnEvery)
			-- Se acabó la fecha del evento con el servidor encendido: fuera caramelos y contador
			if not enabled() then
				clear()
				ReplicatedStorage:SetAttribute("EventName", nil)
				return
			end
			local playing = ReplicatedStorage:GetAttribute("State") == "Playing" and not ReplicatedStorage:GetAttribute("Frozen")
			if playing and #candies < CONFIG.MaxCandies then
				local ok, err = pcall(spawnCandy)
				if not ok then
					warn("[Event] caramelo:", err)
				end
			end
		end
	end)
end

Event.Collect = collect -- (para las pruebas)
return Event
