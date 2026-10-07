-- Títulos: ganados por estadísticas, comprados con monedas y el de VIP; atributo para los demás
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Titles = req(RS.Shared.Titles)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local Remotes = req(RS.Shared.Remotes)
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 12; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
for id, t in Titles.List do
	check(t.Name and t.Color and t.Order and (t.Stat == nil or table.find(Titles.Stats, t.Stat)), "título bien definido: " .. id)
end
check(me:GetAttribute("Title") == nil and data.EquippedTitle == "Novato", "empieza como Novato (sin título visible)")
local equip = Remotes.EquipTitle.OnServerEvent
equip:Fire(me, "Tirador")
check(data.EquippedTitle == "Novato", "sin 100 bajas no se puede")
data.TotalKills = 150
equip:Fire(me, "Tirador")
check(data.EquippedTitle == "Tirador" and me:GetAttribute("Title") == "Tirador" and typeof(me:GetAttribute("TitleColor")) == "Color3", "con 150 bajas: Tirador visible para todos")
equip:Fire(me, "Leyenda")
check(data.EquippedTitle == "Tirador", "Leyenda aún no")
data.Coins = 1000
local ok = Remotes.BuyItem.OnServerInvoke(me, "Title", "Payaso")
check(ok == true and data.Titles.Payaso and data.EquippedTitle == "Payaso" and me:GetAttribute("Title") == "Payaso de feria", "comprar un título lo pone")
check(Remotes.BuyItem.OnServerInvoke(me, "Title", "Millonario") == false, "sin monedas no")
check(Remotes.BuyItem.OnServerInvoke(me, "Title", "Tirador") == false, "los de estadísticas no se venden")
equip:Fire(me, "VIP")
check(data.EquippedTitle == "Payaso", "VIP solo para VIP")
me:SetAttribute("VIP", true)
equip:Fire(me, "VIP")
check(me:GetAttribute("Title") == "VIP", "con VIP sí")
me:SetAttribute("VIP", nil)
PlayerData.PublishTitle(me)
check(me:GetAttribute("Title") == nil, "si deja de ser VIP vuelve a Novato")
equip:Fire(me, 123)
equip:Fire(me, "NoExiste")
check(data.EquippedTitle == "VIP", "datos raros ignorados")
check(Titles.Requirement("Cazador") == "1000 bajas" and Titles.Requirement("Campeon") == "rango Campeón", "textos de requisitos")
print("TITULOS OK")
process.exit(0)
