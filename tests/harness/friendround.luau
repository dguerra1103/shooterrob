-- Amigos en el mismo equipo: al detectar la amistad (entrando) y al repartir al empezar la ronda
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.EndScreenTime = 0.5
GameConfig.MinPlayers = 1
for _, s in GameConfig.ModeSettings do s.RoundTime = 1 end
local M = game.ServerScriptService.Server.Modules
local MapBuilder = req(M.MapBuilder)
local PlayerData = req(M.PlayerData)
local Round = req(M.Round)
local Friends = req(M.Friends)
local Combat = req(M.Combat)
MapBuilder.Build()
PlayerData.Init()
Combat.Init()
Round.Init()
Friends.Init()
-- 1-3 y 2-4 son amigos
local friends = { ["1-3"] = true, ["3-1"] = true, ["2-4"] = true, ["4-2"] = true }
mock.friendsImpl = function(self, other) return friends[(self.UserId % 100) .. "-" .. (other % 100)] == true end
local RS = game.ReplicatedStorage
RS:SetAttribute("Mode", "TDM")
local ps = {}
for i = 1, 4 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.DisplayName = "P" .. i; p.UserId = 100 + i; p.Parent = game:GetService("Players")
	p:SetAttribute("InMenu", true) -- (como hace Loadout al entrar)
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	ps[i] = p
	task.wait(0.1)
end
task.wait(0.3)
print("equipos:", ps[1].Team and ps[1].Team.Name, ps[2].Team and ps[2].Team.Name, ps[3].Team and ps[3].Team.Name, ps[4].Team and ps[4].Team.Name)
local isTeam = ps[1].Team ~= nil
if isTeam then
	check(ps[1].Team == ps[3].Team, "1 y 3 (amigos) juntos")
	check(ps[2].Team == ps[4].Team, "2 y 4 (amigos) juntos")
	check(ps[1].Team ~= ps[2].Team, "equipos igualados (2 y 2)")
else
	print("(modo sin equipos al entrar)")
end
print("AMIGOS EN EQUIPO OK")
process.exit(0)
