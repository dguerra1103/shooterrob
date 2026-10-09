-- Disposición de los controles táctiles (Fase 12; rehecha en la Fase 15 para pantallas alargadas como
-- el Galaxy S26 Ultra). Lógica pura y compartida: el cliente la usa para colocar los botones y el
-- servidor para validar la disposición que guarda cada jugador.
--
-- Idea (Fase 15): nada se mide desde el botón de saltar de Roblox (ahora el salto es nuestro, va en el
-- grupo de combate). Cada pantalla se clasifica por su FORMA (proporción y lado corto de la pantalla
-- real, nunca por el modelo del dispositivo) y la disposición se calcula sobre la ZONA SEGURA:
--   * escala lógica = lado corto de la pantalla / 390 (un teléfono de referencia de 844×390), con
--     topes por clase: los botones miden lo mismo para el pulgar en cualquier teléfono;
--   * GRUPO DE COMBATE del pulgar derecho: DISPARAR es el centro y el resto se coloca alrededor
--     (apuntar arriba a la izquierda, salto a la derecha, agacharse debajo, recargar junto a la
--     munición...). En pantallas alargadas se mete hacia dentro (no se pega al borde físico);
--   * pulgar izquierdo: granada y habilidades sobre el joystick;
--   * poco uso (menú, marcador, emotes, grafiti): una tira pequeña arriba a la derecha.
-- Jerarquía: DISPARAR > APUNTAR > salto y agacharse > recargar > granada y cuerpo a cuerpo > poco uso.
-- El centro (mira) y una zona grande de la derecha (girar la cámara) quedan libres (Zones).
local MobileHUD = {}

-- Versión de la disposición por defecto. Las disposiciones propias guardadas son fracciones de la
-- zona segura y siguen valiendo; ver MigrateLayout.
MobileHUD.LayoutVersion = 2

-- Clases de pantalla (pocas, a propósito). DESKTOP no usa botones táctiles.
MobileHUD.Breakpoints = { "COMPACT_PHONE", "STANDARD_PHONE", "ULTRAWIDE_PHONE", "TABLET", "DESKTOP" }

-- Pantalla de referencia de la escala lógica (lado corto) y topes de la escala por clase
local BASE_SHORT = 390
local SCALE_LIMITS = {
	COMPACT_PHONE = { 0.78, 0.9 },
	STANDARD_PHONE = { 0.88, 1 },
	ULTRAWIDE_PHONE = { 0.95, 1.12 },
	TABLET = { 1.1, 1.25 },
	DESKTOP = { 1, 1 },
}
-- Proporción a partir de la que un teléfono es alargado (19,5:9 = 2,17; 20:9 = 2,22; 16:9 = 1,78)
MobileHUD.UltrawideAspect = 1.95

-- Clasifica una pantalla. `size`: zona segura; `screen`: pantalla entera (ViewportSize), opcional.
-- La forma se mide en la pantalla entera (la muesca o la barra de Roblox no la cambian).
function MobileHUD.Classify(size: Vector2, touch: boolean, screen: Vector2?): string
	if not touch then
		return "DESKTOP"
	end
	local full = screen or size
	local short = math.min(full.X, full.Y)
	local aspect = math.max(full.X, full.Y) / math.max(1, short)
	if short >= 560 then
		return "TABLET"
	elseif short < 350 then
		return "COMPACT_PHONE"
	elseif aspect >= MobileHUD.UltrawideAspect then
		return "ULTRAWIDE_PHONE"
	end
	return "STANDARD_PHONE"
end
-- (nombre de la Fase 12)
MobileHUD.Breakpoint = MobileHUD.Classify

-- Escala lógica: lado corto de la pantalla entera / 390, con los topes de su clase
function MobileHUD.Scale(class: string, screen: Vector2): number
	local limits = SCALE_LIMITS[class] or SCALE_LIMITS.STANDARD_PHONE
	return math.clamp(math.min(screen.X, screen.Y) / BASE_SHORT, limits[1], limits[2])
end

-- (compatibilidad con la Fase 12: escala típica de una clase)
function MobileHUD.Unit(class: string): number
	local limits = SCALE_LIMITS[class] or SCALE_LIMITS.STANDARD_PHONE
	return (limits[1] + limits[2]) / 2
end

