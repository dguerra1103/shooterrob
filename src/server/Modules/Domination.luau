-- Modo "Dominio" (el clásico de los shooters de móvil): tres banderas A, B y C. A queda cerca de la
-- base del primer equipo, B en el centro y C cerca de la base del segundo. Se captura quedándose
-- dentro (~5 s; más rápido con más compañeros) sin enemigos; si hay de los dos equipos, la captura
-- se para. Cada bandera tuya suma 1 punto cada SCORE_EVERY segundos.
--
-- Estado para la interfaz (atributos de ReplicatedStorage), para cada letra L en A, B, C:
--   Dom_L_Position (Vector3), Dom_L_Owner ("" o equipo), Dom_L_Capturing ("" o equipo),
--   Dom_L_Progress (0..1, de la captura en curso), Dom_L_Contested (bool)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)

local Domination = {}

Domination.OnScore = nil -- function(team, amount)

local LETTERS = { "A", "B", "C" }
local CAPTURE_TIME = 5 -- segundos con una persona
local SCORE_EVERY = 3 -- segundos entre puntos de cada bandera
local STEP = 0.25

local active = false
local points = {} -- { Letter, Position, Radius, Owner (Team?), Capturing (Team?), Progress, Visual }
local thread

local function findZones()
	local list = {}
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "HardpointZone" then
				table.insert(list, d)
			end
		end
	end
	return list
end

local function teamSpawnCenter(team)
	local map = workspace:FindFirstChild("Map")
	local sum, count = Vector3.zero, 0
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("SpawnLocation") and d.TeamColor == team.TeamColor then
				sum += d.Position
				count += 1
			end
		end
	end
	return count > 0 and sum / count or nil
end

function Domination.IsAvailable()
	return #findZones() >= 3
end

-- A: la zona más cerca de la base del primer equipo; C: la más cerca de la del segundo; B: la más
-- centrada entre las dos (de las que quedan)
local function choosePoints()
	local zones = findZones()
	local teams = Teams:GetTeams()
	if #zones < 3 or #teams < 2 then
		return nil
	end
	local baseA, baseB = teamSpawnCenter(teams[1]), teamSpawnCenter(teams[2])
	if not baseA or not baseB then
		return { zones[1], zones[2], zones[3] }
	end
	local function closest(list, target, exclude)
		local best, bestDistance = nil, math.huge
		for _, zone in list do
			if not exclude[zone] then
				local distance = (zone.Position - target).Magnitude
				if distance < bestDistance then
					best, bestDistance = zone, distance
				end
			end
		end
		return best
	end
	local used = {}
	local middle = (baseA + baseB) / 2
	local b = closest(zones, middle, used)
	used[b] = true
	local a = closest(zones, baseA, used)
	used[a] = true
	local c = closest(zones, baseB, used)
	return { a, b, c }
end

