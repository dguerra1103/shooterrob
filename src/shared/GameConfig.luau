-- Configuración general del juego. Cambia aquí los valores para ajustar el balance.
local GameConfig = {}

-- Nombre que aparece en la pantalla de inicio y en los carteles del mapa
GameConfig.GameTitle = "SHOOTER NEW"
-- Estilo de los mapas: "Tactico" (el de ahora: materiales de verdad con luz limpia y legible, color un
-- poco vivo y brillo contenido: un shooter de Roblox moderno, MapKit.tacticalize), "Realista" (piedra, yeso, ladrillo, metal y madera de verdad, colores naturales y
-- luz con sombras marcadas, como los shooters militares) o "Cartoon" (colores vivos, plástico liso y
-- sombras suaves). En Realista, los mapas pensados para Cartoon se "realizan" solos (MapKit.realize).
GameConfig.VisualStyle = "Tactico"

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
GameConfig.Modes = { "TDM", "DOM", "SND", "CTF", "KOTH", "FFA", "GUN", "ELIM", "INF", "CAL" }
GameConfig.ModeSettings = {
	TDM = { Name = "Duelo por equipos", ScoreToWin = 50, RoundTime = 10 * 60, Teams = true }, -- puntos = bajas (50 en 10 min, como en los shooters de móvil)
	CTF = { Name = "Captura la bandera", ScoreToWin = 3, RoundTime = 10 * 60, Teams = true }, -- puntos = capturas
	-- Dominio: tres banderas (A, B, C); cada una tuya suma 1 punto cada 3 s
	DOM = { Name = "Dominio", ScoreToWin = 150, RoundTime = 10 * 60, Teams = true },
	KOTH = { Name = "Zona de control", ScoreToWin = 150, RoundTime = 10 * 60, Teams = true }, -- 1 punto/seg en la zona
	FFA = { Name = "Todos contra todos", ScoreToWin = 25, RoundTime = 8 * 60, Teams = false }, -- bajas individuales
	GUN = { Name = "Escalada de armas", ScoreToWin = 0, RoundTime = 10 * 60, Teams = false }, -- 0 = una baja por arma
	-- Eliminación: rondas cortas de UNA vida; gana la ronda el equipo que deje al otro sin nadie en pie
	-- Buscar y destruir: rondas de una vida; atacan y defienden por turnos. Los atacantes plantan la
	-- bomba en A o B (PlantTime s dentro del sitio) y explota a los BombTime s; los defensores la
	-- desactivan (DefuseTime s junto a ella). Solo en mapas con sitios (si no, es Eliminación).
	SND = { Name = "Buscar y destruir", ScoreToWin = 4, RoundTime = 12 * 60, Teams = true, SubRoundTime = 100, PrepTime = 5, PlantTime = 4, DefuseTime = 6, BombTime = 35, DefenderHeadStart = 3 }, -- (los atacantes salen 3 s después: los sitios están a la misma distancia de las dos bases)
	ELIM = { Name = "Eliminación", ScoreToWin = 5, RoundTime = 10 * 60, Teams = true, SubRoundTime = 75, PrepTime = 4 },
	-- Infección (Halloween): todos empiezan como supervivientes (equipo A) y tras PrepTime uno de cada
	-- ZombieRatio se convierte en zombi (equipo B: garras, más vida y algo más rápidos). Quien cae ante
	-- los zombis se convierte en zombi. Ganan los supervivientes si queda alguno al acabar el tiempo.
	INF = { Name = "Infección", ScoreToWin = 1, RoundTime = 150, Teams = true, PrepTime = 12, ZombieHealth = 200, ZombieRatio = 5 },
	-- Calabazas (como "Kill Confirmed"): quien cae suelta una calabaza; un punto si la recoge el equipo
	-- contrario, y si la recoge un compañero del caído la baja no cuenta
	CAL = { Name = "Calabazas", ScoreToWin = 30, RoundTime = 8 * 60, Teams = true },
}
-- Uniforme militar para quien no lleva traje en los mapas realistas (cada jugador puede quitarlo en Ajustes)
GameConfig.SoldierUniform = true
-- Cuerpo estándar con traje o uniforme: quien lleva un traje de operador o el uniforme de soldado juega
-- con el cuerpo de bloques normal de Roblox (mismas proporciones para todos). Sin esto, los avatares
-- con cuerpos muy finos o disfraces se quedaban sin brazos ni piernas visibles bajo el chaleco, y cada
-- avatar tenía un tamaño de blanco distinto. La cabeza, la cara y el pelo son los del jugador.
GameConfig.StandardBody = true
-- Sangre en los impactos y bajas (mapas realistas). false (por defecto): impactos realistas sin sangre
-- (polvo y fibras de la ropa). true: una nube rojo oscuro y gotitas. OJO: en el cuestionario de
-- madurez de Roblox, la sangre realista cuenta como «Moderado» (13+): actualízalo antes de activarla.
GameConfig.RealisticBlood = false
-- Tamaño del arma que lleva el personaje en el mundo (la que ven los demás). 1 = como la de primera
-- persona (enorme al lado del cuerpo); 0,65 = a escala de una persona, como en los shooters realistas
GameConfig.WorldWeaponScale = 0.65
-- Los personajes (bots y demás jugadores) sujetan el arma de fuego con las dos manos: culata al hombro
-- y la otra mano en el guardamanos (IKControl, solo en cada cliente). false = la pose de Roblox
GameConfig.TwoHandedPose = true
-- Contorno rojo fino en los enemigos (solo donde ya se les ve: no atraviesa paredes), para leerlos al
-- momento contra cualquier fondo, como en los shooters competitivos de Roblox. false = sin contorno
GameConfig.EnemyOutline = true
-- Colores que puede elegir el jugador para ese contorno (Ajustes): rojo, amarillo (daltonismo
-- rojo-verde) y magenta (se distingue de casi todos los fondos)
GameConfig.EnemyColors = {
	{ Name = "Rojo", Color = Color3.fromRGB(255, 64, 52) },
	{ Name = "Amarillo", Color = Color3.fromRGB(255, 220, 40) },
	{ Name = "Magenta", Color = Color3.fromRGB(255, 60, 220) },
}
-- En cada votación sale siempre un mapa de 5 contra 5 estilo shooter militar (los de Realistic = true:
-- los nueve 5v5: Construction, Coastal, Terminal...) con Duelo por equipos, Dominio o Buscar y destruir. false = votación al azar
GameConfig.VoteRealisticMap = true
GameConfig.VoteTime = 15 -- segundos de votación (dentro del descanso)

