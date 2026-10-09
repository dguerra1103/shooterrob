-- Arsenal: estadísticas, paleta de fábrica, desbloqueo y posiciones (manos, mira, cañón) de cada arma.
-- El modelo 3D de cada arma está en WeaponDesigns.
local Designs = require(script.Parent.WeaponDesigns)
local Classic = require(script.Parent.WeaponDesignsClassic)

local Weapons = {}

local rad = math.rad
local V = Vector3.new
local RGB = Color3.fromRGB

-- Paletas de fábrica (el aspecto "Default" de cada arma, como en el arte conceptual)
local Palettes = {
	Pulse = { Body = RGB(34, 36, 42), Panel = RGB(226, 229, 236), Accent = RGB(0, 140, 255), Accent2 = RGB(90, 210, 255), Dark = RGB(18, 18, 22) },
	Havoc = { Body = RGB(36, 32, 32), Panel = RGB(235, 50, 25), Accent = RGB(255, 85, 0), Accent2 = RGB(255, 150, 20), Dark = RGB(20, 18, 18) },
	Specter = { Body = RGB(28, 28, 34), Panel = RGB(236, 236, 242), Accent = RGB(255, 40, 200), Accent2 = RGB(0, 220, 255), Dark = RGB(16, 16, 20) },
	Signal = { Body = RGB(24, 26, 30), Panel = RGB(232, 234, 240), Accent = RGB(0, 170, 255), Accent2 = RGB(120, 220, 255), Dark = RGB(14, 14, 18) },
	Volt = { Body = RGB(30, 30, 32), Panel = RGB(255, 190, 30), Accent = RGB(255, 210, 40), Accent2 = RGB(0, 220, 255), Dark = RGB(18, 18, 20) },
	Vortex = { Body = RGB(26, 28, 36), Panel = RGB(222, 226, 234), Accent = RGB(20, 120, 255), Accent2 = RGB(70, 200, 255), Dark = RGB(14, 15, 20) },
	Raptor = { Body = RGB(38, 42, 34), Panel = RGB(105, 135, 70), Accent = RGB(140, 255, 80), Accent2 = RGB(255, 255, 255), Dark = RGB(20, 22, 18) },
	Nova = { Body = RGB(40, 40, 46), Panel = RGB(255, 125, 20), Accent = RGB(255, 220, 0), Accent2 = RGB(0, 220, 255), Dark = RGB(18, 18, 22) },
	Viper = { Body = RGB(30, 30, 34), Panel = RGB(220, 40, 45), Accent = RGB(255, 60, 60), Accent2 = RGB(255, 255, 255), Dark = RGB(16, 16, 18) },
	Gold = { Body = RGB(30, 26, 24), Panel = RGB(235, 175, 50), Accent = RGB(255, 200, 60), Accent2 = RGB(255, 255, 255), Dark = RGB(20, 18, 16), PanelMaterial = Enum.Material.Foil },
	Grind = { Body = RGB(38, 36, 32), Panel = RGB(170, 165, 152), Accent = RGB(255, 180, 0), Accent2 = RGB(255, 205, 30), Dark = RGB(18, 17, 15), PanelMaterial = Enum.Material.Metal },
	Tempest = { Body = RGB(36, 32, 32), Panel = RGB(205, 30, 28), Accent = RGB(255, 90, 0), Accent2 = RGB(255, 200, 70), Dark = RGB(18, 16, 16) },
	Drift = { Body = RGB(30, 26, 36), Panel = RGB(238, 234, 242), Accent = RGB(255, 40, 220), Accent2 = RGB(0, 200, 255), Dark = RGB(16, 14, 20) },
	Breach = { Body = RGB(34, 32, 34), Panel = RGB(150, 148, 150), Accent = RGB(255, 70, 10), Accent2 = RGB(255, 170, 40), Dark = RGB(22, 20, 22), PanelMaterial = Enum.Material.Metal },
	Ghost = { Body = RGB(26, 28, 26), Panel = RGB(228, 230, 226), Accent = RGB(70, 255, 40), Accent2 = RGB(180, 255, 120), Dark = RGB(14, 16, 14) },
	Phantom = { Body = RGB(30, 28, 38), Panel = RGB(232, 230, 240), Accent = RGB(160, 70, 255), Accent2 = RGB(50, 140, 255), Dark = RGB(16, 14, 22) },
	Fang = { Body = RGB(30, 30, 36), Panel = RGB(230, 232, 238), Accent = RGB(0, 220, 255), Accent2 = RGB(255, 255, 255), Dark = RGB(60, 64, 72) },
}
Weapons.Palettes = Palettes

