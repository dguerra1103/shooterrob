-- Rangos competitivos: puntos de rango (RP) que suben al ganar partidas y bajan un poco al perder.
-- Nunca se baja de rango (al perder, como mínimo te quedas en el inicio del tuyo).
-- Se ven en el marcador, en el chat, en el menú y en el resumen de cada partida.
-- Llegar a un rango por primera vez da su premio (Reward: monedas y cajas gratis).
local Ranks = {}

local Icons = require(script.Parent.Icons)

local RGB = Color3.fromRGB

Ranks.Tiers = {
	{ Name = "Bronce", Min = 0, Icon = "🥉", Image = Icons.RankBronze, Color = RGB(215, 140, 70) },
	{ Name = "Plata", Min = 100, Icon = "🥈", Image = Icons.RankSilver, Color = RGB(205, 210, 225), Reward = { Coins = 200 } },
	{ Name = "Oro", Min = 250, Icon = "🥇", Image = Icons.RankGold, Color = RGB(255, 200, 60), Reward = { Coins = 300, Crates = 1 } },
	{ Name = "Platino", Min = 450, Icon = "💠", Image = Icons.RankPlatinum, Color = RGB(90, 225, 210), Reward = { Coins = 500 } },
	{ Name = "Diamante", Min = 700, Icon = "💎", Image = Icons.RankDiamond, Color = RGB(110, 170, 255), Reward = { Coins = 750, Crates = 2 } },
	{ Name = "Campeón", Min = 1000, Icon = "👑", Image = Icons.RankChampion, Color = RGB(255, 90, 200), Reward = { Coins = 1500, Crates = 3 } },
}

-- Puntos por partida
Ranks.Points = {
	Win = 25,
	Loss = -12, -- por equipos
	FFALoss = -5, -- todos contra todos (solo gana uno)
	MVP = 5, -- extra para el MVP, gane o pierda
	BotWin = 8, -- partida solo contra bots (menos de 2 jugadores de verdad): sube poco y no baja
}

-- Temporadas (fechas de fin en hora UTC): al acabar una, cada jugador recibe SeasonRewards según el
-- mejor rango que alcanzó en ella, y sus RP bajan a SeasonCarry (la mitad) para la siguiente. Los
-- premios de llegar a un rango por primera vez (Reward) son de una vez para siempre.
Ranks.Seasons = {
	{ Id = "T1", Name = "Temporada 1", EndsAt = 1798761600 }, -- 1 ene 2027
	{ Id = "T2", Name = "Temporada 2", EndsAt = 1806537600 }, -- 1 abr 2027
	{ Id = "T3", Name = "Temporada 3", EndsAt = 1814400000 }, -- 1 jul 2027
	{ Id = "T4", Name = "Temporada 4", EndsAt = 1822348800 }, -- 1 oct 2027
	{ Id = "T5", Name = "Temporada 5", EndsAt = 1830297600 }, -- 1 ene 2028
	{ Id = "T6", Name = "Temporada 6", EndsAt = 1838160000 }, -- 1 abr 2028
	{ Id = "T7", Name = "Temporada 7", EndsAt = 1846022400 }, -- 1 jul 2028
	{ Id = "T8", Name = "Temporada 8", EndsAt = 1853971200 }, -- 1 oct 2028
	-- (añade más antes de que acabe la última; después de ella ya no cambia de temporada)
}
Ranks.SeasonRewards = { 100, 250, 500, 800, 1200, 2000 } -- monedas por el mejor rango (Bronce..Campeón)
Ranks.SeasonCarry = 0.5

-- La temporada en curso (si ya pasaron todas, la última)
function Ranks.CurrentSeason(now)
	now = now or os.time()
	for _, season in ipairs(Ranks.Seasons) do
		if now < season.EndsAt then
			return season
		end
	end
	return Ranks.Seasons[#Ranks.Seasons]
end

function Ranks.SeasonName(id)
	for _, season in Ranks.Seasons do
		if season.Id == id then
			return season.Name
		end
	end
	return "Temporada"
end

-- Índice del rango (1 = Bronce)
function Ranks.Index(points)
	local index = 1
	for i, tier in Ranks.Tiers do
		if (points or 0) >= tier.Min then
			index = i
		end
	end
	return index
end

function Ranks.Get(points)
	return Ranks.Tiers[Ranks.Index(points)]
end

-- Progreso hacia el siguiente rango: fracción 0..1 y el siguiente rango (nil si ya es el máximo)
function Ranks.Progress(points)
	points = points or 0
	local index = Ranks.Index(points)
	local tier, nextTier = Ranks.Tiers[index], Ranks.Tiers[index + 1]
	if not nextTier then
		return 1, nil
	end
	return math.clamp((points - tier.Min) / (nextTier.Min - tier.Min), 0, 1), nextTier
end

-- Cambio de puntos de una partida. result: "Win", "Loss" o "Draw"
function Ranks.Delta(result, ffa, botsOnly, mvp)
	local points = Ranks.Points
	if botsOnly then
		return result == "Win" and points.BotWin or 0
	end
	local delta = 0
	if result == "Win" then
		delta = points.Win
	elseif result == "Loss" then
		delta = ffa and points.FFALoss or points.Loss
	end
	if mvp then
		delta += points.MVP
	end
	return delta
end

-- Aplica el cambio sin bajar nunca del inicio del rango actual
function Ranks.Apply(points, delta)
	points = points or 0
	local floor = Ranks.Get(points).Min
	return math.max(floor, points + delta)
end

return Ranks
