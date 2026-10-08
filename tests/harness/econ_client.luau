-- Economía (cliente): tienda, previsualización 3D, compra con Robux (y cancelarla), compra con
-- monedas con confirmación, escena de compra y EQUIPAR AHORA, packs parciales, tienda sin
-- productos, pase de batalla, puntos rojos, oferta de después de la partida, PC y móvil.
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "client-test"
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MS = game:GetService("MarketplaceService")
local phoneMode = process.args[2] == "phone"
-- RenderStepped con desconexión de verdad
local conns = {}
local stepped = {}
function stepped:Connect(fn)
	local c = { Connected = true }
	function c.Disconnect() c.Connected = false end
	c.Fn = fn
	table.insert(conns, c)
	return c
end
rawget(RunService, "__props").RenderStepped = stepped
local errors = {}
task.spawn(function()
	while true do
		for _, c in table.clone(conns) do
			if c.Connected then
				local ok, err = pcall(c.Fn, 0.05)
				if not ok then table.insert(errors, tostring(err)) end
			end
		end
		task.wait(0.05)
	end
end)
-- Servidor
local BP = req(RS.Shared.Economy.BattlePassConfig)
BP.Get("S1").StartsAt, BP.Get("S1").EndsAt = 0, 4102444800
local Products = req(RS.Shared.Economy.Products)
local Shop = req(RS.Shared.Shop)
Products.Items["Skin:Inferno"].ProductId = 7001
local red = req(RS.Shared.Economy.StoreRotation).BundleById("RedOps")
red.ProductId = 7002
BP.Get("S1").Premium.ProductId = 7003
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId = "Yo", "Yo", 1
me.Parent = Players
table.insert(mock.players, me)
me:SetAttribute("InMenu", true)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
data.Coins = 3000
data.Skins.OperacionRoja = true -- (tiene uno del pack Operación Roja)
data.Pass.XP = 3 * BP.XPPerTier -- nivel 4 del pase, nada reclamado
mock.invokePlayer = me
local Remotes = req(RS.Shared.Remotes)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = phoneMode and roblox.Vector2.new(844, 390) or roblox.Vector2.new(1280, 720)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local function sync()
	PlayerData.SendUpdate(me)
	for i = #mock.sent, 1, -1 do
		if mock.sent[i].Remote == "DataUpdate" then
			ClientState.Data = mock.sent[i].Args[1]
			break
		end
	end
	ClientState.DataChanged:Fire()
	task.wait(0.05)
end
sync()
local function visible(inst)
	while inst and inst ~= pg do
		if inst.Visible == false or inst.Enabled == false then return false end
		inst = inst.Parent
	end
	return inst == pg
end
local function find(root, pred)
	for _, d in root:GetDescendants() do
		if pred(d) then return d end
	end
	return nil
end
local function textOf(button)
	local label = button and button:FindFirstChild("Label", true)
	return label and label.Text or ""
end
local function lastServer(name)
	for i = #mock.serverSent, 1, -1 do
		if mock.serverSent[i].Remote == name then return mock.serverSent[i].Args end
	end
	return nil
end
local function lastClient(name)
	for i = #mock.sent, 1, -1 do
		if mock.sent[i].Remote == name then return mock.sent[i].Args end
	end
	return nil
end

local MainMenu = req(game.StarterPlayer.Client.Modules.MainMenu)
local ok, err = pcall(MainMenu.Init)
check(ok, "MainMenu.Init sin errores " .. tostring(err))
local Flow = MainMenu.Flow
check(Flow.Screens.Store and Flow.Screens.Pass, "pantallas TIENDA y PASE creadas")
local Store = Flow.Screens.Store
local StoreScreen = Store.Screen
local ItemCard = req(game.StarterPlayer.Client.Modules.Flow.Store.ItemCard)

