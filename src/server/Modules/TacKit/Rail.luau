-- Piezas de ferrocarril (Metro Yard): vía con balasto y traviesas, coche de metro (cobertura alta,
-- con cabina opcional), topera, pórtico de catenaria, torniquetes, máquina de billetes, máquina de
-- bebidas, banco, panel de salidas, tótem "M" y carro de mantenimiento. cf = centro de la base;
-- las piezas largas van a lo largo de Z local (la "cara" mira a -Z).
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local Rail = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local get = Materials.get
local M = Enum.Material

local DARK_GLASS = { RGB(34, 42, 54), M.Glass }
local BOGIE = { RGB(44, 46, 52), M.Metal }

-- Vía de a a b (a la altura del suelo de la zanja): balasto, traviesas cada 3 studs y dos carriles.
-- Todo decorado (no choca: se camina por encima sin tropezar)
function Rail.track(a, b, opts)
	opts = opts or {}
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	G.deco("Ballast", V(5.2, 0.3, length), cf * CFrame.new(0, 0.15, 0), "Ballast").CastShadow = false
	local step = opts.Step or 3
	local count = math.floor(length / step)
	for i = 0, count - 1 do
		local z = -length / 2 + step * (i + 0.5)
		G.deco("Sleeper", V(4.4, 0.24, 0.7), cf * CFrame.new(0, 0.42, z), "Sleeper").CastShadow = false
	end
	for _, s in { -1, 1 } do
		G.deco("RailTrack", V(0.3, 0.4, length), cf * CFrame.new(s * 1.45, 0.7, 0), "Rail").CastShadow = false
	end
end

-- Coche de metro de length studs (a lo largo de Z local) sobre el carril (cf a la altura de la
-- vía). Caja que choca (cobertura alta), franja naranja, ventanas, puertas y aire acondicionado.
-- opts: Cab = "Front" | "Back" | "Both" (cabina con parabrisas y faros), Stripe, Label
function Rail.metroCar(cf, length, opts)
	opts = opts or {}
	length = length or 20
	local stripe = opts.Stripe and get(opts.Stripe) or get("Orange")
	local h = 7.6
	local body = G.box("TrainBody", V(6.4, h, length), cf * CFrame.new(0, 0.5 + h / 2, 0), "Train")
	G.deco("TrainRoof", V(5.6, 0.5, length - 1), cf * CFrame.new(0, 0.5 + h + 0.25, 0), "Steel")
	for _, s in { -1, 1 } do
		local side = cf * CFrame.new(s * 3.24, 0, 0)
		G.deco("TrainWindows", V(0.12, 2.2, length - 3), side * CFrame.new(0, 5.4, 0), DARK_GLASS).CastShadow = false
		G.deco("TrainStripe", V(0.12, 0.7, length), side * CFrame.new(0, 3.2, 0), stripe).CastShadow = false
		G.deco("TrainSkirt", V(0.12, 0.9, length - 2), side * CFrame.new(0, 1.0, 0), BOGIE).CastShadow = false
		for _, z in { -length / 4, length / 4 } do
			G.deco("TrainDoor", V(0.16, 5.8, 3.4), side * CFrame.new(0, 3.6, z), "Steel").CastShadow = false
			G.deco("TrainDoorGlass", V(0.2, 2.2, 2.6), side * CFrame.new(0, 5.2, z), DARK_GLASS).CastShadow = false
		end
	end
	for _, z in { -length / 2 + 4, length / 2 - 4 } do
		G.deco("TrainBogie", V(5.2, 0.9, 4.4), cf * CFrame.new(0, 0.45, z), BOGIE)
		G.deco("TrainAC", V(3.6, 0.7, 3), cf * CFrame.new(0, 0.5 + h + 0.6, z * 0.6), "SteelDark")
	end
	local cabs = opts.Cab
	for _, e in { { "Front", -1 }, { "Back", 1 } } do
		if cabs == e[1] or cabs == "Both" then
			local face = cf * CFrame.new(0, 0, e[2] * (length / 2 + 0.06))
			G.deco("Windscreen", V(5.2, 2.6, 0.12), face * CFrame.new(0, 5.4, 0), DARK_GLASS).CastShadow = false
			G.deco("CabStripe", V(6.4, 0.7, 0.12), face * CFrame.new(0, 3.2, 0), stripe).CastShadow = false
			for _, s in { -1, 1 } do
				local lamp = G.deco("HeadLight", V(0.8, 0.5, 0.14), face * CFrame.new(s * 2.2, 2.2, 0), { RGB(255, 246, 220), M.Neon })
				lamp.CastShadow = false
			end
			local label = G.deco("Destination", V(3.6, 0.7, 0.14), face * CFrame.new(0, 7.2, 0), { RGB(20, 22, 26), M.SmoothPlastic })
			local gui = Kit.sign(label, e[2] < 0 and Enum.NormalId.Front or Enum.NormalId.Back, opts.Label or "M2 · CENTRO", RGB(255, 170, 60), RGB(20, 22, 26))
			gui.LightInfluence = 0
		end
	end
	return body
