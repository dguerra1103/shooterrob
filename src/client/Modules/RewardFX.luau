-- Efectos de recompensa (la "chispa" de los shooters de móvil al hacer algo bien):
--   KillPulse:  al hacer una baja, los bordes de la pantalla destellan (rojo; dorado si es a la cabeza o
--               baja múltiple), el color del mundo se aviva un instante y suena un golpe grave con
--               un "ding" que sube de tono con cada baja seguida
--   AddScore:   contador de puntos de la jugada ("+250") que se acumula y cuenta hacia arriba mientras
--               sigues sumando, como en los shooters; se va solo a los 2,5 s sin sumar
--   Celebrate:  celebración a pantalla completa (rayos girando, confeti y fanfarria) para subir de
--               nivel, ascender de rango o sacar algo bueno en una caja
-- Todo en su propia pantalla, encima del HUD; en calidad Baja, menos confeti.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Sounds = require(ReplicatedStorage.Shared.Sounds)
local ClientState = require(script.Parent.ClientState)

local RewardFX = {}

local KILL_RED = Color3.fromRGB(255, 50, 50)
local GOLD = Color3.fromRGB(255, 200, 40)
local CONFETTI = {
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(80, 220, 255),
	Color3.fromRGB(120, 255, 120),
	Color3.fromRGB(200, 110, 255),
	Color3.new(1, 1, 1),
}

local gui
local edges = {}
local pulseCC
local scoreLabel, scoreScale
local scoreTotal, scoreShown, scoreToken = 0, 0, nil
local celebrating = false

local function tween(inst, time, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function lowQuality()
	return ClientState.EffectiveQuality == "Baja"
end

-- Bordes de la pantalla: 4 franjas con degradado (opacas en el borde, transparentes hacia dentro)
local function buildEdges()
	local specs = {
		{ Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 0.22), 90 },
		{ Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.22), -90 },
		{ Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(0.16, 1), 0 },
		{ Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromScale(0.16, 1), 180 },
	}
	for i, spec in specs do
		local frame = Instance.new("Frame")
		frame.Name = "Edge" .. i
		frame.AnchorPoint = spec[1]
		frame.Position = spec[2]
		frame.Size = spec[3]
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = KILL_RED
		frame.BackgroundTransparency = 1
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = spec[4]
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.6, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = frame
		frame.Parent = gui
		edges[i] = frame
	end
end

local function buildScore()
	scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "ScoreTotal"
	scoreLabel.AnchorPoint = Vector2.new(0.5, 1)
	scoreLabel.Position = UDim2.new(0.5, 0, 0.58, -4)
	scoreLabel.Size = UDim2.fromOffset(220, 44)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Font = Enum.Font.GothamBlack
	scoreLabel.TextSize = 38
	scoreLabel.TextColor3 = GOLD
	scoreLabel.TextStrokeTransparency = 0.2
	scoreLabel.Text = ""
	scoreLabel.Visible = false
	scoreLabel.Parent = gui
	scoreScale = Instance.new("UIScale")
	scoreScale.Parent = scoreLabel
end

function RewardFX.Init()
	local player = Players.LocalPlayer
	gui = Instance.new("ScreenGui")
	gui.Name = "RewardFX"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 21 -- (encima de los menús y la ruleta: las celebraciones se ven siempre)
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	buildEdges()
	buildScore()
	-- El contador sube poco a poco hasta el total (se ve "contar" los puntos)
	RunService.RenderStepped:Connect(function(dt)
		if scoreShown < scoreTotal then
			scoreShown = math.min(scoreTotal, scoreShown + math.max(4, (scoreTotal - scoreShown) * dt * 9))
			scoreLabel.Text = "+" .. math.floor(scoreShown)
		end
	end)
end

-- Destello de los bordes
function RewardFX.EdgeFlash(color, strength)
	if not gui then
		return
	end
	strength = math.clamp(strength or 0.5, 0, 1)
	for _, edge in edges do
		edge.BackgroundColor3 = color
		edge.BackgroundTransparency = 1 - strength
		tween(edge, 0.45, { BackgroundTransparency = 1 })
	end
