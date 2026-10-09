-- Prueba del guardado: bloqueo de sesión, guardados agrupados y compras con Robux
local process = require("@lune/process")
local task = require("@lune/task")
local Enum = require("@lune/roblox").Enum
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local game, req = mock.buildGame(process.args[1])
game.JobId = "server-A"
local M = game.ServerScriptService.Server.Modules
local Shared = game.ReplicatedStorage.Shared
local Remotes = req(Shared.Remotes)
local Shop = req(Shared.Shop)
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local function check(cond, msg)
	if not cond then error("FALLO: " .. msg, 2) end
	print("ok  " .. msg)
end
local Players = game:GetService("Players")
local function join(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	return p
end
local function leave(p)
	table.remove(mock.players, table.find(mock.players, p))
	Players.PlayerRemoving:Fire(p)
	p.Parent = nil
end

-- 1. Jugador nuevo: se crea con bloqueo de este servidor
local p1 = join(1)
check(PlayerData.Get(p1) and PlayerData.Get(p1).Level == 1, "jugador nuevo cargado con valores por defecto")
check(mock.dsData.u_1.SessionLock.Job == "server-A", "bloqueo de sesión puesto al entrar")

-- 2. Datos con bloqueo viejo de otro servidor (caído): se quita y se carga
mock.dsData.u_2 = { Level = 7, XP = 10, Coins = 900, Skins = { Default = true }, SessionLock = { Job = "server-B", Time = os.time() - 4000 } }
local p2 = join(2)
check(PlayerData.Get(p2) and PlayerData.Get(p2).Level == 7 and PlayerData.Get(p2).Coins >= 900, "bloqueo caducado: carga los datos guardados")

-- 2b. Ajustes antiguos (calidad "Alta" por defecto) pasan una vez a "Auto"; los nuevos se respetan
mock.dsData.u_5 = { Level = 3, XP = 0, Coins = 10, Skins = { Default = true }, Settings = { Quality = "Alta", FOV = 90, Sensitivity = 1, AimSensitivity = 0.8 } }
local p5 = join(5)
check(PlayerData.Get(p5).Settings.Quality == "Auto" and PlayerData.Get(p5).Settings.FOV == 90, "calidad antigua migrada a Auto (resto intacto)")
leave(p5)
mock.dsData.u_6 = { Level = 3, XP = 0, Coins = 10, Skins = { Default = true }, Settings = { Quality = "Ultra", QualityVersion = 2, FOV = 80, Sensitivity = 1, AimSensitivity = 0.8 } }
local p6 = join(6)
check(PlayerData.Get(p6).Settings.Quality == "Ultra", "calidad elegida tras la migración se respeta")
leave(p6)
-- 2c. Disposición de los controles táctiles (Fase 15, versión 2): un perfil viejo sin personalizar usa
-- la nueva; uno personalizado se conserva tal cual; la basura se limpia. Nunca se borra lo del jugador
mock.dsData.u_7 = { Level = 2, XP = 0, Coins = 5, Skins = { Default = true }, Settings = { Quality = "Auto", QualityVersion = 2, FOV = 80, Sensitivity = 1, AimSensitivity = 0.8, HudLayout = {} } }
local p7 = join(7)
check(PlayerData.Get(p7).Settings.HudLayoutVersion == 2 and next(PlayerData.Get(p7).Settings.HudLayout) == nil, "disposición sin personalizar: pasa a la versión 2 (la nueva)")
leave(p7)
mock.dsData.u_8 = { Level = 2, XP = 0, Coins = 5, Skins = { Default = true }, Settings = { Quality = "Auto", QualityVersion = 2, FOV = 85, Sensitivity = 1, AimSensitivity = 0.8, HudLayout = { Fire = { X = 0.7, Y = 0.75, S = 1.3, O = 0.8 }, Aim = { S = 0.9 }, Bogus = { X = 1, Y = 1 } } } }
local p8 = join(8)
local s8 = PlayerData.Get(p8).Settings
check(s8.HudLayoutVersion == 2 and s8.HudLayout.Fire.X == 0.7 and s8.HudLayout.Fire.Y == 0.75 and s8.HudLayout.Fire.S == 1.3 and s8.HudLayout.Fire.O == 0.8 and s8.HudLayout.Aim.S == 0.9, "disposición personalizada (versión 1): se conserva")
check(s8.HudLayout.Bogus == nil and s8.FOV == 85, "la basura se limpia y el resto de ajustes queda intacto")
leave(p8)
check(mock.dsData.u_8.Settings.HudLayoutVersion == 2 and mock.dsData.u_8.Settings.HudLayout.Fire.S == 1.3, "y se guarda migrada")

-- 3. Al salir, se guarda y se suelta el bloqueo
PlayerData.Get(p2).Coins = 950
leave(p2)
check(mock.dsData.u_2.Coins == 950 and mock.dsData.u_2.SessionLock == nil, "al salir: guardado y bloqueo liberado")

-- 4. Si otro servidor se queda los datos, este NO los sobrescribe
mock.dsData.u_1.SessionLock = { Job = "server-B", Time = os.time() }
mock.dsData.u_1.Coins = 12345
PlayerData.Get(p1).Coins = 1
local _ = Remotes.GetData.OnServerInvoke(p1)
-- forzamos un guardado como el autoguardado
local prodReceipt = { PlayerId = 1, PurchaseId = "compra-1", ProductId = 777 }
Shop.CoinPacks[1].ProductId = 777
local coinsBefore = PlayerData.Get(p1).Coins
local decision = game:GetService("MarketplaceService").ProcessReceipt(prodReceipt)
check(decision == Enum.ProductPurchaseDecision.NotProcessedYet, "compra no se da por buena si no se puede guardar")
check(PlayerData.Get(p1).Coins == coinsBefore, "monedas de la compra deshechas")
check(mock.dsData.u_1.Coins == 12345, "datos del otro servidor intactos")

-- 5. Compra con Robux normal: se guarda antes de confirmar y no se entrega dos veces
local p3 = join(3)
local d3 = PlayerData.Get(p3)
local c0 = d3.Coins
local r1 = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 3, PurchaseId = "compra-9", ProductId = 777 })
check(r1 == Enum.ProductPurchaseDecision.PurchaseGranted and d3.Coins == c0 + Shop.CoinPacks[1].Coins, "compra entregada")
check(mock.dsData.u_3.Coins == d3.Coins, "compra guardada en el DataStore antes de confirmar")
local r2 = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 3, PurchaseId = "compra-9", ProductId = 777 })
check(r2 == Enum.ProductPurchaseDecision.PurchaseGranted and d3.Coins == c0 + Shop.CoinPacks[1].Coins, "recibo repetido: no se entrega dos veces")

