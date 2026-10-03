-- Diseño 3D (hecho con piezas) de cada arma, inspirado en el arte conceptual del juego.
-- Espacio del modelo: -Z = hacia delante (cañón), +Y = arriba, +X = derecha.
-- "Handle" es la pieza raíz y SIEMPRE va en el origen (0, 0, 0): manos, mira y cañón se miden desde ahí.
--
-- Roles de color (los pinta WeaponModels según la paleta del arma o la skin equipada):
--   Body    = cuerpo principal (normalmente negro mate)
--   Panel   = placas de armadura (blancas en el diseño base)
--   Accent  = neón principal
--   Accent2 = neón / color secundario
--   Dark    = metal oscuro (cañón, raíles, cargador)
--   Metal   = metal claro (gatillo, tornillos)
--   Rubber  = goma de las empuñaduras
--   Lens    = cristal de las miras (teñido con el neón)
--   Gold    = latón (cartuchos, detalles)
--   Shell   = rojo de los cartuchos de escopeta
local Designs = {}

local rad = math.rad

local function V(x, y, z)
	return Vector3.new(x, y, z)
end

-- Caja (con giro opcional en grados)
local function B(name, x, y, z, sx, sy, sz, role, rx, ry, rz)
	local cf = CFrame.new(x, y, z)
	if rx or ry or rz then
		cf *= CFrame.Angles(rad(rx or 0), rad(ry or 0), rad(rz or 0))
	end
	return { Name = name, Size = V(sx, sy, sz), CFrame = cf, Role = role }
end

-- Cilindro a lo largo del eje Z
local function C(name, x, y, z, length, diameter, role)
	return { Name = name, Size = V(length, diameter, diameter), CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, rad(90), 0), Role = role, Shape = "Cylinder" }
end

-- Cilindro a lo largo del eje X (tornillos, pasadores)
local function CX(name, x, y, z, length, diameter, role)
	return { Name = name, Size = V(length, diameter, diameter), CFrame = CFrame.new(x, y, z), Role = role, Shape = "Cylinder" }
end

-- Cilindro vertical
local function CY(name, x, y, z, length, diameter, role)
	return { Name = name, Size = V(length, diameter, diameter), CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, rad(90)), Role = role, Shape = "Cylinder" }
end

local function Ball(name, x, y, z, d, role)
	return { Name = name, Size = V(d, d, d), CFrame = CFrame.new(x, y, z), Role = role, Shape = "Ball" }
end

-- Rótulo con texto en los dos costados del arma
local function Label(name, x, y, z, sx, sy, sz, text, role)
	local part = B(name, x, y, z, sx, sy, sz, role or "Body")
	part.Text = text
	return part
end

-- Piezas en un grupo con su propia posición/giro (por ejemplo el cargador inclinado)
local function Group(base, list)
	local out = {}
	for _, p in list do
		p.CFrame = base * p.CFrame
		table.insert(out, p)
	end
	return out
end

local function add(list, items)
	for _, item in items do
		table.insert(list, item)
	end
end

-- Dientes de un raíl a lo largo de Z
local function railTeeth(list, prefix, x, y, z0, z1, step, width, role)
	local i = 0
	local z = z0
	while z >= z1 do
		i += 1
		table.insert(list, B(prefix .. i, x, y, z, width, 0.05, 0.07, role or "Dark"))
		z -= step
	end
end

