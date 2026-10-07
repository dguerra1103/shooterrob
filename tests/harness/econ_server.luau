-- Economía (servidor): compras con Robux seguras e idempotentes, monedas, pase y analítica.
-- Casos: compra correcta, ya lo tienes, recibo repetido, desconexión durante la compra, servidor
-- nuevo, fallo del DataStore, pack parcial, producto desconocido / sin productos, equipar al momento,
-- pase (premium, nivel, reclamar, misiones, cambio de temporada) y lo que ya no se vende.
local process = require("@lune/process")
local task = require("@lune/task")
local Enum = require("@lune/roblox").Enum
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "server-A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Shared = game.ReplicatedStorage.Shared
local Players = game:GetService("Players")
local MS = game:GetService("MarketplaceService")
local Granted, NotYet = Enum.ProductPurchaseDecision.PurchaseGranted, Enum.ProductPurchaseDecision.NotProcessedYet
local Shop = req(Shared.Shop)
local Products = req(Shared.Economy.Products)
local BP = req(Shared.Economy.BattlePassConfig)
local Catalog = req(Shared.Economy.CosmeticCatalog)
local Config = req(Shared.Economy.MonetizationConfig)
-- (temporada 1 siempre activa en la prueba, sea cual sea la fecha)
local s1 = BP.Get("S1")
s1.StartsAt, s1.EndsAt = 0, 4102444800
-- Ids de prueba (en el juego están a 0 hasta crearlos en el Creator Dashboard)
Products.Items["Skin:Inferno"].ProductId = 9001
Products.Items["Card:Oro"].ProductId = 9002
local red = req(Shared.Economy.StoreRotation).BundleById("RedOps")
red.ProductId = 9003
s1.Premium.ProductId = 9004
Products.TierSkip.ProductId = 9005
Shop.StarterPack.ProductId = 9006
Shop.CoinPacks[1].ProductId = 9007
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
local Analytics = req(game.ServerScriptService.Server.Modules.Analytics)
PlayerData.Init()
local Remotes = req(Shared.Remotes)
local function join(id, name)
	local p = mock.new("Player"); p.Name = name or ("P" .. id); p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	return p, PlayerData.WaitFor(p, 3)
end
local function leave(p)
	table.remove(mock.players, table.find(mock.players, p))
	Players.PlayerRemoving:Fire(p)
	p.Parent = nil
end
local function lastSent(name)
	for i = #mock.sent, 1, -1 do
		if mock.sent[i].Remote == name then return mock.sent[i].Args end
	end
	return nil
end
local function receipt(userId, purchaseId, productId)
	return MS.ProcessReceipt({ PlayerId = userId, PurchaseId = purchaseId, ProductId = productId })
end

