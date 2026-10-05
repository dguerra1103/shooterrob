-- Botín: a veces el enemigo que eliminas suelta un paquete de suministros con un rayo de luz del
-- color de su rareza (como el botín de los juegos de disparos con saqueo). Solo lo puede recoger
-- quien hizo la baja, pasando por encima, y desaparece a los LIFETIME segundos. Dentro hay monedas
-- (y XP en los mejores): como nunca sabes qué toca, cada baja tiene su pequeña emoción.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)

local Loot = {}

Loot.Chance = 0.1 -- probabilidad de que una baja a otro jugador suelte botín
Loot.BotChance = 0.06 -- (contra bots, menos, y con los premios a la mitad: que no salga a cuenta "granjear" bots)
Loot.LIFETIME = 15
local RADIUS = 5

-- Rarezas: peso (probabilidad relativa), monedas, XP y color del rayo
Loot.Tiers = {
-- (de media, unas 23 monedas por paquete: un extra, no una segunda fuente de ingresos)
	{ Name = "Común", Weight = 62, Coins = 10, XP = 0, Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Raro", Weight = 26, Coins = 25, XP = 0, Color = Color3.fromRGB(70, 160, 255) },
	{ Name = "Épico", Weight = 10, Coins = 60, XP = 100, Color = Color3.fromRGB(190, 80, 255) },
	{ Name = "Legendario", Weight = 2, Coins = 200, XP = 250, Color = Color3.fromRGB(255, 180, 30) },
}

local active = {} -- { Model, Position, Owner, Tier, Expires }
local folder
local loopRunning = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Suelo bajo el punto (si cae al vacío o a la lava, no hay botín)
local function groundBelow(position)
	local map = workspace:FindFirstChild("Map")
	if not map then
		return position
	end
	rayParams.FilterDescendantsInstances = { map, workspace.Terrain }
	local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), rayParams)
	if not hit then
		return nil
	end
	if hit.Instance:GetAttribute("Hazard") or hit.Instance.Name == "Lava" or hit.Material == Enum.Material.CrackedLava then
		return nil
	end
	return hit.Position
end

function Loot.RollTier(roll)
	local total = 0
	for _, tier in Loot.Tiers do
		total += tier.Weight
	end
	local pick = (roll or math.random()) * total
	for _, tier in Loot.Tiers do
		pick -= tier.Weight
		if pick <= 0 then
			return tier
		end
	end
	return Loot.Tiers[1]
end

local function build(position, tier)
	local model = Instance.new("Model")
	model.Name = "LootDrop"
	model:SetAttribute("Rarity", tier.Name)
	local function part(name, size, cf, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = model
		return p
	end
	local base = CFrame.new(position)
	-- Paquete del color de la rareza (flota y gira en el cliente, con WorldFX)
	local box = part("LootBox", Vector3.new(1.6, 1.1, 1.1), base * CFrame.new(0, 1.4, 0), tier.Color, Enum.Material.SmoothPlastic)
	box:SetAttribute("Bob", 0.3)
	box:SetAttribute("Spin", 90)
	-- Rayo de luz que se ve desde lejos (más alto cuanto mejor el botín)
	local height = 10 + 4 * (table.find(Loot.Tiers, tier) or 1)
	local beam = part("LootBeam", Vector3.new(0.5, height, 0.5), base * CFrame.new(0, height / 2, 0), tier.Color, Enum.Material.Neon)
	beam.Transparency = 0.45
	local light = Instance.new("PointLight")
	light.Color = tier.Color
	light.Range = 10
	light.Brightness = 1.5
	light.Parent = box
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(tier.Color)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.35, 0)
	sparkle.Lifetime = NumberRange.new(0.6, 1)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.SpreadAngle = Vector2.new(60, 60)
	sparkle.Rate = 8
	sparkle.Parent = box
	model.PrimaryPart = box
	return model
end

local function collect(entry, player)
	local tier = entry.Tier
	local scale = entry.Scale or 1
	local coins = PlayerData.AddCoins(player, math.max(1, math.floor(tier.Coins * scale)))
	local xp = math.floor(tier.XP * scale)
	if xp > 0 then
		PlayerData.AddXP(player, xp, "Botín " .. tier.Name)
	end
	Remotes.Notify:FireClient(player, "Loot", { Rarity = tier.Name, Coins = coins, XP = xp, Color = tier.Color })
end

local function step()
	local now = os.clock()
	for i = #active, 1, -1 do
		local entry = active[i]
		local owner = entry.Owner
		local character = owner.Parent and owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local alive = humanoid and humanoid.Health > 0
		if root and alive and (root.Position - entry.Position).Magnitude <= RADIUS then
			table.remove(active, i)
			entry.Model:Destroy()
			collect(entry, owner)
		elseif now >= entry.Expires or not owner.Parent or not entry.Model.Parent then
			table.remove(active, i)
			entry.Model:Destroy()
		end
	end
end

local function ensureLoop()
	if loopRunning then
		return
	end
	loopRunning = true
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.15 or #active == 0 then
			return
		end
		elapsed = 0
		step()
	end)
end

-- Tras una baja: a veces suelta botín para quien la hizo. roll (opcional, para pruebas)
function Loot.MaybeDrop(position, killer, againstBot, roll)
	if typeof(position) ~= "Vector3" or not killer or not killer:IsA("Player") then
		return nil
	end
	if (roll or math.random()) > (againstBot and Loot.BotChance or Loot.Chance) then
		return nil
	end
	local ground = groundBelow(position)
	if not ground then
		return nil
	end
	if not folder or not folder.Parent then
		folder = Instance.new("Folder")
		folder.Name = "Loot"
		folder.Parent = workspace
	end
	local tier = Loot.RollTier()
	local model = build(ground, tier)
	model:SetAttribute("Owner", killer.UserId)
	model.Parent = folder
	-- (contra bots, el premio se escala como las bajas a bots: GameConfig.Bots.RewardScale)
	local scale = againstBot and (GameConfig.Bots and GameConfig.Bots.RewardScale or 0.5) or 1
	table.insert(active, { Model = model, Position = ground, Owner = killer, Tier = tier, Scale = scale, Expires = os.clock() + Loot.LIFETIME })
	ensureLoop()
	-- Solo quien lo ha ganado ve el aviso
	Remotes.Notify:FireClient(killer, "LootDrop", tier.Name)
	return model, tier
end

-- Al acabar la partida o cambiar de mapa, fuera todo el botín
function Loot.Clear()
	for _, entry in active do
		entry.Model:Destroy()
	end
	table.clear(active)
end

Loot.Step = step
Loot.Active = active
Players.PlayerRemoving:Connect(function(player)
	for i = #active, 1, -1 do
		if active[i].Owner == player then
			active[i].Model:Destroy()
			table.remove(active, i)
		end
	end
end)

return Loot
