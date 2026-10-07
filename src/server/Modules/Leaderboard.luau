-- Clasificación global (todos los servidores): top 10 de bajas, de victorias y de rango (mejor RP).
-- Se guarda en OrderedDataStores y se publica a los clientes como texto JSON en atributos de
-- ReplicatedStorage ("Leaderboard_Kills", "Leaderboard_Wins", "Leaderboard_Rank") para la pantalla de inicio.
-- La de rango es de la temporada en curso (Ranks.Seasons): cada temporada empieza una tabla nueva.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)
local Ranks = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ranks"))

local Leaderboard = {}

local REFRESH = 90 -- segundos entre actualizaciones (los DataStores tienen límite de peticiones)
local TOP = 10

local BOARDS = {
	{ Id = "Kills", Store = "TopBajas_v1", Field = "TotalKills" },
	{ Id = "Wins", Store = "TopVictorias_v1", Field = "Wins" },
	{ Id = "Rank", Store = "TopRango_v1", Field = "RankPoints", Seasonal = true },
}

local stores = {} -- [board.Id] = OrderedDataStore
local storeNames = {} -- [board.Id] = nombre del almacén abierto (cambia con la temporada)

-- Nombre del almacén: el de rango lleva la temporada (la primera conserva el nombre de siempre)
local function storeName(board)
	if not board.Seasonal then
		return board.Store
	end
	local season = Ranks.CurrentSeason()
	return season.Id == Ranks.Seasons[1].Id and board.Store or (board.Store .. "_" .. season.Id)
end

local function openStores()
	for _, board in BOARDS do
		local name = storeName(board)
		if storeNames[board.Id] ~= name then
			local ok, store = pcall(function()
				return DataStoreService:GetOrderedDataStore(name)
			end)
			if ok then
				stores[board.Id] = store
				storeNames[board.Id] = name
			end
		end
	end
end
local pushed = {} -- [userId .. ":" .. tabla] = último valor enviado
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
		-- (tampoco si aún no se pudo abrir la tabla de la temporada nueva: irían a la anterior)
		if board.Seasonal and (data.RankSeason ~= Ranks.CurrentSeason().Id or (tonumber(data.SeasonBest) or 0) <= 0 or storeNames[board.Id] ~= storeName(board)) then
			value = 0 -- (RP de la temporada anterior, o aún no ha jugado de rango en esta: no sale en el top)
		end
		local k = player.UserId .. ":" .. (storeNames[board.Id] or board.Id)
		if store and value > 0 and pushed[k] ~= value then
			-- Nunca baja un récord (por ejemplo si sus datos no cargaron y empieza de 0)
			local ok, err = pcall(function()
				store:UpdateAsync(tostring(player.UserId), function(old)
					return math.max(tonumber(old) or 0, value)
				end)
			end)
			if ok then
				pushed[k] = value
			else
				warn("[Leaderboard] No se pudo subir", board.Id, "de", player.Name, err)
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
	openStores()
	if next(stores) == nil then
		warn("[Leaderboard] Sin acceso a DataStores: no hay clasificación global")
		return
	end
	Players.PlayerRemoving:Connect(function(player)
		local ok, err = pcall(push, player)
		if not ok then
			warn("[Leaderboard] Error al salir", player.Name, err)
		end
		-- (lo ya subido de quien se fue no hace falta recordarlo: la tabla no crece toda la sesión)
		local prefix = player.UserId .. ":"
		for k in pushed do
			if string.sub(k, 1, #prefix) == prefix then
				pushed[k] = nil
			end
		end
	end)
	task.spawn(function()
		task.wait(10)
		while true do
			-- (un fallo en una pasada no para la clasificación para siempre)
			local ok, err = pcall(function()
				openStores() -- (si ha empezado otra temporada, la tabla de rango es otra)
				for _, player in Players:GetPlayers() do
					push(player)
				end
				fetch()
			end)
			if not ok then
				warn("[Leaderboard] Error al actualizar:", err)
			end
			task.wait(REFRESH)
		end
	end)
end

return Leaderboard
