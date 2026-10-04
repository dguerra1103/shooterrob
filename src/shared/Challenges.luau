-- Retos diarios: cada jugador recibe 3 al día (distintos para cada uno). Se completan solos al jugar
-- y dan monedas + XP al momento. Completar los 3 regala una caja. Se puede cambiar 1 reto al día.
-- Retos semanales (WeeklyPool): 3 más largos por semana (de lunes a domingo, hora UTC) con premios
-- grandes; completar los 3 regala WeeklyBonusCrates cajas.
--
-- Stat: "Kill" (con Weapons opcional para limitar a ciertas armas), "Headshot", "Win", "Match",
-- "Capture", "ZoneTime" (segundos en la zona), "Streak" (mejor racha, no se suma), "Survive" (ganar una
-- Infección como superviviente), "Pumpkin" (recoger una calabaza enemiga en el modo Calabazas).
local Challenges = {}

Challenges.PerDay = 3
Challenges.RerollsPerDay = 1
Challenges.BonusCrates = 1 -- por completar todos los del día

Challenges.Pool = {
	{ Id = "Kills", Stat = "Kill", Goal = 15, Text = "Consigue 15 bajas", Coins = 150, XP = 300 },
	{ Id = "Headshots", Stat = "Headshot", Goal = 5, Text = "Haz 5 bajas a la cabeza", Coins = 200, XP = 300 },
	{ Id = "Wins", Stat = "Win", Goal = 2, Text = "Gana 2 partidas", Coins = 250, XP = 400 },
	{ Id = "Matches", Stat = "Match", Goal = 3, Text = "Termina 3 partidas", Coins = 150, XP = 300 },
	{ Id = "Captures", Stat = "Capture", Goal = 2, Text = "Captura 2 banderas", Coins = 250, XP = 400 },
	{ Id = "Zone", Stat = "ZoneTime", Goal = 60, Text = "Controla la zona 60 segundos", Coins = 200, XP = 300 },
	{ Id = "Streak", Stat = "Streak", Goal = 5, Text = "Consigue una racha de 5 bajas", Coins = 300, XP = 400 },
	{ Id = "Rifles", Stat = "Kill", Weapons = { "ARX27", "VortexBR", "TitanLMG", "SplatX" }, Goal = 12, Text = "12 bajas con fusil, ametralladora o paintball", Coins = 200, XP = 300 },
	{ Id = "SMGs", Stat = "Kill", Weapons = { "Specter9", "NovaDrift" }, Goal = 10, Text = "10 bajas con subfusil", Coins = 200, XP = 300 },
	{ Id = "Shotguns", Stat = "Kill", Weapons = { "HavocPump", "BreachHammer" }, Goal = 6, Text = "6 bajas con escopeta", Coins = 200, XP = 300 },
	{ Id = "Snipers", Stat = "Kill", Weapons = { "Signal7", "GhostlineXR", "RaptorDMR" }, Goal = 4, Text = "4 bajas con francotirador o DMR", Coins = 250, XP = 350, MinLevel = 3 },
	{ Id = "Pistols", Stat = "Kill", Weapons = { "Viper", "HandCannon", "PhantomSidewind" }, Goal = 4, Text = "4 bajas con pistola", Coins = 200, XP = 300 },
	{ Id = "Knife", Stat = "Kill", Weapons = { "Knife", "ToyHammer", "Katana", "Scythe" }, Goal = 2, Text = "2 bajas cuerpo a cuerpo", Coins = 300, XP = 400 },
	{ Id = "Grenades", Stat = "Kill", Weapons = { "Grenade" }, Goal = 3, Text = "3 bajas con granada", Coins = 250, XP = 350 },
	{ Id = "Rockets", Stat = "Kill", Weapons = { "NovaLauncher", "Calabazooka" }, Goal = 3, Text = "3 bajas con lanzacohetes", Coins = 250, XP = 350, MinLevel = 14 },
	-- Modo Infección (Halloween)
	{ Id = "Infect", Stat = "Kill", Weapons = { "Claws" }, Goal = 3, Text = "Infecta a 3 supervivientes (Infección)", Coins = 250, XP = 350 },
	{ Id = "Survive", Stat = "Survive", Goal = 1, Text = "Sobrevive hasta el final de una Infección", Coins = 300, XP = 400 },
	{ Id = "Pumpkins", Stat = "Pumpkin", Goal = 8, Text = "Recoge 8 calabazas enemigas (modo Calabazas)", Coins = 250, XP = 350 },
}