-- Lobby: TIENDA abre la tienda nueva; puntos rojos reales
local Home = Flow.Screens.Home
local shopButton = find(pg, function(d) return d.Name == "Menu_Shop" end)
local passButton = find(pg, function(d) return d.Name == "Menu_Pass" end)
Home.Refresh()
check(shopButton:FindFirstChild("Dot") and shopButton.Dot.Visible, "punto rojo en TIENDA: hay novedades sin ver")
check(passButton:FindFirstChild("Dot") and passButton.Dot.Visible, "punto rojo en PASE: hay recompensas sin reclamar")
check(not find(pg, function(d) return d.Name == "Wheel" and d.__className == "TextButton" and visible(d) end), "sin ruleta en el lobby")
shopButton.Activated:Fire()
task.wait(0.1)
check(Flow.State == "Store" and StoreScreen.Visible, "TIENDA abre la pantalla de la tienda")
check(lastServer("Track") and lastServer("Track")[1] == "store_open", "analítica: store_open")
-- DESTACADO: evento / pack de la semana, tienda diaria con reloj real
local content = StoreScreen.Content
local timer = find(content, function(d) return d.Name == "Timer" and string.find(d.Text, "NUEVA EN", 1, true) ~= nil end)
check(timer ~= nil, "tienda diaria con su reloj (" .. tostring(timer and timer.Text) .. ")")
local StoreData = req(game.StarterPlayer.Client.Modules.Flow.Store.StoreData)
local Rotation = req(RS.Shared.Economy.StoreRotation)
check(timer.Text == "NUEVA EN " .. StoreData.FormatTime(Rotation.DayEndsAt(StoreData.Now()) - StoreData.Now()), "el reloj cuenta hasta la medianoche UTC de verdad")
local dailyCards = 0
for _, d in content:GetDescendants() do
	if d.Name:match("^Item_") and d.Parent and d.Parent.Name == "Grid" then dailyCards += 1 end
end
check(dailyCards >= 6, "objetos en DESTACADO (" .. dailyCards .. ")")
-- Todas las pestañas sin errores
local size = phoneMode and ItemCard.Size.PHONE or ItemCard.Size.DESKTOP
for _, id in { "ARMAS", "OPERADORES", "CHARMS", "EFECTOS", "EMOTES", "BUNDLES", "COINS", "FEATURED" } do
	local okTab, errTab = pcall(Store.SelectTab, id)
	check(okTab, "pestaña " .. id .. " " .. tostring(errTab))
	local grid = find(content, function(d) return d.__className == "UIGridLayout" end)
	if grid and id ~= "COINS" then
		check(grid.CellSize.X.Offset == size.X, id .. ": tarjetas del tamaño de " .. (phoneMode and "móvil" or "PC"))
	end
end

