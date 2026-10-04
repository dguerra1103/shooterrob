-- Peligros del mapa: pisar lava quita vida cada cuarto de segundo.
-- Se detecta de dos formas, por si una falla en el servidor: el material del suelo (CrackedLava)
-- y un rayo hacia abajo contra las piezas marcadas con el atributo Hazard = "Lava".
local Players = game:GetService("Players")

local Hazards = {}

local LAVA_DAMAGE = 10 -- por cada 0.25 s
local RAY_LENGTH = 4.5 -- desde el centro del personaje hasta un poco por debajo de los pies

local cachedMap, lavaParts = nil, {}
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include

local function refreshLava()
	local map = workspace:FindFirstChild("Map")
	if map == cachedMap then
		return
	end
	cachedMap = map
	lavaParts = {}
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Hazard") == "Lava" then
				table.insert(lavaParts, d)
			end
		end
	end
	params.FilterDescendantsInstances = lavaParts
end

local function onLava(humanoid, root)
	if humanoid.FloorMaterial == Enum.Material.CrackedLava then
		return true
	end
	if #lavaParts == 0 then
		return false
	end
	return workspace:Raycast(root.Position, Vector3.new(0, -RAY_LENGTH, 0), params) ~= nil
end

function Hazards.Init()
	task.spawn(function()
		while true do
			task.wait(0.25)
			refreshLava()
			-- Jugadores y bots
			local characters = {}
			for _, player in Players:GetPlayers() do
				if player.Character then
					table.insert(characters, player.Character)
				end
			end
			local bots = workspace:FindFirstChild("Bots")
			if bots then
				for _, model in bots:GetChildren() do
					table.insert(characters, model)
				end
			end
			for _, character in characters do
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart")
				if humanoid and root and humanoid.Health > 0 and onLava(humanoid, root) then
					-- La lava no es una baja de nadie
					humanoid:SetAttribute("LastAttacker", nil)
					humanoid:SetAttribute("LastBot", nil)
					humanoid:SetAttribute("LastWeapon", nil)
					humanoid:SetAttribute("LastHitTime", os.clock()) -- (la vida no se recupera dentro)
					humanoid:TakeDamage(LAVA_DAMAGE)
				end
			end
		end
	end)
end

return Hazards
