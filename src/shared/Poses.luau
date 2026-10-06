-- Poses de victoria e intros de MVP: cosméticos que se ven en la pantalla final (Flow/Results). La
-- pose equipada la hace tu personaje en la escena del equipo; la intro de MVP, solo cuando eres el
-- MVP (o el destacado de tu equipo). No cambian nada de la partida.
-- Precio: Price = monedas; los de Robux tienen su producto en Economy/Products (ItemProducts).
-- Cómo se dibujan: Flow/Results/PoseRig (cliente).
local Poses = {}

Poses.List = {
	Ready = { Name = "Arma lista", Rarity = "Común", Icon = "🎯", Description = "Arma en alto, listo para la siguiente." },
	Bajada = { Name = "Arma baja", Rarity = "Raro", Icon = "😌", Price = 400, Description = "Tranquilo, con el arma apuntando al suelo." },
	AlCielo = { Name = "Al cielo", Rarity = "Épico", Icon = "🙌", Price = 900, Description = "El arma en alto, apuntando al cielo." },
	Saludo = { Name = "Saludo", Rarity = "Épico", Icon = "🫡", Description = "Saludo militar, con el arma colgada." },
	Brazos = { Name = "Brazos cruzados", Rarity = "Épico", Icon = "💪", Description = "Brazos cruzados y mirada al frente." },
	Senala = { Name = "Señala al frente", Rarity = "Legendario", Icon = "👉", Description = "Señala a la cámara: el siguiente eres tú." },
}

Poses.Intros = {
	Destello = { Name = "Destello dorado", Rarity = "Común", Icon = "✨", Description = "Destello y chispas doradas al salir de MVP." },
	Giro = { Name = "Media vuelta", Rarity = "Épico", Icon = "🌀", Price = 1200, Description = "Gira sobre sí mismo antes de mirar a la cámara." },
	Ascuas = { Name = "Lluvia de ascuas", Rarity = "Épico", Icon = "🔥", Description = "Ascuas que suben alrededor del MVP." },
	Columna = { Name = "Columna de luz", Rarity = "Legendario", Icon = "🌟", Description = "Una columna de luz cae sobre el MVP." },
}

Poses.Default = "Ready"
Poses.DefaultIntro = "Destello"

function Poses.Get(id)
	return Poses.List[id] or Poses.List[Poses.Default]
end

function Poses.GetIntro(id)
	return Poses.Intros[id] or Poses.Intros[Poses.DefaultIntro]
end

return Poses
