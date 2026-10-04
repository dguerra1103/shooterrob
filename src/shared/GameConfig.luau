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
GameConfig.Modes = { "TDM", "CTF", "KOTH", "FFA", "GUN", "ELIM", "INF" }
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
	OutfitChance = 0.6, -- probabilidad de que un bot lleve uno de los trajes de la tienda
}
-- Evento de temporada (Halloween): durante las rondas aparecen caramelos por el mapa; cada uno da
-- monedas y suma al contador del evento; al llegar a Goal se gana la skin exclusiva RewardSkin.
-- Pon Enabled = false cuando acabe el evento (el progreso queda guardado por si vuelve).
GameConfig.Event = {
	Enabled = true,
	Id = "Halloween2026", -- cambia el Id para empezar de cero en otro evento
	Name = "Halloween",
	CandyCoins = 5, -- monedas por caramelo
	Goal = 100, -- caramelos para la skin
	RewardSkin = "Embrujada",
	-- Premios por el camino (el último premio es la skin al llegar a Goal). Si ya tenías el traje,
	-- se cambia por Compensate monedas.
	Milestones = {
		{ Count = 25, Coins = 150 },
		{ Count = 50, Outfit = "Calabaza", Compensate = 400 },
		{ Count = 75, Weapon = "Calabazooka", Compensate = 300 },
	},
	SpawnEvery = 12, -- segundos entre caramelos
	MaxCandies = 6, -- a la vez en el mapa
	Pumpkins = true, -- calabazas de decoración en los mapas
	EndsAt = 1793750400, -- se apaga solo a partir de esta fecha (4 nov 2026, 00:00 UTC); nil = nunca
}

-- Novedades: tarjeta que ven una vez (en la pantalla de inicio) los jugadores que ya habían jugado.
-- Para anunciar otra actualización, cambia los textos y sube Version.
GameConfig.News = {
	Version = 1,
	Title = "🎃 ¡NOVEDADES DE HALLOWEEN!",
	Items = {
		{ "🧟", "Modo Infección: sobrevive a los zombis... o conviértete en uno" },
		{ "🚀", "Mapa nuevo: Base Lunar, con la Tierra en el cielo" },
		{ "🏆", "Rangos de Bronce a Campeón, con premios al subir" },
		{ "🎡", "Ruleta diaria: un giro gratis cada día" },
		{ "🍬", "Caramelos del evento: traje Cabeza de Calabaza, Calabazooka y skin Embrujada" },
		{ "👤", "Pestaña Perfil con tus estadísticas y tu arma favorita" },
		{ "🔪", "Guadaña y efectos de eliminación de Halloween en la tienda" },
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
}
GameConfig.Coins = {
	Kill = 5,
	Win = 50,
	Capture = 20,
	WinStreak = 10, -- extra por cada victoria seguida (2.ª victoria +10, 3.ª +20...)
	WinStreakMax = 5, -- tope de victorias seguidas que suman extra
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
