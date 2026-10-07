-- Sensación de las armas (gunplay): perfiles por tipo de arma con todo lo que se puede ajustar de cómo
-- se SIENTE disparar, sin tocar lo que decide el combate. Lo usan WeaponController (retroceso, ADS,
-- balanceo, sprint, sacar el arma) y Effects (fogonazo, casquillos, impactos según la calidad).
--
-- Tres retrocesos separados (Fase 2):
--   · De juego (Gameplay): dispersión, apertura de la mira y subida de la mira que hay que controlar.
--     Sale del `Recoil` de cada arma en Weapons.luau y es IGUAL para todos los perfiles: cambiarlo es
--     cambiar el equilibrio del juego.
--   · De cámara (Camera): un golpe visual que se recupera del todo y NO cambia dónde van las balas
--     (WeaponController lo descuenta al apuntar el disparo). Comunica la potencia del arma.
--   · Del arma en la mano (View): muelles del viewmodel. Hace que el arma se sienta física.
--
-- Los cosméticos (skins, camuflajes, colgantes) nunca pasan por aquí: WeaponFeel.Get solo recibe el
-- nombre del arma.
local WeaponFeel = {}

-- Arma de referencia (el "estándar de oro"): el fusil de asalto con el que se ajustó todo lo demás
WeaponFeel.ReferenceWeapon = "ARX27"

-- Retroceso de juego (igual para todas las armas; los valores son los de antes de la Fase 2)
WeaponFeel.Gameplay = {
	ClimbBase = 0.75, -- la mira sube Recoil × (ClimbBase + ClimbGrowth × min(disparos, ClimbShots) / ClimbShots)
	ClimbGrowth = 0.5,
	ClimbShots = 6,
	Drift = 0.45, -- desvío lateral con patrón propio de cada arma (se aprende a controlar)
	DriftNoise = 0.25, -- y algo de azar
	DriftDelay = 3, -- los primeros disparos de la ráfaga casi no se desvían de lado
	AimReduction = 0.35, -- apuntando, el retroceso de juego baja un 35 %
	ApplySpeed = 22, -- lo rápido que se aplica la subida a la cámara
	Recover = 0.65, -- parte de la subida que la mira recupera sola al soltar el gatillo
	RecoverSpeed = 7,
	BloomPerRecoil = 0.4, -- apertura de la mira por disparo (× Recoil)
	BloomMax = 6,
}

-- Perfil base (el del fusil de asalto). Los demás perfiles solo dicen lo que cambia.
local BASE = {
	Camera = {
		Punch = 0.3, -- grados que sube la cámara en cada disparo (se recupera del todo)
		PunchSide = 0.1, -- grados de giro lateral al azar
		PunchRoll = 0.35, -- grados de alabeo
		Stiffness = 320, -- muelle de la recuperación
		Damping = 30,
		AimScale = 0.55, -- apuntando, el golpe de cámara es menor
		Shake = 0, -- temblor por disparo (× Recoil); 0 = sin temblor
		FovKick = 0, -- empujón de campo de visión por disparo (× Recoil)
		Impulse = 0, -- (lo calcula WeaponFeel.Get a partir del muelle)
	},
	View = {
		Back = 1, -- multiplicadores del golpe del arma (que sale del Recoil del arma)
		Rise = 1,
		Side = 1,
		Stiffness = 260, -- muelles: hacia atrás, giro hacia arriba y lado
		Damping = 24,
		RotStiffness = 220,
		RotDamping = 20,
		SideStiffness = 180,
		SideDamping = 18,
		AimScale = 0.5, -- apuntando, el arma se mueve la mitad
	},
	Aim = {
		Speed = 14, -- rapidez al apuntar (más alto = más rápido; 14 ≈ 0,2 s)
		Sway = 0.25, -- inercia del ratón que queda al apuntar (0 = nada, 1 = como de cadera)
		Bob = 0.1, -- balanceo al andar que queda al apuntar
	},
	Sway = { Amount = 1 }, -- inercia del arma al mover el ratón
	Bob = { Walk = 1, Sprint = 1 }, -- balanceo al andar y al correr
	Sprint = {
		Fov = 6, -- grados más de campo de visión corriendo
		Speed = 10, -- rapidez al entrar y salir del sprint (salir rápido = disparar antes)
	},
	Equip = { Time = 0.4 }, -- lo que dura la animación de sacar el arma (no cambia cuándo se puede disparar)
	Flash = {
		Scale = 1, -- tamaño del fogonazo
		Duration = 0.04, -- segundos (0,03-0,08)
		Light = 1, -- intensidad del golpe de luz (0 = sin luz, p. ej. con supresor)
		Smoke = 1, -- humo del fogonazo
	},
	Shells = { Enabled = true, Color = nil :: Color3? }, -- casquillos (cosmético local)
	Heat = { PerShot = 1 }, -- calor del cañón por disparo (con calor sale humo al parar)
}

