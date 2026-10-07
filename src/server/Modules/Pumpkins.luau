-- Modo Calabazas (como "Kill Confirmed"): quien cae suelta una calabaza con el color de su equipo.
-- Si la recoge el equipo contrario, punto para ellos (baja confirmada); si la recoge un compañero del
-- caído, la baja no cuenta (recuperada). Las calabazas desaparecen a los LIFETIME segundos.
-- Round decide qué pasa al recoger (OnCollect) y quién puede recoger (Collectors).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pumpkins = {}

Pumpkins.OnCollect = nil -- function(collector, confirmed, pumpkinTeam)
Pumpkins.Collectors = nil -- function() -> { { Position, Team, Player?, Bot? } }

local LIFETIME = 30
local RADIUS = 4.5

local running = false
local generation = 0 -- (cada Start tiene su propio bucle; el de una partida anterior se para solo)
local active = {} -- { Model, Position, Team, Expires }
local folder

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Suelo bajo el punto (quien cae en el aire suelta la calabaza en el suelo). nil si debajo no hay
-- suelo o es lava (nadie podría recogerla y los bots se lanzarían a por ella)
local function groundBelow(position)
	local map = workspace:FindFirstChild("Map")
	if not map then
		return position
	end
	rayParams.FilterDescendantsInstances = { map, workspace.Terrain } -- (algunos mapas tienen suelo de terreno)
	local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), rayParams)
	if not hit then
		return nil
	end
	local part = hit.Instance
	if part:GetAttribute("Hazard") or hit.Material == Enum.Material.CrackedLava or part.Name == "Lava" then
		return nil
	end
	return hit.Position
end

-- Fuera de Halloween el modo es "Baja confirmada": en vez de calabazas, placas de identificación
-- (se decide al empezar la partida: si Halloween empieza o acaba a mitad, no cambia)
local tagsThisMatch = nil
function Pumpkins.Tags()
	if tagsThisMatch ~= nil then
		return tagsThisMatch
	end
	return ReplicatedStorage:GetAttribute("EventName") ~= "Halloween"
end

local function build(position, team)
	local tags = Pumpkins.Tags()
	local model = Instance.new("Model")
	model.Name = "Pumpkin"
	local body = Instance.new("Part")
	body.Name = "PumpkinBody"
	if tags then
		-- Placa metálica colgando (con el color del equipo en el anillo del suelo)
		body.Size = Vector3.new(1.3, 1.9, 0.2)
		body.Color = Color3.fromRGB(205, 208, 214)
		body.Material = Enum.Material.Metal
	else
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(2.4, 2.4, 2.4)
		body.Color = Color3.fromRGB(255, 130, 20)
		body.Material = Enum.Material.SmoothPlastic
	end
	body.CFrame = CFrame.new(position + Vector3.new(0, 1.7, 0))
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.CastShadow = false
	-- (WorldFX la hace flotar en el cliente)
	body:SetAttribute("Bob", 0.35)
	local light = Instance.new("PointLight")
	light.Color = tags and Color3.fromRGB(230, 236, 255) or Color3.fromRGB(255, 160, 60)
	light.Range = 8
	light.Brightness = 1
	light.Parent = body
	local face = Instance.new("BillboardGui")
	face.Size = UDim2.fromOffset(46, 46)
	face.AlwaysOnTop = false
	face.LightInfluence = 0
	face.MaxDistance = 120
	face.Parent = body
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Text = tags and "🏷️" or "🎃"
	icon.TextScaled = true
	icon.Parent = face
	body.Parent = model
	-- Anillo en el suelo con el color del equipo del caído
	local ring = Instance.new("Part")
	ring.Name = "PumpkinRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 4.5, 4.5)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Color = team and team.TeamColor.Color or Color3.new(1, 1, 1)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.35
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Parent = model
	model.Parent = folder
	return model
end

-- Suelta una calabaza donde cayó alguien del equipo `team`. victimId: UserId del caído (nunca puede
-- recoger la suya); fromBot: el caído era un bot (premia menos)
function Pumpkins.Drop(position, team, victimId, fromBot)
	if not running or typeof(position) ~= "Vector3" or not team then
		return
	end
	local ground = groundBelow(position)
	if not ground then
		return
	end
	table.insert(active, { Model = build(ground, team), Position = ground, Team = team, Expires = os.clock() + LIFETIME, VictimId = victimId, FromBot = fromBot })
end

-- La calabaza más cercana a un punto (para los bots); nil si no hay
function Pumpkins.Nearest(position)
	local best, bestDistance = nil, math.huge
	for _, pumpkin in active do
		local distance = (pumpkin.Position - position).Magnitude
		if distance < bestDistance then
			best, bestDistance = pumpkin.Position, distance
		end
	end
	return best, bestDistance
end

function Pumpkins.Count()
	return #active
end

local function step()
	local now = os.clock()
	local collectors = Pumpkins.Collectors and Pumpkins.Collectors() or {}
	for i = #active, 1, -1 do
		local pumpkin = active[i]
		if now > pumpkin.Expires or not pumpkin.Model.Parent then
			pumpkin.Model:Destroy()
			table.remove(active, i)
		else
			for _, collector in collectors do
				local own = collector.Player and collector.Player.UserId == pumpkin.VictimId
				local revived = collector.Player and now - (collector.Player:GetAttribute("RevivedAt") or -math.huge) < 5
				if collector.Team and not own and not revived and (collector.Position - pumpkin.Position).Magnitude <= RADIUS then
					pumpkin.Model:Destroy()
					table.remove(active, i)
					if Pumpkins.OnCollect then
						task.spawn(Pumpkins.OnCollect, collector, collector.Team ~= pumpkin.Team, pumpkin.Team, pumpkin.FromBot)
					end
					break
				end
			end
		end
	end
end

function Pumpkins.Start()
	Pumpkins.Stop()
	tagsThisMatch = ReplicatedStorage:GetAttribute("EventName") ~= "Halloween"
	running = true
	generation += 1
	local mine = generation
	folder = Instance.new("Folder")
	folder.Name = "Pumpkins"
	folder.Parent = workspace
	task.spawn(function()
		while running and generation == mine do
			local ok, err = pcall(step)
			if not ok then
				warn("[Pumpkins] Error en el bucle:", err)
			end
			task.wait(0.1)
		end
	end)
end

function Pumpkins.Stop()
	tagsThisMatch = nil
	running = false
	for _, pumpkin in active do
		pumpkin.Model:Destroy()
	end
	table.clear(active)
	if folder then
		folder:Destroy()
		folder = nil
	end
end

return Pumpkins
