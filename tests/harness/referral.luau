-- Invitaciones: el nuevo que entra con la invitación cobra, y el que invitó también (si está aquí)
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
local function join(id, launch)
	if launch then mock.joinData[id] = { LaunchData = launch } end
	local p = mock.new("Player"); p.Name = "P" .. id; p.DisplayName = "P" .. id; p.UserId = id; p.AccountAge = 30; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	return p, PlayerData.WaitFor(p, 3)
end
local inviter, invData = join(100)
local coins0 = invData.Coins
local base = GameConfig.Referral
local newbie, newData = join(101, "ref:100")
task.wait(0.1)
check(newData.ReferredBy == 100, "el nuevo queda apuntado como invitado por 100")
local fresh = select(2, join(105))
check(newData.Coins == fresh.Coins + base.NewPlayerCoins, "el nuevo recibe " .. base.NewPlayerCoins)
check(invData.Coins == coins0 + base.InviterCoins and invData.Referrals == 1, "el que invitó recibe " .. base.InviterCoins)
local selfP, selfData = join(102, "ref:102")
check(selfData.ReferredBy == 0, "invitarse a uno mismo no cuenta")
local _, badData = join(103, "ref:abc")
check(badData.ReferredBy == 0, "datos raros ignorados")
invData.Referrals = base.MaxRewards
local before = invData.Coins
local _, d4 = join(104, "ref:100")
check(d4.ReferredBy == 100 and invData.Coins == before, "con el tope de invitaciones el que invita ya no cobra")
-- Cuenta recién creada: el nuevo cobra, el que invita no
invData.Referrals = 0
local before2 = invData.Coins
mock.joinData[106] = { LaunchData = "ref:100" }
local young = mock.new("Player"); young.Name = "P106"; young.DisplayName = "P106"; young.UserId = 106; young.AccountAge = 0; young.Parent = Players
table.insert(mock.players, young)
Players.PlayerAdded:Fire(young)
local dy = PlayerData.WaitFor(young, 3)
check(dy.ReferredBy == 100 and invData.Coins == before2, "cuenta de 0 días: el que invita no cobra")
_ = newbie; _ = selfP
print("INVITACIONES OK")
process.exit(0)
