-- UIFlowController: un solo sitio decide qué pantalla del flujo se ve, en vez de muchos scripts
-- encendiendo y apagando cosas. Estados:
--   Home, Squad, Armory, Operator      (lobby: cámara sobre el mapa, desenfoque, controles quietos)
--   Matchmaking → MatchFound → MapIntro → TeamIntro → Loadout → Deploy (3-2-1) → Gameplay
-- La secuencia se apoya en el ciclo de rondas real del servidor (atributos State, LoadingMap,
-- Deploy, CountdownAt y DeployEndsAt de ReplicatedStorage): las presentaciones se ven MIENTRAS el
-- servidor construye el mapa o mantiene a todos quietos en el despliegue, no se suman a la espera.
-- Quien entra con una partida ya empezada hace la misma secuencia, más corta y a su ritmo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.Parent.ClientState)
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Transition = require(script.Parent.Transition)
local UISound = require(script.Parent.UISound)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Flow = {}
Flow.State = "Boot"
Flow.Changed = Instance.new("BindableEvent")
Flow.Screens = {}

local LOBBY = { Home = true, Squad = true, Armory = true, Operator = true, Store = true, Pass = true }
local SEQUENCE = { Matchmaking = true, MatchFound = true, MapIntro = true, TeamIntro = true, Loadout = true, Deploy = true }
Flow.Lobby = LOBBY
Flow.Sequence = SEQUENCE

-- Tiempos de la secuencia (segundos). Los del despliegue los manda el servidor; estos son los
-- mínimos para que cada momento se lea y los de quien entra con la partida empezada
Flow.Times = {
	SearchMin = 0.9, -- (con partida en marcha: lo justo para que se vea que busca)
	MatchFound = 1.4,
	MapIntroMin = 1.8,
	TeamIntro = 3.2,
	LateLoadout = 5,
	LateCountdown = 3,
}

local guis: { [string]: any } = {}

---------------------------------------------------------------------------
-- Cámara y controles del lobby (lo que antes hacía la pantalla de inicio)
---------------------------------------------------------------------------

local controls
local function getControls()
	if controls then
		return controls
	end
	local ok, result = pcall(function()
		local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		return playerModule:GetControls()
	end)
	if ok then
		controls = result
	end
	return controls
end

local orbitAngle = 0
local cameraMode = nil -- "Orbit" | "Flyover" | "Deploy" | "Scripted" | nil (cámara del juego)
local cameraDriver = nil -- ("Scripted": la pantalla mueve la cámara, p. ej. la pantalla final)
local deployFrom, deployStart, deployTime

-- (GetBoundingBox recorre todas las piezas del mapa: se calcula como mucho cada 2 s o al cambiar de
-- mapa, no en cada fotograma; las piezas aún pueden estar llegando, por eso se refresca)
local centerCache = { Map = nil, At = -math.huge, Center = Vector3.new(0, 8, 0), Radius = 150 }
local function mapCenter()
	local map = workspace:FindFirstChild("Map")
	local now = os.clock()
	if map == centerCache.Map and now - centerCache.At < 2 then
		return centerCache.Center, centerCache.Radius
	end
	centerCache.Map, centerCache.At = map, now
	centerCache.Center, centerCache.Radius = Vector3.new(0, 8, 0), 150
	if map and map:IsA("Model") then
		local ok, cf, size = pcall(map.GetBoundingBox, map)
		if ok and cf then
			centerCache.Center = Vector3.new(cf.Position.X, 8, cf.Position.Z)
			centerCache.Radius = math.clamp(math.max(size.X, size.Z) * 0.5, 90, 200)
		end
	end
	return centerCache.Center, centerCache.Radius
end

