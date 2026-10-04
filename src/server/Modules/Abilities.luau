-- Habilidades: Impulso (E) y Supersalto (Z) se mueven en el cliente (el personaje es suyo en la
-- física); el servidor solo valida la Poción (X), que cura con el tiempo, y avisa a los demás para
-- que vean el efecto.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local Abilities = {}

local lastPotion = {} -- [player] = os.clock()

local function healEffect(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "PotionFX"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(90, 255, 120), Color3.fromRGB(200, 255, 140))
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.8, 1.2)
	emitter.Speed = NumberRange.new(2, 4)
	emitter.SpreadAngle = Vector2.new(40, 40)
	emitter.Acceleration = Vector3.new(0, 4, 0)
	emitter.Rate = 30
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = root
	task.delay(GameConfig.Abilities.Potion.Duration, function()
		emitter.Enabled = false
		task.wait(1.2)
		emitter:Destroy()
	end)
end

-- Cura poco a poco; se corta si el jugador muere
local function usePotion(player)
	local config = GameConfig.Abilities.Potion
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or player:GetAttribute("InMenu") then
		return false
	end
	local now = os.clock()
	if lastPotion[player] and now - lastPotion[player] < config.Cooldown - 0.25 then
		return false
	end
	lastPotion[player] = now
	healEffect(character)
	local steps = 10
	task.spawn(function()
		for _ = 1, steps do
			task.wait(config.Duration / steps)
			if humanoid.Parent == nil or humanoid.Health <= 0 then
				return
			end
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + config.Heal / steps)
		end
	end)
	return true
end
Abilities.UsePotion = usePotion

function Abilities.Init()
	Remotes.UsePotion.OnServerInvoke = usePotion
	Players.PlayerRemoving:Connect(function(player)
		lastPotion[player] = nil
	end)
end

return Abilities