-- 1. Compra correcta (skin con Robux) + bonus de primera compra
local p1, d1 = join(1)
local coins = d1.Coins
check(not d1.FirstPurchase and not d1.Skins.Inferno, "empieza sin la skin")
check(receipt(1, "r1", 9001) == Granted, "compra aceptada")
check(d1.Skins.Inferno == true and d1.Coins == coins, "skin entregada (sin tocar las monedas)")
check(d1.FirstPurchase and d1.Cards.PrimerGolpe, "primera compra: tarjeta PRIMER GOLPE de regalo")
local reveal = lastSent("PurchaseGranted")[1]
check(reveal and reveal.Items[1].Id == "Inferno" and reveal.Bonus and reveal.Bonus.Id == "PrimerGolpe", "el cliente recibe la escena de compra con lo que se dio")
check(mock.dsData.u_1.Skins.Inferno and table.find(mock.dsData.u_1.Purchases, "r1"), "guardado antes de confirmar")
check((Analytics.Counts.purchase_success or 0) >= 1, "analítica: purchase_success")
-- 2. Recibo repetido: no se entrega dos veces
local before = d1.Coins
check(receipt(1, "r1", 9001) == Granted and d1.Coins == before, "recibo repetido: se confirma sin entregar otra vez")
-- 3. Ya lo tenía (comprado a la vez en otro sitio): vuelve en monedas
check(receipt(1, "r2", 9001) == Granted and d1.Coins == before + 179 * Config.Bundles.CoinsPerRobux, "ya lo tenía: Robux devueltos en monedas (" .. (d1.Coins - before) .. ")")
-- 4. Equipar justo después de comprar
Remotes.EquipCosmetic.OnServerEvent:Fire(p1, "Skin", "Inferno")
check(d1.EquippedSkin == "Inferno", "equipar la skin al momento")
Remotes.EquipCosmetic.OnServerEvent:Fire(p1, "Card", "PrimerGolpe")
check(d1.EquippedCard == "PrimerGolpe" and p1:GetAttribute("Card") == "PrimerGolpe", "tarjeta equipada y visible para los demás")
Remotes.EquipCosmetic.OnServerEvent:Fire(p1, "Card", "Oro")
check(d1.EquippedCard == "PrimerGolpe", "no se equipa lo que no tienes")
Remotes.EquipCosmetic.OnServerEvent:Fire(p1, "Skin", "CamoTigre")
check(d1.EquippedSkin == "Inferno", "ni camuflajes de maestría por aquí")
-- 5. Pack parcial: solo lo que falta + monedas por lo que ya tenía
d1.Skins.OperacionRoja = true
before = d1.Coins
check(receipt(1, "r3", 9003) == Granted, "pack aceptado")
check(d1.Outfits.OperacionRoja and d1.KillEffects.ChoqueRojo and d1.Cards.Infierno and d1.Poses.Senala and d1.Bundles.RedOps, "pack: entrega lo que faltaba")
check(d1.Coins == before + 179 * Config.Bundles.CoinsPerRobux, "pack: lo que ya tenías vuelve en monedas")
-- 6. Desconexión durante la compra: no está en el servidor → no se confirma; al volver, se entrega
local p2, d2 = join(2)
leave(p2)
check(receipt(2, "r4", 9002) == NotYet, "desconectado: se deja para cuando vuelva")
p2, d2 = join(2)
check(d2.Cards.Oro == nil, "al volver aún no la tiene (Roblox reintenta)")
check(receipt(2, "r4", 9002) == Granted and d2.Cards.Oro, "Roblox reintenta: entregada")
-- 7. Fallo del DataStore: se deshace todo y no se confirma
local p3, d3 = join(3)
local c3 = d3.Coins
mock.dsFail = true
check(receipt(3, "r5", 9003) == NotYet, "DataStore caído: no se confirma")
check(not d3.Bundles.RedOps and not d3.Skins.OperacionRoja and not d3.FirstPurchase and d3.Coins == c3 and not table.find(d3.Purchases, "r5"), "deshecho: nada entregado, nada apuntado")
mock.dsFail = false
check(receipt(3, "r5", 9003) == Granted and d3.Bundles.RedOps and d3.Skins.OperacionRoja, "reintento con el DataStore de vuelta: entregado")
-- 8. Dos recibos a la vez del mismo jugador: no se pisan
local r6, r7
task.spawn(function() r6 = receipt(3, "r6", 9007) end)
task.spawn(function() r7 = receipt(3, "r7", 9007) end)
task.wait(2)
check(r6 == Granted and r7 == Granted and d3.Coins == c3 + 2 * Shop.CoinPacks[1].Coins, "dos packs de monedas seguidos: los dos entregados una vez (" .. d3.Coins - c3 .. ")")
-- 9. Producto desconocido / sin productos
check(receipt(3, "r8", 123456) == NotYet, "producto que no existe: no se confirma (y avisa)")
check(Products.Resolve(0) == nil, "id 0 (PRÓXIMAMENTE) no es un producto")
-- 10. Servidor nuevo: lo comprado está guardado y el recibo no se repite
leave(p1)
check(mock.dsData.u_1.SessionLock == nil, "al salir suelta el bloqueo")
local game2, req2 = mock.buildGame(process.args[1])
game2.JobId = "server-B"
local BP2 = req2(game2.ReplicatedStorage.Shared.Economy.BattlePassConfig)
BP2.Get("S1").StartsAt, BP2.Get("S1").EndsAt = 0, 4102444800
req2(game2.ReplicatedStorage.Shared.Economy.Products).Items["Skin:Inferno"].ProductId = 9001
local PD2 = req2(game2.ServerScriptService.Server.Modules.PlayerData)
PD2.Init()
local Players2 = game2:GetService("Players")
local np = mock.new("Player"); np.Name = "P1"; np.UserId = 1; np.Parent = Players2
table.insert(mock.players, np)
Players2.PlayerAdded:Fire(np)
local nd = PD2.WaitFor(np, 3)
check(nd.Skins.Inferno and nd.Cards.PrimerGolpe and nd.EquippedSkin == "Inferno", "servidor nuevo: lo comprado y lo equipado siguen")
local nc = nd.Coins
check(game2:GetService("MarketplaceService").ProcessReceipt({ PlayerId = 1, PurchaseId = "r1", ProductId = 9001 }) == Granted and nd.Coins == nc, "servidor nuevo: recibo viejo repetido no se entrega otra vez")
table.remove(mock.players, table.find(mock.players, np))

