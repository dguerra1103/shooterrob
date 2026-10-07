-- Granada cocinada en el cliente: un toque la lanza; mantener G la cocina (cuenta atrás) y al soltar sale
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
char.Parent = game.Workspace
me.Character = char
game.Workspace.CurrentCamera.CFrame = roblox.CFrame.new(0, 5, 0)
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local GrenadeController = req(game.StarterPlayer.Client.Modules.GrenadeController)
GrenadeController.Init()
local handler = mock.actions.Grenade
check(handler ~= nil, "tecla de granada enlazada")
local Begin, End = roblox.Enum.UserInputState.Begin, roblox.Enum.UserInputState.End
local function throws()
	local list = {}
	for _, s in mock.serverSent do
		if s.Remote == "ThrowGrenade" then table.insert(list, s) end
	end
	return list
end
-- Toque rápido: sale enseguida, sin cocinar
handler("Grenade", Begin, {})
handler("Grenade", End, {})
local t = throws()
check(#t == 1 and t[1].Args[2] < 0.1, "un toque la lanza enseguida (sin cocinar)")
-- Mantener: se cocina y la cuenta atrás baja
me:SetAttribute("GrenadeReadyAt", 0)
handler("Grenade", Begin, {})
task.wait(1)
local left = GrenadeController.CookLeft()
check(left ~= nil and left < 1.4 and left > 1.0, string.format("manteniendo, la mecha corre (quedan %.2f s)", left or -1))
handler("Grenade", End, {})
t = throws()
check(#t == 2 and math.abs(t[2].Args[2] - 1) < 0.15, string.format("al soltar sale cocinada (%.2f s)", t[2].Args[2]))
check(GrenadeController.CookLeft() == nil, "y deja de cocinarse")
-- Si se agota la mecha, sale sola
me:SetAttribute("GrenadeReadyAt", 0)
handler("Grenade", Begin, {})
local hb = game:GetService("RunService").Heartbeat
for _ = 1, 30 do
	task.wait(0.1)
	hb:Fire(0.1)
end
t = throws()
check(#t == 3, "si se agota la mecha, sale sola")
-- Muerto mientras la cocina: se cancela
me:SetAttribute("GrenadeReadyAt", 0)
handler("Grenade", Begin, {})
hum.Health = 0
hb:Fire(0.1)
check(GrenadeController.CookLeft() == nil, "muerto, se cancela")
handler("Grenade", End, {})
check(#throws() == 3, "y no se lanza")
print("GRANADA COCINADA OK")
process.exit(0)
