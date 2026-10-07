-- Contorno de enemigos: rojo fino solo en los enemigos (no en compañeros), sin atravesar paredes
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local red = mock.new("Team"); red.Name = "Rojo"; red.Parent = Teams; red.TeamColor = roblox.BrickColor.new("Really red")
local blue = mock.new("Team"); blue.Name = "Azul"; blue.Parent = Teams; blue.TeamColor = roblox.BrickColor.new("Really blue")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players; me.Team = red
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local bots = mock.new("Folder"); bots.Name = "Bots"; bots.Parent = game.Workspace
local function bot(name, team)
	local m = mock.new("Model"); m.Name = name; m:SetAttribute("Bot", true); m:SetAttribute("Team", team)
	local h = mock.new("Humanoid"); h.Health = 100; h.Parent = m
	m.Parent = bots
	return m
end
local mate = bot("Bot Leo", "Rojo")
local enemy = bot("Bot Max", "Azul")
local WorldFX = req(game.StarterPlayer.Client.Modules.WorldFX)
WorldFX.Init()
task.wait(0.3)
local o = enemy:FindFirstChild("EnemyOutline")
check(o ~= nil and o.__className == "Highlight", "el enemigo lleva contorno")
check(o.DepthMode == roblox.Enum.HighlightDepthMode.Occluded, "que no atraviesa paredes")
check(o.FillTransparency == 1 and o.OutlineTransparency > 0.3, "fino: solo el borde, semitransparente")
check(mate:FindFirstChild("EnemyOutline") == nil and mate:FindFirstChild("TeamHighlight") ~= nil, "el compañero no (lleva el de su equipo)")
-- Color elegido en Ajustes (accesibilidad): amarillo
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
ClientState.Settings = ClientState.Settings or table.clone(GameConfig.DefaultSettings)
ClientState.Settings.EnemyColor = 2
WorldFX.Restyle()
check(enemy:FindFirstChild("EnemyOutline").OutlineColor == GameConfig.EnemyColors[2].Color, "con el color elegido en Ajustes (amarillo)")
-- Cambia de bando (Infección): se recalcula
enemy:SetAttribute("Team", "Rojo")
enemy:GetAttributeChangedSignal("Team"):Fire()
task.wait(0.1)
check(enemy:FindFirstChild("EnemyOutline") == nil, "si pasa a tu equipo, se le quita")
print("CONTORNO OK")
process.exit(0)
