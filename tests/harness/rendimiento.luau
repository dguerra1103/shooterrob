-- Fase 5 (rendimiento): el historial de la killcam se recorta de golpe y no muestra a muestra, sin
-- perder lo que hace falta (siempre cubre HistoryTime y no crece sin límite)
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

local Killcam = req(game.StarterPlayer.Client.Modules.Killcam)
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local bot = mock.new("Model"); bot.Name = "Bot1"; bot.Parent = bots
local head = mock.new("Part"); head.Name = "Head"; head.Parent = bot

Killcam.HistoryTime = 0.3 -- (corto, para que la prueba dure poco)
local STEP = 0.02
local maxLen, sorted = 0, true
local start = os.clock()
local x = 0
while os.clock() - start < 2.2 do
	x += 1
	head.Position = roblox.Vector3.new(x, 5, 0)
	Killcam.Record()
	local list = Killcam.Track(bot)
	maxLen = math.max(maxLen, #list)
	for i = 2, #list do
		if list[i] == nil or list[i - 1] == nil or list[i][1] < list[i - 1][1] then
			sorted = false
		end
	end
	task.wait(STEP)
end
local list = Killcam.Track(bot)
local now = os.clock()
check(sorted, "historial en orden y sin huecos")
check(now - list[1][1] >= Killcam.HistoryTime - 0.05, string.format("cubre los %.1f s de historial (%.2f s)", Killcam.HistoryTime, now - list[1][1]))
check(now - list[1][1] <= Killcam.HistoryTime + 1.2, string.format("lo viejo se quita (lo más antiguo: %.2f s)", now - list[1][1]))
check(maxLen <= math.ceil((Killcam.HistoryTime + 1.2) / STEP) + 2, "no crece sin límite (" .. maxLen .. " muestras como mucho)")
check(list[#list][2].X == x, "la última muestra es la posición actual")
-- La posición interpolada sigue funcionando sobre el historial recortado
local mid = Killcam.SampleAt(list, list[#list][1] - 0.1)
check(mid ~= nil and mid.X < x and mid.X > x - 20, "posición en un instante pasado (interpolada)")
print("RENDIMIENTO OK")
process.exit(0)
