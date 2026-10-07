-- Premio de regreso y bonus de Roblox Premium
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
local GameConfig = req(RS.Shared.GameConfig)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local function join(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	return p, PlayerData.WaitFor(p, 3)
end
local today = Shop.DayNumber()
local cfg = GameConfig.Comeback
-- Nuevo: solo se apunta el día
local _, fresh = join(1)
check(fresh.LastPlayDay == today, "el nuevo apunta el día de hoy")
-- Guardado antiguo sin LastPlayDay: sin premio (control de monedas)
mock.dsData.u_2 = { Level = 1, Coins = 100, FreeCrates = 0 }
local _, old = join(2)
check(old.LastPlayDay == today, "guardado antiguo: se apunta el día")
local baseCoins, baseCrates = old.Coins, old.FreeCrates
-- Jugó ayer: sin premio
mock.dsData.u_3 = { Level = 1, Coins = 100, FreeCrates = 0, LastPlayDay = today - 1 }
local _, yesterday = join(3)
check(yesterday.Coins == baseCoins and yesterday.FreeCrates == baseCrates, "jugó ayer: sin premio")
-- Hace 5 días: premio
mock.dsData.u_4 = { Level = 1, Coins = 100, FreeCrates = 0, LastPlayDay = today - 5 }
local _, back = join(4)
check(back.Coins == baseCoins + cfg.Coins and back.FreeCrates == baseCrates + cfg.Crates, "vuelve tras 5 días: +" .. cfg.Coins .. " y caja")
check(back.BoostXP == cfg.BoostXPMinutes * 60, "y XP doble de muestra")
check(back.LastPlayDay == today, "y se apunta hoy")
-- Funciona directo y no repite
local d = { Coins = 0, FreeCrates = 0, LastPlayDay = 10 }
check(PlayerData.RollComeback(d, 13) ~= nil and d.Coins == cfg.Coins, "justo a los " .. cfg.Days .. " días")
check(PlayerData.RollComeback(d, 13) == nil and d.Coins == cfg.Coins, "no repite el mismo día")
check(PlayerData.RollComeback({ Coins = 0, LastPlayDay = 11 }, 13) == nil, "a los 2 días no")
-- Roblox Premium: x1,2 en monedas ganadas
local p5 = join(5)
local d5 = PlayerData.Get and PlayerData.Get(p5) or nil
p5:SetAttribute("RobloxPremium", false)
local before = PlayerData.WaitFor(p5, 3).Coins
PlayerData.AddCoins(p5, 100, true)
local normal = PlayerData.WaitFor(p5, 3).Coins - before
p5:SetAttribute("RobloxPremium", true)
before = PlayerData.WaitFor(p5, 3).Coins
PlayerData.AddCoins(p5, 100, true)
local premium = PlayerData.WaitFor(p5, 3).Coins - before
print("monedas normal/premium:", normal, premium)
check(premium == math.floor(normal * GameConfig.RobloxPremium.Multiplier), "Premium gana +20%")
PlayerData.UpdatePremium(p5)
check(p5:GetAttribute("RobloxPremium") == false, "sin Premium en el mock -> atributo false")
print("REGRESO OK")
process.exit(0)
