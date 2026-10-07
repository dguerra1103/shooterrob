-- Vida que se recupera sola, como en los shooters de móvil: tras GameConfig.HealthRegen.Delay
-- segundos sin recibir daño, la vida sube deprisa hasta llenarse. Para jugadores y bots.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local HealthRegen = {}

local STEP = 0.25

-- perk: la ventaja "Persistente" (GameConfig.Perks) empieza antes y recupera más deprisa
local function regen(humanoid, now, config, perk)
	if humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return
	end
	local hitTime = humanoid:GetAttribute("LastHitTime") or 0
	if now - hitTime < ((perk and perk.RegenDelay) or config.Delay) then
		return
	end
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + config.PerSecond * ((perk and perk.RegenMultiplier) or 1) * STEP)
end

local function perkOf(player)
	local id = player:GetAttribute("Perk")
	for _, perk in GameConfig.Perks or {} do
		if perk.Id == id then
			return perk
		end
	end
	return nil
end

function HealthRegen.Init()
	local config = GameConfig.HealthRegen
	if not config or not config.Enabled then
		return
	end
	task.spawn(function()
		while true do
			task.wait(STEP)
			local ok, err = pcall(function()
				local now = os.clock()
				for _, player in Players:GetPlayers() do
					local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						regen(humanoid, now, config, perkOf(player))
					end
				end
				local bots = workspace:FindFirstChild("Bots")
				if bots then
					for _, model in bots:GetChildren() do
						local humanoid = model:FindFirstChildOfClass("Humanoid")
						if humanoid then
							regen(humanoid, now, config)
						end
					end
				end
			end)
			if not ok then
				warn("[HealthRegen] Error en el bucle:", err)
			end
		end
	end)
end

return HealthRegen
