-- Rangos competitivos: puntos de rango (RP) que suben al ganar partidas y bajan un poco al perder.
-- Nunca se baja de rango (al perder, como mínimo te quedas en el inicio del tuyo).
-- Se ven en el marcador, en el chat, en el menú y en el resumen de cada partida.
-- Llegar a un rango por primera vez da su premio (Reward: monedas y cajas gratis).
local Ranks = {}

local RGB = Color3.fromRGB

Ranks.Tiers = {
	{ Name = "Bronce", Min = 0, Icon = "🥉", Color = RGB(215, 140, 70) },
	{ Name = "Plata", Min = 100, Icon = "🥈", Color = RGB(205, 210, 225), Reward = { Coins = 200 } },
	{ Name = "Oro", Min = 250, Icon = "🥇", Color = RGB(255, 200, 60), Reward = { Coins = 300, Crates = 1 } },
	{ Name = "Platino", Min = 450, Icon = "💠", Color = RGB(90, 225, 210), Reward = { Coins = 500 } },
	{ Name = "Diamante", Min = 700, Icon = "💎", Color = RGB(110, 170, 255), Reward = { Coins = 750, Crates = 2 } },
	{ Name = "Campeón", Min = 1000, Icon = "👑", Color = RGB(255, 90, 200), Reward = { Coins = 1500, Crates = 3 } },
}

-- Puntos por partida
Ranks.Points = {
	Win = 25,
	Loss = -12, -- por equipos
	FFALoss = -5, -- todos contra todos (solo gana uno)
	MVP = 5, -- extra para el MVP, gane o pierda
	BotWin = 8, -- partida solo contra bots (menos de 2 jugadores de verdad): sube poco y no baja
}

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
