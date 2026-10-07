-- "SE BUSCA": racha de 5 marca al jugador; quien lo mata cobra; muere a manos de un bot = se pierde
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local GameConfig = req(RS.Shared.GameConfig)
GameConfig.IntermissionTime = 1
GameConfig.Deploy.LineupTime, GameConfig.Deploy.CountdownTime = 0.2, 0.1
GameConfig.MinPlayers = 1
GameConfig.Modes = { "FFA" }
GameConfig.Modes_FFA_Score = nil
local M = game.ServerScriptService.Server.Modules
req(M.MapBuilder).Build()
local PlayerData = req(M.PlayerData)
PlayerData.Init()
local Round = req(M.Round)
local Bounty = req(M.Bounty)
local Remotes = req(RS.Shared.Remotes)
_ = Remotes
local function notes()
	local list = {}
	for _, src in { mock.sent, mock.broadcast } do
		for _, m in src do
			if m.Remote == "Notify" then table.insert(list, m.Args) end
		end
	end
	return list
end
local function makePlayer(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = game:GetService("Players")
	table.insert(mock.players, p)
	game:GetService("Players").PlayerAdded:Fire(p)
	p:SetAttribute("InMenu", false)
	local char = mock.new("Model"); char.Parent = game.Workspace
	local head = mock.new("Part"); head.Name = "Head"; head.Parent = char
	p.Character = char
	return p, head
end
local a, headA = makePlayer(21)
local b = makePlayer(22)
local c = makePlayer(23)
local d = makePlayer(24)
local e = makePlayer(25)
task.wait(0.2)
Round.Init()
local deadline = os.clock() + 10
while RS:GetAttribute("State") ~= "Playing" and os.clock() < deadline do task.wait(0.1) end
check(RS:GetAttribute("State") == "Playing", "partida en juego")

check(Bounty.Value(4) == 0 and Bounty.Value(5) == 25 and Bounty.Value(7) == 35 and Bounty.Value(99) == 100, "valores de la recompensa")
local bot = { Name = "Bot Max", Team = nil }
for i = 1, 4 do
	Round.RegisterKill(a, nil, "Bot Max", "ARX27", false, nil, nil, bot)
end
check((a:GetAttribute("Bounty") or 0) == 0, "con 4 bajas aún no se le busca")
Round.RegisterKill(a, nil, "Bot Max", "ARX27", false, nil, nil, bot)
check(a:GetAttribute("Bounty") == 25, "racha de 5: SE BUSCA por 25")
check(headA:FindFirstChild("BountyTag") ~= nil, "cartel sobre la cabeza")
check(headA.BountyTag.PlayerToHideFrom == a, "el buscado no ve su propio cartel")
Round.RegisterKill(a, nil, "Bot Max", "ARX27", false, nil, nil, bot)
check(a:GetAttribute("Bounty") == 30, "sube con cada baja (30)")
check(string.find(headA.BountyTag:FindFirstChild("Text", true).Text, "30") ~= nil, "el cartel se actualiza")

local coinsBefore = PlayerData.Get(b).Coins
Round.RegisterKill(b, a, a.Name, "ARX27", false, nil)
local gained = PlayerData.Get(b).Coins - coinsBefore
check(gained == 15 + GameConfig.Coins.Kill, "racha contra bots: la recompensa vale la mitad (+" .. gained .. ")")
check(a:GetAttribute("Bounty") == nil and headA:FindFirstChild("BountyTag") == nil, "al morir se le quita la marca")
local claimed = false
for _, n in notes() do
	if n[1] == "BountyClaimed" then claimed = true end
end
check(claimed, "aviso de recompensa cobrada")

-- Lo mata un bot: se pierde (nadie cobra)
for i = 1, 5 do
	Round.RegisterKill(a, nil, "Bot Max", "ARX27", false, nil, nil, bot)
end
check(a:GetAttribute("Bounty") == 25, "otra vez buscado")
local before = PlayerData.Get(b).Coins
Round.RegisterKill(nil, a, a.Name, "ARX27", false, nil, bot, nil)
check(PlayerData.Get(b).Coins == before and a:GetAttribute("Bounty") == nil, "si lo mata un bot, se pierde")
local function announced(pattern)
	for _, n in notes() do
		if n[1] == "Bounty" and string.find(tostring(n[2]), pattern) then return true end
	end
	return false
end
check(announced("perdido"), "si lo mata un bot se anuncia que se perdió")
for i = 1, 5 do
	Round.RegisterKill(a, nil, "Bot Max", "ARX27", false, nil, nil, bot)
end
Round.RegisterKill(nil, a, a.Name, nil, false, nil)
check(a:GetAttribute("Bounty") == nil and announced("perdido"), "si muere solo, se pierde")
-- Racha con 3 bajas a jugadores: recompensa entera
-- (matar al mismo jugador 3 veces no cuenta como 3 rivales: sigue valiendo la mitad)
for i = 1, 3 do
	Round.RegisterKill(a, c, c.Name, "ARX27", false, nil)
end
check(a:GetAttribute("StreakPlayers") == 1, "el mismo rival cuenta una vez")
Round.RegisterKill(a, d, d.Name, "ARX27", false, nil)
Round.RegisterKill(a, e, e.Name, "ARX27", false, nil)
check(a:GetAttribute("Bounty") == 25, "buscado tras 3 rivales distintos y 2 bajas más")
-- Personaje nuevo sin morir (siguiente ronda de Eliminación): el cartel pasa al nuevo
local char2 = mock.new("Model"); char2.Parent = game.Workspace
local head2 = mock.new("Part"); head2.Name = "Head"; head2.Parent = char2
a.Character = char2
a.CharacterAdded:Fire(char2)
task.wait(0.1)
check(head2:FindFirstChild("BountyTag") ~= nil, "el cartel pasa al personaje nuevo")
local before2 = PlayerData.Get(b).Coins
Round.RegisterKill(b, a, a.Name, "ARX27", false, nil)
check(PlayerData.Get(b).Coins - before2 == 25 + GameConfig.Coins.Kill, "recompensa entera si hubo jugadores en la racha")
-- Nueva ronda: nadie buscado
for i = 1, 5 do
	Round.RegisterKill(a, nil, "Bot Max", "ARX27", false, nil, nil, bot)
end
Bounty.Reset(a)
check(a:GetAttribute("Bounty") == nil and head2:FindFirstChild("BountyTag") == nil, "al reiniciar se quita")
print("SE BUSCA OK")
process.exit(0)
