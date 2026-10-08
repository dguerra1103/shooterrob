-- Disposición de los controles táctiles (Fase 12). Lógica pura y compartida: el cliente la usa para
-- colocar los botones y el servidor para validar la disposición que guarda cada jugador.
--
-- Idea: los botones de la derecha se colocan alrededor del botón de saltar de Roblox (que no es
-- nuestro y cambia de sitio y de tamaño según la pantalla), así que todo se mide desde su centro. Los
-- de la izquierda, desde la esquina de abajo; los de poco uso, desde la de arriba a la derecha. Las
-- distancias están en píxeles de teléfono y se multiplican por la unidad de cada tipo de pantalla.
--
-- Jerarquía: DISPARAR (el más grande) > APUNTAR > recargar, agacharse, granada, cuerpo a cuerpo >
-- marcador, emotes, grafiti. El centro de la pantalla queda libre (CenterClear).
local MobileHUD = {}

-- Tipos de pantalla (pocos, a propósito). DESKTOP no usa botones táctiles.
MobileHUD.Breakpoints = { "PHONE_SMALL", "PHONE", "TABLET", "DESKTOP" }
local UNIT = { PHONE_SMALL = 0.8, PHONE = 1, TABLET = 1.3, DESKTOP = 1 }

function MobileHUD.Breakpoint(size: Vector2, touch: boolean): string
	if not touch then
		return "DESKTOP"
	end
	local short = math.min(size.X, size.Y)
	if short < 360 then
		return "PHONE_SMALL"
	elseif short <= 500 then
		return "PHONE"
	end
	return "TABLET"
end

function MobileHUD.Unit(breakpoint: string): number
	return UNIT[breakpoint] or 1
end

-- Botón de saltar de Roblox (PlayerModule/TouchJump): 70 px en pantallas con el lado corto ≤ 500 y
-- 120 en las demás. Devuelve su centro y su diámetro. Si el botón real existe, se usa el real.
function MobileHUD.JumpRect(size: Vector2): (Vector2, number)
	local small = math.min(size.X, size.Y) <= 500
	local d = small and 70 or 120
	local left = size.X - (d * 1.5 - 10)
	local top = small and (size.Y - d - 20) or (size.Y - d * 1.75)
	return Vector2.new(left + d / 2, top + d / 2), d
end

