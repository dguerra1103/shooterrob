local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local M = game.ServerScriptService.Server.Modules
local Friends = req(M.Friends)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local function add(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.DisplayName = "P" .. id; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	return p
end
mock.friendsImpl = function(self, other) return self.UserId + other == 3 end -- 1 y 2 son amigos
Friends.Init()
local a = add(1)
task.wait(0.1)
check(a:GetAttribute("FriendsHere") == 0 and Friends.Multiplier(a) == 1, "solo: sin bonus")
local b = add(2)
task.wait(0.1)
check(a:GetAttribute("FriendsHere") == 1 and b:GetAttribute("FriendsHere") == 1, "dos amigos se cuentan mutuamente")
check(math.abs(Friends.Multiplier(a) - 1.1) < 1e-6, "+10% con un amigo")
local c = add(3)
task.wait(0.1)
check(c:GetAttribute("FriendsHere") == 0 and a:GetAttribute("FriendsHere") == 1, "un desconocido no da bonus")
Players.PlayerRemoving:Fire(b)
b.Parent = nil
task.wait(0.1)
check(a:GetAttribute("FriendsHere") == 0, "al irse el amigo se quita el bonus")
print("AMIGOS OK")
process.exit(0)