WeaponFeel.Profiles = {
	Rifle = {},
	Pistol = {
		Camera = { Punch = 0.45, PunchSide = 0.15, PunchRoll = 0.5, Stiffness = 380, Damping = 32 },
		View = { Rise = 1.15, Stiffness = 300, Damping = 26, RotStiffness = 260, RotDamping = 22 },
		Aim = { Speed = 17 },
		Sprint = { Speed = 13 },
		Equip = { Time = 0.32 },
		Flash = { Scale = 0.8, Duration = 0.035 },
		Sway = { Amount = 1.1 },
	},
	SMG = {
		Camera = { Punch = 0.18, PunchSide = 0.14, PunchRoll = 0.25 },
		View = { Back = 0.9, Rise = 0.8, Side = 1.3, Stiffness = 300, Damping = 24 },
		Aim = { Speed = 16 },
		Sprint = { Speed = 12 },
		Equip = { Time = 0.35 },
		Flash = { Scale = 0.75, Duration = 0.03 },
		Sway = { Amount = 1.1 },
		Bob = { Walk = 1.15, Sprint = 1.1 },
	},
	LMG = {
		Camera = { Punch = 0.25, PunchSide = 0.08, PunchRoll = 0.3, Stiffness = 260, Damping = 28 },
		View = { Back = 1.15, Rise = 0.8, Side = 0.7, Stiffness = 200, Damping = 22, RotStiffness = 180, RotDamping = 19 },
		Aim = { Speed = 11 },
		Sprint = { Speed = 7 },
		Equip = { Time = 0.5 },
		Flash = { Scale = 1.1, Duration = 0.045 },
		Sway = { Amount = 0.8 },
		Bob = { Walk = 0.8, Sprint = 0.85 },
	},
	Shotgun = {
		Camera = { Punch = 1.0, PunchSide = 0.25, PunchRoll = 1.2, Stiffness = 220, Damping = 24, Shake = 0.05, FovKick = 0.22 },
		View = { Back = 1.25, Rise = 1.1, Side = 0.8, Stiffness = 220, Damping = 20 },
		Equip = { Time = 0.42 },
		Flash = { Scale = 1.4, Duration = 0.06, Smoke = 1.5 },
		Shells = { Color = Color3.fromRGB(220, 50, 50) },
		Heat = { PerShot = 4 },
	},
	Marksman = {
		Camera = { Punch = 0.6, PunchSide = 0.12, PunchRoll = 0.6, Stiffness = 260, Damping = 26 },
		View = { Back = 1.1, Rise = 1.1, Side = 0.6, Stiffness = 240, Damping = 22 },
		Aim = { Speed = 13 },
		Equip = { Time = 0.42 },
		Flash = { Scale = 1.15, Duration = 0.05 },
	},
	Sniper = {
		Camera = { Punch = 1.2, PunchSide = 0.2, PunchRoll = 1.0, Stiffness = 200, Damping = 22, Shake = 0.05, FovKick = 0.22 },
		View = { Back = 1.2, Side = 0.5, Stiffness = 200, Damping = 20 },
		Aim = { Speed = 12 },
		Sprint = { Speed = 8 },
		Equip = { Time = 0.48 },
		Flash = { Scale = 1.5, Duration = 0.07, Smoke = 1.5 },
		Sway = { Amount = 0.9 },
		Heat = { PerShot = 4 },
	},
	Launcher = {
		Camera = { Punch = 1.0, PunchSide = 0.2, PunchRoll = 0.8, Stiffness = 200, Damping = 22, Shake = 0.05, FovKick = 0.22 },
		View = { Back = 1.2, Side = 0.5, Stiffness = 180, Damping = 20 },
		Aim = { Speed = 12 },
		Sprint = { Speed = 8 },
		Equip = { Time = 0.5 },
		Flash = { Scale = 1.6, Duration = 0.08, Light = 1.2 },
		Shells = { Enabled = false },
		Heat = { PerShot = 0 },
	},
	Melee = {
		Equip = { Time = 0.35 },
		Shells = { Enabled = false },
		Heat = { PerShot = 0 },
	},
}

