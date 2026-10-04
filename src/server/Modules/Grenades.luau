-- Granadas: el servidor crea la granada con física, la deja rebotar y la hace explotar.
-- Cada jugador tiene una, que se recarga sola (atributo GrenadeReadyAt = hora del servidor).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local Combat = require(script.Parent.Combat)

local Grenades = {}

local DEF = Weapons.Grenade

local folder

local function now()
	return workspace:GetServerTimeNow()
end

local function makeGrenade(cf)
	local ball = Instance.new("Part")
	ball.Name = "Grenade"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.9, 0.9, 0.9)
	ball.Color = Color3.fromRGB(60, 70, 50)
	ball.Material = Enum.Material.Metal
	ball.CFrame = cf
	ball.CanCollide = true
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CustomPhysicalProperties = PhysicalProperties.new(2, 0.7, 0.35, 1, 1)
	local band = Instance.new("Part")
	band.Name = "Band"
	band.Shape = Enum.PartType.Cylinder
	band.Size = Vector3.new(0.2, 0.95, 0.95)
	band.Color = Color3.fromRGB(255, 50, 40)
	band.Material = Enum.Material.Neon
	band.CanCollide = false
	band.CanQuery = false
	band.CanTouch = false
	band.Massless = true
	band.CFrame = cf
	band.Parent = ball
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ball
	weld.Part1 = band
	weld.Parent = band
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 60, 40)
	light.Range = 8
	light.Brightness = 2
	light.Parent = band
	return ball, light
end

local function throw(player, direction)
	if typeof(direction) ~= "Vector3" then
		return
	end
	local length = direction.Magnitude
	if not (length >= 0.5 and length <= 1.5) then -- también descarta NaN
		return
	end
	if player:GetAttribute("InMenu") or ReplicatedStorage:GetAttribute("Mode") == "GUN" or ReplicatedStorage:GetAttribute("Frozen") then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not head then
		return
	end
	if now() < (player:GetAttribute("GrenadeReadyAt") or 0) then
		return
	end
	player:SetAttribute("GrenadeReadyAt", now() + DEF.Cooldown)
	-- Lanzar quita la protección de aparición, como disparar
	for _, child in character:GetChildren() do
		if child:IsA("ForceField") then
			child:Destroy()
		end
	end

	direction = direction.Unit
	-- Nunca aparece al otro lado de una pared: si hay algo delante, se queda de este lado
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, folder }
	local hit = workspace:Raycast(head.Position, direction * 2.5, params)
	local start = hit and (hit.Position - direction * 0.6) or (head.Position + direction * 2)
	local grenade, light = makeGrenade(CFrame.new(start))
	-- No choca con quien la lanza (si mira hacia abajo no sale rebotada de su cuerpo)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			local noCollide = Instance.new("NoCollisionConstraint")
			noCollide.Part0 = grenade
			noCollide.Part1 = part
			noCollide.Parent = grenade
		end
	end
	grenade.Parent = folder
	grenade:SetNetworkOwner(nil)
	grenade.AssemblyLinearVelocity = direction * DEF.ThrowSpeed + Vector3.new(0, 14, 0)
	grenade.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20

	task.spawn(function()
		-- Parpadeo cada vez más rápido
		local fuseEnd = os.clock() + DEF.Fuse
		while os.clock() < fuseEnd and grenade.Parent do
			light.Enabled = not light.Enabled
			task.wait(math.max(0.06, (fuseEnd - os.clock()) * 0.15))
		end
		if not grenade.Parent then
			return
		end
		local position = grenade.Position + Vector3.new(0, 0.6, 0)
		grenade:Destroy()
		Remotes.ExplosionFX:FireAllClients(position, DEF.Explosive.Radius)
		if player.Parent then
			Combat.Explode(player, position, DEF, "Grenade")
		end
	end)
end

function Grenades.Init()
	folder = Instance.new("Folder")
	folder.Name = "Grenades"
	folder.Parent = workspace
	Remotes.ThrowGrenade.OnServerEvent:Connect(throw)
end

-- Al empezar una ronda todos tienen la granada lista (reaparecer no la recarga: evita abusar)
function Grenades.Reset()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("GrenadeReadyAt", 0)
	end
end

return Grenades
