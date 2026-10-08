-- Iconos de los controles táctiles dibujados con formas (Fase 12): un solo estilo para todos, sin
-- emojis (cada móvil los dibuja distinto) y sin imágenes subidas. Coordenadas de 0 a 1 dentro del
-- hueco del icono; `px` es su tamaño en píxeles (para el grosor de los trazos).
local TouchIcons = {}

local WHITE = Color3.new(1, 1, 1)

local function piece(parent, cx, cy, w, h, rotation, round: any, color: Color3?)
	local frame = Instance.new("Frame")
	frame.Name = "IconPiece"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(cx, cy)
	frame.Size = UDim2.fromScale(w, h)
	frame.Rotation = rotation or 0
	frame.BorderSizePixel = 0
	frame.BackgroundTransparency = 0
	frame.BackgroundColor3 = color or WHITE
	if round then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = if type(round) == "number" then UDim.new(0, round) else UDim.new(0.5, 0)
		corner.Parent = frame
	end
	frame.Parent = parent
	return frame
end

local function ring(parent, cx, cy, d, thickness, color)
	local frame = piece(parent, cx, cy, d, d, 0, true)
	frame.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or WHITE
	stroke.Thickness = thickness
	stroke.Parent = frame
	return frame
end

-- Chevrón (V) con la punta hacia `dir` ("Up", "Down", "Right")
local function chevron(parent, cx, cy, s, dir, t)
	local half = s * 0.36
	if dir == "Down" then
		piece(parent, cx - half * 0.5, cy, half * 1.3, t, 40, true)
		piece(parent, cx + half * 0.5, cy, half * 1.3, t, -40, true)
	elseif dir == "Up" then
		piece(parent, cx - half * 0.5, cy, half * 1.3, t, -40, true)
		piece(parent, cx + half * 0.5, cy, half * 1.3, t, 40, true)
	else
		piece(parent, cx, cy - half * 0.5, t, half * 1.3, -40, true)
		piece(parent, cx, cy + half * 0.5, t, half * 1.3, 40, true)
	end
end

local DRAW = {}

DRAW.Fire = function(p, px)
	-- Bala: punta redonda, cuerpo y culote
	piece(p, 0.5, 0.36, 0.24, 0.24, 0, true)
	piece(p, 0.5, 0.56, 0.24, 0.38, 0, 2)
	piece(p, 0.5, 0.8, 0.32, 0.07, 0, 2)
	local _ = px
end

DRAW.Aim = function(p, px)
	-- Mira: anillo, punto y cuatro marcas
	local t = math.max(2, px * 0.07)
	ring(p, 0.5, 0.5, 0.56, t)
	piece(p, 0.5, 0.5, 0.11, 0.11, 0, true)
	piece(p, 0.5, 0.12, 0.07, 0.16, 0, true)
	piece(p, 0.5, 0.88, 0.07, 0.16, 0, true)
	piece(p, 0.12, 0.5, 0.16, 0.07, 0, true)
	piece(p, 0.88, 0.5, 0.16, 0.07, 0, true)
end

DRAW.Crouch = function(p)
	-- Bajar: chevrón hacia abajo sobre el suelo
	chevron(p, 0.5, 0.42, 0.9, "Down", 0.1)
	piece(p, 0.5, 0.76, 0.56, 0.08, 0, true)
end

DRAW.Reload = function(p)
	-- Cargador con dos balas asomando
	piece(p, 0.5, 0.58, 0.3, 0.52, 10, 3)
	piece(p, 0.42, 0.24, 0.1, 0.14, 10, true)
	piece(p, 0.56, 0.26, 0.1, 0.14, 10, true)
end

DRAW.Grenade = function(p, px)
	-- Cuerpo redondo, palanca y anilla
	piece(p, 0.5, 0.6, 0.48, 0.5, 0, true)
	piece(p, 0.6, 0.3, 0.3, 0.09, -20, true)
	ring(p, 0.3, 0.28, 0.18, math.max(1.5, px * 0.05))
end

DRAW.Airstrike = function(p, px)
	-- Diana con una flecha que cae
	ring(p, 0.5, 0.64, 0.46, math.max(2, px * 0.06))
	piece(p, 0.5, 0.64, 0.1, 0.1, 0, true)
	piece(p, 0.5, 0.26, 0.08, 0.34, 0, true)
	chevron(p, 0.5, 0.42, 0.5, "Down", 0.08)
