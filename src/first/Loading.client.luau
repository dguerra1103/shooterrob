-- Pantalla de carga propia (sustituye a la de Roblox): título, consejos y un indicador que gira hasta
-- que el juego está listo. Vive en ReplicatedFirst para salir lo antes posible, así que no puede usar
-- los módulos del juego (aún no han llegado): el título se escribe aquí también.
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local TITLE = "SHOOTER NEW" -- (el mismo que GameConfig.GameTitle)
local TIPS = {
	"🎯 Los disparos a la cabeza hacen mucho más daño",
	"🧟 En Infección, si te atrapan, te conviertes en zombi",
	"🎡 Tienes un giro gratis de la ruleta cada día",
	"🏆 Gana partidas para subir de rango: de Bronce a Campeón",
	"⚡ E impulso · Z supersalto · X poción",
	"🍬 Recoge caramelos durante las partidas de Halloween",
	"🎁 Cada pocos minutos jugando hay un regalo (tecla H)",
}

local player = Players.LocalPlayer
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "Loading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(24, 16, 40)
background.BorderSizePixel = 0
background.Parent = gui
local backGradient = Instance.new("UIGradient")
backGradient.Color = ColorSequence.new(Color3.fromRGB(60, 25, 90), Color3.fromRGB(15, 12, 30))
backGradient.Rotation = 90
backGradient.Parent = background

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.4)
title.Size = UDim2.fromScale(0.8, 0.18)
title.BackgroundTransparency = 1
title.Font = Enum.Font.FredokaOne
title.Text = TITLE
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = background
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 170)),
})
titleGradient.Rotation = 90
titleGradient.Parent = title
local stroke = Instance.new("UIStroke")
stroke.Thickness = 6
stroke.Color = Color3.fromRGB(30, 10, 40)
stroke.Parent = title

local spinner = Instance.new("TextLabel")
spinner.AnchorPoint = Vector2.new(0.5, 0.5)
spinner.Position = UDim2.fromScale(0.5, 0.62)
spinner.Size = UDim2.fromOffset(60, 60)
spinner.BackgroundTransparency = 1
spinner.Font = Enum.Font.FredokaOne
spinner.Text = "🎃"
spinner.TextScaled = true
spinner.Parent = background

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.68)
status.Size = UDim2.new(0.8, 0, 0, 30)
status.BackgroundTransparency = 1
status.Font = Enum.Font.FredokaOne
status.Text = "Cargando..."
status.TextSize = 24
status.TextColor3 = Color3.fromRGB(255, 220, 120)
status.Parent = background

local tip = Instance.new("TextLabel")
tip.AnchorPoint = Vector2.new(0.5, 1)
tip.Position = UDim2.new(0.5, 0, 1, -40)
tip.Size = UDim2.new(0.9, 0, 0, 30)
tip.BackgroundTransparency = 1
tip.Font = Enum.Font.FredokaOne
tip.Text = TIPS[math.random(1, #TIPS)]
tip.TextSize = 22
tip.TextColor3 = Color3.fromRGB(210, 210, 235)
tip.Parent = background

gui.Parent = player:WaitForChild("PlayerGui")

-- La calabaza gira y bota
local spin = RunService.RenderStepped:Connect(function()
	local t = os.clock()
	spinner.Rotation = math.sin(t * 3) * 20
	spinner.Position = UDim2.new(0.5, 0, 0.62, -math.abs(math.sin(t * 4)) * 14)
end)
task.spawn(function()
	while gui.Parent do
		task.wait(3.5)
		tip.Text = TIPS[math.random(1, #TIPS)]
	end
end)

-- Listo cuando el juego ha cargado y el servidor ya ha preparado la partida (como mucho 25 s)
local started = os.clock()
if not game:IsLoaded() then
	game.Loaded:Wait()
end
status.Text = "Preparando la partida..."
while os.clock() - started < 25 do
	local ready = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage:GetAttribute("State") ~= nil
	if ready and os.clock() - started > 1.5 then
		break
	end
	task.wait(0.2)
end
status.Text = "¡Listo!"
local fade = TweenInfo.new(0.6)
TweenService:Create(background, fade, { BackgroundTransparency = 1 }):Play()
for _, label in { title, spinner, status, tip } do
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
end
TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
task.wait(0.7)
spin:Disconnect()
gui:Destroy()
