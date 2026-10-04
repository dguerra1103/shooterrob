-- Bonus de amigos: +10% de XP y monedas por cada amigo de Roblox que esté en el mismo servidor
-- (hasta +30%). Anima a invitar a amigos. Atributo del jugador: FriendsHere (cuántos hay).
-- PlayerData lo aplica en su multiplicador de premios.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local Friends = {}

Friends.BonusPerFriend = 0.1
Friends.MaxFriends = 3

local friendsOf = {} -- [player] = { [otherPlayer] = true }

-- Lo llama Round para juntar a los amigos en el mismo equipo (nuevo jugador, su amigo)
Friends.OnFriendship = nil :: ((Player, Player) -> ())?

local function publish(player)
	local count = 0
	for other in friendsOf[player] or {} do
		if other.Parent then
			count += 1
		end
	end
	player:SetAttribute("FriendsHere", count)
end

-- ¿Son amigos de Roblox (y están los dos en este servidor)? Round lo usa para ponerlos en el mismo equipo
function Friends.AreFriends(a, b)
	return friendsOf[a] ~= nil and friendsOf[a][b] == true
end

-- Multiplicador por amigos (1 = sin bonus)
function Friends.Multiplier(player)
	return 1 + Friends.BonusPerFriend * math.min(Friends.MaxFriends, player:GetAttribute("FriendsHere") or 0)
end

local function onPlayer(player)
	friendsOf[player] = friendsOf[player] or {}
	publish(player)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			task.spawn(function()
				local ok, isFriend = pcall(player.IsFriendsWith, player, other.UserId)
				if ok and isFriend and player.Parent and other.Parent then
					if friendsOf[player][other] then
						return -- ya contados (y avisados)
					end
					friendsOf[player][other] = true
					friendsOf[other] = friendsOf[other] or {}
					friendsOf[other][player] = true
					publish(player)
					publish(other)
					-- (Round pone juntos a los amigos si el reparto lo permite)
					if Friends.OnFriendship then
						task.spawn(Friends.OnFriendship, player, other)
					end
					local bonus = math.floor(Friends.BonusPerFriend * 100)
					Remotes.Notify:FireClient(other, "Info", "👥 Tu amigo " .. player.DisplayName .. " ha entrado: +" .. bonus .. "% XP y monedas")
					Remotes.Notify:FireClient(player, "Info", "👥 Juegas con tu amigo " .. other.DisplayName .. ": +" .. bonus .. "% XP y monedas")
				end
			end)
		end
	end
end

function Friends.Init()
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		for other in friendsOf[player] or {} do
			if friendsOf[other] then
				friendsOf[other][player] = nil
				if other.Parent then
					publish(other)
				end
			end
		end
		friendsOf[player] = nil
	end)
end

return Friends
