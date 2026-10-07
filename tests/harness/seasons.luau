-- Temporadas de rango: premio al acabar según el mejor rango, RP a la mitad, nuevos sin premio
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Ranks = req(RS.Shared.Ranks)
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
check(Ranks.CurrentSeason(1791590400).Id == "T1" and Ranks.CurrentSeason(1800000000).Id == "T2", "temporada según la fecha")
local function join(id)
	local p = mock.new("Player"); p.Name = "P" .. id; p.UserId = id; p.Parent = Players
	table.insert(mock.players, p)
	Players.PlayerAdded:Fire(p)
	return p, PlayerData.WaitFor(p, 3)
end
-- Nuevo: empieza en la temporada actual sin premio
local _, fresh = join(1)
local current = Ranks.CurrentSeason()
check(fresh.RankSeason == current.Id, "el nuevo empieza en " .. current.Id)
-- Guardado de antes de las temporadas: sin premio ni recorte
mock.dsData.u_2 = { Level = 1, Coins = 100, RankPoints = 300, RankBest = 3 }
local _, old = join(2)
check(old.RankSeason == current.Id and old.RankPoints == 300, "guardado antiguo: sigue igual en la temporada actual")
local baseCoins = old.Coins -- (otros premios de carga, iguales para todos los guardados de este tipo)
-- Viene de una temporada anterior en la que llegó a Oro (3)
mock.dsData.u_3 = { Level = 1, Coins = 100, RankPoints = 300, RankBest = 3, RankSeason = "T0", SeasonBest = 3 }
local p3, prev = join(3)
check(prev.Coins == baseCoins + Ranks.SeasonRewards[3], "premio de fin de temporada por Oro (+" .. Ranks.SeasonRewards[3] .. ")")
check(prev.RankPoints == 150 and prev.RankSeason == current.Id and prev.SeasonBest == 0, "RP a la mitad y temporada nueva (sin jugar aún)")
check(prev.RankBest == 3, "el mejor rango de siempre se conserva")
-- Subir de rango en la temporada actualiza su mejor rango
PlayerData.AddRankPoints(p3, 200)
check(prev.SeasonBest == Ranks.Index(350), "mejor rango de la temporada al subir")
-- Sin jugar ninguna partida de rango en la temporada: RP a la mitad pero sin premio
local d = { Coins = 0, RankPoints = 800, RankSeason = "T0", SeasonBest = 0 }
local text = PlayerData.RollSeason(d)
check(d.Coins == 0 and d.RankPoints == 400 and text ~= nil, "sin jugar esa temporada: sin premio")
-- Cambio con el servidor encendido: el resumen no enseña la bajada del recorte
local data3 = prev
data3.RankSeason = "T0"; data3.SeasonBest = 4; data3.RankPoints = 1000
PlayerData.AddRankPoints(p3, 25)
local summary = PlayerData.MatchSummary(p3)
check(summary.RankPoints - summary.StartRank == 25, "resumen: +25 RP aunque cambió la temporada (" .. summary.StartRank .. " -> " .. summary.RankPoints .. ")")
check(p3:GetAttribute("Rank") == Ranks.Index(data3.RankPoints), "atributo de rango al día")
-- Temporada en el perfil
local view
for _, sent in mock.sent do if sent.Remote == "DataUpdate" then view = sent.Args[1] end end
check(view and view.RankSeasonName == current.Name and view.RankSeasonEndsAt == current.EndsAt, "perfil: " .. tostring(view and view.RankSeasonName))
print("TEMPORADAS OK")
process.exit(0)
