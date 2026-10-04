-- Apariciones dinámicas en los modos por equipos (como en los shooters de móvil): al reaparecer
-- no se vuelve siempre a la base, sino al punto del mapa (FFASpawn o una salida del equipo) más
-- seguro: lejos de los enemigos y, a ser posible, cerca de los compañeros. La primera aparición de
-- cada ronda sigue siendo en la base. Lo usan Round (jugadores) y Bots.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local SpawnPicker = {}

local MODES = { TDM = true, KOTH = true, CAL = true } -- (en bandera y eliminación, siempre en la base)
local SAFE_DISTANCE = 40 -- un enemigo más cerca que esto descarta el punto

local cache = { Map = nil, Free = {}, ByColor = {} }

local function points()
	local map = workspace:FindFirstChild("Map")
	if cache.Map ~= map then
		cache.Map, cache.Free, cache.ByColor = map, {}, {}
		if map then
			for _, d in map:GetDescendants() do
				if d:IsA("SpawnLocation") then
					local key = d.TeamColor.Name
					cache.ByColor[key] = cache.ByColor[key] or {}
					table.insert(cache.ByColor[key], d.Position)
				elseif d:IsA("BasePart") and d.Name == "FFASpawn" then
					table.insert(cache.Free, d.Position)
				end
			end
		end
	end
	return cache
end

-- ¿Se usan apariciones dinámicas ahora mismo?
function SpawnPicker.Enabled()
	return GameConfig.DynamicSpawns ~= false
		and ReplicatedStorage:GetAttribute("TeamMode") == true
		and MODES[ReplicatedStorage:GetAttribute("Mode") or ""] == true
		and not ReplicatedStorage:GetAttribute("Infection")
end

-- Mejor punto para alguien del equipo team (selfModel = su propio personaje, que no cuenta)
function SpawnPicker.Pick(team, selfModel)
	if not team then
		return nil
	end
	local data = points()
	local candidates = table.clone(data.Free)
	for _, p in data.ByColor[team.TeamColor.Name] or {} do
		table.insert(candidates, p)
	end
	if #candidates == 0 then
		return nil
	end
	local enemies, friends = {}, {}
	local function add(model, modelTeam)
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if model ~= selfModel and humanoid and humanoid.Health > 0 and root then
			table.insert(modelTeam == team.Name and friends or enemies, root.Position)
		end
	end
	for _, player in Players:GetPlayers() do
		if player.Character and player.Team and not player:GetAttribute("InMenu") then
			add(player.Character, player.Team.Name)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			add(model, model:GetAttribute("Team"))
		end
	end
	local best, bestScore = nil, -math.huge
	for _, point in candidates do
		local nearestEnemy, nearestFriend = math.huge, math.huge
		for _, p in enemies do
			nearestEnemy = math.min(nearestEnemy, (p - point).Magnitude)
		end
		for _, p in friends do
			nearestFriend = math.min(nearestFriend, (p - point).Magnitude)
		end
		local score = math.min(nearestEnemy, 140) - math.min(nearestFriend, 120) * 0.35 + math.random() * 12
		if nearestEnemy < SAFE_DISTANCE then
			score -= 1000 -- (solo si no queda otra)
		end
		if score > bestScore then
			best, bestScore = point, score
		end
	end
	return best
end

return SpawnPicker
