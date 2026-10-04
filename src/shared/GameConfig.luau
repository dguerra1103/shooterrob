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
GameConfig.Modes = { "TDM", "CTF", "KOTH", "FFA", "GUN", "ELIM" }
GameConfig.ModeSettings = {
	TDM = { Name = "Duelo por equipos", ScoreToWin = 40, RoundTime = 8 * 60, Teams = true }, -- puntos = bajas
	CTF = { Name = "Captura la bandera", ScoreToWin = 3, RoundTime = 10 * 60, Teams = true }, -- puntos = capturas
	KOTH = { Name = "Zona de control", ScoreToWin = 150, RoundTime = 10 * 60, Teams = true }, -- 1 punto/seg en la zona
	FFA = { Name = "Todos contra todos", ScoreToWin = 25, RoundTime = 8 * 60, Teams = false }, -- bajas individuales
	GUN = { Name = "Escalada de armas", ScoreToWin = 0, RoundTime = 10 * 60, Teams = false }, -- 0 = una baja por arma
	-- Eliminación: rondas cortas de UNA vida; gana la ronda el equipo que deje al otro sin nadie en pie
	ELIM = { Name = "Eliminación", ScoreToWin = 5, RoundTime = 10 * 60, Teams = true, SubRoundTime = 75, PrepTime = 4 },
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
	Weapons = { "ARX27", "Specter9", "VortexBR", "NovaDrift" },
	Range = 140,
	Accuracy = 0.55, -- probabilidad de acertar a corta distancia
	AccuracyFalloff = 0.004, -- se resta por cada stud de distancia
	DamageScale = 0.55, -- los bots hacen menos daño que un jugador
	Reaction = 0.5, -- segundos antes de empezar a disparar a un objetivo nuevo
	MaxFireRate = 6, -- disparos por segundo como máximo
	WalkSpeed = 16,
	RewardScale = 0.5, -- XP y monedas por matar un bot (respecto a un jugador)
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
GameConfig.TrainingDummies = true -- muñecos de práctica en el mapa (ponlo en false al publicar)

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
GameConfig.DefaultSettings = { Quality = "Auto", QualityVersion = 2, FOV = 80, Sensitivity = 1, AimSensitivity = 0.8 }
GameConfig.SettingsLimits = {
	FOV = { 70, 100 },
	Sensitivity = { 0.2, 3 },
	AimSensitivity = { 0.2, 1.5 },
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
}

-- ID del GamePass del pase premium. Créalo en el Creator Hub y pon el número aquí.
-- Con 0 el botón de compra queda desactivado.
GameConfig.PremiumPassId = 0

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

return GameConfig
