-- Efectos de eliminación: lo que ven todos cuando eliminas a alguien (como en Arsenal).
-- Se compran con monedas en el menú (pestaña Efectos) y se dibujan en Effects.KillEffect (cliente).
local KillEffects = {}

KillEffects.List = {
	Default = { Name = "Estallido", Rarity = "Común", Icon = "💥", Description = "El de siempre, del color de su equipo." },
	Confeti = { Name = "Confeti", Rarity = "Raro", Icon = "🎉", Price = 500, Description = "¡Fiesta! Una lluvia de papelitos de colores." },
	Amor = { Name = "Amor", Rarity = "Raro", Icon = "💖", Price = 600, Description = "Corazones que suben flotando." },
	Fuego = { Name = "Llamarada", Rarity = "Épico", Icon = "🔥", Price = 800, Description = "Una columna de fuego." },
	Hielo = { Name = "Congelado", Rarity = "Épico", Icon = "❄️", Price = 800, Description = "Estalla en cristales de hielo." },
	Fantasma = { Name = "Fantasma", Rarity = "Épico", Icon = "👻", Price = 900, Description = "Su fantasma sale volando." },
	Calavera = { Name = "Calavera", Rarity = "Legendario", Icon = "💀", Price = 1200, Description = "Calavera gigante y humo rojo." },
	Rayo = { Name = "Rayo", Rarity = "Legendario", Icon = "⚡", Price = 1500, Description = "Un rayo cae del cielo." },
	Monedas = { Name = "Lluvia de monedas", Rarity = "Legendario", Icon = "🪙", Price = 1500, Description = "Revienta en monedas de oro." },
	AgujeroNegro = { Name = "Agujero negro", Rarity = "Mítico", Icon = "🌀", Price = 3000, Description = "Se lo traga un agujero negro." },
	Pintura = { Name = "Pintura", Rarity = "Épico", Icon = "🎨", Price = 900, Description = "Revienta en bolas de pintura y lo deja todo manchado." },
	Arcoiris = { Name = "Arcoíris", Rarity = "Legendario", Icon = "🌈", Price = 1800, Description = "Un arcoíris sale disparado de tu rival." },
}

function KillEffects.Get(id)
	return KillEffects.List[id] or KillEffects.List.Default
end

return KillEffects