Weapons.List = {
	ARX27 = {
		DisplayName = "ARX-27 Pulse",
		Category = "Fusil de asalto",
		Description = "Fiable a cualquier distancia. El arma de todo operador.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Pulse,
		Parts = Designs.ARX27(),
		UnlockLevel = 1,
		Damage = 24,
		MinDamage = 16,
		FalloffStart = 120,
		FalloffEnd = 350,
		HeadshotMultiplier = 1.6,
		FireRate = 10,
		Automatic = true,
		MagSize = 30,
		ReserveAmmo = 150,
		ReloadTime = 1.9,
		Range = 600,
		Spread = 1.6,
		AimSpread = 0.25,
		Pellets = 1,
		Recoil = 0.8,
		AimFOV = 60,
		ViewOffset = CFrame.new(0.8, -0.85, -2.0),
		AimDistance = 1.0,
		RightHand = V(0, -0.48, 0.44),
		LeftHand = V(0, -0.26, -1.0),
		AimPoint = V(0, 0.62, 0.35),
		Muzzle = V(0, 0.06, -2.5),
	},

	HavocPump = {
		DisplayName = "Havoc Pump",
		Category = "Escopeta",
		Description = "Arrasa a corta distancia. Un disparo, una baja.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Havoc,
		Parts = Designs.HavocPump(),
		UnlockLevel = 1,
		Damage = 12,
		MinDamage = 3,
		FalloffStart = 25,
		FalloffEnd = 70,
		HeadshotMultiplier = 1.3,
		FireRate = 1.4,
		Automatic = false,
		MagSize = 6,
		ReserveAmmo = 36,
		ReloadTime = 2.4,
		Range = 160,
		Spread = 6,
		AimSpread = 4.5,
		Pellets = 8,
		Recoil = 4,
		AimFOV = 65,
		ViewOffset = CFrame.new(0.8, -0.85, -1.9),
		AimDistance = 1.0,
		RightHand = V(0, -0.48, 0.55),
		LeftHand = V(0, -0.38, -1.15),
		AimPoint = V(0, 0.43, 0.75),
		Muzzle = V(0, 0.12, -2.38),
	},

	Specter9 = {
		DisplayName = "Specter-9",
		Category = "Subfusil",
		Description = "Muévete rápido, golpea fuerte, desaparece.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Specter,
		Parts = Designs.Specter9(),
		UnlockLevel = 1,
		Damage = 18,
		MinDamage = 11,
		FalloffStart = 50,
		FalloffEnd = 160,
		HeadshotMultiplier = 1.4,
		FireRate = 14,
		Automatic = true,
		MagSize = 32,
		ReserveAmmo = 160,
		ReloadTime = 1.6,
		Range = 400,
		Spread = 2.2,
		AimSpread = 0.6,
		Pellets = 1,
		Recoil = 0.55,
		AimFOV = 65,
		WalkSpeedMultiplier = 1.08,
		ViewOffset = CFrame.new(0.75, -0.78, -1.7),
		AimDistance = 1.1,
		RightHand = V(0, -0.45, 0.32),
		LeftHand = V(0, -0.26, -0.65),
		AimPoint = V(0, 0.53, 0.45),
		Muzzle = V(0, 0, -1.52),
	},

	Signal7 = {
		DisplayName = "Signal-7",
		Category = "Francotirador",
		Description = "Un tiro a la cabeza desde el otro lado del mapa.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Signal,
		Parts = Designs.Signal7(),
		UnlockLevel = 3,
		Price = 500,
		Damage = 90,
		MinDamage = 90,
		FalloffStart = 2000,
		FalloffEnd = 2000,
		HeadshotMultiplier = 2,
		FireRate = 0.9,
		Automatic = false,
		MagSize = 5,
		ReserveAmmo = 25,
		ReloadTime = 2.8,
		Range = 2000,
		Spread = 6,
		AimSpread = 0,
		Pellets = 1,
		Recoil = 5,
		AimFOV = 20,
		Scope = true, -- muestra mira telescópica al apuntar
		ViewOffset = CFrame.new(0.8, -0.85, -2.2),
		AimDistance = 1.0,
		RightHand = V(0, -0.45, 0.62),
		LeftHand = V(0, -0.2, -1.4),
		AimPoint = V(0, 0.52, 1.0),
		Muzzle = V(0, 0.05, -3.78),
	},

	VortexBR = {
		DisplayName = "Vortex AR-9",
		Category = "Fusil de energía",
		Description = "Ráfagas de 3 disparos de energía. Letal a media distancia.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Vortex,
		Parts = Designs.VortexBR(),
		UnlockLevel = 4,
		Price = 750,
		Damage = 30,
		MinDamage = 20,
		FalloffStart = 100,
		FalloffEnd = 300,
		HeadshotMultiplier = 1.5,
		FireRate = 14, -- dentro de la ráfaga
		Burst = 3,
		BurstCooldown = 0.32,
		Automatic = false,
		MagSize = 24,
		ReserveAmmo = 120,
		ReloadTime = 2.0,
		Range = 600,
		Spread = 1.2,
		AimSpread = 0.15,
		Pellets = 1,
		Recoil = 0.9,
		AimFOV = 58,
		ViewOffset = CFrame.new(0.8, -0.85, -2.0),
		AimDistance = 1.0,
		RightHand = V(0, -0.48, 0.44),
		LeftHand = V(0, -0.3, -1.0),
		AimPoint = V(0, 0.66, 0.35),
		Muzzle = V(0, 0.06, -2.28),
	},

	NovaDrift = {
		DisplayName = "Nova Drift",
		Category = "Subfusil",
		Description = "El subfusil más ágil: corre más y dispara sin parar.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Drift,
		Parts = Designs.NovaDrift(),
		UnlockLevel = 5,
		Price = 800,
		Damage = 15,
		MinDamage = 9,
		FalloffStart = 40,
		FalloffEnd = 140,
		HeadshotMultiplier = 1.4,
		FireRate = 16,
		Automatic = true,
		MagSize = 36,
		ReserveAmmo = 180,
		ReloadTime = 1.5,
		Range = 380,
		Spread = 2.4,
		AimSpread = 0.7,
		Pellets = 1,
		Recoil = 0.45,
		AimFOV = 66,
		WalkSpeedMultiplier = 1.12,
		ViewOffset = CFrame.new(0.75, -0.78, -1.7),
		AimDistance = 1.1,
		RightHand = V(0, -0.45, 0.32),
		LeftHand = V(0, -0.36, -0.85),
		AimPoint = V(0, 0.56, 0.45),
		Muzzle = V(0, 0, -1.57),
	},

	RaptorDMR = {
		DisplayName = "Raptor DMR",
		Category = "Fusil de tirador",
		Description = "Semiautomático con mira de aumento. Dos tiros a la cabeza.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Raptor,
		Parts = Designs.RaptorDMR(),
		UnlockLevel = 7,
		Price = 1200,
		Damage = 48,
		MinDamage = 38,
		FalloffStart = 200,
		FalloffEnd = 500,
		HeadshotMultiplier = 1.8,
		FireRate = 3.2,
		Automatic = false,
		MagSize = 12,
		ReserveAmmo = 60,
		ReloadTime = 2.2,
		Range = 900,
		Spread = 2.5,
		AimSpread = 0.05,
		Pellets = 1,
		Recoil = 2.4,
		AimFOV = 40,
		ViewOffset = CFrame.new(0.8, -0.85, -2.0),
		AimDistance = 1.1,
		RightHand = V(0, -0.45, 0.42),
		LeftHand = V(0, -0.18, -1.2),
		AimPoint = V(0, 0.55, 0.4),
		Muzzle = V(0, 0.04, -2.7),
	},

	BreachHammer = {
		DisplayName = "Breach Hammer",
		Category = "Escopeta pesada",
		Description = "Semiautomática: vacía el cargador a quemarropa.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Breach,
		Parts = Designs.BreachHammer(),
		UnlockLevel = 8,
		Price = 1400,
		Damage = 10,
		MinDamage = 2,
		FalloffStart = 18,
		FalloffEnd = 55,
		HeadshotMultiplier = 1.25,
		FireRate = 2.6,
		Automatic = false,
		MagSize = 8,
		ReserveAmmo = 40,
		ReloadTime = 2.8,
		Range = 140,
		Spread = 7,
		AimSpread = 5.5,
		Pellets = 9,
		Recoil = 3.4,
		AimFOV = 66,
		WalkSpeedMultiplier = 0.95,
		ViewOffset = CFrame.new(0.8, -0.85, -1.9),
		AimDistance = 1.0,
		RightHand = V(0, -0.5, 0.55),
		LeftHand = V(0, -0.44, -1.15),
		AimPoint = V(0, 0.45, 0.8),
		Muzzle = V(0, 0.1, -2.29),
	},

	TitanLMG = {
		DisplayName = "Titan Grind",
		Category = "Ametralladora pesada",
		Description = "80 balas por cargador. Mantén la zona bajo fuego.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Grind,
		Parts = Designs.TitanLMG(),
		UnlockLevel = 10,
		Price = 1800,
		Damage = 26,
		MinDamage = 18,
		FalloffStart = 120,
		FalloffEnd = 350,
		HeadshotMultiplier = 1.4,
		FireRate = 9,
		Automatic = true,
		MagSize = 80,
		ReserveAmmo = 240,
		ReloadTime = 4.2,
		Range = 600,
		Spread = 2.4,
		AimSpread = 0.6,
		Pellets = 1,
		Recoil = 0.7,
		AimFOV = 60,
		WalkSpeedMultiplier = 0.85,
		ViewOffset = CFrame.new(0.85, -0.95, -2.0),
		AimDistance = 1.15,
		RightHand = V(0, -0.52, 0.62),
		LeftHand = V(0, -0.45, -1.3),
		AimPoint = V(0, 0.62, 0.4),
		Muzzle = V(0, 0.08, -2.36),
	},

	GhostlineXR = {
		DisplayName = "Ghostline XR",
		Suppressed = true, -- con silenciador: los bots casi no lo oyen
		Category = "Francotirador",
		Description = "Supresor y mira de largo alcance. Un tiro al cuerpo basta.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Ghost,
		Parts = Designs.GhostlineXR(),
		UnlockLevel = 12,
		Price = 2200,
		Damage = 105,
		MinDamage = 100,
		FalloffStart = 2000,
		FalloffEnd = 2000,
		HeadshotMultiplier = 2,
		FireRate = 0.7,
		Automatic = false,
		MagSize = 4,
		ReserveAmmo = 20,
		ReloadTime = 3.2,
		Range = 2000,
		Spread = 7,
		AimSpread = 0,
		Pellets = 1,
		Recoil = 5.5,
		AimFOV = 16,
		Scope = true,
		WalkSpeedMultiplier = 0.92,
		ViewOffset = CFrame.new(0.8, -0.85, -2.3),
		AimDistance = 1.0,
		RightHand = V(0, -0.45, 0.62),
		LeftHand = V(0, -0.2, -1.5),
		AimPoint = V(0, 0.55, 1.0),
		Muzzle = V(0, 0.04, -3.5),
	},

	NovaLauncher = {
		DisplayName = "Tempest Core",
		Category = "Lanzacohetes",
		Description = "Cohetes con núcleo de energía. Daño en área contra grupos.",
		Slot = 1,
		Type = "Gun",
		Palette = Palettes.Tempest,
		Parts = Designs.NovaLauncher(),
		UnlockLevel = 14,
		Price = 3000,
		Damage = 120,
		MinDamage = 120,
		FalloffStart = 500,
		FalloffEnd = 500,
		HeadshotMultiplier = 1,
		FireRate = 0.8,
		Automatic = false,
		MagSize = 1,
		ReserveAmmo = 5,
		ReloadTime = 2.6,
		Range = 500,
		Spread = 0.5,
		AimSpread = 0,
		Pellets = 1,
		Recoil = 6,
		AimFOV = 60,
		Explosive = { Radius = 14, Damage = 120, MinDamage = 30 },
		ProjectileSpeed = 220,
		WalkSpeedMultiplier = 0.9,
		ViewOffset = CFrame.new(0.9, -0.95, -1.8),
		AimDistance = 1.2,
		RightHand = V(0, -0.45, 0.12),
		LeftHand = V(0, -0.4, -1.55),
		AimPoint = V(0, 0.64, 0.4),
		Muzzle = V(0, 0.12, -2.4),
	},

	Viper = {
		DisplayName = "Viper P9",
		Category = "Pistola",
		Description = "Rápida y precisa. Tu plan B.",
		Slot = 2,
		Type = "Gun",
		Palette = Palettes.Viper,
		Parts = Designs.Viper(),
		UnlockLevel = 1,
		Damage = 26,
		MinDamage = 15,
		FalloffStart = 60,
		FalloffEnd = 200,
		HeadshotMultiplier = 1.5,
		FireRate = 7,
		Automatic = false,
		MagSize = 12,
		ReserveAmmo = 72,
		ReloadTime = 1.4,
		Range = 400,
		Spread = 1.4,
		AimSpread = 0.3,
		Pellets = 1,
		Recoil = 1.6,
		AimFOV = 65,
		ViewOffset = CFrame.new(0.6, -0.62, -1.6),
		AimDistance = 1.3,
		RightHand = V(0, -0.5, 0.32),
		LeftHand = V(-0.16, -0.56, 0.3),
		AimPoint = V(0, 0.21, 0.55),
		Muzzle = V(0, 0.02, -0.62),
	},

	HandCannon = {
		DisplayName = "Hand Cannon",
		Category = "Revólver",
		Description = "Seis balas que no perdonan.",
		Slot = 2,
		Type = "Gun",
		Palette = Palettes.Gold,
		Parts = Designs.HandCannon(),
		UnlockLevel = 6,
		Price = 900,
		Damage = 55,
		MinDamage = 35,
		FalloffStart = 60,
		FalloffEnd = 200,
		HeadshotMultiplier = 1.7,
		FireRate = 2.2,
		Automatic = false,
		MagSize = 6,
		ReserveAmmo = 36,
		ReloadTime = 2.0,
		Range = 400,
		Spread = 1.6,
		AimSpread = 0.2,
		Pellets = 1,
		Recoil = 4.5,
		AimFOV = 60,
		ViewOffset = CFrame.new(0.6, -0.62, -1.7),
		AimDistance = 1.4,
		RightHand = V(0, -0.45, 0.3),
		LeftHand = V(-0.16, -0.5, 0.28),
		AimPoint = V(0, 0.29, 0.5),
		Muzzle = V(0, 0.06, -1.43),
	},

	PhantomSidewind = {
		DisplayName = "Phantom Sidewind",
		Category = "Pistola táctica",
		Description = "Mira de punto y ráfagas de 2. Precisión de francotirador en una pistola.",
		Slot = 2,
		Type = "Gun",
		Palette = Palettes.Phantom,
		Parts = Designs.PhantomSidewind(),
		UnlockLevel = 9,
		Price = 1000,
		Damage = 28,
		MinDamage = 18,
		FalloffStart = 80,
		FalloffEnd = 250,
		HeadshotMultiplier = 1.6,
		FireRate = 12, -- dentro de la ráfaga
		Burst = 2,
		BurstCooldown = 0.28,
		Automatic = false,
		MagSize = 16,
		ReserveAmmo = 80,
		ReloadTime = 1.5,
		Range = 450,
		Spread = 1.2,
		AimSpread = 0.15,
		Pellets = 1,
		Recoil = 1.8,
		AimFOV = 60,
		ViewOffset = CFrame.new(0.6, -0.62, -1.6),
		AimDistance = 1.3,
		RightHand = V(0, -0.52, 0.32),
		LeftHand = V(-0.16, -0.58, 0.3),
		AimPoint = V(0, 0.32, 0.55),
		Muzzle = V(0, 0, -0.76),
	},

	Knife = {
		DisplayName = "Colmillo",
		Category = "Cuerpo a cuerpo",
		Slot = 3,
		Type = "Melee",
		Palette = Palettes.Fang,
		Parts = Designs.Knife(),
		UnlockLevel = 1,
		Damage = 55,
		Range = 7,
		Cooldown = 0.55,
		ViewOffset = CFrame.new(0.8, -0.75, -1.5) * CFrame.Angles(rad(15), rad(20), 0),
		RightHand = V(0, 0, 0.1),
	},
}

