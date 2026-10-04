-- Insignias de Roblox (BadgeService). Se dan solas al cumplir cada logro. Con ID 0 no se da
-- (créalas en el Creator Hub → tu experiencia → Insignias y pega los ID en GameConfig.Badges).
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local Badges = {}

local awarded = {} -- [player] = { [nombre] = true } (para no repetir llamadas en la sesión)

-- Logros: nombre en GameConfig.Badges -> condición sobre los datos del jugador
local RULES = {
	{ Name = "Welcome", Check = function(_data)
		return true
	end },
	{ Name = "FirstKill", Check = function(data)
		return (data.TotalKills or 0) >= 1
	end },
	{ Name = "Kills100", Check = function(data)
		return (data.TotalKills or 0) >= 100
	end },
	{ Name = "FirstWin", Check = function(data)
		return (data.Wins or 0) >= 1
	end },
	{ Name = "Level10", Check = function(data)
		return (data.Level or 1) >= 10
	end },
}

local function award(player, name)
	local id = GameConfig.Badges and GameConfig.Badges[name]
	if type(id) ~= "number" or id == 0 then
		return
	end
	awarded[player] = awarded[player] or {}
	if awarded[player][name] then
		return
	end
	awarded[player][name] = "pending"
	task.spawn(function()
		local ok, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, id)
		local done = ok and has
		if ok and not has and player.Parent then
			done = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, id)
		end
		-- Si falló (p. ej. demasiadas peticiones), se reintenta la próxima vez que se compruebe
		if awarded[player] then
			awarded[player][name] = done and true or nil
		end
	end)
end

-- Revisa los logros con los datos actuales (lo llama PlayerData al cargar y cuando cambian)
function Badges.Check(player, data)
	if not data then
		return
	end
	for _, rule in RULES do
		if rule.Check(data) then
			award(player, rule.Name)
		end
	end
end

function Badges.Forget(player)
	awarded[player] = nil
end

return Badges
