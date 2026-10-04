-- Evento de temporada (GameConfig.Event, ahora Halloween): durante las rondas van apareciendo
-- caramelos por el mapa (en los puntos de aparición libres). Al tocar uno: monedas y +1 al contador
-- del evento (se guarda); al llegar a Goal se gana la skin exclusiva. También pone calabazas en los
-- mapas (Event.Decorate lo llama MapBuilder). Los bots no recogen caramelos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Skins = require(Shared.Skins)

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

local function enabled()
	return CONFIG and CONFIG.Enabled
end

-- Puntos libres del mapa actual (FFASpawn)
local function spawnPoints()
	local points = {}
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "FFASpawn" then
				table.insert(points, d.Position)
			end
		end
	end
	return points
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
	data.EventProgress.Count += 1
	local count = data.EventProgress.Count
	PlayerData.AddCoins(player, CONFIG.CandyCoins)
	PlayerData.MarkDirty(player)
	PlayerData.SendUpdate(player)
	Remotes.Notify:FireClient(player, "XP", "🍬 Caramelo  +" .. CONFIG.CandyCoins .. " 🪙  (" .. math.min(count, CONFIG.Goal) .. "/" .. CONFIG.Goal .. ")")
	if count == CONFIG.Goal and PlayerData.GiveSkin(player, CONFIG.RewardSkin) then
		local skin = Skins.Get(CONFIG.RewardSkin)
		Remotes.Notify:FireClient(player, "Challenge", "🎃 ¡Skin " .. skin.Name .. " desbloqueada!")
	end
end

local function spawnCandy()
	local points = spawnPoints()
	if #points == 0 then
		return
	end
	local base = points[math.random(1, #points)]
	local position = base + Vector3.new(math.random(-40, 40) / 10, 2.2, math.random(-40, 40) / 10)
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
			local probe = point + offset.Unit * 5 + Vector3.new(0, 3, 0)
			local hit = workspace:Raycast(probe, Vector3.new(0, -7, 0))
			if hit and hit.Instance.CanCollide then
				Kit.pumpkin(CFrame.new(hit.Position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), rng:NextNumber(0.8, 1.3))
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
	ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
		if ReplicatedStorage:GetAttribute("State") ~= "Playing" then
			clear()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(CONFIG.SpawnEvery)
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