-- Armas cuerpo a cuerpo que se pueden elegir en vez del cuchillo (tecla F y ranura 3)
do
	local katana = {
		DisplayName = "Katana",
		Category = "Cuerpo a cuerpo",
		Description = "Más alcance y más daño, pero más lenta.",
		Slot = 3,
		Type = "Melee",
		Palette = { Body = RGB(30, 30, 34), Panel = RGB(200, 40, 50), Dark = RGB(60, 50, 40), Accent = RGB(235, 240, 250), Accent2 = RGB(200, 160, 60), Lens = RGB(70, 120, 175), PanelMaterial = Enum.Material.Fabric, AccentMaterial = Enum.Material.Metal, Accent2Material = Enum.Material.Metal },
		UnlockLevel = 6,
		Price = 900,
		Damage = 70,
		Range = 9,
		Cooldown = 0.8,
		-- Más a la derecha y hacia abajo para no tapar la mira
		ViewOffset = CFrame.new(0.95, -0.9, -1.3) * CFrame.Angles(rad(10), rad(-10), rad(-20)),
		RightHand = V(0, 0, 0.15),
	}
	katana.Parts = Classic.Katana(katana)
	Weapons.List.Katana = katana
	local hammer = {
		DisplayName = "Martillo de juguete",
		Category = "Cuerpo a cuerpo",
		Description = "¡Boing! Golpes rapidísimos con mucho estilo.",
		Slot = 3,
		Type = "Melee",
		Palette = { Body = RGB(235, 50, 60), Panel = RGB(255, 210, 50), Dark = RGB(40, 40, 46), Accent = RGB(255, 255, 255), Accent2 = RGB(60, 140, 255), Lens = RGB(70, 120, 175), BodyMaterial = Enum.Material.SmoothPlastic, PanelMaterial = Enum.Material.SmoothPlastic, AccentMaterial = Enum.Material.SmoothPlastic, Accent2Material = Enum.Material.SmoothPlastic },
		UnlockLevel = 4,
		Price = 600,
		Damage = 42,
		Range = 7.5,
		Cooldown = 0.42,
		ViewOffset = CFrame.new(0.85, -0.8, -1.5) * CFrame.Angles(rad(20), rad(15), 0),
		RightHand = V(0, 0, 0.35),
	}
	hammer.Parts = Classic.ToyHammer(hammer)
	Weapons.List.ToyHammer = hammer
	-- Halloween
	local scythe = {
		DisplayName = "Guadaña",
		Category = "Cuerpo a cuerpo",
		Description = "¡Edición Halloween! Mucho alcance y golpes que dan miedo.",
		Slot = 3,
		Type = "Melee",
		Palette = { Body = RGB(70, 45, 35), Panel = RGB(70, 45, 35), Dark = RGB(35, 30, 40), Accent = RGB(215, 220, 235), Accent2 = RGB(170, 70, 255), Lens = RGB(70, 120, 175), BodyMaterial = Enum.Material.Wood, AccentMaterial = Enum.Material.Metal, Accent2Material = Enum.Material.Neon },
		UnlockLevel = 3,
		Price = 1500,
		Damage = 65,
		Range = 10,
		Cooldown = 0.85,
		ViewOffset = CFrame.new(0.95, -0.95, -1.2) * CFrame.Angles(rad(15), rad(-8), rad(-25)),
		RightHand = V(0, 0, 0.45),
	}
	scythe.Parts = Classic.Scythe(scythe)
	Weapons.List.Scythe = scythe
