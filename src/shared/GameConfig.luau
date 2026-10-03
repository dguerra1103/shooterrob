-- Configuración general del juego. Cambia aquí los valores para ajustar el balance.
local GameConfig = {}

-- Equipos
GameConfig.Teams = {
	{ Name = "Rojo", Color = BrickColor.new("Really red") },
	{ Name = "Azul", Color = BrickColor.new("Really blue") },
}

-- Rondas (Team Deathmatch: gana el primer equipo en llegar a ScoreToWin bajas)
GameConfig.MinPlayers = 1 -- súbelo a 2+ cuando publiques el juego
GameConfig.IntermissionTime = 15
GameConfig.RoundTime = 8 * 60
GameConfig.ScoreToWin = 40
GameConfig.EndScreenTime = 8
GameConfig.RespawnTime = 3
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

-- Progresión (pase de batalla)
GameConfig.XPPerLevel = 1000
GameConfig.XP = {
	Kill = 100,
	Headshot = 25,
	StreakBonus = 20, -- extra por cada baja de racha
	Win = 500,
	Loss = 150,
}
GameConfig.Coins = {
	Kill = 5,
	Win = 50,
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
