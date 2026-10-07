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
GameConfig.Modes = { "TDM", "DOM", "FFA", "CTF" }
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
local deadline = os.clock() + 40
local states = {}
local last
local votes, lastVote = {}, nil
while os.clock() < deadline do
	local st = RS:GetAttribute("State")
	if st ~= last then table.insert(states, tostring(st)); last = st end
	local v1 = RS:GetAttribute("Vote1_Map")
	if v1 and v1 ~= lastVote then
		lastVote = v1
		table.insert(votes, v1 .. " / " .. tostring(RS:GetAttribute("Vote1_Mode")))
	end
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
print("votación (opción 1):", table.concat(votes, " | "))
for _, v in votes do
	local known = false
	for _, n in { "Construcción", "Costa", "Terminal", "Mall Rush", "Rooftop District", "Metro Yard", "Desert Base", "Dockyard", "Industrial Yard" } do
		known = known or v:find(n, 1, true) ~= nil
	end
	if not known or not (v:find("Duelo por equipos") or v:find("Dominio") or v:find("Buscar y destruir")) then
		bad += 1
		print("FALLO: la primera opción no es un mapa 5 contra 5 con Duelo o Dominio: " .. v)
	end
end
if #votes == 0 then bad += 1 print("FALLO: no hubo votación") end
print(bad == 0 and "VOTACION OK" or "FALLO")
process.exit(bad == 0 and 0 or 1)