end

-- Calabazooka: premio del evento de Halloween (75 caramelos). Lanza calabazas que explotan.
do
	local base = Weapons.List.NovaLauncher
	local pumpkin = table.clone(base)
	pumpkin.DisplayName = "Calabazooka"
	pumpkin.Category = "Lanzacohetes"
	pumpkin.Description = "¡Premio de Halloween! Calabazas explosivas con cara de susto."
	pumpkin.Palette = { Body = RGB(60, 35, 80), Panel = RGB(255, 130, 20), Accent = RGB(255, 210, 60), Accent2 = RGB(90, 170, 60), Dark = RGB(30, 22, 40), AccentMaterial = Enum.Material.Neon }
	pumpkin.UnlockLevel = 999 -- (no se desbloquea por nivel: solo con el evento)
	pumpkin.Price = nil
	pumpkin.EventText = "🎃 75 caramelos"
	pumpkin.Explosive = { Radius = 13, Damage = 115, MinDamage = 30 }
	pumpkin.ReserveAmmo = 6
	pumpkin.ProjectileStyle = "Pumpkin"
	pumpkin.Parts = Classic.Calabazooka(pumpkin)
	Weapons.List.Calabazooka = pumpkin
end

-- Garras: arma de los zombis en el modo Infección (no se elige ni se vende: Hidden)
do
	local claws = {
		DisplayName = "Garras",
		Category = "Cuerpo a cuerpo",
		Description = "Solo para zombis (modo Infección).",
		Slot = 3,
		Type = "Melee",
		Hidden = true,
		ZombieArms = Color3.fromRGB(110, 165, 80), -- brazos verdes en primera persona
		Palette = { Body = RGB(95, 150, 70), Panel = RGB(95, 150, 70), Dark = RGB(60, 40, 50), Accent = RGB(235, 228, 200), Accent2 = RGB(170, 20, 30), Lens = RGB(70, 120, 175), BodyMaterial = Enum.Material.SmoothPlastic, AccentMaterial = Enum.Material.SmoothPlastic },
		UnlockLevel = 1,
		Damage = 50,
		Range = 8,
		Cooldown = 0.5,
		WalkSpeedMultiplier = 1.12, -- los zombis corren un poco más
		ViewOffset = CFrame.new(0.85, -0.85, -1.4) * CFrame.Angles(rad(10), rad(10), 0),
		RightHand = V(0, 0, 0.15),
	}
	claws.Parts = Classic.Claws(claws)
	Weapons.List.Claws = claws
