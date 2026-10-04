-- Regalos por tiempo jugado (GameConfig.PlaytimeGifts): cada pocos minutos de sesión hay un regalo
-- que se recoge con el botón 🎁 (monedas, XP o revivir instantáneos). El servidor cuenta el tiempo.
-- Atributos del jugador para la interfaz: GiftStart (hora del servidor al entrar) y GiftsClaimed.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)

local Gifts = {}

local started = {} -- [player] = os.clock() al entrar
local claimed = {} -- [player] = regalos recogidos

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
	local index = (claimed[player] or 0) + 1
	local gift = GameConfig.PlaytimeGifts[index]
	if not gift or not started[player] then
		return false, "No hay más regalos hoy"
	end
	if os.clock() - started[player] < gift.Minutes * 60 - 1 then
		return false, "Todavía no"
	end
	if not PlayerData.Get(player) then
		return false, "Cargando tus datos"
	end
	claimed[player] = index
	player:SetAttribute("GiftsClaimed", index)
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
		player:SetAttribute("GiftStart", workspace:GetServerTimeNow())
		player:SetAttribute("GiftsClaimed", 0)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		started[player] = nil
		claimed[player] = nil
	end)
end

return Gifts