local function cameraStep(dt)
	if not cameraMode then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local center, radius = mapCenter()
	if cameraMode == "Orbit" then
		orbitAngle += dt * 0.05
		local position = center + Vector3.new(math.cos(orbitAngle) * radius, 60, math.sin(orbitAngle) * radius)
		camera.CFrame = CFrame.lookAt(position, center)
		camera.FieldOfView = 60
	elseif cameraMode == "Flyover" then
		-- Presentación del mapa: pasada lenta y más baja
		orbitAngle += dt * 0.09
		local position = center + Vector3.new(math.cos(orbitAngle) * radius * 0.75, 42, math.sin(orbitAngle) * radius * 0.75)
		camera.CFrame = CFrame.lookAt(position, center + Vector3.new(0, -6, 0))
		camera.FieldOfView = 55
	elseif cameraMode == "Scripted" then
		if cameraDriver then
			cameraDriver(camera, dt)
		end
	elseif cameraMode == "Deploy" then
		-- De la vista del mapa a la espalda de tu personaje, a tiempo con la cuenta atrás
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		if head and deployFrom then
			local a = math.clamp((os.clock() - deployStart) / deployTime, 0, 1)
			a = 1 - (1 - a) ^ 3
			local root = character:FindFirstChild("HumanoidRootPart") or head
			local target = CFrame.lookAt(head.Position - root.CFrame.LookVector * 0.2 + Vector3.new(0, 0.2, 0), head.Position + root.CFrame.LookVector * 10)
			camera.CFrame = deployFrom:Lerp(target, a)
			camera.FieldOfView = 70 + (1 - a) * -10
		end
	end
end

-- duration: solo para "Deploy" (lo que tarda en llegar a tu espalda; por defecto, lo que queda de
-- despliegue)
function Flow.SetCamera(mode, duration)
	cameraDriver = mode == "Scripted" and duration or nil
	if mode == "Deploy" then
		deployFrom = camera.CFrame
		deployStart = os.clock()
		deployTime = math.max(0.5, (duration or Flow.DeployRemaining() or 3) - 0.15)
	end
	cameraMode = mode
	if not mode then
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and not ClientState.Dead then
			camera.CameraSubject = humanoid
		end
	end
end