---------------------------------------------------------------------------
-- ARX-27 PULSE (fusil de asalto)
---------------------------------------------------------------------------
function Designs.ARX27()
	local p = {
		-- Cuerpo
		B("Handle", 0, 0, 0, 0.36, 0.5, 1.5, "Body"),
		B("UpperPanel", 0, 0.15, 0.4, 0.38, 0.2, 0.7, "Panel"),
		B("UpperGlow", 0, 0.15, 0.2, 0.39, 0.06, 0.26, "Accent"),
		B("LowerPanel", 0, -0.15, -0.38, 0.38, 0.18, 0.38, "Panel"),
		B("EjectPort", 0.185, 0.05, -0.02, 0.02, 0.12, 0.3, "Dark"),
		Label("NamePlate", 0, -0.1, 0.32, 0.385, 0.14, 0.42, "ARX-27"),
		CX("Pin1", 0, -0.18, 0.62, 0.39, 0.06, "Metal"),
		CX("Pin2", 0, 0.1, -0.55, 0.39, 0.06, "Metal"),
		-- Guardamanos
		B("Handguard", 0, 0.05, -1.05, 0.4, 0.42, 1.2, "Panel"),
		B("HandguardBottom", 0, -0.15, -1.05, 0.42, 0.14, 1.22, "Body"),
		B("HandguardGlow", 0, 0.13, -1.0, 0.41, 0.055, 0.8, "Accent"),
		B("HandguardGlowLow", 0, -0.11, -1.15, 0.43, 0.04, 0.55, "Accent"),
		B("Slot1", 0, 0.02, -1.42, 0.41, 0.13, 0.07, "Dark"),
		B("Slot2", 0, 0.02, -1.53, 0.41, 0.13, 0.07, "Dark"),
		B("Slot3", 0, 0.02, -1.64, 0.41, 0.13, 0.07, "Dark"),
		B("SideRail", 0, -0.04, -0.75, 0.44, 0.06, 0.4, "Dark"),
		-- Raíl superior
		B("TopRail", 0, 0.31, -0.35, 0.2, 0.08, 2.3, "Dark"),
		-- Miras de hierro
		B("FrontPost", 0, 0.43, -1.5, 0.12, 0.17, 0.08, "Dark"),
		B("FrontPostGlow", 0, 0.5, -1.5, 0.05, 0.05, 0.09, "Accent"),
		B("RearSight", 0, 0.41, 0.72, 0.18, 0.14, 0.09, "Dark"),
		-- Mira holográfica (hueca para poder apuntar a través)
		B("SightBase", 0, 0.4, -0.05, 0.26, 0.1, 0.42, "Dark"),
		B("SightTop", 0, 0.81, -0.05, 0.38, 0.08, 0.42, "Panel"),
		B("SightLeft", -0.17, 0.62, -0.05, 0.05, 0.36, 0.42, "Panel"),
		B("SightRight", 0.17, 0.62, -0.05, 0.05, 0.36, 0.42, "Panel"),
		B("SightHood", 0, 0.81, -0.27, 0.4, 0.1, 0.05, "Body"),
		B("SightLens", 0, 0.62, -0.2, 0.29, 0.31, 0.02, "Lens"),
		B("SightDot", 0, 0.62, -0.19, 0.035, 0.035, 0.01, "Accent"),
		B("SightEmblem", 0.2, 0.62, -0.05, 0.02, 0.1, 0.1, "Accent", 45, 0, 0),
		B("SightKnob", 0.2, 0.47, 0.08, 0.06, 0.08, 0.08, "Metal"),
		-- Cañón y bocacha
		C("Barrel", 0, 0.06, -1.85, 0.5, 0.16, "Dark"),
		C("Muzzle", 0, 0.06, -2.2, 0.5, 0.34, "Body"),
		C("MuzzleRingBack", 0, 0.06, -2.0, 0.06, 0.37, "Accent"),
		C("MuzzleRingFront", 0, 0.06, -2.42, 0.06, 0.37, "Accent"),
		C("MuzzleBore", 0, 0.06, -2.46, 0.03, 0.2, "Dark"),
		B("MuzzleVent", 0, 0.06, -2.2, 0.37, 0.07, 0.18, "Dark"),
		-- Empuñadura y gatillo
		B("TriggerGuard", 0, -0.3, 0.08, 0.06, 0.04, 0.38, "Dark"),
		B("Trigger", 0, -0.22, 0.1, 0.04, 0.12, 0.04, "Metal"),
		-- Culata
		C("BufferTube", 0, 0.1, 1.0, 0.4, 0.16, "Dark"),
		B("StockUpper", 0, 0.12, 1.36, 0.34, 0.26, 0.7, "Panel"),
		B("StockLower", 0, -0.13, 1.5, 0.32, 0.28, 0.46, "Body"),
		B("StockGlow", 0, -0.13, 1.5, 0.33, 0.05, 0.34, "Accent"),
		B("ButtPad", 0, 0.0, 1.78, 0.36, 0.64, 0.12, "Body"),
		B("ButtGlow", 0, 0.0, 1.79, 0.37, 0.48, 0.04, "Accent"),
	}
	railTeeth(p, "RailTooth", 0, 0.37, 0.72, -1.45, 0.19, 0.24)
	-- Cargador recto con franjas de neón
	add(p, Group(CFrame.new(0, -0.58, -0.4) * CFrame.Angles(rad(-8), 0, 0), {
		B("Mag", 0, 0, 0, 0.26, 0.72, 0.36, "Body"),
		B("MagGlowA", 0, -0.02, -0.08, 0.27, 0.5, 0.05, "Accent"),
		B("MagGlowB", 0, -0.02, 0.08, 0.27, 0.5, 0.05, "Accent"),
		B("MagBase", 0, -0.39, 0, 0.3, 0.1, 0.42, "Panel"),
	}))
	-- Empuñadura con goma y franja trasera
	add(p, Group(CFrame.new(0, -0.48, 0.44) * CFrame.Angles(rad(15), 0, 0), {
		B("Grip", 0, 0, 0, 0.24, 0.56, 0.32, "Body"),
		B("GripRubber", 0, -0.02, -0.01, 0.255, 0.38, 0.22, "Rubber"),
		B("GripGlow", 0, 0, 0.17, 0.25, 0.4, 0.03, "Accent"),
	}))
	return p
end

