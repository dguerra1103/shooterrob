-- Visor de francotirador: la mira se mueve un poco; con Mayús se aguanta la respiración
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local UIS = game:GetService("UserInputService")
UIS.TouchEnabled = false
UIS.KeyboardEnabled = true
req(game.StarterPlayer.Client.Modules.ClientState)
local ScopeSway = req(game.StarterPlayer.Client.Modules.ScopeSway)
local A = ScopeSway.Amplitude

-- Avanza t segundos y devuelve la suma de giros aplicados
local function run(seconds, scoped)
	local sumP, sumY = 0, 0
	for _ = 1, math.floor(seconds * 60) do
		local p, y = ScopeSway.Update(1 / 60, scoped)
		sumP += p
		sumY += y
		task.wait(1 / 60)
	end
	return sumP, sumY
end

run(0.5, false)
check(ScopeSway.Amount() < 1e-6, "sin visor, la mira no se mueve")
run(1.5, true)
check(math.abs(ScopeSway.Amount() - A) < A * 0.05, "con el visor, la mira se mueve un poco")
mock.keysDown.LeftShift = true
run(1.5, true)
check(ScopeSway.Holding and ScopeSway.Amount() < A * 0.15, string.format("con Mayús se aguanta la respiración (%.0f %%)", ScopeSway.Amount() / A * 100))
run(2.3, true) -- (se acaba el aire: 3,5 s)
check(not ScopeSway.Holding and ScopeSway.OutOfBreath(), "al acabarse el aire, ya no se puede aguantar")
run(0.6, true)
check(ScopeSway.Amount() > A * 1.2, "y la mira se mueve más un momento")
mock.keysDown.LeftShift = nil
run(2.5, true)
check(ScopeSway.Breath > 0.5 and not ScopeSway.OutOfBreath(), "y se recupera el aire")
-- Al quitar el visor vuelve a su sitio (la suma de giros vuelve a ~0)
ScopeSway.Reset()
local p1, y1 = run(2, true)
local p2, y2 = run(3, false)
check(math.abs(p1 + p2) < 1e-4 and math.abs(y1 + y2) < 1e-4, "al quitar el visor, la mira vuelve a su sitio")
-- En el móvil, la mitad
UIS.TouchEnabled = true
UIS.KeyboardEnabled = false
run(1.5, true)
check(math.abs(ScopeSway.Amount() - A * 0.5) < A * 0.05, "en el móvil se mueve la mitad")
print("VISOR OK")
process.exit(0)
