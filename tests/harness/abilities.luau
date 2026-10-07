local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
GameConfig.Abilities.Potion.Duration = 0.3
GameConfig.Abilities.Potion.Cooldown = 1
local Remotes = req(Shared.Remotes)
local Abilities = req(game.ServerScriptService.Server.Modules.Abilities)
Abilities.Init()
local function check(c, m) if not c then error("FALLO: " .. m, 2) end print("ok  " .. m) end
local p = mock.new("Player"); p.Name = "P"; p.UserId = 9; p.Parent = game:GetService("Players")
local char = mock.new("Model"); local hum = mock.new("Humanoid"); hum.Health = 30; hum.MaxHealth = 100; hum.Parent = char
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = char
p.Character = char
check(Remotes.UsePotion.OnServerInvoke(p) == true, "poción aceptada")
check(Remotes.UsePotion.OnServerInvoke(p) == false, "en recarga: rechazada")
task.wait(0.45)
check(math.abs(hum.Health - 80) < 0.01, "cura 50 en total")
task.wait(0.7)
hum.Health = 95
check(Remotes.UsePotion.OnServerInvoke(p) == true, "tras la recarga vuelve a funcionar")
task.wait(0.45)
check(hum.Health == 100, "no pasa de la vida máxima")
task.wait(1.1)
p:SetAttribute("InMenu", true)
check(Remotes.UsePotion.OnServerInvoke(p) == false, "en el menú no se usa")
p:SetAttribute("InMenu", false)
hum.Health = 0
check(Remotes.UsePotion.OnServerInvoke(p) == false, "muerto no se usa")
print("TODO OK")
process.exit(0)