-- Centro del grupo de combate (donde va DISPARAR) en la zona segura. Margen ergonómico desde el
-- borde derecho de la zona segura; en pantallas alargadas, más hacia dentro (el pulgar no llega
-- cómodo a la esquina de un teléfono largo).
MobileHUD.ClusterReach = Vector2.new(125, 91) -- (lo que sobresalen las zonas táctiles a la derecha y abajo de DISPARAR)
function MobileHUD.ClusterAnchor(class: string, size: Vector2, scale: number, screen: Vector2?): Vector2
	local full = screen or size
	local aspect = math.max(full.X, full.Y) / math.max(1, math.min(full.X, full.Y))
	-- RIGHT_THUMB_INSET: en pantallas alargadas el grupo entra más (el pulgar no llega cómodo a la
	-- esquina de un teléfono largo)
	local inward = 0
	if class == "ULTRAWIDE_PHONE" then
		inward = math.clamp((aspect - 1.9) * math.min(full.X, full.Y) * 0.2, 0, 40)
	end
	local right = MobileHUD.ClusterReach.X * scale + 20 * scale + inward
	local bottom = MobileHUD.ClusterReach.Y * scale + 14 * scale
	return Vector2.new(size.X - right, size.Y - bottom)
end

-- Controles. Anchor: "Cluster" (desde DISPARAR), "BottomLeft" (x desde la izquierda, y desde abajo)
-- o "TopRight" (x desde la derecha, y desde arriba). Size: diámetro (o Vector2 si es una tarjeta).
-- Shape: Round (círculo), Square (tarjeta cuadrada: habilidades y tira de poco uso) o Card (tarjeta
-- del arma). Hit: la ZONA TÁCTIL (una caja, como la del botón de Roblox) es algo mayor que el dibujo;
-- la disposición por defecto deja al menos MinTouchGap entre las cajas de dos controles (Fase 16:
-- antes se medían solo los dibujos y las cajas táctiles se pisaban). Role: Primary, Action, Utility.
-- Fade: se ve menos al apuntar (no se esconde). Critical: control de combate (el editor avisa si dos
-- se pisan y no deja guardar uno encima de otro).
MobileHUD.Controls = {
	-- Grupo de combate (pulgar derecho). Cajas táctiles con 6 px de aire a escala 1.
	{ Id = "Fire", Name = "Disparar", Icon = "Fire", Role = "Primary", Shape = "Round", Anchor = "Cluster", Offset = Vector2.new(0, 0), Size = 92, Hit = 1.13, Critical = true },
	{ Id = "Aim", Name = "Apuntar", Icon = "Aim", Role = "Primary", Shape = "Round", Anchor = "Cluster", Offset = Vector2.new(-96, -44), Size = 62, Hit = 1.13, Critical = true },
	{ Id = "Jump", Name = "Saltar", Icon = "Jump", Role = "Action", Shape = "Round", Anchor = "Cluster", Offset = Vector2.new(92, -10), Size = 58, Hit = 1.14, Critical = true },
	{ Id = "Slide", Name = "Agacharse", Icon = "Crouch", Role = "Action", Shape = "Round", Anchor = "Cluster", Offset = Vector2.new(88, 62), Size = 50, Hit = 1.16, Critical = true },
	{ Id = "Reload", Name = "Recargar", Icon = "Reload", Role = "Action", Shape = "Round", Anchor = "Cluster", Offset = Vector2.new(-92, 34), Size = 46, Hit = 1.17, Critical = true },
	{ Id = "Melee", Name = "Cuerpo a cuerpo", Icon = "Melee", Role = "Action", Shape = "Round", Anchor = "Cluster", Offset = Vector2.new(0, -84), Size = 40, Hit = 1.2, Fade = true, Critical = true },
	{ Id = "Airstrike", Name = "Ataque aéreo", Icon = "Airstrike", Role = "Action", Shape = "Round", Anchor = "Cluster", Offset = Vector2.new(64, -84), Size = 40, Hit = 1.15, Fade = true },
	{ Id = "SwapWeapon", Name = "Cambiar arma", Icon = "Card", Role = "Action", Shape = "Card", Anchor = "Cluster", Offset = Vector2.new(-210, 76), Size = Vector2.new(120, 32), Hit = 1.1 },
	-- Pulgar izquierdo (sobre el joystick de Roblox): una fila de habilidades y la granada
	{ Id = "Grenade", Name = "Granada", Icon = "Grenade", Role = "Action", Shape = "Round", Anchor = "BottomLeft", Offset = Vector2.new(198, -170), Size = 46, Hit = 1.17, Fade = true, Critical = true },
	{ Id = "AbilityDash", Name = "Impulso", Icon = "Dash", Role = "Action", Shape = "Square", Anchor = "BottomLeft", Offset = Vector2.new(38, -170), Size = 40, Hit = 1.15, Fade = true },
	{ Id = "AbilityJump", Name = "Supersalto", Icon = "SuperJump", Role = "Action", Shape = "Square", Anchor = "BottomLeft", Offset = Vector2.new(90, -170), Size = 40, Hit = 1.15, Fade = true },
	{ Id = "AbilityPotion", Name = "Poción", Icon = "Potion", Role = "Action", Shape = "Square", Anchor = "BottomLeft", Offset = Vector2.new(142, -170), Size = 40, Hit = 1.15, Fade = true },
	-- (opcionales: solo con su ajuste; si están apagados no se ven ni reservan sitio)
	{ Id = "Sprint", Name = "Correr", Icon = "Sprint", Role = "Action", Shape = "Square", Anchor = "BottomLeft", Offset = Vector2.new(90, -224), Size = 40, Hit = 1.15 },
	{ Id = "LeftFire", Name = "Disparo izquierdo", Icon = "Fire", Role = "Primary", Shape = "Round", Anchor = "BottomLeft", Offset = Vector2.new(244, -258), Size = 64, Hit = 1.2 },
	-- Tira de poco uso (arriba a la derecha)
	{ Id = "Menu", Name = "Menú y tienda", Icon = "Menu", Role = "Utility", Shape = "Square", Anchor = "TopRight", Offset = Vector2.new(-24, 22), Size = 32, Hit = 1.2, Fade = true },
	{ Id = "Scoreboard", Name = "Marcador", Icon = "Scoreboard", Role = "Utility", Shape = "Square", Anchor = "TopRight", Offset = Vector2.new(-70, 22), Size = 32, Hit = 1.2, Fade = true },
	{ Id = "Emotes", Name = "Emotes", Icon = "Emotes", Role = "Utility", Shape = "Square", Anchor = "TopRight", Offset = Vector2.new(-116, 22), Size = 32, Hit = 1.2, Fade = true },
	{ Id = "Spray", Name = "Grafiti", Icon = "Spray", Role = "Utility", Shape = "Square", Anchor = "TopRight", Offset = Vector2.new(-162, 22), Size = 32, Hit = 1.2, Fade = true },
}
MobileHUD.ById = {}
for _, control in MobileHUD.Controls do
	MobileHUD.ById[control.Id] = control
