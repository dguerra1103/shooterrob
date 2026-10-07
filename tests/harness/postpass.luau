-- Premios después del pase (cada 5 niveles tras el último)
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local pass = #GameConfig.BattlePass
local bonus = GameConfig.PostPassRewards
local function join(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	return p, PlayerData.WaitFor(p, 3)
end
local _, fresh = join(1)
check(fresh.BonusLevel == pass, "nuevo: empieza a contar en el nivel " .. pass)
-- Veterano por encima del pase: no cobra lo de atrás
mock.dsData.u_2 = { Level = pass + 23, XP = 0, Coins = 100, FreeCrates = 0 }
local p2, vet = join(2)
check(vet.BonusLevel == pass + 23, "veterano: empieza desde su nivel")
local coins, crates = vet.Coins, vet.FreeCrates
-- Sube 2 niveles: pasa por el pass+25 (múltiplo de 5)
PlayerData.AddXP(p2, GameConfig.XPPerLevel * 2, "Prueba", true)
check(vet.Level == pass + 25, "sube al " .. (pass + 25))
check(vet.Coins == coins + bonus.Coins and vet.FreeCrates == crates + bonus.Crates, "premio al llegar al " .. (pass + 25))
PlayerData.AddXP(p2, GameConfig.XPPerLevel, "Prueba", true)
check(vet.Coins == coins + bonus.Coins, "en el siguiente nivel no hay premio")
print("DESPUÉS DEL PASE OK")
process.exit(0)
