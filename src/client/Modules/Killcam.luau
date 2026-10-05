-- Killcam (como en los shooters): repetición desde los ojos de quien hizo una baja, mirando hacia su
-- víctima, un poco a cámara lenta, sin color y con bandas de cine. Para eso se guardan, varias veces
-- por segundo, las posiciones de las cabezas de todos (jugadores y bots) durante los últimos segundos.
--   * Al morir: la pide DeathScreen (luego sigue la pantalla de muerte de siempre).
--   * Killcam final: si una baja cierra la partida o una ronda, el servidor avisa (Remotes.FinalKillcam)
--     y todos ven esa baja ("KILLCAM FINAL"), también quien la hizo.
-- Clic o toque: saltarla. Solo en este cliente: mueve la cámara, no cambia nada del juego.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local Killcam = {}

Killcam.HistoryTime = 6 -- segundos de posiciones guardados
Killcam.SampleTime = 0.05 -- cada cuánto se guardan
Killcam.SlowMotion = 1.25 -- (1,25 = un 25 % más lenta)
Killcam.Length = 2.4 -- segundos de repetición (si hay tantos guardados)
Killcam.Enabled = true

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local history = {} -- [Model] = { { tiempo, posición } }
local orphans = {} -- [nombre] = { Track, Removed }: modelos que ya no están (un bot caído y quitado)
local lastKills = {} -- ["asesino|víctima"] = os.clock() de la baja (de la lista de bajas)
local current = nil -- la repetición en curso
local sampleClock = 0
local gui: any = nil
local refs: { [string]: any } = {}
local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude

local function headPosition(model)
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position + Vector3.new(0, 1.5, 0)
	end
	return nil
end

local function characters()
	local models = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(models, p.Character)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			if model:IsA("Model") then
				table.insert(models, model)
			end
		end
	end
	return models
end

function Killcam.Record()
	local now = os.clock()
	for _, model in characters() do
		local position = headPosition(model)
		if position then
			local list = history[model]
			if not list then
				list = {}
				history[model] = list
			end
			table.insert(list, { now, position })
			while #list > 0 and now - list[1][1] > Killcam.HistoryTime do
				table.remove(list, 1)
			end
		end
	end
	for model, list in history do
		if not model.Parent then
			-- (se guarda un rato por su nombre: la killcam final puede necesitar a un bot ya quitado)
			orphans[model.Name] = { Track = list, Removed = now }
			history[model] = nil
		end
	end
	for name, entry in orphans do
		if now - entry.Removed > Killcam.HistoryTime then
			orphans[name] = nil
		end
	end
end

