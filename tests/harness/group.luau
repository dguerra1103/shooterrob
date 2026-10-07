-- Premio por unirse al grupo: una vez, comprobando también GetGroupsAsync
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local GameConfig = req(RS.Shared.GameConfig)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 5; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
local Remotes = req(RS.Shared.Remotes)
local claim = Remotes.ClaimGroup.OnServerInvoke
check(claim(me) == false, "sin ID de grupo no se puede")
GameConfig.Group.Id = 777
local ok, why = claim(me)
check(ok == false and why == "NotMember", "sin estar en el grupo: NotMember")
local ok2, why2 = claim(me)
check(ok2 == false and why2 ~= "NotMember", "no se puede insistir sin parar (" .. tostring(why2) .. ")")
task.wait(3.1)
mock.groupList[5] = { { Id = 12 }, { Id = 777 } }
local coins = data.Coins
local ok3, amount = claim(me)
check(ok3 == true and amount == GameConfig.Group.Coins and data.Coins == coins + amount, "recién unido (IsInGroup en caché): cobra " .. tostring(amount))
check(data.GroupReward == true, "queda marcado")
task.wait(3.1)
local ok4, why4 = claim(me)
check(ok4 == false and why4 == "Ya lo tienes" and data.Coins == coins + amount, "no se cobra dos veces")
-- El cliente lo ve en sus datos
local view
for _, m in mock.sent do
	if m.Remote == "DataUpdate" then view = m.Args[1] end
end
check(view and view.GroupReward == true, "los datos del cliente dicen que ya lo tiene")
print("GRUPO OK")
process.exit(0)
