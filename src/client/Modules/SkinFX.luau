-- Anima las skins arcoíris: las piezas con la etiqueta "RainbowSkin" (ver WeaponModels) van cambiando
-- de color. Cada pieza tiene su fase (RainbowPhase) para que el color recorra el arma como una ola.
-- Funciona igual en tu arma (viewmodel) y en las de los demás. ~30 veces por segundo.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local SkinFX = {}

local TAG = "RainbowSkin"
local SPEED = 0.22 -- vueltas al arcoíris por segundo
local parts = {} -- [part] = { Phase, Sat, Val }

local function add(part)
	if part:IsA("BasePart") then
		parts[part] = {
			Phase = part:GetAttribute("RainbowPhase") or 0,
			Sat = part:GetAttribute("RainbowSat") or 1,
			Val = part:GetAttribute("RainbowVal") or 1,
		}
	end
end

local function remove(part)
	parts[part] = nil
end

function SkinFX.Init()
	for _, part in CollectionService:GetTagged(TAG) do
		add(part)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(remove)
	local accumulator = 0
	RunService.RenderStepped:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 / 30 then
			return
		end
		accumulator = 0
		local t = os.clock() * SPEED
		for part, info in parts do
			if part.Parent then
				part.Color = Color3.fromHSV((t + info.Phase) % 1, info.Sat, info.Val)
			else
				parts[part] = nil
			end
		end
	end)
end

return SkinFX
