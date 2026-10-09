-- Minimapa (arriba a la izquierda, como en los shooters de móvil): el mapa visto desde arriba con
-- los edificios y muros, tú en el centro (la flecha mira hacia donde miras), tus compañeros en azul,
-- los enemigos que disparan sin silenciador como puntos rojos durante unos segundos y, con el
-- Radar de la racha, todos los enemigos. También la zona de control y las banderas.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Weapons = require(Shared.Weapons)
local GameConfig = require(Shared.GameConfig)

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Minimap = {}

local RANGE = 170 -- studs que caben a lo ancho
local RED_DOT_TIME = 2.5 -- segundos que se ve el punto rojo de un disparo
local MAX_SHAPES = 900

local gui, frame, world, me
local border, enemyRadarLabel
local lastEnemyRadar, nextRadarCheck = false, 0
local size, scale = 160, 160 / RANGE
local shapesFolder
local builtFor = nil
local shots = {} -- [modelo] = { Position, Time }
local dots = {} -- círculos reutilizables
local usedDots = 0

-- ¿Está en el equipo contrario? (en todos contra todos, todos lo están)
local function isEnemy(model)
	if not ReplicatedStorage:GetAttribute("TeamMode") then
		return model ~= player.Character
	end
	local owner = Players:GetPlayerFromCharacter(model)
	local team = owner and owner.Team and owner.Team.Name or model:GetAttribute("Team")
	return team ~= nil and team ~= "" and player.Team ~= nil and team ~= player.Team.Name
end

local function isTeammate(model)
	if not ReplicatedStorage:GetAttribute("TeamMode") or model == player.Character then
		return false
	end
	local owner = Players:GetPlayerFromCharacter(model)
	local team = owner and owner.Team and owner.Team.Name or model:GetAttribute("Team")
	return player.Team ~= nil and team == player.Team.Name
end

---------------------------------------------------------------------------
-- Plano del mapa (se rehace al cambiar de mapa)
---------------------------------------------------------------------------

local function rebuild()
	local map = workspace:FindFirstChild("Map")
	builtFor = map
	if shapesFolder then
		shapesFolder:Destroy()
	end
	shapesFolder = UI.new("Folder", { Name = "Shapes", Parent = world })
	if not map then
		return
	end
	local boundary = map:FindFirstChild("Boundary")
	local count = 0
	for _, part in map:GetDescendants() do
		if count >= MAX_SHAPES then
			break
		end
		if part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.9 and not (boundary and part:IsDescendantOf(boundary)) then
			local cf = part.CFrame
			local s = part.Size
			-- Solo lo que es "de pie" (muros, edificios, coberturas): no suelos ni piezas inclinadas
			if cf.UpVector.Y > 0.95 and s.Y >= 2.5 and s.X * s.Z >= 6 and cf.Position.Y + s.Y / 2 > 2.5 and part.Shape ~= Enum.PartType.Ball then
				count += 1
				local right = cf.RightVector
				local tall = s.Y >= 6
				UI.new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(cf.Position.X * scale, cf.Position.Z * scale),
					Size = UDim2.fromOffset(math.max(1, s.X * scale), math.max(1, s.Z * scale)),
					Rotation = math.deg(math.atan2(right.Z, right.X)),
					BackgroundColor3 = tall and Color3.fromRGB(205, 205, 210) or Color3.fromRGB(150, 150, 158),
					BackgroundTransparency = tall and 0.25 or 0.4,
					BorderSizePixel = 0,
					Parent = shapesFolder,
				})
			end
		end
	end
end

---------------------------------------------------------------------------
-- Puntos
---------------------------------------------------------------------------

local function dot(position, color, radius, square)
	usedDots += 1
	local d = dots[usedDots]
	if not d then
		d = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = frame,
		}, { UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }), UI.stroke(Color3.new(0, 0, 0), 1, 0.3) })
		dots[usedDots] = d
	end
	local corner = d:FindFirstChildOfClass("UICorner")
	if corner then
		corner.CornerRadius = square and UDim.new(0, 2) or UDim.new(1, 0)
	end
	d.Visible = true
	d.BackgroundTransparency = 0
	local letter = d:FindFirstChild("Letter")
	if letter then
		letter.Text = ""
	end
	d.BackgroundColor3 = color
	d.Size = UDim2.fromOffset(radius * 2, radius * 2)
	d.Position = UDim2.new(0.5, position.X, 0.5, position.Y)
	return d
end

-- Posición en el minimapa (respecto al centro) de un punto del mundo; nil si se sale
local function toMap(worldPosition, center)
	local offset = Vector2.new(worldPosition.X - center.X, worldPosition.Z - center.Z) * scale
	local half = size / 2 - 4
	if math.abs(offset.X) > half or math.abs(offset.Y) > half then
		-- (los objetivos se quedan pegados al borde para saber hacia dónde están)
		return nil, Vector2.new(math.clamp(offset.X, -half, half), math.clamp(offset.Y, -half, half))
	end
	return offset
