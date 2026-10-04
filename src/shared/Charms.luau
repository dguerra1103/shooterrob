-- Colgantes para el arma: un adorno pequeño que cuelga del lateral del arma y se balancea al
-- moverte (se ve en primera persona y en las armas de los demás). Se compran con monedas en la
-- pestaña Skins y valen para todas las armas de fuego (no para las de cuerpo a cuerpo).
local Charms = {}

local V = Vector3.new
local RGB = Color3.fromRGB

-- Piezas: { Name, Size, Offset (desde el punto del que cuelga), Color, Material, Shape }
local function part(name, size, offset, color, material, shape)
	return { Name = name, Size = size, Offset = offset, Color = color, Material = material or Enum.Material.SmoothPlastic, Shape = shape }
end

Charms.List = {
	Default = { Name = "Sin colgante", Rarity = "Común", Icon = "➖" },
	Dado = {
		Name = "Dado",
		Rarity = "Raro",
		Icon = "🎲",
		Price = 300,
		Parts = {
			part("Body", V(0.16, 0.16, 0.16), V(0, -0.2, 0), RGB(245, 245, 250)),
			part("Dot", V(0.04, 0.04, 0.17), V(0, -0.2, 0), RGB(220, 40, 50), nil, "Ball"),
		},
	},
	Corazon = {
		Name = "Corazón",
		Rarity = "Raro",
		Icon = "💖",
		Price = 300,
		Parts = {
			part("LobeL", V(0.11, 0.11, 0.08), V(-0.045, -0.17, 0), RGB(255, 70, 130), nil, "Ball"),
			part("LobeR", V(0.11, 0.11, 0.08), V(0.045, -0.17, 0), RGB(255, 70, 130), nil, "Ball"),
			part("Tip", V(0.1, 0.1, 0.07), V(0, -0.225, 0), RGB(255, 70, 130)),
		},
	},
	Calabaza = {
		Name = "Calabacita",
		Rarity = "Épico",
		Icon = "🎃",
		Price = 500,
		Parts = {
			part("Body", V(0.2, 0.17, 0.2), V(0, -0.21, 0), RGB(255, 130, 20), nil, "Ball"),
			part("Stem", V(0.03, 0.06, 0.03), V(0, -0.11, 0), RGB(80, 140, 50)),
			part("Face", V(0.1, 0.03, 0.01), V(0, -0.22, -0.1), RGB(255, 220, 60), Enum.Material.Neon),
		},
	},
	Estrella = {
		Name = "Estrella",
		Rarity = "Épico",
		Icon = "⭐",
		Price = 500,
		Parts = {
			part("Core", V(0.12, 0.12, 0.05), V(0, -0.2, 0), RGB(255, 210, 50), Enum.Material.Neon),
			part("ArmA", V(0.22, 0.05, 0.04), V(0, -0.2, 0), RGB(255, 210, 50), Enum.Material.Neon),
			part("ArmB", V(0.05, 0.22, 0.04), V(0, -0.2, 0), RGB(255, 210, 50), Enum.Material.Neon),
		},
	},
	Calavera = {
		Name = "Calavera",
		Rarity = "Épico",
		Icon = "💀",
		Price = 700,
		Parts = {
			part("Skull", V(0.17, 0.15, 0.15), V(0, -0.2, 0), RGB(235, 230, 215), nil, "Ball"),
			part("Jaw", V(0.1, 0.05, 0.1), V(0, -0.28, -0.01), RGB(235, 230, 215)),
			part("EyeL", V(0.04, 0.04, 0.02), V(-0.035, -0.19, -0.075), RGB(20, 20, 25)),
			part("EyeR", V(0.04, 0.04, 0.02), V(0.035, -0.19, -0.075), RGB(20, 20, 25)),
		},
	},
	Patito = {
		Name = "Patito de goma",
		Rarity = "Legendario",
		Icon = "🦆",
		Price = 900,
		Parts = {
			part("Body", V(0.18, 0.13, 0.2), V(0, -0.24, 0), RGB(255, 220, 40), nil, "Ball"),
			part("Head", V(0.11, 0.11, 0.11), V(0, -0.15, -0.06), RGB(255, 220, 40), nil, "Ball"),
			part("Beak", V(0.06, 0.03, 0.06), V(0, -0.16, -0.12), RGB(255, 130, 30)),
		},
	},
	Diamante = {
		Name = "Diamante",
		Rarity = "Legendario",
		Icon = "💎",
		Price = 1200,
		Parts = {
			part("Gem", V(0.15, 0.15, 0.15), V(0, -0.21, 0), RGB(110, 220, 255), Enum.Material.Neon),
			part("Facet", V(0.12, 0.12, 0.12), V(0, -0.21, 0), RGB(200, 245, 255), Enum.Material.Glass),
		},
		Spin = true, -- (las piezas van giradas 45° para parecer un rombo)
	},
}

function Charms.Get(id)
	return Charms.List[id] or Charms.List.Default
end

-- Construye el colgante: cadenita + adorno. Devuelve una tabla de piezas sin anclar ni soldar,
-- colocadas respecto a `hang` (CFrame del punto del que cuelga).
function Charms.Build(id, hang)
	local charm = Charms.List[id]
	if not charm or not charm.Parts then
		return {}
	end
	local parts = {}
	local function make(name, size, cf, color, material, shape)
		local p = Instance.new("Part")
		p.Name = "Charm" .. name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		if shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		end
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		table.insert(parts, p)
		return p
	end
	-- Anilla y cadena
	make("Ring", V(0.05, 0.05, 0.05), hang, RGB(200, 200, 210), Enum.Material.Metal, "Ball")
	make("Chain", V(0.02, 0.1, 0.02), hang * CFrame.new(0, -0.06, 0), RGB(190, 190, 200), Enum.Material.Metal)
	local spin = charm.Spin and CFrame.Angles(0, math.rad(45), math.rad(45)) or CFrame.identity
	for _, spec in charm.Parts do
		make(spec.Name, spec.Size, hang * CFrame.new(spec.Offset) * spin, spec.Color, spec.Material, spec.Shape)
	end
	return parts
end

return Charms
