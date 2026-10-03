-- Maestría de armas: las bajas con cada arma desbloquean camuflajes exclusivos para ESA arma
-- (y monedas). Los camuflajes son skins con Mastery = true (ver Skins.luau): no se venden ni salen en cajas.
local Mastery = {}

Mastery.Tiers = {
	{ Kills = 25, Camo = "MaestriaCarbono", Name = "Carbono", Coins = 100 },
	{ Kills = 75, Camo = "MaestriaOro", Name = "Oro", Coins = 250 },
	{ Kills = 150, Camo = "MaestriaDiamante", Name = "Diamante", Coins = 500 },
	{ Kills = 300, Camo = "MaestriaOscura", Name = "Materia oscura", Coins = 1000 },
}

-- Nivel de maestría alcanzado (0 = ninguno)
function Mastery.Level(kills)
	local level = 0
	for i, tier in Mastery.Tiers do
		if (kills or 0) >= tier.Kills then
			level = i
		end
	end
	return level
end

-- Siguiente nivel por conseguir (nil si ya tiene todos)
function Mastery.Next(kills)
	return Mastery.Tiers[Mastery.Level(kills) + 1]
end

-- ¿Tiene desbloqueado este camuflaje con esas bajas?
function Mastery.HasCamo(kills, camoId)
	for i, tier in Mastery.Tiers do
		if tier.Camo == camoId then
			return Mastery.Level(kills) >= i
		end
	end
	return false
end

return Mastery
