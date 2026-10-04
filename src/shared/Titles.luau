-- Títulos: un apodo que sale junto a tu nombre en el marcador (Tab) y en el chat. Unos se ganan
-- jugando (Stat/Goal, los mismos datos que los logros), otros se compran con monedas (Price) y uno es
-- solo para VIP. Se eligen en la pestaña Perfil.
local Titles = {}

local RGB = Color3.fromRGB

Titles.List = {
	Novato = { Name = "Novato", Color = RGB(200, 200, 210), Order = 1 },
	-- Ganados jugando
	Tirador = { Name = "Tirador", Color = RGB(120, 220, 120), Stat = "TotalKills", Goal = 100, Order = 2 },
	OjoDeHalcon = { Name = "Ojo de halcón", Color = RGB(90, 200, 255), Stat = "Headshots", Goal = 100, Order = 3 },
	Veterano = { Name = "Veterano", Color = RGB(180, 160, 120), Stat = "Matches", Goal = 100, Order = 4 },
	Imparable = { Name = "Imparable", Color = RGB(255, 140, 50), Stat = "BestStreak", Goal = 10, Order = 5 },
	Cazador = { Name = "Cazador", Color = RGB(255, 90, 90), Stat = "TotalKills", Goal = 1000, Order = 6 },
	Invicto = { Name = "Invicto", Color = RGB(255, 215, 60), Stat = "Wins", Goal = 50, Order = 7 },
	Diamante = { Name = "Diamante", Color = RGB(120, 230, 255), Stat = "RankBest", Goal = 5, Order = 8 },
	Leyenda = { Name = "Leyenda", Color = RGB(255, 200, 40), Stat = "TotalKills", Goal = 5000, Order = 9 },
	Campeon = { Name = "Campeón", Color = RGB(255, 120, 255), Stat = "RankBest", Goal = 6, Order = 10 },
	Companero = { Name = "Compañero fiel", Color = RGB(130, 200, 255), Stat = "Assists", Goal = 100, Order = 11 },
	-- Con monedas
	Payaso = { Name = "Payaso de feria", Color = RGB(255, 120, 180), Price = 800, Order = 12 },
	Cazazombis = { Name = "Cazazombis", Color = RGB(120, 230, 90), Price = 1200, Order = 13 },
	Forajido = { Name = "Forajido", Color = RGB(215, 140, 80), Price = 1500, Order = 14 },
	ReyDelBarrio = { Name = "Rey del barrio", Color = RGB(255, 170, 60), Price = 2500, Order = 15 },
	Sheriff = { Name = "Sheriff", Color = RGB(255, 205, 70), Price = 3000, Order = 16 },
	Millonario = { Name = "Millonario", Color = RGB(255, 225, 90), Price = 10000, Order = 17 },
	-- Pase VIP
	VIP = { Name = "VIP", Color = RGB(255, 200, 60), VIPOnly = true, Order = 18 },
}

-- Los datos que se usan para los títulos ganados jugando (deben estar en los datos del jugador)
Titles.Stats = { "TotalKills", "Headshots", "Matches", "BestStreak", "Wins", "RankBest", "Assists" }

function Titles.Get(id)
	return Titles.List[id] or Titles.List.Novato
end

-- ¿Lo tiene? data: datos del jugador (o su vista en el cliente); isVIP: tiene el pase VIP
function Titles.Owns(data, id, isVIP)
	local title = Titles.List[id]
	if not title or not data then
		return false
	end
	if title.Stat then
		return (tonumber(data[title.Stat]) or 0) >= title.Goal
	elseif title.Price then
		return type(data.Titles) == "table" and data.Titles[id] == true
	elseif title.VIPOnly then
		return isVIP == true
	end
	return true
end

-- Lo que falta para conseguirlo (texto corto para el menú)
function Titles.Requirement(id)
	local title = Titles.List[id]
	if not title then
		return ""
	elseif title.Stat == "TotalKills" then
		return title.Goal .. " bajas"
	elseif title.Stat == "Headshots" then
		return title.Goal .. " a la cabeza"
	elseif title.Stat == "Matches" then
		return title.Goal .. " partidas"
	elseif title.Stat == "BestStreak" then
		return "racha de " .. title.Goal
	elseif title.Stat == "Wins" then
		return title.Goal .. " victorias"
	elseif title.Stat == "RankBest" then
		return title.Goal >= 6 and "rango Campeón" or "rango Diamante"
	elseif title.Stat == "Assists" then
		return title.Goal .. " asistencias"
	elseif title.VIPOnly then
		return "👑 Solo VIP"
	end
	return ""
end

-- Ordenados para enseñarlos
function Titles.Sorted()
	local ids = {}
	for id in Titles.List do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return Titles.List[a].Order < Titles.List[b].Order
	end)
	return ids
end

return Titles
