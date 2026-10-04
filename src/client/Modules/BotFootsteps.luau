-- Pasos de los bots (solo en el cliente). Los personajes de los jugadores ya suenan al correr con los
-- sonidos de Roblox, pero los bots no: aquí cada bot cercano lleva el mismo sonido de pasos en bucle,
-- más rápido cuanto más corre, y solo mientras se mueve por el suelo. Los enemigos se oyen más que
-- los compañeros (como en los shooters: oír los pasos del rival es información).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BotFootsteps = {}

local SOUND_ID = "rbxasset://sounds/action_footsteps_plastic.mp3"
local MAX_DISTANCE = 90 -- más lejos no se oyen (y no se gastan sonidos)
local CHECK_INTERVAL = 0.1
local ENEMY_VOLUME = 0.8
local ALLY_VOLUME = 0.35

local player = Players.LocalPlayer
local sounds = {} -- [modelo del bot] = Sound

local function isEnemy(model)
	if ReplicatedStorage:GetAttribute("TeamMode") == false then
		return true
	end
	local team = model:GetAttribute("Team")
	return team == nil or player.Team == nil or team ~= player.Team.Name
end

local function soundFor(model, root)
	local sound = sounds[model]
	if sound and sound.Parent == root then
		return sound
	end
	sound = Instance.new("Sound")
	sound.Name = "Pasos"
	sound.SoundId = SOUND_ID
	sound.Looped = true
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 6
	sound.RollOffMaxDistance = MAX_DISTANCE
	sound.Parent = root
	sounds[model] = sound
	return sound
end

local function update()
	local folder = workspace:FindFirstChild("Bots")
	local camera = workspace.CurrentCamera
	local seen = {}
	if folder and camera then
		for _, model in folder:GetChildren() do
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if humanoid and root and root:IsA("BasePart") and humanoid.Health > 0
				and (root.Position - camera.CFrame.Position).Magnitude < MAX_DISTANCE then
				seen[model] = true
				local velocity = root.AssemblyLinearVelocity
				local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
				local sound = soundFor(model, root)
				-- (en el aire o casi quieto no suenan)
				if speed > 3 and math.abs(velocity.Y) < 6 then
					sound.Volume = isEnemy(model) and ENEMY_VOLUME or ALLY_VOLUME
					sound.PlaybackSpeed = math.clamp(speed / 16, 0.7, 1.6)
					if not sound.IsPlaying then
						sound:Play()
					end
				elseif sound.IsPlaying then
					sound:Stop()
				end
			end
		end
	end
	-- Bots que se alejan, mueren o desaparecen: fuera su sonido
	for model, sound in sounds do
		if not seen[model] then
			sound:Destroy()
			sounds[model] = nil
		end
	end
end

function BotFootsteps.Init()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0
		update()
	end)
end

BotFootsteps.Update = update
return BotFootsteps
