-- Configuración general del juego. Cambia aquí los valores para ajustar el balance.
local GameConfig = {}

-- Nombre que aparece en la pantalla de inicio y en los carteles del mapa
GameConfig.GameTitle = "SHOOTER NEW"
-- Estilo de los mapas: "Cartoon" (colores vivos, plástico liso, sombras suaves, como los shooters más
-- jugados de Roblox) o "Realista" (piedra, yeso, ladrillo y luz más dura)
GameConfig.VisualStyle = "Cartoon"

-- Equipos
GameConfig.Teams = {
	{ Name = "Rojo", Color = BrickColor.new("Really red") },
	{ Name = "Azul", Color = BrickColor.new("Really blue") },
}

-- Rondas
GameConfig.MinPlayers = 1 -- súbelo a 2+ cuando publiques el juego
GameConfig.IntermissionTime = 20

-- Modos de juego. En cada descanso se votan 3 combinaciones de mapa + modo entre estos.
-- Quita alguno de la lista si no lo quieres.
GameConfig.Modes = { "TDM", "CTF", "KOTH", "FFA", "GUN", "ELIM", "INF", "CAL" }
GameConfig.ModeSettings = {
	TDM = { Name = "Duelo por equipos", ScoreToWin = 40, RoundTime = 8 * 60, Teams = true }, -- puntos = bajas
	CTF = { Name = "Captura la bandera", ScoreToWin = 3, RoundTime = 10 * 60, Teams = true }, -- puntos = capturas
	KOTH = { Name = "Zona de control", ScoreToWin = 150, RoundTime = 10 * 60, Teams = true }, -- 1 punto/seg en la zona
	FFA = { Name = "Todos contra todos", ScoreToWin = 25, RoundTime = 8 * 60, Teams = false }, -- bajas individuales
	GUN = { Name = "Escalada de armas", ScoreToWin = 0, RoundTime = 10 * 60, Teams = false }, -- 0 = una baja por arma
	-- Eliminación: rondas cortas de UNA vida; gana la ronda el equipo que deje al otro sin nadie en pie
	ELIM = { Name = "Eliminación", ScoreToWin = 5, RoundTime = 10 * 60, Teams = true, SubRoundTime = 75, PrepTime = 4 },
	-- Infección (Halloween): todos empiezan como supervivientes (equipo A) y tras PrepTime uno de cada
	-- ZombieRatio se convierte en zombi (equipo B: garras, más vida y algo más rápidos). Quien cae ante
	-- los zombis se convierte en zombi. Ganan los supervivientes si queda alguno al acabar el tiempo.
	INF = { Name = "Infección", ScoreToWin = 1, RoundTime = 150, Teams = true, PrepTime = 12, ZombieHealth = 200, ZombieRatio = 5 },
	-- Calabazas (como "Kill Confirmed"): quien cae suelta una calabaza; un punto si la recoge el equipo
	-- contrario, y si la recoge un compañero del caído la baja no cuenta
	CAL = { Name = "Calabazas", ScoreToWin = 30, RoundTime = 8 * 60, Teams = true },
}
GameConfig.VoteTime = 15 -- segundos de votación (dentro del descanso)

-- Captura la bandera
GameConfig.Flag = {
	PickupRadius = 5, -- distancia para coger/devolver la bandera
	CaptureRadius = 7, -- distancia a tu base para capturar
	AutoReturnTime = 20, -- segundos que tarda en volver sola si nadie la toca
	CarrierSpeedMultiplier = 0.9, -- el portador va un poco más lento
}
GameConfig.EndScreenTime = 8
GameConfig.RespawnTime = 3
GameConfig.RespawnNowDelay = 1 -- "Regenerar ahora" se puede pulsar a partir de este segundo
GameConfig.StartingRevives = 3 -- revivir instantáneos con los que empieza un jugador nuevo
GameConfig.ReviveShieldTime = 2 -- segundos de escudo al revivir