---------------------------------------------------------------------------
-- HAVOC PUMP (escopeta)
---------------------------------------------------------------------------
function Designs.HavocPump()
	local p = {
		B("Handle", 0, 0, 0, 0.4, 0.52, 1.4, "Body"),
		B("SidePanel", 0, 0.05, 0.2, 0.42, 0.26, 0.75, "Panel"),
		B("PanelCut", 0, 0.05, 0.2, 0.43, 0.08, 0.5, "Body"),
		B("GlowZig1", 0, 0.12, 0.42, 0.44, 0.04, 0.22, "Accent"),
		B("GlowZig2", 0, 0.03, 0.27, 0.44, 0.18, 0.04, "Accent"),
		B("GlowZig3", 0, -0.06, 0.12, 0.44, 0.04, 0.22, "Accent"),
		Label("NamePlate", 0, 0.2, 0.0, 0.425, 0.13, 0.5, "HAVOC", "Body"),
		-- Ventana de cartuchos
		B("ShellWindow", 0, 0.0, -0.45, 0.42, 0.22, 0.4, "Dark"),
		CX("ShellA", 0, 0.0, -0.45, 0.43, 0.17, "Shell"),
		CX("ShellRimA", 0.2, 0.0, -0.45, 0.04, 0.19, "Gold"),
		CX("ShellRimB", -0.2, 0.0, -0.45, 0.04, 0.19, "Gold"),
		-- Raíl y miras
		B("TopRail", 0, 0.3, -0.35, 0.2, 0.08, 1.9, "Dark"),
		B("GhostRingL", -0.09, 0.42, 0.45, 0.04, 0.18, 0.08, "Accent2"),
		B("GhostRingR", 0.09, 0.42, 0.45, 0.04, 0.18, 0.08, "Accent2"),
		B("GhostRingTop", 0, 0.5, 0.45, 0.22, 0.04, 0.08, "Accent2"),
		B("GhostRingBase", 0, 0.36, 0.45, 0.24, 0.06, 0.12, "Dark"),
		B("FrontSightL", -0.1, 0.42, -2.05, 0.04, 0.2, 0.08, "Panel"),
		B("FrontSightR", 0.1, 0.42, -2.05, 0.04, 0.2, 0.08, "Panel"),
		B("FrontSightTop", 0, 0.5, -2.05, 0.24, 0.04, 0.08, "Panel"),
		B("FrontBead", 0, 0.4, -2.05, 0.04, 0.04, 0.04, "Accent"),
		-- Cañón doble: superior grande e inferior (tubo)
		B("BarrelShroud", 0, 0.12, -1.35, 0.42, 0.36, 1.3, "Body"),
		B("ShroudGlow", 0, 0.24, -1.3, 0.43, 0.05, 0.25, "Accent"),
		B("ShroudHole1", 0, 0.12, -1.55, 0.43, 0.1, 0.1, "Dark"),
		B("ShroudHole2", 0, 0.12, -1.72, 0.43, 0.1, 0.1, "Dark"),
		B("ShroudHole3", 0, 0.12, -1.89, 0.43, 0.1, 0.1, "Dark"),
		C("Barrel", 0, 0.12, -2.15, 0.3, 0.34, "Body"),
		C("MuzzleGlow", 0, 0.12, -2.31, 0.05, 0.36, "Accent"),
		C("MuzzleBore", 0, 0.12, -2.34, 0.03, 0.24, "Dark"),
		C("Tube", 0, -0.2, -1.6, 1.1, 0.2, "Dark"),
		C("TubeCap", 0, -0.2, -2.18, 0.1, 0.22, "Body"),
		C("TubeGlow", 0, -0.2, -2.24, 0.03, 0.12, "Accent"),
		-- Bomba (corredera acanalada)
		B("PumpCore", 0, -0.2, -1.15, 0.34, 0.3, 0.75, "Body"),
		B("PumpClamp", 0, -0.05, -1.6, 0.46, 0.46, 0.14, "Panel"),
		B("PumpClampGlow", 0, -0.05, -1.6, 0.47, 0.05, 0.15, "Accent"),
		-- Gatillo
		B("TriggerGuard", 0, -0.32, 0.25, 0.06, 0.04, 0.38, "Dark"),
		B("Trigger", 0, -0.24, 0.27, 0.04, 0.12, 0.04, "Metal"),
		-- Culata
		B("Stock", 0, 0.02, 1.15, 0.36, 0.42, 0.85, "Body"),
		B("StockPanel", 0, 0.05, 1.1, 0.38, 0.2, 0.5, "Panel"),
		B("StockGlow", 0, -0.12, 1.2, 0.37, 0.04, 0.6, "Accent"),
		B("ButtPad", 0, -0.02, 1.62, 0.4, 0.6, 0.12, "Panel"),
		B("ButtGlow", 0, -0.02, 1.63, 0.41, 0.48, 0.04, "Accent"),
	}
	-- Acanalado de la bomba
	for i = 0, 4 do
		table.insert(p, B("PumpRib" .. i, 0, -0.2, -0.85 - i * 0.13, 0.38, 0.34, 0.07, "Rubber"))
	end
	railTeeth(p, "RailTooth", 0, 0.36, 0.3, -1.2, 0.18, 0.24)
	add(p, Group(CFrame.new(0, -0.48, 0.55) * CFrame.Angles(rad(15), 0, 0), {
		B("Grip", 0, 0, 0, 0.26, 0.56, 0.32, "Body"),
		B("GripRidges", 0, -0.02, -0.01, 0.275, 0.4, 0.24, "Rubber"),
		B("GripGlow", 0, 0, 0.17, 0.27, 0.42, 0.03, "Panel"),
	}))
	return p
end

---------------------------------------------------------------------------
-- SPECTER-9 (subfusil)
---------------------------------------------------------------------------
function Designs.Specter9()
	local p = {
		B("Handle", 0, 0, 0, 0.34, 0.46, 1.2, "Body"),
		B("UpperPanel", 0, 0.12, 0.3, 0.36, 0.2, 0.5, "Panel"),
		B("FrontPanel", 0, -0.05, -0.62, 0.38, 0.36, 0.55, "Panel"),
		B("FrontPanelSlot1", 0, -0.02, -0.52, 0.39, 0.12, 0.09, "Dark"),
		B("FrontPanelSlot2", 0, -0.02, -0.66, 0.39, 0.12, 0.09, "Dark"),
		B("FrontPanelSlot3", 0, -0.02, -0.8, 0.39, 0.12, 0.09, "Dark"),
		B("GlowCyan", 0, 0.14, -0.2, 0.37, 0.045, 0.5, "Accent2"),
		B("GlowPink", 0, 0.14, 0.62, 0.37, 0.18, 0.04, "Accent"),
		B("GlowPinkLow", 0, -0.18, -0.15, 0.37, 0.04, 0.4, "Accent"),
		Label("NamePlate", 0, 0.0, 0.05, 0.355, 0.13, 0.42, "SPECTER-9", "Body"),
		CX("Pin", 0, 0.12, 0.45, 0.38, 0.07, "Metal"),
		-- Raíl, punto rojo y mira delantera
		B("TopRail", 0, 0.27, -0.1, 0.18, 0.08, 1.3, "Dark"),
		B("SightBase", 0, 0.35, 0.1, 0.24, 0.1, 0.36, "Dark"),
		B("SightTop", 0, 0.7, 0.1, 0.32, 0.07, 0.36, "Body"),
		B("SightLeft", -0.145, 0.53, 0.1, 0.04, 0.32, 0.36, "Body"),
		B("SightRight", 0.145, 0.53, 0.1, 0.04, 0.32, 0.36, "Body"),
		B("SightGlowL", -0.17, 0.53, 0.1, 0.01, 0.26, 0.04, "Accent"),
		B("SightGlowR", 0.17, 0.53, 0.1, 0.01, 0.26, 0.04, "Accent"),
		B("SightLens", 0, 0.53, -0.06, 0.25, 0.27, 0.02, "Lens"),
		B("ReticleH", 0, 0.53, -0.05, 0.1, 0.015, 0.01, "Accent"),
		B("ReticleV", 0, 0.53, -0.05, 0.015, 0.1, 0.01, "Accent"),
		B("FrontSightBase", 0, 0.3, -1.0, 0.2, 0.08, 0.16, "Dark"),
		B("FrontSightL", -0.08, 0.42, -1.0, 0.04, 0.18, 0.08, "Panel"),
		B("FrontSightR", 0.08, 0.42, -1.0, 0.04, 0.18, 0.08, "Panel"),
		B("FrontSightGlow", 0, 0.5, -1.0, 0.2, 0.04, 0.09, "Accent"),
		-- Cañón
		C("Barrel", 0, 0.0, -1.05, 0.25, 0.18, "Dark"),
		C("Muzzle", 0, 0.0, -1.32, 0.34, 0.27, "Body"),
		C("MuzzleGlow", 0, 0.0, -1.2, 0.05, 0.29, "Accent"),
		C("MuzzleRing", 0, 0.0, -1.48, 0.04, 0.29, "Accent2"),
		C("MuzzleBore", 0, 0.0, -1.5, 0.02, 0.15, "Dark"),
		-- Gatillo
		B("TriggerGuard", 0, -0.29, 0.02, 0.06, 0.04, 0.32, "Dark"),
		B("Trigger", 0, -0.21, 0.04, 0.04, 0.11, 0.04, "Metal"),
		B("SelectorGlow", 0.18, -0.08, 0.35, 0.02, 0.07, 0.12, "Accent"),
		-- Culata esquelética (triángulo)
		B("StockHinge", 0, 0.05, 0.68, 0.3, 0.3, 0.16, "Dark"),
		B("StockTop", 0, 0.12, 1.15, 0.16, 0.1, 0.9, "Body"),
		B("StockTopGlow", 0, 0.12, 1.15, 0.17, 0.035, 0.75, "Accent"),
		B("StockDiag", 0, -0.12, 1.08, 0.16, 0.08, 0.85, "Body", 28, 0, 0),
		B("StockDiagGlow", 0, -0.12, 1.08, 0.17, 0.03, 0.7, "Accent", 28, 0, 0),
		B("ButtPad", 0, -0.08, 1.6, 0.26, 0.56, 0.1, "Body"),
		B("ButtGlow", 0, -0.08, 1.61, 0.27, 0.42, 0.035, "Accent2"),
	}
	railTeeth(p, "RailTooth", 0, 0.33, 0.4, -0.65, 0.15, 0.22)
	-- Cargador largo recto
	add(p, Group(CFrame.new(0, -0.62, -0.25) * CFrame.Angles(rad(-4), 0, 0), {
		B("Mag", 0, 0, 0, 0.24, 0.88, 0.3, "Body"),
		B("MagGlowCyan", 0, -0.02, -0.07, 0.25, 0.66, 0.04, "Accent2"),
		B("MagGlowPink", 0, -0.02, 0.07, 0.25, 0.66, 0.04, "Accent"),
		B("MagBase", 0, -0.47, 0, 0.27, 0.08, 0.34, "Panel"),
	}))
	add(p, Group(CFrame.new(0, -0.45, 0.32) * CFrame.Angles(rad(14), 0, 0), {
		B("Grip", 0, 0, 0, 0.22, 0.5, 0.28, "Body"),
		B("GripRubber", 0, -0.02, -0.01, 0.235, 0.36, 0.2, "Rubber"),
		B("GripGlow", 0, 0, -0.15, 0.235, 0.36, 0.025, "Accent2"),
	}))
	return p
