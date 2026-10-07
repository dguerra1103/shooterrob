-- Retos semanales: 3 por semana, progreso, premio, caja por completarlos todos y cambio de semana
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Challenges = req(RS.Shared.Challenges)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 9; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
-- Semanas: el lunes empieza una nueva
check(Challenges.WeekNumber(3) == 0 and Challenges.WeekNumber(4) == 1 and Challenges.WeekNumber(10) == 1 and Challenges.WeekNumber(11) == 2, "las semanas empiezan en lunes")
check(Challenges.WeekEndsAt(1) == 11 * 86400, "fin de semana calculado")
PlayerData.Track(me, "Match", 1)
local weekly = data.WeeklyChallenges
check(type(weekly) == "table" and #weekly.List == Challenges.WeeklyCount, "3 retos semanales")
local seen = {}
for _, e in weekly.List do
	check(Challenges.Get(e.Id) ~= nil and not seen[e.Id], "reto semanal válido " .. e.Id)
	seen[e.Id] = true
end
-- Se fijan tres conocidos para probar
weekly.List = { { Id = "W_Kills", Progress = 0, Done = false }, { Id = "W_Streak", Progress = 0, Done = false }, { Id = "W_Melee", Progress = 0, Done = false } }
local coins, crates = data.Coins, data.FreeCrates
for _ = 1, 99 do PlayerData.Track(me, "Kill", 1, "ARX27") end
check(not weekly.List[1].Done and weekly.List[1].Progress == 99, "99/100 bajas")
PlayerData.Track(me, "Kill", 1, "ARX27")
check(weekly.List[1].Done and data.Coins >= coins + 800, "100 bajas: completado y cobrado")
for _ = 1, 9 do PlayerData.Track(me, "Kill", 1, "Knife") end
check(weekly.List[3].Progress == 9 and not weekly.List[3].Done, "cuerpo a cuerpo cuenta solo con esas armas")
PlayerData.Track(me, "Streak", 7)
PlayerData.Track(me, "Streak", 4)
check(weekly.List[2].Progress == 7, "la racha guarda la mejor")
check(data.FreeCrates == crates, "sin caja hasta completar los 3")
PlayerData.Track(me, "Kill", 1, "Katana")
PlayerData.Track(me, "Streak", 10)
check(weekly.Bonus == true and data.FreeCrates == crates + Challenges.WeeklyBonusCrates, "los 3 completados: " .. Challenges.WeeklyBonusCrates .. " cajas")
-- La vista del cliente
local view
for _, m in mock.sent do
	if m.Remote == "DataUpdate" then view = m.Args[1] end
end
check(view and view.Challenges and view.Challenges.Weekly and #view.Challenges.Weekly.List == 3 and view.Challenges.Weekly.Bonus == true, "el cliente ve los semanales")
check(view.Challenges.Weekly.EndsAt > os.time(), "con cuenta atrás")
-- Semana nueva
weekly.Week -= 1
PlayerData.Track(me, "Match", 1)
check(data.WeeklyChallenges.Week == Challenges.WeekNumber(math.floor(os.time() / 86400)) and not data.WeeklyChallenges.Bonus, "otra semana: retos nuevos")
print("SEMANALES OK")
process.exit(0)