-- Habilidades (iconos abajo en el centro): Impulso (E), Supersalto (Z) y Poción (X)
GameConfig.Abilities = {
	Dash = { Cooldown = 6, Speed = 78, Duration = 0.2 },
	Jump = { Cooldown = 10, Power = 82, Forward = 22 },
	Potion = { Cooldown = 25, Heal = 50, Duration = 2.5 },
}
-- Bots: rellenan la partida cuando hay pocos jugadores (se quitan solos al entrar gente)
GameConfig.Bots = {
	Enabled = true,
	FillTo = 6, -- jugadores + bots hasta este número
	Weapons = { "ARX27", "Specter9", "VortexBR", "NovaDrift", "SplatX" },
	Range = 140,
	Accuracy = 0.55, -- probabilidad de acertar a corta distancia
	AccuracyFalloff = 0.004, -- se resta por cada stud de distancia
	DamageScale = 0.55, -- los bots hacen menos daño que un jugador
	Reaction = 0.5, -- segundos antes de empezar a disparar a un objetivo nuevo
	MaxFireRate = 6, -- disparos por segundo como máximo
	WalkSpeed = 16,
	JumpChance = 0.2, -- probabilidad de saltar en cada cambio de dirección mientras pelea
	RewardScale = 0.5, -- XP y monedas por matar un bot (respecto a un jugador)
	-- Puntería y daño contra cada jugador según su rango (Bronce, Plata, Oro, Platino, Diamante,
	-- Campeón): con los novatos son más blandos y con los mejores aprietan más
	SkillByRank = { 0.75, 0.85, 1, 1.1, 1.2, 1.3 },
	OutfitChance = 0.6, -- probabilidad de que un bot lleve uno de los trajes de la tienda (y la mitad, skin de arma)
}
-- Eventos de temporada: durante las rondas aparecen objetos del evento por el mapa (caramelos en
-- Halloween, regalos en Navidad); cada uno da monedas y suma al contador del evento; hay premios
-- por el camino (Milestones; si ya tenías el traje, se cambia por Compensate monedas) y al llegar a
-- Goal se gana la skin exclusiva RewardSkin.
-- Se elige solo el evento cuyas fechas (StartsAt/EndsAt, hora UTC) incluyen el día de hoy; fuera de
-- fechas no hay evento. Para otro año cambia el Id (empieza de cero) y las fechas.
GameConfig.Events = {
	{
		Enabled = true,
		Id = "Halloween2026",
		Name = "Halloween",
		Icon = "🎃",
		Item = "caramelo",
		Items = "caramelos",
		ItemIcon = "🍬",
		ItemShape = "Ball",
		ItemColors = { Color3.fromRGB(255, 130, 20), Color3.fromRGB(170, 80, 255), Color3.fromRGB(120, 230, 60), Color3.fromRGB(255, 70, 120) },
		Decoration = "Pumpkin", -- calabazas en los mapas
		CandyCoins = 5, -- monedas por objeto
		Goal = 100,
		RewardSkin = "Embrujada",
		Milestones = {
			{ Count = 25, Coins = 150 },
			{ Count = 50, Outfit = "Calabaza", Compensate = 400 },
			{ Count = 75, Weapon = "Calabazooka", Compensate = 300 },
		},
		SpawnEvery = 12, -- segundos entre objetos
		MaxCandies = 6, -- a la vez en el mapa
		EndsAt = 1793750400, -- 4 nov 2026, 00:00 UTC
	},
	{
		Enabled = true,
		Id = "Navidad2026",
		Name = "Navidad",
		Icon = "🎄",
		Item = "regalo",
		Items = "regalos",
		ItemIcon = "🎁",
		ItemShape = "Block",
		ItemColors = { Color3.fromRGB(230, 40, 50), Color3.fromRGB(40, 170, 80), Color3.fromRGB(255, 200, 60), Color3.fromRGB(80, 160, 255) },
		Decoration = "Snowman", -- muñecos de nieve en los mapas
		CandyCoins = 5,
		Goal = 100,
		RewardSkin = "Navidena",
		Milestones = {
			{ Count = 25, Coins = 150 },
			{ Count = 50, Outfit = "PapaNoel", Compensate = 400 },
			{ Count = 75, Coins = 500 },
		},
		SpawnEvery = 12,
		MaxCandies = 6,
		StartsAt = 1796083200, -- 1 dic 2026, 00:00 UTC
		EndsAt = 1799366400, -- 8 ene 2027, 00:00 UTC
		-- Novedades propias del evento (salen solas al empezar; Version mayor que la de GameConfig.News)
		News = {
			Version = 3,
			Title = "🎄 ¡LLEGA LA NAVIDAD!",
			Items = {
				{ "🎁", "Evento de Navidad: recoge los regalos que aparecen por el mapa" },
				{ "🎅", "Traje de Papá Noel a los 50 regalos y skin Navideña a los 100" },
				{ "🏘", "Mapa de temporada: Villa Navideña, con su árbol gigante y pista de patinaje" },
				{ "☃️", "En la tienda: efecto Ventisca, bastón de caramelo y grafiti HO HO HO" },
				{ "🛍", "Pack de Navidad por tiempo limitado" },
			},
		},
	},
}

