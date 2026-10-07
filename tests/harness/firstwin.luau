-- Primera victoria del día y caja sorpresa
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local GameConfig = req(RS.Shared.GameConfig)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local p = mock.new("Player"); p.Name = "P1"; p.UserId = 1; p.Parent = Players
table.insert(mock.players, p)
Players.PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
local cfg = GameConfig.FirstWinOfDay
local coins0 = data.Coins
local given = PlayerData.ClaimFirstWin(p, 1)
check(given == cfg.Coins and data.Coins == coins0 + cfg.Coins, "primera victoria: +" .. cfg.Coins)
check(PlayerData.ClaimFirstWin(p, 1) == nil and data.Coins == coins0 + cfg.Coins, "solo una vez al día")
data.FirstWinDay -= 1
check(PlayerData.ClaimFirstWin(p, 0.5) == math.floor(cfg.Coins * 0.5), "al día siguiente otra vez (contra bots, escalado)")
-- Caja sorpresa
local sc = GameConfig.SurpriseCrate
local crates0 = data.FreeCrates
check(PlayerData.RollSurpriseCrate(p, 0.0) == true and data.FreeCrates == crates0 + 1 and data.CratePity == 0, "con suerte: caja")
check(PlayerData.RollSurpriseCrate(p, 0.99) == false and data.CratePity == 1, "sin suerte: suma la garantía")
local got = false
for i = 2, sc.Pity do
	got = PlayerData.RollSurpriseCrate(p, 0.99)
	if got then check(i == sc.Pity, "garantía a las " .. sc.Pity .. " partidas (" .. i .. ")") break end
end
check(got and data.FreeCrates == crates0 + 2, "la garantía da la caja")
p:SetAttribute("VIP", true)
check(PlayerData.RollSurpriseCrate(p, sc.Chance * 1.5) == false, "el VIP no tiene más probabilidad de caja (azar ligado a un pase de pago)")
print("PRIMERA VICTORIA OK")
process.exit(0)
