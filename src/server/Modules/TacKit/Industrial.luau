-- Piezas de planta industrial (Industrial Yard): depósito horizontal sobre cunas, rack de tuberías,
-- chimenea, montón de grava, prensa/máquina, pala cargadora y cinta transportadora.
-- cf = centro de la base; la "cara" mira a -Z.
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local Industrial = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local get = Materials.get
local M = Enum.Material

local TIRE = { RGB(32, 32, 34), M.SmoothPlastic }

-- Depósito horizontal (a lo largo de Z local) sobre dos cunas: cobertura alta
function Industrial.horizontalTank(cf, length, d)
	length, d = length or 16, d or 6
	local body = Kit.pipe("HTank", length, d, cf * CFrame.new(0, d / 2 + 1.2, 0) * CFrame.Angles(0, rad(90), 0), get("Tank")[1], get("Tank")[2])
	for _, z in { -length / 3, length / 3 } do
		G.box("TankSaddle", V(d * 0.8, 2, 1.2), cf * CFrame.new(0, 1, z), "ConcreteDark")
	end
	for _, z in { -length / 4, length / 4 } do
		G.deco("TankBand", V(d + 0.12, 0.5, 0.5), cf * CFrame.new(0, d / 2 + 1.2, z), "Rust").CastShadow = false
	end
	G.deco("TankHazard", V(0.2, 1.4, 3), cf * CFrame.new(d / 2 + 0.05, d / 2 + 1.2, 0), "Orange").CastShadow = false
	return body
end

-- Rack de tuberías de a a b (pilares que chocan cada 10 studs; vigas y tubos por encima de la
-- cabeza, decorado). h = altura de la viga
function Industrial.pipeRack(a, b, h, width)
	h, width = h or 9, width or 6
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local columns = {}
	local n = math.max(1, math.floor(length / 10))
	for i = 0, n do
		local z = -length / 2 + i * length / n
		for _, s in { -1, 1 } do
			table.insert(columns, G.box("RackColumn", V(0.8, h, 0.8), cf * CFrame.new(s * width / 2, h / 2, z), "Steel"))
		end
		G.deco("RackBeam", V(width + 0.8, 0.6, 0.6), cf * CFrame.new(0, h, z), "Steel")
	end
	for i, look in { "Rust", "PipeBlue", "Tank", "PipeGreen" } do
		local x = -width / 2 + 0.9 + (i - 1) * (width - 1.8) / 3
		local pipe = Kit.pipe("RackPipe", length, 0.9, cf * CFrame.new(x, h + 0.75, 0) * CFrame.Angles(0, rad(90), 0), get(look)[1], get(look)[2], true)
		pipe.CastShadow = i == 1
	end
	return columns
end

-- Chimenea de ladrillo (decorado por encima del tejado) con franjas blancas y rojas en la punta
function Industrial.chimney(cf, h, d)
	h, d = h or 50, d or 6
	local stack = Kit.cylinder("Chimney", h, d, cf * CFrame.new(0, h / 2, 0), get("Brick")[1], get("Brick")[2], nil, true)
	for i, y in { h - 6, h - 3 } do
		Kit.cylinder("ChimneyBand", 1.4, d + 0.2, cf * CFrame.new(0, y, 0), i == 1 and get("Red")[1] or get("Paint")[1], M.SmoothPlastic, nil, true)
	end
	Kit.cylinder("ChimneyLip", 0.8, d + 0.8, cf * CFrame.new(0, h, 0), get("ConcreteDark")[1], M.Concrete, nil, true)
	return stack
end

-- Montón de grava o carbón (bloque central y dos rampas): cobertura alta. Las rampas no se pueden
-- subir: un clip invisible cubre todo el montón desde 1,5 studs (deja pasar las balas)
function Industrial.heap(cf, w, d, h, look)
	look = look or "Gravel"
	local parts = {}
	table.insert(parts, G.box("HeapCore", V(w * 0.5, h, d), cf * CFrame.new(0, h / 2, 0), look))
	for _, s in { -1, 1 } do
		local wedge = G.box("HeapSide", V(d, h, w * 0.25), cf * CFrame.new(s * w * 0.375, h / 2, 0) * CFrame.Angles(0, -s * rad(90), 0), look)
		wedge.Shape = Enum.PartType.Wedge
		table.insert(parts, wedge)
	end
	local clip = Kit.block("PlayerClip", V(w, 60 - 1.5, d), cf * CFrame.new(0, 1.5 + (60 - 1.5) / 2, 0), Color3.new(1, 1, 1), nil, Kit.shootThroughFolder())
	clip.Transparency = 1
	clip.CastShadow = false
	return parts
end

-- Prensa o máquina de la nave (cobertura alta) con su panel de luces
function Industrial.machine(cf, w, d, h)
	w, d, h = w or 6, d or 5, h or 7
	local body = G.box("Machine", V(w, h, d), cf * CFrame.new(0, h / 2, 0), "MachineGreen")
	G.deco("MachineTop", V(w * 0.7, 1.6, d * 0.6), cf * CFrame.new(0, h + 0.8, 0), "SteelDark")
	G.deco("MachineStripe", V(w + 0.1, 0.5, d + 0.1), cf * CFrame.new(0, 1.2, 0), "Orange").CastShadow = false
	local panel = G.deco("MachinePanel", V(1.6, 1.2, 0.2), cf * CFrame.new(w * 0.25, h * 0.6, -d / 2 - 0.1), { RGB(120, 220, 140), M.Neon })
	panel.CastShadow = false
	return body
end

-- Pala cargadora (choca: cobertura media). Mira a -Z
function Industrial.wheelLoader(cf)
	local body = G.box("Loader", V(6, 4, 10), cf * CFrame.new(0, 3.2, 1), "Orange")
	G.deco("LoaderCab", V(4.4, 3.4, 4), cf * CFrame.new(0, 6.9, 2), { RGB(40, 48, 58), M.Glass })
	G.deco("LoaderBucket", V(7, 2.6, 2), cf * CFrame.new(0, 1.6, -5.4), "SteelDark")
	for _, s in { -1, 1 } do
		G.deco("LoaderArm", V(0.6, 0.6, 5), cf * CFrame.new(s * 2.4, 3.6, -2.6) * CFrame.Angles(rad(20), 0, 0), "SteelDark")
		for _, z in { -2.6, 4 } do
			Kit.cylinder("Wheel", 1.2, 3.2, cf * CFrame.new(s * 3.2, 1.6, z) * CFrame.Angles(0, 0, rad(90)), TIRE[1], TIRE[2], nil, true)
		end
	end
	return body
end

-- Cinta transportadora inclinada de a (abajo) a b (arriba): decorado sobre patas
function Industrial.conveyor(a, b, width)
	width = width or 3
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	G.deco("ConveyorBelt", V(width, 0.6, length), cf, "SteelDark")
	G.deco("ConveyorCover", V(width + 0.4, 1.4, length), cf * CFrame.new(0, 0.9, 0), "Orange")
	local n = math.max(1, math.floor(length / 10))
	for i = 1, n do
		local p = a:Lerp(b, i / (n + 1))
		G.deco("ConveyorLeg", V(0.6, p.Y, 0.6), CFrame.new(p.X, p.Y / 2, p.Z), "Steel")
	end
end

return Industrial