-- 11. Monedas: tipos nuevos; lo de Robux no se compra con monedas; armas solo por nivel
d3.Coins = 5000
mock.invokePlayer = p3
local ok, msg = Remotes.BuyItem.OnServerInvoke(p3, "Pose", "AlCielo")
check(ok and d3.Poses.AlCielo and d3.Coins == 5000 - 900, "pose comprada con monedas (" .. tostring(msg) .. ")")
ok, msg = Remotes.BuyItem.OnServerInvoke(p3, "Card", "Neon")
check(ok and d3.Cards.Neon, "tarjeta comprada con monedas")
ok, msg = Remotes.BuyItem.OnServerInvoke(p3, "MVPIntro", "Giro")
check(ok and d3.MVPIntros.Giro, "intro de MVP comprada con monedas")
ok, msg = Remotes.BuyItem.OnServerInvoke(p3, "Skin", "Ciber")
check(not ok and msg == "Se compra con Robux" and not d3.Skins.Ciber, "lo de Robux no se compra con monedas")
ok, msg = Remotes.BuyItem.OnServerInvoke(p3, "Pose", "AlCielo")
check(not ok and msg == "Ya lo tienes", "ya lo tienes: no cobra otra vez")
ok, msg = Remotes.BuyItem.OnServerInvoke(p3, "Weapon", "Phantom")
check(not ok, "las armas no se compran (" .. tostring(msg) .. ")")
ok = Remotes.BuyItem.OnServerInvoke(p3, "Card", "Default")
check(not ok, "lo básico no se vende")
d3.Coins = 10
ok, msg = Remotes.BuyItem.OnServerInvoke(p3, "Card", "Carbono")
check(not ok and string.find(msg, "Te faltan") ~= nil, "sin monedas suficientes: " .. msg)
-- 12. Ya no se vende: cajas con monedas
d3.Coins = 5000
ok, msg = Remotes.OpenCrate.OnServerInvoke(p3, "Neon", false)
check(not ok and d3.Coins == 5000, "cajas con monedas apagadas (" .. tostring(msg) .. ")")
d3.FreeCrates = 1
ok = Remotes.OpenCrate.OnServerInvoke(p3, "Neon", true)
check(ok, "las cajas ganadas jugando se siguen abriendo")

