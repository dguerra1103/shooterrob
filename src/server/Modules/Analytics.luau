-- Analítica de la tienda y del pase con AnalyticsService de Roblox (eventos propios y de economía).
-- Solo nombres de evento y datos del juego (ids de objetos, precios, pestañas): nada personal (ni
-- nombres, ni chat, ni datos de la cuenta). Si AnalyticsService falla o no existe, no pasa nada.
-- El cliente solo puede mandar los eventos de MonetizationConfig.Analytics.ClientEvents (lo que ve:
-- abrir la tienda, previsualizar...) y con límite por minuto; lo que de verdad pasa (compras,
-- reclamar el pase) lo manda solo el servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local MonetizationConfig = require(Shared.Economy.MonetizationConfig)

local Analytics = {}
Analytics.Counts = {} -- [evento] = veces (para las pruebas y para depurar)
Analytics.Recent = {} -- últimos eventos { Name, Fields } (como mucho 50)

local config = MonetizationConfig.Analytics
local service
pcall(function()
	service = game:GetService("AnalyticsService")
end)

-- Datos permitidos: hasta 3 valores cortos (texto o número). Nada de tablas ni instancias.
local function clean(fields)
	local out = {}
	if type(fields) ~= "table" then
		return out
	end
	local count = 0
	for key, value in fields do
		if count >= 3 then
			break
		end
		if type(key) == "string" and #key <= 24 and (type(value) == "string" or type(value) == "number") then
			local text = tostring(value)
			if #text <= 40 then
				out[key] = text
				count += 1
			end
		end
	end
	return out
end

local function customFields(fields)
	local out = {}
	local i = 0
	local keys = {}
	for key in fields do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in keys do
		i += 1
		local ok, enumKey = pcall(function()
			return (Enum :: any).AnalyticsCustomFieldKeys["CustomField0" .. i].Name
		end)
		out[ok and enumKey or ("CustomField0" .. i)] = key .. " - " .. fields[key]
	end
	return out
end

-- Evento propio (store_open, purchase_success...). Devuelve true si se registró.
function Analytics.Event(player, name, fields)
	if not config.Enabled or type(name) ~= "string" then
		return false
	end
	if not (config.ClientEvents[name] or config.ServerEvents[name]) then
		return false
	end
	local cleaned = clean(fields)
	Analytics.Counts[name] = (Analytics.Counts[name] or 0) + 1
	table.insert(Analytics.Recent, { Name = name, Fields = cleaned })
	if #Analytics.Recent > 50 then
		table.remove(Analytics.Recent, 1)
	end
	if service and player then
		pcall(function()
			(service :: any):LogCustomEvent(player, name, 1, customFields(cleaned))
		end)
	end
	return true
end

-- Movimiento de monedas (Source = entran, Sink = salen) para ver la inflación de la economía
function Analytics.Economy(player, flow, amount, balance, transaction, sku)
	if not config.Enabled or not service or not player or (tonumber(amount) or 0) <= 0 then
		return
	end
	pcall(function()
		(service :: any):LogEconomyEvent(
			player,
			(Enum :: any).AnalyticsEconomyFlowType[flow],
			"Monedas",
			math.floor(amount),
			math.floor(tonumber(balance) or 0),
			transaction,
			sku
		)
	end)
end

local budget = {} -- [player] = { Start, Count }

function Analytics.Init()
	Remotes.Track.OnServerEvent:Connect(function(player, name, fields)
		if type(name) ~= "string" or not config.ClientEvents[name] then
			return
		end
		local now = os.clock()
		local entry = budget[player]
		if not entry or now - entry.Start > 60 then
			entry = { Start = now, Count = 0 }
			budget[player] = entry
		end
		entry.Count += 1
		if entry.Count > config.ClientPerMinute then
			return
		end
		Analytics.Event(player, name, fields)
	end)
	Players.PlayerRemoving:Connect(function(player)
		budget[player] = nil
	end)
end

return Analytics
