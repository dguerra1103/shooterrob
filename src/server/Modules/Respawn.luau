-- Reaparición controlada por el juego (Players.CharacterAutoLoads = false en default.project.json):
--   * Al morir se reaparece solo tras GameConfig.RespawnTime segundos
--   * "Regenerar ahora": a partir de GameConfig.RespawnNowDelay se puede reaparecer antes
--   * "Revivir instantáneo": gasta un revivir (data.Revives) y vuelve justo donde moriste
-- Round llama a Respawn.ApplyRevive al aparecer el personaje para colocarlo en ese punto.
-- En plena ronda de Eliminación (atributo NoRespawn) no hay reaparición: se espera a la siguiente ronda.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)

local Respawn = {}

local deaths = {} -- [player] = { Time = os.clock(), Position = Vector3?, Character = Model }
local revivePoints = {} -- [player] = Vector3 donde debe aparecer tras revivir
local loading = {} -- [player] = true mientras se carga un personaje (evita cargas dobles)

local function noRespawn()
	return ReplicatedStorage:GetAttribute("NoRespawn") == true
end

local function isDead(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character == nil or humanoid == nil or humanoid.Health <= 0
end

local function load(player)
	if loading[player] or not player.Parent then
		return
	end
	loading[player] = true
	local ok, err = pcall(player.LoadCharacter, player)
	loading[player] = nil
	if ok then
		deaths[player] = nil
	else
		-- Sin CharacterAutoLoads nadie más lo reintentaría: se queda muerto. Reintento en un segundo.
		-- (deaths se conserva para que "Regenerar ahora" siga funcionando mientras tanto)
		warn("[Respawn] No se pudo cargar el personaje:", err)
		revivePoints[player] = nil
		task.delay(1, function()
			if player.Parent and isDead(player) then
				load(player)
			end
		end)
	end
end
Respawn.Load = load

-- ¿Se está cargando su personaje ahora mismo? (Eliminación lo cuenta como vivo)
function Respawn.IsLoading(player)
	return loading[player] == true
end

local function watch(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		deaths[player] = { Time = os.clock(), Position = root and root.Position, Character = character }
		task.delay(GameConfig.RespawnTime, function()
			-- Solo si sigue con el mismo personaje muerto (no ha usado "Regenerar" ni "Revivir")
			if player.Parent and player.Character == character and not noRespawn() then
				load(player)
			end
		end)
	end)
end

-- Llamada por Round al aparecer: si el jugador acaba de revivir, lo pone donde murió.
-- Devuelve true si lo ha colocado (y entonces no se usa el punto de aparición normal).
function Respawn.ApplyRevive(player, character)
	local point = revivePoints[player]
	if not point then
		return false
	end
	revivePoints[player] = nil
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return false
	end
	task.wait()
	character:PivotTo(CFrame.new(point + Vector3.new(0, 3, 0)) * (root.CFrame - root.Position))
	-- Protección breve al revivir (se pierde al disparar, como la de reaparición)
	local shield = Instance.new("ForceField")
	shield.Name = "SpawnShield"
	shield.Visible = true
	shield.Parent = character
	task.delay(GameConfig.ReviveShieldTime, function()
		if shield.Parent then
			shield:Destroy()
		end
	end)
	return true
end

-- Comprueba si se puede revivir ahora mismo; devuelve el punto o nil y el motivo
local function reviveCheck(player)
	local death = deaths[player]
	if not death or not isDead(player) then
		return nil, "Solo al morir"
	end
	if os.clock() - death.Time > GameConfig.RespawnTime + 0.5 then
		return nil, "Demasiado tarde"
	end
	if ReplicatedStorage:GetAttribute("State") ~= "Playing" then
		return nil, "La ronda no está en juego"
	end
	if noRespawn() then
		return nil, "Una sola vida por ronda"
	end
	-- Infección: un superviviente que cae ya es zombi (no vuelve como humano)
	if ReplicatedStorage:GetAttribute("Infection") == "On" and player.Team and player.Team.Name == ReplicatedStorage:GetAttribute("TeamA") then
		return nil, "¡Te han infectado!"
	end
	if ReplicatedStorage:GetAttribute("Frozen") or loading[player] then
		return nil, "Ya estás reapareciendo"
	end
	local point = death.Position
	if not point or point.Y < -20 then
		return nil, "No se puede revivir aquí"
	end
	-- Tiene que haber suelo debajo (no en el aire sobre un hueco) y no puede ser lava
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(point + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), params)
	if not hit then
		return nil, "No hay suelo aquí"
	end
	if hit.Instance:GetAttribute("Hazard") or hit.Material == Enum.Material.CrackedLava then
		return nil, "No se puede revivir en la lava"
	end
	return hit.Position
end

function Respawn.Init()
	Players.CharacterAutoLoads = false -- también en default.project.json; aquí por si se usa otro lugar
	Remotes.RespawnNow.OnServerEvent:Connect(function(player)
		local death = deaths[player]
		if death and isDead(player) and os.clock() - death.Time >= GameConfig.RespawnNowDelay and not noRespawn() then
			load(player)
		end
	end)

	Remotes.InstantRevive.OnServerInvoke = function(player)
		local point, reason = reviveCheck(player)
		if not point then
			return false, reason
		end
		if not PlayerData.UseRevive(player) then
			return false, "Sin revivir"
		end
		revivePoints[player] = point
		-- (al revivir no se puede coger enseguida la bandera ni las calabazas de donde caíste)
		player:SetAttribute("RevivedAt", os.clock())
		task.spawn(load, player)
		return true
	end

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(watch, player, character)
		end)
		if player.Character then
			task.spawn(watch, player, player.Character)
		else
			-- Primera aparición (CharacterAutoLoads está desactivado)
			task.defer(load, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		deaths[player] = nil
		revivePoints[player] = nil
		loading[player] = nil
	end)
end

return Respawn