end

-- Marcadora de paintball (estilo cartoon): las bolas dejan salpicaduras de pintura de colores
do
	local splat = {
		DisplayName = "Splat-X",
		Category = "Paintball",
		Description = "Pinta el mapa (y a tus rivales) de todos los colores.",
		Slot = 1,
		Type = "Gun",
		Palette = {
			Body = RGB(40, 140, 255),
			BodyMaterial = Enum.Material.SmoothPlastic,
			Panel = RGB(34, 34, 40),
			PanelMaterial = Enum.Material.SmoothPlastic,
			Dark = RGB(26, 26, 30),
			Accent = RGB(255, 70, 170),
			AccentMaterial = Enum.Material.SmoothPlastic,
			Accent2 = RGB(255, 215, 50),
			Accent2Material = Enum.Material.SmoothPlastic,
			Lens = RGB(70, 120, 175),
		},
		UnlockLevel = 2,
		Price = 400,
		Damage = 21,
		MinDamage = 15,
		FalloffStart = 60,
		FalloffEnd = 200,
		HeadshotMultiplier = 1.5,
		FireRate = 8,
		Automatic = true,
		MagSize = 25,
		ReserveAmmo = 125,
		ReloadTime = 1.7,
		Range = 450,
		Spread = 1.4,
		AimSpread = 0.4,
		Pellets = 1,
		Recoil = 0.45,
		AimFOV = 62,
		WalkSpeedMultiplier = 1.05,
		ImpactStyle = "Paint", -- salpicaduras de colores (ver Effects.Impact)
		ViewOffset = CFrame.new(0.78, -0.8, -1.8),
		AimDistance = 1.1,
		RightHand = V(0, -0.45, 0.32),
		LeftHand = V(0, -0.26, -0.7),
		AimPoint = V(0, 0.36, 0.45),
		Muzzle = V(0, 0.08, -1.55),
	}
	splat.Parts = Classic.SplatX(splat)
	Weapons.List.SplatX = splat
end