end

-- Tren de varios coches seguidos a lo largo de Z local (cf = centro del tren). Devuelve los cuerpos
function Rail.train(cf, cars, carLength, opts)
	opts = opts or {}
	carLength = carLength or 20
	local gap = 0.8
	local total = cars * carLength + (cars - 1) * gap
	local bodies = {}
	for i = 1, cars do
		local z = -total / 2 + (i - 0.5) * carLength + (i - 1) * gap
		local cab = nil
		if cars == 1 then
			cab = "Both"
		elseif i == 1 then
			cab = "Front"
		elseif i == cars then
			cab = "Back"
		end
		table.insert(bodies, Rail.metroCar(cf * CFrame.new(0, 0, z), carLength, { Cab = cab, Stripe = opts.Stripe, Label = opts.Label }))
		if i < cars then
			G.deco("Gangway", V(4.6, 6.4, gap + 0.2), cf * CFrame.new(0, 0.5 + 3.8, z + carLength / 2 + gap / 2), BOGIE)
		end
	end
	return bodies
end

-- Topera al final de una vía (choca: cobertura baja). Mira a -Z (la vía llega por -Z)
function Rail.bufferStop(cf)
	local body = G.box("BufferStop", V(4.6, 2.6, 1.6), cf * CFrame.new(0, 1.3, 0), "SteelDark")
	G.deco("BufferFace", V(4.8, 0.8, 0.2), cf * CFrame.new(0, 1.9, -0.86), "Red").CastShadow = false
	for _, s in { -1, 1 } do
		G.deco("Buffer", V(0.9, 0.9, 0.8), cf * CFrame.new(s * 1.45, 1.4, -1.1), "Steel")
	end
	return body
end

-- Pórtico de catenaria sobre una zanja (span = ancho; decorado: postes y viga sin colisión)
function Rail.gantry(cf, span, h)
	h = h or 9
	for _, s in { -1, 1 } do
		G.deco("GantryPole", V(0.6, h, 0.6), cf * CFrame.new(s * span / 2, h / 2, 0), "SteelDark")
	end
	G.deco("GantryBeam", V(span + 0.6, 0.6, 0.6), cf * CFrame.new(0, h - 0.3, 0), "SteelDark")
	G.deco("Catenary", V(span, 0.08, 0.08), cf * CFrame.new(0, h - 1.4, 0), BOGIE).CastShadow = false
end

-- Línea de torniquetes a lo largo de X local (count unidades; huecos de paso de 3 studs)
function Rail.turnstiles(cf, count)
	local pitch = 4.2
	local parts = {}
	for i = 0, count do
		local x = (i - count / 2) * pitch
		table.insert(parts, G.box("Turnstile", V(1, 3.2, 2), cf * CFrame.new(x, 1.6, 0), "SteelDark"))
		G.deco("TurnstileTop", V(1.1, 0.12, 2.1), cf * CFrame.new(x, 3.26, 0), "Orange").CastShadow = false
		if i < count then
			G.deco("GatePaddle", V(2.8, 1.6, 0.1), cf * CFrame.new(x + pitch / 2, 1.9, 0), { RGB(190, 214, 230), M.Glass }).Transparency = 0.5
		end
	end
	return parts
