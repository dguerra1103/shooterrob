-- Tarjetas de jugador: fondo, borde y emblema de la tarjeta con tu nombre. Se ven en el lobby (tu
-- perfil), la escuadra, la presentación de equipos y la pantalla final. Solo estética.
-- Price = monedas; las de Robux tienen su producto en Economy/Products (ItemProducts). Bonus = solo
-- se consigue de regalo (no se vende); Pass = solo en el pase de batalla.
local PlayerCards = {}

local RGB = Color3.fromRGB

PlayerCards.List = {
	Default = { Name = "Grafito", Rarity = "Común", Top = RGB(30, 33, 40), Bottom = RGB(16, 18, 22), Border = RGB(90, 96, 110), Emblem = "" },
	Tactico = { Name = "Táctico", Rarity = "Raro", Price = 300, Top = RGB(70, 82, 50), Bottom = RGB(30, 36, 22), Border = RGB(150, 160, 110), Emblem = "✦" },
	Carbono = { Name = "Carbono", Rarity = "Raro", Price = 400, Top = RGB(44, 44, 48), Bottom = RGB(10, 10, 12), Border = RGB(200, 200, 210), Emblem = "▰" },
	Neon = { Name = "Neón", Rarity = "Épico", Price = 900, Top = RGB(30, 10, 60), Bottom = RGB(10, 20, 50), Border = RGB(0, 230, 255), Emblem = "◆" },
	Glaciar = { Name = "Glaciar", Rarity = "Épico", Top = RGB(120, 190, 235), Bottom = RGB(30, 70, 120), Border = RGB(220, 245, 255), Emblem = "❄" },
	Infierno = { Name = "Infierno", Rarity = "Legendario", Top = RGB(200, 60, 20), Bottom = RGB(40, 6, 6), Border = RGB(255, 170, 60), Emblem = "🔥" },
	Oro = { Name = "Oro real", Rarity = "Legendario", Top = RGB(250, 205, 90), Bottom = RGB(140, 90, 20), Border = RGB(255, 240, 170), Emblem = "👑" },
	Vacio = { Name = "Vacío", Rarity = "Mítico", Top = RGB(60, 20, 110), Bottom = RGB(6, 4, 14), Border = RGB(200, 90, 255), Emblem = "✺" },
	ZonaRoja = { Name = "Zona Roja", Rarity = "Épico", Pass = true, Top = RGB(150, 20, 30), Bottom = RGB(20, 8, 10), Border = RGB(255, 80, 80), Emblem = "⚠" },
	PrimerGolpe = { Name = "Primer golpe", Rarity = "Épico", Bonus = true, Top = RGB(255, 198, 26), Bottom = RGB(90, 60, 0), Border = RGB(255, 255, 255), Emblem = "⚡" },
}

PlayerCards.Default = "Default"

function PlayerCards.Get(id)
	return PlayerCards.List[id] or PlayerCards.List.Default
end

return PlayerCards