-- Ballesta (estilo cazador de Halloween): lenta, sin cargador, mucho daño y mata de un tiro a la cabeza
do
	local crossbow = {
		DisplayName = "Ballesta",
		Category = "Ballesta",
		Description = "Un virote cada vez. A la cabeza, no perdona.",
		Slot = 1,
		Type = "Gun",
		Palette = {
			Body = RGB(120, 78, 45),
			BodyMaterial = Enum.Material.Wood,
			Panel = RGB(70, 72, 80),
			PanelMaterial = Enum.Material.Metal,
			Dark = RGB(30, 28, 30),
			Accent = RGB(220, 40, 45),
			Accent2 = RGB(230, 180, 60),
			Lens = RGB(70, 120, 175),
		},
		UnlockLevel = 9,
		Price = 2000,
		Damage = 85,
		MinDamage = 70,
		FalloffStart = 150,
		FalloffEnd = 400,
		HeadshotMultiplier = 2,
		FireRate = 1.1,
		Automatic = false,
		MagSize = 1,
		ReserveAmmo = 20,
		ReloadTime = 1.1,
		Range = 700,
		Spread = 1.2,
		AimSpread = 0.05,
		Pellets = 1,
		Recoil = 1.6,
		AimFOV = 50,
		ViewOffset = CFrame.new(0.8, -0.85, -1.9),
		AimDistance = 1.1,
		RightHand = V(0, -0.42, 0.4),
		LeftHand = V(0, -0.18, -0.9),
		AimPoint = V(0, 0.3, 0.4),
		Muzzle = V(0, 0.06, -1.6),
	}
	crossbow.Parts = Classic.Crossbow(crossbow)
	Weapons.List.Crossbow = crossbow
end

-- Armas que el jugador puede elegir
Weapons.Primaries = {
	"ARX27",
	"HavocPump",
	"Specter9",
	"Signal7",
	"VortexBR",
	"NovaDrift",
	"RaptorDMR",
	"BreachHammer",
	"TitanLMG",
	"GhostlineXR",
	"NovaLauncher",
	"Calabazooka",
	"SplatX",
	"Crossbow",
}
Weapons.Secondaries = { "Viper", "HandCannon", "PhantomSidewind" }
Weapons.Secondary = "Viper" -- secundaria por defecto
Weapons.Melee = "Knife" -- cuerpo a cuerpo por defecto (y el de la Escalada de armas)
Weapons.Melees = { "Knife", "ToyHammer", "Katana", "Scythe" } -- los que se pueden elegir

-- Orden del modo "Escalada de armas": cada baja te da la siguiente
Weapons.GunGameOrder = {
	"ARX27",
	"NovaDrift",
	"VortexBR",
	"Specter9",
	"BreachHammer",
	"TitanLMG",
	"RaptorDMR",
	"GhostlineXR",
	"Signal7",
	"NovaLauncher",
	"HavocPump",
	"PhantomSidewind",
	"HandCannon",
	"Viper",
	"Knife",
}

-- Nombres antiguos guardados en DataStore -> nombres nuevos
Weapons.Legacy = { Rifle = "ARX27", Shotgun = "HavocPump", Sniper = "Signal7", Pistol = "Viper" }

-- Granada de fragmentación (tecla G). No ocupa hueco: cada jugador tiene una que se recarga sola.
Weapons.Grenade = {
	DisplayName = "Granada",
	Type = "Grenade",
	Pellets = 1,
	Damage = 110,
	Explosive = { Radius = 16, Damage = 110, MinDamage = 25 },
	Cooldown = 15, -- segundos hasta tener otra
	Fuse = 2.2, -- segundos hasta explotar
	ThrowSpeed = 80,
}

-- Ataque aéreo (recompensa por racha de 5 bajas, ver Killstreaks)
Weapons.Airstrike = {
	DisplayName = "Ataque aéreo",
	Type = "Streak",
	Pellets = 1,
	Damage = 95,
	Explosive = { Radius = 13, Damage = 95, MinDamage = 30 },
}

-- Estilo de las armas: "Clasico" (siluetas reales, madera y metal, como los shooters más jugados de
-- Roblox) o "SciFi" (el concept pack original con neón). Las skins de la tienda siguen poniendo neón.
Weapons.Style = "Clasico"

