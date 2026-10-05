-- Manda al servidor hacia dónde miras arriba/abajo (unas pocas veces por segundo y solo si cambia), para
-- que los demás te vean apuntar con el arma inclinada (RiflePose, en sus clientes)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)
local ClientState = require(script.Parent.ClientState)

local AimPitch = {}

AimPitch.Interval = 0.2 -- segundos entre envíos
AimPitch.Threshold = 0.05 -- cambio mínimo (radianes, unos 3°) para mandarlo

local player = Players.LocalPlayer
local clock = 0
local lastSent = 0

function AimPitch.Current()
	local camera = workspace.CurrentCamera
	if not camera then
		return 0
	end
	return math.asin(math.clamp(camera.CFrame.LookVector.Y, -1, 1))
end

function AimPitch.Update(dt)
	clock += dt
	if clock < AimPitch.Interval then
		return
	end
	clock = 0
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or ClientState.InMainMenu or ClientState.Dead or ClientState.KillcamActive then
		return
	end
	local pitch = AimPitch.Current()
	if math.abs(pitch - lastSent) >= AimPitch.Threshold then
		lastSent = pitch
		Remotes.AimPitch:FireServer(pitch)
	end
end

function AimPitch.Init()
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(AimPitch.Update, dt)
		if not ok then
			warn("[AimPitch]", err)
		end
	end)
	-- (personaje nuevo: se vuelve a mandar aunque mire igual)
	player.CharacterAdded:Connect(function()
		lastSent = 1000
	end)
end

return AimPitch