end

-- Al hacer una baja (multi = cuántas seguidas en pocos segundos)
function RewardFX.KillPulse(headshot, multi)
	multi = multi or 1
	local special = headshot or multi >= 2
	RewardFX.EdgeFlash(special and GOLD or KILL_RED, math.min(0.35 + 0.1 * multi, 0.7))
	-- El mundo se aviva un instante (más saturado y contrastado)
	if not pulseCC or not pulseCC.Parent then
		pulseCC = Instance.new("ColorCorrectionEffect")
		pulseCC.Name = "KillPulseCC"
		pulseCC.Parent = Lighting
	end
	pulseCC.Saturation = 0.35
	pulseCC.Contrast = 0.12
	pulseCC.Brightness = 0.04
	tween(pulseCC, 0.4, { Saturation = 0, Contrast = 0, Brightness = 0 })
	-- Golpe grave (el "ding" de la baja ya lo pone el marcador de impacto); en bajas seguidas, un
	-- acorde que sube de tono con cada una
	Sounds.Play("Boom", nil, 2.2, 0.18)
	if multi >= 2 then
		local step = 0.12 * math.min(multi - 2, 5)
		task.delay(0.08, function()
			Sounds.Play("Kill", nil, 1.26 + step, 0.5)
			task.wait(0.07)
			Sounds.Play("Kill", nil, 1.5 + step, 0.45)
		end)
	end
end

-- Suma puntos al contador de la jugada
function RewardFX.AddScore(amount)
	if not gui or type(amount) ~= "number" or amount <= 0 then
		return
	end
	if not scoreLabel.Visible then
		scoreTotal, scoreShown = 0, 0
		scoreLabel.Text = "+0"
	end
	scoreTotal += amount
	scoreLabel.Visible = true
	scoreLabel.TextTransparency = 0
	scoreLabel.TextStrokeTransparency = 0.2
	-- (más grande y más naranja cuanto más llevas)
	scoreLabel.TextColor3 = GOLD:Lerp(Color3.fromRGB(255, 110, 40), math.clamp(scoreTotal / 1500, 0, 1))
	scoreScale.Scale = 1.35 + math.clamp(scoreTotal / 3000, 0, 0.4)
	tween(scoreScale, 0.25, { Scale = 1 + math.clamp(scoreTotal / 4000, 0, 0.3) }, Enum.EasingStyle.Back)
	local token = {}
	scoreToken = token
	task.delay(2.5, function()
		if scoreToken ~= token then
			return
		end
		tween(scoreLabel, 0.35, { TextTransparency = 1, TextStrokeTransparency = 1 })
		task.wait(0.35)
		if scoreToken == token then
			scoreLabel.Visible = false
		end
	end)
end

-- Saca la cantidad de un aviso de XP ("+120 XP  Baja" → 120)
function RewardFX.ParseXP(text)
	if type(text) ~= "string" then
		return nil
	end
	local amount = string.match(text, "^%+(%d+) XP")
	return amount and tonumber(amount) or nil
end

