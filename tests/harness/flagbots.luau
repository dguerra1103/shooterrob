-- Captura la bandera con bots: un bot coge la bandera enemiga, la lleva a su base y puntúa
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local GameConfig = req(RS.Shared.GameConfig)
GameConfig.Bots.Range = 0 -- sin peleas
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local M = game.ServerScriptService.Server.Modules
req(M.MapBuilder).Build("Construction")
local Bots = req(M.Bots)
local Flags = req(M.Flags)
local captures = {}
Flags.OnCapture = function(_, team) table.insert(captures, team.Name) end
RS:SetAttribute("TeamA", GameConfig.Teams[1].Name); RS:SetAttribute("TeamB", GameConfig.Teams[2].Name)
RS:SetAttribute("Mode", "CTF"); RS:SetAttribute("TeamMode", true); RS:SetAttribute("State", "Playing")
Flags.Start()
Bots.Init()
-- (el simulador no tiene Heartbeat propio: se dispara a mano)
local RunService = game:GetService("RunService")
task.spawn(function()
	while true do
		RunService.Heartbeat:Fire(0.05)
		task.wait(0.05)
	end
end)
task.wait(GameConfig.Bots.FillTo + 1)
check(#Bots.Agents > 0, "hay bots (" .. #Bots.Agents .. ")")
local A, B = GameConfig.Teams[1].Name, GameConfig.Teams[2].Name
check(typeof(RS:GetAttribute("FlagPos_" .. A)) == "Vector3" and typeof(RS:GetAttribute("FlagHome_" .. B)) == "Vector3", "posiciones de las banderas publicadas")
local runner
for _, agent in Bots.Agents do
	if agent.Team.Name == A and agent.Root then runner = agent break end
end
check(runner ~= nil, "un bot del equipo " .. A)
-- Lo ponemos en la bandera enemiga
runner.Root.Position = RS:GetAttribute("FlagPos_" .. B) + roblox.Vector3.new(0, 3, 0)
task.wait(0.4)
check(runner.CarryingFlag == true and RS:GetAttribute("FlagState_" .. B) == "Carried" and RS:GetAttribute("FlagCarrier_" .. B) == runner.Name, "el bot coge la bandera enemiga")
-- Y en su base
runner.Root.Position = RS:GetAttribute("FlagHome_" .. A) + roblox.Vector3.new(0, 3, 0)
task.wait(0.4)
check(captures[1] == A and RS:GetAttribute("FlagState_" .. B) == "Home" and not runner.CarryingFlag, "el bot captura y suma el punto")
-- Si muere con la bandera, cae
runner.Root.Position = RS:GetAttribute("FlagPos_" .. B) + roblox.Vector3.new(0, 3, 0)
task.wait(0.4)
check(runner.CarryingFlag == true, "la vuelve a coger")
runner.Humanoid:TakeDamage(1000)
task.wait(0.4)
check(RS:GetAttribute("FlagState_" .. B) == "Dropped" and not runner.CarryingFlag, "al morir el bot la bandera cae")
Flags.Stop()
print("BANDERAS BOTS OK")
process.exit(0)
