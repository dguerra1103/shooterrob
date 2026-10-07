-- Podio de la pantalla final: los 3 mejores (jugadores y bots)
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local GameConfig = req(RS.Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.MinPlayers = 1
GameConfig.Modes = { "TDM" }
GameConfig.ModeSettings.TDM.ScoreToWin = 3
GameConfig.Bots.Enabled = false
local M = game.ServerScriptService.Server.Modules
req(M.MapBuilder).Build()
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Remotes = req(RS.Shared.Remotes)
local Round = req(M.Round)
local medals = setmetatable({}, { __index = {} })
local function collect()
	local list = {}
	for _, m in mock.sent do
		if m.Remote == "Notify" and m.Args[1] == "Medal" then
			table.insert(list, m.Args[2])
		end
	end
	return list
end
local function mk(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	local char = mock.new("Model"); char.Parent = game.Workspace
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(0, 3, 0); root.Parent = char
	p.Character = char
	return p, hum, root
end
local a, ha, ra = mk(21)
local b, hb, rb = mk(22)
-- Estadísticas de bots (como las deja Bots en ReplicatedStorage.BotStats)
local bs = mock.new("Folder"); bs.Name = "BotStats"; bs.Parent = RS
local function botEntry(name, kills, deaths)
	local e = mock.new("Folder"); e.Name = name; e:SetAttribute("Kills", kills); e:SetAttribute("Deaths", deaths); e:SetAttribute("Team", "Azul"); e.Parent = bs
end
botEntry("Bot Max", 2, 1)
botEntry("Bot Leo", 2, 0)
botEntry("Bot Ana", 0, 5)
Round.Init()
local deadline = os.clock() + 10
while RS:GetAttribute("State") ~= "Playing" and os.clock() < deadline do task.wait(0.1) end
check(RS:GetAttribute("State") == "Playing", "partida en juego")
a.Team = game:GetService("Teams"):GetChildren()[1]
b.Team = game:GetService("Teams"):GetChildren()[2]
for _ = 1, 3 do
	Round.RegisterKill(a, b, b.Name, "ARX27", false, Vector3.new(0, 3, 10))
end
deadline = os.clock() + 10
local info
while not info and os.clock() < deadline do
	for _, m in mock.broadcast do
		if m.Remote == "RoundEnd" then info = m.Args[1] end
	end
	task.wait(0.1)
end
check(info ~= nil, "fin de partida enviado")
check(type(info.Top) == "table" and #info.Top == 3, "podio de 3")
check(info.Top[1].Name == tostring(a.DisplayName) and info.Top[1].Kills == 3, "1.º el que más bajas tiene (" .. tostring(info.Top[1].Name) .. ")")
check(info.Top[2].Name == "Bot Leo" and info.Top[2].Bot, "2.º bot con 2 bajas y menos muertes")
check(info.Top[3].Name == "Bot Max", "3.º")
print("PODIO OK")
process.exit(0)
