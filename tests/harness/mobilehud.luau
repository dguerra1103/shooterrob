-- shared/MobileHUD (Fases 12 y 15), lógica pura: clases de pantalla por su forma (ULTRAWIDE_PHONE para
-- 19,5:9 como el S26 Ultra), escala lógica, jerarquía, controles sin duplicar, validación de lo
-- guardado, versión y migración de la disposición, y en la matriz de resoluciones (con zonas seguras
-- recortadas): dentro de la zona segura, sin solapes, centro libre, zona de cámara sin botones y grupo
-- derecho metido hacia dentro en pantallas alargadas (FASE_15_HUD_S26_ULTRA.md).
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Vector2 = roblox.Vector2
local MobileHUD = req(game.ReplicatedStorage.Shared.MobileHUD)
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
local TouchIcons = req(game.StarterPlayer.Client.Modules.TouchIcons)

-- Clases de pantalla (Fase 15): por la FORMA de la pantalla (proporción y lado corto), nunca por el
-- modelo. El Galaxy S26 Ultra (19,5:9) en horizontal: 892×412 aprox. → ULTRAWIDE_PHONE
check(MobileHUD.Classify(Vector2.new(1920, 1080), false) == "DESKTOP", "sin pantalla táctil: DESKTOP")
check(MobileHUD.Classify(Vector2.new(568, 320), true) == "COMPACT_PHONE", "568x320: COMPACT_PHONE")
check(MobileHUD.Classify(Vector2.new(667, 375), true) == "STANDARD_PHONE", "667x375 (16:9): STANDARD_PHONE")
check(MobileHUD.Classify(Vector2.new(844, 390), true) == "ULTRAWIDE_PHONE", "844x390 (19,5:9): ULTRAWIDE_PHONE")
check(MobileHUD.Classify(Vector2.new(896, 414), true) == "ULTRAWIDE_PHONE", "896x414: ULTRAWIDE_PHONE")
check(MobileHUD.Classify(Vector2.new(892, 412), true) == "ULTRAWIDE_PHONE", "perfil GALAXY_S26_ULTRA (19,5:9): ULTRAWIDE_PHONE")
check(MobileHUD.Classify(Vector2.new(1024, 768), true) == "TABLET", "1024x768: TABLET")
check(MobileHUD.Classify(Vector2.new(412, 892), true) == "ULTRAWIDE_PHONE", "en vertical, la misma clase")
-- (la clase sale de la pantalla entera: la zona segura con la cámara frontal y la barra de Roblox no
-- la cambia)
check(MobileHUD.Classify(Vector2.new(860, 354), true, Vector2.new(892, 412)) == "ULTRAWIDE_PHONE", "con zona segura recortada, sigue ULTRAWIDE_PHONE")
-- Escala lógica: lado corto / 390 con topes por clase
check(math.abs(MobileHUD.Scale("ULTRAWIDE_PHONE", Vector2.new(844, 390)) - 1) < 1e-6, "844x390: escala 1")
check(MobileHUD.Scale("COMPACT_PHONE", Vector2.new(568, 320)) < 0.9, "teléfono pequeño: algo más pequeño")
check(MobileHUD.Scale("TABLET", Vector2.new(1024, 768)) <= 1.25, "tableta: con tope")

-- Controles: ids únicos, papeles, formas y tamaños coherentes
local seen = {}
for _, c in MobileHUD.Controls do
	check(not seen[c.Id], c.Id .. " no está repetido")
	seen[c.Id] = true
	check(MobileHUD.RoleOpacity[c.Role] ~= nil, c.Id .. " tiene un papel conocido")
	check(c.Anchor == "Cluster" or c.Anchor == "BottomLeft" or c.Anchor == "TopRight", c.Id .. " con ancla conocida")
	check(c.Shape == "Round" or c.Shape == "Square" or c.Shape == "Card", c.Id .. " con forma conocida")
	check(c.Icon == "Card" or TouchIcons.Kinds[c.Icon] ~= nil, c.Id .. " con icono dibujado (" .. c.Icon .. ")")
end
check(TouchIcons.Kinds.Swap ~= nil and TouchIcons.Kinds.Jump ~= nil, "iconos de cambiar arma y saltar")
local fire = MobileHUD.ById.Fire
local compact = MobileHUD.Scale("COMPACT_PHONE", Vector2.new(568, 320))
for _, c in MobileHUD.Controls do
	if c.Id ~= "Fire" and type(c.Size) == "number" then
		check(c.Size < fire.Size, c.Id .. " más pequeño que disparar")
		check(c.Size * compact * (c.Hit or 1) >= 30, c.Id .. " se puede tocar con el dedo hasta en 568x320 (" .. math.floor(c.Size * compact * (c.Hit or 1)) .. " px)")
	end