end

-- Aire mínimo entre las zonas táctiles de dos controles en la disposición por defecto (px)
MobileHUD.MinTouchGap = 4

-- Opacidad de cada papel (multiplica la del fondo, el borde y el icono)
MobileHUD.RoleOpacity = { Primary = 1, Action = 0.9, Utility = 0.75 }
-- Al apuntar, los controles marcados con Fade bajan un poco (siguen funcionando)
MobileHUD.AimFade = 0.6

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

local function sizeVector(size: any, scale: number): Vector2
	if typeof(size) == "Vector2" then
		return size * scale
	end
	return Vector2.new(size, size) * scale
end

-- Posición por defecto (centro) y tamaño de un control en una zona segura de `size`
function MobileHUD.Default(control, size: Vector2, scale: number, anchor: Vector2): (Vector2, Vector2)
	local offset = control.Offset * scale
	local center
	if control.Anchor == "Cluster" then
		center = anchor + offset
	elseif control.Anchor == "BottomLeft" then
		center = Vector2.new(offset.X, size.Y + offset.Y)
	else
		center = Vector2.new(size.X + offset.X, offset.Y)
	end
	return center, sizeVector(control.Size, scale)
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

-- Migración de una disposición guardada con una versión anterior. Nunca borra lo del jugador:
--   * sin personalizar (vacía): se queda vacía → usa la disposición nueva;
--   * personalizada (versión 1, Fase 12): sus posiciones son fracciones de la zona segura y sus
--     tamaños y opacidades multiplicadores, así que siguen valiendo tal cual; los controles que no
--     tocó usan la disposición nueva. Solo se limpia (Validate).
-- Devuelve la disposición y la versión nueva.
function MobileHUD.MigrateLayout(layout: any, version: any): ({ [string]: any }, number)
	local clean = MobileHUD.Validate(layout)
	local _ = version
	return clean, MobileHUD.LayoutVersion
