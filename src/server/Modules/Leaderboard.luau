-- Clasificación global (todos los servidores): top 10 de bajas y de victorias.
-- Se guarda en OrderedDataStores y se publica a los clientes como texto JSON en atributos de
-- ReplicatedStorage ("Leaderboard_Kills", "Leaderboard_Wins") para la pantalla de inicio.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)

local Leaderboard = {}

local REFRESH = 90 -- segundos entre actualizaciones (los DataStores tienen límite de peticiones)
local TOP = 10

local BOARDS = {
	{ Id = "Kills", Store = "TopBajas_v1", Field = "TotalKills" },
	{ Id = "Wins", Store = "TopVictorias_v1", Field = "Wins" },
}

local stores = {}
local pushed = {} -- [userId .. board] = último valor enviado
local names = {} -- caché de nombres por UserId

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local online = Players:GetPlayerByUserId(userId)
	if online then
		names[userId] = online.Name
		return online.Name
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(name) == "string" then
		names[userId] = name
		return name
	end
	return "Jugador"
end

-- Sube los números de un jugador (solo si han cambiado)
local function push(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	for _, board in BOARDS do
		local store = stores[board.Id]
		local value = math.floor(tonumber(data[board.Field]) or 0)
		local k = player.UserId .. board.Id
		if store and value > 0 and pushed[k] ~= value then
			-- Nunca baja un récord (por ejemplo si sus datos no cargaron y empieza de 0)
			local ok = pcall(function()
				store:UpdateAsync(tostring(player.UserId), function(old)
					return math.max(tonumber(old) or 0, value)
				end)
			end)
			if ok then
				pushed[k] = value
			end
		end
	end
end

local function fetch()
	for _, board in BOARDS do
		local store = stores[board.Id]
		if store then
			local ok, page = pcall(function()
				return store:GetSortedAsync(false, TOP):GetCurrentPage()
			end)
			if ok and type(page) == "table" then
				local rows = {}
				for rank, entry in page do
					local userId = tonumber(entry.key)
					if userId then
						table.insert(rows, { Rank = rank, UserId = userId, Name = nameOf(userId), Value = entry.value })
					end
				end
				ReplicatedStorage:SetAttribute("Leaderboard_" .. board.Id, HttpService:JSONEncode(rows))
			end
		end
	end
end

function Leaderboard.Init()
	for _, board in BOARDS do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(board.Store)
		end)
		if ok then
			stores[board.Id] = store
		end
	end
	if next(stores) == nil then
		warn("[Leaderboard] Sin acceso a DataStores: no hay clasificación global")
		return
	end
	Players.PlayerRemoving:Connect(push)
	task.spawn(function()
		task.wait(10)
		while true do
			for _, player in Players:GetPlayers() do
				push(player)
			end
			fetch()
			task.wait(REFRESH)
		end
	end)
end

return Leaderboard
