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
GameConfig.Modes = { "SND" }
for _, s in GameConfig.ModeSettings do
	s.RoundTime = 6
	if s.PrepTime then s.PrepTime = 2 end
	if s.SubRoundTime then s.SubRoundTime = 3 end
end
local warnings = {}
mock.onWarn = function(...)
	table.insert(warnings, table.concat({ ... }, " "))
end
local MapBuilder = req(game.ServerScriptService.Server.Modules.MapBuilder)
MapBuilder.Order = { "MallRush" }
GameConfig.ModeSettings.SND.SubRoundTime = 4
GameConfig.ModeSettings.SND.PrepTime = 1
GameConfig.ModeSettings.SND.RoundTime = 40
local ok, err = pcall(req, game.ServerScriptService.Server.Main)
print("Main.server:", ok, err)
local Players = game:GetService("Players")
local p = mock.new("Player"); p.Name = "P1"; p.UserId = 77; p.Parent = Players
table.insert(mock.players, p)
Players.PlayerAdded:Fire(p)
p:SetAttribute("InMenu", false)
local RS = game.ReplicatedStorage
local deadline = os.clock() + 45
local states = {}
local last
local attackers, lastAtt = {}, nil
local held = {}
while os.clock() < deadline do
	local h = RS:GetAttribute("HeldTeam")
	if h and RS:GetAttribute("Frozen") ~= true then
		held[h .. "@" .. tostring(RS:GetAttribute("Bomb_Attackers"))] = true
	end
	local st = RS:GetAttribute("State")
	if st ~= last then table.insert(states, tostring(st)); last = st end
	local att = RS:GetAttribute("Bomb_Attackers")
	if att and att ~= lastAtt then
		lastAtt = att
		table.insert(attackers, att .. "@" .. tostring(RS:GetAttribute("Mode")))
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
print("atacantes por ronda:", table.concat(attackers, " > "))
if #attackers < 2 then bad += 1 print("FALLO: no hubo rondas con bomba") end
local heldCount = 0
for k in held do
	local a, b = string.match(k, "^(.-)@(.*)$")
	if a ~= b then bad += 1 print("FALLO: se retiene al equipo que no ataca (" .. k .. ")") end
	heldCount += 1
end
print("atacantes retenidos tras la cuenta atrás:", heldCount)
local shared = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:GetAttribute("SharedSites") == true
if shared and heldCount < 1 then bad += 1 print("FALLO: los atacantes no esperan a que se coloquen los defensores") end
if not shared and heldCount > 0 then bad += 1 print("FALLO: con un sitio por equipo no hace falta retener a los atacantes") end
for i = 2, #attackers do
	if attackers[i] == attackers[i - 1] then bad += 1 print("FALLO: no se turnan") end
end
print(bad == 0 and "BUSCAR Y DESTRUIR OK" or "FALLO")
process.exit(bad == 0 and 0 or 1)