-- 13. Pase: XP de jugar, reclamar, premium, nivel comprado y misiones
local p4, d4 = join(4)
check(d4.Pass and d4.Pass.Season == "S1" and d4.Pass.XP == 0, "jugador nuevo: pase S1 desde 0")
PlayerData.StartMatch(p4)
p4:SetAttribute("InMenu", false)
PlayerData.AddXP(p4, 1000, "Partida")
check(d4.Pass.XP == 1000 * BP.MatchXPRate, "XP del pase de jugar (su parte, sin multiplicadores de pago)")
p4:SetAttribute("VIP", true)
PlayerData.AddXP(p4, 1000, "Partida")
check(d4.Pass.XP == 2000 * BP.MatchXPRate and d4.Level >= 4, "el VIP dobla la XP de cuenta pero no la del pase")
p4:SetAttribute("VIP", nil)
mock.invokePlayer = p4
ok, msg = Remotes.ClaimPass.OnServerInvoke(p4, 2, "Free")
check(not ok, "no se reclama un nivel no alcanzado (" .. tostring(msg) .. ")")
task.wait(0.3)
local c4 = d4.Coins
ok, msg = Remotes.ClaimPass.OnServerInvoke(p4, 1, "Free")
check(ok and d4.Pass.Free["1"] and d4.Coins == c4 + s1.Tiers[1].Free.Amount, "nivel 1 gratis reclamado")
task.wait(0.3)
ok = Remotes.ClaimPass.OnServerInvoke(p4, 1, "Free")
check(not ok, "no se reclama dos veces")
task.wait(0.3)
ok, msg = Remotes.ClaimPass.OnServerInvoke(p4, 1, "Premium")
check(not ok and msg == "Es del pase premium", "premium sin el pase: no")
check(receipt(4, "pp1", 9004) == Granted and d4.Pass.HasPremium, "pase premium comprado")
check(lastSent("PurchaseGranted")[1].Pass == true, "escena de compra del pase")
check(receipt(4, "pp2", 9004) == Granted and d4.Pass.HasPremium, "premium repetido: compensado en monedas, sin romper nada")
local xp = d4.Pass.XP
check(receipt(4, "ts1", 9005) == Granted and d4.Pass.XP == xp + BP.XPPerTier, "nivel del pase comprado (solo dentro del pase)")
task.wait(0.3)
local before4 = d4.Skins.Sakura
ok, msg = Remotes.ClaimPass.OnServerInvoke(p4, "All")
check(ok and type(msg) == "table" and #msg >= 2 and d4.Skins.Sakura and not before4, "RECLAMAR TODO (incluye la skin premium del nivel 1)")
-- misiones de temporada
for _ = 1, 10 do PlayerData.Track(p4, "Streak", 10) end
check(d4.Pass.Done.S1Streak and d4.Pass.XP >= xp + BP.XPPerTier + 3000, "misión de temporada: +XP del pase")
local summary = PlayerData.MatchSummary(p4)
check(summary.PassXP > 0 and summary.PassNowXP == d4.Pass.XP, "el resumen de la partida trae la XP del pase")
PlayerData.AddWeaponKill(p4, "ARX27"); PlayerData.AddWeaponKill(p4, "ARX27"); PlayerData.AddWeaponKill(p4, "Viper")
summary = PlayerData.MatchSummary(p4)
check(summary.TopWeapon == "ARX27" and summary.TopWeaponKills == 2, "arma con más bajas de la partida (para la oferta de después)")

-- 14. Migración: quien ya jugaba empieza el pase en su nivel; lo ya dado cuenta como reclamado
mock.dsData.u_5 = { Level = 12, XP = 0, Coins = 100, Skins = { Default = true, Sakura = true }, ClaimedFree = { ["1"] = true, ["2"] = true }, ClaimedPremium = { ["1"] = true }, Premium = true }
local p5, d5 = join(5)
check(d5.Pass.XP == BP.XPFor(12) and BP.TierFor(d5.Pass.XP) == 12, "migrado al nivel 12 del pase")
check(d5.Pass.Free["1"] and d5.Pass.Free["2"] and d5.Pass.Premium["1"] and not d5.Pass.Free["3"], "lo que ya le dio el pase antiguo cuenta como reclamado")
check(d5.Pass.HasPremium, "el pase premium antiguo vale en la temporada 1")
-- 15. Cambio de temporada: lo no reclamado se entrega solo
table.insert(BP.Seasons, { Id = "S2", Name = "TEMPORADA 2", Title = "PRUEBA", StartsAt = 4102444800, EndsAt = 4102444800 + 86400 * 60, Premium = { ProductId = 0, Robux = 399 }, Tiers = s1.Tiers, Missions = {} })
s1.EndsAt = os.time() - 1
BP.Seasons[2].StartsAt = os.time() - 1
local BattlePass = req(game.ServerScriptService.Server.Modules.BattlePass)
local c5 = d5.Coins
local leftovers = BattlePass.Ensure(d5)
check(leftovers and #leftovers > 0 and d5.Pass.Season == "S2" and d5.Pass.XP == 0 and not d5.Pass.HasPremium, "temporada nueva: pase a 0 y " .. #(leftovers or {}) .. " recompensas entregadas solas")
check(d5.Coins > c5, "nadie pierde lo que ganó")
s1.EndsAt = 4102444800; table.remove(BP.Seasons, 2)

-- 16. Pack de inicio (con los objetos nuevos) y analítica del cliente con límite
local p6, d6 = join(6)
check(receipt(6, "st1", 9006) == Granted and d6.StarterPack and d6.Charms.Bala and d6.Cards.Tactico and d6.Poses.Bajada and d6.Skins.Sakura and d6.Outfits.BlazeRunner, "pack de inicio: skin, traje, colgante, tarjeta, pose y monedas")
check((Analytics.Counts.starter_pack_purchase or 0) == 1, "analítica: starter_pack_purchase")
local n = Analytics.Counts.store_open or 0
for _ = 1, 40 do Remotes.Track.OnServerEvent:Fire(p6, "store_open", { tab = "ARMAS" }) end
check((Analytics.Counts.store_open or 0) - n == Config.Analytics.ClientPerMinute, "el cliente no puede inundar la analítica")
local successes = Analytics.Counts.purchase_success or 0
Remotes.Track.OnServerEvent:Fire(p6, "purchase_success", { key = "falso" })
check((Analytics.Counts.purchase_success or 0) == successes, "el cliente no puede mandar compras falsas a la analítica")
-- MarkSeen: quita NUEVO
Remotes.MarkSeen.OnServerEvent:Fire(p6, { "Skin:Inferno", "Skin:Sakura", "Starter" })
check(d6.SeenItems["Skin:Inferno"] and not d6.SeenItems["Skin:Sakura"] and d6.StarterSeen, "novedades vistas (solo las que son novedad)")
print("ECONOMIA SERVIDOR OK")
process.exit(0)
