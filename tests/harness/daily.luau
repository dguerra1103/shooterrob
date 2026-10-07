-- Premio diario: el día que toca (si se salta uno, vuelve al 1)
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Shop = req(RS.Shared.Shop)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local p = mock.new("Player"); p.Name = "P1"; p.UserId = 1; p.Parent = Players
table.insert(mock.players, p)
Players.PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
local function view()
	PlayerData.SendUpdate(p)
	local v
	for _, m in mock.sent do if m.Remote == "DataUpdate" then v = m.Args[1] end end
	return v
end
local today = Shop.DayNumber()
data.DailyStreak, data.LastDailyDay = 4, today - 1
check(view().DailyNext == 5, "racha seguida: toca el día 5")
data.DailyStreak, data.LastDailyDay = 4, today - 3
check(view().DailyNext == 1, "si se saltó un día: vuelve al 1")
data.DailyStreak, data.LastDailyDay = 7, today - 1
check(view().DailyNext == 1, "tras el día 7, otra vez el 1")
print("DIARIO OK")
process.exit(0)
