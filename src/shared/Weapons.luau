-- Estadísticas y modelo (hecho con piezas) de cada arma.
-- Espacio del modelo: -Z = hacia delante (cañón), +Y = arriba. "Handle" es la pieza raíz.
local Weapons = {}

local function P(name, size, cf, role)
	return { Name = name, Size = size, CFrame = cf, Role = role }
end

local rad = math.rad

Weapons.List = {
	Rifle = {
		DisplayName = "AR-7 Hiper",
		Slot = 1,
		Type = "Gun",
		Damage = 24,
		MinDamage = 16,
		FalloffStart = 120,
		FalloffEnd = 350,
		HeadshotMultiplier = 1.6,
		FireRate = 10, -- disparos por segundo
		Automatic = true,
		MagSize = 30,
		ReserveAmmo = 150,
		ReloadTime = 1.9,
		Range = 600,
		Spread = 1.6, -- grados (desde la cadera)
		AimSpread = 0.25, -- grados (apuntando)
		Pellets = 1,
		Recoil = 0.8, -- grados por disparo
		AimFOV = 60,
		ViewOffset = CFrame.new(0.75, -0.75, -1.9),
		AimDistance = 0.9,
		RightHand = Vector3.new(0, -0.45, 0.45),
		LeftHand = Vector3.new(0, -0.22, -1.2),
		AimPoint = Vector3.new(0, 0.43, 0.2),
		Muzzle = Vector3.new(0, 0.04, -2.6),
		Parts = {
			P("Handle", Vector3.new(0.3, 0.42, 1.5), CFrame.new(), "Body"),
			P("Rail", Vector3.new(0.32, 0.08, 1.3), CFrame.new(0, 0.25, -0.05), "Accent"),
			P("Handguard", Vector3.new(0.36, 0.36, 0.9), CFrame.new(0, 0, -1.15), "Body"),
			P("HandguardStripe", Vector3.new(0.38, 0.08, 0.9), CFrame.new(0, 0.05, -1.15), "Accent"),
			P("Barrel", Vector3.new(0.14, 0.14, 0.8), CFrame.new(0, 0.04, -2), "Dark"),
			P("Brake", Vector3.new(0.2, 0.2, 0.22), CFrame.new(0, 0.04, -2.45), "Dark"),
			P("Mag", Vector3.new(0.2, 0.65, 0.32), CFrame.new(0, -0.5, -0.35) * CFrame.Angles(rad(-12), 0, 0), "Dark"),
			P("Grip", Vector3.new(0.2, 0.5, 0.28), CFrame.new(0, -0.42, 0.45) * CFrame.Angles(rad(18), 0, 0), "Body"),
			P("Stock", Vector3.new(0.26, 0.36, 0.9), CFrame.new(0, -0.05, 1.2), "Body"),
			P("StockPad", Vector3.new(0.28, 0.4, 0.08), CFrame.new(0, -0.05, 1.68), "Accent"),
			P("SightBase", Vector3.new(0.14, 0.14, 0.3), CFrame.new(0, 0.33, 0.05), "Dark"),
			P("SightDot", Vector3.new(0.06, 0.06, 0.04), CFrame.new(0, 0.43, 0.05), "Accent"),
		},
	},

	Shotgun = {
		DisplayName = "Trueno SG",
		Slot = 1,
		Type = "Gun",
		Damage = 12, -- por perdigón
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
		ViewOffset = CFrame.new(0.75, -0.8, -1.8),
		AimDistance = 0.9,
		RightHand = Vector3.new(0, -0.45, 0.4),
		LeftHand = Vector3.new(0, -0.25, -1.3),
		AimPoint = Vector3.new(0, 0.3, 0.3),
		Muzzle = Vector3.new(0, 0.1, -2.25),
		Parts = {
			P("Handle", Vector3.new(0.3, 0.4, 1.3), CFrame.new(), "Body"),
			P("Barrel", Vector3.new(0.16, 0.16, 1.6), CFrame.new(0, 0.1, -1.4), "Dark"),
			P("Tube", Vector3.new(0.14, 0.14, 1.3), CFrame.new(0, -0.12, -1.4), "Dark"),
			P("Pump", Vector3.new(0.26, 0.24, 0.8), CFrame.new(0, -0.12, -1.3), "Accent"),
			P("Grip", Vector3.new(0.2, 0.5, 0.28), CFrame.new(0, -0.4, 0.4) * CFrame.Angles(rad(18), 0, 0), "Body"),
			P("Stock", Vector3.new(0.26, 0.38, 1), CFrame.new(0, -0.1, 1.1), "Body"),
			P("Stripe", Vector3.new(0.32, 0.08, 1.2), CFrame.new(0, 0.12, 0), "Accent"),
			P("Bead", Vector3.new(0.05, 0.05, 0.05), CFrame.new(0, 0.21, -2.15), "Accent"),
		},
	},

	Sniper = {
		DisplayName = "Halcón X",
		Slot = 1,
		Type = "Gun",
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
		ViewOffset = CFrame.new(0.75, -0.8, -1.9),
		AimDistance = 0.9,
		RightHand = Vector3.new(0, -0.45, 0.5),
		LeftHand = Vector3.new(0, -0.2, -1.2),
		AimPoint = Vector3.new(0, 0.45, 0.6),
		Muzzle = Vector3.new(0, 0.05, -3.1),
		Parts = {
			P("Handle", Vector3.new(0.3, 0.4, 1.6), CFrame.new(), "Body"),
			P("Barrel", Vector3.new(0.13, 0.13, 2), CFrame.new(0, 0.05, -1.8), "Dark"),
			P("MuzzleBrake", Vector3.new(0.2, 0.2, 0.3), CFrame.new(0, 0.05, -2.9), "Dark"),
			P("Scope", Vector3.new(0.22, 0.22, 1.1), CFrame.new(0, 0.45, -0.1), "Dark"),
			P("ScopeRingFront", Vector3.new(0.26, 0.26, 0.1), CFrame.new(0, 0.45, -0.45), "Accent"),
			P("ScopeRingBack", Vector3.new(0.26, 0.26, 0.1), CFrame.new(0, 0.45, 0.25), "Accent"),
			P("Mag", Vector3.new(0.2, 0.4, 0.4), CFrame.new(0, -0.4, -0.3), "Dark"),
			P("Grip", Vector3.new(0.2, 0.5, 0.28), CFrame.new(0, -0.42, 0.5) * CFrame.Angles(rad(18), 0, 0), "Body"),
			P("Stock", Vector3.new(0.28, 0.45, 1.2), CFrame.new(0, -0.08, 1.35), "Body"),
			P("StockStripe", Vector3.new(0.3, 0.1, 1), CFrame.new(0, 0.1, 1.3), "Accent"),
		},
	},

	Pistol = {
		DisplayName = "Víbora P9",
		Slot = 2,
		Type = "Gun",
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
		ViewOffset = CFrame.new(0.6, -0.6, -1.6),
		AimDistance = 1.3,
		RightHand = Vector3.new(0, -0.5, 0.3),
		LeftHand = Vector3.new(-0.15, -0.55, 0.28),
		AimPoint = Vector3.new(0, 0.2, 0.5),
		Muzzle = Vector3.new(0, 0.02, -0.6),
		Parts = {
			P("Handle", Vector3.new(0.22, 0.28, 1), CFrame.new(), "Body"),
			P("SlideStripe", Vector3.new(0.24, 0.06, 0.9), CFrame.new(0, 0.1, 0), "Accent"),
			P("Frame", Vector3.new(0.2, 0.14, 0.9), CFrame.new(0, -0.2, -0.05), "Dark"),
			P("Grip", Vector3.new(0.2, 0.6, 0.3), CFrame.new(0, -0.5, 0.3) * CFrame.Angles(rad(14), 0, 0), "Body"),
			P("BarrelTip", Vector3.new(0.12, 0.12, 0.1), CFrame.new(0, 0.02, -0.52), "Dark"),
			P("RearSight", Vector3.new(0.18, 0.06, 0.06), CFrame.new(0, 0.17, 0.45), "Dark"),
			P("FrontSight", Vector3.new(0.05, 0.07, 0.05), CFrame.new(0, 0.17, -0.45), "Accent"),
		},
	},

	Knife = {
		DisplayName = "Colmillo",
		Slot = 3,
		Type = "Melee",
		Damage = 55,
		Range = 7,
		Cooldown = 0.55,
		ViewOffset = CFrame.new(0.8, -0.75, -1.5) * CFrame.Angles(rad(15), rad(20), 0),
		RightHand = Vector3.new(0, 0, 0.1),
		Parts = {
			P("Handle", Vector3.new(0.16, 0.2, 0.6), CFrame.new(), "Dark"),
			P("Guard", Vector3.new(0.3, 0.25, 0.06), CFrame.new(0, 0, -0.33), "Body"),
			P("Blade", Vector3.new(0.05, 0.24, 1), CFrame.new(0, 0.02, -0.86), "Accent"),
			P("Spine", Vector3.new(0.06, 0.08, 0.9), CFrame.new(0, 0.14, -0.8), "Body"),
		},
	},
}

-- Armas principales que el jugador puede elegir (slot 1)
Weapons.Primaries = { "Rifle", "Shotgun", "Sniper" }
Weapons.Secondary = "Pistol"
Weapons.Melee = "Knife"

function Weapons.Get(name)
	return Weapons.List[name]
end

return Weapons