-- ¿Está en marcha este evento a esta hora?
function GameConfig.EventActive(event, now)
	now = now or os.time()
	return event ~= nil and event.Enabled == true and (event.StartsAt == nil or now >= event.StartsAt) and (event.EndsAt == nil or now < event.EndsAt)
end

-- El evento de ahora; si no hay ninguno, el próximo que va a empezar (para tener siempre uno a mano;
-- fuera de fechas EventActive dice que no y no sale nada)
function GameConfig.PickEvent(now)
	now = now or os.time()
	local upcoming
	for _, event in GameConfig.Events do
		if GameConfig.EventActive(event, now) then
			return event
		end
		if event.StartsAt and now < event.StartsAt and (not upcoming or event.StartsAt < upcoming.StartsAt) then
			upcoming = event
		end
	end
	return upcoming or GameConfig.Events[#GameConfig.Events]
end
GameConfig.Event = GameConfig.PickEvent()

-- Novedades que tocan ahora: las del evento en marcha si trae las suyas (y son más nuevas), si no
-- GameConfig.News
function GameConfig.ActiveNews()
	local event = GameConfig.CurrentEvent and GameConfig.CurrentEvent()
	if event and event.News and event.News.Version > GameConfig.News.Version then
		return event.News
	end
	return GameConfig.News
end

-- El evento en marcha AHORA según el servidor (atributo EventId que publica Event): en el cliente
-- no se usa su reloj (puede ir mal o estar cambiado). nil si no hay evento.
function GameConfig.CurrentEvent()
	local id = game:GetService("ReplicatedStorage"):GetAttribute("EventId")
	if not id then
		return nil
	end
	for _, event in GameConfig.Events do
		if event.Id == id then
			return event
		end
	end
	return nil
end

-- Logros: metas a largo plazo que se reclaman en la pestaña Perfil (monedas al reclamar).
-- Stat es un campo de los datos del jugador (TotalKills, Wins, Headshots, Matches, BestStreak, Level,
-- RankBest = rango más alto alcanzado, 1 = Bronce ... 6 = Campeón).
GameConfig.Achievements = {}
do
	local tiers = {
		{ "TotalKills", "🎯", "Consigue %d bajas", { 10, 100, 500, 1000, 5000 }, { 100, 300, 800, 1500, 5000 } },
		{ "Wins", "🏆", "Gana %d partidas", { 1, 10, 50, 200 }, { 100, 300, 1000, 3000 } },
		{ "Headshots", "🧠", "Haz %d bajas a la cabeza", { 10, 100, 500 }, { 150, 600, 2000 } },
		{ "Matches", "🎮", "Juega %d partidas", { 10, 50, 200 }, { 150, 500, 1500 } },
		{ "BestStreak", "🔥", "Consigue una racha de %d bajas", { 5, 10, 20 }, { 150, 500, 1500 } },
		{ "Level", "⭐", "Llega al nivel %d", { 10, 25, 50, 100 }, { 300, 800, 2000, 5000 } },
		{ "Assists", "🤝", "Consigue %d asistencias", { 10, 100, 500 }, { 100, 500, 1500 } },
		{ "RankBest", "👑", "Llega al rango %s", { 3, 5, 6 }, { 500, 1500, 4000 } },
	}
	local rankNames = { [3] = "Oro", [5] = "Diamante", [6] = "Campeón" }
	for _, tier in tiers do
		local stat, icon, text, goals, coins = tier[1], tier[2], tier[3], tier[4], tier[5]
		for i, goal in goals do
			table.insert(GameConfig.Achievements, {
				Id = stat .. goal,
				Stat = stat,
				Goal = goal,
				Icon = icon,
				Text = (stat == "RankBest" and string.format(text, rankNames[goal]))
					or (stat == "Wins" and goal == 1 and "Gana tu primera partida")
					or string.format(text, goal),
				Coins = coins[i],
			})
		end
	end
end

-- XP extra por días de la semana (hora UTC): Days usa os.date("!*t").wday (1 = domingo ... 7 = sábado).
-- Multiplica solo la XP (no las monedas). Pon Enabled = false para quitarlo.
GameConfig.XPBoost = { Enabled = true, Multiplier = 2, Days = { 1, 7 }, Text = "⚡ ¡FIN DE SEMANA DE XP DOBLE!" }

-- Novedades: tarjeta que ven una vez (en la pantalla de inicio) los jugadores que ya habían jugado.
-- Para anunciar otra actualización, cambia los textos y sube Version.
GameConfig.News = {
	Version = 2, -- (súbelo en cada actualización; la de Navidad tiene que quedar por encima)
	Title = "🎃 ¡NOVEDADES DE OCTUBRE!",
	Items = {
		{ "🤠", "Mapas nuevos: Pueblo Vaquero y Bahía Pirata, y traje Sheriff Vaquero" },
		{ "🧟", "Modos de Halloween: Infección (zombis) y Calabazas (recoge las de tus enemigos)" },
		{ "🏁", "Temporadas de rango: al acabar, premio según el mejor rango que logres" },
		{ "🏆", "Primera victoria del día: +150 monedas extra cada día" },
		{ "🎁", "Caja sorpresa al acabar las partidas (segura cada 15)" },
		{ "⚡", "Potenciadores de XP doble y monedas dobles en la Tienda" },
		{ "🍬", "Caramelos del evento: Cabeza de Calabaza, Calabazooka y skin Embrujada" },
		{ "🏹", "Ballesta nueva, trajes de Vampiro y Momia y efectos de Halloween" },
		{ "💰", "SE BUSCA, retos semanales, títulos y grafitis (tecla J)" },
	},
}

-- Regalos por tiempo jugado en la sesión (minutos desde que entras; se recogen en orden, botón 🎁)
GameConfig.PlaytimeGifts = {
	{ Minutes = 2, Coins = 40 },
	{ Minutes = 5, Coins = 75 },
	{ Minutes = 10, Revives = 1 },
	{ Minutes = 15, Coins = 150 },
	{ Minutes = 20, Coins = 100, XP = 250 },
	{ Minutes = 30, Revives = 2 },
	{ Minutes = 45, Coins = 300 },
}
GameConfig.SpawnProtection = 2 -- segundos de escudo al reaparecer
GameConfig.TrainingDummies = false -- muñecos de práctica quietos (ya no hacen falta: los bots sirven para practicar)

-- Movimiento
GameConfig.WalkSpeed = 18
GameConfig.SprintSpeed = 26
GameConfig.AimWalkSpeed = 11
GameConfig.SlideSpeed = 58
GameConfig.SlideDuration = 0.75
GameConfig.SlideCooldown = 1.1
GameConfig.FieldOfView = 80

-- Ajustes del jugador (menú Ajustes). Se guardan con su progreso.
-- "Auto": Baja en móviles y Media en PC (lo decide el cliente)
GameConfig.QualityLevels = { "Auto", "Baja", "Media", "Alta", "Ultra" }
GameConfig.DefaultSettings = { Quality = "Auto", QualityVersion = 2, FOV = 80, Sensitivity = 1, AimSensitivity = 0.8, CrossColor = 1, CrossSize = 1 }
GameConfig.SettingsLimits = {
	FOV = { 70, 100 },
	Sensitivity = { 0.2, 3 },
	AimSensitivity = { 0.2, 1.5 },
	CrossColor = { 1, 6 }, -- índice de GameConfig.CrosshairColors
	CrossSize = { 0.6, 2 },
}
-- Colores de la mira que se pueden elegir en Ajustes
GameConfig.CrosshairColors = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(90, 255, 110),
	Color3.fromRGB(70, 230, 255),
	Color3.fromRGB(255, 230, 60),
	Color3.fromRGB(255, 90, 200),
	Color3.fromRGB(255, 70, 70),
}

