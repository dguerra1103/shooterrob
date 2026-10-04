-- Modo "Zona de control": una zona activa que cambia de sitio cada minuto. El equipo que la ocupa
-- (sin enemigos dentro) suma 1 punto por segundo. Si hay jugadores de los dos equipos, está disputada.
--
-- Estado para la interfaz (atributos de ReplicatedStorage):
--   ZoneOwner = "" | nombre del equipo | "Contested",  ZoneMoveIn = segundos hasta que cambie,
--   ZonePosition = Vector3
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)

local Hardpoint = {}

Hardpoint.OnScore = nil -- function(team, amount)

local ROTATE_TIME = 60
local XP_INTERVAL = 5

local active = false
local zones = {}
local index = 0
local visual
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
	table.sort(list, function(a, b)
		return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
	end)
	return list
end

function Hardpoint.IsAvailable()
	return #findZones() > 0
end

local function makeVisual(zone)
	if visual then
		visual:Destroy()
	end
	local radius = zone:GetAttribute("Radius") or 10
	local model = Instance.new("Model")
	model.Name = "ActiveZone"
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
	local base = zone.Position
	local ring = part("Ring", Vector3.new(0.3, radius * 2 + 1, radius * 2 + 1), CFrame.new(base + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	local inner = part("Fill", Vector3.new(0.32, radius * 2 - 1, radius * 2 - 1), CFrame.new(base + Vector3.new(0, 0.21, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.ForceField, 0.3)
	inner.Shape = Enum.PartType.Cylinder
	local beam = part("Beam", Vector3.new(80, radius * 0.6, radius * 0.6), CFrame.new(base + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Neon, 0.8)
	beam.Shape = Enum.PartType.Cylinder
	local light = Instance.new("PointLight")
	light.Range = radius * 2
	light.Brightness = 2
	light.Parent = ring
	-- Marcador visible a través de las paredes
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 50)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 1500
	billboard.Parent = ring
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.2
	label.Text = "◆ ZONA"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = billboard
	model.Parent = workspace
	visual = model
end

local function paint(color)
	if not visual then
		return
	end
	for _, p in visual:GetDescendants() do
		if p:IsA("BasePart") then
			p.Color = color
		elseif p:IsA("PointLight") then
			p.Color = color
		elseif p:IsA("TextLabel") then
			p.TextColor3 = color
		end
	end
end

local function playersInZone(zone)
	local radius = zone:GetAttribute("Radius") or 10
	local center = zone.Position
	local byTeam = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if player.Team and humanoid and humanoid.Health > 0 and root and not player:GetAttribute("InMenu") then
			local offset = root.Position - center
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius and offset.Y > -3 and offset.Y < 10 then
				byTeam[player.Team] = byTeam[player.Team] or {}
				table.insert(byTeam[player.Team], player)
			end
		end
	end
	-- Los bots también ocupan y disputan la zona (sin XP: su lista queda vacía)
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			local team = Teams:FindFirstChild(model:GetAttribute("Team") or "")
			if team and team:IsA("Team") and humanoid and humanoid.Health > 0 and root then
				local offset = root.Position - center
				if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius and offset.Y > -3 and offset.Y < 10 then
					byTeam[team] = byTeam[team] or {}
				end
			end
		end
	end
	return byTeam
end

local function moveTo(i)
	index = i
	local zone = zones[index]
	makeVisual(zone)
	ReplicatedStorage:SetAttribute("ZonePosition", zone.Position)
	Remotes.Notify:FireAllClients("Flag", "¡La zona se ha movido!")
end

function Hardpoint.Start()
	Hardpoint.Stop()
	zones = findZones()
	if #zones == 0 then
		return false
	end
	active = true
	moveTo(1)
	thread = task.spawn(function()
		local moveAt = os.clock() + ROTATE_TIME
		local tick = 0
		while active do
			task.wait(1)
			tick += 1
			local remaining = math.max(0, math.ceil(moveAt - os.clock()))
			ReplicatedStorage:SetAttribute("ZoneMoveIn", remaining)
			if remaining <= 0 then
				moveAt = os.clock() + ROTATE_TIME
				moveTo(index % #zones + 1)
			end
			local byTeam = playersInZone(zones[index])
			local owner, count = nil, 0
			for team in byTeam do
				count += 1
				owner = team
			end
			if count == 0 then
				ReplicatedStorage:SetAttribute("ZoneOwner", "")
				paint(Color3.new(1, 1, 1))
			elseif count > 1 then
				ReplicatedStorage:SetAttribute("ZoneOwner", "Contested")
				paint(Color3.fromRGB(255, 200, 40))
			else
				ReplicatedStorage:SetAttribute("ZoneOwner", owner.Name)
				paint(owner.TeamColor.Color)
				if Hardpoint.OnScore then
					Hardpoint.OnScore(owner, 1)
				end
				for _, player in byTeam[owner] do
					PlayerData.Track(player, "ZoneTime", 1)
				end
				if tick % XP_INTERVAL == 0 then
					for _, player in byTeam[owner] do
						PlayerData.AddXP(player, 20, "Zona")
					end
				end
			end
		end
	end)
	return true
end

function Hardpoint.Stop()
	active = false
	if thread then
		pcall(task.cancel, thread)
		thread = nil
	end
	if visual then
		visual:Destroy()
		visual = nil
	end
	ReplicatedStorage:SetAttribute("ZoneOwner", nil)
	ReplicatedStorage:SetAttribute("ZonePosition", nil)
	ReplicatedStorage:SetAttribute("ZoneMoveIn", nil)
end

return Hardpoint
