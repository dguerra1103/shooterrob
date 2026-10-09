-- Presentación de las armas en primera persona (Fase 9): cómo SE VE y se anima cada arma.
--
-- Tres capas separadas:
--   · Juego (Weapons.luau): daño, cadencia, dispersión, cargador, tiempos de recarga. NO se toca aquí.
--   · Sensación (WeaponFeel.luau): retrocesos, rapidez de ADS y sprint, fogonazo, casquillos.
--   · Presentación (este módulo): poses (cadera, ADS, sprint, sacar, guardar, inspeccionar), marcas de
--     la recarga, reposo, saltos, colgante, piezas móviles del modelo, brazos y modelo 3D a usar.
--
-- Todo va por FAMILIAS (las mismas clases que WeaponFeel: Rifle, SMG, Pistol, Shotgun, Marksman,
-- Sniper, LMG, Launcher, Melee). El ARX-27 es la referencia («gold standard»): la familia Rifle son
-- sus valores. Cada arma puede ajustar lo suyo en WeaponVisual.Weapons.
--
-- Orden de las capas del viewmodel (WeaponController, de fuera a dentro):
--   Cámara → Cuerpo (balanceo, respiración, salto/caída) → Inercia del ratón → Pose base (cadera ↔ ADS)
--   → Locomoción (sprint, pared) → Acción (recarga, sacar/guardar, cuchillo, inspección, reposo)
--   → Retroceso del arma (siempre el último: así nunca lo tapa una animación).
local WeaponFeel = require(script.Parent.WeaponFeel)

local WeaponVisual = {}

local V = Vector3.new

WeaponVisual.ReferenceWeapon = "ARX27"
-- Skin de muestra del «gold standard» (solo para enseñarla en el modo QA de Studio; no da la skin a
-- nadie ni cambia nada de la tienda)
WeaponVisual.GoldSkin = "OperacionRoja"

-- Prioridad de las acciones del viewmodel: si hay varias a la vez, manda la primera. El disparo no
-- está aquí: interrumpe lo que el juego ya dejaba interrumpir (inspección, reposo) y se suma como
-- retroceso por encima de todo.
WeaponVisual.ActionPriority = { "Melee", "Reload", "Equip", "Inspect", "Sprint", "IdleVariant", "Idle" }

function WeaponVisual.ResolveAction(state: { [string]: any }): string
	for _, action in WeaponVisual.ActionPriority do
		if action == "Idle" or state[action] then
			return action
		end
	end
	return "Idle"
end

---------------------------------------------------------------------------
-- Brazos (procedurales: sin modelo ni animaciones externas)
---------------------------------------------------------------------------
-- Hombros fijos en el espacio de la cámara (fuera de la pantalla) y codos con cinemática inversa de
-- dos huesos: las manos siguen al arma (recarga, inspección, sprint...) y los codos se doblan solos.
WeaponVisual.Arms = {
	RightShoulder = V(1.1, -1.5, 0.4),
	LeftShoulder = V(-0.7, -1.5, 0.2),
	RightPole = V(1, -1.4, 0.1), -- hacia dónde se dobla el codo (abajo y hacia fuera)
	LeftPole = V(-1, -1.3, 0),
	Reach = 1.06, -- largo del brazo respecto a la distancia hombro-mano en la pose de cadera (>1 = codo algo doblado)
	UpperRatio = 0.5, -- parte del brazo que es el brazo (el resto, antebrazo)
}