-- Progresión (pase de batalla)
GameConfig.XPPerLevel = 1000
GameConfig.XP = {
	Kill = 100,
	Headshot = 25,
	StreakBonus = 20, -- extra por cada baja de racha
	Win = 500,
	Loss = 150,
	Capture = 300, -- capturar la bandera
	FlagReturn = 75, -- devolver tu bandera caída
	CarrierKill = 75, -- eliminar al portador de tu bandera
	PumpkinConfirm = 60, -- Calabazas: recoger la calabaza de un enemigo caído
	PumpkinDeny = 40, -- Calabazas: recoger la de un compañero (la baja no cuenta)
	Assist = 40, -- asistencia: le quitaste vida a alguien que remató otro (en los últimos 10 s)
}
GameConfig.Coins = {
	Kill = 5,
	Win = 50,
	Capture = 20,
	Assist = 2,
	Pumpkin = 2, -- recoger una calabaza enemiga (modo Calabazas)
	WinStreak = 10, -- extra por cada victoria seguida (2.ª victoria +10, 3.ª +20...)
	WinStreakMax = 5, -- tope de victorias seguidas que suman extra
}

-- Grupo de Roblox: quien se une al grupo del juego puede reclamar Coins una vez (botón en la
-- pantalla de inicio). Crea el grupo en roblox.com/communities/create y pega aquí su ID (con 0 no sale).
GameConfig.Group = {
	Id = 0,
	Coins = 500,
}