end

-- Disposición final: { [id] = { Center, Size, Hit, Opacity, Shape } } en píxeles de la zona segura.
-- opts: { Breakpoint (clase), Screen = tamaño de la pantalla entera (ViewportSize), Custom =
-- disposición guardada }
function MobileHUD.Resolve(size: Vector2, options: { [string]: any }?)
	local opts: { [string]: any } = options or {}
	local screen = typeof(opts.Screen) == "Vector2" and opts.Screen or size
	local class = opts.Breakpoint or MobileHUD.Classify(size, true, screen)
	if class == "DESKTOP" then
		class = "STANDARD_PHONE" -- (táctil con teclado: como un teléfono normal)
	end
	local scale = MobileHUD.Scale(class, screen)
	local anchor = MobileHUD.ClusterAnchor(class, size, scale, screen)
	local custom = MobileHUD.Validate(opts.Custom)
	local out = {}
	for _, control in MobileHUD.Controls do
		local center, dims = MobileHUD.Default(control, size, scale, anchor)
		local opacity = MobileHUD.RoleOpacity[control.Role] or 1
		local own = custom[control.Id]
		if own then
			if own.X and own.Y then
				center = Vector2.new(own.X * size.X, own.Y * size.Y)
			end
			dims *= own.S or 1
			opacity *= own.O or 1
		end
		-- (que nunca se salga de la zona segura)
		local half = dims / 2
		center = Vector2.new(math.clamp(center.X, half.X, math.max(half.X, size.X - half.X)), math.clamp(center.Y, half.Y, math.max(half.Y, size.Y - half.Y)))
		out[control.Id] = { Center = center, Size = dims, Hit = dims * (control.Hit or 1), Opacity = math.clamp(opacity, 0.05, 1), Shape = control.Shape }
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

-- Zonas de la pantalla (para la depuración y las pruebas), en píxeles de la zona segura:
--   Center: centro libre (mira) { Center, Radius };
--   Swipe: zona de cámara del pulgar derecho, un rectángulo SIN botones (Min, Max);
--   LeftThumb / RightThumb: dónde viven los controles de cada pulgar (Min, Max).
-- `ids`: los controles visibles (por defecto, todos menos los opcionales).
MobileHUD.Optional = { LeftFire = true, Sprint = true, Airstrike = true }
function MobileHUD.Zones(size: Vector2, resolved, ids: { string }?)
	local list = ids
	if not list then
		list = {}
		for _, control in MobileHUD.Controls do
			if not MobileHUD.Optional[control.Id] then
				table.insert(list, control.Id)
			end
		end
	end
	local clear = MobileHUD.CenterClear(size)
	local function bounds(filter)
		local mn, mx
		for _, id in list do
			local info = resolved[id]
			if info and filter(info) then
				local a, b = info.Center - info.Hit / 2, info.Center + info.Hit / 2
				mn = mn and mn:Min(a) or a
				mx = mx and mx:Max(b) or b
			end
		end
		return mn, mx
	end
	local rightMin, rightMax = bounds(function(info)
		return info.Center.X > size.X / 2 and info.Center.Y > size.Y * 0.35
	end)
	local leftMin, leftMax = bounds(function(info)
		return info.Center.X < size.X / 2 and info.Center.Y > size.Y * 0.35
	end)
	-- Zona de cámara: a la derecha del centro libre y por encima del grupo de combate, sin ningún
	-- botón dentro. Dos candidatas (todo el ancho por debajo de la tira de poco uso, o desde arriba
	-- del todo hasta la tira) y se queda la mayor.
	local top, stripLeft = 0, size.X
	for _, id in list do
		local info = resolved[id]
		if info and info.Center.Y < size.Y * 0.35 and info.Center.X > size.X / 2 then
			top = math.max(top, info.Center.Y + info.Hit.Y / 2 + 4)
			stripLeft = math.min(stripLeft, info.Center.X - info.Hit.X / 2 - 4)
		end
	end
	local function fit(mn: Vector2, mx: Vector2): (Vector2, Vector2)
		for _, id in list do
			local info = resolved[id]
			if info then
				local a, b = info.Center - info.Hit / 2, info.Center + info.Hit / 2
				if a.X < mx.X and b.X > mn.X and a.Y < mx.Y and b.Y > mn.Y then
					mx = Vector2.new(mx.X, math.max(mn.Y, a.Y - 4))
				end
			end
		end
		return mn, mx
	end
	local left = size.X / 2 + clear * 0.6
	local bottom = (rightMin and rightMin.Y or size.Y) - 4
	local aMin, aMax = fit(Vector2.new(left, top), Vector2.new(size.X - 4, bottom))
	local bMin, bMax = fit(Vector2.new(left, 0), Vector2.new(math.max(left, stripLeft), bottom))
	local function area(mn, mx)
		return math.max(0, mx.X - mn.X) * math.max(0, mx.Y - mn.Y)
	end
	local swipeMin, swipeMax = aMin, aMax
	if area(bMin, bMax) > area(aMin, aMax) then
		swipeMin, swipeMax = bMin, bMax
	end
	return {
		Center = { Center = size / 2, Radius = clear },
		Swipe = { Min = swipeMin, Max = swipeMax },
		RightThumb = rightMin and { Min = rightMin, Max = rightMax } or nil,
		LeftThumb = leftMin and { Min = leftMin, Max = leftMax } or nil,
	}