end

---------------------------------------------------------------------------
-- SIGNAL-7 (francotirador)
---------------------------------------------------------------------------
function Designs.Signal7()
	local p = {
		B("Handle", 0, 0, 0, 0.36, 0.48, 1.7, "Body"),
		B("PanelA", 0, 0.06, 0.45, 0.38, 0.24, 0.6, "Panel"),
		B("PanelB", 0, -0.08, -0.45, 0.38, 0.22, 0.5, "Panel"),
		B("SpotA", 0, 0.1, 0.55, 0.385, 0.08, 0.1, "Body"),
		B("SpotB", 0, 0.02, 0.3, 0.385, 0.06, 0.08, "Body"),
		B("SpotC", 0, -0.1, -0.5, 0.385, 0.07, 0.12, "Body"),
		B("Glow1", 0, -0.04, 0.0, 0.37, 0.045, 0.6, "Accent"),
		B("Glow2", 0, 0.16, -0.5, 0.39, 0.04, 0.4, "Accent"),
		Label("NamePlate", 0, -0.14, 0.15, 0.37, 0.12, 0.45, "SIGNAL-7", "Body"),
		CX("BoltHandle", 0.25, 0.12, 0.55, 0.32, 0.07, "Metal"),
		Ball("BoltKnob", 0.42, 0.12, 0.55, 0.15, "Metal"),
		-- Guardamanos largo con huecos
		B("Handguard", 0, 0.02, -1.45, 0.34, 0.34, 1.3, "Body"),
		B("HandguardGlow", 0, 0.12, -1.45, 0.35, 0.045, 1.0, "Accent"),
		B("HG_Slot1", 0, -0.04, -1.1, 0.35, 0.1, 0.18, "Dark"),
		B("HG_Slot2", 0, -0.04, -1.35, 0.35, 0.1, 0.18, "Dark"),
		B("HG_Slot3", 0, -0.04, -1.6, 0.35, 0.1, 0.18, "Dark"),
		B("HG_Slot4", 0, -0.04, -1.85, 0.35, 0.1, 0.18, "Dark"),
		B("TopRail", 0, 0.27, -0.6, 0.18, 0.08, 2.4, "Dark"),
		-- Cañón largo estriado y freno de boca
		C("Barrel", 0, 0.05, -2.75, 1.4, 0.14, "Dark"),
		C("BarrelFlute", 0, 0.05, -2.6, 0.9, 0.155, "Body"),
		C("Brake", 0, 0.05, -3.55, 0.38, 0.24, "Body"),
		B("BrakeVent1", 0, 0.05, -3.48, 0.26, 0.08, 0.08, "Dark"),
		B("BrakeVent2", 0, 0.05, -3.62, 0.26, 0.08, 0.08, "Dark"),
		C("BrakeGlow", 0, 0.05, -3.36, 0.04, 0.26, "Accent"),
		C("BrakeBore", 0, 0.05, -3.75, 0.02, 0.12, "Dark"),
		-- Mira telescópica con lentes brillantes
		B("ScopeMountA", 0, 0.36, -0.55, 0.12, 0.14, 0.12, "Dark"),
		B("ScopeMountB", 0, 0.36, 0.25, 0.12, 0.14, 0.12, "Dark"),
		C("ScopeTube", 0, 0.52, -0.15, 1.3, 0.22, "Body"),
		C("ScopeBell", 0, 0.52, -0.95, 0.35, 0.34, "Body"),
		C("ScopeBellRing", 0, 0.52, -0.79, 0.04, 0.35, "Accent"),
		C("ScopeLensFront", 0, 0.52, -1.13, 0.02, 0.3, "Lens"),
		C("ScopeEye", 0, 0.52, 0.6, 0.28, 0.3, "Body"),
		C("ScopeLensBack", 0, 0.52, 0.75, 0.02, 0.26, "Lens"),
		CY("ScopeTurret", 0, 0.68, -0.2, 0.12, 0.13, "Panel"),
		CX("ScopeKnob", 0.15, 0.52, -0.2, 0.12, 0.13, "Panel"),
		C("ScopeRingA", 0, 0.52, -0.55, 0.09, 0.25, "Panel"),
		C("ScopeRingB", 0, 0.52, 0.25, 0.09, 0.25, "Panel"),
		-- Bípode plegado
		B("BipodL", -0.08, -0.2, -1.65, 0.05, 0.05, 0.75, "Dark"),
		B("BipodR", 0.08, -0.2, -1.65, 0.05, 0.05, 0.75, "Dark"),
		-- Gatillo
		B("TriggerGuard", 0, -0.31, 0.32, 0.06, 0.04, 0.36, "Dark"),
		B("Trigger", 0, -0.23, 0.34, 0.04, 0.12, 0.04, "Metal"),
		-- Culata esquelética blanca
		B("StockTop", 0, 0.12, 1.45, 0.3, 0.2, 1.0, "Panel"),
		B("StockCheek", 0, 0.27, 1.35, 0.28, 0.12, 0.6, "Body"),
		B("StockBottom", 0, -0.32, 1.55, 0.28, 0.14, 0.75, "Panel"),
		B("StockRear", 0, -0.08, 1.95, 0.3, 0.6, 0.16, "Panel"),
		B("StockGlow", 0, -0.1, 1.45, 0.31, 0.3, 0.04, "Accent"),
		B("ButtPad", 0, -0.08, 2.06, 0.32, 0.62, 0.08, "Body"),
	}
	add(p, Group(CFrame.new(0, -0.42, -0.35), {
		B("Mag", 0, 0, 0, 0.26, 0.42, 0.42, "Body"),
		B("MagGlow", 0, -0.05, 0, 0.27, 0.05, 0.3, "Accent"),
		B("MagBase", 0, -0.24, 0, 0.29, 0.07, 0.45, "Panel"),
	}))
	add(p, Group(CFrame.new(0, -0.45, 0.62) * CFrame.Angles(rad(16), 0, 0), {
		B("Grip", 0, 0, 0, 0.24, 0.55, 0.3, "Body"),
		B("GripRubber", 0, -0.02, -0.01, 0.255, 0.38, 0.21, "Rubber"),
		B("GripGlow", 0, 0, 0.16, 0.25, 0.4, 0.03, "Accent"),
	}))
	return p