end

local function update()
	local visible = not ClientState.InMainMenu and ReplicatedStorage:GetAttribute("State") == "Playing"
	gui.Enabled = visible
	if not visible then
		return
	end
	local map = workspace:FindFirstChild("Map")
	if map ~= builtFor then
		rebuild()
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local center = root and root.Position or camera.CFrame.Position
	world.Position = UDim2.new(0.5, -center.X * scale, 0.5, -center.Z * scale)
	local look = camera.CFrame.LookVector
	me.Rotation = math.deg(math.atan2(look.X, -look.Z))

	usedDots = 0
	local now = os.clock()
	-- Compañeros (jugadores y bots)
	local radar = workspace:GetServerTimeNow() < (player:GetAttribute("RadarUntil") or 0)
	-- Radar enemigo: borde rojo y aviso mientras otro equipo lo tenga (se mira 3 veces por segundo)
	local enemyRadar = lastEnemyRadar
	if now >= nextRadarCheck then
		nextRadarCheck = now + 0.3
		enemyRadar = false
		if ReplicatedStorage:GetAttribute("TeamMode") ~= false and player.Team then
			local serverNow = workspace:GetServerTimeNow()
			for name, value in ReplicatedStorage:GetAttributes() do
				if string.sub(name, 1, 6) == "Radar_" and name ~= "Radar_" .. player.Team.Name and type(value) == "number" and value > serverNow then
					enemyRadar = true
					break
				end
			end
		end
	end
	if enemyRadar ~= lastEnemyRadar then
		lastEnemyRadar = enemyRadar
		if border then
			border.Color = enemyRadar and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(230, 230, 235)
			border.Transparency = enemyRadar and 0 or 0.35
		end
		enemyRadarLabel.Visible = enemyRadar
	end
	local models = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Character then
			table.insert(models, other.Character)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			table.insert(models, model)
		end
	end
	for _, model in models do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local part = model:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and part then
			if isTeammate(model) then
				local p = toMap(part.Position, center)
				if p then
					dot(p, Color3.fromRGB(70, 160, 255), 4)
				end
			elseif radar and isEnemy(model) then
				local p = toMap(part.Position, center)
				if p then
					dot(p, Color3.fromRGB(255, 50, 50), 4)
				end
			end
		end
	end
	-- Disparos enemigos recientes (puntos rojos donde dispararon)
	for model, shot in shots do
		if now - shot.Time > RED_DOT_TIME or not model.Parent then
			shots[model] = nil
		else
			local p = toMap(shot.Position, center)
			if p then
				local d = dot(p, Color3.fromRGB(255, 40, 40), 4.5)
				d.BackgroundTransparency = math.clamp((now - shot.Time) / RED_DOT_TIME, 0, 0.7)
			end
		end
	end
	-- Objetivos: zona de control y banderas (pegados al borde si están lejos)
	local zone = ReplicatedStorage:GetAttribute("ZonePosition")
	if typeof(zone) == "Vector3" then
		local p, edge = toMap(zone, center)
		dot(p or edge, Color3.fromRGB(255, 210, 40), 6, true)
	end
	-- Dominio: las tres banderas con su letra y el color de su dueño
	for _, letter in { "A", "B", "C" } do
		local position = ReplicatedStorage:GetAttribute("Dom_" .. letter .. "_Position")
		if typeof(position) == "Vector3" then
			local p, edge = toMap(position, center)
			local owner = Teams:FindFirstChild(ReplicatedStorage:GetAttribute("Dom_" .. letter .. "_Owner") or "")
			local d = dot(p or edge, owner and owner:IsA("Team") and owner.TeamColor.Color or Color3.fromRGB(230, 230, 235), 7, true)
			local label = d:FindFirstChild("Letter") or UI.label({
				Name = "Letter",
				Size = UDim2.fromScale(1, 1),
				TextSize = 11,
				TextStrokeTransparency = 1,
				TextColor3 = Color3.new(0, 0, 0),
				Parent = d,
			})
			label.Text = letter
		end
	end
	-- Buscar y destruir: los sitios de la bomba (en rojo el de la bomba plantada)
	for _, letter in { "A", "B" } do
		local position = ReplicatedStorage:GetAttribute("Bomb_" .. letter .. "_Position")
		if typeof(position) == "Vector3" then
			local p, edge = toMap(position, center)
			local planted = ReplicatedStorage:GetAttribute("Bomb_State") == "Planted" and ReplicatedStorage:GetAttribute("Bomb_Site") == letter
			local d = dot(p or edge, planted and Color3.fromRGB(255, 60, 50) or Color3.fromRGB(255, 190, 60), 7, true)
			local label = d:FindFirstChild("Letter") or UI.label({
				Name = "Letter",
				Size = UDim2.fromScale(1, 1),
				TextSize = 11,
				TextStrokeTransparency = 1,
				TextColor3 = Color3.new(0, 0, 0),
				Parent = d,
			})
			label.Text = letter
		end
	end
	-- La bomba en el suelo (solo la ven los atacantes, que son quienes la pueden recoger)
	local dropped = ReplicatedStorage:GetAttribute("Bomb_Dropped")
	if typeof(dropped) == "Vector3" and player.Team and player.Team.Name == ReplicatedStorage:GetAttribute("Bomb_Attackers") then
		local p, edge = toMap(dropped, center)
		local d = dot(p or edge, Color3.fromRGB(255, 120, 30), 6, true)
		local label = d:FindFirstChild("Letter") or UI.label({
			Name = "Letter",
			Size = UDim2.fromScale(1, 1),
			TextSize = 11,
			TextStrokeTransparency = 1,
			TextColor3 = Color3.new(0, 0, 0),
			Parent = d,
		})
		label.Text = "💣"
	end
	for _, team in GameConfig.Teams do
		local flag = ReplicatedStorage:GetAttribute("FlagPos_" .. team.Name)
		if typeof(flag) == "Vector3" then
			local p, edge = toMap(flag, center)
			dot(p or edge, team.Color.Color, 5, true)
		end
	end
	for i = usedDots + 1, #dots do
		dots[i].Visible = false
	end