-- Roblox Premium: quien lo tiene gana un poco más de monedas y XP (se multiplica con el VIP). Roblox
-- además paga al juego por el tiempo que juegan los Premium; en la Tienda hay un botón para hacerse Premium.
GameConfig.RobloxPremium = { Multiplier = 1.2 }

-- Premio de regreso: quien vuelve tras Days días o más sin jugar recibe Coins monedas, Crates cajas
-- gratis y BoostXPMinutes minutos de XP doble (de muestra de los potenciadores de la Tienda).
GameConfig.Comeback = { Days = 3, Coins = 400, Crates = 1, BoostXPMinutes = 30 }

-- Mientras hay un evento, la recompensa diaria regala también estos objetos del evento (caramelos...)
GameConfig.EventDailyBonus = 5

-- Primera victoria del día: la primera partida que ganas cada día (hora UTC) da esto de más.
GameConfig.FirstWinOfDay = { Coins = 150, XP = 300 }

-- Caja sorpresa: al acabar cada partida jugada hay Chance de llevarte una caja gratis (el VIP, el
-- doble); tras Pity partidas sin ninguna, sale seguro.
GameConfig.SurpriseCrate = { Chance = 0.06, VIPMultiplier = 2, Pity = 15 }

-- Invitaciones: quien entra por primera vez con la invitación de un amigo (botón INVITAR de la
-- portada) recibe NewPlayerCoins, y el que invitó InviterCoins si está en el mismo servidor (como
-- mucho MaxRewards veces, para que no se pueda abusar con cuentas nuevas).
GameConfig.Referral = {
	NewPlayerCoins = 500,
	InviterCoins = 500,
	MaxRewards = 10,
	MinAccountAge = 3, -- días que debe tener la cuenta del nuevo para que el que invita cobre
}

-- "SE BUSCA": quien llega a una racha de Streak bajas lleva una recompensa encima (todos lo ven
-- marcado). Quien lo elimine cobra Base monedas, + PerKill por cada baja más de la racha (hasta Max).
GameConfig.Bounty = {
	Enabled = true,
	Streak = 5,
	Base = 25,
	PerKill = 5,
	Max = 100,
	XP = 50,
}

-- ID del GamePass del pase premium. Créalo en el Creator Hub y pon el número aquí.
-- Con 0 el botón de compra queda desactivado.
GameConfig.PremiumPassId = 0

