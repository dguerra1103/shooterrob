-- Pase de batalla por temporadas: vía GRATIS y vía PREMIUM, 50 niveles. Se sube con XP del pase,
-- que sale de jugar (la XP de cada partida, sin multiplicadores de pago), de las misiones diarias y
-- semanales y de las misiones de temporada. Las recompensas se RECLAMAN en la pantalla del pase
-- (punto rojo solo si hay algo por reclamar de verdad). Todo es estética o monedas: el pase no da
-- cajas (el azar no se puede comprar subiendo niveles) ni nada que dé ventaja.
--
-- Temporada nueva: añade otra entrada a Seasons con fechas que no se pisen. Al cambiar de
-- temporada lo que quedó sin reclamar de la anterior se entrega solo (nadie pierde lo que ganó).
local Shared = script.Parent.Parent
local GameConfig = require(Shared.GameConfig)

local BattlePassConfig = {}

BattlePassConfig.Tiers = 50
BattlePassConfig.XPPerTier = 3000
-- Parte de la XP de cada partida que va al pase. Con 0,5 y 3000 por nivel: jugando mucho (6 partidas
-- al día y todas las misiones) se acaba en unas 3 semanas; jugando poco (2 partidas y una misión), en
-- unos 2 meses. La temporada dura 3: se puede acabar sin jugar cada día. Ver ECONOMY.md.
BattlePassConfig.MatchXPRate = 0.5
-- XP del pase extra por completar misiones (además de la XP que ya dan)
BattlePassConfig.DailyMissionXP = 600
BattlePassConfig.WeeklyMissionXP = 2500

-- Temporada 1 = el pase que ya había (las recompensas por nivel de siempre), ahora con su propia XP.
-- Las cajas de la vía gratis pasan a ser objetos y monedas.
local function seasonOneTiers()
	local replaced = {
		[20] = { Type = "Coins", Amount = 300 },
		[25] = { Type = "Card", Id = "ZonaRoja" },
		[30] = { Type = "Coins", Amount = 400 },
		[35] = { Type = "Pose", Id = "AlCielo" },
		[40] = { Type = "Coins", Amount = 500 },
		[45] = { Type = "MVPIntro", Id = "Giro" },
		[50] = { Type = "Coins", Amount = 1500 },
	}
	local tiers = {}
	for tier = 1, BattlePassConfig.Tiers do
		local old = GameConfig.BattlePass[tier] or {}
		local free = old.Free
		if replaced[tier] or (free and free.Type == "Crate") then
			free = replaced[tier] or { Type = "Coins", Amount = 200 }
		end
		local premium = old.Premium
		if premium and premium.Type == "Crate" then
			premium = { Type = "Coins", Amount = 300 }
		end
		tiers[tier] = { Free = free, Premium = premium }
	end
	return tiers
end

BattlePassConfig.Seasons = {
	{
		Id = "S1",
		Name = "TEMPORADA 1",
		Title = "ZONA ROJA",
		StartsAt = 1790812800, -- 1 oct 2026 00:00 UTC
		EndsAt = 1798761600, -- 1 ene 2027 00:00 UTC
		Premium = { ProductId = 0, Robux = 399 }, -- TODO: SET IN CREATOR DASHBOARD
		-- Quien compró el pase premium antiguo (Game Pass GameConfig.PremiumPassId) lo tiene en esta temporada
		LegacyPremium = true,
		-- Los que ya jugaban empiezan con la XP de su nivel (el pase de antes iba por nivel)
		MigrateFromLevel = true,
		Tiers = seasonOneTiers(),
		Missions = {
			{ Id = "S1Kills", Text = "Consigue 300 bajas", Stat = "Kill", Goal = 300, XP = 5000 },
			{ Id = "S1Wins", Text = "Gana 25 partidas", Stat = "Win", Goal = 25, XP = 5000 },
			{ Id = "S1Heads", Text = "Haz 100 disparos a la cabeza", Stat = "Headshot", Goal = 100, XP = 4000 },
			{ Id = "S1Matches", Text = "Juega 50 partidas", Stat = "Match", Goal = 50, XP = 4000 },
			{ Id = "S1Caps", Text = "Captura 30 objetivos", Stat = "Capture", Goal = 30, XP = 3000 },
			{ Id = "S1Streak", Text = "Consigue una racha de 10 bajas", Stat = "Streak", Goal = 10, XP = 3000 },
		},
	},
}

-- Temporada en curso (nil entre temporadas)
function BattlePassConfig.Current(now)
	now = now or os.time()
	for _, season in BattlePassConfig.Seasons do
		if now >= season.StartsAt and now < season.EndsAt then
			return season
		end
	end
	return nil
end

function BattlePassConfig.Get(id)
	for _, season in BattlePassConfig.Seasons do
		if season.Id == id then
			return season
		end
	end
	return nil
end

-- Nivel alcanzado con esa XP (el 1 desde el principio)
function BattlePassConfig.TierFor(xp)
	return math.clamp(math.floor((tonumber(xp) or 0) / BattlePassConfig.XPPerTier) + 1, 1, BattlePassConfig.Tiers)
end

-- XP total que hace falta para llegar a un nivel
function BattlePassConfig.XPFor(tier)
	return (math.clamp(tier, 1, BattlePassConfig.Tiers) - 1) * BattlePassConfig.XPPerTier
end

function BattlePassConfig.MaxXP()
	return BattlePassConfig.XPFor(BattlePassConfig.Tiers)
end

return BattlePassConfig