-- Tipo de cada arma (las que no están aquí se deducen de su categoría)
WeaponFeel.ClassOf = {
	ARX27 = "Rifle",
	VortexBR = "Rifle",
	Specter9 = "SMG",
	NovaDrift = "SMG",
	SplatX = "SMG",
	TitanLMG = "LMG",
	HavocPump = "Shotgun",
	BreachHammer = "Shotgun",
	RaptorDMR = "Marksman",
	Crossbow = "Marksman",
	Signal7 = "Sniper",
	GhostlineXR = "Sniper",
	Viper = "Pistol",
	PhantomSidewind = "Pistol",
	HandCannon = "Pistol",
	NovaLauncher = "Launcher",
	Calabazooka = "Launcher",
}

-- Ajustes de un arma concreta encima de su perfil
WeaponFeel.Overrides = {
	-- Revólver: pistola pesada (como antes, sacude la cámara como las armas potentes)
	HandCannon = {
		Camera = { Punch = 0.8, PunchRoll = 0.8, Shake = 0.05, FovKick = 0.22 },
		View = { Back = 1.2, Rise = 1.3 },
		Flash = { Scale = 1.1, Duration = 0.05 },
	},
	-- Con supresor: fogonazo mínimo y sin golpe de luz
	GhostlineXR = { Flash = { Scale = 0.35, Duration = 0.03, Light = 0, Smoke = 0.5 } },
	-- Ballesta y paintball: ni casquillos ni humo de pólvora
	Crossbow = { Shells = { Enabled = false }, Heat = { PerShot = 0 }, Flash = { Scale = 0, Light = 0, Smoke = 0 } },
	SplatX = { Shells = { Enabled = false }, Heat = { PerShot = 0 }, Flash = { Scale = 0.4, Light = 0.3, Smoke = 0.3 } },
}

local CATEGORY_CLASS = {
	["Fusil de asalto"] = "Rifle",
	["Fusil de energía"] = "Rifle",
	Subfusil = "SMG",
	["Ametralladora pesada"] = "LMG",
	Escopeta = "Shotgun",
	["Escopeta pesada"] = "Shotgun",
	["Fusil de tirador"] = "Marksman",
	Francotirador = "Sniper",
	Pistola = "Pistol",
	["Pistola táctica"] = "Pistol",
	["Revólver"] = "Pistol",
	Lanzacohetes = "Launcher",
	["Cuerpo a cuerpo"] = "Melee",
}

-- Tipo de un arma: por nombre, si no por su categoría y, si no, fusil
function WeaponFeel.Class(weaponName: string?, def: any?): string
	local class = weaponName and WeaponFeel.ClassOf[weaponName]
	if class then
		return class
	end
	if def then
		if def.Type == "Melee" then
			return "Melee"
		end
		class = def.Category and CATEGORY_CLASS[def.Category]
		if class then
			return class
		end
		if def.Explosive then
			return "Launcher"
		elseif (def.Pellets or 1) > 1 then
			return "Shotgun"
		end
	end
	return "Rifle"
end

-- Copia `base` con los valores de `extra` encima (por secciones)
local function merge(base, extra)
	local out = {}
	for section, values in base do
		local copy = table.clone(values)
		local over = extra and extra[section]
		if over then
			for key, value in over do
				copy[key] = value
			end
		end
		out[section] = copy
	end
	return out
end

local cache = {}