-- Controles. Anchor: "Jump" (desde el centro del salto), "BottomLeft" (x desde la izquierda, y desde
-- abajo) o "TopRight" (x desde la derecha, y desde arriba). Size: diámetro (o Vector2 si es una
-- tarjeta). Hit: la zona que se puede tocar es algo mayor que el dibujo. Role: Primary, Action
-- (combate), Utility (poco uso: se ve menos y se apaga más al apuntar).
MobileHUD.Controls = {
	{ Id = "Fire", Name = "Disparar", Icon = "Fire", Role = "Primary", Anchor = "Jump", Offset = Vector2.new(-120, -82), Size = 84, Hit = 1.25 },
	{ Id = "Aim", Name = "Apuntar", Icon = "Aim", Role = "Primary", Anchor = "Jump", Offset = Vector2.new(-14, -116), Size = 56, Hit = 1.15 },
	{ Id = "Slide", Name = "Agacharse", Icon = "Crouch", Role = "Action", Anchor = "Jump", Offset = Vector2.new(-100, 7), Size = 50, Hit = 1.15 },
	{ Id = "Reload", Name = "Recargar", Icon = "Reload", Role = "Action", Anchor = "Jump", Offset = Vector2.new(-214, -48), Size = 48, Hit = 1.15 },
	{ Id = "Grenade", Name = "Granada", Icon = "Grenade", Role = "Action", Anchor = "Jump", Offset = Vector2.new(-178, -168), Size = 48, Hit = 1.15, Fade = true },
	{ Id = "Airstrike", Name = "Ataque aéreo", Icon = "Airstrike", Role = "Action", Anchor = "Jump", Offset = Vector2.new(-98, -194), Size = 46, Hit = 1.15, Fade = true },
	{ Id = "Melee", Name = "Cuerpo a cuerpo", Icon = "Melee", Role = "Action", Anchor = "Jump", Offset = Vector2.new(-8, -178), Size = 46, Hit = 1.15, Fade = true },
	{ Id = "SwapWeapon", Name = "Cambiar arma", Icon = "Card", Role = "Action", Anchor = "Jump", Offset = Vector2.new(-266, 23), Size = Vector2.new(136, 50), Hit = 1.05 },
	{ Id = "AbilityDash", Name = "Impulso", Icon = "Dash", Role = "Action", Anchor = "BottomLeft", Offset = Vector2.new(40, -165), Size = 46, Hit = 1.15, Fade = true },
	{ Id = "AbilityJump", Name = "Supersalto", Icon = "SuperJump", Role = "Action", Anchor = "BottomLeft", Offset = Vector2.new(94, -165), Size = 46, Hit = 1.15, Fade = true },
	{ Id = "AbilityPotion", Name = "Poción", Icon = "Potion", Role = "Action", Anchor = "BottomLeft", Offset = Vector2.new(148, -165), Size = 46, Hit = 1.15, Fade = true },
	{ Id = "Sprint", Name = "Correr", Icon = "Sprint", Role = "Action", Anchor = "BottomLeft", Offset = Vector2.new(202, -165), Size = 46, Hit = 1.15 },
	{ Id = "LeftFire", Name = "Disparo izquierdo", Icon = "Fire", Role = "Primary", Anchor = "BottomLeft", Offset = Vector2.new(186, -262), Size = 64, Hit = 1.2 },
	{ Id = "Scoreboard", Name = "Marcador", Icon = "Scoreboard", Role = "Utility", Anchor = "TopRight", Offset = Vector2.new(-24, 26), Size = 38, Hit = 1.15, Fade = true },
	{ Id = "Emotes", Name = "Emotes", Icon = "Emotes", Role = "Utility", Anchor = "TopRight", Offset = Vector2.new(-68, 26), Size = 38, Hit = 1.15, Fade = true },
	{ Id = "Spray", Name = "Grafiti", Icon = "Spray", Role = "Utility", Anchor = "TopRight", Offset = Vector2.new(-112, 26), Size = 38, Hit = 1.15, Fade = true },
	{ Id = "Menu", Name = "Menú y tienda", Icon = "Menu", Role = "Utility", Anchor = "TopRight", Offset = Vector2.new(-156, 26), Size = 38, Hit = 1.15, Fade = true },
}
MobileHUD.ById = {}
for _, control in MobileHUD.Controls do
	MobileHUD.ById[control.Id] = control
end

-- Lo que se ve por defecto de cada papel (multiplica la opacidad del fondo y del icono)
MobileHUD.RoleOpacity = { Primary = 1, Action = 0.85, Utility = 0.7 }
-- Al apuntar, los controles marcados con Fade se ven menos (no se esconden: siguen funcionando)
MobileHUD.AimFade = 0.45

-- Límites de lo que el jugador puede cambiar en el editor (y lo que acepta el servidor)
MobileHUD.Limits = {
	X = { 0, 1 }, -- centro, como fracción del ancho de la zona segura
	Y = { 0, 1 },
	S = { 0.6, 1.6 }, -- tamaño (× el de por defecto)
	O = { 0.25, 1 }, -- opacidad (× la de su papel)
}

-- Radio del centro de la pantalla que se deja libre (la mira, el hitmarker y los avisos de daño)
function MobileHUD.CenterClear(size: Vector2): number
	return math.min(size.X, size.Y) * 0.17
end

local function sizeVector(size: any, unit: number): Vector2
	if typeof(size) == "Vector2" then
		return size * unit
	end
	return Vector2.new(size, size) * unit
end

