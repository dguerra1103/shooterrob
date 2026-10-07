-- Novedades: un jugador que vuelve las ve una vez; uno nuevo no
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local GameConfig = req(RS.Shared.GameConfig)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 6; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
check(data.NewsSeen == GameConfig.News.Version, "un jugador nuevo no ve las novedades")
data.NewsSeen = 0
data.TutorialDone = true
PlayerData.SendUpdate(me)
local view
for _, sent in mock.sent do
	if sent.Remote == "DataUpdate" then view = sent.Args[1] end
end
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.Data = view
ClientState.InMainMenu = true
local News = req(game.StarterPlayer.Client.Modules.News)
News.Init()
task.wait(3)
local gui = pg:FindFirstChild("News")
check(gui ~= nil, "un jugador que vuelve ve las novedades")
local button
for _, d in gui:GetDescendants() do
	if d.__className == "TextButton" and d.Text == "¡A JUGAR!" then button = d end
end
mock.invokePlayer = me
local Remotes = req(RS.Shared.Remotes)
-- (el botón dispara NewsSeen: lo hacemos llegar al servidor como haría Roblox)
Remotes.NewsSeen.OnServerEvent:Fire(me)
button.Activated:Fire()
check(data.NewsSeen == GameConfig.News.Version and pg:FindFirstChild("News") == nil, "al cerrar se apunta y no vuelve a salir")
print("NOVEDADES OK")
process.exit(0)
