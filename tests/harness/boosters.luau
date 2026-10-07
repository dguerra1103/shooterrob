-- Potenciadores con Robux: compra, acumulación, multiplicador y reloj que solo corre jugando
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Enum = roblox.Enum
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
local xp2, coins2 = Shop.Boosters[1], Shop.Boosters[2]
xp2.ProductId, coins2.ProductId = 901, 902
check(data.BoostXP == 0 and data.BoostCoins == 0, "sin potenciadores al empezar")
local MS = game:GetService("MarketplaceService")
local r = MS.ProcessReceipt({ PlayerId = 1, PurchaseId = "b1", ProductId = 901 })
check(r == Enum.ProductPurchaseDecision.PurchaseGranted and data.BoostXP == xp2.Minutes * 60, "XP doble comprado: " .. data.BoostXP .. " s")
MS.ProcessReceipt({ PlayerId = 1, PurchaseId = "b2", ProductId = 901 })
check(data.BoostXP == 2 * xp2.Minutes * 60, "se acumula")
MS.ProcessReceipt({ PlayerId = 1, PurchaseId = "b2", ProductId = 901 })
check(data.BoostXP == 2 * xp2.Minutes * 60, "recibo repetido: no se da dos veces")
check(mock.dsData.u_1.BoostXP == data.BoostXP, "guardado antes de confirmar")
-- Multiplicadores (en partida)
p:SetAttribute("InMenu", false)
local c0 = data.Coins
PlayerData.AddCoins(p, 100, true)
check(data.Coins - c0 == 100, "sin monedas dobles: +100")
MS.ProcessReceipt({ PlayerId = 1, PurchaseId = "b3", ProductId = 902 })
c0 = data.Coins
PlayerData.AddCoins(p, 100, true)
check(data.Coins - c0 == 200, "con monedas dobles: +200")
p:SetAttribute("InMenu", true)
c0 = data.Coins
PlayerData.AddCoins(p, 100, true)
check(data.Coins - c0 == 100, "en la portada no se dobla")
c0 = data.Coins
PlayerData.AddCoins(p, 100, true, true)
check(data.Coins - c0 == 100, "recompensa diaria (noBoost) no se dobla")
p:SetAttribute("InMenu", false)
c0 = data.Coins
PlayerData.AddCoins(p, 100, false)
check(data.Coins - c0 == 100, "las compras/premios fijos no se duplican")
local level0, xp0 = data.Level, data.XP
PlayerData.AddXP(p, 100, "Prueba")
local gained = (data.Level - level0) * 1000 + data.XP - xp0
print("XP ganada con XP doble:", gained)
check(gained >= 200, "XP doble")
-- Reloj: corre jugando, se para en la portada
local before = data.BoostCoins
p:SetAttribute("InMenu", false)
task.wait(5.5)
check(data.BoostCoins < before, "jugando el tiempo baja (" .. before .. " -> " .. data.BoostCoins .. ")")
before = data.BoostCoins
p:SetAttribute("InMenu", true)
task.wait(5.5)
check(data.BoostCoins == before, "en la portada no baja")
-- Se acaba
p:SetAttribute("InMenu", false)
data.BoostCoins = 3
task.wait(5.5)
check(data.BoostCoins == 0, "se acaba")
c0 = data.Coins
PlayerData.AddCoins(p, 100, true)
check(data.Coins - c0 == 100, "acabado: ya no duplica")
local ended = false
for _, sent in mock.sent do
	if sent.Remote == "Notify" and type(sent.Args[2]) == "string" and string.find(sent.Args[2], "Se acabó", 1, true) then ended = true end
end
check(ended, "aviso al acabarse")
print("POTENCIADORES OK")
process.exit(0)
