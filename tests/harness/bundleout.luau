-- Pack Aventurero: entrega los trajes y lo demás; deshace bien si no se puede guardar
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Enum = roblox.Enum
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local Shop = req(game.ReplicatedStorage.Shared.Shop)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local bundle
for _, b in Shop.Bundles do if b.Id == "Aventurero" then bundle = b end end
bundle.ProductId = 4242
local p = mock.new("Player"); p.Name = "P1"; p.UserId = 1; p.Parent = Players
table.insert(mock.players, p)
Players.PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
data.Outfits.Pirata = true -- ya tenía uno
local coins = data.Coins
local MS = game:GetService("MarketplaceService")
local r = MS.ProcessReceipt({ PlayerId = 1, PurchaseId = "av1", ProductId = 4242 })
check(r == Enum.ProductPurchaseDecision.PurchaseGranted, "compra aceptada")
check(data.Outfits.Vaquero and data.Outfits.Pirata and data.Outfits.Caballero and data.KillEffects.Rodadora and data.Charms.Calavera and data.Sprays.Pirata, "trajes, efecto, colgante y grafiti entregados")
check(data.Coins == coins + bundle.Coins + Shop.OutfitPrices.Pirata and data.Bundles.Aventurero, "monedas, lo que ya tenía devuelto en monedas y pack marcado")
-- Otro jugador: no se puede guardar -> se deshace sin quitarle lo que ya tenía
local p2 = mock.new("Player"); p2.Name = "P2"; p2.UserId = 2; p2.Parent = Players
table.insert(mock.players, p2)
Players.PlayerAdded:Fire(p2)
local d2 = PlayerData.WaitFor(p2, 3)
d2.Outfits.Pirata = true
mock.dsData.u_2.SessionLock = { Job = "otro", Time = os.time() }
local r2 = MS.ProcessReceipt({ PlayerId = 2, PurchaseId = "av2", ProductId = 4242 })
check(r2 == Enum.ProductPurchaseDecision.NotProcessedYet, "si no se guarda, no se confirma")
check(d2.Outfits.Vaquero == nil and d2.Outfits.Pirata == true and not d2.Bundles.Aventurero, "deshecho: quita solo lo que dio (el traje que ya tenía se queda)")
print("PACK AVENTURERO OK")
process.exit(0)
