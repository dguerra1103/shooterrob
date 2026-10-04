-- Ambiente del modo Infección: la pantalla se vuelve más apagada para los supervivientes y verdosa
-- para los zombis, y suena un golpe grave cuando llegan los zombis. Fuera de la Infección, nada.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local player = Players.LocalPlayer

local InfectionFX = {}

local LOOKS = {
	None = { TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0 },
	Prep = { TintColor = Color3.fromRGB(235, 235, 245), Saturation = -0.1, Contrast = 0.05 },
	Survivor = { TintColor = Color3.fromRGB(225, 235, 230), Saturation = -0.25, Contrast = 0.1 },
	Zombie = { TintColor = Color3.fromRGB(190, 255, 170), Saturation = -0.1, Contrast = 0.15 },
}

-- Cambios de ambiente que llevan el golpe grave (llegan los zombis o te conviertes)
local SOUND_ON = { ["Prep>Survivor"] = true, ["Prep>Zombie"] = true, ["Survivor>Zombie"] = true }

function InfectionFX.Init()
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "InfectionTint"
	effect.Enabled = false
	effect.Parent = Lighting
	local current: string = "None"
	local function update()
		local infection = ReplicatedStorage:GetAttribute("Infection")
		local look: string = "None"
		if infection and ReplicatedStorage:GetAttribute("State") == "Playing" then
			if infection == "Prep" then
				look = "Prep"
			elseif player.Team and player.Team.Name == ReplicatedStorage:GetAttribute("TeamB") then
				look = "Zombie"
			else
				look = "Survivor"
			end
		end
		if look == current then
			return
		end
		if SOUND_ON[current .. ">" .. look] then
			Sounds.Play("Infected")
		end
		current = look
		effect.Enabled = true
		local tween = TweenService:Create(effect, TweenInfo.new(1.2), LOOKS[look])
		tween:Play()
		if look == "None" then
			tween.Completed:Once(function()
				if current == "None" then
					effect.Enabled = false
				end
			end)
		end
	end
	ReplicatedStorage:GetAttributeChangedSignal("Infection"):Connect(update)
	ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(update)
	player:GetPropertyChangedSignal("Team"):Connect(update)
	update()
end

return InfectionFX