local MAT = Enum.Material
-- Sheen / DarkSheen: brillo (Reflectance) del cuerpo y de las piezas de metal oscuro; TrimAccent: los
-- ribetes llevan el color de acento también con el acabado de fábrica. Las skins no los usan.
local CLASSIC_PALETTES = {
	-- Polímero negro azulado con muebles color arena y ribetes naranjas
	Black = { Sheen = 0.02, DarkSheen = 0.1, TrimAccent = true, Body = RGB(40, 42, 46), Panel = RGB(190, 156, 106), Dark = RGB(26, 27, 31), Accent = RGB(255, 140, 40), Accent2 = RGB(120, 84, 50), Lens = RGB(70, 120, 175), AccentMaterial = MAT.SmoothPlastic, Accent2Material = MAT.Wood },
	-- PULSE (armas con malla, tools/blender): negro azulado, paneles naranja de la casa y testigos de
	-- luz cian. Es la identidad de fábrica de SHOOTERROB; las skins la sustituyen como siempre.
	Pulse = { Sheen = 0, DarkSheen = 0.06, TrimAccent = false, Body = RGB(34, 36, 42), Panel = RGB(245, 122, 26), Dark = RGB(20, 21, 26), Accent = RGB(70, 225, 255), Accent2 = RGB(255, 190, 60), Lens = RGB(90, 170, 255), Trim = RGB(245, 122, 26), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- HAVOC (escopeta): la familia Pulse con el naranja más rojo, cartuchos rojos (Trim) y culotes de latón
	Havoc = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(255, 86, 22), Dark = RGB(20, 21, 26), Accent = RGB(70, 225, 255), Accent2 = RGB(214, 168, 70), Lens = RGB(90, 170, 255), Trim = RGB(205, 34, 38), AccentMaterial = MAT.Neon, Accent2Material = MAT.Metal, PanelMaterial = MAT.SmoothPlastic },
	-- VORTEX (arma de energía): blindaje gris hielo y conductos violeta
	Vortex = { Sheen = 0, DarkSheen = 0.06, Body = RGB(30, 32, 40), Panel = RGB(206, 216, 232), Dark = RGB(18, 19, 25), Accent = RGB(160, 96, 255), Accent2 = RGB(90, 220, 255), Lens = RGB(90, 220, 255), Trim = RGB(206, 216, 232), AccentMaterial = MAT.Neon, Accent2Material = MAT.Neon, PanelMaterial = MAT.SmoothPlastic },
	-- TITAN (ametralladora): la familia Pulse con la cinta de cartuchos de latón (Trim)
	Titan = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(250, 92, 20), Dark = RGB(20, 21, 26), Accent = RGB(70, 225, 255), Accent2 = RGB(214, 168, 70), Lens = RGB(90, 170, 255), Trim = RGB(214, 168, 70), AccentMaterial = MAT.Neon, Accent2Material = MAT.Metal, PanelMaterial = MAT.SmoothPlastic },
	-- DRIFT (subfusil ágil: verde azulado con luz lima)
	Drift = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(40, 200, 150), Dark = RGB(20, 21, 26), Accent = RGB(218, 255, 97), Accent2 = RGB(255, 190, 60), Lens = RGB(97, 225, 203), Trim = RGB(225, 232, 227), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- RAPTOR (tirador: dorado desierto)
	Raptor = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(235, 170, 50), Dark = RGB(20, 21, 26), Accent = RGB(70, 225, 255), Accent2 = RGB(255, 190, 60), Lens = RGB(90, 170, 255), Trim = RGB(249, 211, 111), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- BREACH (escopeta semiautomática: amarillo de obra y luz roja)
	Breach = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(250, 204, 31), Dark = RGB(20, 21, 26), Accent = RGB(255, 44, 30), Accent2 = RGB(255, 190, 60), Lens = RGB(90, 170, 255), Trim = RGB(250, 204, 31), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- GHOST (francotirador con supresor: blanco fantasma y luz azul fría)
	Ghost = { Sheen = 0, DarkSheen = 0.06, Body = RGB(30, 32, 40), Panel = RGB(215, 220, 228), Dark = RGB(20, 21, 26), Accent = RGB(80, 124, 255), Accent2 = RGB(215, 220, 228), Lens = RGB(97, 149, 249), Trim = RGB(215, 220, 228), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- TEMPEST (lanzacohetes: naranja de la casa, cabeza roja (Trim) y franjas amarillas (Accent2))
	Tempest = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(247, 92, 10), Dark = RGB(20, 21, 26), Accent = RGB(70, 225, 255), Accent2 = RGB(255, 199, 20), Lens = RGB(90, 170, 255), Trim = RGB(219, 15, 13), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- CANNON (revólver: acero, rojo oscuro y luz ámbar)
	Cannon = { Sheen = 0, DarkSheen = 0.06, Body = RGB(40, 42, 48), Panel = RGB(200, 40, 40), Dark = RGB(20, 21, 26), Accent = RGB(255, 205, 95), Accent2 = RGB(255, 190, 60), Lens = RGB(90, 170, 255), Trim = RGB(200, 40, 40), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- PHANTOM (pistola de ráfagas: magenta y cian)
	Phantom = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(235, 60, 150), Dark = RGB(20, 21, 26), Accent = RGB(70, 225, 255), Accent2 = RGB(255, 190, 60), Lens = RGB(90, 170, 255), Trim = RGB(235, 60, 150), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- KATANA (katana: carmesí y filo cian)
	Katana = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(215, 40, 50), Accent = RGB(70, 225, 255), Accent2 = RGB(255, 190, 60), Lens = RGB(90, 170, 255), Trim = RGB(215, 40, 50), Dark = RGB(20, 21, 26), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- TOY (martillo de juguete: rojo, amarillo y azul)
	Toy = { Sheen = 0, DarkSheen = 0.06, Body = RGB(235, 50, 45), Panel = RGB(235, 50, 45), Accent = RGB(238, 250, 255), Accent2 = RGB(255, 205, 40), Lens = RGB(90, 170, 255), Trim = RGB(50, 120, 255), Rubber = RGB(30, 52, 110), Dark = RGB(20, 21, 26), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- REAPER (guadaña: naranja calabaza y filo verde tóxico)
	Reaper = { Sheen = 0, DarkSheen = 0.06, Body = RGB(48, 46, 59), Panel = RGB(255, 120, 20), Accent = RGB(120, 255, 80), Accent2 = RGB(150, 70, 220), Lens = RGB(90, 170, 255), Trim = RGB(255, 120, 20), Dark = RGB(20, 21, 26), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- PUMPKIN (Calabazooka: calabaza, enredadera verde, luz de vela y morado)
	Pumpkin = { Sheen = 0, DarkSheen = 0.06, Body = RGB(62, 52, 82), Panel = RGB(255, 120, 20), Accent = RGB(255, 200, 60), Accent2 = RGB(150, 70, 220), Lens = RGB(120, 230, 140), Trim = RGB(110, 200, 60), Rubber = RGB(115, 90, 60), Dark = RGB(20, 21, 26), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- SPLAT (marcadora de pintura: rosa, cian, amarillo y luz lima)
	Splat = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(255, 60, 170), Accent = RGB(170, 255, 80), Accent2 = RGB(60, 220, 255), Lens = RGB(150, 230, 255), Trim = RGB(255, 220, 50), Dark = RGB(20, 21, 26), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- HUNTER (ballesta: verde bosque y luz ámbar)
	Hunter = { Sheen = 0, DarkSheen = 0.06, Body = RGB(34, 36, 42), Panel = RGB(60, 170, 80), Accent = RGB(255, 190, 70), Accent2 = RGB(255, 190, 60), Lens = RGB(90, 170, 255), Trim = RGB(60, 170, 80), Dark = RGB(20, 21, 26), AccentMaterial = MAT.Neon, Accent2Material = MAT.SmoothPlastic, PanelMaterial = MAT.SmoothPlastic },
	-- Metal pavonado y madera
	Wood = { Sheen = 0.04, DarkSheen = 0.1, BodyMaterial = MAT.Metal, Body = RGB(50, 52, 56), Panel = RGB(140, 84, 44), Dark = RGB(30, 30, 33), Accent = RGB(255, 140, 40), Accent2 = RGB(122, 78, 44), Lens = RGB(70, 120, 175), AccentMaterial = MAT.SmoothPlastic, PanelMaterial = MAT.Wood, Accent2Material = MAT.Wood },
	-- Color arena (desierto)
	Tan = { Sheen = 0.02, DarkSheen = 0.1, TrimAccent = true, Body = RGB(196, 164, 112), Panel = RGB(40, 41, 46), Dark = RGB(32, 32, 34), Accent = RGB(255, 140, 40), Accent2 = RGB(120, 84, 50), Lens = RGB(70, 120, 175), AccentMaterial = MAT.SmoothPlastic, Accent2Material = MAT.Wood },
	-- Verde oliva militar
	Olive = { Sheen = 0.02, DarkSheen = 0.1, TrimAccent = true, Body = RGB(74, 88, 52), Panel = RGB(112, 124, 78), Dark = RGB(32, 33, 30), Accent = RGB(255, 140, 40), Accent2 = RGB(128, 84, 48), Lens = RGB(70, 120, 175), AccentMaterial = MAT.SmoothPlastic, Accent2Material = MAT.Wood },
	-- Acero inoxidable y cachas de madera
	Steel = { Sheen = 0.12, DarkSheen = 0.1, Body = RGB(186, 190, 198), Panel = RGB(130, 76, 38), Dark = RGB(60, 62, 66), Accent = RGB(255, 140, 40), Accent2 = RGB(118, 72, 40), Lens = RGB(70, 120, 175), BodyMaterial = MAT.Metal, PanelMaterial = MAT.Wood, AccentMaterial = MAT.SmoothPlastic },
	-- Dos tonos: corredera negra y armazón arena
	TwoTone = { Sheen = 0.02, DarkSheen = 0.1, Body = RGB(190, 160, 112), Panel = RGB(44, 46, 52), Dark = RGB(30, 30, 33), Accent = RGB(255, 140, 40), Accent2 = RGB(120, 84, 50), Lens = RGB(70, 120, 175), PanelMaterial = MAT.Metal, AccentMaterial = MAT.SmoothPlastic },
	-- Cuchillo: hoja de acero, mango negro
	Knife = { Body = RGB(40, 40, 44), Panel = RGB(150, 152, 158), Dark = RGB(170, 172, 178), Accent = RGB(120, 122, 128), Accent2 = RGB(200, 200, 205), Lens = RGB(70, 120, 175), PanelMaterial = MAT.Metal, AccentMaterial = MAT.Metal },
}
Weapons.ClassicPalettes = CLASSIC_PALETTES
local CLASSIC_LOOK = {
	ARX27 = "Pulse", HavocPump = "Havoc", Specter9 = "Pulse", Signal7 = "Pulse", VortexBR = "Vortex",
	NovaDrift = "Drift", RaptorDMR = "Raptor", BreachHammer = "Breach", TitanLMG = "Titan", GhostlineXR = "Ghost",
	NovaLauncher = "Tempest", Viper = "Pulse", HandCannon = "Cannon", PhantomSidewind = "Phantom", Knife = "Pulse",
	Katana = "Katana",
	ToyHammer = "Toy",
	Scythe = "Reaper",
	Calabazooka = "Pumpkin",
	SplatX = "Splat",
	Crossbow = "Hunter",
}
if Weapons.Style == "Clasico" then
	for name, def in Weapons.List do
		for key, value in Classic.Points[name] or {} do
			def[key] = value
		end
		local build = Classic[name]
		if build then
			def.Parts = build(def)
			-- Nombres únicos (las piezas repetidas del bisel se numeran: Edge, Edge2, Edge3...)
			local seen = {}
			for _, part in def.Parts do
				local count = (seen[part.Name] or 0) + 1
				seen[part.Name] = count
				if count > 1 then
					part.Name ..= count
				end
			end
		end
		local look = CLASSIC_LOOK[name]
		if look then
			def.Palette = CLASSIC_PALETTES[look]
		end
	end
end

function Weapons.Get(name)
	if name == "Grenade" then
		return Weapons.Grenade
	elseif name == "Airstrike" then
		return Weapons.Airstrike
	end
	return Weapons.List[name] or Weapons.List[Weapons.Legacy[name] or ""]
end

-- Recarga táctica (como en los shooters realistas): si aún quedan balas en el cargador no hay que
-- montar el arma, así que es más rápida; con el cargador vacío dura el ReloadTime completo
Weapons.TacticalReload = 0.8
function Weapons.ReloadDuration(def, empty)
	local base = def.ReloadTime or 2
	return empty and base or base * Weapons.TacticalReload
end

-- ¿Puede el jugador usar esta arma? (nivel alcanzado o comprada con monedas)
function Weapons.IsUnlocked(name, data)
	local def = Weapons.List[name]
	if not def then
		return false
	end
	if (def.UnlockLevel or 1) <= 1 then
		return true
	end
	if not data then
		return false
	end
	return (data.Level or 1) >= def.UnlockLevel or (data.OwnedWeapons ~= nil and data.OwnedWeapons[name] == true)
end

return Weapons
