-- Asistencia de apuntado (como en los shooters de móvil): con pantalla táctil o mando, si un enemigo
-- visible está cerca de la mira, la cámara se va hacia su pecho poco a poco (más al apuntar con la
-- mira) y, al empezar a apuntar con él cerca, da un pequeño "salto" hacia él. Nunca con ratón: ahí
-- apuntar es cosa de cada uno. Se puede bajar o quitar en Ajustes (Settings.AimAssist: 2 normal,
-- 1 suave, 0 no). WeaponController la llama cada fotograma justo después del retroceso.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientState = require(script.Parent.ClientState)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local AimAssist = {}

local player = Players.LocalPlayer

-- Cono de captura (grados) sin apuntar y apuntando, y cuánto del ángulo que falta se corrige por
-- segundo (fracción). El "salto" al empezar a apuntar corrige una parte en ~0,2 s.
AimAssist.HipCone = 5
AimAssist.AdsCone = 9
AimAssist.HipPull = 1.2
AimAssist.AdsPull = 3.2
AimAssist.SnapCone = 12
AimAssist.SnapPull = 9
AimAssist.SnapTime = 0.2

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local lastAds = 0
local snapUntil = 0

local GAMEPAD = {}
for i = 1, 8 do
	local ok, value = pcall(function()
		return (Enum.UserInputType :: any)["Gamepad" .. i]
	end)
	if ok and value then
		GAMEPAD[value] = true
	end
end

-- ¿Se está jugando con el dedo o con mando? (con ratón, nada)
function AimAssist.UsingAssistInput()
	local ok, last = pcall(function()
		return UserInputService:GetLastInputType()
	end)
	if ok and (last == Enum.UserInputType.Touch or GAMEPAD[last]) then
		return true
	end
	-- (móvil sin teclado aunque aún no haya tocado nada)
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function level()
	local settings = ClientState.Settings or GameConfig.DefaultSettings
	local value = settings.AimAssist
	if value == nil then
		value = 2
	end
	return math.floor(value + 0.5)
end

local function isEnemy(model)
	if model == player.Character then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	-- (con la protección de aparición no se le puede herir: no tira de la mira)
	if model:FindFirstChildOfClass("ForceField") then
		return false
	end
	local teamMode = ReplicatedStorage:GetAttribute("TeamMode") ~= false
	local owner = Players:GetPlayerFromCharacter(model)
	if owner then
		return not (teamMode and player.Team ~= nil and owner.Team == player.Team)
	end
	if model:GetAttribute("Bot") then
		return not (teamMode and player.Team ~= nil and model:GetAttribute("Team") == player.Team.Name)
	end
	return false
end

local function candidates()
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Character then
			table.insert(list, other.Character)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			if model:IsA("Model") then
				table.insert(list, model)
			end
		end
	end
	return list
end

-- Mejor objetivo dentro del cono: { Model, Point, Angle } o nil
function AimAssist.FindTarget(camera, coneDegrees, range)
	local cf = camera.CFrame
	local origin = cf.Position
	local look = cf.LookVector
	local cone = math.rad(coneDegrees)
	local best
	for _, model in candidates() do
		if isEnemy(model) then
			local part = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
			if part and part:IsA("BasePart") then
				local offset = part.Position - origin
				local distance = offset.Magnitude
				if distance > 1 and distance <= range then
					local angle = math.acos(math.clamp(look:Dot(offset / distance), -1, 1))
					if angle < cone and (not best or angle < best.Angle) then
						-- (que se vea: nada de imanes a través de las paredes)
						local ignore = { camera }
						if player.Character then
							table.insert(ignore, player.Character)
						end
						params.FilterDescendantsInstances = ignore
						local hit = workspace:Raycast(origin, offset, params)
						if not hit or hit.Instance:IsDescendantOf(model) then
							best = { Model = model, Point = part.Position, Angle = angle }
						end
					end
				end
			end
		end
	end
	return best
end

-- Gira la cámara una fracción hacia el punto (en su propio espacio: arriba/abajo e izquierda/derecha)
local function turnToward(camera, point, fraction)
	local direction = (point - camera.CFrame.Position).Unit
	local localDir = camera.CFrame:VectorToObjectSpace(direction)
	local yaw = math.atan2(-localDir.X, -localDir.Z)
	local pitch = math.atan2(localDir.Y, math.sqrt(localDir.X * localDir.X + localDir.Z * localDir.Z))
	camera.CFrame = camera.CFrame * CFrame.Angles(pitch * fraction, yaw * fraction, 0)
end

function AimAssist.Update(dt)
	local camera = workspace.CurrentCamera
	local def = ClientState.CurrentDef
	local strength = level()
	local ads = ClientState.AimAlpha or 0
	local startedAiming = ads > 0.1 and lastAds <= 0.1
	lastAds = ads
	if not camera or strength <= 0 or not def or def.Type ~= "Gun" or ClientState.Dead or ClientState.IsBlocked() then
		return nil
	end
	if not AimAssist.UsingAssistInput() then
		return nil
	end
	local scale = strength == 1 and 0.5 or 1
	local range = def.Range or 300
	if startedAiming then
		snapUntil = os.clock() + AimAssist.SnapTime
	end
	local snapping = os.clock() < snapUntil
	local cone = snapping and AimAssist.SnapCone or (AimAssist.HipCone + (AimAssist.AdsCone - AimAssist.HipCone) * ads)
	local target = AimAssist.FindTarget(camera, cone, range)
	if not target then
		return nil
	end
	local pull = snapping and AimAssist.SnapPull or (AimAssist.HipPull + (AimAssist.AdsPull - AimAssist.HipPull) * ads)
	-- (más fuerte cuanto más cerca de la mira; en el borde del cono casi nada)
	local closeness = 1 - target.Angle / math.rad(cone)
	local fraction = math.clamp(pull * scale * closeness * dt, 0, 0.5)
	turnToward(camera, target.Point, fraction)
	return target
end

return AimAssist
