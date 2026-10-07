-- Ruleta diaria: giro gratis, giros comprados, premio entregado y ruleta que se para en él
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
mock.policyInfo = { ArePaidRandomItemsRestricted = false }
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 5; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
mock.invokePlayer = me
local Remotes = req(RS.Shared.Remotes)
local Shop = req(RS.Shared.Shop)
-- Sin casino: con la ruleta apagada (MonetizationConfig.Rules.Wheel) no se puede girar
local Rules = req(RS.Shared.Economy.MonetizationConfig).Rules
check(Rules.Wheel == false and Rules.PaidWheelSpins == false, "ruleta y giros de pago apagados por defecto")
data.WheelSpins = 2
local offOk, offReason = Remotes.SpinWheel.OnServerInvoke(me)
check(offOk == false and offReason == "No disponible" and data.WheelSpins == 2, "apagada: no gira ni gasta giros")
data.WheelSpins = 0
-- (encendida a mano, como antes: el giro gratis sigue funcionando)
Rules.Wheel = true
-- Servidor
local before = { Coins = data.Coins, Revives = data.Revives, Crates = data.FreeCrates, XP = data.XP, Level = data.Level, BoostXP = data.BoostXP }
local ok, index = Remotes.SpinWheel.OnServerInvoke(me)
check(ok == true and type(index) == "number" and Shop.Wheel.Prizes[index] ~= nil, "giro gratis: premio " .. tostring(index))
local prize = Shop.Wheel.Prizes[index]
local gained = (prize.Kind == "Coins" and data.Coins - before.Coins == prize.Amount) or (prize.Kind == "Revives" and data.Revives - before.Revives == prize.Amount)
	or (prize.Kind == "Crate" and data.FreeCrates - before.Crates == prize.Amount) or (prize.Kind == "XP" and (data.XP ~= before.XP or data.Level ~= before.Level))
	or (prize.Kind == "Boost" and data.BoostXP - before.BoostXP == prize.Amount * 60)
check(gained, "se entrega el premio (" .. Shop.WheelPrizeText(prize) .. ")")
local ok2, reason = Remotes.SpinWheel.OnServerInvoke(me)
check(ok2 == false, "no se puede girar enseguida otra vez (" .. tostring(reason) .. ")")
task.wait(3.1)
local ok3, reason3 = Remotes.SpinWheel.OnServerInvoke(me)
check(ok3 == false and string.find(reason3, "mañana") ~= nil, "sin giros: vuelve mañana")
data.WheelSpins = 2
task.wait(3.1)
check(Remotes.SpinWheel.OnServerInvoke(me) == false and data.WheelSpins == 2, "los giros comprados (azar de pago) no se usan")
Rules.PaidWheelSpins = true
task.wait(3.1)
check(Remotes.SpinWheel.OnServerInvoke(me) == true and data.WheelSpins == 1, "(si se encendieran) gasta un giro comprado")
-- Donde no se permiten premios al azar de pago, los giros comprados no se pueden usar
mock.policyInfo = { ArePaidRandomItemsRestricted = true }
local other = mock.new("Player"); other.Name = "Otro"; other.UserId = 99; other.Parent = Players
table.insert(mock.players, other)
Players.PlayerAdded:Fire(other)
local otherData = PlayerData.WaitFor(other, 3)
otherData.WheelDay = req(RS.Shared.Shop).DayNumber()
otherData.WheelSpins = 3
check(Remotes.SpinWheel.OnServerInvoke(other) == false and otherData.WheelSpins == 3, "giros de pago bloqueados donde no se permiten")
-- Reparto de premios: el gordo es raro
local counts = {}
for _ = 1, 20000 do
	local total, roll = 0, 0
	for _, p in Shop.Wheel.Prizes do total += p.Weight end
	roll = math.random() * total
	for i, p in Shop.Wheel.Prizes do
		roll -= p.Weight
		if roll <= 0 then counts[i] = (counts[i] or 0) + 1 break end
	end
end
check((counts[#Shop.Wheel.Prizes] or 0) < 400, "premio gordo ~1% (" .. tostring(counts[#Shop.Wheel.Prizes]) .. " de 20000)")
-- Cliente
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
data.WheelSpins = 1
PlayerData.SendUpdate(me)
local view
for _, sent in mock.sent do
	if sent.Remote == "DataUpdate" then view = sent.Args[1] end
end
ClientState.Data = view
check(view.WheelSpins == 1 and view.WheelFree == false, "el cliente sabe cuántos giros tiene")
local Wheel = req(game.StarterPlayer.Client.Modules.Wheel)
Wheel.Open()
check(pg.Wheel.Enabled and ClientState.WheelOpen, "se abre la ruleta")
task.wait(3.1)
Wheel.Spin()
local status
for _, d in pg:GetDescendants() do
	if d.__className == "TextLabel" and (string.find(d.Text, "Has ganado", 1, true) or string.find(d.Text, "PREMIO GORDO", 1, true)) then status = d.Text end
end
check(status ~= nil, "la ruleta para y dice el premio (" .. tostring(status) .. ")")
Wheel.Close()
check(not ClientState.WheelOpen, "se cierra")
print("RULETA OK")
process.exit(0)