local function makeVisual(point)
	local radius = point.Radius
	local model = Instance.new("Model")
	model.Name = "DomFlag_" .. point.Letter
	local function part(name, size, cf, material, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		p.CFrame = cf
		p.Material = material
		p.Transparency = transparency or 0
		p.Color = Color3.new(1, 1, 1)
		p.Parent = model
		return p
	end
	local base = point.Position
	local ring = part("Ring", Vector3.new(0.3, radius * 2 + 1, radius * 2 + 1), CFrame.new(base + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	local fill = part("Fill", Vector3.new(0.32, radius * 2 - 1, radius * 2 - 1), CFrame.new(base + Vector3.new(0, 0.21, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.ForceField, 0.35)
	fill.Shape = Enum.PartType.Cylinder
	-- Mástil: en el centro si hay sitio; si hay algo justo encima (un monumento), hacia el borde de
	-- la zona; bajo techo (dentro de un edificio), más bajo
	local poleBase, poleHeight = base, 9
	local bestRoom = -1
	for _, offset in { Vector3.zero, Vector3.new(radius * 0.6, 0, 0), Vector3.new(0, 0, radius * 0.6), Vector3.new(-radius * 0.6, 0, 0), Vector3.new(0, 0, -radius * 0.6) } do
		local hit = workspace:Raycast(base + offset + Vector3.new(0, 1, 0), Vector3.new(0, 10, 0))
		local room = hit and hit.Distance or 10
		if room > bestRoom then
			bestRoom, poleBase = room, base + offset
		end
		if room >= 9 then
			break
		end
	end
	poleHeight = math.clamp(bestRoom + 1 - 0.6, 3, 9)
	local pole = part("Pole", Vector3.new(0.4, poleHeight, 0.4), CFrame.new(poleBase + Vector3.new(0, poleHeight / 2, 0)), Enum.Material.Metal)
	pole.Color = Color3.fromRGB(60, 60, 64)
	part("Flag", Vector3.new(0.15, math.min(2.4, poleHeight * 0.3), 3.6), CFrame.new(poleBase + Vector3.new(0, poleHeight - 1.4, 1.8)), Enum.Material.Fabric)
	local light = Instance.new("PointLight")
	light.Range = radius * 2
	light.Brightness = 1.5
	light.Parent = ring
	-- Letra visible a través de las paredes
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.StudsOffset = Vector3.new(0, 11, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 1500
	billboard.Parent = pole
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.2
	label.Text = point.Letter
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = billboard
	model.Parent = workspace
	point.Visual = model
end

local function paint(point)
	local color = point.Owner and point.Owner.TeamColor.Color or Color3.new(1, 1, 1)
	if point.Contested then
		color = Color3.fromRGB(255, 200, 40)
	end
	if point.Painted == color or not point.Visual then
		return
	end
	point.Painted = color
	for _, p in point.Visual:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Pole" then
			p.Color = color
		elseif p:IsA("PointLight") then
			p.Color = color
		elseif p:IsA("TextLabel") then
			p.TextColor3 = color
		end
	end
end

-- Quién está dentro: { [Team] = { jugadores } } (los bots cuentan, sin lista de jugadores)
local function occupants(point)
	local byTeam, counts = {}, {}
	local function add(team, player, root)
		local offset = root.Position - point.Position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude <= point.Radius and offset.Y > -3 and offset.Y < 10 then
			byTeam[team] = byTeam[team] or {}
			counts[team] = (counts[team] or 0) + 1
			if player then
				table.insert(byTeam[team], player)
			end
		end
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if player.Team and humanoid and humanoid.Health > 0 and root and not player:GetAttribute("InMenu") then
			add(player.Team, player, root)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			local team = Teams:FindFirstChild(model:GetAttribute("Team") or "")
			if team and team:IsA("Team") and humanoid and humanoid.Health > 0 and root then
				add(team, nil, root)
			end
		end
	end
	return byTeam, counts
end

local function publish(point)
	local prefix = "Dom_" .. point.Letter .. "_"
	ReplicatedStorage:SetAttribute(prefix .. "Owner", point.Owner and point.Owner.Name or "")
	ReplicatedStorage:SetAttribute(prefix .. "Capturing", point.Capturing and point.Capturing.Name or "")
	ReplicatedStorage:SetAttribute(prefix .. "Progress", math.floor(point.Progress * 100 + 0.5) / 100)
	ReplicatedStorage:SetAttribute(prefix .. "Contested", point.Contested == true)
end

local function update(point, dt)
	local byTeam, counts = occupants(point)
	local present = {}
	for team in byTeam do
		table.insert(present, team)
	end
	point.Contested = #present > 1
	if #present == 1 and present[1] ~= point.Owner then
		-- Capturando (si había otro equipo a medias, empieza de cero)
		local team = present[1]
		if point.Capturing ~= team then
			point.Capturing, point.Progress = team, 0
		end
		local speed = math.min(2, 1 + (counts[team] - 1) * 0.5) -- (más gente, más rápido)
		point.Progress = math.min(1, point.Progress + dt * speed / CAPTURE_TIME)
		if point.Progress >= 1 then
			local previous = point.Owner
			point.Owner, point.Capturing, point.Progress = team, nil, 0
			Remotes.Notify:FireAllClients("Flag", "🚩 " .. team.Name .. " captura " .. point.Letter .. (previous and " (era de " .. previous.Name .. ")" or ""))
			for _, player in byTeam[team] do
				PlayerData.AddXP(player, 50, "Captura " .. point.Letter)
				PlayerData.Track(player, "ZoneTime", 5)
			end
		end
	elseif #present == 1 and present[1] == point.Owner and point.Capturing then
		-- Los dueños vuelven a su bandera: deshacen la captura enemiga a medias
		point.Progress = math.max(0, point.Progress - dt * 2 / CAPTURE_TIME)
		if point.Progress <= 0 then
			point.Capturing = nil
		end
	elseif #present == 0 and point.Capturing then
		-- Nadie dentro: la captura a medias se va perdiendo
		point.Progress = math.max(0, point.Progress - dt / CAPTURE_TIME)
		if point.Progress <= 0 then
			point.Capturing = nil
		end
	end
	paint(point)
	publish(point)
end

function Domination.Start()
	Domination.Stop()
	local zones = choosePoints()
	if not zones then
		return false
	end
	points = {}
	for i, zone in zones do
		local point = {
			Letter = LETTERS[i],
			Position = zone.Position,
			Radius = math.max(8, zone:GetAttribute("Radius") or 10),
			Owner = nil,
			Capturing = nil,
			Progress = 0,
		}
		ReplicatedStorage:SetAttribute("Dom_" .. point.Letter .. "_Position", point.Position)
		makeVisual(point)
		publish(point)
		table.insert(points, point)
	end
	active = true
	thread = task.spawn(function()
		local scoreClock = 0
		while active do
			task.wait(STEP)
			scoreClock += STEP
			for _, point in points do
				update(point, STEP)
			end
			if scoreClock >= SCORE_EVERY then
				scoreClock = 0
				for _, point in points do
					if point.Owner and Domination.OnScore then
						Domination.OnScore(point.Owner, 1)
					end
				end
			end
		end
	end)
	return true
end

-- Para los bots: las banderas con su estado
function Domination.Points()
	return points
end

function Domination.Stop()
	active = false
	if thread then
		pcall(task.cancel, thread)
		thread = nil
	end
	for _, point in points do
		if point.Visual then
			point.Visual:Destroy()
		end
	end
	points = {}
	for _, letter in LETTERS do
		for _, field in { "Position", "Owner", "Capturing", "Progress", "Contested" } do
			ReplicatedStorage:SetAttribute("Dom_" .. letter .. "_" .. field, nil)
		end
	end
end

return Domination
