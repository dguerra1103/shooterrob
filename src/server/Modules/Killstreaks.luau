-- Recompensas por racha de bajas (sin morir):
--   3 bajas: RADAR. Durante unos segundos tu equipo (o tú, en Todos contra todos) ve a los
--            enemigos a través de las paredes. Atributo de jugador RadarUntil = hora del servidor.
--            Los bots también lo consiguen (BotRadar): sus compañeros humanos lo ven y los rivales
--            reciben el aviso, como el radar enemigo de los shooters de móvil.
--   5 bajas: ATAQUE AÉREO. Se guarda (atributo Airstrikes) y se lanza con la tecla T: marca el
--            punto al que apuntas y caen 5 explosiones en línea.
-- No hay recompensas en Escalada de armas.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weapons = require(Shared.Weapons)
local Remotes = require(Shared.Remotes)

local Combat = require(script.Parent.Combat)

local Killstreaks = {}

Killstreaks.RadarStreak = 3
Killstreaks.AirstrikeStreak = 5
local RADAR_TIME = 12
Killstreaks.RadarTime = RADAR_TIME
local MAX_RANGE = 600
local STRIKE_DELAY = 1.6 -- segundos de aviso antes de que caigan las bombas
local STRIKES = 5
local SPACING = 9

local function now()
	return workspace:GetServerTimeNow()
end

local function enabled()
	return ReplicatedStorage:GetAttribute("Mode") ~= "GUN"
end

local function activateRadar(player)
	local untilTime = now() + RADAR_TIME
	for _, other in Players:GetPlayers() do
		local ally = other == player or (player.Team ~= nil and other.Team == player.Team and ReplicatedStorage:GetAttribute("TeamMode") ~= false)
		if other == player then
			other:SetAttribute("RadarUntil", untilTime)
			Remotes.Notify:FireClient(other, "Big", "📡 ¡RADAR ACTIVADO!")
		elseif ally then
			other:SetAttribute("RadarUntil", untilTime)
			Remotes.Notify:FireClient(other, "Info", "📡 Radar activado por " .. player.Name)
		else
			Remotes.Notify:FireClient(other, "Info", "📡 ¡El enemigo tiene radar!")
		end
	end
end

-- Un bot llega a la racha del radar: lo comparten los jugadores de su equipo y se avisa al rival
-- (los bots de su equipo lo reciben en Bots.Radar, que llama Round)
function Killstreaks.OnBotStreak(botName, team, streak)
	if not enabled() or streak ~= Killstreaks.RadarStreak then
		return false
	end
	local untilTime = now() + RADAR_TIME
	local teamMode = ReplicatedStorage:GetAttribute("TeamMode") ~= false
	for _, other in Players:GetPlayers() do
		if team ~= nil and teamMode and other.Team == team then
			other:SetAttribute("RadarUntil", math.max(other:GetAttribute("RadarUntil") or 0, untilTime))
			Remotes.Notify:FireClient(other, "Info", "📡 Radar activado por " .. botName)
		else
			Remotes.Notify:FireClient(other, "Info", "📡 ¡El enemigo tiene radar!")
		end
	end
	return true
end

-- Lo llama Round cada vez que alguien suma una baja a su racha
function Killstreaks.OnStreak(player, streak)
	-- (los zombis de la Infección no tienen recompensas por racha)
	if not enabled() or (player.Character and player.Character:GetAttribute("Zombie")) then
		return
	end
	if streak == Killstreaks.RadarStreak then
		activateRadar(player)
	elseif streak == Killstreaks.AirstrikeStreak then
		player:SetAttribute("Airstrikes", (player:GetAttribute("Airstrikes") or 0) + 1)
		Remotes.Notify:FireClient(player, "Big", "✈ ¡ATAQUE AÉREO LISTO! Pulsa T")
	end
end

-- Al empezar una ronda nadie conserva recompensas
function Killstreaks.Reset()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Airstrikes", 0)
		player:SetAttribute("RadarUntil", 0)
	end
end

-- Punto del suelo bajo una posición (ignorando personajes, granadas y muros invisibles)
local function ground(position)
	local ignore = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	for _, name in { "Dummies", "Bots", "Grenades", "ClientFX" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(ignore, f)
		end
	end
	local map = workspace:FindFirstChild("Map")
	local boundary = map and map:FindFirstChild("Boundary")
	if boundary then
		table.insert(ignore, boundary)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	-- Desde una altura fija: las bombas siempre caen sobre el primer techo (no dentro de edificios)
	local result = workspace:Raycast(Vector3.new(position.X, 200, position.Z), Vector3.new(0, -260, 0), params)
	return result and result.Position + Vector3.new(0, 1, 0) or position
end

local function callAirstrike(player, target)
	if typeof(target) ~= "Vector3" or target ~= target then
		return
	end
	if not enabled() or player:GetAttribute("InMenu") or (player:GetAttribute("Airstrikes") or 0) <= 0 then
		return
	end
	if player.Character and player.Character:GetAttribute("Zombie") then
		return
	end
	if ReplicatedStorage:GetAttribute("State") ~= "Playing" or ReplicatedStorage:GetAttribute("Frozen") then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	local offset = target - root.Position
	if offset.Magnitude > MAX_RANGE or offset.Y < -100 or offset.Y > 150 then
		return
	end
	player:SetAttribute("Airstrikes", player:GetAttribute("Airstrikes") - 1)

	-- 5 puntos en línea, en la dirección en la que mira el jugador
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local direction = flat.Magnitude > 1 and flat.Unit or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	local points = {}
	for i = 1, STRIKES do
		local along = (i - (STRIKES + 1) / 2) * SPACING
		table.insert(points, ground(target + direction * along))
	end
	Remotes.AirstrikeMark:FireAllClients(points, STRIKE_DELAY)
	Remotes.Notify:FireAllClients("Streak", "✈ ¡ATAQUE AÉREO de " .. player.Name .. "!")

	task.delay(STRIKE_DELAY, function()
		for _, point in points do
			if ReplicatedStorage:GetAttribute("State") ~= "Playing" then
				return -- la ronda terminó durante el aviso
			end
			Remotes.ExplosionFX:FireAllClients(point, Weapons.Airstrike.Explosive.Radius)
			if player.Parent then
				Combat.Explode(player, point, Weapons.Airstrike, "Airstrike")
			end
			task.wait(0.18)
		end
	end)
end

function Killstreaks.Init()
	Remotes.CallAirstrike.OnServerEvent:Connect(callAirstrike)
end

return Killstreaks
