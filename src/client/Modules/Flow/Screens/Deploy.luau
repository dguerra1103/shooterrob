-- DESPLIEGUE: PREPÁRATE · 3 · 2 · 1 · ¡YA! mientras la cámara baja del mapa a la espalda de tu
-- personaje. La cuenta atrás es la del servidor (DeployEndsAt), así todos salen a la vez; en
-- Eliminación y Buscar y destruir es la preparación de la primera ronda (Frozen + TimeLeft); quien
-- entra con la partida empezada la hace a su ritmo (3 s). Si tu personaje aún no existe, en vez del
-- número se ve "SINCRONIZANDO PARTIDA…" y se entra en cuanto llega.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)

local player = Players.LocalPlayer
local Colors = Theme.Colors

local Deploy = {}

local flow, screen, block, top, number, sub, ring, sync
local token = 0
local connection
local mode -- "Server" | "Prep" | "Late"
local lateEndsAt, shownAt, lastShown, finished
local prepMax

local function characterReady()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil and humanoid ~= nil and humanoid.Health > 0
end

-- Segundos que faltan para salir (nil = aún no se sabe)
local function remaining()
	if mode == "Late" then
		return math.max(0, lateEndsAt - os.clock())
	elseif mode == "Prep" then
		-- Preparación de la ronda: el servidor cuenta TimeLeft mientras todos están quietos
		if ReplicatedStorage:GetAttribute("Frozen") then
			local left = tonumber(ReplicatedStorage:GetAttribute("TimeLeft"))
			if left and left <= prepMax then
				return left
			end
			return nil
		end
		-- (ya no están quietos: solo vale si se vio la cuenta llegar al final o tras un margen;
		-- entre el despliegue y la primera ronda hay un instante sin "Frozen")
		if (lastShown and lastShown <= 1) or os.clock() - shownAt > prepMax + 2 then
			return 0
		end
		return nil
	end
	return flow.DeployRemaining() or 0
end

local function show(value)
	if value == lastShown then
		return
	end
	lastShown = value
	if value >= 1 then
		number.Text = tostring(value)
		number.TextColor3 = value == 1 and Colors.YellowText or Colors.White
		top.Text = "PREPÁRATE"
		UISound.Play("Countdown", 1 + (3 - math.min(value, 3)) * 0.12)
		Transition.Pulse(number, 1.45, 0.3)
		Transition.Pulse(ring, 1.25, 0.45)
	end
end

local function finish(my)
	if finished then
		return
	end
	finished = true
	number.Text = "¡YA!"
	number.TextColor3 = Colors.Yellow
	top.Text = ""
	sub.Text = "¡A LUCHAR!"
	UISound.Play("Go")
	Transition.Flash(Colors.Yellow, 0.35, 0.3)
	Transition.Pulse(number, 1.6, 0.25)
	task.delay(0.12, function()
		if token == my then
			flow.Advance("Deploy")
		end
	end)
end

local function step()
	local my = token
	if finished then
		return
	end
	local ready = characterReady()
	local left = remaining()
	sync.Visible = not ready
	number.Visible = ready and left ~= nil
	if not ready then
		-- (sin personaje no se entra: se espera a que llegue; el servidor lo está creando)
		if os.clock() - shownAt > 12 then
			finish(my) -- (algo raro: mejor entrar y que el juego normal se encargue)
		end
		return
	end
	if left == nil then
		return
	end
	local whole = math.ceil(left - 0.05)
	if whole <= 0 then
		finish(my)
	else
		show(whole)
	end
end

function Deploy.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "Deploy", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	block = C.new("Frame", { Name = "Block", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(520, 300), Parent = screen })
	-- Anillo fino detrás del número (late con cada segundo)
	ring = C.new("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 10),
		Size = UDim2.fromOffset(190, 190),
		BackgroundTransparency = 1,
		Parent = block,
	}, { C.corner(95), C.stroke(Colors.Yellow, 3, 0.35) })
	top = C.text({ Name = "Top", Text = "PREPÁRATE", Role = "TitleItalic", TextSize = 34, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, 0, 0, 40), Stroke = 2, Parent = block })
	number = C.text({ Name = "Number", Text = "", Role = "TitleItalic", TextSize = 150, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(1, 0, 0, 160), Stroke = 3, Parent = block })
	sub = C.text({ Name = "Sub", Text = "", Role = "Title", TextSize = 22, Color = Colors.Text, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, 0, 0, 28), Stroke = 1, Parent = block })
	sync = C.text({ Name = "Sync", Text = "SINCRONIZANDO PARTIDA…", Role = "Title", TextSize = 26, Color = Colors.Text, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(1, 0, 0, 34), Stroke = 2, Visible = false, Parent = block })
end

function Deploy.Show(ctx)
	token += 1
	finished = false
	lastShown = nil
	shownAt = os.clock()
	local deploy = ReplicatedStorage:GetAttribute("Deploy")
	local modeCode = ReplicatedStorage:GetAttribute("Mode")
	local settings = GameConfig.ModeSettings[modeCode or ""] or {}
	prepMax = settings.PrepTime or 5
	local endsAt = ReplicatedStorage:GetAttribute("DeployEndsAt")
	local justDeployed = endsAt ~= nil and math.abs(workspace:GetServerTimeNow() - endsAt) < 3
	if deploy ~= nil then
		mode = "Server"
	elseif (modeCode == "ELIM" or modeCode == "SND") and (ReplicatedStorage:GetAttribute("Frozen") or justDeployed) then
		mode = "Prep"
	else
		mode = "Late"
		lateEndsAt = os.clock() + flow.Times.LateCountdown
	end
	-- Lo que hay que hacer, debajo del número
	local objective = {
		TDM = "Elimina al equipo rival",
		DOM = "Captura y defiende las banderas",
		KOTH = "Controla la zona",
		CTF = "Roba la bandera rival",
		FFA = "Todos contra todos",
		GUN = "Una baja = arma nueva",
		ELIM = "Una sola vida por ronda",
		SND = "Planta o desactiva la bomba",
		INF = "Sobrevive a la infección",
		CAL = "Recoge las calabazas",
	}
	sub.Text = C.upper(objective[modeCode or ""] or tostring(ReplicatedStorage:GetAttribute("ModeName") or ""))
	number.Text = ""
	top.Text = "PREPÁRATE"
	-- Sin paneles ni desenfoque: se ve el mapa y la cámara bajando hacia ti
	flow.SetBackdrop(0, 0.3)
	Transition.Blur(0, 0.3)
	-- (sin personaje todavía: la cámara sigue sobre el mapa hasta que llegue)
	flow.SetCamera(characterReady() and "Deploy" or "Flyover")
	screen.Visible = true
	Transition.Pop(top, 1.3, 0.25)
	Transition.Pop(sub, 0.8, 0.3, 0.1)
	if connection then
		connection:Disconnect()
	end
	local my = token
	local cameraSet = characterReady()
	connection = RunService.RenderStepped:Connect(function()
		if token ~= my then
			return
		end
		-- (si el personaje llega tarde, la cámara baja hacia él en cuanto existe)
		if not cameraSet and characterReady() then
			cameraSet = true
			if mode == "Late" then
				lateEndsAt = os.clock() + flow.Times.LateCountdown
			end
			flow.SetCamera("Deploy")
		end
		step()
	end)
end

function Deploy.Hide()
	token += 1
	if connection then
		connection:Disconnect()
		connection = nil
	end
	screen.Visible = false
end

return Deploy