-- 5b. Pack de inicio
Shop.StarterPack.ProductId = 888
local view = Remotes.GetData.OnServerInvoke(p3)
check(view.StarterPackAvailable == true, "pack de inicio disponible para jugador nuevo")
local c1 = d3.Coins
local r3 = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 3, PurchaseId = "starter-1", ProductId = 888 })
check(r3 == Enum.ProductPurchaseDecision.PurchaseGranted, "pack de inicio comprado")
check(d3.Coins == c1 + Shop.StarterPack.Coins and d3.Outfits.BlazeRunner and d3.Skins.Sakura and d3.KillEffects.Confeti, "pack entrega monedas, traje, skin y efecto")
check(Remotes.GetData.OnServerInvoke(p3).StarterPackAvailable == false, "el pack ya no se ofrece")
local c2 = d3.Coins
local r4 = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 3, PurchaseId = "starter-again", ProductId = 888 })
check(r4 == Enum.ProductPurchaseDecision.PurchaseGranted and d3.Coins == c2 + Shop.StarterPack.Coins, "pack repetido: solo monedas, sin perder el pago")
-- Si no se puede guardar, se deshace todo
local p4 = join(4)
local d4 = PlayerData.Get(p4)
local coins4 = d4.Coins
mock.dsData.u_4.SessionLock = { Job = "server-B", Time = os.time() }
local saveFail = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 4, PurchaseId = "starter-2", ProductId = 888 })
check(saveFail == Enum.ProductPurchaseDecision.NotProcessedYet and not d4.StarterPack and not d4.Skins.Sakura and not d4.Outfits.BlazeRunner, "pack deshecho si no se guarda")
check(d4.Coins == coins4, "al deshacer quedan sus monedas de antes (" .. d4.Coins .. ")")
check(table.find(d4.Purchases, "starter-2") == nil, "el recibo deshecho no queda registrado")

