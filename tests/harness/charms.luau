-- Colgantes: compra, equipar, piezas en el arma y en el arma en primera persona
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local WeaponModels = req(RS.Shared.WeaponModels)
local Charms = req(RS.Shared.Charms)
for id in Charms.List do
	if id ~= "Default" then
		local model = WeaponModels.Build("ARX27", "Default", nil, id)
		check(model:FindFirstChild("CharmRing") ~= nil, "colgante " .. id .. " en el arma")
	end
end
check(WeaponModels.Build("Knife", "Default", nil, "Dado"):FindFirstChild("CharmRing") == nil, "las armas cuerpo a cuerpo no llevan colgante")
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 8; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
data.Coins = 5000
local Remotes = req(RS.Shared.Remotes)
local ok, msg = Remotes.BuyItem.OnServerInvoke(me, "Charm", "Calabaza")
check(ok and data.Charms.Calabaza and data.EquippedCharm == "Calabaza" and data.Coins == 4500, "comprar un colgante lo equipa (" .. tostring(msg) .. ")")
Remotes.EquipCharm.OnServerEvent:Fire(me, "Diamante")
check(data.EquippedCharm == "Calabaza", "no se equipa uno que no tienes")
Remotes.EquipCharm.OnServerEvent:Fire(me, "Default")
check(data.EquippedCharm == "Default", "se puede quitar")
local Loadout = req(game.ServerScriptService.Server.Modules.Loadout)
local tool = Loadout.MakeTool("ARX27", "Default", "Calabaza")
check(tool:GetAttribute("Charm") == "Calabaza" and tool:FindFirstChild("CharmBody") ~= nil, "la herramienta lleva el colgante")
print("COLGANTES OK")
process.exit(0)
