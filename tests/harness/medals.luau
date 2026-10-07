-- Medallas de baja: Primera sangre, Venganza, Cazarrachas, Larga distancia, Desde la tumba
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
Round.Init()
local deadline = os.clock() + 10
while RS:GetAttribute("State") ~= "Playing" and os.clock() < deadline do task.wait(0.1) end
check(RS:GetAttribute("State") == "Playing", "partida en juego")
local function has(name)
	for _, t in collect() do
		if string.find(t, name, 1, true) then
			return true
		end
	end
	return false
end
-- 1) b mata a a: primera sangre para b
table.clear(mock.sent)
Round.RegisterKill(b, a, a.Name, "ARX27", false, Vector3.new(0, 3, 10))
check(has("PRIMERA SANGRE"), "primera sangre")
check(a:GetAttribute("LastKiller") == b.Name, "se recuerda quién te eliminó")
-- 1b) intercambio (a mata a b en el mismo instante): no es venganza
table.clear(mock.sent)
Round.RegisterKill(a, b, b.Name, "ARX27", false, Vector3.new(0, 3, 10))
check(not has("VENGANZA"), "un intercambio no cuenta como venganza")
-- 2) b vuelve a matar a a; un rato después a mata a b: venganza, sin primera sangre
Round.RegisterKill(b, a, a.Name, "ARX27", false, Vector3.new(0, 3, 10))
task.wait(1.1)
table.clear(mock.sent)
Round.RegisterKill(a, b, b.Name, "ARX27", false, Vector3.new(0, 3, 10))
check(has("VENGANZA") and not has("PRIMERA"), "venganza (y la primera sangre solo una vez)")
-- 3) un bot con racha 3 cae a lo lejos: cazarrachas y larga distancia
table.clear(mock.sent)
Round.RegisterKill(a, nil, "Bot Max", "ARX27", false, Vector3.new(0, 3, 150), nil, { Name = "Bot Max", Streak = 4 })
check(has("CAZARRACHAS"), "cazarrachas")
check(has("LARGA DISTANCIA"), "larga distancia")
-- 4) granada desde lejos no es larga distancia; muerto: desde la tumba
table.clear(mock.sent)
ha.Health = 0
Round.RegisterKill(a, nil, "Bot Leo", "Grenade", false, Vector3.new(0, 3, 150), nil, { Name = "Bot Leo" })
check(has("TUMBA") and not has("LARGA"), "desde la tumba")
ha.Health = 100
table.clear(mock.sent)
Round.RegisterKill(a, nil, "Bot Leo", "ARX27", false, Vector3.new(0, 3, 20), nil, { Name = "Bot Leo" })
check(#collect() == 0, "baja normal sin medallas")
print("MEDALLAS OK")
process.exit(0)
