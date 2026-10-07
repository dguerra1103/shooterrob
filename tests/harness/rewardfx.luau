-- Efectos de recompensa: destello de baja, contador de puntos y celebración
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local RewardFX = req(game.StarterPlayer.Client.Modules.RewardFX)
-- Antes de arrancar no rompe nada
RewardFX.EdgeFlash(nil, 0.5); RewardFX.AddScore(10); check(RewardFX.Celebrate("x") == nil, "sin arrancar no hace nada (y no falla)")
RewardFX.Init()
local gui = pg:FindFirstChild("RewardFX")
check(gui ~= nil and gui.ResetOnSpawn == false, "pantalla propia que no se borra al reaparecer")
local edges = 0
for _, c in gui:GetChildren() do if string.sub(c.Name, 1, 4) == "Edge" then edges += 1 end end
check(edges == 4, "cuatro bordes para el destello")
check(RewardFX.ParseXP("+120 XP  Baja") == 120 and RewardFX.ParseXP("+5 XP") == 5, "lee la XP de los avisos")
check(RewardFX.ParseXP("🎃 Calabaza +3") == nil and RewardFX.ParseXP(nil) == nil, "y no confunde otros avisos")
RewardFX.KillPulse(true, 3)
local cc = game:GetService("Lighting"):FindFirstChild("KillPulseCC")
check(cc ~= nil, "la baja aviva el color del mundo")
local score = gui:FindFirstChild("ScoreTotal")
RewardFX.AddScore(100)
RewardFX.AddScore(50)
check(score.Visible, "el contador de puntos aparece")
for _ = 1, 120 do RunService.RenderStepped:Fire(1 / 60) end
check(score.Text == "+150", "y cuenta hasta el total de la jugada (" .. tostring(score.Text) .. ")")
task.wait(3.2)
check(not score.Visible, "se va solo a los 2,5 s sin sumar")
RewardFX.AddScore(40)
for _ = 1, 120 do RunService.RenderStepped:Fire(1 / 60) end
check(score.Text == "+40", "la siguiente jugada empieza de cero")
local holder = RewardFX.Celebrate("¡NIVEL 10!", "¡Sigue así!", nil, true)
check(holder ~= nil and holder.Parent == gui, "celebración a pantalla completa")
local pieces = 0
for _, d in holder:GetDescendants() do if d.ClassName == "Frame" or d.__className == "Frame" then pieces += 1 end end
check(pieces > 40, "con rayos y confeti (" .. pieces .. " piezas)")
check(RewardFX.Celebrate("segunda") == true, "si coinciden dos, la segunda espera su turno")
local count = 0
for _, c in gui:GetChildren() do if c.Name == "Celebration" then count += 1 end end
check(count == 1, "no se amontonan en pantalla")
RewardFX.Celebrate("tercera"); check(RewardFX.Celebrate("cuarta") == nil, "la cola no crece sin fin")
task.wait(3.8)
check(holder.Parent == nil, "la primera se recoge sola")
local second
for _, d in gui:GetDescendants() do if (d.ClassName == "TextLabel" or d.__className == "TextLabel") and d.Text == "segunda" then second = d end end
check(second ~= nil, "y sale la segunda")
task.wait(7.5)
local left = 0
for _, c in gui:GetChildren() do if c.Name == "Celebration" then left += 1 end end
check(left == 0, "al final no queda ninguna")
check(RewardFX.Celebrate("otra") ~= nil, "después ya se puede celebrar otra")
-- Monedas que vuelan al contador
local roblox = require("@lune/roblox")
local target = mock.new("TextLabel"); target.Parent = gui
target.AbsolutePosition = roblox.Vector2.new(600, 400); target.AbsoluteSize = roblox.Vector2.new(200, 30)
RewardFX.FlyCoins(target, 5)
task.wait(0.1)
local flying = 0
for _, c in gui:GetChildren() do if (c.ClassName == "TextLabel" or c.__className == "TextLabel") and c.Text == "🪙" then flying += 1 end end
check(flying >= 1, "salen monedas volando (" .. flying .. ")")
task.wait(1)
flying = 0
for _, c in gui:GetChildren() do if (c.ClassName == "TextLabel" or c.__className == "TextLabel") and c.Text == "🪙" then flying += 1 end end
check(flying == 0 and target:FindFirstChildOfClass("UIScale") ~= nil, "llegan al contador y este da un salto")
RewardFX.FlyCoins(nil, 3) -- (sin contador no hace nada)
-- Prioridad: subir de rango pasa delante (y no se pierde con la cola llena)
task.wait(4)
RewardFX.Celebrate("a"); RewardFX.Celebrate("b"); RewardFX.Celebrate("c")
check(RewardFX.Celebrate("d") == nil, "cola llena: lo menor se descarta")
check(RewardFX.Celebrate("RANGO", nil, nil, true, true) == true, "lo prioritario entra igualmente")
task.wait(3.8)
local nowShown
for _, d in gui:GetDescendants() do if (d.ClassName == "TextLabel" or d.__className == "TextLabel") and (d.Text == "RANGO" or d.Text == "b") then nowShown = d.Text end end
check(nowShown == "RANGO", "y sale la siguiente (" .. tostring(nowShown) .. ")")
task.wait(8)
local punch = RewardFX.Punch("¡A LUCHAR!")
check(punch ~= nil and punch.Parent == gui and punch.Text == "¡A LUCHAR!", "texto de golpe al empezar")
task.wait(1.5)
check(punch.Parent == nil, "y se va solo")
print("RECOMPENSAS OK")
process.exit(0)