end

---------------------------------------------------------------------------
-- TITAN LMG (ametralladora ligera, estilo "Volt Bruiser")
---------------------------------------------------------------------------
function Designs.TitanLMG()
	local p = {
		B("Handle", 0, 0, 0, 0.44, 0.56, 1.6, "Body"),
		B("SidePlate", 0, 0.04, 0.25, 0.46, 0.3, 0.8, "Panel"),
		B("SidePlateGlow", 0, 0.04, 0.25, 0.47, 0.05, 0.6, "Accent"),
		B("CyanLight", 0, -0.12, -0.45, 0.47, 0.06, 0.12, "Accent2"),
		Label("NamePlate", 0, -0.15, 0.3, 0.465, 0.13, 0.5, "TITAN"),
		-- Asa de transporte
		B("CarryPostA", 0, 0.38, 0.35, 0.12, 0.2, 0.1, "Dark"),
		B("CarryPostB", 0, 0.38, -0.35, 0.12, 0.2, 0.1, "Dark"),
		B("CarryHandle", 0, 0.5, 0, 0.14, 0.08, 0.8, "Panel"),
		-- Mira (abierta) sobre el asa
		B("SightBase", 0, 0.58, 0.1, 0.22, 0.06, 0.3, "Dark"),
		B("SightL", -0.12, 0.7, 0.1, 0.04, 0.22, 0.3, "Body"),
		B("SightR", 0.12, 0.7, 0.1, 0.04, 0.22, 0.3, "Body"),
		B("SightTop", 0, 0.82, 0.1, 0.28, 0.05, 0.3, "Body"),
		B("SightLens", 0, 0.7, -0.03, 0.2, 0.2, 0.02, "Lens"),
		B("SightDot", 0, 0.7, -0.02, 0.035, 0.035, 0.01, "Accent"),
		-- Guardamanos con ranuras amarillas
		B("Shroud", 0, 0.08, -1.25, 0.44, 0.46, 1.0, "Body"),
		B("ShroudPlate", 0, 0.08, -1.25, 0.46, 0.3, 0.8, "Panel"),
		B("ShroudSlot1", 0, 0.08, -1.0, 0.47, 0.16, 0.08, "Dark"),
		B("ShroudSlot2", 0, 0.08, -1.15, 0.47, 0.16, 0.08, "Dark"),
		B("ShroudSlot3", 0, 0.08, -1.3, 0.47, 0.16, 0.08, "Dark"),
		B("ShroudSlot4", 0, 0.08, -1.45, 0.47, 0.16, 0.08, "Dark"),
		B("ShroudGlow", 0, 0.29, -1.25, 0.3, 0.04, 0.9, "Accent"),
		C("Barrel", 0, 0.08, -2.0, 0.6, 0.18, "Dark"),
		C("Muzzle", 0, 0.08, -2.35, 0.3, 0.36, "Body"),
		C("MuzzleGlow", 0, 0.08, -2.5, 0.05, 0.38, "Accent"),
		C("MuzzleBore", 0, 0.08, -2.53, 0.02, 0.2, "Dark"),
		-- Caja de munición
		B("AmmoBox", 0, -0.48, -0.35, 0.5, 0.5, 0.6, "Panel"),
		B("AmmoBoxBand", 0, -0.48, -0.35, 0.52, 0.08, 0.62, "Body"),
		B("AmmoBoxGlow", 0, -0.62, -0.35, 0.51, 0.04, 0.4, "Accent"),
		CX("Belt1", 0.24, -0.1, -0.2, 0.08, 0.1, "Gold"),
		CX("Belt2", 0.24, -0.16, -0.32, 0.08, 0.1, "Gold"),
		-- Bípode
		B("BipodL", -0.1, -0.28, -1.6, 0.06, 0.06, 0.8, "Dark"),
		B("BipodR", 0.1, -0.28, -1.6, 0.06, 0.06, 0.8, "Dark"),
		-- Gatillo y culata
		B("TriggerGuard", 0, -0.34, 0.35, 0.06, 0.04, 0.38, "Dark"),
		B("Trigger", 0, -0.26, 0.37, 0.04, 0.12, 0.04, "Metal"),
		B("Stock", 0, -0.02, 1.25, 0.4, 0.48, 0.9, "Panel"),
		B("StockCore", 0, -0.02, 1.25, 0.42, 0.22, 0.7, "Body"),
		B("StockGlow", 0, -0.02, 1.25, 0.43, 0.05, 0.5, "Accent"),
		B("ButtPad", 0, -0.02, 1.74, 0.44, 0.62, 0.12, "Body"),
	}
	add(p, Group(CFrame.new(0, -0.52, 0.62) * CFrame.Angles(rad(15), 0, 0), {
		B("Grip", 0, 0, 0, 0.26, 0.56, 0.32, "Body"),
		B("GripRubber", 0, -0.02, -0.01, 0.275, 0.4, 0.22, "Rubber"),
		B("GripGlow", 0, 0, 0.17, 0.27, 0.42, 0.03, "Accent"),
	}))
	return p
