-- Asistencia de apuntado: con dedo o mando la mira se va hacia el enemigo cercano y visible
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage
local Teams = game:GetService("Teams")
local red = mock.new("Team"); red.Name = "Rojo"; red.Parent = Teams
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players; me.Team = red
Players.LocalPlayer = me
RS:SetAttribute("TeamMode", true)
local UIS = game:GetService("UserInputService")
UIS.TouchEnabled = true
UIS.KeyboardEnabled = false
local camera = game.Workspace.CurrentCamera
camera.CFrame = CFrame.new(0, 5, 0) -- mira hacia -Z
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
ClientState.CurrentDef = { Type = "Gun", Range = 300 }
ClientState.AimAlpha = 0
local AimAssist = req(game.StarterPlayer.Client.Modules.AimAssist)
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local function bot(name, team, pos)
	local m = mock.new("Model"); m.Name = name; m:SetAttribute("Bot", true); m:SetAttribute("Team", team)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	local t = mock.new("Part"); t.Name = "UpperTorso"; t.Position = pos; t.CFrame = CFrame.new(pos); t.Parent = m
	m.Parent = bots
	return m
end
-- Enemigo 3° a la derecha, a 50 studs
local angle = math.rad(3)
local enemy = bot("Bot Max", "Azul", Vector3.new(math.sin(angle) * 50, 5, -math.cos(angle) * 50))
local function lookAngleTo(pos)
	local dir = (pos - camera.CFrame.Position).Unit
	return math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(dir), -1, 1)))
end
local before = lookAngleTo(enemy.UpperTorso.Position)
for _ = 1, 30 do AimAssist.Update(1 / 60) end
local after = lookAngleTo(enemy.UpperTorso.Position)
check(after < before - 0.3, string.format("la mira se va hacia el enemigo (%.2f° → %.2f°)", before, after))
-- Un compañero no atrae
camera.CFrame = CFrame.new(0, 5, 0)
enemy.Parent = nil
local mate = bot("Bot Leo", "Rojo", Vector3.new(math.sin(angle) * 50, 5, -math.cos(angle) * 50))
local mateBefore = lookAngleTo(mate.UpperTorso.Position)
for _ = 1, 30 do AimAssist.Update(1 / 60) end
check(math.abs(lookAngleTo(mate.UpperTorso.Position) - mateBefore) < 0.01, "un compañero no atrae la mira")
mate.Parent = nil
-- Lejos del cono (20°) no hace nada
camera.CFrame = CFrame.new(0, 5, 0)
local far = bot("Bot Lejos", "Azul", Vector3.new(math.sin(math.rad(20)) * 50, 5, -math.cos(math.rad(20)) * 50))
local farBefore = lookAngleTo(far.UpperTorso.Position)
for _ = 1, 30 do AimAssist.Update(1 / 60) end
check(math.abs(lookAngleTo(far.UpperTorso.Position) - farBefore) < 0.01, "un enemigo lejos de la mira no la mueve")
far.Parent = nil
-- (CFrame.lookAt de lune mira al revés: se construye a mano)
local function lookAt(from, to)
	local d = to - from
	local yaw = math.atan2(-d.X, -d.Z)
	local pitch = math.atan2(d.Y, math.sqrt(d.X * d.X + d.Z * d.Z))
	return CFrame.new(from) * CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
end
-- Apuntando a la cabeza: no la baja al pecho
local headBot = bot("Bot Cabeza", "Azul", Vector3.new(0, 5, -40))
local head = mock.new("Part"); head.Name = "Head"; head.Position = Vector3.new(0, 6.6, -40); head.CFrame = CFrame.new(head.Position); head.Parent = headBot
camera.CFrame = lookAt(Vector3.new(0, 5, 0), head.Position)
ClientState.AimAlpha = 1
for _ = 1, 60 do AimAssist.Update(1 / 60) end
check(lookAngleTo(head.Position) < 0.2, string.format("apuntando a la cabeza, se queda en la cabeza (%.2f°)", lookAngleTo(head.Position)))
-- Un poco por encima de la cabeza: baja hasta la cabeza, no al pecho
camera.CFrame = lookAt(Vector3.new(0, 5, 0), head.Position + Vector3.new(0, 2, 0))
for _ = 1, 120 do AimAssist.Update(1 / 60) end
check(lookAngleTo(head.Position) < lookAngleTo(headBot.UpperTorso.Position), "por encima, baja a la cabeza (lo más cercano)")
ClientState.AimAlpha = 0
headBot.Parent = nil
-- Bailando un emote o corriendo: nada
enemy.Parent = bots
camera.CFrame = CFrame.new(0, 5, 0)
ClientState.Emoting = true
local emoteBefore = lookAngleTo(enemy.UpperTorso.Position)
for _ = 1, 30 do AimAssist.Update(1 / 60) end
check(math.abs(lookAngleTo(enemy.UpperTorso.Position) - emoteBefore) < 0.01, "bailando un emote, nada")
ClientState.Emoting = false
-- Devuelve lo que giró (para descontarlo de la recuperación del retroceso)
camera.CFrame = CFrame.new(0, 5, 0)
local _, pitch, yaw = AimAssist.Update(1 / 60)
check(type(pitch) == "number" and type(yaw) == "number" and yaw < 0, "devuelve el giro aplicado (" .. tostring(yaw) .. ")")
enemy.Parent = nil
-- Con ratón y teclado: nada
UIS.TouchEnabled = false
UIS.KeyboardEnabled = true
camera.CFrame = CFrame.new(0, 5, 0)
enemy.Parent = bots
local pcBefore = lookAngleTo(enemy.UpperTorso.Position)
for _ = 1, 30 do AimAssist.Update(1 / 60) end
check(math.abs(lookAngleTo(enemy.UpperTorso.Position) - pcBefore) < 0.01, "con ratón no hay asistencia")
-- Ajuste en "No"
UIS.TouchEnabled = true
UIS.KeyboardEnabled = false
ClientState.Settings = { AimAssist = 0 }
camera.CFrame = CFrame.new(0, 5, 0)
for _ = 1, 30 do AimAssist.Update(1 / 60) end
check(math.abs(lookAngleTo(enemy.UpperTorso.Position) - pcBefore) < 0.01, "con el ajuste en No, nada")
print("ASISTENCIA OK")
process.exit(0)