end

-- Máquina de billetes (choca: cobertura media)
function Rail.ticketMachine(cf)
	local body = G.box("TicketMachine", V(2.6, 6, 1.8), cf * CFrame.new(0, 3, 0), "WallBlue")
	local screen = G.deco("TicketScreen", V(1.8, 1.4, 0.1), cf * CFrame.new(0, 4.3, -0.92), { RGB(120, 200, 255), M.Neon })
	screen.CastShadow = false
	G.deco("TicketSlot", V(1.6, 0.3, 0.1), cf * CFrame.new(0, 2.6, -0.92), "SteelDark")
	return body
end

-- Máquina de bebidas (choca)
function Rail.vending(cf, color)
	local body = G.box("Vending", V(3, 6.4, 2.2), cf * CFrame.new(0, 3.2, 0), { color or RGB(240, 128, 36), M.SmoothPlastic })
	G.deco("VendingGlass", V(1.8, 4, 0.1), cf * CFrame.new(-0.4, 3.8, -1.12), { RGB(200, 230, 255), M.Glass }).CastShadow = false
	return body
end

-- Banco del andén (choca: cobertura muy baja)
function Rail.bench(cf)
	local seat = G.box("Bench", V(5, 1.4, 1.6), cf * CFrame.new(0, 0.7, 0), "SteelDark")
	G.deco("BenchBack", V(5, 1.4, 0.3), cf * CFrame.new(0, 2, 0.65), "Orange").CastShadow = false
	return seat
end

-- Panel de salidas colgado (decorado; luce)
function Rail.departureBoard(cf, text)
	local board = G.deco("DepartureBoard", V(7, 1.6, 0.4), cf, { RGB(18, 20, 26), M.SmoothPlastic })
	board.CastShadow = false
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Kit.sign(board, face, text or "M2 CENTRO  2 min", RGB(255, 170, 60), RGB(18, 20, 26))
		gui.LightInfluence = 0
	end
	G.deco("BoardHanger", V(0.2, 2, 0.2), cf * CFrame.new(-2.5, 1.8, 0), "SteelDark")
	G.deco("BoardHanger", V(0.2, 2, 0.2), cf * CFrame.new(2.5, 1.8, 0), "SteelDark")
	return board
end

-- Tótem del metro: poste con la "M" azul en un cuadrado (hito para orientarse)
function Rail.metroTotem(cf, h)
	h = h or 9
	G.box("TotemPole", V(0.8, h, 0.8), cf * CFrame.new(0, h / 2, 0), "SteelDark")
	local sign = G.deco("TotemSign", V(3.2, 3.2, 0.5), cf * CFrame.new(0, h + 1.2, 0), "Blue")
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Kit.sign(sign, face, "M", RGB(255, 255, 255), RGB(40, 96, 196))
		gui.LightInfluence = 0.3
	end
	return sign
end

-- Carro de mantenimiento sobre la vía (choca: cobertura media)
function Rail.trolley(cf)
	local body = G.box("Trolley", V(5, 2.6, 7), cf * CFrame.new(0, 1.9, 0), "Orange")
	for _, z in { -2.4, 2.4 } do
		G.deco("TrolleyWheels", V(4.4, 0.6, 1.2), cf * CFrame.new(0, 0.3, z), BOGIE)
	end
	G.deco("TrolleyLoad", V(4.2, 1.2, 3), cf * CFrame.new(0, 3.8, -1.2), "SteelDark")
	return body
end

-- Armario de señales (choca: cobertura alta y estrecha)
function Rail.relayCabinet(cf, h)
	h = h or 6
	local body = G.box("RelayCabinet", V(3.2, h, 2.4), cf * CFrame.new(0, h / 2, 0), "ConcreteDark")
	G.deco("CabinetStripe", V(3.3, 0.5, 2.5), cf * CFrame.new(0, h - 0.6, 0), "Orange").CastShadow = false
	local lamp = G.deco("SignalLamp", V(0.6, 0.6, 0.2), cf * CFrame.new(0.8, h - 1.6, -1.25), { RGB(80, 255, 120), M.Neon })
	lamp.CastShadow = false
	return body
end

return Rail
