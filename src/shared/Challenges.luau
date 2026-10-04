-- Retos diarios: cada jugador recibe 3 al día (distintos para cada uno). Se completan solos al jugar
-- y dan monedas + XP al momento. Completar los 3 regala una caja. Se puede cambiar 1 reto al día.
--
-- Stat: "Kill" (con Weapons opcional para limitar a ciertas armas), "Headshot", "Win", "Match",
-- "Capture", "ZoneTime" (segundos en la zona), "Streak" (mejor racha, no se suma), "Survive" (ganar una
-- Infección como superviviente).
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
	{ Id = "Knife", Stat = "Kill", Weapons = { "Knife", "ToyHammer", "Katana" }, Goal = 2, Text = "2 bajas cuerpo a cuerpo", Coins = 300, XP = 400 },
	{ Id = "Grenades", Stat = "Kill", Weapons = { "Grenade" }, Goal = 3, Text = "3 bajas con granada", Coins = 250, XP = 350 },
	{ Id = "Rockets", Stat = "Kill", Weapons = { "NovaLauncher" }, Goal = 3, Text = "3 bajas con el Tempest Core", Coins = 250, XP = 350, MinLevel = 14 },
	-- Modo Infección (Halloween)
	{ Id = "Infect", Stat = "Kill", Weapons = { "Claws" }, Goal = 3, Text = "Infecta a 3 supervivientes (Infección)", Coins = 250, XP = 350 },
	{ Id = "Survive", Stat = "Survive", Goal = 1, Text = "Sobrevive hasta el final de una Infección", Coins = 300, XP = 400 },
}

local byId = {}
for _, c in Challenges.Pool do
	byId[c.Id] = c
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
function Challenges.Pick(day, userId, level, count, exclude, salt)
	local rng = Random.new(day * 7919 + userId * 31 + (salt or 0))
	local pool = {}
	for _, c in Challenges.Pool do
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