end
-- Jerarquía: disparar > apuntar > salto, agacharse > recargar > granada > cuerpo a cuerpo
local by = MobileHUD.ById
check(by.Aim.Size > by.Jump.Size and by.Jump.Size >= by.Slide.Size and by.Slide.Size > by.Reload.Size, "jerarquía: apuntar > salto ≥ agacharse > recargar")
check(by.Reload.Size >= by.Grenade.Size and by.Grenade.Size > by.Melee.Size, "jerarquía: recargar ≥ granada > cuerpo a cuerpo")
check(by.Fire.Anchor == "Cluster" and by.Aim.Anchor == "Cluster" and by.Jump.Anchor == "Cluster" and by.Reload.Anchor == "Cluster", "grupo de combate del pulgar derecho")
check(by.Grenade.Anchor == "BottomLeft" and by.AbilityDash.Anchor == "BottomLeft", "granada y habilidades sobre el joystick")
local utility = 0
for _, c in MobileHUD.Controls do
	if c.Role == "Utility" then
		utility += 1
		check(c.Anchor == "TopRight" and c.Size <= 32, c.Id .. " en la tira pequeña de arriba a la derecha")
	end
end
check(utility == 4, "tira de poco uso: menú, marcador, emotes y grafiti")

-- Ajustes por defecto y límites
check(type(GameConfig.DefaultSettings.HudLayout) == "table" and next(GameConfig.DefaultSettings.HudLayout) == nil, "disposición por defecto vacía (la de fábrica)")
check(GameConfig.DefaultSettings.AutoSprint == 1 and GameConfig.DefaultSettings.LeftFire == 0 and GameConfig.DefaultSettings.FireDrag == 1, "correr solo, sin disparo izquierdo y disparar arrastrando por defecto")
check(GameConfig.MobileHUDDebug == false, "depuración del HUD apagada por defecto")

-- Validación de lo guardado
local clean = MobileHUD.Validate({
	Fire = { X = 0.5, Y = 0.5, S = 3, O = -1 },
	Aim = { X = 0.2 },
	Melee = { S = 0 / 0 },
	Reload = { S = math.huge },
	Unknown = { X = 0.1, Y = 0.1 },
	[1] = { X = 1 },
	Grenade = "x",
})
check(clean.Fire.S == MobileHUD.Limits.S[2] and clean.Fire.O == MobileHUD.Limits.O[1], "tamaño y opacidad recortados")
check(clean.Aim == nil, "posición a medias descartada")
check(clean.Melee == nil and clean.Reload == nil, "NaN e infinito descartados")
check(clean.Unknown == nil and clean[1] == nil and clean.Grenade == nil, "controles desconocidos y basura fuera")
check(next(MobileHUD.Validate(nil)) == nil and next(MobileHUD.Validate("hola")) == nil, "sin tabla: vacía")
local again = MobileHUD.Validate(clean)
check(again.Fire.S == clean.Fire.S and again.Fire.X == clean.Fire.X, "validar dos veces da lo mismo")

-- Versión de la disposición (Fase 15) y migración segura
check(MobileHUD.LayoutVersion == 2 and GameConfig.DefaultSettings.HudLayoutVersion == MobileHUD.LayoutVersion, "versión de la disposición por defecto: 2")
local migrated, version = MobileHUD.MigrateLayout({}, nil)
check(next(migrated) == nil and version == 2, "sin personalizar: queda vacía (usa la nueva)")
local own = { Fire = { X = 0.7, Y = 0.8, S = 1.2, O = 0.9 }, Aim = { S = 0.8 } }
migrated, version = MobileHUD.MigrateLayout(own, 1)
check(version == 2 and migrated.Fire.X == 0.7 and migrated.Fire.Y == 0.8 and migrated.Fire.S == 1.2 and migrated.Fire.O == 0.9 and migrated.Aim.S == 0.8, "personalizada: se conserva tal cual")
migrated = MobileHUD.MigrateLayout({ Fire = { X = 9 }, Bogus = { X = 1, Y = 1 }, Aim = "x" }, nil)
check(migrated.Fire == nil and migrated.Bogus == nil and migrated.Aim == nil, "basura de una versión vieja: se limpia sin romper")

