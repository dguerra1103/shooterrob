-- Arranca el servidor entero (Main.server) en el simulador con un jugador y juega un rato
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.IntermissionTime = 2
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.EndScreenTime = 0.5
GameConfig.Modes = { process.args[2] or "INF" }
for _, s in GameConfig.ModeSettings do
	s.RoundTime = 6
	if s.PrepTime then s.PrepTime = 2 end
	if s.SubRoundTime then s.SubRoundTime = 3 end
end
local warnings = {}
mock.onWarn = function(...)
	table.insert(warnings, table.concat({ ... }, " "))
end
local ok, err = pcall(req, game.ServerScriptService.Server.Main)
print("Main.server:", ok, err)
local Players = game:GetService("Players")
local p = mock.new("Player"); p.Name = "P1"; p.UserId = 77; p.Parent = Players
table.insert(mock.players, p)
Players.PlayerAdded:Fire(p)
p:SetAttribute("InMenu", false)
local RS = game.ReplicatedStorage
local deadline = os.clock() + 25
local states = {}
local last
while os.clock() < deadline do
	local st = RS:GetAttribute("State")
	if st ~= last then table.insert(states, tostring(st)); last = st end
	task.wait(0.1)
end
print("estados:", table.concat(states, " > "))
local bad = 0
for _, line in warnings do
	if string.find(line, "Arranque", 1, true) or string.find(line, "Error", 1, true) or string.find(line, "think", 1, true) or string.find(line, "balance", 1, true) then
		bad += 1
		print("AVISO:", line)
	end
end
print(bad == 0 and "SERVIDOR OK" or "FALLO")
process.exit(bad == 0 and 0 or 1)