-- Cinemática inversa de dos huesos. Devuelve la posición del codo y si la mano se alcanza.
-- (si no se alcanza, el codo queda en la recta hombro-mano y el antebrazo se estira lo que falte)
function WeaponVisual.SolveArm(shoulder: Vector3, hand: Vector3, upper: number, lower: number, pole: Vector3): (Vector3, boolean)
	local toHand = hand - shoulder
	local distance = toHand.Magnitude
	if distance < 1e-4 then
		return shoulder + pole.Unit * upper, false
	end
	local dir = toHand / distance
	if distance >= upper + lower then
		-- (brazo estirado del todo: el codo en la recta; el antebrazo se estira lo que falte)
		return shoulder + dir * upper, false
	end
	local reached = distance >= math.abs(upper - lower)
	local d = math.clamp(distance, math.abs(upper - lower) + 1e-3, upper + lower - 1e-3)
	local along = (upper * upper - lower * lower + d * d) / (2 * d)
	local height = math.sqrt(math.max(0, upper * upper - along * along))
	-- Dirección de doblado: el polo sin su parte a lo largo del brazo
	local bend = pole - dir * pole:Dot(dir)
	if bend.Magnitude < 1e-4 then
		bend = Vector3.yAxis:Cross(dir)
		if bend.Magnitude < 1e-4 then
			bend = Vector3.xAxis
		end
	end
	bend = bend.Unit
	return shoulder + dir * along + bend * height, reached
end

---------------------------------------------------------------------------
-- Piezas móviles del modelo
---------------------------------------------------------------------------
-- Una pieza se mueve sola si tiene el atributo "Piece" (modelos nuevos o importados) o si su nombre
-- empieza por uno de estos prefijos (los modelos de piezas de siempre).
WeaponVisual.PiecePrefixes = {
	Mag = { "Mag", "Drum", "AmmoBox", "BeltRound" }, -- cargador (sale y entra en la recarga)
	Slide = { "Slide" }, -- corredera de pistola
	Pump = { "Pump" }, -- bomba de escopeta
	Bolt = { "BoltHandle", "BoltKnob" }, -- cerrojo de francotirador
	Charge = { "ChargingHandle" }, -- palanca de carga de fusil (recarga vacía)
}
-- Nombres que empiezan igual pero NO se mueven
WeaponVisual.PieceExclude = { "MagTube", "BoltShroud", "BoltRelease", "Pumpkin" }

