-- Regalos por tiempo jugado (GameConfig.PlaytimeGifts): cada pocos minutos de sesión hay un regalo
-- que se recoge con el botón 🎁 (monedas, XP o revivir instantáneos). El servidor cuenta el tiempo.
-- El progreso del día (regalos recogidos y tiempo jugado) se guarda con el resto de datos, así que
-- salir y volver a entrar no reinicia la cuenta: al día siguiente empieza de cero.
-- Atributos del jugador para la interfaz: GiftStart (hora del servidor equivalente al inicio de la
-- cuenta) y GiftsClaimed.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Shop = require(Shared.Shop)

local PlayerData = require(script.Parent.PlayerData)

local Gifts = {}

local started = {} -- [player] = os.clock() equivalente al inicio de la cuenta de hoy
local claimed = {} -- [player] = regalos recogidos hoy
local days = {} -- [player] = día (Shop.DayNumber) al que corresponde la cuenta
local restored = {} -- [player] = true cuando ya se ha leído el progreso guardado (antes no se guarda ni se reclama)

local function publish(player)
	player:SetAttribute("GiftStart", workspace:GetServerTimeNow() - (os.clock() - started[player]))
	player:SetAttribute("GiftsClaimed", claimed[player] or 0)
end

-- Si ha cambiado el día (la sesión cruzó la medianoche UTC), la cuenta empieza de cero
local function checkDay(player)
	local today = Shop.DayNumber()
	if started[player] and days[player] ~= today then
		days[player] = today
		started[player] = os.clock()
		claimed[player] = 0
		publish(player)
	end
end

-- Copia el progreso a los datos guardados
local function persist(player)
	local data = PlayerData.Get(player)
	if data and started[player] and restored[player] then
		checkDay(player)
		data.Gifts = { Day = days[player], Claimed = claimed[player] or 0, Seconds = math.floor(os.clock() - started[player]) }
		PlayerData.MarkDirty(player)
	end
end

local function describe(gift)
	local parts = {}
	if gift.Coins then
		table.insert(parts, "+" .. gift.Coins .. " 🪙")
	end
	if gift.XP then
		table.insert(parts, "+" .. gift.XP .. " XP")
	end
	if gift.Revives then
		table.insert(parts, "+" .. gift.Revives .. " 💖 revivir")
	end
	return table.concat(parts, "  ")
end
Gifts.Describe = describe

local function claim(player)
	checkDay(player)
	local index = (claimed[player] or 0) + 1
	local gift = GameConfig.PlaytimeGifts[index]
	if not gift or not started[player] then
		return false, "No hay más regalos hoy"
	end
	if os.clock() - started[player] < gift.Minutes * 60 - 1 then
		return false, "Todavía no"
	end
	if not PlayerData.Get(player) or not restored[player] then
		return false, "Cargando tus datos"
	end
	claimed[player] = index
	player:SetAttribute("GiftsClaimed", index)
	persist(player)
	if gift.Coins then
		PlayerData.AddCoins(player, gift.Coins, false)
	end
	if gift.XP then
		PlayerData.AddXP(player, gift.XP, "Regalo")
	end
	if gift.Revives then
		PlayerData.AddRevives(player, gift.Revives)
	end
	Remotes.Notify:FireClient(player, "Challenge", "🎁 Regalo: " .. describe(gift))
	return true, index
end

function Gifts.Init()
	Remotes.ClaimGift.OnServerInvoke = claim
	local function onPlayer(player)
		started[player] = os.clock()
		claimed[player] = 0
		days[player] = Shop.DayNumber()
		publish(player)
		-- Recupera el progreso de hoy (si ya jugó hoy en otro servidor o antes de salir). Espera lo que
		-- haga falta: hasta entonces no se guarda nada (si no, se borraría el progreso guardado)
		task.spawn(function()
			local data
			while player.Parent and started[player] and not data do
				data = PlayerData.WaitFor(player, 5)
			end
			if not data or not player.Parent or not started[player] then
				return
			end
			local saved = data.Gifts
			if type(saved) == "table" and saved.Day == days[player] then
				claimed[player] = math.max(claimed[player], saved.Claimed or 0)
				started[player] = math.min(started[player], os.clock() - (saved.Seconds or 0))
				publish(player)
			end
			restored[player] = true
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	-- Antes del guardado final (al salir o al cerrar el servidor); después se olvida al jugador
	PlayerData.OnLeaving = function(player)
		persist(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		-- Se limpia un poco después para que el guardado final lo encuentre (el orden de los
		-- eventos de salida no está garantizado)
		task.delay(5, function()
			started[player] = nil
			claimed[player] = nil
			days[player] = nil
			restored[player] = nil
		end)
	end)
	-- Guarda el tiempo jugado de vez en cuando (por si el servidor se cierra de golpe)
	task.spawn(function()
		while true do
			task.wait(30)
			for player in started do
				if player.Parent then
					persist(player)
				end
			end
		end
	end)
end

return Gifts