end

---------------------------------------------------------------------------
-- VORTEX BR (fusil de ráfaga, bullpup)
---------------------------------------------------------------------------
function Designs.VortexBR()
	local p = {
		B("Handle", 0, 0, 0, 0.36, 0.5, 1.4, "Body"),
		B("Shell", 0, 0.06, 0.2, 0.38, 0.38, 1.6, "Panel"),
		B("ShellCut", 0, -0.05, 0.55, 0.39, 0.16, 0.5, "Body"),
		B("GlowLine", 0, 0.18, 0.1, 0.39, 0.045, 1.2, "Accent"),
		B("GlowLine2", 0, -0.08, -0.3, 0.39, 0.04, 0.5, "Accent2"),
		Label("NamePlate", 0, 0.02, 0.45, 0.385, 0.12, 0.45, "VORTEX"),
		B("TopRail", 0, 0.29, -0.1, 0.18, 0.08, 1.6, "Dark"),
		-- Mira de punto
		B("SightBase", 0, 0.36, -0.1, 0.22, 0.08, 0.34, "Dark"),
		B("SightL", -0.13, 0.52, -0.1, 0.04, 0.26, 0.34, "Body"),
		B("SightR", 0.13, 0.52, -0.1, 0.04, 0.26, 0.34, "Body"),
		B("SightTop", 0, 0.67, -0.1, 0.3, 0.05, 0.34, "Body"),
		B("SightLens", 0, 0.52, -0.25, 0.22, 0.22, 0.02, "Lens"),
		B("SightDot", 0, 0.52, -0.24, 0.035, 0.035, 0.01, "Accent2"),
		-- Frente
		B("Front", 0, 0.02, -0.95, 0.36, 0.36, 0.6, "Body"),
		B("FrontGlow", 0, 0.12, -0.95, 0.37, 0.04, 0.5, "Accent"),
		C("Barrel", 0, 0.04, -1.45, 0.5, 0.15, "Dark"),
		C("Muzzle", 0, 0.04, -1.75, 0.22, 0.26, "Body"),
		C("MuzzleGlow", 0, 0.04, -1.86, 0.04, 0.28, "Accent2"),
		C("MuzzleBore", 0, 0.04, -1.88, 0.02, 0.12, "Dark"),
		-- Cargador detrás de la empuñadura (bullpup)
		B("Mag", 0, -0.45, 0.45, 0.24, 0.5, 0.32, "Dark", -10, 0, 0),
		B("MagGlow", 0, -0.45, 0.45, 0.25, 0.36, 0.04, "Accent2", -10, 0, 0),
		B("TriggerGuard", 0, -0.3, -0.3, 0.06, 0.04, 0.36, "Dark"),
		B("Trigger", 0, -0.22, -0.28, 0.04, 0.12, 0.04, "Metal"),
		B("ButtPad", 0, -0.02, 1.02, 0.4, 0.56, 0.1, "Body"),
		B("ButtGlow", 0, -0.02, 1.03, 0.41, 0.42, 0.035, "Accent"),
	}
	add(p, Group(CFrame.new(0, -0.45, -0.12) * CFrame.Angles(rad(12), 0, 0), {
		B("Grip", 0, 0, 0, 0.22, 0.52, 0.28, "Body"),
		B("GripRubber", 0, -0.02, -0.01, 0.235, 0.38, 0.2, "Rubber"),
	}))
	return p
end

