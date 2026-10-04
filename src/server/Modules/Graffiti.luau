-- Grafitis (Sprays): el cliente dice dónde quiere pintar y el servidor lo comprueba (que esté vivo y
-- jugando, que el punto esté a su alcance y a la vista, recarga) y pinta el grafiti equipado. Uno por
-- jugador: el nuevo borra el anterior. Van dentro del mapa, así que se borran al cambiar de mapa.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Sprays = require(Shared.Sprays)

local PlayerData = require(script.Parent.PlayerData)

local Graffiti = {}

local lastSpray = {}
local current = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function finite(v)
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e5 and math.abs(v.Y) < 1e5 and math.abs(v.Z) < 1e5
end

-- Personajes (jugadores y bots) para que el rayo no pinte encima de nadie
local function characters()
	local list = {}
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(list, other.Character)
		end
	end
	for _, model in workspace:GetChildren() do
		if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
			table.insert(list, model)
		end
	end
	return list
end

function Graffiti.Paint(player, position)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and head and root) or humanoid.Health <= 0 or player:GetAttribute("InMenu") then
		return false
	end
	if not finite(position) then
		return false
	end
	local now = os.clock()
	if lastSpray[player] and now - lastSpray[player] < Sprays.Cooldown then
		return false
	end
	local offset = position - head.Position
	if offset.Magnitude > Sprays.Range + 3 or offset.Magnitude < 0.5 then
		return false
	end
	-- El servidor mira lo que hay de verdad en ese punto (y usa su superficie)
	rayParams.FilterDescendantsInstances = characters()
	local hit = workspace:Raycast(head.Position, offset.Unit * (offset.Magnitude + 1), rayParams)
	if not hit or (hit.Position - position).Magnitude > 2 or not hit.Instance.Anchored or hit.Instance.Transparency > 0.6 then
		return false
	end
	lastSpray[player] = now

	local normal = hit.Normal
	local up = math.abs(normal.Y) > 0.9 and root.CFrame.LookVector or Vector3.yAxis
	local origin = hit.Position + normal * 0.04
	local part = Instance.new("Part")
	part.Name = "Spray_" .. player.UserId
	part.Size = Vector3.new(Sprays.Size, Sprays.Size, 0.05)
	part.CFrame = CFrame.lookAt(origin, origin + normal, up)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.6
	gui.MaxDistance = 200
	gui.Parent = part
	local data = PlayerData.Get(player)
	Sprays.Draw(data and data.EquippedSpray or "Default", gui)

	if current[player] then
		current[player]:Destroy()
	end
	current[player] = part
	part.Parent = workspace:FindFirstChild("Map") or workspace
	return true
end

function Graffiti.Init()
	Remotes.Spray.OnServerEvent:Connect(Graffiti.Paint)
	Players.PlayerRemoving:Connect(function(player)
		if current[player] then
			current[player]:Destroy()
		end
		current[player] = nil
		lastSpray[player] = nil
	end)
end

return Graffiti
