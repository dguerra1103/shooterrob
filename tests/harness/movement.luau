-- Movimiento realista: aceleración, estamina, solo correr hacia delante, cansancio y aterrizajes
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local V = roblox.Vector3.new
local Enum = roblox.Enum
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local Movement = req(game.StarterPlayer.Client.Modules.Movement)
ClientState.InMainMenu = false
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Name = "Humanoid"; hum.Health = 100; hum.MaxHealth = 100; hum.HipHeight = 2; hum.Parent = char
hum.JumpHeight = 7.2; hum.JumpPower = 50
hum.FloorMaterial = Enum.Material.Plastic
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = char
root.AssemblyLinearVelocity = V(0, 0, 0)
me.Character = char
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
Movement.Init()
task.wait(0.1)
local cam = game.Workspace.CurrentCamera
cam.CFrame = roblox.CFrame.lookAt(V(0, 5, 0), V(0, 5, -10)) -- mira hacia -Z
local lv = game.Workspace.CurrentCamera.CFrame.LookVector
local FWD = V(lv.X, 0, lv.Z).Unit
local RunService = game:GetService("RunService")
local function step(seconds)
	local n = math.floor(seconds / (1 / 30))
	for _ = 1, n do RunService.Heartbeat:Fire(1 / 30) end
end
-- Arranca a andar hacia delante: acelera
hum.MoveDirection = FWD
step(1 / 30)
local first = hum.WalkSpeed
step(1)
print("velocidad al arrancar / al rato:", first, hum.WalkSpeed)
check(first < GameConfig.WalkSpeed and math.abs(hum.WalkSpeed - GameConfig.WalkSpeed) < 0.01, "acelera hasta andar")
-- Correr hacia delante
mock.actions.Sprint("Sprint", Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.Keyboard })
step(1)
print("dbg", ClientState.Sprinting, hum.WalkSpeed, ClientState.IsBlocked(), ClientState.Exhausted, cam.CFrame.LookVector)
check(ClientState.Sprinting and math.abs(hum.WalkSpeed - GameConfig.SprintSpeed) < 0.01, "corre hacia delante")
check(ClientState.Stamina < 0.9, "correr gasta estamina (" .. string.format("%.2f", ClientState.Stamina) .. ")")
-- De lado no se corre
hum.MoveDirection = V(FWD.Z, 0, -FWD.X)
step(0.2)
check(not ClientState.Sprinting, "de lado no se corre")
-- Hasta agotarse
hum.MoveDirection = FWD
step(GameConfig.Movement.StaminaSeconds + 0.5)
check(ClientState.Exhausted and not ClientState.Sprinting, "se agota y deja de correr")
step(0.1)
check(hum.JumpHeight < 7.2, "cansado salta menos")
-- Soltar y recuperarse
mock.actions.Sprint("Sprint", Enum.UserInputState.End, { UserInputType = Enum.UserInputType.Keyboard })
task.wait(GameConfig.Movement.RegenDelay + 0.1) -- (la espera usa el reloj de verdad)
step(GameConfig.Movement.RegenSeconds * GameConfig.Movement.MinToSprint + 0.3)
check(not ClientState.Exhausted, "se recupera")
-- Aterrizaje fuerte
hum.FloorMaterial = Enum.Material.Air
root.AssemblyLinearVelocity = V(0, -80, 0)
step(0.1)
hum.FloorMaterial = Enum.Material.Plastic
root.AssemblyLinearVelocity = V(0, 0, 0)
hum.StateChanged:Fire(Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Landed)
check(ClientState.LandKick > 0.5, "golpe de cámara al aterrizar desde alto")
step(0.1)
check(hum.WalkSpeed < GameConfig.WalkSpeed, "frena un momento tras una caída fuerte")
-- Agacharse (C andando): más bajo y más lento; correr te levanta
task.wait(0.6)
step(1)
mock.actions.Slide("Slide", Enum.UserInputState.Begin, {})
step(0.5)
check(ClientState.Crouching, "C andando: se agacha (no se desliza)")
check(not ClientState.Sliding, "no se desliza andando")
check(hum.HipHeight < 1, "agachado: el cuerpo baja (" .. string.format("%.2f", hum.HipHeight) .. ")")
step(1)
check(math.abs(hum.WalkSpeed - GameConfig.CrouchSpeed) < 0.5, "agachado anda más despacio (" .. string.format("%.1f", hum.WalkSpeed) .. ")")
mock.actions.Slide("Slide", Enum.UserInputState.Begin, {})
step(0.5)
check(not ClientState.Crouching and hum.HipHeight > 1.9, "C otra vez: se levanta")
mock.actions.Slide("Slide", Enum.UserInputState.Begin, {})
step(0.2)
mock.actions.Sprint("Sprint", Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.Keyboard })
step(0.2)
check(not ClientState.Crouching, "correr te levanta")
step(1)
mock.actions.Slide("Slide", Enum.UserInputState.Begin, {})
check(ClientState.Sliding and not ClientState.Crouching, "C corriendo: se desliza")
-- Ventaja "Ligero": anda un 8 % más rápido
task.wait(1.2)
mock.actions.Sprint("Sprint", Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.Keyboard })
mock.actions.Sprint("Sprint", Enum.UserInputState.End, { UserInputType = Enum.UserInputType.Keyboard })
ClientState.Sprinting = false
me:SetAttribute("Perk", 1)
step(2)
print("  andando con Ligero:", hum.WalkSpeed, ClientState.Sprinting)
check(math.abs(hum.WalkSpeed - (ClientState.Sprinting and GameConfig.SprintSpeed or GameConfig.WalkSpeed) * 1.08) < 0.05, "Ligero: un 8 % más rápido")
print("MOVIMIENTO OK")
process.exit(0)