-- Confeti: trocitos de colores que salen disparados del centro y caen girando
local function confetti(parent, count)
	for _ = 1, count do
		local piece = Instance.new("Frame")
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.1, 0.35)
		piece.Size = UDim2.fromOffset(math.random(6, 12), math.random(10, 18))
		piece.BorderSizePixel = 0
		piece.BackgroundColor3 = CONFETTI[math.random(1, #CONFETTI)]
		piece.Rotation = math.random(0, 360)
		piece.ZIndex = 3
		piece.Parent = parent
		local angle = math.random() * math.pi * 2
		local spread = 0.15 + math.random() * 0.35
		local up = UDim2.fromScale(0.5 + math.cos(angle) * spread, 0.35 + math.sin(angle) * spread * 0.6 - 0.12)
		local fall = UDim2.fromScale(up.X.Scale + (math.random() - 0.5) * 0.15, 1.1)
		local burst = tween(piece, 0.45, { Position = up, Rotation = piece.Rotation + math.random(-180, 180) }, Enum.EasingStyle.Quad)
		burst.Completed:Once(function()
			if piece.Parent then
				tween(piece, 1.6 + math.random() * 0.8, {
					Position = fall,
					Rotation = piece.Rotation + math.random(-540, 540),
					BackgroundTransparency = 0.3,
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end)
	end
end

-- Fanfarria: tres notas que suben y un golpe grave
local function fanfare(big)
	Sounds.Play("Boom", nil, 1.6, big and 0.3 or 0.2)
	for i, pitch in { 1, 1.26, 1.5, big and 2 or nil } do
		task.delay((i - 1) * 0.11, function()
			Sounds.Play("Kill", nil, pitch, 0.6)
		end)
	end
end

-- Celebración a pantalla completa. title: texto grande; subtitle: debajo (opcional);
-- color: el de la celebración; big: más confeti y una nota más
function RewardFX.Celebrate(title, subtitle, color, big)
	if not gui or celebrating then
		return
	end
	celebrating = true
	color = color or GOLD
	local holder = Instance.new("Frame")
	holder.Name = "Celebration"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Parent = gui
	-- Rayos de luz girando detrás del título
	local rays = Instance.new("Frame")
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.33)
	rays.Size = UDim2.fromOffset(10, 10)
	rays.BackgroundTransparency = 1
	rays.Parent = holder
	local rayCount = lowQuality() and 6 or 10
	for i = 1, rayCount do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.fromOffset(46, 900)
		ray.Rotation = (i - 1) * (180 / rayCount)
		ray.BorderSizePixel = 0
		ray.BackgroundColor3 = color
		ray.BackgroundTransparency = 0.82
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = ray
		ray.Parent = rays
	end
	local raysScale = Instance.new("UIScale")
	raysScale.Scale = 0.2
	raysScale.Parent = rays
	tween(raysScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(rays, 3.2, { Rotation = 70 }, Enum.EasingStyle.Linear)
	-- Destello blanco de un instante
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BorderSizePixel = 0
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0.55
	flash.Parent = holder
	tween(flash, 0.35, { BackgroundTransparency = 1 })
	RewardFX.EdgeFlash(color, 0.6)
	-- Título
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.33)
	label.Size = UDim2.fromOffset(900, 80)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 64
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Text = tostring(title)
	label.ZIndex = 2
	label.Parent = holder
	local scale = Instance.new("UIScale")
	scale.Scale = 2.4
	scale.Parent = label
	tween(scale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	local sub
	if subtitle then
		sub = Instance.new("TextLabel")
		sub.AnchorPoint = Vector2.new(0.5, 0)
		sub.Position = UDim2.new(0.5, 0, 0.33, 44)
		sub.Size = UDim2.fromOffset(800, 34)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.GothamBold
		sub.TextSize = 26
		sub.TextColor3 = Color3.new(1, 1, 1)
		sub.TextStrokeTransparency = 0.2
		sub.TextTransparency = 1
		sub.Text = tostring(subtitle)
		sub.ZIndex = 2
		sub.Parent = holder
		task.delay(0.25, function()
			tween(sub, 0.3, { TextTransparency = 0 })
		end)
	end
	confetti(holder, (lowQuality() and 18 or 40) * (big and 1.5 or 1))
	fanfare(big)
	task.delay(2.6, function()
		tween(label, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		if sub then
			tween(sub, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end
		for _, ray in rays:GetChildren() do
			if ray:IsA("Frame") then
				tween(ray, 0.5, { BackgroundTransparency = 1 })
			end
		end
		task.wait(0.9)
		holder:Destroy()
		celebrating = false
	end)
	return holder
end

return RewardFX
