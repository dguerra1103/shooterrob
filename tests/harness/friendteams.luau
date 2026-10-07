-- Los amigos caen en el mismo equipo cuando el reparto empata
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local M = game.ServerScriptService.Server.Modules
local Friends = req(M.Friends)
Friends.Init()
-- 1 y 2 son amigos; 3 y 4 también
local pairsF = { ["1-2"] = true, ["2-1"] = true, ["3-4"] = true, ["4-3"] = true }
mock.friendsImpl = function(self, other) return pairsF[self.UserId .. "-" .. other] == true end
local ps = {}
for i = 1, 4 do
	local p = mock.new("Player"); p.Name = "P" .. i; p.DisplayName = "P" .. i; p.UserId = i
	p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	ps[i] = p
	task.wait(0.05)
end
task.wait(0.2)
check(Friends.AreFriends(ps[1], ps[2]) and Friends.AreFriends(ps[4], ps[3]) and not Friends.AreFriends(ps[1], ps[3]), "amistades detectadas")
print("OK AMIGOS (detección)")
process.exit(0)