-- Disposición por defecto en la matriz de resoluciones (pantalla entera / zona segura)
local matrix = {
	{ 568, 320, 568, 320 }, { 667, 375, 667, 375 }, { 844, 390, 844, 390 }, { 844, 390, 750, 369 },
	{ 896, 414, 896, 414 }, { 892, 412, 892, 412 }, { 892, 412, 860, 354 }, { 932, 430, 932, 430 },
	{ 1024, 768, 1024, 768 }, { 1180, 820, 1180, 820 },
}
for _, dims in matrix do
	local screen, size = Vector2.new(dims[1], dims[2]), Vector2.new(dims[3], dims[4])
	local name = dims[1] .. "x" .. dims[2] .. (dims[3] ~= dims[1] and (" (zona segura " .. dims[3] .. "x" .. dims[4] .. ")") or "")
	local layout = MobileHUD.Resolve(size, { Screen = screen })
	local count = 0
	for id, info in layout do
		count += 1
		check(info.Opacity > 0 and info.Opacity <= 1, name .. " " .. id .. " opacidad válida")
		local half = info.Size / 2
		check(info.Center.X - half.X >= -0.5 and info.Center.Y - half.Y >= -0.5 and info.Center.X + half.X <= size.X + 0.5 and info.Center.Y + half.Y <= size.Y + 0.5, name .. " " .. id .. " dentro de la zona segura")
	end
	check(count == #MobileHUD.Controls, name .. ": todos los controles colocados")
	check(layout.Fire.Center.X > size.X / 2 and layout.AbilityDash.Center.X < size.X / 2, name .. ": combate a la derecha, habilidades a la izquierda (joystick)")
	-- Sin solapes (con 4 px de aire) y nada en el centro libre
	local ids = {}
	for _, c in MobileHUD.Controls do
		if not MobileHUD.Optional[c.Id] then table.insert(ids, c.Id) end
	end
	local over = MobileHUD.Overlaps(layout, ids, 4)
	check(#over == 0, name .. ": ningún control pisa a otro" .. (over[1] and (" (" .. over[1][1] .. "/" .. over[1][2] .. ")") or ""))
	local clear = MobileHUD.CenterClear(size)
	for _, id in ids do
		local info = layout[id]
		check((info.Center - size / 2).Magnitude - math.max(info.Size.X, info.Size.Y) / 2 >= clear, name .. ": " .. id .. " fuera del centro libre")
	end
	-- Zona de cámara: un rectángulo grande a la derecha sin ningún botón dentro
	local zones = MobileHUD.Zones(size, layout, ids)
	local swipe = zones.Swipe
	local area = (swipe.Max.X - swipe.Min.X) * (swipe.Max.Y - swipe.Min.Y)
	check(area >= size.X * size.Y * 0.09, name .. ": zona de cámara grande (" .. math.floor(area / (size.X * size.Y) * 100) .. " % de la pantalla)")
	check(swipe.Min.X >= size.X / 2, name .. ": zona de cámara en la mitad derecha")
	for _, id in ids do
		local info = layout[id]
		local a, b = info.Center - info.Hit / 2, info.Center + info.Hit / 2
		check(not (a.X < swipe.Max.X and b.X > swipe.Min.X and a.Y < swipe.Max.Y and b.Y > swipe.Min.Y), name .. ": " .. id .. " no toca la zona de cámara")
	end
	-- Grupo derecho: nada pegado al borde de la zona segura (margen ergonómico)
	local outer = 0
	for _, c in MobileHUD.Controls do
		if c.Anchor == "Cluster" then
			local info = layout[c.Id]
			outer = math.max(outer, info.Center.X + info.Size.X / 2)
		end
	end
	local class = MobileHUD.Classify(size, true, screen)
	local margin = size.X - outer
	check(margin >= 18, name .. ": el grupo de combate no toca el borde derecho (" .. math.floor(margin) .. " px)")
	if class == "ULTRAWIDE_PHONE" then
		check(margin >= 36, name .. ": en pantalla alargada, el grupo va más hacia dentro (" .. math.floor(margin) .. " px)")
	end
end
-- En la misma altura, la pantalla alargada mete el grupo más hacia dentro que una normal
local wide = MobileHUD.Resolve(Vector2.new(892, 412), { Screen = Vector2.new(892, 412) })
local narrow = MobileHUD.Resolve(Vector2.new(740, 412), { Screen = Vector2.new(740, 412), Breakpoint = "STANDARD_PHONE" })
check(892 - wide.Jump.Center.X > 740 - narrow.Jump.Center.X, "ULTRAWIDE: grupo derecho más hacia dentro que en 16:9")
-- Detector de solapes (Fase 16): cajas VISUAL y TOUCH con aire mínimo, también con los opcionales
local all = {}
for _, c in MobileHUD.Controls do table.insert(all, c.Id) end
for _, dims in matrix do
	local screen, size = Vector2.new(dims[1], dims[2]), Vector2.new(dims[3], dims[4])
	local layout = MobileHUD.Resolve(size, { Screen = screen })
	local list = MobileHUD.Collisions(layout, all, MobileHUD.MinTouchGap)
	local text = {}
	for _, c in list do table.insert(text, c[1] .. "/" .. c[2] .. ":" .. c.Kind) end
	check(#list == 0, dims[1] .. "x" .. dims[2] .. ": 0 choques de cajas táctiles con " .. MobileHUD.MinTouchGap .. " px de aire (con correr y disparo izquierdo) " .. table.concat(text, " "))
	for _, c in MobileHUD.Controls do
		local info = layout[c.Id]
		check(info.Hit.X > info.Size.X and info.Hit.Y > info.Size.Y, dims[1] .. "x" .. dims[2] .. ": " .. c.Id .. " toca algo más que su dibujo")
	end
end
-- (el detector sí ve los choques: dos controles en el mismo sitio, y cajas que se rozan)
local stacked = MobileHUD.Resolve(Vector2.new(892, 412), { Custom = { Fire = { X = 0.7, Y = 0.7 }, Aim = { X = 0.7, Y = 0.7 } } })
local hits = MobileHUD.Collisions(stacked, { "Fire", "Aim" }, 0)
check(#hits == 1 and hits[1].Kind == "Visual", "dos controles en el mismo sitio: choque visual")
local close = MobileHUD.Resolve(Vector2.new(892, 412), { Custom = { Fire = { X = 0.5, Y = 0.8 }, Aim = { X = 0.5 + 84 / 892, Y = 0.8 } } })
local near = MobileHUD.Collisions(close, { "Fire", "Aim" }, MobileHUD.MinTouchGap)
check(#near == 1 and near[1].Kind == "Touch", "dibujos separados pero cajas táctiles juntas: choque táctil")
-- Editor: bloquea solo lo roto, avisa del resto
local stackedCheck = MobileHUD.CheckLayout(Vector2.new(892, 412), stacked, { "Fire", "Aim" })
check(#stackedCheck.Blocking == 1, "editor: disparar encima de apuntar no se puede guardar")
local closeCheck = MobileHUD.CheckLayout(Vector2.new(892, 412), close, { "Fire", "Aim" })
check(#closeCheck.Blocking == 0 and #closeCheck.Warnings == 1, "editor: muy juntos se avisa, pero se puede guardar")
local centered = MobileHUD.Resolve(Vector2.new(892, 412), { Custom = { Reload = { X = 0.5, Y = 0.5 } } })
local centerCheck = MobileHUD.CheckLayout(Vector2.new(892, 412), centered, { "Reload" })
check(#centerCheck.Warnings == 1 and centerCheck.Warnings[1][2] == "Center", "editor: un botón en la mira se avisa")
local defaultCheck = MobileHUD.CheckLayout(Vector2.new(892, 412), wide)
check(#defaultCheck.Blocking == 0 and #defaultCheck.Warnings == 0, "editor: la disposición por defecto no tiene avisos")
-- Hueco libre entre botones (avisos de una línea)
local a0, a1 = MobileHUD.FreeSpan({ { Min = Vector2.new(100, 0), Max = Vector2.new(200, 50) }, { Min = Vector2.new(500, 0), Max = Vector2.new(560, 50) } }, 10, 30, 0, 892)
check(a0 == 560 and a1 == 892, "hueco libre más grande entre obstáculos (" .. tostring(a0) .. "-" .. tostring(a1) .. ")")
local b0, b1 = MobileHUD.FreeSpan({ { Min = Vector2.new(0, 0), Max = Vector2.new(892, 50) } }, 10, 30, 0, 892)
check(b0 == nil and b1 == nil, "sin hueco: nada")

-- Disposición propia: fracciones de la pantalla (vale al girar o cambiar de móvil)
local a = MobileHUD.Resolve(Vector2.new(844, 390), { Custom = { Fire = { X = 0.25, Y = 0.5 } } })
local b = MobileHUD.Resolve(Vector2.new(1024, 768), { Custom = { Fire = { X = 0.25, Y = 0.5 } } })
check(math.abs(a.Fire.Center.X - 211) < 1 and math.abs(b.Fire.Center.X - 256) < 1, "la posición propia es relativa a la pantalla")
-- Métricas de ayuda
local m = MobileHUD.Metrics(Vector2.new(892, 412), wide)
check(m.Overlaps == 0 and m.Coverage < 0.12 and m.SwipeArea > 0.12, string.format("métricas 892x412: cobertura %.1f %%, cámara %.1f %%", m.Coverage * 100, m.SwipeArea * 100))
print("MOBILEHUD OK")
process.exit(0)
