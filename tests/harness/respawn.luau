-- Prueba de la reaparición propia: reaparición automática, "Regenerar ahora" y "Revivir instantáneo"
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.RespawnTime = 0.4
GameConfig.RespawnNowDelay = 0.1
GameConfig.ReviveShieldTime = 0.1
local Remotes = req(Shared.Remotes)
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Respawn = req(M.Respawn)
local Players = game:GetService("Players")

local function check(cond, msg)
	if not cond then
		error("FALLO: " .. msg, 2)
	end
	print("ok  " .. msg)
end

local loads = 0
local failNext = 0 -- cuántas cargas fallan antes de funcionar
local revived = {}
local deathSpot = Vector3.new(0, 3, 0)
mock.onLoadCharacter = function(p)
	if failNext > 0 then
		failNext -= 1
		error("fallo de red simulado")
	end
	loads += 1
	local char = mock.new("Model")
	char.Name = p.Name
	local hum = mock.new("Humanoid")
	hum.Health = 100
	hum.Parent = char
	local root = mock.new("Part")
	root.Name = "HumanoidRootPart"
	root.Position = Vector3.new(0, 3, 0)
	root.Parent = char
	char.Parent = game.Workspace
	p.Character = char
	p.CharacterAdded:Fire(char)
end

-- Suelo en y = 0 (y lava en x > 200)
local groundPart = mock.new("Part")
local lavaPart = mock.new("Part")
lavaPart:SetAttribute("Hazard", "Lava")
mock.raycastImpl = function(origin, direction)
	local target = origin + direction
	if origin.Y >= 0 and target.Y <= 0 then
		return { Position = Vector3.new(origin.X, 0, origin.Z), Instance = origin.X > 200 and lavaPart or groundPart, Material = roblox.Enum.Material.Plastic, Normal = Vector3.new(0, 1, 0) }
	end
	return nil
end
Respawn.Init()
local p = mock.new("Player")
p.Name = "P1"
p.UserId = 1
p.Parent = Players
table.insert(mock.players, p)
-- Como Round: al aparecer, intenta colocar el revivir
p.CharacterAdded:Connect(function(char)
	task.spawn(function()
		if Respawn.ApplyRevive(p, char) then
			table.insert(revived, char)
		end
	end)
end)
Players.PlayerAdded:Fire(p)
task.wait(0.1)
check(loads == 1, "primera aparición al entrar (sin CharacterAutoLoads)")

local function kill(position)
	local char = p.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	char.HumanoidRootPart.Position = position or deathSpot
	hum.Health = 0
	hum.Died:Fire()
	return char
end

-- Reaparición automática
kill()
task.wait(0.2)
check(loads == 1, "no reaparece antes de tiempo")
task.wait(0.35)
check(loads == 2, "reaparece solo tras RespawnTime")

-- Regenerar ahora
kill()
Remotes.RespawnNow.OnServerEvent:Fire(p)
check(loads == 2, "regenerar ahora no funciona antes del retardo mínimo")
task.wait(0.15)
Remotes.RespawnNow.OnServerEvent:Fire(p)
check(loads == 3, "regenerar ahora reaparece al instante")
task.wait(0.4)
check(loads == 3, "sin reaparición doble después de regenerar")
Remotes.RespawnNow.OnServerEvent:Fire(p)
check(loads == 3, "regenerar ahora estando vivo no hace nada")

-- Revivir instantáneo
local data = PlayerData.WaitFor(p, 2)
check(data and data.Revives == GameConfig.StartingRevives, "jugador nuevo con revivir de regalo")
game.ReplicatedStorage:SetAttribute("State", "Playing")
local ok, reason = Remotes.InstantRevive.OnServerInvoke(p)
check(ok == false and reason ~= nil, "revivir estando vivo: rechazado")
kill(Vector3.new(50, 3, 20))
ok = Remotes.InstantRevive.OnServerInvoke(p)
task.wait(0.05)
check(ok == true and loads == 4, "revivir instantáneo reaparece")
check(data.Revives == GameConfig.StartingRevives - 1, "gasta un revivir")
check(#revived == 1, "aparece en el punto donde murió")
local root = p.Character.HumanoidRootPart
check((root.Position - Vector3.new(50, 3, 20)).Magnitude < 0.1, "posición del revivir correcta (sobre el suelo)")
check(p.Character:FindFirstChildOfClass("ForceField") ~= nil, "escudo breve al revivir")
task.wait(0.5)
check(loads == 4, "sin reaparición extra tras revivir")

kill()
task.wait(0.5)
ok, reason = Remotes.InstantRevive.OnServerInvoke(p)
check(ok == false, "revivir demasiado tarde: rechazado")

-- En el aire sobre un hueco y en la lava: no se gasta
task.wait(0.5)
local before = data.Revives
kill(Vector3.new(10, 40, 0))
ok, reason = Remotes.InstantRevive.OnServerInvoke(p)
check(ok == false and data.Revives == before, "en el aire (sin suelo cerca): rechazado")
task.wait(0.5)
kill(Vector3.new(250, 3, 0))
ok, reason = Remotes.InstantRevive.OnServerInvoke(p)
check(ok == false and data.Revives == before, "sobre lava: rechazado")
task.wait(0.5)

data.Revives = 0
kill()
ok, reason = Remotes.InstantRevive.OnServerInvoke(p)
check(ok == false and reason == "Sin revivir", "sin revivir: rechazado")
data.Revives = 2
game.ReplicatedStorage:SetAttribute("State", "Intermission")
ok = Remotes.InstantRevive.OnServerInvoke(p)
check(ok == false and data.Revives == 2, "fuera de la ronda no se gasta")
game.ReplicatedStorage:SetAttribute("State", "Playing")
kill(Vector3.new(0, -50, 0))
task.wait(0.5)
kill(Vector3.new(0, -50, 0))
ok = Remotes.InstantRevive.OnServerInvoke(p)
check(ok == false and data.Revives == 2, "no se revive en el vacío")

-- Si LoadCharacter falla tras morir, se reintenta y "Regenerar ahora" sigue funcionando
task.wait(0.5)
local loadsBefore = loads
failNext = 1
kill()
task.wait(0.5) -- la reaparición automática falla aquí
check(loads == loadsBefore and p.Character.Humanoid.Health == 0, "carga fallida: sigue muerto de momento")
Remotes.RespawnNow.OnServerEvent:Fire(p)
check(loads == loadsBefore + 1, "regenerar ahora funciona tras una carga fallida")
failNext = 1
kill()
task.wait(0.5)
task.wait(1.2) -- reintento a los 1 s
check(loads == loadsBefore + 2, "reintento automático tras una carga fallida")
print("TODO OK")
process.exit(0)