-- Un paso de muelle amortiguado con la solución EXACTA (no por aproximación): el resultado es el
-- mismo a 30, 60 o 240 fps, así que el golpe se siente igual en cualquier dispositivo. Devuelve la
-- posición y la velocidad nuevas.
function WeaponFeel.StepSpring(x: number, v: number, stiffness: number, damping: number, dt: number): (number, number)
	local w0 = math.sqrt(stiffness)
	local zeta = math.min(damping / (2 * w0), 0.999) -- (los perfiles son subamortiguados)
	local wd = w0 * math.sqrt(1 - zeta * zeta)
	local decay = math.exp(-zeta * w0 * dt)
	local c, s = math.cos(wd * dt), math.sin(wd * dt)
	local newX = decay * (x * c + (v + zeta * w0 * x) / wd * s)
	local newV = decay * (v * c - (zeta * w0 * v + w0 * w0 * x) / wd * s)
	return newX, newV
end

-- Velocidad inicial del muelle para que el golpe llegue a 1 radián de pico (fórmula exacta del
-- máximo). Así `Punch` son de verdad los grados que sube la cámara.
local function punchImpulse(stiffness: number, damping: number): number
	local w0 = math.sqrt(stiffness)
	local zeta = math.min(damping / (2 * w0), 0.999)
	local wd = w0 * math.sqrt(1 - zeta * zeta)
	local peakTime = math.atan2(wd, zeta * w0) / wd
	local peakPerVelocity = math.exp(-zeta * w0 * peakTime) * math.sin(wd * peakTime) / wd
	return peakPerVelocity > 0 and 1 / peakPerVelocity or 0
end

-- Perfil completo de un arma (perfil base + su tipo + sus ajustes). No depende de la skin.
function WeaponFeel.Get(weaponName: string?, def: any?)
	local key = weaponName or ""
	local cached = cache[key]
	if cached then
		return cached
	end
	local class = WeaponFeel.Class(weaponName, def)
	local profile = merge(BASE, WeaponFeel.Profiles[class])
	local override = weaponName and WeaponFeel.Overrides[weaponName]
	if override then
		profile = merge(profile, override)
	end
	profile.Class = class
	profile.Camera.Impulse = punchImpulse(profile.Camera.Stiffness, profile.Camera.Damping)
	cache[key] = profile
	return profile
end

-- Para las pruebas (y si se cambian perfiles en caliente)
function WeaponFeel.ClearCache()
	table.clear(cache)
end

-- Presupuesto de efectos por calidad gráfica (Ajustes → Calidad; "Auto" ya resuelto). Nunca toca el
-- hitmarker, los avisos de baja ni los impactos sobre personas: eso es información de juego.
WeaponFeel.Quality = {
	Baja = {
		Shells = false, -- casquillos
		BulletMarks = 0, -- marcas de bala visibles a la vez (0 = sin marcas)
		ImpactParticles = 0.4, -- partículas de los impactos en el escenario (× las normales)
		FlashParticles = 0.5, -- partículas del fogonazo
		MuzzleSmoke = false, -- humo del fogonazo
		BarrelSmoke = false, -- humo del cañón caliente
	},
	Media = {
		Shells = true,
		BulletMarks = 30,
		ImpactParticles = 0.75,
		FlashParticles = 1,
		MuzzleSmoke = true,
		BarrelSmoke = true,
	},
	Alta = {
		Shells = true,
		BulletMarks = 50,
		ImpactParticles = 1,
		FlashParticles = 1,
		MuzzleSmoke = true,
		BarrelSmoke = true,
	},
}
WeaponFeel.Quality.Ultra = WeaponFeel.Quality.Alta

-- En móvil (pantalla táctil sin teclado), aunque la calidad sea alta, se recorta lo que más cuesta
WeaponFeel.MobileCap = {
	Shells = false,
	BulletMarks = 20,
	ImpactParticles = 0.6,
}

function WeaponFeel.Budget(quality: string?, mobile: boolean?)
	local budget = table.clone(WeaponFeel.Quality[quality or "Media"] or WeaponFeel.Quality.Media)
	if mobile then
		local cap = WeaponFeel.MobileCap
		budget.Shells = budget.Shells and cap.Shells
		budget.BulletMarks = math.min(budget.BulletMarks, cap.BulletMarks)
		budget.ImpactParticles = math.min(budget.ImpactParticles, cap.ImpactParticles)
	end
	return budget
end

return WeaponFeel
