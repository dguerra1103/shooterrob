-- Peligros del mapa: pisar lava (material CrackedLava) quita vida cada cuarto de segundo.
local Players = game:GetService("Players")

local Hazards = {}

local LAVA_DAMAGE = 10 -- por cada 0.25 s

function Hazards.Init()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 and humanoid.FloorMaterial == Enum.Material.CrackedLava then
					humanoid:SetAttribute("LastAttacker", nil)
					humanoid:SetAttribute("LastWeapon", nil)
					humanoid:TakeDamage(LAVA_DAMAGE)
				end
			end
		end
	end)
end

return Hazards
