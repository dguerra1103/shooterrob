-- Resultado de una partida: puntos de cada jugador (los mismos en el servidor y en la pantalla final),
-- motivo del final y sus textos. El servidor rellena el MatchResult (ver Round.endRound) y lo manda en
-- RoundEnd; la pantalla de resultados (Flow/Results) solo lo pinta.
--
-- MatchResult = {
--   Mode = "TDM", ModeName = "Duelo por equipos", Map = "Construction", TeamMode = true,
--   TeamA = "Rojo", TeamB = "Azul", ScoreA = 50, ScoreB = 38, Winner = "Rojo" | nil (empate),
--   Reason = "ScoreLimit" (ver Reasons), MVP = "<Id>",
--   Players = { { Id, Name, UserId?, Bot?, Team, Kills, Deaths, Assists, Captures, Points, Weapon, Skin, Level? } },
-- }
-- Id: "u<UserId>" para los jugadores, "b<Nombre>" para los bots
local MatchResults = {}

-- Puntos de la partida: bajas, asistencias y objetivos (capturas de bandera, zonas, bombas)
MatchResults.PointValues = { Kill = 100, Assist = 50, Capture = 250 }

function MatchResults.Points(kills, assists, captures)
	local v = MatchResults.PointValues
	return (tonumber(kills) or 0) * v.Kill + (tonumber(assists) or 0) * v.Assist + (tonumber(captures) or 0) * v.Capture
end

-- Orden del marcador y del MVP: más puntos; a igualdad, más bajas y menos muertes
function MatchResults.Better(a, b)
	if (a.Points or 0) ~= (b.Points or 0) then
		return (a.Points or 0) > (b.Points or 0)
	end
	if (a.Kills or 0) ~= (b.Kills or 0) then
		return (a.Kills or 0) > (b.Kills or 0)
	end
	if (a.Deaths or 0) ~= (b.Deaths or 0) then
		return (a.Deaths or 0) < (b.Deaths or 0)
	end
	return tostring(a.Name) < tostring(b.Name)
end

-- Motivos del final (el texto que va debajo de VICTORIA / DERROTA)
MatchResults.Reasons = {
	ScoreLimit = "LÍMITE DE PUNTOS ALCANZADO",
	Objectives = "OBJETIVOS ASEGURADOS",
	ZoneControl = "ZONA BAJO CONTROL",
	Captures = "BANDERAS CAPTURADAS",
	Eliminated = "EQUIPO ENEMIGO ELIMINADO",
	DecisiveRound = "RONDA DECISIVA GANADA",
	BombDefused = "BOMBA DESACTIVADA",
	BombExploded = "OBJETIVO COMPLETADO",
	Tags = "CALABAZAS RECOGIDAS",
	Survivors = "SUPERVIVIENTES EN PIE",
	Infected = "TODOS INFECTADOS",
	GunGame = "ÚLTIMA ARMA COMPLETADA",
	FFAScore = "LÍMITE DE BAJAS ALCANZADO",
	TimeLimit = "TIEMPO AGOTADO",
	Draw = "EMPATE",
}

-- Motivo según el modo, quién ganó y cómo acabó la última ronda (Eliminación / Buscar y destruir)
-- reachedGoal: el ganador llegó a la meta (si no, se acabó el tiempo)
function MatchResults.ReasonFor(mode, hasWinner, reachedGoal, lastRound)
	if not hasWinner then
		return "Draw"
	end
	if mode == "INF" then
		return reachedGoal and "Infected" or "Survivors"
	end
	if not reachedGoal then
		return "TimeLimit"
	end
	if mode == "SND" then
		if lastRound == "BombDefused" or lastRound == "BombExploded" then
			return lastRound
		end
		return "DecisiveRound"
	elseif mode == "ELIM" then
		return lastRound == "Eliminated" and "Eliminated" or "DecisiveRound"
	elseif mode == "DOM" then
		return "Objectives"
	elseif mode == "KOTH" then
		return "ZoneControl"
	elseif mode == "CTF" then
		return "Captures"
	elseif mode == "CAL" then
		return "Tags"
	elseif mode == "GUN" then
		return "GunGame"
	elseif mode == "FFA" then
		return "FFAScore"
	end
	return "ScoreLimit"
end

function MatchResults.ReasonText(reason)
	return MatchResults.Reasons[reason or ""] or ""
end

return MatchResults