-- Captura la bandera
GameConfig.Flag = {
	PickupRadius = 5, -- distancia para coger/devolver la bandera
	CaptureRadius = 7, -- distancia a tu base para capturar
	AutoReturnTime = 20, -- segundos que tarda en volver sola si nadie la toca
	CarrierSpeedMultiplier = 0.9, -- el portador va un poco más lento
}
GameConfig.EndScreenTime = 8

-- Despliegue al empezar cada partida (todos quietos y sin daño mientras tanto): presentación de los
-- equipos y elección rápida de clase (LineupTime) y cuenta atrás 3-2-1 (CountdownTime). En
-- Eliminación y Buscar y destruir la cuenta atrás es la preparación de la primera ronda.
-- Animaciones de los personajes de los menús (vista 3D del lobby, operador, escuadra, armamento y
-- victoria). Sube la animación (R15) a Roblox y pega aquí "rbxassetid://<id>"; vacío = pose por
-- código con el arma lista (ver Flow/Preview)
GameConfig.UIAnimations = {
	MenuIdle = "",
	OperatorIdle = "",
	WeaponInspect = "",
	SquadIdle = "",
	VictoryPose = "", -- (MVP en la pantalla final)
	VictoryIdle = "",
	SquadVictoryIdle = "", -- (compañeros del MVP en la pantalla final)
}

-- Pantalla final: botón 👍 de reconocimiento a compañeros. Apagado: aún no hay sistema que lo guarde
-- (al encenderlo hay que conectar PlayerResultCard.OnHonor a un remoto real)
GameConfig.ResultsHonor = false

