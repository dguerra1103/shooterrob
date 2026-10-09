-- Iconos de los controles táctiles dibujados con formas (Fase 12; unificados en la Fase 15): un solo
-- estilo para todos, sin emojis (cada móvil los dibuja distinto) y sin imágenes subidas. Coordenadas
-- de 0 a 1 dentro del hueco del icono; `px` es su tamaño en píxeles.
--
-- Fase 15: todos los trazos tienen EL MISMO GROSOR (LINE, fracción del hueco; los anillos, LINE × px)
-- y las piezas macizas se reservan para la silueta principal (bala, cargador, granada, cuchillo...),
-- así ningún icono se ve grueso junto a otro finísimo.
local TouchIcons = {}

local WHITE = Color3.new(1, 1, 1)
local LINE = 0.09 -- grosor de trazo común (fracción del hueco del icono)

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

-- Anillo con el grosor común
local function ring(parent, cx, cy, d, px)
	local frame = piece(parent, cx, cy, d, d, 0, true)
	frame.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = WHITE
	stroke.Thickness = math.max(1.5, px * LINE)
	stroke.Parent = frame
	return frame
end

-- Trazo recto de (x1, y1) a (x2, y2) con el grosor común (en coordenadas del hueco)
local function line(parent, x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	local frame = piece(parent, (x1 + x2) / 2, (y1 + y2) / 2, length + LINE, LINE, math.deg(math.atan2(dy, dx)), true)
	return frame
end

-- Chevrón (V) con la punta en (cx, cy) hacia `dir` ("Up", "Down", "Right", "Left"), brazos de `s`
local function chevron(parent, cx, cy, s, dir)
	local h = s * 0.5
	if dir == "Up" then
		line(parent, cx - h, cy + h * 0.8, cx, cy)
		line(parent, cx + h, cy + h * 0.8, cx, cy)
	elseif dir == "Down" then
		line(parent, cx - h, cy - h * 0.8, cx, cy)
		line(parent, cx + h, cy - h * 0.8, cx, cy)
	elseif dir == "Left" then
		line(parent, cx + h * 0.8, cy - h, cx, cy)
		line(parent, cx + h * 0.8, cy + h, cx, cy)
	else
		line(parent, cx - h * 0.8, cy - h, cx, cy)
		line(parent, cx - h * 0.8, cy + h, cx, cy)
	end
end

local DRAW = {}

DRAW.Fire = function(p)
	-- Bala: punta redonda, cuerpo y culote (la silueta principal, maciza)
	piece(p, 0.5, 0.34, 0.26, 0.26, 0, true)
	piece(p, 0.5, 0.56, 0.26, 0.4, 0, 2)
	piece(p, 0.5, 0.82, 0.34, LINE, 0, true)
end

DRAW.Aim = function(p, px)
	-- Mira: anillo, punto y cuatro marcas
	ring(p, 0.5, 0.5, 0.56, px)
	piece(p, 0.5, 0.5, 0.12, 0.12, 0, true)
	line(p, 0.5, 0.04, 0.5, 0.18)
	line(p, 0.5, 0.82, 0.5, 0.96)
	line(p, 0.04, 0.5, 0.18, 0.5)
	line(p, 0.82, 0.5, 0.96, 0.5)
end

DRAW.Jump = function(p)
	-- Saltar: chevrón hacia arriba sobre el suelo (pareja de agacharse)
	chevron(p, 0.5, 0.28, 0.62, "Up")
	line(p, 0.24, 0.78, 0.76, 0.78)
end

DRAW.Crouch = function(p)
	-- Agacharse: chevrón hacia abajo sobre el suelo
	chevron(p, 0.5, 0.56, 0.62, "Down")
	line(p, 0.24, 0.8, 0.76, 0.8)
end

DRAW.Reload = function(p)
	-- Cargador con dos balas asomando
	piece(p, 0.5, 0.6, 0.3, 0.5, 10, 3)
	piece(p, 0.43, 0.25, 0.11, 0.15, 10, true)
	piece(p, 0.57, 0.27, 0.11, 0.15, 10, true)
end

DRAW.Grenade = function(p, px)
	-- Cuerpo redondo, palanca y anilla
	piece(p, 0.5, 0.62, 0.46, 0.48, 0, true)
	line(p, 0.46, 0.34, 0.78, 0.24)
	ring(p, 0.3, 0.28, 0.18, px)
end

DRAW.Airstrike = function(p, px)
	-- Diana con una flecha que cae
	ring(p, 0.5, 0.66, 0.44, px)
	piece(p, 0.5, 0.66, 0.1, 0.1, 0, true)
	line(p, 0.5, 0.06, 0.5, 0.36)
	chevron(p, 0.5, 0.4, 0.34, "Down")
end

DRAW.Melee = function(p)
	-- Cuchillo en diagonal
	piece(p, 0.57, 0.41, 0.15, 0.52, 45, 3)
	piece(p, 0.3, 0.68, 0.15, 0.26, 45, 2)
	line(p, 0.27, 0.51, 0.49, 0.73)
end

DRAW.Dash = function(p)
	-- Líneas de velocidad y chevrón
	line(p, 0.12, 0.34, 0.34, 0.34)
	line(p, 0.06, 0.5, 0.36, 0.5)
	line(p, 0.12, 0.66, 0.34, 0.66)
	chevron(p, 0.78, 0.5, 0.56, "Right")
end

DRAW.SuperJump = function(p)
	-- Doble chevrón hacia arriba
	chevron(p, 0.5, 0.22, 0.6, "Up")
	chevron(p, 0.5, 0.5, 0.6, "Up")
end

DRAW.Potion = function(p)
	-- Frasco: cuerpo redondo, cuello y tapón
	piece(p, 0.5, 0.64, 0.46, 0.44, 0, true)
	piece(p, 0.5, 0.36, 0.16, 0.2, 0, 2)
	line(p, 0.38, 0.22, 0.62, 0.22)
end

DRAW.Sprint = function(p)
	-- Doble chevrón hacia delante
	chevron(p, 0.56, 0.5, 0.56, "Right")
	chevron(p, 0.82, 0.5, 0.56, "Right")
end

DRAW.Scoreboard = function(p)
	-- Lista: tres filas
	for _, y in { 0.28, 0.5, 0.72 } do
		piece(p, 0.2, y, 0.12, 0.12, 0, true)
		line(p, 0.36, y, 0.84, y)
	end
end

DRAW.Emotes = function(p, px)
	-- Cara: anillo, ojos y boca
	ring(p, 0.5, 0.5, 0.7, px)
	piece(p, 0.38, 0.42, 0.1, 0.1, 0, true)
	piece(p, 0.62, 0.42, 0.1, 0.1, 0, true)
	line(p, 0.38, 0.64, 0.62, 0.64)
end

DRAW.Spray = function(p)
	-- Bote: cuerpo, boquilla y gotas
	piece(p, 0.42, 0.6, 0.28, 0.46, 0, 3)
	piece(p, 0.42, 0.3, 0.14, 0.1, 0, 2)
	piece(p, 0.68, 0.26, 0.08, 0.08, 0, true)
	piece(p, 0.78, 0.36, 0.08, 0.08, 0, true)
	piece(p, 0.78, 0.16, 0.08, 0.08, 0, true)
end

DRAW.Menu = function(p)
	-- Engranaje: dientes, rueda y hueco (el hueco no se tiñe: va del color del fondo)
	for _, rotation in { 0, 45, 90, 135 } do
		piece(p, 0.5, 0.5, 0.86, 0.16, rotation, 2)
	end
	piece(p, 0.5, 0.5, 0.62, 0.62, 0, true)
	local hole = piece(p, 0.5, 0.5, 0.26, 0.26, 0, true, Color3.fromRGB(14, 16, 22))
	hole.Name = "IconHole"
end

DRAW.Swap = function(p)
	-- Cambiar: dos flechas opuestas
	line(p, 0.14, 0.34, 0.8, 0.34)
	chevron(p, 0.86, 0.34, 0.36, "Right")
	line(p, 0.2, 0.66, 0.86, 0.66)
	chevron(p, 0.14, 0.66, 0.36, "Left")
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
TouchIcons.Line = LINE
return TouchIcons