---------------------------------------------------------------------------
-- RAPTOR DMR (fusil de tirador)
---------------------------------------------------------------------------
function Designs.RaptorDMR()
	local p = {
		B("Handle", 0, 0, 0, 0.34, 0.46, 1.5, "Body"),
		B("UpperPanel", 0, 0.12, 0.2, 0.36, 0.2, 1.0, "Panel"),
		B("Glow", 0, 0.12, -0.1, 0.37, 0.04, 0.6, "Accent"),
		Label("NamePlate", 0, -0.1, 0.2, 0.355, 0.12, 0.45, "RAPTOR"),
		B("TopRail", 0, 0.28, -0.4, 0.18, 0.08, 2.0, "Dark"),
		-- Mira de aumento (tipo ACOG) hueca
		B("ScopeBase", 0, 0.36, 0.05, 0.22, 0.08, 0.5, "Dark"),
		B("ScopeL", -0.13, 0.55, 0.05, 0.04, 0.3, 0.55, "Body"),
		B("ScopeR", 0.13, 0.55, 0.05, 0.04, 0.3, 0.55, "Body"),
		B("ScopeTop", 0, 0.72, 0.05, 0.3, 0.06, 0.55, "Body"),
		B("ScopeGlow", 0, 0.76, 0.05, 0.12, 0.03, 0.45, "Accent"),
		B("ScopeLens", 0, 0.55, -0.2, 0.22, 0.28, 0.02, "Lens"),
		B("ScopeChevron", 0, 0.53, -0.19, 0.03, 0.05, 0.01, "Accent2"),
		-- Guardamanos y cañón
		B("Handguard", 0, 0.02, -1.25, 0.34, 0.36, 1.0, "Panel"),
		B("HG_Slot1", 0, 0.0, -1.0, 0.35, 0.12, 0.12, "Body"),
		B("HG_Slot2", 0, 0.0, -1.25, 0.35, 0.12, 0.12, "Body"),
		B("HG_Slot3", 0, 0.0, -1.5, 0.35, 0.12, 0.12, "Body"),
		B("HG_Glow", 0, -0.14, -1.25, 0.35, 0.035, 0.8, "Accent"),
		C("Barrel", 0, 0.04, -2.1, 0.8, 0.13, "Dark"),
		C("Muzzle", 0, 0.04, -2.55, 0.25, 0.22, "Body"),
		C("MuzzleGlow", 0, 0.04, -2.43, 0.04, 0.24, "Accent"),
		C("MuzzleBore", 0, 0.04, -2.68, 0.02, 0.1, "Dark"),
		B("Mag", 0, -0.45, -0.3, 0.24, 0.48, 0.34, "Dark", -6, 0, 0),
		B("MagBase", 0, -0.7, -0.33, 0.27, 0.06, 0.38, "Panel", -6, 0, 0),
		B("TriggerGuard", 0, -0.3, 0.12, 0.06, 0.04, 0.36, "Dark"),
		B("Trigger", 0, -0.22, 0.14, 0.04, 0.12, 0.04, "Metal"),
		B("Stock", 0, 0.02, 1.25, 0.3, 0.42, 0.9, "Panel"),
		B("StockHole", 0, -0.05, 1.2, 0.31, 0.16, 0.45, "Body"),
		B("ButtPad", 0, 0.0, 1.73, 0.32, 0.58, 0.1, "Body"),
	}
	add(p, Group(CFrame.new(0, -0.45, 0.42) * CFrame.Angles(rad(15), 0, 0), {
		B("Grip", 0, 0, 0, 0.22, 0.52, 0.28, "Body"),
		B("GripRubber", 0, -0.02, -0.01, 0.235, 0.38, 0.2, "Rubber"),
		B("GripGlow", 0, 0, 0.15, 0.235, 0.36, 0.025, "Accent"),
	}))
	return p
end

---------------------------------------------------------------------------
-- NOVA (lanzacohetes)
---------------------------------------------------------------------------
function Designs.NovaLauncher()
	local p = {
		B("Handle", 0, 0, 0, 0.3, 0.3, 0.6, "Body"),
		C("Tube", 0, 0.35, -0.2, 3.2, 0.6, "Body"),
		C("SleeveFront", 0, 0.35, -1.25, 0.7, 0.64, "Panel"),
		C("SleeveMid", 0, 0.35, -0.15, 0.9, 0.64, "Panel"),
		C("SleeveRear", 0, 0.35, 1.0, 0.6, 0.64, "Panel"),
		C("TubeBand1", 0, 0.35, -0.9, 0.12, 0.68, "Dark"),
		C("TubeBand2", 0, 0.35, 0.6, 0.12, 0.68, "Dark"),
		B("Stripe", 0, 0.66, -0.2, 0.08, 0.03, 2.6, "Accent"),
		C("TubeGlow1", 0, 0.35, -0.75, 0.05, 0.665, "Accent"),
		C("TubeGlow2", 0, 0.35, 0.45, 0.05, 0.665, "Accent"),
		C("FrontCone", 0, 0.35, -1.9, 0.3, 0.78, "Body"),
		C("FrontRing", 0, 0.35, -2.07, 0.05, 0.8, "Accent"),
		C("FrontBore", 0, 0.35, -2.1, 0.02, 0.5, "Dark"),
		Ball("RocketTip", 0, 0.35, -1.95, 0.42, "Shell"),
		C("RearExhaust", 0, 0.35, 1.5, 0.3, 0.72, "Body"),
		C("RearGlow", 0, 0.35, 1.66, 0.04, 0.66, "Accent2"),
		C("RearBore", 0, 0.35, 1.67, 0.02, 0.5, "Dark"),
		Label("NamePlate", 0, 0.35, -0.2, 0.635, 0.16, 0.7, "NOVA"),
		-- Mira lateral elevada
		B("SightArm", 0, 0.7, -0.2, 0.08, 0.14, 0.1, "Dark"),
		B("SightL", -0.12, 0.85, -0.2, 0.04, 0.22, 0.24, "Body"),
		B("SightR", 0.12, 0.85, -0.2, 0.04, 0.22, 0.24, "Body"),
		B("SightTop", 0, 0.97, -0.2, 0.28, 0.04, 0.24, "Body"),
		B("SightLens", 0, 0.85, -0.3, 0.2, 0.2, 0.02, "Lens"),
		B("SightDot", 0, 0.85, -0.29, 0.04, 0.04, 0.01, "Accent2"),
		-- Empuñaduras
		B("TriggerGuard", 0, -0.2, -0.05, 0.06, 0.04, 0.34, "Dark"),
		B("ForeGrip", 0, -0.12, -0.9, 0.18, 0.5, 0.2, "Body"),
		B("ForeGripGlow", 0, -0.12, -0.99, 0.19, 0.36, 0.025, "Accent"),
	}
	add(p, Group(CFrame.new(0, -0.32, 0.1) * CFrame.Angles(rad(12), 0, 0), {
		B("Grip", 0, 0, 0, 0.22, 0.5, 0.28, "Body"),
		B("GripRubber", 0, -0.02, -0.01, 0.235, 0.36, 0.2, "Rubber"),
	}))
	return p