-- 5c. Packs de temporada (por fechas)
local halloween, navidad = Shop.Bundles[1], Shop.Bundles[2]
halloween.ProductId, navidad.ProductId = 999, 998
local function offered(p) return table.find(Remotes.GetData.OnServerInvoke(p).BundlesAvailable or {}, "Halloween") ~= nil end
check(offered(p3) == (os.time() < halloween.EndsAt), "pack de Halloween ofrecido mientras dura")
check(table.find(Remotes.GetData.OnServerInvoke(p3).BundlesAvailable or {}, "Navidad") == nil, "el de Navidad aún no se ofrece")
local c5 = d3.Coins
local r5 = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 3, PurchaseId = "halloween-1", ProductId = 999 })
check(r5 == Enum.ProductPurchaseDecision.PurchaseGranted and d3.Coins == c5 + halloween.Coins, "pack de Halloween: monedas")
check(d3.KillEffects.Calabazas and d3.Charms.Calabaza and d3.Sprays.Calabaza and d3.Bundles.Halloween, "pack de Halloween: efecto, colgante y grafiti")
check(not offered(p3), "ya no se ofrece")
local c6 = d3.Coins
local r6 = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 3, PurchaseId = "halloween-2", ProductId = 999 })
check(r6 == Enum.ProductPurchaseDecision.PurchaseGranted and d3.Coins == c6 + halloween.Coins, "repetido: solo monedas")
local d4b = PlayerData.Get(p4)
d4b.Charms.Calabaza = true -- (ya tenía el colgante: al deshacer no se le quita)
local fail = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 4, PurchaseId = "halloween-3", ProductId = 999 })
check(fail == Enum.ProductPurchaseDecision.NotProcessedYet and not d4b.Bundles.Halloween and not d4b.KillEffects.Calabazas and not d4b.Sprays.Calabaza and d4b.Charms.Calabaza, "deshecho si no se guarda (sin quitar lo que ya tenía)")
-- Pack de Navidad (en sus fechas)
navidad.StartsAt = os.time() - 10
check(table.find(Remotes.GetData.OnServerInvoke(p3).BundlesAvailable or {}, "Navidad") ~= nil, "en sus fechas se ofrece el de Navidad")
local r7 = game:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 3, PurchaseId = "navidad-1", ProductId = 998 })
check(r7 == Enum.ProductPurchaseDecision.PurchaseGranted and d3.KillEffects.Nieve and d3.Charms.Baston and d3.Sprays.Navidad and d3.Bundles.Navidad, "pack de Navidad: ventisca, bastón y grafiti")
halloween.ProductId, navidad.ProductId = 0, 0
-- Guardado antiguo con el pack de Halloween comprado: pasa a Bundles
mock.dsData.u_77 = { Level = 4, Coins = 100, HalloweenBundle = true }
local p77 = join(77)
local d77 = PlayerData.WaitFor(p77, 3)
check(d77 and d77.Bundles.Halloween == true and d77.HalloweenBundle == nil, "guardado antiguo: el pack de Halloween se conserva")

-- 6. Varias compras seguidas = una sola escritura (límite de Roblox)
d3.Coins = 100000
local writes0 = mock.dsWrites
for _, id in { "Toxico", "Selva", "Oceano", "Dorado", "Hielo" } do
	assert(Remotes.BuyItem.OnServerInvoke(p3, "Skin", id))
end
check(mock.dsWrites == writes0, "las compras no escriben al momento")
task.wait(7.5)
check(mock.dsWrites == writes0 + 1, "5 compras seguidas -> 1 escritura (" .. (mock.dsWrites - writes0) .. ")")
check(mock.dsData.u_3.Skins.Hielo == true, "la escritura agrupada incluye todas las compras")
print("TODO OK")
process.exit(0)
