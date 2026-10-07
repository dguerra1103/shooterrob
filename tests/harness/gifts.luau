local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.PlaytimeGifts = { { Minutes = 0.05, Coins = 40 }, { Minutes = 0.1, Revives = 2, XP = 10 } }
local Remotes = req(Shared.Remotes)
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Gifts = req(M.Gifts)
Gifts.Init()
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local p = mock.new("Player"); p.Name = "P"; p.UserId = 77; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 2)
check(data ~= nil, "datos cargados")
local coins, revives = data.Coins, data.Revives
check(Remotes.ClaimGift.OnServerInvoke(p) == false, "antes de tiempo: rechazado")
task.wait(3)
check(Remotes.ClaimGift.OnServerInvoke(p) == true and data.Coins == coins + 40, "primer regalo: +40 monedas")
check(Remotes.ClaimGift.OnServerInvoke(p) == false, "el segundo aún no")
check(p:GetAttribute("GiftsClaimed") == 1, "contador para la interfaz")
-- Sale y vuelve a entrar: no se reinicia la cuenta
game:GetService("Players").PlayerRemoving:Fire(p)
table.remove(mock.players, table.find(mock.players, p))
p.Parent = nil
task.wait(0.5)
local q = mock.new("Player"); q.Name = "P"; q.UserId = 77; q.Parent = game:GetService("Players")
table.insert(mock.players, q)
game:GetService("Players").PlayerAdded:Fire(q)
data = PlayerData.WaitFor(q, 3)
task.wait(0.3)
check(q:GetAttribute("GiftsClaimed") == 1, "al volver conserva los regalos recogidos")
check(Remotes.ClaimGift.OnServerInvoke(q) == false, "no puede volver a recoger el primero")
local start = q:GetAttribute("GiftStart")
check(start and workspace_time_ok ~= false, "conserva el tiempo jugado")
task.wait(3.2)
check(Remotes.ClaimGift.OnServerInvoke(q) == true and data.Revives == revives + 2, "segundo regalo: +2 revivir")
check(Remotes.ClaimGift.OnServerInvoke(q) == false, "no hay más regalos")
print("REGALOS OK")
process.exit(0)
