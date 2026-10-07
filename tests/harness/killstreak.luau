local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local task = mock.taskImpl
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local Shared = game.ReplicatedStorage.Shared
local M = game.ServerScriptService.Server.Modules
local GameConfig = req(Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local Remotes = req(Shared.Remotes)
local Killstreaks = req(M.Killstreaks)
Killstreaks.Init()
local function check(c, m) if not c then error("FALLO: " .. m, 2) end print("ok  " .. m) end
local teams = game:GetService("Teams"):GetChildren()
local function makePlayer(id, team, pos)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = game:GetService("Players"); p.Team = team
	local char = mock.new("Model"); char.Parent = game.Workspace
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.Parent = char
	local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = CFrame.new(pos); root.Size = Vector3.new(2, 2, 1); root.Parent = char
	p.Character = char
	table.insert(mock.players, p)
	return p, hum
end
local a1 = makePlayer(1, teams[1], Vector3.new(0, 3, 0))
local a2 = makePlayer(2, teams[1], Vector3.new(10, 3, 0))
local b1, hb1 = makePlayer(3, teams[2], Vector3.new(0, 3, -60))
game.ReplicatedStorage:SetAttribute("TeamMode", true)
game.ReplicatedStorage:SetAttribute("Mode", "TDM")
game.ReplicatedStorage:SetAttribute("State", "Playing")

Killstreaks.OnStreak(a1, 3)
check((a2:GetAttribute("RadarUntil") or 0) > os.clock(), "radar para el compañero")
check((a1:GetAttribute("RadarUntil") or 0) > os.clock(), "radar para quien lo consigue")
check((b1:GetAttribute("RadarUntil") or 0) == 0, "el enemigo no recibe radar")
Killstreaks.OnStreak(a1, 5)
check(a1:GetAttribute("Airstrikes") == 1, "racha de 5: ataque aéreo listo")

local ev = Remotes.CallAirstrike.OnServerEvent
ev:Fire(b1, Vector3.new(0, 0, 0))
check((b1:GetAttribute("Airstrikes") or 0) == 0, "sin carga no se lanza")
ev:Fire(a1, Vector3.new(0, 0, -5000))
check(a1:GetAttribute("Airstrikes") == 1, "objetivo demasiado lejos rechazado")
ev:Fire(a1, Vector3.new(0 / 0, 0, 0))
check(a1:GetAttribute("Airstrikes") == 1, "objetivo NaN rechazado")
game.ReplicatedStorage:SetAttribute("State", "Intermission")
ev:Fire(a1, Vector3.new(0, 3, -60))
check(a1:GetAttribute("Airstrikes") == 1, "fuera de partida no se lanza")
game.ReplicatedStorage:SetAttribute("State", "Playing")
ev:Fire(a1, Vector3.new(0, -120, -60))
check(a1:GetAttribute("Airstrikes") == 1, "objetivo muy por debajo rechazado")
ev:Fire(a1, Vector3.new(0, 3, -60))
check(a1:GetAttribute("Airstrikes") == 0, "ataque aéreo lanzado (gasta la carga)")
task.wait(2.8)
check(hb1.Health < 100, "las bombas dañan al enemigo (" .. hb1.Health .. ")")
check(hb1:GetAttribute("LastWeapon") == "Airstrike", "baja atribuida al ataque aéreo")

game.ReplicatedStorage:SetAttribute("Mode", "GUN")
Killstreaks.OnStreak(a1, 5)
check(a1:GetAttribute("Airstrikes") == 0, "en Escalada no hay recompensas")
Killstreaks.OnStreak(a1, 5)
game.ReplicatedStorage:SetAttribute("Mode", "TDM")
Killstreaks.OnStreak(a1, 5)
Killstreaks.Reset()
check(a1:GetAttribute("Airstrikes") == 0 and a2:GetAttribute("RadarUntil") == 0, "al empezar ronda se reinician")
-- FFA: el radar es solo para uno
game.ReplicatedStorage:SetAttribute("TeamMode", false)
Killstreaks.OnStreak(a1, 3)
check((a2:GetAttribute("RadarUntil") or 0) == 0, "en FFA el radar es solo tuyo")
-- Racha de un bot: su equipo humano tiene radar y el rival recibe el aviso
game.ReplicatedStorage:SetAttribute("TeamMode", true)
Killstreaks.Reset()
check(Killstreaks.OnBotStreak("Bot Max", teams[2], 2) == false, "bot con 2 bajas: nada")
check(Killstreaks.OnBotStreak("Bot Max", teams[2], 3) == true, "bot con 3 bajas: radar")
check((b1:GetAttribute("RadarUntil") or 0) > 0, "el compañero humano del bot ve el radar")
check((a1:GetAttribute("RadarUntil") or 0) == 0, "el rival no recibe radar")
check((game.ReplicatedStorage:GetAttribute("Radar_" .. teams[2].Name) or 0) > 0, "el minimapa del rival sabe que hay radar enemigo")
Killstreaks.Reset()
check(game.ReplicatedStorage:GetAttribute("Radar_" .. teams[2].Name) == nil, "al empezar ronda se borra el radar de equipo")
game.ReplicatedStorage:SetAttribute("Mode", "GUN")
check(Killstreaks.OnBotStreak("Bot Max", teams[2], 3) == false, "en Escalada los bots tampoco")
game.ReplicatedStorage:SetAttribute("Mode", "TDM")
print("TODO OK")
process.exit(0)