end

-- Métricas de ayuda para revisar una disposición (no son la verdad: ayudan a comparar)
--   Coverage: fracción de la zona segura que tapan los dibujos de los controles;
--   RightHalf: controles en la mitad derecha; SwipeArea: fracción de la pantalla para la cámara;
--   MinGap: menor distancia entre dos dibujos (px); Overlaps: pares que se pisan.
function MobileHUD.Metrics(size: Vector2, resolved, ids: { string }?)
	local list = ids or {}
	if not ids then
		for _, control in MobileHUD.Controls do
			if not MobileHUD.Optional[control.Id] then
				table.insert(list, control.Id)
			end
		end
	end
	local covered, right, minGap = 0, 0, math.huge
	for i, id in list do
		local a = resolved[id]
		if a then
			local control = MobileHUD.ById[id]
			local area = a.Size.X * a.Size.Y
			if control and control.Shape == "Round" then
				area *= math.pi / 4
			end
			covered += area
			if a.Center.X > size.X / 2 then
				right += 1
			end
			for j = i + 1, #list do
				local b = resolved[list[j]]
				if b then
					local gap = (a.Center - b.Center).Magnitude - (math.max(a.Size.X, a.Size.Y) + math.max(b.Size.X, b.Size.Y)) / 2
					minGap = math.min(minGap, gap)
				end
			end
		end
	end
	local zones = MobileHUD.Zones(size, resolved, list)
	local swipe = zones.Swipe.Max - zones.Swipe.Min
	return {
		Coverage = covered / (size.X * size.Y),
		RightHalf = right,
		SwipeArea = math.max(0, swipe.X) * math.max(0, swipe.Y) / (size.X * size.Y),
		MinGap = minGap,
		Overlaps = #MobileHUD.Overlaps(resolved, list, 0),
	}
end

---------------------------------------------------------------------------
-- Detector de solapes (Fase 16). Cada control tiene dos rectángulos:
--   VISUAL: lo que se dibuja (Center ± Size/2);
--   TOUCH: la caja que recoge los toques (Center ± Hit/2, como el botón).
-- Dos controles chocan si sus cajas se cortan (con `gap` de aire). Lo usan las pruebas, la capa de
-- depuración (en rojo) y el editor de HUD.
---------------------------------------------------------------------------

function MobileHUD.Rect(info, kind: string?): (Vector2, Vector2)
	local dims = kind == "Visual" and info.Size or info.Hit
	return info.Center - dims / 2, info.Center + dims / 2
end

local function cut(aMin: Vector2, aMax: Vector2, bMin: Vector2, bMax: Vector2, gap: number): boolean
	return aMin.X < bMax.X + gap and bMin.X < aMax.X + gap and aMin.Y < bMax.Y + gap and bMin.Y < aMax.Y + gap
end
MobileHUD.RectsCut = cut

-- Área (px²) en la que se cortan dos rectángulos
local function overlapArea(aMin: Vector2, aMax: Vector2, bMin: Vector2, bMax: Vector2): number
	local w = math.min(aMax.X, bMax.X) - math.max(aMin.X, bMin.X)
	local h = math.min(aMax.Y, bMax.Y) - math.max(aMin.Y, bMin.Y)
	return (w > 0 and h > 0) and w * h or 0
end
MobileHUD.OverlapArea = overlapArea