end

---------------------------------------------------------------------------
-- VIPER P9 (pistola)
---------------------------------------------------------------------------
function Designs.Viper()
	local p = {
		B("Handle", 0, 0, 0, 0.26, 0.3, 1.05, "Body"),
		B("SlidePanel", 0, 0.05, 0.1, 0.27, 0.16, 0.65, "Panel"),
		B("SlideGlow", 0, 0.12, -0.25, 0.27, 0.04, 0.45, "Accent"),
		B("Serration1", 0, 0.02, 0.38, 0.275, 0.2, 0.03, "Dark"),
		B("Serration2", 0, 0.02, 0.44, 0.275, 0.2, 0.03, "Dark"),
		B("Serration3", 0, 0.02, 0.5, 0.275, 0.2, 0.03, "Dark"),
		B("Frame", 0, -0.21, -0.05, 0.24, 0.14, 0.95, "Dark"),
		B("FrameGlow", 0, -0.21, -0.35, 0.245, 0.03, 0.3, "Accent"),
		C("BarrelTip", 0, 0.02, -0.56, 0.08, 0.13, "Dark"),
		B("RearSightL", -0.07, 0.19, 0.46, 0.05, 0.07, 0.07, "Dark"),
		B("RearSightR", 0.07, 0.19, 0.46, 0.05, 0.07, 0.07, "Dark"),
		B("FrontSight", 0, 0.19, -0.46, 0.05, 0.08, 0.05, "Accent2"),
		B("TriggerGuard", 0, -0.33, -0.05, 0.05, 0.04, 0.32, "Dark"),
		B("Trigger", 0, -0.27, -0.02, 0.03, 0.12, 0.03, "Metal"),
		B("Hammer", 0, 0.14, 0.55, 0.06, 0.1, 0.06, "Metal"),
	}
	add(p, Group(CFrame.new(0, -0.5, 0.32) * CFrame.Angles(rad(14), 0, 0), {
		B("Grip", 0, 0, 0, 0.24, 0.62, 0.32, "Body"),
		B("GripPanel", 0, 0, 0, 0.255, 0.44, 0.22, "Panel"),
		B("GripGlow", 0, 0, 0.165, 0.25, 0.46, 0.025, "Accent"),
	}))
	return p
end

---------------------------------------------------------------------------
-- HAND CANNON (revólver)
---------------------------------------------------------------------------
function Designs.HandCannon()
	local p = {
		B("Handle", 0, 0, 0, 0.26, 0.36, 0.6, "Body"),
		CX("Cylinder", 0, 0.0, -0.1, 0.3, 0.4, "Panel"),
		CX("CylinderGlow", 0, 0.0, -0.1, 0.31, 0.2, "Accent"),
		B("TopStrap", 0, 0.2, -0.1, 0.2, 0.06, 0.6, "Body"),
		B("Barrel", 0, 0.08, -0.85, 0.2, 0.24, 1.1, "Body"),
		B("BarrelRib", 0, 0.22, -0.85, 0.1, 0.06, 1.1, "Panel"),
		B("BarrelGlow", 0, 0.08, -0.85, 0.21, 0.04, 0.9, "Accent"),
		C("Bore", 0, 0.06, -1.41, 0.02, 0.12, "Dark"),
		B("FrontSight", 0, 0.29, -1.33, 0.04, 0.1, 0.08, "Accent2"),
		B("RearSightL", -0.06, 0.27, 0.22, 0.04, 0.06, 0.06, "Dark"),
		B("RearSightR", 0.06, 0.27, 0.22, 0.04, 0.06, 0.06, "Dark"),
		B("Hammer", 0, 0.2, 0.3, 0.07, 0.14, 0.1, "Metal", -25, 0, 0),
		B("TriggerGuard", 0, -0.27, 0.0, 0.05, 0.04, 0.3, "Dark"),
		B("Trigger", 0, -0.21, 0.02, 0.03, 0.12, 0.03, "Metal"),
	}
	add(p, Group(CFrame.new(0, -0.45, 0.3) * CFrame.Angles(rad(20), 0, 0), {
		B("Grip", 0, 0, 0, 0.24, 0.6, 0.3, "Panel"),
		B("GripWood", 0, -0.02, 0, 0.255, 0.44, 0.22, "Body"),
		B("GripGlow", 0, 0, 0.155, 0.25, 0.44, 0.025, "Accent"),
	}))
	return p
end

---------------------------------------------------------------------------
-- COLMILLO (cuchillo)
---------------------------------------------------------------------------
function Designs.Knife()
	return {
		B("Handle", 0, 0, 0, 0.17, 0.22, 0.6, "Body"),
		B("Wrap1", 0, 0, -0.15, 0.18, 0.23, 0.06, "Rubber"),
		B("Wrap2", 0, 0, 0, 0.18, 0.23, 0.06, "Rubber"),
		B("Wrap3", 0, 0, 0.15, 0.18, 0.23, 0.06, "Rubber"),
		B("Pommel", 0, 0, 0.34, 0.2, 0.24, 0.08, "Panel"),
		B("PommelGlow", 0, 0, 0.385, 0.12, 0.12, 0.02, "Accent"),
		B("Guard", 0, 0, -0.33, 0.34, 0.26, 0.07, "Panel"),
		B("Blade", 0, 0.02, -0.82, 0.05, 0.26, 0.92, "Dark"),
		B("BladeGlow", 0, -0.08, -0.82, 0.055, 0.05, 0.9, "Accent"),
		B("BladeTip", 0, -0.02, -1.36, 0.05, 0.18, 0.32, "Dark", 30, 0, 0),
		B("TipGlow", 0, -0.09, -1.33, 0.055, 0.04, 0.28, "Accent", 30, 0, 0),
		B("Spine", 0, 0.15, -0.8, 0.06, 0.06, 0.88, "Panel"),
	}
end

return Designs