-- Compra con Robux: ventana nativa de Roblox, y CANCELAR la deja como estaba
Store.SelectTab("ARMAS")
local infernoCard = find(content, function(d) return d.Name == "Item_Skin:Inferno" end)
check(infernoCard and textOf(infernoCard.Action) == "COMPRAR", "Inferno: COMPRAR")
check(find(infernoCard, function(d) return d.Name == "Price" and d.Text == "R$ 179" end), "precio en Robux a la vista")
check(find(infernoCard, function(d) return d.Name == "Tag" and find(d, function(t) return t.Text == "NUEVO" end) end), "etiqueta NUEVO")
infernoCard.Action.Activated:Fire()
task.wait(0.05)
check(mock.prompts[#mock.prompts] and mock.prompts[#mock.prompts].Id == 7001, "ventana de compra de Roblox con su producto")
check(textOf(infernoCard.Action) == "PROCESANDO…", "mientras está abierta: PROCESANDO (sin doble compra)")
infernoCard.Action.Activated:Fire()
check(#mock.prompts == 1, "no se abre otra ventana con una compra en curso")
MS.PromptProductPurchaseFinished:Fire(1, 7001, false)
task.wait(0.05)
check(textOf(infernoCard.Action) == "COMPRAR" and not data.Skins.Inferno, "cancelada: vuelve a COMPRAR y no se da nada")
check(lastServer("Track")[1] == "purchase_cancel", "analítica: purchase_cancel")
-- Compra correcta: la entrega el servidor al llegar el recibo → escena de compra → EQUIPAR AHORA
infernoCard.Action.Activated:Fire()
MS.PromptProductPurchaseFinished:Fire(1, 7001, true)
local decision = MS.ProcessReceipt({ PlayerId = 1, PurchaseId = "c1", ProductId = 7001 })
check(decision == roblox.Enum.ProductPurchaseDecision.PurchaseGranted and data.Skins.Inferno, "el servidor entrega la skin")
local Reveal = req(game.StarterPlayer.Client.Modules.Flow.Store.Reveal)
Reveal.Show(lastClient("PurchaseGranted")[1])
sync()
task.wait(1.2)
local revealGui = pg:FindFirstChild("PurchaseReveal")
local revealFrame = revealGui and find(revealGui, function(d) return d.Name == "Reveal" end)
check(revealFrame and find(revealFrame, function(d) return d.Name == "Title" and d.Text == "COMPRA COMPLETADA" end), "COMPRA COMPLETADA")
check(find(revealFrame, function(d) return d.Name == "ItemName" and d.Text == "INFERNO" end) and find(revealFrame, function(d) return d.Name == "RarityStamp" end), "nombre y rareza")
check(game:GetService("Lighting"):FindFirstChild("RevealBlur"), "legendario: desenfoque detrás")
check(find(revealFrame, function(d) return d.Name == "Extras" and string.find(d.Text, "PRIMER GOLPE", 1, true) end), "bonus de primera compra en una línea")
local equip = find(revealFrame, function(d) return d.Name == "Equip" end)
check(equip and textOf(equip) == "EQUIPAR AHORA", "EQUIPAR AHORA")
equip.Activated:Fire()
local args = lastServer("EquipCosmetic")
check(args and args[1] == "Skin" and args[2] == "Inferno", "pide al servidor equipar")
Remotes.EquipCosmetic.OnServerEvent:Fire(me, args[1], args[2])
check(textOf(equip) == "EQUIPADO ✓" and data.EquippedSkin == "Inferno", "EQUIPADO ✓ (y equipada en el servidor)")
Reveal.Close()
sync()
check(textOf(infernoCard.Action) == "EQUIPADO ✓", "la tarjeta de la tienda dice EQUIPADO ✓ (nunca otra vez COMPRAR)")

-- Compra con monedas: confirmación de dos pasos
Store.SelectTab("EMOTES")
local poseCard = find(content, function(d) return d.Name == "Item_Pose:AlCielo" end)
check(poseCard and find(poseCard, function(d) return d.Name == "Price" and d.Text == "🪙 900" end), "pose con su precio en monedas")
poseCard.Action.Activated:Fire()
local confirm = find(pg, function(d) return d.Name == "Confirm" end)
check(confirm and find(confirm, function(d) return d.Name == "Balance" and string.find(d.Text, "te quedarán 2100", 1, true) end), "confirmación con lo que te queda")
check(not data.Poses.AlCielo, "abrir la confirmación no compra nada")
find(confirm, function(d) return d.Name == "Cancel" end).Activated:Fire()
check(not find(pg, function(d) return d.Name == "Confirm" end) and not data.Poses.AlCielo, "CANCELAR: no compra")
poseCard.Action.Activated:Fire()
find(pg, function(d) return d.Name == "Accept" end).Activated:Fire()
task.wait(0.1)
check(data.Poses.AlCielo and data.Coins == 2100, "CONFIRMAR: comprada con monedas en el servidor")
local granted = lastClient("PurchaseGranted")[1]
check(granted.Type == "CoinItem" and granted.Items[1].Id == "AlCielo", "escena de compra también con monedas")
-- Sin dinero suficiente
data.Coins = 100
sync()
Store.SelectTab("CHARMS")
local neon = find(content, function(d) return d.Name == "Item_Card:Neon" end)
neon.Action.Activated:Fire()
local box = find(pg, function(d) return d.Name == "Confirm" end)
check(box and not find(box, function(d) return d.Name == "Accept" end) and find(box, function(d) return d.Name == "GetCoins" end), "sin monedas: no deja confirmar, ofrece MONEDAS")
find(box, function(d) return d.Name == "Cancel" end).Activated:Fire()

-- Pack parcial: lo que ya tienes y lo que vale por separado (cuentas reales)
Store.SelectTab("BUNDLES")
local redCard = find(content, function(d) return d.Name == "Bundle_RedOps" end)
local value = redCard and find(redCard, function(d) return d.Name == "Value" end)
check(value and string.find(value.Text, "R$ 625", 1, true) and string.find(value.Text, "-36%", 1, true), "por separado R$ 625 (-36 %): " .. tostring(value and value.Text))
check(string.find(value.Text, "Ya tienes 1 de 5", 1, true) and string.find(value.Text, "1790", 1, true), "parcial: ya tienes 1 de 5 y se devuelven 1790 🪙")
check(find(redCard, function(d) return d.Name == "B_Skin:OperacionRoja" and d:FindFirstChild("Owned") end), "lo que ya tienes sale como ✓ TUYO")
-- Tienda sin productos (todos a 0): PRÓXIMAMENTE, sin ventanas de compra
local artico = find(content, function(d) return d.Name == "Bundle_Artico" end)
check(artico and textOf(artico.Buy.Action) == "PRÓXIMAMENTE", "producto sin id: PRÓXIMAMENTE")
local prompts = #mock.prompts
artico.Buy.Action.Activated:Fire()
check(#mock.prompts == prompts, "sin id no se abre ninguna compra")
Store.SelectTab("COINS")
check(find(content, function(d) return d.Name == "Product_Puñado" end), "monedas: packs listados (PRÓXIMAMENTE hasta poner sus ids)")

-- Previsualización 3D de todos los tipos
local Inspect = req(game.StarterPlayer.Client.Modules.Flow.Store.Inspect)
local Catalog = req(RS.Shared.Economy.CosmeticCatalog)
for _, key in { "Skin:Ciber", "Outfit:OperacionRoja", "Charm:Bala", "Card:Oro", "KillEffect:Pixel", "MVPIntro:Columna", "Pose:Senala", "Spray:Corona", "Title:Payaso" } do
	local kind, id = Catalog.ParseKey(key)
	local okOpen, errOpen = pcall(Store.Preview, Catalog.Item(kind, id))
	check(okOpen and Inspect.IsOpen(), "previsualizar " .. key .. " " .. tostring(errOpen))
	task.wait(0.1)
end
Store.Preview(Catalog.Item("Skin", "Ciber"), { Weapon = "ARX27" })
local overlay = find(pg, function(d) return d.Name == "Inspect" end)
local vp = find(overlay, function(d) return d.Name == "InspectViewport" end)
local cam = vp.CurrentCamera
task.wait(0.9)
local before = cam.CFrame.Position
Inspect.Zoom(0.7)
check((cam.CFrame.Position - before).Magnitude > 0.01, "zoom acerca la cámara")
local p1 = cam.CFrame.Position
Inspect.Turn(0.8, 0.1)
check((cam.CFrame.Position - p1).Magnitude > 0.01, "arrastrar gira el arma")
check(find(overlay, function(d) return d.Name == "WeaponName" end), "cambiar de arma para ver la skin")
check(find(overlay, function(d) return d.__className == "TextLabel" and string.find(d.Text, "Solo estética", 1, true) end), "dice que es solo estética")
Inspect.Close()
check(not Inspect.IsOpen(), "se cierra")
-- Esc en la vista previa cierra solo la vista previa (no saca de la tienda)
Store.Preview(Catalog.Item("Skin", "Ciber"))
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Fire({ KeyCode = roblox.Enum.KeyCode.Escape, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
task.wait(0.05)
check(not Inspect.IsOpen() and Flow.State == "Store", "Esc cierra la vista previa y sigues en la tienda")
-- Escena de compra de un potenciador (sin objeto): su icono y su nombre, no "+0 monedas"
Reveal.Show({ Type = "Booster", Key = "XP2", Title = "XP DOBLE · 30 MIN", Icon = "⚡", Items = {}, Coins = 0, Compensation = 0 })
task.wait(0.8)
local boosterFrame = find(pg.PurchaseReveal, function(d) return d.Name == "Reveal" end)
check(boosterFrame and find(boosterFrame, function(d) return d.Name == "ItemName" and d.Text == "XP DOBLE · 30 MIN" end), "escena de compra de un potenciador")
Reveal.Close()

-- Pase de batalla
Flow.SetState("Pass")
local Pass = Flow.Screens.Pass
local passScreen = Pass.Screen
check(passScreen.Visible and lastServer("Track")[1] == "battlepass_open", "PASE abre su pantalla (battlepass_open)")
local claimAll = find(passScreen, function(d) return d.Name == "ClaimAll" end)
-- (niveles 1-4 gratis; el 4 no trae nada en la vía gratis: 3 de verdad)
check(string.find(textOf(claimAll), "RECLAMAR TODO (3)", 1, true), "RECLAMAR TODO con lo que hay de verdad: " .. textOf(claimAll))
local cell = find(passScreen, function(d) return d.Name == "Free" and d.Parent and d.Parent.Name == "Tier_2" end)
check(cell and find(cell, function(d) return d.Name == "ClaimTag" end), "nivel 2 gratis: RECLAMAR")
local premiumCell = find(passScreen, function(d) return d.Name == "Premium" and d.Parent and d.Parent.Name == "Tier_1" end)
check(find(premiumCell, function(d) return d.Name == "Shade" end), "premium sin el pase: con candado")
local coinsBefore = data.Coins
cell.Activated:Fire()
task.wait(0.4)
check(data.Pass.Free["2"] and data.Skins.Toxico and data.Coins == coinsBefore, "tocar la casilla la reclama en el servidor (skin Tóxico)")
sync()
task.wait(0.3)
claimAll = find(passScreen, function(d) return d.Name == "ClaimAll" end)
claimAll.Activated:Fire()
task.wait(0.5)
check(data.Pass.Free["1"] and data.Pass.Free["3"] and not data.Pass.Free["4"], "RECLAMAR TODO")
check(find(passScreen, function(d) return d.Name == "Slide" end), "lo reclamado entra deslizándose")
local premiumButton = find(passScreen, function(d) return d.Name == "Premium" and d.Parent == passScreen end)
premiumButton.Activated:Fire()
check(mock.prompts[#mock.prompts].Id == 7003, "premium: ventana de compra de Roblox")
MS.PromptProductPurchaseFinished:Fire(1, 7003, false)
local skip = find(passScreen, function(d) return d.Name == "TierSkip" end)
check(skip and string.find(textOf(skip), "PRÓXIMAMENTE", 1, true), "+1 nivel: PRÓXIMAMENTE hasta poner su id")
sync()
Home.Refresh()
check(not (passButton:FindFirstChild("Dot") and passButton.Dot.Visible), "sin nada por reclamar: sin punto rojo en PASE")
-- NUEVO: al verlas, dejan de ser nuevas
local seen = lastServer("MarkSeen")
check(seen and #seen[1] > 0, "manda al servidor lo que ya ha visto")
Remotes.MarkSeen.OnServerEvent:Fire(me, seen[1])

-- Oferta de después de la partida: solo de vez en cuando y por lo que hiciste
local Data = req(game.StarterPlayer.Client.Modules.Flow.Results.Data)
local Config = req(RS.Shared.Economy.MonetizationConfig)
local owns = function(kind, id) return Catalog.Owns(data, kind, id) end
local items = Catalog.StoreItems({ "Skin" })
local offer = Data.PostMatchOffer({ Matches = 8, TopWeapon = "ARX27", TopWeaponKills = 9 }, Config.PostMatchOffer, items, owns)
check(offer and offer.Weapon == "ARX27" and not owns("Skin", offer.Item.Id), "oferta: skin que no tienes para el arma con la que dominaste")
check(Data.PostMatchOffer({ Matches = 9, TopWeapon = "ARX27", TopWeaponKills = 9 }, Config.PostMatchOffer, items, owns) == nil, "no en todas las partidas")
check(Data.PostMatchOffer({ Matches = 8, TopWeapon = "ARX27", TopWeaponKills = 2 }, Config.PostMatchOffer, items, owns) == nil, "no si no destacaste con el arma")
check(Data.PostMatchOffer({ Matches = 0, TopWeapon = "ARX27", TopWeaponKills = 20 }, Config.PostMatchOffer, items, owns) == nil, "no a los recién llegados")
local rewards = Data.Rewards({ XP = 900, Coins = 40, PassXP = 900, PassStartXP = 2000, PassNowXP = 2900, PassXPPerTier = 2500, PassTiers = 50 })
check(rewards[3] and rewards[3].Kind == "Pass" and rewards[3].TierUp and string.find(rewards[3].Label, "NIVEL 2", 1, true), "recompensas de la partida: XP del pase y subida de nivel")

-- (Fase 11) Un revelado abierto (y otro en cola) no pasa a la partida: al entrar en juego se cierra todo
Reveal.Show(lastClient("PurchaseGranted")[1])
Reveal.Show({ Type = "Booster", Key = "XP2", Title = "XP DOBLE · 30 MIN", Icon = "⚡", Items = {}, Coins = 0, Compensation = 0 })
sync()
task.wait(0.4)
check(ClientState.RevealOpen == true, "revelado abierto (con otro en cola)")
if Flow.State == "Gameplay" then Flow.SetState("Home") end
Flow.EnterGameplay()
task.wait(0.5)
check(ClientState.RevealOpen == false and find(pg.PurchaseReveal, function(d) return d.Name == "Reveal" end) == nil,
	"al entrar en partida no queda ningún revelado (ni el de la cola)")
check(game:GetService("Lighting"):FindFirstChild("RevealBlur") == nil, "ni su desenfoque")

task.wait(0.3)
check(#errors == 0, "sin errores por fotograma (" .. tostring(errors[1]) .. ")")
print("ECONOMIA CLIENTE OK" .. (phoneMode and " (MÓVIL)" or ""))
process.exit(0)