local function lockControls(locked)
	task.spawn(function()
		local ctrl = getControls()
		if ctrl then
			if locked then
				ctrl:Disable()
			else
				ctrl:Enable()
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Tiempos del servidor
---------------------------------------------------------------------------

local function serverNow()
	return workspace:GetServerTimeNow()
end

-- Segundos que faltan para que acabe el despliegue (nil si no hay despliegue en marcha)
function Flow.DeployRemaining()
	local endsAt = ReplicatedStorage:GetAttribute("DeployEndsAt")
	if ReplicatedStorage:GetAttribute("Deploy") == nil or not endsAt then
		return nil
	end
	return math.max(0, endsAt - serverNow())
end

function Flow.CountdownIn()
	local at = ReplicatedStorage:GetAttribute("CountdownAt")
	if ReplicatedStorage:GetAttribute("Deploy") == nil or not at then
		return nil
	end
	return at - serverNow()
end

---------------------------------------------------------------------------
-- Estados
---------------------------------------------------------------------------

function Flow.Register(name, screen)
	Flow.Screens[name] = screen
end

-- Cambia de pantalla. ctx: datos para la pantalla nueva (p. ej. { Late = true })
function Flow.SetState(state, ctx)
	local previous = Flow.State
	if previous == state then
		local screen = Flow.Screens[state]
		if screen and screen.Refresh then
			screen.Refresh(ctx)
		end
		return
	end
	Flow.State = state
	local old = Flow.Screens[previous]
	if old and old.Hide then
		old.Hide(state)
	end
	-- Lobby y secuencia: interfaz del juego oculta y personaje quieto; en Gameplay, todo vuelve
	local inFlow = state ~= "Gameplay"
	ClientState.InMainMenu = inFlow
	ClientState.UpdateMouse()
	UserInputService.MouseIconEnabled = inFlow or UserInputService.MouseIconEnabled
	lockControls(inFlow)
	if guis.Content then
		guis.Content.Enabled = inFlow
		guis.Backdrop.Enabled = inFlow
	end
	local screen = Flow.Screens[state]
	if screen and screen.Show then
		screen.Show(ctx or {}, previous)
	end
	Flow.Changed:Fire(state, previous)
end

-- Fondo oscuro detrás de las pantallas (opacidad 0..1) con fundido
function Flow.SetBackdrop(alpha, time)
	if guis.Dim then
		Transition.Tween(guis.Dim, time or Theme.Time.Normal, { BackgroundTransparency = 1 - alpha })
	end
end

---------------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------------

-- JUGAR: buscar partida (desde el lobby)
function Flow.Play()
	if not LOBBY[Flow.State] then
		return
	end
	Transition.Flash(Theme.Colors.Yellow, 0.4, 0.3)
	pcall(function()
		Remotes.SetReady:FireServer(true)
	end)
	Flow.SetState("Matchmaking")
end

function Flow.CancelSearch()
	if Flow.State ~= "Matchmaking" then
		return
	end
	UISound.Play("Back")
	pcall(function()
		Remotes.SetReady:FireServer(false)
	end)
	-- (venía de una partida: de vuelta al lobby también en el servidor)
	if not player:GetAttribute("InMenu") then
		pcall(function()
			Remotes.EnterMenu:FireServer()
		end)
	end
	Flow.SetState("Home")
end

-- JUGAR DE NUEVO desde la pantalla final: a buscar la siguiente partida (el servidor ya te cuenta
-- en ella; la búsqueda enseña la votación y el tiempo que falta)
function Flow.Requeue()
	if Flow.State == "Matchmaking" then
		return
	end
	Transition.Flash(Theme.Colors.Yellow, 0.35, 0.3)
	Flow.SetState("Matchmaking", { Requeue = true })
end

-- Entrar a jugar (al acabar la cuenta atrás): fuera el escudo del menú, cámara del juego
function Flow.EnterGameplay()
	if Flow.State == "Gameplay" then
		return
	end
	if player:GetAttribute("InMenu") then
		Remotes.LeaveMenu:FireServer()
	end
	Transition.Blur(0, 0.2)
	Flow.SetCamera(nil)
	Flow.SetState("Gameplay")
end

-- Volver al lobby (desde la pantalla de muerte): solo lo acepta el servidor si estás muerto o
-- recién aparecido
function Flow.ReturnToLobby()
	if LOBBY[Flow.State] then
		return
	end
	Remotes.EnterMenu:FireServer()
	Flow.SetState("Home")
end

-- La siguiente pantalla de la secuencia según lo que esté haciendo el servidor
function Flow.Advance(from)
	local state = ReplicatedStorage:GetAttribute("State")
	local deploying = ReplicatedStorage:GetAttribute("Deploy") ~= nil
	if from == "MatchFound" then
		Flow.SetState("MapIntro", { Late = not deploying })
	elseif from == "MapIntro" then
		if deploying or state == "Playing" then
			Flow.SetState("TeamIntro", { Late = not deploying })
		end
	elseif from == "TeamIntro" then
		Flow.SetState("Loadout", { Late = not deploying })
	elseif from == "Loadout" then
		Flow.SetState("Deploy", { Late = not deploying })
	elseif from == "Deploy" then
		Flow.EnterGameplay()
	end
end

---------------------------------------------------------------------------
-- Reacción al ciclo de rondas (para quien está en la secuencia o jugando)
---------------------------------------------------------------------------

local function onRoundChanged()
	local state = ReplicatedStorage:GetAttribute("State")
	local loading = ReplicatedStorage:GetAttribute("LoadingMap")
	local deploy = ReplicatedStorage:GetAttribute("Deploy")
	local current = Flow.State
	if LOBBY[current] or current == "Boot" then
		return -- (en el lobby no se interrumpe nada)
	end
	if current == "Matchmaking" then
		-- Partida lista: el mapa nuevo se está construyendo o empieza el despliegue
		if loading or (state == "Playing" and deploy) then
			Flow.SetState("MatchFound")
		end
		return
	end
	if current == "Gameplay" and state == "Ended" then
		-- Fin de partida: la pantalla final llega con el resultado; mientras, que el HUD no celebre
		Flow.EndedAt = os.clock()
		ClientState.ResultsActive = true
		task.delay(4, function()
			if Flow.State == "Gameplay" then
				ClientState.ResultsActive = false
			end
		end)
		return
	end
	if current == "Results" then
		-- Acaba la pantalla final: a buscar la siguiente (salvo que se haya cancelado); si la partida
		-- siguiente ya empieza, su presentación
		if loading then
			Flow.SetState("MapIntro", { Server = true })
		elseif state == "Playing" and deploy == "Lineup" then
			Flow.SetState("TeamIntro", { Server = true })
		elseif state == "Intermission" then
			local screen = Flow.Screens.Results
			if not (screen and screen.AutoAdvance) or screen.AutoAdvance() then
				Flow.Requeue()
			end
		end
		return
	end
	if current == "Gameplay" then
		-- Ronda nueva para quien ya estaba jugando: presentación del mapa y despliegue
		if loading then
			Flow.SetState("MapIntro", { Server = true })
		elseif state == "Playing" and deploy == "Lineup" then
			Flow.SetState("TeamIntro", { Server = true })
		end
		return
	end
	if current == "MapIntro" and state == "Playing" and deploy then
		local screen = Flow.Screens.MapIntro
		if screen and screen.ReadyToLeave and screen.ReadyToLeave() then
			Flow.Advance("MapIntro")
		end
	end
	if (current == "TeamIntro" or current == "Loadout") and state == "Playing" and (deploy == "Countdown" or deploy == nil) then
		-- Cuenta atrás del servidor (o, en Eliminación y Buscar y destruir, la preparación de la
		-- primera ronda justo después de la presentación)
		Flow.SetState("Deploy")
	end
	if SEQUENCE[current] and state ~= "Playing" and not loading and current ~= "MatchFound" then
		-- (la partida se cortó en plena secuencia: a esperar la siguiente)
		if state == "Intermission" and (current == "TeamIntro" or current == "Loadout" or current == "Deploy") then
			Flow.SetState("Matchmaking")
		end
	end
end
Flow.OnRoundChanged = onRoundChanged

---------------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------------

function Flow.Init(screens)
	local playerGui = player:WaitForChild("PlayerGui")
	-- Fondo a pantalla completa (oscurece el mundo detrás de los paneles)
	guis.Backdrop = C.new("ScreenGui", {
		Name = "FlowBackdrop",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 3,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	guis.Dim = C.new("Frame", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Bg,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = guis.Backdrop,
	})
	-- Viñeta: más oscuro a los lados (se leen los paneles; el centro queda para el personaje)
	C.new("Frame", {
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = guis.Backdrop,
	}, {
		C.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.25),
				NumberSequenceKeypoint.new(0.28, 0.85),
				NumberSequenceKeypoint.new(0.72, 0.85),
				NumberSequenceKeypoint.new(1, 0.25),
			}),
		}),
	})
	-- Contenido (zona segura: muesca y barra de Roblox)
	guis.Content = C.new("ScreenGui", {
		Name = "MainMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 4,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	pcall(function()
		guis.Content.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	-- Botón invisible "Modal": libera el ratón aunque la cámara sea en primera persona
	C.new("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Parent = guis.Content })
	local root = C.root(guis.Content, "FlowRoot")
	guis.Root = root
	-- Efectos (destellos y barridos) por encima de todo, también en partida
	guis.FX = C.new("ScreenGui", {
		Name = "FlowFX",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 30,
		Parent = playerGui,
	})
	Transition.SetLayer(C.new("Frame", { Name = "Layer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = guis.FX }))

	Flow.Guis = guis
	Flow.Root = root
	for name, screen in screens do
		local ok, err = xpcall(screen.Build, debug.traceback, Flow, root)
		if ok then
			Flow.Register(name, screen)
		else
			warn("[Flow] " .. name .. " no se pudo crear: " .. tostring(err))
		end
	end

	RunService:BindToRenderStep("FlowCamera", Enum.RenderPriority.Camera.Value + 2, cameraStep)
	for _, attr in { "State", "LoadingMap", "Deploy" } do
		ReplicatedStorage:GetAttributeChangedSignal(attr):Connect(onRoundChanged)
	end
	-- Esc / B del mando: de una pantalla del lobby (escuadra, armamento, operador) a la principal
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not LOBBY[Flow.State] or Flow.State == "Home" or ClientState.MenuOpen then
			return
		end
		-- (con la vista previa, la confirmación o la escena de compra abiertas, Esc cierra solo eso)
		if ClientState.StoreModal or ClientState.ConfirmOpen or ClientState.RevealOpen then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Backspace then
			UISound.Play("Back")
			Flow.SetState("Home")
		end
	end)
	guis.Content:SetAttribute("Ready", true)
end

return Flow