-- Posición en el instante t (interpolando entre muestras)
function Killcam.SampleAt(list, t)
	if not list or #list == 0 then
		return nil
	end
	if t <= list[1][1] then
		return list[1][2]
	end
	for i = 2, #list do
		local b = list[i]
		if b[1] >= t then
			local a = list[i - 1]
			local k = (t - a[1]) / math.max(1e-3, b[1] - a[1])
			return a[2]:Lerp(b[2], math.clamp(k, 0, 1))
		end
	end
	return list[#list][2]
end

-- Historia de un personaje (por modelo o, si ya no está, por nombre)
function Killcam.Track(model, name)
	return (model and history[model]) or (name and orphans[name] and orphans[name].Track) or nil
end

-- ¿Se veían? (del ojo de quien hizo la baja a la víctima; las personas, los efectos, las barandillas
-- invisibles y los cristales no tapan)
function Killcam.ClearLine(from, to)
	local ignore = { camera }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	for _, name in { "Bots", "ClientFX" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	for _ = 1, 4 do
		losParams.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(from, to - from, losParams)
		if not hit then
			return true
		end
		if hit.Instance.Transparency < 0.3 then
			return false
		end
		table.insert(ignore, hit.Instance)
	end
	return true
end

-- Durante la repetición: la víctima se ve (aunque sea tu propio cuerpo, que la primera persona deja
-- invisible) y quien hizo la baja no (la cámara está en su cabeza: se vería por dentro)
local function setModelLook(model, modifier)
	if not model then
		return
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.LocalTransparencyModifier = modifier
		end
	end
end

function Killcam.Active()
	return current ~= nil
end

-- Termina la repetición. runOnEnd: avisar a quien la pidió (p. ej. para pasar a observar)
function Killcam.Stop(runOnEnd)
	local k = current
	if not k then
		return
	end
	current = nil
	ClientState.KillcamActive = false
	ClientState.KillcamFinal = false
	pcall(function()
		RunService:UnbindFromRenderStep("Killcam")
	end)
	if k.Effect then
		k.Effect:Destroy()
	end
	if k.Killer and k.Killer.Parent then
		-- (si eras tú, la primera persona vuelve a esconderte sola)
		setModelLook(k.Killer, 0)
	end
	if refs.Frame then
		refs.Frame.Visible = false
	end
	camera.FieldOfView = k.Fov
	-- (en la final sigues vivo: la cámara vuelve a donde mirabas)
	if k.Final and k.CameraBefore then
		camera.CFrame = k.CameraBefore
	end
	camera.CameraType = Enum.CameraType.Custom
	if runOnEnd and k.OnEnd then
		task.spawn(k.OnEnd)
	end
end

local function step()
	local k = current
	if not k then
		return
	end
	local elapsed = os.clock() - k.Start
	if elapsed >= k.Span * Killcam.SlowMotion then
		Killcam.Stop(true)
		return
	end
	local t = k.From + elapsed / Killcam.SlowMotion
	local eye = Killcam.SampleAt(k.KillerTrack, t)
	local victim = Killcam.SampleAt(k.VictimTrack, t)
	if not eye or not victim then
		Killcam.Stop(true)
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 60
	-- (si los dos puntos casi coinciden, se mantiene hacia donde se miraba)
	if (victim - eye).Magnitude > 0.5 then
		k.Look = CFrame.lookAt(eye + Vector3.new(0, 0.15, 0), victim - Vector3.new(0, 0.4, 0))
	end
	camera.CFrame = k.Look or CFrame.new(eye + Vector3.new(0, 0.15, 0))
	setModelLook(k.Killer, 1)
	setModelLook(k.Victim, 0)
end

-- Empieza una repetición; devuelve false si no hay con qué (poca historia, o sin línea de visión).
-- opts: Killer, Victim (modelos; pueden faltar si ya no están: entonces KillerName/VictimName),
--       At (os.clock() de la baja), Title, Name (texto de debajo), CheckSight, Final, OnEnd()
function Killcam.Play(opts)
	if not Killcam.Enabled then
		return false
	end
	local killerTrack = Killcam.Track(opts.Killer, opts.KillerName)
	local victimTrack = Killcam.Track(opts.Victim, opts.VictimName)
	if not killerTrack or not victimTrack or #killerTrack < 6 or #victimTrack < 6 then
		return false
	end
	local at = opts.At or os.clock()
	local available = at - killerTrack[1][1]
	if available < 0.6 then
		return false
	end
	if opts.CheckSight then
		local eye, target = Killcam.SampleAt(killerTrack, at), Killcam.SampleAt(victimTrack, at)
		if not eye or not target or not Killcam.ClearLine(eye, target) then
			return false
		end
	end
	Killcam.Stop(false) -- (nunca dos a la vez)
	local span = math.min(Killcam.Length, available)
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "KillcamColor"
	effect.Saturation = -0.45
	effect.Contrast = 0.12
	effect.TintColor = Color3.fromRGB(235, 240, 255)
	effect.Parent = camera
	current = {
		Start = os.clock(),
		From = at - span,
		Span = span,
		KillerTrack = table.clone(killerTrack),
		VictimTrack = table.clone(victimTrack),
		Killer = opts.Killer,
		Victim = opts.Victim,
		Fov = camera.FieldOfView,
		CameraBefore = camera.CFrame,
		Effect = effect,
		Final = opts.Final == true,
		OnEnd = opts.OnEnd,
		Look = nil :: CFrame?,
	}
	ClientState.KillcamActive = true
	ClientState.KillcamFinal = opts.Final == true
	if refs.Frame then
		refs.Title.Text = opts.Title or "▶ KILLCAM"
		refs.Name.Text = opts.Name or ""
		refs.Frame.Visible = true
	end
	-- (al final de todo lo demás: nada mueve la cámara mientras dura)
	RunService:BindToRenderStep("Killcam", Enum.RenderPriority.Last.Value, step)
	return true
end

-- "Nombre · Arma" para el rótulo
function Killcam.Caption(who, weaponName)
	local name = who
	if typeof(who) == "Instance" then
		name = who:IsA("Player") and who.DisplayName or who.Name
	end
	local weapon = type(weaponName) == "string" and Weapons.List[weaponName]
	local weaponText = weapon and weapon.DisplayName or weaponName
	return tostring(name or "") .. ((weaponText and weaponText ~= "") and ("  ·  " .. tostring(weaponText)) or "")
end

local function modelNamed(name)
	if type(name) ~= "string" then
		return nil
	end
	local p = Players:FindFirstChild(name)
	if p and p:IsA("Player") then
		return p.Character, p
	end
	local bots = workspace:FindFirstChild("Bots")
	return bots and bots:FindFirstChild(name) or nil, nil
end

-- Killcam final (la manda el servidor): la última baja de la partida o de la ronda
function Killcam.PlayFinal(info)
	if type(info) ~= "table" or ClientState.InMainMenu then
		return false
	end
	local killer, killerPlayer = modelNamed(info.Killer)
	local victim = modelNamed(info.Victim)
	local at = lastKills[tostring(info.Killer) .. "|" .. tostring(info.Victim)] or (os.clock() - 0.3)
	return Killcam.Play({
		Killer = killer,
		Victim = victim,
		KillerName = info.Killer,
		VictimName = info.Victim,
		At = at,
		Title = "▶ KILLCAM FINAL",
		Name = Killcam.Caption(killerPlayer or info.Killer, info.Weapon),
		Final = true,
	})
end

local function buildOverlay()
	gui = UI.new("ScreenGui", {
		Name = "Killcam",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 40,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Bandas negras de cine arriba y abajo, «KILLCAM» y quién hizo la baja con qué
	refs.Frame = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
	UI.new("Frame", {
		Size = UDim2.new(1, 0, 0.09, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = refs.Frame,
	})
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0.09, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = refs.Frame,
	})
	refs.Title = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.09, 6),
		Size = UDim2.new(0.6, 0, 0, 34),
		Text = "▶ KILLCAM",
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 70, 60),
		TextStrokeTransparency = 0.2,
		Parent = refs.Frame,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = 30 }) })
	refs.Name = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.09, 40),
		Size = UDim2.new(0.6, 0, 0, 24),
		Text = "",
		TextScaled = true,
		Parent = refs.Frame,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = 20 }) })
end

function Killcam.Init()
	buildOverlay()
	-- Historia de posiciones (cada SampleTime s)
	RunService.Heartbeat:Connect(function(dt)
		sampleClock += dt
		if sampleClock >= Killcam.SampleTime then
			sampleClock = 0
			local ok, err = pcall(Killcam.Record)
			if not ok then
				warn("[Killcam]", err)
			end
		end
	end)
	-- Cuándo pasó cada baja en este cliente (la final se repite justo hasta ese momento)
	Remotes.KillFeed.OnClientEvent:Connect(function(info)
		if type(info) == "table" and info.Killer and info.Victim then
			lastKills[tostring(info.Killer) .. "|" .. tostring(info.Victim)] = os.clock()
		end
	end)
	Remotes.FinalKillcam.OnClientEvent:Connect(function(info)
		local ok, err = pcall(Killcam.PlayFinal, info)
		if not ok then
			warn("[Killcam] final:", err)
		end
	end)
	-- La final también se puede saltar (clic o toque); la de la muerte la salta DeathScreen
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not current or not current.Final then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Killcam.Stop(true)
		end
	end)
end

return Killcam
