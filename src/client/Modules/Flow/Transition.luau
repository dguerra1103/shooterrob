-- UITransitionController: todas las transiciones del flujo pasan por aquí (fundido, deslizar,
-- escala, destello y desenfoque), con duraciones cortas y coherentes. Las pantallas no aparecen
-- de golpe ni se quedan esperando a que acabe una animación larga.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Transition = {}

local fxLayer -- Frame a pantalla completa por encima de todo (destellos)
local blur

local function tween(inst, time, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
Transition.Tween = tween

-- Capa de efectos (la pone el FlowController: un ScreenGui con DisplayOrder alto)
function Transition.SetLayer(frame)
	fxLayer = frame
end

-- Fundido de un CanvasGroup (o de cualquier objeto con GroupTransparency)
function Transition.FadeIn(group, time)
	group.Visible = true
	group.GroupTransparency = 1
	return tween(group, time or Theme.Time.Normal, { GroupTransparency = 0 })
end

function Transition.FadeOut(group, time, hideAfter)
	local t = tween(group, time or Theme.Time.Fast, { GroupTransparency = 1 })
	if hideAfter ~= false then
		t.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and group.GroupTransparency > 0.99 then
				group.Visible = false
			end
		end)
	end
	return t
end

-- Entra deslizando desde un desplazamiento (en píxeles virtuales) hasta su sitio
function Transition.SlideIn(frame, offset, time, delayTime)
	-- Mientras desliza, su sitio es el guardado (repetir a media animación no lo desplaza); si
	-- está quieto, su sitio es donde está ahora (por si la pantalla cambió de tamaño)
	local target = frame:GetAttribute("RestPosition")
	if not frame:GetAttribute("Sliding") or typeof(target) ~= "UDim2" then
		target = frame.Position
		frame:SetAttribute("RestPosition", target)
	end
	local slide = (frame:GetAttribute("SlideToken") or 0) + 1
	frame:SetAttribute("SlideToken", slide)
	frame:SetAttribute("Sliding", true)
	frame.Position = target + UDim2.fromOffset(offset.X, offset.Y)
	local duration = time or Theme.Time.Normal
	local function go()
		tween(frame, duration, { Position = target }, Enum.EasingStyle.Quint)
	end
	if delayTime and delayTime > 0 then
		task.delay(delayTime, go)
	else
		go()
	end
	task.delay((delayTime or 0) + duration + 0.05, function()
		if frame:GetAttribute("SlideToken") == slide then
			frame:SetAttribute("Sliding", nil)
		end
	end)
	return target
end

-- Aparece creciendo un poco (UIScale propia "PopScale")
function Transition.Pop(frame, from, time, delayTime)
	local scale = frame:FindFirstChild("PopScale") or Instance.new("UIScale")
	scale.Name = "PopScale"
	scale.Parent = frame
	scale.Scale = from or 0.9
	local function go()
		tween(scale, time or Theme.Time.Fast, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	if delayTime and delayTime > 0 then
		task.delay(delayTime, go)
	else
		go()
	end
	return scale
end

-- Latido corto (cuenta atrás, número que cambia)
function Transition.Pulse(frame, amount, time)
	local scale = frame:FindFirstChild("PopScale") or Instance.new("UIScale")
	scale.Name = "PopScale"
	scale.Parent = frame
	scale.Scale = amount or 1.25
	return tween(scale, time or 0.25, { Scale = 1 }, Enum.EasingStyle.Quad)
end

-- Destello a pantalla completa (amarillo al pulsar JUGAR, blanco al encontrar partida)
function Transition.Flash(color, strength, time)
	if not fxLayer then
		return
	end
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BorderSizePixel = 0
	flash.BackgroundColor3 = color or Theme.Colors.Yellow
	flash.BackgroundTransparency = 1 - (strength or 0.35)
	flash.ZIndex = 50
	flash.Parent = fxLayer
	local t = tween(flash, time or 0.35, { BackgroundTransparency = 1 })
	t.Completed:Once(function()
		flash:Destroy()
	end)
	return flash
end

-- Desenfoque del mundo detrás de los menús (nunca durante el combate)
function Transition.Blur(size, time)
	if not blur or not blur.Parent then
		-- (la pantalla de arranque deja el suyo con el mismo nombre: se reutiliza)
		blur = Lighting:FindFirstChild("FlowBlur")
	end
	if not blur or not blur.Parent then
		blur = Instance.new("BlurEffect")
		blur.Name = "FlowBlur"
		blur.Size = 0
		blur.Parent = Lighting
	end
	local t = tween(blur, time or Theme.Time.Fast, { Size = size })
	if size <= 0 then
		t.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and blur and blur.Size <= 0.01 then
				blur:Destroy()
				blur = nil
			end
		end)
	end
	return t
end

-- Barra que cruza la pantalla (cambio de pantalla grande: partida encontrada, equipos)
function Transition.Wipe(color, time)
	if not fxLayer then
		return
	end
	local bar = Instance.new("Frame")
	bar.Name = "Wipe"
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.fromScale(-1.2, 0.5)
	bar.Size = UDim2.new(1.2, 0, 0.36, 0)
	bar.Rotation = -8
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = color or Theme.Colors.Yellow
	bar.ZIndex = 49
	bar.Parent = fxLayer
	local t = tween(bar, time or 0.45, { Position = UDim2.fromScale(1.1, 0.5) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	t.Completed:Once(function()
		bar:Destroy()
	end)
	return t
end

return Transition
