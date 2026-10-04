-- Grafitis (tecla J): un dibujo que pintas en la pared o el suelo que tienes delante. Se compran con
-- monedas en la pestaña Efectos. Cada jugador tiene un grafiti a la vez en el mapa (el nuevo
-- sustituye al anterior) y se borran al cambiar de mapa.
local Sprays = {}

local RGB = Color3.fromRGB

-- Icon: emoji grande; Caption: texto debajo (opcional); Color: color del texto; Bg: fondo redondo
Sprays.List = {
	Default = { Name = "GG", Rarity = "Común", Icon = "GG", Color = RGB(255, 255, 255), Bg = RGB(50, 130, 255) },
	Fuego = { Name = "En llamas", Rarity = "Raro", Icon = "🔥", Caption = "ON FIRE", Color = RGB(255, 200, 60), Bg = RGB(200, 50, 30), Price = 200 },
	Cien = { Name = "Cien", Rarity = "Raro", Icon = "💯", Color = RGB(255, 255, 255), Bg = RGB(255, 235, 235), Price = 250 },
	Calavera = { Name = "Calavera", Rarity = "Raro", Icon = "💀", Caption = "RIP", Color = RGB(235, 235, 235), Bg = RGB(30, 30, 40), Price = 300 },
	Calabaza = { Name = "Calabaza", Rarity = "Épico", Icon = "🎃", Caption = "BOO!", Color = RGB(255, 150, 30), Bg = RGB(60, 20, 80), Price = 400 },
	Payaso = { Name = "Payaso", Rarity = "Épico", Icon = "🤡", Caption = "EZ", Color = RGB(255, 80, 120), Bg = RGB(255, 240, 120), Price = 450 },
	Gato = { Name = "Gato chulo", Rarity = "Épico", Icon = "😼", Caption = "MIAU", Color = RGB(255, 255, 255), Bg = RGB(140, 80, 220), Price = 500 },
	Corona = { Name = "Corona", Rarity = "Legendario", Icon = "👑", Caption = "REY", Color = RGB(255, 215, 60), Bg = RGB(120, 20, 40), Price = 800 },
	Diamante = { Name = "Diamante", Rarity = "Legendario", Icon = "💎", Caption = "PRO", Color = RGB(150, 235, 255), Bg = RGB(20, 40, 90), Price = 1000 },
	-- Solo para quien tiene el pase VIP (no se vende con monedas)
	VIP = { Name = "VIP", Rarity = "Legendario", Icon = "👑", Caption = "VIP", Color = RGB(255, 215, 60), Bg = RGB(90, 30, 140), VIPOnly = true },
}

Sprays.Cooldown = 6 -- segundos entre grafitis
Sprays.Range = 14 -- distancia máxima a la pared (studs)
Sprays.Size = 4.5 -- tamaño del grafiti (studs)

function Sprays.Get(id)
	return Sprays.List[id] or Sprays.List.Default
end

-- ¿Puede usarlo? (los comprados, más el de VIP si es VIP)
function Sprays.Owns(owned, id, isVIP)
	local spray = Sprays.List[id]
	if not spray then
		return false
	end
	if spray.VIPOnly then
		return isVIP == true
	end
	return owned ~= nil and owned[id] == true
end

-- Dibuja el grafiti dentro de `parent` (un SurfaceGui o un marco del menú)
function Sprays.Draw(id, parent)
	local spray = Sprays.Get(id)
	local circle = Instance.new("Frame")
	circle.Name = "Spray"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.Size = UDim2.fromScale(0.94, 0.94)
	circle.BackgroundColor3 = spray.Bg
	circle.BackgroundTransparency = 0.1
	circle.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = circle
	local ring = Instance.new("UIStroke")
	ring.Color = Color3.new(1, 1, 1)
	ring.Transparency = 0.2
	ring.Thickness = 3
	ring.Parent = circle
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.fromScale(0.5, spray.Caption and 0.12 or 0.18)
	icon.Size = UDim2.fromScale(0.7, spray.Caption and 0.52 or 0.64)
	icon.Text = spray.Icon
	icon.TextScaled = true
	icon.Font = Enum.Font.FredokaOne
	icon.TextColor3 = spray.Color
	icon.Parent = circle
	if spray.Caption then
		local caption = Instance.new("TextLabel")
		caption.BackgroundTransparency = 1
		caption.AnchorPoint = Vector2.new(0.5, 0)
		caption.Position = UDim2.fromScale(0.5, 0.64)
		caption.Size = UDim2.fromScale(0.72, 0.22)
		caption.Text = spray.Caption
		caption.TextScaled = true
		caption.Font = Enum.Font.FredokaOne
		caption.TextColor3 = spray.Color
		caption.TextStrokeTransparency = 0.4
		caption.Parent = circle
	end
	return circle
end

return Sprays
