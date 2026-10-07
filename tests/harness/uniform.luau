-- Uniforme militar para quien no lleva traje en los mapas realistas (y su avatar si lo prefiere)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local blue = mock.new("Team"); blue.Name = "Azul"; blue.TeamColor = roblox.BrickColor.new("Really blue"); blue.Parent = Teams
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local Loadout = req(game.ServerScriptService.Server.Modules.Loadout)
local p = mock.new("Player"); p.Name = "P1"; p.UserId = 1; p.Parent = Players; p.Team = blue
table.insert(mock.players, p)
Players.PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
local map = mock.new("Folder"); map.Name = "Map"; map.Parent = game.Workspace
check(Loadout.UniformFor(p, data) == nil, "en un mapa no realista, nada")
map:SetAttribute("Realistic", true)
local uniform = Loadout.UniformFor(p, data)
check(uniform ~= nil and uniform.Id == "Soldier", "en un mapa realista y sin traje: uniforme militar")
check(uniform.Glow == blue.TeamColor.Color, "con el color de su equipo en el brazalete")
data.Settings = data.Settings or {}
data.Settings.Uniform = 0
check(Loadout.UniformFor(p, data) == nil, "si prefiere su avatar (Ajustes), nada")
print("UNIFORME OK")
process.exit(0)