-- Insignias de Roblox (Creator Hub → Insignias). Pega el ID de cada una; con 0 no se da.
GameConfig.Badges = {
	Welcome = 0, -- entrar por primera vez
	FirstKill = 0, -- primera baja
	Kills100 = 0, -- 100 bajas
	FirstWin = 0, -- primera victoria
	Level10 = 0, -- nivel 10
	RankGold = 0, -- llegar a rango Oro
	RankDiamond = 0, -- llegar a rango Diamante
	RankChampion = 0, -- llegar a rango Campeón
}

-- Después del último nivel del pase: cada Every niveles, Coins monedas y Crates cajas gratis.
GameConfig.PostPassRewards = { Every = 5, Coins = 300, Crates = 1 }

-- Recompensas por nivel. Free = pase gratis, Premium = pase de pago.
-- Tipos: { Type = "Skin", Id = "<id de Skins>" } o { Type = "Coins", Amount = n }
GameConfig.BattlePass = {
	{ Free = { Type = "Coins", Amount = 50 }, Premium = { Type = "Skin", Id = "Sakura" } },
	{ Free = { Type = "Skin", Id = "Toxico" }, Premium = { Type = "Coins", Amount = 150 } },
	{ Free = { Type = "Coins", Amount = 75 }, Premium = { Type = "Skin", Id = "Hielo" } },
	{ Free = nil, Premium = { Type = "Coins", Amount = 200 } },
	{ Free = { Type = "Skin", Id = "Selva" }, Premium = { Type = "Skin", Id = "Calabaza" } },
	{ Free = { Type = "Coins", Amount = 100 }, Premium = { Type = "Coins", Amount = 250 } },
	{ Free = nil, Premium = { Type = "Skin", Id = "Vacio" } },
	{ Free = { Type = "Coins", Amount = 125 }, Premium = { Type = "Coins", Amount = 300 } },
	{ Free = { Type = "Skin", Id = "Oceano" }, Premium = { Type = "Skin", Id = "Dorado" } },
	{ Free = { Type = "Coins", Amount = 150 }, Premium = { Type = "Coins", Amount = 400 } },
	{ Free = nil, Premium = { Type = "Skin", Id = "Galaxia" } },
	{ Free = { Type = "Coins", Amount = 200 }, Premium = { Type = "Coins", Amount = 500 } },
	{ Free = { Type = "Skin", Id = "Atardecer" }, Premium = { Type = "Skin", Id = "Dragon" } },
	{ Free = { Type = "Coins", Amount = 250 }, Premium = { Type = "Coins", Amount = 750 } },
	{ Free = { Type = "Coins", Amount = 500 }, Premium = { Type = "Skin", Id = "Magma" } },
}

-- Niveles 16 a 50 del pase (para que dure: unas 40 partidas). Cada 5 niveles, caja gratis y un
-- traje o un efecto en la vía premium; el resto, monedas y camuflajes.
do
	local premiumBig = {
		[20] = { Type = "Outfit", Id = "NeonRecon" },
		[25] = { Type = "Outfit", Id = "VoltBruiser" },
		[30] = { Type = "Outfit", Id = "FrostByte" },
		[35] = { Type = "Outfit", Id = "ToxicRogue" },
		[40] = { Type = "KillEffect", Id = "Rayo" },
		[45] = { Type = "KillEffect", Id = "AgujeroNegro" },
		[50] = { Type = "Outfit", Id = "GoldenAce" },
	}
	local premiumSkins = { "CamoBosque", "CamoDesierto", "CamoDigital", "CamoArtico", "CamoTigre", "CamoNebulosa", "Prisma" }
	local skinIndex = 0
	for tier = 16, 50 do
		local entry
		if tier % 5 == 0 then
			entry = { Free = { Type = "Crate", Amount = tier == 50 and 3 or 1 }, Premium = premiumBig[tier] }
		elseif tier % 5 == 3 then
			skinIndex += 1
			entry = { Free = { Type = "Coins", Amount = 100 + tier * 5 }, Premium = { Type = "Skin", Id = premiumSkins[(skinIndex - 1) % #premiumSkins + 1] } }
		else
			entry = { Free = tier % 2 == 0 and { Type = "Coins", Amount = 100 + tier * 5 } or nil, Premium = { Type = "Coins", Amount = 250 + tier * 10 } }
		end
		table.insert(GameConfig.BattlePass, entry)
	end
end

return GameConfig
