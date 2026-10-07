-- Mapa destacado del día: rota, se publica y da más XP mientras se juega en él
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local GameConfig = req(RS.Shared.GameConfig)
local M = game.ServerScriptService.Server.Modules
local MapBuilder = req(M.MapBuilder)
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local a, b = MapBuilder.FeaturedId(100), MapBuilder.FeaturedId(101)
check(a and b and a ~= b, "cambia cada día (" .. tostring(a) .. " -> " .. tostring(b) .. ")")
check(not MapBuilder.Defs[MapBuilder.FeaturedId(5)].Season, "nunca uno de temporada")
local featured = RS:GetAttribute("FeaturedMap")
check(type(featured) == "string", "se publica: " .. tostring(featured))
local p = mock.new("Player"); p.Name = "P"; p.DisplayName = "P"; p.UserId = 1; p.Parent = Players
table.insert(mock.players, p)
Players.PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
local function gain()
	local l, x = data.Level, data.XP
	PlayerData.AddXP(p, 100, "Prueba")
	return (data.Level - l) * GameConfig.XPPerLevel + data.XP - x
end
RS:SetAttribute("State", "Playing")
RS:SetAttribute("MapName", "Otro mapa")
local normal = gain()
RS:SetAttribute("MapName", featured)
local bonus = gain()
print("XP normal / destacado:", normal, bonus)
check(bonus == math.floor(normal * GameConfig.FeaturedMap.XPBonus), "+25% en el mapa destacado")
RS:SetAttribute("State", "Intermission")
check(gain() == normal, "fuera de partida no cuenta")
print("MAPA DESTACADO OK")
process.exit(0)