-- Choques entre los controles `ids` (por defecto, todos menos los opcionales):
-- { { A, B, Kind = "Visual" | "Touch", Area } }. Visual: los dibujos se cortan; Touch: las cajas
-- táctiles se cortan o quedan a menos de `gap` px.
function MobileHUD.Collisions(resolved, ids: { string }?, gap: number?)
	local list = ids
	if not list then
		list = {}
		for _, control in MobileHUD.Controls do
			if not MobileHUD.Optional[control.Id] then
				table.insert(list, control.Id)
			end
		end
	end
	local g = gap or 0
	local out = {}
	for i = 1, #list do
		for j = i + 1, #list do
			local a, b = resolved[list[i]], resolved[list[j]]
			if a and b then
				local avMin, avMax = MobileHUD.Rect(a, "Visual")
				local bvMin, bvMax = MobileHUD.Rect(b, "Visual")
				local atMin, atMax = MobileHUD.Rect(a, "Touch")
				local btMin, btMax = MobileHUD.Rect(b, "Touch")
				if cut(avMin, avMax, bvMin, bvMax, 0) then
					table.insert(out, { list[i], list[j], Kind = "Visual", Area = overlapArea(avMin, avMax, bvMin, bvMax) })
				elseif cut(atMin, atMax, btMin, btMax, g) then
					table.insert(out, { list[i], list[j], Kind = "Touch", Area = overlapArea(atMin, atMax, btMin, btMax) })
				end
			end
		end
	end
	return out
end

-- Revisión de una disposición propia (editor de HUD). Solo bloquea lo que está roto de verdad:
--   Blocking: dos controles de combate (Critical) uno encima del otro (sus cajas se tapan en más de
--   la mitad de la más pequeña): un dedo no puede elegir entre los dos;
--   Warnings: dos controles de combate cuyas cajas se tocan, o un control dentro del centro libre.
-- (fuera de la pantalla no puede quedar nada: Resolve lo mete siempre dentro)
function MobileHUD.CheckLayout(size: Vector2, resolved, ids: { string }?)
	local list = ids
	if not list then
		list = {}
		for _, control in MobileHUD.Controls do
			table.insert(list, control.Id)
		end
	end
	local blocking, warnings = {}, {}
	for i = 1, #list do
		for j = i + 1, #list do
			local a, b = resolved[list[i]], resolved[list[j]]
			local ca, cb = MobileHUD.ById[list[i]], MobileHUD.ById[list[j]]
			if a and b and ca and cb and ca.Critical and cb.Critical then
				local aMin, aMax = MobileHUD.Rect(a, "Touch")
				local bMin, bMax = MobileHUD.Rect(b, "Touch")
				local area = overlapArea(aMin, aMax, bMin, bMax)
				local smaller = math.min(a.Hit.X * a.Hit.Y, b.Hit.X * b.Hit.Y)
				if area > smaller * 0.5 then
					table.insert(blocking, { list[i], list[j] })
				elseif area > 0 then
					table.insert(warnings, { list[i], list[j] })
				end
			end
		end
	end
	local clear = MobileHUD.CenterClear(size)
	for _, id in list do
		local info = resolved[id]
		if info and (info.Center - size / 2).Magnitude < clear then
			table.insert(warnings, { id, "Center" })
		end
	end
	return { Blocking = blocking, Warnings = warnings }
end

-- Mayor tramo horizontal libre entre xMin y xMax en la franja [y0, y1], esquivando `rects`
-- ({ Min, Max }). Devuelve (x0, x1) o nil. Para colocar avisos de una línea entre los botones.
function MobileHUD.FreeSpan(rects, y0: number, y1: number, xMin: number, xMax: number): (number?, number?)
	local blocked = {}
	for _, r in rects do
		if r.Min.Y < y1 and r.Max.Y > y0 and r.Max.X > xMin and r.Min.X < xMax then
			table.insert(blocked, { math.max(xMin, r.Min.X), math.min(xMax, r.Max.X) })
		end
	end
	table.sort(blocked, function(p, q)
		return p[1] < q[1]
	end)
	local bestA, bestB, cursor = nil, nil, xMin
	local function consider(a, b)
		if b - a > 0 and (not bestA or b - a > bestB - bestA) then
			bestA, bestB = a, b
		end
	end
	for _, seg in blocked do
		consider(cursor, seg[1])
		cursor = math.max(cursor, seg[2])
	end
	consider(cursor, xMax)
	return bestA, bestB
end

return MobileHUD