-- Posición por defecto (centro) y tamaño de un control en una pantalla de `size` (zona segura)
function MobileHUD.Default(control, size: Vector2, unit: number, jumpCenter: Vector2): (Vector2, Vector2)
	local offset = control.Offset * unit
	local center
	if control.Anchor == "Jump" then
		center = jumpCenter + offset
	elseif control.Anchor == "BottomLeft" then
		center = Vector2.new(offset.X, size.Y + offset.Y)
	else
		center = Vector2.new(size.X + offset.X, offset.Y)
	end
	return center, sizeVector(control.Size, unit)
end

local function clamp(value: any, limits: { number }): number?
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	return math.floor(math.clamp(value, limits[1], limits[2]) * 1000 + 0.5) / 1000
end

-- Limpia una disposición guardada: solo controles conocidos y números dentro de sus límites. Lo usa
-- el servidor antes de guardar (nunca se fía de lo que manda el cliente) y el cliente al cargarla.
function MobileHUD.Validate(raw: any): { [string]: { X: number?, Y: number?, S: number?, O: number? } }
	local clean = {}
	if type(raw) ~= "table" then
		return clean
	end
	for id, entry in raw do
		if type(id) == "string" and MobileHUD.ById[id] and type(entry) == "table" then
			local item = {}
			for key, limits in MobileHUD.Limits do
				item[key] = clamp(entry[key], limits)
			end
			-- (la posición va por parejas: o las dos o ninguna)
			if item.X == nil or item.Y == nil then
				item.X, item.Y = nil, nil
			end
			if next(item) then
				clean[id] = item
			end
		end
	end
	return clean
end

-- Disposición final: { [id] = { Center, Size, Hit, Opacity } } en píxeles de la zona segura.
-- opts: { Breakpoint, Jump = centro real del salto (opcional), Custom = disposición guardada }
function MobileHUD.Resolve(size: Vector2, options: { [string]: any }?)
	local opts: { [string]: any } = options or {}
	local breakpoint = opts.Breakpoint or MobileHUD.Breakpoint(size, true)
	local unit = MobileHUD.Unit(breakpoint)
	local jumpCenter = opts.Jump or (MobileHUD.JumpRect(size))
	local custom = MobileHUD.Validate(opts.Custom)
	local out = {}
	for _, control in MobileHUD.Controls do
		local center, dims = MobileHUD.Default(control, size, unit, jumpCenter)
		local opacity = MobileHUD.RoleOpacity[control.Role] or 1
		local own = custom[control.Id]
		if own then
			if own.X and own.Y then
				center = Vector2.new(own.X * size.X, own.Y * size.Y)
			end
			dims *= own.S or 1
			opacity *= own.O or 1
		end
		-- (que nunca se salga de la pantalla)
		local half = dims / 2
		center = Vector2.new(math.clamp(center.X, half.X, math.max(half.X, size.X - half.X)), math.clamp(center.Y, half.Y, math.max(half.Y, size.Y - half.Y)))
		out[control.Id] = { Center = center, Size = dims, Hit = dims * (control.Hit or 1), Opacity = math.clamp(opacity, 0.05, 1) }
	end
	return out
end

-- Pares de controles que se pisan (para las pruebas y el modo de depuración). `ids`: solo esos.
function MobileHUD.Overlaps(resolved, ids: { string }?, margin: number?): { { string } }
	local list = ids or {}
	if not ids then
		for _, control in MobileHUD.Controls do
			table.insert(list, control.Id)
		end
	end
	local pairs_ = {}
	local m: number = margin or 0
	for i = 1, #list do
		for j = i + 1, #list do
			local a, b = resolved[list[i]], resolved[list[j]]
			if a and b then
				local d = a.Center - b.Center
				local reach = (a.Size + b.Size) / 2 + Vector2.new(m, m)
				-- (círculos inscritos en su caja: se comparan como cajas recortadas)
				if math.abs(d.X) < reach.X * 0.86 and math.abs(d.Y) < reach.Y * 0.86 and d.Magnitude < (math.max(a.Size.X, a.Size.Y) + math.max(b.Size.X, b.Size.Y)) / 2 + m then
					table.insert(pairs_, { list[i], list[j] })
				end
			end
		end
	end
	return pairs_
end

return MobileHUD