end

Minimap.Update = update

-- Disparo de otro jugador o bot (los mismos avisos que dibujan sus trazadoras)
local function onShot(tool)
	if typeof(tool) ~= "Instance" or not tool.Parent then
		return
	end
	local model = tool.Parent
	local def = Weapons.Get(tool:GetAttribute("Weapon"))
	if def and def.Suppressed then
		return -- con silenciador no sale en el minimapa
	end
	local owner = Players:GetPlayerFromCharacter(model)
	if owner and owner:GetAttribute("Perk") == 3 then
		return -- (ventaja "Fantasma")
	end
	local part = model:FindFirstChild("HumanoidRootPart") or tool:FindFirstChild("Handle")
	if part and part:IsA("BasePart") and isEnemy(model) then
		shots[model] = { Position = part.Position, Time = os.clock() }
	end
end

function Minimap.Init()
	-- (se espera a saber el tamaño de la pantalla: al arrancar puede valer 0 y en el móvil salía
	-- el minimapa grande del ordenador)
	UI.WaitViewport()
	local viewport = camera.ViewportSize
	local phone = UI.IsPhone()
	size = phone and 96 or ((viewport.Y > 0 and viewport.Y < 500) and 112 or 160)
	-- (Fase 15: en teléfonos bajos, como 568×320, algo más pequeño para que quepan las habilidades)
	if phone and math.min(viewport.X, viewport.Y) < 350 then
		size = 84
	end
	-- (debajo de los botones de Roblox de arriba a la izquierda, que si no lo tapaban)
	-- (en pantallas táctiles; en el ordenador, arriba del todo como siempre)
	local touchOnly = InputMode.TouchUI()
	local top = touchOnly and UI.TopbarBottom() or 14
	scale = size / RANGE
	gui = UI.new("ScreenGui", {
		Name = "Minimap",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- (táctil en pantallas alargadas, Fase 15: algo separado del borde, como el resto del HUD)
	local aspect = math.max(viewport.X, viewport.Y) / math.max(1, math.min(viewport.X, viewport.Y))
	local left = (touchOnly and aspect >= 1.95) and 22 or 14
	frame = UI.new("Frame", {
		Position = UDim2.fromOffset(left, top),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.fromRGB(22, 26, 30),
		BackgroundTransparency = 0.3,
		ClipsDescendants = true,
		Parent = gui,
	}, { UI.corner(8), UI.stroke(Color3.fromRGB(230, 230, 235), 2, 0.35) })
	border = frame:FindFirstChildOfClass("UIStroke")
	enemyRadarLabel = UI.label({
		Position = UDim2.new(0, 0, 1, -16),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "📡 RADAR ENEMIGO",
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 120, 120),
		BackgroundColor3 = Color3.fromRGB(60, 0, 0),
		BackgroundTransparency = 0.35,
		ZIndex = 6,
		Visible = false,
		Parent = frame,
	})
	world = UI.new("Frame", {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	me = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		Text = "▲",
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 230, 90),
		ZIndex = 5,
		Parent = frame,
	})
	-- (el botón de PASE · TIENDA y lo demás de la izquierda van debajo)
	ClientState.MinimapBottom = top + size
	ClientState.MinimapLeft = left
	ClientState.MinimapSize = size
	Remotes.ShotFX.OnClientEvent:Connect(onShot)
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 / 30 then
			return
		end
		accumulator = 0
		update()
	end)
end

return Minimap
