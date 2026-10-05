-- Sonidos de los demás que dan información, como en los shooters: si alguien recarga cerca (jugador o
-- bot), se oye su cargador saliendo y entrando en su posición. Solo de cerca (unos 70 studs): así se
-- sabe que es buen momento para asomarse. Solo en este cliente.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared.Sounds)
local Weapons = require(Shared.Weapons)

local ClientState = require(script.Parent.ClientState)

local EnemySounds = {}

EnemySounds.Range = 70 -- hasta dónde se oye una recarga
EnemySounds.Interval = 0.15 -- cada cuánto se mira quién está recargando

local player = Players.LocalPlayer
local reloading = setmetatable({}, { __mode = "k" }) -- [Tool] = true mientras recarga
local clock = 0

local function heldTools()
	local list = {}
	local function add(model)
		if model then
			local tool = model:FindFirstChildOfClass("Tool")
			if tool and tool:GetAttribute("Weapon") then
				table.insert(list, tool)
			end
		end
	end
	for _, p in Players:GetPlayers() do
		if p ~= player then
			add(p.Character)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			add(model)
		end
	end
	return list
end

local function play(name, handle, pitch, volume)
	local sound = Sounds.Play(name, handle, pitch, volume)
	if sound then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 6
		sound.RollOffMaxDistance = EnemySounds.Range
	end
	return sound
end

-- Empieza la recarga de alguien: cargador fuera y, un poco después, dentro
function EnemySounds.OnReload(tool)
	local handle = tool:FindFirstChild("Handle")
	local camera = workspace.CurrentCamera
	if not handle or not handle:IsA("BasePart") or not camera then
		return false
	end
	if (handle.Position - camera.CFrame.Position).Magnitude > EnemySounds.Range then
		return false
	end
	local def = Weapons.Get(tool:GetAttribute("Weapon"))
	local duration = def and def.ReloadTime or 2
	play("MagOut", handle, 1, 0.8)
	task.delay(duration * 0.5, function()
		if tool.Parent and tool:GetAttribute("Reloading") and handle.Parent then
			play("MagIn", handle, 1, 0.9)
		end
	end)
	return true
end

function EnemySounds.Update(dt)
	clock += dt
	if clock < EnemySounds.Interval then
		return
	end
	clock = 0
	if ClientState.InMainMenu then
		return
	end
	for _, tool in heldTools() do
		local now = tool:GetAttribute("Reloading") == true
		if now and not reloading[tool] then
			EnemySounds.OnReload(tool)
		end
		reloading[tool] = now or nil
	end
end

function EnemySounds.Init()
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(EnemySounds.Update, dt)
		if not ok then
			warn("[EnemySounds]", err)
		end
	end)
end

return EnemySounds
