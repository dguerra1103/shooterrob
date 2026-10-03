-- Skins de armas. Cada skin pinta las piezas del arma según su "Role":
--   Body   = cuerpo principal
--   Accent = detalles brillantes (neón)
--   Dark   = cañón, cargador, mira
local Skins = {}

Skins.List = {
	Default = {
		Name = "Estándar",
		Rarity = "Común",
		Body = Color3.fromRGB(70, 74, 82),
		BodyMaterial = Enum.Material.Metal,
		Accent = Color3.fromRGB(0, 200, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(30, 30, 34),
	},
	Toxico = {
		Name = "Tóxico",
		Rarity = "Raro",
		Body = Color3.fromRGB(40, 48, 40),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(110, 255, 60),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(20, 26, 20),
	},
	Selva = {
		Name = "Selva",
		Rarity = "Raro",
		Body = Color3.fromRGB(86, 110, 60),
		BodyMaterial = Enum.Material.Fabric,
		Accent = Color3.fromRGB(196, 160, 90),
		AccentMaterial = Enum.Material.SmoothPlastic,
		Dark = Color3.fromRGB(50, 40, 30),
	},
	Oceano = {
		Name = "Océano",
		Rarity = "Épico",
		Body = Color3.fromRGB(20, 60, 120),
		BodyMaterial = Enum.Material.Glass,
		Accent = Color3.fromRGB(80, 220, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(10, 25, 50),
	},
	Atardecer = {
		Name = "Atardecer",
		Rarity = "Épico",
		Body = Color3.fromRGB(255, 140, 80),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 60, 140),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(70, 20, 60),
	},
	Sakura = {
		Name = "Sakura",
		Rarity = "Épico",
		Body = Color3.fromRGB(255, 170, 215),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 80, 200),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(120, 40, 110),
	},
	Hielo = {
		Name = "Hielo",
		Rarity = "Épico",
		Body = Color3.fromRGB(200, 235, 255),
		BodyMaterial = Enum.Material.Ice,
		Accent = Color3.fromRGB(120, 200, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(60, 90, 120),
	},
	Calabaza = {
		Name = "Calabaza",
		Rarity = "Legendario",
		Body = Color3.fromRGB(255, 120, 20),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 220, 40),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(30, 20, 10),
	},
	Vacio = {
		Name = "Vacío",
		Rarity = "Legendario",
		Body = Color3.fromRGB(15, 15, 18),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 20, 40),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(40, 0, 5),
	},
	Dorado = {
		Name = "Dorado",
		Rarity = "Legendario",
		Body = Color3.fromRGB(255, 200, 60),
		BodyMaterial = Enum.Material.Foil,
		Accent = Color3.fromRGB(255, 255, 200),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(110, 80, 20),
	},
	Galaxia = {
		Name = "Galaxia",
		Rarity = "Mítico",
		Body = Color3.fromRGB(120, 60, 255),
		BodyMaterial = Enum.Material.ForceField,
		Accent = Color3.fromRGB(255, 120, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(25, 10, 60),
	},
	Dragon = {
		Name = "Dragón",
		Rarity = "Mítico",
		Body = Color3.fromRGB(150, 20, 20),
		BodyMaterial = Enum.Material.Slate,
		Accent = Color3.fromRGB(255, 170, 0),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(40, 5, 5),
	},
	Magma = {
		Name = "Magma",
		Rarity = "Mítico",
		Body = Color3.fromRGB(40, 20, 15),
		BodyMaterial = Enum.Material.Basalt,
		Accent = Color3.fromRGB(255, 90, 0),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(255, 50, 0),
	},
}

Skins.RarityColors = {
	["Común"] = Color3.fromRGB(180, 180, 180),
	["Raro"] = Color3.fromRGB(70, 160, 255),
	["Épico"] = Color3.fromRGB(190, 80, 255),
	["Legendario"] = Color3.fromRGB(255, 180, 30),
	["Mítico"] = Color3.fromRGB(255, 60, 90),
}

function Skins.Get(id)
	return Skins.List[id] or Skins.List.Default
end

return Skins
