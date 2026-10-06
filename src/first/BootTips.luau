-- Textos de la pantalla de arranque (en ReplicatedFirst: tienen que estar antes que nada). Por idioma:
-- se usa el del jugador si existe y, si no, español. Para añadir uno, copia la tabla "es".
return {
	es = {
		Phases = {
			Interface = "CARGANDO INTERFAZ",
			Weapons = "CARGANDO ARMAS",
			Maps = "CARGANDO MAPAS",
			Match = "PREPARANDO PARTIDA",
			Building = "CONSTRUYENDO %s",
			Ready = "LISTO",
		},
		Tips = {
			"Los disparos a la cabeza hacen mucho más daño",
			"Apuntar (clic derecho) reduce la dispersión: dispara apuntando a media distancia",
			"Cambia de clase antes de desplegar: la última que usaste viene marcada",
			"Los flancos ganan partidas: no corras siempre por el centro",
			"Gana partidas para subir de rango: de Bronce a Campeón",
			"Con 3 bajas seguidas tienes Radar; con 5, Ataque aéreo",
			"Tus amigos juegan en tu equipo y ganáis más XP y monedas",
			"En Buscar y destruir solo hay una vida por ronda: juega con tu equipo",
			"Recarga a cubierto: el enemigo escucha el cargador",
			"Las misiones diarias dan XP y monedas: míralas en el lobby",
		},
	},
	en = {
		Phases = {
			Interface = "LOADING INTERFACE",
			Weapons = "LOADING WEAPONS",
			Maps = "LOADING MAPS",
			Match = "PREPARING MATCH",
			Building = "BUILDING %s",
			Ready = "READY",
		},
		Tips = {
			"Headshots deal much more damage",
			"Aiming (right click) tightens your spread: aim at mid range",
			"Change class before deploying: your last one is preselected",
			"Flanks win matches: don't always run through the middle",
			"Win matches to rank up: from Bronze to Champion",
			"3 kills in a row gives Radar; 5 gives an Airstrike",
			"Friends play on your team and you all earn more XP and coins",
			"Search and Destroy has one life per round: stick with your team",
			"Reload behind cover: enemies hear the magazine",
			"Daily missions give XP and coins: check them in the lobby",
		},
	},
}