end

DRAW.Melee = function(p)
	-- Cuchillo en diagonal
	piece(p, 0.56, 0.42, 0.14, 0.52, 45, 3)
	piece(p, 0.3, 0.68, 0.16, 0.26, 45, 2)
	piece(p, 0.39, 0.59, 0.26, 0.06, 45, true)
end

DRAW.Dash = function(p)
	-- Líneas de velocidad y chevrón
	piece(p, 0.26, 0.36, 0.26, 0.07, 0, true)
	piece(p, 0.22, 0.5, 0.34, 0.07, 0, true)
	piece(p, 0.26, 0.64, 0.26, 0.07, 0, true)
	chevron(p, 0.66, 0.5, 0.7, "Right", 0.1)
end

DRAW.SuperJump = function(p)
	-- Flecha hacia arriba sobre el suelo (doble chevrón)
	chevron(p, 0.5, 0.36, 0.8, "Up", 0.1)
	chevron(p, 0.5, 0.56, 0.8, "Up", 0.1)
	piece(p, 0.5, 0.8, 0.5, 0.07, 0, true)
end

DRAW.Potion = function(p, px)
	-- Frasco: cuerpo redondo, cuello y tapón
	piece(p, 0.5, 0.64, 0.46, 0.44, 0, true)
	piece(p, 0.5, 0.36, 0.16, 0.2, 0, 2)
	piece(p, 0.5, 0.22, 0.24, 0.08, 0, 2)
	local _ = px
end

DRAW.Sprint = function(p)
	-- Doble chevrón hacia delante
	chevron(p, 0.4, 0.5, 0.7, "Right", 0.1)
	chevron(p, 0.62, 0.5, 0.7, "Right", 0.1)
end

DRAW.Scoreboard = function(p)
	-- Lista: tres filas
	for i, y in { 0.3, 0.5, 0.7 } do
		piece(p, 0.24, y, 0.1, 0.1, 0, true)
		piece(p, 0.58, y, 0.5, 0.08, 0, true)
		local _ = i
	end
end

DRAW.Emotes = function(p, px)
	-- Cara: anillo, ojos y boca
	ring(p, 0.5, 0.5, 0.64, math.max(1.5, px * 0.06))
	piece(p, 0.38, 0.42, 0.09, 0.09, 0, true)
	piece(p, 0.62, 0.42, 0.09, 0.09, 0, true)
	piece(p, 0.5, 0.64, 0.3, 0.07, 0, true)
end

DRAW.Spray = function(p)
	-- Bote: cuerpo, boquilla y gotas
	piece(p, 0.42, 0.6, 0.28, 0.46, 0, 3)
	piece(p, 0.42, 0.3, 0.14, 0.1, 0, 2)
	piece(p, 0.66, 0.26, 0.07, 0.07, 0, true)
	piece(p, 0.76, 0.34, 0.07, 0.07, 0, true)
	piece(p, 0.74, 0.18, 0.07, 0.07, 0, true)
end

DRAW.Menu = function(p)
	-- Engranaje: dientes, rueda y hueco (el hueco no se tiñe: va del color del fondo)
	for _, rotation in { 0, 45, 90, 135 } do
		piece(p, 0.5, 0.5, 0.84, 0.16, rotation, 2)
	end
	piece(p, 0.5, 0.5, 0.62, 0.62, 0, true)
	local hole = piece(p, 0.5, 0.5, 0.26, 0.26, 0, true, Color3.fromRGB(14, 16, 22))
	hole.Name = "IconHole"
end

-- Dibuja el icono `kind` en `parent` (que ocupa el hueco del icono). Devuelve true si existe.
function TouchIcons.Draw(kind: string, parent: Instance, px: number?): boolean
	local draw = DRAW[kind]
	if not draw then
		return false
	end
	draw(parent, px or 40)
	return true
end

-- Cambia el color de todo el icono (estado: apuntando, recarga necesaria...)
function TouchIcons.Tint(parent: Instance, color: Color3)
	for _, child in parent:GetDescendants() do
		if child:IsA("Frame") and child.Name == "IconPiece" then
			if child.BackgroundTransparency < 1 then
				child.BackgroundColor3 = color
			end
			local stroke = child:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = color
			end
		end
	end
end

TouchIcons.Kinds = DRAW
return TouchIcons