GameConfig.Deploy = {
	Enabled = true,
	LineupTime = 7,
	CountdownTime = 3,
}

-- Clases (5 huecos): arma principal, secundaria y ventaja. Las de partida se guardan con el progreso
-- y se cambian en Armamento o en la elección rápida antes de desplegar.
GameConfig.ClassCount = 5
GameConfig.DefaultClasses = {
	{ Name = "ASALTO", Primary = "ARX27", Secondary = "Viper", Perk = 1 },
	{ Name = "CQB", Primary = "Specter9", Secondary = "Viper", Perk = 1 },
	{ Name = "ESCOPETA", Primary = "HavocPump", Secondary = "Viper", Perk = 2 },
	{ Name = "TIRADOR", Primary = "Signal7", Secondary = "Viper", Perk = 3 },
	{ Name = "PESADO", Primary = "TitanLMG", Secondary = "Viper", Perk = 2 },
}
-- Killcam final: si una baja cierra la partida o una ronda de Eliminación / Buscar y destruir, todos ven
-- su repetición desde los ojos de quien la hizo (con todo congelado este rato). false = sin ella
-- Instrumentación de impactos (Fase 2, solo diagnóstico; NO cambia qué impactos valen). Con Enabled, el
-- servidor mide cuánto se separa el punto de impacto que dice el cliente de la pieza que dice haber
-- tocado y lo resume en la consola cada ReportEvery impactos. Sirve para ajustar la tolerancia
-- (~8 studs) y la validación del tiro a la cabeza con latencia real en Studio. Apagado en producción.
GameConfig.HitTelemetry = { Enabled = false, ReportEvery = 200 }
-- Modo QA (Fase 8): panel de pruebas para Roblox Studio (mapa y modo, terminar partida, bots, arma,
-- rendimiento, telemetría de impactos, ayudas visuales). Funciona SOLO si Enabled = true Y el juego
-- corre dentro de Roblox Studio (RunService:IsStudio()). En un servidor publicado no existe: ni panel,
-- ni RemoteEvent, ni comandos (ver Shared/QA.luau y FASE_08_VALIDACION_STUDIO.md). Dejar en false al
-- hacer commit.
GameConfig.QA = { Enabled = false }
-- Desenfoque al apuntar (AimFX). Apagado: en combate nada sale borroso (Fase 3). La viñeta sí sigue.
GameConfig.AimDepthOfField = false
GameConfig.FinalKillcam = true
GameConfig.FinalKillcamTime = 3.4
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
-- Bots: rellenan la partida cuando hay pocos jugadores (se quitan solos al entrar gente). Con
-- FillTo = 10 las partidas por equipos son siempre 5 contra 5 (como en los shooters de móvil).
GameConfig.Bots = {
	Enabled = true,
	FillTo = 10, -- jugadores + bots hasta este número (10 = 5 contra 5)
	-- Roles: cada bot sale con uno (y sus armas). Max = como mucho tantos por equipo.
	Roles = {
		{ Name = "Asalto", Weight = 4, Weapons = { "ARX27", "VortexBR" } }, -- fusil: equilibrado
		{ Name = "Subfusil", Weight = 2.5, Weapons = { "Specter9", "NovaDrift" } }, -- corre y entra a por ti
		{ Name = "Tirador", Weight = 1.5, Max = 1, Weapons = { "RaptorDMR", "Signal7" } }, -- se aposta lejos (ventanas, alturas)
		{ Name = "Escopeta", Weight = 1, Max = 1, Weapons = { "HavocPump" } }, -- distancia corta, muy agresivo
		{ Name = "Ametralladora", Weight = 1, Max = 1, Weapons = { "TitanLMG" } }, -- aguanta una línea
	},
	Weapons = { "ARX27", "Specter9", "VortexBR", "NovaDrift" }, -- (si no hay Roles)
	Range = 160,
	Accuracy = 0.55, -- probabilidad de acertar a corta distancia (con la puntería ya asentada)
	AccuracyFalloff = 0.004, -- se resta por cada stud de distancia (menos con fusiles de precisión)
	DamageScale = 0.55, -- los bots hacen menos daño que un jugador
	Reaction = 0.45, -- segundos antes de empezar a disparar a un objetivo nuevo (varía con cada bot)
	MaxFireRate = 8, -- disparos por segundo como máximo
	WalkSpeed = 18, -- peleando (como un jugador andando)
	SprintSpeed = 25, -- de camino, sin enemigos cerca (como un jugador corriendo)
	JumpChance = 0.06, -- probabilidad de saltar en cada cambio de dirección mientras pelea
	Hearing = 1, -- multiplica la distancia a la que oyen los disparos (110 studs; con silenciador 25)
	GrenadeCooldown = 18, -- segundos entre granadas de cada bot
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
		{ "🤠", "Mapas nuevos: Pueblo Vaquero, Bahía Pirata y Castillo del Rey" },
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
-- Vida que se recupera sola (como en los shooters de móvil): tras Delay segundos sin daño sube
-- PerSecond puntos por segundo hasta llenarse
GameConfig.HealthRegen = { Enabled = true, Delay = 4, PerSecond = 35 }
-- Apariciones dinámicas (Duelo por equipos, Zona y Calabazas): al reaparecer, en el punto del mapa
-- más seguro (lejos de los enemigos, cerca de tu equipo) en vez de en la base. false = siempre en la base
GameConfig.DynamicSpawns = true
GameConfig.SpawnProtection = 2 -- segundos de escudo al reaparecer
GameConfig.TrainingDummies = false -- muñecos de práctica quietos (ya no hacen falta: los bots sirven para practicar)

-- Movimiento
GameConfig.WalkSpeed = 18
GameConfig.SprintSpeed = 26
GameConfig.AimWalkSpeed = 11
GameConfig.CrouchSpeed = 10 -- agachado (C sin correr; corriendo, C desliza)
GameConfig.CrouchDrop = 1.3 -- cuánto se baja el cuerpo al agacharse
GameConfig.SlideSpeed = 58
GameConfig.SlideDuration = 0.75
GameConfig.SlideCooldown = 1.1
GameConfig.FieldOfView = 80
-- Movimiento realista: aceleración, estamina al correr, aterrizajes y balanceo de cámara
GameConfig.Movement = {
	Acceleration = 30, -- studs/s que gana la velocidad por segundo al arrancar o al pasar a correr
	Deceleration = 70, -- y que pierde al frenar o dejar de correr
	StartFactor = 0.55, -- al empezar a andar, se arranca con esta parte de la velocidad
	SprintAngle = 0.55, -- solo se corre hacia delante (coseno entre hacia dónde vas y hacia dónde miras)
	StaminaSeconds = 6, -- segundos corriendo sin parar con la estamina llena
	RegenSeconds = 4, -- segundos para llenarla otra vez desde cero
	RegenDelay = 0.8, -- espera tras correr o saltar antes de recuperarse
	MinToSprint = 0.3, -- si se agota, hace falta esta parte para volver a correr
	JumpCost = 0.12, -- estamina que gasta cada salto
	TiredJump = 0.7, -- sin estamina se salta menos
	HardLanding = 38, -- velocidad de caída a partir de la que el aterrizaje se nota
	HeavyLanding = 62, -- y a partir de la que frena un momento
	CameraBob = 1, -- balanceo de cámara al andar (0 = nada)
}

-- Ajustes del jugador (menú Ajustes). Se guardan con su progreso.
-- "Auto": Baja en móviles y Media en PC (lo decide el cliente)
GameConfig.QualityLevels = { "Auto", "Baja", "Media", "Alta", "Ultra" }
-- AutoFire: disparo automático con la mira sobre un enemigo (0 = no, 1 = siempre, 2 = solo en pantallas táctiles)
-- Perk: ventaja elegida (GameConfig.Perks; 0 = ninguna)
-- ScreenFX: efectos de pantalla (1 = normales; 0 = reducidos: sin desenfoques, destellos ni temblores,
-- para quien se marea; ver CombatFX, AimFX y WeaponController)
-- Controles táctiles (Fase 12): AutoSprint 1 = corre solo con el joystick a tope hacia delante (0 =
-- botón), LeftFire 1 = segundo botón de disparar a la izquierda, FireDrag 1 = el dedo de DISPARAR
-- también gira la cámara, HudLayout = posición, tamaño y opacidad de cada control (MobileHUD.Validate),
-- HudLayoutVersion = versión de la disposición por defecto con la que se guardó (MobileHUD.LayoutVersion;
-- la pone el servidor al migrar, el cliente no la cambia)
GameConfig.DefaultSettings = { Quality = "Auto", QualityVersion = 2, FOV = 80, Sensitivity = 1, AimSensitivity = 0.8, CrossColor = 1, CrossSize = 1, AutoFire = 2, AimAssist = 2, Uniform = 1, ScreenFX = 1, EnemyColor = 1, Perk = 0, AutoSprint = 1, LeftFire = 0, FireDrag = 1, HudLayout = {}, HudLayoutVersion = 2 }
GameConfig.SettingsLimits = {
	FOV = { 70, 100 },
	Sensitivity = { 0.2, 3 },
	AimSensitivity = { 0.2, 1.5 },
	CrossColor = { 1, 6 }, -- índice de GameConfig.CrosshairColors
	CrossSize = { 0.6, 2 },
	AutoFire = { 0, 2 },
	AimAssist = { 0, 2 }, -- asistencia de apuntado con dedo o mando: 2 normal, 1 suave, 0 no
	Uniform = { 0, 1 }, -- 1 = uniforme militar en los mapas realistas si no llevas traje; 0 = tu avatar
	ScreenFX = { 0, 1 }, -- 1 = efectos de pantalla normales; 0 = reducidos
	EnemyColor = { 1, 3 }, -- color del contorno de los enemigos (GameConfig.EnemyColors): accesibilidad
	Perk = { 0, 3 },
	AutoSprint = { 0, 1 },
	LeftFire = { 0, 1 },
	FireDrag = { 0, 1 },
}
-- Modo de depuración de los controles táctiles (zona segura, zonas táctiles, centro libre, zona de
-- cámara, resolución). Solo funciona en Studio y está apagado: nunca lo ve un jugador.
GameConfig.MobileHUDDebug = false
-- Ventajas (como en los shooters de móvil): cada jugador elige una en Ajustes, gratis. El número es
-- el valor guardado (Settings.Perk) y el atributo "Perk" del jugador.
GameConfig.Perks = {
	{ Id = 1, Name = "Ligero", Icon = "🏃", Text = "Corres y andas un 8 % más rápido", SpeedMultiplier = 1.08 },
	{ Id = 2, Name = "Persistente", Icon = "❤️", Text = "La vida empieza a recuperarse antes (2,5 s) y más deprisa", RegenDelay = 2.5, RegenMultiplier = 1.3 },
	{ Id = 3, Name = "Fantasma", Icon = "👻", Text = "Al disparar no sales en el minimapa enemigo y los bots te oyen la mitad de lejos" },
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
	Ace = 250, -- Eliminación/Buscar y destruir: eliminar tú solo a todo el equipo rival en una ronda
}
-- Medallas de baja (como en los shooters de móvil): aviso en pantalla y XP extra (contra bots,
-- reducida como el resto del XP). LongShot: distancia mínima en studs (sin explosivos ni cuerpo a cuerpo)
GameConfig.Medals = {
	FirstBlood = { Text = "💥 PRIMERA SANGRE", Name = "Primera sangre", XP = 40 },
	Revenge = { Text = "😤 VENGANZA", Name = "Venganza", XP = 30 },
	LongShot = { Text = "🔭 LARGA DISTANCIA", Name = "Larga distancia", XP = 30, Distance = 90 },
	StreakEnder = { Text = "🛑 CAZARRACHAS", Name = "Cazarrachas", XP = 50, Streak = 3 },
	Afterlife = { Text = "👻 DESDE LA TUMBA", Name = "Desde la tumba", XP = 40 },
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

-- Mapa destacado: cada día (hora UTC) uno de los mapas de siempre da XPBonus de XP al jugarlo
-- (se marca con ⭐ en la votación)
GameConfig.FeaturedMap = { XPBonus = 1.25 }

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
