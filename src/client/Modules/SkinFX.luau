-- Anima las skins arcoíris: las piezas con la etiqueta "RainbowSkin" (ver WeaponModels) van cambiando
-- de color. Cada pieza tiene su fase (RainbowPhase) para que el color recorra el arma como una ola.
-- Funciona igual en tu arma (viewmodel) y en las de los demás. ~30 veces por segundo.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local SkinFX = {}

local TAG = "RainbowSkin"
local SPEED = 0.22 -- vueltas al arcoíris por segundo
local parts = {} -- [part] = { Phase, Sat, Val, Viewport }

local function add(part)
	if part:IsA("BasePart") then
		parts[part] = {
			Phase = part:GetAttribute("RainbowPhase") or 0,
			Sat = part:GetAttribute("RainbowSat") or 1,
			Val = part:GetAttribute("RainbowVal") or 1,
			Viewport = part:FindFirstAncestorWhichIsA("ViewportFrame"), -- icono de la interfaz
		}
	end
end

-- ¿Se ve el icono? (el panel del menú cerrado sigue existiendo: no hace falta animar lo que no se ve)
local function guiVisible(gui)
	local node = gui
	while node do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		elseif node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
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
		local shown = {} -- visibilidad de cada icono, calculada una vez por paso
		for part, info in parts do
			if not part.Parent then
				parts[part] = nil
				continue
			end
			local visible
			if info.Viewport then
				visible = shown[info.Viewport]
				if visible == nil then
					visible = guiVisible(info.Viewport)
					shown[info.Viewport] = visible
				end
			else
				-- Arma oculta (la tuya en la mano la sustituye el viewmodel)
				visible = part.LocalTransparencyModifier < 1 and part.Transparency < 1
			end
			if visible then
				part.Color = Color3.fromHSV((t + info.Phase) % 1, info.Sat, info.Val)
			end
		end
	end)
end

return SkinFX