local function startsWith(name: string, prefix: string): boolean
	return string.sub(name, 1, #prefix) == prefix
end

function WeaponVisual.PieceGroup(name: string, pieceAttribute: string?): string?
	if type(pieceAttribute) == "string" and WeaponVisual.PiecePrefixes[pieceAttribute] then
		return pieceAttribute
	end
	for _, prefix in WeaponVisual.PieceExclude do
		if startsWith(name, prefix) then
			return nil
		end
	end
	for group, prefixes in WeaponVisual.PiecePrefixes do
		for _, prefix in prefixes do
			if startsWith(name, prefix) then
				return group
			end
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- Familias
---------------------------------------------------------------------------
-- Poses: Offset (studs, espacio del arma) y Angles (grados: cabeceo, giro, alabeo).
local BASE = {
	-- Reposo: respiración (× la de siempre) y, tras un rato sin hacer nada, un pequeño gesto (la mano
	-- izquierda suelta y vuelve a agarrar el guardamanos). Nunca mientras haces otra cosa.
	Idle = {
		Breath = 1,
		VariantAfter = 9, -- segundos quieto sin tocar nada
		VariantDuration = 1.3,
		VariantCooldown = 16, -- como mucho uno cada tanto
		VariantRoll = 7, -- grados que se ladea el arma
		VariantHand = V(0.06, -0.14, 0.12), -- la mano izquierda se separa y vuelve
	},
	Sprint = { Offset = V(-0.25, -0.2, 0.1), Angles = V(-12, 35, 18) },
	Equip = { Offset = V(0.15, -0.9, 0.1), Angles = V(-50, 15, -25) },
	-- Guardar: el arma vieja baja de lado mientras sube la nueva (no retrasa el cambio)
	Unequip = { Time = 0.14, Offset = V(0.1, -0.85, 0.15), Angles = V(-40, 10, -20) },
	-- Inspección: claves { t (0-1), posición, ángulos } con transición suave entre ellas
	Inspect = {
		Duration = 2.6,
		Moment = 0.42, -- cuando se ve el colgante de cerca (evento InspectMoment y meneo del colgante)
		Keys = {
			{ 0, V(0, 0, 0), V(0, 0, 0) },
			{ 0.16, V(-0.35, 0.18, 0.25), V(12, 70, -25) }, -- costado izquierdo (skin y colgante)
			{ 0.42, V(-0.28, 0.2, 0.38), V(16, 55, -18) }, -- más cerca
			{ 0.72, V(-0.32, 0.16, 0.25), V(8, -45, 10) }, -- el otro costado
			{ 0.86, V(-0.08, 0.05, 0.08), V(-6, -8, 4) }, -- remate: sube un poco
			{ 1, V(0, 0, 0), V(0, 0, 0) },
		},
	},
	-- Recarga: inclinación del arma y marcas (fracción de la duración REAL de la recarga, la del juego).
	-- Tactical = con balas; Empty = vacía (con cerrojo/palanca). Ready = el arma vuelve a estar lista.
	Reload = {
		Tilt = { Offset = V(-0.08, -0.1, 0.05), Angles = V(8, -10, 28) },
		Tactical = { MagOut = 0.12, MagIn = 0.55, Ready = 0.95 },
		Empty = { MagOut = 0.12, MagIn = 0.55, Bolt = 0.85, Ready = 0.97 },
		ChargePull = 0.22, -- studs que retrocede la palanca de carga
		-- Armas que cargan cartucho a cartucho (escopeta de bomba): un ShellIn por cartucho y el
		-- bombeo final (Bolt), sea vacía o no
		Shells = { 0.2, 0.38, 0.56, 0.74 },
		ShellPump = 0.85,
		ShellReady = 0.97,
	},
	-- Salto y caída: el arma se queda atrás al despegar y se hunde al aterrizar (más cuanto más alto)
	Jump = { Kick = 0.9, Stiffness = 120, Damping = 14 },
	-- Colgante: empujones por acción (además del giro de la cámara)
	Charm = { Fire = 0.5, Reload = 1.4, Land = 1.6, Sprint = 0.35, Inspect = 2.2, Idle = 1 },
	-- Cuchillo: momento del golpe (fracción) para el evento MeleeHit
	Melee = { HitAt = 0.3 },
}

-- Lo que cambia cada familia (encima de BASE). El fusil (ARX-27) es BASE tal cual.
WeaponVisual.Families = {
	Rifle = {},
	SMG = {
		Sprint = { Offset = V(-0.2, -0.16, 0.08), Angles = V(-10, 30, 15) },
		Equip = { Offset = V(0.12, -0.7, 0.08), Angles = V(-40, 12, -20) },
		Unequip = { Time = 0.12 },
		Inspect = { Duration = 2.3 },
	},
	Pistol = {
		-- Pistola: corre con el arma recogida hacia arriba («high ready»), saca muy rápido
		Sprint = { Offset = V(0.05, 0.02, 0.2), Angles = V(28, 12, -8) },
		Equip = { Offset = V(0.1, -0.6, 0.05), Angles = V(-35, 8, -15) },
		Unequip = { Time = 0.1 },
		Idle = { VariantRoll = 10, VariantHand = V(0.04, -0.08, 0.06) },
		Inspect = {
			Duration = 2.1,
			Moment = 0.4,
			Keys = {
				{ 0, V(0, 0, 0), V(0, 0, 0) },
				{ 0.18, V(-0.2, 0.12, 0.2), V(10, 65, -30) },
				{ 0.4, V(-0.16, 0.16, 0.3), V(14, 50, -20) },
				{ 0.62, V(-0.2, 0.12, 0.2), V(6, -60, 25) },
				{ 0.82, V(-0.04, 0.04, 0.05), V(-8, -6, 6) },
				{ 1, V(0, 0, 0), V(0, 0, 0) },
			},
		},
		Reload = { Tilt = { Offset = V(-0.05, -0.06, 0.03), Angles = V(10, -8, 22) } },
	},
	Shotgun = {
		Sprint = { Offset = V(-0.28, -0.24, 0.12), Angles = V(-14, 38, 20) },
		Equip = { Offset = V(0.18, -1.0, 0.12), Angles = V(-55, 15, -28) },
		Unequip = { Time = 0.16 },
		Jump = { Kick = 1.1 },
	},
	Marksman = {
		Sprint = { Offset = V(-0.27, -0.22, 0.11), Angles = V(-13, 36, 19) },
		Unequip = { Time = 0.15 },
	},
	Sniper = {
		Sprint = { Offset = V(-0.3, -0.26, 0.12), Angles = V(-15, 32, 18) },
		Equip = { Offset = V(0.18, -1.0, 0.12), Angles = V(-55, 15, -28) },
		Unequip = { Time = 0.17 },
		Inspect = { Duration = 2.8 },
		Jump = { Kick = 1.1, Stiffness = 100 },
	},
	LMG = {
		-- Ametralladora: se lleva baja y pegada al cuerpo al correr (pesa)
		Sprint = { Offset = V(-0.15, -0.3, 0.14), Angles = V(-22, 22, 10) },
		Equip = { Offset = V(0.2, -1.1, 0.15), Angles = V(-55, 12, -22) },
		Unequip = { Time = 0.18 },
		Inspect = { Duration = 2.9 },
		Jump = { Kick = 1.25, Stiffness = 90, Damping = 12 },
		Reload = { Tilt = { Offset = V(-0.1, -0.14, 0.06), Angles = V(10, -12, 32) } },
	},
	Launcher = {
		Sprint = { Offset = V(-0.2, -0.28, 0.12), Angles = V(-18, 26, 12) },
		Unequip = { Time = 0.18 },
	},
	Melee = {
		Sprint = { Offset = V(-0.1, -0.15, 0.1), Angles = V(-15, 20, 15) },
		Unequip = { Time = 0.1 },
	},
}

---------------------------------------------------------------------------
-- Ajustes por arma (modelo, piezas, puntos)
---------------------------------------------------------------------------
-- Model = nil → el modelo de piezas de siempre (WeaponDesigns / WeaponDesignsClassic).
-- Model = "Nombre" → plantilla en ReplicatedStorage.WeaponViewModels[Nombre] (por ejemplo, un modelo
-- comprado). Ver WeaponVisual.ModelRequirements y FASE_09_ARX27_GOLD_STANDARD.md (sección M).
-- ViewOffset (CFrame) / AimDistance (studs): pose de cadera y distancia de la mira si el modelo nuevo
-- lo necesita (si no, las de Weapons). Además, cualquier sección de las familias (Sprint, Inspect...).
WeaponVisual.Weapons = {
	ARX27 = { Model = "ARX27" }, -- (malla de Blender: Shared/WeaponMeshKit)
	TitanLMG = { Model = "TitanLMG" },
	Viper = { Model = "Viper" },
	VortexBR = { Model = "VortexBR" },
	HavocPump = { Model = "HavocPump" },
	Signal7 = { Model = "Signal7" },
	Specter9 = { Model = "Specter9" },
}

-- Lo que necesita un modelo externo para funcionar sin tocar el código
WeaponVisual.ModelRequirements = {
	PrimaryPart = "Handle", -- pieza raíz (todas las demás soldadas a ella)
	Attachments = { "Muzzle", "AimPoint", "Eject" }, -- en el Handle: boca del cañón, centro de la mira, ventana de expulsión
	Optional = { "LeftHand", "RightHand", "CharmPoint" }, -- en el Handle: dónde agarran las manos y de dónde cuelga el colgante
	-- Piezas: atributo "Role" (Body, Panel, Accent, Accent2, Dark, Metal, Rubber, Lens, Reticle, Trim)
	-- para las skins y atributo "Piece" (Mag, Slide, Pump, Bolt, Charge) para las que se mueven.
}

-- ¿Qué le falta a un modelo para usarlo? (lista vacía = listo)
function WeaponVisual.ValidateModel(model: any): { string }
	local missing = {}
	if not model then
		table.insert(missing, "modelo")
		return missing
	end
	local handle = model.PrimaryPart
	if not handle or handle.Name ~= WeaponVisual.ModelRequirements.PrimaryPart then
		table.insert(missing, "PrimaryPart = Handle")
		return missing
	end
	for _, name in WeaponVisual.ModelRequirements.Attachments do
		local attachment = handle:FindFirstChild(name)
		if not attachment or not attachment:IsA("Attachment") then
			table.insert(missing, "Attachment " .. name)
		end
	end
	local painted = false
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Role") then
			painted = true
			break
		end
	end
	if not painted then
		table.insert(missing, "piezas con atributo Role (para las skins)")
	end
	return missing
end

---------------------------------------------------------------------------
-- Resolución
---------------------------------------------------------------------------

-- Copia profunda de `base` con `extra` encima (tablas por secciones; los Vector3 y listas se reemplazan)
local function merge(base, extra)
	local out = {}
	for key, value in base do
		out[key] = value
	end
	if extra then
		for key, value in extra do
			local current = out[key]
			if type(value) == "table" and type(current) == "table" and value[1] == nil and current[1] == nil then
				out[key] = merge(current, value)
			else
				out[key] = value
			end
		end
	end
	return out
end
WeaponVisual.Merge = merge

local cache = {}

-- Presentación completa de un arma (BASE + su familia + sus ajustes)
function WeaponVisual.Get(weaponName: string?, def: any?)
	local key = weaponName or ""
	local cached = cache[key]
	if cached then
		return cached
	end
	local family = WeaponFeel.Class(weaponName, def)
	local visual = merge(BASE, WeaponVisual.Families[family])
	local own = weaponName and WeaponVisual.Weapons[weaponName]
	if own then
		visual = merge(visual, own)
	end
	visual.Family = family
	cache[key] = visual
	return visual
end

function WeaponVisual.ClearCache()
	table.clear(cache)
end

-- Marcas de una recarga en orden: { { Name, At } } (At = fracción de la duración). shells = carga
-- cartucho a cartucho (ShellIn × n, Bolt = bombeo y Ready)
function WeaponVisual.ReloadMarkers(visual, empty: boolean, shells: boolean?): { { Name: string, At: number } }
	local list = {}
	if shells then
		for _, at in visual.Reload.Shells do
			table.insert(list, { Name = "ShellIn", At = at })
		end
		table.insert(list, { Name = "Bolt", At = visual.Reload.ShellPump })
		table.insert(list, { Name = "Ready", At = visual.Reload.ShellReady })
		return list
	end
	local timeline = empty and visual.Reload.Empty or visual.Reload.Tactical
	for name, at in timeline do
		table.insert(list, { Name = name, At = at })
	end
	table.sort(list, function(a, b)
		return a.At < b.At
	end)
	return list
end

-- Pose de la inspección en el instante t (0-1): posición y ángulos (grados) interpolados con suavidad
local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
function WeaponVisual.InspectPose(visual, t: number): (Vector3, Vector3)
	local keys = visual.Inspect.Keys
	t = math.clamp(t, 0, 1)
	for i = 2, #keys do
		local a, b = keys[i - 1], keys[i]
		if t <= b[1] then
			local span = b[1] - a[1]
			local k = span > 0 and smooth((t - a[1]) / span) or 1
			return a[2]:Lerp(b[2], k), a[3]:Lerp(b[3], k)
		end
	end
	local last = keys[#keys]
	return last[2], last[3]
end

-- CFrame de una pose { Offset, Angles (grados) } multiplicada por un peso (0-1; puede pasarse un poco
-- o ser negativo: el rebote al sacar el arma)
function WeaponVisual.PoseCFrame(pose, weight: number): CFrame
	if weight == 0 then
		return CFrame.identity
	end
	local o, a = pose.Offset * weight, pose.Angles * weight
	return CFrame.new(o) * CFrame.Angles(math.rad(a.X), math.rad(a.Y), math.rad(a.Z))
end

return WeaponVisual
