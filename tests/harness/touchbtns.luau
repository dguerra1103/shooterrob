-- Botones táctiles propios: en el móvil salen todos (Roblox solo creaba 7) y cada uno en su sitio
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
mock.policyInfo = { ArePaidRandomItemsRestricted = false }
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local GameConfig = req(RS.Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = Teams
end
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player"); me.Name = "Jugador"; me.DisplayName = "Jugador"; me.UserId = 3; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
data.TutorialDone = true
data.NewsSeen = GameConfig.News.Version
PlayerData.SendUpdate(me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
me.Team = Teams:GetChildren()[1]
mock.invokePlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(830, 380)
local UIS = game:GetService("UserInputService")
UIS.TouchEnabled = true
UIS.KeyboardEnabled = false
RS:SetAttribute("TeamA", GameConfig.Teams[1].Name); RS:SetAttribute("TeamB", GameConfig.Teams[2].Name); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Playing"); RS:SetAttribute("Mode", "TDM")
req(game.StarterPlayer.Client.Main)
task.wait(2)
local gui = pg:FindFirstChild("TouchButtons")
check(gui ~= nil, "pantalla de botones táctiles propia")
local names = {}
for _, b in gui:GetChildren() do names[b.Name] = b end
for _, n in { "Fire", "Aim", "Reload", "Melee", "SwapWeapon", "Sprint", "Slide", "Grenade", "Emotes", "Scoreboard", "Airstrike", "Spray" } do
	check(names[n] ~= nil, "botón " .. n)
end
local TL = req(game.StarterPlayer.Client.Modules.TouchLayout)
local fire = names.Fire
check(fire.Size.X.Offset == 76 and fire.Position == TL.Phone.Fire[1], "disparar grande y en su sitio del teléfono")
check(names.Scoreboard.Position.Y.Scale == 0 and names.Scoreboard.Position.Y.Offset == 8, "marcador arriba de verdad (no a media pantalla)")
local title = fire:FindFirstChild("ActionTitle")
check(title and title.Text == "🔫", "con su icono")
-- Pulsar el botón llama a la acción (como ContextActionService)
local WeaponController = req(game.StarterPlayer.Client.Modules.WeaponController)
_ = WeaponController
local input = mock.new("InputObject")
input.UserInputType = roblox.Enum.UserInputType.Touch
input.UserInputState = roblox.Enum.UserInputState.Begin
local ok, err = pcall(function() names.Reload.InputBegan:Fire(input) end)
check(ok, "pulsar un botón no da error " .. tostring(err))
print("BOTONES TACTILES OK")
process.exit(0)
