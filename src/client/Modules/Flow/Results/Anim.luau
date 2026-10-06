-- Microanimaciones de la pantalla final: contadores que suben, entradas con salto y destellos sobre
-- un panel. Todo con un token: si la pantalla se cierra, lo que estaba en marcha se para solo.
local TweenService = game:GetService("TweenService")

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)

local Anim = {}

Anim.Token = 0
function Anim.Alive(token)
	return token == Anim.Token
end

-- Cuenta de from a to en `time` segundos (texto con `format`, p. ej. "+%d XP"). Con números
-- pequeños (rondas de Buscar y destruir) va de uno en uno con su tic; si no, suave y con tics espaciados
function Anim.Count(label, from, to, time, format, token, sound)
	format = format or "%d"
	from, to = math.floor(from or 0), math.floor(to or 0)
	if to == from then
		label.Text = string.format(format, to)
		return
	end
	local small = math.abs(to - from) <= 12
	task.spawn(function()
		if small then
			local stepTime = math.min(0.12, time / math.abs(to - from))
			local dir = to > from and 1 or -1
			for value = from + dir, to, dir do
				if token and not Anim.Alive(token) then
					return
				end
				label.Text = string.format(format, value)
				if sound then
					UISound.Play(sound, 1 + (value - from) / math.max(1, math.abs(to - from)) * 0.3)
				end
				task.wait(stepTime)
			end
			return
		end
		local start = os.clock()
		local lastTick = 0
		while os.clock() - start < time do
			if token and not Anim.Alive(token) then
				return
			end
			local a = (os.clock() - start) / time
			a = 1 - (1 - a) ^ 3
			label.Text = string.format(format, math.floor(from + (to - from) * a + 0.5))
			if sound and os.clock() - lastTick > 0.07 then
				lastTick = os.clock()
				UISound.Play(sound, 0.9 + a * 0.5)
			end
			task.wait()
		end
		label.Text = string.format(format, to)
	end)
end

-- Entra con un salto pequeño (escala)
function Anim.Pop(frame, from, time, delayTime)
	frame.Visible = true
	return Transition.Pop(frame, from or 0.7, time or 0.22, delayTime)
end

-- Destello dentro de un panel (sin tapar la pantalla): un rectángulo del color que se desvanece
function Anim.Glow(frame, color, strength, time)
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.BackgroundColor3 = color or Theme.Colors.Yellow
	glow.BackgroundTransparency = 1 - (strength or 0.45)
	glow.BorderSizePixel = 0
	glow.Size = UDim2.fromScale(1, 1)
	glow.ZIndex = (tonumber(frame.ZIndex) or 1) + 20
	local corner = frame:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = glow
	end
	glow.Parent = frame
	local t = TweenService:Create(glow, TweenInfo.new(time or 0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
	t.Completed:Once(function()
		glow:Destroy()
	end)
	t:Play()
end

-- Brillo que cruza un panel de izquierda a derecha (una vez: MVP, desbloqueo)
function Anim.Sheen(frame, time)
	local sheen = Instance.new("Frame")
	sheen.Name = "Sheen"
	sheen.BackgroundColor3 = Color3.new(1, 1, 1)
	sheen.BackgroundTransparency = 0.6
	sheen.BorderSizePixel = 0
	sheen.AnchorPoint = Vector2.new(0.5, 0.5)
	sheen.Position = UDim2.fromScale(-0.2, 0.5)
	sheen.Size = UDim2.new(0, 26, 1.6, 0)
	sheen.Rotation = 18
	sheen.ZIndex = (tonumber(frame.ZIndex) or 1) + 21
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 1) })
	gradient.Parent = sheen
	-- (en un marco propio que recorta: lo que sobresale del panel, como la corona del MVP, no se corta)
	local clip = Instance.new("Frame")
	clip.Name = "SheenClip"
	clip.BackgroundTransparency = 1
	clip.Size = UDim2.fromScale(1, 1)
	clip.ClipsDescendants = true
	clip.ZIndex = sheen.ZIndex
	clip.Parent = frame
	sheen.Parent = clip
	local t = TweenService:Create(sheen, TweenInfo.new(time or 0.6, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(1.2, 0.5) })
	t.Completed:Once(function()
		clip:Destroy()
	end)
	t:Play()
end

return Anim
