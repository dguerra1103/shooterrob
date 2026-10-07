-- Skins de armas. Cada skin pinta las piezas del arma según su "Role":
--   Body   = cuerpo principal
--   Accent = detalles brillantes (neón)
--   Dark   = cañón, cargador, mira
--   Accent2 = detalles secundarios (paneles, rayas)
-- Opcional:
--   Effect = "Sparkle" (destellos) o "Flame" (llamas) alrededor del arma
--   Pulse  = true: los detalles de neón laten entre Accent y Accent2
--   Rainbow = { Accent = true, Body = true, ... }: esas piezas cambian de color sin parar (arcoíris);
--             RainbowSat / RainbowVal = saturación y brillo de los colores (0-1)
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
		Accent2 = Color3.fromRGB(110, 115, 125),
	},
	Toxico = {
		Name = "Tóxico",
		Rarity = "Raro",
		Body = Color3.fromRGB(40, 48, 40),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(110, 255, 60),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(20, 26, 20),
		Accent2 = Color3.fromRGB(255, 230, 0),
	},
	Selva = {
		Name = "Selva",
		Rarity = "Raro",
		Body = Color3.fromRGB(86, 110, 60),
		BodyMaterial = Enum.Material.Fabric,
		Accent = Color3.fromRGB(196, 160, 90),
		AccentMaterial = Enum.Material.SmoothPlastic,
		Dark = Color3.fromRGB(50, 40, 30),
		Accent2 = Color3.fromRGB(60, 80, 40),
	},
	Oceano = {
		Name = "Océano",
		Rarity = "Épico",
		Body = Color3.fromRGB(20, 60, 120),
		BodyMaterial = Enum.Material.Glass,
		Accent = Color3.fromRGB(80, 220, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(10, 25, 50),
		Accent2 = Color3.fromRGB(255, 255, 255),
	},
	Atardecer = {
		Name = "Atardecer",
		Rarity = "Épico",
		Body = Color3.fromRGB(255, 140, 80),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 60, 140),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(70, 20, 60),
		Accent2 = Color3.fromRGB(255, 200, 60),
	},
	Sakura = {
		Name = "Sakura",
		Rarity = "Épico",
		Body = Color3.fromRGB(255, 170, 215),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 80, 200),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(120, 40, 110),
		Accent2 = Color3.fromRGB(255, 255, 255),
		Effect = "Sparkle",
	},
	Hielo = {
		Name = "Hielo",
		Rarity = "Épico",
		Body = Color3.fromRGB(200, 235, 255),
		BodyMaterial = Enum.Material.Ice,
		Accent = Color3.fromRGB(120, 200, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(60, 90, 120),
		Accent2 = Color3.fromRGB(255, 255, 255),
		Effect = "Sparkle",
	},
	Calabaza = {
		Name = "Calabaza",
		Rarity = "Legendario",
		Body = Color3.fromRGB(255, 120, 20),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 220, 40),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(30, 20, 10),
		Accent2 = Color3.fromRGB(120, 40, 160),
		Effect = "Flame",
	},
	Vacio = {
		Name = "Vacío",
		Rarity = "Legendario",
		Body = Color3.fromRGB(15, 15, 18),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Accent = Color3.fromRGB(255, 20, 40),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(40, 0, 5),
		Accent2 = Color3.fromRGB(40, 40, 48),
		Effect = "Sparkle",
		Pulse = true,
	},
	Dorado = {
		Name = "Dorado",
		Rarity = "Legendario",
		Body = Color3.fromRGB(255, 200, 60),
		BodyMaterial = Enum.Material.Foil,
		Accent = Color3.fromRGB(255, 255, 200),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(110, 80, 20),
		Accent2 = Color3.fromRGB(255, 255, 255),
		Effect = "Sparkle",
	},
	Galaxia = {
		Name = "Galaxia",
		Rarity = "Mítico",
		Body = Color3.fromRGB(120, 60, 255),
		BodyMaterial = Enum.Material.ForceField,
		Accent = Color3.fromRGB(255, 120, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(25, 10, 60),
		Accent2 = Color3.fromRGB(80, 200, 255),
		Effect = "Sparkle",
		Pulse = true,
	},
	Dragon = {
		Name = "Dragón",
		Rarity = "Mítico",
		Body = Color3.fromRGB(150, 20, 20),
		BodyMaterial = Enum.Material.Slate,
		Accent = Color3.fromRGB(255, 170, 0),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(40, 5, 5),
		Accent2 = Color3.fromRGB(255, 60, 0),
		Effect = "Flame",
		Pulse = true,
	},
	Magma = {
		Name = "Magma",
		Rarity = "Mítico",
		Body = Color3.fromRGB(40, 20, 15),
		BodyMaterial = Enum.Material.Basalt,
		Accent = Color3.fromRGB(255, 90, 0),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(255, 50, 0),
		Accent2 = Color3.fromRGB(255, 200, 0),
		Effect = "Flame",
		Pulse = true,
	},

	-- Camuflajes con imagen (MaterialVariant "Camo<nombre>", ver assets/textures/LEEME.md). Mientras la
	-- imagen no esté subida, el arma se pinta con los colores de respaldo (Body/Panel).
	CamoBosque = {
		Name = "Bosque",
		Rarity = "Raro",
		Camo = "Bosque",
		Body = Color3.fromRGB(98, 112, 70),
		Panel = Color3.fromRGB(128, 100, 62),
		Accent = Color3.fromRGB(230, 220, 160),
		AccentMaterial = Enum.Material.SmoothPlastic,
		Dark = Color3.fromRGB(34, 34, 28),
		Accent2 = Color3.fromRGB(62, 78, 46),
	},
	CamoDesierto = {
		Name = "Desierto",
		Rarity = "Raro",
		Camo = "Desierto",
		Body = Color3.fromRGB(204, 178, 132),
		Panel = Color3.fromRGB(168, 138, 98),
		Accent = Color3.fromRGB(255, 140, 40),
		AccentMaterial = Enum.Material.SmoothPlastic,
		Dark = Color3.fromRGB(60, 52, 42),
		Accent2 = Color3.fromRGB(126, 100, 72),
	},
	CamoDigital = {
		Name = "Digital urbano",
		Rarity = "Épico",
		Camo = "Digital",
		Body = Color3.fromRGB(140, 145, 152),
		Panel = Color3.fromRGB(98, 102, 108),
		Accent = Color3.fromRGB(0, 200, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(40, 42, 46),
		Accent2 = Color3.fromRGB(196, 200, 206),
	},
	CamoArtico = {
		Name = "Ártico",
		Rarity = "Épico",
		Camo = "Artico",
		Body = Color3.fromRGB(236, 240, 246),
		Panel = Color3.fromRGB(140, 160, 182),
		Accent = Color3.fromRGB(120, 210, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(70, 84, 100),
		Accent2 = Color3.fromRGB(190, 205, 220),
	},
	CamoTigre = {
		Name = "Tigre",
		Rarity = "Legendario",
		Camo = "Tigre",
		Body = Color3.fromRGB(240, 132, 30),
		Panel = Color3.fromRGB(25, 20, 18),
		Accent = Color3.fromRGB(255, 220, 120),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(25, 20, 18),
		Accent2 = Color3.fromRGB(180, 80, 20),
		Effect = "Sparkle",
	},
	CamoNebulosa = {
		Name = "Nebulosa",
		Rarity = "Mítico",
		Camo = "Nebulosa",
		Body = Color3.fromRGB(90, 40, 170),
		Panel = Color3.fromRGB(40, 20, 90),
		Accent = Color3.fromRGB(200, 140, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(20, 10, 40),
		Accent2 = Color3.fromRGB(80, 200, 255),
		Effect = "Sparkle",
		Pulse = true,
	},

	-- Camuflajes de maestría (se ganan con bajas de cada arma; ver Mastery.luau)
	MaestriaCarbono = {
		Name = "Carbono",
		Rarity = "Épico",
		Mastery = true,
		Body = Color3.fromRGB(30, 30, 34),
		BodyMaterial = Enum.Material.Fabric,
		Panel = Color3.fromRGB(56, 56, 62),
		PanelMaterial = Enum.Material.Fabric,
		Accent = Color3.fromRGB(235, 235, 245),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(14, 14, 16),
		Accent2 = Color3.fromRGB(150, 150, 160),
	},
	MaestriaOro = {
		Name = "Oro",
		Rarity = "Legendario",
		Mastery = true,
		Body = Color3.fromRGB(240, 180, 50),
		BodyMaterial = Enum.Material.Foil,
		Panel = Color3.fromRGB(255, 215, 90),
		PanelMaterial = Enum.Material.Foil,
		Accent = Color3.fromRGB(255, 240, 170),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(120, 84, 20),
		Accent2 = Color3.fromRGB(255, 255, 255),
		Effect = "Sparkle",
	},
	MaestriaDiamante = {
		Name = "Diamante",
		Rarity = "Legendario",
		Mastery = true,
		Body = Color3.fromRGB(160, 220, 255),
		BodyMaterial = Enum.Material.Glass,
		Panel = Color3.fromRGB(225, 245, 255),
		PanelMaterial = Enum.Material.Glass,
		Accent = Color3.fromRGB(110, 225, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(60, 110, 160),
		Accent2 = Color3.fromRGB(255, 255, 255),
		Effect = "Sparkle",
	},
	MaestriaOscura = {
		Name = "Materia oscura",
		Rarity = "Mítico",
		Mastery = true,
		Body = Color3.fromRGB(16, 10, 26),
		BodyMaterial = Enum.Material.SmoothPlastic,
		Panel = Color3.fromRGB(44, 20, 78),
		Accent = Color3.fromRGB(170, 60, 255),
		AccentMaterial = Enum.Material.Neon,
		Dark = Color3.fromRGB(8, 6, 12),
		Accent2 = Color3.fromRGB(255, 60, 200),
		Effect = "Flame",
		Pulse = true,
	},
}

-- Skins de los mapas nuevos
Skins.List.Caramelo = {
	Name = "Caramelo",
	Rarity = "Raro",
	Body = Color3.fromRGB(255, 150, 200),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = Color3.fromRGB(140, 230, 200),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(255, 255, 255),
	AccentMaterial = Enum.Material.SmoothPlastic,
	Dark = Color3.fromRGB(120, 60, 90),
	Accent2 = Color3.fromRGB(255, 220, 90),
}
Skins.List.Juguete = {
	Name = "Juguete",
	Rarity = "Raro",
	Body = Color3.fromRGB(235, 50, 50),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = Color3.fromRGB(40, 120, 235),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(255, 210, 40),
	AccentMaterial = Enum.Material.SmoothPlastic,
	Dark = Color3.fromRGB(40, 40, 46),
	Accent2 = Color3.fromRGB(60, 200, 90),
}
Skins.List.Tiki = {
	Name = "Tiki",
	Rarity = "Épico",
	Body = Color3.fromRGB(150, 95, 50),
	BodyMaterial = Enum.Material.Wood,
	Panel = Color3.fromRGB(60, 210, 220),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(255, 140, 40),
	AccentMaterial = Enum.Material.Neon,
	Dark = Color3.fromRGB(70, 45, 25),
	Accent2 = Color3.fromRGB(255, 220, 90),
	Effect = "Flame",
}
Skins.List.Pintura = {
	Name = "Salpicón",
	Rarity = "Legendario",
	Body = Color3.fromRGB(245, 245, 250),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = Color3.fromRGB(255, 60, 140),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(60, 200, 255),
	AccentMaterial = Enum.Material.Neon,
	Dark = Color3.fromRGB(255, 200, 40),
	Accent2 = Color3.fromRGB(120, 230, 60),
	Effect = "Sparkle",
}

-- Skin del evento de Halloween (no se vende ni sale en cajas: se gana con caramelos, ver Event)
Skins.List.Embrujada = {
	Name = "Embrujada",
	Rarity = "Mítico",
	Event = true,
	Body = Color3.fromRGB(40, 20, 60),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = Color3.fromRGB(255, 120, 20),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(120, 255, 80),
	AccentMaterial = Enum.Material.Neon,
	Dark = Color3.fromRGB(15, 10, 20),
	Accent2 = Color3.fromRGB(190, 90, 255),
	Effect = "Flame",
	Pulse = true,
	EventText = "🎃 Evento: caramelos",
}

-- Skin del evento de Navidad (se gana con regalos, ver GameConfig.Events)
-- A juego con los mapas Pueblo Vaquero y Bahía Pirata (en la tienda con monedas)
Skins.List.Vaquera = {
	Name = "Vaquera",
	Rarity = "Épico",
	Body = Color3.fromRGB(150, 95, 55),
	BodyMaterial = Enum.Material.Wood,
	Panel = Color3.fromRGB(110, 70, 40),
	PanelMaterial = Enum.Material.Leather,
	Accent = Color3.fromRGB(230, 200, 120),
	AccentMaterial = Enum.Material.Metal,
	Dark = Color3.fromRGB(60, 40, 25),
	Accent2 = Color3.fromRGB(200, 60, 40),
}
Skins.List.Tesoro = {
	Name = "Tesoro pirata",
	Rarity = "Legendario",
	-- (oro con piezas negras y rubíes)
	Body = Color3.fromRGB(240, 185, 50),
	BodyMaterial = Enum.Material.Foil,
	Panel = Color3.fromRGB(35, 30, 38),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(230, 30, 60),
	AccentMaterial = Enum.Material.Neon,
	Dark = Color3.fromRGB(30, 26, 30),
	Accent2 = Color3.fromRGB(255, 230, 140),
	Effect = "Sparkle",
}

Skins.List.Navidena = {
	Name = "Navideña",
	Rarity = "Mítico",
	Event = true,
	EventText = "🎄 Evento: regalos",
	Body = Color3.fromRGB(200, 25, 40),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = Color3.fromRGB(245, 245, 250),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(60, 220, 110),
	AccentMaterial = Enum.Material.Neon,
	Dark = Color3.fromRGB(20, 70, 40),
	Accent2 = Color3.fromRGB(255, 210, 70),
	Pulse = true,
}

-- Skins arcoíris (las anima el cliente, ver SkinFX)
Skins.List.Arcoiris = {
	Name = "Arcoíris",
	Rarity = "Mítico",
	Body = Color3.fromRGB(24, 24, 32),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = Color3.fromRGB(255, 60, 60),
	PanelMaterial = Enum.Material.Neon, -- paneles y detalles brillan con los colores del arcoíris
	Accent = Color3.fromRGB(255, 60, 60),
	AccentMaterial = Enum.Material.Neon,
	Dark = Color3.fromRGB(12, 12, 16),
	Accent2 = Color3.fromRGB(255, 255, 255),
	Effect = "Sparkle",
	Rainbow = { Panel = true, Accent = true, Accent2 = true },
	RainbowSat = 1,
	RainbowVal = 1,
}
Skins.List.Prisma = {
	Name = "Prisma",
	Rarity = "Legendario",
	Body = Color3.fromRGB(255, 170, 210),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = Color3.fromRGB(250, 250, 255),
	PanelMaterial = Enum.Material.SmoothPlastic,
	Accent = Color3.fromRGB(255, 255, 255),
	AccentMaterial = Enum.Material.Neon,
	Dark = Color3.fromRGB(60, 60, 80),
	Accent2 = Color3.fromRGB(200, 230, 255),
	Rainbow = { Body = true },
	RainbowSat = 0.45,
	RainbowVal = 1,
}

Skins.RarityColors = {
	["Común"] = Color3.fromRGB(180, 180, 180),
	["Raro"] = Color3.fromRGB(70, 160, 255),
	["Épico"] = Color3.fromRGB(190, 80, 255),
	["Legendario"] = Color3.fromRGB(255, 180, 30),
	["Mítico"] = Color3.fromRGB(255, 60, 90),
}

-- Colección premium (se compran con Robux: ver Economy/Products, ItemProducts). Solo cambian el
-- aspecto: el arma dispara, retrocede y daña exactamente igual.
local RGB = Color3.fromRGB
Skins.List.Inferno = {
	Name = "Inferno",
	Rarity = "Legendario",
	Collection = "INFERNO",
	Body = RGB(34, 30, 30),
	BodyMaterial = Enum.Material.Slate,
	Panel = RGB(70, 22, 14),
	Accent = RGB(255, 110, 20),
	AccentMaterial = Enum.Material.Neon,
	Dark = RGB(16, 12, 12),
	Accent2 = RGB(255, 210, 60),
	Effect = "Flame",
}
Skins.List.Ciber = {
	Name = "Ciber",
	Rarity = "Épico",
	Collection = "CYBER",
	Body = RGB(18, 20, 28),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = RGB(36, 40, 60),
	Accent = RGB(0, 235, 255),
	AccentMaterial = Enum.Material.Neon,
	Dark = RGB(8, 8, 14),
	Accent2 = RGB(255, 40, 200),
	Pulse = true,
}
Skins.List.ArticoTactico = {
	Name = "Ártico táctico",
	Rarity = "Épico",
	Collection = "ARCTIC",
	Camo = "Artico",
	Body = RGB(225, 232, 240),
	Panel = RGB(150, 165, 180),
	Accent = RGB(90, 200, 255),
	AccentMaterial = Enum.Material.Neon,
	Dark = RGB(60, 70, 84),
	Accent2 = RGB(255, 255, 255),
}
Skins.List.Callejero = {
	Name = "Callejero",
	Rarity = "Épico",
	Collection = "STREET",
	Body = RGB(70, 40, 140),
	BodyMaterial = Enum.Material.SmoothPlastic,
	Panel = RGB(255, 210, 40),
	Accent = RGB(255, 70, 170),
	AccentMaterial = Enum.Material.Neon,
	Dark = RGB(24, 18, 40),
	Accent2 = RGB(60, 230, 160),
}
Skins.List.GrietaVacio = {
	Name = "Grieta del vacío",
	Rarity = "Mítico",
	Collection = "VOID",
	Body = RGB(12, 8, 20),
	BodyMaterial = Enum.Material.Glass,
	Panel = RGB(40, 14, 70),
	Accent = RGB(180, 70, 255),
	AccentMaterial = Enum.Material.Neon,
	Dark = RGB(4, 2, 8),
	Accent2 = RGB(90, 220, 255),
	Effect = "Sparkle",
	Pulse = true,
}
Skins.List.OperacionRoja = {
	Name = "Operación Roja",
	Rarity = "Legendario",
	Collection = "RED OPS",
	Body = RGB(22, 22, 24),
	BodyMaterial = Enum.Material.Metal,
	Panel = RGB(120, 16, 22),
	Accent = RGB(255, 40, 50),
	AccentMaterial = Enum.Material.Neon,
	Dark = RGB(10, 10, 12),
	Accent2 = RGB(230, 230, 235),
}

-- Las piezas con el papel "Trim" (ribetes) llevan el color de acento de la skin (WeaponModels.paint).
-- Con el acabado de fábrica de cada arma siguen siendo metal oscuro.
for id, skin in Skins.List do
	if id ~= "Default" then
		skin.TrimAccent = true
	end
end

function Skins.Get(id)
	return Skins.List[id] or Skins.List.Default
end

return Skins