Challenges.WeeklyCount = 3
Challenges.WeeklyBonusCrates = 2
Challenges.WeeklyPool = {
	{ Id = "W_Kills", Stat = "Kill", Goal = 100, Text = "Consigue 100 bajas", Coins = 800, XP = 1500 },
	{ Id = "W_Wins", Stat = "Win", Goal = 10, Text = "Gana 10 partidas", Coins = 1000, XP = 2000 },
	{ Id = "W_Headshots", Stat = "Headshot", Goal = 30, Text = "Haz 30 bajas a la cabeza", Coins = 900, XP = 1500 },
	{ Id = "W_Matches", Stat = "Match", Goal = 15, Text = "Termina 15 partidas", Coins = 700, XP = 1500 },
	{ Id = "W_Captures", Stat = "Capture", Goal = 8, Text = "Captura 8 banderas", Coins = 900, XP = 1500 },
	{ Id = "W_Zone", Stat = "ZoneTime", Goal = 400, Text = "Controla la zona 400 segundos", Coins = 800, XP = 1500 },
	{ Id = "W_Streak", Stat = "Streak", Goal = 10, Text = "Consigue una racha de 10 bajas", Coins = 1000, XP = 2000 },
	{ Id = "W_Melee", Stat = "Kill", Weapons = { "Knife", "ToyHammer", "Katana", "Scythe" }, Goal = 10, Text = "10 bajas cuerpo a cuerpo", Coins = 900, XP = 1500 },
	{ Id = "W_Snipers", Stat = "Kill", Weapons = { "Signal7", "GhostlineXR", "RaptorDMR" }, Goal = 25, Text = "25 bajas con francotirador o DMR", Coins = 900, XP = 1500, MinLevel = 3 },
	{ Id = "W_Grenades", Stat = "Kill", Weapons = { "Grenade" }, Goal = 12, Text = "12 bajas con granada", Coins = 900, XP = 1500 },
}

local byId = {}
for _, c in Challenges.Pool do
	byId[c.Id] = c
end
for _, c in Challenges.WeeklyPool do
	byId[c.Id] = c
end

-- Semana (empieza el lunes a las 00:00 UTC) de un número de día (Shop.DayNumber) y cuándo acaba
function Challenges.WeekNumber(day)
	return (day + 3) // 7
end
function Challenges.WeekEndsAt(week)
	return ((week + 1) * 7 - 3) * 86400
end

function Challenges.Get(id)
	return byId[id]
end

-- ¿Cuenta este evento para el reto?
function Challenges.Matches(challenge, stat, weaponName)
	if challenge.Stat ~= stat then
		return false
	end
	if challenge.Weapons then
		return weaponName ~= nil and table.find(challenge.Weapons, weaponName) ~= nil
	end
	return true
end

-- Elige `count` retos distintos (sin repetir los de `exclude`). Determinista por día y jugador.
-- `source` es la lista de la que se eligen (por defecto los diarios).
function Challenges.Pick(day, userId, level, count, exclude, salt, source)
	local rng = Random.new(day * 7919 + userId * 31 + (salt or 0))
	local pool = {}
	for _, c in source or Challenges.Pool do
		if (c.MinLevel or 1) <= (level or 1) and not (exclude and exclude[c.Id]) then
			table.insert(pool, c.Id)
		end
	end
	local picked = {}
	for _ = 1, math.min(count, #pool) do
		local i = rng:NextInteger(1, #pool)
		table.insert(picked, table.remove(pool, i))
	end
	return picked
end

return Challenges
